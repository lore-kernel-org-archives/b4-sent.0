From: Daan De Meyer <daan@amutable.com>
Date: Sun, 12 Jul 2026 16:25:13 +0200
Subject: [PATCH 1/2] btrfs: reject swapfile activation if any extent has
 checksums
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260712-reflink-into-nodatasum-v1-1-9f27ef836073@amutable.com>
References: <20260712-reflink-into-nodatasum-v1-0-9f27ef836073@amutable.com>
In-Reply-To: <20260712-reflink-into-nodatasum-v1-0-9f27ef836073@amutable.com>
To: Chris Mason <clm@fb.com>, David Sterba <dsterba@suse.com>
Cc: linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daan De Meyer <daan@amutable.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783866322; l=3034;
 i=daan@amutable.com; s=20260712; h=from:subject:message-id;
 bh=u4OxLSoQvFJmB2D7ka2hrKLQE4cNzHXmvuQ5SAih+34=;
 b=YJca4M67OBNqWmBcy1w1pTcy5q4Y01HatTxtZHWH9eEAwx1grbC3uv9trLCSJ6pjIMkpJ0NxU
 Q2dHlJYmypUBQraxUs59Vv4cIHkEjBCpbt2P8xFy5Geo5UJ+QCCGt44
X-Developer-Key: i=daan@amutable.com; a=ed25519;
 pk=I1l+WwrtmzRgofA5SQ1wTuJi18fjh91w+f5uRkFeZEA=
X-Endpoint-Received: by B4 Relay for daan@amutable.com/20260712 with auth_id=868
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

btrfs_swap_activate() checks that the file is NODATACOW and NODATASUM
and that none of its extents are shared, but it does not check that the
extents are actually free of checksum items.

Once an inode with NODATASUM set can reference extents that have
checksums in the csum tree, which a subsequent patch allows by
permitting reflinks from checksummed files into NODATASUM files, this
becomes a corruption vector:

  1. Reflink a checksummed file into a NODATASUM file.
  2. Delete the source file, so the extents are no longer shared.
  3. mkswap + swapon the NODATASUM file. The existing NODATACOW,
     NODATASUM and sharedness checks all pass.
  4. Writes to the active swap file go to disk directly, bypassing the
     COW fallback in can_nocow_file_extent() that everywhere else
     prevents in-place writes over extents that have checksums.

Such writes invalidate the checksums that remain in the csum tree,
after which scrub and read repair report, and on profiles with
redundancy attempt to repair, false corruption.

Close the hole by rejecting swap file activation if checksums exist for
any of the file's extents, mirroring the checksum lookup done by
can_nocow_file_extent().

Signed-off-by: Daan De Meyer <daan@amutable.com>
---
 fs/btrfs/inode.c | 29 +++++++++++++++++++++++++++++
 1 file changed, 29 insertions(+)

diff --git a/fs/btrfs/inode.c b/fs/btrfs/inode.c
index 272598f6ae77..76a637f4263d 100644
--- a/fs/btrfs/inode.c
+++ b/fs/btrfs/inode.c
@@ -10216,6 +10216,7 @@ static int btrfs_swap_activate(struct swap_info_struct *sis, struct file *file,
 		struct extent_buffer *leaf;
 		struct btrfs_file_extent_item *ei;
 		struct btrfs_block_group *bg;
+		struct btrfs_root *csum_root;
 		u64 logical_block_start;
 		u64 physical_block_start;
 		u64 extent_gen;
@@ -10300,6 +10301,34 @@ static int btrfs_swap_activate(struct swap_info_struct *sis, struct file *file,
 			goto out;
 		}
 
+		/*
+		 * The extents may have csums despite the NODATASUM inode flag,
+		 * from a reflink of a checksummed file into this file. Writes
+		 * to an active swap file bypass the COW fallback that protects
+		 * such extents everywhere else (see can_nocow_file_extent()),
+		 * so they would invalidate the csums and make scrub and read
+		 * repair report false corruption.
+		 */
+		csum_root = btrfs_csum_root(fs_info, logical_block_start);
+		if (unlikely(!csum_root)) {
+			btrfs_err(fs_info,
+				  "missing csum root for extent at bytenr %llu",
+				  logical_block_start);
+			ret = -EUCLEAN;
+			goto out;
+		}
+		ret = btrfs_lookup_csums_list(csum_root, logical_block_start,
+					      logical_block_start + len - 1,
+					      NULL, false);
+		if (ret < 0)
+			goto out;
+		if (ret > 0) {
+			btrfs_warn(fs_info,
+				   "swapfile must not have checksummed extents");
+			ret = -EINVAL;
+			goto out;
+		}
+
 		map = btrfs_get_chunk_map(fs_info, logical_block_start, len);
 		if (IS_ERR(map)) {
 			ret = PTR_ERR(map);

-- 
2.54.0

