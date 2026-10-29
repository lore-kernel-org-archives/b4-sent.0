From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 29 Oct 2026 11:23:05 +0900
Subject: [PATCH v5 8/9] xfs: add datasync and log_flushed arguments to
 xfs_log_force_inode()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-xfs-pnfs-batch-v5-8-ef8d2eafb7fa@samsung.com>
References: <20261029-xfs-pnfs-batch-v5-0-ef8d2eafb7fa@samsung.com>
In-Reply-To: <20261029-xfs-pnfs-batch-v5-0-ef8d2eafb7fa@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Pankaj Raghav <p.raghav@samsung.com>, 
 Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Sergey Bashirov <sergeybashirov@gmail.com>, 
 Andrey Albershteyn <aalbersh@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793240577; l=7887;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=Nk+YR6VX9t0NZiz+UYJSWclOe3yOkmbiwsMnQiHyqeg=;
 b=uEkmlVQV/SRpaQLmeETqXxq/8IUovjnSIIWPvlwop/Dgs364zwCn3XrqCJxGNyI5NjzzJLcy/
 PWYjARpEzusBuSdnIqWFbT/j4tEYK5ydwNcp+Du9chICZQQgmZkPeZb
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add datasync and log_flushed arguments to xfs_log_force_inode() and
move the body of xfs_fsync_flush_log() into it. The next patch needs a
datasync log force in the pNFS LAYOUTCOMMIT path. xfs_file_fsync()
calls it instead, and the other callers pass false and NULL. No
functional change.

Suggested-by: Christoph Hellwig <hch@lst.de>
Link: https://lore.kernel.org/r/20261014130124.GA15407@lst.de
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
Reviewed-by: Christoph Hellwig <hch@lst.de>
---
 fs/xfs/xfs_export.c  |  2 +-
 fs/xfs/xfs_file.c    | 50 ++++----------------------------------------------
 fs/xfs/xfs_inode.c   | 36 ++++++++++++++++++++++++++++++++----
 fs/xfs/xfs_inode.h   |  3 ++-
 fs/xfs/xfs_pnfs.c    |  2 +-
 fs/xfs/xfs_zone_gc.c |  2 +-
 6 files changed, 41 insertions(+), 54 deletions(-)

