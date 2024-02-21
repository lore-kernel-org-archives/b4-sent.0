From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:45 -0600
Subject: [PATCH v2 14/25] evm: add support for fscaps security hooks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-14-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4327; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=Yr3ph0XCYOXrp9CXWdQMd7IWQbhJjbtCnaMZrcY53gY=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1mol25TRgD1iHEn0O+Lzt/PUvoaNtWltRiGhhXzf
 m3QV75SJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqJQAKCRBTA5mu5fQxyS9CB/
 9kSIwlWp/cTH5n9oXEiY7IRY7QctvMWegFyimx7di5G0HHXG0GkFzYw+GCyZNDCVL5R5AuZIagZMKH
 cytRQKwJZdn+UxoBt7VxRcVA0NXxcM5vRXXYDzuNpVQNmbfH5HvHaFvaIDzOEYFmJqsIW/jaxzfWVB
 RjglGLzpDryq2M/ZCsQx9KBTGmEwTBnxzalQNyrtvXgG4UHhg2ZBqBAWhD3SNXDCf7Ii95JGmya1vE
 xyBqVMzbjM3/l+t7NBgQWvLHaHz7A3od4uGdwyYRfroyU95TFJcCTgcv4bgK682Ja2e9Zo3X4dw5Wp
 Ka5r0Q2dpUgYDHMm+pijpjRjRaNrcP
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support the new fscaps security hooks by converting the vfs_caps to raw
xattr data and then handling them the same as other xattrs.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 include/linux/evm.h               | 39 +++++++++++++++++++++++++
 security/integrity/evm/evm_main.c | 60 +++++++++++++++++++++++++++++++++++++++
 2 files changed, 99 insertions(+)

diff --git a/include/linux/evm.h b/include/linux/evm.h
index 36ec884320d9..aeb9ff52ad22 100644
--- a/include/linux/evm.h
+++ b/include/linux/evm.h
@@ -57,6 +57,20 @@ static inline void evm_inode_post_set_acl(struct dentry *dentry,
 {
 	return evm_inode_post_setxattr(dentry, acl_name, NULL, 0);
 }
+extern int evm_inode_set_fscaps(struct mnt_idmap *idmap,
+				struct dentry *dentry,
+				const struct vfs_caps *caps, int flags);
+static inline int evm_inode_remove_fscaps(struct dentry *dentry)
+{
+	return evm_inode_set_fscaps(&nop_mnt_idmap, dentry, NULL, XATTR_REPLACE);
+}
+extern void evm_inode_post_set_fscaps(struct mnt_idmap *idmap,
+				      struct dentry *dentry,
+				      const struct vfs_caps *caps, int flags);
+static inline void evm_inode_post_remove_fscaps(struct dentry *dentry)
+{
+	return evm_inode_post_set_fscaps(&nop_mnt_idmap, dentry, NULL, 0);
+}
 
 int evm_inode_init_security(struct inode *inode, struct inode *dir,
 			    const struct qstr *qstr, struct xattr *xattrs,
@@ -164,6 +178,31 @@ static inline void evm_inode_post_set_acl(struct dentry *dentry,
 	return;
 }
 
+static inline int evm_inode_set_fscaps(struct mnt_idmap *idmap,
+				       struct dentry *dentry,
+				       const struct vfs_caps *caps, int flags)
+{
+	return 0;
+}
+
+static inline int evm_inode_remove_fscaps(struct dentry *dentry)
+{
+	return 0;
+}
+
+static inline void evm_inode_post_set_fscaps(struct mnt_idmap *idmap,
+					     struct dentry *dentry,
+					     const struct vfs_caps *caps,
+					     int flags)
+{
+	return;
+}
+
+static inline void evm_inode_post_remove_fscaps(struct dentry *dentry)
+{
+	return;
+}
+
 static inline int evm_inode_init_security(struct inode *inode, struct inode *dir,
 					  const struct qstr *qstr,
 					  struct xattr *xattrs,
diff --git a/security/integrity/evm/evm_main.c b/security/integrity/evm/evm_main.c
index cc7956d7878b..ecf4634a921a 100644
--- a/security/integrity/evm/evm_main.c
+++ b/security/integrity/evm/evm_main.c
@@ -805,6 +805,66 @@ void evm_inode_post_removexattr(struct dentry *dentry, const char *xattr_name)
 	evm_update_evmxattr(dentry, xattr_name, NULL, 0);
 }
 
+int evm_inode_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+			 const struct vfs_caps *caps, int flags)
+{
+	struct inode *inode = d_inode(dentry);
+	struct vfs_ns_cap_data nscaps;
+	const void *xattr_data = NULL;
+	int size = 0;
+
+	/* Policy permits modification of the protected xattrs even though
+	 * there's no HMAC key loaded
+	 */
+	if (evm_initialized & EVM_ALLOW_METADATA_WRITES)
+		return 0;
+
+	if (caps) {
+		size = vfs_caps_to_xattr(idmap, i_user_ns(inode), caps, &nscaps,
+					 sizeof(nscaps));
+		if (size < 0)
+			return size;
+		xattr_data = &nscaps;
+	}
+
+	return evm_protect_xattr(idmap, dentry, XATTR_NAME_CAPS, xattr_data, size);
+}
+
+void evm_inode_post_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
+			       const struct vfs_caps *caps, int flags)
+{
+	struct inode *inode = d_inode(dentry);
+	struct vfs_ns_cap_data nscaps;
+	const void *xattr_data = NULL;
+	int size = 0;
+
+	if (!evm_revalidate_status(XATTR_NAME_CAPS))
+		return;
+
+	evm_reset_status(dentry->d_inode);
+
+	if (!(evm_initialized & EVM_INIT_HMAC))
+		return;
+
+	if (is_unsupported_fs(dentry))
+		return;
+
+	if (caps) {
+		size = vfs_caps_to_xattr(idmap, i_user_ns(inode), caps, &nscaps,
+					 sizeof(nscaps));
+		/*
+		 * The fscaps here should have been converted to an xattr by
+		 * evm_inode_set_fscaps() already, so a failure to convert
+		 * here is a bug.
+		 */
+		if (WARN_ON_ONCE(size < 0))
+			return;
+		xattr_data = &nscaps;
+	}
+
+	evm_update_evmxattr(dentry, XATTR_NAME_CAPS, xattr_data, size);
+}
+
 static int evm_attr_change(struct mnt_idmap *idmap,
 			   struct dentry *dentry, struct iattr *attr)
 {

-- 
2.43.0

