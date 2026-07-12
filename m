From: Daan De Meyer <daan@amutable.com>
Date: Sun, 12 Jul 2026 16:37:22 +0200
Subject: [PATCH] btrfs: test checksum handling for clone, dedupe and swap
 on NOCOW files
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260712-push-kwzqkrlxwvnv-v1-1-e2466aff1bfd@amutable.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CMBBFr0JmbROoAolXMS6mZbAVrTgDhUi4u
 60u389/bwMh9iRwLjZgil78KySoDgVYh+FGyneJQZe6KdtKq3EWp4bl8x74sS4xRHVErBukk+l
 aC8kbmXq//pqX659lNneyUw7lh0EhZRiDdXl6okzEsO9fT8JUfI4AAAA=
X-Change-ID: 20260712-push-kwzqkrlxwvnv-3aa56ae4bd7c
To: Zorro Lang <zlang@kernel.org>, Anand Jain <asj@kernel.org>, 
 Filipe Manana <fdmanana@suse.com>
Cc: fstests@vger.kernel.org, linux-btrfs@vger.kernel.org, 
 Daan De Meyer <daan@amutable.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783867046; l=10412;
 i=daan@amutable.com; s=20260712; h=from:subject:message-id;
 bh=FR63JniEZ2028iGYTflhLnIFarsSaqEaFzU2/w/MTqc=;
 b=M7KjmG2Z7zNcfX+s1xsWCzQH9SQyTI+IrXPYOYjoHtk8EshwvfTAK2xv+yR7hSa6De06WGy8X
 xKIs3jBhm6VDaceXNUqX/WGCsy0euz5qF59OdppNw00qYiMSnIbz6Mm
X-Developer-Key: i=daan@amutable.com; a=ed25519;
 pk=I1l+WwrtmzRgofA5SQ1wTuJi18fjh91w+f5uRkFeZEA=
X-Endpoint-Received: by B4 Relay for daan@amutable.com/20260712 with auth_id=868
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add two tests covering how checksummed and NOCOW extents interact.

btrfs/348 verifies that checksummed extents can be cloned and
deduplicated into NOCOW files, and that the reverse direction stays
rejected because NOCOW extents do not have checksums.

btrfs/349 verifies that a NOCOW swap file containing a checksummed
extent is rejected even after the checksummed source is deleted and the
extent is no longer shared.

Signed-off-by: Daan De Meyer <daan@amutable.com>
---
These tests cover the kernel series available at:
https://lore.kernel.org/linux-btrfs/20260712-reflink-into-nodatasum-v1-0-9f27ef836073@amutable.com/
---
 tests/btrfs/348     | 180 ++++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/btrfs/348.out |   2 +
 tests/btrfs/349     |  73 +++++++++++++++++++++
 tests/btrfs/349.out |   2 +
 4 files changed, 257 insertions(+)