diff --git a/fs/xfs/xfs_export.c b/fs/xfs/xfs_export.c
index 9afda52ed1..9dd6dd8c27 100644
--- a/fs/xfs/xfs_export.c
+++ b/fs/xfs/xfs_export.c
@@ -234,7 +234,7 @@ STATIC int
 xfs_fs_nfs_commit_metadata(
 	struct inode		*inode)
 {
-	return xfs_log_force_inode(XFS_I(inode));
+	return xfs_log_force_inode(XFS_I(inode), false, NULL);
 }
 
 const struct export_operations xfs_export_operations = {
diff --git a/fs/xfs/xfs_file.c b/fs/xfs/xfs_file.c
index 720f4a9b40..27176a4808 100644
--- a/fs/xfs/xfs_file.c
+++ b/fs/xfs/xfs_file.c
@@ -76,49 +76,7 @@ xfs_dir_fsync(
 	struct xfs_inode	*ip = XFS_I(file->f_mapping->host);
 
 	trace_xfs_dir_fsync(ip);
-	return xfs_log_force_inode(ip);
-}
-
-/*
- * All metadata updates are logged, which means that we just have to push the
- * journal to the required sequence number than holds the updates. We track
- * datasync commits separately to full sync commits, and hence only need to
- * select the correct sequence number for the log force here.
- *
- * We don't have to serialise against concurrent modifications, as we do not
- * have to wait for modifications that have not yet completed. We define a
- * transaction commit as completing when the commit sequence number is updated,
- * hence if the sequence number has not updated, the sync operation has been
- * run before the commit completed and we don't have to wait for it.
- *
- * If we have concurrent fsync/fdatasync() calls, the sequence numbers remain
- * set on the log item until - at least - the journal flush completes. In
- * reality, they are only cleared when the inode is fully unpinned (i.e.
- * persistent in the journal and not dirty in the CIL), and so we rely on
- * xfs_log_force_seq() either skipping sequences that have been persisted or
- * waiting on sequences that are still in flight to correctly order concurrent
- * sync operations.
- */
-static int
-xfs_fsync_flush_log(
-	struct xfs_inode	*ip,
-	bool			datasync,
-	int			*log_flushed)
-{
-	struct xfs_inode_log_item *iip = ip->i_itemp;
-	xfs_csn_t		seq = 0;
-
-	spin_lock(&iip->ili_lock);
-	if (datasync)
-		seq = iip->ili_datasync_seq;
-	else
-		seq = iip->ili_commit_seq;
-	spin_unlock(&iip->ili_lock);
-
-	if (!seq)
-		return 0;
-
-	return xfs_log_force_seq(ip->i_mount, seq, XFS_LOG_SYNC, log_flushed);
+	return xfs_log_force_inode(ip, false, NULL);
 }
 
 STATIC int
@@ -151,7 +109,7 @@ xfs_file_fsync(
 	 * no modifications to this inode that need to be pushed out.
 	 */
 	if (ip->i_itemp) {
-		error = xfs_fsync_flush_log(ip, datasync, &log_flushed);
+		error = xfs_log_force_inode(ip, datasync, &log_flushed);
 		if (error)
 			return error;
 	}
@@ -1599,7 +1557,7 @@ __xfs_file_fallocate(
 	}
 
 	if (!error && xfs_file_sync_writes(file))
-		error = xfs_log_force_inode(ip);
+		error = xfs_log_force_inode(ip, false, NULL);
 
 out_unlock:
 	xfs_iunlock(ip, iolock);
@@ -1750,7 +1708,7 @@ xfs_file_remap_range(
 		goto out_unlock;
 
 	if (xfs_file_sync_writes(file_in) || xfs_file_sync_writes(file_out))
-		xfs_log_force_inode(dest);
+		xfs_log_force_inode(dest, false, NULL);
 out_unlock:
 	xfs_iunlock2_remapping(src, dest);
 	if (ret)
diff --git a/fs/xfs/xfs_inode.c b/fs/xfs/xfs_inode.c
index 15b62574b8..0d1c9531cd 100644
--- a/fs/xfs/xfs_inode.c
+++ b/fs/xfs/xfs_inode.c
@@ -2669,11 +2669,36 @@ xfs_irele(
 }
 
 /*
- * Ensure all committed transactions touching the inode are written to the log.
+ * Ensure all committed transactions touching the inode are written to the log,
+ * or with @datasync only those that fdatasync has to wait for.
+ *
+ * All metadata updates are logged, which means that we just have to push the
+ * journal to the required sequence number that holds the updates. We track
+ * datasync commits separately to full sync commits, and hence only need to
+ * select the correct sequence number for the log force here.
+ *
+ * We don't have to serialise against concurrent modifications, as we do not
+ * have to wait for modifications that have not yet completed. We define a
+ * transaction commit as completing when the commit sequence number is updated,
+ * hence if the sequence number has not updated, the sync operation has been
+ * run before the commit completed and we don't have to wait for it.
+ *
+ * If we have concurrent fsync/fdatasync() calls, the sequence numbers remain
+ * set on the log item until - at least - the journal flush completes. In
+ * reality, they are only cleared when the inode is fully unpinned (i.e.
+ * persistent in the journal and not dirty in the CIL), and so we rely on
+ * xfs_log_force_seq() either skipping sequences that have been persisted or
+ * waiting on sequences that are still in flight to correctly order concurrent
+ * sync operations.
+ *
+ * If @log_flushed is not NULL, it is set when the log force wrote an iclog,
+ * which flushes the device caches before the log write.
  */
 int
 xfs_log_force_inode(
-	struct xfs_inode	*ip)
+	struct xfs_inode	*ip,
+	bool			datasync,
+	int			*log_flushed)
 {
 	struct xfs_inode_log_item *iip = ip->i_itemp;
 	xfs_csn_t		seq = 0;
@@ -2682,12 +2707,15 @@ xfs_log_force_inode(
 		return 0;
 
 	spin_lock(&iip->ili_lock);
-	seq = iip->ili_commit_seq;
+	if (datasync)
+		seq = iip->ili_datasync_seq;
+	else
+		seq = iip->ili_commit_seq;
 	spin_unlock(&iip->ili_lock);
 
 	if (!seq)
 		return 0;
-	return xfs_log_force_seq(ip->i_mount, seq, XFS_LOG_SYNC, NULL);
+	return xfs_log_force_seq(ip->i_mount, seq, XFS_LOG_SYNC, log_flushed);
 }
 
 /*
diff --git a/fs/xfs/xfs_inode.h b/fs/xfs/xfs_inode.h
index 1fa442b646..6dfd9271e6 100644
--- a/fs/xfs/xfs_inode.h
+++ b/fs/xfs/xfs_inode.h
@@ -595,7 +595,8 @@ int		xfs_ifree(struct xfs_trans *, struct xfs_inode *);
 int		xfs_itruncate_extents_flags(struct xfs_trans **,
 				struct xfs_inode *, int, xfs_fsize_t, int);
 
-int		xfs_log_force_inode(struct xfs_inode *ip);
+int		xfs_log_force_inode(struct xfs_inode *ip, bool datasync,
+				int *log_flushed);
 void		xfs_iunpin_wait(xfs_inode_t *);
 #define xfs_ipincount(ip)	((unsigned int) atomic_read(&ip->i_pincount))
 
diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index c1a6409f00..f4c4a02e5c 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -118,7 +118,7 @@ xfs_fs_map_update_inode(
 	 * Force the log so that the blocks handed out to the client are
 	 * guaranteed to be present even after a server crash.
 	 */
-	return xfs_log_force_inode(ip);
+	return xfs_log_force_inode(ip, false, NULL);
 }
 
 /*
diff --git a/fs/xfs/xfs_zone_gc.c b/fs/xfs/xfs_zone_gc.c
index 54b70ed292..cea5447a88 100644
--- a/fs/xfs/xfs_zone_gc.c
+++ b/fs/xfs/xfs_zone_gc.c
@@ -1018,7 +1018,7 @@ xfs_zone_gc_reset_zones(
 		struct xfs_gc_bio	*chunk;
 		struct bio		*bio;
 
-		xfs_log_force_inode(rtg_rmap(rtg));
+		xfs_log_force_inode(rtg_rmap(rtg), false, NULL);
 
 		next = rtg_group(rtg)->xg_next_reset;
 		rtg_group(rtg)->xg_next_reset = NULL;

-- 
2.43.0

