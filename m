From: Peter Lamberg <kernel@pelam.fi>
Date: Tue, 03 Nov 2026 22:39:32 +0200
Subject: [PATCH] btrfs: test that a resumed snapshot deletion keeps its
 drop progress
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-btrfs-355-v1-1-fb0a30b4983b@pelam.fi>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrDXpKCKuIhZtDcYC6SAScXfF8
 iU//wKhwCRQJxcEOlh4mSMwTcCPdh5IcRcNmc5KRG2U20IvyhSFQo/GWbI6rzzEfg3U8/m9mva
 37G4iv70DuO8HglLW+20AAAA=
X-Change-ID: 20261103-btrfs-355-1c13baea048c
To: fstests@vger.kernel.org
Cc: linux-btrfs@vger.kernel.org, asj@kernel.org, fdmanana@suse.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793738376; l=7537;
 i=kernel@pelam.fi; s=20261103; h=from:subject:message-id;
 bh=vPs9slwRx0isQyVtBajLr+Y9W7onpaaZGuikppHgV+Y=;
 b=bvXxMmhlz5VyEKlugJi9fkHlbas74ZjjEkRhzEZWmAo9ZWrRZmFlELwkyrvEaTIhG87VPwkn9
 E6JqAyZLyDaDerRENUC+KKueC1PEDQ3G/vEwIuD6W+i2634zAp8xY+F
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
30000 files with one 3000 byte xattr each), takes a read-only snapshot
S2 and deletes S1. It unmounts once a root child has been dropped, then
does five quick mount/unmount cycles and checks that the drop key never
goes back to zero. Finally it lets the deletion finish and checks that
S2's content is unchanged and S1's root item is gone.

Without the fix the test fails on the first resume; with it the test
passes. It takes about 15 seconds on loop devices on a SATA SSD.

Assisted-by: LLM
Signed-off-by: Peter Lamberg <kernel@pelam.fi>
---
Kernel fix, sent to linux-btrfs:
https://lore.kernel.org/linux-btrfs/20261103-drop-progress-v1-1-16e345565109@pelam.fi/

Reproducers and logs: https://pelam.fi/btrfs-drop-progress/

btrfs/355 fails 3/3 on the stock Ubuntu 7.3.0-9-generic btrfs.ko and 3/3
on a module built from the same source without the fix; it passes 3/3
with the fix. About 15 s on a SATA SSD, 11-13 s with the devices on
tmpfs. It _notrun's if the tree stays too shallow or the window is
missed.

_fixed_by_kernel_commit has a placeholder hash until the fix is merged;
I'll send a v2 with the real one. The test number may need adjusting if
355 gets taken first.
---

---
 tests/btrfs/355     | 153 ++++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/btrfs/355.out |   2 +
 2 files changed, 155 insertions(+)

