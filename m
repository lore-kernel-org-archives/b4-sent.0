From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 14 Oct 2026 12:42:58 +0900
Subject: [PATCH v2 1/2] xfs: refuse a pNFS LAYOUTCOMMIT of a range without
 blocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-xfs-pnfs-commit-hole-v2-1-d3a02a79ab6c@samsung.com>
References: <20261014-xfs-pnfs-commit-hole-v2-0-d3a02a79ab6c@samsung.com>
In-Reply-To: <20261014-xfs-pnfs-commit-hole-v2-0-d3a02a79ab6c@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, linux-nfs@vger.kernel.org, 
 Andrey Albershteyn <aalbersh@kernel.org>, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791949377; l=7960;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=9+k4mUpONSU1WRs5BKsYgMVyLgF0YzOV4HCFJgDRn10=;
 b=wgIFWh1ej7RXGPbyYHWL7amSGM9Sm5dz+TYamOfLmbzKTHAmu+2BnxcArzCkAbHijABPnOobm
 y2JiseDkbnrAirHTnjfz+BUkAvXv4gTXdQc2nUniuk/gcn8IvR5Slgd
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
Add XFS_BMAPI_CONVERT_ONLY, which makes xfs_bmapi_write() fail with -EIO
instead of allocating blocks for a hole or a delalloc extent, and pass
it from xfs_fs_commit_blocks() through xfs_iomap_write_unwritten(). Each
xfs_bmapi_write() call finds the extent and converts it in one
transaction under the ILOCK, so nothing can change it between the check
and the conversion. -EIO is what xfs_pnfs_validate_isize() returns when
the new size falls into a hole.

Ranges before the hole have been converted by the time the commit
fails, as they would have been had the client committed them in a
LAYOUTCOMMIT of their own. Later ranges are left alone, and the
timestamps and the size are not updated.

With this, both LAYOUTCOMMITs get NFS4ERR_IO, XFS keeps running and no
block is allocated.

Suggested-by: Christoph Hellwig <hch@lst.de>
Fixes: 527851124d10 ("xfs: implement pNFS export operations")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/xfs/libxfs/xfs_bmap.c | 14 ++++++++++++++
 fs/xfs/libxfs/xfs_bmap.h | 10 +++++++++-
 fs/xfs/xfs_file.c        |  2 +-
 fs/xfs/xfs_ioend.c       |  2 +-
 fs/xfs/xfs_iomap.c       |  7 ++++---
 fs/xfs/xfs_iomap.h       |  3 ++-
 fs/xfs/xfs_pnfs.c        |  9 ++++++++-
 7 files changed, 39 insertions(+), 8 deletions(-)

diff --git a/fs/xfs/libxfs/xfs_bmap.c b/fs/xfs/libxfs/xfs_bmap.c
index 9bffde1484..fbfbfaf2b3 100644
--- a/fs/xfs/libxfs/xfs_bmap.c
+++ b/fs/xfs/libxfs/xfs_bmap.c
@@ -4130,6 +4130,8 @@ xfs_bmapi_finish(
  * Returns a negative error code on failure, including -ENOSPC when it could not
  * allocate any blocks and -ENOSR when it did allocate blocks to convert a
  * delalloc range, but those blocks were before the passed in range.
+ * With XFS_BMAPI_CONVERT_ONLY, returns -EIO instead of allocating blocks when
+ * the range starts with a hole or a delalloc extent.
  */
 int
 xfs_bmapi_write(
@@ -4237,6 +4239,18 @@ xfs_bmapi_write(
 		 * that we found, if any.
 		 */
 		if (need_alloc || wasdelay) {
+			if (flags & XFS_BMAPI_CONVERT_ONLY) {
+				/*
+				 * Earlier mappings may have dirtied the
+				 * transaction, so return them and fail on the
+				 * next call.
+				 */
+				if (n)
+					break;
+				error = -EIO;
+				goto error0;
+			}
+
 			bma.eof = eof;
 			bma.conv = !!(flags & XFS_BMAPI_CONVERT);
 			bma.wasdel = wasdelay;
diff --git a/fs/xfs/libxfs/xfs_bmap.h b/fs/xfs/libxfs/xfs_bmap.h
index 60f6df4ce0..a0bc9cd412 100644
--- a/fs/xfs/libxfs/xfs_bmap.h
+++ b/fs/xfs/libxfs/xfs_bmap.h
@@ -90,6 +90,13 @@ struct xfs_bmalloca {
 /* Try to align allocations to the extent size hint */
 #define XFS_BMAPI_EXTSZALIGN	(1u << 11)
 
+/*
+ * Use with XFS_BMAPI_CONVERT to convert unwritten extents without allocating
+ * blocks. Stop at a hole or a delalloc extent: return the mappings found so
+ * far, or fail with -EIO if there are none.
+ */
+#define XFS_BMAPI_CONVERT_ONLY	(1u << 12)
+
 #define XFS_BMAPI_FLAGS \
 	{ XFS_BMAPI_ENTIRE,	"ENTIRE" }, \
 	{ XFS_BMAPI_METADATA,	"METADATA" }, \
@@ -102,7 +109,8 @@ struct xfs_bmalloca {
 	{ XFS_BMAPI_COWFORK,	"COWFORK" }, \
 	{ XFS_BMAPI_NODISCARD,	"NODISCARD" }, \
 	{ XFS_BMAPI_NORMAP,	"NORMAP" },\
-	{ XFS_BMAPI_EXTSZALIGN,	"EXTSZALIGN" }
+	{ XFS_BMAPI_EXTSZALIGN,	"EXTSZALIGN" }, \
+	{ XFS_BMAPI_CONVERT_ONLY,	"CONVERT_ONLY" }
 
 
 static inline int xfs_bmapi_aflag(int w)
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
index f0e01ac34d..6d4d084c71 100644
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
index 329c745e31..7c3630be65 100644
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
@@ -676,8 +677,8 @@ xfs_iomap_write_unwritten(
 		 */
 		nimaps = 1;
 		error = xfs_bmapi_write(tp, ip, offset_fsb, count_fsb,
-					XFS_BMAPI_CONVERT, resblks, &imap,
-					&nimaps);
+					XFS_BMAPI_CONVERT | bmapi_flags,
+					resblks, &imap, &nimaps);
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
index ab38561700..05c9660aea 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -328,7 +328,14 @@ xfs_fs_commit_blocks(
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

