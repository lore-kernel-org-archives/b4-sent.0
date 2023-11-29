From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 29 Nov 2023 15:50:19 -0600
Subject: [PATCH 01/16] mnt_idmapping: split out core vfs[ug]id_t
 definitions into vfsid.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231129-idmap-fscap-refactor-v1-1-da5a26058a5b@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=5492; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=8hyIqObGCNM7OndECY6ik1cyygtFav0NlxWDW3pdIrY=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBlZ7IypVCG7IPii3Bv/9IWC//wjbIJFZxmwWtk15il
 2eLSfdSJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZWeyMgAKCRBTA5mu5fQxyeIuB/
 98tcQpOL+ArlkKRsUG2863oU+nR4ASsCNyB0teYwg1zHPGKgvQpVQ6sTEKVATR8UU8BHodZ/NrW+9z
 SCWPGhpCWCOuLMyLQKoaVjacW1v7mfAHytfLH7W7PA8Uv2l+4YauHotUx6ViIJMiurXpu3am9mMctL
 xwiDiJc7e88bSAWeqRim6qWEUQV6Qft733XXUOwHo7XQGF6nw2owmvyUnQpPrruZCWfrnL4cLSouL+
 aZm0cLpA6I4BzvGdPncMfkqSFtylQN+mgbWnX5UZEgzr4akhSvywqhfUiicwxB1ZNz38qY07ce0fmk
 pXiqKWJ91c4rFBldMqTgeDb6+B4Jfe
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rootid member of cpu_vfs_cap_data is a kuid_t, but it should be a
vfsuid_t as the id stored there is mapped into the mount idmapping. It's
currently impossible to use vfsuid_t within cred.h though as it is
defined in mnt_idmapping.h, which uses definitions from cred.h.

Split out the core vfsid type definitions into a separate file which can
be included from cred.h.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 MAINTAINERS                   |  1 +
 include/linux/mnt_idmapping.h | 66 +-------------------------------------
 include/linux/vfsid.h         | 74 +++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 76 insertions(+), 65 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 012df8ccf34e..8c73081d3dcc 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -10260,6 +10260,7 @@ S:	Maintained
 T:	git git://git.kernel.org/pub/scm/linux/kernel/git/vfs/idmapping.git
 F:	Documentation/filesystems/idmappings.rst
 F:	include/linux/mnt_idmapping.*
+F:	include/linux/vfsid.h
 F:	tools/testing/selftests/mount_setattr/
 
 IDT VersaClock 5 CLOCK DRIVER
diff --git a/include/linux/mnt_idmapping.h b/include/linux/mnt_idmapping.h
index b8da2db4ecd2..8b5e00ee6472 100644
--- a/include/linux/mnt_idmapping.h
+++ b/include/linux/mnt_idmapping.h
@@ -4,6 +4,7 @@
 
 #include <linux/types.h>
 #include <linux/uidgid.h>
+#include <linux/vfsid.h>
 
 struct mnt_idmap;
 struct user_namespace;
@@ -11,61 +12,6 @@ struct user_namespace;
 extern struct mnt_idmap nop_mnt_idmap;
 extern struct user_namespace init_user_ns;
 
