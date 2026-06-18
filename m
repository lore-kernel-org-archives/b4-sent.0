From: Alberto Ruiz <aruiz@redhat.com>
Date: Thu, 18 Jun 2026 17:13:44 +0100
Subject: [PATCH RFC 1/2] erofs: add memory-backed mode for non-page-aligned
 mount
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260618-erofs-memback-v1-1-5aa7006a241a@redhat.com>
References: <20260618-erofs-memback-v1-0-5aa7006a241a@redhat.com>
In-Reply-To: <20260618-erofs-memback-v1-0-5aa7006a241a@redhat.com>
To: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>, 
 Yue Hu <zbestahu@gmail.com>, Jeffle Xu <jefflexu@linux.alibaba.com>, 
 Sandeep Dhavale <dhavale@google.com>, Hongbo Li <lihongbo22@huawei.com>, 
 Chunhai Guo <guochunhai@vivo.com>
Cc: linux-kernel@vger.kernel.org, linux-erofs@lists.ozlabs.org, 
 Javier Martinez Canillas <javierm@redhat.com>, 
 Brian Masney <bmasney@redhat.com>, Eric Curtin <ericcurtin17@gmail.com>, 
 Alberto Ruiz <aruiz@redhat.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781799229; l=18009;
 i=aruiz@redhat.com; s=20260612; h=from:subject:message-id;
 bh=+aI05DUEyRnhEtfFMe6jGTiz+NQLr4iaBIt1I8BeAgs=;
 b=i9KHG1L7+qMwbzjZhOG13oLa/klYVso8+GwNHkA7xWZOIXH3D+AMO1S3g2k+DVyw0nTYrfn7/
 nHNcv96AeMZC1AVdU6f2dMGwJr8qQBNsvhN75NiprKmg4vpktMysIUx
X-Developer-Key: i=aruiz@redhat.com; a=ed25519;
 pk=d1doFQwve1B/jU9nG5oPl1W5d+t+iFrjkkwk/hD97Ow=
X-Endpoint-Received: by B4 Relay for aruiz@redhat.com/20260612 with auth_id=818
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new "memback" backing mode to EROFS that reads directly from a
contiguous kernel memory region without going through the block layer.

The metadata path (erofs_bread) achieves true zero-copy by using
virt_to_page() + kmap_local_page() to access pages directly,
bypassing the page cache entirely.

The file data path uses new address_space_operations
(erofs_memback_aops) that resolve logical-to-physical offsets via
erofs_map_blocks() and memcpy from the backing memory into file page
cache folios -- one copy, same as the current block device approach
but without any block layer involvement.

For compressed data, erofs_memback_submit_bio() walks bio segments and
copies compressed data from memory, following the same dispatch pattern
used by the existing fileio and fscache modes.

Non-page-aligned memory regions are handled naturally via
offset_in_page() for metadata and byte-granular memcpy for data,
allowing EROFS images at arbitrary offsets regardless of page size.

A kernel-internal API erofs_memback_set_pending(data, size) stores the
memory region parameters in static globals which erofs_fc_get_tree()
consumes on the next mount via get_tree_nodev(), allowing early boot
code to trigger a standard EROFS mount without exposing kernel pointers
as mount option strings.

Assisted-by: Claude:claude-opus-4-6
Signed-off-by: Alberto Ruiz <aruiz@redhat.com>
---
 fs/erofs/Makefile   |   1 +
 fs/erofs/data.c     |  33 +++++++++-
 fs/erofs/internal.h |  53 +++++++++++-----
 fs/erofs/memback.c  | 169 ++++++++++++++++++++++++++++++++++++++++++++++++++++
 fs/erofs/super.c    |  38 ++++++++++--
 fs/erofs/zdata.c    |  16 +++--
 6 files changed, 284 insertions(+), 26 deletions(-)

diff --git a/fs/erofs/Makefile b/fs/erofs/Makefile
index a80e1762b607..8f3b73835328 100644
--- a/fs/erofs/Makefile
+++ b/fs/erofs/Makefile
@@ -10,4 +10,5 @@ erofs-$(CONFIG_EROFS_FS_ZIP_ZSTD) += decompressor_zstd.o
 erofs-$(CONFIG_EROFS_FS_ZIP_ACCEL) += decompressor_crypto.o
 erofs-$(CONFIG_EROFS_FS_BACKED_BY_FILE) += fileio.o
 erofs-$(CONFIG_EROFS_FS_ONDEMAND) += fscache.o
