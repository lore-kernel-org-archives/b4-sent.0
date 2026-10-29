From: Manuel Huber <manuelh@nvidia.com>
Subject: [PATCH v2 0/3] IPE: add a dedicated policy keyring
Date: Thu, 29 Oct 2026 00:30:37 +0000
Message-Id: <20261029-b4-ipe-keyring-rfc-v2-0-77727b205844@nvidia.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ7CIBBFr9LM2jFAayOuvIfpAujQToy0AUNsG
 u4u9gAu30v++zskikwJbs0OkTInXkIFdWrAzSZMhDxWBiVUL4XUaDvklfBJW+QwYfQOrW6tNiS
 VNgrqcI3k+XNEH0PlmdN7idvxkeXP/s1liQLlpfeihunatfeQeWRzdssLhlLKFxAewIm1AAAA
X-Change-ID: 20261019-b4-ipe-keyring-rfc-b93b9ae129a2
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793233875; l=3522;
 i=manuelh@nvidia.com; s=20261019; h=from:subject:message-id;
 bh=pTATwWDEl4HWcrF9PyrJWcbEkLf1+DklVc30h0qdx5g=;
 b=vDmytWLoNFu6z92hq+UUXOOaRVOC9WPlYNxEWJbbVI+bBd9Wh4fTTtwYSB85f7xz/+Xf1p0iH
 oA0oLNoSbQSBRM0M3jPBepMg+EUjIqDohlmCmxUePa09iqheN2gf7ZR
X-Developer-Key: i=manuelh@nvidia.com; a=ed25519;
 pk=uKggxpZ/mM0qtFnudxvh5Dfz8I6VoehwoM3eYCe3tyU=
X-Endpoint-Received: by B4 Relay for manuelh@nvidia.com/20261019 with auth_id=1244
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a dedicated ".ipe" keyring for IPE policy-signature verification,
allowing userspace to provision IPE-specific policy-signing certificates.
Systems that do not provision the keyring retain their existing behavior.

This series is based on commit 48f936e302a9 ("ipe: update the project and
test suite links") from ipe/next. The BPF, dm-verity, and fs-verity
well-known key IDs are now in mainline [1]; KEY_SPEC_IPE_KEYRING follows
these IDs at -12. The series should be rebased once that work is available
in ipe/next.

IPE currently checks the keyring's entry count directly. A separate
keys RFC proposes keyring_is_empty() to encapsulate this check [2].
This series does not depend on that RFC; it should use the helper if
available in the submission base.

Testing:
- Built x86_64 kernels with GCC 15.2.0 and Clang/LLD 21.1.8.
- Passed all 33 in-tree IPE parser KUnit cases under QEMU/KVM.
- Passed all 2,364 IPE CI cases under QEMU/KVM, including eight new
  .ipe keyring cases [3]. The CI changes are in draft PR [4].

[1] https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=62c457528529
[2] https://lore.kernel.org/r/20261016215326.4110064-5-jarkko@kernel.org
[3] The CI run used a local compatibility adjustment to locate
    usr/gen_init_cpio on this kernel base.
[4] https://github.com/Integrity-Policy-Enforcement/ci/pull/4

Signed-off-by: Manuel Huber <manuelh@nvidia.com>
---
Changes in v2:
- Drop the RFC designation.
- Replace ipe.keyring_unsealed with default-off CONFIG_SECURITY_IPE_KEYRING;
  leave provisioning and restriction of the enabled keyring to userspace.
- Require restrict_link_reject before using .ipe for policy verification.
- Access the keyring directly instead of through a lookup helper, and panic
  if keyring allocation fails.
- Explain the per-guest signing use case and the reason for avoiding a
  static private key in guest build artifacts.
- Retain the well-known key ID commit, but refine its commit message.
- Define the IPE acronym in kernel-parameters.txt.
- Document the userspace-provisioned threat model and kexec requirements.
- Drop the kselftest commit; instead, add tests to IPE CI's policy_signature
  batch [4].
- Link to v1: https://lore.kernel.org/r/20261019-b4-ipe-keyring-rfc-v1-0-156f0b93e843@nvidia.com

---
Manuel Huber (3):
      ipe: add the .ipe policy keyring
      keys: add KEY_SPEC_IPE_KEYRING
      Documentation: ipe: document the IPE keyring

 Documentation/admin-guide/LSM/ipe.rst           | 77 ++++++++++++++++++++++++-
 Documentation/admin-guide/kernel-parameters.txt |  1 +
 Documentation/security/ipe.rst                  | 19 ++++--
 Documentation/security/keys/core.rst            | 12 ++++
 include/linux/key.h                             |  2 +
 include/uapi/linux/keyctl.h                     |  1 +
 security/ipe/Kconfig                            | 16 +++++
 security/ipe/Makefile                           |  2 +
 security/ipe/ipe.c                              |  4 ++
 security/ipe/keyring.c                          | 32 ++++++++++
 security/ipe/keyring.h                          | 17 ++++++
 security/ipe/policy.c                           | 17 ++++++
 security/keys/process_keys.c                    | 23 ++++++++
 13 files changed, 217 insertions(+), 6 deletions(-)
---
base-commit: 48f936e302a9c48cfc032eb5944c3a6246bc9043
change-id: 20261019-b4-ipe-keyring-rfc-b93b9ae129a2

Best regards,
-- 
Manuel Huber <manuelh@nvidia.com>

