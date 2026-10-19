From: Manuel Huber <manuelh@nvidia.com>
Date: Mon, 19 Oct 2026 21:40:25 +0000
Subject: [PATCH RFC 1/4] ipe: add the .ipe policy keyring
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-b4-ipe-keyring-rfc-v1-1-156f0b93e843@nvidia.com>
References: <20261019-b4-ipe-keyring-rfc-v1-0-156f0b93e843@nvidia.com>
In-Reply-To: <20261019-b4-ipe-keyring-rfc-v1-0-156f0b93e843@nvidia.com>
To: Fan Wu <wufan@kernel.org>, David Howells <dhowells@redhat.com>, 
 Jarkko Sakkinen <jarkko@kernel.org>
Cc: Christian Brauner <brauner@kernel.org>, 
 Andrew Halaney <andrew@amutable.com>, Paul Moore <paul@paul-moore.com>, 
 James Morris <jmorris@namei.org>, "Serge E. Hallyn" <serge@hallyn.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Shuah Khan <shuah@kernel.org>, Randy Dunlap <rdunlap@infradead.org>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 linux-security-module@vger.kernel.org, keyrings@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-doc@vger.kernel.org, 
 bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Manuel Huber <manuelh@nvidia.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792446042; l=7425;
 i=manuelh@nvidia.com; s=20261019; h=from:subject:message-id;
 bh=pzmdNrjH0K9jBZOsygXh8Yb7f2fOt7gvUDgHY5ObJnM=;
 b=224d2yttNRkgR9OFGtyo3Av3E6VfoYQzjQs75w2w9gzlveaL4NqBDAD/bPpkGmLk8nKssW5tw
 bnMFsrT4dQqDt7AuC0tNnj5u5wi9HMLbltX0uZGNIerHOwUPuFqmWxJ
X-Developer-Key: i=manuelh@nvidia.com; a=ed25519;
 pk=uKggxpZ/mM0qtFnudxvh5Dfz8I6VoehwoM3eYCe3tyU=
X-Endpoint-Received: by B4 Relay for manuelh@nvidia.com/20261019 with auth_id=1244
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a dedicated .ipe keyring for IPE policy signature verification,
modeled after the .dm-verity and .bpf keyring implementations.

With this, userspace can provision its own keys into the keyring,
then restrict it and activate it for IPE policy signature verification.

This enables scenarios in which a trusted userspace component generates
an IPE policy, and creates an ephemeral policy-signing key pair,
provisions its public certificate, and restricts the IPE keyring during
the early lifetime of a system. The trusted component can then sign the
IPE policy, destroy the private key, and load and activate the policy.
During that phase, the system is considered in a trusted state whereas
the system transitions into a possibly untrusted state afterwards,
running arbitrary user-provided applications. In such a scenario, the
trusted userspace component could reside on a dm-verity protected
rootfs disk, and applications would reside on additional dm-verity
protected disks. The latter disks would be dynamically attached and
their dm-verity root hashes and/or signatures not known a priori to
launching the system.

A concrete usage scenario could be Kata Containers, which enables
running Kubernetes pods in ephemeral, headless utility VMs, possibly
without systemd. The rootfs disk is static and known beforehand, but
containerd's image layers might be acquired and transported into the
VM using the erofs snapshotter and dynamic block device attachment
using dm-verity.

Signed-off-by: Manuel Huber <manuelh@nvidia.com>
---
 Documentation/admin-guide/kernel-parameters.txt |  9 +++
 security/ipe/Makefile                           |  1 +
 security/ipe/ipe.c                              |  2 +
 security/ipe/keyring.c                          | 79 +++++++++++++++++++++++++
 security/ipe/keyring.h                          | 16 +++++
 security/ipe/policy.c                           | 10 ++++
 6 files changed, 117 insertions(+)

diff --git a/Documentation/admin-guide/kernel-parameters.txt b/Documentation/admin-guide/kernel-parameters.txt
index e75344f4e0cd..fd508dd779ed 100644
--- a/Documentation/admin-guide/kernel-parameters.txt
+++ b/Documentation/admin-guide/kernel-parameters.txt
@@ -2733,6 +2733,15 @@ Kernel parameters
 			Determine whether IPE starts in permissive (0) or
 			enforce (1) mode. The default is enforce.
 
+	ipe.keyring_unsealed=
+			[IPE]
+			Format: <bool>
+			When set to 1, leave the IPE policy keyring
+			unsealed after initialization so userspace can provision
+			keys. Once the keyring is nonempty and restricted, it is
+			searched during policy-signature verification. The default
+			is 0, which creates the keyring restricted and empty.
+
 	ipe.success_audit=
 			[IPE]
 			Format: <bool>
diff --git a/security/ipe/Makefile b/security/ipe/Makefile
index 2ffabfa63fe9..109e736696a5 100644
--- a/security/ipe/Makefile
+++ b/security/ipe/Makefile
@@ -20,6 +20,7 @@ obj-$(CONFIG_SECURITY_IPE) += \
 	hooks.o \
 	fs.o \
 	ipe.o \
+	keyring.o \
 	policy.o \
 	policy_fs.o \
 	policy_parser.o \
diff --git a/security/ipe/ipe.c b/security/ipe/ipe.c
index 495bb765de1b..f5232f850dc2 100644
--- a/security/ipe/ipe.c
+++ b/security/ipe/ipe.c
@@ -7,6 +7,7 @@
 #include "ipe.h"
 #include "eval.h"
 #include "hooks.h"
