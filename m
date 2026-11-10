From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 10 Nov 2026 09:38:17 +0900
Subject: [PATCH] xfs: wait for direct I/O before swapping extents
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-xfs-swapext-dio-wait-v1-1-b8ccc5d5ef3c@samsung.com>
X-B4-Tracking: v=1; b=H4sIAHhn8moC/x3MMQ6AIAxA0auYzjYBBhWvYhwQi3ZRQ42SEO4uc
 XzD/xmEIpPA2GSI9LDweVTotgG/u2Mj5LUajDKd1spiCoLyuovSjSuf+Dq+sVt6pbxxdtAENb0
 iBU7/dppL+QBEvDAdZgAAAA==
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Christoph Hellwig <hch@lst.de>, Dave Chinner <david@fromorbit.com>, 
 "Darrick J. Wong" <djwong@kernel.org>, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794271096; l=1421;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=grxFvx5J+h49fGNJIZy/14ToLYlTBOdKLe89d7TYHY4=;
 b=B51sfxA0+dz3DqeZ+HRW/V1/hxt+LhhEHxydxcXybSn6BwVKeZsYRYTVhyEbN1Z446A40ukcB
 M770yk8DukNC2y8v4PlXy9orTllGOoVeeB6+FsoewycphEKwIN6cB/8
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An AIO direct write drops the iolock before its bios complete.
XFS_IOC_SWAPEXT does not wait for it. The write can land in blocks that
the swap moved to the temporary file. Once xfs_fsr frees them, the
write corrupts whatever reuses them.

Wait for direct I/O first, as exchange-range does.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested with an AIO direct write held back by cgroup io.max. Before, the
write reached files that reused the freed blocks in 7 of 7 runs. After,
those files were intact. The new fstests case "xfs: test that swapext
waits for in-flight direct I/O" fails before and passes after. Running
fstests -g fsr shows no change.

Applies with or without "xfs: break layouts before swapping extents".
---
 fs/xfs/xfs_bmap_util.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/fs/xfs/xfs_bmap_util.c b/fs/xfs/xfs_bmap_util.c
index 865aec3ae5a..4d214708f9c 100644
--- a/fs/xfs/xfs_bmap_util.c
+++ b/fs/xfs/xfs_bmap_util.c
@@ -1257,6 +1257,7 @@ xfs_swap_extent_flush(
 {
 	int	error;
 
+	inode_dio_wait(VFS_I(ip));
 	error = filemap_write_and_wait(VFS_I(ip)->i_mapping);
 	if (error)
 		return error;

---
base-commit: 1e17fc56469d62d1c1ac45c137a2456d14456f1d
change-id: 20261109-xfs-swapext-dio-wait-6b700c2a981e

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

