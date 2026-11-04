From: orkunsari <sariorkunemin@gmail.com>
Date: Wed, 04 Nov 2026 14:56:16 +0300
Subject: [PATCH 2/2] nfsd: check access to the export being entered when
 crossing mounts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-nfsd-cross-mnt-v1-2-5ec5fca0a553@gmail.com>
References: <20261104-nfsd-cross-mnt-v1-0-5ec5fca0a553@gmail.com>
In-Reply-To: <20261104-nfsd-cross-mnt-v1-0-5ec5fca0a553@gmail.com>
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 orkunsari <sariorkunemin@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793793374; l=4976;
 i=sariorkunemin@gmail.com; s=20261103; h=from:subject:message-id;
 bh=JlWr15lM/B/AmdFzx3FSapRze7rNKJEt/9Zsci6sgU0=;
 b=YJyABjfSPK9rruPjbLFt30iEZsCIOr0gOH9Qzat7to+VEsfM3NIvmIF/FHx+KujSavlypCIq2
 6fSTm6RDwq3DHf2hEVfxGKU7AhbowuxcpBT5TNqI/dWOI/wk3yKWGOv
X-Developer-Key: i=sariorkunemin@gmail.com; a=ed25519;
 pk=MJ3Y3somkGDQVAXOSR189QAqWOcfzYCRkL1cSQgJXnE=
X-Endpoint-Received: by B4 Relay for sariorkunemin@gmail.com/20261103 with auth_id=1408
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit f0d6ad5a2f67 ("nfsd: move check_nfsd_access() call into
nfsd_cross_mnt()") moved the check_nfsd_access() calls from
nfsd_lookup() and the NFSv4 READDIR encoder into nfsd_cross_mnt().  The
moved call checks @exp, the export being left, which the caller has
already verified, rather than @exp2, the export being entered.  The
sec= and xprtsec= settings of a crossmnt/nohide child export are
therefore no longer applied when LOOKUP or READDIR returns its root
filehandle and attributes.  Later operations on that filehandle are
still checked by fh_verify().

The same commit also removed the check that nfsd_lookup() applied after
a ".." lookup steps up into a parent export via nfsd_lookup_parent().

Simply checking @exp2 instead is not enough: nfsd_lookup_dentry() also
serves SECINFO, which must not fail with NFS4ERR_WRONGSEC (RFC 8881,
section 2.6.3.1.1.5) and did not check the target export before.

Split the crossing into __nfsd_cross_mnt(), which checks @exp2 before
switching to it only when asked to.  nfsd_cross_mnt() keeps checking,
for READDIR and the CREATE paths, while nfsd_lookup_dentry() does not.
nfsd_lookup() checks the resulting export whenever it differs from the
directory's, which covers both mount crossings and "..", as it did
before.

This was found by AI-assisted code review (Claude Code).  The fix has
been build-tested with W=1 only; no reproducer was run.

Fixes: f0d6ad5a2f67 ("nfsd: move check_nfsd_access() call into nfsd_cross_mnt()")
Signed-off-by: orkunsari <sariorkunemin@gmail.com>
---
 fs/nfsd/vfs.c | 46 +++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 39 insertions(+), 7 deletions(-)

diff --git a/fs/nfsd/vfs.c b/fs/nfsd/vfs.c
index 56c49b5bc5..2df2df5aaf 100644
--- a/fs/nfsd/vfs.c
+++ b/fs/nfsd/vfs.c
@@ -120,14 +120,16 @@ nfserrno(int errno)
 }
 
 /*
- * Called from nfsd_lookup and encode_dirent. Check if we have crossed
- * a mount point.
+ * Check if we have crossed a mount point.  If @check_access is set, the
+ * export being entered must also pass check_nfsd_access().
+ * nfsd_lookup_dentry() passes false, as it also serves SECINFO; its
+ * other users check the resulting export themselves.
  * Returns an nfs error leaving *dpp and *expp unchanged,
  *  or nfs_ok having possibly changed *dpp and *expp
  */
-__be32
-nfsd_cross_mnt(struct svc_rqst *rqstp, struct dentry **dpp,
-	       struct svc_export **expp)
+static __be32
+__nfsd_cross_mnt(struct svc_rqst *rqstp, struct dentry **dpp,
+		 struct svc_export **expp, bool check_access)
 {
 	struct svc_export *exp = *expp, *exp2 = NULL;
 	struct dentry *dentry = *dpp;
@@ -165,7 +167,8 @@ nfsd_cross_mnt(struct svc_rqst *rqstp, struct dentry **dpp,
 			err = 0;
 	} else if (nfsd_v4client(rqstp) ||
 		(exp->ex_flags & NFSEXP_CROSSMOUNT) || EX_NOHIDE(exp2)) {
-		nfserr = check_nfsd_access(exp, rqstp);
+		if (check_access)
+			nfserr = check_nfsd_access(exp2, rqstp);
 		if (nfserr == nfs_ok) {
 			/* successfully crossed mount point */
 			/*
@@ -189,6 +192,20 @@ nfsd_cross_mnt(struct svc_rqst *rqstp, struct dentry **dpp,
 	return nfserrno(err);
 }
 
+/*
+ * Called from encode_dirent and the CREATE procedures. Check if we have
+ * crossed a mount point, and if so whether the client may access the
+ * export being entered.
+ * Returns an nfs error leaving *dpp and *expp unchanged,
+ *  or nfs_ok having possibly changed *dpp and *expp
+ */
+__be32
+nfsd_cross_mnt(struct svc_rqst *rqstp, struct dentry **dpp,
+	       struct svc_export **expp)
+{
+	return __nfsd_cross_mnt(rqstp, dpp, expp, true);
+}
+
 static void follow_to_parent(struct path *path)
 {
 	struct dentry *dp;
@@ -284,7 +301,12 @@ nfsd_lookup_dentry(struct svc_rqst *rqstp, struct svc_fh *fhp,
 		if (IS_ERR(dentry))
 			goto out_nfserr;
 		if (nfsd_mountpoint(dentry, exp)) {
-			__be32 nfserr = nfsd_cross_mnt(rqstp, &dentry, &exp);
+			/*
+			 * Access to the new export is checked by the caller
+			 * where needed; SECINFO must not fail with WRONGSEC.
+			 */
+			__be32 nfserr = __nfsd_cross_mnt(rqstp, &dentry, &exp,
+							 false);
 
 			if (nfserr) {
 				dput(dentry);
@@ -336,6 +358,15 @@ nfsd_lookup(struct svc_rqst *rqstp, struct svc_fh *fhp, const char *name,
 	err = nfsd_lookup_dentry(rqstp, fhp, name, len, &exp, &dentry);
 	if (err)
 		return err;
+	/*
+	 * The lookup may have crossed into another export, either down
+	 * through a mount point or up through "..".
+	 */
+	if (exp != fhp->fh_export) {
+		err = check_nfsd_access(exp, rqstp);
+		if (err)
+			goto out;
+	}
 	/*
 	 * Note: we compose the file handle now, but as the
 	 * dentry may be negative, it may need to be updated.
@@ -344,6 +375,7 @@ nfsd_lookup(struct svc_rqst *rqstp, struct svc_fh *fhp, const char *name,
 	if (!err && d_really_is_negative(dentry))
 		err = nfserr_noent;
 
+out:
 	dput(dentry);
 	exp_put(exp);
 	return err;

-- 
2.56.0

