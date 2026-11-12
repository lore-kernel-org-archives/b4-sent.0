From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 12 Nov 2026 09:41:56 +0900
Subject: [PATCH v2] xfs: check the disk address for hardware atomic writes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-xfs-hw-atomic-align-v2-1-c90394805e7b@samsung.com>
X-B4-Tracking: v=1; b=H4sIAFML9WoC/32NQQ6CMBBFr0Jm7RimEFBX3sOwKHWASaQ1HUQM4
 e5WDuDyveS/v4JyFFa4ZCtEnkUl+ATmkIEbrO8Z5Z4YTG4qIspx6RSHN9opjOLQPqT3mLNtq1N
 RlGVtIS2fkTtZ9uqtSTyITiF+9pOZfvZ/byYkNKYuW6rOrjB8VTvqy/dHF0Zotm37AlqwMIy4A
 AAA
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Pankaj Raghav <p.raghav@samsung.com>, 
 Pankaj Raghav <pankaj.raghav@linux.dev>, John Garry <john.garry@linux.dev>, 
 "Darrick J. Wong" <djwong@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 Dave Chinner <david@fromorbit.com>, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794444115; l=2519;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=/KQlHm9zqOvC9vqKeC5B3c3hAccfr9ecgZJuujouvUg=;
 b=+lSElbUv0ZC1/gr/jZ2ThAFPuMnQ1/1sWHgTm4Nzwg96uKMPQ4ue2HxEOB/GH1spDUmkZxtpU
 L3mz5mjt69BB+UtzwNCmLcdPj8VQv1FL3xfUyfwI1AGVPNhIxHWOnC4
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_bmap_hw_atomic_write_possible() checks the alignment of the encoded
br_startblock, not of the disk address. This was harmless while atomic
writes were capped at the greatest power-of-two factor of the group
size.

Commit ec8f62cc109a ("xfs: don't limit software atomic writes by the
group alignment") lifted that cap. The block layer can now fail a
misaligned write with -EINVAL, and XFS does not fall back to COW.
Unaligned AGs, such as those made by mkfs.xfs before 6.16, and rtgroups
made by any version can hit this.

Check the disk address instead.

Fixes: ec8f62cc109a ("xfs: don't limit software atomic writes by the group alignment")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
The bug needs a group size that is not a multiple of the device's
atomic write unit max. mkfs.xfs 6.16+ rounds agsize to a multiple
of it if the device reports one at mkfs time, but never rounds
rgsize. Before 6.16, a single device of 4 TB or more got an odd
agsize.

Tested on emulated NVMe with a 64 KiB atomic unit and boundary.
64 KiB atomic overwrites in AG 1-3 (mkfs.xfs 6.6.0 -d agsize=262142b)
and rtgroups 1-7 (xfsprogs 7ebfc20eb88e -r rgsize=65534b) failed with
EINVAL before and used COW after. fstests -g atomicwrites and xfs/838
(rt) give the same results before and after (generic/773 fails with
ENOSPC on both).

Changes in v2:
- Explain why the check was harmless before ec8f62cc109a and which
  filesystems are affected (Pankaj).
- Reword the comment: an fsbno is not always a linear disk address
  (Pankaj).
---
 fs/xfs/xfs_iomap.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/fs/xfs/xfs_iomap.c b/fs/xfs/xfs_iomap.c
index c3465204b8d..119ff8e4c95 100644
--- a/fs/xfs/xfs_iomap.c
+++ b/fs/xfs/xfs_iomap.c
@@ -848,8 +848,10 @@ xfs_bmap_hw_atomic_write_possible(
 	 * atomic writes are required to be naturally aligned for disk blocks,
 	 * which ensures that we adhere to block layer rules that we won't
 	 * straddle any boundary or violate write alignment requirement.
+	 * Check the disk address: an fsbno is not always a linear disk address.
 	 */
-	if (!IS_ALIGNED(imap->br_startblock, imap->br_blockcount))
+	if (!IS_ALIGNED(xfs_fsb_to_db(ip, imap->br_startblock),
+			XFS_FSB_TO_BB(mp, imap->br_blockcount)))
 		return false;
 
 	/*

---
base-commit: 48326a2382d80715475d10ce98734ac65d2d2150
change-id: 20261110-xfs-hw-atomic-align-0eab6833447a

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

