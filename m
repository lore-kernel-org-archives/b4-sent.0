From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 08 Oct 2026 10:39:33 +0900
Subject: [PATCH 4/8] exportfs: let ->map_blocks return more than one
 mapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-xfs-nfsd-map-blocks-v1-4-560026cdccb6@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791423569; l=4360;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=yfEeM0fY6TrrzCqX9WsIEdqNGlJA7KCjilbR9ng1fjM=;
 b=IqbGK8tsz4w6qRNJuJo2CQXSRLh8yXS7EPv95ssdolp+VxRsrtI9l9b5qntTPSiRE8PIIF8bH
 +CfyMI2I20SCFb0UuSanFxyp9xP/GWaqgxiPxg8UDKQw5jCoZEaSoc+
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit cc6c40e09d7b ("NFSD/blocklayout: Support multiple extents
per LAYOUTGET"), nfsd calls ->map_blocks once per extent of a block
layout, each time for the range left after the extent before. In XFS,
each call locks the inode, flushes and invalidates its page cache, maps
one extent and unlocks the inode again, and the mapping of the file can
change between the calls. When XFS still mapped whole extents, that
gave layouts whose extents overlapped, see commit 36ca6f11424a ("xfs:
fix overlapping extents returned for pNFS LAYOUTGET"), and nfsd now
trims the start of each extent after the first ("nfsd: do not return
overlapping extents in a block layout").

Let ->map_blocks fill an array of mappings, so that a filesystem can map
the whole range of a layout in one go, under one lock, and make the
mappings fit together: the first one contains the offset asked for, and
each further one starts where the one before it ends. Document as well
that the offset and the length come from the client unchecked, and what
the array holds on error. Only the interface changes here: XFS fills one
mapping, and nfsd asks for one at a time.

Suggested-by: Darrick J. Wong <djwong@kernel.org>
Suggested-by: Christoph Hellwig <hch@lst.de>
Link: https://lore.kernel.org/r/20260519145949.GH9555@frogsfrogsfrogs
Link: https://lore.kernel.org/r/20261007131133.GB30647@lst.de
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/blocklayout.c          |  4 +++-
 fs/xfs/xfs_pnfs.c              |  6 ++++--
 include/linux/exportfs_block.h | 14 ++++++++++----
 3 files changed, 17 insertions(+), 7 deletions(-)

diff --git a/fs/nfsd/blocklayout.c b/fs/nfsd/blocklayout.c
index 1aabae0033..cedaf0e15d 100644
--- a/fs/nfsd/blocklayout.c
+++ b/fs/nfsd/blocklayout.c
@@ -30,11 +30,13 @@ nfsd4_block_map_extent(struct inode *inode, const struct svc_fh *fhp,
 {
 	struct super_block *sb = inode->i_sb;
 	struct iomap iomap;
+	unsigned int nr_iomaps = 1;
 	u32 device_generation = 0;
 	int error;
 
 	error = sb->s_export_op->block_ops->map_blocks(inode, offset, length,
-			&iomap, iomode != IOMODE_READ, &device_generation);
+			&iomap, &nr_iomaps, iomode != IOMODE_READ,
+			&device_generation);
 	if (error) {
 		if (error == -ENXIO)
 			return nfserr_layoutunavailable;
diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index 88d9c3c043..055e6fb299 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -121,7 +121,8 @@ xfs_fs_map_blocks(
 	struct inode		*inode,
 	loff_t			offset,
 	u64			length,
-	struct iomap		*iomap,
+	struct iomap		*iomaps,
+	unsigned int		*nr_iomaps,
 	bool			write,
 	u32			*device_generation)
 {
@@ -238,7 +239,8 @@ xfs_fs_map_blocks(
 	}
 	xfs_iunlock(ip, XFS_IOLOCK_EXCL);
 
-	error = xfs_bmbt_to_iomap(ip, iomap, &imap, 0, 0, seq);
+	error = xfs_bmbt_to_iomap(ip, iomaps, &imap, 0, 0, seq);
+	*nr_iomaps = 1;
 	*device_generation = mp->m_generation;
 	return error;
 out_unlock:
diff --git a/include/linux/exportfs_block.h b/include/linux/exportfs_block.h
index 21e61fc012..1d0b0abbd3 100644
--- a/include/linux/exportfs_block.h
+++ b/include/linux/exportfs_block.h
@@ -44,12 +44,18 @@ struct exportfs_block_ops {
 	/*
 	 * Map blocks for direct block access.
 	 * If @write is %true, also allocate the blocks for the range if needed.
-	 * The mapping returned must contain @offset. It may start before
-	 * @offset and may end before or after @offset + @len.
+	 * @offset and @len come from the client: @offset may be negative or at
+	 * or past the maximum file size, and @offset + @len may overflow.
+	 * Fill in at most *@nr_iomaps mappings, which is at least one, and on
+	 * success set *@nr_iomaps to the number filled in, at least one. On
+	 * error, the mappings and *@nr_iomaps are undefined. The first mapping
+	 * must contain @offset and may start before it. Each further mapping
+	 * must start where the one before it ends. The last one may end before
+	 * or after @offset + @len.
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

