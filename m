From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 08 Oct 2026 10:39:37 +0900
Subject: [PATCH 8/8] nfsd: get all extents of a block layout in one
 ->map_blocks call
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-xfs-nfsd-map-blocks-v1-8-560026cdccb6@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791423569; l=9338;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=/MwS2SK4X2+xmp7sF7HJdcpW7r0rc3YDZufktlkfIR0=;
 b=CiK/fKJjDabu5DKUGb7ak1EUKpsW2bUw5xAfLrHQrA/1nXo20pigWZVY+Wt6r4hhre2vS+2pO
 IslYFISOxRXBvyVsvq1qcImhI4VeMYtwa5Lmw5p/tO0HNPES/DpOe+C
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nfsd4_block_proc_layoutget() calls ->map_blocks once per extent, each
time for the range left after the extent before, and trims each extent
so that it starts where the one before it ended, as the mapping can
change between the calls.

Ask for all extents in one call, which ->map_blocks now allows, so that
the filesystem maps them together. The array of mappings is bounded by
the same loga_maxcount limit as the layout. Instead of trimming, check
that the first extent contains the offset asked for and that each one
after it starts where the one before it ends, and warn and answer
NFS4ERR_LAYOUTUNAVAILABLE if not, as nfsd already does for a first
extent that does not contain the offset: with the whole range mapped
under one lock, a mapping that does not fit is a filesystem bug, which
trimming would hide. nfsd also warns if the filesystem returns no
mapping, or more than it has room for. nfsd4_block_map_extent() becomes
nfsd4_block_iomap_to_extent(), which only converts a mapping, and the
device ID is set up once per layout instead of once per extent.

With XFS, a READ LAYOUTGET for the first 256 KiB of a file in which 32
blocks of 4 KiB are each followed by a 4 KiB hole calls ->map_blocks
once instead of 64 times, gets the same 64 extents, and
nfsd4_block_proc_layoutget() takes 9 us instead of 26 us (median of 20
LAYOUTGETs each; QEMU VMs, XFS on an NVMe/TCP namespace, pynfs as the
client, time from a kprobe, KASAN and lockdep off). A READ LAYOUTGET for
NFS4_UINT64_MAX bytes, which got NFS4ERR_INVAL when nfsd asked again
from the maximum file size on, now gets a layout to 2^63. An RW
LAYOUTGET with a loga_minlength of zero, which nfsd refuses once it
meets an unwritten extent, now has all holes in its range allocated
before it is refused, instead of only the first one; the Linux client
asks for at least one page.

pynfs BLOCK1, BLOCK2, BLOCK4 and BLOCK5 pass as before (five runs
before, three after, with KASAN and lockdep). On a test kernel whose XFS
does not trim a mapping to the offset asked for, BLOCK5 gets
NFS4ERR_LAYOUTUNAVAILABLE and nfsd warns that the filesystem "returned
extent 0+12288 for offset 8192", where nfsd used to trim that extent
instead. fstests generic/075, 091 and 263 over the block and the SCSI
layout give the same results as before: 075 fails with the fsx size
error that it also gets without this series, and bl_alloc_lseg() on the
client returns no error.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/blocklayout.c | 136 ++++++++++++++++++++++++++------------------------
 1 file changed, 70 insertions(+), 66 deletions(-)

diff --git a/fs/nfsd/blocklayout.c b/fs/nfsd/blocklayout.c
index cedaf0e15d..e5e0a43ade 100644
--- a/fs/nfsd/blocklayout.c
+++ b/fs/nfsd/blocklayout.c
@@ -20,43 +20,19 @@
 
 
 /*
- * Get an extent from the file system that contains offset. It may start
- * below offset and may be shorter than the requested length.
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
-	unsigned int nr_iomaps = 1;
-	u32 device_generation = 0;
-	int error;
-
-	error = sb->s_export_op->block_ops->map_blocks(inode, offset, length,
-			&iomap, &nr_iomaps, iomode != IOMODE_READ,
-			&device_generation);
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
@@ -69,7 +45,7 @@ nfsd4_block_map_extent(struct inode *inode, const struct svc_fh *fhp,
 			}
 
 			bex->es = PNFS_BLOCK_INVALID_DATA;
-			bex->soff = iomap.addr;
+			bex->soff = iomap->addr;
 			break;
 		}
 		fallthrough;
@@ -81,16 +57,12 @@ nfsd4_block_map_extent(struct inode *inode, const struct svc_fh *fhp,
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
 
@@ -99,11 +71,17 @@ nfsd4_block_proc_layoutget(struct svc_rqst *rqstp, struct inode *inode,
 		const struct svc_fh *fhp, struct nfsd4_layoutget *args)
 {
 	struct nfsd4_layout_seg *seg = &args->lg_seg;
+	struct super_block *sb = inode->i_sb;
 	struct pnfs_block_layout *bl;
 	struct pnfs_block_extent *first_bex, *last_bex;
+	struct nfsd4_deviceid vol_id;
+	struct iomap *iomaps = NULL;
 	u64 offset = seg->offset, length = seg->length;
 	u32 i, nr_extents_max, block_size = i_blocksize(inode);
+	u32 device_generation = 0;
+	unsigned int nr_iomaps;
 	__be32 nfserr;
+	int error;
 
 	if (locks_in_grace(SVC_NET(rqstp)))
 		return nfserr_grace;
@@ -146,42 +124,67 @@ nfsd4_block_proc_layoutget(struct svc_rqst *rqstp, struct inode *inode,
 		goto out_error;
 	bl->nr_extents = nr_extents_max;
 	args->lg_content = bl;
+	iomaps = kmalloc_array(nr_extents_max, sizeof(*iomaps), GFP_KERNEL);
+	if (!iomaps)
+		goto out_error;
 
-	for (i = 0; i < bl->nr_extents; i++) {
-		struct pnfs_block_extent *bex = bl->extents + i;
-		u64 bex_length;
+	/*
+	 * Get all extents in one call, so that the filesystem maps them
+	 * together and they fit.
+	 */
+	nr_iomaps = nr_extents_max;
+	error = sb->s_export_op->block_ops->map_blocks(inode, offset, length,
+			iomaps, &nr_iomaps, seg->iomode != IOMODE_READ,
+			&device_generation);
+	if (error) {
+		if (error == -ENXIO)
+			nfserr = nfserr_layoutunavailable;
+		else
+			nfserr = nfserrno(error);
+		goto out_error;
+	}
 
