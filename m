From: Xiubo Li <xiubo.li@clyso.com>
Date: Mon, 13 Jul 2026 17:46:10 +0800
Subject: [PATCH 4/5] ceph: move mdsc->mutex into __do_request()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260713-ceph-mdsc-mutex-optimization-v1-4-9ae5ac135c34@clyso.com>
References: <20260713-ceph-mdsc-mutex-optimization-v1-0-9ae5ac135c34@clyso.com>
In-Reply-To: <20260713-ceph-mdsc-mutex-optimization-v1-0-9ae5ac135c34@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783936018; l=8374;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=Vu2lxq/ZLSzuATsXBorCwXr4GVDVi48b6ZbdEBHxwoA=;
 b=96kxuKn/PVQ1sqbdtWBrjPKYlnCbrSLLcfdpHc2YkTKav+2ouQfDnpPAv3n45CyouPQUKDqP4
 ZsRM7mQe/nNBwsml6IZzaTii8r1P/+EA0b+6T8jgHyzXlPgify6GpDK
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
 fs/ceph/mds_client.c | 45 +++++++++++++++++++++++++--------------------
 1 file changed, 25 insertions(+), 20 deletions(-)

diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index 6f9049148721..ef54d19ace2a 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -3577,9 +3577,12 @@ static void __do_request(struct ceph_mds_client *mdsc,
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
 
@@ -3612,6 +3615,7 @@ static void __do_request(struct ceph_mds_client *mdsc,
 			spin_lock(&mdsc->wait_list_lock);
 			list_add(&req->r_wait, &mdsc->waiting_for_map);
 			spin_unlock(&mdsc->wait_list_lock);
+			mutex_unlock(&mdsc->mutex);
 			return;
 		}
 		if (!(mdsc->fsc->mount_options->flags &
@@ -3637,6 +3641,7 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		spin_lock(&mdsc->wait_list_lock);
 		list_add(&req->r_wait, &mdsc->waiting_for_map);
 		spin_unlock(&mdsc->wait_list_lock);
+		mutex_unlock(&mdsc->mutex);
 		return;
 	}
 
@@ -3710,6 +3715,8 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		goto out_session;
 	}
 
+	mutex_unlock(&mdsc->mutex);
+
 	/* send request */
 	req->r_resend_mds = -1;   /* forget any previous mds hint */
 
@@ -3740,6 +3747,7 @@ static void __do_request(struct ceph_mds_client *mdsc,
 			err = wait_on_bit(&di->flags, CEPH_DENTRY_ASYNC_CREATE_BIT,
 					  TASK_KILLABLE);
 			if (err) {
+				mutex_lock(&mdsc->mutex);
 				mutex_lock(&req->r_fill_mutex);
 				set_bit(CEPH_MDS_R_ABORTED, &req->r_req_flags);
 				mutex_unlock(&req->r_fill_mutex);
@@ -3777,6 +3785,8 @@ static void __do_request(struct ceph_mds_client *mdsc,
 
 	err = __send_request(session, req, false);
 
+	mutex_lock(&mdsc->mutex);
+
 out_session:
 	ceph_put_mds_session(session);
 finish:
@@ -3786,6 +3796,7 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		complete_request(mdsc, req);
 		__unregister_request(mdsc, req);
 	}
+	mutex_unlock(&mdsc->mutex);
 	return;
 }
 
@@ -3900,10 +3911,11 @@ int ceph_mdsc_submit_request(struct ceph_mds_client *mdsc, struct inode *dir,
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
 
@@ -4276,13 +4288,14 @@ static void handle_forward(struct ceph_mds_client *mdsc,
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
 
@@ -4606,11 +4619,9 @@ static void handle_session(struct ceph_mds_session *session,
 
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
@@ -5245,9 +5256,7 @@ static int send_mds_reconnect(struct ceph_mds_client *mdsc,
 
 	mutex_unlock(&session->s_mutex);
 
-	mutex_lock(&mdsc->mutex);
 	__wake_requests(mdsc, &session->s_waiting);
-	mutex_unlock(&mdsc->mutex);
 
 	up_read(&mdsc->snap_rwsem);
 	ceph_pagelist_release(recon_state.pagelist);
@@ -5672,8 +5681,8 @@ static void ceph_mdsc_reset_workfn(struct work_struct *work)
 		}
 		sessions[i]->s_state = CEPH_MDS_SESSION_CLOSED;
 		__unregister_session(mdsc, sessions[i]);
-		__wake_requests(mdsc, &sessions[i]->s_waiting);
 		mutex_unlock(&mdsc->mutex);
+		__wake_requests(mdsc, &sessions[i]->s_waiting);
 
 		mutex_lock(&sessions[i]->s_mutex);
 		cleanup_session_requests(mdsc, sessions[i]);
@@ -5684,9 +5693,7 @@ static void ceph_mdsc_reset_workfn(struct work_struct *work)
 
 		ceph_put_mds_session(sessions[i]);
 
-		mutex_lock(&mdsc->mutex);
 		kick_requests(mdsc, mds);
-		mutex_unlock(&mdsc->mutex);
 
 		torn_down++;
 		pr_info_client(cl, "mds%d session reset complete\n", mds);
@@ -5802,8 +5809,8 @@ static void check_new_map(struct ceph_mds_client *mdsc,
 			/* force close session for stopped mds */
 			ceph_get_mds_session(s);
 			__unregister_session(mdsc, s);
-			__wake_requests(mdsc, &s->s_waiting);
 			mutex_unlock(&mdsc->mutex);
+			__wake_requests(mdsc, &s->s_waiting);
 
 			mutex_lock(&s->s_mutex);
 			cleanup_session_requests(mdsc, s);
@@ -5812,8 +5819,8 @@ static void check_new_map(struct ceph_mds_client *mdsc,
 
 			ceph_put_mds_session(s);
 
-			mutex_lock(&mdsc->mutex);
 			kick_requests(mdsc, i);
+			mutex_lock(&mdsc->mutex);
 			continue;
 		}
 
@@ -5857,8 +5864,8 @@ static void check_new_map(struct ceph_mds_client *mdsc,
 			    oldstate != CEPH_MDS_STATE_STARTING)
 				pr_info_client(cl, "mds%d recovery completed\n",
 					       s->s_mds);
-			kick_requests(mdsc, i);
 			mutex_unlock(&mdsc->mutex);
+			kick_requests(mdsc, i);
 			mutex_lock(&s->s_mutex);
 			mutex_lock(&mdsc->mutex);
 			ceph_kick_flushing_caps(mdsc, s);
@@ -6766,8 +6773,8 @@ void ceph_mdsc_force_umount(struct ceph_mds_client *mdsc)
 
 		if (session->s_state == CEPH_MDS_SESSION_REJECTED)
 			__unregister_session(mdsc, session);
-		__wake_requests(mdsc, &session->s_waiting);
 		mutex_unlock(&mdsc->mutex);
+		__wake_requests(mdsc, &session->s_waiting);
 
 		mutex_lock(&session->s_mutex);
 		__close_session(mdsc, session);
@@ -6778,11 +6785,11 @@ void ceph_mdsc_force_umount(struct ceph_mds_client *mdsc)
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
@@ -6924,8 +6931,8 @@ void ceph_mdsc_handle_fsmap(struct ceph_mds_client *mdsc, struct ceph_msg *msg)
 err_out:
 	mutex_lock(&mdsc->mutex);
 	mdsc->mdsmap_err = err;
-	__wake_requests(mdsc, &mdsc->waiting_for_map);
 	mutex_unlock(&mdsc->mutex);
+	__wake_requests(mdsc, &mdsc->waiting_for_map);
 }
 
 /*
@@ -6976,11 +6983,11 @@ void ceph_mdsc_handle_mdsmap(struct ceph_mds_client *mdsc, struct ceph_msg *msg)
 	mdsc->fsc->max_file_size = min((loff_t)mdsc->mdsmap->m_max_file_size,
 					MAX_LFS_FILESIZE);
 
+	mutex_unlock(&mdsc->mutex);
 	__wake_requests(mdsc, &mdsc->waiting_for_map);
 	ceph_monc_got_map(&mdsc->fsc->client->monc, CEPH_SUB_MDSMAP,
 			  mdsc->mdsmap->m_epoch);
 
-	mutex_unlock(&mdsc->mutex);
 	schedule_delayed(mdsc, 0);
 	return;
 
@@ -7078,8 +7085,8 @@ static void mds_peer_reset(struct ceph_connection *con)
 		ceph_get_mds_session(s);
 		s->s_state = CEPH_MDS_SESSION_CLOSED;
 		__unregister_session(mdsc, s);
-		__wake_requests(mdsc, &s->s_waiting);
 		mutex_unlock(&mdsc->mutex);
+		__wake_requests(mdsc, &s->s_waiting);
 
 		mutex_lock(&s->s_mutex);
 		cleanup_session_requests(mdsc, s);
@@ -7088,9 +7095,7 @@ static void mds_peer_reset(struct ceph_connection *con)
 
 		wake_up_all(&mdsc->session_close_wq);
 
-		mutex_lock(&mdsc->mutex);
 		kick_requests(mdsc, s->s_mds);
-		mutex_unlock(&mdsc->mutex);
 
 		ceph_put_mds_session(s);
 		break;

-- 
2.53.0

