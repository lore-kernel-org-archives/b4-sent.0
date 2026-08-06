From: Daan De Meyer <daan@amutable.com>
Date: Thu, 06 Aug 2026 12:36:57 +0200
Subject: [PATCH 1/2] loop: drop stale partitions on LOOP_CHANGE_FD
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-b4-loop-nbd-stale-partitions-v1-1-67bb75a8d7be@amutable.com>
References: <20260806-b4-loop-nbd-stale-partitions-v1-0-67bb75a8d7be@amutable.com>
In-Reply-To: <20260806-b4-loop-nbd-stale-partitions-v1-0-67bb75a8d7be@amutable.com>
To: Jens Axboe <axboe@kernel.dk>, Christian Brauner <brauner@kernel.org>, 
 Daan De Meyer <daan.j.demeyer@gmail.com>, 
 Josef Bacik <josef@toxicpanda.com>
Cc: linux-block@vger.kernel.org, linux-kernel@vger.kernel.org, 
 nbd@other.debian.org, Daan De Meyer <daan@amutable.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786012634; l=2677;
 i=daan@amutable.com; s=20260712; h=from:subject:message-id;
 bh=nhYTyeBI8f5wHwWSuPgM7TTwBqQ7seYwKGdg4H84Gys=;
 b=BuzSqhc/LWYbKLMaUbRZex0rks0uRY7YxKDwj/bN1ilWW8oNKAPgQN9SceX6GBbSrS6oBRUfh
 HEfJ20jrHvqAtYdzMUoTlvrdHw5OPPU+BN0p9IaJKlk1beJ6EN2ywyu
X-Developer-Key: i=daan@amutable.com; a=ed25519;
 pk=I1l+WwrtmzRgofA5SQ1wTuJi18fjh91w+f5uRkFeZEA=
X-Endpoint-Received: by B4 Relay for daan@amutable.com/20260712 with auth_id=868
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 267ec4d7223a ("loop: fix partition scan race between udev and
loop_reread_partitions()") stopped disk_force_media_change() from
setting GD_NEED_PART_SCAN. That bit did more than request a rescan:
bdev_disk_changed() drops every partition before it consults
disk_has_partscan(), so the lazy scan on the next open was also what
removed partitions from a loop device without LO_FLAGS_PARTSCAN.

Such devices are not unusual. bdev_add_partition() only rejects
GENHD_FL_NO_PART disks, so BLKPG_ADD_PARTITION works while
GD_SUPPRESS_PART_SCAN is set, and parted, libfdisk and systemd all fall
back to BLKPG when BLKRRPART fails with -EINVAL, which is what a loop
device without LO_FLAGS_PARTSCAN returns.

loop_change_fd() only rescans when LO_FLAGS_PARTSCAN is set, so those
partitions now survive the backing file swap and keep describing the old
file. The new backing file must have the same size, but its partition
table can be completely different, leaving the partition devices mapping
the wrong ranges.

Call loop_reread_partitions() unconditionally. Without LO_FLAGS_PARTSCAN,
blk_add_partitions() returns early, so this drops the stale partitions
without scanning the new backing file.

Fixes: 267ec4d7223a ("loop: fix partition scan race between udev and loop_reread_partitions()")
Cc: stable@vger.kernel.org
Signed-off-by: Daan De Meyer <daan@amutable.com>
---
 drivers/block/loop.c | 10 ++++++----
 1 file changed, 6 insertions(+), 4 deletions(-)

diff --git a/drivers/block/loop.c b/drivers/block/loop.c
index 1faecef33009..416a9c651f97 100644
--- a/drivers/block/loop.c
+++ b/drivers/block/loop.c
@@ -538,7 +538,6 @@ static int loop_change_fd(struct loop_device *lo, struct block_device *bdev,
 	struct file *old_file;
 	unsigned int memflags;
 	int error;
-	bool partscan;
 	bool is_loop;
 
 	if (!file)
@@ -592,7 +591,6 @@ static int loop_change_fd(struct loop_device *lo, struct block_device *bdev,
 	loop_assign_backing_file(lo, file);
 	loop_update_dio(lo);
 	blk_mq_unfreeze_queue(lo->lo_queue, memflags);
-	partscan = lo->lo_flags & LO_FLAGS_PARTSCAN;
 	loop_global_unlock(lo, is_loop);
 
 	/*
@@ -610,8 +608,12 @@ static int loop_change_fd(struct loop_device *lo, struct block_device *bdev,
 	 */
 	fput(old_file);
 	dev_set_uevent_suppress(disk_to_dev(lo->lo_disk), 0);
-	if (partscan)
-		loop_reread_partitions(lo);
+	/*
+	 * Rescan or, without LO_FLAGS_PARTSCAN, just drop the partitions of the
+	 * old backing file. They can exist without LO_FLAGS_PARTSCAN as they may
+	 * have been added manually with BLKPG.
+	 */
+	loop_reread_partitions(lo);
 
 	error = 0;
 done:

-- 
2.54.0

