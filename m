From: Manuel Huber <manuelh@nvidia.com>
Subject: [PATCH RFC 0/4] IPE: add a dedicated policy keyring
Date: Mon, 19 Oct 2026 21:40:24 +0000
Message-Id: <20261019-b4-ipe-keyring-rfc-v1-0-156f0b93e843@nvidia.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MMQqAMAxA0atIZgO2ilBXwQO4ikOrUYNQJQVRp
 He3OL7h/xcCCVOAJntB6OLAh09QeQbTZv1KyHMy6ELXqlAGXYV8Eu70CPsVZZnQmdIZS0obqyG
 Fp9DC9z8doO9aGGP8AH+7iDNpAAAA
X-Change-ID: 20261019-b4-ipe-keyring-rfc-b93b9ae129a2
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792446042; l=2751;
 i=manuelh@nvidia.com; s=20261019; h=from:subject:message-id;
 bh=6WPcEAqFx8dpbBNrw8M+IL0uMQ7Yp3AICptgIgyBFtA=;
 b=gkxyREkuboghZ5svc2zXzJmD9W9S2bUyNSjdWo563ECwGLU3xuBDMg9oYuexLJePZ5edkrcMn
 iUDB19Lgr1ICwRUnqLsI5JMzrO0MYWKnXfSeG9B8v1dUd48rmk8lKcC
X-Developer-Key: i=manuelh@nvidia.com; a=ed25519;
 pk=uKggxpZ/mM0qtFnudxvh5Dfz8I6VoehwoM3eYCe3tyU=
X-Endpoint-Received: by B4 Relay for manuelh@nvidia.com/20261019 with auth_id=1244
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a dedicated ".ipe" keyring for IPE policy-signature verification,
modeled after the dm-verity keyring, allowing userspace to provision
IPE-specific policy-signing certificates. Systems that do not provision
the keyring retain their existing behavior.

This RFC is based on commit 48f936e302a9 ("ipe: update the project and
test suite links") from ipe/next so review can begin before the
prerequisite keyring work reaches that branch. The series will be rebased
onto a refreshed ipe/next once that work is available there [1].

The keyring readiness check currently follows the dm-verity and BPF
implementations. A parallel keys RFC introduces keyring_is_empty() for
this purpose [2]. A later revision will use the helper if it is available
in the submission base.

Testing:
- Built an x86_64 kernel with GCC 15.2.0 and Clang/LLD 21.1.8.
- Passed all 33 IPE parser KUnit assertions.
- Passed all 4 sealed-default keyring selftests under QEMU TCG.
- Passed all 16 provisioning-mode keyring selftests under QEMU TCG with
  ipe.keyring_unsealed=1.

[1] https://lore.kernel.org/r/20261008-ajhalaney-dmverity-key-identifier-v2-0-008456d189cb@amutable.com
[2] https://lore.kernel.org/r/20261016215326.4110064-5-jarkko@kernel.org

Signed-off-by: Manuel Huber <manuelh@nvidia.com>
---
Manuel Huber (4):
      ipe: add the .ipe policy keyring
      keys: add KEY_SPEC_IPE_KEYRING
      Documentation: ipe: document the IPE keyring
      selftests/ipe: test the IPE policy keyring

 Documentation/admin-guide/LSM/ipe.rst           |  41 ++-
 Documentation/admin-guide/kernel-parameters.txt |   9 +
 Documentation/security/ipe.rst                  |  16 +-
 Documentation/security/keys/core.rst            |   9 +
 MAINTAINERS                                     |   1 +
 include/linux/key.h                             |   2 +
 include/uapi/linux/keyctl.h                     |   1 +
 security/ipe/Makefile                           |   1 +
 security/ipe/ipe.c                              |   2 +
 security/ipe/keyring.c                          |  80 ++++++
 security/ipe/keyring.h                          |  16 ++
 security/ipe/policy.c                           |  10 +
 security/keys/process_keys.c                    |  23 ++
 tools/testing/selftests/Makefile                |   1 +
 tools/testing/selftests/ipe/Makefile            |   5 +
 tools/testing/selftests/ipe/config              |   7 +
 tools/testing/selftests/ipe/test-ipe-keyring.sh | 357 ++++++++++++++++++++++++
 17 files changed, 575 insertions(+), 6 deletions(-)
---
base-commit: 48f936e302a9c48cfc032eb5944c3a6246bc9043
change-id: 20261019-b4-ipe-keyring-rfc-b93b9ae129a2

Best regards,
-- 
Manuel Huber <manuelh@nvidia.com>

