From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 13 Oct 2026 15:00:51 +0900
Subject: [PATCH] xfs: refuse a pNFS LAYOUTCOMMIT of a range without blocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-xfs-pnfs-commit-hole-v1-1-740912db9102@samsung.com>
X-B4-Tracking: v=1; b=H4sIABLJzWoC/x2MywqAIBAAfyX23IIP6PUr0UFszYXS0IhA+veky
 8AcZgpkSkwZpqZAopszx1BFtg1Yb8JGyGt1UEJ1UkiFj8t4hgobj4Mv9HEntFoYGo0aeqehpmc
 ix8+/nZf3/QDDdNEmZgAAAA==
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791871250; l=9109;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=Bi4Nh3asVtu3vWZjxDBfgpyfYTuGljO1+XtVfwgnRxg=;
 b=GJqo7QNKAmRq/d9iJKVk3On4jj+V5vkQ+9TS4l7MnfsXzSyF+O8KdRohMmv2I/kKXd7LoHWCA
 Oe2Go/UzGOUDmEBGh8aEPEUs9/OQAC5FynZst6240gEZUDE3YejQomQ
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_fs_commit_blocks() passes every range that a pNFS client commits to
xfs_iomap_write_unwritten(), whatever is mapped there, and the range can
be a hole. nfsd does not check the extents of a block or SCSI layout
LAYOUTCOMMIT against the layouts it handed out, and for a reclaim during
the grace period it has no layouts to check against, so a client can
commit a range that it never had a layout for. Blocks under a layout can
also be freed: blockgc frees blocks past EOF that were already allocated
when a write layout handed them out, and a check in nfsd would not
notice that.

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
Check all the ranges before converting any of them, and fail the commit
with -EIO if one has a hole or a delalloc extent, as
xfs_pnfs_validate_isize() does when the new size falls into one. A
commit refused this way converts nothing: LAYOUTCOMMIT has a single
status, and after a partial conversion the client could not tell which
of its extents were committed. The iolock, held across the check and
the conversion, keeps blocks from being removed in between.

With this, both LAYOUTCOMMITs get NFS4ERR_IO, XFS keeps running and no
block is allocated. A LAYOUTCOMMIT of the laid-out range together with
the 64 KiB hole also gets NFS4ERR_IO and converts nothing, so the
laid-out range stays unwritten.

Also clamp the client's length to what is left below the size before
adding it to the offset, instead of clamping the sum. The sum can wrap
around. A wrapped range would skip the new check, and the conversion
loop already passes the client's length, unclamped, to
xfs_iomap_write_unwritten(). xfs_bmapi_write() then fails an assertion
on XFS_DEBUG kernels, which is a BUG with XFS_ASSERT_FATAL, and
otherwise returns -ENOSR, which nfsd warns about as a non-standard
errno. With the clamp, an extent of 2^64 - 4 KiB at 4 KiB in the same
file is checked only up to the size. It gets NFS4ERR_IO for the hole
after the laid-out range, without a warning or an assertion.

