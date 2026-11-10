From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 10 Nov 2026 09:38:24 +0900
Subject: [PATCH] xfs: test that swapext waits for in-flight direct I/O
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-xfs-swapext-dio-test-v1-1-ead6ea3e23f1@samsung.com>
X-B4-Tracking: v=1; b=H4sIAH9n8moC/x3MQQqAIBBA0avErBvQKLGuEi0sx5pNhSMlRHdPW
 r7F/w8IRSaBoXog0sXCx16g6wqWze0rIftiaFRjtFY95iAotzspJ/R8YCJJaOfeGtu51msFJT0
 jBc7/dpze9wMgO2BZZgAAAA==
To: Zorro Lang <zlang@kernel.org>, fstests@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, linux-xfs@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794271103; l=6049;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=ylPTRSWaZxLfITp48AQo3BS/GJN6yjbmiPbJVD9BHYM=;
 b=BJjlurFRKFPOIsqvCUq9/kQWgF6NqVSX1YbrnwvwdWVSrUrvIgzvpZb5RAa4IDSnyu5qFBdeG
 KAe7RSFL/WmBuP/o8N0a9z+3lnl+UikqKs6XeAMuyYHfZazE92hmj0t
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Test that XFS_IOC_SWAPEXT waits for in-flight direct I/O. A cgroup
io.max limit holds back an AIO direct write during the swap. When the
swap returns, the donor must already hold the write's data.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
The kernel fix is "xfs: wait for direct I/O before swapping extents",
posted to linux-xfs. Without it the test failed in 6 of 6 runs, 3 with
always_cow and 3 without. With it the test passed in 6 of 6 runs.
---
 tests/xfs/843     | 139 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/xfs/843.out |   2 +
 2 files changed, 141 insertions(+)

