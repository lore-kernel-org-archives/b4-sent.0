From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 29 Oct 2026 11:23:06 +0900
Subject: [PATCH v5 9/9] xfs: make pNFS LAYOUTCOMMIT stable the way
 fdatasync does
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-xfs-pnfs-batch-v5-9-ef8d2eafb7fa@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793240577; l=2939;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=zMi4+NHyFoBXkEeHRNMf+DhfmCMGbT+Omkai4dVCPZE=;
 b=XQiXgVbPqOBEnmTpohI/2RUmK8qOZUVnuVG24MMLoXHI6r22vHlaz3Gpkpzv/usBuvQ485iA5
 X+PVx9AXZG7AIGZvl74JDNG/Hpv2LSFgDcA7yUn07lT9Qo5RyJeDuFp
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Every LAYOUTCOMMIT commits a synchronous transaction and forces the
log. fdatasync after the same overwrite does not, because timestamps
alone do not set ili_datasync_seq.

Do what fdatasync does. Commit without XFS_TRANS_SYNC, force the log up
to ili_datasync_seq, and flush the data device cache if that wrote no
iclog. Conversions and size changes still force the log. As with
fdatasync, a crash before the next log write can lose the new
timestamps and the change attribute that nfsd derives from the ctime.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
Reviewed-by: Christoph Hellwig <hch@lst.de>
---
With the block layout on NVMe/TCP in QEMU, 64 KiB overwrites of a
16 MiB file with fsync each took 473 ms instead of 800 ms. With 4
writers, one file each, 1011 ms instead of 1083 ms (medians of 5 runs).
---
 fs/xfs/xfs_pnfs.c | 21 +++++++++++++++------
 1 file changed, 15 insertions(+), 6 deletions(-)

diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index f4c4a02e5c..065875c8b7 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -295,10 +295,12 @@ xfs_pnfs_validate_isize(
  * converting any unwritten extents, flushing the disk cache and updating the
  * time stamps.
  *
- * Note that we rely on the caller to always send us a timestamp update so that
- * we always commit a transaction here.  If that stops being true we will have
- * to manually flush the cache here similar to what the fsync code path does
- * for datasyncs on files that have no dirty metadata.
+ * Like fdatasync, a commit that only updates the timestamps does not force the
+ * log: they are logged as XFS_ILOG_TIMESTAMP and reach the disk with a later
+ * log write. The log is forced up to the last change that a datasync needs,
+ * such as the unwritten extent conversions or a new size, and the cache of the
+ * device holding the file data is flushed if that log force did not write an
+ * iclog itself.
  */
 static int
 xfs_fs_commit_blocks(
@@ -312,6 +314,7 @@ xfs_fs_commit_blocks(
 	struct xfs_trans	*tp;
 	struct timespec64	now;
 	bool			update_isize = false;
+	int			log_flushed = 0;
 	int			error, i;
 	loff_t			size;
 
@@ -368,7 +371,8 @@ xfs_fs_commit_blocks(
 
 	xfs_ilock(ip, XFS_ILOCK_EXCL);
 	xfs_trans_ijoin(tp, ip, XFS_ILOCK_EXCL);
-	xfs_trans_log_inode(tp, ip, XFS_ILOG_CORE);
+	xfs_trans_log_inode(tp, ip,
+			update_isize ? XFS_ILOG_CORE : XFS_ILOG_TIMESTAMP);
 
 	now = inode_set_ctime_current(inode);
 	inode_set_atime_to_ts(inode, now);
@@ -379,8 +383,13 @@ xfs_fs_commit_blocks(
 		ip->i_disk_size = new_size;
 	}
 
-	xfs_trans_set_sync(tp);
 	error = xfs_trans_commit(tp);
+	if (error)
+		goto out_drop_iolock;
+
+	error = xfs_log_force_inode(ip, true, &log_flushed);
+	if (!error && !log_flushed)
+		error = blkdev_issue_flush(xfs_inode_buftarg(ip)->bt_bdev);
 
 out_drop_iolock:
 	xfs_iunlock(ip, XFS_IOLOCK_EXCL);

-- 
2.43.0

