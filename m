From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:42 -0600
Subject: [PATCH v2 11/25] security: add hooks for set/get/remove of fscaps
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-11-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6068; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=bU1CcTjoAErUmCcImLT8MBeG6twr7o4CKTQE5qVrAgQ=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1moiOmBWOkW3C2D6watYerA1n6u6GpH/leMlBqw7
 WLNKqEiJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqIgAKCRBTA5mu5fQxyX4hB/
 4gHtUbOV115lPuC//xfy9D4S1XJ5dcZzKpX27IoQgRAB8iadS9qTPZMY9JzN+fEAEJjKFFAFM94cF0
 rLytBPDiTKSoKBhm83DGIfLJyy9gdXXFGXFzmy5MzY4VkuLjCzBltyOieqCT8M64K49wiTDIWCrTku
 mf3oZbjkX8CKEyWzC5OjK08smBtBMLPrNQbDTlb5J2i75XOVmI2yrPuZMCJojB8IN39jKaJ8UX3Hjc
 HElICYbTk+WAYh9ZuZUpzzyo7IEH0c3YjbR8PLFH7Xg0ZTT5jPH6Ccksrf7oNmjUcAAUf7e/S7Xd7K
 vW7wHQVxNqrw0G7gjCWEoB0nJW9wrt
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In preparation for moving fscaps out of the xattr code paths, add new
security hooks. These hooks are largely needed because common kernel
code will pass around struct vfs_caps pointers, which EVM will need to
convert to raw xattr data for verification and updates of its hashes.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 include/linux/lsm_hook_defs.h |  7 +++++
 include/linux/security.h      | 33 +++++++++++++++++++++
 security/security.c           | 69 +++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 109 insertions(+)

diff --git a/include/linux/lsm_hook_defs.h b/include/linux/lsm_hook_defs.h
index 76458b6d53da..7b3c23f9e4a5 100644
--- a/include/linux/lsm_hook_defs.h
+++ b/include/linux/lsm_hook_defs.h
@@ -152,6 +152,13 @@ LSM_HOOK(int, 0, inode_get_acl, struct mnt_idmap *idmap,
 	 struct dentry *dentry, const char *acl_name)
 LSM_HOOK(int, 0, inode_remove_acl, struct mnt_idmap *idmap,
 	 struct dentry *dentry, const char *acl_name)
+LSM_HOOK(int, 0, inode_set_fscaps, struct mnt_idmap *idmap,
+	 struct dentry *dentry, const struct vfs_caps *caps, int flags);
+LSM_HOOK(void, LSM_RET_VOID, inode_post_set_fscaps, struct mnt_idmap *idmap,
+	 struct dentry *dentry, const struct vfs_caps *caps, int flags);
+LSM_HOOK(int, 0, inode_get_fscaps, struct mnt_idmap *idmap, struct dentry *dentry);
+LSM_HOOK(int, 0, inode_remove_fscaps, struct mnt_idmap *idmap,
+	 struct dentry *dentry);
 LSM_HOOK(int, 0, inode_need_killpriv, struct dentry *dentry)
 LSM_HOOK(int, 0, inode_killpriv, struct mnt_idmap *idmap,
 	 struct dentry *dentry)
diff --git a/include/linux/security.h b/include/linux/security.h
index d0eb20f90b26..40be548e5e12 100644
--- a/include/linux/security.h
+++ b/include/linux/security.h
@@ -378,6 +378,13 @@ int security_inode_getxattr(struct dentry *dentry, const char *name);
 int security_inode_listxattr(struct dentry *dentry);
 int security_inode_removexattr(struct mnt_idmap *idmap,
 			       struct dentry *dentry, const char *name);
