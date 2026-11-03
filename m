From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 03 Nov 2026 15:29:33 +0900
Subject: [PATCH v2 3/3] erofs: allocate file-backed mount requests from a
 bio_set
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-erofs-fileio-bioset-v2-3-5b91af423f72@samsung.com>
References: <20261103-erofs-fileio-bioset-v2-0-5b91af423f72@samsung.com>
In-Reply-To: <20261103-erofs-fileio-bioset-v2-0-5b91af423f72@samsung.com>
To: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>
Cc: Yue Hu <zbestahu@gmail.com>, Jingbo Xu <jefflexu@163.com>, 
 Sandeep Dhavale <dhavale@google.com>, Hongbo Li <hongbohbli@tencent.com>, 
 Chunhai Guo <guochunhai@vivo.com>, linux-erofs@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793687370; l=7189;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=JbqJh/FkhKfvIvt36XGJLGfatIdEF7acPZdHkk8NFxw=;
 b=zKwtocBw9GAhkmWaJ39Tvr1TTjwASzS7rfamB0PmQxCn1nTWpnxbyXKlHrShEnC/gc24GI2cy
 LgQ+s6c1q3JBsAe26z4GTEOylTaG4hCRhXUKX3gpdy3zxEWjM2E8dV7
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 9f74ae8c9ac9 ("erofs: shorten bvecs[] for file-backed
mounts"), a file-backed request holds at most 16 bvecs. A 1 MiB
readahead window of order-0 folios then takes several backing reads.

Allocate requests from a bio_set, using the mempool that commit
considered. Each path submits its request before it allocates the
next one.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
A backing read through loop, FUSE, NFS or a fanotify listener may
allocate from this pool in another task, as fs_bio_set users do under
loop. NFS LOCALIO may allocate in the same task while the outer
request holds an element. Such a request waits for returned reserves.

Tested in a QEMU guest:
- read_ahead_kb=1024, 1 MiB read() calls on 256 files of 1 MiB:
  0.119 s instead of 0.141 s on mm-new with "mm/readahead: align the
  async window in page_cache_ra_order()" (median of 6). The other 15
  workload and mode cases changed by -22% to +0.2%.
- The same reads on erofs dev without that mm patch: 0.170 s instead
  of 0.137 s.
- failslab failing the readers' bio and biovec slab allocations: the
  reserves served 48 to 499 bio allocations in each of 8 cases. All
  data read back correctly.
---
 fs/erofs/fileio.c   | 47 +++++++++++++++++++++++++++++++++++------------
 fs/erofs/internal.h |  4 ++++
 fs/erofs/super.c    |  7 +++++++
 3 files changed, 46 insertions(+), 12 deletions(-)

diff --git a/fs/erofs/fileio.c b/fs/erofs/fileio.c
index e13293ec70..a0f745f0c1 100644
--- a/fs/erofs/fileio.c
+++ b/fs/erofs/fileio.c
@@ -7,13 +7,18 @@
 #include <trace/events/erofs.h>
 
 struct erofs_fileio_rq {
-	struct bio_vec bvecs[16];
-	struct bio bio;
 	struct kiocb iocb;
 	struct super_block *sb;
 	refcount_t ref;
+	/*
+	 * must be last: the fields above are the front_pad of
+	 * erofs_fileio_bioset, and inline bvecs follow the bio
+	 */
+	struct bio bio;
 };
 
+static struct bio_set erofs_fileio_bioset;
+
 struct erofs_fileio {
 	struct erofs_map_blocks map;
 	struct erofs_map_dev dev;
@@ -38,9 +43,8 @@ static void erofs_fileio_ki_complete(struct kiocb *iocb, long ret)
 		rq->bio.bi_status = errno_to_blk_status(ret);
 	}
 	bio_endio(&rq->bio);
-	bio_uninit(&rq->bio);
 	if (refcount_dec_and_test(&rq->ref))
-		kfree(rq);
+		bio_put(&rq->bio);
 }
 
 static void erofs_fileio_rq_submit(struct erofs_fileio_rq *rq)
@@ -56,22 +60,25 @@ static void erofs_fileio_rq_submit(struct erofs_fileio_rq *rq)
 	if (test_opt(&EROFS_SB(rq->sb)->opt, DIRECT_IO) &&
 	    rq->iocb.ki_filp->f_mode & FMODE_CAN_ODIRECT)
 		rq->iocb.ki_flags = IOCB_DIRECT;
