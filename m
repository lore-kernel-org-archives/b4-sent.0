From: Xiubo Li <xiubo.li@clyso.com>
Date: Thu, 26 Nov 2026 12:06:15 +0100
Subject: [PATCH v8 5/5] ceph: narrow mdsc->mutex scope in
 replay_unsafe_requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261126-ceph-mdsc-mutex-optimization-v8-5-5bb2299ef4ee@clyso.com>
References: <20261126-ceph-mdsc-mutex-optimization-v8-0-5bb2299ef4ee@clyso.com>
In-Reply-To: <20261126-ceph-mdsc-mutex-optimization-v8-0-5bb2299ef4ee@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795691181; l=34238;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=Ok9nY057BYABTIegwJc8NnDnk4z9VAJw8POhOXwEshk=;
 b=8uA3OyFS1owuXvgCRmk6Wq6s/5j/Sn6tl0XtpMtD6Bsgu85ZYHPVCsfRf77DSJgRDljcqIsok
 0i9uZUDGiB1CUnRQnUZT4OOZFkusUifzEWvM0t+SWoNsrBMocRMjsek
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently replay_unsafe_requests() holds mdsc->mutex across the
entire function, including the __send_request() calls.  Since
__send_request() is lockless and the async cap-release helper
schedules deferred work, neither needs the mutex.

Collect the unsafe-list entries and the matching old xarray
entries into local lists under mdsc->mutex, taking a reference on
each, then replay them outside the mutex.  Taking a reference
ensures a concurrent reply handler can complete and unregister a
request without invalidating the local list or the iterator.

Unsafe requests remain on session->s_unsafe; r_aux_item serves
only as a walk-list link.  This keeps them tracked as unsafe
until the MDS replies, so a later reconnect can replay them again
and cleanup_session_requests() can still abort them on session
teardown.

A dispatch owner in __do_request() holds CEPH_MDS_R_DISPATCHING
across its unlocked send window.  If send_mds_reconnect() resets the
session connection inside that window, the message the owner has
already queued is dropped, so replay_unsafe_requests() must not skip
such a request: it waits for the owner to release the bit, then
rescans and replays the request itself.  The owner never takes
session->s_mutex in the send window, so waiting with it held cannot
deadlock.

release_dispatch() runs for every dispatched request with mdsc->mutex
held, so it must not pay for that rare wait.  The replay counts
itself in r_replay_waiters and issues smp_mb__after_atomic() before
it waits; release_dispatch() clears DISPATCHING, issues
smp_mb__after_atomic(), and calls wake_up_bit() only when the count
is nonzero.  Either the waiter sees DISPATCHING clear or the releaser
sees the count raised, so no wake-up is lost, and the common release
is one atomic clear plus a plain read, without the lookup in the
kernel-wide bit_wait_table that wake_up_bit() does.  Only the waiters
change the count, once their wait has returned: an owner may release,
consume a pending RESEND and claim DISPATCHING again before the
waiter has gone to sleep, and the release of that second claim must
still wake it.

cleanup_session_requests() and handle_forward() may rewrite
r_attempts and r_num_fwd under mdsc->mutex while the owner encodes
the message without it, which would put a retry count of 255 (or
0xffffffff) into the request.  The owner therefore copies both into
r_send_attempts and r_send_num_fwd under mdsc->mutex, and
__prepare_send_request() encodes from the copies.  r_resend_mds is
also reset before the mutex is dropped, so that a forward arriving in
the window is not undone.

An owner that consumes CEPH_MDS_R_RESEND re-dispatches the request in
its own context.  For an async create that context can be the
submitting thread, which links the new inode to the dentry only in
ceph_finish_async_create(), after ceph_mdsc_submit_request() returns.
A forward that arrives during the first send must therefore not make
it wait for CEPH_DENTRY_ASYNC_CREATE_BIT, which only it can clear.
ceph_mdsc_submit_request() tells do_request() that it runs in the
submitting thread, and there the resend of an async create whose
inode is not linked yet neither waits nor moves the auth cap:
ceph_finish_async_create() adds the cap on req->r_session, which
already names the new session.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/mds_client.c | 499 +++++++++++++++++++++++++++++++++++++++++++--------
 fs/ceph/mds_client.h |  52 +++++-
 2 files changed, 480 insertions(+), 71 deletions(-)

diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index 6d4182cfa70a..e3c52340ff05 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -1925,12 +1925,24 @@ static void cleanup_session_requests(struct ceph_mds_client *mdsc,
 			mapping_set_error(req->r_unsafe_dir->i_mapping, -EIO);
 		__unregister_request(mdsc, req);
 	}