diff --git a/tests/xfs/843 b/tests/xfs/843
new file mode 100755
index 0000000..2a4ab53
--- /dev/null
+++ b/tests/xfs/843
@@ -0,0 +1,139 @@
+#! /bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Copyright (c) 2026 Samsung Electronics Co., Ltd. All Rights Reserved.
+#
+# FS QA Test No. 843
+#
+# Check that XFS_IOC_SWAPEXT waits for direct I/O that is still in flight.
+# An AIO direct write to the target is held back by a cgroup io.max limit
+# while the target's extents are swapped with a donor. When the swap
+# returns, the donor must already hold the write's data.
+#
+. ./common/preamble
+_begin_fstest auto quick swapext aio
+
+_cleanup()
+{
+	[ -n "$fio_pid" ] && wait $fio_pid > /dev/null 2>&1
+	if [ -n "$cgdir" ]; then
+		rmdir $cgdir/$seq-cg > /dev/null 2>&1
+		[ -n "$drop_io_cgroup" ] && \
+			echo "-io" > $cgdir/cgroup.subtree_control 2> /dev/null
+	fi
+	_unmount $SCRATCH_MNT > /dev/null 2>&1
+	[ -n "$loop_dev" ] && _destroy_loop_device $loop_dev > /dev/null 2>&1
+	cd /
+	rm -f $tmp.*
+}
+
+. ./common/cgroup2
+
+_require_scratch_nocheck
+_require_cgroup2 io
+_require_loop
+_require_block_device $SCRATCH_DEV
+_require_non_zoned_device $SCRATCH_DEV
+_require_xfs_io_command swapext
+_require_odirect
+_require_aio
+
+_fixed_by_kernel_commit xxxxxxxxxxxx \
+	"xfs: wait for direct I/O before swapping extents"
+
+filesize=$((1024 * 1024))
+# A 1 MiB write at this rate stays in the throttle for about 4 seconds.
+wbps=262144
+
+fio_config=$tmp.fio
+cat > $fio_config <<EOF
+[swapext-dio]
+filename=$SCRATCH_MNT/target
+ioengine=libaio
+direct=1
+rw=write
+bs=$filesize
+size=$filesize
+iodepth=1
+overwrite=1
+buffer_pattern=0x63
+EOF
+_require_fio $fio_config
+
+# io.max cannot be set on a partition, so use a loop device as generic/563
+# does.
+loopsize_mb=$(_small_fs_size_mb 256)
+_require_scratch_size_nocheck $((loopsize_mb * 1024))
+loop_dev=$(_create_loop_device_like_bdev $SCRATCH_DEV $SCRATCH_DEV \
+					 $((loopsize_mb * 1024 * 1024)))
+smajor=$((0x`stat -L -c %t $loop_dev`))
+sminor=$((0x`stat -L -c %T $loop_dev`))
+
+_mkfs_dev $loop_dev >> $seqres.full 2>&1
+_mount $loop_dev $SCRATCH_MNT || _fail "mount failed"
+_xfs_force_bdev data $SCRATCH_MNT
+
+cgdir=$CGROUP2_PATH
+drop_io_cgroup=
+grep -q -w io $cgdir/cgroup.subtree_control || drop_io_cgroup=1
+echo "+io" > $cgdir/cgroup.subtree_control || _fail "subtree control"
+mkdir -p $cgdir/$seq-cg
+echo "$smajor:$sminor wbps=$wbps" > $cgdir/$seq-cg/io.max || \
+	_notrun "cannot set io.max"
+
+$XFS_IO_PROG -f -d -c "pwrite -q -S 0x61 -b $filesize 0 $filesize" \
+	$SCRATCH_MNT/target >> $seqres.full
+$XFS_IO_PROG -f -d -c "pwrite -q -S 0x62 -b $filesize 0 $filesize" \
+	$SCRATCH_MNT/donor >> $seqres.full
+$XFS_IO_PROG -f -c "pwrite -q -S 0x63 -b $filesize 0 $filesize" \
+	$tmp.expected >> $seqres.full
+
+# Start the throttled AIO direct write. XFS drops the iolock once the bio is
+# submitted, so the swap below can take the iolock while the write is still
+# in flight. The write updates the target's timestamps when it is submitted.
+ctime0=$(stat -c %z $SCRATCH_MNT/target)
+(echo $BASHPID > $cgdir/$seq-cg/cgroup.procs && \
+	exec $FIO_PROG $fio_config --output=$tmp.fio.out) &
+fio_pid=$!
+for ((i = 0; i < 100; i++)); do
+	[ "$(stat -c %z $SCRATCH_MNT/target)" != "$ctime0" ] && break
+	sleep 0.1
+done
+[ "$(stat -c %z $SCRATCH_MNT/target)" != "$ctime0" ] || \
+	_fail "direct write was not submitted"
+
+# io.stat counts the write when io.max lets it through. Fewer bytes than
+# the write means it is still queued just before the swap.
+wbytes=$(sed -n "s/^$smajor:$sminor .*wbytes=\([0-9]*\) .*/\1/p" \
+	$cgdir/$seq-cg/io.stat)
+echo "wbytes before swapext: ${wbytes:-0}" >> $seqres.full
+[ "${wbytes:-0}" -lt $filesize ] || \
+	_notrun "direct write was not held back by io.max"
+
+$XFS_IO_PROG -c "swapext $SCRATCH_MNT/donor" $SCRATCH_MNT/target
+
+# The donor now owns the target's old data. The swap waits for the write,
+# so the donor already holds what the write wrote. This also holds when
+# always_cow sends the write to CoW staging blocks. The swap drops the
+# donor's page cache, so this first read comes from the disk.
+donor_sum=$(_md5_checksum $SCRATCH_MNT/donor)
+
+wait $fio_pid || _fail "fio failed"
+fio_pid=
+cat $tmp.fio.out >> $seqres.full
+
+# A missing io.stat line also reads as 0 above. Make sure that io.max did
+# account for the write, so the swap really ran while it was held back.
+wbytes=$(sed -n "s/^$smajor:$sminor .*wbytes=\([0-9]*\) .*/\1/p" \
+	$cgdir/$seq-cg/io.stat)
+echo "wbytes after the write: ${wbytes:-0}" >> $seqres.full
+[ "${wbytes:-0}" -ge $filesize ] || \
+	_notrun "direct write was not charged to the io.max cgroup"
+
+[ "$donor_sum" = "$(_md5_checksum $tmp.expected)" ] || \
+	echo "donor does not hold the direct write after swapext"
+
+_unmount $SCRATCH_MNT
+_check_xfs_filesystem $loop_dev none none
+
+echo Silence is golden
+_exit 0
diff --git a/tests/xfs/843.out b/tests/xfs/843.out
new file mode 100644
index 0000000..87c1350
--- /dev/null
+++ b/tests/xfs/843.out
@@ -0,0 +1,2 @@
+QA output created by 843
+Silence is golden

---
base-commit: d07dca72d2455f4ba8c660ad4c008541ccccb707
change-id: 20261109-xfs-swapext-dio-test-8b98685a4d10

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

