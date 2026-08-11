From: Xiubo Li <xiubo.li@clyso.com>
Date: Tue, 11 Aug 2026 13:17:47 +0800
Subject: [PATCH v3 3/5] ceph: add wait_list_lock for wait-list
 serialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-ceph-mdsc-mutex-optimization-v3-3-d031114419f4@clyso.com>
References: <20260811-ceph-mdsc-mutex-optimization-v3-0-d031114419f4@clyso.com>
In-Reply-To: <20260811-ceph-mdsc-mutex-optimization-v3-0-d031114419f4@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786425473; l=4398;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=Jfam+nJ/bsXm8oYLqWWTI70QiKEhx69kaUtydPwxx54=;
 b=LQp0pJADQv7MsFthHxayVOrMsuO4ch5pe4nuh/wfOgGQvmb2M7ipA/R8W0du8qVb0z855SWXe
 q1LhL7FtStKCNkvU8DmgjsFLJkMEz2Ew2fBniy6nieaFZWPg5blTZw/
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The per-MDS session wait list and the global waiting-for-map list
are currently serialized by mdsc->mutex, even though the list
operations themselves don't need the mutex's broader protection.
Introduce a dedicated spinlock to guard these lists so that
waking and kicking waiters can run outside the mutex.

Reviewed-by: Viacheslav Dubeyko <slava@dubeyko.com>
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/mds_client.c | 18 +++++++++++++++++-
 fs/ceph/mds_client.h |  3 +++
 2 files changed, 20 insertions(+), 1 deletion(-)

diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index bf63f5c1fca2..2d2994b4399b 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -3618,7 +3618,9 @@ static void __do_request(struct ceph_mds_client *mdsc,
 			doutc(cl, "no mdsmap, waiting for map\n");
 			trace_ceph_mdsc_suspend_request(mdsc, session, req,
 							ceph_mdsc_suspend_reason_no_mdsmap);
+			spin_lock(&mdsc->wait_list_lock);
 			list_add(&req->r_wait, &mdsc->waiting_for_map);
+			spin_unlock(&mdsc->wait_list_lock);
 			return;
 		}
 		if (!(mdsc->fsc->mount_options->flags &
@@ -3641,7 +3643,9 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		doutc(cl, "no mds or not active, waiting for map\n");
 		trace_ceph_mdsc_suspend_request(mdsc, session, req,
 						ceph_mdsc_suspend_reason_no_active_mds);
+		spin_lock(&mdsc->wait_list_lock);
 		list_add(&req->r_wait, &mdsc->waiting_for_map);
+		spin_unlock(&mdsc->wait_list_lock);
 		return;
 	}
 
@@ -3689,9 +3693,12 @@ static void __do_request(struct ceph_mds_client *mdsc,
 			if (ceph_test_mount_opt(mdsc->fsc, CLEANRECOVER)) {
 				trace_ceph_mdsc_suspend_request(mdsc, session, req,
 								ceph_mdsc_suspend_reason_rejected);
+				spin_lock(&mdsc->wait_list_lock);
 				list_add(&req->r_wait, &mdsc->waiting_for_map);
-			} else
+				spin_unlock(&mdsc->wait_list_lock);
+			} else {
 				err = -EACCES;
+			}
 			goto out_session;
 		}
 
@@ -3706,7 +3713,9 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		}
 		trace_ceph_mdsc_suspend_request(mdsc, session, req,
 						ceph_mdsc_suspend_reason_session);
+		spin_lock(&mdsc->wait_list_lock);
 		list_add(&req->r_wait, &session->s_waiting);
+		spin_unlock(&mdsc->wait_list_lock);
 		goto out_session;
 	}
 
@@ -3799,7 +3808,9 @@ static void __wake_requests(struct ceph_mds_client *mdsc,
 	struct ceph_mds_request *req;
 	LIST_HEAD(tmp_list);
 
+	spin_lock(&mdsc->wait_list_lock);
 	list_splice_init(head, &tmp_list);
+	spin_unlock(&mdsc->wait_list_lock);
 
 	while (!list_empty(&tmp_list)) {
 		req = list_entry(tmp_list.next,
@@ -3832,7 +3843,9 @@ static void kick_requests(struct ceph_mds_client *mdsc, int mds)
 		if (req->r_session &&
 		    req->r_session->s_mds == mds) {
 			doutc(cl, " kicking tid %llu\n", req->r_tid);
+			spin_lock(&mdsc->wait_list_lock);
 			list_del_init(&req->r_wait);
+			spin_unlock(&mdsc->wait_list_lock);
 			trace_ceph_mdsc_resume_request(mdsc, req);
 			__do_request(mdsc, req);
 		}
@@ -6277,6 +6290,7 @@ int ceph_mdsc_init(struct ceph_fs_client *fsc)
 	mdsc->snap_realms = RB_ROOT;
 	INIT_LIST_HEAD(&mdsc->snap_empty);
 	spin_lock_init(&mdsc->snap_empty_lock);
+	spin_lock_init(&mdsc->wait_list_lock);
 	xa_init(&mdsc->request_tree);
 	INIT_DELAYED_WORK(&mdsc->delayed_work, delayed_work);
 	mdsc->last_renew_caps = jiffies;
@@ -6359,7 +6373,9 @@ static void wait_requests(struct ceph_mds_client *mdsc)
 		mutex_lock(&mdsc->mutex);
 		while ((req = __get_oldest_req(mdsc))) {
 			doutc(cl, "timed out on tid %llu\n", req->r_tid);
+			spin_lock(&mdsc->wait_list_lock);
 			list_del_init(&req->r_wait);
+			spin_unlock(&mdsc->wait_list_lock);
 			__unregister_request(mdsc, req);
 		}
 	}
diff --git a/fs/ceph/mds_client.h b/fs/ceph/mds_client.h
index 976dc9ffac17..19d2eae9da5b 100644
--- a/fs/ceph/mds_client.h
+++ b/fs/ceph/mds_client.h
@@ -530,6 +530,9 @@ struct ceph_mds_client {
 	struct list_head        snap_empty;
 	int			num_snap_realms;
 	spinlock_t              snap_empty_lock;  /* protect snap_empty */
+	spinlock_t              wait_list_lock;   /* protect waiting_for_map
+						   * and s_waiting lists
+						   */
 
 	u64                    last_tid;      /* most recent mds request */
 	u64                    oldest_tid;    /* oldest incomplete mds request,

-- 
2.53.0

