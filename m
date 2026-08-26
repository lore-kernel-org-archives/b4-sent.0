From: Xiubo Li <xiubo.li@clyso.com>
Date: Tue, 25 Aug 2026 23:30:02 -0700
Subject: [PATCH v3] ceph: remove the inline data support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-b4-ceph-remove-inline-data-v3-1-235b6890d7b7@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43NSw6CMBgE4KuYrq0pFUpx5T2Miz5+pAZa0mIjI
 dzdFjesjMvJTL5ZUABvIKDLYUEeognG2RTOxwNSnbAPwEanjCihjNSUY1liBWOHPQwuptb2xgL
 WYhJYV5ViJWNa14ASMHpozXvDb/dvDi/5BDVlMS86Eybn5+09Fnn311EscIF524oaCC+rRlxVP
 wd3Um5A+SjSPdX8pGiitCSqoVpIDrCn1nX9ALXvXrYhAQAA
X-Change-ID: 20260728-b4-ceph-remove-inline-data-d55c6466dd7e
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787726020; l=19126;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=WY/sGz4OnLSoOtNOGaG7bX4If/0zWcpCUQxK7OQllTA=;
 b=JERpJmplNjMKa8gXi0OEUoOJxKnx5q/ObXyl8eI3YQcaSXQ5/UIYlVJRZlzLhxAX+DC1p6xph
 uoPOGkKGbTIBjzp/T21O77EgiKjomLzLM15+u4xnBcR7k2pfij3XkED
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Inline data support has been deprecated in the CephFS MDS and is
being formally removed.  Existing inline data can be migrated to
data pool objects via MDS scrub (see PR #44359).

Add CONFIG_CEPH_FS_INLINE_DATA (default n) to gate all inline data
code in the kclient.  When disabled, CEPH_FEATURE_MDS_INLINE_DATA is
not advertised to the MDS, which will then refuse to open files that
still have inline data, returning -EPERM and preventing silent data
corruption that would occur if the kclient tried to read inline data
from OSD objects that do not contain it.

The conditional compilation is centralized in fs/ceph/super.h, where
static inline helpers make all the inline data code compile out
cleanly when the option is disabled, so that removing the option
later only touches that one place.  ceph_inline_version() returns
CEPH_INLINE_NONE when the option is disabled, which makes every
version comparison in the disabled build constant-fold to false;
the stubbed out ceph_uninline_data() and ceph_fill_inline_data() are
then unreachable.

The MDS still carries inline_version + inline_data on the wire, so
the reply and cap grant parsers keep consuming those fields even
with the option disabled, only skipping them, to keep the decode
pointer in sync for the fields that follow.

This config option will be kept for a transitional period to
allow existing CephFS deployments to migrate inline data via
MDS scrub.  Once the migration period ends, the option and all
inline data code will be permanently removed.

Users upgrading from an older Ceph release should ensure all inline
data has been migrated before deploying a kclient with this option
disabled:
  1. Enable and run MDS scrub to uninline existing data
  2. Disable inline_data on the filesystem:
     ceph fs set <fs> inline_data false --yes-i-really-really-mean-it

Link: https://tracker-origin.ceph.com/issues/67769
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
Changes in v3:
- addressed Viacheslav's review comments: dropped all the #ifdef
  blocks from the call sites by centralizing the conditional
  compilation in fs/ceph/super.h
- added ceph_inline_version() and ceph_set_inline_version()
  accessors; with the option disabled the getter returns
  CEPH_INLINE_NONE so every version comparison constant-folds to
  false
- added no-op stubs for ceph_uninline_data() and
  ceph_fill_inline_data() so their callers don't need to be #ifdef'd
- parsed the inline fields in the reply inode and cap grant messages
  via parse_reply_info_inline_data() and parse_inline_data()
  helpers, which skip the fields with the option disabled to keep
  the decode pointer in sync (also renamed __len to len)
- defined CEPH_STAT_CAP_INLINE_DATA as 0 with the option disabled
  instead of #ifdef'ing the getattr masks at the call sites
- renamed CEPH_FEATURE_MDS_INLINE_DATA_DEFAULT to
  CEPH_FEATURE_MDS_INLINE_DATA_SUPPORTED and moved it next to
  CEPH_FEATURES_SUPPORTED_DEFAULT
- only i_inline_version keeps its #ifdef; the other inline data
  fields stay unconditional, since the helpers make them dead code
- Link to v2: https://patch.msgid.link/20260729-b4-ceph-remove-inline-data-v2-1-db0c92dab8ee@clyso.com

Changes in v2:
- keep CEPH_FEATURE_MDS_INLINE_DATA always defined as (1ULL << 40)
  so decode logic can still check MDS feature bits; gate the
  supported features set via CEPH_FEATURE_MDS_INLINE_DATA_DEFAULT
- Link to v1: https://patch.msgid.link/20260728-b4-ceph-remove-inline-data-v1-1-8ffa7e08459a@clyso.com

To: Ilya Dryomov <idryomov@gmail.com>
To: Alex Markuze <amarkuze@redhat.com>
To: Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 fs/ceph/Kconfig                    | 12 ++++++++
 fs/ceph/addr.c                     | 13 +++++++--
 fs/ceph/caps.c                     | 42 +++++++++++++++++++++------
 fs/ceph/inode.c                    |  6 ++--
 fs/ceph/mds_client.c               | 45 ++++++++++++++++++++++-------
 fs/ceph/snap.c                     |  2 +-
 fs/ceph/super.h                    | 59 ++++++++++++++++++++++++++++++++++----
 include/linux/ceph/ceph_features.h | 14 ++++++++-
 include/linux/ceph/ceph_fs.h       |  5 ++++
 9 files changed, 166 insertions(+), 32 deletions(-)

diff --git a/fs/ceph/Kconfig b/fs/ceph/Kconfig
index 3d64a316ca31..be1c8ada5665 100644
--- a/fs/ceph/Kconfig
+++ b/fs/ceph/Kconfig
@@ -17,6 +17,18 @@ config CEPH_FS
 	  If unsure, say N.
 
 if CEPH_FS
+config CEPH_FS_INLINE_DATA
+	bool "Enable CephFS inline data support (deprecated)"
+	depends on CEPH_FS
+	default n
+	help
+	  Inline data support has been deprecated in the CephFS MDS
+	  and is being formally removed.  Existing inline data can be
+	  migrated to data pool objects via MDS scrub.  Choose N
+	  unless you have a legacy filesystem that requires it,
+	  and ensure all inline data has been migrated (see
+	  ceph fs set <fs> inline_data false) before enabling.
+
 config CEPH_FSCACHE
 	bool "Enable Ceph client caching support"
 	depends on CEPH_FS=m && FSCACHE || CEPH_FS=y && FSCACHE=y
diff --git a/fs/ceph/addr.c b/fs/ceph/addr.c
index c05bdf5d7273..39920e748eed 100644
--- a/fs/ceph/addr.c
+++ b/fs/ceph/addr.c
@@ -275,6 +275,7 @@ static void finish_netfs_read(struct ceph_osd_request *req)
 	ceph_dec_osd_stopping_blocker(fsc->mdsc);
 }
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 static bool ceph_netfs_issue_op_inline(struct netfs_io_subrequest *subreq)
 {
 	struct netfs_io_request *rreq = subreq->rreq;
@@ -336,6 +337,12 @@ static bool ceph_netfs_issue_op_inline(struct netfs_io_subrequest *subreq)
 	netfs_read_subreq_terminated(subreq);
 	return true;
 }
