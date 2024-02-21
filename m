From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:54 -0600
Subject: [PATCH v2 23/25] commoncap: remove cap_inode_getsecurity()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-23-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6353; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=1TYsrROC+3Gbnk0WZAJOXwUVYboiTmQbZsKMb1rgvU8=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1motCgsTy90LeHpbc+1t508RRXtO5Tr7ynwS2xU5
 yQgyIXmJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqLQAKCRBTA5mu5fQxyQ9cB/
 9MkVi0GeoZBdDB2ESik5DH2lKt0/HCAcGaHhI2z5p4iKB9cR3qimVKy6AeRQZfs0uvL4bMpX25vrN3
 vkSxeQd54+0Yi2B2vbiVY4RcQdgOgGdROsu4Gb1qFojTTV1755axxStzIFUMmgnl5YeRHN+23qBTLL
 IxEOnqlduM5TIE0uA6dNQ0PUxLJ0qJCQr37gIq2p+3sAtcmseSnVzD+t6LOujXssQqvrMEqilevLgY
 HJYwxlHlhQFsf4GXMGNvncW/+2qM8tkzBoNYP3lDU//O6orY9JA3BXJ5MYrARhiuq4ID02RQF65O6C
 Yae6GRpnBH1D3evacGuX1iUEaVptSk
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reading of fscaps xattrs is now done via vfs_get_fscaps(), so there is
no longer any need to do it from security_inode_getsecurity(). Remove
cap_inode_getsecurity() and its associated helpers which are now unused.

We don't allow reading capabilities xattrs this way anyomre, so remove
the handler and associated helpers.

Acked-by: Paul Moore <paul@paul-moore.com>
Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 include/linux/security.h |   5 +-
 security/commoncap.c     | 132 -----------------------------------------------
 2 files changed, 1 insertion(+), 136 deletions(-)

diff --git a/include/linux/security.h b/include/linux/security.h
index 40be548e5e12..599d665eac71 100644
--- a/include/linux/security.h
+++ b/include/linux/security.h
@@ -162,9 +162,6 @@ int cap_inode_removexattr(struct mnt_idmap *idmap,
 			  struct dentry *dentry, const char *name);
 int cap_inode_need_killpriv(struct dentry *dentry);
 int cap_inode_killpriv(struct mnt_idmap *idmap, struct dentry *dentry);
-int cap_inode_getsecurity(struct mnt_idmap *idmap,
-			  struct inode *inode, const char *name, void **buffer,
-			  bool alloc);
 extern int cap_mmap_addr(unsigned long addr);
 extern int cap_mmap_file(struct file *file, unsigned long reqprot,
 			 unsigned long prot, unsigned long flags);
@@ -984,7 +981,7 @@ static inline int security_inode_getsecurity(struct mnt_idmap *idmap,
 					     const char *name, void **buffer,
 					     bool alloc)
 {
-	return cap_inode_getsecurity(idmap, inode, name, buffer, alloc);
+	return -EOPNOTSUPP;
 }
 
 static inline int security_inode_setsecurity(struct inode *inode, const char *name, const void *value, size_t size, int flags)
diff --git a/security/commoncap.c b/security/commoncap.c
index 4254e5e46024..a0ff7e6092e0 100644
--- a/security/commoncap.c
+++ b/security/commoncap.c
@@ -353,137 +353,6 @@ static __u32 sansflags(__u32 m)
 	return m & ~VFS_CAP_FLAGS_EFFECTIVE;
 }
 