+#include "keyring.h"
 
 extern const char *const ipe_boot_policy;
 bool ipe_enabled;
@@ -97,4 +98,5 @@ DEFINE_LSM(ipe) = {
 	.init = ipe_init,
 	.blobs = &ipe_blobs,
 	.initcall_fs = ipe_init_securityfs,
+	.initcall_late = ipe_keyring_init,
 };
diff --git a/security/ipe/keyring.c b/security/ipe/keyring.c
new file mode 100644
index 000000000000..ea8d164b62a6
--- /dev/null
+++ b/security/ipe/keyring.c
@@ -0,0 +1,79 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (C) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
+ */
+
+#include <linux/cred.h>
+#include <linux/err.h>
+#include <linux/key.h>
+#include <linux/moduleparam.h>
+
+#include "ipe.h"
+#include "keyring.h"
+
+static struct key *ipe_keyring __ro_after_init;
+
+static bool ipe_keyring_unsealed __ro_after_init;
+
+/* Set the right module name for built-in parameters. */
+#ifdef KBUILD_MODNAME
+#undef KBUILD_MODNAME
+#define KBUILD_MODNAME "ipe"
+#endif
+
+module_param_named(keyring_unsealed, ipe_keyring_unsealed, bool, 0444);
+MODULE_PARM_DESC(keyring_unsealed, "Leave the IPE keyring unsealed");
+
+/**
+ * ipe_keyring_lookup() - Get the IPE keyring if it is ready for use.
+ *
+ * Return: A borrowed pointer to the IPE keyring if it is nonempty and
+ * restricted, or %NULL otherwise. The keyring has system lifetime.
+ */
+struct key *ipe_keyring_lookup(void)
+{
+	if (!ipe_keyring)
+		return NULL;
+
+	if (!READ_ONCE(ipe_keyring->keys.nr_leaves_on_tree) ||
+	    !READ_ONCE(ipe_keyring->restrict_link))
+		return NULL;
+
+	return ipe_keyring;
+}
+
+/**
+ * ipe_keyring_init() - Allocate and configure the IPE keyring.
+ *
+ * Return: Always %0. A failure leaves IPE without its dedicated keyring.
+ */
+int __init ipe_keyring_init(void)
+{
+	struct key *keyring;
+	int rc;
+
+	keyring = keyring_alloc(".ipe", GLOBAL_ROOT_UID, GLOBAL_ROOT_GID,
+				current_cred(),
+				KEY_POS_SEARCH |
+				KEY_USR_VIEW | KEY_USR_READ | KEY_USR_WRITE |
+				KEY_USR_SEARCH | KEY_USR_SETATTR,
+				KEY_ALLOC_NOT_IN_QUOTA, NULL, NULL);
+	if (IS_ERR(keyring)) {
+		pr_err("failed to allocate keyring: %ld\n", PTR_ERR(keyring));
+		return 0;
+	}
+
+	if (!ipe_keyring_unsealed) {
+		rc = keyring_restrict(make_key_ref(keyring, true), NULL, NULL);
+		if (rc) {
+			pr_err("failed to restrict keyring: %d\n", rc);
+			key_revoke(keyring);
+			key_put(keyring);
+			return 0;
+		}
+	}
+
+	ipe_keyring = keyring;
+
+	return 0;
+}
diff --git a/security/ipe/keyring.h b/security/ipe/keyring.h
new file mode 100644
index 000000000000..3d450a465511
--- /dev/null
+++ b/security/ipe/keyring.h
@@ -0,0 +1,16 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (C) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
+ */
+
+#ifndef _IPE_KEYRING_H
+#define _IPE_KEYRING_H
+
+#include <linux/init.h>
+
+struct key;
+
+int __init ipe_keyring_init(void);
+struct key *ipe_keyring_lookup(void);
+
+#endif /* _IPE_KEYRING_H */
diff --git a/security/ipe/policy.c b/security/ipe/policy.c
index e542329726bc..abc1ff9ac230 100644
--- a/security/ipe/policy.c
+++ b/security/ipe/policy.c
@@ -9,6 +9,7 @@
 #include "ipe.h"
 #include "eval.h"
 #include "fs.h"
+#include "keyring.h"
 #include "policy.h"
 #include "policy_parser.h"
 #include "audit.h"
@@ -160,6 +161,7 @@ struct ipe_policy *ipe_new_policy(const char *text, size_t textlen,
 				  const char *pkcs7, size_t pkcs7len)
 {
 	struct ipe_policy *new = NULL;
+	struct key *keyring;
 	int rc = 0;
 
 	new = kzalloc_obj(*new);
@@ -189,6 +191,14 @@ struct ipe_policy *ipe_new_policy(const char *text, size_t textlen,
 						    VERIFYING_UNSPECIFIED_SIGNATURE,
 						    set_pkcs7_data, new);
 #endif
+		if (rc == -ENOKEY || rc == -EKEYREJECTED) {
+			keyring = ipe_keyring_lookup();
+			if (keyring)
+				rc = verify_pkcs7_signature(NULL, 0, new->pkcs7,
+							    pkcs7len, keyring,
+							    VERIFYING_UNSPECIFIED_SIGNATURE,
+							    set_pkcs7_data, new);
+		}
 		if (rc)
 			goto err;
 	} else {

-- 
2.53.0