+#else
+static bool ceph_netfs_issue_op_inline(struct netfs_io_subrequest *subreq)
+{
+	return false;
+}
+#endif /* CONFIG_CEPH_FS_INLINE_DATA */
 
 static int ceph_netfs_prepare_read(struct netfs_io_subrequest *subreq)
 {
@@ -2195,6 +2202,7 @@ static vm_fault_t ceph_page_mkwrite(struct vm_fault *vmf)
 	return ret;
 }
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 void ceph_fill_inline_data(struct inode *inode, struct page *locked_page,
 			   char	*data, size_t len)
 {
@@ -2258,7 +2266,7 @@ int ceph_uninline_data(struct file *file)
 	u64 len;
 
 	spin_lock(&ci->i_ceph_lock);
-	inline_version = ci->i_inline_version;
+	inline_version = ceph_inline_version(ci);
 	spin_unlock(&ci->i_ceph_lock);
 
 	doutc(cl, "%llx.%llx inline_version %llu\n", ceph_vinop(inode),
@@ -2374,7 +2382,7 @@ int ceph_uninline_data(struct file *file)
 		/* Set to CAP_INLINE_NONE and dirty the caps */
 		down_read(&fsc->mdsc->snap_rwsem);
 		spin_lock(&ci->i_ceph_lock);
-		ci->i_inline_version = CEPH_INLINE_NONE;
+		ceph_set_inline_version(ci, CEPH_INLINE_NONE);
 		dirty = __ceph_mark_dirty_caps(ci, CEPH_CAP_FILE_WR, &prealloc_cf);
 		spin_unlock(&ci->i_ceph_lock);
 		up_read(&fsc->mdsc->snap_rwsem);
@@ -2397,6 +2405,7 @@ int ceph_uninline_data(struct file *file)
 	      ceph_vinop(inode), inline_version, err);
 	return err;
 }
