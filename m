From: Dhruva Gole <goledhruva@gmail.com>
Date: Sun, 25 Oct 2026 17:21:52 +0000
Subject: [PATCH v2 3/3] btrfs: cover NOCOMPRESS inline eligibility and
 short tails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-b4-btrfs-nocomp-v2-v2-3-628c1986f9b9@gmail.com>
References: <20261025-b4-btrfs-nocomp-v2-v2-0-628c1986f9b9@gmail.com>
In-Reply-To: <20261025-b4-btrfs-nocomp-v2-v2-0-628c1986f9b9@gmail.com>
To: fstests@vger.kernel.org
Cc: linux-btrfs@vger.kernel.org, Anand Jain <asj@kernel.org>, 
 Filipe Manana <fdmanana@suse.com>, Zorro Lang <zlang@kernel.org>, 
 Qu Wenruo <wqu@suse.com>, Dhruva Gole <goledhruva@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792948953; l=5180;
 i=goledhruva@gmail.com; s=remote-20261025; h=from:subject:message-id;
 bh=nSeOy4HCHBGmnWIBWdeEUmRx3/Kf0uqzyuynzDLXb2s=;
 b=hdLjnwCyiP7mZH3rd0qyBYpJRAVlsuGvMxA3admyu/205BegJe6BiIsNncxZGX/LijREG3lfU
 snXSbmIk/7PDvwR8r7g7t8LFvLGNfEBaAFET5ijcwwuzqtl4PmrbC7U
X-Developer-Key: i=goledhruva@gmail.com; a=ed25519;
 pk=OBz78Vw5K+/+HyXjxg9mNOV2Bq087eJgHL749H+Xe/k=
X-Endpoint-Received: by B4 Relay for goledhruva@gmail.com/remote-20261025 with auth_id=1318
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Test that defrag --nocomp keeps a compressed inline extent while it is still
allowed by max_inline, and that it uncompresses the extent once remounted
with max_inline=0. Also exercise files with sizes of 1 byte, a sector minus
one byte, a sector plus one byte and a maximum compressed extent plus one
byte. Check the layouts with fiemap and the file contents with md5sum after
a remount.

Signed-off-by: Dhruva Gole <goledhruva@gmail.com>
---
 tests/btrfs/357     | 81 +++++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/btrfs/357.out | 39 ++++++++++++++++++++++++++
 2 files changed, 120 insertions(+)

