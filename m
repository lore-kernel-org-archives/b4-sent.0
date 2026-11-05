From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 05 Nov 2026 11:49:13 +0900
Subject: [PATCH 2/2] xfs: skip the fsync flush when a later flush has
 completed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-xfs-fsync-flush-seq-v1-2-299bdf5e28c3@samsung.com>
References: <20261105-xfs-fsync-flush-seq-v1-0-299bdf5e28c3@samsung.com>
In-Reply-To: <20261105-xfs-fsync-flush-seq-v1-0-299bdf5e28c3@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, Dave Chinner <david@fromorbit.com>, 
 "Darrick J. Wong" <djwong@kernel.org>, Amir Goldstein <amir73il@gmail.com>, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793846951; l=5190;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=CP7EIACxnvec5vGCIOS285YW810d9eW4b4Yw8xE5yJ0=;
 b=yCLjYvB4h1N4WikF8IL9ngx0V236OUzrUIe7C7Wl3iaYQoEQQF9sVeb/YT07vIjb60JRlMDoY
 aDYX3acWrSECc1M14Zd7VntKsIBIRHaeEfdw/FQcZOSWxKPI5kz0dAd
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 47c7d0b19502 ("xfs: fix incorrect log_flushed on
fsync"), fsync sends its own cache flush whenever another task wrote
out the iclog it waited for. With concurrent fsyncs, these flushes can
limit throughput.

Skip the flush when a flush submitted after the data writes completed
has finished. Number the fsync's own flush too, so that concurrent
fsyncs can share it. DAX does not use the new skip, because DAX writes
do not go through block I/O.

Suggested-by: Christoph Hellwig <hch@lst.de>
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
16 fio jobs of 4k append + fsync, QEMU guest on a 990 PRO without
power loss protection (virtio-blk, cache=none): 809 -> 4185 fsyncs/s,
mean fsync latency 19.8 -> 3.8 ms.

dm-log-writes with 8 fsync writers: no fsync-ed block was lost in 528
replays, while at least 33257 of 48048 fsyncs skipped their flush
through the new check. Taking the snapshot before the writeback loses
15 of 528. The test needs "dm-log-writes: log earlier flushes' writes
when a later flush completes", sent to dm-devel.
---
 fs/xfs/xfs_buf.c  | 26 ++++++++++++++++++++++++++
 fs/xfs/xfs_buf.h  | 19 +++++++++++++++++++
 fs/xfs/xfs_file.c | 21 +++++++++++++++------
 3 files changed, 60 insertions(+), 6 deletions(-)

diff --git a/fs/xfs/xfs_buf.c b/fs/xfs/xfs_buf.c
index 9025b177931..6b545d79a41 100644
--- a/fs/xfs/xfs_buf.c
+++ b/fs/xfs/xfs_buf.c
@@ -1785,6 +1785,32 @@ xfs_buftarg_flush_done(
 		;
 }
 
+/*
+ * Return true if a flush numbered above @seq has completed. All writes that
+ * completed before @seq was read are then on stable storage.
+ */
+bool
+xfs_buftarg_flushed_since(
+	struct xfs_buftarg	*btp,
+	s64			seq)
+{
+	return atomic64_read(&btp->bt_flush_completed) > seq;
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
index e8ca4452025..0f48ee6d3f2 100644
--- a/fs/xfs/xfs_buf.h
+++ b/fs/xfs/xfs_buf.h
@@ -368,6 +368,23 @@ struct xfs_buftarg *xfs_alloc_buftarg(struct xfs_mount *mp,
 		struct file *bdev_file);
 extern void xfs_free_buftarg(struct xfs_buftarg *);
 
+/*
+ * Call after the writes that a flush must cover have completed, and pass the
+ * result to xfs_buftarg_flushed_since().
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
 /* Call right before submitting a cache flush to @btp. */
 static inline s64
 xfs_buftarg_flush_start(
@@ -377,6 +394,8 @@ xfs_buftarg_flush_start(
 }
 
 void xfs_buftarg_flush_done(struct xfs_buftarg *btp, s64 seq);
+bool xfs_buftarg_flushed_since(struct xfs_buftarg *btp, s64 seq);
+int xfs_buftarg_flush(struct xfs_buftarg *btp);
 extern void xfs_buftarg_wait(struct xfs_buftarg *);
 extern void xfs_buftarg_drain(struct xfs_buftarg *);
 int xfs_configure_buftarg(struct xfs_buftarg *btp, unsigned int sectorsize,
diff --git a/fs/xfs/xfs_file.c b/fs/xfs/xfs_file.c
index 396aca8c66a..a98361e9ead 100644
--- a/fs/xfs/xfs_file.c
+++ b/fs/xfs/xfs_file.c
@@ -87,7 +87,9 @@ xfs_file_fsync(
 	int			datasync)
 {
 	struct xfs_inode	*ip = XFS_I(file->f_mapping->host);
+	struct xfs_buftarg	*btp = xfs_inode_buftarg(ip);
 	int			log_flushed = 0;
+	s64			flush_seq;
 	int			error;
 
 	trace_xfs_file_fsync(ip);
@@ -95,6 +97,7 @@ xfs_file_fsync(
 	error = file_write_and_wait_range(file, start, end);
 	if (error)
 		return error;
+	flush_seq = xfs_buftarg_flush_seq(btp);
 
 	if (xfs_is_shutdown(ip->i_mount))
 		return -EIO;
@@ -115,16 +118,22 @@ xfs_file_fsync(
 	}
 
 	/*
-	 * If the log force was a no-op, we may still need to flush the
-	 * file data target cache here. This can happen for fdatasync/O_DSYNC
-	 * when no metadata needed to be committed.
+	 * Flush the file data target unless a flush submitted to it after the
+	 * data writes above completed has already finished. That is usually
+	 * the flush before an iclog written out by this log force or by
+	 * another task, or another fsync's flush.
+	 *
+	 * DAX writes are CPU stores, not block I/O, and the check above
+	 * relies on REQ_PREFLUSH covering completed block I/O. So DAX only
+	 * skips the flush when this log force flushed, as before.
 	 *
 	 * Use the inode's actual file data target rather than assuming the
 	 * main data device.
 	 */
-	if (!log_flushed)
-		return blkdev_issue_flush(xfs_inode_buftarg(ip)->bt_bdev);
-	return 0;
+	if (log_flushed ||
+	    (!IS_DAX(VFS_I(ip)) && xfs_buftarg_flushed_since(btp, flush_seq)))
+		return 0;
+	return xfs_buftarg_flush(btp);
 }
 
 static int

-- 
2.43.0

