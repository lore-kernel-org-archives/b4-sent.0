From: Manuel Huber <manuelh@nvidia.com>
Date: Thu, 29 Oct 2026 00:30:38 +0000
Subject: [PATCH v2 1/3] ipe: add the .ipe policy keyring
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-b4-ipe-keyring-rfc-v2-1-77727b205844@nvidia.com>
References: <20261029-b4-ipe-keyring-rfc-v2-0-77727b205844@nvidia.com>
In-Reply-To: <20261029-b4-ipe-keyring-rfc-v2-0-77727b205844@nvidia.com>
To: Fan Wu <wufan@kernel.org>, David Howells <dhowells@redhat.com>, 
 Jarkko Sakkinen <jarkko@kernel.org>
Cc: Christian Brauner <brauner@kernel.org>, 
 Andrew Halaney <andrew@amutable.com>, Paul Moore <paul@paul-moore.com>, 
 James Morris <jmorris@namei.org>, "Serge E. Hallyn" <serge@hallyn.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Luca Boccassi <luca.boccassi@gmail.com>, 
 James Bottomley <James.Bottomley@HansenPartnership.com>, 
 linux-security-module@vger.kernel.org, keyrings@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 kexec@lists.infradead.org, Manuel Huber <manuelh@nvidia.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793233875; l=8137;
 i=manuelh@nvidia.com; s=20261019; h=from:subject:message-id;
 bh=qUKO8xyX+/8KnwHErrUte/NPW7CoaYPDwwyvYL+BdNU=;
 b=MXkQBF9XIPmW3lQQqP3IeEwfmaFpTfmzIFwNsZAfrIlG+uYj7UlcRHC7eY3gmY9NLyjJSOSXl
 UChshGXrzhTCTBe+wgtGrLi/y93tQwVlFJqhvvfgB0ri92DtgmGQM/r
X-Developer-Key: i=manuelh@nvidia.com; a=ed25519;
 pk=uKggxpZ/mM0qtFnudxvh5Dfz8I6VoehwoM3eYCe3tyU=
X-Endpoint-Received: by B4 Relay for manuelh@nvidia.com/20261019 with auth_id=1244
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a dedicated .ipe keyring for IPE policy signature verification.
With this, userspace can provision its own keys into the keyring,
then restrict it and activate it for IPE policy signature verification.

Gate creation of the keyring behind a new by-default disabled
CONFIG_SECURITY_IPE_KEYRING Kconfig option. When created, the keyring
is empty and writable. The keyring is used as a fallback after the
existing policy trust sources only when it is created, non-empty, and
restricted with restrict_link_reject.

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
using dm-verity. While in that usage scenario, signing a per-guest
policy with a pre-provisioned policy-signing certificate in the
builtin, secondary, or platform keyrings would be technically possible,
it would require including its corresponding private key in the guest
build artifacts. Making it possible to use an ephemeral,
userspace-provided key avoids shipping a static policy-signing private
key with the guest rootfs.

Signed-off-by: Manuel Huber <manuelh@nvidia.com>
---
 Documentation/admin-guide/kernel-parameters.txt |  1 +
 security/ipe/Kconfig                            | 16 +++++++++++++
 security/ipe/Makefile                           |  2 ++
 security/ipe/ipe.c                              |  4 ++++
 security/ipe/keyring.c                          | 30 +++++++++++++++++++++++++
 security/ipe/keyring.h                          | 17 ++++++++++++++
 security/ipe/policy.c                           | 17 ++++++++++++++
 7 files changed, 87 insertions(+)

diff --git a/Documentation/admin-guide/kernel-parameters.txt b/Documentation/admin-guide/kernel-parameters.txt
index e75344f4e0cd..9fabbc1c95b6 100644
--- a/Documentation/admin-guide/kernel-parameters.txt
+++ b/Documentation/admin-guide/kernel-parameters.txt
@@ -23,6 +23,7 @@
 	HW	Appropriate hardware is enabled.
 	HYPER_V HYPERV support is enabled.
 	IMA     Integrity measurement architecture is enabled.
+	IPE	Integrity Policy Enforcement is enabled.
 	IP_PNP	IP DHCP, BOOTP, or RARP is enabled.
 	IPV6	IPv6 support is enabled.
 	ISAPNP	ISA PnP code is enabled.
diff --git a/security/ipe/Kconfig b/security/ipe/Kconfig
index a110a6cd848b..5c51da074264 100644
--- a/security/ipe/Kconfig
+++ b/security/ipe/Kconfig
@@ -51,6 +51,22 @@ config IPE_POLICY_SIG_PLATFORM_KEYRING
 
 	  If unsure, answer Y.
 
+config SECURITY_IPE_KEYRING
+	bool "IPE policy keyring"
+	default n
+	help
+	  This option creates the .ipe keyring, which allows trusted
+	  userspace to provision certificates for IPE policy signature
+	  verification. IPE uses the keyring only after userspace has added
+	  at least one certificate and applied a reject-all restriction.
+
+	  Enable this only when the userspace component that provisions and
+	  restricts the keyring is part of the system's trusted computing
+	  base. Such systems must also prevent unauthorized kexec, which
+	  would start a new kernel without preserving the keyring state.
+
+	  If unsure, answer N.
+
 menu "IPE Trust Providers"
 
 config IPE_PROP_DM_VERITY
