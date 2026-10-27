From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 27 Oct 2026 16:08:49 -0400
Subject: [PATCH] fs: annotate data race in get_nr_inodes()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-kcsan-inode-v1-1-1ef0eb871f2c@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrDWpohJXEYtqB0NS0kEk4u6K5
 Vv8fwFjIGSokwsCHsS0+IgsTcCOxg8oyEWDkkpnUlVitmy8IL84FMaVWklduDLvIRZrwJ7O79a
 0v3nvJrTbu4D7fgBSSeuJbwAAAA==
X-Change-ID: 20261027-kcsan-inode-ad562064d53f
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793131729; l=1338;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=RilFwEuG5mfa59o4kBWEQvpFFOo3It83HXyNfvM2YrM=;
 b=Ti0XKvyXUR4c9cFr6dRTkQZpL8+CKuInzahtgyklAh0OzNzygLqhQf2XBwxBBk6byk6QhRx4Y
 k8raP+nEciCAs2J/zhHdg+HrqiMd7dtXchK4ZPvnP/wL8IW74E4NRX7
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

get_nr_inodes() sums the per-CPU inode counts without a lock, and the
result is only an estimate, so it's harmless if one of them changes
during the sum.  Wrap the reads in data_race() to mark this.

  [   11.857490] BUG: KCSAN: data-race in get_nr_inodes+0x9f/0xf0

  [   11.857568] race at unknown origin, with read to 0xff1100002b6281e8 of 8 bytes by task 106 on cpu 1:
  [   11.857621]  get_nr_inodes+0x9f/0xf0
  [   11.857675]  get_nr_dirty_inodes+0x1d/0x110
  [   11.857748]  writeback_inodes_sb+0x3d/0x60
  ...

  [   11.870052] value changed: 0x00000000000000b3 -> 0x00000000000000b5

Found with KCSAN while fuzzing under a deterministic hypervisor that's
currently under development.

Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 fs/inode.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/inode.c b/fs/inode.c
index 1cb6293b237a..ee4366264c36 100644
--- a/fs/inode.c
+++ b/fs/inode.c
@@ -79,7 +79,7 @@ static long get_nr_inodes(void)
 	int i;
 	long sum = 0;
 	for_each_possible_cpu(i)
-		sum += per_cpu(nr_inodes, i);
+		sum += data_race(per_cpu(nr_inodes, i));
 	return sum < 0 ? 0 : sum;
 }
 

---
base-commit: d135ab453a7400a34930bdda1ef4bdc8acfac80e
change-id: 20261027-kcsan-inode-ad562064d53f

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

