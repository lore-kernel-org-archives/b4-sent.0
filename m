From: Peter Lamberg <kernel@pelam.fi>
Date: Wed, 04 Nov 2026 22:35:39 +0200
Subject: [PATCH v2] btrfs: test that a resumed snapshot deletion keeps its
 drop progress
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-btrfs-355-v2-1-4b1ec6c23c44@pelam.fi>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ6CMBAAv0L2bE23BYOe/Ifh0NatrFEg3Uo0h
 L8LePU4yWRmAqHEJHAqJkg0snDfLWB2BYTWdTdSfF0YjDYHRG2VzymKslWlMKD1jpwu6wCLPyS
 K/N5al+bH8vJ3CnkNrEbLkvv02WYjrt6/7ogKVfTaWe3LY239eaCHe+4jQzPP8xds7wHnswAAA
 A==
X-Change-ID: 20261103-btrfs-355-1c13baea048c
To: fstests@vger.kernel.org
Cc: quwenruo.btrfs@gmx.com, linux-btrfs@vger.kernel.org, fdmanana@suse.com, 
 asj@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793824549; l=8417;
 i=kernel@pelam.fi; s=20261103; h=from:subject:message-id;
 bh=6BolEpS0wnHLee4MIs6gKR0KwTGwm8SS4vQl94fYdOI=;
 b=LLGsVq9hcRprx0LQub2L/fxTg1BUZx6NQ0As0bCaeFiBrOFLATCy6sefhoWVZaFu2fj/g9BZz
 2zIRSEP7wcsDdB2ZTy28ghUzlwBe+7sZOam51H9BaOsvyJRSRMjdT9e
X-Developer-Key: i=kernel@pelam.fi; a=ed25519;
 pk=qpD/xh/xwDGEMdfQk/5prChHF0mXHXDTrs35FxiJgrk=
X-Endpoint-Received: by B4 Relay for kernel@pelam.fi/20261103 with auth_id=1398
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a partially dropped subvolume is resumed, btrfs_drop_snapshot()
can write drop_progress (0 0 0) back to the root item if a commit or
unmount happens before the resumed run drops its first reference. The
next run then restarts from the first slot and tries to free blocks
still shared with a snapshot again, and the transaction aborts with
"unable to find ref byte nr". See the kernel fix:

  "btrfs: keep drop_progress when resuming snapshot deletion"

The test builds a subvolume S1 with a level 3 tree (nodesize 4096,
30000 files with a 2000 byte inline extent each), takes a read-only
snapshot S2 and deletes S1. It unmounts once a root child has been
dropped, then does five quick mount/unmount cycles and checks that the
drop key never goes back to zero. Finally it lets the deletion finish
and, after a mount cycle, checks that S2's content is unchanged and
S1's root item is gone.

Without the fix the test fails on the first resume; with it the test
passes. It takes about 12 seconds on loop devices on a SATA SSD.

Assisted-by: LLM
Signed-off-by: Peter Lamberg <kernel@pelam.fi>
---
Kernel fix, sent to linux-btrfs:
https://lore.kernel.org/linux-btrfs/20261103-drop-progress-v1-1-16e345565109@pelam.fi/

Reproducers and logs: https://pelam.fi/btrfs-drop-progress/

v2 fails 3/3 on the stock Ubuntu 7.3.0-9-generic btrfs.ko and 3/3 on a
module built from the same source without the fix; it passes 3/3 with
the fix, 12-13 s on loop devices on a SATA SSD. Same 3/3 results with
the devices on tmpfs, 10-11 s. Also run with MKFS_OPTIONS="-s 4096":
fails without the fix, passes with it. It _notrun's if the tree stays
too shallow or the window is missed.

Without the fix the transaction aborts during the final deletion.
btrfs subvolume sync then returns because the fs went read-only
(btrfs-progs 7.1 here; the read-only check is in progs since 6.6.3).

