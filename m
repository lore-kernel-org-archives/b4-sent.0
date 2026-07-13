From: Xiubo Li <xiubo.li@clyso.com>
Date: Mon, 13 Jul 2026 17:46:08 +0800
Subject: [PATCH 2/5] ceph: replace the request_tree rbtree with an xarray
 keyed by r_tid.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260713-ceph-mdsc-mutex-optimization-v1-2-9ae5ac135c34@clyso.com>
References: <20260713-ceph-mdsc-mutex-optimization-v1-0-9ae5ac135c34@clyso.com>
In-Reply-To: <20260713-ceph-mdsc-mutex-optimization-v1-0-9ae5ac135c34@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783936018; l=11026;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=E29whNYNjCrjTbCZtl25dlUASbbTF+MPIVTIDSccGrg=;
 b=MAr2v7AyfqWcIKZzMBPymFyNap8LCIyVFryZEeYf0X4uUUtVykIWz4/U6Iz1jSrTWVkMeKmhk
 0sRDqsSCCg+AS/2qhgA8+xA7v7uS8qja3QqfbrhrrDcydaYaUmsnXPT
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The xarray gives O(1) lookups by tid (vs O(log N) rbtree) and
uses internal RCU-based locking, eliminating mdsc->mutex as a
precondition for tree access and paving the way for lockless
xa_load() in the future. Iteration is also cleaner: xa_for_each()
and xa_find() replace the open-coded rb_first()/rb_next() walks.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/debugfs.c    |   6 +--
 fs/ceph/mds_client.c | 109 ++++++++++++++++++++++-----------------------------
 fs/ceph/mds_client.h |   3 +-
 3 files changed, 50 insertions(+), 68 deletions(-)

diff --git a/fs/ceph/debugfs.c b/fs/ceph/debugfs.c
index 18eb5da03411..491ead3fe1c6 100644
--- a/fs/ceph/debugfs.c
+++ b/fs/ceph/debugfs.c
@@ -87,12 +87,12 @@ static int mdsc_show(struct seq_file *s, void *p)
 	struct ceph_fs_client *fsc = s->private;
 	struct ceph_mds_client *mdsc = fsc->mdsc;
 	struct ceph_mds_request *req;
-	struct rb_node *rp;
+	unsigned long idx;
 	char *path;
 
 	mutex_lock(&mdsc->mutex);
