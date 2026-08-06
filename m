From: Daan De Meyer <daan@amutable.com>
Date: Thu, 06 Aug 2026 12:36:58 +0200
Subject: [PATCH 2/2] nbd: drop stale partitions on NBD_CLEAR_SOCK
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-b4-loop-nbd-stale-partitions-v1-2-67bb75a8d7be@amutable.com>
References: <20260806-b4-loop-nbd-stale-partitions-v1-0-67bb75a8d7be@amutable.com>
In-Reply-To: <20260806-b4-loop-nbd-stale-partitions-v1-0-67bb75a8d7be@amutable.com>
To: Jens Axboe <axboe@kernel.dk>, Christian Brauner <brauner@kernel.org>, 
 Daan De Meyer <daan.j.demeyer@gmail.com>, 
 Josef Bacik <josef@toxicpanda.com>
Cc: linux-block@vger.kernel.org, linux-kernel@vger.kernel.org, 
 nbd@other.debian.org, Daan De Meyer <daan@amutable.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786012634; l=2049;
 i=daan@amutable.com; s=20260712; h=from:subject:message-id;
 bh=aLcawfodzvP0fJXSj8HpdGNkZURTQ0aqxMLBOWMxTBU=;
 b=FM8lQ6abSH+zQI5Z+faOY250ag+68dCCs2+lZanTrB/pXeFbfrlYyr++1nnOotORedCbB25Wi
 BG8tcLAeyPCDuYpUajgzDzZn5VKM0QQp16W6N0V9jHiLc/A0lWx8wmU
X-Developer-Key: i=daan@amutable.com; a=ed25519;
 pk=I1l+WwrtmzRgofA5SQ1wTuJi18fjh91w+f5uRkFeZEA=
X-Endpoint-Received: by B4 Relay for daan@amutable.com/20260712 with auth_id=868
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 267ec4d7223a ("loop: fix partition scan race between udev and
loop_reread_partitions()") stopped disk_force_media_change() from
setting GD_NEED_PART_SCAN. Besides requesting a rescan, that bit was what
removed stale partitions on the next open, as bdev_disk_changed() drops
all partitions before it consults disk_has_partscan().

nbd_clear_sock_ioctl() relied on that. It zeroes the capacity through
nbd_bdev_reset(), but nothing removes the partitions of the disconnected
device anymore. With the default max_part=16 they linger until the next
connect sets GD_NEED_PART_SCAN again. With max_part=0 nothing ever sets
it, so they are never removed at all, even though nbd does not set
GENHD_FL_NO_PART and partitions can therefore still be added with BLKPG.

Set GD_NEED_PART_SCAN in nbd_clear_sock_ioctl() so the partitions are
dropped on the next open. Calling bdev_disk_changed() directly is not an
option as it needs open_mutex, which nbd_open() acquires under
config_lock.

Fixes: 267ec4d7223a ("loop: fix partition scan race between udev and loop_reread_partitions()")
Cc: stable@vger.kernel.org
Signed-off-by: Daan De Meyer <daan@amutable.com>
---
 drivers/block/nbd.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/block/nbd.c b/drivers/block/nbd.c
index 8f10762e90ef..cdafe9d39369 100644
--- a/drivers/block/nbd.c
+++ b/drivers/block/nbd.c
@@ -1612,6 +1612,13 @@ static void nbd_clear_sock_ioctl(struct nbd_device *nbd)
 	nbd_clear_sock(nbd);
 	disk_force_media_change(nbd->disk);
 	nbd_bdev_reset(nbd);
+	/*
+	 * Drop the partitions of the disconnected device on the next open. They
+	 * can exist even with max_part zero as they may have been added manually
+	 * with BLKPG. Dropping them here is not possible as that needs
+	 * open_mutex, which nbd_open() acquires under config_lock.
+	 */
+	set_bit(GD_NEED_PART_SCAN, &nbd->disk->state);
 	if (test_and_clear_bit(NBD_RT_HAS_CONFIG_REF,
 			       &nbd->config->runtime_flags))
 		nbd_config_put(nbd);

-- 
2.54.0