-static bool is_v2header(int size, const struct vfs_cap_data *cap)
-{
-	if (size != XATTR_CAPS_SZ_2)
-		return false;
-	return sansflags(le32_to_cpu(cap->magic_etc)) == VFS_CAP_REVISION_2;
-}
-
-static bool is_v3header(int size, const struct vfs_cap_data *cap)
-{
-	if (size != XATTR_CAPS_SZ_3)
-		return false;
-	return sansflags(le32_to_cpu(cap->magic_etc)) == VFS_CAP_REVISION_3;
-}
-
-/*
- * getsecurity: We are called for security.* before any attempt to read the
- * xattr from the inode itself.
- *
- * This gives us a chance to read the on-disk value and convert it.  If we
- * return -EOPNOTSUPP, then vfs_getxattr() will call the i_op handler.
- *
- * Note we are not called by vfs_getxattr_alloc(), but that is only called
- * by the integrity subsystem, which really wants the unconverted values -
- * so that's good.
- */
-int cap_inode_getsecurity(struct mnt_idmap *idmap,
-			  struct inode *inode, const char *name, void **buffer,
-			  bool alloc)
-{
-	int size;
-	kuid_t kroot;
-	vfsuid_t vfsroot;
-	u32 nsmagic, magic;
-	uid_t root, mappedroot;
-	char *tmpbuf = NULL;
-	struct vfs_cap_data *cap;
-	struct vfs_ns_cap_data *nscap = NULL;
-	struct dentry *dentry;
-	struct user_namespace *fs_ns;
-
-	if (strcmp(name, "capability") != 0)
-		return -EOPNOTSUPP;
-
-	dentry = d_find_any_alias(inode);
-	if (!dentry)
-		return -EINVAL;
-	size = vfs_getxattr_alloc(idmap, dentry, XATTR_NAME_CAPS, &tmpbuf,
-				  sizeof(struct vfs_ns_cap_data), GFP_NOFS);
-	dput(dentry);
-	/* gcc11 complains if we don't check for !tmpbuf */
-	if (size < 0 || !tmpbuf)
-		goto out_free;
-
-	fs_ns = inode->i_sb->s_user_ns;
-	cap = (struct vfs_cap_data *) tmpbuf;
-	if (is_v2header(size, cap)) {
-		root = 0;
-	} else if (is_v3header(size, cap)) {
-		nscap = (struct vfs_ns_cap_data *) tmpbuf;
-		root = le32_to_cpu(nscap->rootid);
-	} else {
-		size = -EINVAL;
-		goto out_free;
-	}
-
-	kroot = make_kuid(fs_ns, root);
-
-	/* If this is an idmapped mount shift the kuid. */
-	vfsroot = make_vfsuid(idmap, fs_ns, kroot);
-
-	/* If the root kuid maps to a valid uid in current ns, then return
-	 * this as a nscap. */
-	mappedroot = from_kuid(current_user_ns(), vfsuid_into_kuid(vfsroot));
-	if (mappedroot != (uid_t)-1 && mappedroot != (uid_t)0) {
-		size = sizeof(struct vfs_ns_cap_data);
-		if (alloc) {
-			if (!nscap) {
-				/* v2 -> v3 conversion */
-				nscap = kzalloc(size, GFP_ATOMIC);
-				if (!nscap) {
-					size = -ENOMEM;
-					goto out_free;
-				}
-				nsmagic = VFS_CAP_REVISION_3;
-				magic = le32_to_cpu(cap->magic_etc);
-				if (magic & VFS_CAP_FLAGS_EFFECTIVE)
-					nsmagic |= VFS_CAP_FLAGS_EFFECTIVE;
-				memcpy(&nscap->data, &cap->data, sizeof(__le32) * 2 * VFS_CAP_U32);
-				nscap->magic_etc = cpu_to_le32(nsmagic);
-			} else {
-				/* use allocated v3 buffer */
-				tmpbuf = NULL;
-			}
-			nscap->rootid = cpu_to_le32(mappedroot);
-			*buffer = nscap;
-		}
-		goto out_free;
-	}
-
-	if (!rootid_owns_currentns(vfsroot)) {
-		size = -EOVERFLOW;
-		goto out_free;
-	}
-
-	/* This comes from a parent namespace.  Return as a v2 capability */
-	size = sizeof(struct vfs_cap_data);
-	if (alloc) {
-		if (nscap) {
-			/* v3 -> v2 conversion */
-			cap = kzalloc(size, GFP_ATOMIC);
-			if (!cap) {
-				size = -ENOMEM;
-				goto out_free;
-			}
-			magic = VFS_CAP_REVISION_2;
-			nsmagic = le32_to_cpu(nscap->magic_etc);
-			if (nsmagic & VFS_CAP_FLAGS_EFFECTIVE)
-				magic |= VFS_CAP_FLAGS_EFFECTIVE;
-			memcpy(&cap->data, &nscap->data, sizeof(__le32) * 2 * VFS_CAP_U32);
-			cap->magic_etc = cpu_to_le32(magic);
-		} else {
-			/* use unconverted v2 */
-			tmpbuf = NULL;
-		}
-		*buffer = cap;
-	}
-out_free:
-	kfree(tmpbuf);
-	return size;
-}
-
 /**
  * rootid_from_vfs_caps - translate root uid of vfs caps
  *
@@ -1633,7 +1502,6 @@ static struct security_hook_list capability_hooks[] __ro_after_init = {
 	LSM_HOOK_INIT(bprm_creds_from_file, cap_bprm_creds_from_file),
 	LSM_HOOK_INIT(inode_need_killpriv, cap_inode_need_killpriv),
 	LSM_HOOK_INIT(inode_killpriv, cap_inode_killpriv),
-	LSM_HOOK_INIT(inode_getsecurity, cap_inode_getsecurity),
 	LSM_HOOK_INIT(mmap_addr, cap_mmap_addr),
 	LSM_HOOK_INIT(mmap_file, cap_mmap_file),
 	LSM_HOOK_INIT(task_fix_setuid, cap_task_fix_setuid),

-- 
2.43.0

