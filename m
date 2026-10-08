From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 08 Oct 2026 10:39:36 +0900
Subject: [PATCH 7/8] xfs: map the whole range of a pNFS layout in one
 ->map_blocks call
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-xfs-nfsd-map-blocks-v1-7-560026cdccb6@samsung.com>
References: <20261008-xfs-nfsd-map-blocks-v1-0-560026cdccb6@samsung.com>
In-Reply-To: <20261008-xfs-nfsd-map-blocks-v1-0-560026cdccb6@samsung.com>
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>, 
 Christoph Hellwig <hch@lst.de>, Carlos Maiolino <cem@kernel.org>, 
 Amir Goldstein <amir73il@gmail.com>
Cc: "Darrick J. Wong" <djwong@kernel.org>, Dave Chinner <dgc@kernel.org>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-xfs@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791423569; l=5125;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=W4uxTtzIiaCL9JDyYl3vGOSp5Kpa7RtXwMu5dPaSg/w=;
 b=MoQFoCy96KsbPydtI0MJDOuWvKQFHn8oAQrtDWUCR0dd/+l+b7MmBSY5+sKxLYffoDiTuXKuS
 /ActQe5ajHfCs1GDfgRqOMfPpjRiZ+bBOcwF6dkkfApvoSSXzbIdCBr
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_fs_map_blocks() maps one extent per call, and nfsd calls it again
for the rest of the range. Each call takes the iolock and the
invalidate lock, flushes and invalidates the page cache, and, if it
allocated blocks for a write layout, updates the inode and forces the
log.

Map extent after extent until the range is covered or the array of
mappings is full, all under one hold of the iolock and the invalidate
lock, with one flush and invalidation and at most one inode update and
log force. Each mapping starts where the one before it ends.
xfs_fs_map_extent() never maps anything before the offset it is given,
which matters here: allocating a hole merges it with the extents around
it, and a mapping of the next offset would otherwise reach back over the
hole.

If an allocation fails after others in the same call, the error is
returned without the inode update and the log force. nfsd then fails the
LAYOUTGET, so none of the blocks allocated is handed out; they stay
unwritten, and blocks past EOF can be freed again unless the inode
already has XFS_DIFLAG_PREALLOC or the file is empty.

With the nfsd change that follows, a LAYOUTGET for the first 256 KiB of
a file in which 32 blocks of 4 KiB written with O_DIRECT are each
followed by a 4 KiB hole gets 64 extents in one call. For an RW layout,
which allocates the 32 holes, the log is forced once instead of 32
times, and nfsd4_block_proc_layoutget() takes 2.2 ms instead of 166 ms,
most of which were the 32 synchronous log forces (median of 20
LAYOUTGETs each; QEMU VMs, XFS on an NVMe/TCP namespace, pynfs as the
client, time from a kprobe, KASAN and lockdep off).

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/xfs/xfs_pnfs.c | 47 +++++++++++++++++++++++++++++++----------------
 1 file changed, 31 insertions(+), 16 deletions(-)

diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index bd6f7d5093..60c552c511 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -138,13 +138,12 @@ xfs_fs_map_extent(
 	/*
 	 * Map to the end of the extent that covers the start of the range,
 	 * so that a client doing I/O in pieces gets a layout it can use for
-	 * the pieces that follow.  Never map anything before the start of
-	 * the range: nfsd calls in here once per extent of a LAYOUTGET, for
-	 * the range that is left after the previous extent, and the mapping
-	 * can change in between, so a mapping that reaches back can overlap
-	 * one already in the layout.  Don't extend the mapping past EOF
-	 * beyond the range either: xfs_free_eofblocks() can free blocks past
-	 * EOF without breaking the layout.
+	 * the pieces that follow. Never map anything before @offset_fsb:
+	 * allocating the hole before it can have merged that hole with the
+	 * extents around it, and a mapping that reaches back would overlap
+	 * the previous one. Don't extend the mapping past EOF beyond the
+	 * range either: xfs_free_eofblocks() can free blocks past EOF without
+	 * breaking the layout.
 	 */
 	error = xfs_bmapi_read(ip, offset_fsb, end_fsb - offset_fsb,
 				imap, &nimaps, XFS_BMAPI_ENTIRE);
@@ -182,6 +181,10 @@ xfs_fs_map_extent(
 
 /*
  * Get a layout for the pNFS client.
+ *
+ * Map the range, or as much of it as fits into @iomaps, while holding the
+ * iolock and the invalidate lock, so that the mappings fit together: each
+ * one starts where the one before it ends.
  */
 static int
 xfs_fs_map_blocks(
@@ -195,14 +198,16 @@ xfs_fs_map_blocks(
 {
 	struct xfs_inode	*ip = XFS_I(inode);
 	struct xfs_mount	*mp = ip->i_mount;
-	struct xfs_bmbt_irec	imap;
+	xfs_fileoff_t		offset_fsb, end_fsb;
+	unsigned int		nr = 0;
 	bool			allocated = false;
 	loff_t			limit;
 	int			error = 0;
-	u64			seq;
 
 	if (xfs_is_shutdown(mp))
 		return -EIO;
+	if (WARN_ON_ONCE(!*nr_iomaps))
+		return -EINVAL;
 
 	/*
 	 * We can't export inodes residing on the realtime device.  The realtime
@@ -248,10 +253,21 @@ xfs_fs_map_blocks(
 	if (WARN_ON_ONCE(error))
 		goto out_unlock;
 
-	error = xfs_fs_map_extent(ip, XFS_B_TO_FSBT(mp, offset),
-			offset + length, write, &imap, &seq, &allocated);
-	if (error)
-		goto out_unlock;
+	offset_fsb = XFS_B_TO_FSBT(mp, offset);
+	end_fsb = XFS_B_TO_FSB(mp, (xfs_ufsize_t)offset + length);
+	while (nr < *nr_iomaps && offset_fsb < end_fsb) {
+		struct xfs_bmbt_irec	imap;
+		u64			seq;
+
+		error = xfs_fs_map_extent(ip, offset_fsb, offset + length,
+				write, &imap, &seq, &allocated);
+		if (error)
+			goto out_unlock;
+		error = xfs_bmbt_to_iomap(ip, &iomaps[nr++], &imap, 0, 0, seq);
+		if (error)
+			goto out_unlock;
+		offset_fsb = imap.br_startoff + imap.br_blockcount;
+	}
 
 	if (allocated) {
 		/*
@@ -267,10 +283,9 @@ xfs_fs_map_blocks(
 	}
 	xfs_iunlock(ip, XFS_IOLOCK_EXCL | XFS_MMAPLOCK_EXCL);
 
-	error = xfs_bmbt_to_iomap(ip, iomaps, &imap, 0, 0, seq);
-	*nr_iomaps = 1;
+	*nr_iomaps = nr;
 	*device_generation = mp->m_generation;
-	return error;
+	return 0;
 out_unlock:
 	xfs_iunlock(ip, XFS_IOLOCK_EXCL | XFS_MMAPLOCK_EXCL);
 	return error;

-- 
2.43.0

