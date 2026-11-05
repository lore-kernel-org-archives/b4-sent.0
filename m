From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 05 Nov 2026 11:49:12 +0900
Subject: [PATCH 1/2] xfs: number the cache flushes submitted to each
 buftarg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-xfs-fsync-flush-seq-v1-1-299bdf5e28c3@samsung.com>
References: <20261105-xfs-fsync-flush-seq-v1-0-299bdf5e28c3@samsung.com>
In-Reply-To: <20261105-xfs-fsync-flush-seq-v1-0-299bdf5e28c3@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, Dave Chinner <david@fromorbit.com>, 
 "Darrick J. Wong" <djwong@kernel.org>, Amir Goldstein <amir73il@gmail.com>, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793846951; l=5750;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=vCNq5bDAVGp/yBF1fAud3Oul3TiBCsGiIyJWfQTxBaw=;
 b=UBDAsPbK8EbORFJBcxDz/R8e2jqRBUpmdLGOmpOvrA7hwcM2ncI0uzK6VA7/ENyI4Q9+81Z3L
 V3wbkjXSlw6BX/AeczFxh7p2yvpS3O4lwczGW7AqRilK5EGOzZPKsxP
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fsync can only skip its own cache flush when its log force wrote out
the iclog. It cannot tell whether a flush that another task submitted
covers its data.

Number the cache flushes that the log code submits to each buftarg,
and record the highest number that completed without error. Nothing
reads the numbers yet.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/xfs/xfs_buf.c      | 13 +++++++++++++
 fs/xfs/xfs_buf.h      | 21 +++++++++++++++++++++
 fs/xfs/xfs_log.c      | 25 +++++++++++++++++++------
 fs/xfs/xfs_log_priv.h |  1 +
 4 files changed, 54 insertions(+), 6 deletions(-)

diff --git a/fs/xfs/xfs_buf.c b/fs/xfs/xfs_buf.c
index 6c93b4f5629..9025b177931 100644
--- a/fs/xfs/xfs_buf.c
+++ b/fs/xfs/xfs_buf.c
@@ -1772,6 +1772,19 @@ xfs_init_buftarg(
 	return -ENOMEM;
 }
 
