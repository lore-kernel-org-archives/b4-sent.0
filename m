From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 26 Nov 2026 10:52:25 +0900
Subject: [PATCH v2 1/2] xfs: factor the mapping of one pNFS extent out of
 xfs_fs_map_blocks()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-xfs-nfsd-map-blocks-v2-1-6d85b1388739@samsung.com>
References: <20261126-xfs-nfsd-map-blocks-v2-0-6d85b1388739@samsung.com>
In-Reply-To: <20261126-xfs-nfsd-map-blocks-v2-0-6d85b1388739@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795657944; l=6438;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=LbAnNAneOGzHgP5YEL5LZU8hkVcZI2YdvmZ1qH3H1no=;
 b=fBQ5f75Kco5k8yOS0YcINvvUfjxQyYlVTcUXHnd38mo0nX1bX2Vn8K7UQZ7Zm94MifUu4AkMp
 nl3ccCSYuNXCl3GtNNBd9y2d7AKR48nauQpBX43Hf793XcNmQaS2jBr
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the part of xfs_fs_map_blocks() that maps one extent of a pNFS
layout into a new helper, xfs_fs_map_extent(). The helper also
allocates the extent first if it is a hole in a write layout. The next
patch calls it once for each extent of a layout.

No change in behavior.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/xfs/xfs_pnfs.c | 137 +++++++++++++++++++++++++++++++-----------------------
 1 file changed, 80 insertions(+), 57 deletions(-)

diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index 4a6c1a399d7..39d1c5271a7 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -122,6 +122,74 @@ xfs_fs_map_update_inode(
 	return xfs_log_force_inode(ip, false, NULL);
 }
 
+/*
+ * Map the extent of a pNFS layout that starts at @offset_fsb, allocating it
+ * first if it is a hole in a write layout, and set *@update_inode if it
+ * allocated. The mapping may end before or after @end. Called with the iolock
+ * and the invalidate lock held.
+ */
+static int
+xfs_fs_map_extent(
+	struct xfs_inode	*ip,
+	xfs_fileoff_t		offset_fsb,
+	loff_t			end,
+	bool			write,
+	struct xfs_bmbt_irec	*imap,
+	u64			*seq,
+	bool			*update_inode)
+{
+	struct xfs_mount	*mp = ip->i_mount;
+	xfs_fileoff_t		end_fsb = XFS_B_TO_FSB(mp, (xfs_ufsize_t)end);
+	int			nimaps = 1;
+	uint			lock_flags;
+	int			error;
+
+	lock_flags = xfs_ilock_data_map_shared(ip);
+	/*
+	 * Map to the end of the extent that covers the start of the range,
+	 * so that a client doing I/O in pieces gets a layout it can use for
+	 * the pieces that follow.  Never map anything before the start of
+	 * the range: nfsd calls in here once per extent of a LAYOUTGET, for
+	 * the range that is left after the previous extent, and the mapping
+	 * can change in between, so a mapping that reaches back can overlap
+	 * one already in the layout.  Don't extend the mapping past EOF
+	 * beyond the range either: xfs_free_eofblocks() can free blocks past
+	 * EOF without breaking the layout.
+	 */
+	error = xfs_bmapi_read(ip, offset_fsb, end_fsb - offset_fsb,
+				imap, &nimaps, XFS_BMAPI_ENTIRE);
+	if (error) {
+		xfs_iunlock(ip, lock_flags);
+		return error;
+	}
+	if (nimaps)
+		xfs_trim_extent(imap, offset_fsb,
+				max_t(xfs_fileoff_t, end_fsb,
+				      XFS_B_TO_FSB(mp, XFS_ISIZE(ip))) -
+				offset_fsb);
+	*seq = xfs_iomap_inode_sequence(ip, 0);
+
+	ASSERT(!nimaps || imap->br_startblock != DELAYSTARTBLOCK);
+
+	if (!write || (nimaps && imap->br_startblock != HOLESTARTBLOCK)) {
+		xfs_iunlock(ip, lock_flags);
+		return 0;
+	}
+
+	if (end > XFS_ISIZE(ip))
+		end_fsb = xfs_iomap_eof_align_last_fsb(ip, end_fsb);
+	else if (nimaps)
+		end_fsb = min(end_fsb, imap->br_startoff + imap->br_blockcount);
+	xfs_iunlock(ip, lock_flags);
+
+	error = xfs_iomap_write_direct(ip, offset_fsb, end_fsb - offset_fsb, 0,
+			imap, seq);
+	if (error)
+		return error;
+	*update_inode = true;
+	return 0;
+}
+
 /*
  * Get a layout for the pNFS client.
  */
