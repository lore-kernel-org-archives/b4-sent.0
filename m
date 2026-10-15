From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 15 Oct 2026 13:08:08 +0900
Subject: [PATCH v3 9/9] xfs: make pNFS LAYOUTCOMMIT stable the way
 fdatasync does
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-xfs-pnfs-batch-v3-9-54fc7b2e467d@samsung.com>
References: <20261015-xfs-pnfs-batch-v3-0-54fc7b2e467d@samsung.com>
In-Reply-To: <20261015-xfs-pnfs-batch-v3-0-54fc7b2e467d@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, 
 Andrey Albershteyn <aalbersh@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792037279; l=5333;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=laXqq7TOR45+FMXiIBI9lNIgwekJrK+v7NewiqiFklI=;
 b=NJF1MfjxR3IHODdcVM2tSGuKwM5IgMC5wu+oG+8UnocjZul1G50vNBL6vt9Bjq36/aDguk1Dg
 FWfMvMRD11iDUudMZWe2fdD7CoFRW1hxHVcrgppvCk+mH/Gi2tOU8TJ
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_fs_commit_blocks() commits the timestamp update of every
LAYOUTCOMMIT as a synchronous transaction, so every LAYOUTCOMMIT forces
the log. When the client only overwrote blocks that were already written
on disk and the size does not change, the only metadata that this log
force makes stable for the file is the new timestamps. fdatasync after
the same overwrite does not force the log: a timestamp-only change does
not set ili_datasync_seq, and without it xfs_file_fsync() only flushes
the cache of the device that holds the file data. The comment above
xfs_fs_commit_blocks() says that it relies on always committing a
transaction, and that it would otherwise have to flush the cache the way
fsync does for a datasync.

Do it the way fdatasync does: log the timestamps as XFS_ILOG_TIMESTAMP
when the size does not change, commit the transaction without
XFS_TRANS_SYNC, force the log up to ili_datasync_seq, and flush the
cache of the device that holds the file data unless that log force wrote
an iclog. The unwritten extent conversions and a new size set
ili_datasync_seq, so a LAYOUTCOMMIT that converts extents or changes the
size still forces the log. So does a conversion that was done earlier,
for example by a direct write on the server: ili_datasync_seq stays set
until that conversion is on disk, so the log force covers it.

With the block layout on an NVMe/TCP namespace in QEMU, backed by a
partition of an NVMe SSD with a volatile write cache, one client process
overwriting a 16 MiB file in 64 KiB writes, each followed by fsync, took
473 ms instead of 800 ms (median of 5 runs). On average a LAYOUTCOMMIT
spent 1.1 ms in xfs_fs_commit_blocks() instead of 2.4 ms, and none wrote
an iclog. With 4 KiB writes to a 4 MiB file it took 1841 ms instead of
3101 ms. A LAYOUTCOMMIT now issues an empty cache flush instead of a log
write with REQ_PREFLUSH and REQ_FUA. The guest that ran nvmet reached
the SSD through virtio-blk, which has no FUA, so there the FUA cost a
second cache flush. The gain should be smaller with native FUA and on a
device without a volatile write cache. It is also smaller with several
writers: 4 threads overwriting 16 MiB files in 64 KiB writes took
1011 ms instead of 1083 ms. LAYOUTCOMMITs of new files force the log as
before.

As with fdatasync, the timestamps of a LAYOUTCOMMIT that converts
nothing and keeps the size, and the change attribute that nfsd derives
from the ctime, reach the disk with a later log write instead of before
the reply, at the latest the one that the log worker issues every 30 s
by default. After a crash in that window, the change attribute can go
back to the value it had before the LAYOUTCOMMIT, while the data the
client wrote is on disk. The Linux client sends LAYOUTCOMMIT from both
fsync() and fdatasync() (pnfs_generic_sync() ignores datasync), so
fsync() on a block layout client now gets the timestamp guarantee of
fdatasync(). RFC 8881 section 12.5.4 says that LAYOUTCOMMIT may require
committing the block list to stable storage, which this keeps, and
section 12.5.4.1 only asks that the updated attributes be visible when
it completes.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/xfs/xfs_pnfs.c | 21 +++++++++++++++------
 1 file changed, 15 insertions(+), 6 deletions(-)

diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index dd2df30717..14c115638f 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -296,10 +296,12 @@ xfs_pnfs_validate_isize(
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
@@ -313,6 +315,7 @@ xfs_fs_commit_blocks(
 	struct xfs_trans	*tp;
 	struct timespec64	now;
 	bool			update_isize = false;
+	int			log_flushed = 0;
 	int			error, i;
 	loff_t			size;
 
@@ -369,7 +372,8 @@ xfs_fs_commit_blocks(
 
 	xfs_ilock(ip, XFS_ILOCK_EXCL);
 	xfs_trans_ijoin(tp, ip, XFS_ILOCK_EXCL);
-	xfs_trans_log_inode(tp, ip, XFS_ILOG_CORE);
+	xfs_trans_log_inode(tp, ip,
+			update_isize ? XFS_ILOG_CORE : XFS_ILOG_TIMESTAMP);
 
 	now = inode_set_ctime_current(inode);
 	inode_set_atime_to_ts(inode, now);
@@ -380,8 +384,13 @@ xfs_fs_commit_blocks(
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

