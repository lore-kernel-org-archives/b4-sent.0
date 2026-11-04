From: Mark Korenberg <socketpair@gmail.com>
Date: Wed, 04 Nov 2026 15:38:13 +0500
Subject: [PATCH] btrfs: tag all metadata I/O with REQ_META
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-btrfs-sb-read-req-meta-v1-1-e06b4d059897@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MOwqAQAwFryKpDbjiB72KWOxq1BT+kkUE8e4Gp
 3gwxZsHlIRJoU0eELpYed9MXJrAsPhtJuTRHPIsr5zLCgxRJkUNKORHmxNXih7rQGVTe6N0YOd
 DaOL7D3f9+3590TW5aAAAAA==
X-Change-ID: 20261104-btrfs-sb-read-req-meta-7be597aaaa51
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>
Cc: Qu Wenruo <wqu@suse.com>, Mark Harmstone <mark@harmstone.com>, 
 linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793788693; l=8044;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=mYH3/gnnOZUSAhAg/m5d4wWs4j5FYwgoK/14jQ1efxc=;
 b=anZ01FKCWN9aFwRKCMSDidaF09ljwxpxtqjTu4+J+D4mLTyRtxHqg/1Ebg3vHvzEnqqce2nNl
 2mdA+kPyCbDDYWrQKrdpKdQVpSSglshizFCSC+5P4RIGaelMFvxgKRy
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Tree block reads and writes and super block writes carry REQ_META, but
several other paths do metadata I/O without it, so the block layer and
drivers (blktrace, BFQ, blk-cgroup, wbt, ublk) see it as data I/O:

- scrub reads super blocks with a bare REQ_OP_READ;
- btrfs_repair_bbio_failure() rewrites a bad tree block copy without it;
- RAID5/6 rbios build new per-device bios from a bare op, so all tree
  block writes on RAID5/6, and recovery reads, lose the flag;
- scrub and dev-replace read, repair and copy metadata block groups
  without it;
- remap relocation copies metadata block groups without it.

Tag these by the chunk type: metadata and system chunks get REQ_META,
mixed chunks do not, as they also hold data.  All bios of a block group
then carry the same flag and stay mergeable (blk-cgroup does not merge
bios that differ in REQ_META).

This does not change the btrfs submission path: scrub and remap bbios
skip checksumming, and scrub_read_endio() and scrub_repair_read_endio()
do not wait for other I/O, so running them on endio_meta_workers is
fine.  With blk-cgroup, metadata scrub I/O is now issued as root and
charged back, like other metadata I/O.

bdev_rw_virt() takes an enum req_op, but gfs2 and xfs already pass
REQ_META through it.

Signed-off-by: Mark Korenberg <socketpair@gmail.com>
---
I noticed this in the request log of a ublk zoned device: tree block
reads and writes arrive with UBLK_IO_F_META, while the super block
reads at mount do not.  An audit of all bio submission sites in
fs/btrfs then found the paths listed in the commit message.

The super block reads at mount are the one case I left alone, along
with a few others:
- btrfs_read_disk_super() and sb_write_pointer() read through the
  block device page cache, which cannot pass REQ_META.  That is on
  purpose since 8f32380d3f29 ("btrfs: use the page cache for super
  block reading"), to stay coherent with mkfs and udev.  The same goes
  for btrfs_scratch_superblocks().
- Discards free space, and the empty preflush of write_dev_flush()
  covers the whole device.

Testing: virtme-ng VM, memory backed null_blk, tracefs
block:block_bio_queue, every bio classified as super block or by the
chunk type of its dev extent:
- RAID5 metadata and data: copy /usr/include, scrub, then replace
  devid 1 with a new device
- DUP metadata with one copy of a leaf corrupted, read the directory
  until "read error corrected"

Bios of metadata chunks, with REQ_META / without:

                                before      after
  RAID5 writes (and RMW reads)  0 / 274     245 / 0
  scrub                         0 / 390     369 / 0
  scrub, super blocks           0 / 6         6 / 0
  dev-replace                   0 / 258     243 / 0
  repair write                  0 / 1         1 / 0

No data bio carries REQ_META, before or after.  No new warnings, W=1
build clean.

Not tested: the remap relocation part, btrfs-progs 7.1 here cannot
create a remap-tree filesystem.  Mark, could you give it a look?

The audit, the patch and the test were drafted with the help of an AI
assistant (Claude Opus 5.5).
---
 fs/btrfs/bio.c        |  3 ++-
 fs/btrfs/raid56.c     |  3 ++-
 fs/btrfs/relocation.c | 13 ++++++++-----
 fs/btrfs/scrub.c      |  5 +++--
 fs/btrfs/volumes.h    | 10 ++++++++++
 5 files changed, 25 insertions(+), 9 deletions(-)

diff --git a/fs/btrfs/bio.c b/fs/btrfs/bio.c
index 2e12a6d7e16f..efbce4d549ff 100644
--- a/fs/btrfs/bio.c
+++ b/fs/btrfs/bio.c
@@ -951,7 +951,8 @@ int btrfs_repair_bbio_failure(struct btrfs_bio *bbio, const struct bvec_iter *or
 	}
 
 	repair_bio = bio_alloc(smap.dev->bdev, max(1, length >> PAGE_SHIFT),
-			       REQ_OP_WRITE | REQ_SYNC, GFP_NOFS);
+			       REQ_OP_WRITE | REQ_SYNC |
+			       (is_data_inode(inode) ? 0 : REQ_META), GFP_NOFS);
 	repair_bio->bi_iter.bi_sector = smap.physical >> SECTOR_SHIFT;
 	while (cur < length) {
 		struct page *page = bio_iter_page(&bbio->bio, iter);
diff --git a/fs/btrfs/raid56.c b/fs/btrfs/raid56.c
index a8a8004bb14c..1b5cdcdeced3 100644
--- a/fs/btrfs/raid56.c
+++ b/fs/btrfs/raid56.c
@@ -1205,7 +1205,8 @@ static int rbio_add_io_paddrs(struct btrfs_raid_bio *rbio, struct bio_list *bio_
 	/* put a new bio on the list */
 	bio = bio_alloc(stripe->dev->bdev,
 			max(rbio->bioc->stripe_len >> PAGE_SHIFT, 1),
-			op, GFP_NOFS);
+			op | btrfs_chunk_req_meta(rbio->bioc->map_type),
+			GFP_NOFS);
 	bio->bi_iter.bi_sector = disk_start >> SECTOR_SHIFT;
 	bio->bi_private = rbio;
 
diff --git a/fs/btrfs/relocation.c b/fs/btrfs/relocation.c
index b2ac5b836b21..af17be38eea3 100644
--- a/fs/btrfs/relocation.c
+++ b/fs/btrfs/relocation.c
@@ -4146,8 +4146,9 @@ static int copy_remapped_data_io(struct btrfs_fs_info *fs_info,
 }
 
 static int copy_remapped_data(struct btrfs_fs_info *fs_info, u64 old_addr,
-			      u64 new_addr, u64 length)
+			      u64 new_addr, u64 length, u64 type)
 {
+	const blk_opf_t meta = btrfs_chunk_req_meta(type);
 	int ret;
 	const u64 copy_len = min_t(u64, length, SZ_1M);
 	struct page **pages;
@@ -4172,12 +4173,12 @@ static int copy_remapped_data(struct btrfs_fs_info *fs_info, u64 old_addr,
 		to_copy = min_t(u64, to_copy, BIO_MAX_VECS << PAGE_SHIFT);
 
 		ret = copy_remapped_data_io(fs_info, &priv, pages, old_addr,
-					    to_copy, REQ_OP_READ);
+					    to_copy, REQ_OP_READ | meta);
 		if (ret)
 			goto end;
 
 		ret = copy_remapped_data_io(fs_info, &priv, pages, new_addr,
-					    to_copy, REQ_OP_WRITE);
+					    to_copy, REQ_OP_WRITE | meta);
 		if (ret)
 			goto end;
 
