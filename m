From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 29 Oct 2026 11:23:04 +0900
Subject: [PATCH v5 7/9] xfs: take the invalidate lock while mapping a pNFS
 layout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-xfs-pnfs-batch-v5-7-ef8d2eafb7fa@samsung.com>
References: <20261029-xfs-pnfs-batch-v5-0-ef8d2eafb7fa@samsung.com>
In-Reply-To: <20261029-xfs-pnfs-batch-v5-0-ef8d2eafb7fa@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, "Darrick J. Wong" <djwong@kernel.org>, 
 Dave Chinner <dgc@kernel.org>, Pankaj Raghav <p.raghav@samsung.com>, 
 Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Sergey Bashirov <sergeybashirov@gmail.com>, 
 Andrey Albershteyn <aalbersh@kernel.org>, linux-nfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793240577; l=1836;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=gBm+GQlIRCxEZO4KRoZl7CtxJsRVQymJZ83QN8nYo/0=;
 b=OtSKVXuoqsSukbkvXukaNN64ALis31zly7lzkWf1eVkX7HOpBXOASUDgUl0wwSl1L0igFvXeB
 hqq5fhp1dXMAsBwe308OWiwdFxl0K24FIZt1j6j3mn7qgW+Sw1jLFFW
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_fs_map_blocks() flushes the page cache under the iolock, but a
write fault takes only the invalidate lock. A fault on a shared mapping
can then add a delalloc extent before the range is mapped. That trips
an ASSERT, or nfsd warns and refuses the layout.

Take the invalidate lock with the iolock, as __xfs_file_fallocate()
does. Not for stable: pNFS already leaves local writers to shared
mappings unsynchronized.

Suggested-by: Darrick J. Wong <djwong@kernel.org>
Link: https://lore.kernel.org/r/20260519145949.GH9555@frogsfrogsfrogs
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
Reviewed-by: Christoph Hellwig <hch@lst.de>
---
 fs/xfs/xfs_pnfs.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/fs/xfs/xfs_pnfs.c b/fs/xfs/xfs_pnfs.c
index 7153e7a1e1..c1a6409f00 100644
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
@@ -251,13 +254,13 @@ xfs_fs_map_blocks(
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

