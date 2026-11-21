From: Xiubo Li <xiubo.li@clyso.com>
Date: Sat, 21 Nov 2026 03:21:06 +0200
Subject: [PATCH 2/2] ceph: serialize O_APPEND writes across clients on Fx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-ceph-append-excl-v1-2-5870375edeb8@clyso.com>
References: <20261121-ceph-append-excl-v1-0-5870375edeb8@clyso.com>
In-Reply-To: <20261121-ceph-append-excl-v1-0-5870375edeb8@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Anthony D'Atri <anthony.datri@gmail.com>, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795224072; l=17172;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=3rlWYujx9TXZvzA2nDZJ0jKdsJ6J7KdkRiRb164g8iI=;
 b=J+9jyoelIPJOdJOoSdn3ze07FhpOMYrXSrOvNP5PgfTt8mv5N33f+NvOPYIl5yMGBDZDjT2W6
 bMZ1S2MssqOBnX5E5TAtihEAELIpZzGbsz/J8SSqAYSrGKQbZsUQdOt
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An O_APPEND write takes its offset from the cached i_size, but with two
clients writing a file the filelock is in MIX and both hold Fw, so a
client may append at an end of file that another client has already
moved, and overwrite what that client appended.  Re-reading i_size
after ceph_get_caps() does not help there: neither client waits for
caps, and the other client's size reaches us only after it flushed its
caps.

The MDS can now hand Fx to O_APPEND writers one at a time, in request
order (CEPHFS_FEATURE_APPEND_EXCL): a client asks for its turn with
CEPH_CLIENT_CAPS_APPEND in a cap update, the MDS gathers the other
writers' Fw first, so that their size updates are applied, and sends
the size with Fx.  While a client holds Fx no other client can write
the file, so i_size is the true end of file.

When the auth MDS supports it, let an O_APPEND write need Fx as well as
Fw, and ask the auth MDS for a turn while it waits.  Ask once per turn,
and again only if the auth cap moved (an export or an MDS restart may
have lost the request) or after CEPH_GET_CAPS_WAIT_TIMEOUT: the waiter
is woken by every cap message, and answering each of them with another
request would flood the MDS.

The MDS revokes Fx as soon as the next client asks for a turn, maybe
before the waiting write could take its cap refs.  Keep a revoked Fx,
with Fw and Fb, until then, or the turn would be lost before it was
used.  The write's Fx and Fw refs then hold the hand-over back until
it is done, and the cap flush that releases Fw carries the new size.
Only the write that was waiting when Fx came may use it while it is
being revoked: a later one, e.g. this client's next write while the
revoke waits for our dirty data to be written back, gives the turn up
and asks for a new one, or the other clients would never get theirs.
So does a write that needs more max_size than it has, which the MDS
cannot grant while it takes Fx back.

Once it holds Fx, the write moves to i_size as before; if that range
needs more max_size, it drops its refs and asks again instead of
writing less.

Link: https://tracker.ceph.com/issues/7333
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c               | 179 +++++++++++++++++++++++++++++++++++++++++++
 fs/ceph/file.c               |  33 ++++++--
 fs/ceph/inode.c              |   3 +
 fs/ceph/mds_client.h         |   4 +-
 fs/ceph/super.h              |  14 ++++
 include/linux/ceph/ceph_fs.h |   1 +
 6 files changed, 226 insertions(+), 8 deletions(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index fd6f3a372271..0431cb7f17eb 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -1056,6 +1056,24 @@ static bool __ceph_is_any_revoking(const struct ceph_inode_info *ci)
 	return false;
 }
 
+/*
+ * The caps that an O_APPEND write waiting for its turn keeps while the
+ * MDS revokes them, see ceph_get_append_caps().
+ */
+#define CEPH_APPEND_TURN_CAPS	(CEPH_CAP_FILE_EXCL | CEPH_CAP_FILE_WR | \
+				 CEPH_CAP_FILE_BUFFER)
+
+static int __ceph_append_turn_caps(struct ceph_inode_info *ci,
+				   int implemented)
+{
+	lockdep_assert_held(&ci->i_ceph_lock);
+
+	if (ci->i_append_waiting && !ci->i_append_yield &&
+	    (implemented & CEPH_CAP_FILE_EXCL))
+		return implemented & CEPH_APPEND_TURN_CAPS;
+	return 0;
+}
+
 int __ceph_caps_used(struct ceph_inode_info *ci)
 {
 	int used = 0;
@@ -2270,6 +2288,13 @@ void ceph_check_caps(struct ceph_inode_info *ci, int flags)
 	 */
 	issued = __ceph_caps_issued(ci, &implemented);
 
+	/*
+	 * An O_APPEND write that asked for Fx must be able to use it: do
+	 * not let the revoke for the next appender, which may come right
+	 * with the grant, complete before the write took its cap refs.
+	 */
+	used |= __ceph_append_turn_caps(ci, implemented);
+
 	revoking = implemented & ~issued;
 
 	want = file_wanted;
@@ -2459,6 +2484,13 @@ void ceph_check_caps(struct ceph_inode_info *ci, int flags)
 				goto ack;
 		}
 
