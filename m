From: Xiubo Li <xiubo.li@clyso.com>
Date: Mon, 13 Jul 2026 17:46:09 +0800
Subject: [PATCH 3/5] ceph: add wait_list_lock for wait-list serialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260713-ceph-mdsc-mutex-optimization-v1-3-9ae5ac135c34@clyso.com>
References: <20260713-ceph-mdsc-mutex-optimization-v1-0-9ae5ac135c34@clyso.com>
In-Reply-To: <20260713-ceph-mdsc-mutex-optimization-v1-0-9ae5ac135c34@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783936018; l=4380;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=J7oEObT3LMGtmwTthR3MugHZb7zCkSg8x13b9qZBoVw=;
 b=pkey4ZKEKkXCwSUEK7FuG5kl8MBucKSAkoT/5SoxxCLNDpm1uI5bvPGe4zon4bCLzeiGOygLh
 fnSovYeLfGbAyf0yf7+H6Ducq0CFW//KTgPS2zKFJ1HC2pweHSTfi8/
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a dedicated spinlock to protect the waiting_for_map and
s_waiting lists, which are currently serialized by mdsc->mutex.
This is a preparatory step for removing mdsc->mutex from the
kick_requests() path: xa_for_each() is internally locked and the
per-request filter checks are lockless, so only list_del_init()
needs external protection.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/mds_client.c | 18 +++++++++++++++++-
 fs/ceph/mds_client.h |  3 +++
 2 files changed, 20 insertions(+), 1 deletion(-)

diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index 909f909b64ed..6f9049148721 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -3609,7 +3609,9 @@ static void __do_request(struct ceph_mds_client *mdsc,
 			doutc(cl, "no mdsmap, waiting for map\n");
 			trace_ceph_mdsc_suspend_request(mdsc, session, req,
 							ceph_mdsc_suspend_reason_no_mdsmap);
+			spin_lock(&mdsc->wait_list_lock);
 			list_add(&req->r_wait, &mdsc->waiting_for_map);
+			spin_unlock(&mdsc->wait_list_lock);
 			return;
 		}
 		if (!(mdsc->fsc->mount_options->flags &
@@ -3632,7 +3634,9 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		doutc(cl, "no mds or not active, waiting for map\n");
 		trace_ceph_mdsc_suspend_request(mdsc, session, req,
 						ceph_mdsc_suspend_reason_no_active_mds);
+		spin_lock(&mdsc->wait_list_lock);
 		list_add(&req->r_wait, &mdsc->waiting_for_map);
+		spin_unlock(&mdsc->wait_list_lock);
 		return;
 	}
 
@@ -3680,9 +3684,12 @@ static void __do_request(struct ceph_mds_client *mdsc,
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
 
@@ -3697,7 +3704,9 @@ static void __do_request(struct ceph_mds_client *mdsc,
 		}
 		trace_ceph_mdsc_suspend_request(mdsc, session, req,
 						ceph_mdsc_suspend_reason_session);
+		spin_lock(&mdsc->wait_list_lock);
 		list_add(&req->r_wait, &session->s_waiting);
+		spin_unlock(&mdsc->wait_list_lock);
 		goto out_session;
 	}
 
@@ -3790,7 +3799,9 @@ static void __wake_requests(struct ceph_mds_client *mdsc,
 	struct ceph_mds_request *req;
 	LIST_HEAD(tmp_list);
 
+	spin_lock(&mdsc->wait_list_lock);
 	list_splice_init(head, &tmp_list);
+	spin_unlock(&mdsc->wait_list_lock);
 
 	while (!list_empty(&tmp_list)) {
 		req = list_entry(tmp_list.next,
@@ -3823,7 +3834,9 @@ static void kick_requests(struct ceph_mds_client *mdsc, int mds)
 		if (req->r_session &&
 		    req->r_session->s_mds == mds) {
 			doutc(cl, " kicking tid %llu\n", req->r_tid);
+			spin_lock(&mdsc->wait_list_lock);
 			list_del_init(&req->r_wait);
+			spin_unlock(&mdsc->wait_list_lock);
 			trace_ceph_mdsc_resume_request(mdsc, req);
 			__do_request(mdsc, req);
 		}
@@ -6258,6 +6271,7 @@ int ceph_mdsc_init(struct ceph_fs_client *fsc)
 	mdsc->snap_realms = RB_ROOT;
 	INIT_LIST_HEAD(&mdsc->snap_empty);
 	spin_lock_init(&mdsc->snap_empty_lock);
+	spin_lock_init(&mdsc->wait_list_lock);
 	xa_init(&mdsc->request_tree);
 	INIT_DELAYED_WORK(&mdsc->delayed_work, delayed_work);
 	mdsc->last_renew_caps = jiffies;
@@ -6340,7 +6354,9 @@ static void wait_requests(struct ceph_mds_client *mdsc)
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
index 00ca993ed583..cd5dacfb42bd 100644
--- a/fs/ceph/mds_client.h
+++ b/fs/ceph/mds_client.h
@@ -529,6 +529,9 @@ struct ceph_mds_client {
 	struct list_head        snap_empty;
 	int			num_snap_realms;
 	spinlock_t              snap_empty_lock;  /* protect snap_empty */
+	spinlock_t              wait_list_lock;   /* protect waiting_for_map
+						   * and s_waiting lists
+						   */
 
 	u64                    last_tid;      /* most recent mds request */
 	atomic64_t             oldest_tid;    /* oldest incomplete mds request,

-- 
2.53.0

