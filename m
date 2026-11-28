From: Abhiraj Dutta <abhirajdutta7@gmail.com>
Date: Fri, 27 Nov 2026 23:19:51 -0500
Subject: [PATCH] gfs2: Don't cache metadata blocks beyond the end of the
 device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-gfs2-b4-v1-1-43d2c224e835@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGZWCmsC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyNz3fS0YiPdJBNds2TL1BSL5NS0NAtTJaDqgqLUtMwKsEnRsbW1AHf
 zEKFZAAAA
To: Andreas Gruenbacher <agruenba@redhat.com>
Cc: gfs2@lists.linux.dev, linux-kernel@vger.kernel.org, 
 syzbot+4c7590f1cee06597e43a@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Abhiraj Dutta <abhirajdutta7@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795839666; l=10138;
 i=abhirajdutta7@gmail.com; s=20261127; h=from:subject:message-id;
 bh=dsnc3Ja34kkr1cnrn1lgndonoi9rMe0qU9CCmqrbRyM=;
 b=ZD6CZ5VjsntqsOeM86xyP+6hPqi5f3Y/7i603Y95l3h0dMRu/9RiuKDSRkxlHjxelXGZgJ389
 GflsLxwn3N/CyGm34c88nTYFvCTvuh9H5Y+3Ocev4AP8EIkEb+LSS1L
X-Developer-Key: i=abhirajdutta7@gmail.com; a=ed25519;
 pk=/yElQa3xC9IL0VQpYXJ0w1qqAjVx6gnQspoyVUEvD7M=
X-Endpoint-Received: by B4 Relay for abhirajdutta7@gmail.com/20261127 with auth_id=1674
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Block numbers read from disk are used to create buffers in the glock
address spaces without any range check.  When the block size is equal to
the page size, a block number of ~0ULL ends up at page index ULONG_MAX,
and truncate_inode_pages_final() never removes a folio at that index.
The glock is then freed with the folio still in its address space and
on the LRU (__gfs2_glock_put() doesn't check for leftover pages on a
withdrawn filesystem), and reclaim follows folio->mapping into freed
memory:

  BUG: KASAN: slab-use-after-free in folio_evictable+0xe4/0x250
  Read of size 8 at addr ffff88804805ec78 by task kswapd1/76
  Call Trace:
   folio_evictable
   evict_folios
   try_to_shrink_lruvec
   shrink_one
   shrink_node
   kswapd
  Allocated by task 5805:
   kmem_cache_alloc_noprof
   gfs2_glock_get
   gfs2_inode_lookup
   gfs2_dir_search
   gfs2_lookupi
   init_journal
  Freed by task 15:
   kmem_cache_free
   rcu_core
  Last potentially related work creation:
   call_rcu
   gfs2_glock_free
   gfs2_evict_inode
   evict
   gfs2_jindex_free
   init_journal
  The buggy address belongs to the object at ffff88804805e8c0
   which belongs to the cache gfs2_glock(aspace) of size 1176

syzbot hits this with an image where an indirect block of a journal
inode contains ~0ULL.  gfs2_jdesc_check() walks the metadata tree, the
read of that block fails, the mount is aborted and the journal inode
glocks go away with the folio still cached.

Such a block can never be read anyway.  Reject block numbers beyond the
end of the device in gfs2_meta_read() and gfs2_meta_ra(), skip them in
the readahead helpers, and fail journal replay if a log descriptor
points past the end of the device.

Generative AI tools (Claude Code) were used for consultation and
research, to automate the tedious parts of debugging (running the
reproducer in loops, adding temporary debug checks and going through
the logs) and to draft the fix.  All code was manually reviewed.

Reported-by: syzbot+4c7590f1cee06597e43a@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=4c7590f1cee06597e43a
Fixes: b3b94faa5fe5 ("[GFS2] The core of GFS2")
Cc: stable@vger.kernel.org
Signed-off-by: Abhiraj Dutta <abhirajdutta7@gmail.com>
---
Tested in a KASAN VM on v7.4-rc4 (the patch applies to gfs2/for-next
as is) by mounting the syzbot image in six parallel loops and then
forcing reclaim with memory.reclaim.  Without the patch, none of 11 runs
got through: 7 hit the same use-after-free (reported in isolate_folios(),
where folio_evictable() was inlined) or a GPF in shrink_folio_list(),
and 4 hung before anything reached the log.  With the patch, 10 runs of
3600-5700 mounts each were clean, and so were 3 more runs (2600-2800
mounts each) with this exact version.  Some temporary debug checks
showed glocks being freed with exactly one folio left, at index
ULONG_MAX, for block 0xffffffffffffffff.

On a healthy filesystem: 6000-entry directories and 64MB of data, then
a crash with a dirty journal, and a second crash right after fsyncing
metadata and a journaled-data file, where the next mount replayed 412
journal blocks.  Data checksums and fsck.gfs2 were clean after both.
All of this also passed with lockdep, PROVE_RCU, DEBUG_PAGEALLOC and
DEBUG_OBJECTS_RCU_HEAD enabled.  Not tested: lock_dlm.

