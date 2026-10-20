From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 20 Oct 2026 12:08:47 +0900
Subject: [PATCH v4 4/9] xfs: clamp a pNFS LAYOUTCOMMIT extent before
 computing its end
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-xfs-pnfs-batch-v4-4-9230fa2ca4a4@samsung.com>
References: <20261020-xfs-pnfs-batch-v4-0-9230fa2ca4a4@samsung.com>
In-Reply-To: <20261020-xfs-pnfs-batch-v4-0-9230fa2ca4a4@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, 
 Andrey Albershteyn <aalbersh@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792465723; l=1903;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=nP9RMvT+2/zi+VUBuU+Zdw9BhC8rbBfOGbPtZzbzLCE=;
 b=PJJKeYHGKbDmd5zcaR1gtO5Pp/W5Fe9pqLdUmfq0kmgYCQxZZDjBjbd1WgYu+I3lyocdVAQTZ
 2AcR4w6j/lVC5UUEGO+HyLgfse/9n1wSeXaHAd55oQ3xrGDyH4AraQN
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_fs_commit_blocks() clamps the end of each committed extent to the
file size, but computes the end as offset + length first. A length
from the client can make that sum wrap around, and the loop then
passes the client's length, unclamped, to xfs_iomap_write_unwritten().
The range wraps there as well, and xfs_bmapi_write() maps nothing.
Before the previous two patches, that failed an assertion on XFS_DEBUG
kernels, which is a BUG with XFS_ASSERT_FATAL, and otherwise returned
-ENOSR, which nfsd warns about as a non-standard errno. With
XFS_BMAPI_CONVERT_ONLY, the LAYOUTCOMMIT fails with -EIO and converts
nothing, even when every block up to the size is allocated.

With pynfs as the client and an RW layout for the first 64 KiB of a
2 MiB sparse file, a LAYOUTCOMMIT of 2^64 - 4 KiB at 4 KiB got
NFS4ERR_IO, "nfsd: non-standard errno: -63" and a WARNING, or the
assertion on XFS_DEBUG. With the previous two patches, it gets
NFS4ERR_IO and the laid-out range stays unwritten.

Clamp the length to what is left below the size before adding it to
the offset. The extent then ends at the size, its allocated part is
converted, and the LAYOUTCOMMIT gets NFS4ERR_IO at the hole after it.

Fixes: 527851124d10 ("xfs: implement pNFS export operations")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
Reviewed-by: Christoph Hellwig <hch@lst.de>
---
 fs/xfs/xfs_pnfs.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index 7ff83274a5..19eb18e129 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -328,9 +328,7 @@ xfs_fs_commit_blocks(
 		if (start > size)
 			continue;
 
-		end = start + maps[i].length;
-		if (end > size)
-			end = size;
+		end = start + min_t(u64, maps[i].length, size - start);
 
 		length = end - start;
 		if (!length)

-- 
2.43.0