@@ -4344,7 +4345,8 @@ static int move_existing_remap(struct btrfs_fs_info *fs_info,
 		goto end;
 	}
 
-	ret = copy_remapped_data(fs_info, new_addr, dest_addr, dest_length);
+	ret = copy_remapped_data(fs_info, new_addr, dest_addr, dest_length,
+				 bg->flags);
 	if (unlikely(ret))
 		goto end;
 
@@ -5161,7 +5163,8 @@ static int do_remap_reloc_trans(struct btrfs_fs_info *fs_info,
 		}
 	}
 
-	ret = copy_remapped_data(fs_info, start, new_addr, length);
+	ret = copy_remapped_data(fs_info, start, new_addr, length,
+				 src_bg->flags);
 	if (ret) {
 		btrfs_abort_transaction(trans, ret);
 		goto fail;
diff --git a/fs/btrfs/scrub.c b/fs/btrfs/scrub.c
index 98362c91bce4..269948b1caeb 100644
--- a/fs/btrfs/scrub.c
+++ b/fs/btrfs/scrub.c
@@ -934,7 +934,8 @@ static struct btrfs_bio *alloc_scrub_bbio(struct btrfs_fs_info *fs_info,
 	 * enough to contain the full stripe.
 	 */
 	bbio = btrfs_bio_alloc(round_up(stripe->stripe_len, PAGE_SIZE) >>
-			       PAGE_SHIFT, opf,
+			       PAGE_SHIFT,
+			       opf | btrfs_chunk_req_meta(stripe->bg->flags),
 			       BTRFS_I(fs_info->btree_inode),
 			       logical, end_io, stripe);
 	bbio->is_scrub = true;
@@ -2957,7 +2958,7 @@ static int scrub_one_super(struct scrub_ctx *sctx, struct btrfs_device *dev,
 	int ret;
 
 	ret = bdev_rw_virt(dev->bdev, physical >> SECTOR_SHIFT, sb,
-			BTRFS_SUPER_INFO_SIZE, REQ_OP_READ);
+			BTRFS_SUPER_INFO_SIZE, REQ_OP_READ | REQ_META);
 	if (ret < 0)
 		return ret;
 	ret = btrfs_check_super_csum(fs_info, sb);
diff --git a/fs/btrfs/volumes.h b/fs/btrfs/volumes.h
index 891bc2432870..66796f09eae8 100644
--- a/fs/btrfs/volumes.h
+++ b/fs/btrfs/volumes.h
@@ -709,6 +709,16 @@ static inline enum btrfs_map_op btrfs_op(const struct bio *bio)
 	}
 }
 
+/*
+ * REQ_META for I/O to a chunk of type @type that holds only tree blocks.
+ * A mixed chunk also holds data and gets no flag, otherwise its data
+ * would be tagged as metadata.
+ */
+static inline blk_opf_t btrfs_chunk_req_meta(u64 type)
+{
+	return (type & BTRFS_BLOCK_GROUP_DATA) ? 0 : REQ_META;
+}
+
 static inline unsigned long btrfs_chunk_item_size(int num_stripes)
 {
 	return offsetof(struct btrfs_chunk, stripe) +

---
base-commit: df5b88a7914e18488908ddf13e14e31ab39f954c
change-id: 20261104-btrfs-sb-read-req-meta-7be597aaaa51

Best regards,
-- 
Mark Korenberg <socketpair@gmail.com>

