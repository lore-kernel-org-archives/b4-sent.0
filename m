From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 12 Nov 2026 12:58:09 +0900
Subject: [PATCH] ovl: bump the impure dir version when linking a file with
 origin
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-ovl-link-impure-v1-1-7804905610a9@samsung.com>
X-B4-Tracking: v=1; b=H4sIAFA59WoC/x3MQQqAIBBA0avErBtopES6SrSInGqoVJQkiO6et
 HyL/x9IHIUT9NUDkbMk8a6A6grmbXIro9hiUI3SRKTQ5wMPcTvKGa7IaLRqDTXUaWugVCHyIvd
 /HMb3/QAmDAOQYQAAAA==
To: Miklos Szeredi <miklos@szeredi.hu>, Amir Goldstein <amir73il@gmail.com>
Cc: linux-unionfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sashiko <sashiko-bot@kernel.org>, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794455888; l=4013;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=KL4nutV0WdP0jvfIHdlIIHren54/dSp9jeM8NnkBbQ8=;
 b=4tIZe/ic11x6dFKJ6OaClDWqN40yI94UC+AbRPlyd3ElduWhwW/8/ITGrDjl7U7/2I/k/o0bf
 yzNoRM2imq6Ac29GzZYFO6Xt3X3KzDu8LpYdGUHPWFAnTxeiPmJ+GhH
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Linking a file with copy up origin into a non-merge impure dir does
not bump the dir version. readdir then reuses the impure dir cache
built before the link. It reports the upper inode number as d_ino of
the new link, not st_ino.

Pass whether the linked file has an origin to ovl_dir_modified(), as
rename and unlink do.

Fixes: 4edb83bb1041 ("ovl: constant d_ino for non-merge dirs")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/bug/linux-98f207b6-3936-48e9-a40f-88f20be4db7b
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested on ext4 and xfs with default overlay options: the new fstests
test overlay/013 fails without this patch and passes with it. So does
a script that puts a whiteout in a non-merge upper dir before mount
and links over it (ovl_create_over_whiteout()). Apart from
overlay/013, only 079, 085 and 088 fail in overlay/auto on ovl-fixes,
with and without this patch.
---
 fs/overlayfs/dir.c | 20 +++++++++++---------
 1 file changed, 11 insertions(+), 9 deletions(-)

diff --git a/fs/overlayfs/dir.c b/fs/overlayfs/dir.c
index e0a164e22d67..8fec18dc5fc7 100644
--- a/fs/overlayfs/dir.c
+++ b/fs/overlayfs/dir.c
@@ -368,7 +368,7 @@ static bool ovl_type_origin(struct dentry *dentry)
 }
 
 static int ovl_create_upper(struct dentry *dentry, struct inode *inode,
-			    struct ovl_cattr *attr)
+			    struct ovl_cattr *attr, bool origin)
 {
 	struct ovl_fs *ofs = OVL_FS(dentry->d_sb);
 	struct dentry *upperdir = ovl_dentry_upper(dentry->d_parent);
@@ -393,7 +393,7 @@ static int ovl_create_upper(struct dentry *dentry, struct inode *inode,
 		ovl_set_opaque(dentry, newdentry);
 	}
 
-	ovl_dir_modified(dentry->d_parent, false);
+	ovl_dir_modified(dentry->d_parent, origin);
 	err = ovl_instantiate(dentry, inode, newdentry, !!attr->hardlink, NULL);
 	if (err)
 		goto out_cleanup;
@@ -491,7 +491,7 @@ static int ovl_set_upper_acl(struct ovl_fs *ofs, struct dentry *upperdentry,
 }
 
 static int ovl_create_over_whiteout(struct dentry *dentry, struct inode *inode,
-				    struct ovl_cattr *cattr)
+				    struct ovl_cattr *cattr, bool origin)
 {
 	struct ovl_fs *ofs = OVL_FS(dentry->d_sb);
 	struct dentry *workdir = ovl_workdir(dentry);
@@ -582,7 +582,7 @@ static int ovl_create_over_whiteout(struct dentry *dentry, struct inode *inode,
 		if (err)
 			goto out_cleanup_unlocked;
 	}
-	ovl_dir_modified(dentry->d_parent, false);
+	ovl_dir_modified(dentry->d_parent, origin);
 	err = ovl_instantiate(dentry, inode, newdentry, hardlink, NULL);
 	if (err) {
 		ovl_cleanup(ofs, upperdir, newdentry);
@@ -647,12 +647,12 @@ DEFINE_CLASS(ovl_override_creator_creds,
 
 static int ovl_create_handle_whiteouts(struct dentry *dentry,
 				       struct inode *inode,
-				       struct ovl_cattr *attr)
+				       struct ovl_cattr *attr, bool origin)
 {
 	if (!ovl_dentry_is_whiteout(dentry))
-		return ovl_create_upper(dentry, inode, attr);
+		return ovl_create_upper(dentry, inode, attr, origin);
 
-	return ovl_create_over_whiteout(dentry, inode, attr);
+	return ovl_create_over_whiteout(dentry, inode, attr, origin);
 }
 
 static int ovl_create_or_link(struct dentry *dentry, struct inode *inode,
@@ -687,12 +687,14 @@ static int ovl_create_or_link(struct dentry *dentry, struct inode *inode,
 		 */
 
 		if (attr->hardlink)
-			return ovl_create_handle_whiteouts(dentry, inode, attr);
+			return ovl_create_handle_whiteouts(dentry, inode, attr,
+							   origin);
 
 		scoped_class(ovl_override_creator_creds, cred, original_creds, dentry, inode, attr->mode) {
 			if (IS_ERR(cred))
 				return PTR_ERR(cred);
-			return ovl_create_handle_whiteouts(dentry, inode, attr);
+			return ovl_create_handle_whiteouts(dentry, inode, attr,
+							   origin);
 		}
 	}
 	return err;

---
base-commit: 0d5e729c515f4ae4eacc179dbcf350d9b499a161
change-id: 20261112-ovl-link-impure-8624810156d8

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

