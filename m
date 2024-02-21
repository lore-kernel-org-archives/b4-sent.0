From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:47 -0600
Subject: [PATCH v2 16/25] fs: add inode operations to get/set/remove fscaps
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-16-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3842; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=yjTkC6GQSOdkd/yofwHxTRqqG6BMoKBOmSs9mRH3lD0=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1momcOrJrmhhvfSlvseUc5ZkzjX47oXe/xbCoMiA
 8Fhev46JATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqJgAKCRBTA5mu5fQxyTg8B/
 4pdFVXDzplj+s5uQiNwRqie7BpHWe3tIOvDiVGDv576tfzBZUMOtKIm4/hiistj+rni3+bxxxwy1bZ
 h2v2QzDZVJACen4oBtiHhn0ushKMMxAvjSU7gdjX2S93lwm7Zohpkq/zf/lVpj4tqQyk0Y8m+qcThW
 YSWAFw666PemdoaOc3QKfeORxCuCimtGEScFebmaQXGK/fwUz6wQxVfIG+BzsMs4ZMK32RRtT8y+cI
 uKeQCrUVe1DzsTGff5EIdRfwgo5m+3LEV/8lmR4ZceA2pKeEJfJ0OuFbvhf3JV0P3lbi/mcCDdcZdT
 SZkQ1U89qyGJRlXpcGom2dKvclDCVV
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add inode operations for getting, setting and removing filesystem
capabilities rather than passing around raw xattr data. This provides
better type safety for ids contained within xattrs.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 Documentation/filesystems/locking.rst |  4 ++++
 Documentation/filesystems/vfs.rst     | 17 +++++++++++++++++
 include/linux/fs.h                    |  4 ++++
 3 files changed, 25 insertions(+)

diff --git a/Documentation/filesystems/locking.rst b/Documentation/filesystems/locking.rst
index d5bf4b6b7509..d208dd9f75ae 100644
--- a/Documentation/filesystems/locking.rst
+++ b/Documentation/filesystems/locking.rst
@@ -81,6 +81,8 @@ prototypes::
 				umode_t create_mode);
 	int (*tmpfile) (struct mnt_idmap *, struct inode *,
 			struct file *, umode_t);
+	int (*get_fscaps)(struct mnt_idmap *, struct dentry *, struct vfs_caps *);
+	int (*set_fscaps)(struct mnt_idmap *, struct dentry *, const struct vfs_caps *, int setxattr_flags);
 	int (*fileattr_set)(struct mnt_idmap *idmap,
 			    struct dentry *dentry, struct fileattr *fa);
 	int (*fileattr_get)(struct dentry *dentry, struct fileattr *fa);
@@ -114,6 +116,8 @@ fiemap:		no
 update_time:	no
 atomic_open:	shared (exclusive if O_CREAT is set in open flags)
 tmpfile:	no
+get_fscaps:     no
+set_fscaps:     exclusive
 fileattr_get:	no or exclusive
 fileattr_set:	exclusive
 get_offset_ctx  no
diff --git a/Documentation/filesystems/vfs.rst b/Documentation/filesystems/vfs.rst
index eebcc0f9e2bc..ed1cb03f271e 100644
--- a/Documentation/filesystems/vfs.rst
+++ b/Documentation/filesystems/vfs.rst
@@ -514,6 +514,8 @@ As of kernel 2.6.22, the following members are defined:
 		int (*tmpfile) (struct mnt_idmap *, struct inode *, struct file *, umode_t);
 		struct posix_acl * (*get_acl)(struct mnt_idmap *, struct dentry *, int);
 	        int (*set_acl)(struct mnt_idmap *, struct dentry *, struct posix_acl *, int);
+		int (*get_fscaps)(struct mnt_idmap *, struct dentry *, struct vfs_caps *);
+		int (*set_fscaps)(struct mnt_idmap *, struct dentry *, const struct vfs_caps *, int setxattr_flags);
 		int (*fileattr_set)(struct mnt_idmap *idmap,
 				    struct dentry *dentry, struct fileattr *fa);
 		int (*fileattr_get)(struct dentry *dentry, struct fileattr *fa);
@@ -667,6 +669,21 @@ otherwise noted.
 	open; this can be done by calling finish_open_simple() right at
 	the end.
 
+``get_fscaps``
+
+        called to get filesystem capabilites of an inode.  If unset,
+        xattr handlers will be used to get the raw xattr data.  Most
+        filesystems can rely on the generic handler.
+
+``set_fscaps``
+
+        called to set filesystem capabilites of an inode.  If unset,
+        xattr handlers will be used to set the raw xattr data.  Most
+        filesystems can rely on the generic handler.
+
+        If the new fscaps value is NULL the filesystem must remove any
+        fscaps from the inode.
+
 ``fileattr_get``
 	called on ioctl(FS_IOC_GETFLAGS) and ioctl(FS_IOC_FSGETXATTR) to
 	retrieve miscellaneous file flags and attributes.  Also called
diff --git a/include/linux/fs.h b/include/linux/fs.h
index ed5966a70495..89163e0f7aad 100644
--- a/include/linux/fs.h
+++ b/include/linux/fs.h
@@ -2067,6 +2067,10 @@ struct inode_operations {
 				     int);
 	int (*set_acl)(struct mnt_idmap *, struct dentry *,
 		       struct posix_acl *, int);
+	int (*get_fscaps)(struct mnt_idmap *, struct dentry *,
+			  struct vfs_caps *);
+	int (*set_fscaps)(struct mnt_idmap *, struct dentry *,
+			  const struct vfs_caps *, int setxattr_flags);
 	int (*fileattr_set)(struct mnt_idmap *idmap,
 			    struct dentry *dentry, struct fileattr *fa);
 	int (*fileattr_get)(struct dentry *dentry, struct fileattr *fa);

-- 
2.43.0