+/* Record that the flush numbered @seq completed successfully. */
+void
+xfs_buftarg_flush_done(
+	struct xfs_buftarg	*btp,
+	s64			seq)
+{
+	s64			old = atomic64_read(&btp->bt_flush_completed);
+
+	while (seq > old &&
+	       !atomic64_try_cmpxchg(&btp->bt_flush_completed, &old, seq))
+		;
+}
+
 struct xfs_buftarg *
 xfs_alloc_buftarg(
 	struct xfs_mount	*mp,
diff --git a/fs/xfs/xfs_buf.h b/fs/xfs/xfs_buf.h
index a4729253b56..e8ca4452025 100644
--- a/fs/xfs/xfs_buf.h
+++ b/fs/xfs/xfs_buf.h
@@ -103,6 +103,17 @@ struct xfs_buftarg {
 	unsigned int		bt_awu_max;
 
 	struct rhashtable	bt_hash;
+
+	/*
+	 * Cache flush tracking: a flush that takes the next number from
+	 * xfs_buftarg_flush_start() before it is submitted records it here
+	 * once it completes without error, keeping the highest number. A
+	 * completed flush with a number above a snapshot taken after some
+	 * writes completed covers those writes. Flushes without a number
+	 * are not counted.
+	 */
+	atomic64_t		bt_flush_submitted;
+	atomic64_t		bt_flush_completed;
 };
 
 struct xfs_buf_map {
@@ -356,6 +367,16 @@ xfs_buf_update_cksum(struct xfs_buf *bp, unsigned long cksum_offset)
 struct xfs_buftarg *xfs_alloc_buftarg(struct xfs_mount *mp,
 		struct file *bdev_file);
 extern void xfs_free_buftarg(struct xfs_buftarg *);
+
+/* Call right before submitting a cache flush to @btp. */
+static inline s64
+xfs_buftarg_flush_start(
+	struct xfs_buftarg	*btp)
+{
+	return atomic64_inc_return(&btp->bt_flush_submitted);
+}
+
+void xfs_buftarg_flush_done(struct xfs_buftarg *btp, s64 seq);
 extern void xfs_buftarg_wait(struct xfs_buftarg *);
 extern void xfs_buftarg_drain(struct xfs_buftarg *);
 int xfs_configure_buftarg(struct xfs_buftarg *btp, unsigned int sectorsize,
diff --git a/fs/xfs/xfs_log.c b/fs/xfs/xfs_log.c
index 74b324f915a..734daa4e99b 100644
--- a/fs/xfs/xfs_log.c
+++ b/fs/xfs/xfs_log.c
@@ -1211,6 +1211,8 @@ xlog_ioend_work(
 		xlog_force_shutdown(log, SHUTDOWN_LOG_IO_ERROR);
 	}
 
+	if (!error && iclog->ic_flush_seq)
+		xfs_buftarg_flush_done(log->l_targ, iclog->ic_flush_seq);
 	xlog_state_done_syncing(iclog);
 	bio_uninit(&iclog->ic_bio);
 
@@ -1570,19 +1572,21 @@ xlog_flush_end_io(
 	bio_put(bio);
 }
 
-static void
+static s64
 xlog_flush_async(
 	struct xlog_flush_done	*done,
-	struct block_device	*bdev)
+	struct xfs_buftarg	*btp)
 {
 	struct bio		*bio;
+	s64			seq = xfs_buftarg_flush_start(btp);
 
-	bio = bio_alloc(bdev, 0, REQ_OP_WRITE | REQ_PREFLUSH | REQ_SYNC,
+	bio = bio_alloc(btp->bt_bdev, 0, REQ_OP_WRITE | REQ_PREFLUSH | REQ_SYNC,
 			GFP_NOFS);
 	bio->bi_private = done;
 	bio->bi_end_io = xlog_flush_end_io;
 	atomic_inc(&done->pending);
 	submit_bio(bio);
+	return seq;
 }
 
 /*
@@ -1605,16 +1609,17 @@ xlog_flush_data_caches(
 		.pending	= ATOMIC_INIT(1),
 		.done		= COMPLETION_INITIALIZER_ONSTACK(done.done),
 	};
+	s64			dseq = 0, rseq = 0, lseq;
 
 	*did_flush = false;
 	if (mp->m_ddev_targp != mp->m_logdev_targp &&
 	    bdev_write_cache(mp->m_ddev_targp->bt_bdev)) {
-		xlog_flush_async(&done, mp->m_ddev_targp->bt_bdev);
+		dseq = xlog_flush_async(&done, mp->m_ddev_targp);
 		*did_flush = true;
 	}
 	if (mp->m_rtdev_targp && mp->m_rtdev_targp != mp->m_ddev_targp &&
 	    bdev_write_cache(mp->m_rtdev_targp->bt_bdev)) {
-		xlog_flush_async(&done, mp->m_rtdev_targp->bt_bdev);
+		rseq = xlog_flush_async(&done, mp->m_rtdev_targp);
 		*did_flush = true;
 	}
 
@@ -1623,12 +1628,17 @@ xlog_flush_data_caches(
 		 * If we flushed any other device, also use an async flush for
 		 * the log device so that all flushes happen in parallel.
 		 */
-		xlog_flush_async(&done, mp->m_logdev_targp->bt_bdev);
+		lseq = xlog_flush_async(&done, mp->m_logdev_targp);
 
 		xlog_flush_done(&done);
 		wait_for_completion(&done.done);
 		if (done.status)
 			return -EIO;
+		if (dseq)
+			xfs_buftarg_flush_done(mp->m_ddev_targp, dseq);
+		if (rseq)
+			xfs_buftarg_flush_done(mp->m_rtdev_targp, rseq);
+		xfs_buftarg_flush_done(mp->m_logdev_targp, lseq);
 	}
 
 	return 0;
@@ -1688,6 +1698,9 @@ xlog_write_iclog(
 		iclog->ic_bio.bi_opf |= REQ_PREFLUSH;
 	if (iclog->ic_flags & XLOG_ICL_NEED_FUA)
 		iclog->ic_bio.bi_opf |= REQ_FUA;
+	iclog->ic_flush_seq = 0;
+	if (iclog->ic_bio.bi_opf & REQ_PREFLUSH)
+		iclog->ic_flush_seq = xfs_buftarg_flush_start(log->l_targ);
 
 	iclog->ic_flags &= ~(XLOG_ICL_NEED_FLUSH | XLOG_ICL_NEED_FLUSH_LOG |
 			     XLOG_ICL_NEED_FUA);
diff --git a/fs/xfs/xfs_log_priv.h b/fs/xfs/xfs_log_priv.h
index 529720a4984..df0f13c4e04 100644
--- a/fs/xfs/xfs_log_priv.h
+++ b/fs/xfs/xfs_log_priv.h
@@ -222,6 +222,7 @@ struct xlog_in_core {
 #endif
 	struct semaphore	ic_sema;
 	struct work_struct	ic_end_io_work;
+	s64			ic_flush_seq;	/* buftarg flush number */
 	struct bio		ic_bio;
 	struct bio_vec		ic_bvec[];
 };

-- 
2.43.0

