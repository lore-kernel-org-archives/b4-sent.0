From: Daan De Meyer <daan@amutable.com>
Subject: [PATCH v4 0/2] loop, nbd: drop partitions left behind by the
 GD_NEED_PART_SCAN removal
Date: Fri, 23 Oct 2026 09:47:19 +0200
Message-Id: <20261023-b4-loop-nbd-stale-partitions-v4-0-2baf05e4b2cb@amutable.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43O3UrEMBAF4FdZcu1Ikm2brFe+h3gxk4w20jYly
 RZl6bubrCAiwnp55ufjXETmFDiLh8NFJN5CDnGpobs7CDfi8soQfM1CSz1IKwegDqYYV1jIQy4
 4MayYSij1L4P2SrJno1CjqMSa+CW8X/mn56+cz/TGrjSzXRBmBkq4uLGNZsyFU1uMIZeYPq7FN
 tWAf3bYFEgYDJHp0XpD/IjzuSBNfO/iLFqNTf/wdHfD09U7WdVjb4xj8n94x29PSa1veMfqGdd
 bdkjDydlf3r7vn03m/y+WAQAA
X-Change-ID: 20260806-b4-loop-nbd-stale-partitions-2d10ede71a2a
To: Jens Axboe <axboe@kernel.dk>, Christian Brauner <brauner@kernel.org>, 
 Josef Bacik <josef@toxicpanda.com>, 
 Daan De Meyer <daan.j.demeyer@gmail.com>
Cc: linux-block@vger.kernel.org, linux-kernel@vger.kernel.org, 
 nbd@other.debian.org, Christoph Hellwig <hch@infradead.org>, 
 Bart Van Assche <bvanassche@acm.org>, 
 Shin'ichiro Kawasaki <shinichiro.kawasaki@wdc.com>, 
 Daan De Meyer <daan@amutable.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792741645; l=3132;
 i=daan@amutable.com; s=20260712; h=from:subject:message-id;
 bh=sPPVu4iJxaWGfV0YTWn1NFDKocSxyPtXFqSoQBma8cc=;
 b=elUCr89cUZfXi8D6aSlTVsOaNwDS65768Mgli2yNSip8k00EIDuICkF6/MRocaQmhOIJGo4CH
 7HhRU1dU0S4DnCB/4zMWeAbY8BbFVNvuajQki/T0pSqJbnEi3evA2eU
X-Developer-Key: i=daan@amutable.com; a=ed25519;
 pk=I1l+WwrtmzRgofA5SQ1wTuJi18fjh91w+f5uRkFeZEA=
X-Endpoint-Received: by B4 Relay for daan@amutable.com/20260712 with auth_id=868
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 267ec4d7223a ("loop: fix partition scan race between udev and
loop_reread_partitions()") stopped disk_force_media_change() from setting
GD_NEED_PART_SCAN. The caller audit in that commit only considered the bit
as a request to rescan partitions, but it did more than that:
bdev_disk_changed() drops every entry in disk->part_tbl before it consults
disk_has_partscan(), and only the re-adding half is gated on partition
scanning being enabled. The lazy scan on the next open was therefore also
the only thing removing partitions from a device that has partitions but
no partition scanning.

Loop devices without LO_FLAGS_PARTSCAN are exactly such devices, and they
are not unusual. bdev_add_partition() only rejects GENHD_FL_NO_PART disks,
so BLKPG_ADD_PARTITION works while GD_SUPPRESS_PART_SCAN is set, and
parted, libfdisk and systemd all fall back to BLKPG when BLKRRPART fails
with -EINVAL, which is what a loop device without LO_FLAGS_PARTSCAN
returns.

Commit c4f4c0fc551c ("loop: remove manually added partitions on detach")
fixed the detach path after this was reported as loop devices picking up
partition devices from a previously built image:

  https://bugs.debian.org/1141434

These two patches fix the two remaining places that relied on the same
lazy cleanup, LOOP_CHANGE_FD and NBD_CLEAR_SOCK.

Regression tests for both paths have been submitted to blktests:

  https://github.com/linux-blktests/blktests/pull/259
  https://github.com/linux-blktests/blktests/pull/260

Signed-off-by: Daan De Meyer <daan@amutable.com>
---
Changes in v4:
- nbd: Fix the lock order described in the comment and commit message.
  nbd_open() takes config_lock under open_mutex, not the other way
  around.
- No functional change, so the review and test tags from v3 were carried
  over.
- Link to v3: https://patch.msgid.link/20261022-b4-loop-nbd-stale-partitions-v3-0-7c58ecab69c8@amutable.com

Changes in v3:
- Rebase onto current mainline.
- No functional changes.
- Link to v2: https://patch.msgid.link/20260824-b4-loop-nbd-stale-partitions-v2-0-9815a577cebd@amutable.com

Changes in v2:
- Rewrap the comments added by both patches so they fit in 80 columns
  (Christoph Hellwig).
- No functional change, so the review and test tags from v1 were carried
  over.
- Link to v1: https://patch.msgid.link/20260806-b4-loop-nbd-stale-partitions-v1-0-67bb75a8d7be@amutable.com

To: Jens Axboe <axboe@kernel.dk>
To: Daan De Meyer <daan.j.demeyer@gmail.com>
To: Christian Brauner <brauner@kernel.org>
To: Josef Bacik <josef@toxicpanda.com>
Cc: linux-block@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: nbd@other.debian.org

---
Daan De Meyer (2):
      loop: drop stale partitions on LOOP_CHANGE_FD
      nbd: drop stale partitions on NBD_CLEAR_SOCK

 drivers/block/loop.c | 10 ++++++----
 drivers/block/nbd.c  |  9 +++++++++
 2 files changed, 15 insertions(+), 4 deletions(-)
---
base-commit: 7be4bc52fd9e0e55dc9a2e0232b89427d2c4b614
change-id: 20260806-b4-loop-nbd-stale-partitions-2d10ede71a2a

Best regards,
--  
Daan De Meyer <daan@amutable.com>

