From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 03 Jul 2025 02:59:11 +0300
Subject: [PATCH] bcachefs: Suppress unnecessary inode_i_sectors_wrong fsck
 error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250703-isectors-not-wrong-v1-1-37002be151e0@gmail.com>
X-B4-Tracking: v=1; b=H4sIAM7HZWgC/x3MPQqAMAxA4atIZgO14g9eRRxKTWuWVhJRQby7x
 fEb3ntASZgUpuoBoZOVcypo6gr85lIk5LUYrLGdGUyLrOSPLIopH3hJThFHGl1jex9aM0AJd6H
 A9z+dl/f9AN1vRPtkAAAA
X-Change-ID: 20250703-isectors-not-wrong-8e8a126cf307
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1208; i=himikof@gmail.com;
 h=from:subject:message-id; bh=2wcJM/AavbId1UzNMVMhmkxxIl8bglzMr8gbV3nXSjw=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWSkHv/veldg3gHD2C8hoV436lYaT/r0/lBo2yrHWR6Z6
 3Q/LrHb3lHKwiDGxSArpsjyYcnXP2syrf9YCu01hJnDygQyhIGLUwAmclOC4X+Zj9najUWHPt3P
 EXruNUHu7POZ82sPtmgWZ+/Zu12w/doURoZ5rZxfBNkm/Zsj4XvBKPtoya9SZtd/sXJcFmtsLPo
 Nq1gA
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It is possible that fsck first miscounted the expected sector count (due
to applying other fixes at the same time, for example) and then
corrected itself using extents. No need to log an fsck error and
write the inode in this case.

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/fsck.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/fs/bcachefs/fsck.c b/fs/bcachefs/fsck.c
index 1ceca63c87a3bf3eb75d396f7a10949c502b0e8d..471e93a3f00c637050b5c485d72b27cfb284282d 100644
--- a/fs/bcachefs/fsck.c
+++ b/fs/bcachefs/fsck.c
@@ -1638,7 +1638,8 @@ static int check_i_sectors_notnested(struct btree_trans *trans, struct inode_wal
 			i->count = count2;
 		}
 
-		if (fsck_err_on(!(i->inode.bi_flags & BCH_INODE_i_sectors_dirty),
+		if (fsck_err_on(!(i->inode.bi_flags & BCH_INODE_i_sectors_dirty) &&
+				i->inode.bi_sectors != i->count,
 				trans, inode_i_sectors_wrong,
 				"inode %llu:%u has incorrect i_sectors: got %llu, should be %llu",
 				w->last_pos.inode, i->inode.bi_snapshot,

---
base-commit: 14a12362bb22b3735c51ecdb712570a12992a695
change-id: 20250703-isectors-not-wrong-8e8a126cf307

Best regards,
-- 
Nikita Ofitserov

