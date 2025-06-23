From: Abhinav Saxena <xandfury@gmail.com>
Subject: [PATCH 0/2] Possible TTY privilege escalation in TIOCSTI ioctl
Date: Sun, 22 Jun 2025 19:41:06 -0600
Message-Id: <20250622-toicsti-bug-v1-0-f374373b04b2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALKwWGgC/1XMQQ6CMBCF4auQWVvTDiLgynsYFm0ZYRKhpK1EQ
 3p3K4kLl/9L3rdBIM8U4FJs4GnlwG7OoQ4F2FHPAwnucwNKrORZNSI6tiGyMM9B1A2iaag96RI
 hPxZPd37t2q3LPXKIzr93fFXf9ee0f86qhBQk0dalripj++swaX4crZugSyl9ACfzuGKmAAAA
To: Shuah Khan <shuah@kernel.org>, Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <nick.desaulniers+lkml@gmail.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>, 
 Paul Moore <paul@paul-moore.com>, 
 Stephen Smalley <stephen.smalley.work@gmail.com>, 
 Ondrej Mosnacek <omosnace@redhat.com>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 llvm@lists.linux.dev, selinux@vger.kernel.org, 
 Abhinav Saxena <xandfury@gmail.com>, kees@kernel.org, 
 linux-hardening@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750642871; l=4278;
 i=xandfury@gmail.com; s=20250614; h=from:subject:message-id;
 bh=buJJLb5Q6cm8TshrP4dLEkTBplTMymNnBjPBccRp1EE=;
 b=WiOBZMIPV8q1Q0IRgB3MwpCfgV8UbYqwBRlogLksBbO+sZ645oPaUbC0oWxeL6ssfQFHOIVbZ
 P0gzf64q/5jCSQhD8yRf16oMX8M59Kpt/R2QDRhVY4rxyYsn23l8wcf
X-Developer-Key: i=xandfury@gmail.com; a=ed25519;
 pk=YN6w7WNet8skqvMWxhG5BlAmtd1SQmo8If6Mofh4k44=
X-Endpoint-Received: by B4 Relay for xandfury@gmail.com/20250614 with auth_id=436
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series was initially sent to security@k.o; resending it in
public. I might follow-up with a tests series which addresses similar 
issues with TIOCLINUX.

===============

The TIOCSTI ioctl uses capable(CAP_SYS_ADMIN) for access control, which 
checks the current process's credentials. However, it doesn't validate 
against the file opener's credentials stored in file->f_cred.

This creates a potential security issue where an unprivileged process 
can open a TTY fd and pass it to a privileged process via SCM_RIGHTS. 
The privileged process may then inadvertently grant access based on its 
elevated privileges rather than the original opener's credentials.

Background
==========

As noted in previous discussion, while CONFIG_LEGACY_TIOCSTI can restrict 
TIOCSTI usage, it is enabled by default in most distributions. Even when 
CONFIG_LEGACY_TIOCSTI=n, processes with CAP_SYS_ADMIN can still use TIOCSTI 
according to the Kconfig documentation.

Additionally, CONFIG_LEGACY_TIOCSTI controls the default value for the 
dev.tty.legacy_tiocsti sysctl, which remains runtime-configurable. This 
means the described attack vector could work on systems even with 
CONFIG_LEGACY_TIOCSTI=n, particularly on Ubuntu 24.04 where it's "restricted" 
but still functional.

Solution Approach
=================

This series addresses the issue through SELinux LSM integration rather 
than modifying core TTY credential checking to avoid potential compatibility 
issues with existing userspace.

The enhancement adds proper current task and file credential capability 
validation in SELinux's selinux_file_ioctl() hook specifically for 
TIOCSTI operations.

Testing
=======

All patches have been validated using:
- scripts/checkpatch.pl --strict (0 errors, 0 warnings)
- Functional testing on kernel v6.16-rc2
- File descriptor passing security test scenarios
- SELinux policy enforcement testing

The fd_passing_security test demonstrates the security concern.
To verify, disable legacy TIOCSTI and run the test:

$ echo "0" | sudo tee /proc/sys/dev/tty/legacy_tiocsti
$ sudo ./tools/testing/selftests/tty/tty_tiocsti_test -t fd_passing_security

Patch Overview
==============

PATCH 1/2: selftests/tty: add TIOCSTI test suite
Comprehensive test suite demonstrating the issue and fix validation

PATCH 2/2: selinux: add capability checks for TIOCSTI ioctl
Core security enhancement via SELinux LSM hook

References
==========

- tty_ioctl(4) - documents TIOCSTI ioctl and capability requirements
- commit 83efeeeb3d04 ("tty: Allow TIOCSTI to be disabled")
- Documentation/security/credentials.rst
- https://github.com/KSPP/linux/issues/156
- https://lore.kernel.org/linux-hardening/Y0m9l52AKmw6Yxi1@hostpad/
- drivers/tty/Kconfig

Configuration References:
[1] - https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/drivers/tty/Kconfig#n149
[2] - https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/drivers/tty/Kconfig#n162
[3] - https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/drivers/tty/Kconfig#n188

To: Shuah Khan <shuah@kernel.org>
To: Nathan Chancellor <nathan@kernel.org>
To: Nick Desaulniers <nick.desaulniers+lkml@gmail.com>
To: Bill Wendling <morbo@google.com>
To: Justin Stitt <justinstitt@google.com>
To: Paul Moore <paul@paul-moore.com>
To: Stephen Smalley <stephen.smalley.work@gmail.com>
To: Ondrej Mosnacek <omosnace@redhat.com>
Cc: linux-kernel@vger.kernel.org
Cc: linux-kselftest@vger.kernel.org
Cc: llvm@lists.linux.dev
Cc: selinux@vger.kernel.org

Signed-off-by: Abhinav Saxena <xandfury@gmail.com>
---
Abhinav Saxena (2):
      selftests/tty: add TIOCSTI test suite
      selinux: add capability checks for TIOCSTI ioctl

 security/selinux/hooks.c                       |   6 +
 tools/testing/selftests/tty/Makefile           |   6 +-
 tools/testing/selftests/tty/config             |   1 +
 tools/testing/selftests/tty/tty_tiocsti_test.c | 421 +++++++++++++++++++++++++
 4 files changed, 433 insertions(+), 1 deletion(-)
---
base-commit: 5adb635077d1b4bd65b183022775a59a378a9c00
change-id: 20250618-toicsti-bug-7822b8e94a32

Best regards,
-- 
Abhinav Saxena <xandfury@gmail.com>

