From: Xiubo Li <xiubo.li@clyso.com>
Date: Wed, 15 Jul 2026 11:58:42 +0800
Subject: [PATCH v2 2/5] ceph: replace the request_tree rbtree with an
 xarray keyed by r_tid.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260715-ceph-mdsc-mutex-optimization-v2-2-90e81b726724@clyso.com>
References: <20260715-ceph-mdsc-mutex-optimization-v2-0-90e81b726724@clyso.com>
In-Reply-To: <20260715-ceph-mdsc-mutex-optimization-v2-0-90e81b726724@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784087938; l=13290;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=ukIc8+P1kl6gNpJzkfIpt3Q/+/0Seg+CITm/bgW4ghs=;
 b=VVsqLPQizoZ5TQVfkZI67wx8uyZPJH+xBPpa4YXNZix7aSw3+v1ADLL3B+JXjKBn3rXbYdxXk
 stGGslxi/wZCFd6GeUUZ5FHZajk90qTQJ2DR7AljKexXFDwE/U0P4xN
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The xarray gives O(1) lookups by tid (vs O(log N) rbtree) and
uses internal RCU-based locking, eliminating mdsc->mutex as a
precondition for tree access and paving the way for lockless
xa_load() in the future. In practise this yields a 13x reduction
of handle_reply mutex hold time, from 51-416us down to 10-32us,
due to parse_reply_info() no longer being protected by the global
mutex.

Check xa_store() for allocation failure, which would otherwise be
silent, and skip __do_request() in the submit path if registration
failed.

On 32-bit architectures xarray silently truncates u64 keys because
its index type is unsigned long.  Guard the entire conversion by
BITS_PER_LONG==64 and fall back to the original rbtree on 32-bit
so there is no regression from the current code.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/debugfs.c    |   9 +++
 fs/ceph/mds_client.c | 160 +++++++++++++++++++++++++++++++++++++++++++++++++--
 fs/ceph/mds_client.h |  10 +++-
 3 files changed, 173 insertions(+), 6 deletions(-)

diff --git a/fs/ceph/debugfs.c b/fs/ceph/debugfs.c
index 18eb5da03411..f0d0b9b04b79 100644
--- a/fs/ceph/debugfs.c
+++ b/fs/ceph/debugfs.c
@@ -87,12 +87,21 @@ static int mdsc_show(struct seq_file *s, void *p)
 	struct ceph_fs_client *fsc = s->private;
 	struct ceph_mds_client *mdsc = fsc->mdsc;
 	struct ceph_mds_request *req;
+#if BITS_PER_LONG == 64
+	unsigned long idx;
+#else
 	struct rb_node *rp;
+#endif
 	char *path;
 
 	mutex_lock(&mdsc->mutex);
