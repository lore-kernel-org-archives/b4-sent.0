From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 29 Nov 2023 15:50:33 -0600
Subject: [PATCH 15/16] commoncap: use vfs fscaps interfaces for killpriv
 checks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231129-idmap-fscap-refactor-v1-15-da5a26058a5b@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1080; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=FWlHUtx1il/2WmiearZx3LNeV83xpbRFd1g6e9syKsA=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBlZ7I+qo1rIY3IOTiiUwRAxi2OMNSepIYyq0YWIbCA
 KDVnYlCJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZWeyPgAKCRBTA5mu5fQxyQptCA
 CBRf/0K9qKrdU9ZyL7OUgLfoKpWZ3Y5Xvo2/RWzXlmQ2DXKoq/UH+loOnYsDaqePGfdWVh5uyo58d5
 tr4QxdG4SYWTf0aojF8Nv/Ap+jz0JAT1fkv5J5wNpK8VYaurr5U74/r2olZuglS8yOIpiotQf/sS7m
 FPb8lsc649YKHNU1fc+t9qPO3v3pygCKP9+bJJ2r6HSyaZw6SPYHtvKOlS1chbYH20mqdKLa40NzU3
 WzZnkXBYpChnZM7Wx7072VG8CmqZ/WS7DNSeX8HZx14OF7c4clq4hsIZ16P0bYtxnGjcdxJfekad8I
 TE9Ua9977cqAsf27gse9g5nBZH9JZX
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 security/commoncap.c | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/security/commoncap.c b/security/commoncap.c
index ced7a3c9685f..15344c86c759 100644
--- a/security/commoncap.c
+++ b/security/commoncap.c
@@ -295,11 +295,12 @@ int cap_capset(struct cred *new,
  */
 int cap_inode_need_killpriv(struct dentry *dentry)
 {
-	struct inode *inode = d_backing_inode(dentry);
+	struct vfs_caps caps;
 	int error;
 
-	error = __vfs_getxattr(dentry, inode, XATTR_NAME_CAPS, NULL, 0);
-	return error > 0;
+	/* Use nop_mnt_idmap for no mapping here as mapping is unimportant */
+	error= __vfs_get_fscaps(&nop_mnt_idmap, dentry, &caps);
+	return error == 0;
 }
 
 /**
@@ -322,7 +323,7 @@ int cap_inode_killpriv(struct mnt_idmap *idmap, struct dentry *dentry)
 {
 	int error;
 
-	error = __vfs_removexattr(idmap, dentry, XATTR_NAME_CAPS);
+	error = __vfs_remove_fscaps(idmap, dentry);
 	if (error == -EOPNOTSUPP)
 		error = 0;
 	return error;

-- 
2.43.0

