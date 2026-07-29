From: Xiubo Li <xiubo.li@clyso.com>
Date: Wed, 29 Jul 2026 09:28:41 +0800
Subject: [PATCH v2] ceph: remove the inline data support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-b4-ceph-remove-inline-data-v2-1-db0c92dab8ee@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NQQ6CMBBFr0Jm7RhooKAr72FYlHaQMdiSFhsJ4
 e4WvIDLl//z3gqBPFOAa7aCp8iBnU0gThnoQdkHIZvEIHIh81o02JWoaRrQ08vFtNqRLaFRs0J
 TVVqWUhpTEyTB5KnnzyG/tz8O7+5Jet6N+2PgMDu/HPVY7L+/QrHAApu+VzXlTVld1E2PS3Bn7
 V7Qbtv2BUi+7NrWAAAA
X-Change-ID: 20260728-b4-ceph-remove-inline-data-d55c6466dd7e
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785288528; l=21411;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=61MTytgmbQDmddZ4rqkPu9ae9lBPNJdCLDm1t8RVa4k=;
 b=+TTkDPIThnjTH3wUG2081SKut5KI9zOjXWyTOsQpOnMLi748bjohUJaDrjIllrY9KLwau0PVj
 /Iwbaa0FlIPBL9c3XBa6/mQhOcXcUdEeIkxkhv6i2OYGqYyvjzzlVyu
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Inline data support has been deprecated in the CephFS MDS and is
being formally removed.  Existing inline data can be migrated to
data pool objects via MDS scrub (see PR #44359).

Add CONFIG_CEPH_FS_INLINE_DATA (default n) to gate all inline data
code in the kclient.  When disabled, CEPH_FEATURE_MDS_INLINE_DATA
is defined as 0 so that the kclient no longer advertises the
feature to the MDS.  The MDS will then refuse to open files that
still have inline data, returning -EPERM, preventing silent data
corruption that would occur if the kclient tried to read inline
data from OSD objects that do not contain it.

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
Changes in v2:
- keep CEPH_FEATURE_MDS_INLINE_DATA always defined as (1ULL << 40)
  so decode logic can still check MDS feature bits; gate the
  supported features set via CEPH_FEATURE_MDS_INLINE_DATA_DEFAULT
- Link to v1: https://patch.msgid.link/20260728-b4-ceph-remove-inline-data-v1-1-8ffa7e08459a@clyso.com
---
 fs/ceph/Kconfig                    | 12 ++++++++++++
 fs/ceph/addr.c                     | 16 +++++++++++++++
 fs/ceph/caps.c                     | 40 +++++++++++++++++++++++++++++++++++++-
 fs/ceph/file.c                     | 20 +++++++++++++++++++
 fs/ceph/inode.c                    | 10 ++++++++++
 fs/ceph/mds_client.c               | 30 ++++++++++++++++++++++++++++
 fs/ceph/mds_client.h               |  2 ++
 fs/ceph/snap.c                     |  2 ++
 fs/ceph/super.h                    | 13 +++++++++++++
 include/linux/ceph/ceph_features.h |  7 ++++++-
 10 files changed, 150 insertions(+), 2 deletions(-)

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
index e2da3ab9f808..5211320a50ac 100644
--- a/fs/ceph/addr.c
+++ b/fs/ceph/addr.c
@@ -274,6 +274,7 @@ static void finish_netfs_read(struct ceph_osd_request *req)
 	ceph_dec_osd_stopping_blocker(fsc->mdsc);
 }
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 static bool ceph_netfs_issue_op_inline(struct netfs_io_subrequest *subreq)
 {
 	struct netfs_io_request *rreq = subreq->rreq;
@@ -335,6 +336,7 @@ static bool ceph_netfs_issue_op_inline(struct netfs_io_subrequest *subreq)
 	netfs_read_subreq_terminated(subreq);
 	return true;
 }
+#endif /* CONFIG_CEPH_FS_INLINE_DATA */
 
 static int ceph_netfs_prepare_read(struct netfs_io_subrequest *subreq)
 {
@@ -372,8 +374,10 @@ static void ceph_netfs_issue_read(struct netfs_io_subrequest *subreq)
 		goto out;
 	}
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	if (ceph_has_inline_data(ci) && ceph_netfs_issue_op_inline(subreq))
 		return;
