From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 26 Nov 2026 10:45:47 +0900
Subject: [PATCH] xfs: punch delalloc blocks past EOF before mapping a pNFS
 layout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-xfs-pnfs-delalloc-eof-v1-1-509deb79a255@samsung.com>
X-B4-Tracking: v=1; b=H4sIAEqPB2sC/x2MywqAIBAAfyX23EIaGfQr0cHHWguioRCB+O9Jl
 4E5zFQolJkKbEOFTA8XTrGLGAewl44nIbvuICephJAKX1/wjh2Ogg4hWaTkcV3MLNWkyRoLvb0
 zeX7/73609gHZHh15ZwAAAA==
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, Dave Chinner <dgc@kernel.org>, 
 Christoph Hellwig <hch@lst.de>, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795657546; l=2347;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=V363AEekfhVNmNgFRwTSiV54vNvZ++lzcBIxwNKpDXM=;
 b=QfPaSk/iTM48NWJBRh6hlUOsMSA7R7UxCc8uUT+wcBjKEdN/6+kBRYDn5lz2DaJurf7YbBVY6
 0Rr+HhvA0+RBKhDcl7dLR0L0elHdE2IOn9l4rs4OZDH7AByGXEsCbco
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Writeback on fragmented free space can leave speculative
preallocation past EOF as delalloc. A LAYOUTGET over it BUG()s on
XFS_DEBUG kernels. Other kernels warn in nfsd and refuse the layout.
A LAYOUTCOMMIT past it moves EOF over it. Inode reclaim then asserts.

Punch it after the flush. Delalloc past EOF holds no data.

Fixes: 527851124d10 ("xfs: implement pNFS export operations")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested with pynfs on XFS_DEBUG, with free space fragmented as in
xfs/538 and the bmap_alloc_minlen_extent error tag set. LAYOUTGETs over
the 512 KiB left delalloc no longer assert. Neither does eviction after
a LAYOUTCOMMIT past it. The pynfs block tests and fstests over pNFS
show no change (BLOCK3, generic/075, 112 and 127 fail either way).

xfs_bmap_punch_delalloc_range() takes the same arguments in the 6.18.y
and 7.3.y stable trees. Older trees need them adjusted (5.10.y and
5.15.y take a start block and a length).
---
 fs/xfs/xfs_pnfs.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index 945f7a3e11c..4a6c1a399d7 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -11,6 +11,7 @@
 #include "xfs_inode.h"
 #include "xfs_trans.h"
 #include "xfs_bmap.h"
+#include "xfs_bmap_util.h"
 #include "xfs_iomap.h"
 #include "xfs_pnfs.h"
 #include <linux/exportfs_block.h>
@@ -192,6 +193,18 @@ xfs_fs_map_blocks(
 	if (WARN_ON_ONCE(error))
 		goto out_unlock;
 
+	/*
+	 * Writeback stops allocating a delalloc extent once the page it writes
+	 * is covered, so speculative preallocation past EOF can stay delalloc.
+	 * Delalloc past EOF never holds data. Punch all of it, as
+	 * xfs_free_eofblocks() does for preallocated files, so that a layout
+	 * never maps it and a LAYOUTCOMMIT never moves EOF over it.
+	 */
+	if (ip->i_delayed_blks)
+		xfs_bmap_punch_delalloc_range(ip, XFS_DATA_FORK,
+				round_up(XFS_ISIZE(ip), mp->m_sb.sb_blocksize),
+				LLONG_MAX, NULL);
+
 	end_fsb = XFS_B_TO_FSB(mp, (xfs_ufsize_t)offset + length);
 	offset_fsb = XFS_B_TO_FSBT(mp, offset);
 

---
base-commit: 5e7b6fe39324913f6416c854c6ed3a1793aaba8e
change-id: 20261126-xfs-pnfs-delalloc-eof-75b3260aecbc

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

