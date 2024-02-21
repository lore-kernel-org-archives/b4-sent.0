From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:55 -0600
Subject: [PATCH v2 24/25] commoncap: use vfs fscaps interfaces
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-24-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2792; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=zvbUblF/TCnxaSxVn34c8qD/M35GRlC4hQ2KeRAG42o=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1motMsHmTPRzonCbUf17MUmkAtrgRQQP52t1limF
 xnRCVamJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqLQAKCRBTA5mu5fQxySjhB/
 9/xvaR6j6ROnXfKTxmKnKxnszhmNMXT1oboWqLVttCDoIEShnCN3jNsyIpALo6DQpAxED7nadYlW2F
 vDcaQlOVAqpLDZExtPdSnIAd61AuZiTbo96dmmNv46xSZbKz4YFtYStNCCynSuEuJ6T5hDfXI8ZC7l
 D++5+5X5lQSz00p/UyCKeSsMVATo8TLtwEQ0z6Z+55owxbqadtCXLzeeT9jYnv43ixJny2K5DFwAT/
 ONWSTYt66Dh/JR/D5nJ8mlOrqPvXlnOYpONu68LvMfAd5c3IWAYp3NeQYi6GFXjBbQuE0sXInhC7rb
 xFOguuTz0t3YgEiStWMwzbqX0R1zY8
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the vfs interfaces for fetching file capabilities for killpriv
checks and from get_vfs_caps_from_disk(). While there, update the
kerneldoc for get_vfs_caps_from_disk() to explain how it is different
from vfs_get_fscaps_nosec().

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 security/commoncap.c | 30 +++++++++++++-----------------
 1 file changed, 13 insertions(+), 17 deletions(-)

diff --git a/security/commoncap.c b/security/commoncap.c
index a0ff7e6092e0..751bb26a06a6 100644
--- a/security/commoncap.c
+++ b/security/commoncap.c
@@ -296,11 +296,12 @@ int cap_capset(struct cred *new,
  */
 int cap_inode_need_killpriv(struct dentry *dentry)
 {
-	struct inode *inode = d_backing_inode(dentry);
+	struct vfs_caps caps;
 	int error;
 
-	error = __vfs_getxattr(dentry, inode, XATTR_NAME_CAPS, NULL, 0);
-	return error > 0;
+	/* Use nop_mnt_idmap for no mapping here as mapping is unimportant */
+	error = vfs_get_fscaps_nosec(&nop_mnt_idmap, dentry, &caps);
+	return error == 0;
 }
 
 /**
@@ -323,7 +324,7 @@ int cap_inode_killpriv(struct mnt_idmap *idmap, struct dentry *dentry)
 {
 	int error;
 
-	error = __vfs_removexattr(idmap, dentry, XATTR_NAME_CAPS);
+	error = vfs_remove_fscaps_nosec(idmap, dentry);
 	if (error == -EOPNOTSUPP)
 		error = 0;
 	return error;
@@ -719,6 +720,10 @@ ssize_t vfs_caps_to_user_xattr(struct mnt_idmap *idmap,
  * @cpu_caps:	vfs capabilities
  *
  * Extract the on-exec-apply capability sets for an executable file.
+ * For version 3 capabilities xattrs, returns the capabilities only if
+ * they are applicable to current_user_ns() (i.e. that the rootid
+ * corresponds to an ID which maps to ID 0 in current_user_ns() or an
+ * ancestor), and returns -ENODATA otherwise.
  *
  * If the inode has been found through an idmapped mount the idmap of
  * the vfsmount must be passed through @idmap. This function will then
@@ -731,25 +736,16 @@ int get_vfs_caps_from_disk(struct mnt_idmap *idmap,
 			   struct vfs_caps *cpu_caps)
 {
 	struct inode *inode = d_backing_inode(dentry);
-	int size, ret;
-	struct vfs_ns_cap_data data, *nscaps = &data;
+	int ret;
 
 	if (!inode)
 		return -ENODATA;
 
-	size = __vfs_getxattr((struct dentry *)dentry, inode,
-			      XATTR_NAME_CAPS, &data, XATTR_CAPS_SZ);
-	if (size == -ENODATA || size == -EOPNOTSUPP)
+	ret = vfs_get_fscaps_nosec(idmap, (struct dentry *)dentry, cpu_caps);
+	if (ret == -EOPNOTSUPP || ret == -EOVERFLOW)
 		/* no data, that's ok */
-		return -ENODATA;
+		ret = -ENODATA;
 
-	if (size < 0)
-		return size;
-
-	ret = vfs_caps_from_xattr(idmap, inode->i_sb->s_user_ns,
-				  cpu_caps, nscaps, size);
-	if (ret == -EOVERFLOW)
-		return -ENODATA;
 	if (ret)
 		return ret;
 

-- 
2.43.0

