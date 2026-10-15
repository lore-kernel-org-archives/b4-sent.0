From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 15 Oct 2026 13:08:02 +0900
Subject: [PATCH v3 3/9] xfs: refuse a pNFS LAYOUTCOMMIT of a range without
 blocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-xfs-pnfs-batch-v3-3-54fc7b2e467d@samsung.com>
References: <20261015-xfs-pnfs-batch-v3-0-54fc7b2e467d@samsung.com>
In-Reply-To: <20261015-xfs-pnfs-batch-v3-0-54fc7b2e467d@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, 
 Andrey Albershteyn <aalbersh@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792037279; l=6693;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=y9oXsSXKxNQ7tKvuRud909UiKn5rkRIXj2FcEPvkFdU=;
 b=rljg2GbhSwNLbo4O17fiIpwfzGPG7myNGf4P3GIFicqySDhw11O6nJ3bVD4MGsbLNWE4qtX0o
 5/ZJtagwvt7Bpl7ion5xIJYkmaDOMGw4kbS/9d7sDw3GCssUWd5sRL4
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_fs_commit_blocks() passes every range that a pNFS client commits to
xfs_iomap_write_unwritten(), whatever is mapped there, and the range can
be a hole. nfsd does not check the extents of a block or SCSI layout
LAYOUTCOMMIT against the layouts it handed out, and for a reclaim during
the grace period it has no layouts to check against, so a client can
commit a range that it never had a layout for.

For a hole, xfs_bmapi_write() with XFS_BMAPI_CONVERT allocates new
blocks as written extents, while the transaction only reserved blocks
for bmbt splits. A hole larger than that reservation shuts XFS down:

  XFS (nvme0n1): Corruption of in-memory data (0x8) detected at
    xfs_trans_mod_sb+0x817/0x960 (fs/xfs/xfs_trans.c:351).
    Shutting down filesystem.

A smaller hole gets blocks that nobody wrote mapped into the file as
data, so readers see whatever those blocks held, and the LAYOUTCOMMIT
succeeds.

With pynfs as the client and an RW layout for the first 64 KiB of a
2 MiB sparse file, a LAYOUTCOMMIT of 64 KiB at offset 1 MiB, which no
layout covered, got NFS4ERR_IO and shut XFS down. A LAYOUTCOMMIT of
4 KiB at 1 MiB got NFS4_OK, and the file got a written block there. The
client wrote nothing to the device in either case.

A client may only write to blocks that a layout handed out, and
xfs_fs_map_blocks() allocates blocks for any hole in a write layout, so
a committed range without blocks holds nothing that can be committed.
Pass XFS_BMAPI_CONVERT_ONLY from xfs_fs_commit_blocks() through
xfs_iomap_write_unwritten(), and fail with -EIO when xfs_bmapi_write()
finds a hole or a delalloc extent. Each xfs_bmapi_write() call finds the
extent and converts it in one transaction under the ILOCK, so nothing
can change it between the check and the conversion. -EIO is what
xfs_pnfs_validate_isize() returns when the new size falls into a hole.

xfs_iomap_write_unwritten() commits the transaction instead of
cancelling it when it fails this way, as xfs_alloc_file_space() does
after -ENOSR. xfs_iext_count_extend() logs the inode when it moves the
inode to large extent counters, which happens when the data fork of an
inode without large extent counts nears 2^31 extents on a filesystem
that supports them, and cancelling a dirty transaction shuts the
filesystem down.

Ranges before the hole have been converted by the time the commit
fails, as they would have been had the client committed them in a
LAYOUTCOMMIT of their own. Later ranges are left alone, and the
timestamps and the size are not updated.

With this, both LAYOUTCOMMITs get NFS4ERR_IO, XFS keeps running and no
block is allocated.

Link: https://lore.kernel.org/r/20261014130834.GB15773@lst.de
Fixes: 527851124d10 ("xfs: implement pNFS export operations")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/xfs/xfs_file.c  |  2 +-
 fs/xfs/xfs_ioend.c |  2 +-
 fs/xfs/xfs_iomap.c | 20 +++++++++++++++++---
 fs/xfs/xfs_iomap.h |  3 ++-
 fs/xfs/xfs_pnfs.c  |  9 ++++++++-
 5 files changed, 29 insertions(+), 7 deletions(-)