@@ -137,10 +205,7 @@ xfs_fs_map_blocks(
 	struct xfs_inode	*ip = XFS_I(inode);
 	struct xfs_mount	*mp = ip->i_mount;
 	struct xfs_bmbt_irec	imap;
-	xfs_fileoff_t		offset_fsb, end_fsb;
 	loff_t			limit;
-	int			nimaps = 1;
-	uint			lock_flags;
 	int			error = 0;
 	u64			seq;
 	bool			update_inode = false;
@@ -205,64 +270,22 @@ xfs_fs_map_blocks(
 				round_up(XFS_ISIZE(ip), mp->m_sb.sb_blocksize),
 				LLONG_MAX, NULL);
 
-	end_fsb = XFS_B_TO_FSB(mp, (xfs_ufsize_t)offset + length);
-	offset_fsb = XFS_B_TO_FSBT(mp, offset);
+	error = xfs_fs_map_extent(ip, XFS_B_TO_FSBT(mp, offset),
+			offset + length, write, &imap, &seq, &update_inode);
+	if (error)
+		goto out_unlock;
 
-	lock_flags = xfs_ilock_data_map_shared(ip);
 	/*
-	 * Map to the end of the extent that covers the start of the range,
-	 * so that a client doing I/O in pieces gets a layout it can use for
-	 * the pieces that follow.  Never map anything before the start of
-	 * the range: nfsd calls in here once per extent of a LAYOUTGET, for
-	 * the range that is left after the previous extent, and the mapping
-	 * can change in between, so a mapping that reaches back can overlap
-	 * one already in the layout.  Don't extend the mapping past EOF
-	 * beyond the range either: xfs_free_eofblocks() can free blocks past
-	 * EOF without breaking the layout.
+	 * Blocks past EOF that were allocated for buffered writes, such as
+	 * speculative preallocation, can be freed by xfs_free_eofblocks()
+	 * without breaking the layout unless the inode is marked as
+	 * preallocated. Mark it before handing them out for writing, as for
+	 * blocks allocated above.
 	 */
-	error = xfs_bmapi_read(ip, offset_fsb, end_fsb - offset_fsb,
-				&imap, &nimaps, XFS_BMAPI_ENTIRE);
-	if (error) {
-		xfs_iunlock(ip, lock_flags);
-		goto out_unlock;
-	}
-	if (nimaps)
-		xfs_trim_extent(&imap, offset_fsb,
-				max_t(xfs_fileoff_t, end_fsb,
-				      XFS_B_TO_FSB(mp, XFS_ISIZE(ip))) -
-				offset_fsb);
-	seq = xfs_iomap_inode_sequence(ip, 0);
-
-	ASSERT(!nimaps || imap.br_startblock != DELAYSTARTBLOCK);
-
-	if (write && (!nimaps || imap.br_startblock == HOLESTARTBLOCK)) {
-		if (offset + length > XFS_ISIZE(ip))
-			end_fsb = xfs_iomap_eof_align_last_fsb(ip, end_fsb);
-		else if (nimaps && imap.br_startblock == HOLESTARTBLOCK)
-			end_fsb = min(end_fsb, imap.br_startoff +
-					       imap.br_blockcount);
-		xfs_iunlock(ip, lock_flags);
-
-		error = xfs_iomap_write_direct(ip, offset_fsb,
-				end_fsb - offset_fsb, 0, &imap, &seq);
-		if (error)
-			goto out_unlock;
+	if (write && !(ip->i_diflags & XFS_DIFLAG_PREALLOC) &&
+	    imap.br_startoff + imap.br_blockcount >
+	    XFS_B_TO_FSB(mp, XFS_ISIZE(ip)))
 		update_inode = true;
-	} else {
-		xfs_iunlock(ip, lock_flags);
-
-		/*
-		 * Blocks past EOF that were allocated for buffered writes, such
-		 * as speculative preallocation, can be freed by
-		 * xfs_free_eofblocks() without breaking the layout unless the
-		 * inode is marked as preallocated. Mark it before handing them
-		 * out for writing, as for blocks allocated above.
-		 */
-		if (write && !(ip->i_diflags & XFS_DIFLAG_PREALLOC) &&
-		    imap.br_startoff + imap.br_blockcount >
-		    XFS_B_TO_FSB(mp, XFS_ISIZE(ip)))
-			update_inode = true;
-	}
 
 	if (update_inode) {
 		error = xfs_fs_map_update_inode(ip);

-- 
2.43.0

