From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Wed, 25 Nov 2026 20:03:46 +0100
Subject: [PATCH 4/4] generic: test a short copy into a hole of reused
 blocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-ntfs-reproducers-v1-4-0cc67533d803@proton.me>
References: <20261125-ntfs-reproducers-v1-0-0cc67533d803@proton.me>
In-Reply-To: <20261125-ntfs-reproducers-v1-0-0cc67533d803@proton.me>
To: fstests@vger.kernel.org, Zorro Lang <zlang@kernel.org>
Cc: ntfs@lists.linux.dev, Namjae Jeon <linkinjeon@kernel.org>, 
 Hyunchul Lee <hyc.lee@gmail.com>, Zhan Xusheng <zhanxusheng1024@gmail.com>, 
 Ernest Borowski <ernest.borowski.git@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3906;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=nJ56RhZFyeHeI9JCtM7gckxJWIkuFTyzgjE4m6wLb+E=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmx2Q77UF21B5fv432RwSEmon0wM+CIvGn+E7d23fR9YY
 jZPqLvcUcrCIMbFICumyNLx/0aIT8i3T8vitPpg5rAygQxh4OIUgInI7GRkuLlDWefa7nRfj4kz
 cw4miyrL7Lhp0mf6SFi7YMb+yX9vNTL8lbV+0rqpSTfpV+CBV9/ONOcrdT84WHvqR/nrtbcTJwk
 cZAYA
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a buffered write into a hole stops part way through a block because
its source buffer runs into an unreadable page, only the bytes copied are
dirty. A filesystem that allocates in units larger than the blocks it
tracks as dirty, as ntfs does, has to zero the rest of the allocation, or
reads return what the reused clusters held before. On ntfs the rest of the
cluster read back the old file contents after an fsync and a remount, with
4 KiB and with 64 KiB clusters; the fix is "ntfs: zero the rest of a new
cluster after a short buffered write" from the ntfs delayed allocation
series, not merged yet. Free the blocks of a filled file by truncating it
to zero and back, write its last byte, write two and a half blocks into the
hole from a buffer that is readable for 1000, 5096 or 12800 bytes, and
compare the file with the expected contents after a remount.

Link: https://lore.kernel.org/all/20261124-b4-ntfs-delalloc-fixes-v2-0-f394c800ec03@proton.me/
Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 tests/generic/818     | 58 +++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/generic/818.out |  2 ++
 2 files changed, 60 insertions(+)

diff --git a/tests/generic/818 b/tests/generic/818
new file mode 100755
index 00000000..97c30767
--- /dev/null
+++ b/tests/generic/818
@@ -0,0 +1,58 @@
+#! /bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Copyright (c) 2026 Ernest Borowski <ernest.borowski.git@proton.me>.  All Rights Reserved.
+#
+# FS QA Test No. 818
+#
+# A buffered write into a hole whose copy from user space stops part way
+# through a block, because the source buffer runs into an unreadable page,
+# must leave everything it did not write reading as zeroes once the data is on
+# the disk.  The blocks the hole gets may have held data before, so a block
+# that is allocated but only partly written would expose that old data.
+#
+# Fill a file and fsync it, truncate it to zero and back to its size so that
+# its old blocks are free again, write its last byte, then write two and a
+# half blocks at a block boundary from a buffer with only part of it readable.
+# After an fsync and a remount the file must hold the bytes the write returned
+# and zeroes around them.
+#
+. ./common/preamble
+_begin_fstest auto quick rw
+
+_fixed_by_fs_commit ntfs xxxxxxxxxxxx \
+	"ntfs: zero the rest of a new cluster after a short buffered write"
+
+_require_scratch
+_require_test_program "pwrite-short-copy"
+
+_scratch_mkfs >> $seqres.full 2>&1
+_scratch_mount
+
+blksz=$(_get_file_block_size $SCRATCH_MNT)
+size=$((32 * blksz))
+off=$((8 * blksz))
+len=$((2 * blksz + blksz / 2))
+file=$SCRATCH_MNT/file
+
+# _scratch_cycle_mount sets $ret, so the write's result is kept in $written.
+# Short copies that end in the first, second and third block of the write.
+for copy in $((blksz / 4)) $((blksz + blksz / 4)) $((2 * blksz + blksz / 8)); do
+	$XFS_IO_PROG -f -c "pwrite -q -S 0xab 0 $size" -c fsync \
+		-c "truncate 0" -c "truncate $size" \
+		-c "pwrite -q -S 0x01 $((size - 1)) 1" $file
+	written=$($here/src/pwrite-short-copy $file $off $len $copy)
+	echo "copy $copy: write of $len bytes at $off returned $written" >> $seqres.full
+	$XFS_IO_PROG -c fsync $file
+	_scratch_cycle_mount
+
+	rm -f $tmp.expected
+	$XFS_IO_PROG -f -c "truncate $size" \
+		-c "pwrite -q -S 0x01 $((size - 1)) 1" $tmp.expected
+	[ "$written" -gt 0 ] && \
+		$XFS_IO_PROG -c "pwrite -q -S 0x5c $off $written" $tmp.expected
+	cmp -s $file $tmp.expected || \
+		echo "copy $copy: file contents differ after a short copy"
+done
+
+echo "Silence is golden"
+_exit 0
diff --git a/tests/generic/818.out b/tests/generic/818.out
new file mode 100644
index 00000000..cb099786
--- /dev/null
+++ b/tests/generic/818.out
@@ -0,0 +1,2 @@
+QA output created by 818
+Silence is golden

-- 
2.56.1