+erofs-y += memback.o
 erofs-$(CONFIG_EROFS_FS_PAGE_CACHE_SHARE) += ishare.o
diff --git a/fs/erofs/data.c b/fs/erofs/data.c
index 44da21c9d777..26fff07df5bd 100644
--- a/fs/erofs/data.c
+++ b/fs/erofs/data.c
@@ -22,7 +22,8 @@ void erofs_put_metabuf(struct erofs_buf *buf)
 	if (!buf->page)
 		return;
 	erofs_unmap_metabuf(buf);
-	folio_put(page_folio(buf->page));
+	if (!buf->memback)
+		folio_put(page_folio(buf->page));
 	buf->page = NULL;
 }
 
@@ -45,6 +46,25 @@ void *erofs_bread(struct erofs_buf *buf, erofs_off_t offset, bool need_kmap)
 			return ERR_PTR(err);
 	}
 
+	if (buf->memback) {
+		void *addr = (char *)buf->mapping + offset;
+		struct page *page;
+
+		if (offset >= buf->memback_size)
+			return ERR_PTR(-EFSCORRUPTED);
+
+		page = virt_to_page(addr);
+		if (buf->page != page) {
+			erofs_unmap_metabuf(buf);
+			buf->page = page;
+		}
+		if (!need_kmap)
+			return NULL;
+		if (!buf->base)
+			buf->base = kmap_local_page(buf->page);
+		return buf->base + offset_in_page(addr);
+	}
+
 	if (buf->page) {
 		folio = page_folio(buf->page);
 		if (folio_file_page(folio, index) != buf->page)
@@ -70,15 +90,24 @@ int erofs_init_metabuf(struct erofs_buf *buf, struct super_block *sb,
 	struct erofs_sb_info *sbi = EROFS_SB(sb);
 
 	buf->file = NULL;
+	buf->memback = false;
 	if (in_metabox) {
 		if (unlikely(!sbi->metabox_inode))
 			return -EFSCORRUPTED;
 		buf->mapping = sbi->metabox_inode->i_mapping;
 		return 0;
 	}
+	if (erofs_is_memback_mode(sbi)) {
+		buf->memback = true;
+		buf->memback_size = sbi->memback_size;
+		buf->off = 0;
+		/* Reuse the mapping pointer to carry the base address */
+		buf->mapping = (struct address_space *)sbi->memback_data;
+		return 0;
+	}
 	buf->off = sbi->dif0.fsoff;
 	if (erofs_is_fileio_mode(sbi)) {
-		buf->file = sbi->dif0.file;	/* some fs like FUSE needs it */
+		buf->file = sbi->dif0.file; /* some fs like FUSE needs it */
 		buf->mapping = buf->file->f_mapping;
 	} else if (erofs_is_fscache_mode(sb))
 		buf->mapping = sbi->dif0.fscache->inode->i_mapping;
diff --git a/fs/erofs/internal.h b/fs/erofs/internal.h
index 4792490161ec..75014f8b1596 100644
--- a/fs/erofs/internal.h
+++ b/fs/erofs/internal.h
@@ -103,7 +103,10 @@ struct erofs_xattr_prefix_item {
 
 struct erofs_sb_info {
 	struct erofs_device_info dif0;
-	struct erofs_mount_opts opt;	/* options */
+	struct erofs_mount_opts opt; /* options */
+
+	void *memback_data;
+	unsigned long memback_size;
 #ifdef CONFIG_EROFS_FS_ZIP
 	/* list for all registered superblocks, mainly for shrinker */
 	struct list_head list;
@@ -176,11 +179,16 @@ struct erofs_sb_info {
 #define EROFS_MOUNT_DAX_ALWAYS		0x00000040
 #define EROFS_MOUNT_DAX_NEVER		0x00000080
 #define EROFS_MOUNT_DIRECT_IO		0x00000100
-#define EROFS_MOUNT_INODE_SHARE		0x00000200
+#define EROFS_MOUNT_INODE_SHARE 0x00000200
+
+#define clear_opt(opt, option) ((opt)->mount_opt &= ~EROFS_MOUNT_##option)
+#define set_opt(opt, option) ((opt)->mount_opt |= EROFS_MOUNT_##option)
+#define test_opt(opt, option) ((opt)->mount_opt & EROFS_MOUNT_##option)
 
-#define clear_opt(opt, option)	((opt)->mount_opt &= ~EROFS_MOUNT_##option)
-#define set_opt(opt, option)	((opt)->mount_opt |= EROFS_MOUNT_##option)
-#define test_opt(opt, option)	((opt)->mount_opt & EROFS_MOUNT_##option)
+static inline bool erofs_is_memback_mode(struct erofs_sb_info *sbi)
+{
+	return sbi->memback_data != NULL;
+}
 
 static inline bool erofs_is_fileio_mode(struct erofs_sb_info *sbi)
 {
@@ -192,7 +200,8 @@ extern struct file_system_type erofs_anon_fs_type;
 static inline bool erofs_is_fscache_mode(struct super_block *sb)
 {
 	return IS_ENABLED(CONFIG_EROFS_FS_ONDEMAND) &&
-			!erofs_is_fileio_mode(EROFS_SB(sb)) && !sb->s_bdev;
+	       !erofs_is_memback_mode(EROFS_SB(sb)) &&
+	       !erofs_is_fileio_mode(EROFS_SB(sb)) && !sb->s_bdev;
 }
 
 enum {
@@ -205,13 +214,15 @@ struct erofs_buf {
 	struct address_space *mapping;
 	struct file *file;
 	u64 off;
+	unsigned long memback_size;
 	struct page *page;
 	void *base;
+	bool memback;
 };
-#define __EROFS_BUF_INITIALIZER	((struct erofs_buf){ .page = NULL })
+#define __EROFS_BUF_INITIALIZER ((struct erofs_buf){ .page = NULL })
 
-#define erofs_blknr(sb, pos)	((erofs_blk_t)((pos) >> (sb)->s_blocksize_bits))
-#define erofs_blkoff(sb, pos)	((pos) & ((sb)->s_blocksize - 1))
+#define erofs_blknr(sb, pos) ((erofs_blk_t)((pos) >> (sb)->s_blocksize_bits))
+#define erofs_blkoff(sb, pos) ((pos) & ((sb)->s_blocksize - 1))
 #define erofs_pos(sb, blk)	((erofs_off_t)(blk) << (sb)->s_blocksize_bits)
 #define erofs_iblks(i)	(round_up((i)->i_size, i_blocksize(i)) >> (i)->i_blkbits)
 
@@ -414,6 +425,7 @@ extern const struct super_operations erofs_sops;
 
 extern const struct address_space_operations erofs_aops;
 extern const struct address_space_operations erofs_fileio_aops;
+extern const struct address_space_operations erofs_memback_aops;
 extern const struct address_space_operations z_erofs_aops;
 extern const struct address_space_operations erofs_fscache_access_aops;
 
@@ -476,11 +488,14 @@ erofs_get_aops(struct inode *realinode, bool no_fscache)
 	if (erofs_inode_is_data_compressed(EROFS_I(realinode)->datalayout)) {
 		if (!IS_ENABLED(CONFIG_EROFS_FS_ZIP))
 			return ERR_PTR(-EOPNOTSUPP);
-		DO_ONCE_LITE_IF(realinode->i_blkbits != PAGE_SHIFT,
-			  erofs_info, realinode->i_sb,
-			  "EXPERIMENTAL EROFS subpage compressed block support in use. Use at your own risk!");
+		DO_ONCE_LITE_IF(
+			realinode->i_blkbits != PAGE_SHIFT, erofs_info,
+			realinode->i_sb,
+			"EXPERIMENTAL EROFS subpage compressed block support in use. Use at your own risk!");
 		return &z_erofs_aops;
 	}
+	if (erofs_is_memback_mode(EROFS_SB(realinode->i_sb)))
+		return &erofs_memback_aops;
 	if (IS_ENABLED(CONFIG_EROFS_FS_ONDEMAND) && !no_fscache &&
 	    erofs_is_fscache_mode(realinode->i_sb))
 		return &erofs_fscache_access_aops;
@@ -542,10 +557,20 @@ int z_erofs_parse_cfgs(struct super_block *sb, struct erofs_super_block *dsb);
 struct bio *erofs_fileio_bio_alloc(struct erofs_map_dev *mdev);
 void erofs_fileio_submit_bio(struct bio *bio);
 #else
-static inline struct bio *erofs_fileio_bio_alloc(struct erofs_map_dev *mdev) { return NULL; }
-static inline void erofs_fileio_submit_bio(struct bio *bio) {}
+static inline struct bio *erofs_fileio_bio_alloc(struct erofs_map_dev *mdev)
+{
+	return NULL;
+}
+static inline void erofs_fileio_submit_bio(struct bio *bio)
+{
+}
 #endif
 
+struct bio *erofs_memback_bio_alloc(struct erofs_map_dev *mdev);
+void erofs_memback_submit_bio(struct bio *bio);
+
+void __init erofs_memback_set_pending(void *data, unsigned long size);
+
 #ifdef CONFIG_EROFS_FS_ONDEMAND
 int erofs_fscache_register_fs(struct super_block *sb);
 void erofs_fscache_unregister_fs(struct super_block *sb);
diff --git a/fs/erofs/memback.c b/fs/erofs/memback.c
new file mode 100644
index 000000000000..3e965f35eabe
--- /dev/null
+++ b/fs/erofs/memback.c
@@ -0,0 +1,169 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Memory-backed EROFS support.
+ *
+ * Serves EROFS data directly from a contiguous kernel memory region
+ * (e.g. an initrd) without going through the block layer.
+ */
+#include "internal.h"
+#include <trace/events/erofs.h>
+
+struct erofs_memback_rq {
+	struct bio_vec bvecs[16];
+	struct bio bio;
+	struct erofs_sb_info *sbi;
+};
+
+static void erofs_memback_rq_submit(struct erofs_memback_rq *rq)
+{
+	struct erofs_sb_info *sbi;
+	struct bio_vec bv;
+	struct bvec_iter iter;
+	loff_t pos;
+
+	if (!rq)
+		return;
+
+	sbi = rq->sbi;
+	pos = rq->bio.bi_iter.bi_sector << SECTOR_SHIFT;
+
+	bio_for_each_segment(bv, &rq->bio, iter) {
+		void *dst = bvec_kmap_local(&bv);
+		unsigned long avail = sbi->memback_size - pos;
+		unsigned long len = min_t(unsigned long, bv.bv_len, avail);
+
+		if (pos < sbi->memback_size && len)
+			memcpy(dst, (char *)sbi->memback_data + pos, len);
+		if (len < bv.bv_len)
+			memset(dst + len, 0, bv.bv_len - len);
+		kunmap_local(dst);
+		pos += bv.bv_len;
+	}
+	bio_endio(&rq->bio);
+	bio_uninit(&rq->bio);
+	kfree(rq);
+}
+
+static struct erofs_memback_rq *
+erofs_memback_rq_alloc(struct erofs_map_dev *mdev)
+{
+	struct erofs_memback_rq *rq =
+		kzalloc(sizeof(*rq), GFP_KERNEL | __GFP_NOFAIL);
+
+	bio_init(&rq->bio, NULL, rq->bvecs, ARRAY_SIZE(rq->bvecs), REQ_OP_READ);
+	rq->sbi = EROFS_SB(mdev->m_sb);
+	return rq;
+}
+
+struct bio *erofs_memback_bio_alloc(struct erofs_map_dev *mdev)
+{
+	return &erofs_memback_rq_alloc(mdev)->bio;
+}
+
+void erofs_memback_submit_bio(struct bio *bio)
+{
+	erofs_memback_rq_submit(
+		container_of(bio, struct erofs_memback_rq, bio));
+}
+
+struct erofs_memback_io {
+	struct erofs_map_blocks map;
+	struct erofs_map_dev dev;
+	struct erofs_memback_rq *rq;
+};
+
+static int erofs_memback_scan_folio(struct erofs_memback_io *io,
+				    struct inode *inode, struct folio *folio)
+{
+	struct erofs_sb_info *sbi = EROFS_SB(inode->i_sb);
+	struct erofs_map_blocks *map = &io->map;
+	unsigned int cur = 0, end = folio_size(folio), len, attached = 0;
+	loff_t pos = folio_pos(folio), ofs;
+	int err = 0;
+
+	erofs_onlinefolio_init(folio);
+	while (cur < end) {
+		if (!in_range(pos + cur, map->m_la, map->m_llen)) {
+			map->m_la = pos + cur;
+			map->m_llen = end - cur;
+			err = erofs_map_blocks(inode, map);
+			if (err)
+				break;
+		}
+
+		ofs = pos + cur - map->m_la;
+		len = min_t(loff_t, map->m_llen - ofs, end - cur);
+		if (map->m_flags & EROFS_MAP_META) {
+			struct erofs_buf buf = __EROFS_BUF_INITIALIZER;
+			void *src;
+
+			src = erofs_read_metabuf(&buf, inode->i_sb,
+						 map->m_pa + ofs,
+						 erofs_inode_in_metabox(inode));
+			if (IS_ERR(src)) {
+				err = PTR_ERR(src);
+				break;
+			}
+			memcpy_to_folio(folio, cur, src, len);
+			erofs_put_metabuf(&buf);
+		} else if (!(map->m_flags & EROFS_MAP_MAPPED)) {
+			folio_zero_segment(folio, cur, cur + len);
+			attached = 0;
+		} else {
+			loff_t pa = map->m_pa + ofs;
+
+			if (pa + len > sbi->memback_size) {
+				err = -EFSCORRUPTED;
+				break;
+			}
+			memcpy_to_folio(folio, cur,
+					(char *)sbi->memback_data + pa, len);
+			attached = 1;
+		}
+		cur += len;
+	}
+	erofs_onlinefolio_end(folio, err, false);
+	return err;
+}
+
+static int erofs_memback_read_folio(struct file *file, struct folio *folio)
+{
+	bool need_iput;
+	struct inode *realinode =
+		erofs_real_inode(folio_inode(folio), &need_iput);
+	struct erofs_memback_io io = {};
+	int err;
+
+	trace_erofs_read_folio(realinode, folio, true);
+	err = erofs_memback_scan_folio(&io, realinode, folio);
+	if (need_iput)
+		iput(realinode);
+	return err;
+}
+
+static void erofs_memback_readahead(struct readahead_control *rac)
+{
+	bool need_iput;
+	struct inode *realinode =
+		erofs_real_inode(rac->mapping->host, &need_iput);
+	struct erofs_memback_io io = {};
+	struct folio *folio;
+	int err;
+
+	trace_erofs_readahead(realinode, readahead_index(rac),
+			      readahead_count(rac), true);
+	while ((folio = readahead_folio(rac))) {
+		err = erofs_memback_scan_folio(&io, realinode, folio);
+		if (err && err != -EINTR)
+			erofs_err(realinode->i_sb,
+				  "readahead error at folio %lu @ nid %llu",
+				  folio->index, EROFS_I(realinode)->nid);
+	}
+	if (need_iput)
+		iput(realinode);
+}
+
+const struct address_space_operations erofs_memback_aops = {
+	.read_folio = erofs_memback_read_folio,
+	.readahead = erofs_memback_readahead,
+};
diff --git a/fs/erofs/super.c b/fs/erofs/super.c
index 802add6652fd..724389d79aac 100644
--- a/fs/erofs/super.c
+++ b/fs/erofs/super.c
@@ -625,9 +625,8 @@ static void erofs_set_sysfs_name(struct super_block *sb)
 					     sbi->fsid);
 	else if (sbi->fsid)
 		super_set_sysfs_name_generic(sb, "%s", sbi->fsid);
-	else if (erofs_is_fileio_mode(sbi))
-		super_set_sysfs_name_generic(sb, "%s",
-					     bdi_dev_name(sb->s_bdi));
+	else if (erofs_is_memback_mode(sbi) || erofs_is_fileio_mode(sbi))
+		super_set_sysfs_name_generic(sb, "%s", bdi_dev_name(sb->s_bdi));
 	else
 		super_set_sysfs_name_id(sb);
 }
@@ -708,7 +707,7 @@ static int erofs_fc_fill_super(struct super_block *sb, struct fs_context *fc)
 			return -EINVAL;
 		}
 
-		if (erofs_is_fileio_mode(sbi)) {
+		if (erofs_is_memback_mode(sbi) || erofs_is_fileio_mode(sbi)) {
 			sb->s_blocksize = 1 << sbi->blkszbits;
 			sb->s_blocksize_bits = sbi->blkszbits;
 		} else if (!sb_set_blocksize(sb, 1 << sbi->blkszbits)) {
@@ -791,11 +790,39 @@ static int erofs_fc_fill_super(struct super_block *sb, struct fs_context *fc)
 	return 0;
 }
 
+/*
+ * Pending memback parameters, consumed during erofs_fc_get_tree().
+ * Only used by single-threaded __init code, no synchronization needed.
+ */
+static void *erofs_memback_pending_data;
+static unsigned long erofs_memback_pending_size;
+
+void __init erofs_memback_set_pending(void *data, unsigned long size)
+{
+	erofs_memback_pending_data = data;
+	erofs_memback_pending_size = size;
+}
+
+static void erofs_memback_consume_pending(struct erofs_sb_info *sbi)
+{
+	sbi->memback_data = erofs_memback_pending_data;
+	sbi->memback_size = erofs_memback_pending_size;
+	erofs_memback_pending_data = NULL;
+	erofs_memback_pending_size = 0;
+}
+
 static int erofs_fc_get_tree(struct fs_context *fc)
 {
 	struct erofs_sb_info *sbi = fc->s_fs_info;
 	int ret;
 
+	if (erofs_memback_pending_data) {
+		erofs_memback_consume_pending(sbi);
+		return get_tree_nodev(fc, erofs_fc_fill_super);
+	}
+	if (erofs_is_memback_mode(sbi))
+		return get_tree_nodev(fc, erofs_fc_fill_super);
+
 	if (IS_ENABLED(CONFIG_EROFS_FS_ONDEMAND) && sbi->fsid)
 		return get_tree_nodev(fc, erofs_fc_fill_super);
 
@@ -928,7 +955,8 @@ static void erofs_kill_sb(struct super_block *sb)
 {
 	struct erofs_sb_info *sbi = EROFS_SB(sb);
 
-	if ((IS_ENABLED(CONFIG_EROFS_FS_ONDEMAND) && sbi->fsid) ||
+	if (erofs_is_memback_mode(sbi) ||
+	    (IS_ENABLED(CONFIG_EROFS_FS_ONDEMAND) && sbi->fsid) ||
 	    sbi->dif0.file)
 		kill_anon_super(sb);
 	else
diff --git a/fs/erofs/zdata.c b/fs/erofs/zdata.c
index c6240dccbb0f..af4ddb492660 100644
--- a/fs/erofs/zdata.c
+++ b/fs/erofs/zdata.c
@@ -1709,10 +1709,12 @@ static void z_erofs_submit_queue(struct z_erofs_frontend *f,
 			       sb->s_blocksize);
 		do {
 			bvec.bv_page = NULL;
-			if (bio && (cur != last_pa ||
-				    bio->bi_bdev != mdev.m_bdev)) {
+			if (bio &&
+			    (cur != last_pa || bio->bi_bdev != mdev.m_bdev)) {
 drain_io:
-				if (erofs_is_fileio_mode(EROFS_SB(sb)))
+				if (erofs_is_memback_mode(EROFS_SB(sb)))
+					erofs_memback_submit_bio(bio);
+				else if (erofs_is_fileio_mode(EROFS_SB(sb)))
 					erofs_fileio_submit_bio(bio);
 				else if (erofs_is_fscache_mode(sb))
 					erofs_fscache_submit_bio(bio);
@@ -1742,7 +1744,9 @@ static void z_erofs_submit_queue(struct z_erofs_frontend *f,
 			}
 
 			if (!bio) {
-				if (erofs_is_fileio_mode(EROFS_SB(sb)))
+				if (erofs_is_memback_mode(EROFS_SB(sb)))
+					bio = erofs_memback_bio_alloc(&mdev);
+				else if (erofs_is_fileio_mode(EROFS_SB(sb)))
 					bio = erofs_fileio_bio_alloc(&mdev);
 				else if (erofs_is_fscache_mode(sb))
 					bio = erofs_fscache_bio_alloc(&mdev);
@@ -1772,7 +1776,9 @@ static void z_erofs_submit_queue(struct z_erofs_frontend *f,
 	} while (next != Z_EROFS_PCLUSTER_TAIL);
 
 	if (bio) {
-		if (erofs_is_fileio_mode(EROFS_SB(sb)))
+		if (erofs_is_memback_mode(EROFS_SB(sb)))
+			erofs_memback_submit_bio(bio);
+		else if (erofs_is_fileio_mode(EROFS_SB(sb)))
 			erofs_fileio_submit_bio(bio);
 		else if (erofs_is_fscache_mode(sb))
 			erofs_fscache_submit_bio(bio);

-- 
2.53.0

