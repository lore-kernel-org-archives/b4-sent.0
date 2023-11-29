From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 29 Nov 2023 15:50:26 -0600
Subject: [PATCH 08/16] fs: add vfs_get_fscaps()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231129-idmap-fscap-refactor-v1-8-da5a26058a5b@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3647; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=+rNu+aEJtyNDKr3Mz+sg00VpaKJj7LN1+EUYKCn22bc=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBlZ7I4/avu6/WjMpQysJRD4e086dAG/Cwb8KohO3Og
 fd3i1iGJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZWeyOAAKCRBTA5mu5fQxyUF1B/
 9oQr2DVGypJwRSipJa6KV9qSjXlv20xo0hNhsSFvuH9Ach0ImZwoiRJyWGJTQ1qBcQPq7seTQQ+7B+
 S2dK266E1ICJEoRmy+cIe8P+BJme5M6yUAyFiSPqel1NPeKIbMFIGG6LST8fWtudf6UinqfhFZKyvd
 qE1ALWh6jQ12XE2xqlEPn0/tDpmo8eT7EU0F0z5LdbBiLGrQIQwMQpHnldwMwrCZkrjFnViq2fZbAj
 wzu2f79hmFumu4lFZ7Y4Gtb7CrOmipp/+6R4MsVmbtiaiiDpWIn3MrIlDO0ivXbVWESxV66lWPdbWZ
 CcbdRRuAOliiqvt4XyKPp1qO4gEpFI
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Provide a type-safe interface for retrieving filesystem capabilities and
a generic implementation suitable for most filesystems. Also add an
internal interface, __vfs_get_fscaps(), which skips security checks for
later use from the capability code.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 fs/xattr.c         | 66 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 include/linux/fs.h |  4 ++++
 2 files changed, 70 insertions(+)

diff --git a/fs/xattr.c b/fs/xattr.c
index 09d927603433..3abaf9bef0a5 100644
--- a/fs/xattr.c
+++ b/fs/xattr.c
@@ -181,6 +181,72 @@ xattr_supports_user_prefix(struct inode *inode)
 }
 EXPORT_SYMBOL(xattr_supports_user_prefix);
 
+static int generic_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+			      struct vfs_caps *caps)
+{
+	struct inode *inode = d_inode(dentry);
+	struct vfs_ns_cap_data *nscaps = NULL;
+	int ret;
+
+	ret = (int)vfs_getxattr_alloc(idmap, dentry, XATTR_NAME_CAPS,
+				      (char **)&nscaps, 0, GFP_NOFS);
+
+	if (ret >= 0)
+		ret = vfs_caps_from_xattr(idmap, i_user_ns(inode), caps, nscaps, ret);
+
+	kfree(nscaps);
+	return ret;
+}
+
+/**
+ * __vfs_get_fscaps - get filesystem capabilities without security checks
+ * @idmap: idmap of the mount the inode was found from
+ * @dentry: the dentry from which to get filesystem capabilities
+ * @caps: storage in which to return the filesystem capabilities
+ *
+ * This function gets the filesystem capabilities for the dentry and returns
+ * them in @caps. It does not perform security checks.
+ *
+ * Return: 0 on success, a negative errno on error.
+ */
+int __vfs_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+		     struct vfs_caps *caps)
+{
+	struct inode *inode = d_inode(dentry);
+
+	if (inode->i_op->get_fscaps)
+		return inode->i_op->get_fscaps(idmap, dentry, caps);
+	return generic_get_fscaps(idmap, dentry, caps);
+}
+
+/**
+ * vfs_get_fscaps - get filesystem capabilities
+ * @idmap: idmap of the mount the inode was found from
+ * @dentry: the dentry from which to get filesystem capabilities
+ * @caps: storage in which to return the filesystem capabilities
+ *
+ * This function gets the filesystem capabilities for the dentry and returns
+ * them in @caps.
+ *
+ * Return: 0 on success, a negative errno on error.
+ */
+int vfs_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+		   struct vfs_caps *caps)
+{
+	int error;
+
+	/*
+	 * The VFS has no restrictions on reading security.* xattrs, so
+	 * xattr_permission() isn't needed. Only LSMs get a say.
+	 */
+	error = security_inode_getxattr(dentry, XATTR_NAME_CAPS);
+	if (error)
+		return error;
+
+	return __vfs_get_fscaps(idmap, dentry, caps);
+}
+EXPORT_SYMBOL(vfs_get_fscaps);
+
 int
 __vfs_setxattr(struct mnt_idmap *idmap, struct dentry *dentry,
 	       struct inode *inode, const char *name, const void *value,
diff --git a/include/linux/fs.h b/include/linux/fs.h
index a0a77f67b999..e25b39e4017a 100644
--- a/include/linux/fs.h
+++ b/include/linux/fs.h
@@ -2055,6 +2055,10 @@ extern int vfs_dedupe_file_range(struct file *file,
 extern loff_t vfs_dedupe_file_range_one(struct file *src_file, loff_t src_pos,
 					struct file *dst_file, loff_t dst_pos,
 					loff_t len, unsigned int remap_flags);
+extern int __vfs_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+			    struct vfs_caps *caps);
+extern int vfs_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+			  struct vfs_caps *caps);
 
 enum freeze_holder {
 	FREEZE_HOLDER_KERNEL	= (1U << 0),

-- 
2.43.0