+#endif
 
 	// TODO: This rounding here is slightly dodgy.  It *should* work, for
 	// now, as the cache only deals in blocks that are a multiple of
@@ -2006,7 +2010,11 @@ static vm_fault_t ceph_filemap_fault(struct vm_fault *vmf)
 	      off, ceph_cap_string(got));
 
 	if ((got & (CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_LAZYIO)) ||
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	    !ceph_has_inline_data(ci)) {
+#else
+	    true) {
+#endif
 		CEPH_DEFINE_RW_CONTEXT(rw_ctx, got);
 		ceph_add_rw_context(fi, &rw_ctx);
 		ret = filemap_fault(vmf);
@@ -2037,7 +2045,11 @@ static vm_fault_t ceph_filemap_fault(struct vm_fault *vmf)
 			goto out_inline;
 		}
 		err = __ceph_do_getattr(inode, page,
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 					 CEPH_STAT_CAP_INLINE_DATA, true);
+#else
+					 0, true);
+#endif
 		if (err < 0 || off >= i_size_read(inode)) {
 			unlock_page(page);
 			put_page(page);
@@ -2168,6 +2180,7 @@ static vm_fault_t ceph_page_mkwrite(struct vm_fault *vmf)
 	return ret;
 }
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 void ceph_fill_inline_data(struct inode *inode, struct page *locked_page,
 			   char	*data, size_t len)
 {
@@ -2214,7 +2227,9 @@ void ceph_fill_inline_data(struct inode *inode, struct page *locked_page,
 		put_page(page);
 	}
 }
+#endif /* CONFIG_CEPH_FS_INLINE_DATA */
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 int ceph_uninline_data(struct file *file)
 {
 	struct inode *inode = file_inode(file);
@@ -2370,6 +2385,7 @@ int ceph_uninline_data(struct file *file)
 	      ceph_vinop(inode), inline_version, err);
 	return err;
 }