_fixed_by_kernel_commit has a placeholder hash until the fix is merged.
The test number may need adjusting if 355 gets taken first.
---
Changes in v2, following Qu Wenruo's review:
- Add _require_btrfs_support_sectorsize 4096 and mkfs -s 4096.
- Fill S1 with 2000 byte inline extents instead of 3000 byte xattrs;
  drop _require_attrs. Still a level 3 tree with 30000 files (about
  31200 leaves), created with a plain shell loop.
- Read S1's root item with grep and sed instead of awk.
- Compare S2 before and after with md5sum instead of getfattr.
- drop_caches: keep only the one in the poll loop. Without it dump-tree
  read a stale root item while mounted (the loop saw drop key 6072, the
  key on disk after the unmount was 20592). Before the final md5sum a
  mount cycle replaces it, so S2 is read from disk.
- Wait for the deletion with filesystem sync + subvolume sync instead of
  timeout 600; drop _require_command timeout.

Other changes:
- _require_btrfs_inline_extents_creation; S1's id from _btrfs_get_subvolid
  instead of inspect-internal rootid.
- _notrun, not a silent pass, if the first run is not interrupted at the
  root level or the deletion finished before the first resume.

- Link to v1: https://lore.kernel.org/fstests/20261103-btrfs-355-v1-1-fb0a30b4983b@pelam.fi/
---
 tests/btrfs/355     | 127 ++++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/btrfs/355.out |   2 +
 2 files changed, 129 insertions(+)

