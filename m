From: Manuel Huber <manuelh@nvidia.com>
Date: Mon, 19 Oct 2026 21:40:27 +0000
Subject: [PATCH RFC 3/4] Documentation: ipe: document the IPE keyring
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-b4-ipe-keyring-rfc-v1-3-156f0b93e843@nvidia.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792446042; l=4917;
 i=manuelh@nvidia.com; s=20261019; h=from:subject:message-id;
 bh=bQSlVKSLE/vFXclrnH0WGlD57ySt0pDqaCI7PqKjvz8=;
 b=LeRG8q2weFYyCzPHBXqZC5UUlqvkvzwvk8VeM4N7+kedJjkHqVy+hnuVIQ+xrFVEi0iR32rAm
 7fUQYrHrKA3DBUiCrfmMsjOPbsMLoFlwYPYdpBypAVhMf9xZU2Fw6SJ
X-Developer-Key: i=manuelh@nvidia.com; a=ed25519;
 pk=uKggxpZ/mM0qtFnudxvh5Dfz8I6VoehwoM3eYCe3tyU=
X-Endpoint-Received: by B4 Relay for manuelh@nvidia.com/20261019 with auth_id=1244
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the .ipe policy-verification keyring and its additive use
after the existing trust sources.

Signed-off-by: Manuel Huber <manuelh@nvidia.com>
---
 Documentation/admin-guide/LSM/ipe.rst | 41 ++++++++++++++++++++++++++++++++++-
 Documentation/security/ipe.rst        | 16 +++++++++-----
 2 files changed, 51 insertions(+), 6 deletions(-)

diff --git a/Documentation/admin-guide/LSM/ipe.rst b/Documentation/admin-guide/LSM/ipe.rst
index 9e82a2082b94..48ccad203301 100644
--- a/Documentation/admin-guide/LSM/ipe.rst
+++ b/Documentation/admin-guide/LSM/ipe.rst
@@ -238,7 +238,11 @@ unconstrained root, and deploying an "allow all" policy). These
 policies must be signed by a certificate that chains to the
 ``SYSTEM_TRUSTED_KEYRING``, or to the secondary and/or platform keyrings if
 ``CONFIG_IPE_POLICY_SIG_SECONDARY_KEYRING`` and/or
-``CONFIG_IPE_POLICY_SIG_PLATFORM_KEYRING`` are enabled, respectively.
+``CONFIG_IPE_POLICY_SIG_PLATFORM_KEYRING`` are enabled, respectively. IPE also
+provides a dedicated ``.ipe`` keyring for policy-signing certificates that are
+provisioned by userspace, as described below. The ``.ipe`` keyring is an
+additive final fallback and does not replace the configured system trust
+sources.
 With openssl, the policy can be signed by::
 
    openssl smime -sign \
@@ -251,6 +255,41 @@ With openssl, the policy can be signed by::
       -outform der \
       -out "$MY_POLICY.p7b"
 
+Provisioning the IPE policy keyring
+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
+
+The ``.ipe`` keyring allows a system to provision an IPE-specific policy
+signing certificate without embedding it in the kernel or firmware trust
+stores. It is not linked into any process keyring. Userspace addresses it
+directly with the ``KEY_SPEC_IPE_KEYRING`` special key ID (``-12``), which does
+not grant possession of the keyring.
+
+The keyring is restricted while empty by default and cannot then be
+provisioned. To provision it, boot with ``ipe.keyring_unsealed=1``. Userspace
+can add a DER-encoded X.509 certificate and then apply a reject-all
+restriction::
+
+   keyctl padd asymmetric "" -12 < policy-signing-key.der
+   keyctl restrict_keyring -12
+
+Both steps are required. IPE ignores the keyring until it is nonempty and
+restricted, so a partially provisioned, mutable keyring is not a trust source.
+The restriction cannot be removed. More than one certificate can be enrolled
+by repeating the ``keyctl padd`` command before restricting the keyring.
+
+Restriction prevents adding keys, but it does not prevent userspace from
+removing keys or otherwise disabling the keyring. To lock it against further
+userspace modification, drop its write and setattr permissions::
+
+   keyctl setperm -12 0x08030000
+
+This retains the permissions needed for verification and inspection.
+Provisioning, restriction, and permission hardening must be completed before
+relying on ``.ipe`` as a trust source.
+
+Once nonempty and restricted, ``.ipe`` is searched after the configured system
+trust sources. An absent, empty, or unrestricted ``.ipe`` keyring is ignored.
+
 Deploying the policies is done through securityfs, through the
 ``new_policy`` node. To deploy a policy, simply cat the file into the
 securityfs node::
diff --git a/Documentation/security/ipe.rst b/Documentation/security/ipe.rst
index 4490aed5918a..80f9893dddb5 100644
--- a/Documentation/security/ipe.rst
+++ b/Documentation/security/ipe.rst
@@ -248,11 +248,17 @@ policy updates have to be done rebootlessly.
 
 To allow an update from an external source, it could be potentially malicious,
 so this policy needs to have a way to be identified as trusted. This is
-done via a signature chained to a trust source in the kernel. Arbitrarily,
-this is  the ``SYSTEM_TRUSTED_KEYRING``, a keyring that is initially
-populated at kernel compile-time, as this matches the expectation that the
-author of the compiled-in policy described above is the same entity that can
-deploy policy updates.
+done via a signature chained to a trust source in the kernel. IPE can use the
+builtin trusted keyring and, when configured, the secondary and platform
+keyrings. This matches systems where the entity that establishes the kernel or
+firmware trust store is also authorized to deploy policy updates.
+
+IPE also has a dedicated ``.ipe`` keyring for deployments that establish an
+IPE-specific trust anchor from userspace. The keyring can be provisioned and
+irreversibly restricted. IPE uses it only when it is nonempty and restricted,
+and only as a fallback after the configured system keyrings. This keeps the
+existing trust model intact while allowing a policy-signing key to be rotated
+across boots without changing the kernel image or a broader system trust store.
 
 Anti-Rollback / Anti-Replay
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- 
2.53.0

