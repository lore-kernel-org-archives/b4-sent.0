From: Xiubo Li <xiubo.li@clyso.com>
Date: Wed, 15 Jul 2026 11:58:45 +0800
Subject: [PATCH v2 5/5] ceph: narrow mdsc->mutex scope in
 replay_unsafe_requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260715-ceph-mdsc-mutex-optimization-v2-5-90e81b726724@clyso.com>
References: <20260715-ceph-mdsc-mutex-optimization-v2-0-90e81b726724@clyso.com>
In-Reply-To: <20260715-ceph-mdsc-mutex-optimization-v2-0-90e81b726724@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784087938; l=3210;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=V6Rwu7aHfIW8x0x76qZaMXOB1fkfzmlqcq+V2RGl5oI=;
 b=FIsjpUqPWfrOuyahZ7cKIGiLoVTn4OvhNnZBI/JH4w3nt8Jq6+7SmkDzSBcAf6eJF39Wp8ojZ
 K5qkHU0/IIKCp8tzchKuWbrw4R2JqsGy7C3gSHjeTRdkVqCSy+0YU8L
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__send_request() is lockless so holding mdsc->mutex across the
replay loop only serializes the list iteration itself.  Collect
the unsafe list entries under the mutex, then replay them without
it.  The old-request tree walk uses xa_for_each() which is
internally locked.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/mds_client.c | 51 ++++++++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 44 insertions(+), 7 deletions(-)

diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index be0dae919d69..c313574def74 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -4744,30 +4744,66 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 #else
 	struct rb_node *p;
 #endif
+	LIST_HEAD(replay_list);
 
 	doutc(mdsc->fsc->client, "mds%d\n", session->s_mds);
 
+#if BITS_PER_LONG == 64
+	/* collect unsafe requests under the mutex */
 	mutex_lock(&mdsc->mutex);
-	list_for_each_entry_safe(req, nreq, &session->s_unsafe, r_unsafe_item)
+	list_for_each_entry_safe(req, nreq, &session->s_unsafe,
+				 r_unsafe_item) {
+		ceph_mdsc_get_request(req);
+		list_move(&req->r_unsafe_item, &replay_list);
+	}
+	mutex_unlock(&mdsc->mutex);
+
+	/* replay unsafe requests (local list, no mutex needed) */
+	list_for_each_entry_safe(req, nreq, &replay_list, r_unsafe_item) {
 		__send_request(session, req, true);
+		list_del_init(&req->r_unsafe_item);
+		ceph_mdsc_put_request(req);
+	}
 
 	/*
-	 * also re-send old requests when MDS enters reconnect stage. So that MDS
-	 * can process completed request in clientreplay stage.
+	 * also re-send old requests when MDS enters reconnect stage.
+	 * xa_for_each() is internally locked.
 	 */
-#if BITS_PER_LONG == 64
 	idx = 0;
 	xa_for_each(&mdsc->request_tree, idx, req) {
-#else
+		if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags))
+			continue;
+		if (req->r_attempts == 0)
+			continue;
+		if (!req->r_session)
+			continue;
+		if (req->r_session->s_mds != session->s_mds)
+			continue;
+
+		ceph_mdsc_release_dir_caps_async(req);
+
+		ceph_mdsc_get_request(req);
+		__send_request(session, req, true);
+		ceph_mdsc_put_request(req);
+	}
+#else /* BITS_PER_LONG != 64 — keep mutex for rb-tree iteration */
+	mutex_lock(&mdsc->mutex);
+	list_for_each_entry_safe(req, nreq, &session->s_unsafe,
+				 r_unsafe_item)
+		__send_request(session, req, true);
+
+	/*
+	 * also re-send old requests when MDS enters reconnect stage.
+	 * Must hold mutex for rb_first()/rb_next().
+	 */
 	p = rb_first(&mdsc->request_tree);
 	while (p) {
 		req = rb_entry(p, struct ceph_mds_request, r_node);
 		p = rb_next(p);
-#endif
 		if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags))
 			continue;
 		if (req->r_attempts == 0)
-			continue; /* only old requests */
+			continue;
 		if (!req->r_session)
 			continue;
 		if (req->r_session->s_mds != session->s_mds)
@@ -4778,6 +4814,7 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 		__send_request(session, req, true);
 	}
 	mutex_unlock(&mdsc->mutex);
+#endif
 }
 
 static int send_reconnect_partial(struct ceph_reconnect_state *recon_state)

-- 
2.53.0