-	/* zero r_attempts, so kick_requests() will re-send requests */
+	/*
+	 * Zero r_attempts so that the following kick_requests() will
+	 * re-send the request.  If a dispatch owner is currently in the
+	 * send window (CEPH_MDS_R_DISPATCHING set), a concurrent
+	 * kick_requests() could not pick the request up and the resend
+	 * request would be lost; set CEPH_MDS_R_RESEND instead and let
+	 * the owner re-evaluate the request when it releases dispatch
+	 * ownership.
+	 */
 	idx = 0;
 	xa_for_each(&mdsc->request_tree, idx, req) {
 		if (req->r_session &&
-		    req->r_session->s_mds == session->s_mds)
+		    req->r_session->s_mds == session->s_mds) {
 			req->r_attempts = 0;
+			if (test_bit(CEPH_MDS_R_DISPATCHING,
+				     &req->r_req_flags))
+				set_bit(CEPH_MDS_R_RESEND, &req->r_req_flags);
+		}
 	}
 	mutex_unlock(&mdsc->mutex);
 }
@@ -3526,6 +3538,8 @@ static int __prepare_send_request(struct ceph_mds_session *session,
 	struct ceph_mds_request_head *nhead;
 	struct ceph_msg *msg;
 	int flags = 0, old_max_retry;
+	int attempts = req->r_send_attempts;
+	int num_fwd = req->r_send_num_fwd;
 	bool old_version = !test_bit(CEPHFS_FEATURE_32BITS_RETRY_FWD,
 				     &session->s_features);
 
@@ -3535,16 +3549,19 @@ static int __prepare_send_request(struct ceph_mds_session *session,
 	 * so we limit to retry at most 256 times.
 	 *
 	 * r_attempts was already incremented under mdsc->mutex by the
-	 * caller (__do_request or replay_unsafe_requests), so the
-	 * actual retry count is r_attempts - 1 and we skip the check
-	 * on the first dispatch (r_attempts == 1).
+	 * caller (__do_request or replay_unsafe_requests), which also
+	 * copied it to r_send_attempts, so the actual retry count is
+	 * attempts - 1 and we skip the check on the first dispatch
+	 * (attempts == 1).  Use the copy: r_attempts itself may be
+	 * reset concurrently by cleanup_session_requests() or
+	 * handle_forward() while this runs without mdsc->mutex.
 	 */
-	if (req->r_attempts > 1) {
+	if (attempts > 1) {
 		old_max_retry = sizeof_field(struct ceph_mds_request_head,
 					     num_retry);
 		old_max_retry = 1 << (old_max_retry * BITS_PER_BYTE);
-		if ((old_version && (req->r_attempts - 1) >= old_max_retry) ||
-		    ((uint32_t)(req->r_attempts - 1) >= U32_MAX)) {
+		if ((old_version && (attempts - 1) >= old_max_retry) ||
+		    ((uint32_t)(attempts - 1) >= U32_MAX)) {
 			pr_warn_ratelimited_client(cl, "request tid %llu seq overflow\n",
 						   req->r_tid);
 			return -EMULTIHOP;
@@ -3560,7 +3577,7 @@ static int __prepare_send_request(struct ceph_mds_session *session,
 			req->r_sent_on_mseq = -1;
 	}
 	doutc(cl, "%p tid %lld %s (attempt %d)\n", req, req->r_tid,
-	      ceph_mds_op_name(req->r_op), req->r_attempts);
+	      ceph_mds_op_name(req->r_op), attempts);
 
 	if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags)) {
 		void *p;
@@ -3582,10 +3599,10 @@ static int __prepare_send_request(struct ceph_mds_session *session,
 		if (req->r_target_inode)
 			lhead->ino = cpu_to_le64(ceph_ino(req->r_target_inode));
 
-		lhead->num_retry = req->r_attempts - 1;
+		lhead->num_retry = attempts - 1;
 		if (!old_version) {
 			nhead = (struct ceph_mds_request_head*)msg->front.iov_base;
-			nhead->ext_num_retry = cpu_to_le32(req->r_attempts - 1);
+			nhead->ext_num_retry = cpu_to_le32(attempts - 1);
 		}
 
 		/* remove cap/dentry releases from message */
@@ -3620,12 +3637,12 @@ static int __prepare_send_request(struct ceph_mds_session *session,
 	if (req->r_parent)
 		flags |= CEPH_MDS_FLAG_WANT_DENTRY;
 	lhead->flags = cpu_to_le32(flags);
-	lhead->num_fwd = req->r_num_fwd;
-	lhead->num_retry = req->r_attempts - 1;
+	lhead->num_fwd = num_fwd;
+	lhead->num_retry = attempts - 1;
 	if (!old_version) {
 		nhead = (struct ceph_mds_request_head*)msg->front.iov_base;
-		nhead->ext_num_fwd = cpu_to_le32(req->r_num_fwd);
-		nhead->ext_num_retry = cpu_to_le32(req->r_attempts - 1);
+		nhead->ext_num_fwd = cpu_to_le32(num_fwd);
+		nhead->ext_num_retry = cpu_to_le32(attempts - 1);
 	}
 
 	doutc(cl, " r_parent = %p\n", req->r_parent);
@@ -3649,11 +3666,38 @@ static int __send_request(struct ceph_mds_session *session,
 	return err;
 }
 
+/*
+ * Release dispatch ownership of @req and wake up anyone waiting for
+ * it: replay_unsafe_requests() waits for an in-flight dispatch to
+ * finish before it replays the request itself.
+ */
+static void release_dispatch(struct ceph_mds_request *req)
+{
+	clear_bit_unlock(CEPH_MDS_R_DISPATCHING, &req->r_req_flags);
+	/*
+	 * Pairs with smp_mb__after_atomic() in replay_unsafe_requests():
+	 * either the waiter sees DISPATCHING clear, or this sees
+	 * r_replay_waiters raised and wakes it up.  The plain read keeps
+	 * the common, no-waiter path free of the shared bit_wait_table.
+	 * r_replay_waiters is left for the waiters to drop: a waiter that
+	 * has not gone to sleep yet when this dispatch is followed by a
+	 * new claim (a consumed CEPH_MDS_R_RESEND) must still be woken by
+	 * the next release.  wake_up_bit() wakes every waiter, since
+	 * wait_on_bit() waiters are not exclusive.
+	 */
+	smp_mb__after_atomic();
+	if (atomic_read(&req->r_replay_waiters))
+		wake_up_bit(&req->r_req_flags, CEPH_MDS_R_DISPATCHING);
+}
+
 /*
  * send request, or put it on the appropriate wait list.
+ *
+ * @submitter is true when called from ceph_mdsc_submit_request(), in
+ * the thread that submits @req.
  */
-static void __do_request(struct ceph_mds_client *mdsc,
-			struct ceph_mds_request *req)
+static void do_request(struct ceph_mds_client *mdsc,
+		       struct ceph_mds_request *req, bool submitter)
 {
 	struct ceph_client *cl = mdsc->fsc->client;
 	struct ceph_mds_session *session = NULL;
@@ -3661,37 +3705,58 @@ static void __do_request(struct ceph_mds_client *mdsc,
 	int err = 0;
 	bool random;
 
+restart:
+	/* re-entry from the resend loop below: reset per-pass state */
+	session = NULL;
+	err = 0;
 	mutex_lock(&mdsc->mutex);
 
 	/*
-	 * r_attempts is bumped under mdsc->mutex just before the mutex
-	 * is dropped to send the request, and it is only ever written
-	 * back to 0 by the forward handler or cleanup_session_requests()
-	 * (both under the mutex) before re-dispatching through a new
-	 * __do_request() call.  Consequently, r_attempts > 0 at this
-	 * point always means another __do_request() instance has already
-	 * passed the point of no return for this request, i.e. a racing
-	 * kick_requests() or __wake_requests() picked up the same
-	 * request from the xarray or a wait list and is about to send
-	 * it.  Bail out to prevent a double dispatch.
+	 * r_attempts only counts protocol send attempts now.  Dispatch
+	 * ownership is claimed separately via CEPH_MDS_R_DISPATCHING
+	 * under mdsc->mutex and held across the unlocked prepare/send
+	 * window: only one context may rebuild and send req->r_request
+	 * at a time.  A racing kick_requests() or __wake_requests()
+	 * that sees the claim set simply drops the request here.
 	 *
-	 * Note: kick_requests() also filters on r_attempts > 0 during
-	 * its collection pass, but that is a one-time snapshot taken
-	 * under the mutex.  Between that snapshot and the actual
-	 * __do_request() call the mutex is dropped and re-acquired, so
-	 * the protection is not atomic — this per-request gate closes
-	 * the remaining window.
+	 * cleanup_session_requests() and handle_forward() may zero
+	 * r_attempts while the owner is in flight; instead of racing,
+	 * they set CEPH_MDS_R_RESEND and the owner consumes it when
+	 * releasing ownership below.
 	 */
-	if (req->r_attempts > 0) {
+	if (test_and_set_bit(CEPH_MDS_R_DISPATCHING, &req->r_req_flags)) {
 		mutex_unlock(&mdsc->mutex);
 		return;
 	}
+	/*
+	 * Claiming dispatch ownership supersedes any pending resend
+	 * request: the dispatch about to happen below is the
+	 * re-evaluation.  RESEND set later, while the send window is
+	 * open, is consumed by the release path at the bottom.
+	 */
+	clear_bit(CEPH_MDS_R_RESEND, &req->r_req_flags);
 
 	if (req->r_err || test_bit(CEPH_MDS_R_GOT_RESULT, &req->r_req_flags)) {
 		if (test_bit(CEPH_MDS_R_ABORTED, &req->r_req_flags))
 			__unregister_request(mdsc, req);
-		mutex_unlock(&mdsc->mutex);
-		return;
+		/*
+		 * The request is done (or dead) and must not be sent
+		 * again; the dispatch ownership claimed above is simply
+		 * released, consuming any pending resend request with it.
+		 */
+		clear_bit(CEPH_MDS_R_RESEND, &req->r_req_flags);
+		release_dispatch(req);
+		goto no_dispatch;
+	}
+	if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags)) {
+		/*
+		 * Unsafe requests are replayed only by
+		 * replay_unsafe_requests() during MDS reconnect, never
+		 * through the normal dispatch path.
+		 */
+		clear_bit(CEPH_MDS_R_RESEND, &req->r_req_flags);
+		release_dispatch(req);
+		goto no_dispatch;
 	}
 
 	if (READ_ONCE(mdsc->fsc->mount_state) == CEPH_MOUNT_FENCE_IO) {
@@ -3721,10 +3786,10 @@ static void __do_request(struct ceph_mds_client *mdsc,
 			trace_ceph_mdsc_suspend_request(mdsc, session, req,
 							ceph_mdsc_suspend_reason_no_mdsmap);
 			spin_lock(&mdsc->wait_list_lock);
+			list_del_init(&req->r_wait);
 			list_add(&req->r_wait, &mdsc->waiting_for_map);
 			spin_unlock(&mdsc->wait_list_lock);
-			mutex_unlock(&mdsc->mutex);
-			return;
+			goto out_session;
 		}
 		if (!(mdsc->fsc->mount_options->flags &
 		      CEPH_MOUNT_OPT_MOUNTWAIT) &&
@@ -3747,10 +3812,10 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		trace_ceph_mdsc_suspend_request(mdsc, session, req,
 						ceph_mdsc_suspend_reason_no_active_mds);
 		spin_lock(&mdsc->wait_list_lock);
+		list_del_init(&req->r_wait);
 		list_add(&req->r_wait, &mdsc->waiting_for_map);
 		spin_unlock(&mdsc->wait_list_lock);
-		mutex_unlock(&mdsc->mutex);
-		return;
+		goto out_session;
 	}
 
 	/* get, open session */
@@ -3798,6 +3863,7 @@ static void __do_request(struct ceph_mds_client *mdsc,
 				trace_ceph_mdsc_suspend_request(mdsc, session, req,
 								ceph_mdsc_suspend_reason_rejected);
 				spin_lock(&mdsc->wait_list_lock);
+				list_del_init(&req->r_wait);
 				list_add(&req->r_wait, &mdsc->waiting_for_map);
 				spin_unlock(&mdsc->wait_list_lock);
 			} else {
@@ -3818,17 +3884,26 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		trace_ceph_mdsc_suspend_request(mdsc, session, req,
 						ceph_mdsc_suspend_reason_session);
 		spin_lock(&mdsc->wait_list_lock);
+		list_del_init(&req->r_wait);
 		list_add(&req->r_wait, &session->s_waiting);
 		spin_unlock(&mdsc->wait_list_lock);
 		goto out_session;
 	}
 
+	/*
+	 * Everything that handle_forward() and cleanup_session_requests()
+	 * may rewrite under mdsc->mutex while the send window is open is
+	 * read or reset here, before the mutex is dropped: a forward
+	 * that arrives in the window sets a new r_resend_mds and
+	 * CEPH_MDS_R_RESEND, and must not be undone by this dispatch.
+	 */
 	req->r_attempts++;
+	req->r_send_attempts = req->r_attempts;
+	req->r_send_num_fwd = req->r_num_fwd;
+	req->r_resend_mds = -1;   /* forget any previous mds hint */
 	mutex_unlock(&mdsc->mutex);
 
 	/* send request */
-	req->r_resend_mds = -1;   /* forget any previous mds hint */
-
 	if (req->r_request_started == 0)   /* note request start time */
 		req->r_request_started = jiffies;
 
@@ -3839,8 +3914,20 @@ static void __do_request(struct ceph_mds_client *mdsc,
 	 * it the request will be forwarded.
 	 *
 	 * And then the auth cap will be changed.
+	 *
+	 * The submitting thread gets here with a nonzero forward count
+	 * only when a forward arrived while its first send was in flight
+	 * and it consumed CEPH_MDS_R_RESEND.  The new inode is linked to
+	 * the dentry by ceph_finish_async_create(), which this thread runs
+	 * only after ceph_mdsc_submit_request() returns, so it must not
+	 * wait for CEPH_DENTRY_ASYNC_CREATE_BIT.  There is no auth cap to
+	 * move yet either: ceph_finish_async_create() adds it on
+	 * req->r_session, which this pass has already switched to the
+	 * new session.
 	 */
-	if (test_bit(CEPH_MDS_R_ASYNC, &req->r_req_flags) && req->r_num_fwd) {
+	if (test_bit(CEPH_MDS_R_ASYNC, &req->r_req_flags) &&
+	    req->r_send_num_fwd &&
+	    !(submitter && !d_inode(req->r_dentry))) {
 		struct ceph_dentry_info *di = ceph_dentry(req->r_dentry);
 		struct ceph_inode_info *ci;
 		struct ceph_cap *cap;
@@ -3905,30 +3992,96 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		complete_request(mdsc, req);
 		__unregister_request(mdsc, req);
 	}
+	/*
+	 * Release dispatch ownership.  If a session teardown or a
+	 * forward observed this request while the mutex was dropped
+	 * above, it set CEPH_MDS_R_RESEND under the mutex: consume it
+	 * here and re-evaluate, unless the request has already been
+	 * unregistered (error path above, or a racing reply).
+	 */
+	release_dispatch(req);
+	if (test_and_clear_bit(CEPH_MDS_R_RESEND, &req->r_req_flags) &&
+	    xa_load(&mdsc->request_tree, req->r_tid) == req) {
+		mutex_unlock(&mdsc->mutex);
+		goto restart;
+	}
+no_dispatch:
 	mutex_unlock(&mdsc->mutex);
 	return;
 }
 
+static void __do_request(struct ceph_mds_client *mdsc,
+			 struct ceph_mds_request *req)
+{
+	do_request(mdsc, req, false);
+}
+
 static void __wake_requests(struct ceph_mds_client *mdsc,
 			    struct list_head *head)
 {
 	struct ceph_client *cl = mdsc->fsc->client;
-	struct ceph_mds_request *req;
-	LIST_HEAD(tmp_list);
+	struct ceph_mds_request *req, *nreq;
+	LIST_HEAD(wake_list);
 
+	/*
+	 * Serialize the splice against the park decision in
+	 * __do_request(): both take mdsc->mutex, so a request cannot
+	 * be parked on @head after we have drained it, and everything
+	 * parked before we take the mutex is moved here.
+	 */
+	mutex_lock(&mdsc->mutex);
 	spin_lock(&mdsc->wait_list_lock);
-	list_splice_init(head, &tmp_list);
+	list_for_each_entry_safe(req, nreq, head, r_wait) {
+		/*
+		 * A non-empty r_aux_item means the request is already
+		 * owned by another dispatch collector (kick_requests()
+		 * or replay_unsafe_requests()); let it be dispatched by
+		 * that collector.  No stale waiter can result: a
+		 * kick-owned request was already delinked from r_wait
+		 * at claim time, and a replay-owned request is never on
+		 * a wait list (s_unsafe requests carry GOT_UNSAFE,
+		 * which __do_request() refuses to park, and replay's
+		 * old-request scan only takes r_attempts > 0 while
+		 * parked requests always have r_attempts == 0).
+		 */
+		if (!list_empty(&req->r_aux_item))
+			continue;
+		list_del_init(&req->r_wait);
+		/*
+		 * Pin the request in the same critical section that
+		 * delinks it from the wait list: once r_wait is
+		 * delinked, no list still owns it, so the reference
+		 * keeps the object alive while it is dispatched.
+		 */
+		ceph_mdsc_get_request(req);
+		list_add_tail(&req->r_aux_item, &wake_list);
+	}
 	spin_unlock(&mdsc->wait_list_lock);
+	mutex_unlock(&mdsc->mutex);
+
+	/*
+	 * Dispatch without holding the locks, but pop each node under
+	 * mdsc->mutex: r_aux_item doubles as the collector-ownership
+	 * predicate, so every access to it (collector list_empty()
+	 * checks and these pops) must be serialized by the mutex to
+	 * avoid a real data race on the node.
+	 */
+	mutex_lock(&mdsc->mutex);
+	while (!list_empty(&wake_list)) {
+		req = list_first_entry(&wake_list, struct ceph_mds_request,
+				       r_aux_item);
+		list_del_init(&req->r_aux_item);
+		mutex_unlock(&mdsc->mutex);
 
-	while (!list_empty(&tmp_list)) {
-		req = list_entry(tmp_list.next,
-				 struct ceph_mds_request, r_wait);
-		list_del_init(&req->r_wait);
 		doutc(cl, " wake request %p tid %llu\n", req,
 		      req->r_tid);
 		trace_ceph_mdsc_resume_request(mdsc, req);
 		__do_request(mdsc, req);
+		ceph_mdsc_put_request(req);
+
+		mutex_lock(&mdsc->mutex);
 	}
+	mutex_unlock(&mdsc->mutex);
 }
 
 /*
@@ -3938,7 +4091,7 @@ static void __wake_requests(struct ceph_mds_client *mdsc,
 static void kick_requests(struct ceph_mds_client *mdsc, int mds)
 {
 	struct ceph_client *cl = mdsc->fsc->client;
-	struct ceph_mds_request *req, *nreq;
+	struct ceph_mds_request *req;
 	unsigned long idx;
 	LIST_HEAD(kick_list);
 
@@ -3958,19 +4111,42 @@ static void kick_requests(struct ceph_mds_client *mdsc, int mds)
 			spin_lock(&mdsc->wait_list_lock);
 			list_del_init(&req->r_wait);
 			spin_unlock(&mdsc->wait_list_lock);
+			/*
+			 * A non-empty r_aux_item means the request is
+			 * already owned by another dispatch collector
+			 * (__wake_requests() or replay_unsafe_requests());
+			 * never queue the same node twice.
+			 */
+			if (!list_empty(&req->r_aux_item)) {
+				ceph_mdsc_put_request(req);
+				continue;
+			}
 			list_add_tail(&req->r_aux_item, &kick_list);
 		}
 	}
 	mutex_unlock(&mdsc->mutex);
 
 	/* replay without the mutex */
-	list_for_each_entry_safe(req, nreq, &kick_list, r_aux_item) {
+	/*
+	 * Same as __wake_requests(): r_aux_item is the collector-ownership
+	 * predicate, so pops are done under mdsc->mutex; the dispatch
+	 * itself runs outside the locks.
+	 */
+	mutex_lock(&mdsc->mutex);
+	while (!list_empty(&kick_list)) {
+		req = list_first_entry(&kick_list, struct ceph_mds_request,
+				       r_aux_item);
+		list_del_init(&req->r_aux_item);
+		mutex_unlock(&mdsc->mutex);
+
 		doutc(cl, " kicking tid %llu\n", req->r_tid);
 		trace_ceph_mdsc_resume_request(mdsc, req);
-		list_del_init(&req->r_aux_item);
 		__do_request(mdsc, req);
 		ceph_mdsc_put_request(req);
+
+		mutex_lock(&mdsc->mutex);
 	}
+	mutex_unlock(&mdsc->mutex);
 }
 
 int ceph_mdsc_submit_request(struct ceph_mds_client *mdsc, struct inode *dir,
@@ -4033,7 +4209,7 @@ int ceph_mdsc_submit_request(struct ceph_mds_client *mdsc, struct inode *dir,
 	mutex_unlock(&mdsc->mutex);
 
 	trace_ceph_mdsc_submit_request(mdsc, req);
-	__do_request(mdsc, req);
+	do_request(mdsc, req, true);
 	err = req->r_err;
 	return err;
 }
@@ -4423,6 +4599,15 @@ static void handle_forward(struct ceph_mds_client *mdsc,
 		req->r_num_fwd = fwd_seq;
 		req->r_resend_mds = next_mds;
 		put_request_session(req);
+		/*
+		 * If a dispatch owner is in the send window, the
+		 * __do_request() below cannot claim the request and the
+		 * forward would be lost; set CEPH_MDS_R_RESEND so that
+		 * the owner re-evaluates the request when it releases
+		 * dispatch ownership.
+		 */
+		if (test_bit(CEPH_MDS_R_DISPATCHING, &req->r_req_flags))
+			set_bit(CEPH_MDS_R_RESEND, &req->r_req_flags);
 	}
 	mutex_unlock(&mdsc->mutex);
 
@@ -4804,21 +4989,86 @@ void ceph_mdsc_release_dir_caps_async(struct ceph_mds_request *req)
 	}
 }
 
+enum {
+	REPLAY_SKIP,		/* already queued by a collector */
+	REPLAY_QUEUED,		/* claimed and queued on the replay list */
+	REPLAY_BUSY,		/* a dispatch owner is in its send window */
+};
+
+/*
+ * Claim dispatch ownership of @req for a replay and queue it on @list.
+ * Called under mdsc->mutex.
+ */
+static int replay_claim_request(struct ceph_mds_client *mdsc,
+				struct ceph_mds_request *req,
+				struct list_head *list)
+{
+	lockdep_assert_held(&mdsc->mutex);
+
+	/*
+	 * A non-empty r_aux_item means the request is already owned by
+	 * a dispatch collector: either this replay queued it on an
+	 * earlier pass, or kick_requests()/__wake_requests() hold it and
+	 * will run it through __do_request(), which parks it on
+	 * s_waiting while the session is reconnecting.
+	 */
+	if (!list_empty(&req->r_aux_item))
+		return REPLAY_SKIP;
+	/*
+	 * Replay sends __send_request() directly, so it must claim
+	 * dispatch ownership to exclude a concurrent __do_request()
+	 * from the send window.  If another context holds it, the
+	 * caller waits for it to be released and rescans: skipping the
+	 * request would lose it when that dispatch had already queued
+	 * its message on the connection this reconnect has just reset.
+	 */
+	if (test_and_set_bit(CEPH_MDS_R_DISPATCHING, &req->r_req_flags))
+		return REPLAY_BUSY;
+	/* the replay send below supersedes any pending resend */
+	clear_bit(CEPH_MDS_R_RESEND, &req->r_req_flags);
+	ceph_mdsc_get_request(req);
+	req->r_attempts++;
+	req->r_send_attempts = req->r_attempts;
+	req->r_send_num_fwd = req->r_num_fwd;
+	list_add_tail(&req->r_aux_item, list);
+	return REPLAY_QUEUED;
+}
+
 /*
  * called under session->mutex.
  */
 static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 				   struct ceph_mds_session *session)
 {
-	struct ceph_mds_request *req, *nreq;
+	struct ceph_mds_request *req, *nreq, *busy;
 	unsigned long idx;
+	LIST_HEAD(unsafe_list);
+	LIST_HEAD(old_list);
 
 	doutc(mdsc->fsc->client, "mds%d\n", session->s_mds);
 
+	/*
+	 * Collect unsafe and old requests under mdsc->mutex, then
+	 * replay them without it: __send_request() is lockless and
+	 * ceph_mdsc_release_dir_caps_async() schedules work.
+	 */
 	mutex_lock(&mdsc->mutex);
-	list_for_each_entry_safe(req, nreq, &session->s_unsafe, r_unsafe_item) {
-		req->r_attempts++;
-		__send_request(session, req, true);
+rescan:
+	busy = NULL;
+	list_for_each_entry_safe(req, nreq, &session->s_unsafe,
+				 r_unsafe_item) {
+		/*
+		 * Keep the request on s_unsafe: r_aux_item is only a
+		 * walk list.  The request must stay tracked as unsafe
+		 * until the MDS replies, so that a later reconnect can
+		 * replay it again and cleanup_session_requests() can
+		 * still abort it on session teardown.
+		 */
+		if (replay_claim_request(mdsc, req, &unsafe_list) ==
+		    REPLAY_BUSY) {
+			busy = req;
+			break;
+		}
 	}
 
 	/*
@@ -4826,20 +5076,128 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 	 * can process completed request in clientreplay stage.
 	 */
 	idx = 0;
-	xa_for_each(&mdsc->request_tree, idx, req) {
-		if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags))
-			continue;
-		if (req->r_attempts == 0)
-			continue; /* only old requests */
-		if (!req->r_session)
-			continue;
-		if (req->r_session->s_mds != session->s_mds)
-			continue;
+	if (!busy) {
+		xa_for_each(&mdsc->request_tree, idx, req) {
+			if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags))
+				continue;
+			if (req->r_attempts == 0)
+				continue; /* only old requests */
+			if (!req->r_session)
+				continue;
+			if (req->r_session->s_mds != session->s_mds)
+				continue;
+			if (replay_claim_request(mdsc, req, &old_list) ==
+			    REPLAY_BUSY) {
+				busy = req;
+				break;
+			}
+		}
+	}
 
-		ceph_mdsc_release_dir_caps_async(req);
+	if (busy) {
+		/*
+		 * Wait for the owner to leave its send window, then scan
+		 * again: the request may have been answered, forwarded,
+		 * parked or unregistered meanwhile, and the lists may
+		 * have changed while mdsc->mutex was dropped.  Requests
+		 * already claimed above stay queued (their r_aux_item is
+		 * set, so the rescan skips them).  The owner does not
+		 * take session->s_mutex in its send window, so waiting
+		 * here with it held cannot deadlock.  A later
+		 * __do_request() sees CEPH_MDS_SESSION_RECONNECTING and
+		 * only parks the request on s_waiting.
+		 */
+		ceph_mdsc_get_request(busy);
+		mutex_unlock(&mdsc->mutex);
+		doutc(mdsc->fsc->client, "mds%d waiting for tid %llu\n",
+		      session->s_mds, busy->r_tid);
+		/*
+		 * Ask release_dispatch() for a wake-up.  The count stays
+		 * raised until this waiter has seen the bit clear, so a
+		 * release that comes before the waiter sleeps and is
+		 * followed by a new claim does not use up the wake-up:
+		 * the next release wakes it again.
+		 */
+		atomic_inc(&busy->r_replay_waiters);
+		/*
+		 * Order the count before the DISPATCHING test in
+		 * wait_on_bit(); pairs with smp_mb__after_atomic() in
+		 * release_dispatch().
+		 */
+		smp_mb__after_atomic();
+		wait_on_bit(&busy->r_req_flags, CEPH_MDS_R_DISPATCHING,
+			    TASK_UNINTERRUPTIBLE);
+		atomic_dec(&busy->r_replay_waiters);
+		ceph_mdsc_put_request(busy);
+		mutex_lock(&mdsc->mutex);
+		goto rescan;
+	}
+
+	mutex_unlock(&mdsc->mutex);
+
+	/*
+	 * Same as __wake_requests(): r_aux_item is the
+	 * collector-ownership predicate, so every access to it (the
+	 * list_empty() checks in the collectors above and these pops)
+	 * is serialized by mdsc->mutex.  The send itself runs outside
+	 * the locks.
+	 */
+
+	/* replay unsafe requests */
+	mutex_lock(&mdsc->mutex);
+	while (!list_empty(&unsafe_list)) {
+		bool resend;
+
+		req = list_first_entry(&unsafe_list, struct ceph_mds_request,
+				       r_aux_item);
+		list_del_init(&req->r_aux_item);
+		mutex_unlock(&mdsc->mutex);
 
-		req->r_attempts++;
 		__send_request(session, req, true);
+
+		mutex_lock(&mdsc->mutex);
+		release_dispatch(req);
+		resend = test_and_clear_bit(CEPH_MDS_R_RESEND, &req->r_req_flags);
+		mutex_unlock(&mdsc->mutex);
+		/*
+		 * A teardown or forward may have requested a re-evaluation
+		 * while this replay send was in flight.  Re-dispatch
+		 * through the normal path, which claims dispatch ownership
+		 * itself: if the request has become unsafe meanwhile,
+		 * __do_request() sees GOT_UNSAFE and bails out, leaving
+		 * the request queued for the next replay; otherwise it is
+		 * sent again normally.
+		 */
+		if (resend)
+			__do_request(mdsc, req);
+		ceph_mdsc_put_request(req);
+
+		mutex_lock(&mdsc->mutex);
+	}
+	mutex_unlock(&mdsc->mutex);
+
+	/* replay old requests */
+	mutex_lock(&mdsc->mutex);
+	while (!list_empty(&old_list)) {
+		bool resend;
+
+		req = list_first_entry(&old_list, struct ceph_mds_request,
+				       r_aux_item);
+		list_del_init(&req->r_aux_item);
+		mutex_unlock(&mdsc->mutex);
+
+		ceph_mdsc_release_dir_caps_async(req);
+		__send_request(session, req, true);
+
+		mutex_lock(&mdsc->mutex);
+		release_dispatch(req);
+		resend = test_and_clear_bit(CEPH_MDS_R_RESEND, &req->r_req_flags);
+		mutex_unlock(&mdsc->mutex);
+		if (resend)
+			__do_request(mdsc, req);
+		ceph_mdsc_put_request(req);
+
+		mutex_lock(&mdsc->mutex);
 	}
 	mutex_unlock(&mdsc->mutex);
 }
@@ -5399,9 +5757,10 @@ static int send_mds_reconnect(struct ceph_mds_client *mdsc,
 
 	mutex_unlock(&session->s_mutex);
 
+	up_read(&mdsc->snap_rwsem);
+
 	__wake_requests(mdsc, &session->s_waiting);
 
-	up_read(&mdsc->snap_rwsem);
 	ceph_pagelist_release(recon_state.pagelist);
 	return 0;
 
diff --git a/fs/ceph/mds_client.h b/fs/ceph/mds_client.h
index 11059678284d..0cdaf5b6d45e 100644
--- a/fs/ceph/mds_client.h
+++ b/fs/ceph/mds_client.h
@@ -359,6 +359,31 @@ struct ceph_mds_request {
 #define CEPH_MDS_R_PARENT_LOCKED	(7) /* is r_parent->i_rwsem wlocked? */
 #define CEPH_MDS_R_ASYNC		(8) /* async request */
 #define CEPH_MDS_R_FSCRYPT_FILE		(9) /* must marshal fscrypt_file field */
+/*
+ * A dispatch owner has claimed the right to rebuild and send
+ * req->r_request (__do_request() past the send gate, or
+ * replay_unsafe_requests()).  Set and cleared under mdsc->mutex;
+ * held across the unlocked send window, cleared by the owner when it
+ * re-acquires the mutex and releases ownership.  Release it with
+ * release_dispatch(): replay_unsafe_requests() waits for it with
+ * wait_on_bit() instead of skipping a request in flight, and flags
+ * the wait in r_replay_waiters.
+ */
+#define CEPH_MDS_R_DISPATCHING		(10)
+/*
+ * Another context observed a session/request state change while a
+ * dispatch owner was in flight and wants a re-evaluation.  It is a
+ * request to re-evaluate, not a guarantee that a resend is still
+ * needed.
+ *
+ * If RESEND is set while DISPATCHING is held, the current dispatcher
+ * consumes it on release and redispatches.
+ * If RESEND is set after DISPATCHING has been cleared, the producer
+ * must itself trigger a redispatch: cleanup_session_requests() is
+ * followed by kick_requests(), while handle_forward() calls
+ * __do_request() directly.
+ */
+#define CEPH_MDS_R_RESEND		(11)
 	unsigned long	r_req_flags;
 
 	struct mutex r_fill_mutex;
@@ -420,6 +445,25 @@ struct ceph_mds_request {
 	int               r_attempts;   /* resend attempts */
 	int               r_num_fwd;    /* number of forward attempts */
 	int               r_resend_mds; /* mds to resend to next, if any*/
+	/*
+	 * Copies of r_attempts and r_num_fwd taken under mdsc->mutex by
+	 * the dispatch owner when it claims a send.  The owner encodes
+	 * the message from these in the unlocked send window, while
+	 * cleanup_session_requests() and handle_forward() may rewrite
+	 * r_attempts and r_num_fwd under mdsc->mutex.  Written and read
+	 * only by the CEPH_MDS_R_DISPATCHING owner.
+	 */
+	int               r_send_attempts;
+	int               r_send_num_fwd;
+	/*
+	 * Number of replay_unsafe_requests() callers waiting for
+	 * CEPH_MDS_R_DISPATCHING to be released.  Lets release_dispatch()
+	 * skip wake_up_bit(), and its lookup in the shared bit_wait_table,
+	 * in the common case where nobody waits.  Changed only by the
+	 * waiters, so it stays raised across a release that is followed
+	 * by a new claim, and the next release still wakes them up.
+	 */
+	atomic_t          r_replay_waiters;
 	u32               r_sent_on_mseq; /* cap mseq request was sent at*/
 	u64		  r_deleg_ino;
 
@@ -428,7 +472,13 @@ struct ceph_mds_request {
 	struct completion r_safe_completion;
 	ceph_mds_request_callback_t r_callback;
 	struct list_head  r_unsafe_item;  /* per-session unsafe list item */
-	struct list_head  r_aux_item;     /* auxiliary local list item */
+	/*
+	 * Auxiliary walk list for the dispatch collectors; doubles as
+	 * the collector-ownership token.  INIT_LIST_HEAD() is done
+	 * before publication; afterwards, all accesses are serialized
+	 * by mdsc->mutex.
+	 */
+	struct list_head  r_aux_item;
 
 	long long	  r_dir_release_cnt;
 	long long	  r_dir_ordered_cnt;

-- 
2.53.0