diff --git a/tests/btrfs/355 b/tests/btrfs/355
new file mode 100755
index 00000000..7a272660
--- /dev/null
+++ b/tests/btrfs/355
@@ -0,0 +1,127 @@
+#! /bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Copyright (c) 2026 Peter Lamberg
+#
+# FS QA Test 355
+#
+# Test that a resumed snapshot deletion keeps its saved drop progress.
+#
+# If the drop progress is reset to zero on resume (a commit or unmount before
+# the resumed run drops its first reference), the next run restarts from the
+# first slot and tries to free blocks still shared with a snapshot again: the
+# transaction aborts with "unable to find ref byte nr".
+#
+. ./common/preamble
+_begin_fstest auto quick snapshot subvol
+
+_fixed_by_kernel_commit xxxxxxxxxxxx \
+	"btrfs: keep drop_progress when resuming snapshot deletion"
+
+_require_scratch
+_require_btrfs_support_sectorsize 4096
+_require_btrfs_inline_extents_creation
+_require_btrfs_command inspect-internal dump-tree
+
+# A 2000 byte inline extent per file gives about one 4K leaf per file, and a
+# 4K node holds up to 121 pointers. 30000 files give ~31200 leaves under ~268
+# level 1 nodes: a level 3 tree whose root has 3 children of 62, 120 and 86
+# pointers. Level 3 needs more than 121 level 1 nodes, i.e. ~14000 files.
+# The resumed drop has to walk a whole root child before it drops anything,
+# which is the window the second unmount must land in.
+nfiles=30000
+data=$(printf '%2000s' '')
+
+# Print S1's root item from the root tree, nothing once it is gone.
+s1_root_item()
+{
+	$BTRFS_UTIL_PROG inspect-internal dump-tree -t root $SCRATCH_DEV \
+		2>> $seqres.full | \
+		grep -A 4 "key ($s1_id ROOT_ITEM 0)"
+}
+
+# Print "<drop_progress objectid> <drop_level>" of S1, nothing once it is gone.
+drop_state()
+{
+	s1_root_item | \
+		sed -n 's/.*drop_progress key (\([0-9]*\) .* drop_level \([0-9]*\)$/\1 \2/p'
+}
+
+s2_digest()
+{
+	(cd $SCRATCH_MNT/S2 && find . -type f | sort | xargs md5sum | md5sum)
+}
+
+_scratch_mkfs -n 4096 -s 4096 >> $seqres.full 2>&1 || \
+	_notrun "mkfs with nodesize 4096 failed"
+_scratch_mount -o max_inline=2048,compress=none
+
+$BTRFS_UTIL_PROG subvolume create $SCRATCH_MNT/S1 >> $seqres.full
+for ((i = 0; i < nfiles; i++)); do
+	echo -n "$data" > $SCRATCH_MNT/S1/f$i
+done
+s1_id=$(_btrfs_get_subvolid $SCRATCH_MNT S1)
+
+# S2 shares every block of S1, S1 owns them.
+$BTRFS_UTIL_PROG subvolume snapshot -r $SCRATCH_MNT/S1 $SCRATCH_MNT/S2 \
+	>> $seqres.full
+$BTRFS_UTIL_PROG filesystem sync $SCRATCH_MNT
+digest_before=$(s2_digest)
+level=$(s1_root_item | sed -n 's/^\s*level \([0-9]*\) generation_v2.*/\1/p')
+echo "S1 id $s1_id root level $level files $nfiles" >> $seqres.full
+[ -n "$level" ] && [ $level -ge 3 ] || \
+	_notrun "S1 tree too shallow (level $level)"
+
+$BTRFS_UTIL_PROG subvolume delete $SCRATCH_MNT/S1 >> $seqres.full
+
+# First drop run: unmount once at least one root child has been dropped, so
+# the saved drop progress is non-zero and at the root level.
+for ((i = 0; i < 600; i++)); do
+	# dump-tree reads the device through its page cache, which goes stale
+	# while the fs is mounted
+	echo 3 > /proc/sys/vm/drop_caches
+	$BTRFS_UTIL_PROG filesystem sync $SCRATCH_MNT
+	read -r obj lvl < <(drop_state)
+	[ -z "$obj" ] && \
+		_notrun "subvolume deletion finished before it was interrupted"
+	[ "$obj" != 0 ] && [ "$lvl" = "$level" ] && break
+	sleep 0.1
+done
+[ "$obj" != 0 ] && [ "$lvl" = "$level" ] || \
+	_notrun "subvolume deletion did not progress to the root level"
+_scratch_unmount
+echo "first run interrupted at drop key ($obj) level $lvl" >> $seqres.full
+
+# Resumed runs, each interrupted right away. The saved progress must never go
+# back to zero.
+for ((i = 0; i < 5; i++)); do
+	_scratch_mount
+	_scratch_unmount
+	read -r obj lvl < <(drop_state)
+	echo "resume $i: drop key ($obj) level $lvl" >> $seqres.full
+	if [ -z "$obj" ]; then
+		[ $i = 0 ] && \
+			_notrun "S1 deletion finished before it was resumed"
+		break
+	fi
+	if [ "$obj" = 0 ]; then
+		echo "drop progress of the deleted subvolume reset to zero on resume"
+		break
+	fi
+done
+
+# Let the deletion finish. With a reset drop progress this tries to free blocks
+# still used by S2 again and the transaction aborts.
+_scratch_mount
+$BTRFS_UTIL_PROG filesystem sync $SCRATCH_MNT	# wakes the cleaner
+$BTRFS_UTIL_PROG subvolume sync $SCRATCH_MNT >> $seqres.full
+# Read S2 back from disk, not from the page cache filled by digest_before.
+_scratch_cycle_mount
+digest_after=$(s2_digest)
+[ "$digest_before" = "$digest_after" ] || \
+	echo "S2 content changed after deleting S1"
+_scratch_unmount
+[ -z "$(drop_state)" ] || echo "S1 deletion did not finish"
+
+echo "Silence is golden"
+status=0
+exit
diff --git a/tests/btrfs/355.out b/tests/btrfs/355.out
new file mode 100644
index 00000000..4e4c5e98
--- /dev/null
+++ b/tests/btrfs/355.out
@@ -0,0 +1,2 @@
+QA output created by 355
+Silence is golden



