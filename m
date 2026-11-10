From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 10 Nov 2026 17:00:57 +0900
Subject: [PATCH] xfs: check the disk address for hardware atomic writes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-xfs-hw-atomic-align-v1-1-2274b169c32e@samsung.com>
X-B4-Tracking: v=1; b=H4sIADjP8moC/x3MQQ5AMBBA0avIrE3S0iCuIhaDwSSUtEKTxt01l
 m/xfwTPTthDm0VwfIuXwyboPINxJbswypQMhSoqrbXCMHtcH6Tr2GVE2mSxqJiGqilLY2qCVJ6
 OZwn/tevf9wPrfuLTZQAAAA==
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: Pankaj Raghav <p.raghav@samsung.com>, 
 Pankaj Raghav <pankaj.raghav@linux.dev>, John Garry <john.garry@linux.dev>, 
 "Darrick J. Wong" <djwong@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 Dave Chinner <david@fromorbit.com>, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794297656; l=2023;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=F8iIbd6Eszp+I6y7W1YZ0heXUAQ4Tct/8s2wppk82FQ=;
 b=kS+BsKaUWKZesCUse7dkx23u/LG0MNFq7np4APEH+yrpLvythgqWsOXGgFYwtntkZPK591kGu
 v94W6w3YdiwDUe3qCVwGnLxZoPZwqBgp9MZY+WsfZJEXYYp08dsI/Op
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xfs_bmap_hw_atomic_write_possible() checks the alignment of the encoded
br_startblock, not of the disk address. The two can differ outside the
first group.

Since commit ec8f62cc109a ("xfs: don't limit software atomic writes by
the group alignment"), a misaligned write can reach the hardware path.
The block layer can fail it with -EINVAL, and XFS does not retry it
through the COW path.

Check the disk address instead.

Fixes: ec8f62cc109a ("xfs: don't limit software atomic writes by the group alignment")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Affects a group size that is not a multiple of the device's atomic
write unit max. mkfs.xfs 6.16+ rounds agsize to it, not rgsize.

Tested on emulated NVMe, 64 KiB atomic unit and boundary: 64 KiB
atomic overwrites in AG 1-3 (mkfs.xfs 6.6.0, agsize=262142b) and
rtgroups 1-7 (xfsprogs 7ebfc20eb88e, rgsize=65534b) failed with EINVAL
before and use COW after. fstests -g atomicwrites, xfs/838 (rt): no
change.
---
 fs/xfs/xfs_iomap.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/fs/xfs/xfs_iomap.c b/fs/xfs/xfs_iomap.c
index c3465204b8d..cfa2f7ac03a 100644
--- a/fs/xfs/xfs_iomap.c
+++ b/fs/xfs/xfs_iomap.c
@@ -848,8 +848,11 @@ xfs_bmap_hw_atomic_write_possible(
 	 * atomic writes are required to be naturally aligned for disk blocks,
 	 * which ensures that we adhere to block layer rules that we won't
 	 * straddle any boundary or violate write alignment requirement.
+	 * Check the disk address: br_startblock carries the group number in
+	 * its high bits, so it can be aligned when the disk address is not.
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

