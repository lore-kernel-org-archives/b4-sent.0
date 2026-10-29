From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 29 Oct 2026 11:23:02 +0900
Subject: [PATCH v5 5/9] xfs: cap the block count of
 xfs_iomap_write_direct() at one extent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-xfs-pnfs-batch-v5-5-ef8d2eafb7fa@samsung.com>
References: <20261029-xfs-pnfs-batch-v5-0-ef8d2eafb7fa@samsung.com>
In-Reply-To: <20261029-xfs-pnfs-batch-v5-0-ef8d2eafb7fa@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Pankaj Raghav <p.raghav@samsung.com>, 
 Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Sergey Bashirov <sergeybashirov@gmail.com>, 
 Andrey Albershteyn <aalbersh@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793240577; l=1933;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=aeK9qMxGbPp1LcY6+3H1RkPMvPFHl7/38YF8dOmhwok=;
 b=kdvSoV3L5wg8zEipmWBoyAxFBf8dEDZ4H8D8OmXcBcSIkrBvMTp2gToF6073Uql6WTfjIBFQ6
 VvOrfnOc7KpD+9ftyAjEM7M3y1RtSqOC0O5sq8bE5knVl54Hd7Ut8/Y
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_iomap_write_direct() reserves blocks for the whole count in an
unsigned int. For a pNFS layout the client chooses that count, and an
RW LAYOUTGET for 16 TiB wraps the reservation and shuts XFS down.

xfs_bmapi_write() maps at most XFS_MAX_BMBT_EXTLEN blocks here, so cap
the count at that. nfsd asks again for the rest. The other callers get
the same mapping as before.

Suggested-by: Darrick J. Wong <djwong@kernel.org>
Link: https://lore.kernel.org/r/20261008154017.GO2705364@frogsfrogsfrogs
Suggested-by: Christoph Hellwig <hch@lst.de>
Link: https://lore.kernel.org/r/20261015060932.GD14035@lst.de
Suggested-by: Pankaj Raghav <p.raghav@samsung.com>
Link: https://lore.kernel.org/r/atoImJxtg70XcIjS@quentin
Fixes: 527851124d10 ("xfs: implement pNFS export operations")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested with pynfs on a 32 GiB XFS: the 16 TiB RW LAYOUTGET shut XFS
down before, and gets NFS4ERR_NOSPC after with XFS still running.
Like one for 100 GiB, which allocated nothing before, it now leaves
about 24 GiB allocated past EOF.
---
 fs/xfs/xfs_iomap.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/fs/xfs/xfs_iomap.c b/fs/xfs/xfs_iomap.c
index 99d48081c5..c3465204b8 100644
--- a/fs/xfs/xfs_iomap.c
+++ b/fs/xfs/xfs_iomap.c
@@ -285,6 +285,14 @@ xfs_iomap_write_direct(
 
 	ASSERT(count_fsb > 0);
 
+	/*
+	 * xfs_bmapi_write() maps at most XFS_MAX_BMBT_EXTLEN blocks in one
+	 * mapping, so don't reserve blocks for more. A pNFS layout range
+	 * comes from a client, and its block count may not even fit the
+	 * 32-bit reservation. The caller maps the rest with a later call.
+	 */
+	count_fsb = min_t(xfs_filblks_t, count_fsb, XFS_MAX_BMBT_EXTLEN);
+
 	resaligned = xfs_aligned_fsb_count(offset_fsb, count_fsb,
 					   xfs_get_extsz_hint(ip));
 	if (unlikely(XFS_IS_REALTIME_INODE(ip))) {

-- 
2.43.0

