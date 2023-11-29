From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 29 Nov 2023 15:50:34 -0600
Subject: [PATCH 16/16] vfs: return -EOPNOTSUPP for fscaps from vfs_*xattr()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231129-idmap-fscap-refactor-v1-16-da5a26058a5b@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1541; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=fGkhj5/NF9UPawvhqYtWeLh70xVuDREL8YeiOyAcAQA=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBlZ7I+wlKgt++JWupSZaBp9QGfdBkmz7IEI8ioxj4s
 f1+aQbyJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZWeyPgAKCRBTA5mu5fQxyTvfB/
 9YWexz1iQXD9/hl9qna/DWzl4zGo/SAzZV9yU+WAg1lMJqq4GFg0sAtqm2p8er4jQP8TEmJ1gfT+Rp
 OwnKnhV4uu4HWyEr7dNuRZPmxzAryHGI1rMeQqZmBuQ6oItUJeIE00YEKRTgMVm18qFcraMmUQVYcD
 o8vPfg2zw4i4XaDyCATxBE4yxIWmTjTHvJxdui3jxNCN1DDq9wMrXGKX2OZsyeCDw9VhgdNL6EYyF2
 xIHyfPKGASENkIpB05s2Aq3zudSepjo7YMWyfxSC3ghhvdqjksN1MMdM8JFf8oAsfPKxEyobr3TadT
 DOjWk90F22+U7CvJPhBxhcP09S5qxG
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
index 372644b15457..4b779779ad8c 100644
--- a/fs/xattr.c
+++ b/fs/xattr.c
@@ -540,6 +540,9 @@ vfs_setxattr(struct mnt_idmap *idmap, struct dentry *dentry,
 	const void  *orig_value = value;
 	int error;
 
+	if (!strcmp(name, XATTR_NAME_CAPS))
+		return -EOPNOTSUPP;
+
 retry_deleg:
 	inode_lock(inode);
 	error = __vfs_setxattr_locked(idmap, dentry, name, value, size,
@@ -655,6 +658,9 @@ vfs_getxattr(struct mnt_idmap *idmap, struct dentry *dentry,
 	struct inode *inode = dentry->d_inode;
 	int error;
 
+	if (!strcmp(name, XATTR_NAME_CAPS))
+		return -EOPNOTSUPP;
+
 	error = xattr_permission(idmap, inode, name, MAY_READ);
 	if (error)
 		return error;
@@ -794,6 +800,9 @@ vfs_removexattr(struct mnt_idmap *idmap, struct dentry *dentry,
 	struct inode *delegated_inode = NULL;
 	int error;
 
+	if (!strcmp(name, XATTR_NAME_CAPS))
+		return -EOPNOTSUPP;
+
 retry_deleg:
 	inode_lock(inode);
 	error = __vfs_removexattr_locked(idmap, dentry,

-- 
2.43.0

