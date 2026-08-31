From: Xiubo Li <xiubo.li@clyso.com>
Date: Mon, 31 Aug 2026 00:01:39 -0700
Subject: [PATCH v4] ceph: parallelize object copy in ceph_do_objects_copy()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260831-b4-ceph-copyfrom-v4-1-3841c930bb31@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33OTQ7CIBAF4KsY1mJgSpC68h7GBT9Ti1FpoBIb0
 7sLutAY4/Il730zd5Iwekxks7iTiNknHy4liOWC2F5fDki9K5kAA8nWwKgR1OLQUxuGqYvhTK2
 SihlwUnJJymyI2Pnbk9ztXzldzRHtWJ3a6H0aQ5yeNzOvvT985pTTVgsL0LpOImztaUphZcOZV
 D7DG1B8/QOAAjDFypxrJ0B/A80HAPIH0NQPjEGjQLdasU9gnucHHXha0EQBAAA=
X-Change-ID: 20260720-b4-ceph-copyfrom-c8680b2d6616
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788159698; l=19252;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=kaMLHAyLuRg+j9xPAP25mQSE6s6ZFgoJnQjGbnIt30k=;
 b=/VDEVA95n65muytJL7p1FxkI6wGIPr4MVWO2592Ax9LUZMbBMnNTB8u4TdunV2h2iZqU37XqT
 tMP5nO89f5mDPmXnyHdW7BhzuASnnh1MputM5YZm5XfOgCOmSLdrAeH
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

Error handling uses a 'truncate at first failure' strategy: requests are
completed and results are processed in offset order, and the copy is
truncated at the first failing object.  Parallel requests may have
already written destination objects past the failure point before the
failure is detected; on failure the truncate seq/size is bumped to the
published EOF, so the OSDs discard those speculative writes before any
future read or write can expose them.  That is only safe when the copy
starts at or beyond the destination EOF, because the truncate must not
discard data that was already in the file past the copied range; copies
into the middle of an existing file are therefore submitted serially,
so they can never modify destination data past the position implied by
the result.

The window size is snapshotted per call so a concurrent sysfs write to
copyfrom_max_inflight cannot shift the window bounds mid-copy, and an
allocation failure is reported only if no earlier in-flight request
failed with a real I/O error.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
Testing:

A 44-check functional + fault-injection suite was run on a vstart
cluster (mount -o copyfrom; this kernel defaults to nocopyfrom):

- parallel success, window sweep 1/2/4/8/16/32/64 (ring-buffer reuse and
  window > num_objects), window=0 clamp, 66M copy with trailing partial
  object via splice;
- fault injection (debug-only module params, not part of the patch):
  first-object failure -> error and EOF unchanged; mid-copy failure ->
  only the successful prefix is published; speculative writes past the
  failure point are discarded on subsequent reads/writes (reads of the
  stale region return zeros after the file grows past it);
  allocation-failure handling stops submission; a real I/O error beats
  an allocation failure; sparse dst_off > EOF total failure keeps the
  old EOF and the pre-existing hole;
- middle-of-file copies are serialized: success and injected failure
  leave all data outside the copied prefix intact (no truncate_seq bump
  discards pre-existing data);
- concurrent sysfs churn of copyfrom_max_inflight while copying (window
  snapshotted per call): 8 copies intact, no splats;
- EOPNOTSUPP fallback: copy-from2 disabled for the mount lifetime,
  subsequent copies fall back to splice, metric counter frozen;
- perf: 128M (32 objects) serial best 3.5s vs parallel best 1.6s.
---
Changes in v4:
- Fix the 32-bit build break reported by Ilya: replace tail/head %
  max_inflight with div_u64_rem() when indexing the reqs[] ring buffer
  (u64 % u32 pulled in libgcc __umoddi3 on 32-bit).
- Address Alex's NACK: on first failure in parallel mode, bump
  i_truncate_seq and set i_truncate_size to the published EOF (partial
  copy: orig_dst_off + first_fail_obj * object_size, exactly what the
  caller publishes via ceph_inode_set_size(); total failure: the
  orig_dst_size snapshot taken at entry).  This replaces the previous
  per-object truncate of speculative writes.  orig_dst_size is now
  snapshotted once at entry and used for both the parallel-mode gate and
  the truncate boundary.
- READ_ONCE() the copyfrom_max_inflight snapshot.
- Found and fixed during testing: the failure path marked FILE_WR dirty
  and flushed caps, consuming the caller's preallocated cap flush; the
  caller's subsequent __ceph_mark_dirty_caps() then re-dirtied the caps
  with no preallocated flush at hand, tripping
  BUG_ON(!ci->i_prealloc_cap_flush) in __mark_caps_flushing() when the
  file was closed.  The failure path now only bumps truncate_seq/size
  under i_ceph_lock; the caller's existing set_size + mark_dirty + flush
  machinery handles publication for partial copies, and total failures
  need no flush at all.
