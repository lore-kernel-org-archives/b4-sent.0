From: Manuel Huber <manuelh@nvidia.com>
Date: Thu, 29 Oct 2026 00:30:39 +0000
Subject: [PATCH v2 2/3] keys: add KEY_SPEC_IPE_KEYRING
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-b4-ipe-keyring-rfc-v2-2-77727b205844@nvidia.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793233875; l=4547;
 i=manuelh@nvidia.com; s=20261019; h=from:subject:message-id;
 bh=/BFpBbq1FQa32YOzNX0aI7W2U2EGLrFUn65BbO8gg8g=;
 b=a8U5f4fDz3jnb/NdfevMsgRLh/Bpxd/5HEOmei1beg5hrND+EV39Tf8E8oS855+nuFE+ElntV
 n91Ec7ANsvBAm1CF9zhXRGxQp3PZor/EBkp5EHuKnB0+Vk+S+UDqvu0
X-Developer-Key: i=manuelh@nvidia.com; a=ed25519;
 pk=uKggxpZ/mM0qtFnudxvh5Dfz8I6VoehwoM3eYCe3tyU=
X-Endpoint-Received: by B4 Relay for manuelh@nvidia.com/20261019 with auth_id=1244
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The BPF, dm-verity, and fs-verity keyrings have well-known IDs which
allow userspace to directly address them. This commit follows the same
pattern for the .ipe keyring.

This provides a direct interface independent of resolving %:.ipe through
process keyrings and /proc/keys.

Signed-off-by: Manuel Huber <manuelh@nvidia.com>
---
 Documentation/security/keys/core.rst | 12 ++++++++++++
 include/linux/key.h                  |  2 ++
 include/uapi/linux/keyctl.h          |  1 +
 security/ipe/keyring.c               |  2 ++
 security/keys/process_keys.c         | 23 +++++++++++++++++++++++
 5 files changed, 40 insertions(+)

diff --git a/Documentation/security/keys/core.rst b/Documentation/security/keys/core.rst
index 326b8a973828..64b37817a335 100644
--- a/Documentation/security/keys/core.rst
+++ b/Documentation/security/keys/core.rst
@@ -373,6 +373,18 @@ process making the call::
 	KEY_SPEC_REQKEY_AUTH_KEY	-7	assumed request_key()
 						  authorisation key
 
+There are also values that refer to a specific kernel keyring rather than to
+anything belonging to the caller.  These well-known IDs allow userspace to
+name kernel keyrings directly even when they are not linked into a process
+keyring::
+
+	CONSTANT			VALUE	KEY REFERENCED
+	==============================	======	===========================
+	KEY_SPEC_IPE_KEYRING		-12	the ".ipe" keyring
+
+The availability of a subsystem keyring depends on its kernel configuration.
+Looking up an unavailable keyring returns ``ENOKEY``.
+
 
 The main syscalls are:
 
diff --git a/include/linux/key.h b/include/linux/key.h
index 81b8f05c6898..9c2ac0c70d56 100644
--- a/include/linux/key.h
+++ b/include/linux/key.h
@@ -440,6 +440,8 @@ extern key_ref_t keyring_search(key_ref_t keyring,
 extern int keyring_restrict(key_ref_t keyring, const char *type,
 			    const char *restriction);
 
+extern void key_register_ipe_keyring(struct key *keyring);
+
 extern struct key *key_lookup(key_serial_t id);
 
 static inline key_serial_t key_serial(const struct key *key)
diff --git a/include/uapi/linux/keyctl.h b/include/uapi/linux/keyctl.h
index 4c8884eea808..e42fca286b15 100644
--- a/include/uapi/linux/keyctl.h
+++ b/include/uapi/linux/keyctl.h
@@ -24,6 +24,7 @@
 #define KEY_SPEC_GROUP_KEYRING		-6	/* - key ID for GID-specific keyring */
 #define KEY_SPEC_REQKEY_AUTH_KEY	-7	/* - key ID for assumed request_key auth key */
 #define KEY_SPEC_REQUESTOR_KEYRING	-8	/* - key ID for request_key() dest keyring */
+#define KEY_SPEC_IPE_KEYRING		-12	/* - key ID for the .ipe keyring */
 
 /* request-key default keyrings */
 #define KEY_REQKEY_DEFL_NO_CHANGE		-1
diff --git a/security/ipe/keyring.c b/security/ipe/keyring.c
index 8502f825945d..14626df46e71 100644
--- a/security/ipe/keyring.c
+++ b/security/ipe/keyring.c
@@ -26,5 +26,7 @@ int __init ipe_keyring_init(void)
 			      KEY_ALLOC_NOT_IN_QUOTA, NULL, NULL);
 	if (IS_ERR(ipe_keyring))
 		panic("failed to allocate \".ipe\" keyring");
+	key_register_ipe_keyring(ipe_keyring);
+
 	return 0;
 }
diff --git a/security/keys/process_keys.c b/security/keys/process_keys.c
index a63c46bb2d14..20d6faefb75e 100644
--- a/security/keys/process_keys.c
+++ b/security/keys/process_keys.c
@@ -22,6 +22,9 @@
 /* Session keyring create vs join semaphore */
 static DEFINE_MUTEX(key_session_mutex);
 
+/* IPE keyring reachable through KEY_SPEC_IPE_KEYRING */
+static struct key *ipe_keyring __ro_after_init;
+
 /* The root user's tracking struct */
 struct key_user root_key_user = {
 	.usage		= REFCOUNT_INIT(3),
@@ -590,6 +593,18 @@ bool lookup_user_key_possessed(const struct key *key,
 	return key == match_data->raw_data;
 }
 
+/**
+ * key_register_ipe_keyring - Publish the IPE keyring
+ * @keyring: The keyring to publish
+ *
+ * Make @keyring reachable by userspace through the KEY_SPEC_IPE_KEYRING
+ * special key ID. Called once, from an initcall, and never undone.
+ */
+void key_register_ipe_keyring(struct key *keyring)
+{
+	ipe_keyring = keyring;
+}
+
 /*
  * Look up a key ID given us by userspace with a given permissions mask to get
  * the key it refers to.
@@ -741,6 +756,14 @@ key_ref_t lookup_user_key(key_serial_t id, unsigned long lflags,
 		key_ref = make_key_ref(key, 1);
 		break;
 
+	case KEY_SPEC_IPE_KEYRING:
+		key = ipe_keyring;
+		if (!key)
+			goto error;
+		__key_get(key);
+		key_ref = make_key_ref(key, 0);
+		break;
+
 	default:
 		key_ref = ERR_PTR(-EINVAL);
 		if (id < 1)

-- 
2.53.0

