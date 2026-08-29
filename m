From: Xiubo Li <xiubo.li@clyso.com>
Date: Sat, 29 Aug 2026 04:35:05 -0700
Subject: [PATCH v6 5/5] ceph: narrow mdsc->mutex scope in
 replay_unsafe_requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260829-ceph-mdsc-mutex-optimization-v6-5-466936ccbd9d@clyso.com>
References: <20260829-ceph-mdsc-mutex-optimization-v6-0-466936ccbd9d@clyso.com>
In-Reply-To: <20260829-ceph-mdsc-mutex-optimization-v6-0-466936ccbd9d@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788003304; l=20051;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=/EHyoZ7wRER2jIWRnLrnYMw6tSJhevbbtpyXEzZ2iKo=;
 b=f7omZYl6VFVRNV3sykvWGZ6/1+UGyEj/aL87HgRGWy75DhlTxEULUrfW4obSX0GH0VdnEVz6e
 Q7sqt0c9KSrAlQ2masxbVSg0ScdUNmXuBKwiuogRes3f8durZk7022m
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

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/mds_client.c | 311 ++++++++++++++++++++++++++++++++++++++++++++-------
 fs/ceph/mds_client.h |  30 ++++-
 2 files changed, 300 insertions(+), 41 deletions(-)

diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index 0b515df15081..aaf7e11b3d60 100644
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
@@ -3661,37 +3673,58 @@ static void __do_request(struct ceph_mds_client *mdsc,
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
+		clear_bit(CEPH_MDS_R_DISPATCHING, &req->r_req_flags);
+		goto no_dispatch;
+	}
+	if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags)) {
+		/*
+		 * Unsafe requests are replayed only by
+		 * replay_unsafe_requests() during MDS reconnect, never
+		 * through the normal dispatch path.
+		 */
+		clear_bit(CEPH_MDS_R_RESEND, &req->r_req_flags);
+		clear_bit(CEPH_MDS_R_DISPATCHING, &req->r_req_flags);
+		goto no_dispatch;
 	}
 
 	if (READ_ONCE(mdsc->fsc->mount_state) == CEPH_MOUNT_FENCE_IO) {
@@ -3721,10 +3754,10 @@ static void __do_request(struct ceph_mds_client *mdsc,
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
@@ -3747,10 +3780,10 @@ static void __do_request(struct ceph_mds_client *mdsc,
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
@@ -3798,6 +3831,7 @@ static void __do_request(struct ceph_mds_client *mdsc,
 				trace_ceph_mdsc_suspend_request(mdsc, session, req,
 								ceph_mdsc_suspend_reason_rejected);
 				spin_lock(&mdsc->wait_list_lock);
+				list_del_init(&req->r_wait);
 				list_add(&req->r_wait, &mdsc->waiting_for_map);
 				spin_unlock(&mdsc->wait_list_lock);
 			} else {
@@ -3818,6 +3852,7 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		trace_ceph_mdsc_suspend_request(mdsc, session, req,
 						ceph_mdsc_suspend_reason_session);
 		spin_lock(&mdsc->wait_list_lock);
+		list_del_init(&req->r_wait);
 		list_add(&req->r_wait, &session->s_waiting);
 		spin_unlock(&mdsc->wait_list_lock);
 		goto out_session;
@@ -3905,6 +3940,20 @@ static void __do_request(struct ceph_mds_client *mdsc,
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
+	clear_bit(CEPH_MDS_R_DISPATCHING, &req->r_req_flags);
+	if (test_and_clear_bit(CEPH_MDS_R_RESEND, &req->r_req_flags) &&
+	    xa_load(&mdsc->request_tree, req->r_tid) == req) {
+		mutex_unlock(&mdsc->mutex);
+		goto restart;
+	}
+no_dispatch:
 	mutex_unlock(&mdsc->mutex);
 	return;
 }
@@ -3913,22 +3962,68 @@ static void __wake_requests(struct ceph_mds_client *mdsc,
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
@@ -3938,7 +4033,7 @@ static void __wake_requests(struct ceph_mds_client *mdsc,
 static void kick_requests(struct ceph_mds_client *mdsc, int mds)
 {
 	struct ceph_client *cl = mdsc->fsc->client;
-	struct ceph_mds_request *req, *nreq;
+	struct ceph_mds_request *req;
 	unsigned long idx;
 	LIST_HEAD(kick_list);
 
@@ -3958,19 +4053,42 @@ static void kick_requests(struct ceph_mds_client *mdsc, int mds)
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
@@ -4423,6 +4541,15 @@ static void handle_forward(struct ceph_mds_client *mdsc,
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
 
@@ -4812,13 +4939,44 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 {
 	struct ceph_mds_request *req, *nreq;
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
-	list_for_each_entry_safe(req, nreq, &session->s_unsafe, r_unsafe_item)
+	list_for_each_entry_safe(req, nreq, &session->s_unsafe,
+				 r_unsafe_item) {
+		/*
+		 * A non-empty r_aux_item means the request is already
+		 * owned by another dispatch collector; never queue the
+		 * same node twice.  Replay sends __send_request()
+		 * directly, so it must also claim dispatch ownership
+		 * (CEPH_MDS_R_DISPATCHING) to exclude a concurrent
+		 * __do_request() from the send window.
+		 */
+		if (!list_empty(&req->r_aux_item))
+			continue;
+		if (test_and_set_bit(CEPH_MDS_R_DISPATCHING, &req->r_req_flags))
+			continue;
+		/* the replay send below supersedes any pending resend */
+		clear_bit(CEPH_MDS_R_RESEND, &req->r_req_flags);
+		ceph_mdsc_get_request(req);
 		req->r_attempts++;
-		__send_request(session, req, true);
+		/*
+		 * Keep the request on s_unsafe: r_aux_item is only a
+		 * walk list.  The request must stay tracked as unsafe
+		 * until the MDS replies, so that a later reconnect can
+		 * replay it again and cleanup_session_requests() can
+		 * still abort it on session teardown.
+		 */
+		list_add_tail(&req->r_aux_item, &unsafe_list);
+	}
 
 	/*
 	 * also re-send old requests when MDS enters reconnect stage. So that MDS
@@ -4834,11 +4992,83 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 			continue;
 		if (req->r_session->s_mds != session->s_mds)
 			continue;
+		if (!list_empty(&req->r_aux_item))
+			continue;
+		if (test_and_set_bit(CEPH_MDS_R_DISPATCHING, &req->r_req_flags))
+			continue;
+		/* the replay send below supersedes any pending resend */
+		clear_bit(CEPH_MDS_R_RESEND, &req->r_req_flags);
 
-		ceph_mdsc_release_dir_caps_async(req);
-
+		ceph_mdsc_get_request(req);
 		req->r_attempts++;
+		list_add_tail(&req->r_aux_item, &old_list);
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
+
 		__send_request(session, req, true);
+
+		mutex_lock(&mdsc->mutex);
+		clear_bit(CEPH_MDS_R_DISPATCHING, &req->r_req_flags);
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
+		clear_bit(CEPH_MDS_R_DISPATCHING, &req->r_req_flags);
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
@@ -5398,9 +5628,10 @@ static int send_mds_reconnect(struct ceph_mds_client *mdsc,
 
 	mutex_unlock(&session->s_mutex);
 
+	up_read(&mdsc->snap_rwsem);
+
 	__wake_requests(mdsc, &session->s_waiting);
 
-	up_read(&mdsc->snap_rwsem);
 	ceph_pagelist_release(recon_state.pagelist);
 	return 0;
 
diff --git a/fs/ceph/mds_client.h b/fs/ceph/mds_client.h
index 11059678284d..4de4064ab727 100644
--- a/fs/ceph/mds_client.h
+++ b/fs/ceph/mds_client.h
@@ -359,6 +359,28 @@ struct ceph_mds_request {
 #define CEPH_MDS_R_PARENT_LOCKED	(7) /* is r_parent->i_rwsem wlocked? */
 #define CEPH_MDS_R_ASYNC		(8) /* async request */
 #define CEPH_MDS_R_FSCRYPT_FILE		(9) /* must marshal fscrypt_file field */
+/*
+ * A dispatch owner has claimed the right to rebuild and send
+ * req->r_request (__do_request() past the send gate, or
+ * replay_unsafe_requests()).  Set and cleared under mdsc->mutex;
+ * held across the unlocked send window, cleared by the owner when it
+ * re-acquires the mutex and releases ownership.
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
@@ -428,7 +450,13 @@ struct ceph_mds_request {
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

