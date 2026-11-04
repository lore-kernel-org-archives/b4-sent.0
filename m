From: orkunsari <sariorkunemin@gmail.com>
Date: Wed, 04 Nov 2026 14:56:15 +0300
Subject: [PATCH 1/2] nfsd: unlock the locked parent after crossing a mount
 in CREATE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-nfsd-cross-mnt-v1-1-5ec5fca0a553@gmail.com>
References: <20261104-nfsd-cross-mnt-v1-0-5ec5fca0a553@gmail.com>
In-Reply-To: <20261104-nfsd-cross-mnt-v1-0-5ec5fca0a553@gmail.com>
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 orkunsari <sariorkunemin@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793793374; l=4017;
 i=sariorkunemin@gmail.com; s=20261103; h=from:subject:message-id;
 bh=nmjbVfxD/SAnHRb/TsZON41UIu9qiDUdfa1MwQhC9uA=;
 b=3QjWHJ3TJ1bU3gFFVufK2ZH1N6D4mdafYiFxclfJcseLecUOAbufSi8HjsL19Ps93KTnCzYcH
 j45F3HOmc2nARigRDFO3C/M8kN8HsBk2n8X8GbHvJ3CxOqQlBGc7tl8
X-Developer-Key: i=sariorkunemin@gmail.com; a=ed25519;
 pk=MJ3Y3somkGDQVAXOSR189QAqWOcfzYCRkL1cSQgJXnE=
X-Endpoint-Received: by B4 Relay for sariorkunemin@gmail.com/20261103 with auth_id=1408
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit f58a48389c14 ("nfsd: correctly handle CREATE of mounted-on
files"), nfsd_proc_create() and nfsd3_create_file() call
nfsd_cross_mnt() on the dentry returned by start_creating().  When the
name refers to a file that has something mounted on it,
nfsd_cross_mnt() replaces that dentry with the root of the mounted
filesystem and drops its reference to the original one.

The replacement is later passed to end_creating(), which unlocks the
d_parent of the dentry it is given.  That is the parent of the mount
source, not the directory start_creating() locked, so the directory
being created in is left locked and another directory's i_rwsem is
released without being held.

Do the crossing on a separate reference that is only used for
fh_compose(), so that the dentry returned by start_creating() is the
one passed to end_creating().  Only positive regular files are crossed,
so the later checks on the child dentry give the same result.

This was found by AI-assisted code review (Claude Code).  The fix has
been build-tested with W=1 only; no reproducer was run.

Fixes: f58a48389c14 ("nfsd: correctly handle CREATE of mounted-on files")
Signed-off-by: orkunsari <sariorkunemin@gmail.com>
---
 fs/nfsd/nfs3proc.c | 14 +++++++++++---
 fs/nfsd/nfsproc.c  | 14 +++++++++++---
 2 files changed, 22 insertions(+), 6 deletions(-)

diff --git a/fs/nfsd/nfs3proc.c b/fs/nfsd/nfs3proc.c
index 60cd01b6a3..0711e93c99 100644
--- a/fs/nfsd/nfs3proc.c
+++ b/fs/nfsd/nfs3proc.c
@@ -334,7 +334,7 @@ nfsd3_create_file(struct svc_rqst *rqstp, struct svc_fh *fhp,
 		  struct svc_fh *resfhp, struct nfsd3_createargs *argp)
 {
 	struct iattr *iap = &argp->attrs;
-	struct dentry *parent, *child;
+	struct dentry *parent, *child, *mnt_child;
 	struct nfsd_attrs attrs = {
 		.na_iattr	= iap,
 	};
@@ -378,21 +378,29 @@ nfsd3_create_file(struct svc_rqst *rqstp, struct svc_fh *fhp,
 	}
 
 	exp = exp_get(fhp->fh_export);
+	/*
+	 * Cross on a separate reference: child must remain the dentry
+	 * start_creating() returned so that end_creating() unlocks the
+	 * right directory.
+	 */
+	mnt_child = dget(child);
 	if (argp->createmode == NFS3_CREATE_UNCHECKED) {
 		/*
 		 * If name is already in dcache we need to check for mountpoints
 		 */
 		if (d_is_reg(child) &&
 		    unlikely(nfsd_mountpoint(child, exp))) {
-			status = nfsd_cross_mnt(rqstp, &child, &exp);
+			status = nfsd_cross_mnt(rqstp, &mnt_child, &exp);
 			if (status != nfs_ok) {
+				dput(mnt_child);
 				exp_put(exp);
 				goto out;
 			}
 		}
 	}
 
-	status = fh_compose(resfhp, exp, child, fhp);
+	status = fh_compose(resfhp, exp, mnt_child, fhp);
+	dput(mnt_child);
 	exp_put(exp);
 	if (status != nfs_ok)
 		goto out;
diff --git a/fs/nfsd/nfsproc.c b/fs/nfsd/nfsproc.c
index 1f74008bc0..7da653bc0e 100644
--- a/fs/nfsd/nfsproc.c
+++ b/fs/nfsd/nfsproc.c
@@ -682,7 +682,7 @@ nfsd_create_file(struct svc_rqst *rqstp, struct svc_fh *fhp,
 		.na_iattr	= attr,
 	};
 	struct svc_export *exp;
-	struct dentry *dchild;
+	struct dentry *dchild, *dmnt;
 	struct inode *inode;
 	int type, mode;
 	__be32 status;
@@ -709,16 +709,24 @@ nfsd_create_file(struct svc_rqst *rqstp, struct svc_fh *fhp,
 	 * If name exists we need to check for mountpoints
 	 */
 	exp = exp_get(fhp->fh_export);
+	/*
+	 * Cross on a separate reference: dchild must remain the dentry
+	 * start_creating() returned so that end_creating() unlocks the
+	 * right directory.
+	 */
+	dmnt = dget(dchild);
 	if (d_is_reg(dchild) &&
 	    unlikely(nfsd_mountpoint(dchild, exp))) {
-		status = nfsd_cross_mnt(rqstp, &dchild, &exp);
+		status = nfsd_cross_mnt(rqstp, &dmnt, &exp);
 		if (status != nfs_ok) {
+			dput(dmnt);
 			exp_put(exp);
 			goto out;
 		}
 	}
 
-	status = fh_compose(resfhp, exp, dchild, fhp);
+	status = fh_compose(resfhp, exp, dmnt, fhp);
+	dput(dmnt);
 	exp_put(exp);
 	if (!status && d_really_is_negative(dchild))
 		status = nfserr_noent;

-- 
2.56.0

