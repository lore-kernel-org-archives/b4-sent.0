From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 26 Nov 2026 10:52:26 +0900
Subject: [PATCH v2 2/2] exportfs, xfs, nfsd: map a whole pNFS block layout
 in one ->map_blocks call
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-xfs-nfsd-map-blocks-v2-2-6d85b1388739@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795657944; l=14545;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=3mIptkgus8B8uDyWKD1+PQcXAn4sV2xVThBPvIOqiFU=;
 b=SFtju4fZSdCcbnvFQNul6zcG+rBkqUASlcbCbY1G0kQJ3ftQPGEKPES/u2RZ4adM8AlWJwNFs
 caobjpkcK4HD75L5q1lfEf3rXZAwViwsvx3QOu/jlxT1+wQFggB7gpW
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nfsd calls ->map_blocks once per extent of a block layout. Each call
takes the XFS locks, writes back the page cache and can force the log.
The mapping can change between the calls.

Let ->map_blocks fill an array. XFS fills it under one hold of the
iolock and the invalidate lock and forces the log at most once. It
stops at the maximum file size, where nfsd stopped. If a mapping fails,
the blocks allocated before it get neither the inode update nor the log
force. The LAYOUTGET fails.

The times are medians of LAYOUTGETs for 256 KiB, timed in
nfsd4_block_proc_layoutget() (QEMU, XFS on NVMe/TCP, pynfs, no KASAN or
lockdep). The gapped files have 32 blocks of 4 KiB written with
O_DIRECT, 8 KiB apart:

    READ, gapped:      64 calls -> 1, 6.7 -> 4.9 us
    RW, gapped:        32 log forces -> 1, 46.7 -> 1.8 ms
    READ, one extent:  1 call -> 1, no change (1.9 and 2.1 us)

Suggested-by: Darrick J. Wong <djwong@kernel.org>
Suggested-by: Christoph Hellwig <hch@lst.de>
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
The medians are over 60 LAYOUTGETs from three boots per kernel, and 160
from eight boots for one extent. The median of one boot for one extent
is 0.5 to 2.4 us over both kernels. pynfs block tests over the block
layout and fstests generic/075, 091 and 263 over the block and SCSI
layouts give the same results as without this series, with KASAN and
lockdep. With XFS_DEBUG, generic/013, 075, 091, 112, 127 and 263 run,
and 075, 112 and 127 fail with fsx errors as without this series.
---
 fs/nfsd/blocklayout.c          | 137 ++++++++++++++++++++++-------------------
 fs/xfs/xfs_pnfs.c              |  54 ++++++++++------
 include/linux/exportfs_block.h |  17 +++--
 3 files changed, 121 insertions(+), 87 deletions(-)

diff --git a/fs/nfsd/blocklayout.c b/fs/nfsd/blocklayout.c
index c8942191b5f..90ed1cacf00 100644
--- a/fs/nfsd/blocklayout.c
+++ b/fs/nfsd/blocklayout.c
@@ -20,48 +20,19 @@
 
 
 /*
- * Get an extent from the file system that contains offset. It may start
- * below offset and may end before or after offset + length.
+ * Turn a mapping from the filesystem into an extent of the layout.
  */
 static __be32