+#endif /* CONFIG_CEPH_FS_INLINE_DATA */
 
 static const struct vm_operations_struct ceph_vmops = {
 	.fault		= ceph_filemap_fault,
diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index f8d898ad091e..2fd2116a3308 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -1266,7 +1266,9 @@ struct cap_msg_args {
 	kuid_t			uid;
 	kgid_t			gid;
 	umode_t			mode;
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	bool			inline_data;
+#endif
 	bool			wake;
 	bool			encrypted;
 	u32			fscrypt_auth_len;
@@ -1336,8 +1338,16 @@ static void encode_cap_msg(struct ceph_msg *msg, struct cap_msg_args *arg)
 	p = fc + 1;
 	/* flock buffer size (version 2) */
 	ceph_encode_32(&p, 0);
-	/* inline version (version 4) */
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	ceph_encode_64(&p, arg->inline_data ? 0 : CEPH_INLINE_NONE);
+#else
+	/*
+	 * Inline data support has been removed.  The field is still
+	 * encoded for protocol compatibility; always advertise
+	 * CEPH_INLINE_NONE to indicate no inline data is present.
+	 */
+	ceph_encode_64(&p, CEPH_INLINE_NONE);
+#endif
 	/* inline data size */
 	ceph_encode_32(&p, 0);
 	/*
@@ -1499,7 +1509,9 @@ static void __prep_cap(struct cap_msg_args *arg, struct ceph_cap *cap,
 	arg->gid = inode->i_gid;
 	arg->mode = inode->i_mode;
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	arg->inline_data = ci->i_inline_version != CEPH_INLINE_NONE;
+#endif
 	if (!(flags & CEPH_CLIENT_CAPS_PENDING_CAPSNAP) &&
 	    !list_empty(&ci->i_cap_snaps)) {
 		struct ceph_cap_snap *capsnap;
@@ -1620,7 +1632,9 @@ static inline int __send_flush_snap(struct inode *inode,
 	arg.gid = capsnap->gid;
 	arg.mode = capsnap->mode;
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	arg.inline_data = capsnap->inline_data;
+#endif
 	arg.flags = 0;
 	arg.wake = false;
 	arg.encrypted = IS_ENCRYPTED(inode);
@@ -3192,6 +3206,7 @@ int __ceph_get_caps(struct inode *inode, struct ceph_file_info *fi, int need,
 			return ret;
 		}
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 		if (S_ISREG(ci->netfs.inode.i_mode) &&
 		    ceph_has_inline_data(ci) &&
 		    (_got & (CEPH_CAP_FILE_CACHE|CEPH_CAP_FILE_LAZYIO)) &&
@@ -3223,6 +3238,7 @@ int __ceph_get_caps(struct inode *inode, struct ceph_file_info *fi, int need,
 				return ret;
 			continue;
 		}
+#endif
 		break;
 	}
 	*got = _got;
@@ -3518,10 +3534,12 @@ static void invalidate_aliases(struct inode *inode)
 
 struct cap_extra_info {
 	struct ceph_string *pool_ns;
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	/* inline data */
 	u64 inline_version;
 	void *inline_data;
 	u32 inline_len;
+#endif
 	/* dirstat */
 	bool dirstat_valid;
 	u64 nfiles;
@@ -3564,7 +3582,9 @@ static void handle_cap_grant(struct inode *inode,
 	bool queue_trunc = false;
 	bool queue_invalidate = false;
 	bool deleted_inode = false;
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	bool fill_inline = false;
+#endif
 	bool revoke_wait = false;
 	int flags = 0;
 
@@ -3830,6 +3850,7 @@ static void handle_cap_grant(struct inode *inode,
 			check_caps = 2; /* check all caps */
 	}
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	if (extra_info->inline_version > 0 &&
 	    extra_info->inline_version >= ci->i_inline_version) {
 		ci->i_inline_version = extra_info->inline_version;
@@ -3837,6 +3858,7 @@ static void handle_cap_grant(struct inode *inode,
 		    (newcaps & (CEPH_CAP_FILE_CACHE|CEPH_CAP_FILE_LAZYIO)))
 			fill_inline = true;
 	}
+#endif
 
 	if (le32_to_cpu(grant->op) == CEPH_CAP_OP_IMPORT) {
 		if (ci->i_auth_cap == cap) {
@@ -3856,9 +3878,11 @@ static void handle_cap_grant(struct inode *inode,
 	}
 	spin_unlock(&ci->i_ceph_lock);
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	if (fill_inline)
 		ceph_fill_inline_data(inode, NULL, extra_info->inline_data,
 				      extra_info->inline_len);
+#endif
 
 	if (queue_trunc)
 		ceph_queue_vmtruncate(inode);
@@ -4476,12 +4500,26 @@ void ceph_handle_caps(struct ceph_mds_session *session,
 	}
 
 	if (msg_version >= 4) {
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 		ceph_decode_64_safe(&p, end, extra_info.inline_version, bad);
 		ceph_decode_32_safe(&p, end, extra_info.inline_len, bad);
 		if (p + extra_info.inline_len > end)
 			goto bad;
 		extra_info.inline_data = p;
 		p += extra_info.inline_len;
+#else
+		/*
+		 * Inline data support has been removed, but cap grant
+		 * messages (msg_version >= 4) always carry inline_version
+		 * + inline_data.  We must consume the fields to keep the
+		 * decode pointer in sync.
+		 */
+		u32 __len;
+
+		ceph_decode_skip_64(&p, end, bad);
+		ceph_decode_32_safe(&p, end, __len, bad);
+		ceph_decode_skip_n(&p, end, __len, bad);
+#endif
 	}
 
 	if (msg_version >= 5) {
diff --git a/fs/ceph/file.c b/fs/ceph/file.c
index 3823671ab95a..901ed97b1963 100644
--- a/fs/ceph/file.c
+++ b/fs/ceph/file.c
@@ -224,7 +224,9 @@ static int ceph_init_file_info(struct inode *inode, struct file *file,
 		ceph_inode_to_fs_client(&ci->netfs.inode)->mount_options;
 	struct ceph_client *cl = ceph_inode_to_client(inode);
 	struct ceph_file_info *fi;
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	int ret;
+#endif
 
 	doutc(cl, "%p %llx.%llx %p 0%o (%s)\n", inode, ceph_vinop(inode),
 	      file, inode->i_mode, isdir ? "dir" : "regular");
@@ -258,14 +260,17 @@ static int ceph_init_file_info(struct inode *inode, struct file *file,
 	INIT_LIST_HEAD(&fi->rw_contexts);
 	fi->filp_gen = READ_ONCE(ceph_inode_to_fs_client(inode)->filp_gen);
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	if ((file->f_mode & FMODE_WRITE) && ceph_has_inline_data(ci)) {
 		ret = ceph_uninline_data(file);
 		if (ret < 0)
 			goto error;
 	}
+#endif
 
 	return 0;
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 error:
 	ceph_fscache_unuse_cookie(inode, file->f_mode & FMODE_WRITE);
 	ceph_put_fmode(ci, fi->fmode, 1);
@@ -273,6 +278,7 @@ static int ceph_init_file_info(struct inode *inode, struct file *file,
 	/* wake up anyone waiting for caps on this inode */
 	wake_up_all(&ci->i_cap_wq);
 	return ret;
+#endif
 }
 
 /*
@@ -702,7 +708,9 @@ static int ceph_finish_async_create(struct inode *dir, struct inode *inode,
 
 	ktime_get_real_ts64(&now);
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	iinfo.inline_version = CEPH_INLINE_NONE;
+#endif
 	iinfo.change_attr = 1;
 	ceph_encode_timespec64(&iinfo.btime, &now);
 
@@ -2224,7 +2232,11 @@ static ssize_t ceph_read_iter(struct kiocb *iocb, struct iov_iter *to)
 		      inode, ceph_vinop(inode), iocb->ki_pos, (unsigned)len,
 		      ceph_cap_string(got));
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 		if (!ceph_has_inline_data(ci)) {
+#else
+		if (true) {
+#endif
 			if (!retry_op &&
 			    (iocb->ki_flags & IOCB_DIRECT) &&
 			    !IS_ENCRYPTED(inode)) {
@@ -2267,7 +2279,11 @@ static ssize_t ceph_read_iter(struct kiocb *iocb, struct iov_iter *to)
 			if (!page)
 				return -ENOMEM;
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 			mask = CEPH_STAT_CAP_INLINE_DATA;
+#else
+			mask = 0;
+#endif
 		}
 
 		statret = __ceph_do_getattr(inode, page, mask, !!page);
@@ -2349,8 +2365,12 @@ static ssize_t ceph_splice_read(struct file *in, loff_t *ppos,
 	if (ceph_inode_is_shutdown(inode))
 		return -ESTALE;
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	if (ceph_has_inline_data(ci) ||
 	    (fi->flags & CEPH_F_SYNC))
+#else
+	if (fi->flags & CEPH_F_SYNC)
+#endif
 		return copy_splice_read(in, ppos, pipe, len, flags);
 
 	ret = ceph_start_io_read(inode);
diff --git a/fs/ceph/inode.c b/fs/ceph/inode.c
index 61d7c0b8161f..20abf7dc9c64 100644
--- a/fs/ceph/inode.c
+++ b/fs/ceph/inode.c
@@ -627,7 +627,9 @@ struct inode *ceph_alloc_inode(struct super_block *sb)
 	spin_lock_init(&ci->i_ceph_lock);
 
 	ci->i_version = 0;
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	ci->i_inline_version = 0;
+#endif
 	ci->i_time_warp_seq = 0;
 	ci->i_ceph_flags = 0;
 	atomic64_set(&ci->i_ordered_count, 1);
@@ -1030,7 +1032,9 @@ int ceph_fill_inode(struct inode *inode, struct page *locked_page,
 	bool wake = false;
 	bool queue_trunc = false;
 	bool new_version = false;
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	bool fill_inline = false;
+#endif
 	umode_t mode = le32_to_cpu(info->mode);
 	dev_t rdev = le32_to_cpu(info->rdev);
 
@@ -1362,6 +1366,7 @@ int ceph_fill_inode(struct inode *inode, struct page *locked_page,
 		}
 	}
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	if (iinfo->inline_version > 0 &&
 	    iinfo->inline_version >= ci->i_inline_version) {
 		int cache_caps = CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_LAZYIO;
@@ -1370,6 +1375,7 @@ int ceph_fill_inode(struct inode *inode, struct page *locked_page,
 		    (locked_page || (info_caps & cache_caps)))
 			fill_inline = true;
 	}
+#endif
 
 	if (cap_fmode >= 0) {
 		if (!info_caps)
@@ -1382,9 +1388,11 @@ int ceph_fill_inode(struct inode *inode, struct page *locked_page,
 
 	ceph_fscache_register_inode_cookie(inode);
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	if (fill_inline)
 		ceph_fill_inline_data(inode, locked_page,
 				      iinfo->inline_data, iinfo->inline_len);
+#endif
 
 	if (wake)
 		wake_up_all(&ci->i_cap_wq);
@@ -3022,6 +3030,7 @@ int __ceph_do_getattr(struct inode *inode, struct page *locked_page,
 	req->r_args.getattr.mask = cpu_to_le32(mask);
 	req->r_locked_page = locked_page;
 	err = ceph_mdsc_do_request(mdsc, NULL, req);
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	if (locked_page && err == 0) {
 		u64 inline_version = req->r_reply_info.targeti.inline_version;
 		if (inline_version == 0) {
@@ -3034,6 +3043,7 @@ int __ceph_do_getattr(struct inode *inode, struct page *locked_page,
 			err = req->r_reply_info.targeti.inline_len;
 		}
 	}
+#endif
 	ceph_mdsc_put_request(req);
 	doutc(cl, "result=%d\n", err);
 	return err;
diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index 18be36c2e9e8..6a439da76616 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -156,12 +156,26 @@ static int parse_reply_info_in(void **p, void *end,
 	*p += info->xattr_len;
 
 	if (features == (u64)-1) {
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 		/* inline data */
 		ceph_decode_64_safe(p, end, info->inline_version, bad);
 		ceph_decode_32_safe(p, end, info->inline_len, bad);
 		ceph_decode_need(p, end, info->inline_len, bad);
 		info->inline_data = *p;
 		*p += info->inline_len;
+#else
+		/*
+		 * Inline data support has been removed, but the MDS always
+		 * encodes inline_version + inline_data in versioned replies.
+		 * We must consume these fields from the message to keep the
+		 * decode pointer in sync, even though we discard them.
+		 */
+		u32 __len;
+
+		ceph_decode_skip_64(p, end, bad);
+		ceph_decode_32_safe(p, end, __len, bad);
+		ceph_decode_skip_n(p, end, __len, bad);
+#endif
 		/* quota */
 		err = parse_reply_info_quota(p, end, info);
 		if (err < 0)
@@ -276,6 +290,7 @@ static int parse_reply_info_in(void **p, void *end,
 		*p = end;
 	} else {
 		/* legacy (unversioned) struct */
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 		if (features & CEPH_FEATURE_MDS_INLINE_DATA) {
 			ceph_decode_64_safe(p, end, info->inline_version, bad);
 			ceph_decode_32_safe(p, end, info->inline_len, bad);
@@ -284,6 +299,21 @@ static int parse_reply_info_in(void **p, void *end,
 			*p += info->inline_len;
 		} else
 			info->inline_version = CEPH_INLINE_NONE;
+#else
+		/*
+		 * Inline data support has been removed.  When the MDS
+		 * advertises CEPH_FEATURE_MDS_INLINE_DATA it includes
+		 * inline_version + inline_data in legacy replies.  We
+		 * must consume them to keep the decode pointer in sync.
+		 */
+		if (features & CEPH_FEATURE_MDS_INLINE_DATA) {
+			u32 __len;
+
+			ceph_decode_skip_64(p, end, bad);
+			ceph_decode_32_safe(p, end, __len, bad);
+			ceph_decode_skip_n(p, end, __len, bad);
+		}
+#endif
 
 		if (features & CEPH_FEATURE_MDS_QUOTA) {
 			err = parse_reply_info_quota(p, end, info);
diff --git a/fs/ceph/mds_client.h b/fs/ceph/mds_client.h
index 731d6ad04956..9bcf1a9d5ba8 100644
--- a/fs/ceph/mds_client.h
+++ b/fs/ceph/mds_client.h
@@ -149,9 +149,11 @@ struct ceph_mds_reply_info_in {
 	char *symlink;
 	u32 xattr_len;
 	char *xattr_data;
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	u64 inline_version;
 	u32 inline_len;
 	char *inline_data;
+#endif
 	u32 pool_ns_len;
 	char *pool_ns_data;
 	u64 max_bytes;
diff --git a/fs/ceph/snap.c b/fs/ceph/snap.c
index e5d8d59ffc17..3bc3a2ce72a2 100644
--- a/fs/ceph/snap.c
+++ b/fs/ceph/snap.c
@@ -613,7 +613,9 @@ static void ceph_queue_cap_snap(struct ceph_inode_info *ci,
 		capsnap->xattr_version = 0;
 	}
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	capsnap->inline_data = ci->i_inline_version != CEPH_INLINE_NONE;
+#endif
 
 	/* dirty page count moved from _head to this cap_snap;
 	   all subsequent writes page dirties occur _after_ this
diff --git a/fs/ceph/super.h b/fs/ceph/super.h
index 3737ea7ed88b..eced08f52b79 100644
--- a/fs/ceph/super.h
+++ b/fs/ceph/super.h
@@ -274,7 +274,9 @@ struct ceph_cap_snap {
 	u32 truncate_seq;
 	int writing;   /* a sync write is still in progress */
 	int dirty_pages;     /* dirty pages awaiting writeback */
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	bool inline_data;
+#endif
 	bool need_flush;
 };
 
@@ -381,7 +383,9 @@ struct ceph_inode_info {
 	spinlock_t i_ceph_lock;
 
 	u64 i_version;
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 	u64 i_inline_version;
+#endif
 	u32 i_time_warp_seq;
 
 	unsigned long i_ceph_flags;
@@ -1335,11 +1339,14 @@ extern void __ceph_touch_fmode(struct ceph_inode_info *ci,
 extern const struct address_space_operations ceph_aops;
 extern const struct netfs_request_ops ceph_netfs_ops;
 int ceph_mmap_prepare(struct vm_area_desc *desc);
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 extern int ceph_uninline_data(struct file *file);
+#endif
 extern int ceph_pool_perm_check(struct inode *inode, int need);
 extern void ceph_pool_perm_destroy(struct ceph_mds_client* mdsc);
 int ceph_purge_inode_cap(struct inode *inode, struct ceph_cap *cap, bool *invalidate);
 
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
 static inline bool ceph_has_inline_data(struct ceph_inode_info *ci)
 {
 	if (ci->i_inline_version == CEPH_INLINE_NONE ||
@@ -1347,6 +1354,12 @@ static inline bool ceph_has_inline_data(struct ceph_inode_info *ci)
 		return false;
 	return true;
 }
+#else
+static inline bool ceph_has_inline_data(struct ceph_inode_info *ci)
+{
+	return false;
+}
+#endif
 
 /* file.c */
 extern const struct file_operations ceph_file_fops;
diff --git a/include/linux/ceph/ceph_features.h b/include/linux/ceph/ceph_features.h
index 3a47acd9cc14..207b93787a4f 100644
--- a/include/linux/ceph/ceph_features.h
+++ b/include/linux/ceph/ceph_features.h
@@ -132,6 +132,11 @@ DEFINE_CEPH_FEATURE(38, 1, OSD_ERASURE_CODES)
 DEFINE_CEPH_FEATURE(38, 1, OSD_OSD_TMAP2OMAP) // overlap
 DEFINE_CEPH_FEATURE(39, 1, OSDMAP_ENC)
 DEFINE_CEPH_FEATURE(40, 1, MDS_INLINE_DATA)
+#ifdef CONFIG_CEPH_FS_INLINE_DATA
+#define CEPH_FEATURE_MDS_INLINE_DATA_DEFAULT	CEPH_FEATURE_MDS_INLINE_DATA
+#else
+#define CEPH_FEATURE_MDS_INLINE_DATA_DEFAULT	0
+#endif
 DEFINE_CEPH_FEATURE(41, 1, CRUSH_TUNABLES3)
 DEFINE_CEPH_FEATURE(41, 1, OSD_PRIMARY_AFFINITY) // overlap
 DEFINE_CEPH_FEATURE(42, 1, MSGR_KEEPALIVE2)
@@ -204,7 +209,7 @@ DEFINE_CEPH_FEATURE_DEPRECATED(63, 1, RESERVED_BROKEN, LUMINOUS) // client-facin
 	 CEPH_FEATURE_CRUSH_V2 |		\
 	 CEPH_FEATURE_EXPORT_PEER |		\
 	 CEPH_FEATURE_OSDMAP_ENC |		\
-	 CEPH_FEATURE_MDS_INLINE_DATA |		\
+	 CEPH_FEATURE_MDS_INLINE_DATA_DEFAULT |	\
 	 CEPH_FEATURE_CRUSH_TUNABLES3 |		\
 	 CEPH_FEATURE_OSD_PRIMARY_AFFINITY |	\
 	 CEPH_FEATURE_MSGR_KEEPALIVE2 |		\

---
base-commit: 602bb4525c8146865b7f6e44c81d54bf97861aed
change-id: 20260728-b4-ceph-remove-inline-data-d55c6466dd7e

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

