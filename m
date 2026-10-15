From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 15 Oct 2026 13:08:06 +0900
Subject: [PATCH v3 7/9] xfs: take the invalidate lock while mapping a pNFS
 layout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-xfs-pnfs-batch-v3-7-54fc7b2e467d@samsung.com>
References: <20261015-xfs-pnfs-batch-v3-0-54fc7b2e467d@samsung.com>
In-Reply-To: <20261015-xfs-pnfs-batch-v3-0-54fc7b2e467d@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Dai Ngo <Dai.Ngo@oracle.com>, 
 Sergey Bashirov <sergeybashirov@gmail.com>, 
 Andrey Albershteyn <aalbersh@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792037279; l=2310;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=Y4pj8g534AU8Fw0hQevx0icUrGeA3TFnaiTLae8Dzlc=;
 b=mKegVXQlLtC4uQGjv6FqhI2dMP4jLVun5IlFw/GEsIpfExYWsFuqkyrwqzxHECAGejDKJfgNo
 XkA3iXcrUQSADuQVz3d78+/CsoteVG8P55RBF1ILN9Hb2XhF3wDWCwv
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_fs_map_blocks() flushes and invalidates the page cache of the file
under the iolock and then maps the range, but a write fault takes only
the invalidate lock (XFS_MMAPLOCK_SHARED in __xfs_write_fault()), not
the iolock. A fault on a shared mapping of the file can therefore add a
delalloc extent to the range between the flush and the mapping, which
trips the ASSERT on DELAYSTARTBLOCK, or is handed to nfsd, which warns
about a filesystem that returned a delalloc extent and refuses the
layout.

Take the invalidate lock in exclusive mode together with the iolock, as
__xfs_file_fallocate() does, so that page faults wait until the layout
has been mapped.

Not marked for stable: the race needs a process on the server that
writes to a shared mapping of the file while a client gets a layout for
the same range, and the comment above xfs_break_leased_layouts() already
leaves such writers unsynchronized with pNFS clients.

Suggested-by: Darrick J. Wong <djwong@kernel.org>
Link: https://lore.kernel.org/r/20260519145949.GH9555@frogsfrogsfrogs
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/xfs/xfs_pnfs.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index 9a578a2d02..3d97b29b54 100644
--- a/fs/xfs/xfs_pnfs.c
+++ b/fs/xfs/xfs_pnfs.c
@@ -168,8 +168,11 @@ xfs_fs_map_blocks(
 	 * similar to direct I/O, except that the synchronization is much more
 	 * complicated.  See the comment near xfs_break_leased_layouts
 	 * for a detailed explanation.
+	 *
+	 * Take the invalidate lock as well, so that page faults cannot add
+	 * delalloc extents to the range while it is being mapped.
 	 */
-	xfs_ilock(ip, XFS_IOLOCK_EXCL);
+	xfs_ilock(ip, XFS_IOLOCK_EXCL | XFS_MMAPLOCK_EXCL);
 
 	error = -EINVAL;
 	limit = mp->m_super->s_maxbytes;
@@ -252,13 +255,13 @@ xfs_fs_map_blocks(
 		if (error)
 			goto out_unlock;
 	}
-	xfs_iunlock(ip, XFS_IOLOCK_EXCL);
+	xfs_iunlock(ip, XFS_IOLOCK_EXCL | XFS_MMAPLOCK_EXCL);
 
 	error = xfs_bmbt_to_iomap(ip, iomap, &imap, 0, 0, seq);
 	*device_generation = mp->m_generation;
 	return error;
 out_unlock:
-	xfs_iunlock(ip, XFS_IOLOCK_EXCL);
+	xfs_iunlock(ip, XFS_IOLOCK_EXCL | XFS_MMAPLOCK_EXCL);
 	return error;
 }
 

-- 
2.43.0

