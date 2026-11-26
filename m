From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 26 Nov 2026 17:21:02 +0900
Subject: [PATCH v3] xfs: skip the fsync flush when a later flush has
 completed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-xfs-fsync-flush-seq-v3-1-830f5dd79fae@samsung.com>
X-B4-Tracking: v=1; b=H4sIAO3rB2sC/33NQQ6CMBCF4auQrh3TDimCK+9hXECZQhMB7UgDI
 dzdwkoT4/J/yXyzCCbviMU5WYSn4NgNfYz0kAjTln1D4OrYAiVmSkkNk2WwPPcG7H3kFpiekKc
 lobE2Q9QiXj48WTft6vUWu3X8Gvy8PwlqW/97QYEELIqqtpowN+mFy47HvjmaoRObGPBDUeq3g
 lGptJHSoK7xlH0r67q+Af4dn1z+AAAA
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, Dave Chinner <dgc@kernel.org>, 
 "Darrick J. Wong" <djwong@kernel.org>, Amir Goldstein <amir73il@gmail.com>, 
 Brian Foster <bfoster@redhat.com>, Pankaj Raghav <pankaj.raghav@linux.dev>, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795681262; l=13602;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=vzT2Rt/enTMo0aDqVXmMlExUthUUiFIy5YYe9FN0M9M=;
 b=1IaAQSEjAIil32bh/BYJwacUErCtVZ3ZVEXRGlRfpliInWcXaWsD5LfbqooVYgK9vSmGTV26E
 O58i8HjSJwRDXEJhqHVq31+arfl26+g7G1iT4hALEJs6FKLrtHYGPIW
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 47c7d0b19502 ("xfs: fix incorrect log_flushed on
fsync"), fsync sends its own cache flush unless its log force pushed
out the iclog it waited for. With concurrent fsyncs, these flushes can
limit throughput.

Number the flushes that the log and fsync send to each buftarg. Skip
the fsync flush when a flush submitted after the data writes completed
has succeeded.

An fsync that skips relies on the status of the covering flush, as
the log does. It misses a failed preflush sent with data if a driver
drops that error.

QEMU guest, 990 PRO NVMe SSD, before -> after:

  fio 4KiB writes + fsync to preallocated files, mean of 2 runs
    16 jobs: 1023 -> 4226 fsyncs/s, mean fsync latency 15.6 -> 3.8 ms
     1 job:  387 -> 391 fsyncs/s
  dbench -t 30, MB/s and max latency, mean of 3 runs
    4 AGs, 128 clients:               1968 -> 6857, 0.4 -> 0.4 s
    4 AGs, 256 clients:               3220 -> 6219, 0.3 -> 2.4 s
    4 AGs, 256 clients, no flushes:   6527 -> 6369, 13.8 -> 14.7 s
    4 AGs, 512 clients:               4699 -> 5126, 0.4 -> 22.3 s
    32 AGs, 512 clients:              4812 -> 3256, 0.5 -> 21.6 s
    32 AGs, 512 clients, no flushes:  3515 -> 3419, 28.4 -> 27.8 s
    32 AGs, 512 clients, 1 GiB log:   5095 -> 9353, 0.4 -> 2.2 s
    (no flushes: guest queue/write_cache set to write through)
    (latencies over a second are unlink() calls in the inodegc throttle)

Suggested-by: Christoph Hellwig <hch@lst.de>
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Christoph's 2017 mail with the sequence counter idea:
https://lore.kernel.org/20170830142134.GA650@lst.de

The fio and dbench numbers are from this patch on for-next 5e7b6fe39324,
8 vCPUs, virtio-blk (cache=none) on an SSD without power loss
protection, mkfs.xfs -K with the default geometry (4 AGs, 64 MiB log)
unless noted. "No flushes" means that the guest's queue/write_cache was
set to write through, so the guest block layer drops flushes and FUA.
The SSD cache stays on.

fstests -g quick on 5e7b6fe39324 with and without the patch (loop
devices, XFS_DEBUG, KASAN, lockdep, no DAX): the same 5 failures.

Dave's questions on v2 (v2 numbers in
https://lore.kernel.org/r/20261117023345epcms2p5117009330b6c600f68c598d5e08aef5e@epcms2p5):
at 1024 clients, MB/s rises 6% with 4 AGs and falls 10% with 32 AGs.
With 4 AGs, log writes per fsync rise from 0.11-0.14 to 0.37 at 256 and
512 clients. With flushes, log writes peak at 5324/s (12284/s with a
1 GiB log). With the 64 MiB log, the patch reaches the inodegc throttle
(0.88-1.00 throttle events per unlink(), under 0.10 otherwise) from
256 clients with 4 AGs and 512 with 32 AGs, and the base from 1024. With
no flushes, the base also reaches it at 256 clients (4 AGs) and 512
(32 AGs), with 1.07-1.15 log writes per fsync at 256. Both kernels then
do 13.4-17.7k log writes/s at 256 clients, with MB/s within run-to-run
spread (6242-6953 against 5995-6608). At 512 clients with 32 AGs,
dropping the flushes takes the base from 4778 to 3515 MB/s. With a 1 GiB
log, the patch takes 32 AGs and 512 clients from 5095 to 9353 MB/s. The
loss in the commit log is with the default 64 MiB log. With that log,
78-87% of the patch's log reservations at 512 clients sleep for log
space, against under 3% for the base.

A dm-log-writes test written for this series (v2 on 48326a2382d8 without
CONFIG_FS_DAX, 8 fsync writers, internal log) lost no fsync-ed block in
528 replays. At least 33319 of 48048 fsyncs skipped their flush through
the new check. A variant that samples before the writeback loses 16 of
528. The test needs "dm-log-writes: log earlier flushes' writes when a
later flush completes" from the dm tree. v2 and v3 behave differently
only for DAX files.

Bio-based dm dropped the error of a failed preflush sent with data until
commit e92cd41e8e5e ("dm: fail a REQ_PREFLUSH bio with data when its
preflush fails", in v7.4-rc3, not yet in for-next). From the code,
bcache in writeback mode still drops it. Not tested.

Changes in v3:
- Merge the two patches into one
- Keep initialized declarations first in xlog_flush_async(), and give
  lseq its own line in xlog_flush_data_caches()
- Drop the IS_DAX() check and its comment in xfs_file_fsync(), so DAX
  files take the new skip too
- Describe the flush status caveat in the commit log
- Call the fio workload writes to preallocated files, not append, and
  remeasure it on the current for-next
- Add dbench results to the commit log, and answer Dave's questions
  below ---
- Say below --- that the dm case is fixed by e92cd41e8e5e
- Drop Brian's Reviewed-by tags because the patches were merged and
  the DAX check changed
- Rebase onto the current for-next
---
 fs/xfs/xfs_buf.c      | 40 ++++++++++++++++++++++++++++++++++++++++
 fs/xfs/xfs_buf.h      | 43 +++++++++++++++++++++++++++++++++++++++++++
 fs/xfs/xfs_file.c     | 14 +++++++++++---
 fs/xfs/xfs_log.c      | 29 ++++++++++++++++++++++-------
 fs/xfs/xfs_log_priv.h |  1 +
 5 files changed, 117 insertions(+), 10 deletions(-)

diff --git a/fs/xfs/xfs_buf.c b/fs/xfs/xfs_buf.c
index 6c93b4f5629..2862cbdeda4 100644
--- a/fs/xfs/xfs_buf.c
+++ b/fs/xfs/xfs_buf.c
@@ -1772,6 +1772,46 @@ xfs_init_buftarg(
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
+/*
+ * Return true if a flush has been submitted and completed since @submit_seq
+ * was sampled. If so, all writes that completed before @submit_seq was sampled
+ * are on stable storage.
+ */
+bool
+xfs_buftarg_flushed_since(
+	struct xfs_buftarg	*btp,
+	s64			submit_seq)
+{
+	return atomic64_read(&btp->bt_flush_completed) > submit_seq;
+}
+
+/* Flush the device cache and record it. */
+int
+xfs_buftarg_flush(
+	struct xfs_buftarg	*btp)
+{
+	s64			seq = xfs_buftarg_flush_start(btp);
+	int			error;
+
+	error = blkdev_issue_flush(btp->bt_bdev);
+	if (!error)
+		xfs_buftarg_flush_done(btp, seq);
+	return error;
+}
+
 struct xfs_buftarg *
 xfs_alloc_buftarg(
 	struct xfs_mount	*mp,
diff --git a/fs/xfs/xfs_buf.h b/fs/xfs/xfs_buf.h
index a4729253b56..08282e1b3c8 100644
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
+	 * completed flush with a number above a sample taken after some
+	 * writes completed covers those writes. Flushes without a number
+	 * are not counted.
+	 */
+	atomic64_t		bt_flush_submitted;
+	atomic64_t		bt_flush_completed;
 };
 
 struct xfs_buf_map {
@@ -356,6 +367,38 @@ xfs_buf_update_cksum(struct xfs_buf *bp, unsigned long cksum_offset)
 struct xfs_buftarg *xfs_alloc_buftarg(struct xfs_mount *mp,
 		struct file *bdev_file);
 extern void xfs_free_buftarg(struct xfs_buftarg *);
+
+/*
+ * Sample the flush submit counter of @btp. Call this after the writes that a
+ * flush must cover have completed. Flushes take their number before they are
+ * submitted, so a flush numbered above the sample was submitted after it and
+ * covers those writes once it succeeds. xfs_buftarg_flushed_since() checks
+ * for such a flush.
+ */
+static inline s64
+xfs_buftarg_flush_seq(
+	struct xfs_buftarg	*btp)
+{
+	/*
+	 * Order the read after the write completions the caller waited for.
+	 * Pairs with the fully ordered atomic64_inc_return() that
+	 * xfs_buftarg_flush_start() does before the flush is submitted.
+	 */
+	smp_mb();
+	return atomic64_read(&btp->bt_flush_submitted);
+}
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
+bool xfs_buftarg_flushed_since(struct xfs_buftarg *btp, s64 submit_seq);
+int xfs_buftarg_flush(struct xfs_buftarg *btp);
 extern void xfs_buftarg_wait(struct xfs_buftarg *);
 extern void xfs_buftarg_drain(struct xfs_buftarg *);
 int xfs_configure_buftarg(struct xfs_buftarg *btp, unsigned int sectorsize,
diff --git a/fs/xfs/xfs_file.c b/fs/xfs/xfs_file.c
index 8070a07e601..e5bb67ca2c7 100644
--- a/fs/xfs/xfs_file.c
+++ b/fs/xfs/xfs_file.c
@@ -87,7 +87,9 @@ xfs_file_fsync(
 	int			datasync)
 {
 	struct xfs_inode	*ip = XFS_I(file->f_mapping->host);
+	struct xfs_buftarg	*btp = xfs_inode_buftarg(ip);
 	int			log_flushed = 0;
+	s64			submit_seq;
 	int			error;
 
 	trace_xfs_file_fsync(ip);
@@ -95,6 +97,7 @@ xfs_file_fsync(
 	error = file_write_and_wait_range(file, start, end);
 	if (error)
 		return error;
+	submit_seq = xfs_buftarg_flush_seq(btp);
 
 	if (xfs_is_shutdown(ip->i_mount))
 		return -EIO;
@@ -119,12 +122,17 @@ xfs_file_fsync(
 	 * file data target cache here. This can happen for fdatasync/O_DSYNC
 	 * when no metadata needed to be committed.
 	 *
+	 * Flush the file data target unless a flush submitted to it after the
+	 * data writes above completed has already finished. That is usually
+	 * the flush before an iclog written out by this log force or by
+	 * another task, or another fsync's flush.
+	 *
 	 * Use the inode's actual file data target rather than assuming the
 	 * main data device.
 	 */
-	if (!log_flushed)
-		return blkdev_issue_flush(xfs_inode_buftarg(ip)->bt_bdev);
-	return 0;
+	if (log_flushed || xfs_buftarg_flushed_since(btp, submit_seq))
+		return 0;
+	return xfs_buftarg_flush(btp);
 }
 
 static int
diff --git a/fs/xfs/xfs_log.c b/fs/xfs/xfs_log.c
index 74b324f915a..b46f9c1ce8e 100644
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
+	s64			seq = xfs_buftarg_flush_start(btp);
 	struct bio		*bio;
 
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
@@ -1605,16 +1609,18 @@ xlog_flush_data_caches(
 		.pending	= ATOMIC_INIT(1),
 		.done		= COMPLETION_INITIALIZER_ONSTACK(done.done),
 	};
+	s64			dseq = 0, rseq = 0;
+	s64			lseq;
 
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
 
@@ -1623,12 +1629,17 @@ xlog_flush_data_caches(
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
@@ -1678,14 +1689,18 @@ xlog_write_iclog(
 	iclog->ic_bio.bi_iter.bi_sector = log->l_logBBstart + bno;
 	iclog->ic_bio.bi_end_io = xlog_bio_end_io;
 	iclog->ic_bio.bi_private = iclog;
+	iclog->ic_flush_seq = 0;
 
 	if (iclog->ic_flags & XLOG_ICL_NEED_FLUSH) {
 		if (xlog_flush_data_caches(log->l_mp, &did_flush))
 			goto shutdown;
 	}
 	if (!did_flush &&
-	    (iclog->ic_flags & (XLOG_ICL_NEED_FLUSH | XLOG_ICL_NEED_FLUSH_LOG)))
+	    (iclog->ic_flags &
+	     (XLOG_ICL_NEED_FLUSH | XLOG_ICL_NEED_FLUSH_LOG))) {
 		iclog->ic_bio.bi_opf |= REQ_PREFLUSH;
+		iclog->ic_flush_seq = xfs_buftarg_flush_start(log->l_targ);
+	}
 	if (iclog->ic_flags & XLOG_ICL_NEED_FUA)
 		iclog->ic_bio.bi_opf |= REQ_FUA;
 
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

---
base-commit: 5e7b6fe39324913f6416c854c6ed3a1793aaba8e
change-id: 20261105-xfs-fsync-flush-seq-83ae2cff6225

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

