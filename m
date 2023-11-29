From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 29 Nov 2023 15:50:30 -0600
Subject: [PATCH 12/16] ovl: use vfs_{get,set}_fscaps() for copy-up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231129-idmap-fscap-refactor-v1-12-da5a26058a5b@kernel.org>
References: <20231129-idmap-fscap-refactor-v1-0-da5a26058a5b@kernel.org>
In-Reply-To: <20231129-idmap-fscap-refactor-v1-0-da5a26058a5b@kernel.org>
To: Christian Brauner <brauner@kernel.org>, Serge Hallyn <serge@hallyn.com>, 
 Paul Moore <paul@paul-moore.com>, Eric Paris <eparis@redhat.com>, 
 James Morris <jmorris@namei.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Miklos Szeredi <miklos@szeredi.hu>, Amir Goldstein <amir73il@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-security-module@vger.kernel.org, audit@vger.kernel.org, 
 linux-unionfs@vger.kernel.org, 
 "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=4000; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=sdaoEg9ciUZftk2H34h2y651gj0bEkfe58vTpkMB1yM=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBlZ7I7nj2pDM1Swf1xxfWdnQF142gaU0cjaKHbr9wa
 IfaLDx2JATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZWeyOwAKCRBTA5mu5fQxyagzB/
 9p+FECwvuMkt4XpREQZadycge188mmaG0BdTCbVb2BetQ3LKBPtUkg4sx9fWHrGjDqMTmYASWswk8w
 ZxaDGEGJ4Hu1GJI6t42C5f0v6yLIm3xXZa54SVpbW6saMAY4YcZBAHtg+Lq5zJqjHxSy/WWSI3lNco
 7/L9wXsaUPMpHWuiy8v7p4EhXAxCjGiNTCHLkM/2FnayolmIwXVgBMiQ7PSU+KwElFmf/JHBmc/CXJ
 qy3Ibx41A7h81JLGZSY+rnHq7KdXnC0tbY7F1bbXdlD5Sr0pkfDOA7r7RplaqTUtg48HD5m1hJ7hp5
 YxnKnn+lyAuSXl8IlHlrpCCrEeLE8U
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Using vfs_{get,set}xattr() for fscaps will be blocked in a future
commit, so convert ovl to use the new interfaces. Also remove the now
unused ovl_getxattr_value().

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 fs/overlayfs/copy_up.c | 72 ++++++++++++++++++++++++++------------------------
 1 file changed, 37 insertions(+), 35 deletions(-)

diff --git a/fs/overlayfs/copy_up.c b/fs/overlayfs/copy_up.c
index 4382881b0709..b43af5ce4b21 100644
--- a/fs/overlayfs/copy_up.c
+++ b/fs/overlayfs/copy_up.c
@@ -73,6 +73,23 @@ static int ovl_copy_acl(struct ovl_fs *ofs, const struct path *path,
 	return err;
 }
 
+static int ovl_copy_fscaps(struct ovl_fs *ofs, const struct path *oldpath,
+			   struct dentry *new)
+{
+	struct vfs_caps capability;
+	int err;
+
+	err = vfs_get_fscaps(mnt_idmap(oldpath->mnt), oldpath->dentry,
+			     &capability);
+	if (err) {
+		if (err == -ENODATA || err == -EOPNOTSUPP)
+			return 0;
+		return err;
+	}
+
+	return vfs_set_fscaps(ovl_upper_mnt_idmap(ofs), new, &capability, 0);
+}
+
 int ovl_copy_xattr(struct super_block *sb, const struct path *oldpath, struct dentry *new)
 {
 	struct dentry *old = oldpath->dentry;
@@ -130,6 +147,14 @@ int ovl_copy_xattr(struct super_block *sb, const struct path *oldpath, struct de
 			break;
 		}
 
+		if (!strcmp(name, XATTR_NAME_CAPS)) {
+			error = ovl_copy_fscaps(OVL_FS(sb), oldpath, new);
+			if (!error)
+				continue;
+			/* fs capabilities must be copied */
+			break;
+		}
+
 retry:
 		size = ovl_do_getxattr(oldpath, name, value, value_size);
 		if (size == -ERANGE)
@@ -1006,61 +1031,40 @@ static bool ovl_need_meta_copy_up(struct dentry *dentry, umode_t mode,
 	return true;
 }
 
-static ssize_t ovl_getxattr_value(const struct path *path, char *name, char **value)
-{
-	ssize_t res;
-	char *buf;
-
-	res = ovl_do_getxattr(path, name, NULL, 0);
-	if (res == -ENODATA || res == -EOPNOTSUPP)
-		res = 0;
-
-	if (res > 0) {
-		buf = kzalloc(res, GFP_KERNEL);
-		if (!buf)
-			return -ENOMEM;
-
-		res = ovl_do_getxattr(path, name, buf, res);
-		if (res < 0)
-			kfree(buf);
-		else
-			*value = buf;
-	}
-	return res;
-}
-
 /* Copy up data of an inode which was copied up metadata only in the past. */
 static int ovl_copy_up_meta_inode_data(struct ovl_copy_up_ctx *c)
 {
 	struct ovl_fs *ofs = OVL_FS(c->dentry->d_sb);
 	struct path upperpath;
 	int err;
-	char *capability = NULL;
-	ssize_t cap_size;
+	struct vfs_caps capability;
+	bool has_capability = false;
 
 	ovl_path_upper(c->dentry, &upperpath);
 	if (WARN_ON(upperpath.dentry == NULL))
 		return -EIO;
 
 	if (c->stat.size) {
-		err = cap_size = ovl_getxattr_value(&upperpath, XATTR_NAME_CAPS,
-						    &capability);
-		if (cap_size < 0)
+		err = vfs_get_fscaps(mnt_idmap(upperpath.mnt), upperpath.dentry,
+				     &capability);
+		if (!err)
+			has_capability = 1;
+		else if (err != -ENODATA && err != EOPNOTSUPP)
 			goto out;
 	}
 
 	err = ovl_copy_up_data(c, &upperpath);
 	if (err)
-		goto out_free;
+		goto out;
 
 	/*
 	 * Writing to upper file will clear security.capability xattr. We
 	 * don't want that to happen for normal copy-up operation.
 	 */
 	ovl_start_write(c->dentry);
-	if (capability) {
-		err = ovl_do_setxattr(ofs, upperpath.dentry, XATTR_NAME_CAPS,
-				      capability, cap_size, 0);
+	if (has_capability) {
+		err = vfs_set_fscaps(mnt_idmap(upperpath.mnt), upperpath.dentry,
+				     &capability, 0);
 	}
 	if (!err) {
 		err = ovl_removexattr(ofs, upperpath.dentry,
@@ -1068,13 +1072,11 @@ static int ovl_copy_up_meta_inode_data(struct ovl_copy_up_ctx *c)
 	}
 	ovl_end_write(c->dentry);
 	if (err)
-		goto out_free;
+		goto out;
 
 	ovl_clear_flag(OVL_HAS_DIGEST, d_inode(c->dentry));
 	ovl_clear_flag(OVL_VERIFIED_DIGEST, d_inode(c->dentry));
 	ovl_set_upperdata(d_inode(c->dentry));
-out_free:
-	kfree(capability);
 out:
 	return err;
 }

-- 
2.43.0

