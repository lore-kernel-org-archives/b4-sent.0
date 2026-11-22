From: =?utf-8?q?Omar_Yi=C4=9Fitcan_Meng=C3=BC?= <menguomary@gmail.com>
Date: Sun, 22 Nov 2026 13:20:02 +0300
Subject: [PATCH] jfs: fix integer overflow in dbDiscardAG() and validate
 dn_agfree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261122-jfs-fix-dbdiscardag-overflow-v1-1-c3b3230242dc@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yXMwQrCMAwA0F8pOS9gg1Ttr4iHrk1mhqzSzDkY+
 3dRj+/yNjBuygbRbdB4UdM6QXS+c5DvaRoYtUB0QAcK3hPhKIaiK5a+qOXUShqwLtzkUd94PFO
 Q4BNd5ASdg2dj0fXXX29/26sfOc/fE/b9A5fMHyCAAAAA
X-Change-ID: 20261122-jfs-fix-dbdiscardag-overflow-4826f61a29f7
To: Dave Kleikamp <shaggy@kernel.org>
Cc: jfs-discussion@lists.sourceforge.net, 
 Christian Brauner <brauner@kernel.org>, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+29eda1328acf6cf2dbfb@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, 
 =?utf-8?q?Omar_Yi=C4=9Fitcan_Meng=C3=BC?= <menguomary@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795342801; l=2536;
 i=menguomary@gmail.com; s=20261121; h=from:subject:message-id;
 bh=hMHH4yTPBHZUdEF0MQBMA04GLD3DPYMcNION+cySEUY=;
 b=kFsqLNKFTA0bRSTpgK1ZizBPkY3/f3o5uFzQfSnERdVJVQeHu8RAQUcJumcVCIJDH3fcg7nxg
 EkbDzhuT90/B3FTj/M3cuwHSXd3FU+dqk0eFGzUfN9R6zORfLYpM7Um
X-Developer-Key: i=menguomary@gmail.com; a=ed25519;
 pk=dgRbAFBMBZdJfvBTw9RBcE3WxXn6Yt7GOZFPRpQqpkY=
X-Endpoint-Received: by B4 Relay for menguomary@gmail.com/20261121 with auth_id=1595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If a corrupted JFS image has a negative per-AG free block count such as
dn_agfree[agno] == -1, dbMount() currently accepts it without validation
and stores -1 in bmp->db_agfree[agno].

When FITRIM later calls dbDiscardAG() with minlen == 1, the signed s64
value nblocks = -1 is implicitly converted to u64 max_ranges = U64_MAX.
After do_div(max_ranges, minlen), max_ranges + 1 overflows u64 to 0,
causing range_cnt to be 0 and kmalloc_objs(struct range2trim, 0, ...)
to return ZERO_SIZE_PTR (0x10). Since totrim != NULL and the while loop
(nblocks >= minlen) is skipped, tt->nblocks = 0 dereferences 0x18 and
triggers a general protection fault.

Fix this in two places:
1. Validate bmp->db_agfree[i] >= 0 in dbMount() to reject corrupted
   on-disk metadata at mount time with -EINVAL.
2. Return early in dbDiscardAG() when nblocks < minlen, preventing any
   negative nblocks (for example from runtime corruption) from
   overflowing max_ranges + 1 and avoiding an unnecessary allocation
   when an AG has fewer than minlen free blocks.

Reported-by: syzbot+29eda1328acf6cf2dbfb@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=29eda1328acf6cf2dbfb
Fixes: b40c2e665cd5 ("fs/jfs: TRIM support for JFS Filesystem")
Cc: stable@vger.kernel.org
Signed-off-by: Omar Yiğitcan Mengü <menguomary@gmail.com>
---
 fs/jfs/jfs_dmap.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/fs/jfs/jfs_dmap.c b/fs/jfs/jfs_dmap.c
index a841cf21d..94542ed93 100644
--- a/fs/jfs/jfs_dmap.c
+++ b/fs/jfs/jfs_dmap.c
@@ -293,8 +293,13 @@ int dbMount(struct inode *ipbmap)
 		goto err_release_metapage;
 	}
 
-	for (i = 0; i < MAXAG; i++)
+	for (i = 0; i < MAXAG; i++) {
 		bmp->db_agfree[i] = le64_to_cpu(dbmp_le->dn_agfree[i]);
+		if (bmp->db_agfree[i] < 0) {
+			err = -EINVAL;
+			goto err_release_metapage;
+		}
+	}
 	bmp->db_agsize = le64_to_cpu(dbmp_le->dn_agsize);
 	bmp->db_maxfreebud = dbmp_le->dn_maxfreebud;
 
@@ -1677,6 +1682,10 @@ s64 dbDiscardAG(struct inode *ip, int agno, s64 minlen)
 	IWRITE_LOCK(ipbmap, RDWRLOCK_DMAP);
 
 	nblocks = bmp->db_agfree[agno];
+	if (nblocks < minlen) {
+		IWRITE_UNLOCK(ipbmap);
+		return 0;
+	}
 	max_ranges = nblocks;
 	do_div(max_ranges, minlen);
 	range_cnt = min_t(u64, max_ranges + 1, 32 * 1024);

---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261122-jfs-fix-dbdiscardag-overflow-4826f61a29f7

Best regards,
--  
Omar Yiğitcan Mengü <menguomary@gmail.com>

