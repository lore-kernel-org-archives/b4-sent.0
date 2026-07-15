From: Xiubo Li <xiubo.li@clyso.com>
Date: Wed, 15 Jul 2026 11:58:41 +0800
Subject: [PATCH v2 1/5] ceph: convert oldest_tid to atomic64_t
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260715-ceph-mdsc-mutex-optimization-v2-1-90e81b726724@clyso.com>
References: <20260715-ceph-mdsc-mutex-optimization-v2-0-90e81b726724@clyso.com>
In-Reply-To: <20260715-ceph-mdsc-mutex-optimization-v2-0-90e81b726724@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784087938; l=4251;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=Ln313jfnyI9iEkGY4T3NBIW+U7Vyr9d7sWpnTOxEXz8=;
 b=l3ywj6I+ak12opOA5SQTGoS7YjH4j/e47k19/70QSNRmLOlPy/zc9zNIqEOPPvNsLLcv107f0
 uHPkV89Pzg3ACE0HsNDBOgFKgMV5J5JOUXS72t82+hQVISqL/Gsf4Ki
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The oldest_client_tid sent in the MDS request header is advisory:
a stale value is harmless -- at worst the MDS may resend a reply
we already have, or skip one we still need (which will just be
retried).  With the plain u64 read, however, the compiler is free
to split or cache the load, which is undefined behaviour when the
write side runs under mdsc->mutex on a different CPU.

Convert mdsc->oldest_tid from u64 to atomic64_t so that reads
are guaranteed to be single-copy atomic on all architectures.
This removes the one remaining reason __prepare_send_request()
and __send_request() needed to be called under mdsc->mutex, so
drop those comments as well.

All write sites (__register_request, __unregister_request) still
run under mdsc->mutex, so use atomic64_set() for clarity.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/mds_client.c | 21 ++++++++-------------
 fs/ceph/mds_client.h |  2 +-
 2 files changed, 9 insertions(+), 14 deletions(-)

diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index 9f84ef2ac6e4..98d0a5baff70 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -1235,8 +1235,9 @@ static void __register_request(struct ceph_mds_client *mdsc,
 	if (!req->r_mnt_idmap)
 		req->r_mnt_idmap = &nop_mnt_idmap;
 
-	if (mdsc->oldest_tid == 0 && req->r_op != CEPH_MDS_OP_SETFILELOCK)
-		mdsc->oldest_tid = req->r_tid;
+	if (atomic64_read(&mdsc->oldest_tid) == 0 &&
+	    req->r_op != CEPH_MDS_OP_SETFILELOCK)
+		atomic64_set(&mdsc->oldest_tid, req->r_tid);
 
 	if (dir) {
 		struct ceph_inode_info *ci = ceph_inode(dir);
@@ -1257,14 +1258,14 @@ static void __unregister_request(struct ceph_mds_client *mdsc,
 	/* Never leave an unregistered request on an unsafe list! */
 	list_del_init(&req->r_unsafe_item);
 
-	if (req->r_tid == mdsc->oldest_tid) {
+	if (req->r_tid == atomic64_read(&mdsc->oldest_tid)) {
 		struct rb_node *p = rb_next(&req->r_node);
-		mdsc->oldest_tid = 0;
+		atomic64_set(&mdsc->oldest_tid, 0);
 		while (p) {
 			struct ceph_mds_request *next_req =
 				rb_entry(p, struct ceph_mds_request, r_node);
 			if (next_req->r_op != CEPH_MDS_OP_SETFILELOCK) {
-				mdsc->oldest_tid = next_req->r_tid;
+				atomic64_set(&mdsc->oldest_tid, next_req->r_tid);
 				break;
 			}
 			p = rb_next(p);
@@ -1693,7 +1694,7 @@ create_session_full_msg(struct ceph_mds_client *mdsc, int op, u64 seq)
 	ceph_encode_32(&p, 0);
 
 	/* version == 7, oldest_client_tid */
-	ceph_encode_64(&p, mdsc->oldest_tid);
+	ceph_encode_64(&p, atomic64_read(&mdsc->oldest_tid));
 
 	msg->front.iov_len = p - msg->front.iov_base;
 	msg->hdr.front_len = cpu_to_le32(msg->front.iov_len);
@@ -2759,7 +2760,7 @@ static struct ceph_mds_request *__get_oldest_req(struct ceph_mds_client *mdsc)
 
 static inline  u64 __get_oldest_tid(struct ceph_mds_client *mdsc)
 {
-	return mdsc->oldest_tid;
+	return atomic64_read(&mdsc->oldest_tid);
 }
 
 #if IS_ENABLED(CONFIG_FS_ENCRYPTION)
@@ -3438,9 +3439,6 @@ static void complete_request(struct ceph_mds_client *mdsc,
 	complete_all(&req->r_completion);
 }
 
-/*
- * called under mdsc->mutex
- */
 static int __prepare_send_request(struct ceph_mds_session *session,
 				  struct ceph_mds_request *req,
 				  bool drop_cap_releases)
@@ -3555,9 +3553,6 @@ static int __prepare_send_request(struct ceph_mds_session *session,
 	return 0;
 }
 
-/*
- * called under mdsc->mutex
- */
 static int __send_request(struct ceph_mds_session *session,
 			  struct ceph_mds_request *req,
 			  bool drop_cap_releases)
diff --git a/fs/ceph/mds_client.h b/fs/ceph/mds_client.h
index 731d6ad04956..3b614b5df18c 100644
--- a/fs/ceph/mds_client.h
+++ b/fs/ceph/mds_client.h
@@ -532,7 +532,7 @@ struct ceph_mds_client {
 	spinlock_t              snap_empty_lock;  /* protect snap_empty */
 
 	u64                    last_tid;      /* most recent mds request */
-	u64                    oldest_tid;    /* oldest incomplete mds request,
+	atomic64_t             oldest_tid;    /* oldest incomplete mds request,
 						 excluding setfilelock requests */
 	struct rb_root         request_tree;  /* pending mds requests */
 	struct delayed_work    delayed_work;  /* delayed work */

-- 
2.53.0

