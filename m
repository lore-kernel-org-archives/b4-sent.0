From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Subject: [PATCH 0/2] Fix a readlink() typo in Psystem_daemon()
Date: Wed, 18 Nov 2026 23:25:03 +0000
Message-Id: <20261118-b4-bug008-daemon-readlink-v1-0-187c9eb22d11@d-matrix.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw6CMBBG4Vchs3aSDlUkvopx0csPjpdiWjEmh
 He36vJbnLNQQVYUOjQLZby06JQqZNNQOLs0gjVWU2vaTkR69lv282hMz9HhPiXOcPGm6crdHtY
 asYMPO6r9I2PQ9+99PP1dZn9BeH6HtK4fMroavH0AAAA=
X-Change-ID: 20261118-b4-bug008-daemon-readlink-67e33013fbc5
To: dtrace@lists.linux.dev
Cc: Kris Van Hees <kris.van.hees@oracle.com>, 
 Nick Alcock <nix@esperi.org.uk>, Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795044315; l=1094;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=QVx+rfvL5K2vWv/q7g97wjpaXyyF8t8/XuIKwtxhIQg=;
 b=ZPwTsbCa7BBJ/n53UWuPLJrpzdvZCAUEKqYyLtZ40shi/lKRB7EKgEbgV4k30hTO3DSlO21EC
 VFpLA0MfATcDfvr9rWKE0InD+wCvRSg9PjFijsHR2yonxchGuBkrLsd
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Psystem_daemon() tests readlink() == 0, but readlink() returns the
number of bytes stored or -1, so the "regular file outside /var" rule
never applied: every root process without a terminal was a system
daemon wherever systemd doesn't decide.

Patch 1 is the one-character fix.  Patch 2 adds a test that hides
/run/systemd with unshare, so the rule is exercised on systemd hosts
too.  On systems without systemd Patch 1 also turns pid/tst.emptystack,
tst.float, tst.manypids and tst.probemod green.

---
Eslam Almorshdy (2):
      libproc: fix readlink() typo in Psystem_daemon()
      test: add test for system daemons with regular files as streams

 libproc/Pcontrol.c                            |  2 +-
 test/unittest/proc/tst.system-daemon-files.r  |  2 +
 test/unittest/proc/tst.system-daemon-files.sh | 94 +++++++++++++++++++++++++++
 3 files changed, 97 insertions(+), 1 deletion(-)
---
base-commit: 61fea621160ea4b6302874c62a723da105b44883
change-id: 20261118-b4-bug008-daemon-readlink-67e33013fbc5

Best regards,
--  
Eslam Almorshdy <ealmorshdy@d-matrix.ai>

