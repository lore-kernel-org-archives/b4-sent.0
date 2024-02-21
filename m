From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:35 -0600
Subject: [PATCH v2 04/25] capability: rename cpu_vfs_cap_data to vfs_caps
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-4-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3545; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=Y5Y30p4SCfTGfQg8oU5oIf6A+JB4LZOuEG/nIXEuQzs=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1mobLp7u/pdNjeacbXMjbSmEjyV6rMwMwivWNU01
 Kh0BkwWJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqGwAKCRBTA5mu5fQxyY9qB/
 9zUYtdKwx4X8HLo4wnjsbAIGYaWULalOUkaxXnOKjI5Cs4QTHrFSqLwolWhCcuwuJCqxufBU3HxTnc
 mxPuO1+61LNNhi/pCD44c/qRrZUVVTkRAtKBczWgUu6i3XXeeqJLm6XeipSXmdG8cXmXYG8Z187Qbq
 F5NubGadgplNl+QZZZQxAr5Ejyxm7NmVVnTwEBMdlEobRDFUGTFx2dSAaIon/Yk9iw58upAsiDc80O
 IxJbm6qPqST7KMcaLpBxCduVum8Kw1Ljhi2YFVnvMFzw1j5/byvyaLLhuW5jFhzBU4PIXJo3y89Kng
 MOIi8lpcWkKwus9TggxdTwSRIABNLw
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vfs_caps is a more generic name which is better suited to the broader
use this struct will see in subsequent commits.

Reviewed-by: Christian Brauner <brauner@kernel.org>
Acked-by: Paul Moore <paul@paul-moore.com>
Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 include/linux/capability.h | 4 ++--
 kernel/auditsc.c           | 4 ++--
 security/commoncap.c       | 8 ++++----
 3 files changed, 8 insertions(+), 8 deletions(-)

diff --git a/include/linux/capability.h b/include/linux/capability.h
index 0c356a517991..c24477e660fc 100644
--- a/include/linux/capability.h
+++ b/include/linux/capability.h
@@ -24,7 +24,7 @@ extern int file_caps_enabled;
 typedef struct { u64 val; } kernel_cap_t;
 
 /* same as vfs_ns_cap_data but in cpu endian and always filled completely */
-struct cpu_vfs_cap_data {
+struct vfs_caps {
 	__u32 magic_etc;
 	kuid_t rootid;
 	kernel_cap_t permitted;
@@ -211,7 +211,7 @@ static inline bool checkpoint_restore_ns_capable(struct user_namespace *ns)
 /* audit system wants to get cap info from files as well */
 int get_vfs_caps_from_disk(struct mnt_idmap *idmap,
 			   const struct dentry *dentry,
-			   struct cpu_vfs_cap_data *cpu_caps);
+			   struct vfs_caps *cpu_caps);
 
 int cap_convert_nscap(struct mnt_idmap *idmap, struct dentry *dentry,
 		      const void **ivalue, size_t size);
diff --git a/kernel/auditsc.c b/kernel/auditsc.c
index 6f0d6fb6523f..783d0bf69ca5 100644
--- a/kernel/auditsc.c
+++ b/kernel/auditsc.c
@@ -2247,7 +2247,7 @@ void __audit_getname(struct filename *name)
 static inline int audit_copy_fcaps(struct audit_names *name,
 				   const struct dentry *dentry)
 {
-	struct cpu_vfs_cap_data caps;
+	struct vfs_caps caps;
 	int rc;
 
 	if (!dentry)
@@ -2800,7 +2800,7 @@ int __audit_log_bprm_fcaps(struct linux_binprm *bprm,
 {
 	struct audit_aux_data_bprm_fcaps *ax;
 	struct audit_context *context = audit_context();
-	struct cpu_vfs_cap_data vcaps;
+	struct vfs_caps vcaps;
 
 	ax = kmalloc(sizeof(*ax), GFP_KERNEL);
 	if (!ax)
diff --git a/security/commoncap.c b/security/commoncap.c
index 162d96b3a676..7cda247dc7e9 100644
--- a/security/commoncap.c
+++ b/security/commoncap.c
@@ -584,7 +584,7 @@ int cap_convert_nscap(struct mnt_idmap *idmap, struct dentry *dentry,
  * Calculate the new process capability sets from the capability sets attached
  * to a file.
  */
-static inline int bprm_caps_from_vfs_caps(struct cpu_vfs_cap_data *caps,
+static inline int bprm_caps_from_vfs_caps(struct vfs_caps *caps,
 					  struct linux_binprm *bprm,
 					  bool *effective,
 					  bool *has_fcap)
@@ -635,7 +635,7 @@ static inline int bprm_caps_from_vfs_caps(struct cpu_vfs_cap_data *caps,
  */
 int get_vfs_caps_from_disk(struct mnt_idmap *idmap,
 			   const struct dentry *dentry,
-			   struct cpu_vfs_cap_data *cpu_caps)
+			   struct vfs_caps *cpu_caps)
 {
 	struct inode *inode = d_backing_inode(dentry);
 	__u32 magic_etc;
@@ -646,7 +646,7 @@ int get_vfs_caps_from_disk(struct mnt_idmap *idmap,
 	vfsuid_t rootvfsuid;
 	struct user_namespace *fs_ns;
 
-	memset(cpu_caps, 0, sizeof(struct cpu_vfs_cap_data));
+	memset(cpu_caps, 0, sizeof(struct vfs_caps));
 
 	if (!inode)
 		return -ENODATA;
@@ -725,7 +725,7 @@ static int get_file_caps(struct linux_binprm *bprm, const struct file *file,
 			 bool *effective, bool *has_fcap)
 {
 	int rc = 0;
-	struct cpu_vfs_cap_data vcaps;
+	struct vfs_caps vcaps;
 
 	cap_clear(bprm->cred->cap_permitted);
 

-- 
2.43.0

