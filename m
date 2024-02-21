From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:46 -0600
Subject: [PATCH v2 15/25] security: call evm fscaps hooks from generic
 security hooks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-15-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1658; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=CJx4jVGIRqQ1qdmTj2y9zLMKH38BdGpPQGSp5yBCQqY=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1molI6sVtDD31t+ZdHf1WoPke0imykwNoYOzlcEa
 MLxxYsqJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqJQAKCRBTA5mu5fQxyUmKB/
 sG1SON2b9GiN9agwuQ8lNxw2IHmhmbxgz33hhQ2tViUIItDAJSIkNy5i0HyqiJgPzP/w1VR+NSBYZ3
 rze6gn/V7wNsI6T4BHcLgXfr/PP7enV45rcBxOGWDoeBgrvhVY2RIIRwv0+5nKw+ZUUoxMJyIXsguH
 AQe19vJzujrIFbKdZ5VySsugJ5uN9keqsl3z8Qth5BpJ4cml1+ab/U3rPxAwFa/t2OH6DxBKRvYF0c
 GVb+YvhlZ+LDNcy1vbiuUqcuEeEatxNwdefLfn1dBPKNGW6/nY86XhjMB66KBqJqPp/VEC20A/hPcB
 ne6Sf/61X39xbpD+uZnRFwaVm9Ag8L
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 security/security.c | 15 +++++++++++++--
 1 file changed, 13 insertions(+), 2 deletions(-)

diff --git a/security/security.c b/security/security.c
index 0d210da9862c..f515d8430318 100644
--- a/security/security.c
+++ b/security/security.c
@@ -2365,9 +2365,14 @@ int security_inode_remove_acl(struct mnt_idmap *idmap,
 int security_inode_set_fscaps(struct mnt_idmap *idmap, struct dentry *dentry,
 			      const struct vfs_caps *caps, int flags)
 {
+	int ret;
+
 	if (unlikely(IS_PRIVATE(d_backing_inode(dentry))))
 		return 0;
-	return call_int_hook(inode_set_fscaps, 0, idmap, dentry, caps, flags);
+	ret = call_int_hook(inode_set_fscaps, 0, idmap, dentry, caps, flags);
+	if (ret)
+		return ret;
+	return evm_inode_set_fscaps(idmap, dentry, caps, flags);
 }
 
 /**
@@ -2387,6 +2392,7 @@ void security_inode_post_set_fscaps(struct mnt_idmap *idmap,
 	if (unlikely(IS_PRIVATE(d_backing_inode(dentry))))
 		return;
 	call_void_hook(inode_post_set_fscaps, idmap, dentry, caps, flags);
+	evm_inode_post_set_fscaps(idmap, dentry, caps, flags);
 }
 
 /**
@@ -2415,9 +2421,14 @@ int security_inode_get_fscaps(struct mnt_idmap *idmap, struct dentry *dentry)
  */
 int security_inode_remove_fscaps(struct mnt_idmap *idmap, struct dentry *dentry)
 {
+	int ret;
+
 	if (unlikely(IS_PRIVATE(d_backing_inode(dentry))))
 		return 0;
-	return call_int_hook(inode_remove_fscaps, 0, idmap, dentry);
+	ret = call_int_hook(inode_remove_fscaps, 0, idmap, dentry);
+	if (ret)
+		return ret;
+	return evm_inode_remove_fscaps(dentry);
 }
 
 /**

-- 
2.43.0

