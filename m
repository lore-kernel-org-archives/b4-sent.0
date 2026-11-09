From: Daejun Park <daejun7.park@samsung.com>
Date: Mon, 09 Nov 2026 17:26:56 +0900
Subject: [PATCH] xfs: break layouts before swapping extents
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-xfs-swapext-break-layout-v1-1-7f6f137d18bb@samsung.com>
X-B4-Tracking: v=1; b=H4sIAM+D8WoC/x3MQQ5EQBBA0atIrVWiOwiuIhbNVFEhSJcZPRF31
 7F8i/8vUPJCCk1ygaefqGxrhEkTGCa3joTyiQab2dKYrMbAinq6ncKBvSc34+L+2/fAqubB5lz
 0VDHEfPfEEt512933A+YM3WxqAAAA
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, Dave Chinner <david@fromorbit.com>, 
 "Darrick J. Wong" <djwong@kernel.org>, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794212815; l=2472;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=CaEz7uBoybLqkkBn52P/NyxwhKH05LuHzbS9Eqv03SQ=;
 b=VPEoMQhIVld/k5YkvBH0AmoaVyqS9gkXEFvSLrjzHvbtu6mNXWyDh3wo6FhDsy6jKs0aYJQya
 2BYjMR7naZFAAH8bvnhjLivZQ4J/AU5u8wSaXH7hsKTkYBawyIGnFaz
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

XFS_IOC_SWAPEXT does not break pNFS layouts. A client can keep writing
to blocks that the swap moved to the temporary file. xfs_fsr frees
those blocks when it closes that file. The writes then land in whatever
reuses them.

Lock with xfs_ilock2_io_mmap(), as the exchange-range ioctls do.

Fixes: 781355c6e5ae ("xfs: recall pNFS layouts on conflicting access")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
xfs_fsr uses SWAPEXT on kernels without XFS_IOC_COMMIT_RANGE, on
filesystems without exchange-range, and in all xfsprogs before 6.12.

When both files are DAX, xfs_ilock2_io_mmap() also breaks DAX layouts.
With two DAX files whose pages had been faulted in, SWAPEXT hit the
WARN_ON_ONCE in truncate_folio_batch_exceptionals() in 3 of 3 boots
before this patch and in 0 of 3 after it. A DAX file swapped with a
non-DAX file still hits it.

Tested with a pynfs client holding an RW block layout while the MDS ran
"xfs_io -c swapext". Before, the client's writes overwrote other files'
data and a directory block. After, the swap recalls the layout first.
The fstests fsr and swapext tests pass with and without the patch.
---
 fs/xfs/xfs_bmap_util.c | 10 ++++------
 1 file changed, 4 insertions(+), 6 deletions(-)

diff --git a/fs/xfs/xfs_bmap_util.c b/fs/xfs/xfs_bmap_util.c
index 865aec3ae5a..595b7ea3ac9 100644
--- a/fs/xfs/xfs_bmap_util.c
+++ b/fs/xfs/xfs_bmap_util.c
@@ -1554,9 +1554,9 @@ xfs_swap_extents(
 	 * page cache safely. Once we have done this we can take the ilocks and
 	 * do the rest of the checks.
 	 */
-	lock_two_nondirectories(VFS_I(ip), VFS_I(tip));
-	filemap_invalidate_lock_two(VFS_I(ip)->i_mapping,
-				    VFS_I(tip)->i_mapping);
+	error = xfs_ilock2_io_mmap(ip, tip);
+	if (error)
+		return error;
 
 	/* Verify that both files have the same format */
 	if ((VFS_I(ip)->i_mode & S_IFMT) != (VFS_I(tip)->i_mode & S_IFMT)) {
@@ -1762,9 +1762,7 @@ xfs_swap_extents(
 	xfs_iunlock(ip, XFS_ILOCK_EXCL);
 	xfs_iunlock(tip, XFS_ILOCK_EXCL);
 out_unlock:
-	filemap_invalidate_unlock_two(VFS_I(ip)->i_mapping,
-				      VFS_I(tip)->i_mapping);
-	unlock_two_nondirectories(VFS_I(ip), VFS_I(tip));
+	xfs_iunlock2_io_mmap(ip, tip);
 	return error;
 
 out_trans_cancel:

---
base-commit: 1e17fc56469d62d1c1ac45c137a2456d14456f1d
change-id: 20261109-xfs-swapext-break-layout-89fc24f5be8f

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