-	for (rp = rb_first(&mdsc->request_tree); rp; rp = rb_next(rp)) {
-		req = rb_entry(rp, struct ceph_mds_request, r_node);
+	idx = 0;
+	xa_for_each(&mdsc->request_tree, idx, req) {
 
 		if (req->r_request && req->r_session)
 			seq_printf(s, "%lld\tmds%d\t", req->r_tid,
diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index 98d0a5baff70..909f909b64ed 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -1183,7 +1183,6 @@ void ceph_mdsc_release_request(struct kref *kref)
 	kmem_cache_free(ceph_mds_request_cachep, req);
 }
 
-DEFINE_RB_FUNCS(request, struct ceph_mds_request, r_tid, r_node)
 
 /*
  * lookup session, bump ref if found.
@@ -1195,7 +1194,7 @@ lookup_get_request(struct ceph_mds_client *mdsc, u64 tid)
 {
 	struct ceph_mds_request *req;
 
-	req = lookup_request(&mdsc->request_tree, tid);
+	req = xa_load(&mdsc->request_tree, tid);
 	if (req)
 		ceph_mdsc_get_request(req);
 
@@ -1229,7 +1228,7 @@ static void __register_request(struct ceph_mds_client *mdsc,
 	}
 	doutc(cl, "%p tid %lld\n", req, req->r_tid);
 	ceph_mdsc_get_request(req);
-	insert_request(&mdsc->request_tree, req);
+	xa_store(&mdsc->request_tree, req->r_tid, req, GFP_NOFS);
 
 	req->r_cred = get_current_cred();
 	if (!req->r_mnt_idmap)
@@ -1259,20 +1258,20 @@ static void __unregister_request(struct ceph_mds_client *mdsc,
 	list_del_init(&req->r_unsafe_item);
 
 	if (req->r_tid == atomic64_read(&mdsc->oldest_tid)) {
-		struct rb_node *p = rb_next(&req->r_node);
+		unsigned long tidx = req->r_tid + 1;
+		struct ceph_mds_request *next_req;
+
 		atomic64_set(&mdsc->oldest_tid, 0);
-		while (p) {
-			struct ceph_mds_request *next_req =
-				rb_entry(p, struct ceph_mds_request, r_node);
+		xa_for_each_start(&mdsc->request_tree, tidx, next_req, tidx) {
 			if (next_req->r_op != CEPH_MDS_OP_SETFILELOCK) {
-				atomic64_set(&mdsc->oldest_tid, next_req->r_tid);
+				atomic64_set(&mdsc->oldest_tid,
+					     next_req->r_tid);
 				break;
 			}
-			p = rb_next(p);
 		}
 	}
 
-	erase_request(&mdsc->request_tree, req);
+	xa_erase(&mdsc->request_tree, req->r_tid);
 
 	if (req->r_unsafe_dir) {
 		struct ceph_inode_info *ci = ceph_inode(req->r_unsafe_dir);
@@ -1829,7 +1828,7 @@ static void cleanup_session_requests(struct ceph_mds_client *mdsc,
 {
 	struct ceph_client *cl = mdsc->fsc->client;
 	struct ceph_mds_request *req;
-	struct rb_node *p;
+	unsigned long idx;
 
 	doutc(cl, "mds%d\n", session->s_mds);
 	mutex_lock(&mdsc->mutex);
@@ -1845,10 +1844,8 @@ static void cleanup_session_requests(struct ceph_mds_client *mdsc,
 		__unregister_request(mdsc, req);
 	}
 	/* zero r_attempts, so kick_requests() will re-send requests */
-	p = rb_first(&mdsc->request_tree);
-	while (p) {
-		req = rb_entry(p, struct ceph_mds_request, r_node);
-		p = rb_next(p);
+	idx = 0;
+	xa_for_each(&mdsc->request_tree, idx, req) {
 		if (req->r_session &&
 		    req->r_session->s_mds == session->s_mds)
 			req->r_attempts = 0;
@@ -2732,7 +2729,6 @@ ceph_mdsc_create_request(struct ceph_mds_client *mdsc, int op, int mode)
 	req->r_fmode = -1;
 	req->r_feature_needed = -1;
 	kref_init(&req->r_kref);
-	RB_CLEAR_NODE(&req->r_node);
 	INIT_LIST_HEAD(&req->r_wait);
 	init_completion(&req->r_completion);
 	init_completion(&req->r_safe_completion);
@@ -2752,10 +2748,9 @@ ceph_mdsc_create_request(struct ceph_mds_client *mdsc, int op, int mode)
  */
 static struct ceph_mds_request *__get_oldest_req(struct ceph_mds_client *mdsc)
 {
-	if (RB_EMPTY_ROOT(&mdsc->request_tree))
-		return NULL;
-	return rb_entry(rb_first(&mdsc->request_tree),
-			struct ceph_mds_request, r_node);
+	unsigned long idx = 0;
+
+	return xa_find(&mdsc->request_tree, &idx, ULONG_MAX, XA_PRESENT);
 }
 
 static inline  u64 __get_oldest_tid(struct ceph_mds_client *mdsc)
@@ -3816,12 +3811,11 @@ static void kick_requests(struct ceph_mds_client *mdsc, int mds)
 {
 	struct ceph_client *cl = mdsc->fsc->client;
 	struct ceph_mds_request *req;
-	struct rb_node *p = rb_first(&mdsc->request_tree);
+	unsigned long idx;
 
 	doutc(cl, "kick_requests mds%d\n", mds);
-	while (p) {
-		req = rb_entry(p, struct ceph_mds_request, r_node);
-		p = rb_next(p);
+	idx = 0;
+	xa_for_each(&mdsc->request_tree, idx, req) {
 		if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags))
 			continue;
 		if (req->r_attempts > 0)
@@ -4654,7 +4648,7 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 				   struct ceph_mds_session *session)
 {
 	struct ceph_mds_request *req, *nreq;
-	struct rb_node *p;
+	unsigned long idx;
 
 	doutc(mdsc->fsc->client, "mds%d\n", session->s_mds);
 
@@ -4666,10 +4660,8 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 	 * also re-send old requests when MDS enters reconnect stage. So that MDS
 	 * can process completed request in clientreplay stage.
 	 */
-	p = rb_first(&mdsc->request_tree);
-	while (p) {
-		req = rb_entry(p, struct ceph_mds_request, r_node);
-		p = rb_next(p);
+	idx = 0;
+	xa_for_each(&mdsc->request_tree, idx, req) {
 		if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags))
 			continue;
 		if (req->r_attempts == 0)
@@ -5514,7 +5506,7 @@ static void ceph_mdsc_reset_workfn(struct work_struct *work)
 	 */
 	{
 		struct ceph_mds_request *req;
-		struct rb_node *rn;
+		unsigned long idx;
 		u64 last_tid;
 
 		mutex_lock(&mdsc->mutex);
@@ -5522,14 +5514,12 @@ static void ceph_mdsc_reset_workfn(struct work_struct *work)
 		mutex_unlock(&mdsc->mutex);
 
 		mutex_lock(&mdsc->mutex);
-		rn = rb_first(&mdsc->request_tree);
-		while (rn) {
-			req = rb_entry(rn, struct ceph_mds_request, r_node);
-			if (req->r_tid > last_tid)
-				break;
+		idx = 0;
+		while ((req = xa_find(&mdsc->request_tree, &idx, last_tid,
+				      XA_PRESENT))) {
 			if (req->r_op == CEPH_MDS_OP_SETFILELOCK ||
 			    !(req->r_op & CEPH_MDS_OP_WRITE)) {
-				rn = rb_next(rn);
+				idx++;
 				continue;
 			}
 			ceph_mdsc_get_request(req);
@@ -5542,7 +5532,7 @@ static void ceph_mdsc_reset_workfn(struct work_struct *work)
 			ceph_mdsc_put_request(req);
 			if (time_after(jiffies, drain_deadline))
 				break;
-			rn = rb_first(&mdsc->request_tree);
+			idx = 0;  /* restart: tree may have changed */
 		}
 		mutex_unlock(&mdsc->mutex);
 
@@ -6268,7 +6258,7 @@ int ceph_mdsc_init(struct ceph_fs_client *fsc)
 	mdsc->snap_realms = RB_ROOT;
 	INIT_LIST_HEAD(&mdsc->snap_empty);
 	spin_lock_init(&mdsc->snap_empty_lock);
-	mdsc->request_tree = RB_ROOT;
+	xa_init(&mdsc->request_tree);
 	INIT_DELAYED_WORK(&mdsc->delayed_work, delayed_work);
 	mdsc->last_renew_caps = jiffies;
 	INIT_LIST_HEAD(&mdsc->cap_delay_list);
@@ -6590,34 +6580,33 @@ static void flush_mdlog_and_wait_mdsc_unsafe_requests(struct ceph_mds_client *md
 						 u64 want_tid)
 {
 	struct ceph_client *cl = mdsc->fsc->client;
-	struct ceph_mds_request *req = NULL, *nextreq;
+	struct ceph_mds_request *req;
 	struct ceph_mds_session *last_session = NULL;
-	struct rb_node *n;
+	unsigned long idx;
 
 	mutex_lock(&mdsc->mutex);
 	doutc(cl, "want %lld\n", want_tid);
-restart:
-	req = __get_oldest_req(mdsc);
-	while (req && req->r_tid <= want_tid) {
-		/* find next request */
-		n = rb_next(&req->r_node);
-		if (n)
-			nextreq = rb_entry(n, struct ceph_mds_request, r_node);
-		else
-			nextreq = NULL;
-		if (req->r_op != CEPH_MDS_OP_SETFILELOCK &&
-		    (req->r_op & CEPH_MDS_OP_WRITE)) {
+	idx = 0;
+	while ((req = xa_find(&mdsc->request_tree, &idx, want_tid,
+			      XA_PRESENT))) {
+		u64 next_tid = req->r_tid + 1;
+
+		if (req->r_op == CEPH_MDS_OP_SETFILELOCK ||
+		    !(req->r_op & CEPH_MDS_OP_WRITE)) {
+			idx = next_tid;
+			continue;
+		}
+
+		{
 			struct ceph_mds_session *s = req->r_session;
 
 			if (!s) {
-				req = nextreq;
+				idx = next_tid;
 				continue;
 			}
 
 			/* write op */
 			ceph_mdsc_get_request(req);
-			if (nextreq)
-				ceph_mdsc_get_request(nextreq);
 			s = ceph_get_mds_session(s);
 			mutex_unlock(&mdsc->mutex);
 
@@ -6635,16 +6624,9 @@ static void flush_mdlog_and_wait_mdsc_unsafe_requests(struct ceph_mds_client *md
 
 			mutex_lock(&mdsc->mutex);
 			ceph_mdsc_put_request(req);
-			if (!nextreq)
-				break;  /* next dne before, so we're done! */
-			if (RB_EMPTY_NODE(&nextreq->r_node)) {
-				/* next request was removed from tree */
-				ceph_mdsc_put_request(nextreq);
-				goto restart;
-			}
-			ceph_mdsc_put_request(nextreq);  /* won't go away */
+			/* restart from the next tid; tree may have changed */
+			idx = next_tid;
 		}
-		req = nextreq;
 	}
 	mutex_unlock(&mdsc->mutex);
 	ceph_put_mds_session(last_session);
@@ -6803,6 +6785,7 @@ static void ceph_mdsc_stop(struct ceph_mds_client *mdsc)
 	if (mdsc->mdsmap)
 		ceph_mdsmap_destroy(mdsc->mdsmap);
 	kfree(mdsc->sessions);
+	xa_destroy(&mdsc->request_tree);
 	ceph_caps_finalize(mdsc);
 
 	if (mdsc->s_cap_auths) {
diff --git a/fs/ceph/mds_client.h b/fs/ceph/mds_client.h
index 3b614b5df18c..00ca993ed583 100644
--- a/fs/ceph/mds_client.h
+++ b/fs/ceph/mds_client.h
@@ -329,7 +329,6 @@ typedef int (*ceph_mds_request_wait_callback_t) (struct ceph_mds_client *mdsc,
  */
 struct ceph_mds_request {
 	u64 r_tid;                   /* transaction id */
-	struct rb_node r_node;
 	struct ceph_mds_client *r_mdsc;
 
 	struct kref       r_kref;
@@ -534,7 +533,7 @@ struct ceph_mds_client {
 	u64                    last_tid;      /* most recent mds request */
 	atomic64_t             oldest_tid;    /* oldest incomplete mds request,
 						 excluding setfilelock requests */
-	struct rb_root         request_tree;  /* pending mds requests */
+	struct xarray           request_tree;  /* pending mds requests */
 	struct delayed_work    delayed_work;  /* delayed work */
 	unsigned long    last_renew_caps;  /* last time we renewed our caps */
 	struct list_head cap_delay_list;   /* caps with delayed release */

-- 
2.53.0

