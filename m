From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 08 Oct 2026 19:18:24 +0900
Subject: [PATCH v2] generic: test that preallocated blocks still read
 zeroes after I/O errors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-ext4-zeroout-eio-test-v2-1-883ac28de4cf@samsung.com>
X-B4-Tracking: v=1; b=H4sIAO9tx2oC/4WNQQ6CMBBFr0Jm7ZiWYFFX3sOwaGGAWUBNpzQo4
 e5WLuDuv5/89zcQCkwC92KDQImF/ZyhPBXQjnYeCLnLDKUqjVbqirTGCj8UvF8iEnuMJDlQbRx
 ZZS+6hrx9Bep5PbzPJvPIEn14HzdJ/9p/xqRR4805YzqyvanMQ+wkyzycWz9Bs+/7F//tTZ+8A
 AAA
To: fstests@vger.kernel.org
Cc: linux-ext4@vger.kernel.org, Zorro Lang <zlang@kernel.org>, 
 Christoph Hellwig <hch@infradead.org>, 
 Ojaswin Mujoo <ojaswin@linux.ibm.com>, Jan Kara <jack@suse.cz>, 
 Theodore Ts'o <tytso@mit.edu>, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791454703; l=6468;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=bQ9R3OIOFgPENEMm5FZziQo5b0dVQOH5X5ABnSjdIRU=;
 b=4yudI3ooTojxPcpGuXzftjwu0HiF+LVdly7MhZ4z4WRwXqssiC6zC+vvjXDbhTbZaQb5nWrWz
 3QgG7ZBfJ3PCd6p/Hd0y3czUV8LO20C5eAZZUrg3tQotFXRelON4tRw
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Write one block of a preallocated range while I/O to the rest of the
range fails, and check that the rest still reads back as zeroes rather
than the old contents of the disk.

ext4 got this wrong. When a write converts part of a small unwritten
extent, ext4 may zero out the rest of the extent and convert all of it
to written. If that zeroout fails, ext4 falls back to splitting the
extent, but it cached the blocks it failed to zero out as written in the
extent status tree, so reads of those blocks returned the old contents
of the disk.

On ext4 the test mounts with dioread_lock and nodelalloc and sets
extent_max_zeroout_kb to get into that path: with the default
dioread_nolock, the extent stays unwritten until the I/O completes and
is converted then, without this zeroout. generic/250 and generic/252 do
not hit it either, as they write with direct I/O while dm-error is
loaded, which also leaves the extent unwritten. btrfs is excluded, as
fiemap does not report device offsets there.

The ext4 fix is "ext4: don't cache unzeroed blocks as written after a
failed zeroout".

Link: https://lore.kernel.org/r/20261008-ext4-fc-zeroout-v2-1-55cab1e24fa3@samsung.com
Suggested-by: Ojaswin Mujoo <ojaswin@linux.ibm.com>
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
The ext4 fix is 1/2 of the series in the Link: and is not merged yet,
hence xxxxxxxxxxxx in _fixed_by_fs_commit. The test number may need to
change.

Tested in QEMU. On ext4 dev 9091c97be340 without the fix, blocks 1-7
read back as 0x53. With the fix, alone or with the rest of the series,
the test passes with 1k and 4k blocks. It passes on xfs with 1k and 4k
blocks.
---
Changes in v2:
- Make it a generic test (Christoph). The ext4 mount options and
  extent_max_zeroout_kb are set only on ext4. btrfs is excluded, as
  fiemap does not report device offsets there, and xfs gets the zoned
  and realtime handling of generic/791.
- Link to v1: https://lore.kernel.org/r/20261008-ext4-zeroout-eio-test-v1-1-9bb66deaf646@samsung.com
---
 tests/generic/806     | 106 ++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/generic/806.out |   5 +++
 2 files changed, 111 insertions(+)

diff --git a/tests/generic/806 b/tests/generic/806
new file mode 100755
index 0000000..8991b6e
--- /dev/null
+++ b/tests/generic/806
@@ -0,0 +1,106 @@
+#! /bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Copyright (c) 2026 Samsung Electronics Co., Ltd. All Rights Reserved.
+#
+# FS QA Test No. 806
+#
+# Write one block of a preallocated range while I/O to the rest of the range
+# fails, then check that the rest still reads back as zeroes, not as the old
+# contents of the disk.
+#
+# ext4 zeroes out the rest of a small unwritten extent when a write converts
+# part of it. When that zeroout failed, it fell back to splitting the extent,
+# but it cached the blocks it failed to zero out as written in the extent
+# status tree, so reading them returned the old contents of the disk.
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
+# The test writes to the device at the offsets fiemap reports, which are not
+# device offsets on btrfs.
+_exclude_fs btrfs
+
+_require_scratch
+_require_dm_target error
+_require_xfs_io_command "falloc"
+_require_xfs_io_command "fiemap"
+test $FSTYP = ext4 && _require_scratch_ext4_feature_enabled "extent"
+
+_fixed_by_fs_commit ext4 xxxxxxxxxxxx \
+	"ext4: don't cache unzeroed blocks as written after a failed zeroout"
+
+_scratch_mkfs >> $seqres.full 2>&1
+
+# dm-error table sizes need zone alignment on zoned devices, and the check
+# needs a mounted file system.
+_scratch_mount
+test $FSTYP = xfs && _require_xfs_scratch_non_zoned
+_scratch_unmount
+
+# ext4 does the zeroout when a write converts the extent itself. With the
+# default dioread_nolock, the extent stays unwritten until the I/O completes,
+# so mount with dioread_lock, and with nodelalloc to convert the extent at
+# write time.
+mount_opts=
+test $FSTYP = ext4 && mount_opts="-o nodelalloc,dioread_lock"
+
+do_mount()
+{
+	_dmerror_mount $mount_opts >> $seqres.full 2>&1 || _fail "mount failed"
+	test $FSTYP = xfs && _xfs_force_bdev data $SCRATCH_MNT
+}
+
+_dmerror_init
+do_mount
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
+# Put something other than zeroes in the preallocated blocks
+_dmerror_unmount
+$XFS_IO_PROG -d \
+	-c "pwrite -S 0x53 -b $blksz $((phys * 512)) $((nblks * blksz))" \
+	$DMERROR_DEV >> $seqres.full
+do_mount
+
+# ext4 zeroes out the rest of the extent if the whole extent fits in
+# extent_max_zeroout_kb, which mount resets.
+test $FSTYP = ext4 && _set_fs_sysfs_attr $DMERROR_DEV \
+	extent_max_zeroout_kb $((nblks * blksz / 1024))
+
+# Fail I/O to blocks 1 to the end of the range and write block 0
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
diff --git a/tests/generic/806.out b/tests/generic/806.out
new file mode 100644
index 0000000..84b3a35
--- /dev/null
+++ b/tests/generic/806.out
@@ -0,0 +1,5 @@
+QA output created by 806
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

