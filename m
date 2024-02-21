From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:36 -0600
Subject: [PATCH v2 05/25] capability: use vfsuid_t for vfs_caps rootids
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-5-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2813; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=YMHnxXBEI/P1sDB6/aXu4KjyTt4t2HZBNesMC/3zNhs=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1moc9PlzOKO/Kyx+lBa/M3xomZ3GPJVZxjtiE7L2
 DuW0zcKJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqHAAKCRBTA5mu5fQxyWfCB/
 43YTrTvfhVuOT0q1B/D6FhejPBxQNkO/BnYQ3ZrnKJbTbp44bZUF5mGs5jcP2xDdmAjW4CEnAhSy9M
 pSzcb+7UKv6auwA0B0Y6Bd0Rabx/8z/3pnoUYWlLrgXWJluVZbFhrZmEhI0nSpdP/a3wwqdkBRl7xn
 ATu5t0uCHGnbdr9CRQvE2DGGQiB0rHgAD6mxoWAPQpW+fKMiBNbPOwu7YKPvaynD5JTZ6EvlTiSlrf
 whTtvzTnkpe2dGqZVxeEsNQ35AkJQgMEAYwSro7u4f2w9R/b5hO7M8WOg8/KkOoZBzahTBqYE+QJg2
 KzNOWFT6FYRXRuHJ01Uf7V739eWk+C
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rootid is a kuid_t, but it contains an id which maped into a mount
idmapping, so it is really a vfsuid. This is confusing and creates
potential for misuse of the value, so change it to vfsuid_t.

Acked-by: Paul Moore <paul@paul-moore.com>
Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 include/linux/capability.h | 3 ++-
 kernel/auditsc.c           | 5 +++--
 security/commoncap.c       | 2 +-
 3 files changed, 6 insertions(+), 4 deletions(-)

diff --git a/include/linux/capability.h b/include/linux/capability.h
index c24477e660fc..eb46d346bbbc 100644
--- a/include/linux/capability.h
+++ b/include/linux/capability.h
@@ -16,6 +16,7 @@
 #include <uapi/linux/capability.h>
 #include <linux/uidgid.h>
 #include <linux/bits.h>
+#include <linux/vfsid.h>
 
 #define _KERNEL_CAPABILITY_VERSION _LINUX_CAPABILITY_VERSION_3
 
@@ -26,7 +27,7 @@ typedef struct { u64 val; } kernel_cap_t;
 /* same as vfs_ns_cap_data but in cpu endian and always filled completely */
 struct vfs_caps {
 	__u32 magic_etc;
-	kuid_t rootid;
+	vfsuid_t rootid;
 	kernel_cap_t permitted;
 	kernel_cap_t inheritable;
 };
diff --git a/kernel/auditsc.c b/kernel/auditsc.c
index 783d0bf69ca5..65691450b080 100644
--- a/kernel/auditsc.c
+++ b/kernel/auditsc.c
@@ -65,6 +65,7 @@
 #include <uapi/linux/netfilter/nf_tables.h>
 #include <uapi/linux/openat2.h> // struct open_how
 #include <uapi/linux/fanotify.h>
+#include <linux/mnt_idmapping.h>
 
 #include "audit.h"
 
@@ -2260,7 +2261,7 @@ static inline int audit_copy_fcaps(struct audit_names *name,
 	name->fcap.permitted = caps.permitted;
 	name->fcap.inheritable = caps.inheritable;
 	name->fcap.fE = !!(caps.magic_etc & VFS_CAP_FLAGS_EFFECTIVE);
-	name->fcap.rootid = caps.rootid;
+	name->fcap.rootid = AS_KUIDT(caps.rootid);
 	name->fcap_ver = (caps.magic_etc & VFS_CAP_REVISION_MASK) >>
 				VFS_CAP_REVISION_SHIFT;
 
@@ -2816,7 +2817,7 @@ int __audit_log_bprm_fcaps(struct linux_binprm *bprm,
 	ax->fcap.permitted = vcaps.permitted;
 	ax->fcap.inheritable = vcaps.inheritable;
 	ax->fcap.fE = !!(vcaps.magic_etc & VFS_CAP_FLAGS_EFFECTIVE);
-	ax->fcap.rootid = vcaps.rootid;
+	ax->fcap.rootid = AS_KUIDT(vcaps.rootid);
 	ax->fcap_ver = (vcaps.magic_etc & VFS_CAP_REVISION_MASK) >> VFS_CAP_REVISION_SHIFT;
 
 	ax->old_pcap.permitted   = old->cap_permitted;
diff --git a/security/commoncap.c b/security/commoncap.c
index 7cda247dc7e9..a0b5c9740759 100644
--- a/security/commoncap.c
+++ b/security/commoncap.c
@@ -711,7 +711,7 @@ int get_vfs_caps_from_disk(struct mnt_idmap *idmap,
 	cpu_caps->permitted.val &= CAP_VALID_MASK;
 	cpu_caps->inheritable.val &= CAP_VALID_MASK;
 
-	cpu_caps->rootid = vfsuid_into_kuid(rootvfsuid);
+	cpu_caps->rootid = rootvfsuid;
 
 	return 0;
 }

-- 
2.43.0

