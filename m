From: Daejun Park <daejun7.park@samsung.com>
Date: Fri, 30 Oct 2026 12:54:36 +0900
Subject: [PATCH] erofs: allocate file-backed mount requests from a bio_set
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-erofs-fileio-bioset-v1-1-caf47adbb3a3@samsung.com>
X-B4-Tracking: v=1; b=H4sIAPsU5GoC/x3MTQqAIBBA4avErBtQo9KuEi36GWsgNJyIILp70
 vJbvPeAUGIS6IoHEl0sHEOGLguYtzGshLxkg1Gm0co4pBS9oOedOOLEUejEVld1qybrFusgl0c
 iz/d/7Yf3/QACpbrhZQAAAA==
To: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>
Cc: Yue Hu <zbestahu@gmail.com>, Jingbo Xu <jefflexu@163.com>, 
 Sandeep Dhavale <dhavale@google.com>, Hongbo Li <hongbohbli@tencent.com>, 
 Chunhai Guo <guochunhai@vivo.com>, linux-erofs@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793332475; l=7653;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=gbIxnX8FciCSXpNYzWxLVeaper8bYHxXoy7NVQKYLCc=;
 b=I6WF5AUXX0OQ89qm/VX6quw8eorvh1mBHO9e7AewMvJa0Kcn5MiGTDvcC4lwsZ93fdrT2yliD
 6BIC9qz1LBkDbjbNHf8QEkMl3JZqfJOp+386V0RVbVamf1RBQjgp1Uu
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 9f74ae8c9ac9 ("erofs: shorten bvecs[] for file-backed
mounts"), a file-backed request holds at most 16 bvecs. A 1 MiB
synchronous readahead window of order-0 folios can then take several
backing reads.

Allocate requests from a bio_set, using the mempool that commit
considered. With GFP_NOIO, bio_alloc_bioset() does not fail if each
task submits a request before it allocates another:

- Every path submits its request before it allocates the next one.

- Mount already rejects backing files on stacked fses and on
  file-backed EROFS. A backing read cannot reach this pool again in
  the same task.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
This needs "erofs: apply the stacked fs check to extra file-backed
devices" [1].

Tested in QEMU on mm-new with that patch and "mm/readahead: keep at
least half of the async window when aligning it" [2]:

- With read_ahead_kb=1024, 1 MiB read() calls on 256 files of 1 MiB
  take 0.119 s instead of 0.141 s (median of 6). The other 15 cases
  changed by -22% to +0.4%.

- Without the mm patch, this patch makes the same reads about 25%
  slower.

- With failslab failing all bio and biovec slab allocations of 8
  parallel readers, every request came from the bio_set's reserves.
  All data read back correctly.

- KASAN and lockdep found only the lockdep report noted in [1].

[1] https://lore.kernel.org/r/20261030-erofs-stacked-extra-devices-v1-1-39f7df7ac01b@samsung.com
[2] https://lore.kernel.org/r/20261030-mm-readahead-async-align-v1-1-109dea6851fc@samsung.com
---
 fs/erofs/fileio.c   | 44 ++++++++++++++++++++++++++++++++------------
 fs/erofs/internal.h |  4 ++++
 fs/erofs/super.c    |  7 +++++++
 3 files changed, 43 insertions(+), 12 deletions(-)

diff --git a/fs/erofs/fileio.c b/fs/erofs/fileio.c
index e13293ec70..0fe6eb6643 100644
--- a/fs/erofs/fileio.c
+++ b/fs/erofs/fileio.c
@@ -7,13 +7,15 @@
 #include <trace/events/erofs.h>
 
 struct erofs_fileio_rq {
-	struct bio_vec bvecs[16];
-	struct bio bio;
 	struct kiocb iocb;
 	struct super_block *sb;
 	refcount_t ref;
+	/* must be last: erofs_fileio_bioset allocates the rest as front_pad */
+	struct bio bio;
 };
 
+static struct bio_set erofs_fileio_bioset;
+
 struct erofs_fileio {
 	struct erofs_map_blocks map;
 	struct erofs_map_dev dev;
@@ -38,9 +40,8 @@ static void erofs_fileio_ki_complete(struct kiocb *iocb, long ret)
 		rq->bio.bi_status = errno_to_blk_status(ret);
 	}
 	bio_endio(&rq->bio);
-	bio_uninit(&rq->bio);
 	if (refcount_dec_and_test(&rq->ref))
-		kfree(rq);
+		bio_put(&rq->bio);
 }
 
 static void erofs_fileio_rq_submit(struct erofs_fileio_rq *rq)
@@ -56,22 +57,25 @@ static void erofs_fileio_rq_submit(struct erofs_fileio_rq *rq)
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
@@ -80,7 +84,8 @@ static struct erofs_fileio_rq *erofs_fileio_rq_alloc(struct super_block *sb,
 
 struct bio *erofs_fileio_bio_alloc(struct erofs_map_dev *mdev)
 {
-	return &erofs_fileio_rq_alloc(mdev->m_sb, mdev->m_dif->file)->bio;
+	return &erofs_fileio_rq_alloc(mdev->m_sb, mdev->m_dif->file,
+				      BIO_MAX_VECS)->bio;
 }
 
 void erofs_fileio_submit_bio(struct bio *bio)
@@ -108,11 +113,14 @@ static int erofs_fileio_iomap_read_folio_range(const struct iomap_iter *iter,
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
@@ -161,10 +169,22 @@ int erofs_read_meta_folio(struct file *file, struct folio *folio)
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
index ee01a5ef85..faea77ba25 100644
--- a/fs/erofs/super.c
+++ b/fs/erofs/super.c
@@ -1100,6 +1100,10 @@ static int __init erofs_module_init(void)
 	if (err)
 		goto ishare_err;
 
+	err = erofs_init_fileio();
+	if (err)
+		goto fileio_err;
+
 	err = register_filesystem(&erofs_fs_type);
 	if (err)
 		goto fs_err;
@@ -1107,6 +1111,8 @@ static int __init erofs_module_init(void)
 	return 0;
 
 fs_err:
+	erofs_exit_fileio();
+fileio_err:
 	erofs_exit_ishare();
 ishare_err:
 	erofs_exit_sysfs();
@@ -1122,6 +1128,7 @@ static int __init erofs_module_init(void)
 static void __exit erofs_module_exit(void)
 {
 	unregister_filesystem(&erofs_fs_type);
+	erofs_exit_fileio();
 	erofs_exit_ishare();
 
 	/* ensure all delayed rcu free inodes & pclusters are flushed */

---
base-commit: 7778e12f447c2b465fd9c8796348521494b5d3e4
change-id: 20261029-erofs-fileio-bioset-713570b89d89

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

