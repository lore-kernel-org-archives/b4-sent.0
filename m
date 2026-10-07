From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 07 Oct 2026 11:03:01 +0900
Subject: [PATCH] nfsd: do not return overlapping extents in a block layout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261007-nfsd-block-trim-v1-1-53370f97047a@samsung.com>
X-B4-Tracking: v=1; b=H4sIAFSoxWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAwNz3by04hTdpJz85GzdkqLMXF0Lw0SzRIskAzOzZEsloK6CotS0zAq
 widGxtbUAuMRLE2EAAAA=
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>, 
 Christoph Hellwig <hch@lst.de>
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, 
 Carlos Maiolino <cem@kernel.org>, Amir Goldstein <amir73il@gmail.com>, 
 linux-nfs@vger.kernel.org, linux-xfs@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791338580; l=7304;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=PTWvDDTklhlJON/gBnvNuDfKr1JRGBy9zjg7M7ycusQ=;
 b=bd9AbsvWdqztTdLDTeJ5H75RS+OogtG4FtoNz1tSqEMQWbYQG0QjgmvOKrEWzQDr9PR8m5BgL
 I9DZTOxMGXJCC+OsyV+SqQpx1jxKlqDWIG14nErO5klBH6UpPyioNFM
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit cc6c40e09d7b ("NFSD/blocklayout: Support multiple extents
per LAYOUTGET"), nfsd4_block_proc_layoutget() calls ->map_blocks once
per extent of a LAYOUTGET, each time for the range left after the
previous extent. nfsd4_block_map_extent() takes a mapping that starts at
the offset asked for or below it, but only the first extent may start
below it. A later extent that starts below its offset overlaps the
extents before it, which RFC 5663 section 2.3.1 does not allow. The
Linux client rejects such a layout (verify_extent() returns -EIO), and
the I/O that needed it fails. The block and SCSI layouts share this
code.

XFS, the only ->map_blocks implementation, used to map the whole extent
that contains the offset. Together with one call per extent, that gave
overlapping layouts in v6.19 and v7.0: allocating the blocks for one
extent of a write layout could merge the extent that the next call
starts in with the unwritten extents before it. Since commit
36ca6f11424a ("xfs: fix overlapping extents returned for pNFS
LAYOUTGET"), XFS does not map below the offset, so this patch changes
nothing with current XFS. It only stops nfsd from relying on that: trim
each extent after the first so that it starts at the offset asked for,
and move its volume offset by the same amount unless it is a NONE_DATA
extent, which has none.

nfsd leaves the end of a mapping alone, as only the filesystem knows
where it should end. It does need a mapping that contains the offset
asked for, which RFC 5663 section 2.3.1 also requires of the first
extent. A mapping that does not would leave a gap in the layout or make
the length computed from it wrap around, so warn and return
NFS4ERR_LAYOUTUNAVAILABLE; the client then does the I/O through the
metadata server. iomap_iter_done() has the same check, as a
WARN_ON_ONCE(), for ->iomap_begin(), and nfsd4_block_map_extent()
already warns and fails this way for a mapping of an unexpected type.
Document in exportfs_block.h that the mapping must contain the offset.

On a test kernel whose xfs_fs_map_blocks() maps with XFS_BMAPI_ENTIRE
and does not trim, as XFS did before that commit, a write layout over a
hole between two unwritten blocks comes back as 0+4096, 4096+4096 and
0+12288, and the pynfs test BLOCK5 fails in five runs out of five.
fstests generic/075, 091 and 263 over the block layout fail with an EIO
or a zero-length O_DIRECT write, and bl_alloc_lseg() on the client
returns -EIO three times. With this patch on top, the third extent is
8192+4096, BLOCK5 passes in five runs out of five, generic/091 and 263
pass, generic/075 fails with the fsx "Size error" that it also fails
with on nfsd-testing, and bl_alloc_lseg() returns no error.

Suggested-by: Darrick J. Wong <djwong@kernel.org>
Link: https://lore.kernel.org/r/20261006051324.GV2705364@frogsfrogsfrogs
Link: https://lore.kernel.org/r/20261006152333.GO1615495@frogsfrogsfrogs
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Darrick asked whether nfsd should trim the lower end of a mapping that
starts below the offset asked for, or warn and fail. This patch trims
such a mapping for every extent but the first, and warns only when a
mapping does not contain the offset at all. The XFS patch his question
was about also trims, in xfs_fs_map_blocks(). The two patches do not
depend on each other:
https://lore.kernel.org/r/20261006003425epcms2p586728e55ff5f9bbabc506b672fc4a421@epcms2p5

No stable backport is needed, which is also why there is no Fixes: tag
for cc6c40e09d7b. Overlapping extents need both the per-extent calls of
cc6c40e09d7b (v6.19) and XFS_BMAPI_ENTIRE in xfs_fs_map_blocks(), which
36ca6f11424a removed in v7.1. Only 6.19.y and 7.0.y have both, and
neither is maintained any more; 6.18.y and older call ->map_blocks once
per LAYOUTGET.

Tested on nfsd-testing 56589cdb5881 with three QEMU VMs (an NVMe/TCP
target, the server with nfsd and XFS, and a client), over the block
layout only. With only this patch, nfsd-testing gives the same BLOCK5
and fstests results as without it. With KASAN and lockdep, the test
kernel with this patch on top gives the same BLOCK5 and fstests results
as above, with no warning. Trimming was seen only for the INVALID_DATA
extents of BLOCK5; nothing counted trims during the fstests runs. The
pynfs test BLOCK5 is at
https://lore.kernel.org/r/20261006002622epcms2p38e492aef17fdf79e48b05c9aada2918d@epcms2p3
---
 fs/nfsd/blocklayout.c          | 28 ++++++++++++++++++++++++++--
 include/linux/exportfs_block.h |  2 ++
 2 files changed, 28 insertions(+), 2 deletions(-)

diff --git a/fs/nfsd/blocklayout.c b/fs/nfsd/blocklayout.c
index df02cf746..1aabae003 100644
--- a/fs/nfsd/blocklayout.c
+++ b/fs/nfsd/blocklayout.c
@@ -20,8 +20,8 @@
 
 
 /*
- * Get an extent from the file system that starts at offset or below
- * and may be shorter than the requested length.
+ * Get an extent from the file system that contains offset. It may start
+ * below offset and may be shorter than the requested length.
  */
 static __be32
 nfsd4_block_map_extent(struct inode *inode, const struct svc_fh *fhp,
@@ -41,6 +41,13 @@ nfsd4_block_map_extent(struct inode *inode, const struct svc_fh *fhp,
 		return nfserrno(error);
 	}
 
+	if (WARN_ONCE(iomap.offset > offset ||
+		      offset - iomap.offset >= iomap.length,
+		      "pnfsd: %s ino %llu: filesystem returned extent %lld+%llu for offset %llu\n",
+		      sb->s_id, inode->i_ino, iomap.offset, iomap.length,
+		      offset))
+		return nfserr_layoutunavailable;
+
 	switch (iomap.type) {
 	case IOMAP_MAPPED:
 		if (iomode == IOMODE_READ)
@@ -147,6 +154,23 @@ nfsd4_block_proc_layoutget(struct svc_rqst *rqstp, struct inode *inode,
 		if (nfserr != nfs_ok)
 			goto out_error;
 
+		/*
+		 * Each extent after the first was mapped for the range that
+		 * starts where the previous extent ends, but the filesystem
+		 * may return a mapping that starts below that point. Trim
+		 * it, as RFC 5663 section 2.3.1 does not allow extents to
+		 * overlap. nfsd4_block_map_extent() made sure the mapping
+		 * contains offset. NONE_DATA extents have no volume offset.
+		 */
+		if (i > 0 && bex->foff < offset) {
+			u64 skip = offset - bex->foff;
+
+			bex->foff = offset;
+			bex->len -= skip;
+			if (bex->es != PNFS_BLOCK_NONE_DATA)
+				bex->soff += skip;
+		}
+
 		bex_length = bex->len - (offset - bex->foff);
 		if (bex_length >= length) {
 			bl->nr_extents = i + 1;
diff --git a/include/linux/exportfs_block.h b/include/linux/exportfs_block.h
index de519b7b5..21e61fc01 100644
--- a/include/linux/exportfs_block.h
+++ b/include/linux/exportfs_block.h
@@ -44,6 +44,8 @@ struct exportfs_block_ops {
 	/*
 	 * Map blocks for direct block access.
 	 * If @write is %true, also allocate the blocks for the range if needed.
+	 * The mapping returned must contain @offset. It may start before
+	 * @offset and may end before or after @offset + @len.
 	 */
 	int (*map_blocks)(struct inode *inode, loff_t offset, u64 len,
 			struct iomap *iomap, bool write,

---
base-commit: 56589cdb58819ce54decedbbfddf231d94b5ce41
change-id: 20261007-nfsd-block-trim-81a6a8b066c9

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