- Link to v3: https://patch.msgid.link/20260826-b4-ceph-copyfrom-v3-1-9bbeb82a9a80@clyso.com

Changes in v3:
- use div_u64_rem() instead of direct 64-bit modulo when computing
  the reqs[] ring-buffer slot, fixing the 32-bit build (modpost:
  "__umoddi3" undefined) reported by Ilya
- Link to v2: https://patch.msgid.link/20260817-b4-ceph-copyfrom-v2-1-08029d1ad42a@clyso.com

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
 fs/ceph/file.c | 291 ++++++++++++++++++++++++++++++++++++++++++++++++---------
 1 file changed, 249 insertions(+), 42 deletions(-)

diff --git a/fs/ceph/file.c b/fs/ceph/file.c
index d5606456dbd5..371b481f9303 100644
--- a/fs/ceph/file.c
+++ b/fs/ceph/file.c
@@ -12,6 +12,7 @@
 #include <linux/falloc.h>
 #include <linux/iversion.h>
 #include <linux/ktime.h>
+#include <linux/math64.h>
 #include <linux/splice.h>
 
 #include "super.h"
@@ -3000,6 +3001,22 @@ ceph_alloc_copyfrom_request(struct ceph_osd_client *osdc,
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
@@ -3008,13 +3025,24 @@ static ssize_t ceph_do_objects_copy(struct ceph_inode_info *src_ci, u64 *src_off
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
+	u64 orig_src_off = *src_off;
+	u64 orig_dst_off = *dst_off;
+	u64 orig_dst_size = i_size_read(&dst_ci->netfs.inode);
+	u64 num_objects, head = 0, tail = 0;
+	u64 first_fail_obj = U64_MAX, alloc_fail_obj = U64_MAX;
+	unsigned int max_inflight;
+	int first_fail_err = 0, alloc_fail_err = 0;
+	unsigned int inflight = 0;
+	u32 slot, rem;
 	int ret;
+	bool have_eopnotsupp = false;
 
 	src_oloc.pool = src_ci->i_layout.pool_id;
 	src_oloc.pool_ns = ceph_try_get_string(src_ci->i_layout.pool_ns);
@@ -3022,54 +3050,233 @@ static ssize_t ceph_do_objects_copy(struct ceph_inode_info *src_ci, u64 *src_off
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
-				ceph_ino(&src_ci->netfs.inode), src_objnum);
-		ceph_oid_init(&dst_oid);
-		ceph_oid_printf(&dst_oid, "%llx.%08llx",
-				ceph_ino(&dst_ci->netfs.inode), dst_objnum);
-		/* Do an object remote copy */
-		req = ceph_alloc_copyfrom_request(osdc, ceph_snap(&src_ci->netfs.inode),
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
+	 * failure before the failure is detected.  Those objects lie beyond
+	 * the result that will be published, but they would become visible
+	 * if the file later grows past that point, so on failure the
+	 * truncate seq/size is bumped to the published EOF: the OSDs then
+	 * discard the speculative data before any future read or write can
+	 * expose it.  That is only safe when the copy starts at or beyond
+	 * the original destination EOF (orig_dst_size), because the
+	 * truncate must not discard data that was already in the file past
+	 * the copied range.  When copying
+	 * into the middle of an existing file, the excess objects would
+	 * clobber live data on failure with no way to undo it, so such
+	 * copies are submitted serially (window of 1).
+	 *
+	 * This assumes the destination size is stable for the duration of
+	 * the copy.  CephFS does not serialize concurrent size updates --
+	 * FILE_WR caps are shared among clients and no inode/MDS lock is
+	 * held across the copies -- but concurrent modification is outside
+	 * copy_file_range()'s guarantees, and the pre-existing serial
+	 * implementation was equally racy in that case.
+	 */
+	max_inflight = READ_ONCE(copyfrom_max_inflight);
+	if (!max_inflight)
+		max_inflight = 1;
+	if (orig_dst_off < orig_dst_size)
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
+	 * tail is one past the last submitted object and head the oldest
+	 * object not yet drained, so every object in [head, tail) has a
+	 * live request in its slot: the loop simply stops at head == tail
+	 * once submission can no longer continue.  Requests already in
+	 * the window are drained before returning.
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
+					ceph_ino(&src_ci->netfs.inode),
+					src_objnum);
+			ceph_oid_init(&dst_oid);
+			ceph_oid_printf(&dst_oid, "%llx.%08llx",
+					ceph_ino(&dst_ci->netfs.inode),
+					dst_objnum);
+
+			/* Do an object remote copy */
+			div_u64_rem(tail, max_inflight, &rem);
+			slot = rem;
+			req = ceph_alloc_copyfrom_request(osdc,
+						ceph_snap(&src_ci->netfs.inode),
+						&src_oid, &src_oloc,
+						&dst_oid, &dst_oloc,
+						dst_ci->i_truncate_seq,
+						dst_ci->i_truncate_size);
+			if (IS_ERR(req)) {
+				/*
+				 * Remember the allocation failure and stop
+				 * submitting.  The failed object does not
+				 * enter the ring: tail stays one past the
+				 * last submitted object.  In-flight
+				 * requests may still carry a real I/O
+				 * error for an earlier object; the drain
+				 * loop records it and it takes precedence
+				 * over this failure when the result is
+				 * reported.
+				 */
+				alloc_fail_obj = tail;
+				alloc_fail_err = PTR_ERR(req);
+				break;
+			}
 			ceph_osdc_start_request(osdc, req);
-			ret = ceph_osdc_wait_request(osdc, req);
-			ceph_update_copyfrom_metrics(&fsc->mdsc->metric,
-						     req->r_start_latency,
-						     req->r_end_latency,
-						     object_size, ret);
-			ceph_osdc_put_request(req);
+			reqs[slot] = req;
+			tail++;
+			inflight++;
 		}
-		if (ret) {
-			if (ret == -EOPNOTSUPP) {
-				fsc->have_copy_from2 = false;
-				pr_notice_client(cl,
-					"OSDs don't support copy-from2; disabling copy offload\n");
-			}
-			doutc(cl, "returned %d\n", ret);
-			if (bytes <= 0)
-				bytes = ret;
-			goto out;
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
+		div_u64_rem(head, max_inflight, &rem);
+		slot = rem;
+		ret = ceph_osdc_wait_request(osdc, reqs[slot]);
+		ceph_update_copyfrom_metrics(&fsc->mdsc->metric,
+					     reqs[slot]->r_start_latency,
+					     reqs[slot]->r_end_latency,
+					     object_size, ret);
+		ceph_osdc_put_request(reqs[slot]);
+		reqs[slot] = NULL;
+		inflight--;
+
+		if (ret == -EOPNOTSUPP)
+			have_eopnotsupp = true;
+
+		if (ret < 0 && first_fail_obj == U64_MAX) {
+			first_fail_obj = head;
+			first_fail_err = ret;
 		}
-		len -= object_size;
-		bytes += object_size;
-		*src_off += object_size;
-		*dst_off += object_size;
+		if (ret)
+			doutc(cl, "object %llu returned %d\n", head, ret);
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
+
+	/*
+	 * For parallel copies the destination starts at or beyond the
+	 * original EOF, so on failure all speculative writes are at or
+	 * beyond the published EOF.  Bump truncate_seq and set
+	 * truncate_size to that published EOF so the OSDs discard those
+	 * writes before any read or write can expose them: the seq
+	 * travels with every future OSD op.  For a partial copy the
+	 * published EOF is the start of the first failed object, which
+	 * the caller publishes through ceph_inode_set_size(); for a
+	 * total failure it remains orig_dst_size.  Middle-of-file copies
+	 * are serialized and never leave such stray objects, and must
+	 * not bump truncate_seq: a boundary below their unchanged EOF
+	 * would discard pre-existing data.
+	 *
+	 * Do not mark the caps dirty or flush them here.  For a partial
+	 * copy the caller marks FILE_WR dirty with its preallocated cap
+	 * flush right after publishing the new size; dirtying here first
+	 * would consume that flush (ceph_check_caps() swaps it out via
+	 * __mark_caps_flushing()), leaving the caller to re-dirty the
+	 * caps with no preallocated flush at hand, which BUG()s later in
+	 * __mark_caps_flushing().  For a total failure no flush is
+	 * needed at all: the file size is unchanged and the truncate seq
+	 * rides along with every future OSD op.
+	 */
+	if (max_inflight > 1 && first_fail_obj != U64_MAX) {
+		u64 truncate_size;
+
+		if (first_fail_obj == 0)
+			truncate_size = orig_dst_size;
+		else
+			truncate_size = orig_dst_off +
+					first_fail_obj * object_size;
+
+		spin_lock(&dst_ci->i_ceph_lock);
+		dst_ci->i_truncate_size = truncate_size;
+		dst_ci->i_truncate_seq++;
+		spin_unlock(&dst_ci->i_ceph_lock);
 	}
 
+	if (first_fail_obj == U64_MAX)
+		bytes = (ssize_t)num_objects * object_size;
+	else if (first_fail_obj == 0)
+		bytes = first_fail_err;
+	else
+		bytes = (ssize_t)first_fail_obj * object_size;
+
+	/*
+	 * Deferred until after the drain loop, but safe: once EOPNOTSUPP
+	 * is observed no further requests are submitted, and requests
+	 * already in the window are drained before this function returns.
+	 * The flag is cleared here, so no COPY_FROM2 request can be sent
+	 * against it afterwards.
+	 */
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
base-commit: dee30ce1286a0d18b14545ecac345e4cf4a80511
change-id: 20260720-b4-ceph-copyfrom-c8680b2d6616

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