diff --git a/security/ipe/Makefile b/security/ipe/Makefile
index 2ffabfa63fe9..78161dfb48ea 100644
--- a/security/ipe/Makefile
+++ b/security/ipe/Makefile
@@ -25,6 +25,8 @@ obj-$(CONFIG_SECURITY_IPE) += \
 	policy_parser.o \
 	audit.o \
 
+obj-$(CONFIG_SECURITY_IPE_KEYRING) += keyring.o
+
 clean-files := boot_policy.c \
 
 obj-$(CONFIG_SECURITY_IPE_KUNIT_TEST) += \
diff --git a/security/ipe/ipe.c b/security/ipe/ipe.c
index 495bb765de1b..ee8731eb4070 100644
--- a/security/ipe/ipe.c
+++ b/security/ipe/ipe.c
@@ -7,6 +7,7 @@
 #include "ipe.h"
 #include "eval.h"
 #include "hooks.h"
+#include "keyring.h"
 
 extern const char *const ipe_boot_policy;
 bool ipe_enabled;
@@ -97,4 +98,7 @@ DEFINE_LSM(ipe) = {
 	.init = ipe_init,
 	.blobs = &ipe_blobs,
 	.initcall_fs = ipe_init_securityfs,
+#ifdef CONFIG_SECURITY_IPE_KEYRING
+	.initcall_late = ipe_keyring_init,
+#endif
 };
diff --git a/security/ipe/keyring.c b/security/ipe/keyring.c
new file mode 100644
index 000000000000..8502f825945d
--- /dev/null
+++ b/security/ipe/keyring.c
@@ -0,0 +1,30 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (C) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
+ */
+
+#include <linux/cred.h>
+#include <linux/err.h>
+#include <linux/key.h>
+
+#include "keyring.h"
+
+struct key *ipe_keyring __ro_after_init;
+
+/**
+ * ipe_keyring_init() - Allocate and configure the IPE keyring.
+ *
+ * Return: Always %0.
+ */
+int __init ipe_keyring_init(void)
+{
+	ipe_keyring =
+		keyring_alloc(".ipe", GLOBAL_ROOT_UID, GLOBAL_ROOT_GID,
+			      current_cred(), KEY_POS_SEARCH |
+				KEY_USR_VIEW | KEY_USR_READ | KEY_USR_WRITE |
+				KEY_USR_SEARCH | KEY_USR_SETATTR,
+			      KEY_ALLOC_NOT_IN_QUOTA, NULL, NULL);
+	if (IS_ERR(ipe_keyring))
+		panic("failed to allocate \".ipe\" keyring");
+	return 0;
+}
diff --git a/security/ipe/keyring.h b/security/ipe/keyring.h
new file mode 100644
index 000000000000..d9a057a14978
--- /dev/null
+++ b/security/ipe/keyring.h
@@ -0,0 +1,17 @@
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
+extern struct key *ipe_keyring;
+
+int __init ipe_keyring_init(void);
+
+#endif /* _IPE_KEYRING_H */
diff --git a/security/ipe/policy.c b/security/ipe/policy.c
index e542329726bc..514a1985b5e1 100644
--- a/security/ipe/policy.c
+++ b/security/ipe/policy.c
@@ -4,11 +4,13 @@
  */
 
 #include <linux/errno.h>
+#include <linux/key.h>
 #include <linux/verification.h>
 
 #include "ipe.h"
 #include "eval.h"
 #include "fs.h"
+#include "keyring.h"
 #include "policy.h"
 #include "policy_parser.h"
 #include "audit.h"
@@ -160,6 +162,9 @@ struct ipe_policy *ipe_new_policy(const char *text, size_t textlen,
 				  const char *pkcs7, size_t pkcs7len)
 {
 	struct ipe_policy *new = NULL;
+#ifdef CONFIG_SECURITY_IPE_KEYRING
+	struct key_restriction *restriction;
+#endif
 	int rc = 0;
 
 	new = kzalloc_obj(*new);
@@ -188,6 +193,18 @@ struct ipe_policy *ipe_new_policy(const char *text, size_t textlen,
 						    VERIFY_USE_PLATFORM_KEYRING,
 						    VERIFYING_UNSPECIFIED_SIGNATURE,
 						    set_pkcs7_data, new);
+#endif
+#ifdef CONFIG_SECURITY_IPE_KEYRING
+		if (rc == -ENOKEY || rc == -EKEYREJECTED) {
+			restriction = READ_ONCE(ipe_keyring->restrict_link);
+			if (READ_ONCE(ipe_keyring->keys.nr_leaves_on_tree) &&
+			    restriction &&
+			    READ_ONCE(restriction->check) == restrict_link_reject)
+				rc = verify_pkcs7_signature(NULL, 0, new->pkcs7,
+							    pkcs7len, ipe_keyring,
+							    VERIFYING_UNSPECIFIED_SIGNATURE,
+							    set_pkcs7_data, new);
+		}
 #endif
 		if (rc)
 			goto err;

-- 
2.53.0

