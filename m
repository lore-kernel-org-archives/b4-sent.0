From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Subject: [PATCH 0/7] Fix probe placement in LLVM lld-linked objects by
 using file offsets
Date: Thu, 15 Oct 2026 03:53:40 +0000
Message-Id: <20261015-bug001-uprobe-file-offset-v1-0-bf4c53af8f39@d-matrix.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBG4auUWTuQFBvRq4iLJvlTR6QpmUaE0
 rsbdfkt3ttIUQRKl26jgpeo5LnBHjoK93GewBKbqTe9s8YO7OtkjOW6lOzBSZ7gnJJi5XByxyH
 CxWjO1PqlIMn7977e/tbqHwjrd0j7/gEqIlHvfQAAAA==
X-Change-ID: 20261015-bug001-uprobe-file-offset-c7645de6dd09
To: dtrace@lists.linux.dev
Cc: dtrace-devel@oss.oracle.com, Kris Van Hees <kris.van.hees@oracle.com>, 
 Alan Maguire <alan.maguire@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792036450; l=3296;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=jJJvlFGOD7zyaP8PKItehBzxJge5Uh8UV0NujqFwbDI=;
 b=qors4Uq55z+RzkOZuyb41pQ/lRchGZpTXQfRgBgt20RcKwk7wxw3Y+HoTm+1UHSi18bQZH0JY
 b6G47lt6p78DEBN0OEH5AFFIvyCXR3NCRD68MFs9/Daofh9X5BcYquL
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DTrace places uprobes by (inode, file offset), but computes the offset
of pid, USDT and dtrace provider probes as the address's distance from
the object's first segment.  The two coincide in GNU ld's default
layout.  LLVM lld packs segments in the file, so its text segment's
p_vaddr - p_offset is 0x1000 larger than the first segment's, and on
lld-linked objects, every such probe is placed 0x1000 bytes past its
target.  It then never fires, fires in other code, puts a breakpoint
inside an instruction, or makes enabling fail with ENOTSUPP (currently
reported as EBADF).  If libdtrace itself is linked by lld (not a
documented build option), dtrace:::BEGIN never fires and every session
hangs.

Patch 1 keeps each mapping's file offset, which libproc already parses.
Patches 2, 4 and 6 convert through the containing mapping in the pid,
USDT and dtrace providers, and patches 3, 5 and 7 add a test for each;
the three fixes depend only on patch 1.  Offsets in GNU ld objects do
not change, and dtprobed needs no change for these objects.

Tested on devel 61fea621, building after each fix, with libdtrace linked
by GNU ld and by lld: each test fails before its fix and passes after,
and the tests reject three plausible wrong fixes: subtracting a constant
0x1000, dropping the file offset, and handling only the main executable.
The pid/, usdt/, begin/ and end/ tests show no other change.  The whole
series gives the same results on dev-queue 0e93872f.

dt_cg_elf_sym_to_offset() in Alan's pending uresolve() series [1]
computes uprobe offsets as distances from the first segment, like the
code patch 2 replaces, so it needs the same change if both are applied.

[1] https://lore.kernel.org/dtrace/20260605221217.1211791-5-alan.maguire@oracle.com/

---
Eslam Almorshdy (7):
      libproc: keep the file offset of each mapping
      pid: place uprobes by file offset
      test: add pid probe placement test for lld-linked objects
      usdt: place uprobes by file offset
      test: add USDT probe placement test for lld-linked objects
      dtrace provider: place uprobes by file offset
      test: add dtrace provider probe placement test for lld-linked objects

 include/sys/sol_procfs.h                    |   1 +
 libdtrace/dt_pid.c                          |  49 +++++++++++--
 libdtrace/dt_prov_dtrace.c                  |  10 +--
 libproc/Psymtab.c                           |   1 +
 test/unittest/begin/tst.begin-end-offset.r  |   1 +
 test/unittest/begin/tst.begin-end-offset.sh |  87 +++++++++++++++++++++++
 test/unittest/pid/tst.lld-offset.r          |   1 +
 test/unittest/pid/tst.lld-offset.sh         |  59 ++++++++++++++++
 test/unittest/pid/tst.lld-offset.x          |  14 ++++
 test/unittest/usdt/tst.lld-offset.r         |   1 +
 test/unittest/usdt/tst.lld-offset.sh        | 104 ++++++++++++++++++++++++++++
 test/unittest/usdt/tst.lld-offset.x         |  14 ++++
 test/utils/Build                            |   2 +-
 test/utils/linkers.sh                       |  21 ++++++
 14 files changed, 355 insertions(+), 10 deletions(-)
---
base-commit: 61fea621160ea4b6302874c62a723da105b44883
change-id: 20261015-bug001-uprobe-file-offset-c7645de6dd09

Best regards,
--  
Eslam Almorshdy <ealmorshdy@d-matrix.ai>

