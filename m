From: Xiubo Li <xiubo.li@clyso.com>
Date: Wed, 19 Aug 2026 20:35:53 -0700
Subject: [PATCH v3] ceph: add 'lazyio' mount option to kclient
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260819-lazyio-v3-1-21110d37c4be@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WN0Q6CIBhGX8VxHQ0w+LGr3qN1oYBJM2lgLHO+e
 2BbtXV5tu+cb0bBeGsC2hcz8ibaYN2QoNwUSHX1cDbY6sSIESaIYBz39XOyDotKQgul4hxalMY
 3b1r7WEPH05vDvbkYNWY7LzobRuen9SnSvPuLRoop1g0tCUiQldYH1U/BbZW7ohyN7KsBoR+NJ
 a1SQoAUO0l486sty/ICQvTbCOUAAAA=
X-Change-ID: 20260625-lazyio-6987f73c557f
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787196957; l=18383;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=GsJ5PDZ5+TZxa9oeCA1lW0uuL//A9k7/aqzXiLOaWdE=;
 b=qFe2zLrxYLuIEmIqZ1ZLdsELWxvPdktXJMYSlqFYUQwsnQZbpXI5WmMEvER9eCmZyOMlmb2O+
 1MN3fYX9GSIAH9AUJYoBRkHT6UkorIIXUVzzrh1OJ5XRMS0L2sEPqes
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a 'lazyio' mount option to the kernel Ceph client that enables
LazyIO globally for all regular file opens on a mount. This is the
kclient equivalent of the 'client_force_lazyio=true' config option
in the ceph-fuse userspace client.

When 'lazyio' is specified, CEPH_FILE_MODE_LAZY is automatically
added to every regular file's fmode at open time in
ceph_init_file_info(), causing the I/O paths to request
CEPH_CAP_FILE_LAZYIO from the MDS. This permits buffered I/O via
the page cache even when multiple clients have the file open for
write — beneficial for HPC workloads that can tolerate relaxed
cache coherency.

The mount option is exposed as 'lazyio' / 'nolazyio' via the VFS
fsparam_flag_no mechanism and supports remount.

Link: https://tracker.ceph.com/issues/77594
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
Add a 'lazyio' mount option that enables LazyIO globally for all regular
file opens on a CephFS mount. This is the kclient equivalent of the
'client_force_lazyio=true' config option in ceph-fuse.

When 'lazyio' is specified, CEPH_FILE_MODE_LAZY is automatically set on
every regular file's fmode at open time. The I/O paths then request
CEPH_CAP_FILE_LAZYIO from the MDS, which permits buffered I/O via the
page cache even with concurrent writers — beneficial for HPC workloads
that can tolerate relaxed cache coherency.

The mount option supports 'lazyio' / 'nolazyio' via fsparam_flag_no
and can be changed at remount.

The following is a test report:

=== LazyIO Multi-Client Read Test ===
(B writes → MDS revokes CACHE from A; lazyio keeps LAZYIO → buffered reads)

  nolazyio: 200 MB in 0.63s -> 319.8 MB/s
  lazyio  : 200 MB in 0.24s -> 840.3 MB/s

=== IO500 tool ior test: ===
        nolazyio        lazyio
Write:  54.27 MB/s  ->  89.1 MB/s
Read:   165.48 MB/s ->  166.25

The ior closes the file between its write and read phases. After the write fd
closes, the client's wanted caps drop to LAZYIO only (no fds open; the clean
page cache's used caps are reported as LAZYIO), and the MDS treats LAZYIO wants
as non-notable — the lazy client is invisible to loner selection. The holder,
writing every 100 ms, then becomes the only notable client, so the MDS hands it
EXCL and revokes all caps from the lazy client (EXCL grants nothing to non-loners,
including LAZYIO). With neither CACHE nor LAZYIO, the client invalidates its
entire 4 GiB page cache. When the read phase reopens the file, the lock returns
to MIX and the caps work correctly, but the cache is gone — every 1 MiB read
goes to the OSD (~200 MiB/s instead of ~4 GiB/s page-cache hits).