+		/* an O_APPEND write asks for its turn */
+		if ((flags & CHECK_CAPS_APPEND) && cap == ci->i_auth_cap &&
+		    !(cap->implemented & CEPH_CAP_FILE_EXCL)) {
+			doutc(cl, "asking for the O_APPEND turn\n");
+			goto ack;
+		}
+
 		/* things we might delay */
 		if ((cap->issued & ~retain) == 0)
 			continue;     /* nope, all good */
@@ -2497,6 +2529,10 @@ void ceph_check_caps(struct ceph_inode_info *ci, int flags)
 
 		mds = cap->mds;  /* remember mds, so we don't repeat */
 
+		if ((flags & CHECK_CAPS_APPEND) && cap == ci->i_auth_cap &&
+		    !(cap->implemented & CEPH_CAP_FILE_EXCL))
+			mflags |= CEPH_CLIENT_CAPS_APPEND;
+
 		__prep_cap(&arg, ci, cap, CEPH_CAP_OP_UPDATE, mflags, cap_used,
 			   want, retain, flushing, flush_tid, oldest_flush_tid);
 
@@ -3120,6 +3156,26 @@ static int try_get_cap_refs(struct inode *inode, int need, int want,
 
 	have = __ceph_caps_issued(ci, &implemented);
 
+	if ((need & CEPH_CAP_FILE_EXCL) && ci->i_append_waiting) {
+		if (!(implemented & CEPH_CAP_FILE_EXCL) ||
+		    (have & CEPH_CAP_FILE_EXCL)) {
+			ci->i_append_yield = false;
+		} else if (!(have & CEPH_CAP_FILE_EXCL) &&
+			   !ci->i_append_yield) {
+			/*
+			 * Fx is being revoked for the next appender, but it
+			 * stays ours until we ack, see ceph_check_caps().
+			 * Not if we need more max_size: the MDS cannot
+			 * grant that while it takes Fx back, so give the
+			 * turn up and ask for a new one.
+			 */
+			if (endoff > (loff_t)ci->i_max_size)
+				ci->i_append_yield = true;
+			else
+				have |= implemented & CEPH_APPEND_TURN_CAPS;
+		}
+	}
+
 	if (have & need & CEPH_CAP_FILE_WR) {
 		if (endoff >= 0 && endoff > (loff_t)ci->i_max_size) {
 			doutc(cl, "%p %llx.%llx endoff %llu > maxsize %llu\n",
@@ -3349,6 +3405,54 @@ int ceph_try_get_caps(struct inode *inode, int need, int want,
 	return ret;
 }
 
+/*
+ * An O_APPEND write is waiting for Fx: ack a revoke of the turn it gave
+ * up, and ask the auth MDS for a turn if we have none.  Ask once per
+ * turn; again only if the auth cap moved (an export or an MDS restart
+ * may have lost the request) or after CEPH_GET_CAPS_WAIT_TIMEOUT.  We
+ * are woken by every cap message, often with no news for us, and must
+ * not answer each of them with another request.
+ */
+static void ceph_append_kick(struct ceph_inode_info *ci)
+{
+	struct ceph_cap *auth;
+	int implemented, flags;
+
+	for (int i = 0; i < 2; i++) {
+		flags = 0;
+		spin_lock(&ci->i_ceph_lock);
+		__ceph_caps_issued(ci, &implemented);
+		auth = ci->i_auth_cap;
+		if (implemented & CEPH_CAP_FILE_EXCL)
+			ci->i_append_asked = 0;  /* that turn came */
+		if (ci->i_append_waiting && auth) {
+			if (!(implemented & CEPH_CAP_FILE_EXCL)) {
+				if (!ci->i_append_asked ||
+				    ci->i_append_asked_mds != auth->mds ||
+				    ci->i_append_asked_mseq != auth->mseq ||
+				    time_after(jiffies, ci->i_append_asked +
+					       CEPH_GET_CAPS_WAIT_TIMEOUT)) {
+					ci->i_append_asked = jiffies ?: 1;
+					ci->i_append_asked_mds = auth->mds;
+					ci->i_append_asked_mseq = auth->mseq;
+					flags = CHECK_CAPS_AUTHONLY |
+						CHECK_CAPS_APPEND;
+				}
+			} else if (ci->i_append_yield &&
+				   !(auth->issued & CEPH_CAP_FILE_EXCL)) {
+				flags = CHECK_CAPS_AUTHONLY;
+			}
+		}
+		spin_unlock(&ci->i_ceph_lock);
+		if (!flags)
+			return;
+		ceph_check_caps(ci, flags);
+		if (flags & CHECK_CAPS_APPEND)
+			return;
+		/* the revoke may be acked now: ask for a new turn */
+	}
+}
+
 /*
  * Wait for caps, and take cap references.  If we can't get a WR cap
  * due to a small max_size, make sure we check_max_size (and possibly
@@ -3400,6 +3504,8 @@ int __ceph_get_caps(struct inode *inode, struct ceph_file_info *fi, int need,
 			/* make sure used fmode not timeout */
 			ceph_get_fmode(ci, flags, FMODE_WAIT_BIAS);
 			add_wait_queue(&ci->i_cap_wq, &wait);
+			if (need & CEPH_CAP_FILE_EXCL)
+				ceph_append_kick(ci);
 
 			flags |= NON_BLOCKING;
 			while (!(ret = try_get_cap_refs(inode, need, want,
@@ -3421,6 +3527,8 @@ int __ceph_get_caps(struct inode *inode, struct ceph_file_info *fi, int need,
 					ret = -EUCLEAN;
 					break;
 				}
+				if (need & CEPH_CAP_FILE_EXCL)
+					ceph_append_kick(ci);
 			}
 
 			remove_wait_queue(&ci->i_cap_wq, &wait);
@@ -3509,6 +3617,77 @@ int ceph_get_caps(struct file *filp, int need, int want, loff_t endoff,
 	return __ceph_get_caps(inode, fi, need, want, endoff, got);
 }
 
+/*
+ * Whether the auth MDS serializes O_APPEND writes, see
+ * ceph_get_append_caps().
+ */
+bool ceph_append_excl_supported(struct ceph_inode_info *ci)
+{
+	bool ret;
+
+	spin_lock(&ci->i_ceph_lock);
+	ret = ci->i_auth_cap &&
+	      test_bit(CEPHFS_FEATURE_APPEND_EXCL,
+		       &ci->i_auth_cap->session->s_features);
+	spin_unlock(&ci->i_ceph_lock);
+	return ret;
+}
+
+/*
+ * Get the caps for an O_APPEND write.
+ *
+ * The end of file that the write was placed at may be out of date: two
+ * clients appending to a file both hold Fw with the filelock in MIX,
+ * and nothing makes one wait for the other.  Ask the MDS for Fx
+ * instead (CEPH_CLIENT_CAPS_APPEND).  It hands Fx to the appending
+ * clients one at a time, in request order, after it gathered the
+ * other writers' Fw so that their size updates are applied, and sends
+ * that size with Fx.  While we hold Fx no other client can write the
+ * file, so i_size is the true end of file.
+ *
+ * The MDS revokes Fx again as soon as another client asks for a turn,
+ * maybe before we could take our cap refs: keep a revoked Fx (with Fw
+ * and Fb) until then, see ceph_check_caps().  Our Fx and Fw refs then
+ * hold the hand-over back until the write is done, and the cap flush
+ * that releases Fw carries our new size.
+ */
+int ceph_get_append_caps(struct file *filp, int want, loff_t endoff,
+			 int *got)
+{
+	struct ceph_inode_info *ci = ceph_inode(file_inode(filp));
+	int ret, issued, implemented;
+
+	spin_lock(&ci->i_ceph_lock);
+	/*
+	 * A revoked Fx belongs to the write that waited for it.  A new
+	 * write that finds Fx being revoked already, e.g. the next one of
+	 * this client while the revoke waits for our dirty data, must let
+	 * the revoke complete and wait for a turn of its own, or the
+	 * other clients would never get one.
+	 */
+	issued = __ceph_caps_issued(ci, &implemented);
+	if (!ci->i_append_waiting &&
+	    (implemented & ~issued & CEPH_CAP_FILE_EXCL))
+		ci->i_append_yield = true;
+	ci->i_append_waiting++;
+	spin_unlock(&ci->i_ceph_lock);
+
+	ret = ceph_get_caps(filp, CEPH_CAP_FILE_WR | CEPH_CAP_FILE_EXCL, want,
+			    endoff, got);
+
+	spin_lock(&ci->i_ceph_lock);
+	if (--ci->i_append_waiting == 0)
+		ci->i_append_yield = false;
+	if (ret == 0)
+		ci->i_append_asked = 0;  /* our turn came, ask for the next */
+	spin_unlock(&ci->i_ceph_lock);
+
+	/* ack a revoke that we held back for this write */
+	if (ret < 0)
+		ceph_check_caps(ci, CHECK_CAPS_AUTHONLY);
+	return ret;
+}
+
 /*
  * Take cap refs.  Caller must already know we hold at least one ref
  * on the caps in question or we don't know this is safe.
diff --git a/fs/ceph/file.c b/fs/ceph/file.c
index 75fb12be209b..962f734066cc 100644
--- a/fs/ceph/file.c
+++ b/fs/ceph/file.c
@@ -2500,6 +2500,7 @@ static ssize_t ceph_write_iter(struct kiocb *iocb, struct iov_iter *from)
 	ssize_t count, written = 0;
 	int err, want = 0, got;
 	bool direct_lock = false;
+	bool append_excl = false;
 	u32 map_flags;
 	u64 pool_flags;
 	loff_t pos;
@@ -2578,18 +2579,25 @@ static ssize_t ceph_write_iter(struct kiocb *iocb, struct iov_iter *from)
 		want |= CEPH_CAP_FILE_BUFFER;
 	if (fi->fmode & CEPH_FILE_MODE_LAZY)
 		want |= CEPH_CAP_FILE_LAZYIO;
+	if (iocb->ki_flags & IOCB_APPEND)
+		append_excl = ceph_append_excl_supported(ci);
+get_caps:
 	got = 0;
-	err = ceph_get_caps(file, CEPH_CAP_FILE_WR, want, pos + count, &got);
+	if (append_excl)
+		err = ceph_get_append_caps(file, want, pos + count, &got);
+	else
+		err = ceph_get_caps(file, CEPH_CAP_FILE_WR, want, pos + count,
+				    &got);
 	if (err < 0)
 		goto out;
 
 	/*
-	 * For O_APPEND writes we may have waited for Fwx exclusive caps
-	 * while the previous Fwx holder (another client) extended the
-	 * file.  i_size has been updated via the cap grant message from
-	 * the MDS, but ki_pos is still the old EOF.  Re-read i_size here
-	 * (no extra MDS round-trip needed) and adjust ki_pos to the true
-	 * EOF.  Since we hold Fwx, no other client can change the file.
+	 * For O_APPEND writes we may have waited for caps while another
+	 * client extended the file, so ki_pos may be an old EOF.  Re-read
+	 * i_size here and adjust ki_pos.  With append_excl we hold Fx: no
+	 * other client can change the file, and i_size is the true EOF
+	 * that the MDS sent with Fx.  Without it this only helps if the
+	 * cap grant we waited for brought the other client's size.
 	 */
 	if (iocb->ki_flags & IOCB_APPEND) {
 		loff_t cur_eof = i_size_read(inode);
@@ -2615,6 +2623,17 @@ static ssize_t ceph_write_iter(struct kiocb *iocb, struct iov_iter *from)
 			 * necessary.
 			 */
 			spin_lock(&ci->i_ceph_lock);
+			if (pos + count > (loff_t)ci->i_max_size &&
+			    append_excl) {
+				/*
+				 * Ask for more max_size with the new
+				 * range; we keep the turn if Fx is not
+				 * being revoked.
+				 */
+				spin_unlock(&ci->i_ceph_lock);
+				ceph_put_cap_refs(ci, got);
+				goto get_caps;
+			}
 			if (pos + count > (loff_t)ci->i_max_size) {
 				loff_t max_size = ci->i_max_size;
 
diff --git a/fs/ceph/inode.c b/fs/ceph/inode.c
index 2e5d1256a3a5..9e586c7e40b7 100644
--- a/fs/ceph/inode.c
+++ b/fs/ceph/inode.c
@@ -710,6 +710,9 @@ struct inode *ceph_alloc_inode(struct super_block *sb)
 	ci->i_fx_ref = 0;
 	ci->i_wrbuffer_ref = 0;
 	ci->i_wrbuffer_ref_head = 0;
+	ci->i_append_waiting = 0;
+	ci->i_append_yield = false;
+	ci->i_append_asked = 0;
 	atomic_set(&ci->i_filelock_ref, 0);
 	atomic_set(&ci->i_shared_gen, 1);
 	ci->i_rdcache_gen = 0;
diff --git a/fs/ceph/mds_client.h b/fs/ceph/mds_client.h
index ff9ba09f3b59..750cc72d53a6 100644
--- a/fs/ceph/mds_client.h
+++ b/fs/ceph/mds_client.h
@@ -38,8 +38,9 @@ enum ceph_feature_type {
 	CEPHFS_FEATURE_HAS_OWNER_UIDGID,
 	CEPHFS_FEATURE_MDS_AUTH_CAPS_CHECK,
 	CEPHFS_FEATURE_SUBVOLUME_METRICS,
+	CEPHFS_FEATURE_APPEND_EXCL = 25,
 
-	CEPHFS_FEATURE_MAX = CEPHFS_FEATURE_SUBVOLUME_METRICS,
+	CEPHFS_FEATURE_MAX = CEPHFS_FEATURE_APPEND_EXCL,
 };
 
 #define CEPHFS_FEATURES_CLIENT_SUPPORTED {	\
@@ -57,6 +58,7 @@ enum ceph_feature_type {
 	CEPHFS_FEATURE_HAS_OWNER_UIDGID,	\
 	CEPHFS_FEATURE_MDS_AUTH_CAPS_CHECK,	\
 	CEPHFS_FEATURE_SUBVOLUME_METRICS,	\
+	CEPHFS_FEATURE_APPEND_EXCL,		\
 }
 
 /*
diff --git a/fs/ceph/super.h b/fs/ceph/super.h
index b11083ad1da7..2fbeef60b23c 100644
--- a/fs/ceph/super.h
+++ b/fs/ceph/super.h
@@ -254,6 +254,7 @@ struct ceph_cap {
 #define CHECK_CAPS_FLUSH        2  /* flush any dirty caps */
 #define CHECK_CAPS_NOINVAL      4  /* don't invalidate pagecache */
 #define CHECK_CAPS_FLUSH_FORCE  8  /* force flush any caps */
+#define CHECK_CAPS_APPEND      16  /* ask the auth MDS for an O_APPEND turn */
 
 struct ceph_cap_flush {
 	u64 tid;
@@ -529,6 +530,16 @@ struct ceph_inode_info {
 	int i_pin_ref;
 	int i_rd_ref, i_rdcache_ref, i_wr_ref, i_wb_ref, i_fx_ref;
 	int i_wrbuffer_ref, i_wrbuffer_ref_head;
+	/*
+	 * An O_APPEND write is waiting for its turn (Fx) from the MDS, see
+	 * ceph_get_append_caps(); i_append_yield: it gave that turn up.
+	 */
+	int i_append_waiting;
+	bool i_append_yield;
+	/* when and where it last asked for a turn, see ceph_append_kick() */
+	unsigned long i_append_asked;
+	int i_append_asked_mds;
+	u32 i_append_asked_mseq;
 	atomic_t i_filelock_ref;
 	atomic_t i_shared_gen;       /* increment each time we get FILE_SHARED */
 	u32 i_rdcache_gen;      /* incremented each time we get FILE_CACHE. */
@@ -1459,6 +1470,9 @@ extern int __ceph_get_caps(struct inode *inode, struct ceph_file_info *fi,
 			   int need, int want, loff_t endoff, int *got);
 extern int ceph_get_caps(struct file *filp, int need, int want,
 			 loff_t endoff, int *got);
+extern bool ceph_append_excl_supported(struct ceph_inode_info *ci);
+extern int ceph_get_append_caps(struct file *filp, int want, loff_t endoff,
+				int *got);
 extern int ceph_try_get_caps(struct inode *inode,
 			     int need, int want, bool nonblock, int *got);
 
diff --git a/include/linux/ceph/ceph_fs.h b/include/linux/ceph/ceph_fs.h
index d70bbce1a1b2..d3f4953f12df 100644
--- a/include/linux/ceph/ceph_fs.h
+++ b/include/linux/ceph/ceph_fs.h
@@ -773,6 +773,7 @@ extern const char *ceph_cap_op_name(int op);
 #define CEPH_CLIENT_CAPS_SYNC			(1<<0)
 #define CEPH_CLIENT_CAPS_NO_CAPSNAP		(1<<1)
 #define CEPH_CLIENT_CAPS_PENDING_CAPSNAP	(1<<2)
+#define CEPH_CLIENT_CAPS_APPEND			(1<<3) /* O_APPEND turn wanted */
 
 /*
  * caps message, used for capability callbacks, acks, requests, etc.

-- 
2.53.0

