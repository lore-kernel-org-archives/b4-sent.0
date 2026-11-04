From: Mark Korenberg <socketpair@gmail.com>
Subject: [PATCH 0/2] ublk: don't let one stuck device block control of all
 ublk devices
Date: Thu, 05 Nov 2026 00:25:04 +0500
Message-Id: <20261105-ublk-del-gendisk-hang-v1-0-913a91a4314d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvxJ7bkEtPfSV6JC51mJYKEUQ/T3rO
 DAzN2RKTBm66oZEJ2feYgFZVzAtY5wJ2RUGJZSRUrR42DWgoxVnio5zwM9Ca5vGa2OU9hpKuyf
 yfP3ffnieFzecOzVnAAAA
X-Change-ID: 20261104-ublk-del-gendisk-hang-bb33f56625f5
To: Ming Lei <tom.leiming@gmail.com>
Cc: Jens Axboe <axboe@kernel.dk>, linux-block@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ming Lei <ming.lei@redhat.com>, 
 Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793820305; l=3412;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=ed+++DV3HtIipUSehjA+fspJo3hIwQmkBnnMsoaxA5M=;
 b=IRpKMhVeG5cfku6a00obCR56pJkuAzujaK89yVgM4ezrw36H1p/L9VE5WEKVSQ7iEkUZVW/kf
 Ls89C11kNhtASBn32zNZiGKz3OIhRn7PTHGBmfXdZ8XEZPQNBsywi/o
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the filesystem on a ublk device is stuck, removing that device
blocks in del_gendisk(), which syncs the filesystem. DEL_DEV holds the
global ublk_ctl_mutex across the removal, so ADD_DEV and DEL_DEV of
every other ublk device hang too, until reboot. It doesn't matter
whether the server is alive: when it dies, the release work does the
same syncing del_gendisk() under ub->mutex, and DEL_DEV waits for
ub->mutex holding ublk_ctl_mutex.

I hit it with btrfs on a ublk zoned device whose writeback deadlocked
on its own (a btrfs bug, handled separately): killing the server as a
last resort didn't help, and no new ublk device could be created on the
machine afterwards.

Patch 2 removes the global part: DEL_DEV doesn't take ublk_ctl_mutex.
It relies on patch 1, which fixes an older race the mutex partly hid:
ADD_DEV makes a new device findable by its id before its char device is
added, and if adding it fails, a DEL_DEV that found the device removes
a char device that was never added. With a failure injected into
ublk_add_chdev() this oopses on master in kill_device() from
cdev_device_del(); with patch 1, DEL_DEV gets -ENODEV.

Reproducer, without btrfs or zoned: XFS (or ext4) on a ublk loop
device, its external log (journal) on dm-linear over null_blk:

  dmsetup suspend --nolockfs --noflush <log>
  write a file; syncfs                  # blocks, as expected
  kill -9 <ublk server>                 # optional
  DEL_DEV 0                             # directly, as libublk does
  ADD_DEV 1                             # null target
  dmsetup resume <log>                  # everything unwinds

           DEL_DEV 0                         ADD_DEV 1
  master   D, survives SIGKILL               hangs on ublk_ctl_mutex
  series   D, survives SIGKILL (see below)   ok

The stuck device itself still can't be stopped or deleted until its
filesystem moves: its STOP_DEV and DEL_DEV sleep uninterruptibly, in
del_gendisk() or on ub->mutex. When the server is gone, nothing can be
written anyway, so that removal should be a surprise one done without
ub->mutex, but marking the disk dead isn't enough (the filesystem's
->shutdown() and the writeback flush in bdi_unregister() can block the
same way), and doing the removal without ub->mutex races with the
release work, recovery and a new server attaching. I'll send that part
separately as an RFC.

Tested in a VM with lockdep on top of master c339f4010dea, XFS and ext4,
with and without the server killed; block for-next has no ublk_drv.c
changes on top of it. The ublk selftests give the same results with and
without the series (integrity_01/03 fail on both, no
CONFIG_BLK_DEV_INTEGRITY here); a stress of DEL_DEV racing ADD_DEV of
the same id shows no warnings, also with KASAN and KCSAN.

This series was developed with the help of an AI coding assistant
(Claude); I reviewed and tested the changes and take responsibility
for them.

---
Mark Korenberg (2):
      ublk: publish a new device by its id only once it is set up
      ublk: don't take ublk_ctl_mutex in DEL_DEV

 drivers/block/ublk_drv.c | 60 +++++++++++++++++++++++++++++-------------------
 1 file changed, 37 insertions(+), 23 deletions(-)
---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261104-ublk-del-gendisk-hang-bb33f56625f5

Best regards,
-- 
Mark Korenberg <socketpair@gmail.com>

