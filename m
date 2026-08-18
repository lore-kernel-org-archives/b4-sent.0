From: Xiubo Li <xiubo.li@clyso.com>
Date: Mon, 17 Aug 2026 18:47:50 -0700
Subject: [PATCH v2] ceph: parallelize object copy in ceph_do_objects_copy()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260817-b4-ceph-copyfrom-v2-1-08029d1ad42a@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0Jm7Zh2Qiq48h6GBQyD1AglLRIJ4
 e62uHf5kvff3yCItxLgmm3gZbHBujECnTLgvh4fgraNDKTIqAspbHJkmXpkN62ddwNyYQrVUGu
 MNhBnk5fOfo7kvfpxeDdP4Tl1ktHbMDu/Hp+LTt6f/KJRY1nnTFS2nRG68WsN7sxugGrf9y9So
 rBhwgAAAA==
X-Change-ID: 20260720-b4-ceph-copyfrom-c8680b2d6616
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787017679; l=13458;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=rFUPV8NCUSzokOzRVuPki87FaVnpiju92Y3nq/X5fy8=;
 b=sXWQyXGEgV7bhuHi83Qp7dcVx3BHr+c8U2dfFmvjLgV9VZAr9V/yxg1fU5HxmDnBNrnNmXEPf
 JXsJfFT4l0WAqoUHFjQCpx8ydDutEEhE1gtvXwYZ8FmFC5x3XXC4c4Z
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The current ceph_do_objects_copy() submits COPY_FROM2 requests serially
(submit-wait-submit-wait), which means the total latency scales linearly
with the number of objects being copied.

Convert to a sliding-window parallel model: submit up to
copyfrom_max_inflight (16) requests concurrently, then wait for them
in FIFO order.  Because all in-flight requests make progress while we
wait for the oldest one, the total wait time is MAX(latency_i) rather
than SUM(latency_i).

Error handling uses a 'truncate at first failure' strategy: results are
scanned in offset order and the copy is truncated at the first failing
object.  Parallel requests may have already written destination objects
past the failure point before the failure is detected; that is only
harmless when the copy starts at or beyond the destination EOF, where
the excess objects end up beyond the new (truncated) EOF and are
unreachable through reads.  Copies into the middle of an existing file
are therefore submitted serially, so they can never modify destination
data past the position implied by the result.

The window size is snapshotted per call so a concurrent sysfs write to
copyfrom_max_inflight cannot shift the window bounds mid-copy, and an
allocation failure is reported only if no earlier in-flight request
failed with a real I/O error.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
Changes in v2:
- Address review comments from Alex Markuze:
- Fix a use-after-free in the drain loop: clear the ring-buffer slot
  after putting the request, and stop draining once all in-flight
  requests have been waited on.
- Snapshot copyfrom_max_inflight once per call (clamped to >= 1) and
  use it for all window bookkeeping, so a concurrent sysfs write can
  no longer shift the window bounds mid-copy.
- Track request-allocation failures separately so they never mask a
  real I/O error from an earlier in-flight request.
- Only parallelize copies that start at or beyond the destination EOF.
  Copies into the middle of an existing file are submitted serially
  (window of 1), so a failed copy can never leave destination objects
  written past the failure point inside the file.  This assumes the
  destination size is stable during the copy: CephFS does not serialize
  concurrent size updates (FILE_WR caps are shared among clients and no
  inode/MDS lock is held across the copies), and concurrent
  modification is outside copy_file_range()'s guarantees.
- Widen the object indices to u64 to avoid overflow for very large
  copies with small object sizes.
- Link to v1: https://patch.msgid.link/20260720-b4-ceph-copyfrom-v1-1-9a4c229df6e2@clyso.com

To: Ilya Dryomov <idryomov@gmail.com>
To: Alex Markuze <amarkuze@redhat.com>
To: Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 fs/ceph/file.c | 242 +++++++++++++++++++++++++++++++++++++++++++++++----------
 1 file changed, 201 insertions(+), 41 deletions(-)

diff --git a/fs/ceph/file.c b/fs/ceph/file.c
index 9d89d7fc1095..d6dfa0473e52 100644
--- a/fs/ceph/file.c
+++ b/fs/ceph/file.c
@@ -2965,6 +2965,22 @@ ceph_alloc_copyfrom_request(struct ceph_osd_client *osdc,
 	return ERR_PTR(ret);
 }
 
