From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Wed, 25 Nov 2026 20:03:44 +0100
Subject: [PATCH 2/4] generic: check the size after a buffered write runs
 out of space
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-ntfs-reproducers-v1-2-0cc67533d803@proton.me>
References: <20261125-ntfs-reproducers-v1-0-0cc67533d803@proton.me>
In-Reply-To: <20261125-ntfs-reproducers-v1-0-0cc67533d803@proton.me>
To: fstests@vger.kernel.org, Zorro Lang <zlang@kernel.org>
Cc: ntfs@lists.linux.dev, Namjae Jeon <linkinjeon@kernel.org>, 
 Hyunchul Lee <hyc.lee@gmail.com>, Zhan Xusheng <zhanxusheng1024@gmail.com>, 
 Ernest Borowski <ernest.borowski.git@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3635;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=Iujrk+gE3XdVg5UO9fzbHHtWGauDODtpqe4fePza+TE=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmx2Q762Sxv5JWNCpTXc/5Re46xIucD94sTt1lP8k65dU
 WI9VS3dUcrCIMbFICumyNLx/0aIT8i3T8vitPpg5rAygQxh4OIUgIl4aDAytHFb2vueKUr8bL+h
 mTd63gsWxyvWbH6MDMpabOmma9xUGf6ZpQfvW9z147x7KceUuCnSlqt/LFMRYlm6/Db3Asdnv0S
 YAQ==
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A buffered write that runs out of free space part way returns a short
count, and the file size has to end at the last byte it wrote. ntfs raises
the size to the end of the whole request before it copies anything and
keeps it after the copy stops early, so the file grows by a tail of zeroes
that the caller never wrote; "ntfs: trim the sizes after a short write" by
Zhan Xusheng, under review on the ntfs list, fixes that. Fill a 512 MiB
filesystem, free 256 KiB or more again, append eight times as much to a
file in one write(2), and check the size before and after a remount and the
contents of the file. generic/275 also runs a filesystem out of space with
writes, but only checks that some data was written.

Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 tests/generic/816     | 67 +++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/generic/816.out |  2 ++
 2 files changed, 69 insertions(+)

diff --git a/tests/generic/816 b/tests/generic/816
new file mode 100755
index 00000000..14432f13
--- /dev/null
+++ b/tests/generic/816
@@ -0,0 +1,67 @@
+#! /bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Copyright (c) 2026 Ernest Borowski <ernest.borowski.git@proton.me>.  All Rights Reserved.
+#
+# FS QA Test No. 816
+#
+# A buffered write that runs out of space part way must leave the file size
+# at the end of the bytes it wrote.  Fill a small filesystem, free a little
+# space again, append more than that to a file in one write(2), and check that
+# the size is the old size plus the count the write returned, before and after
+# a remount, and that the file holds the old data followed by the bytes
+# written.
+#
+. ./common/preamble
+_begin_fstest auto quick rw enospc
+
+. ./common/populate
+
+_fixed_by_fs_commit ntfs xxxxxxxxxxxx \
+	"ntfs: trim the sizes after a short write"
+
+_require_scratch
+_require_no_compress
+
+_scratch_mkfs_sized $((512 * 1024 * 1024)) >> $seqres.full 2>&1
+_scratch_mount
+
+blksz=$(_get_file_block_size $SCRATCH_MNT)
+unit=$((blksz > 65536 ? blksz : 65536))
+old=$((4 * unit))
+len=$((32 * unit))
+file=$SCRATCH_MNT/file
+
+$XFS_IO_PROG -f -c "pwrite -q -S 0x11 0 $old" -c fsync $file
+$XFS_IO_PROG -f -c "pwrite -q -S 0x33 0 $old" -c fsync $SCRATCH_MNT/spare
+_fill_fs $((64 * 1024 * 1024)) $SCRATCH_MNT/fill $blksz 0 >> $seqres.full 2>&1
+rm -f $SCRATCH_MNT/spare
+_scratch_sync
+$DF_PROG $SCRATCH_MNT >> $seqres.full
+
+# One write(2) of $len bytes at the end of the file.  xfs_io prints the count
+# the write returned, or an error and no count when it wrote nothing.
+$XFS_IO_PROG -c "pwrite -S 0x22 -b $len $old $len" $file > $tmp.write 2>&1
+cat $tmp.write >> $seqres.full
+written=$(sed -n -e 's/^wrote \([0-9]*\)\/.*/\1/p' $tmp.write)
+written=${written:-0}
+[ $written -lt $len ] || _notrun "could not run the filesystem out of space"
+
+check_size()
+{
+	local size=$(_get_filesize $file)
+
+	[ $size -eq $((old + written)) ] || \
+		echo "$1: size $size after writing $written bytes at $old"
+}
+
+check_size "after the write"
+_scratch_cycle_mount
+check_size "after remount"
+
+$XFS_IO_PROG -f -c "pwrite -q -S 0x11 0 $old" $tmp.expected
+[ $written -gt 0 ] && \
+	$XFS_IO_PROG -c "pwrite -q -S 0x22 $old $written" $tmp.expected
+cmp -s $file $tmp.expected || echo "file contents differ"
+
+echo "Silence is golden"
+_exit 0
diff --git a/tests/generic/816.out b/tests/generic/816.out
new file mode 100644
index 00000000..a9d8f943
--- /dev/null
+++ b/tests/generic/816.out
@@ -0,0 +1,2 @@
+QA output created by 816
+Silence is golden

-- 
2.56.1