+int security_inode_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+			      const struct vfs_caps *caps, int flags);
+void security_inode_post_set_fscaps(struct mnt_idmap *idmap,
+				    struct dentry *dentry,
+				    const struct vfs_caps *caps, int flags);
+int security_inode_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry);
+int security_inode_remove_fscaps(struct mnt_idmap *idmap, struct dentry *dentry);
 int security_inode_need_killpriv(struct dentry *dentry);
 int security_inode_killpriv(struct mnt_idmap *idmap, struct dentry *dentry);
 int security_inode_getsecurity(struct mnt_idmap *idmap,
@@ -935,6 +942,32 @@ static inline int security_inode_removexattr(struct mnt_idmap *idmap,
 	return cap_inode_removexattr(idmap, dentry, name);
 }
 
+static inline int security_inode_set_fscaps(struct mnt_idmap *idmap,
+					    struct dentry *dentry,
+					    const struct vfs_caps *caps,
+					    int flags)
+{
+	return 0;
+}
+static void security_inode_post_set_fscaps(struct mnt_idmap *idmap,
+					   struct dentry *dentry,
+					   const struct vfs_caps *caps,
+					   int flags)
+{
+}
+
+static int security_inode_get_fscaps(struct mnt_idmap *idmap,
+				     struct dentry *dentry)
+{
+	return 0;
+}
+
+static int security_inode_remove_fscaps(struct mnt_idmap *idmap,
+					struct dentry *dentry)
+{
+	return 0;
+}
+
 static inline int security_inode_need_killpriv(struct dentry *dentry)
 {
 	return cap_inode_need_killpriv(dentry);
diff --git a/security/security.c b/security/security.c
index 3aaad75c9ce8..0d210da9862c 100644
--- a/security/security.c
+++ b/security/security.c
@@ -2351,6 +2351,75 @@ int security_inode_remove_acl(struct mnt_idmap *idmap,
 	return evm_inode_remove_acl(idmap, dentry, acl_name);
 }
 
+/**
+ * security_inode_set_fscaps() - Check if setting fscaps is allowed
+ * @idmap: idmap of the mount
+ * @dentry: file
+ * @caps: fscaps to be written
+ * @flags: flags for setxattr
+ *
+ * Check permission before setting the file capabilities given in @vfs_caps.
+ *
+ * Return: Returns 0 if permission is granted.
+ */
+int security_inode_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+			      const struct vfs_caps *caps, int flags)
+{
+	if (unlikely(IS_PRIVATE(d_backing_inode(dentry))))
+		return 0;
+	return call_int_hook(inode_set_fscaps, 0, idmap, dentry, caps, flags);
+}
+
+/**
+ * security_inode_post_set_fscaps() - Update the inode after setting fscaps
+ * @idmap: idmap of the mount
+ * @dentry: file
+ * @caps: fscaps to be written
+ * @flags: flags for setxattr
+ *
+ * Update inode security field after successfully setting fscaps.
+ *
+ */
+void security_inode_post_set_fscaps(struct mnt_idmap *idmap,
+				    struct dentry *dentry,
+				    const struct vfs_caps *caps, int flags)
+{
+	if (unlikely(IS_PRIVATE(d_backing_inode(dentry))))
+		return;
+	call_void_hook(inode_post_set_fscaps, idmap, dentry, caps, flags);
+}
+
+/**
+ * security_inode_get_fscaps() - Check if reading fscaps is allowed
+ * @dentry: file
+ *
+ * Check permission before getting fscaps.
+ *
+ * Return: Returns 0 if permission is granted.
+ */
+int security_inode_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry)
+{
+	if (unlikely(IS_PRIVATE(d_backing_inode(dentry))))
+		return 0;
+	return call_int_hook(inode_get_fscaps, 0, idmap, dentry);
+}
+
+/**
+ * security_inode_remove_fscaps() - Check if removing fscaps is allowed
+ * @idmap: idmap of the mount
+ * @dentry: file
+ *
+ * Check permission before removing fscaps.
+ *
+ * Return: Returns 0 if permission is granted.
+ */
+int security_inode_remove_fscaps(struct mnt_idmap *idmap, struct dentry *dentry)
+{
+	if (unlikely(IS_PRIVATE(d_backing_inode(dentry))))
+		return 0;
+	return call_int_hook(inode_remove_fscaps, 0, idmap, dentry);
+}
+
 /**
  * security_inode_post_setxattr() - Update the inode after a setxattr operation
  * @dentry: file

-- 
2.43.0