-	iov_iter_bvec(&iter, ITER_DEST, rq->bvecs, rq->bio.bi_vcnt,
+	iov_iter_bvec(&iter, ITER_DEST, rq->bio.bi_io_vec, rq->bio.bi_vcnt,
 		      rq->bio.bi_iter.bi_size);
 	scoped_with_creds(rq->iocb.ki_filp->f_cred)
 		ret = vfs_iocb_iter_read(rq->iocb.ki_filp, &rq->iocb, &iter);
 	if (ret != -EIOCBQUEUED)
 		erofs_fileio_ki_complete(&rq->iocb, ret);
 	if (refcount_dec_and_test(&rq->ref))
-		kfree(rq);
+		bio_put(&rq->bio);
 }
 
 static struct erofs_fileio_rq *erofs_fileio_rq_alloc(struct super_block *sb,
-						     struct file *file)
+		struct file *file, unsigned short nr_vecs)
 {
-	struct erofs_fileio_rq *rq = kzalloc_obj(*rq, GFP_KERNEL | __GFP_NOFAIL);
+	struct bio *bio = bio_alloc_bioset(NULL, nr_vecs, REQ_OP_READ,
+					   GFP_NOIO, &erofs_fileio_bioset);
+	struct erofs_fileio_rq *rq =
+			container_of(bio, struct erofs_fileio_rq, bio);
 
-	bio_init(&rq->bio, NULL, rq->bvecs, ARRAY_SIZE(rq->bvecs), REQ_OP_READ);
+	memset(rq, 0, offsetof(struct erofs_fileio_rq, bio));
 	rq->iocb.ki_filp = file;
 	rq->sb = sb;
 	refcount_set(&rq->ref, 2);
@@ -80,7 +87,8 @@ static struct erofs_fileio_rq *erofs_fileio_rq_alloc(struct super_block *sb,
 
 struct bio *erofs_fileio_bio_alloc(struct erofs_map_dev *mdev)
 {
-	return &erofs_fileio_rq_alloc(mdev->m_sb, mdev->m_dif->file)->bio;
+	return &erofs_fileio_rq_alloc(mdev->m_sb, mdev->m_dif->file,
+				      BIO_MAX_VECS)->bio;
 }
 
 void erofs_fileio_submit_bio(struct bio *bio)
@@ -108,11 +116,14 @@ static int erofs_fileio_iomap_read_folio_range(const struct iomap_iter *iter,
 			   offset_in_folio(folio, iter->pos))) {
 		struct super_block *sb = iter_ctx->realinode->i_sb;
 		struct erofs_device_info *dif = iter->iomap.private;
+		unsigned short nr_vecs;
 
 		/* submit the existing range if there was one. */
 		if (ctx->read_ctx)
 			erofs_fileio_iomap_submit_read(iter, ctx);
-		rq = erofs_fileio_rq_alloc(sb, dif->file);
+		nr_vecs = bio_max_segs(DIV_ROUND_UP(iomap_length(iter),
+						    PAGE_SIZE));
+		rq = erofs_fileio_rq_alloc(sb, dif->file, nr_vecs);
 		rq->bio.bi_iter.bi_sector = sector;
 		bio_add_folio_nofail(&rq->bio, folio, plen,
 				offset_in_folio(folio, iter->pos));
@@ -161,10 +172,22 @@ int erofs_read_meta_folio(struct file *file, struct folio *folio)
 		}
 	}
 
-	io.rq = erofs_fileio_rq_alloc(inode->i_sb, io.dev.m_dif->file);
+	io.rq = erofs_fileio_rq_alloc(inode->i_sb, io.dev.m_dif->file, 1);
 	io.rq->bio.bi_end_io = erofs_fileio_meta_endio;
 	io.rq->bio.bi_iter.bi_sector = pos >> 9;
 	bio_add_folio_nofail(&io.rq->bio, folio, len, 0);
 	erofs_fileio_rq_submit(io.rq);
 	return 0;
 }
+
+int __init erofs_init_fileio(void)
+{
+	return bioset_init(&erofs_fileio_bioset, BIO_POOL_SIZE,
+			   offsetof(struct erofs_fileio_rq, bio),
+			   BIOSET_NEED_BVECS);
+}
+
+void erofs_exit_fileio(void)
+{
+	bioset_exit(&erofs_fileio_bioset);
+}
diff --git a/fs/erofs/internal.h b/fs/erofs/internal.h
index 924b37e06e..e6b85bde82 100644
--- a/fs/erofs/internal.h
+++ b/fs/erofs/internal.h
@@ -510,9 +510,13 @@ int z_erofs_parse_cfgs(struct super_block *sb, struct erofs_super_block *dsb);
 #ifdef CONFIG_EROFS_FS_BACKED_BY_FILE
 struct bio *erofs_fileio_bio_alloc(struct erofs_map_dev *mdev);
 void erofs_fileio_submit_bio(struct bio *bio);
+int __init erofs_init_fileio(void);
+void erofs_exit_fileio(void);
 #else
 static inline struct bio *erofs_fileio_bio_alloc(struct erofs_map_dev *mdev) { return NULL; }
 static inline void erofs_fileio_submit_bio(struct bio *bio) {}
+static inline int erofs_init_fileio(void) { return 0; }
+static inline void erofs_exit_fileio(void) {}
 #endif
 
 #ifdef CONFIG_EROFS_FS_PAGE_CACHE_SHARE
diff --git a/fs/erofs/super.c b/fs/erofs/super.c
index e92a7fa90a..17408aef92 100644
--- a/fs/erofs/super.c
+++ b/fs/erofs/super.c
@@ -1106,6 +1106,10 @@ static int __init erofs_module_init(void)
 	if (err)
 		goto ishare_err;
 
+	err = erofs_init_fileio();
+	if (err)
+		goto fileio_err;
+
 	err = register_filesystem(&erofs_fs_type);
 	if (err)
 		goto fs_err;
@@ -1113,6 +1117,8 @@ static int __init erofs_module_init(void)
 	return 0;
 
 fs_err:
+	erofs_exit_fileio();
+fileio_err:
 	erofs_exit_ishare();
 ishare_err:
 	erofs_exit_sysfs();
@@ -1128,6 +1134,7 @@ static int __init erofs_module_init(void)
 static void __exit erofs_module_exit(void)
 {
 	unregister_filesystem(&erofs_fs_type);
+	erofs_exit_fileio();
 	erofs_exit_ishare();
 
 	/* ensure all delayed rcu free inodes & pclusters are flushed */

-- 
2.43.0