-		nfserr = nfsd4_block_map_extent(inode, fhp, offset, length,
-				seg->iomode, args->lg_minlength, bex);
-		if (nfserr != nfs_ok)
-			goto out_error;
+	nfserr = nfserr_layoutunavailable;
+	if (WARN_ONCE(!nr_iomaps || nr_iomaps > nr_extents_max,
+		      "pnfsd: %s ino %llu: filesystem returned %u extents for %u\n",
+		      sb->s_id, inode->i_ino, nr_iomaps, nr_extents_max))
+		goto out_error;
 
-		/*
-		 * Each extent after the first was mapped for the range that
-		 * starts where the previous extent ends, but the filesystem
-		 * may return a mapping that starts below that point. Trim
-		 * it, as RFC 5663 section 2.3.1 does not allow extents to
-		 * overlap. nfsd4_block_map_extent() made sure the mapping
-		 * contains offset. NONE_DATA extents have no volume offset.
-		 */
-		if (i > 0 && bex->foff < offset) {
-			u64 skip = offset - bex->foff;
+	error = nfsd4_set_deviceid(&vol_id, fhp, device_generation);
+	if (error) {
+		nfserr = nfserrno(error);
+		goto out_error;
+	}
 
-			bex->foff = offset;
-			bex->len -= skip;
-			if (bex->es != PNFS_BLOCK_NONE_DATA)
-				bex->soff += skip;
-		}
+	for (i = 0; i < nr_iomaps; i++) {
+		const struct iomap *iomap = iomaps + i;
+		struct pnfs_block_extent *bex = bl->extents + i;
 
-		bex_length = bex->len - (offset - bex->foff);
-		if (bex_length >= length) {
-			bl->nr_extents = i + 1;
-			break;
-		}
+		/*
+		 * The first extent contains the offset asked for, and each
+		 * extent after it starts where the one before it ends: RFC
+		 * 5663 section 2.3.1 requires the extents to be logically
+		 * contiguous.
+		 */
+		nfserr = nfserr_layoutunavailable;
+		if (WARN_ONCE(iomap->offset > offset ||
+			      offset - iomap->offset >= iomap->length ||
+			      (i > 0 && iomap->offset != offset),
+			      "pnfsd: %s ino %llu: filesystem returned extent %lld+%llu for offset %llu\n",
+			      sb->s_id, inode->i_ino, iomap->offset,
+			      iomap->length, offset))
+			goto out_error;
 
-		offset = bex->foff + bex->len;
-		length -= bex_length;
+		nfserr = nfsd4_block_iomap_to_extent(iomap, seg->iomode,
+				args->lg_minlength, bex);
+		if (nfserr != nfs_ok)
+			goto out_error;
+		bex->vol_id = vol_id;
+		offset = iomap->offset + iomap->length;
 	}
+	bl->nr_extents = nr_iomaps;
+	kfree(iomaps);
+	iomaps = NULL;
 
 	first_bex = bl->extents;
 	last_bex = bl->extents + bl->nr_extents - 1;
@@ -198,6 +201,7 @@ nfsd4_block_proc_layoutget(struct svc_rqst *rqstp, struct inode *inode,
 	return nfs_ok;
 
 out_error:
+	kfree(iomaps);
 	seg->length = 0;
 	return nfserr;
 }

-- 
2.43.0