+#if BITS_PER_LONG == 64
+	idx = 0;
+	xa_for_each(&mdsc->request_tree, idx, req) {
+#else
 	for (rp = rb_first(&mdsc->request_tree); rp; rp = rb_next(rp)) {
 		req = rb_entry(rp, struct ceph_mds_request, r_node);
+#endif
 
 		if (req->r_request && req->r_session)
 			seq_printf(s, "%lld\tmds%d\t", req->r_tid,
diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index 98d0a5baff70..239ed34886f9 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -1183,7 +1183,9 @@ void ceph_mdsc_release_request(struct kref *kref)
 	kmem_cache_free(ceph_mds_request_cachep, req);
 }
 
+#if BITS_PER_LONG != 64
 DEFINE_RB_FUNCS(request, struct ceph_mds_request, r_tid, r_node)
+#endif
 
 /*
  * lookup session, bump ref if found.
@@ -1195,7 +1197,11 @@ lookup_get_request(struct ceph_mds_client *mdsc, u64 tid)
 {
 	struct ceph_mds_request *req;
 
+#if BITS_PER_LONG == 64
+	req = xa_load(&mdsc->request_tree, tid);
+#else
 	req = lookup_request(&mdsc->request_tree, tid);
+#endif
 	if (req)
 		ceph_mdsc_get_request(req);
 
@@ -1229,7 +1235,17 @@ static void __register_request(struct ceph_mds_client *mdsc,
 	}
 	doutc(cl, "%p tid %lld\n", req, req->r_tid);
 	ceph_mdsc_get_request(req);
+#if BITS_PER_LONG == 64
+	if (xa_is_err(xa_store(&mdsc->request_tree, req->r_tid, req,
+			       GFP_NOFS))) {
+		pr_err_client(cl, "%p tid %lld: xa_store failed\n",
+			      req, req->r_tid);
+		req->r_err = -ENOMEM;
+		return;
+	}
+#else
 	insert_request(&mdsc->request_tree, req);
+#endif
 
 	req->r_cred = get_current_cred();
 	if (!req->r_mnt_idmap)
@@ -1259,6 +1275,19 @@ static void __unregister_request(struct ceph_mds_client *mdsc,
 	list_del_init(&req->r_unsafe_item);
 
 	if (req->r_tid == atomic64_read(&mdsc->oldest_tid)) {
+#if BITS_PER_LONG == 64
+		unsigned long tidx = req->r_tid + 1;
+		struct ceph_mds_request *next_req;
+
+		atomic64_set(&mdsc->oldest_tid, 0);
+		xa_for_each_start(&mdsc->request_tree, tidx, next_req, tidx) {
+			if (next_req->r_op != CEPH_MDS_OP_SETFILELOCK) {
+				atomic64_set(&mdsc->oldest_tid,
+					     next_req->r_tid);
+				break;
+			}
+		}
+#else
 		struct rb_node *p = rb_next(&req->r_node);
 		atomic64_set(&mdsc->oldest_tid, 0);
 		while (p) {
@@ -1270,9 +1299,14 @@ static void __unregister_request(struct ceph_mds_client *mdsc,
 			}
 			p = rb_next(p);
 		}
+#endif
 	}
 
+#if BITS_PER_LONG == 64
+	xa_erase(&mdsc->request_tree, req->r_tid);
+#else
 	erase_request(&mdsc->request_tree, req);
+#endif
 
 	if (req->r_unsafe_dir) {
 		struct ceph_inode_info *ci = ceph_inode(req->r_unsafe_dir);
@@ -1829,7 +1863,11 @@ static void cleanup_session_requests(struct ceph_mds_client *mdsc,
 {
 	struct ceph_client *cl = mdsc->fsc->client;
 	struct ceph_mds_request *req;
+#if BITS_PER_LONG == 64
+	unsigned long idx;
+#else
 	struct rb_node *p;
+#endif
 
 	doutc(cl, "mds%d\n", session->s_mds);
 	mutex_lock(&mdsc->mutex);
@@ -1845,6 +1883,14 @@ static void cleanup_session_requests(struct ceph_mds_client *mdsc,
 		__unregister_request(mdsc, req);
 	}
 	/* zero r_attempts, so kick_requests() will re-send requests */
+#if BITS_PER_LONG == 64
+	idx = 0;
+	xa_for_each(&mdsc->request_tree, idx, req) {
+		if (req->r_session &&
+		    req->r_session->s_mds == session->s_mds)
+			req->r_attempts = 0;
+	}
+#else
 	p = rb_first(&mdsc->request_tree);
 	while (p) {
 		req = rb_entry(p, struct ceph_mds_request, r_node);
@@ -1853,6 +1899,7 @@ static void cleanup_session_requests(struct ceph_mds_client *mdsc,
 		    req->r_session->s_mds == session->s_mds)
 			req->r_attempts = 0;
 	}
+#endif
 	mutex_unlock(&mdsc->mutex);
 }
 
@@ -2732,7 +2779,9 @@ ceph_mdsc_create_request(struct ceph_mds_client *mdsc, int op, int mode)
 	req->r_fmode = -1;
 	req->r_feature_needed = -1;
 	kref_init(&req->r_kref);
+#if BITS_PER_LONG != 64
 	RB_CLEAR_NODE(&req->r_node);
+#endif
 	INIT_LIST_HEAD(&req->r_wait);
 	init_completion(&req->r_completion);
 	init_completion(&req->r_safe_completion);
@@ -2752,10 +2801,16 @@ ceph_mdsc_create_request(struct ceph_mds_client *mdsc, int op, int mode)
  */
 static struct ceph_mds_request *__get_oldest_req(struct ceph_mds_client *mdsc)
 {
+#if BITS_PER_LONG == 64
+	unsigned long idx = 0;
+
+	return xa_find(&mdsc->request_tree, &idx, ULONG_MAX, XA_PRESENT);
+#else
 	if (RB_EMPTY_ROOT(&mdsc->request_tree))
 		return NULL;
 	return rb_entry(rb_first(&mdsc->request_tree),
 			struct ceph_mds_request, r_node);
+#endif
 }
 
 static inline  u64 __get_oldest_tid(struct ceph_mds_client *mdsc)
@@ -3816,12 +3871,20 @@ static void kick_requests(struct ceph_mds_client *mdsc, int mds)
 {
 	struct ceph_client *cl = mdsc->fsc->client;
 	struct ceph_mds_request *req;
-	struct rb_node *p = rb_first(&mdsc->request_tree);
+#if BITS_PER_LONG == 64
+	unsigned long idx;
+#else
+	struct rb_node *p;
+#endif
 
 	doutc(cl, "kick_requests mds%d\n", mds);
-	while (p) {
+#if BITS_PER_LONG == 64
+	idx = 0;
+	xa_for_each(&mdsc->request_tree, idx, req) {
+#else
+	for (p = rb_first(&mdsc->request_tree); p; p = rb_next(p)) {
 		req = rb_entry(p, struct ceph_mds_request, r_node);
-		p = rb_next(p);
+#endif
 		if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags))
 			continue;
 		if (req->r_attempts > 0)
@@ -3894,7 +3957,8 @@ int ceph_mdsc_submit_request(struct ceph_mds_client *mdsc, struct inode *dir,
 	mutex_lock(&mdsc->mutex);
 	__register_request(mdsc, req, dir);
 	trace_ceph_mdsc_submit_request(mdsc, req);
-	__do_request(mdsc, req);
+	if (!req->r_err)
+		__do_request(mdsc, req);
 	err = req->r_err;
 	mutex_unlock(&mdsc->mutex);
 	return err;
@@ -4654,7 +4718,11 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 				   struct ceph_mds_session *session)
 {
 	struct ceph_mds_request *req, *nreq;
+#if BITS_PER_LONG == 64
+	unsigned long idx;
+#else
 	struct rb_node *p;
+#endif
 
 	doutc(mdsc->fsc->client, "mds%d\n", session->s_mds);
 
@@ -4666,10 +4734,15 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 	 * also re-send old requests when MDS enters reconnect stage. So that MDS
 	 * can process completed request in clientreplay stage.
 	 */
+#if BITS_PER_LONG == 64
+	idx = 0;
+	xa_for_each(&mdsc->request_tree, idx, req) {
+#else
 	p = rb_first(&mdsc->request_tree);
 	while (p) {
 		req = rb_entry(p, struct ceph_mds_request, r_node);
 		p = rb_next(p);
+#endif
 		if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags))
 			continue;
 		if (req->r_attempts == 0)
@@ -5514,7 +5587,11 @@ static void ceph_mdsc_reset_workfn(struct work_struct *work)
 	 */
 	{
 		struct ceph_mds_request *req;
+#if BITS_PER_LONG == 64
+		unsigned long idx;
+#else
 		struct rb_node *rn;
+#endif
 		u64 last_tid;
 
 		mutex_lock(&mdsc->mutex);
@@ -5522,14 +5599,24 @@ static void ceph_mdsc_reset_workfn(struct work_struct *work)
 		mutex_unlock(&mdsc->mutex);
 
 		mutex_lock(&mdsc->mutex);
+#if BITS_PER_LONG == 64
+		idx = 0;
+		while ((req = xa_find(&mdsc->request_tree, &idx, last_tid,
+				      XA_PRESENT))) {
+#else
 		rn = rb_first(&mdsc->request_tree);
 		while (rn) {
 			req = rb_entry(rn, struct ceph_mds_request, r_node);
 			if (req->r_tid > last_tid)
 				break;
+#endif
 			if (req->r_op == CEPH_MDS_OP_SETFILELOCK ||
 			    !(req->r_op & CEPH_MDS_OP_WRITE)) {
+#if BITS_PER_LONG == 64
+				idx++;
+#else
 				rn = rb_next(rn);
+#endif
 				continue;
 			}
 			ceph_mdsc_get_request(req);
@@ -5542,7 +5629,11 @@ static void ceph_mdsc_reset_workfn(struct work_struct *work)
 			ceph_mdsc_put_request(req);
 			if (time_after(jiffies, drain_deadline))
 				break;
+#if BITS_PER_LONG == 64
+			idx = 0;  /* restart: tree may have changed */
+#else
 			rn = rb_first(&mdsc->request_tree);
+#endif
 		}
 		mutex_unlock(&mdsc->mutex);
 
@@ -6268,7 +6359,11 @@ int ceph_mdsc_init(struct ceph_fs_client *fsc)
 	mdsc->snap_realms = RB_ROOT;
 	INIT_LIST_HEAD(&mdsc->snap_empty);
 	spin_lock_init(&mdsc->snap_empty_lock);
+#if BITS_PER_LONG == 64
+	xa_init(&mdsc->request_tree);
+#else
 	mdsc->request_tree = RB_ROOT;
+#endif
 	INIT_DELAYED_WORK(&mdsc->delayed_work, delayed_work);
 	mdsc->last_renew_caps = jiffies;
 	INIT_LIST_HEAD(&mdsc->cap_delay_list);
@@ -6590,8 +6685,59 @@ static void flush_mdlog_and_wait_mdsc_unsafe_requests(struct ceph_mds_client *md
 						 u64 want_tid)
 {
 	struct ceph_client *cl = mdsc->fsc->client;
-	struct ceph_mds_request *req = NULL, *nextreq;
 	struct ceph_mds_session *last_session = NULL;
+#if BITS_PER_LONG == 64
+	struct ceph_mds_request *req;
+	unsigned long idx;
+
+	mutex_lock(&mdsc->mutex);
+	doutc(cl, "want %lld\n", want_tid);
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
+			struct ceph_mds_session *s = req->r_session;
+
+			if (!s) {
+				idx = next_tid;
+				continue;
+			}
+
+			/* write op */
+			ceph_mdsc_get_request(req);
+			s = ceph_get_mds_session(s);
+			mutex_unlock(&mdsc->mutex);
+
+			/* send flush mdlog request to MDS */
+			if (last_session != s) {
+				send_flush_mdlog(s);
+				ceph_put_mds_session(last_session);
+				last_session = s;
+			} else {
+				ceph_put_mds_session(s);
+			}
+			doutc(cl, "wait on %llu (want %llu)\n",
+			      req->r_tid, want_tid);
+			wait_for_completion(&req->r_safe_completion);
+
+			mutex_lock(&mdsc->mutex);
+			ceph_mdsc_put_request(req);
+			idx = next_tid;
+		}
+	}
+	mutex_unlock(&mdsc->mutex);
+	ceph_put_mds_session(last_session);
+	doutc(cl, "done\n");
+#else /* BITS_PER_LONG != 64 — rbtree fallback */
+	struct ceph_mds_request *req = NULL, *nextreq;
 	struct rb_node *n;
 
 	mutex_lock(&mdsc->mutex);
@@ -6649,6 +6795,7 @@ static void flush_mdlog_and_wait_mdsc_unsafe_requests(struct ceph_mds_client *md
 	mutex_unlock(&mdsc->mutex);
 	ceph_put_mds_session(last_session);
 	doutc(cl, "done\n");
+#endif
 }
 
 void ceph_mdsc_sync(struct ceph_mds_client *mdsc)
@@ -6803,6 +6950,9 @@ static void ceph_mdsc_stop(struct ceph_mds_client *mdsc)
 	if (mdsc->mdsmap)
 		ceph_mdsmap_destroy(mdsc->mdsmap);
 	kfree(mdsc->sessions);
+#if BITS_PER_LONG == 64
+	xa_destroy(&mdsc->request_tree);
+#endif
 	ceph_caps_finalize(mdsc);
 
 	if (mdsc->s_cap_auths) {
diff --git a/fs/ceph/mds_client.h b/fs/ceph/mds_client.h
index 3b614b5df18c..c2de551607e3 100644
--- a/fs/ceph/mds_client.h
+++ b/fs/ceph/mds_client.h
@@ -329,7 +329,11 @@ typedef int (*ceph_mds_request_wait_callback_t) (struct ceph_mds_client *mdsc,
  */
 struct ceph_mds_request {
 	u64 r_tid;                   /* transaction id */
+#if BITS_PER_LONG == 64
+	/* embedded in mdsc->request_tree xarray */
+#else
 	struct rb_node r_node;
+#endif
 	struct ceph_mds_client *r_mdsc;
 
 	struct kref       r_kref;
@@ -534,7 +538,11 @@ struct ceph_mds_client {
 	u64                    last_tid;      /* most recent mds request */
 	atomic64_t             oldest_tid;    /* oldest incomplete mds request,
 						 excluding setfilelock requests */
-	struct rb_root         request_tree;  /* pending mds requests */
+#if BITS_PER_LONG == 64
+	struct xarray           request_tree;  /* pending mds requests */
+#else
+	struct rb_root          request_tree;  /* pending mds requests */
+#endif
 	struct delayed_work    delayed_work;  /* delayed work */
 	unsigned long    last_renew_caps;  /* last time we renewed our caps */
 	struct list_head cap_delay_list;   /* caps with delayed release */

-- 
2.53.0

