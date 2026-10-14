From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 14 Oct 2026 12:43:10 +0900
Subject: [PATCH v2 1/2] xfs: move xfs_fsync_flush_log() next to
 xfs_log_force_inode()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-xfs-pnfs-commit-datasync-v2-1-c11341a189b5@samsung.com>
References: <20261014-xfs-pnfs-commit-datasync-v2-0-c11341a189b5@samsung.com>
In-Reply-To: <20261014-xfs-pnfs-commit-datasync-v2-0-c11341a189b5@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791949389; l=6051;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=EEoN4C2mu5rEVtPAeTzFbTEBWfQzNvqL4/43qXNXEiM=;
 b=kamuJ+OxoGn4R3BXrCGn56Rt/8eo4jCytbF22Ss6aSqjlW6e7Mv5mAiTS6o/E89ytlYqHU/dl
 tOD21gnxfR+BMlaI0OaQ1N424OVGM2BTXiAmtaZGxk3BfNQxcmHu35v
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_log_force_inode() is xfs_fsync_flush_log() without a datasync
variant and without the log_flushed result, plus a check for an inode
without a log item. Move xfs_fsync_flush_log() to xfs_inode.c as
__xfs_log_force_inode(), with that check, and make
xfs_log_force_inode() a wrapper around it, so that code outside
xfs_file.c can force the log for a datasync. The next patch uses it in
the pNFS LAYOUTCOMMIT path.

No functional change: xfs_file_fsync() only calls it for an inode with
a log item, and xfs_log_force_inode() passes no datasync and no
log_flushed, as before.

Suggested-by: Christoph Hellwig <hch@lst.de>
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/xfs/xfs_file.c  | 44 +-------------------------------------------
 fs/xfs/xfs_inode.c | 42 +++++++++++++++++++++++++++++++++++++-----
 fs/xfs/xfs_inode.h |  2 ++
 3 files changed, 40 insertions(+), 48 deletions(-)

diff --git a/fs/xfs/xfs_file.c b/fs/xfs/xfs_file.c
index 7d0c8a1975..2c70e8ca7f 100644
--- a/fs/xfs/xfs_file.c
+++ b/fs/xfs/xfs_file.c
@@ -79,48 +79,6 @@ xfs_dir_fsync(
 	return xfs_log_force_inode(ip);
 }
 
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
-}
-
 STATIC int
 xfs_file_fsync(
 	struct file		*file,
@@ -151,7 +109,7 @@ xfs_file_fsync(
 	 * no modifications to this inode that need to be pushed out.
 	 */
 	if (ip->i_itemp) {
-		error = xfs_fsync_flush_log(ip, datasync, &log_flushed);
+		error = __xfs_log_force_inode(ip, datasync, &log_flushed);
 		if (error)
 			return error;
 	}
diff --git a/fs/xfs/xfs_inode.c b/fs/xfs/xfs_inode.c
index 15b62574b8..d9ba9260e8 100644
--- a/fs/xfs/xfs_inode.c
+++ b/fs/xfs/xfs_inode.c
@@ -2669,11 +2669,30 @@ xfs_irele(
 }
 
 /*
- * Ensure all committed transactions touching the inode are written to the log.
+ * All metadata updates are logged, which means that we just have to push the
+ * journal to the required sequence number than holds the updates. We track
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
  */
 int
-xfs_log_force_inode(
-	struct xfs_inode	*ip)
+__xfs_log_force_inode(
+	struct xfs_inode	*ip,
+	bool			datasync,
+	int			*log_flushed)
 {
 	struct xfs_inode_log_item *iip = ip->i_itemp;
 	xfs_csn_t		seq = 0;
@@ -2682,12 +2701,25 @@ xfs_log_force_inode(
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
+}
+
+/*
+ * Ensure all committed transactions touching the inode are written to the log.
+ */
+int
+xfs_log_force_inode(
+	struct xfs_inode	*ip)
+{
+	return __xfs_log_force_inode(ip, false, NULL);
 }
 
 /*
diff --git a/fs/xfs/xfs_inode.h b/fs/xfs/xfs_inode.h
index 1602027cd0..a3dc5f55d6 100644
--- a/fs/xfs/xfs_inode.h
+++ b/fs/xfs/xfs_inode.h
@@ -586,6 +586,8 @@ int		xfs_ifree(struct xfs_trans *, struct xfs_inode *);
 int		xfs_itruncate_extents_flags(struct xfs_trans **,
 				struct xfs_inode *, int, xfs_fsize_t, int);
 
+int		__xfs_log_force_inode(struct xfs_inode *ip, bool datasync,
+				int *log_flushed);
 int		xfs_log_force_inode(struct xfs_inode *ip);
 void		xfs_iunpin_wait(xfs_inode_t *);
 #define xfs_ipincount(ip)	((unsigned int) atomic_read(&ip->i_pincount))

-- 
2.43.0

