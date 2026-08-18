From: Xiubo Li <xiubo.li@clyso.com>
Date: Tue, 18 Aug 2026 03:58:11 -0700
Subject: [PATCH v5 4/5] ceph: move mdsc->mutex into __do_request()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260818-ceph-mdsc-mutex-optimization-v5-4-7d335a3a1d0b@clyso.com>
References: <20260818-ceph-mdsc-mutex-optimization-v5-0-7d335a3a1d0b@clyso.com>
In-Reply-To: <20260818-ceph-mdsc-mutex-optimization-v5-0-7d335a3a1d0b@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787050693; l=14134;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=R5iownZcbw5WkgdADYZGNONBbq6M0MX3T8goiqp70mc=;
 b=SCgdHeWrMDrGX2nSGhaEODUXZfoB0R5C+l8QVODs0MNyNpDszqts4l3vFvfH5/H8Ob4SxDEBp
 ACX/qhyh9fDAzViNWgk+/PT63ZXUUPGsLTOP5N4vsN1ZKtUnfmPOou8
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently every caller must hold mdsc->mutex when invoking the
request-send machinery.  Move the mutex acquisition inside
__do_request() so that callers can fire off a request without
first serializing on the global lock.  The mutex is released
before the network send phase and re-acquired only for cleanup,
so dentry traversal and message construction run concurrently
across CPUs.

This is the primary source of the observed 2x stat throughput
improvement: the per-request send path shrinks from hundreds of
microseconds to tens of microseconds once it no longer waits on
the mutex.  Wait-list draining, session-state wake-ups, and
request kicking are reworked to either use the new wait-list
spinlock or collect candidates under the mutex and process them
outside it.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/mds_client.c | 118 +++++++++++++++++++++++++++++++++++----------------
 fs/ceph/mds_client.h |   1 +
 2 files changed, 83 insertions(+), 36 deletions(-)

diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index f35aa194795e..c624f80aa5fd 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -2743,6 +2743,7 @@ ceph_mdsc_create_request(struct ceph_mds_client *mdsc, int op, int mode)
 	init_completion(&req->r_completion);
 	init_completion(&req->r_safe_completion);
 	INIT_LIST_HEAD(&req->r_unsafe_item);
+	INIT_LIST_HEAD(&req->r_aux_item);
 
 	ktime_get_coarse_real_ts64(&req->r_stamp);
 
