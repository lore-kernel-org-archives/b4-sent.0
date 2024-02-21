From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:51 -0600
Subject: [PATCH v2 20/25] ovl: add fscaps handlers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-20-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4817; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=ttWdljGV2VOOVlmLs8ch4F+B9OPu/3AJrV4l738gSBE=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1moqr1C0o66vju1JEhWEhxdjP9MjLsg75RZLdJMz
 EGbaqxmJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqKgAKCRBTA5mu5fQxyasXB/
 0ck2MmFB/6xo9OUk9n0uU1WV1hFMVoAQcMtqmhIQz/2o92A+LSQK3qhijWqisOM+8FwP0mq2qJxzMN
 vIR8aLOcS0thGDP0hfR39KgwnIBaHRd/nB/r7IdYiRO+hJmxzhiWNUp1IIYYbAlGvxeD7YKcQaPI6w
 ujDpQ/1BRMFLG/aUZlWxGKGWcvTaun5znDQgPzJy2O4WmnYgB0YdN+3H+qKej3XIqL5cxd9tpymr8a
 HVtkrcMynShyHq7SIhQ1Hshd+ebeNCgKfG4XE3neYdZrCQjNHAcwys74zaZ8osEiqTuT5wf1p4sORt
 V1GcnFZzEQHrTdJSCnsZ7y7llnM8zr
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add handlers which read fs caps from the lower or upper filesystem and
write/remove fs caps to the upper filesystem, performing copy-up as
necessary.

While fscaps only really make sense on regular files, the general policy
is to allow most xattr namespaces on all different inode types, so
fscaps handlers are installed in the inode operations for all types of
inodes.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 fs/overlayfs/dir.c       |  2 ++
 fs/overlayfs/inode.c     | 72 ++++++++++++++++++++++++++++++++++++++++++++++++
 fs/overlayfs/overlayfs.h |  5 ++++
 3 files changed, 79 insertions(+)

diff --git a/fs/overlayfs/dir.c b/fs/overlayfs/dir.c
index 0f8b4a719237..4ff360fe10c9 100644
--- a/fs/overlayfs/dir.c
+++ b/fs/overlayfs/dir.c
@@ -1307,6 +1307,8 @@ const struct inode_operations ovl_dir_inode_operations = {
 	.get_inode_acl	= ovl_get_inode_acl,
 	.get_acl	= ovl_get_acl,
 	.set_acl	= ovl_set_acl,
+	.get_fscaps	= ovl_get_fscaps,
+	.set_fscaps	= ovl_set_fscaps,
 	.update_time	= ovl_update_time,
 	.fileattr_get	= ovl_fileattr_get,
 	.fileattr_set	= ovl_fileattr_set,
diff --git a/fs/overlayfs/inode.c b/fs/overlayfs/inode.c
index c63b31a460be..7a8978ea6fe1 100644
--- a/fs/overlayfs/inode.c
+++ b/fs/overlayfs/inode.c
@@ -568,6 +568,72 @@ int ovl_set_acl(struct mnt_idmap *idmap, struct dentry *dentry,
 }
 #endif
 
+int ovl_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+		   struct vfs_caps *caps)
+{
+	int err;
+	const struct cred *old_cred;
+	struct path realpath;
+
+	ovl_path_real(dentry, &realpath);
+	old_cred = ovl_override_creds(dentry->d_sb);
+	err = vfs_get_fscaps(mnt_idmap(realpath.mnt), realpath.dentry, caps);
+	revert_creds(old_cred);
+	return err;
+}
+
+int ovl_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+		   const struct vfs_caps *caps, int setxattr_flags)
+{
+	int err;
+	struct ovl_fs *ofs = OVL_FS(dentry->d_sb);
+	struct dentry *upperdentry = ovl_dentry_upper(dentry);
+	struct dentry *realdentry = upperdentry ?: ovl_dentry_lower(dentry);
+	const struct cred *old_cred;
+
+	/*
+	 * If the fscaps are to be remove from a lower file, check that they
+	 * exist before copying up.
+	 */
+	if (!caps && !upperdentry) {
+		struct path realpath;
+		struct vfs_caps lower_caps;
+
+		ovl_path_lower(dentry, &realpath);
+		old_cred = ovl_override_creds(dentry->d_sb);
+		err = vfs_get_fscaps(mnt_idmap(realpath.mnt), realdentry,
+				     &lower_caps);
+		revert_creds(old_cred);
+		if (err)
+			goto out;
+	}
+
+	err = ovl_want_write(dentry);
+	if (err)
+		goto out;
+
+	err = ovl_copy_up(dentry);
+	if (err)
+		goto out_drop_write;
+	upperdentry = ovl_dentry_upper(dentry);
+
+	old_cred = ovl_override_creds(dentry->d_sb);
+	if (!caps)
+		err = vfs_remove_fscaps(ovl_upper_mnt_idmap(ofs), upperdentry);
+	else
+		err = vfs_set_fscaps(ovl_upper_mnt_idmap(ofs), upperdentry,
+				     caps, setxattr_flags);
+	revert_creds(old_cred);
+
+	/* copy c/mtime */
+	ovl_copyattr(d_inode(dentry));
+
+out_drop_write:
+	ovl_drop_write(dentry);
+out:
+	return err;
+}
+
 int ovl_update_time(struct inode *inode, int flags)
 {
 	if (flags & S_ATIME) {
@@ -747,6 +813,8 @@ static const struct inode_operations ovl_file_inode_operations = {
 	.get_inode_acl	= ovl_get_inode_acl,
 	.get_acl	= ovl_get_acl,
 	.set_acl	= ovl_set_acl,
+	.get_fscaps	= ovl_get_fscaps,
+	.set_fscaps	= ovl_set_fscaps,
 	.update_time	= ovl_update_time,
 	.fiemap		= ovl_fiemap,
 	.fileattr_get	= ovl_fileattr_get,
@@ -758,6 +826,8 @@ static const struct inode_operations ovl_symlink_inode_operations = {
 	.get_link	= ovl_get_link,
 	.getattr	= ovl_getattr,
 	.listxattr	= ovl_listxattr,
+	.get_fscaps	= ovl_get_fscaps,
+	.set_fscaps	= ovl_set_fscaps,
 	.update_time	= ovl_update_time,
 };
 
@@ -769,6 +839,8 @@ static const struct inode_operations ovl_special_inode_operations = {
 	.get_inode_acl	= ovl_get_inode_acl,
 	.get_acl	= ovl_get_acl,
 	.set_acl	= ovl_set_acl,
+	.get_fscaps	= ovl_get_fscaps,
+	.set_fscaps	= ovl_set_fscaps,
 	.update_time	= ovl_update_time,
 };
 
diff --git a/fs/overlayfs/overlayfs.h b/fs/overlayfs/overlayfs.h
index ee949f3e7c77..4f948749ee02 100644
--- a/fs/overlayfs/overlayfs.h
+++ b/fs/overlayfs/overlayfs.h
@@ -781,6 +781,11 @@ static inline struct posix_acl *ovl_get_acl_path(const struct path *path,
 }
 #endif
 
+int ovl_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+		   struct vfs_caps *caps);
+int ovl_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+		   const struct vfs_caps *caps, int setxattr_flags);
+
 int ovl_update_time(struct inode *inode, int flags);
 bool ovl_is_private_xattr(struct super_block *sb, const char *name);
 

-- 
2.43.0