-typedef struct {
-	uid_t val;
-} vfsuid_t;
-
-typedef struct {
-	gid_t val;
-} vfsgid_t;
-
-static_assert(sizeof(vfsuid_t) == sizeof(kuid_t));
-static_assert(sizeof(vfsgid_t) == sizeof(kgid_t));
-static_assert(offsetof(vfsuid_t, val) == offsetof(kuid_t, val));
-static_assert(offsetof(vfsgid_t, val) == offsetof(kgid_t, val));
-
-#ifdef CONFIG_MULTIUSER
-static inline uid_t __vfsuid_val(vfsuid_t uid)
-{
-	return uid.val;
-}
-
-static inline gid_t __vfsgid_val(vfsgid_t gid)
-{
-	return gid.val;
-}
-#else
-static inline uid_t __vfsuid_val(vfsuid_t uid)
-{
-	return 0;
-}
-
-static inline gid_t __vfsgid_val(vfsgid_t gid)
-{
-	return 0;
-}
-#endif
-
-static inline bool vfsuid_valid(vfsuid_t uid)
-{
-	return __vfsuid_val(uid) != (uid_t)-1;
-}
-
-static inline bool vfsgid_valid(vfsgid_t gid)
-{
-	return __vfsgid_val(gid) != (gid_t)-1;
-}
-
-static inline bool vfsuid_eq(vfsuid_t left, vfsuid_t right)
-{
-	return vfsuid_valid(left) && __vfsuid_val(left) == __vfsuid_val(right);
-}
-
-static inline bool vfsgid_eq(vfsgid_t left, vfsgid_t right)
-{
-	return vfsgid_valid(left) && __vfsgid_val(left) == __vfsgid_val(right);
-}
-
 /**
  * vfsuid_eq_kuid - check whether kuid and vfsuid have the same value
  * @vfsuid: the vfsuid to compare
@@ -96,16 +42,6 @@ static inline bool vfsgid_eq_kgid(vfsgid_t vfsgid, kgid_t kgid)
 	return vfsgid_valid(vfsgid) && __vfsgid_val(vfsgid) == __kgid_val(kgid);
 }
 
-/*
- * vfs{g,u}ids are created from k{g,u}ids.
- * We don't allow them to be created from regular {u,g}id.
- */
-#define VFSUIDT_INIT(val) (vfsuid_t){ __kuid_val(val) }
-#define VFSGIDT_INIT(val) (vfsgid_t){ __kgid_val(val) }
-
-#define INVALID_VFSUID VFSUIDT_INIT(INVALID_UID)
-#define INVALID_VFSGID VFSGIDT_INIT(INVALID_GID)
-
 /*
  * Allow a vfs{g,u}id to be used as a k{g,u}id where we want to compare
  * whether the mapped value is identical to value of a k{g,u}id.
diff --git a/include/linux/vfsid.h b/include/linux/vfsid.h
new file mode 100644
index 000000000000..90262944b042
--- /dev/null
+++ b/include/linux/vfsid.h
@@ -0,0 +1,74 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef _LINUX_MNT_VFSID_H
+#define _LINUX_MNT_VFSID_H
+
+#include <linux/types.h>
+#include <linux/uidgid.h>
+#include <linux/build_bug.h>
+
+typedef struct {
+	uid_t val;
+} vfsuid_t;
+
+typedef struct {
+	gid_t val;
+} vfsgid_t;
+
+static_assert(sizeof(vfsuid_t) == sizeof(kuid_t));
+static_assert(sizeof(vfsgid_t) == sizeof(kgid_t));
+static_assert(offsetof(vfsuid_t, val) == offsetof(kuid_t, val));
+static_assert(offsetof(vfsgid_t, val) == offsetof(kgid_t, val));
+
+#ifdef CONFIG_MULTIUSER
+static inline uid_t __vfsuid_val(vfsuid_t uid)
+{
+	return uid.val;
+}
+
+static inline gid_t __vfsgid_val(vfsgid_t gid)
+{
+	return gid.val;
+}
+#else
+static inline uid_t __vfsuid_val(vfsuid_t uid)
+{
+	return 0;
+}
+
+static inline gid_t __vfsgid_val(vfsgid_t gid)
+{
+	return 0;
+}
+#endif
+
+static inline bool vfsuid_valid(vfsuid_t uid)
+{
+	return __vfsuid_val(uid) != (uid_t)-1;
+}
+
+static inline bool vfsgid_valid(vfsgid_t gid)
+{
+	return __vfsgid_val(gid) != (gid_t)-1;
+}
+
+static inline bool vfsuid_eq(vfsuid_t left, vfsuid_t right)
+{
+	return vfsuid_valid(left) && __vfsuid_val(left) == __vfsuid_val(right);
+}
+
+static inline bool vfsgid_eq(vfsgid_t left, vfsgid_t right)
+{
+	return vfsgid_valid(left) && __vfsgid_val(left) == __vfsgid_val(right);
+}
+
+/*
+ * vfs{g,u}ids are created from k{g,u}ids.
+ * We don't allow them to be created from regular {u,g}id.
+ */
+#define VFSUIDT_INIT(val) (vfsuid_t){ __kuid_val(val) }
+#define VFSGIDT_INIT(val) (vfsgid_t){ __kgid_val(val) }
+
+#define INVALID_VFSUID VFSUIDT_INIT(INVALID_UID)
+#define INVALID_VFSGID VFSGIDT_INIT(INVALID_GID)
+
+#endif /* _LINUX_MNT_VFSID_H */

-- 
2.43.0

