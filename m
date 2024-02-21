From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:52 -0600
Subject: [PATCH v2 21/25] ovl: use vfs_{get,set}_fscaps() for copy-up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-21-3039364623bd@kernel.org>
References: <20240221-idmap-fscap-refactor-v2-0-3039364623bd@kernel.org>
In-Reply-To: <20240221-idmap-fscap-refactor-v2-0-3039364623bd@kernel.org>
To: Christian Brauner <brauner@kernel.org>, 
 Seth Forshee <sforshee@kernel.org>, Serge Hallyn <serge@hallyn.com>, 
 Paul Moore <paul@paul-moore.com>, Eric Paris <eparis@redhat.com>, 
 James Morris <jmorris@namei.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Jan Kara <jack@suse.cz>, Stephen Smalley <stephen.smalley.work@gmail.com>, 
 Ondrej Mosnacek <omosnace@redhat.com>, 
 Casey Schaufler <casey@schaufler-ca.com>, Mimi Zohar <zohar@linux.ibm.com>, 
 Roberto Sassu <roberto.sassu@huawei.com>, 
 Dmitry Kasatkin <dmitry.kasatkin@gmail.com>, 
 Eric Snowberg <eric.snowberg@oracle.com>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Jonathan Corbet <corbet@lwn.net>, Miklos Szeredi <miklos@szeredi.hu>, 
 Amir Goldstein <amir73il@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-security-module@vger.kernel.org, audit@vger.kernel.org, 
 selinux@vger.kernel.org, linux-integrity@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-unionfs@vger.kernel.org
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=4041; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=zODK8f1Oy6szXpHeADRTdhogMg3GAwHuizUWMJpE3DE=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1moryy7rWCDyCKYhTErtw9reVBQghynbKThrJ7UB
 cXmkPrOJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqKwAKCRBTA5mu5fQxyVGuB/
 98YVYzC3rmVA+s5SJScrnZ4Y5tk6TMC1IC3m8QqEF/wR9kN8x37EMkdEPDIonp4yWwKAp6jK5PHooi
 f/TDfrw9dyMvPoFu1mtHOk7vcZiK+5YhYlIWrGhaRNAhn89fEQAq8U0XJc0QZMBWZX3zC/JjGALUIe
 AXfYqoTkymSa8cturCezE9r8NumhzW5fw2Xeam38vDff9hJEQnZdTqoORMKGVWyvWlcy0o7g1kEuga
 GwQcCqZY7BooJEggxTGYotp66PNUyX0oamXw/4QROT9Cldpj8wp9PrlATvF94aP27wamFYLAmAwztP
 1sjZ5ZJP6nJXzabi+skNTzn9983WmN
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Using vfs_{get,set}xattr() for fscaps will be blocked in a future
commit, so convert ovl to use the new interfaces. Also remove the now
unused ovl_getxattr_value().

Reviewed-by: Amir Goldstein <amir73il@gmail.com>
Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 fs/overlayfs/copy_up.c | 72 ++++++++++++++++++++++++++------------------------
 1 file changed, 37 insertions(+), 35 deletions(-)

diff --git a/fs/overlayfs/copy_up.c b/fs/overlayfs/copy_up.c
index b8e25ca51016..d7c8d76e2394 100644
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
 
+		if (is_fscaps_xattr(name)) {
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
@@ -1039,61 +1064,40 @@ static bool ovl_need_meta_copy_up(struct dentry *dentry, umode_t mode,
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
@@ -1101,13 +1105,11 @@ static int ovl_copy_up_meta_inode_data(struct ovl_copy_up_ctx *c)
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

