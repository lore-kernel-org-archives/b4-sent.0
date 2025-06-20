From: Abhinav Saxena <xandfury@gmail.com>
Subject: [PATCH SECURITY 0/2] TTY privilege escalation in TIOCSTI ioctl
Date: Thu, 19 Jun 2025 20:18:17 -0600
Message-Id: <20250619-toicsti-bug-v1-0-e02c73a55bcd@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOnEVGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDM0ML3ZL8zOTikkzdpNJ0XXMLI6Mki1RLk0RjIyWgjoKi1LTMCrBp0bG
 1tQCzEgrRXQAAAA==
To: security@kernel.org
Cc: Abhinav Saxena <xandfury@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750385902; l=2829;
 i=xandfury@gmail.com; s=20250614; h=from:subject:message-id;
 bh=w3mKrOqvbnIn47DsAIi70rsx/Mr+UsENhzHWyacf7us=;
 b=4KiSj6HpRCc/VvazwpF6+tVI/Ez0ILPBnAV+xgL1/wB5rCkdaGL+qFY/+8WRwbJ5NwR6VFtFE
 h/Qe2W6mysEAgzIZwGlQaaHeyOvKV3luSCkAmz3AuwaeJl5J3HjKen7
X-Developer-Key: i=xandfury@gmail.com; a=ed25519;
 pk=YN6w7WNet8skqvMWxhG5BlAmtd1SQmo8If6Mofh4k44=
X-Endpoint-Received: by B4 Relay for xandfury@gmail.com/20250614 with auth_id=436
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TIOCSTI ioctl incorrectly uses only capable(CAP_SYS_ADMIN), which 
checks the current process's credentials instead of also checking the file 
opener's credentials stored in file->f_cred.

This creates a TOCTOU vulnerability where an unprivileged process 
can open a TTY fd and pass it to a privileged process via SCM_RIGHTS. 
The privileged process then inadvertently grants access based on its 
elevated privileges.

Problem Impact
==============

This vulnerability allows privilege escalation attacks where:
- Unprivileged processes can inject keystrokes into privileged terminals
- Container escape scenarios via terminal manipulation
- Bypass of intended access controls for TTY operations

Solution Approach
=================

This series addresses the vulnerability through SELinux LSM integration
rather than modifying core TTY credential checking to avoid potential
compatibility issues with existing userspace.

The fix adds proper current task and file credential capability 
validation in SELinux's selinux_file_ioctl() hook specifically for 
TIOCSTI operations.

Testing
=======

All patches have been validated using:
- scripts/checkpatch.pl --strict (0 errors, 0 warnings)
- Functional testing on kernel v6.16-rc2
- TOCTOU attack vector verification
- SELinux policy enforcement testing

The fd_passing_security test demonstrates the vulnerability.
To verify, disable legacy TIOCSTI and run the test:

$ echo "0" | sudo tee /proc/sys/dev/tty/legacy_tiocsti
$ sudo ./tools/testing/selftests/tty/tty_tiocsti_test -t fd_passing_security

Patch Overview
==============

PATCH 1/2: selftests/tty: add TIOCSTI test suite
Comprehensive test suite demonstrating the vulnerability and fix validation

PATCH 2/2: selinux: add capability checks for TIOCSTI ioctl
Core security fix via SELinux LSM hook

References
==========

- tty_ioctl(4) - documents TIOCSTI ioctl and capability requirements
- commit 83efeeeb3d04 ("tty: Allow TIOCSTI to be disabled")
- Documentation/security/credentials.rst
- https://github.com/KSPP/linux/issues/156
- https://lore.kernel.org/linux-hardening/Y0m9l52AKmw6Yxi1@hostpad/

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

