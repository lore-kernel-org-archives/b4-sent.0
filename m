From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:44 -0600
Subject: [PATCH v2 13/25] smack: add hooks for fscaps operations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-13-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3419; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=YiCWnmvB8338QqWiqSd4eJ/jOoBDPxjCWf8ETipJD0I=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1mokwpT6Wd5LYVT0NdW4vUmGJH9U+1d+cLjm5vxy
 ILld6IGJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqJAAKCRBTA5mu5fQxyRbFB/
 99rEgJl1COtBpH35uJRkwXLKAW2bI3ehYcqwDZaWHYMV9allq0ZPBy2JON08GqXpiydvLVO/Ln9mCh
 rrBTyNabTPZ5+6inOHWHzYen+5m4e//T+aD3C35Iu+fYOp1VWDMreKV9CBPDc+o7smjDrcwTT5U3HU
 T+MiwUElmV0hrCl9mx1x6ZQ+OZDxR0wxJWjByWHuSobI8LpfwHLfOtNvETMAFmzDNRcoKxdHlFIdgb
 mLUONM0sKkjjuohgodnMIV64F6StQ4LkZuRqT/sMkNOSOPTPg69udW4Cj0fS+JLVxodaQqo5+IAO07
 HkN+gK7eFDKtfF0Q+djswLOfkjsTiZ
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add hooks for set/get/remove fscaps operations which perform the same
checks as the xattr hooks would have done for XATTR_NAME_CAPS.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 security/smack/smack_lsm.c | 71 ++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 71 insertions(+)

diff --git a/security/smack/smack_lsm.c b/security/smack/smack_lsm.c
index 0fdbf04cc258..1eaa89dede6b 100644
--- a/security/smack/smack_lsm.c
+++ b/security/smack/smack_lsm.c
@@ -1530,6 +1530,74 @@ static int smack_inode_remove_acl(struct mnt_idmap *idmap,
 	return rc;
 }
 
+/**
+ * smack_inode_set_fscaps - Smack check for setting file capabilities
+ * @mnt_userns: the userns attached to the source mnt for this request
+ * @detry: the object
+ * @caps: the file capabilities
+ * @flags: unused
+ *
+ * Returns 0 if the access is permitted, or an error code otherwise.
+ */
+static int smack_inode_set_fscaps(struct mnt_idmap *idmap,
+				  struct dentry *dentry,
+				  const struct vfs_caps *caps, int flags)
+{
+	struct smk_audit_info ad;
+	int rc;
+
+	smk_ad_init(&ad, __func__, LSM_AUDIT_DATA_DENTRY);
+	smk_ad_setfield_u_fs_path_dentry(&ad, dentry);
+	rc = smk_curacc(smk_of_inode(d_backing_inode(dentry)), MAY_WRITE, &ad);
+	rc = smk_bu_inode(d_backing_inode(dentry), MAY_WRITE, rc);
+	return rc;
+}
+
+/**
+ * smack_inode_get_fscaps - Smack check for getting file capabilities
+ * @dentry: the object
+ *
+ * Returns 0 if access is permitted, an error code otherwise
+ */
+static int smack_inode_get_fscaps(struct mnt_idmap *idmap,
+				  struct dentry *dentry)
+{
+	struct smk_audit_info ad;
+	int rc;
+
+	smk_ad_init(&ad, __func__, LSM_AUDIT_DATA_DENTRY);
+	smk_ad_setfield_u_fs_path_dentry(&ad, dentry);
+
+	rc = smk_curacc(smk_of_inode(d_backing_inode(dentry)), MAY_READ, &ad);
+	rc = smk_bu_inode(d_backing_inode(dentry), MAY_READ, rc);
+	return rc;
+}
+
+/**
+ * smack_inode_remove_acl - Smack check for removing file capabilities
+ * @idmap: idmap of the mnt this request came from
+ * @dentry: the object
+ *
+ * Returns 0 if access is permitted, an error code otherwise
+ */
+static int smack_inode_remove_fscaps(struct mnt_idmap *idmap,
+				     struct dentry *dentry)
+{
+	struct smk_audit_info ad;
+	int rc;
+
+	rc = cap_inode_removexattr(idmap, dentry, XATTR_NAME_CAPS);
+	if (rc != 0)
+		return rc;
+
+	smk_ad_init(&ad, __func__, LSM_AUDIT_DATA_DENTRY);
+	smk_ad_setfield_u_fs_path_dentry(&ad, dentry);
+
+	rc = smk_curacc(smk_of_inode(d_backing_inode(dentry)), MAY_WRITE, &ad);
+	rc = smk_bu_inode(d_backing_inode(dentry), MAY_WRITE, rc);
+	return rc;
+}
+
 /**
  * smack_inode_getsecurity - get smack xattrs
  * @idmap: idmap of the mount
@@ -5045,6 +5113,9 @@ static struct security_hook_list smack_hooks[] __ro_after_init = {
 	LSM_HOOK_INIT(inode_set_acl, smack_inode_set_acl),
 	LSM_HOOK_INIT(inode_get_acl, smack_inode_get_acl),
 	LSM_HOOK_INIT(inode_remove_acl, smack_inode_remove_acl),
+	LSM_HOOK_INIT(inode_set_fscaps, smack_inode_set_fscaps),
+	LSM_HOOK_INIT(inode_get_fscaps, smack_inode_get_fscaps),
+	LSM_HOOK_INIT(inode_remove_fscaps, smack_inode_remove_fscaps),
 	LSM_HOOK_INIT(inode_getsecurity, smack_inode_getsecurity),
 	LSM_HOOK_INIT(inode_setsecurity, smack_inode_setsecurity),
 	LSM_HOOK_INIT(inode_listsecurity, smack_inode_listsecurity),

-- 
2.43.0