One behaviour change: gfs2_meta_read() and gfs2_meta_ra() now withdraw
on such a block, where the failed read used to just return -EIO outside
of a transaction.  A pointer past the end of the device can only mean
corrupt metadata, and gfs2 already withdraws for a pointer to the wrong
type of block (gfs2_metatype_check()) and for a resource group past the
end of the device (compute_bitstructs()), so I went with that.  This
assumes the device size the node sees is current.  The bug would still
be fixed without the gfs2_consist() calls, since no buffer gets created
either way.

The missing check is as old as gfs2, hence the Fixes tag.  The
use-after-free itself became possible with commit 009d851837ab ("GFS2:
Metadata address space clean up").
---
 fs/gfs2/bmap.c     |  3 ++-
 fs/gfs2/dir.c      |  7 ++++++-
 fs/gfs2/lops.c     | 13 +++++++++++++
 fs/gfs2/meta_io.c  | 15 +++++++++++++--
 fs/gfs2/meta_io.h  | 10 ++++++++++
 fs/gfs2/recovery.c |  2 ++
 6 files changed, 46 insertions(+), 4 deletions(-)

diff --git a/fs/gfs2/bmap.c b/fs/gfs2/bmap.c
index 4916bcfa1f..07f2e6d1f9 100644
--- a/fs/gfs2/bmap.c
+++ b/fs/gfs2/bmap.c
@@ -296,12 +296,13 @@ static void clone_metapath(struct metapath *clone, struct metapath *mp)
 
 static void gfs2_metapath_ra(struct gfs2_glock *gl, __be64 *start, __be64 *end)
 {
+	struct gfs2_sbd *sdp = glock_sbd(gl);
 	const __be64 *t;
 
 	for (t = start; t < end; t++) {
 		struct buffer_head *rabh;
 
-		if (!*t)
+		if (!*t || !gfs2_block_valid(sdp, be64_to_cpu(*t)))
 			continue;
 
 		rabh = gfs2_getbuf(gl, be64_to_cpu(*t), CREATE);
diff --git a/fs/gfs2/dir.c b/fs/gfs2/dir.c
index 6cfe335fd5..b1fd8b3227 100644
--- a/fs/gfs2/dir.c
+++ b/fs/gfs2/dir.c
@@ -305,6 +305,10 @@ static int gfs2_dir_read_data(struct gfs2_inode *ip, __be64 *buf,
 				goto fail;
 			BUG_ON(extlen < 1);
 			bh = gfs2_meta_ra(gl, dblock, extlen);
+			if (!bh) {
+				error = -EIO;
+				goto fail;
+			}
 		} else {
 			error = gfs2_meta_read(gl, dblock, DIO_WAIT, 0, &bh);
 			if (error)
@@ -1494,6 +1498,7 @@ static void gfs2_dir_readahead(struct inode *inode, unsigned hsize, u32 index,
 {
 	struct gfs2_glock *gl = gfs2_inode_glock(inode);
 	struct gfs2_inode *ip = GFS2_I(inode);
+	struct gfs2_sbd *sdp = GFS2_SB(inode);
 	struct buffer_head *bh;
 	u64 blocknr = 0, last;
 	unsigned count;
@@ -1510,7 +1515,7 @@ static void gfs2_dir_readahead(struct inode *inode, unsigned hsize, u32 index,
 		last = blocknr;
 		blocknr = be64_to_cpu(ip->i_hash_cache[f_ra->start]);
 		f_ra->start++;
-		if (blocknr == last)
+		if (blocknr == last || !gfs2_block_valid(sdp, blocknr))
 			continue;
 
 		bh = gfs2_getbuf(gl, blocknr, 1);
diff --git a/fs/gfs2/lops.c b/fs/gfs2/lops.c
index 657edd406d..d2d16f0e72 100644
--- a/fs/gfs2/lops.c
+++ b/fs/gfs2/lops.c
@@ -803,6 +803,12 @@ static int buf_lo_scan_elements(struct gfs2_jdesc *jd, u32 start,
 		if (gfs2_revoke_check(jd, blkno, start))
 			continue;
 
+		if (!gfs2_block_valid(sdp, blkno)) {
+			fs_err(sdp, "jid=%u: block %llu is out of range\n",
+			       jd->jd_jid, blkno);
+			return -EIO;
+		}
+
 		error = gfs2_replay_read_block(jd, start, &bh_log);
 		if (error)
 			return error;
@@ -999,6 +1005,7 @@ static int databuf_lo_scan_elements(struct gfs2_jdesc *jd, u32 start,
 				    struct gfs2_log_descriptor *ld,
 				    __be64 *ptr, int pass)
 {
+	struct gfs2_sbd *sdp = GFS2_SB(jd->jd_inode);
 	struct gfs2_glock *gl = gfs2_inode_glock(jd->jd_inode);
 	unsigned int blks = be32_to_cpu(ld->ld_data1);
 	struct buffer_head *bh_log, *bh_ip;
@@ -1019,6 +1026,12 @@ static int databuf_lo_scan_elements(struct gfs2_jdesc *jd, u32 start,
 		if (gfs2_revoke_check(jd, blkno, start))
 			continue;
 
+		if (!gfs2_block_valid(sdp, blkno)) {
+			fs_err(sdp, "jid=%u: block %llu is out of range\n",
+			       jd->jd_jid, blkno);
+			return -EIO;
+		}
+
 		error = gfs2_replay_read_block(jd, start, &bh_log);
 		if (error)
 			return error;
diff --git a/fs/gfs2/meta_io.c b/fs/gfs2/meta_io.c
index 63591a4be1..3ba86cf1a3 100644
--- a/fs/gfs2/meta_io.c
+++ b/fs/gfs2/meta_io.c
@@ -269,6 +269,12 @@ int gfs2_meta_read(struct gfs2_glock *gl, u64 blkno, int flags,
 		return -EIO;
 	}
 
+	if (!gfs2_block_valid(sdp, blkno)) {
+		gfs2_consist(sdp);
+		*bhp = NULL;
+		return -EIO;
+	}
+
 	*bhp = bh = gfs2_getbuf(gl, blkno, CREATE);
 
 	lock_buffer(bh);
@@ -280,7 +286,7 @@ int gfs2_meta_read(struct gfs2_glock *gl, u64 blkno, int flags,
 		bhs[num++] = bh;
 	}
 
-	if (rahead) {
+	if (rahead && gfs2_block_valid(sdp, blkno + 1)) {
 		bh = gfs2_getbuf(gl, blkno + 1, CREATE);
 
 		lock_buffer(bh);
@@ -490,6 +496,11 @@ struct buffer_head *gfs2_meta_ra(struct gfs2_glock *gl, u64 dblock, u32 extlen)
 	if (extlen > max_ra)
 		extlen = max_ra;
 
+	if (!gfs2_block_valid(sdp, dblock)) {
+		gfs2_consist(sdp);
+		return NULL;
+	}
+
 	first_bh = gfs2_getbuf(gl, dblock, CREATE);
 
 	if (buffer_uptodate(first_bh))
@@ -499,7 +510,7 @@ struct buffer_head *gfs2_meta_ra(struct gfs2_glock *gl, u64 dblock, u32 extlen)
 	dblock++;
 	extlen--;
 
-	while (extlen) {
+	while (extlen && gfs2_block_valid(sdp, dblock)) {
 		bh = gfs2_getbuf(gl, dblock, CREATE);
 
 		bh_readahead(bh, REQ_RAHEAD | REQ_META | REQ_PRIO);
diff --git a/fs/gfs2/meta_io.h b/fs/gfs2/meta_io.h
index ec76215bfb..7a838ab940 100644
--- a/fs/gfs2/meta_io.h
+++ b/fs/gfs2/meta_io.h
@@ -7,6 +7,7 @@
 #ifndef __DIO_DOT_H__
 #define __DIO_DOT_H__
 
+#include <linux/blkdev.h>
 #include <linux/buffer_head.h>
 #include <linux/string.h>
 #include "incore.h"
@@ -48,6 +49,15 @@ static inline struct gfs2_sbd *gfs2_mapping2sbd(struct address_space *mapping)
 		return inode->i_sb->s_fs_info;
 }
 
+/*
+ * Block numbers from disk can be garbage.  A buffer for a block near ~0 ends up
+ * at a page index that truncate_inode_pages_final() never reaches.
+ */
+static inline bool gfs2_block_valid(struct gfs2_sbd *sdp, u64 blkno)
+{
+	return blkno < sb_bdev_nr_blocks(sdp->sd_vfs);
+}
+
 struct buffer_head *gfs2_meta_new(struct gfs2_glock *gl, u64 blkno);
 int gfs2_meta_read(struct gfs2_glock *gl, u64 blkno, int flags,
 		   int rahead, struct buffer_head **bhp);
diff --git a/fs/gfs2/recovery.c b/fs/gfs2/recovery.c
index f950eb95f4..18c18fa5f5 100644
--- a/fs/gfs2/recovery.c
+++ b/fs/gfs2/recovery.c
@@ -49,6 +49,8 @@ int gfs2_replay_read_block(struct gfs2_jdesc *jd, unsigned int blk,
 	}
 
 	*bh = gfs2_meta_ra(gl, dblock, extlen);
+	if (!*bh)
+		return -EIO;
 
 	return error;
 }

---
base-commit: 81ea845df2ccf0acbe3be6cdf936ee222c2fd6c9
change-id: 20261127-gfs2-b4-6c9ed8ceff85

Best regards,
-- 
Abhiraj Dutta <abhirajdutta7@gmail.com>