diff --git a/tests/btrfs/357 b/tests/btrfs/357
new file mode 100755
index 00000000..f9c790bb
--- /dev/null
+++ b/tests/btrfs/357
@@ -0,0 +1,81 @@
+#! /bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Copyright (c) 2026 Meta Platforms, Inc. and affiliates. All Rights Reserved.
+#
+# FS QA Test 357
+#
+# Test that defrag --nocomp keeps a compressed inline extent while it can stay
+# inline, uncompresses it once max_inline no longer allows it, and handles
+# files with short EOF tails.
+#
+. ./common/preamble
+_begin_fstest auto quick defrag compress fiemap
+
+. ./common/filter
+. ./common/punch # for _coalesce_extents
+
+# Keep all flags, including DATA_INLINE (0x200) and ENCODED (0x8), while
+# filtering out physical addresses. A compressed inline extent has flags 0x309
+# (DATA_INLINE | NOT_ALIGNED | ENCODED | LAST).
+_filter_fiemap_keep_flags()
+{
+	$AWK_PROG '
+		$3 == "hole" {
+			print $1, $2, $3;
+			next;
+		}
+		$5 ~ /^0x[[:xdigit:]]+$/ {
+			print $1, $2, $5;
+		}' | _coalesce_extents
+}
+
+_require_btrfs_defrag_nocompress
+_require_btrfs_support_sectorsize 4096
+_require_btrfs_no_nodatacow
+_require_btrfs_no_nodatasum
+_require_btrfs_no_autodefrag
+_require_btrfs_inline_extents_creation
+_require_xfs_io_command "fiemap"
+
+_wants_kernel_commit 009b2056cb25 \
+	"btrfs: defrag: add flag to force no-compression"
+
+_scratch_mkfs -s 4k >> $seqres.full 2>&1 || _fail "mkfs failed"
+_scratch_mount -o compress=zlib,max_inline=4096
+
+# Create a compressed inline extent and check both ENCODED and DATA_INLINE.
+$XFS_IO_PROG -f -c "pwrite -S 0xab 0 2K" $SCRATCH_MNT/compressed-inline | \
+	_filter_xfs_io
+echo "fiemap before defrag:"
+$XFS_IO_PROG -c "fiemap -v" $SCRATCH_MNT/compressed-inline | \
+	_filter_fiemap_keep_flags
+
+$BTRFS_UTIL_PROG filesystem defragment --nocomp $SCRATCH_MNT/compressed-inline
+_scratch_cycle_mount compress=zlib,max_inline=4096
+echo "fiemap after defrag with max_inline=4096:"
+$XFS_IO_PROG -c "fiemap -v" $SCRATCH_MNT/compressed-inline | \
+	_filter_fiemap_keep_flags
+
+_scratch_cycle_mount compress=zlib,max_inline=0
+$BTRFS_UTIL_PROG filesystem defragment --nocomp $SCRATCH_MNT/compressed-inline
+
+for len in 1 4095 4097 131073; do
+	$XFS_IO_PROG -f -c "pwrite -S 0xcd 0 $len" $SCRATCH_MNT/tail-$len | \
+		_filter_xfs_io
+	echo "tail-$len fiemap before defrag:"
+	$XFS_IO_PROG -c "fiemap -v" $SCRATCH_MNT/tail-$len | \
+		_filter_fiemap_keep_flags
+	$BTRFS_UTIL_PROG filesystem defragment --nocomp $SCRATCH_MNT/tail-$len
+done
+
+# Check the new layout and data are persisted.
+_scratch_cycle_mount compress=zlib,max_inline=0
+
+for f in compressed-inline tail-1 tail-4095 tail-4097 tail-131073; do
+	echo "$f fiemap after defrag:"
+	$XFS_IO_PROG -c "fiemap -v" $SCRATCH_MNT/$f | _filter_fiemap_keep_flags
+done
+md5sum $SCRATCH_MNT/{compressed-inline,tail-1,tail-4095,tail-4097,tail-131073} | \
+	_filter_scratch
+
+_exit 0
diff --git a/tests/btrfs/357.out b/tests/btrfs/357.out
new file mode 100644
index 00000000..2351f68b
--- /dev/null
+++ b/tests/btrfs/357.out
@@ -0,0 +1,39 @@
+QA output created by 357
+wrote 2048/2048 bytes at offset 0
+XXX Bytes, X ops; XX:XX:XX.X (XXX YYY/sec and XXX ops/sec)
+fiemap before defrag:
+0: [0..7]: 0x309
+fiemap after defrag with max_inline=4096:
+0: [0..7]: 0x309
+wrote 1/1 bytes at offset 0
+XXX Bytes, X ops; XX:XX:XX.X (XXX YYY/sec and XXX ops/sec)
+tail-1 fiemap before defrag:
+0: [0..7]: 0x1
+wrote 4095/4095 bytes at offset 0
+XXX Bytes, X ops; XX:XX:XX.X (XXX YYY/sec and XXX ops/sec)
+tail-4095 fiemap before defrag:
+0: [0..7]: 0x1
+wrote 4097/4097 bytes at offset 0
+XXX Bytes, X ops; XX:XX:XX.X (XXX YYY/sec and XXX ops/sec)
+tail-4097 fiemap before defrag:
+0: [0..15]: 0x9
+wrote 131073/131073 bytes at offset 0
+XXX Bytes, X ops; XX:XX:XX.X (XXX YYY/sec and XXX ops/sec)
+tail-131073 fiemap before defrag:
+0: [0..255]: 0x8
+1: [256..263]: 0x1
+compressed-inline fiemap after defrag:
+0: [0..7]: 0x1
+tail-1 fiemap after defrag:
+0: [0..7]: 0x1
+tail-4095 fiemap after defrag:
+0: [0..7]: 0x1
+tail-4097 fiemap after defrag:
+0: [0..15]: 0x1
+tail-131073 fiemap after defrag:
+0: [0..263]: 0x1
+a97d075b76a2d5d777ebadd4e3f3be94  SCRATCH_MNT/compressed-inline
+e6cf2aa82fa371b686171ecd6a734e5d  SCRATCH_MNT/tail-1
+eb7177e6602dec278d9eb99dfcb32764  SCRATCH_MNT/tail-4095
+915c2ed4a6fdedfd3ef3bb4198d9b4f8  SCRATCH_MNT/tail-4097
+1e71d33e1f1368bb15cbe39b7b9f2447  SCRATCH_MNT/tail-131073

-- 
2.43.0

