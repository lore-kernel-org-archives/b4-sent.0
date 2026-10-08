From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 08 Oct 2026 10:39:34 +0900
Subject: [PATCH 5/8] xfs: factor the mapping of one pNFS extent out of
 xfs_fs_map_blocks()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-xfs-nfsd-map-blocks-v1-5-560026cdccb6@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791423569; l=5618;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=Q+h4dpH0hz9/hODpZMj+iE/EhdMRoAazypl5IY5SQ0k=;
 b=mDDCk3/kr4U7LpaRU1OIKdGHVF4y4MONHtSi2H6uAYKOcgnNPvbeCrPYRDAEs5zJTRk80Arbe
 zfVPfv1NLMYCRYxer0/3vJONO4pwUqlRw4gO+lGkRYvBG5RqNs2kzVw
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the part of xfs_fs_map_blocks() that maps one extent, and allocates
it first if it is a hole in a write layout, into a new helper,
xfs_fs_map_extent(), so that the next patch can call it for each extent
of a layout. The inode update and the log force after an allocation stay
in xfs_fs_map_blocks().

No change in behavior.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/xfs/xfs_pnfs.c | 119 +++++++++++++++++++++++++++++++++---------------------
 1 file changed, 72 insertions(+), 47 deletions(-)

diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index 055e6fb299..81e1ae0351 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -113,6 +113,73 @@ xfs_fs_map_update_inode(
 	return xfs_trans_commit(tp);
 }
 
+/*
+ * Map the extent of a pNFS layout that starts at @offset_fsb, allocating it
+ * first if it is a hole in a write layout. The mapping may end before or
+ * after @end. Called with the iolock held.
+ */
+static int
+xfs_fs_map_extent(
+	struct xfs_inode	*ip,
+	xfs_fileoff_t		offset_fsb,
+	loff_t			end,
+	bool			write,
+	struct xfs_bmbt_irec	*imap,
+	u64			*seq,
+	bool			*allocated)
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
+	*allocated = true;
+	return 0;
+}
+
 /*
  * Get a layout for the pNFS client.
  */
@@ -129,10 +196,8 @@ xfs_fs_map_blocks(
 	struct xfs_inode	*ip = XFS_I(inode);
 	struct xfs_mount	*mp = ip->i_mount;
 	struct xfs_bmbt_irec	imap;
-	xfs_fileoff_t		offset_fsb, end_fsb;
+	bool			allocated = false;
 	loff_t			limit;
-	int			nimaps = 1;
-	uint			lock_flags;
 	int			error = 0;
 	u64			seq;
 
@@ -180,49 +245,12 @@ xfs_fs_map_blocks(
 	if (WARN_ON_ONCE(error))
 		goto out_unlock;
 
-	end_fsb = XFS_B_TO_FSB(mp, (xfs_ufsize_t)offset + length);
-	offset_fsb = XFS_B_TO_FSBT(mp, offset);
-
-	lock_flags = xfs_ilock_data_map_shared(ip);
-	/*
-	 * Map to the end of the extent that covers the start of the range,
-	 * so that a client doing I/O in pieces gets a layout it can use for
-	 * the pieces that follow.  Never map anything before the start of
-	 * the range: nfsd calls in here once per extent of a LAYOUTGET, for
-	 * the range that is left after the previous extent, and the mapping
-	 * can change in between, so a mapping that reaches back can overlap
-	 * one already in the layout.  Don't extend the mapping past EOF
-	 * beyond the range either: xfs_free_eofblocks() can free blocks past
-	 * EOF without breaking the layout.
-	 */
-	error = xfs_bmapi_read(ip, offset_fsb, end_fsb - offset_fsb,
-				&imap, &nimaps, XFS_BMAPI_ENTIRE);
-	if (error) {
-		xfs_iunlock(ip, lock_flags);
+	error = xfs_fs_map_extent(ip, XFS_B_TO_FSBT(mp, offset),
+			offset + length, write, &imap, &seq, &allocated);
+	if (error)
 		goto out_unlock;
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
 
+	if (allocated) {
 		/*
 		 * Ensure the next transaction is committed synchronously so
 		 * that the blocks allocated and handed out to the client are
@@ -233,9 +261,6 @@ xfs_fs_map_blocks(
 			error = xfs_log_force_inode(ip);
 		if (error)
 			goto out_unlock;
-
-	} else {
-		xfs_iunlock(ip, lock_flags);
 	}
 	xfs_iunlock(ip, XFS_IOLOCK_EXCL);
 

-- 
2.43.0

