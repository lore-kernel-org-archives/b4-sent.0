From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 29 Nov 2023 15:50:29 -0600
Subject: [PATCH 11/16] ovl: add fscaps handlers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231129-idmap-fscap-refactor-v1-11-da5a26058a5b@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4821; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=BwiWRhULdTol/9WEQmsxas2IytUWyM/ogSTWu44qpJw=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBlZ7I6iAocplR2q2+fuSg1ko4e7Kz+2lEulIyGRTZ8
 n3DgHXeJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZWeyOgAKCRBTA5mu5fQxyUobB/
 9cVA5ptITHzeEzm+RIQcQADfXChKCFVQKeA6bHZok/18cgOkQk/26rzwsL5XdFD7fnv2bCrU9vRIRb
 30Z1oMUu1lq4adrgGuw0IhCsLbdY3Sh8o4KKBSqJXlYhMK3FpLMpV1C7ioFShEFLmIXLlIrUxmRNLe
 aWKQH7K7PUIzB16F2PxRmUkS99ZyafUJO2rx2rxh+BZR5gM+ieFJYTKZsy+oY3A4QTMzDaCYyipAnv
 XEXNxJ0jwDOQiQTnsw/M6p4DnzSJqhCQUX8GktpvTwLypNdTJnQkl6W2cfnOiTCFwSB/YfzaFa0SYy
 H/nnJe3yZCfkkB3Ngt58xpEwaqw7Il
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add handlers which read fs caps from the lower or upper filesystem and
write/remove fs caps to the upper filesystem, performing copy-up as
necessary.

While it doesn't make sense to use fscaps on directories, nothing in the
kernel actually prevents setting or getting fscaps xattrs for directory
inodes. If we omit fscaps handlers in ovl_dir_inode_operations then the
generic handlers will be used. These handlers will use the xattr inode
operations, bypassing any idmapping on lower mounts, so fscaps handlers
are also installed for ovl_dir_inode_operations.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 fs/overlayfs/dir.c       |  3 ++
 fs/overlayfs/inode.c     | 84 ++++++++++++++++++++++++++++++++++++++++++++++++
 fs/overlayfs/overlayfs.h |  6 ++++
 3 files changed, 93 insertions(+)

diff --git a/fs/overlayfs/dir.c b/fs/overlayfs/dir.c
index aab3f5d93556..d9ab3c9ce10a 100644
--- a/fs/overlayfs/dir.c
+++ b/fs/overlayfs/dir.c
@@ -1303,6 +1303,9 @@ const struct inode_operations ovl_dir_inode_operations = {
 	.get_inode_acl	= ovl_get_inode_acl,
 	.get_acl	= ovl_get_acl,
 	.set_acl	= ovl_set_acl,
+	.get_fscaps	= ovl_get_fscaps,
+	.set_fscaps	= ovl_set_fscaps,
+	.remove_fscaps	= ovl_remove_fscaps,
 	.update_time	= ovl_update_time,
 	.fileattr_get	= ovl_fileattr_get,
 	.fileattr_set	= ovl_fileattr_set,
diff --git a/fs/overlayfs/inode.c b/fs/overlayfs/inode.c
index c63b31a460be..82fc6e479d45 100644
--- a/fs/overlayfs/inode.c
+++ b/fs/overlayfs/inode.c
@@ -568,6 +568,87 @@ int ovl_set_acl(struct mnt_idmap *idmap, struct dentry *dentry,
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
+		   const struct vfs_caps *caps, int flags)
+{
+	int err;
+	struct ovl_fs *ofs = OVL_FS(dentry->d_sb);
+	struct dentry *upperdentry = ovl_dentry_upper(dentry);
+	struct dentry *realdentry = upperdentry ?: ovl_dentry_lower(dentry);
+	const struct cred *old_cred;
+
+	err = ovl_want_write(dentry);
+	if (err)
+		goto out;
+
+	if (!upperdentry) {
+		err = ovl_copy_up(dentry);
+		if (err)
+			goto out_drop_write;
+
+		realdentry = ovl_dentry_upper(dentry);
+	}
+
+	old_cred = ovl_override_creds(dentry->d_sb);
+	err = vfs_set_fscaps(ovl_upper_mnt_idmap(ofs), realdentry, caps, flags);
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
+int ovl_remove_fscaps(struct mnt_idmap *idmap, struct dentry *dentry)
+{
+	int err;
+	struct ovl_fs *ofs = OVL_FS(dentry->d_sb);
+	struct dentry *upperdentry = ovl_dentry_upper(dentry);
+	struct dentry *realdentry = upperdentry ?: ovl_dentry_lower(dentry);
+	const struct cred *old_cred;
+
+	err = ovl_want_write(dentry);
+	if (err)
+		goto out;
+
+	if (!upperdentry) {
+		err = ovl_copy_up(dentry);
+		if (err)
+			goto out_drop_write;
+
+		realdentry = ovl_dentry_upper(dentry);
+	}
+
+	old_cred = ovl_override_creds(dentry->d_sb);
+	err = vfs_remove_fscaps(ovl_upper_mnt_idmap(ofs), realdentry);
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
@@ -747,6 +828,9 @@ static const struct inode_operations ovl_file_inode_operations = {
 	.get_inode_acl	= ovl_get_inode_acl,
 	.get_acl	= ovl_get_acl,
 	.set_acl	= ovl_set_acl,
+	.get_fscaps	= ovl_get_fscaps,
+	.set_fscaps	= ovl_set_fscaps,
+	.remove_fscaps	= ovl_remove_fscaps,
 	.update_time	= ovl_update_time,
 	.fiemap		= ovl_fiemap,
 	.fileattr_get	= ovl_fileattr_get,
diff --git a/fs/overlayfs/overlayfs.h b/fs/overlayfs/overlayfs.h
index 05c3dd597fa8..e72ee2374f96 100644
--- a/fs/overlayfs/overlayfs.h
+++ b/fs/overlayfs/overlayfs.h
@@ -764,6 +764,12 @@ static inline struct posix_acl *ovl_get_acl_path(const struct path *path,
 }
 #endif
 
+int ovl_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+		   struct vfs_caps *caps);
+int ovl_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+		   const struct vfs_caps *caps, int flags);
+int ovl_remove_fscaps(struct mnt_idmap *idmap, struct dentry *dentry);
+
 int ovl_update_time(struct inode *inode, int flags);
 bool ovl_is_private_xattr(struct super_block *sb, const char *name);
 

-- 
2.43.0