In short: lazyio's read benefit depends on the page cache surviving; the close
window between phases lets the writer take EXCL for free, which invalidates the
cache.
---
Changes in v3:
- Rework try_get_cap_refs() so a missing LAZYIO never makes a want
  unsatisfiable and silently drops CACHE/BUFFER refs (degrading to sync I/O).
- Add ceph_adjust_caps_used_for_lazyio() and report LAZYIO in used caps to
  the MDS when it stands in for CACHE/BUFFER.
- In handle_cap_grant(), flush dirty data before acking an LAZYIO revoke,
  and invalidate when either CACHE or LAZYIO is revoked and neither remains.
- Define CEPH_O_LAZY as 00020000 (matching src/include/ceph_fs.h) and send
  it in the open request flags.
- Link to v2: https://patch.msgid.link/20260701-lazyio-v2-1-9c667864805b@clyso.com

Changes in v2:
- Move LAZYIO fmode addition from ceph_init_file_info() to ceph_open() before
  ceph_caps_for_mode(), so the MDS sees LAZYIO in the wanted caps at open time.
  Also cover ceph_atomic_open() for the writer path.
- Add ceph_adjust_caps_used_for_lazyio() to substitute LAZYIO for CACHE/BUFFER
  in used caps reported to MDS when those caps are not issued.
- Gate try_get_cap_refs() LAZYIO substitution on want & CEPH_CAP_FILE_LAZYIO
  so a non-lazy fd cannot have its consistency guarantees weakened by a lazy fd
  on the same inode.
- Separate revocation handling in handle_cap_grant(): BUFFER revocation always
  triggers writeback; LAZYIO revocation triggers writeback only when dirty data
  is held (i_wrbuffer_ref/i_wb_ref); clean cached pages fall through to the
  existing invalidation path.
- Add LAZYIO to ceph_init_request() so readahead works for lazy fds.
- Fix fmode propagation: use fmode instead of req->r_fmode in ceph_open() MDS
  path, and set req->r_fmode |= CEPH_FILE_MODE_LAZY for both ceph_open() and
  ceph_atomic_open().
- Remove dead #ifdef O_LAZY blocks in ceph_flags_to_mode() and ceph_renew_caps().
- Link to v1: https://patch.msgid.link/20260625-lazyio-v1-1-db13078789dd@clyso.com

To: Ilya Dryomov <idryomov@gmail.com>
To: Alex Markuze <amarkuze@redhat.com>
To: Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 fs/ceph/addr.c               |   4 ++
 fs/ceph/caps.c               | 105 +++++++++++++++++++++++++++++++++++++++----
 fs/ceph/file.c               |  33 +++++++++++---
 fs/ceph/super.c              |  15 +++++++
 fs/ceph/super.h              |   1 +
 fs/ceph/util.c               |   4 --
 include/linux/ceph/ceph_fs.h |   1 +
 7 files changed, 145 insertions(+), 18 deletions(-)

diff --git a/fs/ceph/addr.c b/fs/ceph/addr.c
index 0a86f672cc09..d22deb05b38a 100644
--- a/fs/ceph/addr.c
+++ b/fs/ceph/addr.c
@@ -491,6 +491,10 @@ static int ceph_init_request(struct netfs_io_request *rreq, struct file *file)
 			rreq->netfs_priv = priv;
 			return 0;
 		}
+
+		/* If this is a lazy fd, also try to get LAZYIO caps */
+		if (fi->fmode & CEPH_FILE_MODE_LAZY)
+			want |= CEPH_CAP_FILE_LAZYIO;
 	}
 
 	/*
diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index d51454e995a8..2e238ca2367b 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -999,6 +999,31 @@ int __ceph_caps_used(struct ceph_inode_info *ci)
 	return used;
 }
 
+/*
+ * Substitute LAZYIO for CACHE/BUFFER when they are not issued.
+ * If we have LAZYIO but not CACHE/BUFFER, report LAZYIO as used instead
+ * so the MDS knows we're fine with the weaker consistency guarantee.
+ */
+static inline int ceph_adjust_caps_used_for_lazyio(int used, int issued,
+					int implemented)
+{
+	if (!(used & (CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_BUFFER)))
+		return used;
+	if (!(implemented & CEPH_CAP_FILE_LAZYIO))
+		return used;
+	if (issued & CEPH_CAP_FILE_LAZYIO) {
+		if (!(issued & CEPH_CAP_FILE_CACHE)) {
+			used &= ~CEPH_CAP_FILE_CACHE;
+			used |= CEPH_CAP_FILE_LAZYIO;
+		}
+		if (!(issued & CEPH_CAP_FILE_BUFFER)) {
+			used &= ~CEPH_CAP_FILE_BUFFER;
+			used |= CEPH_CAP_FILE_LAZYIO;
+		}
+	}
+	return used;
+}
+
 #define FMODE_WAIT_BIAS 1000
 
 /*
@@ -2049,6 +2074,10 @@ void ceph_check_caps(struct ceph_inode_info *ci, int flags)
 	 * usually because they have outstanding references).
 	 */
 	issued = __ceph_caps_issued(ci, &implemented);
