From: Xiubo Li <xiubo.li@clyso.com>
Date: Mon, 20 Jul 2026 20:39:24 +0800
Subject: [PATCH] ceph: parallelize object copy in ceph_do_objects_copy()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260720-b4-ceph-copyfrom-v1-1-9a4c229df6e2@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB2IoUzFq4gLM451CpqQaGkR7
 260y7f4f4ckUSVBU+wQ5aNJ/ZJRlQXw1C8vQR2ywRpL5mkNugeyhAnZh98Y/YxcU22cHYgqgpy
 FKKN+72Xb/Z029xZerw8cxwlGjrXYdAAAAA==
X-Change-ID: 20260720-b4-ceph-copyfrom-c8680b2d6616
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784551170; l=9188;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=tBKXfCJ+NgJ+kSb6ibcSYY9ADa5eQQQSOPM+cAzJ68Y=;
 b=lLJhX844uCwzYJMues2rQhaN+mW0jEx8/TKpFwSdDCXZh6Dtm6LVBoohNC+AMIeMwEhTemzMb
 mdBHAOXmAB2D92Tdny88+GmPKW+v18diP2t9lx5QvPdNICTq+B6v/nK
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The current ceph_do_objects_copy() submits COPY_FROM2 requests serially
(submit-wait-submit-wait), which means the total latency scales linearly
with the number of objects being copied.

Convert to a sliding-window parallel model: submit up to
CEPH_COPY_FROM_MAX_INFLIGHT (16) requests concurrently, then wait for
them in FIFO order.  Because all in-flight requests make progress while
we wait for the oldest one, the total wait time is MAX(latency_i)
rather than SUM(latency_i).

Error handling uses a 'truncate at first failure' strategy: all
submitted requests are allowed to complete, results are scanned in
offset order, and the copy is truncated at the first failing object.
Objects beyond the truncation point that were successfully written by
the OSD become orphaned beyond EOF, which is harmless — they are
unreachable through reads and are cleaned up on file deletion.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/file.c | 193 +++++++++++++++++++++++++++++++++++++++++++++------------
 1 file changed, 152 insertions(+), 41 deletions(-)

diff --git a/fs/ceph/file.c b/fs/ceph/file.c
index 9d89d7fc1095..32147c719c35 100644
--- a/fs/ceph/file.c
+++ b/fs/ceph/file.c
@@ -2965,6 +2965,20 @@ ceph_alloc_copyfrom_request(struct ceph_osd_client *osdc,
 	return ERR_PTR(ret);
 }
 
