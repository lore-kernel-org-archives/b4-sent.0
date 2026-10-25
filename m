From: Dhruva Gole <goledhruva@gmail.com>
Date: Sun, 25 Oct 2026 17:21:51 +0000
Subject: [PATCH v2 2/3] btrfs: check NOCOMPRESS preserves holes and
 preallocation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-b4-btrfs-nocomp-v2-v2-2-628c1986f9b9@gmail.com>
References: <20261025-b4-btrfs-nocomp-v2-v2-0-628c1986f9b9@gmail.com>
In-Reply-To: <20261025-b4-btrfs-nocomp-v2-v2-0-628c1986f9b9@gmail.com>
To: fstests@vger.kernel.org
Cc: linux-btrfs@vger.kernel.org, Anand Jain <asj@kernel.org>, 
 Filipe Manana <fdmanana@suse.com>, Zorro Lang <zlang@kernel.org>, 
 Qu Wenruo <wqu@suse.com>, Dhruva Gole <goledhruva@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792948953; l=4278;
 i=goledhruva@gmail.com; s=remote-20261025; h=from:subject:message-id;
 bh=6fh0L2Df1MA5vL1mDztYUnELsLKDU3e6oyTbelQ73h4=;
 b=ShAubn445l75XjgcJ1k8Rh3ZDdnPu2vfo0f8VzKryzadZIr5ejww+4b15ugONMU/FyfZ1oNDt
 FgeTBgq9qu4CTWQ634FgO7o58KWBDYtRv5wlztXcZ4fMZqcbKZrvB7D
X-Developer-Key: i=goledhruva@gmail.com; a=ed25519;
 pk=OBz78Vw5K+/+HyXjxg9mNOV2Bq087eJgHL749H+Xe/k=
X-Endpoint-Received: by B4 Relay for goledhruva@gmail.com/remote-20261025 with auth_id=1318
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Create a file with compressed extents separated by holes, a preallocated
extent inside EOF and a preallocated extent beyond EOF. Test that defrag
--nocomp uncompresses the data extents while the holes and preallocated
extents are left untouched, checking the layout with fiemap and the file
contents with md5sum after a remount.

Signed-off-by: Dhruva Gole <goledhruva@gmail.com>
---
 tests/btrfs/356     | 64 +++++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/btrfs/356.out | 28 +++++++++++++++++++++++
 2 files changed, 92 insertions(+)

diff --git a/tests/btrfs/356 b/tests/btrfs/356
new file mode 100755
index 00000000..b1d89f43
--- /dev/null
+++ b/tests/btrfs/356
@@ -0,0 +1,64 @@
+#! /bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Copyright (c) 2026 Meta Platforms, Inc. and affiliates. All Rights Reserved.
+#
+# FS QA Test 356
+#
+# Test that defrag --nocomp uncompresses data extents but leaves holes and
+# preallocated extents, including one beyond EOF, untouched.
+#
+. ./common/preamble
+_begin_fstest auto quick defrag compress prealloc fiemap
+
+. ./common/filter
+. ./common/punch # for _filter_fiemap_flags
+
+_require_btrfs_defrag_nocompress
+_require_btrfs_support_sectorsize 4096
+_require_btrfs_no_nodatacow
+_require_btrfs_no_nodatasum
+_require_btrfs_no_autodefrag
+_require_xfs_io_command "fiemap"
+_require_xfs_io_command "falloc" "-k"
+
+_wants_kernel_commit 009b2056cb25 \
+	"btrfs: defrag: add flag to force no-compression"
+
+_scratch_mkfs -s 4k >> $seqres.full 2>&1 || _fail "mkfs failed"
+_scratch_mount -o compress=zlib
+
+# Compressed extents at 0, 512K and 1M, holes in between, a preallocated
+# extent at 256K and a preallocated extent beyond EOF at 1280K. Fsync before
+# fallocating, otherwise the data would be written as NOCOW, uncompressed.
+$XFS_IO_PROG -f -c "pwrite -S 0xab 0 128K" \
+	     -c "pwrite -S 0xcd 512K 128K" \
+	     -c "pwrite -S 0xef 1M 128K" \
+	     -c "fsync" \
+	     -c "falloc 256K 128K" \
+	     -c "falloc -k 1280K 128K" \
+	     $SCRATCH_MNT/compressed_sparse_file | _filter_xfs_io
+
+echo "fiemap before defrag:"
+$XFS_IO_PROG -c "fiemap -v" $SCRATCH_MNT/compressed_sparse_file | _filter_fiemap_flags 1
+
+# Check the physical start of each preallocated extent as in btrfs/257.
+prealloc=$(_get_file_extent_sector "$SCRATCH_MNT/compressed_sparse_file" 262144)
+prealloc_eof=$(_get_file_extent_sector "$SCRATCH_MNT/compressed_sparse_file" 1310720)
+
+$BTRFS_UTIL_PROG filesystem defragment --nocomp $SCRATCH_MNT/compressed_sparse_file
+
+# Check that the extent layout and data persist across a remount.
+_scratch_cycle_mount compress=zlib
+
+if [ "$prealloc" != "$(_get_file_extent_sector "$SCRATCH_MNT/compressed_sparse_file" 262144)" ]; then
+	echo "preallocation inside EOF moved"
+fi
+if [ "$prealloc_eof" != "$(_get_file_extent_sector "$SCRATCH_MNT/compressed_sparse_file" 1310720)" ]; then
+	echo "preallocation beyond EOF moved"
+fi
+
+echo "fiemap after defrag:"
+$XFS_IO_PROG -c "fiemap -v" $SCRATCH_MNT/compressed_sparse_file | _filter_fiemap_flags 1
+md5sum $SCRATCH_MNT/compressed_sparse_file | _filter_scratch
+
+_exit 0
diff --git a/tests/btrfs/356.out b/tests/btrfs/356.out
new file mode 100644
index 00000000..777fdf1e
--- /dev/null
+++ b/tests/btrfs/356.out
@@ -0,0 +1,28 @@
+QA output created by 356
+wrote 131072/131072 bytes at offset 0
+XXX Bytes, X ops; XX:XX:XX.X (XXX YYY/sec and XXX ops/sec)
+wrote 131072/131072 bytes at offset 524288
+XXX Bytes, X ops; XX:XX:XX.X (XXX YYY/sec and XXX ops/sec)
+wrote 131072/131072 bytes at offset 1048576
+XXX Bytes, X ops; XX:XX:XX.X (XXX YYY/sec and XXX ops/sec)
+fiemap before defrag:
+0: [0..255]: encoded
+1: [256..511]: hole
+2: [512..767]: unwritten
+3: [768..1023]: hole
+4: [1024..1279]: encoded
+5: [1280..2047]: hole
+6: [2048..2303]: encoded
+7: [2304..2559]: hole
+8: [2560..2815]: unwritten
+fiemap after defrag:
+0: [0..255]: none
+1: [256..511]: hole
+2: [512..767]: unwritten
+3: [768..1023]: hole
+4: [1024..1279]: none
+5: [1280..2047]: hole
+6: [2048..2303]: none
+7: [2304..2559]: hole
+8: [2560..2815]: unwritten
+dc61af0129fdc173b1bc986ca00096bc  SCRATCH_MNT/compressed_sparse_file

-- 
2.43.0

