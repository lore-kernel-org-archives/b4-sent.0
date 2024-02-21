From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:56 -0600
Subject: [PATCH v2 25/25] vfs: return -EOPNOTSUPP for fscaps from
 vfs_*xattr()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-25-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1556; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=JkAYnCkvvJdZGpxH4b0zbmLDehUJl7XVpS/k3t/jU9U=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1mouT6WPJX7a66eMZi03rVY0QujcBq9Oshkq0LfM
 Tuo4JCOJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqLgAKCRBTA5mu5fQxyYCgB/
 945jyUfmMhsxGudorl5vI3QR/Ixu+abEbAKQoQWFIgQCflgI7lEzlE8Gpqk4PF6fP+Z4ZfP0ipIhZW
 Hvcg61i4lw3bmENsZEOVvExwPI4miDqPaQYM5MgS72JjInytlPLdJ5J9YHHPBvYMhUlUJvF4NzVBC1
 9E242ebzj+LwCGygOgJWhED2lY/Hb6uyrRFm1Cz7HpnhwU6iLvmwzI2zV1OW2VbkuTMnKBAYo6R6P4
 c+pauDINbyl1S9IwKjV1/Nmp3njKa6CF4FcIE+hdhnDFMdvpB7KmRK/3vS9yDqlhgFpDIuqkf8wNp7
 kOXGHoNmPjZ5soY0mZi+wE1d1xksOV
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that the new vfs-level interfaces are fully supported and all code
has been converted to use them, stop permitting use of the top-level vfs
xattr interfaces for capabilities xattrs. Unlike with ACLs we still need
to be able to work with fscaps xattrs using lower-level interfaces in a
handful of places, so only use of the top-level xattr interfaces is
restricted.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 fs/xattr.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/fs/xattr.c b/fs/xattr.c
index 30eff6bc4f6d..2b8214c9534f 100644
--- a/fs/xattr.c
+++ b/fs/xattr.c
@@ -534,6 +534,9 @@ vfs_setxattr(struct mnt_idmap *idmap, struct dentry *dentry,
 	const void  *orig_value = value;
 	int error;
 
+	if (WARN_ON_ONCE(is_fscaps_xattr(name)))
+		return -EOPNOTSUPP;
+
 retry_deleg:
 	inode_lock(inode);
 	error = __vfs_setxattr_locked(idmap, dentry, name, value, size,
@@ -649,6 +652,9 @@ vfs_getxattr(struct mnt_idmap *idmap, struct dentry *dentry,
 	struct inode *inode = dentry->d_inode;
 	int error;
 
+	if (WARN_ON_ONCE(is_fscaps_xattr(name)))
+		return -EOPNOTSUPP;
+
 	error = xattr_permission(idmap, inode, name, MAY_READ);
 	if (error)
 		return error;
@@ -788,6 +794,9 @@ vfs_removexattr(struct mnt_idmap *idmap, struct dentry *dentry,
 	struct inode *delegated_inode = NULL;
 	int error;
 
+	if (WARN_ON_ONCE(is_fscaps_xattr(name)))
+		return -EOPNOTSUPP;
+
 retry_deleg:
 	inode_lock(inode);
 	error = __vfs_removexattr_locked(idmap, dentry,

-- 
2.43.0

