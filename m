From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:49 -0600
Subject: [PATCH v2 18/25] fs: add vfs_set_fscaps()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-18-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3582; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=+wh5MLx6qw22a4Y5hCQZNo83AwcQ+EWK6GdCRZ0V+nQ=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1mooRK6GQBMSPSNeq9TIC5Eyps87cR1e+jRyO5IO
 L9tbqdiJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqKAAKCRBTA5mu5fQxybD1B/
 9c/EK+CWeOAxlDfTdwJDnyY4A/3nNMB6EGtr5LZ4F2yneQa64m4QIo+ZrLzxwRuKvGPtIkZCsgv3Wb
 6VqtJ33/oxBPXedXR/8tZF8LC3tHmVHZfMcJiWkgNH1vM/2hjC3leSEQ3Srb60sYUy2gPEfXPlhWpe
 h/pci4hnVsUsdxdKrZxVZVwxFBuorxCAFi/1o0mLPD9pAPePer6DS5+YEVd3E+OgW7bBhAyDbiQacI
 Rs7+v+o8JqU+YEueRgm1Wmn00s+iF4/Rr+LY78hTjMrqWSXqxGiaZhctJhfft1eTDgbM1jEEsoYH6B
 N1daNdaH5CVnSWpjKxBb1/q+bBht8s
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Provide a type-safe interface for setting filesystem capabilities and a
generic implementation suitable for most filesystems.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 fs/xattr.c         | 79 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 include/linux/fs.h |  2 ++
 2 files changed, 81 insertions(+)

diff --git a/fs/xattr.c b/fs/xattr.c
index 10d1b1f78fc2..96de43928a51 100644
--- a/fs/xattr.c
+++ b/fs/xattr.c
@@ -245,6 +245,85 @@ int vfs_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
 }
 EXPORT_SYMBOL(vfs_get_fscaps);
 
+static int generic_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+			      const struct vfs_caps *caps, int setxattr_flags)
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
+				     &nscaps, size, setxattr_flags);
+}
+
+/**
+ * vfs_set_fscaps - set filesystem capabilities
+ * @idmap: idmap of the mount the inode was found from
+ * @dentry: the dentry on which to set filesystem capabilities
+ * @caps: the filesystem capabilities to be written
+ * @setxattr_flags: setxattr flags to use when writing the capabilities xattr
+ *
+ * This function writes the supplied filesystem capabilities to the dentry.
+ *
+ * Return: 0 on success, a negative errno on error.
+ */
+int vfs_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+		   const struct vfs_caps *caps, int setxattr_flags)
+{
+	struct inode *inode = d_inode(dentry);
+	struct inode *delegated_inode = NULL;
+	int error;
+
+retry_deleg:
+	inode_lock(inode);
+
+	error = xattr_permission(idmap, inode, XATTR_NAME_CAPS, MAY_WRITE);
+	if (error)
+		goto out_inode_unlock;
+	error = security_inode_set_fscaps(idmap, dentry, caps, setxattr_flags);
+	if (error)
+		goto out_inode_unlock;
+
+	error = try_break_deleg(inode, &delegated_inode);
+	if (error)
+		goto out_inode_unlock;
+
+	if (inode->i_opflags & IOP_XATTR) {
+		if (inode->i_op->set_fscaps)
+			error = inode->i_op->set_fscaps(idmap, dentry, caps,
+							setxattr_flags);
+		else
+			error = generic_set_fscaps(idmap, dentry, caps,
+						   setxattr_flags);
+		if (!error) {
+			fsnotify_xattr(dentry);
+			security_inode_post_set_fscaps(idmap, dentry, caps,
+						       setxattr_flags);
+		}
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
index d7cd2467e1ea..4f5d7ed44644 100644
--- a/include/linux/fs.h
+++ b/include/linux/fs.h
@@ -2120,6 +2120,8 @@ extern int vfs_get_fscaps_nosec(struct mnt_idmap *idmap, struct dentry *dentry,
 				struct vfs_caps *caps);
 extern int vfs_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
 			  struct vfs_caps *caps);
+extern int vfs_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+			  const struct vfs_caps *caps, int setxattr_flags);
 
 /**
  * enum freeze_holder - holder of the freeze

-- 
2.43.0

