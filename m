From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:50 -0600
Subject: [PATCH v2 19/25] fs: add vfs_remove_fscaps()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-19-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3779; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=a3ugvMhATksPxV+a7Wcb3fojtkXnejQOJKEmfG2Au6A=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1mopgDVenhi3VLPaPvFwxM95tqNAaxCLXvBKa+2y
 76GFlFmJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqKQAKCRBTA5mu5fQxyQftB/
 0eV/oZCodcvmT2NzrSTKkvLIWCpVU5YGKGFugW3HG3lJRUuGtO+t+A3RwZKzOSWbtk1CkbGAetJWXa
 aqqprqjsUstKaAApbpfZoZ+eK6TN/rCUWHcGfXJrwsSbxogu7GRc2n0qYaSlu+qA3xEzF8z6c/Ddpr
 k/Dc7FVT0eukTELGcPFhqthrQZQwUPUa27SB4BCSgNW5nS3MQFGNmL3komWpIDaUw1t7zzjePB3Q8p
 Sd6mViD54RmlcUD/RuxaNacNOjFHyQ0gXUwF/iAQuoi0uwi4vkFeECAIEt6niPSkeZ/0OqmUxINUBZ
 jM1eqVetaMefnRdsKXRtEreKVXPamw
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Provide a type-safe interface for removing filesystem capabilities and a
generic implementation suitable for most filesystems. Also add an
internal interface, vfs_remove_fscaps_nosec(), which is called with the
inode lock held and skips security checks for later use from the
capability code.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 fs/xattr.c         | 81 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 include/linux/fs.h |  2 ++
 2 files changed, 83 insertions(+)

diff --git a/fs/xattr.c b/fs/xattr.c
index 96de43928a51..8b0f7384cbc9 100644
--- a/fs/xattr.c
+++ b/fs/xattr.c
@@ -324,6 +324,87 @@ int vfs_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
 }
 EXPORT_SYMBOL(vfs_set_fscaps);
 
+static int generic_remove_fscaps(struct mnt_idmap *idmap, struct dentry *dentry)
+{
+	return __vfs_removexattr(idmap, dentry, XATTR_NAME_CAPS);
+}
+
+/**
+ * vfs_remove_fscaps_nosec - remove filesystem capabilities without
+ *                           security checks
+ * @idmap: idmap of the mount the inode was found from
+ * @dentry: the dentry from which to remove filesystem capabilities
+ *
+ * This function removes any filesystem capabilities from the specified
+ * dentry. Does not perform any security checks, and callers must hold the
+ * inode lock.
+ *
+ * Return: 0 on success, a negative errno on error.
+ */
+int vfs_remove_fscaps_nosec(struct mnt_idmap *idmap, struct dentry *dentry)
+{
+	struct inode *inode = dentry->d_inode;
+	int error;
+
+	if (inode->i_op->set_fscaps)
+		error =  inode->i_op->set_fscaps(idmap, dentry, NULL,
+						 XATTR_REPLACE);
+	else
+		error = generic_remove_fscaps(idmap, dentry);
+
+	return error;
+}
+
+/**
+ * vfs_remove_fscaps - remove filesystem capabilities
+ * @idmap: idmap of the mount the inode was found from
+ * @dentry: the dentry from which to remove filesystem capabilities
+ *
+ * This function removes any filesystem capabilities from the specified
+ * dentry.
+ *
+ * Return: 0 on success, a negative errno on error.
+ */
+int vfs_remove_fscaps(struct mnt_idmap *idmap, struct dentry *dentry)
+{
+	struct inode *inode = dentry->d_inode;
+	struct inode *delegated_inode = NULL;
+	int error;
+
+retry_deleg:
+	inode_lock(inode);
+
+	error = xattr_permission(idmap, inode, XATTR_NAME_CAPS, MAY_WRITE);
+	if (error)
+		goto out_inode_unlock;
+
+	error = security_inode_remove_fscaps(idmap, dentry);
+	if (error)
+		goto out_inode_unlock;
+
+	error = try_break_deleg(inode, &delegated_inode);
+	if (error)
+		goto out_inode_unlock;
+
+	error = vfs_remove_fscaps_nosec(idmap, dentry);
+	if (!error) {
+		fsnotify_xattr(dentry);
+		evm_inode_post_remove_fscaps(dentry);
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
+EXPORT_SYMBOL(vfs_remove_fscaps);
+
 int
 __vfs_setxattr(struct mnt_idmap *idmap, struct dentry *dentry,
 	       struct inode *inode, const char *name, const void *value,
diff --git a/include/linux/fs.h b/include/linux/fs.h
index 4f5d7ed44644..c07427d2fc71 100644
--- a/include/linux/fs.h
+++ b/include/linux/fs.h
@@ -2122,6 +2122,8 @@ extern int vfs_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
 			  struct vfs_caps *caps);
 extern int vfs_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
 			  const struct vfs_caps *caps, int setxattr_flags);
+extern int vfs_remove_fscaps_nosec(struct mnt_idmap *idmap, struct dentry *dentry);
+extern int vfs_remove_fscaps(struct mnt_idmap *idmap, struct dentry *dentry);
 
 /**
  * enum freeze_holder - holder of the freeze

-- 
2.43.0

