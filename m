From: Daan De Meyer <daan@amutable.com>
Date: Fri, 23 Oct 2026 09:47:21 +0200
Subject: [PATCH v4 2/2] nbd: drop stale partitions on NBD_CLEAR_SOCK
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-b4-loop-nbd-stale-partitions-v4-2-2baf05e4b2cb@amutable.com>
References: <20261023-b4-loop-nbd-stale-partitions-v4-0-2baf05e4b2cb@amutable.com>
In-Reply-To: <20261023-b4-loop-nbd-stale-partitions-v4-0-2baf05e4b2cb@amutable.com>
To: Jens Axboe <axboe@kernel.dk>, Christian Brauner <brauner@kernel.org>, 
 Josef Bacik <josef@toxicpanda.com>, 
 Daan De Meyer <daan.j.demeyer@gmail.com>
Cc: linux-block@vger.kernel.org, linux-kernel@vger.kernel.org, 
 nbd@other.debian.org, Christoph Hellwig <hch@infradead.org>, 
 Bart Van Assche <bvanassche@acm.org>, 
 Shin'ichiro Kawasaki <shinichiro.kawasaki@wdc.com>, 
 Daan De Meyer <daan@amutable.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792741645; l=2448;
 i=daan@amutable.com; s=20260712; h=from:subject:message-id;
 bh=Xsf7lw9CzriaYcZ7LSWs2dUmnLL/EkAep1GawGfe3ic=;
 b=Gk00yNSAxP0BGLLgZfO+zaDaxRJD3UmvXzA2USAiHH8ymQf38em9AeTOaEeJgTv7csveCg6OV
 S+Ui/WVp2pFB7LgAZP1DCBYHO4ZjfizxVy2yFlSfoOzrfWpY9IWgabW
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
option as it needs open_mutex. nbd_open() acquires config_lock under
open_mutex, and nbd_clear_sock_ioctl() runs with config_lock held.
Taking open_mutex in nbd_clear_sock_ioctl() would invert that lock order.

Fixes: 267ec4d7223a ("loop: fix partition scan race between udev and loop_reread_partitions()")
Cc: stable@vger.kernel.org
Reviewed-by: Christian Brauner (Amutable) <brauner@kernel.org>
Reviewed-by: Bart Van Assche <bvanassche@acm.org>
Tested-by: Shin'ichiro Kawasaki <shinichiro.kawasaki@wdc.com>
Signed-off-by: Daan De Meyer <daan@amutable.com>
---
 drivers/block/nbd.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/block/nbd.c b/drivers/block/nbd.c
index ffce519bf008..322dbd16dc93 100644
--- a/drivers/block/nbd.c
+++ b/drivers/block/nbd.c
@@ -1616,6 +1616,15 @@ static void nbd_clear_sock_ioctl(struct nbd_device *nbd)
 	nbd_clear_sock(nbd);
 	disk_force_media_change(nbd->disk);
 	nbd_bdev_reset(nbd);
+	/*
+	 * Drop the partitions of the disconnected device on the next open.
+	 * They can exist even with max_part zero as they may have been added
+	 * manually with BLKPG. Dropping them here would need open_mutex.
+	 * nbd_open() acquires config_lock under open_mutex, and we hold
+	 * config_lock here. Taking open_mutex here can deadlock against
+	 * nbd_open().
+	 */
+	set_bit(GD_NEED_PART_SCAN, &nbd->disk->state);
 	if (test_and_clear_bit(NBD_RT_HAS_CONFIG_REF,
 			       &nbd->config->runtime_flags))
 		nbd_config_put(nbd);

-- 
2.54.0

