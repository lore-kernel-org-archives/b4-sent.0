From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:43 -0600
Subject: [PATCH v2 12/25] selinux: add hooks for fscaps operations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-12-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2028; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=pUWNt9mRsWKZJ1yXibvTabhp6NyYRplMYf4ol2PV1qs=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1mojvJhyZw9emud3TEu0eTTg0ZvRpxQbx/wYTlv3
 1foWLWqJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqIwAKCRBTA5mu5fQxyUwiB/
 94Hwww+Nvwr2i0mm92V1m/muLDxNZ3ichSgSbVTXRmFnGLWiqqjMZl3IjV8bIU9kY0uE4x7zfEpBpX
 rTcdD3t9JeMPtm8WcBoFclqIlyRYkgBIkPLFiY2Vb+GmlW/HPp0p7gXrkdXLnqRb2JLOEGjY3ReRrm
 gx2B15blpH1tEHAitlNwTMg6Wlt+MkUqvPIXsiYP4hseEFG3GRmrmtLK8VDfPFmy0HO4MkayGhMzDS
 piT9CYjbYEIlnSpJFWwC7agQMDtzoUNqlU4zRIOSjOTGd+/O8lHnI0mqolxe+jhCS0DXiQ3StnEUTj
 AJXJqyr0z/OYbUCf//HFYSGghhbxur
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add hooks for set/get/remove fscaps operations which perform the same
checks as the xattr hooks would have done for XATTR_NAME_CAPS.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 security/selinux/hooks.c | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/security/selinux/hooks.c b/security/selinux/hooks.c
index a6bf90ace84c..da129a387b34 100644
--- a/security/selinux/hooks.c
+++ b/security/selinux/hooks.c
@@ -3367,6 +3367,29 @@ static int selinux_inode_removexattr(struct mnt_idmap *idmap,
 	return -EACCES;
 }
 
+static int selinux_inode_set_fscaps(struct mnt_idmap *idmap,
+				    struct dentry *dentry,
+				    const struct vfs_caps *caps, int flags)
+{
+	return dentry_has_perm(current_cred(), dentry, FILE__SETATTR);
+}
+
+static int selinux_inode_get_fscaps(struct mnt_idmap *idmap,
+				    struct dentry *dentry)
+{
+	return dentry_has_perm(current_cred(), dentry, FILE__GETATTR);
+}
+
+static int selinux_inode_remove_fscaps(struct mnt_idmap *idmap,
+				       struct dentry *dentry)
+{
+	int rc = cap_inode_removexattr(idmap, dentry, XATTR_NAME_CAPS);
+	if (rc)
+		return rc;
+
+	return dentry_has_perm(current_cred(), dentry, FILE__SETATTR);
+}
+
 static int selinux_path_notify(const struct path *path, u64 mask,
 						unsigned int obj_type)
 {
@@ -7165,6 +7188,9 @@ static struct security_hook_list selinux_hooks[] __ro_after_init = {
 	LSM_HOOK_INIT(inode_set_acl, selinux_inode_set_acl),
 	LSM_HOOK_INIT(inode_get_acl, selinux_inode_get_acl),
 	LSM_HOOK_INIT(inode_remove_acl, selinux_inode_remove_acl),
+	LSM_HOOK_INIT(inode_set_fscaps, selinux_inode_set_fscaps),
+	LSM_HOOK_INIT(inode_get_fscaps, selinux_inode_get_fscaps),
+	LSM_HOOK_INIT(inode_remove_fscaps, selinux_inode_remove_fscaps),
 	LSM_HOOK_INIT(inode_getsecurity, selinux_inode_getsecurity),
 	LSM_HOOK_INIT(inode_setsecurity, selinux_inode_setsecurity),
 	LSM_HOOK_INIT(inode_listsecurity, selinux_inode_listsecurity),

-- 
2.43.0

