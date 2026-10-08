From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 08 Oct 2026 10:39:31 +0900
Subject: [PATCH 2/8] xfs: refuse a direct allocation whose block
 reservation would wrap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-xfs-nfsd-map-blocks-v1-2-560026cdccb6@samsung.com>
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
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791423569; l=2365;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=TgcEzJiRm0kG/kpwtVJnUxNYpa17XFqyuVHzFMTWefc=;
 b=nXT2lMRKwomwin0Noo+Pg4rGnzfPT+T2Y7oHvm/DoqBqcmWCQJn3sAJBobXBULzhKPCsWc7IC
 1ljV0rHj6NLB5PZosP/0MaKg0Mk7evQ8dmue6dIXOkxL9K26h5rEITz
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_iomap_write_direct() maps one extent, but it reserves blocks for the
whole count it is given, in an unsigned int. A count of about 2^32
blocks or more wraps the reservation. If it wraps to a few blocks, the
allocation uses more blocks than the transaction reserved, and
xfs_trans_mod_sb() shuts the filesystem down. If it wraps to nearly 2^32
blocks, the allocation fails with -ENOSPC.

Direct I/O, DAX and buffered writes with an extent size hint never ask
for that much, as xfs_direct_write_iomap_begin() limits them to
1024 pages to keep the count below 32 bits. xfs_fs_map_blocks() has no
such limit: it asks for everything from the start of a hole to the end
of the range of a pNFS layout, which a client chooses, and an RW
LAYOUTGET at offset 0 of an empty file for 16 TiB does it.

Fail such a count with -ENOSPC before anything is reserved, also on a
filesystem with that much free space, as the transaction cannot take
it. A count that fits is reserved in full, as before, so a hole longer
than the free space still fails before it is allocated.

With pynfs as the client and a 32 GiB XFS, an RW LAYOUTGET at offset 0
of an empty file for 16 TiB shut the filesystem down: "Corruption of
in-memory data (0x8) detected at xfs_trans_mod_sb". With this patch it
gets NFS4ERR_NOSPC and nothing is allocated, as with 100 GiB, and one
for 16 GiB, which fits, is still granted, in three extents.

Fixes: 527851124d10 ("xfs: implement pNFS export operations")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/xfs/xfs_iomap.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/fs/xfs/xfs_iomap.c b/fs/xfs/xfs_iomap.c
index 7c6238fed6..1917e49166 100644
--- a/fs/xfs/xfs_iomap.c
+++ b/fs/xfs/xfs_iomap.c
@@ -287,6 +287,13 @@ xfs_iomap_write_direct(
 
 	resaligned = xfs_aligned_fsb_count(offset_fsb, count_fsb,
 					   xfs_get_extsz_hint(ip));
+	/*
+	 * The transaction takes the block reservation as an unsigned int.
+	 * Refuse a count that does not fit rather than reserve too little;
+	 * only a pNFS layout for a huge range asks for that much.
+	 */
+	if (resaligned > UINT_MAX - XFS_DIOSTRAT_SPACE_RES(mp, 0))
+		return -ENOSPC;
 	if (unlikely(XFS_IS_REALTIME_INODE(ip))) {
 		dblocks = XFS_DIOSTRAT_SPACE_RES(mp, 0);
 		rblocks = resaligned;

-- 
2.43.0