+
+	/* substitute LAZYIO for CACHE/BUFFER when they are not issued */
+	used = ceph_adjust_caps_used_for_lazyio(used, issued, implemented);
+
 	revoking = implemented & ~issued;
 
 	want = file_wanted;
@@ -2905,9 +2934,46 @@ static int try_get_cap_refs(struct inode *inode, int need, int want,
 				}
 				snap_rwsem_locked = true;
 			}
-			if ((have & want) == want)
+			/*
+			 * Allow LAZYIO to act as a substitute for
+			 * CACHE or BUFFER when those caps are not
+			 * issued, but only for callers that
+			 * explicitly requested LAZYIO.  This
+			 * prevents a non-lazy fd from having its
+			 * CACHE/BUFFER wants satisfied by LAZYIO
+			 * on an inode where a different fd is lazy.
+			 *
+			 * A missing LAZYIO cap, however, must never
+			 * cost us the CACHE/BUFFER refs that are
+			 * actually issued: the MDS only grants
+			 * LAZYIO for files opened with CEPH_O_LAZY
+			 * and it can be revoked at any time.  If we
+			 * made the whole want unsatisfiable without
+			 * it, the I/O paths would silently drop
+			 * CACHE/BUFFER (e.g. take no wrbuffer refs)
+			 * and degrade to synchronous writes.
+			 */
+			if ((have & (want & ~CEPH_CAP_FILE_LAZYIO)) ==
+			    (want & ~CEPH_CAP_FILE_LAZYIO)) {
+				*got = need | (want & ~exclude &
+					       ~CEPH_CAP_FILE_LAZYIO);
+				if ((want & CEPH_CAP_FILE_LAZYIO) &&
+				    (have & CEPH_CAP_FILE_LAZYIO) &&
+				    !(exclude & CEPH_CAP_FILE_LAZYIO))
+					*got |= CEPH_CAP_FILE_LAZYIO;
+			} else if ((want & CEPH_CAP_FILE_LAZYIO) &&
+				   (have & CEPH_CAP_FILE_LAZYIO) &&
+				   !(exclude & CEPH_CAP_FILE_LAZYIO) &&
+				   ((have & want) ==
+				    (want & ~(CEPH_CAP_FILE_CACHE |
+					      CEPH_CAP_FILE_BUFFER)))) {
+				/* LAZYIO substitutes for missing CACHE/BUFFER */
 				*got = need | (want & ~exclude);
-			else
+				if ((*got & CEPH_CAP_FILE_CACHE) &&
+				    !(have & CEPH_CAP_FILE_CACHE) &&
+				    (have & CEPH_CAP_FILE_LAZYIO))
+					*got |= CEPH_CAP_FILE_LAZYIO;
+			} else
 				*got = need;
 			ceph_take_cap_refs(ci, *got, true);
 			ret = 1;
