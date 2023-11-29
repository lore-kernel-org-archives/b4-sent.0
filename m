From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 29 Nov 2023 15:50:27 -0600
Subject: [PATCH 09/16] fs: add vfs_set_fscaps()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231129-idmap-fscap-refactor-v1-9-da5a26058a5b@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3947; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=9l5fqS0lfJcyX9vw4KCwkH1iHUQkPeV3R9q3VUBroWs=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBlZ7I5R91Ab7BjTptx2E/V9ecRYanz35z2BVyB57QQ
 pm6SV2CJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZWeyOQAKCRBTA5mu5fQxyfZwB/
 45NtsnoK+BQ3Ly7m1AOvL3fWkADguQcZ36JnrA/kmjz3u4R5+qB6Yfz1HQjo9g8MKR2mZh7D9itHuQ
 J9jpu/t0jdnNDwSedgG6j1ZHUfOoVKnmbpy4xKtahohtVRS9xaQ4ziaxHBG81RRmuc2MXeVApFQN5c
 wFrL74wgMl1inxRy4/s59AR/BlT6QYXtatl6m5zLBDAOxUwlbvU5rp1tLUiHl4C4B8gbor1ETNEome
 MyjCTJLeAZrx1p7mnXZR6XWf9/qYQZOz2VSqIq48NsMSLPxTl1svnt64tZ1qAm91QCQkjx8eBPjRIC
 Qkx/iwFGKwS+YSpydOUNvpJY2tdx/L
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Provide a type-safe interface for setting filesystem capabilities and a
generic implementation suitable for most filesystems.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 fs/xattr.c         | 87 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 include/linux/fs.h |  2 ++
 2 files changed, 89 insertions(+)

diff --git a/fs/xattr.c b/fs/xattr.c
index 3abaf9bef0a5..03cc824e4f87 100644
--- a/fs/xattr.c
+++ b/fs/xattr.c
@@ -247,6 +247,93 @@ int vfs_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
 }
 EXPORT_SYMBOL(vfs_get_fscaps);
 
+static int generic_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+			      const struct vfs_caps *caps, int flags)
+{
+	struct inode *inode = d_inode(dentry);
+	struct vfs_ns_cap_data nscaps;
+	int size;
+
+	size = vfs_caps_to_xattr(idmap, i_user_ns(inode), caps,
+				 &nscaps, sizeof(nscaps));
+	if (size < 0)
+		return size;
+
+	return __vfs_setxattr_noperm(idmap, dentry, XATTR_NAME_CAPS,
+				     &nscaps, size, flags);
+}
+
+/**
+ * vfs_set_fscaps - set filesystem capabilities
+ * @idmap: idmap of the mount the inode was found from
+ * @dentry: the dentry on which to set filesystem capabilities
+ * @caps: the filesystem capabilities to be written
+ * @flags: setxattr flags to use when writing the capabilities xattr
+ *
+ * This function writes the supplied filesystem capabilities to the dentry.
+ *
+ * Return: 0 on success, a negative errno on error.
+ */
+int vfs_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+		   const struct vfs_caps *caps, int flags)
+{
+	struct inode *inode = d_inode(dentry);
+	struct inode *delegated_inode = NULL;
+	struct vfs_ns_cap_data nscaps;
+	int size, error;
+
+	/*
+	 * Unfortunately EVM wants to have the raw xattr value to compare to
+	 * the on-disk version, so we need to pass the raw xattr to the
+	 * security hooks. But we also want to do security checks before
+	 * breaking leases, so that means a conversion to the raw xattr here
+	 * which will usually be reduntant with the conversion we do for
+	 * writing the xattr to disk.
+	 */
+	size = vfs_caps_to_xattr(idmap, i_user_ns(inode), caps, &nscaps,
+				 sizeof(nscaps));
+	if (size < 0)
+		return size;
+
+retry_deleg:
+	inode_lock(inode);
+
+	error = xattr_permission(idmap, inode, XATTR_NAME_CAPS, MAY_WRITE);
+	if (error)
+		goto out_inode_unlock;
+	error = security_inode_setxattr(idmap, dentry, XATTR_NAME_CAPS, &nscaps,
+					size, flags);
+	if (error)
+		goto out_inode_unlock;
+
+	error = try_break_deleg(inode, &delegated_inode);
+	if (error)
+		goto out_inode_unlock;
+
+	if (inode->i_opflags & IOP_XATTR) {
+		if (inode->i_op->set_fscaps)
+			error = inode->i_op->set_fscaps(idmap, dentry, caps, flags);
+		else
+			error = generic_set_fscaps(idmap, dentry, caps, flags);
+	} else if (unlikely(is_bad_inode(inode))) {
+		error = -EIO;
+	} else {
+		error = -EOPNOTSUPP;
+	}
+
+out_inode_unlock:
+	inode_unlock(inode);
+
+	if (delegated_inode) {
+		error = break_deleg_wait(&delegated_inode);
+		if (!error)
+			goto retry_deleg;
+	}
+
+	return error;
+}
+EXPORT_SYMBOL(vfs_set_fscaps);
+
 int
 __vfs_setxattr(struct mnt_idmap *idmap, struct dentry *dentry,
 	       struct inode *inode, const char *name, const void *value,
diff --git a/include/linux/fs.h b/include/linux/fs.h
index e25b39e4017a..80992e210b83 100644
--- a/include/linux/fs.h
+++ b/include/linux/fs.h
@@ -2059,6 +2059,8 @@ extern int __vfs_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
 			    struct vfs_caps *caps);
 extern int vfs_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
 			  struct vfs_caps *caps);
+extern int vfs_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+			  const struct vfs_caps *caps, int flags);
 
 enum freeze_holder {
 	FREEZE_HOLDER_KERNEL	= (1U << 0),

-- 
2.43.0

