From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 08 Oct 2026 16:39:33 +0900
Subject: [PATCH] ext4: test reads after a failed zeroout of an unwritten
 extent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-ext4-zeroout-eio-test-v1-1-9bb66deaf646@samsung.com>
X-B4-Tracking: v=1; b=H4sIALRIx2oC/x2MTQ5AMBQGryJv7SWt+IuriEXx4W1U2pKGuLvGb
 mYx85CHE3jqsoccLvFi9yQ6z2jazL6CZU5OhSpqrVTLiKHkG87aMzDEcoBPgKYeYZSpdEOpPRw
 Wif+3H973AyG9aZpnAAAA
To: fstests@vger.kernel.org
Cc: linux-ext4@vger.kernel.org, Zorro Lang <zlang@kernel.org>, 
 Ojaswin Mujoo <ojaswin@linux.ibm.com>, Jan Kara <jack@suse.cz>, 
 Theodore Ts'o <tytso@mit.edu>, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791445172; l=5273;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=q6mMATYv2ME98koxg+DZiicKe/k0E2HaDFj4GdEIBcM=;
 b=9mN9Mmc+vUiM2AX1wNHA5KSYYHDaXJMJRcHJucyz2+FajjDU7cJ3Wx+LQ4skO4W5scpchnQXo
 ireUp4ZwBmiAIOLazd1rrVxCGT6G9G/vQsGqyr9Jc8finYibUPnEeqS
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a write converts part of a small unwritten extent, ext4 may zero
out the rest of the extent and convert all of it to written. If that
zeroout fails, ext4 falls back to splitting the extent, but it cached
the blocks it failed to zero out as written in the extent status tree,
so reads of those blocks returned the old contents of the disk.

Make the zeroout fail with dm-error and check that those blocks still
read back as zeroes. The test mounts with dioread_lock and nodelalloc:
with the default dioread_nolock, the extent stays unwritten until the
I/O completes and is converted then, without this zeroout. generic/250
and generic/252 do not hit it either, as they write with direct I/O
while dm-error is loaded, which also leaves the extent unwritten.

The kernel fix is "ext4: don't cache unzeroed blocks as written after a
failed zeroout".

Link: https://lore.kernel.org/r/20261008-ext4-fc-zeroout-v2-1-55cab1e24fa3@samsung.com
Suggested-by: Ojaswin Mujoo <ojaswin@linux.ibm.com>
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
The kernel fix is 1/2 of the series in the Link: and is not merged yet,
hence xxxxxxxxxxxx in _fixed_by_kernel_commit. The test number may need
to change.

Tested in QEMU on ext4 dev 9091c97be340. Without the fix, blocks 1-7
read back as 0x53 with 1k, 4k and 64k blocks. With the fix, alone or
with the rest of the series, the test passes, also with -O fast_commit.
---
 tests/ext4/309     | 87 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/ext4/309.out |  5 ++++
 2 files changed, 92 insertions(+)

diff --git a/tests/ext4/309 b/tests/ext4/309
new file mode 100755
index 0000000..1fafd58
--- /dev/null
+++ b/tests/ext4/309
@@ -0,0 +1,87 @@
+#! /bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Copyright (c) 2026 Samsung Electronics Co., Ltd. All Rights Reserved.
+#
+# FS QA Test No. 309
+#
+# When a write converts part of a small unwritten extent, ext4 may zero out
+# the rest of the extent and convert all of it to written. If that zeroout
+# fails, it falls back to splitting the extent, but it used to cache the
+# blocks it failed to zero out as written in the extent status tree, so
+# reading them returned the old contents of the disk. Fail the zeroout with
+# dm-error and check that those blocks still read back as zeroes.
+#
+. ./common/preamble
+_begin_fstest auto quick rw prealloc eio
+
+_cleanup()
+{
+	cd /
+	rm -f $tmp.*
+	_dmerror_cleanup
+}
+
+. ./common/dmerror
+
+_require_scratch
+_require_dm_target error
+_require_xfs_io_command "falloc"
+_require_xfs_io_command "fiemap"
+_require_scratch_ext4_feature_enabled "extent"
+
+_fixed_by_kernel_commit xxxxxxxxxxxx \
+	"ext4: don't cache unzeroed blocks as written after a failed zeroout"
+
+# The zeroout is done when a write converts the extent itself. With the
+# default dioread_nolock, the extent stays unwritten until the I/O completes,
+# so mount with dioread_lock, and with nodelalloc to convert the extent at
+# write time.
+mount_dioread_lock()
+{
+	_dmerror_mount -o nodelalloc,dioread_lock >> $seqres.full 2>&1 || \
+		_fail "mount failed"
+}
+
+_scratch_mkfs >> $seqres.full 2>&1
+_dmerror_init
+mount_dioread_lock
+
+nblks=8
+blksz=$(_get_file_block_size $SCRATCH_MNT)
+sects_per_blk=$((blksz / 512))
+file=$SCRATCH_MNT/file
+
+$XFS_IO_PROG -f -c "falloc 0 $((nblks * blksz))" -c fsync $file >> $seqres.full
+extent="$($XFS_IO_PROG -c "fiemap -v" $file | grep "^[[:space:]]*0:")"
+echo "$extent" >> $seqres.full
+phys=$(echo "$extent" | $AWK_PROG '{print $3}' | sed -e 's/\.\..*//')
+len=$(echo "$extent" | $AWK_PROG '{print $4}')
+flags=$(echo "$extent" | $AWK_PROG '{print $5}')
+flags=${flags:-0}
+test "$len" = $((nblks * sects_per_blk)) -a $((flags & 0x800)) -ne 0 || \
+	_notrun "could not allocate one unwritten extent of $nblks blocks"
+
+# Put something other than zeroes in the unwritten blocks
+_dmerror_unmount
+$XFS_IO_PROG -d \
+	-c "pwrite -S 0x53 -b $blksz $((phys * 512)) $((nblks * blksz))" \
+	$DMERROR_DEV >> $seqres.full
+mount_dioread_lock
+
+# Writing block 0 zeroes out the rest of the extent if the whole extent fits
+# in extent_max_zeroout_kb, which mount resets; make that zeroout fail.
+_set_fs_sysfs_attr $DMERROR_DEV extent_max_zeroout_kb $((nblks * blksz / 1024))
+_dmerror_reset_table
+_dmerror_mark_range_bad $((phys + sects_per_blk)) \
+	$(((nblks - 1) * sects_per_blk))
+_dmerror_load_error_table
+$XFS_IO_PROG -c "pwrite -S 0x41 0 $blksz" -c fsync $file >> $seqres.full
+_dmerror_load_working_table
+
+echo "block 0:"
+od -An -v -tx1 -N $blksz $file | sort -u
+echo "blocks 1-$((nblks - 1)):"
+od -An -v -tx1 -j $blksz $file | sort -u
+
+# success, all done
+_exit 0
diff --git a/tests/ext4/309.out b/tests/ext4/309.out
new file mode 100644
index 0000000..19ed3d6
--- /dev/null
+++ b/tests/ext4/309.out
@@ -0,0 +1,5 @@
+QA output created by 309
+block 0:
+ 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41
+blocks 1-7:
+ 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

---
base-commit: 22348afe338c0f6d540c0d7ef0db749eaa51b218
change-id: 20261008-ext4-zeroout-eio-test-ee76bea0a517

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