diff --git a/tests/btrfs/348 b/tests/btrfs/348
new file mode 100755
index 00000000..4faf994e
--- /dev/null
+++ b/tests/btrfs/348
@@ -0,0 +1,180 @@
+#! /bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Copyright (c) 2026 Daan De Meyer. All Rights Reserved.
+#
+# FS QA Test 348
+#
+# Verify that checksummed extents can be cloned and deduplicated into NOCOW
+# files.  The reverse direction must remain rejected because NOCOW extents do
+# not have checksums.
+#
+. ./common/preamble
+_begin_fstest auto quick clone dedupe scrub
+
+. ./common/reflink
+
+_require_scratch_reflink
+_require_scratch_dedupe
+_require_chattr C
+_require_btrfs_no_nodatacow
+_require_btrfs_no_nodatasum
+_require_btrfs_command inspect-internal dump-tree
+
+_fixed_by_kernel_commit 28ce1d263f4d \
+	"btrfs: allow reflinking from checksummed files into nodatasum files"
+
+filesize=128K
+
+write_pattern()
+{
+	local file=$1
+	local pattern=$2
+
+	$XFS_IO_PROG -f -c "pwrite -q -S $pattern 0 $filesize" \
+		-c fsync "$file" || _fail "failed to write $file"
+}
+
+make_nocow_file()
+{
+	local file=$1
+
+	touch "$file"
+	$CHATTR_PROG +C "$file" || _fail "failed to set NOCOW on $file"
+}
+
+get_extent_bytenr()
+{
+	local file=$1
+	local offset=${2:-0}
+
+	extent_bytenr=$(_btrfs_get_file_extent_item_bytenr "$file" "$offset")
+	[ -n "$extent_bytenr" ] || _fail "failed to find an extent for $file"
+}
+
+check_contents()
+{
+	local file=$1
+	local expected=$2
+
+	cmp -s "$file" "$expected" || _fail "unexpected contents in $file"
+}
+
+# Generate reference files outside the scratch filesystem.
+write_pattern "$tmp.pattern_a" 0x61
+write_pattern "$tmp.pattern_b" 0x62
+write_pattern "$tmp.pattern_c" 0x63
+
+_scratch_mkfs >> $seqres.full 2>&1 || _fail "mkfs failed"
+_scratch_mount
+
+# Clone a checksummed extent into a NOCOW file.
+source=$SCRATCH_MNT/clone_source
+dest=$SCRATCH_MNT/clone_dest
+write_pattern "$source" 0x61
+make_nocow_file "$dest"
+_reflink_range "$source" 0 "$dest" 0 "$filesize" > /dev/null 2>&1
+
+# Remount so that the data checks below cannot be satisfied from page cache.
+_scratch_cycle_mount
+get_extent_bytenr "$source"
+source_bytenr=$extent_bytenr
+get_extent_bytenr "$dest"
+dest_bytenr=$extent_bytenr
+[ "$source_bytenr" = "$dest_bytenr" ] || \
+	_fail "clone did not share the source extent"
+check_contents "$source" "$tmp.pattern_a"
+check_contents "$dest" "$tmp.pattern_a"
+
+# The first write to the NOCOW destination must COW because the shared extent
+# has checksums.  This keeps the source data and its checksums intact.
+write_pattern "$dest" 0x62
+get_extent_bytenr "$dest"
+first_write_bytenr=$extent_bytenr
+[ "$first_write_bytenr" != "$source_bytenr" ] || \
+	_fail "first NOCOW destination write did not COW"
+_scratch_cycle_mount
+check_contents "$source" "$tmp.pattern_a"
+check_contents "$dest" "$tmp.pattern_b"
+
+# Once the destination has a private extent without checksums, NOCOW writes
+# should resume modifying that extent in place.
+write_pattern "$dest" 0x63
+get_extent_bytenr "$dest"
+second_write_bytenr=$extent_bytenr
+[ "$second_write_bytenr" = "$first_write_bytenr" ] || \
+	_fail "subsequent NOCOW destination write was not in place"
+check_contents "$dest" "$tmp.pattern_c"
+
+# The checksums must also force the first write to COW after the checksummed
+# source is deleted and the destination is the extent's only remaining owner.
+source=$SCRATCH_MNT/unshared_source
+dest=$SCRATCH_MNT/unshared_dest
+write_pattern "$source" 0x61
+make_nocow_file "$dest"
+_reflink_range "$source" 0 "$dest" 0 "$filesize" > /dev/null 2>&1
+get_extent_bytenr "$source"
+source_bytenr=$extent_bytenr
+get_extent_bytenr "$dest"
+shared_bytenr=$extent_bytenr
+[ "$source_bytenr" = "$shared_bytenr" ] || \
+	_fail "clone did not share the source extent"
+rm "$source"
+_scratch_cycle_mount
+write_pattern "$dest" 0x62
+get_extent_bytenr "$dest"
+unshared_write_bytenr=$extent_bytenr
+[ "$unshared_write_bytenr" != "$shared_bytenr" ] || \
+	_fail "write to unshared checksummed extent did not COW"
+check_contents "$dest" "$tmp.pattern_b"
+
+# Dedupe uses the same remap preparation path and must allow the same
+# checksummed source to NOCOW destination direction.
+source=$SCRATCH_MNT/dedupe_source
+dest=$SCRATCH_MNT/dedupe_dest
+write_pattern "$source" 0x61
+make_nocow_file "$dest"
+$XFS_IO_PROG -f -c "pwrite -q -S 0x61 0 384K" -c fsync "$dest" || \
+	_fail "failed to write $dest"
+_dedupe_range "$source" 0 "$dest" "$filesize" "$filesize" \
+	> /dev/null 2>&1
+_scratch_cycle_mount
+get_extent_bytenr "$source"
+source_bytenr=$extent_bytenr
+get_extent_bytenr "$dest" "$((128 * 1024))"
+dest_bytenr=$extent_bytenr
+[ "$source_bytenr" = "$dest_bytenr" ] || \
+	_fail "dedupe did not share the source extent"
+_compare_range "$source" 0 "$dest" "$((128 * 1024))" "$((128 * 1024))" || \
+	_fail "deduped range contents differ from the source"
+
+# Scrub must handle the NOCOW destination's mixture of checksummed and
+# non-checksummed extents without reporting an error.
+$BTRFS_UTIL_PROG scrub start -B "$SCRATCH_MNT" >> $seqres.full 2>&1 || \
+	_fail "scrub found errors"
+
+# Cloning or deduplicating a NOCOW source into a checksummed destination must
+# not share the source extent, since it has no checksums for destination reads.
+source=$SCRATCH_MNT/reverse_source
+clone_dest=$SCRATCH_MNT/reverse_clone_dest
+dedupe_dest=$SCRATCH_MNT/reverse_dedupe_dest
+make_nocow_file "$source"
+write_pattern "$source" 0x61
+touch "$clone_dest"
+_reflink_range "$source" 0 "$clone_dest" 0 "$filesize" > /dev/null 2>&1
+get_extent_bytenr "$source"
+source_bytenr=$extent_bytenr
+clone_bytenr=$(_btrfs_get_file_extent_item_bytenr "$clone_dest" 0)
+if [ -n "$clone_bytenr" ] && [ "$clone_bytenr" = "$source_bytenr" ]; then
+	_fail "NOCOW to checksummed clone succeeded"
+fi
+write_pattern "$dedupe_dest" 0x61
+_dedupe_range "$source" 0 "$dedupe_dest" 0 "$filesize" > /dev/null 2>&1
+get_extent_bytenr "$dedupe_dest"
+dedupe_bytenr=$extent_bytenr
+if [ "$dedupe_bytenr" = "$source_bytenr" ]; then
+	_fail "NOCOW to checksummed dedupe succeeded"
+fi
+
+echo "Silence is golden"
+
+_exit 0
diff --git a/tests/btrfs/348.out b/tests/btrfs/348.out
new file mode 100644
index 00000000..ec5e4701
--- /dev/null
+++ b/tests/btrfs/348.out
@@ -0,0 +1,2 @@
+QA output created by 348
+Silence is golden
diff --git a/tests/btrfs/349 b/tests/btrfs/349
new file mode 100755
index 00000000..66e0935a
--- /dev/null
+++ b/tests/btrfs/349
@@ -0,0 +1,73 @@
+#! /bin/bash
+# SPDX-License-Identifier: GPL-2.0
+# Copyright (c) 2026 Daan De Meyer. All Rights Reserved.
+#
+# FS QA Test 349
+#
+# Verify that a NOCOW swap file containing a checksummed extent is rejected
+# even after the checksummed source is deleted and the extent is no longer
+# shared.
+#
+. ./common/preamble
+_begin_fstest auto quick clone swap
+
+_cleanup()
+{
+	cd /
+	test -n "$swap_file" && swapoff "$swap_file" > /dev/null 2>&1
+	rm -f $tmp.*
+}
+
+. ./common/reflink
+
+_require_scratch_swapfile
+_require_scratch_reflink
+_require_chattr C
+_require_btrfs_no_nodatacow
+_require_btrfs_no_nodatasum
+_require_btrfs_command inspect-internal dump-tree
+
+_fixed_by_kernel_commit 8e4ef5e540bb \
+	"btrfs: reject swapfile activation if any extent has checksums"
+_fixed_by_kernel_commit 28ce1d263f4d \
+	"btrfs: allow reflinking from checksummed files into nodatasum files"
+
+_scratch_mkfs >> $seqres.full 2>&1 || _fail "mkfs failed"
+_scratch_mount
+
+swap_file=$SCRATCH_MNT/swapfile
+source=$SCRATCH_MNT/checksummed_source
+swap_size=$((16 * 1024 * 1024))
+extent_size=$((128 * 1024))
+dest_offset=$((1024 * 1024))
+
+# First verify that this filesystem and configuration can activate a regular
+# NOCOW swap file.
+_format_swapfile "$swap_file" "$swap_size" >> $seqres.full
+_swapon_file "$swap_file" >> $seqres.full 2>&1 || \
+	_fail "failed to activate plain NOCOW swap file"
+swapoff "$swap_file" >> $seqres.full 2>&1 || \
+	_fail "failed to deactivate plain NOCOW swap file"
+
+# Replace a range away from the swap header with a checksummed extent.  Delete
+# the source and commit the deletion so that sharedness cannot be the reason
+# for rejecting swap activation.
+$XFS_IO_PROG -f -c "pwrite -q -S 0x61 0 $extent_size" -c fsync "$source" || \
+	_fail "failed to write checksummed source"
+_reflink_range "$source" 0 "$swap_file" "$dest_offset" "$extent_size" \
+	> /dev/null 2>&1
+source_bytenr=$(_btrfs_get_file_extent_item_bytenr "$source" 0)
+swap_bytenr=$(_btrfs_get_file_extent_item_bytenr "$swap_file" "$dest_offset")
+[ -n "$source_bytenr" ] && [ "$source_bytenr" = "$swap_bytenr" ] || \
+	_fail "checksummed extent was not cloned into the swap file"
+rm "$source"
+_scratch_cycle_mount
+
+if _swapon_file "$swap_file" >> $seqres.full 2>&1; then
+	swapoff "$swap_file" > /dev/null 2>&1
+	_fail "activated swap file containing a checksummed extent"
+fi
+
+echo "Silence is golden"
+
+_exit 0
diff --git a/tests/btrfs/349.out b/tests/btrfs/349.out
new file mode 100644
index 00000000..aac66ede
--- /dev/null
+++ b/tests/btrfs/349.out
@@ -0,0 +1,2 @@
+QA output created by 349
+Silence is golden

---
base-commit: cac9fe2b8dc3e6dbc0c2383b9e3b4d3c1b9e7dd0
change-id: 20260712-push-kwzqkrlxwvnv-3aa56ae4bd7c

Best regards,
--  
Daan De Meyer <daan@amutable.com>