+/*
+ * Default maximum number of in-flight COPY_FROM2 requests.  Can be
+ * overridden at module load time via the copyfrom_max_inflight parameter.
+ *
+ * Higher values improve throughput over high-latency links, but too many
+ * concurrent requests can saturate OSD disk queues, especially in small
+ * clusters.  Tune this to match the number of OSDs and their concurrency
+ * capability.  For most clusters 16--64 is a reasonable range.
+ */
+static unsigned int copyfrom_max_inflight = 16;
+module_param(copyfrom_max_inflight, uint, 0644);
+MODULE_PARM_DESC(copyfrom_max_inflight,
+		 "Maximum in-flight COPY_FROM2 requests per copy_file_range call");
+
 static ssize_t ceph_do_objects_copy(struct ceph_inode_info *src_ci, u64 *src_off,
 				    struct ceph_inode_info *dst_ci, u64 *dst_off,
 				    struct ceph_fs_client *fsc,
@@ -2973,13 +2987,19 @@ static ssize_t ceph_do_objects_copy(struct ceph_inode_info *src_ci, u64 *src_off
 	struct ceph_object_locator src_oloc, dst_oloc;
 	struct ceph_object_id src_oid, dst_oid;
 	struct ceph_osd_client *osdc;
+	struct ceph_osd_request **reqs = NULL;
 	struct ceph_osd_request *req;
 	ssize_t bytes = 0;
 	u64 src_objnum, src_objoff, dst_objnum, dst_objoff;
 	u32 src_objlen, dst_objlen;
 	u32 object_size = src_ci->i_layout.object_size;
 	struct ceph_client *cl = fsc->client;
-	int ret;
+	u64 orig_src_off = *src_off;
+	u64 orig_dst_off = *dst_off;
+	int num_objects, head = 0, tail = 0, inflight = 0;
+	int first_fail_obj = -1, first_fail_err = 0;
+	int slot, ret;
+	bool have_eopnotsupp = false;
 
 	src_oloc.pool = src_ci->i_layout.pool_id;
 	src_oloc.pool_ns = ceph_try_get_string(src_ci->i_layout.pool_ns);
@@ -2987,54 +3007,145 @@ static ssize_t ceph_do_objects_copy(struct ceph_inode_info *src_ci, u64 *src_off
 	dst_oloc.pool_ns = ceph_try_get_string(dst_ci->i_layout.pool_ns);
 	osdc = &fsc->client->osdc;
 
-	while (len >= object_size) {
-		ceph_calc_file_object_mapping(&src_ci->i_layout, *src_off,
-					      object_size, &src_objnum,
-					      &src_objoff, &src_objlen);
-		ceph_calc_file_object_mapping(&dst_ci->i_layout, *dst_off,
-					      object_size, &dst_objnum,
-					      &dst_objoff, &dst_objlen);
-		ceph_oid_init(&src_oid);
-		ceph_oid_printf(&src_oid, "%llx.%08llx",
-				src_ci->i_vino.ino, src_objnum);
-		ceph_oid_init(&dst_oid);
-		ceph_oid_printf(&dst_oid, "%llx.%08llx",
-				dst_ci->i_vino.ino, dst_objnum);
-		/* Do an object remote copy */
-		req = ceph_alloc_copyfrom_request(osdc, src_ci->i_vino.snap,
-						  &src_oid, &src_oloc,
-						  &dst_oid, &dst_oloc,
-						  dst_ci->i_truncate_seq,
-						  dst_ci->i_truncate_size);
-		if (IS_ERR(req))
-			ret = PTR_ERR(req);
-		else {
+	num_objects = len / object_size;
+	if (!num_objects)
+		goto out;
+
+	reqs = kvmalloc_array(copyfrom_max_inflight, sizeof(*reqs), GFP_KERNEL);
+	if (!reqs) {
+		bytes = -ENOMEM;
+		goto out;
+	}
+
+	/*
+	 * Sliding window: submit requests up to MAX_INFLIGHT, then wait for
+	 * the oldest in-flight request to complete before submitting more.
+	 * The reqs[] ring buffer is indexed by (slot % MAX_INFLIGHT), so
+	 * memory is bounded to MAX_INFLIGHT regardless of num_objects.
+	 * First-failure and EOPNOTSUPP detection happen inline — no post-scan
+	 * needed.
+	 */
+	while (head < num_objects) {
+		/* Submit new requests while the window has room */
+		while (tail < num_objects &&
+		       first_fail_obj == -1 &&
+		       inflight < copyfrom_max_inflight) {
+			u64 object_src_off = orig_src_off +
+					     (u64)tail * object_size;
+			u64 object_dst_off = orig_dst_off +
+					     (u64)tail * object_size;
+
+			ceph_calc_file_object_mapping(&src_ci->i_layout,
+						      object_src_off,
+						      object_size,
+						      &src_objnum,
+						      &src_objoff,
+						      &src_objlen);
+			ceph_calc_file_object_mapping(&dst_ci->i_layout,
+						      object_dst_off,
+						      object_size,
+						      &dst_objnum,
+						      &dst_objoff,
+						      &dst_objlen);
+			ceph_oid_init(&src_oid);
+			ceph_oid_printf(&src_oid, "%llx.%08llx",
+					src_ci->i_vino.ino, src_objnum);
+			ceph_oid_init(&dst_oid);
+			ceph_oid_printf(&dst_oid, "%llx.%08llx",
+					dst_ci->i_vino.ino, dst_objnum);
+
+			/* Do an object remote copy */
+			slot = tail % copyfrom_max_inflight;
+			req = ceph_alloc_copyfrom_request(osdc,
+						src_ci->i_vino.snap,
+						&src_oid, &src_oloc,
+						&dst_oid, &dst_oloc,
+						dst_ci->i_truncate_seq,
+						dst_ci->i_truncate_size);
+			if (IS_ERR(req)) {
+				/*
+				 * Allocation failed: treat as first failure
+				 * and stop submitting.  Drain inflight
+				 * requests to check for EOPNOTSUPP.
+				 */
+				if (first_fail_obj == -1) {
+					first_fail_obj = tail;
+					first_fail_err = PTR_ERR(req);
+				}
+				reqs[slot] = NULL;
+				tail++;
+				continue;
+			}
 			ceph_osdc_start_request(osdc, req);
-			ret = ceph_osdc_wait_request(osdc, req);
+			reqs[slot] = req;
+			tail++;
+			inflight++;
+		}
+
+		/*
+		 * Wait for the oldest in-flight request (FIFO order).
+		 * This is required for correctness: we must determine the
+		 * first failure in object-offset order to know how many
+		 * bytes were successfully copied.  It does not hurt
+		 * performance because all requests in the window are
+		 * submitted concurrently -- later requests complete in
+		 * the background while we wait, so the wall-clock time
+		 * is dominated by the slowest request, not the sum.
+		 */
+		slot = head % copyfrom_max_inflight;
+		if (reqs[slot]) {
+			ret = ceph_osdc_wait_request(osdc, reqs[slot]);
 			ceph_update_copyfrom_metrics(&fsc->mdsc->metric,
-						     req->r_start_latency,
-						     req->r_end_latency,
+						     reqs[slot]->r_start_latency,
+						     reqs[slot]->r_end_latency,
 						     object_size, ret);
-			ceph_osdc_put_request(req);
-		}
-		if (ret) {
-			if (ret == -EOPNOTSUPP) {
-				fsc->have_copy_from2 = false;
-				pr_notice_client(cl,
-					"OSDs don't support copy-from2; disabling copy offload\n");
+			ceph_osdc_put_request(reqs[slot]);
+			inflight--;
+
+			if (ret == -EOPNOTSUPP)
+				have_eopnotsupp = true;
+
+			if (ret < 0 && first_fail_obj == -1) {
+				first_fail_obj = head;
+				first_fail_err = ret;
 			}
-			doutc(cl, "returned %d\n", ret);
-			if (bytes <= 0)
-				bytes = ret;
-			goto out;
+			if (ret)
+				doutc(cl, "object %d returned %d\n", head, ret);
 		}
-		len -= object_size;
-		bytes += object_size;
-		*src_off += object_size;
-		*dst_off += object_size;
+		/*
+		 * If reqs[slot] was NULL, allocation for this object had
+		 * failed earlier; first_fail_obj was already set in the
+		 * submit loop -- just drain past it.
+		 */
+		head++;
 	}
 
+	/*
+	 * Determine bytes copied: all objects before the first failure
+	 * succeeded.  Any objects beyond the truncation point that were
+	 * successfully written by the OSD become unreachable orphans
+	 * (beyond EOF) and are harmless.
+	 */
+	if (first_fail_obj == -1) {
+		bytes = (ssize_t)num_objects * object_size;
+	} else if (first_fail_obj == 0) {
+		bytes = first_fail_err;
+	} else {
+		bytes = (ssize_t)first_fail_obj * object_size;
+	}
+
+	if (have_eopnotsupp) {
+		fsc->have_copy_from2 = false;
+		pr_notice_client(cl,
+			"OSDs don't support copy-from2; disabling copy offload\n");
+	}
+
+	if (bytes > 0) {
+		*src_off = orig_src_off + bytes;
+		*dst_off = orig_dst_off + bytes;
+	}
 out:
+	kvfree(reqs);
 	ceph_oloc_destroy(&src_oloc);
 	ceph_oloc_destroy(&dst_oloc);
 	return bytes;

---
base-commit: fc67edb66b3c9924c4e0bb366a92b32ea13c526a
change-id: 20260720-b4-ceph-copyfrom-c8680b2d6616

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

