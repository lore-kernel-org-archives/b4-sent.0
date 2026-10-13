From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 13 Oct 2026 17:54:44 +0900
Subject: [PATCH] xfs: make pNFS LAYOUTCOMMIT stable the way fdatasync does
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-xfs-pnfs-commit-datasync-v1-1-2a12ef89ecd9@samsung.com>
X-B4-Tracking: v=1; b=H4sIANPxzWoC/x2MMQqAMAwAvyKZDbRRLPgVcSg1agarNCJK8e8Wl
 4Mb7jIoJ2GFvsqQ+BKVPRaxdQVh9XFhlKk4kKHOGtvgPSsesSDs2yYnTv70+sSAJjhqyTnLnqD
 kR+JZ7n89jO/7ASW/80BqAAAA
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791881683; l=11372;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=ip7Msi6gT+JifFGVdHAmbTCV6iicDIeWhtwUO01WyTw=;
 b=TA86k7XdwKniuuC6WMzrAjfTjtocKO6EijU/YPm4yq/vt6dee0ah0N+08wKOKW/6mYSgNzI/7
 lvloau4g7KpBDIWpKi0jQFBEPc0thCEZYkJnEG0bO4zRnlicg6tYqoU
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
by default. The Linux client sends LAYOUTCOMMIT from both fsync() and
fdatasync() (pnfs_generic_sync() ignores datasync), so fsync() on a
block layout client now gets the timestamp guarantee of fdatasync().
RFC 8881 section 12.5.4 says that LAYOUTCOMMIT may require committing
the block list to stable storage, which this keeps, and section 12.5.4.1
only asks that the updated attributes be visible when it completes.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
With this, the timestamps of a LAYOUTCOMMIT that converts nothing and
keeps the size, and the change attribute that nfsd derives from the
ctime, are not stable when the reply goes out. After a server crash, a
client that cached the file before the LAYOUTCOMMIT could see the old
change attribute again and keep its stale cache until the file changes.
A WRITE with DATA_SYNC4 already leaves the timestamps that way ("persist
data only" in nfsd_vfs_write(), nfsd4_iocb_flags() in nfsd-testing),
although there the client asks for it, and the comment above
nfsd4_change_attribute() assumes a stable change attribute only for
directories.

On a sync export, nfsd makes most metadata operations stable before it
replies: commit_metadata() after SETATTR, ALLOCATE, DEALLOCATE, create,
link, rename and unlink, and a full fsync for CLONE and, as RFC 8881
section 18.3.4 asks, for COMMIT. With this patch, a LAYOUTCOMMIT on a
sync export replies before its timestamps are stable, unlike those.
LAYOUTCOMMIT is not that COMMIT: section 12.5.4 says "The data should be
written and committed to the appropriate storage devices before the
LAYOUTCOMMIT occurs", and of durability it says only that for block
layouts LAYOUTCOMMIT may require committing the block list to stable
storage, which this patch keeps. If nfsd wants LAYOUTCOMMIT to follow
the sync export option anyway, ->commit_blocks can take a datasync
argument as ->fsync does, but sync is the default, so the gain would
then be limited to async exports.

Tested on nfsd-testing d918c664efd5 with the same change, in QEMU
guests: nfsd on XFS (mkfs.xfs defaults, internal log, sync export), the
block layout on an NVMe/TCP namespace exported by nvmet from another
guest, and the Linux NFSv4.2 client. The patch applies to XFS for-next
0be6da616ab5 as is.

nfsd-testing does not have commit e3c682dd1130 ("xfs: map pNFS layouts
to the end of the extent again"), which only changes LAYOUTGET, nor the
for-next changes to the log cache flushes (xlog_flush_data_caches() and
XLOG_ICL_NEED_FLUSH_LOG), which only matter with an external log or an
rt device.

 - Overwrites of written files, each write followed by fsync, KASAN
   and lockdep off. The namespace was backed by a partition of a
   Samsung 990 PRO (volatile write cache), given to the nvmet guest as
   virtio-blk with cache=none. virtio-blk has no FUA, so REQ_FUA became
   a write plus a cache flush there. Medians of 5 runs, with the
   kernels without and with the patch alternating; "ms each" is the
   time in xfs_fs_commit_blocks() per LAYOUTCOMMIT:

     threads  file    write   without    with  commits  ms each
     1        16 MiB  64 KiB   800 ms  473 ms   256   2.4 -> 1.1
     4        16 MiB  64 KiB  1083 ms 1011 ms  1024   2.6 -> 2.5
     1         4 MiB   4 KiB  3101 ms 1841 ms  1024   2.6 -> 1.5

   With the patch no LAYOUTCOMMIT forced the log, and the log was
   written at most once per run. With 4 writers the gain is smaller:
   without the patch their log forces are partly shared, and with it
   their cache flushes queue up. Overwrites of 64 MiB files in 4 MiB
   writes by 4 threads took 1150 ms instead of 1328 ms, medians of 3
   runs that overlap (1114 to 1214 ms against 1181 to 1424 ms) and did
   not alternate.
 - New files, 4 threads writing 64 MiB each in 4 MiB writes, each
   write followed by fsync: every LAYOUTCOMMIT still forced the log, as
   before.
 - A crash right after a LAYOUTCOMMIT of an extent that the server had
   just converted with a direct write, before that conversion was
   written to the log: the server preallocated 4 MiB and wrote it with
   O_DIRECT, the client overwrote it through the layout and called
   fsync, and the server VM was killed. After mount, the extent was
   written and held the client's data, with and without the patch (2
   runs each). A prototype that only flushed the cache when the range
   was written in memory and the size did not change lost the data in
   both runs: the extent came back unwritten.
 - The same crash after the client wrote a new 4 MiB file through the
   layout and called fsync (allocation, conversion and a new size):
   size, extent and data were all there, with and without the patch
   (2 runs each).
 - With a KASAN and lockdep kernel, and no warnings from either: pynfs
   block and blockextent, same as without the patch (BLOCK3 fails
   either way, on a bug in the test); fstests generic/075, 091 and 263
   over the block layout, where 075 fails with an fsx size error as it
   does without the patch, and none of the 10337 LAYOUTCOMMITs failed.
   The pynfs tests also passed the same way on an XFS_DEBUG kernel with
   XFS_ASSERT_FATAL.
 - W=1 builds of fs/xfs/xfs_pnfs.o and fs/xfs/xfs_file.o on XFS
   for-next 0be6da616ab5 and on nfsd-testing: no warnings.

If preferred, I can factor the end of xfs_file_fsync() into a helper
that both use, instead of exporting xfs_fsync_flush_log().
---
 fs/xfs/xfs_file.c |  2 +-
 fs/xfs/xfs_file.h |  2 ++
 fs/xfs/xfs_pnfs.c | 22 ++++++++++++++++------
 3 files changed, 19 insertions(+), 7 deletions(-)

diff --git a/fs/xfs/xfs_file.c b/fs/xfs/xfs_file.c
index 7d0c8a1975..851c5d830e 100644
--- a/fs/xfs/xfs_file.c
+++ b/fs/xfs/xfs_file.c
@@ -99,7 +99,7 @@ xfs_dir_fsync(
  * waiting on sequences that are still in flight to correctly order concurrent
  * sync operations.
  */
-static int
+int
 xfs_fsync_flush_log(
 	struct xfs_inode	*ip,
 	bool			datasync,
diff --git a/fs/xfs/xfs_file.h b/fs/xfs/xfs_file.h
index 2ad91f755c..a10d684ecb 100644
--- a/fs/xfs/xfs_file.h
+++ b/fs/xfs/xfs_file.h
@@ -11,5 +11,7 @@ extern const struct file_operations xfs_dir_file_operations;
 
 bool xfs_is_falloc_aligned(struct xfs_inode *ip, loff_t pos,
 		long long int len);
+int xfs_fsync_flush_log(struct xfs_inode *ip, bool datasync,
+		int *log_flushed);
 
 #endif /* __XFS_FILE_H__ */
diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index ab38561700..850c07e611 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -13,6 +13,7 @@
 #include "xfs_bmap.h"
 #include "xfs_iomap.h"
 #include "xfs_pnfs.h"
+#include "xfs_file.h"
 #include <linux/exportfs_block.h>
 
 /*
@@ -277,10 +278,12 @@ xfs_pnfs_validate_isize(
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
@@ -294,6 +297,7 @@ xfs_fs_commit_blocks(
 	struct xfs_trans	*tp;
 	struct timespec64	now;
 	bool			update_isize = false;
+	int			log_flushed = 0;
 	int			error, i;
 	loff_t			size;
 
@@ -345,7 +349,8 @@ xfs_fs_commit_blocks(
 
 	xfs_ilock(ip, XFS_ILOCK_EXCL);
 	xfs_trans_ijoin(tp, ip, XFS_ILOCK_EXCL);
-	xfs_trans_log_inode(tp, ip, XFS_ILOG_CORE);
+	xfs_trans_log_inode(tp, ip,
+			update_isize ? XFS_ILOG_CORE : XFS_ILOG_TIMESTAMP);
 
 	now = inode_set_ctime_current(inode);
 	inode_set_atime_to_ts(inode, now);
@@ -356,8 +361,13 @@ xfs_fs_commit_blocks(
 		ip->i_disk_size = new_size;
 	}
 
-	xfs_trans_set_sync(tp);
 	error = xfs_trans_commit(tp);
+	if (error)
+		goto out_drop_iolock;
+
+	error = xfs_fsync_flush_log(ip, true, &log_flushed);
+	if (!error && !log_flushed)
+		error = blkdev_issue_flush(xfs_inode_buftarg(ip)->bt_bdev);
 
 out_drop_iolock:
 	xfs_iunlock(ip, XFS_IOLOCK_EXCL);

---
base-commit: 0be6da616ab5031ea6419dc4fe0bf0e378fb6757
change-id: 20261013-xfs-pnfs-commit-datasync-0c7242771ea2

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

