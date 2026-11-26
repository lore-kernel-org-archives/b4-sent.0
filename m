From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Thu, 26 Nov 2026 21:29:25 +0100
Subject: [PATCH v2 2/4] generic: check the size after a buffered write runs
 out of space
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-ntfs-reproducers-v2-2-7d5fa5a688b9@proton.me>
References: <20261126-ntfs-reproducers-v2-0-7d5fa5a688b9@proton.me>
In-Reply-To: <20261126-ntfs-reproducers-v2-0-7d5fa5a688b9@proton.me>
To: fstests@vger.kernel.org, Zorro Lang <zlang@kernel.org>
Cc: ntfs@lists.linux.dev, Namjae Jeon <linkinjeon@kernel.org>, 
 Hyunchul Lee <hyc.lee@gmail.com>, Zhan Xusheng <zhanxusheng1024@gmail.com>, 
 Ernest Borowski <ernest.borowski.git@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5135;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=lnpV2z8fc1PLEC20/FZcqZnQe83YXlORyjSto2dz+SE=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmyOaUsY3eIjXNmcE/8YyN1XYS7aWmWSo/D8t2riv4/lR
 W0x/hs7SlkYxLgYZMUUWTr+3wjxCfn2aVmcVh/MHFYmkCEMXJwCMJGfSxkZjinVbHleeP+F4gOx
 veeE5m9dvtw1e+4EPru35y1eG1heN2RkmBbL8+GbyfTN83avFF5pOVty0ff4C61mzd36O5Ik/0V
 /4gIA
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
filesystem, free 256 KiB or more again, write eight times as much to a file
in one write(2) that starts 64 KiB or one block before the end of the file,
and check the size before and after a remount and the contents of the file.
XFS and ext4 reserve space for all of a new range at once, so a write that
started at the end of the file failed there with nothing written; this one
stores the part over the old data and comes up short. A write error other
than ENOSPC fails the test, and a
write that fails with ENOSPC before storing anything is checked the same
way but then reported as not run. generic/275 also runs a filesystem out of
space with writes, but only checks that some data was written.

Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 tests/generic/816     | 91 +++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/generic/816.out |  2 ++
 2 files changed, 93 insertions(+)

diff --git a/tests/generic/816 b/tests/generic/816
new file mode 100755
index 00000000..625a8429
--- /dev/null
+++ b/tests/generic/816
@@ -0,0 +1,91 @@
+#! /bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Copyright (c) 2026 Ernest Borowski <ernest.borowski.git@proton.me>.  All Rights Reserved.
+#
+# FS QA Test No. 816
+#
+# A buffered write that runs out of space part way must leave the file size
+# at the end of the bytes it wrote.  Fill a small filesystem, free a little
+# space again, and write more than that to a file in one write(2) that starts
+# a little before the end of the file and goes past it.  Check that the size
+# ends at the end of the old data or of the bytes the write returned,
+# whichever is further, before and after a remount, and that the file holds
+# the old data with the bytes written over it.
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
+_scratch_mkfs_sized $((512 * 1024 * 1024)) >> "$seqres.full" 2>&1
+_scratch_mount
+
+blksz=$(_get_file_block_size "$SCRATCH_MNT")
+unit=$((blksz > 65536 ? blksz : 65536))
+old=$((4 * unit))
+len=$((32 * unit))
+# The write starts inside the old data: a filesystem that reserves space for
+# all of a new range at once, as XFS does, then still stores the part over
+# allocated blocks and comes up short instead of failing with nothing written.
+pos=$((old - unit))
+file=$SCRATCH_MNT/file
+
+$XFS_IO_PROG -f -c "pwrite -q -S 0x11 0 $old" -c fsync "$file"
+$XFS_IO_PROG -f -c "pwrite -q -S 0x33 0 $old" -c fsync "$SCRATCH_MNT/spare"
+_fill_fs $((64 * 1024 * 1024)) "$SCRATCH_MNT/fill" "$blksz" 0 >> "$seqres.full" 2>&1
+rm -f "$SCRATCH_MNT/spare"
+_scratch_sync
+$DF_PROG "$SCRATCH_MNT" >> "$seqres.full"
+
+# One write(2) of $len bytes at $pos.  xfs_io prints the count
+# the write returned, or the error when the write failed.  ENOSPC before the
+# first byte is checked like a short write of zero bytes, any other error
+# fails the test.
+$XFS_IO_PROG -c "pwrite -S 0x22 -b $len $pos $len" "$file" > "$tmp.write" 2>&1
+cat "$tmp.write" >> "$seqres.full"
+written=$(sed -n -e 's/^wrote \([0-9]*\)\/.*/\1/p' "$tmp.write")
+if [ -z "$written" ]; then
+	grep -q "No space left on device" "$tmp.write" || \
+		_fail "write failed: $(cat "$tmp.write")"
+	written=0
+fi
+[ "$written" -lt "$len" ] || _notrun "could not run the filesystem out of space"
+
+end=$((pos + written > old ? pos + written : old))
+errors=0
+check_size()
+{
+	local size
+
+	size=$(_get_filesize "$file")
+	[ "$size" -eq "$end" ] && return
+	echo "$1: size $size after writing $written bytes at $pos"
+	errors=$((errors + 1))
+}
+
+check_size "after the write"
+# shellcheck disable=SC2119 # the mount options argument is optional
+_scratch_cycle_mount
+check_size "after remount"
+
+$XFS_IO_PROG -f -c "pwrite -q -S 0x11 0 $old" "$tmp.expected"
+[ "$written" -gt 0 ] && \
+	$XFS_IO_PROG -c "pwrite -q -S 0x22 $pos $written" "$tmp.expected"
+if ! cmp -s "$file" "$tmp.expected"; then
+	echo "file contents differ"
+	errors=$((errors + 1))
+fi
+
+# A write that failed before storing anything must not change the file either,
+# but it did not test a short write.
+[ "$written" -eq 0 ] && [ "$errors" -eq 0 ] && \
+	_notrun "the write failed with ENOSPC before storing anything"
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

