From: Daan De Meyer <daan@amutable.com>
Date: Fri, 04 Sep 2026 16:48:55 +0200
Subject: [PATCH v3 1/2] lsm: expose mount idmaps to inode hooks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260904-lsm-mount-idmaps-v3-1-920a1963675d@amutable.com>
References: <20260904-lsm-mount-idmaps-v3-0-920a1963675d@amutable.com>
In-Reply-To: <20260904-lsm-mount-idmaps-v3-0-920a1963675d@amutable.com>
To: Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, Paul Moore <paul@paul-moore.com>
Cc: linux-fsdevel@vger.kernel.org, linux-security-module@vger.kernel.org, 
 Daan De Meyer <daan@amutable.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788533337; l=20921;
 i=daan@amutable.com; s=20260712; h=from:subject:message-id;
 bh=0JAIxiQ9zKoY4KM2Za7vPDmUIJxxnFJ5cyVbY5St0yk=;
 b=FuSQy2NAdW9g/SCaDCr7kRiUBroLWRc92XwWJiCK7giomdIcrJ4rV/SeQC8mz3WbwkbN62sji
 Je4g4L7WyvRDZZtsivHIVPdNql18vd2B6+bx6y4ZfmPpInmkGA/iNX9
X-Developer-Key: i=daan@amutable.com; a=ed25519;
 pk=I1l+WwrtmzRgofA5SQ1wTuJi18fjh91w+f5uRkFeZEA=
X-Endpoint-Received: by B4 Relay for daan@amutable.com/20260712 with auth_id=868
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pass the mount idmap through the create, link, symlink, mkdir, mknod,
and permission hooks. Update the in-tree security implementations and
non-VFS callers accordingly.

Signed-off-by: Daan De Meyer <daan@amutable.com>
---
 fs/cachefiles/security.c      |  4 +--
 fs/namei.c                    | 18 +++++++-------
 include/linux/lsm_hook_defs.h | 23 +++++++++--------
 include/linux/security.h      | 58 +++++++++++++++++++++++++------------------
 security/security.c           | 40 +++++++++++++++++------------
 security/selinux/hooks.c      | 19 +++++++++-----
 security/smack/smack_lsm.c    |  9 ++++---
 7 files changed, 100 insertions(+), 71 deletions(-)