diff --git a/tests/btrfs/355 b/tests/btrfs/355
new file mode 100755
index 00000000..40e41c00
--- /dev/null
+++ b/tests/btrfs/355
@@ -0,0 +1,153 @@
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
+. ./common/attr
+. ./common/filter
+
+_fixed_by_kernel_commit xxxxxxxxxxxx \
+	"btrfs: keep drop_progress when resuming snapshot deletion"
+
+_require_scratch
+_require_attrs user
+_require_btrfs_command inspect-internal dump-tree
+_require_btrfs_command inspect-internal rootid
+_require_command "$TIMEOUT_PROG" timeout
+
+# One big user xattr per file gives roughly one 4K leaf per file. A level 2
+# node covers at most ~14600 leaves, so 30000 files make a level 3 tree with a
+# few root children of several thousand leaves each.
+# The resumed drop has to walk a whole such child before it drops anything,
+# which is the window the second unmount must land in.
+nfiles=30000
+per_dir=1000
+pad=$(printf '%3000s' '' | tr ' ' x)
+
+drop_caches()
+{
+	sync
+	echo 3 > /proc/sys/vm/drop_caches
+}
+
+# Print the S1 root item's "drop_progress objectid" and "drop_level", or
+# "ABSENT" if the root item is gone (deletion finished).
+drop_state()
+{
+	$BTRFS_UTIL_PROG inspect-internal dump-tree -t root $SCRATCH_DEV \
+		2>/dev/null | $AWK_PROG -v want=$s1_id '
+		/item [0-9]+ key \(/ {
+			split($0, a, "("); split(a[2], b, " "); cur = b[1]; next
+		}
+		cur == want && /drop_progress key/ {
+			match($0, /key \([0-9]+/); obj = substr($0, RSTART + 5, RLENGTH - 5)
+			match($0, /drop_level [0-9]+/); lvl = substr($0, RSTART + 11, RLENGTH - 11)
+			print obj, lvl; found = 1
+		}
+		END { if (!found) print "ABSENT" }'
+}
+
+root_level()
+{
+	$BTRFS_UTIL_PROG inspect-internal dump-tree -t root $SCRATCH_DEV \
+		2>/dev/null | $AWK_PROG -v want=$s1_id '
+		/item [0-9]+ key \(/ {
+			split($0, a, "("); split(a[2], b, " "); cur = b[1]; next
+		}
+		cur == want && /^[[:space:]]*level [0-9]+ generation_v2/ {
+			match($0, /level [0-9]+/); print substr($0, RSTART + 6, RLENGTH - 6); exit
+		}'
+}
+
+s2_digest()
+{
+	$GETFATTR_PROG --absolute-names -R -d -m user.pad $SCRATCH_MNT/S2 2>&1 | \
+		_filter_scratch | md5sum | cut -d' ' -f1
+}
+
+_scratch_mkfs -n 4096 >> $seqres.full 2>&1 || \
+	_notrun "mkfs with nodesize 4096 failed"
+_scratch_mount
+
+$BTRFS_UTIL_PROG subvolume create $SCRATCH_MNT/S1 >> $seqres.full
+for ((d = 0; d < nfiles / per_dir; d++)); do
+	dir=$SCRATCH_MNT/S1/d$d
+	mkdir $dir
+	(cd $dir && seq -f "f%04.0f" 0 $((per_dir - 1)) | xargs touch &&
+	 seq -f "f%04.0f" 0 $((per_dir - 1)) | \
+		xargs $SETFATTR_PROG -n user.pad -v "$pad") || \
+		_fail "populating S1 failed"
+done
+s1_id=$($BTRFS_UTIL_PROG inspect-internal rootid $SCRATCH_MNT/S1)
+
+# S2 shares every block of S1, S1 owns them.
+$BTRFS_UTIL_PROG subvolume snapshot -r $SCRATCH_MNT/S1 $SCRATCH_MNT/S2 \
+	>> $seqres.full
+$BTRFS_UTIL_PROG filesystem sync $SCRATCH_MNT
+digest_before=$(s2_digest)
+level=$(root_level)
+echo "S1 id $s1_id root level $level files $nfiles" >> $seqres.full
+[ -n "$level" ] && [ $level -ge 3 ] || \
+	_notrun "S1 tree too shallow (level $level)"
+
+$BTRFS_UTIL_PROG subvolume delete $SCRATCH_MNT/S1 >> $seqres.full
+drop_caches
+
+# First drop run: unmount once at least one root child has been dropped, so
+# the saved drop progress is non-zero and at the root level.
+for ((i = 0; i < 600; i++)); do
+	$BTRFS_UTIL_PROG filesystem sync $SCRATCH_MNT
+	read -r obj lvl < <(drop_state)
+	[ "$obj" = ABSENT ] && \
+		_notrun "subvolume deletion finished before it was interrupted"
+	[ "$obj" != 0 ] && [ "$lvl" = "$level" ] && break
+	# dump-tree reads through the block device page cache, which goes
+	# stale while the fs is mounted
+	drop_caches
+	sleep 0.1
+done
+[ "$obj" != 0 ] || _notrun "subvolume deletion made no progress"
+_scratch_unmount
+echo "first run interrupted at drop key ($obj) level $lvl" >> $seqres.full
+
+# Resumed runs, each interrupted right away. The saved progress must never go
+# back to zero.
+for ((i = 0; i < 5; i++)); do
+	drop_caches
+	_scratch_mount
+	_scratch_unmount
+	read -r obj lvl < <(drop_state)
+	echo "resume $i: drop key ($obj) level $lvl" >> $seqres.full
+	[ "$obj" = ABSENT ] && break
+	if [ "$obj" = 0 ]; then
+		echo "drop progress of the deleted subvolume reset to zero on resume"
+		break
+	fi
+done
+
+# Let the deletion finish. With a reset drop progress this tries to free blocks
+# still used by S2 again and the transaction aborts.
+_scratch_mount
+$TIMEOUT_PROG 600 $BTRFS_UTIL_PROG subvolume sync $SCRATCH_MNT \
+	>> $seqres.full 2>&1
+drop_caches
+digest_after=$(s2_digest)
+[ "$digest_before" = "$digest_after" ] || \
+	echo "S2 content changed after deleting S1"
+_scratch_unmount
+[ "$(drop_state)" = ABSENT ] || echo "S1 deletion did not finish"
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