diff --git a/fs/xfs/xfs_file.c b/fs/xfs/xfs_file.c
index 7d0c8a1975..720f4a9b40 100644
--- a/fs/xfs/xfs_file.c
+++ b/fs/xfs/xfs_file.c
@@ -666,7 +666,7 @@ xfs_dio_write_end_io(
 	 * they are converted.
 	 */
 	if (flags & IOMAP_DIO_UNWRITTEN) {
-		error = xfs_iomap_write_unwritten(ip, offset, size, true);
+		error = xfs_iomap_write_unwritten(ip, offset, size, true, 0);
 		goto out;
 	}
 
diff --git a/fs/xfs/xfs_ioend.c b/fs/xfs/xfs_ioend.c
index 48becc3bf6..7f4a4a95af 100644
--- a/fs/xfs/xfs_ioend.c
+++ b/fs/xfs/xfs_ioend.c
@@ -237,7 +237,7 @@ xfs_end_ioend_write(
 	if (ioend->io_flags & IOMAP_IOEND_SHARED)
 		error = xfs_reflink_end_cow(ip, offset, size);
 	else if (ioend->io_flags & IOMAP_IOEND_UNWRITTEN)
-		error = xfs_iomap_write_unwritten(ip, offset, size, false);
+		error = xfs_iomap_write_unwritten(ip, offset, size, false, 0);
 
 	if (!error &&
 	    !(ioend->io_flags & IOMAP_IOEND_DIRECT) &&
diff --git a/fs/xfs/xfs_iomap.c b/fs/xfs/xfs_iomap.c
index 329c745e31..99d48081c5 100644
--- a/fs/xfs/xfs_iomap.c
+++ b/fs/xfs/xfs_iomap.c
@@ -614,7 +614,8 @@ xfs_iomap_write_unwritten(
 	xfs_inode_t	*ip,
 	xfs_off_t	offset,
 	xfs_off_t	count,
-	bool		update_isize)
+	bool		update_isize,
+	uint32_t	bmapi_flags)
 {
 	xfs_mount_t	*mp = ip->i_mount;
 	xfs_fileoff_t	offset_fsb;
@@ -676,8 +677,21 @@ xfs_iomap_write_unwritten(
 		 */
 		nimaps = 1;
 		error = xfs_bmapi_write(tp, ip, offset_fsb, count_fsb,
-					XFS_BMAPI_CONVERT, resblks, &imap,
-					&nimaps);
+					XFS_BMAPI_CONVERT | bmapi_flags,
+					resblks, &imap, &nimaps);
+		if (error == -ENOSR && (bmapi_flags & XFS_BMAPI_CONVERT_ONLY)) {
+			/*
+			 * Nothing was mapped: the rest of the range starts
+			 * with a hole or a delalloc extent. Nothing was
+			 * changed either, but xfs_iext_count_extend() may
+			 * have logged the inode, and cancelling a dirty
+			 * transaction shuts the filesystem down. Commit it,
+			 * as xfs_alloc_file_space() does on -ENOSR.
+			 */
+			error = xfs_trans_commit(tp);
+			xfs_iunlock(ip, XFS_ILOCK_EXCL);
+			return error ? error : -EIO;
+		}
 		if (error)
 			goto error_on_bmapi_transaction;
 
diff --git a/fs/xfs/xfs_iomap.h b/fs/xfs/xfs_iomap.h
index f2520a9b3a..8fc0c6fc8b 100644
--- a/fs/xfs/xfs_iomap.h
+++ b/fs/xfs/xfs_iomap.h
@@ -15,7 +15,8 @@ struct xfs_zone_alloc_ctx;
 int xfs_iomap_write_direct(struct xfs_inode *ip, xfs_fileoff_t offset_fsb,
 		xfs_fileoff_t count_fsb, unsigned int flags,
 		struct xfs_bmbt_irec *imap, u64 *sequence);
-int xfs_iomap_write_unwritten(struct xfs_inode *, xfs_off_t, xfs_off_t, bool);
+int xfs_iomap_write_unwritten(struct xfs_inode *ip, xfs_off_t offset,
+		xfs_off_t count, bool update_isize, uint32_t bmapi_flags);
 xfs_fileoff_t xfs_iomap_eof_align_last_fsb(struct xfs_inode *ip,
 		xfs_fileoff_t end_fsb);
 
diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index a9f0b472f3..7ff83274a5 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -344,7 +344,14 @@ xfs_fs_commit_blocks(
 					(end - 1) >> PAGE_SHIFT);
 		WARN_ON_ONCE(error);
 
-		error = xfs_iomap_write_unwritten(ip, start, length, false);
+		/*
+		 * A client may only write to blocks that a layout handed out,
+		 * and xfs_fs_map_blocks() allocates blocks for any hole in a
+		 * write layout, so refuse to allocate blocks for a hole or a
+		 * delalloc extent in the committed range.
+		 */
+		error = xfs_iomap_write_unwritten(ip, start, length, false,
+				XFS_BMAPI_CONVERT_ONLY);
 		if (error)
 			goto out_drop_iolock;
 	}

-- 
2.43.0