diff --git a/fs/cachefiles/security.c b/fs/cachefiles/security.c
index fc6611886b3b..eefe5453b904 100644
--- a/fs/cachefiles/security.c
+++ b/fs/cachefiles/security.c
@@ -51,14 +51,14 @@ static int cachefiles_check_cache_dir(struct cachefiles_cache *cache,
 {
 	int ret;
 
-	ret = security_inode_mkdir(d_backing_inode(root), root, 0);
+	ret = security_inode_mkdir(&nop_mnt_idmap, d_backing_inode(root), root, 0);
 	if (ret < 0) {
 		pr_err("Security denies permission to make dirs: error %d",
 		       ret);
 		return ret;
 	}
 
-	ret = security_inode_create(d_backing_inode(root), root, 0);
+	ret = security_inode_create(&nop_mnt_idmap, d_backing_inode(root), root, 0);
 	if (ret < 0)
 		pr_err("Security denies permission to create files: error %d",
 		       ret);
diff --git a/fs/namei.c b/fs/namei.c
index 20a6534ea3ef..99f894f3f7e1 100644
--- a/fs/namei.c
+++ b/fs/namei.c
@@ -658,7 +658,7 @@ int inode_permission(struct mnt_idmap *idmap,
 	if (unlikely(retval))
 		return retval;
 
-	return security_inode_permission(inode, mask);
+	return security_inode_permission(idmap, inode, mask);
 }
 EXPORT_SYMBOL(inode_permission);
 
@@ -695,7 +695,7 @@ static __always_inline int lookup_inode_permission_may_exec(struct mnt_idmap *id
 	if (unlikely(((inode->i_mode & 0111) != 0111) || !no_acl_inode(inode)))
 		return inode_permission(idmap, inode, mask);
 
-	return security_inode_permission(inode, mask);
+	return security_inode_permission(idmap, inode, mask);
 }
 
 /**
@@ -4188,7 +4188,7 @@ int vfs_create(struct mnt_idmap *idmap, struct dentry *dentry, umode_t mode,
 		return -EACCES;	/* shouldn't it be ENOSYS? */
 
 	mode = vfs_prepare_mode(idmap, dir, mode, S_IALLUGO, S_IFREG);
-	error = security_inode_create(dir, dentry, mode);
+	error = security_inode_create(idmap, dir, dentry, mode);
 	if (error)
 		return error;
 	error = try_break_deleg(dir, LEASE_BREAK_DIR_CREATE, di);
@@ -4212,7 +4212,7 @@ int vfs_mkobj(struct dentry *dentry, umode_t mode,
 
 	mode &= S_IALLUGO;
 	mode |= S_IFREG;
-	error = security_inode_create(dir, dentry, mode);
+	error = security_inode_create(&nop_mnt_idmap, dir, dentry, mode);
 	if (error)
 		return error;
 	error = f(dentry, mode, arg);
@@ -4328,7 +4328,7 @@ static int may_o_create(struct mnt_idmap *idmap,
 	if (error)
 		return error;
 
-	return security_inode_create(dir->dentry->d_inode, dentry, mode);
+	return security_inode_create(idmap, dir->dentry->d_inode, dentry, mode);
 }
 
 /**
@@ -5258,7 +5258,7 @@ int vfs_mknod(struct mnt_idmap *idmap, struct inode *dir,
 	if (error)
 		return error;
 
-	error = security_inode_mknod(dir, dentry, mode, dev);
+	error = security_inode_mknod(idmap, dir, dentry, mode, dev);
 	if (error)
 		return error;
 
@@ -5395,7 +5395,7 @@ struct dentry *vfs_mkdir(struct mnt_idmap *idmap, struct inode *dir,
 		goto err;
 
 	mode = vfs_prepare_mode(idmap, dir, mode, S_IRWXUGO | S_ISVTX, S_IFDIR);
-	error = security_inode_mkdir(dir, dentry, mode);
+	error = security_inode_mkdir(idmap, dir, dentry, mode);
 	if (error)
 		goto err;
 
@@ -5783,7 +5783,7 @@ int vfs_symlink(struct mnt_idmap *idmap, struct inode *dir,
 	if (!dir->i_op->symlink)
 		return -EPERM;
 
-	error = security_inode_symlink(dir, dentry, oldname);
+	error = security_inode_symlink(idmap, dir, dentry, oldname);
 	if (error)
 		return error;
 
@@ -5907,7 +5907,7 @@ int vfs_link(struct dentry *old_dentry, struct mnt_idmap *idmap,
 	if (S_ISDIR(inode->i_mode))
 		return -EPERM;
 
-	error = security_inode_link(old_dentry, dir, new_dentry);
+	error = security_inode_link(idmap, old_dentry, dir, new_dentry);
 	if (error)
 		return error;
 
diff --git a/include/linux/lsm_hook_defs.h b/include/linux/lsm_hook_defs.h
index 65c9609ec207..9e49a5bc9ff3 100644
--- a/include/linux/lsm_hook_defs.h
+++ b/include/linux/lsm_hook_defs.h
@@ -120,26 +120,27 @@ LSM_HOOK(int, -EOPNOTSUPP, inode_init_security, struct inode *inode,
 	 int *xattr_count)
 LSM_HOOK(int, 0, inode_init_security_anon, struct inode *inode,
 	 const struct qstr *name, const struct inode *context_inode)
-LSM_HOOK(int, 0, inode_create, struct inode *dir, struct dentry *dentry,
-	 umode_t mode)
+LSM_HOOK(int, 0, inode_create, struct mnt_idmap *idmap, struct inode *dir,
+	 struct dentry *dentry, umode_t mode)
 LSM_HOOK(void, LSM_RET_VOID, inode_post_create_tmpfile, struct mnt_idmap *idmap,
 	 struct inode *inode)
-LSM_HOOK(int, 0, inode_link, struct dentry *old_dentry, struct inode *dir,
-	 struct dentry *new_dentry)
+LSM_HOOK(int, 0, inode_link, struct mnt_idmap *idmap,
+	 struct dentry *old_dentry, struct inode *dir, struct dentry *new_dentry)
 LSM_HOOK(int, 0, inode_unlink, struct inode *dir, struct dentry *dentry)
-LSM_HOOK(int, 0, inode_symlink, struct inode *dir, struct dentry *dentry,
-	 const char *old_name)
-LSM_HOOK(int, 0, inode_mkdir, struct inode *dir, struct dentry *dentry,
-	 umode_t mode)
+LSM_HOOK(int, 0, inode_symlink, struct mnt_idmap *idmap, struct inode *dir,
+	 struct dentry *dentry, const char *old_name)
+LSM_HOOK(int, 0, inode_mkdir, struct mnt_idmap *idmap, struct inode *dir,
+	 struct dentry *dentry, umode_t mode)
 LSM_HOOK(int, 0, inode_rmdir, struct inode *dir, struct dentry *dentry)
-LSM_HOOK(int, 0, inode_mknod, struct inode *dir, struct dentry *dentry,
-	 umode_t mode, dev_t dev)
+LSM_HOOK(int, 0, inode_mknod, struct mnt_idmap *idmap, struct inode *dir,
+	 struct dentry *dentry, umode_t mode, dev_t dev)
 LSM_HOOK(int, 0, inode_rename, struct inode *old_dir, struct dentry *old_dentry,
 	 struct inode *new_dir, struct dentry *new_dentry)
 LSM_HOOK(int, 0, inode_readlink, struct dentry *dentry)
 LSM_HOOK(int, 0, inode_follow_link, struct dentry *dentry, struct inode *inode,
 	 bool rcu)
-LSM_HOOK(int, 0, inode_permission, struct inode *inode, int mask)
+LSM_HOOK(int, 0, inode_permission, struct mnt_idmap *idmap,
+	 struct inode *inode, int mask)
 LSM_HOOK(int, 0, inode_setattr, struct mnt_idmap *idmap, struct dentry *dentry,
 	 struct iattr *attr)
 LSM_HOOK(void, LSM_RET_VOID, inode_post_setattr, struct mnt_idmap *idmap,
diff --git a/include/linux/security.h b/include/linux/security.h
index 153e9043058f..0f5f20ac1050 100644
--- a/include/linux/security.h
+++ b/include/linux/security.h
@@ -404,24 +404,28 @@ int security_inode_init_security(struct inode *inode, struct inode *dir,
 int security_inode_init_security_anon(struct inode *inode,
 				      const struct qstr *name,
 				      const struct inode *context_inode);
-int security_inode_create(struct inode *dir, struct dentry *dentry, umode_t mode);
+int security_inode_create(struct mnt_idmap *idmap, struct inode *dir,
+			  struct dentry *dentry, umode_t mode);
 void security_inode_post_create_tmpfile(struct mnt_idmap *idmap,
 					struct inode *inode);
-int security_inode_link(struct dentry *old_dentry, struct inode *dir,
-			 struct dentry *new_dentry);
+int security_inode_link(struct mnt_idmap *idmap, struct dentry *old_dentry,
+			struct inode *dir, struct dentry *new_dentry);
 int security_inode_unlink(struct inode *dir, struct dentry *dentry);
-int security_inode_symlink(struct inode *dir, struct dentry *dentry,
-			   const char *old_name);
-int security_inode_mkdir(struct inode *dir, struct dentry *dentry, umode_t mode);
+int security_inode_symlink(struct mnt_idmap *idmap, struct inode *dir,
+			   struct dentry *dentry, const char *old_name);
+int security_inode_mkdir(struct mnt_idmap *idmap, struct inode *dir,
+			 struct dentry *dentry, umode_t mode);
 int security_inode_rmdir(struct inode *dir, struct dentry *dentry);
-int security_inode_mknod(struct inode *dir, struct dentry *dentry, umode_t mode, dev_t dev);
+int security_inode_mknod(struct mnt_idmap *idmap, struct inode *dir,
+			 struct dentry *dentry, umode_t mode, dev_t dev);
 int security_inode_rename(struct inode *old_dir, struct dentry *old_dentry,
 			  struct inode *new_dir, struct dentry *new_dentry,
 			  unsigned int flags);
 int security_inode_readlink(struct dentry *dentry);
 int security_inode_follow_link(struct dentry *dentry, struct inode *inode,
 			       bool rcu);
-int security_inode_permission(struct inode *inode, int mask);
+int security_inode_permission(struct mnt_idmap *idmap, struct inode *inode,
+			      int mask);
 int security_inode_setattr(struct mnt_idmap *idmap,
 			   struct dentry *dentry, struct iattr *attr);
 void security_inode_post_setattr(struct mnt_idmap *idmap, struct dentry *dentry,
@@ -902,9 +906,10 @@ static inline int security_inode_init_security_anon(struct inode *inode,
 	return 0;
 }
 
-static inline int security_inode_create(struct inode *dir,
-					 struct dentry *dentry,
-					 umode_t mode)
+static inline int security_inode_create(struct mnt_idmap *idmap,
+					struct inode *dir,
+					struct dentry *dentry,
+					umode_t mode)
 {
 	return 0;
 }
@@ -913,9 +918,10 @@ static inline void
 security_inode_post_create_tmpfile(struct mnt_idmap *idmap, struct inode *inode)
 { }
 
-static inline int security_inode_link(struct dentry *old_dentry,
-				       struct inode *dir,
-				       struct dentry *new_dentry)
+static inline int security_inode_link(struct mnt_idmap *idmap,
+				      struct dentry *old_dentry,
+				      struct inode *dir,
+				      struct dentry *new_dentry)
 {
 	return 0;
 }
@@ -926,16 +932,18 @@ static inline int security_inode_unlink(struct inode *dir,
 	return 0;
 }
 
-static inline int security_inode_symlink(struct inode *dir,
-					  struct dentry *dentry,
-					  const char *old_name)
+static inline int security_inode_symlink(struct mnt_idmap *idmap,
+					 struct inode *dir,
+					 struct dentry *dentry,
+					 const char *old_name)
 {
 	return 0;
 }
 
-static inline int security_inode_mkdir(struct inode *dir,
-					struct dentry *dentry,
-					int mode)
+static inline int security_inode_mkdir(struct mnt_idmap *idmap,
+				       struct inode *dir,
+				       struct dentry *dentry,
+				       int mode)
 {
 	return 0;
 }
@@ -946,9 +954,10 @@ static inline int security_inode_rmdir(struct inode *dir,
 	return 0;
 }
 
-static inline int security_inode_mknod(struct inode *dir,
-					struct dentry *dentry,
-					int mode, dev_t dev)
+static inline int security_inode_mknod(struct mnt_idmap *idmap,
+				       struct inode *dir,
+				       struct dentry *dentry,
+				       int mode, dev_t dev)
 {
 	return 0;
 }
@@ -974,7 +983,8 @@ static inline int security_inode_follow_link(struct dentry *dentry,
 	return 0;
 }
 
-static inline int security_inode_permission(struct inode *inode, int mask)
+static inline int security_inode_permission(struct mnt_idmap *idmap,
+					    struct inode *inode, int mask)
 {
 	return 0;
 }
diff --git a/security/security.c b/security/security.c
index 2ee276ab15c5..a9190da3341d 100644
--- a/security/security.c
+++ b/security/security.c
@@ -1614,6 +1614,7 @@ int security_path_chroot(const struct path *path)
 
 /**
  * security_inode_create() - Check if creating a file is allowed
+ * @idmap: idmap of the mount
  * @dir: the parent directory
  * @dentry: the file being created
  * @mode: requested file mode
@@ -1622,12 +1623,12 @@ int security_path_chroot(const struct path *path)
  *
  * Return: Returns 0 if permission is granted.
  */
-int security_inode_create(struct inode *dir, struct dentry *dentry,
-			  umode_t mode)
+int security_inode_create(struct mnt_idmap *idmap, struct inode *dir,
+			  struct dentry *dentry, umode_t mode)
 {
 	if (unlikely(IS_PRIVATE(dir)))
 		return 0;
-	return call_int_hook(inode_create, dir, dentry, mode);
+	return call_int_hook(inode_create, idmap, dir, dentry, mode);
 }
 EXPORT_SYMBOL_GPL(security_inode_create);
 
@@ -1648,6 +1649,7 @@ void security_inode_post_create_tmpfile(struct mnt_idmap *idmap,
 
 /**
  * security_inode_link() - Check if creating a hard link is allowed
+ * @idmap: idmap of the mount
  * @old_dentry: existing file
  * @dir: new parent directory
  * @new_dentry: new link
@@ -1656,12 +1658,12 @@ void security_inode_post_create_tmpfile(struct mnt_idmap *idmap,
  *
  * Return: Returns 0 if permission is granted.
  */
-int security_inode_link(struct dentry *old_dentry, struct inode *dir,
-			struct dentry *new_dentry)
+int security_inode_link(struct mnt_idmap *idmap, struct dentry *old_dentry,
+			struct inode *dir, struct dentry *new_dentry)
 {
 	if (unlikely(IS_PRIVATE(d_backing_inode(old_dentry))))
 		return 0;
-	return call_int_hook(inode_link, old_dentry, dir, new_dentry);
+	return call_int_hook(inode_link, idmap, old_dentry, dir, new_dentry);
 }
 
 /**
@@ -1682,6 +1684,7 @@ int security_inode_unlink(struct inode *dir, struct dentry *dentry)
 
 /**
  * security_inode_symlink() - Check if creating a symbolic link is allowed
+ * @idmap: idmap of the mount
  * @dir: parent directory
  * @dentry: symbolic link
  * @old_name: existing filename
@@ -1690,16 +1693,17 @@ int security_inode_unlink(struct inode *dir, struct dentry *dentry)
  *
  * Return: Returns 0 if permission is granted.
  */
-int security_inode_symlink(struct inode *dir, struct dentry *dentry,
-			   const char *old_name)
+int security_inode_symlink(struct mnt_idmap *idmap, struct inode *dir,
+			   struct dentry *dentry, const char *old_name)
 {
 	if (unlikely(IS_PRIVATE(dir)))
 		return 0;
-	return call_int_hook(inode_symlink, dir, dentry, old_name);
+	return call_int_hook(inode_symlink, idmap, dir, dentry, old_name);
 }
 
 /**
  * security_inode_mkdir() - Check if creating a new directory is allowed
+ * @idmap: idmap of the mount
  * @dir: parent directory
  * @dentry: new directory
  * @mode: new directory mode
@@ -1709,11 +1713,12 @@ int security_inode_symlink(struct inode *dir, struct dentry *dentry,
  *
  * Return: Returns 0 if permission is granted.
  */
-int security_inode_mkdir(struct inode *dir, struct dentry *dentry, umode_t mode)
+int security_inode_mkdir(struct mnt_idmap *idmap, struct inode *dir,
+			 struct dentry *dentry, umode_t mode)
 {
 	if (unlikely(IS_PRIVATE(dir)))
 		return 0;
-	return call_int_hook(inode_mkdir, dir, dentry, mode);
+	return call_int_hook(inode_mkdir, idmap, dir, dentry, mode);
 }
 EXPORT_SYMBOL_GPL(security_inode_mkdir);
 
@@ -1735,6 +1740,7 @@ int security_inode_rmdir(struct inode *dir, struct dentry *dentry)
 
 /**
  * security_inode_mknod() - Check if creating a special file is allowed
+ * @idmap: idmap of the mount
  * @dir: parent directory
  * @dentry: new file
  * @mode: new file mode
@@ -1747,12 +1753,12 @@ int security_inode_rmdir(struct inode *dir, struct dentry *dentry)
  *
  * Return: Returns 0 if permission is granted.
  */
-int security_inode_mknod(struct inode *dir, struct dentry *dentry,
-			 umode_t mode, dev_t dev)
+int security_inode_mknod(struct mnt_idmap *idmap, struct inode *dir,
+			 struct dentry *dentry, umode_t mode, dev_t dev)
 {
 	if (unlikely(IS_PRIVATE(dir)))
 		return 0;
-	return call_int_hook(inode_mknod, dir, dentry, mode, dev);
+	return call_int_hook(inode_mknod, idmap, dir, dentry, mode, dev);
 }
 
 /**
@@ -1823,6 +1829,7 @@ int security_inode_follow_link(struct dentry *dentry, struct inode *inode,
 
 /**
  * security_inode_permission() - Check if accessing an inode is allowed
+ * @idmap: idmap of the mount
  * @inode: inode
  * @mask: access mask
  *
@@ -1835,11 +1842,12 @@ int security_inode_follow_link(struct dentry *dentry, struct inode *inode,
  *
  * Return: Returns 0 if permission is granted.
  */
-int security_inode_permission(struct inode *inode, int mask)
+int security_inode_permission(struct mnt_idmap *idmap, struct inode *inode,
+			      int mask)
 {
 	if (unlikely(IS_PRIVATE(inode)))
 		return 0;
-	return call_int_hook(inode_permission, inode, mask);
+	return call_int_hook(inode_permission, idmap, inode, mask);
 }
 
 /**
diff --git a/security/selinux/hooks.c b/security/selinux/hooks.c
index 035aaf113d1d..967984d0af30 100644
--- a/security/selinux/hooks.c
+++ b/security/selinux/hooks.c
@@ -3074,12 +3074,14 @@ static int selinux_inode_init_security_anon(struct inode *inode,
 			    &ad);
 }
 
-static int selinux_inode_create(struct inode *dir, struct dentry *dentry, umode_t mode)
+static int selinux_inode_create(struct mnt_idmap *idmap, struct inode *dir,
+				struct dentry *dentry, umode_t mode)
 {
 	return may_create(dir, dentry, SECCLASS_FILE);
 }
 
-static int selinux_inode_link(struct dentry *old_dentry, struct inode *dir, struct dentry *new_dentry)
+static int selinux_inode_link(struct mnt_idmap *idmap, struct dentry *old_dentry,
+			      struct inode *dir, struct dentry *new_dentry)
 {
 	return may_link(dir, old_dentry, MAY_LINK);
 }
@@ -3089,12 +3091,14 @@ static int selinux_inode_unlink(struct inode *dir, struct dentry *dentry)
 	return may_link(dir, dentry, MAY_UNLINK);
 }
 
-static int selinux_inode_symlink(struct inode *dir, struct dentry *dentry, const char *name)
+static int selinux_inode_symlink(struct mnt_idmap *idmap, struct inode *dir,
+				 struct dentry *dentry, const char *name)
 {
 	return may_create(dir, dentry, SECCLASS_LNK_FILE);
 }
 
-static int selinux_inode_mkdir(struct inode *dir, struct dentry *dentry, umode_t mask)
+static int selinux_inode_mkdir(struct mnt_idmap *idmap, struct inode *dir,
+			       struct dentry *dentry, umode_t mask)
 {
 	return may_create(dir, dentry, SECCLASS_DIR);
 }
@@ -3104,7 +3108,8 @@ static int selinux_inode_rmdir(struct inode *dir, struct dentry *dentry)
 	return may_link(dir, dentry, MAY_RMDIR);
 }
 
-static int selinux_inode_mknod(struct inode *dir, struct dentry *dentry, umode_t mode, dev_t dev)
+static int selinux_inode_mknod(struct mnt_idmap *idmap, struct inode *dir,
+			       struct dentry *dentry, umode_t mode, dev_t dev)
 {
 	return may_create(dir, dentry, inode_mode_to_security_class(mode));
 }
@@ -3236,13 +3241,15 @@ static inline void task_avdcache_update(struct task_security_struct *tsec,
 
 /**
  * selinux_inode_permission - Check if the current task can access an inode
+ * @idmap: idmap of the mount
  * @inode: the inode that is being accessed
  * @requested: the accesses being requested
  *
  * Check if the current task is allowed to access @inode according to
  * @requested.  Returns 0 if allowed, negative values otherwise.
  */
-static int selinux_inode_permission(struct inode *inode, int requested)
+static int selinux_inode_permission(struct mnt_idmap *idmap,
+				    struct inode *inode, int requested)
 {
 	int mask;
 	u32 perms;
diff --git a/security/smack/smack_lsm.c b/security/smack/smack_lsm.c
index 8e88ac65fd7f..a45819d13c0d 100644
--- a/security/smack/smack_lsm.c
+++ b/security/smack/smack_lsm.c
@@ -1089,14 +1089,15 @@ static int smack_inode_init_security(struct inode *inode, struct inode *dir,
 
 /**
  * smack_inode_link - Smack check on link
+ * @idmap: idmap of the mount
  * @old_dentry: the existing object
  * @dir: unused
  * @new_dentry: the new object
  *
  * Returns 0 if access is permitted, an error code otherwise
  */
-static int smack_inode_link(struct dentry *old_dentry, struct inode *dir,
-			    struct dentry *new_dentry)
+static int smack_inode_link(struct mnt_idmap *idmap, struct dentry *old_dentry,
+			    struct inode *dir, struct dentry *new_dentry)
 {
 	struct smack_known *isp;
 	struct smk_audit_info ad;
@@ -1226,6 +1227,7 @@ static int smack_inode_rename(struct inode *old_inode,
 
 /**
  * smack_inode_permission - Smack version of permission()
+ * @idmap: idmap of the mount
  * @inode: the inode in question
  * @mask: the access requested
  *
@@ -1233,7 +1235,8 @@ static int smack_inode_rename(struct inode *old_inode,
  *
  * Returns 0 if access is permitted, an error code otherwise
  */
-static int smack_inode_permission(struct inode *inode, int mask)
+static int smack_inode_permission(struct mnt_idmap *idmap, struct inode *inode,
+				  int mask)
 {
 	struct superblock_smack *sbsp = smack_superblock(inode->i_sb);
 	struct smk_audit_info ad;

-- 
2.54.0