+/*
+ * Default maximum number of in-flight COPY_FROM2 requests.  Can be
+ * overridden at module load time or at runtime via sysfs through the
+ * copyfrom_max_inflight parameter.  The value is snapshotted per
+ * copy_file_range call, so a runtime change only affects new copies.
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
@@ -2973,13 +2989,21 @@ static ssize_t ceph_do_objects_copy(struct ceph_inode_info *src_ci, u64 *src_off
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
+	u64 num_objects, head = 0, tail = 0;
+	u64 first_fail_obj = U64_MAX, alloc_fail_obj = U64_MAX;
+	unsigned int max_inflight;
+	int first_fail_err = 0, alloc_fail_err = 0, inflight = 0;
+	int slot, ret;
+	bool have_eopnotsupp = false;
 
 	src_oloc.pool = src_ci->i_layout.pool_id;
 	src_oloc.pool_ns = ceph_try_get_string(src_ci->i_layout.pool_ns);
@@ -2987,54 +3011,190 @@ static ssize_t ceph_do_objects_copy(struct ceph_inode_info *src_ci, u64 *src_off
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
+	/*
+	 * Snapshot the window size once.  A concurrent sysfs write to
+	 * copyfrom_max_inflight must not be able to shift the window bounds
+	 * mid-copy: that would corrupt the ring-buffer bookkeeping and could
+	 * index past reqs[].
+	 *
+	 * Parallel requests can write destination objects beyond the first
+	 * failure before the failure is detected.  That is only harmless
+	 * when the copy starts at or beyond the destination EOF: the excess
+	 * objects end up beyond the new (truncated) EOF and are unreachable
+	 * through reads.  When copying into the middle of an existing file,
+	 * the excess objects would clobber live data on failure, so such
+	 * copies are submitted serially (window of 1).
+	 *
+	 * This assumes the destination size is stable for the duration of
+	 * the copy.  CephFS does not serialize concurrent size updates --
+	 * FILE_WR caps are shared among clients and no inode/MDS lock is
+	 * held across the copies -- but concurrent modification is outside
+	 * copy_file_range()'s guarantees, and the pre-existing serial
+	 * implementation was equally racy in that case.
+	 */
+	max_inflight = copyfrom_max_inflight;
+	if (!max_inflight)
+		max_inflight = 1;
+	if (orig_dst_off < i_size_read(&dst_ci->netfs.inode))
+		max_inflight = 1;
+
+	reqs = kvmalloc_array(max_inflight, sizeof(*reqs), GFP_KERNEL);
+	if (!reqs) {
+		bytes = -ENOMEM;
+		goto out;
+	}
+
+	/*
+	 * Sliding window: submit requests up to max_inflight, then wait for
+	 * the oldest in-flight request to complete before submitting more.
+	 * The reqs[] ring buffer is indexed by (slot % max_inflight), so
+	 * memory is bounded to max_inflight regardless of num_objects.
+	 * First-failure and EOPNOTSUPP detection happen inline — no post-scan
+	 * needed.
+	 */
+	/*
+	 * Drain only the valid window: stop once all in-flight requests are
+	 * waited on (head == tail) and no new submission can follow, instead
+	 * of walking head past the tail over freed/never-filled slots.
+	 */
+	while (head < tail ||
+	       (tail < num_objects &&
+		first_fail_obj == U64_MAX && alloc_fail_obj == U64_MAX)) {
+		/* Submit new requests while the window has room */
+		while (tail < num_objects &&
+		       first_fail_obj == U64_MAX && alloc_fail_obj == U64_MAX &&
+		       inflight < max_inflight) {
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
+			slot = tail % max_inflight;
+			req = ceph_alloc_copyfrom_request(osdc,
+						src_ci->i_vino.snap,
+						&src_oid, &src_oloc,
+						&dst_oid, &dst_oloc,
+						dst_ci->i_truncate_seq,
+						dst_ci->i_truncate_size);
+			if (IS_ERR(req)) {
+				/*
+				 * Remember the allocation failure and stop
+				 * submitting.  In-flight requests may still
+				 * carry a real I/O error for an earlier
+				 * object; the drain loop records it and it
+				 * takes precedence over this failure when the
+				 * result is reported.
+				 */
+				alloc_fail_obj = tail;
+				alloc_fail_err = PTR_ERR(req);
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
+		slot = head % max_inflight;
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
+			reqs[slot] = NULL;
+			inflight--;
+
+			if (ret == -EOPNOTSUPP)
+				have_eopnotsupp = true;
+
+			if (ret < 0 && first_fail_obj == U64_MAX) {
+				first_fail_obj = head;
+				first_fail_err = ret;
 			}
-			doutc(cl, "returned %d\n", ret);
-			if (bytes <= 0)
-				bytes = ret;
-			goto out;
+			if (ret)
+				doutc(cl, "object %llu returned %d\n", head, ret);
 		}
-		len -= object_size;
-		bytes += object_size;
-		*src_off += object_size;
-		*dst_off += object_size;
+		/*
+		 * A NULL slot means the object was never submitted (its
+		 * allocation failed, or submission stopped after a failure)
+		 * or was already drained -- just skip past it.
+		 */
+		head++;
+	}
+
+	/*
+	 * Determine bytes copied: all objects before the first failure
+	 * succeeded.  An allocation failure is only reported if no earlier
+	 * in-flight request failed, so a real I/O error is never masked by
+	 * -ENOMEM.
+	 */
+	if (first_fail_obj == U64_MAX && alloc_fail_obj != U64_MAX) {
+		first_fail_obj = alloc_fail_obj;
+		first_fail_err = alloc_fail_err;
+	}
+	if (first_fail_obj == U64_MAX)
+		bytes = (ssize_t)num_objects * object_size;
+	else if (first_fail_obj == 0)
+		bytes = first_fail_err;
+	else
+		bytes = (ssize_t)first_fail_obj * object_size;
+
+	/*
+	 * Deferred until after the drain loop, but safe: any request
+	 * failure stops new submissions, so no COPY_FROM2 requests are
+	 * sent after EOPNOTSUPP was seen, and the flag is cleared before
+	 * this function returns.
+	 */
+	if (have_eopnotsupp) {
+		fsc->have_copy_from2 = false;
+		pr_notice_client(cl,
+			"OSDs don't support copy-from2; disabling copy offload\n");
 	}
 
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