-nfsd4_block_map_extent(struct inode *inode, const struct svc_fh *fhp,
-		u64 offset, u64 length, u32 iomode, u64 minlength,
-		struct pnfs_block_extent *bex)
+nfsd4_block_iomap_to_extent(const struct iomap *iomap, u32 iomode,
+		u64 minlength, struct pnfs_block_extent *bex)
 {
-	struct super_block *sb = inode->i_sb;
-	struct iomap iomap;
-	u32 device_generation = 0;
-	bool write;
-	int error;
-
-	/*
-	 * An RW layout with a minlength of zero only gets extents that can
-	 * be returned as READ_WRITE_DATA (RFC 5663, section 2.3.1), so do
-	 * not have the filesystem allocate blocks that would be refused.
-	 */
-	write = iomode != IOMODE_READ && minlength != 0;
-	error = sb->s_export_op->block_ops->map_blocks(inode, offset, length,
-			&iomap, write, &device_generation);
-	if (error) {
-		if (error == -ENXIO)
-			return nfserr_layoutunavailable;
-		return nfserrno(error);
-	}
-
-	if (WARN_ONCE(iomap.offset > offset ||
-		      offset - iomap.offset >= iomap.length,
-		      "pnfsd: %s ino %llu: filesystem returned extent %lld+%llu for offset %llu\n",
-		      sb->s_id, inode->i_ino, iomap.offset, iomap.length,
-		      offset))
-		return nfserr_layoutunavailable;
-
-	switch (iomap.type) {
+	switch (iomap->type) {
 	case IOMAP_MAPPED:
 		if (iomode == IOMODE_READ)
 			bex->es = PNFS_BLOCK_READ_DATA;
 		else
 			bex->es = PNFS_BLOCK_READWRITE_DATA;
-		bex->soff = iomap.addr;
+		bex->soff = iomap->addr;
 		break;
 	case IOMAP_UNWRITTEN:
 		if (iomode & IOMODE_RW) {
@@ -74,7 +45,7 @@ nfsd4_block_map_extent(struct inode *inode, const struct svc_fh *fhp,
 			}
 
 			bex->es = PNFS_BLOCK_INVALID_DATA;
-			bex->soff = iomap.addr;
+			bex->soff = iomap->addr;
 			break;
 		}
 		fallthrough;
@@ -83,22 +54,18 @@ nfsd4_block_map_extent(struct inode *inode, const struct svc_fh *fhp,
 			bex->es = PNFS_BLOCK_NONE_DATA;
 			break;
 		}
-		/* Not allocated for a minlength of zero, see above. */
+		/* Not allocated for a minlength of zero, see the caller. */
 		if (minlength == 0)
 			return nfserr_layoutunavailable;
 		fallthrough;
 	case IOMAP_DELALLOC:
 	default:
-		WARN(1, "pnfsd: filesystem returned %d extent\n", iomap.type);
+		WARN(1, "pnfsd: filesystem returned %d extent\n", iomap->type);
 		return nfserr_layoutunavailable;
 	}
 
-	error = nfsd4_set_deviceid(&bex->vol_id, fhp, device_generation);
-	if (error)
-		return nfserrno(error);
-
-	bex->foff = iomap.offset;
-	bex->len = iomap.length;
+	bex->foff = iomap->offset;
+	bex->len = iomap->length;
 	return nfs_ok;
 }
 
@@ -111,7 +78,14 @@ nfsd4_block_proc_layoutget(struct svc_rqst *rqstp, struct inode *inode,
 	struct pnfs_block_extent *first_bex, *last_bex;
 	u64 offset = seg->offset, length = seg->length;
 	u32 i, nr_extents_max, block_size = i_blocksize(inode);
+	struct super_block *sb = inode->i_sb;
+	struct nfsd4_deviceid vol_id;
+	struct iomap *iomaps = NULL;
+	u32 device_generation = 0;
+	unsigned int nr_iomaps;
 	__be32 nfserr;
+	bool write;
+	int error;
 
 	if (locks_in_grace(SVC_NET(rqstp)))
 		return nfserr_grace;
@@ -154,23 +128,66 @@ nfsd4_block_proc_layoutget(struct svc_rqst *rqstp, struct inode *inode,
 		goto out_error;
 	bl->nr_extents = nr_extents_max;
 	args->lg_content = bl;
+	iomaps = kvmalloc_objs(*iomaps, nr_extents_max);
+	if (!iomaps)
+		goto out_error;
 
-	for (i = 0; i < bl->nr_extents; i++) {
+	/*
+	 * Get all extents in one call, so that the filesystem maps them in
+	 * one go and each one follows the one before it. An RW layout with a
+	 * minlength of zero only gets extents that can be returned as
+	 * READ_WRITE_DATA (RFC 5663, section 2.3.1), so do not have the
+	 * filesystem allocate blocks that would be refused.
+	 */
+	nr_iomaps = nr_extents_max;
+	write = seg->iomode != IOMODE_READ && args->lg_minlength != 0;
+	error = sb->s_export_op->block_ops->map_blocks(inode, offset, length,
+			iomaps, &nr_iomaps, write, &device_generation);
+	if (error) {
+		if (error == -ENXIO)
+			nfserr = nfserr_layoutunavailable;
+		else
+			nfserr = nfserrno(error);
+		goto out_error;
+	}
+
+	nfserr = nfserr_layoutunavailable;
+	if (WARN_ONCE(!nr_iomaps || nr_iomaps > nr_extents_max,
+		      "pnfsd: %s ino %llu: filesystem returned %u extents for %u\n",
+		      sb->s_id, inode->i_ino, nr_iomaps, nr_extents_max))
+		goto out_error;
+
+	error = nfsd4_set_deviceid(&vol_id, fhp, device_generation);
+	if (error) {
+		nfserr = nfserrno(error);
+		goto out_error;
+	}
+
+	for (i = 0; i < nr_iomaps; i++) {
+		const struct iomap *iomap = iomaps + i;
 		struct pnfs_block_extent *bex = bl->extents + i;
-		u64 bex_length;
 
-		nfserr = nfsd4_block_map_extent(inode, fhp, offset, length,
-				seg->iomode, args->lg_minlength, bex);
+		nfserr = nfserr_layoutunavailable;
+		if (WARN_ONCE(iomap->offset > offset ||
+			      offset - iomap->offset >= iomap->length,
+			      "pnfsd: %s ino %llu: filesystem returned extent %lld+%llu for offset %llu\n",
+			      sb->s_id, inode->i_ino, iomap->offset,
+			      iomap->length, offset))
+			goto out_error;
+
+		nfserr = nfsd4_block_iomap_to_extent(iomap, seg->iomode,
+				args->lg_minlength, bex);
 		if (nfserr != nfs_ok)
 			goto out_error;
+		bex->vol_id = vol_id;
 
 		/*
-		 * Each extent after the first was mapped for the range that
-		 * starts where the previous extent ends, but the filesystem
-		 * may return a mapping that starts below that point. Trim
-		 * it, as RFC 5663 section 2.3.1 does not allow extents to
-		 * overlap. nfsd4_block_map_extent() made sure the mapping
-		 * contains offset. NONE_DATA extents have no volume offset.
+		 * Each mapping after the first should start where the previous
+		 * extent ends, but the filesystem may return a mapping that
+		 * starts below that point. Trim it, as RFC 5663 section 2.3.1
+		 * does not allow extents to overlap. The check above made sure
+		 * the mapping contains offset. NONE_DATA extents have no volume
+		 * offset.
 		 */
 		if (i > 0 && bex->foff < offset) {
 			u64 skip = offset - bex->foff;
@@ -180,18 +197,11 @@ nfsd4_block_proc_layoutget(struct svc_rqst *rqstp, struct inode *inode,
 			if (bex->es != PNFS_BLOCK_NONE_DATA)
 				bex->soff += skip;
 		}
-
-		bex_length = bex->len - (offset - bex->foff);
-		/* There is nothing to map past the maximum file size. */
-		if (bex_length >= length ||
-		    bex->foff + bex->len >= inode->i_sb->s_maxbytes) {
-			bl->nr_extents = i + 1;
-			break;
-		}
-
 		offset = bex->foff + bex->len;
-		length -= bex_length;
 	}
+	bl->nr_extents = nr_iomaps;
+	kvfree(iomaps);
+	iomaps = NULL;
 
 	first_bex = bl->extents;
 	last_bex = bl->extents + bl->nr_extents - 1;
@@ -208,6 +218,7 @@ nfsd4_block_proc_layoutget(struct svc_rqst *rqstp, struct inode *inode,
 	return nfs_ok;
 
 out_error:
+	kvfree(iomaps);
 	seg->length = 0;
 	return nfserr;
 }
diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index 39d1c5271a7..93764071804 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -148,13 +148,13 @@ xfs_fs_map_extent(
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
+	 * the extent there can have merged with the one before it, by the
+	 * allocation of a hole for this layout or by the completion of a
+	 * direct write, and a mapping that reaches back would overlap the
+	 * previous one. Don't extend the mapping past EOF beyond the range
+	 * either: xfs_free_eofblocks() can free blocks past EOF without
+	 * breaking the layout.
 	 */
 	error = xfs_bmapi_read(ip, offset_fsb, end_fsb - offset_fsb,
 				imap, &nimaps, XFS_BMAPI_ENTIRE);
@@ -192,23 +192,29 @@ xfs_fs_map_extent(
 
 /*
  * Get a layout for the pNFS client.
+ *
+ * Map the range, or as much of it as fits into @iomaps, one extent after the
+ * other, each starting where the one before it ends. Holding the iolock and
+ * the invalidate lock across the loop keeps other I/O and page faults from
+ * starting in between.
  */
 static int
 xfs_fs_map_blocks(
 	struct inode		*inode,
 	loff_t			offset,
 	u64			length,
-	struct iomap		*iomap,
+	struct iomap		*iomaps,
+	unsigned int		*nr_iomaps,
 	bool			write,
 	u32			*device_generation)
 {
 	struct xfs_inode	*ip = XFS_I(inode);
 	struct xfs_mount	*mp = ip->i_mount;
-	struct xfs_bmbt_irec	imap;
-	loff_t			limit;
+	unsigned int		nr = 0;
 	int			error = 0;
-	u64			seq;
 	bool			update_inode = false;
+	xfs_fileoff_t		offset_fsb, end_fsb;
+	loff_t			limit;
 
 	if (xfs_is_shutdown(mp))
 		return -EIO;
@@ -270,10 +276,21 @@ xfs_fs_map_blocks(
 				round_up(XFS_ISIZE(ip), mp->m_sb.sb_blocksize),
 				LLONG_MAX, NULL);
 
-	error = xfs_fs_map_extent(ip, XFS_B_TO_FSBT(mp, offset),
-			offset + length, write, &imap, &seq, &update_inode);
-	if (error)
-		goto out_unlock;
+	offset_fsb = XFS_B_TO_FSBT(mp, offset);
+	end_fsb = XFS_B_TO_FSB(mp, (xfs_ufsize_t)offset + length);
+	while (nr < *nr_iomaps && offset_fsb < end_fsb) {
+		struct xfs_bmbt_irec	imap;
+		u64			seq;
+
+		error = xfs_fs_map_extent(ip, offset_fsb, offset + length,
+				write, &imap, &seq, &update_inode);
+		if (error)
+			goto out_unlock;
+		error = xfs_bmbt_to_iomap(ip, &iomaps[nr++], &imap, 0, 0, seq);
+		if (error)
+			goto out_unlock;
+		offset_fsb = imap.br_startoff + imap.br_blockcount;
+	}
 
 	/*
 	 * Blocks past EOF that were allocated for buffered writes, such as
@@ -283,8 +300,7 @@ xfs_fs_map_blocks(
 	 * blocks allocated above.
 	 */
 	if (write && !(ip->i_diflags & XFS_DIFLAG_PREALLOC) &&
-	    imap.br_startoff + imap.br_blockcount >
-	    XFS_B_TO_FSB(mp, XFS_ISIZE(ip)))
+	    offset_fsb > XFS_B_TO_FSB(mp, XFS_ISIZE(ip)))
 		update_inode = true;
 
 	if (update_inode) {
@@ -294,9 +310,9 @@ xfs_fs_map_blocks(
 	}
 	xfs_iunlock(ip, XFS_IOLOCK_EXCL | XFS_MMAPLOCK_EXCL);
 
-	error = xfs_bmbt_to_iomap(ip, iomap, &imap, 0, 0, seq);
+	*nr_iomaps = nr;
 	*device_generation = mp->m_generation;
-	return error;
+	return 0;
 out_unlock:
 	xfs_iunlock(ip, XFS_IOLOCK_EXCL | XFS_MMAPLOCK_EXCL);
 	return error;
diff --git a/include/linux/exportfs_block.h b/include/linux/exportfs_block.h
index 21e61fc0124..f85ce1a67e3 100644
--- a/include/linux/exportfs_block.h
+++ b/include/linux/exportfs_block.h
@@ -43,13 +43,20 @@ struct exportfs_block_ops {
 
 	/*
 	 * Map blocks for direct block access.
-	 * If @write is %true, also allocate the blocks for the range if needed.
-	 * The mapping returned must contain @offset. It may start before
-	 * @offset and may end before or after @offset + @len.
+	 * If @write is %true, allocate any hole in the range mapped, so that no
+	 * mapping is a hole. No mapping may be IOMAP_DELALLOC. @len and
+	 * *@nr_iomaps are at least one. Return no mapping that starts at or
+	 * past the maximum file size. @offset may be negative or past it, and
+	 * @offset + @len may lie past it or wrap. On success, fill in between
+	 * one and *@nr_iomaps mappings and set *@nr_iomaps to their number. On
+	 * error, the mappings and *@nr_iomaps are undefined. The first mapping
+	 * must contain @offset, and each further one the offset at which the
+	 * one before it ends. A mapping may start before that offset. Only the
+	 * last one may reach @offset + @len, and it may end before or after it.
 	 */
 	int (*map_blocks)(struct inode *inode, loff_t offset, u64 len,
-			struct iomap *iomap, bool write,
-			u32 *device_generation);
+			struct iomap *iomaps, unsigned int *nr_iomaps,
+			bool write, u32 *device_generation);
 
 	/*
 	 * Commit blocks previously handed out by ->map_blocks and written to by

-- 
2.43.0