Fixes: 527851124d10 ("xfs: implement pNFS export operations")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested on nfsd-testing d918c664efd5 with the same change on top, all in
QEMU guests with KASAN and lockdep. The block layout was on an NVMe/TCP
namespace exported by nvmet. The client was pynfs, except for fstests,
which ran on the Linux NFSv4.2 client. XFS_DEBUG kernels were used for
one run of the pynfs tests with the patch and for the wrap case without
it. XFS for-next also has commit e3c682dd1130 ("xfs: map pNFS layouts to
the end of the extent again") in xfs_fs_map_blocks(), which nfsd-testing
does not have. xfs_fs_commit_blocks() and xfs_iomap_write_unwritten()
are the same in both trees. The pynfs tests for this are local; I can
post them if they are wanted.

 - A LAYOUTCOMMIT of a 64 KiB hole: NFS4ERR_IO and shutdown without the
   patch. With it, NFS4ERR_IO, no shutdown and nothing allocated, in 5
   runs.
 - A LAYOUTCOMMIT of a 4 KiB hole: NFS4_OK and a written block in the
   file without the patch. With it, NFS4ERR_IO and nothing allocated.
 - The laid-out range and the 64 KiB hole in one LAYOUTCOMMIT: shutdown
   without the patch. With it, NFS4ERR_IO, and fiemap on the server
   shows the laid-out range still unwritten.
 - An extent at 4 KiB with a length of 2^64 - 4 KiB: NFS4ERR_IO and
   "nfsd: non-standard errno: -63" without the patch, and with
   XFS_DEBUG "Assertion failed: bma.nallocs >= *nmap" in
   xfs_bmapi_write(). With it, NFS4ERR_IO and no warning, also with
   XFS_DEBUG.
 - Blocks past EOF freed by blockgc under a layout, without "xfs: mark
   the inode preallocated for pNFS write layouts past EOF" [1]: the
   LAYOUTCOMMIT after the client's write shut XFS down without this
   patch and got NFS4ERR_IO with it. The client's data is still lost
   there; [1] keeps those blocks.
 - pynfs block and blockextent: same as without the patch (BLOCK3 fails
   either way, on a bug in the test).
 - fstests generic/075, 091 and 263 over the block layout, with and
   without the patch: 075 fails with an fsx size error either way, and
   XFS refused none of the 10331 LAYOUTCOMMITs with the patch.
 - W=1 builds of fs/xfs/xfs_pnfs.o with the patch on XFS for-next
   0be6da616ab5 and on nfsd-testing d918c664efd5: no warnings.

-EIO follows xfs_pnfs_validate_isize() and reaches the client as
NFS4ERR_IO. No errno maps to NFS4ERR_BADLAYOUT, and the Linux client
treats NFS4ERR_BADLAYOUT on a LAYOUTCOMMIT as success. For a reclaim,
RFC 8881 section 18.42.3 requires NFS4ERR_RECLAIM_BAD, which nfsd would
have to map.

An nfsd check of the extents against the layouts would be a separate
change, and for the reasons above would not make this one unnecessary.
The shutdown came up in the review of the ->map_blocks series [2].

xfs_pnfs_validate_isize() reads the extents under XFS_ILOCK_SHARED,
which xfs_iread_extents() does not allow when they are not loaded yet.
That needs a separate fix.

[1] https://lore.kernel.org/r/20261012-xfs-pnfs-eof-prealloc-v1-1-e4864d917a00@samsung.com
[2] https://lore.kernel.org/r/20261012024846epcms2p7cccc5c988b2553b3f831070eb17e0455@epcms2p7
---
 fs/xfs/xfs_pnfs.c | 60 ++++++++++++++++++++++++++++++++++++++++++++++++++++---
 1 file changed, 57 insertions(+), 3 deletions(-)

diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index ab38561700..da60154198 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -272,6 +272,46 @@ xfs_pnfs_validate_isize(
 	return 0;
 }
 
+/*
+ * Ensure the committed range is backed by allocated blocks. A client may only
+ * write to blocks that a layout handed out, xfs_fs_map_blocks() allocates
+ * blocks for any hole in a write layout, and no layout hands out a delalloc
+ * extent. A hole or a delalloc extent in the range was either never laid out
+ * or lost its blocks after the layout was handed out, so nothing the client
+ * wrote can be committed there. Converting a hole would also allocate blocks
+ * that the transaction did not reserve.
+ */
+static int
+xfs_pnfs_validate_commit(
+	struct xfs_inode	*ip,
+	xfs_off_t		start,
+	xfs_off_t		end)
+{
+	struct xfs_mount	*mp = ip->i_mount;
+	xfs_fileoff_t		offset_fsb = XFS_B_TO_FSBT(mp, start);
+	xfs_fileoff_t		end_fsb = XFS_B_TO_FSB(mp, end);
+	struct xfs_bmbt_irec	imap;
+	uint			lock_flags;
+	int			nimaps;
+	int			error = 0;
+
+	lock_flags = xfs_ilock_data_map_shared(ip);
+	while (offset_fsb < end_fsb) {
+		nimaps = 1;
+		error = xfs_bmapi_read(ip, offset_fsb, end_fsb - offset_fsb,
+				&imap, &nimaps, 0);
+		if (error)
+			break;
+		if (!nimaps || !xfs_bmap_is_real_extent(&imap)) {
+			error = -EIO;
+			break;
+		}
+		offset_fsb = imap.br_startoff + imap.br_blockcount;
+	}
+	xfs_iunlock(ip, lock_flags);
+	return error;
+}
+
 /*
  * Make sure the blocks described by maps are stable on disk.  This includes
  * converting any unwritten extents, flushing the disk cache and updating the
@@ -305,6 +345,22 @@ xfs_fs_commit_blocks(
 		size = new_size;
 	}
 
+	/*
+	 * Check all of the maps before converting any of them, so that a commit
+	 * refused for a hole or a delalloc extent converts nothing.
+	 */
+	for (i = 0; i < nr_maps; i++) {
+		u64 start = maps[i].offset;
+		u64 end;
+
+		if (start >= size)
+			continue;
+		end = start + min_t(u64, maps[i].length, size - start);
+		error = xfs_pnfs_validate_commit(ip, start, end);
+		if (error)
+			goto out_drop_iolock;
+	}
+
 	for (i = 0; i < nr_maps; i++) {
 		u64 start, length, end;
 
@@ -312,9 +368,7 @@ xfs_fs_commit_blocks(
 		if (start > size)
 			continue;
 
-		end = start + maps[i].length;
-		if (end > size)
-			end = size;
+		end = start + min_t(u64, maps[i].length, size - start);
 
 		length = end - start;
 		if (!length)

---
base-commit: 0be6da616ab5031ea6419dc4fe0bf0e378fb6757
change-id: 20261012-xfs-pnfs-commit-hole-c30ae9a287f3

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