+#endif /* CONFIG_CEPH_FS_INLINE_DATA */
 
 static const struct vm_operations_struct ceph_vmops = {
 	.fault		= ceph_filemap_fault,
diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index 6466e11ca783..56910749b860 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -1525,7 +1525,7 @@ static void __prep_cap(struct cap_msg_args *arg, struct ceph_inode_info *ci,
 	arg->gid = inode->i_gid;
 	arg->mode = inode->i_mode;
 
-	arg->inline_data = ci->i_inline_version != CEPH_INLINE_NONE;
+	arg->inline_data = ceph_inline_version(ci) != CEPH_INLINE_NONE;
 	if (!(flags & CEPH_CLIENT_CAPS_PENDING_CAPSNAP) &&
 	    !list_empty(&ci->i_cap_snaps)) {
 		struct ceph_cap_snap *capsnap;
@@ -3589,6 +3589,32 @@ struct cap_extra_info {
 	u64 fscrypt_file_size;
 };
 
+/*
+ * Cap grant messages (msg_version >= 4) always carry inline_version
+ * followed by inline_data.  With inline data support disabled we still
+ * have to consume the fields, we just don't keep the data around.
+ */
+static int parse_inline_data(void **p, void *end,
+			     struct cap_extra_info *extra_info)
+{
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
+	ceph_decode_64_safe(p, end, extra_info->inline_version, bad);
+	ceph_decode_32_safe(p, end, extra_info->inline_len, bad);
+	ceph_decode_need(p, end, extra_info->inline_len, bad);
+	extra_info->inline_data = *p;
+	*p += extra_info->inline_len;
+#else
+	u32 len;
+
+	ceph_decode_skip_64(p, end, bad);
+	ceph_decode_32_safe(p, end, len, bad);
+	ceph_decode_skip_n(p, end, len, bad);
+#endif
+	return 0;
+bad:
+	return -EIO;
+}
+
 /*
  * Handle a cap GRANT message from the MDS.  (Note that a GRANT may
  * actually be a revocation if it specifies a smaller cap set.)
@@ -3902,9 +3928,9 @@ static void handle_cap_grant(struct inode *inode,
 	}
 
 	if (extra_info->inline_version > 0 &&
-	    extra_info->inline_version >= ci->i_inline_version) {
-		ci->i_inline_version = extra_info->inline_version;
-		if (ci->i_inline_version != CEPH_INLINE_NONE &&
+	    extra_info->inline_version >= ceph_inline_version(ci)) {
+		ceph_set_inline_version(ci, extra_info->inline_version);
+		if (extra_info->inline_version != CEPH_INLINE_NONE &&
 		    (newcaps & (CEPH_CAP_FILE_CACHE|CEPH_CAP_FILE_LAZYIO)))
 			fill_inline = true;
 	}
@@ -4496,6 +4522,7 @@ void ceph_handle_caps(struct ceph_mds_session *session,
 	struct ceph_snap_realm *realm = NULL;
 	int op;
 	int msg_version = le16_to_cpu(msg->hdr.version);
+	int err;
 	u32 seq, mseq, issue_seq;
 	struct ceph_vino vino;
 	void *snaptrace;
@@ -4547,12 +4574,9 @@ void ceph_handle_caps(struct ceph_mds_session *session,
 	}
 
 	if (msg_version >= 4) {
-		ceph_decode_64_safe(&p, end, extra_info.inline_version, bad);
-		ceph_decode_32_safe(&p, end, extra_info.inline_len, bad);
-		if (p + extra_info.inline_len > end)
+		err = parse_inline_data(&p, end, &extra_info);
+		if (err < 0)
 			goto bad;
-		extra_info.inline_data = p;
-		p += extra_info.inline_len;
 	}
 
 	if (msg_version >= 5) {
diff --git a/fs/ceph/inode.c b/fs/ceph/inode.c
index d52e2b389e0b..152f22cecc7f 100644
--- a/fs/ceph/inode.c
+++ b/fs/ceph/inode.c
@@ -627,7 +627,7 @@ struct inode *ceph_alloc_inode(struct super_block *sb)
 	spin_lock_init(&ci->i_ceph_lock);
 
 	ci->i_version = 0;
-	ci->i_inline_version = 0;
+	ceph_set_inline_version(ci, 0);
 	ci->i_time_warp_seq = 0;
 	ci->i_ceph_flags = 0;
 	atomic64_set(&ci->i_ordered_count, 1);
@@ -1363,9 +1363,9 @@ int ceph_fill_inode(struct inode *inode, struct page *locked_page,
 	}
 
 	if (iinfo->inline_version > 0 &&
-	    iinfo->inline_version >= ci->i_inline_version) {
+	    iinfo->inline_version >= ceph_inline_version(ci)) {
 		int cache_caps = CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_LAZYIO;
-		ci->i_inline_version = iinfo->inline_version;
+		ceph_set_inline_version(ci, iinfo->inline_version);
 		if (ceph_has_inline_data(ci) &&
 		    (locked_page || (info_caps & cache_caps)))
 			fill_inline = true;
diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index 2fdef73b28f4..c675087ccf3d 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -114,6 +114,32 @@ static int parse_reply_info_quota(void **p, void *end,
 	return -EIO;
 }
 
+/*
+ * Decode the inline_version + inline_data fields the MDS puts into
+ * reply inodes.  With inline data support disabled we still have to
+ * consume them, we just don't keep the data around.
+ */
+static int parse_reply_info_inline_data(void **p, void *end,
+					struct ceph_mds_reply_info_in *info)
+{
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
+	ceph_decode_64_safe(p, end, info->inline_version, bad);
+	ceph_decode_32_safe(p, end, info->inline_len, bad);
+	ceph_decode_need(p, end, info->inline_len, bad);
+	info->inline_data = *p;
+	*p += info->inline_len;
+#else
+	u32 len;
+
+	ceph_decode_skip_64(p, end, bad);
+	ceph_decode_32_safe(p, end, len, bad);
+	ceph_decode_skip_n(p, end, len, bad);
+#endif
+	return 0;
+bad:
+	return -EIO;
+}
+
 static int parse_reply_info_in(void **p, void *end,
 			       struct ceph_mds_reply_info_in *info,
 			       u64 features,
@@ -158,11 +184,9 @@ static int parse_reply_info_in(void **p, void *end,
 
 	if (features == (u64)-1) {
 		/* inline data */
-		ceph_decode_64_safe(p, end, info->inline_version, bad);
-		ceph_decode_32_safe(p, end, info->inline_len, bad);
-		ceph_decode_need(p, end, info->inline_len, bad);
-		info->inline_data = *p;
-		*p += info->inline_len;
+		err = parse_reply_info_inline_data(p, end, info);
+		if (err < 0)
+			goto out_bad;
 		/* quota */
 		err = parse_reply_info_quota(p, end, info);
 		if (err < 0)
@@ -278,13 +302,12 @@ static int parse_reply_info_in(void **p, void *end,
 	} else {
 		/* legacy (unversioned) struct */
 		if (features & CEPH_FEATURE_MDS_INLINE_DATA) {
-			ceph_decode_64_safe(p, end, info->inline_version, bad);
-			ceph_decode_32_safe(p, end, info->inline_len, bad);
-			ceph_decode_need(p, end, info->inline_len, bad);
-			info->inline_data = *p;
-			*p += info->inline_len;
-		} else
+			err = parse_reply_info_inline_data(p, end, info);
+			if (err < 0)
+				goto out_bad;
+		} else {
 			info->inline_version = CEPH_INLINE_NONE;
+		}
 
 		if (features & CEPH_FEATURE_MDS_QUOTA) {
 			err = parse_reply_info_quota(p, end, info);
diff --git a/fs/ceph/snap.c b/fs/ceph/snap.c
index e5d8d59ffc17..df2aadc60b60 100644
--- a/fs/ceph/snap.c
+++ b/fs/ceph/snap.c
@@ -613,7 +613,7 @@ static void ceph_queue_cap_snap(struct ceph_inode_info *ci,
 		capsnap->xattr_version = 0;
 	}
 
-	capsnap->inline_data = ci->i_inline_version != CEPH_INLINE_NONE;
+	capsnap->inline_data = ceph_inline_version(ci) != CEPH_INLINE_NONE;
 
 	/* dirty page count moved from _head to this cap_snap;
 	   all subsequent writes page dirties occur _after_ this
diff --git a/fs/ceph/super.h b/fs/ceph/super.h
index 0a779cdc8392..8712ccc3dfc9 100644
--- a/fs/ceph/super.h
+++ b/fs/ceph/super.h
@@ -394,7 +394,9 @@ struct ceph_inode_info {
 	spinlock_t i_ceph_lock;
 
 	u64 i_version;
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	u64 i_inline_version;
+#endif
 	u32 i_time_warp_seq;
 
 	unsigned long i_ceph_flags;
@@ -1376,15 +1378,64 @@ extern void __ceph_touch_fmode(struct ceph_inode_info *ci,
 extern const struct address_space_operations ceph_aops;
 extern const struct netfs_request_ops ceph_netfs_ops;
 int ceph_mmap_prepare(struct vm_area_desc *desc);
-extern int ceph_uninline_data(struct file *file);
 extern int ceph_pool_perm_check(struct inode *inode, int need);
 extern void ceph_pool_perm_destroy(struct ceph_mds_client* mdsc);
 int ceph_purge_inode_cap(struct inode *inode, struct ceph_cap *cap, bool *invalidate);
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
+extern int ceph_uninline_data(struct file *file);
+extern void ceph_fill_inline_data(struct inode *inode, struct page *locked_page,
+				  char *data, size_t len);
+
+static inline u64 ceph_inline_version(struct ceph_inode_info *ci)
+{
+	return ci->i_inline_version;
+}
+
+static inline void ceph_set_inline_version(struct ceph_inode_info *ci,
+					   u64 version)
+{
+	ci->i_inline_version = version;
+}
+#else
+/*
+ * Only ever called under ceph_has_inline_data(), which is a constant
+ * false here, so this is unreachable; 0 keeps the error paths above
+ * simple without implying anything was done.
+ */
+static inline int ceph_uninline_data(struct file *file)
+{
+	return 0;
+}
+
+static inline void ceph_fill_inline_data(struct inode *inode,
+					 struct page *locked_page,
+					 char *data, size_t len)
+{
+}
+
+/*
+ * Without inline data support an inode never has any, so report the
+ * version the MDS uses for "no inline data" and ignore any update.
+ * This constant-folds all the inline data handling away.
+ */
+static inline u64 ceph_inline_version(struct ceph_inode_info *ci)
+{
+	return CEPH_INLINE_NONE;
+}
+
+static inline void ceph_set_inline_version(struct ceph_inode_info *ci,
+					   u64 version)
+{
+}
+#endif /* CONFIG_CEPH_FS_INLINE_DATA */
+
 static inline bool ceph_has_inline_data(struct ceph_inode_info *ci)
 {
-	if (ci->i_inline_version == CEPH_INLINE_NONE ||
-	    ci->i_inline_version == 1) /* initial version, no data */
+	u64 version = ceph_inline_version(ci);
+
+	if (version == CEPH_INLINE_NONE ||
+	    version == 1) /* initial version, no data */
 		return false;
 	return true;
 }
@@ -1400,8 +1451,6 @@ extern ssize_t __ceph_sync_read(struct inode *inode, loff_t *ki_pos,
 				struct iov_iter *to, int *retry_op,
 				u64 *last_objver);
 extern int ceph_release(struct inode *inode, struct file *filp);
-extern void ceph_fill_inline_data(struct inode *inode, struct page *locked_page,
-				  char *data, size_t len);
 
 /* dir.c */
 extern const struct file_operations ceph_dir_fops;
diff --git a/include/linux/ceph/ceph_features.h b/include/linux/ceph/ceph_features.h
index 3a47acd9cc14..1e4dce93a8a1 100644
--- a/include/linux/ceph/ceph_features.h
+++ b/include/linux/ceph/ceph_features.h
@@ -173,6 +173,18 @@ DEFINE_CEPH_FEATURE(62, 1, RESERVED)           // do not use; used as a sentinal
 DEFINE_CEPH_FEATURE_DEPRECATED(63, 1, RESERVED_BROKEN, LUMINOUS) // client-facing
 
 
+/*
+ * Only advertise CEPH_FEATURE_MDS_INLINE_DATA when inline data support is
+ * built in.  Without it the MDS refuses to hand out files that still have
+ * inline data instead of letting the client read the data pool objects
+ * that do not hold it yet.
+ */
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
+#define CEPH_FEATURE_MDS_INLINE_DATA_SUPPORTED	CEPH_FEATURE_MDS_INLINE_DATA
+#else
+#define CEPH_FEATURE_MDS_INLINE_DATA_SUPPORTED	0
+#endif
+
 /*
  * Features supported.
  */
@@ -204,7 +216,7 @@ DEFINE_CEPH_FEATURE_DEPRECATED(63, 1, RESERVED_BROKEN, LUMINOUS) // client-facin
 	 CEPH_FEATURE_CRUSH_V2 |		\
 	 CEPH_FEATURE_EXPORT_PEER |		\
 	 CEPH_FEATURE_OSDMAP_ENC |		\
-	 CEPH_FEATURE_MDS_INLINE_DATA |		\
+	 CEPH_FEATURE_MDS_INLINE_DATA_SUPPORTED |\
 	 CEPH_FEATURE_CRUSH_TUNABLES3 |		\
 	 CEPH_FEATURE_OSD_PRIMARY_AFFINITY |	\
 	 CEPH_FEATURE_MSGR_KEEPALIVE2 |		\
diff --git a/include/linux/ceph/ceph_fs.h b/include/linux/ceph/ceph_fs.h
index 69ac3e55a3fe..0adc526ec321 100644
--- a/include/linux/ceph/ceph_fs.h
+++ b/include/linux/ceph/ceph_fs.h
@@ -707,8 +707,13 @@ int ceph_flags_to_mode(int flags);
 				 CEPH_CAP_LINK_SHARED |	\
 				 CEPH_CAP_FILE_SHARED |	\
 				 CEPH_CAP_XATTR_SHARED)
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 #define CEPH_STAT_CAP_INLINE_DATA (CEPH_CAP_FILE_SHARED | \
 				   CEPH_CAP_FILE_RD)
+#else
+/* no inline data to fetch, so no extra caps are needed for it */
+#define CEPH_STAT_CAP_INLINE_DATA 0
+#endif
 #define CEPH_STAT_RSTAT CEPH_CAP_FILE_WREXTEND
 
 #define CEPH_CAP_ANY_SHARED (CEPH_CAP_AUTH_SHARED |			\

---
base-commit: 86f405187248b7a5a2104eba07f941d27593893e
change-id: 20260728-b4-ceph-remove-inline-data-d55c6466dd7e

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