@@ -3525,13 +3591,20 @@ static void handle_cap_grant(struct inode *inode,
 
 
 	/*
-	 * If CACHE is being revoked, and we have no dirty buffers,
-	 * try to invalidate (once).  (If there are dirty buffers, we
-	 * will invalidate _after_ writeback.)
+	 * Check the revocation of *both* CACHE and LAZYIO, because
+	 * CACHE may have been revoked earlier and cap->issued no
+	 * longer contains it -- at that point only LAZYIO was
+	 * covering us.  If LAZYIO is now also being revoked and no
+	 * cache cap remains, we must invalidate the page cache.
+	 * Without this, a CACHE-revoked-then-LAZYIO-revoked sequence
+	 * leaves stale pages in memory until the next periodic
+	 * check_caps (up to 60s).  Also invalidate when we have no
+	 * dirty buffers (if dirty, invalidate after writeback).
 	 */
 	if (S_ISREG(inode->i_mode) && /* don't invalidate readdir cache */
-	    ((cap->issued & ~newcaps) & CEPH_CAP_FILE_CACHE) &&
-	    (newcaps & CEPH_CAP_FILE_LAZYIO) == 0 &&
+	    ((cap->issued & ~newcaps) &
+	     (CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_LAZYIO)) &&
+	    !(newcaps & (CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_LAZYIO)) &&
 	    !(ci->i_wrbuffer_ref || ci->i_wb_ref)) {
 		if (try_nonblocking_invalidate(inode)) {
 			/* there were locked pages.. invalidate later
@@ -3675,6 +3748,7 @@ static void handle_cap_grant(struct inode *inode,
 	/* check cap bits */
 	wanted = __ceph_caps_wanted(ci);
 	used = __ceph_caps_used(ci);
+	used = ceph_adjust_caps_used_for_lazyio(used, cap->issued, cap->implemented);
 	dirty = __ceph_caps_dirty(ci);
 	doutc(cl, " my wanted = %s, used = %s, dirty %s\n",
 	      ceph_cap_string(wanted), ceph_cap_string(used),
@@ -3702,13 +3776,26 @@ static void handle_cap_grant(struct inode *inode,
 		doutc(cl, "revocation: %s -> %s (revoking %s)\n",
 		      ceph_cap_string(cap->issued), ceph_cap_string(newcaps),
 		      ceph_cap_string(revoking));
+		/*
+		 * If BUFFER is being revoked and we have dirty data,
+		 * trigger writeback before acking.  When LAZYIO was
+		 * covering for BUFFER (BUFFER not issued, dirty refs
+		 * held), also trigger writeback.  Clean cached pages
+		 * under LAZYIO are handled by queue_invalidate below.
+		 */
 		if (S_ISREG(inode->i_mode) &&
 		    (revoking & used & CEPH_CAP_FILE_BUFFER)) {
 			writeback = true;  /* initiate writeback; will delay ack */
 			revoke_wait = true;
+		} else if (S_ISREG(inode->i_mode) &&
+			   (revoking & used & CEPH_CAP_FILE_LAZYIO) &&
+			   (ci->i_wrbuffer_ref || ci->i_wb_ref)) {
+			/* LAZYIO was covering for dirty data — flush first */
+			writeback = true;
+			revoke_wait = true;
 		} else if (queue_invalidate &&
-			 revoking == CEPH_CAP_FILE_CACHE &&
-			 (newcaps & CEPH_CAP_FILE_LAZYIO) == 0) {
+			 (revoking & (CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_LAZYIO)) &&
+			 !(newcaps & (CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_LAZYIO))) {
 			revoke_wait = true; /* do nothing yet, invalidation will be queued */
 		} else if (cap == ci->i_auth_cap) {
 			check_caps = 1; /* check auth cap only */
diff --git a/fs/ceph/file.c b/fs/ceph/file.c
index d54d71669176..4d5afd1e0277 100644
--- a/fs/ceph/file.c
+++ b/fs/ceph/file.c
@@ -346,10 +346,6 @@ int ceph_renew_caps(struct inode *inode, int fmode)
 		flags = O_RDONLY;
 	else if (wanted & CEPH_CAP_FILE_WR)
 		flags = O_WRONLY;
-#ifdef O_LAZY
-	if (wanted & CEPH_CAP_FILE_LAZYIO)
-		flags |= O_LAZY;
-#endif
 
 	req = prepare_open_request(inode->i_sb, flags, 0);
 	if (IS_ERR(req)) {
@@ -357,6 +353,10 @@ int ceph_renew_caps(struct inode *inode, int fmode)
 		goto out;
 	}
 
+	if (wanted & CEPH_CAP_FILE_LAZYIO) {
+		req->r_fmode |= CEPH_FILE_MODE_LAZY;
+		req->r_args.open.flags |= cpu_to_le32(CEPH_O_LAZY);
+	}
 	req->r_inode = inode;
 	ihold(inode);
 	req->r_num_caps = 1;
@@ -408,6 +408,19 @@ int ceph_open(struct inode *inode, struct file *file)
 	doutc(cl, "%p %llx.%llx file %p flags %d (%d)\n", inode,
 	      ceph_vinop(inode), file, flags, file->f_flags);
 	fmode = ceph_flags_to_mode(flags);
+
+	/*
+	 * If lazyio mount option is set, enable lazyio for all regular
+	 * files.  Skip snapped files: snap caps never include LAZYIO,
+	 * so including it in wanted would force an unnecessary MDS
+	 * round-trip for every open of a snapped file.
+	 */
+	if (S_ISREG(inode->i_mode) &&
+	    ceph_snap(inode) == CEPH_NOSNAP &&
+	    (fsc->mount_options->flags & CEPH_MOUNT_OPT_LAZYIO)) {
+		fmode |= CEPH_FILE_MODE_LAZY;
+	}
+
 	wanted = ceph_caps_for_mode(fmode);
 
 	if (fmode & CEPH_FILE_MODE_WR)
@@ -484,13 +497,16 @@ int ceph_open(struct inode *inode, struct file *file)
 		err = PTR_ERR(req);
 		goto out;
 	}
+	req->r_fmode |= fmode & CEPH_FILE_MODE_LAZY;
+	if (fmode & CEPH_FILE_MODE_LAZY)
+		req->r_args.open.flags |= cpu_to_le32(CEPH_O_LAZY);
 	req->r_inode = inode;
 	ihold(inode);
 
 	req->r_num_caps = 1;
 	err = ceph_mdsc_do_request(mdsc, NULL, req);
 	if (!err)
-		err = ceph_init_file(inode, file, req->r_fmode);
+		err = ceph_init_file(inode, file, fmode);
 	ceph_mdsc_put_request(req);
 	doutc(cl, "open result=%d on %llx.%llx\n", err, ceph_vinop(inode));
 out:
@@ -834,6 +850,9 @@ int ceph_atomic_open(struct inode *dir, struct dentry *dentry,
 		} else {
 			int fmode = ceph_flags_to_mode(flags);
 
+			if (fsc->mount_options->flags & CEPH_MOUNT_OPT_LAZYIO)
+				fmode |= CEPH_FILE_MODE_LAZY;
+
 			mask = MAY_READ;
 			if (fmode & CEPH_FILE_MODE_WR)
 				mask |= MAY_WRITE;
@@ -876,6 +895,10 @@ int ceph_atomic_open(struct inode *dir, struct dentry *dentry,
 		err = PTR_ERR(req);
 		goto out_ctx;
 	}
+	if (fsc->mount_options->flags & CEPH_MOUNT_OPT_LAZYIO) {
+		req->r_fmode |= CEPH_FILE_MODE_LAZY;
+		req->r_args.open.flags |= cpu_to_le32(CEPH_O_LAZY);
+	}
 	req->r_dentry = dget(dentry);
 	req->r_num_caps = 2;
 	mask = CEPH_STAT_CAP_INODE | CEPH_CAP_AUTH_SHARED;
diff --git a/fs/ceph/super.c b/fs/ceph/super.c
index c05fbd4237f8..0bbd38933f0e 100644
--- a/fs/ceph/super.c
+++ b/fs/ceph/super.c
@@ -177,6 +177,7 @@ enum {
 	Opt_wsync,
 	Opt_pagecache,
 	Opt_sparseread,
+	Opt_lazyio,
 };
 
 enum ceph_recover_session_mode {
@@ -203,6 +204,7 @@ static const struct fs_parameter_spec ceph_mount_parameters[] = {
 	fsparam_flag_no	("fsc",				Opt_fscache), // fsc|nofsc
 	fsparam_string	("fsc",				Opt_fscache), // fsc=...
 	fsparam_flag_no ("ino32",			Opt_ino32),
+	fsparam_flag_no	("lazyio",			Opt_lazyio),
 	fsparam_string	("mds_namespace",		Opt_mds_namespace),
 	fsparam_string	("mon_addr",			Opt_mon_addr),
 	fsparam_flag_no ("poolperm",			Opt_poolperm),
@@ -593,6 +595,12 @@ static int ceph_parse_mount_param(struct fs_context *fc,
 		else
 			fsopt->flags |= CEPH_MOUNT_OPT_SPARSEREAD;
 		break;
+	case Opt_lazyio:
+		if (result.negated)
+			fsopt->flags &= ~CEPH_MOUNT_OPT_LAZYIO;
+		else
+			fsopt->flags |= CEPH_MOUNT_OPT_LAZYIO;
+		break;
 	case Opt_test_dummy_encryption:
 #ifdef CONFIG_FS_ENCRYPTION
 		fscrypt_free_dummy_policy(&fsopt->dummy_enc_policy);
@@ -749,6 +757,8 @@ static int ceph_show_options(struct seq_file *m, struct dentry *root)
 		seq_puts(m, ",nopagecache");
 	if (fsopt->flags & CEPH_MOUNT_OPT_SPARSEREAD)
 		seq_puts(m, ",sparseread");
+	if (fsopt->flags & CEPH_MOUNT_OPT_LAZYIO)
+		seq_puts(m, ",lazyio");
 
 	fscrypt_show_test_dummy_encryption(m, ',', root->d_sb);
 
@@ -1410,6 +1420,11 @@ static int ceph_reconfigure_fc(struct fs_context *fc)
 	else
 		ceph_clear_mount_opt(fsc, SPARSEREAD);
 
+	if (fsopt->flags & CEPH_MOUNT_OPT_LAZYIO)
+		ceph_set_mount_opt(fsc, LAZYIO);
+	else
+		ceph_clear_mount_opt(fsc, LAZYIO);
+
 	if (strcmp_null(fsc->mount_options->mon_addr, fsopt->mon_addr)) {
 		kfree(fsc->mount_options->mon_addr);
 		fsc->mount_options->mon_addr = fsopt->mon_addr;
diff --git a/fs/ceph/super.h b/fs/ceph/super.h
index afc89ce91804..aec2eb4d0256 100644
--- a/fs/ceph/super.h
+++ b/fs/ceph/super.h
@@ -45,6 +45,7 @@
 #define CEPH_MOUNT_OPT_ASYNC_DIROPS    (1<<15) /* allow async directory ops */
 #define CEPH_MOUNT_OPT_NOPAGECACHE     (1<<16) /* bypass pagecache altogether */
 #define CEPH_MOUNT_OPT_SPARSEREAD      (1<<17) /* always do sparse reads */
+#define CEPH_MOUNT_OPT_LAZYIO          (1<<18) /* force lazyio for all file opens */
 
 #define CEPH_MOUNT_OPT_DEFAULT			\
 	(CEPH_MOUNT_OPT_DCACHE |		\
diff --git a/fs/ceph/util.c b/fs/ceph/util.c
index 2c34875675bf..be3db3f20344 100644
--- a/fs/ceph/util.c
+++ b/fs/ceph/util.c
@@ -73,10 +73,6 @@ int ceph_flags_to_mode(int flags)
 		mode = CEPH_FILE_MODE_RDWR;
 		break;
 	}
-#ifdef O_LAZY
-	if (flags & O_LAZY)
-		mode |= CEPH_FILE_MODE_LAZY;
-#endif
 
 	return mode;
 }
diff --git a/include/linux/ceph/ceph_fs.h b/include/linux/ceph/ceph_fs.h
index 69ac3e55a3fe..01fd5f6647c8 100644
--- a/include/linux/ceph/ceph_fs.h
+++ b/include/linux/ceph/ceph_fs.h
@@ -414,6 +414,7 @@ extern const char *ceph_mds_op_name(int op);
 #define CEPH_O_CREAT		00000100
 #define CEPH_O_EXCL		00000200
 #define CEPH_O_TRUNC		00001000
+#define CEPH_O_LAZY		00020000
 #define CEPH_O_DIRECTORY	00200000
 #define CEPH_O_NOFOLLOW		00400000
 

---
base-commit: 9fc75b71fdd38465c76c6f6a884cdd4ae3c72d90
change-id: 20260625-lazyio-6987f73c557f

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

