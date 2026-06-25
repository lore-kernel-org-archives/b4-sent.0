From: Xiubo Li <xiubo.li@clyso.com>
Date: Thu, 25 Jun 2026 18:06:59 +0800
Subject: [PATCH] ceph: add 'lazyio' mount option to kclient
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260625-lazyio-v1-1-db13078789dd@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMyNT3ZzEqsrMfF0zSwvzNHPjZFNT8zQloOKCotS0zAqwQdGxEH5xaVJ
 WanIJSLdSbS0Arv10pGoAAAA=
X-Change-ID: 20260625-lazyio-6987f73c557f
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782382027; l=10168;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=PM08fe1LNt30o34qqJUNodDi+sgsOhN8kdGyuU5/DCE=;
 b=dwfGhD65fy3yAnefPFG+5Lyjv9fYg4h5baopfHJnr4aUNh9YXCmGmPYDLT1f3ZrSdIAHbbpok
 juQ+z2SLO2NBeitrcU1a61PC38E0cJ+xz4NP5PQkJReqaY6w7pIrgi2
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
---
 fs/ceph/caps.c  | 75 +++++++++++++++++++++++++++++++++++++++++++++++++--------
 fs/ceph/file.c  |  7 ++++++
 fs/ceph/super.c | 15 ++++++++++++
 fs/ceph/super.h |  1 +
 4 files changed, 88 insertions(+), 10 deletions(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index d51454e995a8..a4e1a1aade9d 100644
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
@@ -2905,9 +2934,22 @@ static int try_get_cap_refs(struct inode *inode, int need, int want,
 				}
 				snap_rwsem_locked = true;
 			}
-			if ((have & want) == want)
+			/*
+			 * Allow LAZYIO to act as a substitute for CACHE
+			 * or BUFFER when those caps are not issued.
+			 */
+			if ((have & want) == want ||
+			    ((have & CEPH_CAP_FILE_LAZYIO) &&
+			     !(exclude & CEPH_CAP_FILE_LAZYIO) &&
+			     ((have & want) ==
+			      (want & ~(CEPH_CAP_FILE_CACHE |
+					CEPH_CAP_FILE_BUFFER))))) {
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
@@ -3525,13 +3567,20 @@ static void handle_cap_grant(struct inode *inode,
 
 
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
@@ -3675,6 +3724,7 @@ static void handle_cap_grant(struct inode *inode,
 	/* check cap bits */
 	wanted = __ceph_caps_wanted(ci);
 	used = __ceph_caps_used(ci);
+	used = ceph_adjust_caps_used_for_lazyio(used, cap->issued, cap->implemented);
 	dirty = __ceph_caps_dirty(ci);
 	doutc(cl, " my wanted = %s, used = %s, dirty %s\n",
 	      ceph_cap_string(wanted), ceph_cap_string(used),
@@ -3702,13 +3752,18 @@ static void handle_cap_grant(struct inode *inode,
 		doutc(cl, "revocation: %s -> %s (revoking %s)\n",
 		      ceph_cap_string(cap->issued), ceph_cap_string(newcaps),
 		      ceph_cap_string(revoking));
+		/*
+		 * If BUFFER or LAZYIO is being revoked and we have
+		 * dirty data, trigger writeback before acking.
+		 */
 		if (S_ISREG(inode->i_mode) &&
-		    (revoking & used & CEPH_CAP_FILE_BUFFER)) {
+		    (revoking & used &
+		     (CEPH_CAP_FILE_BUFFER | CEPH_CAP_FILE_LAZYIO))) {
 			writeback = true;  /* initiate writeback; will delay ack */
 			revoke_wait = true;
 		} else if (queue_invalidate &&
-			 revoking == CEPH_CAP_FILE_CACHE &&
-			 (newcaps & CEPH_CAP_FILE_LAZYIO) == 0) {
+			 (revoking & (CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_LAZYIO)) &&
+			 !(newcaps & (CEPH_CAP_FILE_CACHE | CEPH_CAP_FILE_LAZYIO))) {
 			revoke_wait = true; /* do nothing yet, invalidation will be queued */
 		} else if (cap == ci->i_auth_cap) {
 			check_caps = 1; /* check auth cap only */
diff --git a/fs/ceph/file.c b/fs/ceph/file.c
index d54d71669176..36888ce7b587 100644
--- a/fs/ceph/file.c
+++ b/fs/ceph/file.c
@@ -251,6 +251,13 @@ static int ceph_init_file_info(struct inode *inode, struct file *file,
 		file->private_data = fi;
 	}
 
+	/* If lazyio mount option is set, enable lazyio for all regular files */
+	if (!isdir && (opt->flags & CEPH_MOUNT_OPT_LAZYIO)) {
+		fmode |= CEPH_FILE_MODE_LAZY;
+		doutc(cl, "%p %llx.%llx force_lazyio: added LAZY to fmode\n",
+		      inode, ceph_vinop(inode));
+	}
+
 	ceph_get_fmode(ci, fmode, 1);
 	fi->fmode = fmode;
 
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

---
base-commit: 9fc75b71fdd38465c76c6f6a884cdd4ae3c72d90
change-id: 20260625-lazyio-6987f73c557f

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