@@ -3462,20 +3463,23 @@ static int __prepare_send_request(struct ceph_mds_session *session,
 	 * Avoid infinite retrying after overflow. The client will
 	 * increase the retry count and if the MDS is old version,
 	 * so we limit to retry at most 256 times.
+	 *
+	 * r_attempts was already incremented under mdsc->mutex by the
+	 * caller (__do_request or replay_unsafe_requests), so the
+	 * actual retry count is r_attempts - 1 and we skip the check
+	 * on the first dispatch (r_attempts == 1).
 	 */
-	if (req->r_attempts) {
-	       old_max_retry = sizeof_field(struct ceph_mds_request_head,
-					    num_retry);
-	       old_max_retry = 1 << (old_max_retry * BITS_PER_BYTE);
-	       if ((old_version && req->r_attempts >= old_max_retry) ||
-		   ((uint32_t)req->r_attempts >= U32_MAX)) {
+	if (req->r_attempts > 1) {
+		old_max_retry = sizeof_field(struct ceph_mds_request_head,
+					     num_retry);
+		old_max_retry = 1 << (old_max_retry * BITS_PER_BYTE);
+		if ((old_version && (req->r_attempts - 1) >= old_max_retry) ||
+		    ((uint32_t)(req->r_attempts - 1) >= U32_MAX)) {
 			pr_warn_ratelimited_client(cl, "request tid %llu seq overflow\n",
 						   req->r_tid);
 			return -EMULTIHOP;
-	       }
+		}
 	}
-
-	req->r_attempts++;
 	if (req->r_inode) {
 		struct ceph_cap *cap =
 			ceph_get_cap_for_mds(ceph_inode(req->r_inode), mds);
@@ -3587,9 +3591,36 @@ static void __do_request(struct ceph_mds_client *mdsc,
 	int err = 0;
 	bool random;
 
+	mutex_lock(&mdsc->mutex);
+
+	/*
+	 * r_attempts is bumped under mdsc->mutex just before the mutex
+	 * is dropped to send the request, and it is only ever written
+	 * back to 0 by the forward handler or cleanup_session_requests()
+	 * (both under the mutex) before re-dispatching through a new
+	 * __do_request() call.  Consequently, r_attempts > 0 at this
+	 * point always means another __do_request() instance has already
+	 * passed the point of no return for this request, i.e. a racing
+	 * kick_requests() or __wake_requests() picked up the same
+	 * request from the xarray or a wait list and is about to send
+	 * it.  Bail out to prevent a double dispatch.
+	 *
+	 * Note: kick_requests() also filters on r_attempts > 0 during
+	 * its collection pass, but that is a one-time snapshot taken
+	 * under the mutex.  Between that snapshot and the actual
+	 * __do_request() call the mutex is dropped and re-acquired, so
+	 * the protection is not atomic — this per-request gate closes
+	 * the remaining window.
+	 */
+	if (req->r_attempts > 0) {
+		mutex_unlock(&mdsc->mutex);
+		return;
+	}
+
 	if (req->r_err || test_bit(CEPH_MDS_R_GOT_RESULT, &req->r_req_flags)) {
 		if (test_bit(CEPH_MDS_R_ABORTED, &req->r_req_flags))
 			__unregister_request(mdsc, req);
+		mutex_unlock(&mdsc->mutex);
 		return;
 	}
 
@@ -3622,6 +3653,7 @@ static void __do_request(struct ceph_mds_client *mdsc,
 			spin_lock(&mdsc->wait_list_lock);
 			list_add(&req->r_wait, &mdsc->waiting_for_map);
 			spin_unlock(&mdsc->wait_list_lock);
+			mutex_unlock(&mdsc->mutex);
 			return;
 		}
 		if (!(mdsc->fsc->mount_options->flags &
@@ -3647,6 +3679,7 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		spin_lock(&mdsc->wait_list_lock);
 		list_add(&req->r_wait, &mdsc->waiting_for_map);
 		spin_unlock(&mdsc->wait_list_lock);
+		mutex_unlock(&mdsc->mutex);
 		return;
 	}
 
@@ -3720,6 +3753,9 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		goto out_session;
 	}
 
+	req->r_attempts++;
+	mutex_unlock(&mdsc->mutex);
+
 	/* send request */
 	req->r_resend_mds = -1;   /* forget any previous mds hint */
 
@@ -3750,6 +3786,7 @@ static void __do_request(struct ceph_mds_client *mdsc,
 			err = wait_on_bit(&di->flags, CEPH_DENTRY_ASYNC_CREATE_BIT,
 					  TASK_KILLABLE);
 			if (err) {
+				mutex_lock(&mdsc->mutex);
 				mutex_lock(&req->r_fill_mutex);
 				set_bit(CEPH_MDS_R_ABORTED, &req->r_req_flags);
 				mutex_unlock(&req->r_fill_mutex);
@@ -3787,6 +3824,8 @@ static void __do_request(struct ceph_mds_client *mdsc,
 
 	err = __send_request(session, req, false);
 
+	mutex_lock(&mdsc->mutex);
+
 out_session:
 	ceph_put_mds_session(session);
 finish:
@@ -3796,12 +3835,10 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		complete_request(mdsc, req);
 		__unregister_request(mdsc, req);
 	}
+	mutex_unlock(&mdsc->mutex);
 	return;
 }
 
-/*
- * called under mdsc->mutex
- */
 static void __wake_requests(struct ceph_mds_client *mdsc,
 			    struct list_head *head)
 {
@@ -3831,10 +3868,14 @@ static void __wake_requests(struct ceph_mds_client *mdsc,
 static void kick_requests(struct ceph_mds_client *mdsc, int mds)
 {
 	struct ceph_client *cl = mdsc->fsc->client;
-	struct ceph_mds_request *req;
+	struct ceph_mds_request *req, *nreq;
 	unsigned long idx;
+	LIST_HEAD(kick_list);
 
 	doutc(cl, "kick_requests mds%d\n", mds);
+
+	/* collect matching requests under the mutex */
+	mutex_lock(&mdsc->mutex);
 	idx = 0;
 	xa_for_each(&mdsc->request_tree, idx, req) {
 		if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags))
@@ -3843,14 +3884,23 @@ static void kick_requests(struct ceph_mds_client *mdsc, int mds)
 			continue; /* only new requests */
 		if (req->r_session &&
 		    req->r_session->s_mds == mds) {
-			doutc(cl, " kicking tid %llu\n", req->r_tid);
+			ceph_mdsc_get_request(req);
 			spin_lock(&mdsc->wait_list_lock);
 			list_del_init(&req->r_wait);
 			spin_unlock(&mdsc->wait_list_lock);
-			trace_ceph_mdsc_resume_request(mdsc, req);
-			__do_request(mdsc, req);
+			list_add_tail(&req->r_aux_item, &kick_list);
 		}
 	}
+	mutex_unlock(&mdsc->mutex);
+
+	/* replay without the mutex */
+	list_for_each_entry_safe(req, nreq, &kick_list, r_aux_item) {
+		doutc(cl, " kicking tid %llu\n", req->r_tid);
+		trace_ceph_mdsc_resume_request(mdsc, req);
+		list_del_init(&req->r_aux_item);
+		__do_request(mdsc, req);
+		ceph_mdsc_put_request(req);
+	}
 }
 
 int ceph_mdsc_submit_request(struct ceph_mds_client *mdsc, struct inode *dir,
@@ -3910,10 +3960,11 @@ int ceph_mdsc_submit_request(struct ceph_mds_client *mdsc, struct inode *dir,
 	doutc(cl, "submit_request on %p for inode %p\n", req, dir);
 	mutex_lock(&mdsc->mutex);
 	__register_request(mdsc, req, dir);
+	mutex_unlock(&mdsc->mutex);
+
 	trace_ceph_mdsc_submit_request(mdsc, req);
 	__do_request(mdsc, req);
 	err = req->r_err;
-	mutex_unlock(&mdsc->mutex);
 	return err;
 }
 
@@ -4296,13 +4347,14 @@ static void handle_forward(struct ceph_mds_client *mdsc,
 		req->r_num_fwd = fwd_seq;
 		req->r_resend_mds = next_mds;
 		put_request_session(req);
-		__do_request(mdsc, req);
 	}
 	mutex_unlock(&mdsc->mutex);
 
 	/* kick calling process */
 	if (aborted)
 		complete_request(mdsc, req);
+	else if (!test_bit(CEPH_MDS_R_ABORTED, &req->r_req_flags))
+		__do_request(mdsc, req);
 	ceph_mdsc_put_request(req);
 	return;
 
@@ -4626,11 +4678,9 @@ static void handle_session(struct ceph_mds_session *session,
 
 	mutex_unlock(&session->s_mutex);
 	if (wake) {
-		mutex_lock(&mdsc->mutex);
 		__wake_requests(mdsc, &session->s_waiting);
 		if (wake == 2)
 			kick_requests(mdsc, mds);
-		mutex_unlock(&mdsc->mutex);
 	}
 	if (op == CEPH_SESSION_CLOSE)
 		ceph_put_mds_session(session);
@@ -4687,6 +4737,7 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 
 	mutex_lock(&mdsc->mutex);
 	list_for_each_entry_safe(req, nreq, &session->s_unsafe, r_unsafe_item)
+		req->r_attempts++;
 		__send_request(session, req, true);
 
 	/*
@@ -4706,6 +4757,7 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 
 		ceph_mdsc_release_dir_caps_async(req);
 
+		req->r_attempts++;
 		__send_request(session, req, true);
 	}
 	mutex_unlock(&mdsc->mutex);
@@ -5265,9 +5317,7 @@ static int send_mds_reconnect(struct ceph_mds_client *mdsc,
 
 	mutex_unlock(&session->s_mutex);
 
-	mutex_lock(&mdsc->mutex);
 	__wake_requests(mdsc, &session->s_waiting);
-	mutex_unlock(&mdsc->mutex);
 
 	up_read(&mdsc->snap_rwsem);
 	ceph_pagelist_release(recon_state.pagelist);
@@ -5692,8 +5742,8 @@ static void ceph_mdsc_reset_workfn(struct work_struct *work)
 		}
 		sessions[i]->s_state = CEPH_MDS_SESSION_CLOSED;
 		__unregister_session(mdsc, sessions[i]);
-		__wake_requests(mdsc, &sessions[i]->s_waiting);
 		mutex_unlock(&mdsc->mutex);
+		__wake_requests(mdsc, &sessions[i]->s_waiting);
 
 		mutex_lock(&sessions[i]->s_mutex);
 		cleanup_session_requests(mdsc, sessions[i]);
@@ -5704,9 +5754,7 @@ static void ceph_mdsc_reset_workfn(struct work_struct *work)
 
 		ceph_put_mds_session(sessions[i]);
 
-		mutex_lock(&mdsc->mutex);
 		kick_requests(mdsc, mds);
-		mutex_unlock(&mdsc->mutex);
 
 		torn_down++;
 		pr_info_client(cl, "mds%d session reset complete\n", mds);
@@ -5822,8 +5870,8 @@ static void check_new_map(struct ceph_mds_client *mdsc,
 			/* force close session for stopped mds */
 			ceph_get_mds_session(s);
 			__unregister_session(mdsc, s);
-			__wake_requests(mdsc, &s->s_waiting);
 			mutex_unlock(&mdsc->mutex);
+			__wake_requests(mdsc, &s->s_waiting);
 
 			mutex_lock(&s->s_mutex);
 			cleanup_session_requests(mdsc, s);
@@ -5832,8 +5880,8 @@ static void check_new_map(struct ceph_mds_client *mdsc,
 
 			ceph_put_mds_session(s);
 
-			mutex_lock(&mdsc->mutex);
 			kick_requests(mdsc, i);
+			mutex_lock(&mdsc->mutex);
 			continue;
 		}
 
@@ -5877,8 +5925,8 @@ static void check_new_map(struct ceph_mds_client *mdsc,
 			    oldstate != CEPH_MDS_STATE_STARTING)
 				pr_info_client(cl, "mds%d recovery completed\n",
 					       s->s_mds);
-			kick_requests(mdsc, i);
 			mutex_unlock(&mdsc->mutex);
+			kick_requests(mdsc, i);
 			mutex_lock(&s->s_mutex);
 			mutex_lock(&mdsc->mutex);
 			ceph_kick_flushing_caps(mdsc, s);
@@ -6786,8 +6834,8 @@ void ceph_mdsc_force_umount(struct ceph_mds_client *mdsc)
 
 		if (session->s_state == CEPH_MDS_SESSION_REJECTED)
 			__unregister_session(mdsc, session);
-		__wake_requests(mdsc, &session->s_waiting);
 		mutex_unlock(&mdsc->mutex);
+		__wake_requests(mdsc, &session->s_waiting);
 
 		mutex_lock(&session->s_mutex);
 		__close_session(mdsc, session);
@@ -6798,11 +6846,11 @@ void ceph_mdsc_force_umount(struct ceph_mds_client *mdsc)
 		mutex_unlock(&session->s_mutex);
 		ceph_put_mds_session(session);
 
-		mutex_lock(&mdsc->mutex);
 		kick_requests(mdsc, mds);
+		mutex_lock(&mdsc->mutex);
 	}
-	__wake_requests(mdsc, &mdsc->waiting_for_map);
 	mutex_unlock(&mdsc->mutex);
+	__wake_requests(mdsc, &mdsc->waiting_for_map);
 }
 
 static void ceph_mdsc_stop(struct ceph_mds_client *mdsc)
@@ -6944,8 +6992,8 @@ void ceph_mdsc_handle_fsmap(struct ceph_mds_client *mdsc, struct ceph_msg *msg)
 err_out:
 	mutex_lock(&mdsc->mutex);
 	mdsc->mdsmap_err = err;
-	__wake_requests(mdsc, &mdsc->waiting_for_map);
 	mutex_unlock(&mdsc->mutex);
+	__wake_requests(mdsc, &mdsc->waiting_for_map);
 }
 
 /*
@@ -6996,11 +7044,11 @@ void ceph_mdsc_handle_mdsmap(struct ceph_mds_client *mdsc, struct ceph_msg *msg)
 	mdsc->fsc->max_file_size = min((loff_t)mdsc->mdsmap->m_max_file_size,
 					MAX_LFS_FILESIZE);
 
+	mutex_unlock(&mdsc->mutex);
 	__wake_requests(mdsc, &mdsc->waiting_for_map);
 	ceph_monc_got_map(&mdsc->fsc->client->monc, CEPH_SUB_MDSMAP,
 			  mdsc->mdsmap->m_epoch);
 
-	mutex_unlock(&mdsc->mutex);
 	schedule_delayed(mdsc, 0);
 	return;
 
@@ -7098,8 +7146,8 @@ static void mds_peer_reset(struct ceph_connection *con)
 		ceph_get_mds_session(s);
 		s->s_state = CEPH_MDS_SESSION_CLOSED;
 		__unregister_session(mdsc, s);
-		__wake_requests(mdsc, &s->s_waiting);
 		mutex_unlock(&mdsc->mutex);
+		__wake_requests(mdsc, &s->s_waiting);
 
 		mutex_lock(&s->s_mutex);
 		cleanup_session_requests(mdsc, s);
@@ -7108,9 +7156,7 @@ static void mds_peer_reset(struct ceph_connection *con)
 
 		wake_up_all(&mdsc->session_close_wq);
 
-		mutex_lock(&mdsc->mutex);
 		kick_requests(mdsc, s->s_mds);
-		mutex_unlock(&mdsc->mutex);
 
 		ceph_put_mds_session(s);
 		break;
diff --git a/fs/ceph/mds_client.h b/fs/ceph/mds_client.h
index 19d2eae9da5b..ee2e11f1c462 100644
--- a/fs/ceph/mds_client.h
+++ b/fs/ceph/mds_client.h
@@ -427,6 +427,7 @@ struct ceph_mds_request {
 	struct completion r_safe_completion;
 	ceph_mds_request_callback_t r_callback;
 	struct list_head  r_unsafe_item;  /* per-session unsafe list item */
+	struct list_head  r_aux_item;     /* auxiliary local list item */
 
 	long long	  r_dir_release_cnt;
 	long long	  r_dir_ordered_cnt;

-- 
2.53.0

