From: Xiubo Li <xiubo.li@clyso.com>
Date: Wed, 15 Jul 2026 11:58:44 +0800
Subject: [PATCH v2 4/5] ceph: move mdsc->mutex into __do_request()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260715-ceph-mdsc-mutex-optimization-v2-4-90e81b726724@clyso.com>
References: <20260715-ceph-mdsc-mutex-optimization-v2-0-90e81b726724@clyso.com>
In-Reply-To: <20260715-ceph-mdsc-mutex-optimization-v2-0-90e81b726724@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784087938; l=8538;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=NnDJ68VidiftOOlT17UxoqIitRdN5cgavA36gfJL014=;
 b=REV96JWmxzIeiexTmdhnBzIudmEGj692GmP4M1OEOwZaAhFatZTobX4U8p+UZ1h8EQV74dunt
 5PYZGmjOxPaCHDB+X16Ikd7vzBwPylVuNam99Bo5ZNk3GXt8q2P6YiH
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__do_request() now acquires mdsc->mutex on entry and unlocks at
every exit point, so callers no longer need to hold it.  As a
result kick_requests() is now completely free of mdsc->mutex:
xa_for_each() is internally locked, list_del_init() is guarded by
wait_list_lock, and __do_request() manages its own serialization.

Remove the no-longer-needed mutex_lock/unlock around __do_request()
in ceph_mdsc_submit_request() and handle_forward().  The do_request()
wrapper introduced in the previous commit is no longer necessary
and is dropped.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/mds_client.c | 48 +++++++++++++++++++++++++-----------------------
 1 file changed, 25 insertions(+), 23 deletions(-)

diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index a250938f32d3..be0dae919d69 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -3637,9 +3637,12 @@ static void __do_request(struct ceph_mds_client *mdsc,
 	int err = 0;
 	bool random;
 
+	mutex_lock(&mdsc->mutex);
+
 	if (req->r_err || test_bit(CEPH_MDS_R_GOT_RESULT, &req->r_req_flags)) {
 		if (test_bit(CEPH_MDS_R_ABORTED, &req->r_req_flags))
 			__unregister_request(mdsc, req);
+		mutex_unlock(&mdsc->mutex);
 		return;
 	}
 
@@ -3672,6 +3675,7 @@ static void __do_request(struct ceph_mds_client *mdsc,
 			spin_lock(&mdsc->wait_list_lock);
 			list_add(&req->r_wait, &mdsc->waiting_for_map);
 			spin_unlock(&mdsc->wait_list_lock);
+			mutex_unlock(&mdsc->mutex);
 			return;
 		}
 		if (!(mdsc->fsc->mount_options->flags &
@@ -3697,6 +3701,7 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		spin_lock(&mdsc->wait_list_lock);
 		list_add(&req->r_wait, &mdsc->waiting_for_map);
 		spin_unlock(&mdsc->wait_list_lock);
+		mutex_unlock(&mdsc->mutex);
 		return;
 	}
 
@@ -3770,6 +3775,8 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		goto out_session;
 	}
 
+	mutex_unlock(&mdsc->mutex);
+
 	/* send request */
 	req->r_resend_mds = -1;   /* forget any previous mds hint */
 
@@ -3800,6 +3807,7 @@ static void __do_request(struct ceph_mds_client *mdsc,
 			err = wait_on_bit(&di->flags, CEPH_DENTRY_ASYNC_CREATE_BIT,
 					  TASK_KILLABLE);
 			if (err) {
+				mutex_lock(&mdsc->mutex);
 				mutex_lock(&req->r_fill_mutex);
 				set_bit(CEPH_MDS_R_ABORTED, &req->r_req_flags);
 				mutex_unlock(&req->r_fill_mutex);
@@ -3837,6 +3845,8 @@ static void __do_request(struct ceph_mds_client *mdsc,
 
 	err = __send_request(session, req, false);
 
+	mutex_lock(&mdsc->mutex);
+
 out_session:
 	ceph_put_mds_session(session);
 finish:
@@ -3846,12 +3856,10 @@ static void __do_request(struct ceph_mds_client *mdsc,
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
@@ -3969,11 +3977,12 @@ int ceph_mdsc_submit_request(struct ceph_mds_client *mdsc, struct inode *dir,
 	doutc(cl, "submit_request on %p for inode %p\n", req, dir);
 	mutex_lock(&mdsc->mutex);
 	__register_request(mdsc, req, dir);
+	mutex_unlock(&mdsc->mutex);
+
 	trace_ceph_mdsc_submit_request(mdsc, req);
 	if (!req->r_err)
 		__do_request(mdsc, req);
 	err = req->r_err;
-	mutex_unlock(&mdsc->mutex);
 	return err;
 }
 
@@ -4346,13 +4355,14 @@ static void handle_forward(struct ceph_mds_client *mdsc,
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
 
@@ -4676,11 +4686,9 @@ static void handle_session(struct ceph_mds_session *session,
 
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
@@ -5326,9 +5334,7 @@ static int send_mds_reconnect(struct ceph_mds_client *mdsc,
 
 	mutex_unlock(&session->s_mutex);
 
-	mutex_lock(&mdsc->mutex);
 	__wake_requests(mdsc, &session->s_waiting);
-	mutex_unlock(&mdsc->mutex);
 
 	up_read(&mdsc->snap_rwsem);
 	ceph_pagelist_release(recon_state.pagelist);
@@ -5773,8 +5779,8 @@ static void ceph_mdsc_reset_workfn(struct work_struct *work)
 		}
 		sessions[i]->s_state = CEPH_MDS_SESSION_CLOSED;
 		__unregister_session(mdsc, sessions[i]);
-		__wake_requests(mdsc, &sessions[i]->s_waiting);
 		mutex_unlock(&mdsc->mutex);
+		__wake_requests(mdsc, &sessions[i]->s_waiting);
 
 		mutex_lock(&sessions[i]->s_mutex);
 		cleanup_session_requests(mdsc, sessions[i]);
@@ -5785,9 +5791,7 @@ static void ceph_mdsc_reset_workfn(struct work_struct *work)
 
 		ceph_put_mds_session(sessions[i]);
 
-		mutex_lock(&mdsc->mutex);
 		kick_requests(mdsc, mds);
-		mutex_unlock(&mdsc->mutex);
 
 		torn_down++;
 		pr_info_client(cl, "mds%d session reset complete\n", mds);
@@ -5903,8 +5907,8 @@ static void check_new_map(struct ceph_mds_client *mdsc,
 			/* force close session for stopped mds */
 			ceph_get_mds_session(s);
 			__unregister_session(mdsc, s);
-			__wake_requests(mdsc, &s->s_waiting);
 			mutex_unlock(&mdsc->mutex);
+			__wake_requests(mdsc, &s->s_waiting);
 
 			mutex_lock(&s->s_mutex);
 			cleanup_session_requests(mdsc, s);
@@ -5913,8 +5917,8 @@ static void check_new_map(struct ceph_mds_client *mdsc,
 
 			ceph_put_mds_session(s);
 
-			mutex_lock(&mdsc->mutex);
 			kick_requests(mdsc, i);
+			mutex_lock(&mdsc->mutex);
 			continue;
 		}
 
@@ -5958,8 +5962,8 @@ static void check_new_map(struct ceph_mds_client *mdsc,
 			    oldstate != CEPH_MDS_STATE_STARTING)
 				pr_info_client(cl, "mds%d recovery completed\n",
 					       s->s_mds);
-			kick_requests(mdsc, i);
 			mutex_unlock(&mdsc->mutex);
+			kick_requests(mdsc, i);
 			mutex_lock(&s->s_mutex);
 			mutex_lock(&mdsc->mutex);
 			ceph_kick_flushing_caps(mdsc, s);
@@ -6931,8 +6935,8 @@ void ceph_mdsc_force_umount(struct ceph_mds_client *mdsc)
 
 		if (session->s_state == CEPH_MDS_SESSION_REJECTED)
 			__unregister_session(mdsc, session);
-		__wake_requests(mdsc, &session->s_waiting);
 		mutex_unlock(&mdsc->mutex);
+		__wake_requests(mdsc, &session->s_waiting);
 
 		mutex_lock(&session->s_mutex);
 		__close_session(mdsc, session);
@@ -6943,11 +6947,11 @@ void ceph_mdsc_force_umount(struct ceph_mds_client *mdsc)
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
@@ -7091,8 +7095,8 @@ void ceph_mdsc_handle_fsmap(struct ceph_mds_client *mdsc, struct ceph_msg *msg)
 err_out:
 	mutex_lock(&mdsc->mutex);
 	mdsc->mdsmap_err = err;
-	__wake_requests(mdsc, &mdsc->waiting_for_map);
 	mutex_unlock(&mdsc->mutex);
+	__wake_requests(mdsc, &mdsc->waiting_for_map);
 }
 
 /*
@@ -7143,11 +7147,11 @@ void ceph_mdsc_handle_mdsmap(struct ceph_mds_client *mdsc, struct ceph_msg *msg)
 	mdsc->fsc->max_file_size = min((loff_t)mdsc->mdsmap->m_max_file_size,
 					MAX_LFS_FILESIZE);
 
+	mutex_unlock(&mdsc->mutex);
 	__wake_requests(mdsc, &mdsc->waiting_for_map);
 	ceph_monc_got_map(&mdsc->fsc->client->monc, CEPH_SUB_MDSMAP,
 			  mdsc->mdsmap->m_epoch);
 
-	mutex_unlock(&mdsc->mutex);
 	schedule_delayed(mdsc, 0);
 	return;
 
@@ -7245,8 +7249,8 @@ static void mds_peer_reset(struct ceph_connection *con)
 		ceph_get_mds_session(s);
 		s->s_state = CEPH_MDS_SESSION_CLOSED;
 		__unregister_session(mdsc, s);
-		__wake_requests(mdsc, &s->s_waiting);
 		mutex_unlock(&mdsc->mutex);
+		__wake_requests(mdsc, &s->s_waiting);
 
 		mutex_lock(&s->s_mutex);
 		cleanup_session_requests(mdsc, s);
@@ -7255,9 +7259,7 @@ static void mds_peer_reset(struct ceph_connection *con)
 
 		wake_up_all(&mdsc->session_close_wq);
 
-		mutex_lock(&mdsc->mutex);
 		kick_requests(mdsc, s->s_mds);
-		mutex_unlock(&mdsc->mutex);
 
 		ceph_put_mds_session(s);
 		break;

-- 
2.53.0

