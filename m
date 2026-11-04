From: Mark Korenberg <socketpair@gmail.com>
Subject: [PATCH v2 0/2] btrfs: zoned: fix silent data loss from leaked
 active zone reservation
Date: Wed, 04 Nov 2026 23:00:18 +0500
Message-Id: <20261104-btrfs-zoned-active-zone-leak-v2-0-0cee2ef72171@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43NQQ6CMBCF4auQWTumrUTElfcwLEo7hYlATds0K
 uHuVk7g8nuL/60QKTBFuFYrBMoc2S8F6lCBGfUyELItBiXUWQrVYp+Ci/jxC1nUJnGmHTiRfmD
 fn2qtlW0v0kBJPAM5fu35e1c8ckw+vPe3LH/rn+EsUWDTNNYK6Vwr69swa56Oxs/Qbdv2BRtR3
 kfIAAAA
X-Change-ID: 20261029-btrfs-zoned-active-zone-leak-bb34aa2d981c
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>, 
 Naohiro Aota <naohiro.aota@wdc.com>
Cc: linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Johannes Thumshirn <johannes.thumshirn@wdc.com>, stable@vger.kernel.org, 
 Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793815218; l=6777;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=xSIK1HX5mQGo89AMMrRLlOySg0P+Nsrmd95DAFY59Lo=;
 b=emwMDsMWXPt6AOxgNdVxeiOFjEDbRGhbOc4MF8tqbjPKLwNWOWafh4qpVWQoMCt2ArDmJFv58
 1WgME60WkIRBBZifEREzfeMLF3h4dTKhB8RT0kUgkjG9iTn2ot9mnnE
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On zoned btrfs, buffered writeback can fail with -ENOSPC after a
balance on a device with plenty of free space, and the data is lost:

  BTRFS error (device ublkb0): cow_file_range failed, root=5 inode=...
    start=... len=16777216 cur_offset=... cur_alloc_size=0: -28

write() and close() succeed, cp and rsync exit with 0, and only the
first syncfs() returns -ENOSPC. In the original report (ublk zoned
device, 16 MiB zones, 7.2.11) a 3.7 GB git pack file copied with rsync
lost 37 ranges of 16 MiB. The code involved is the same in master and
in btrfs for-next. The v1 cover letter has the traces and more detail.

Cause
-----

1. btrfs_relocate_block_group() ignores -EAGAIN from
   btrfs_zone_finish(), which it gets for a metadata or system block
   group with tree blocks not written yet and for the data relocation
   block group. The block group is then removed with its zones still
   active, and its share of reserved_active_zones is never given back.
   On the reporter's machine the reservation was -3 before a remount,
   with four removed block groups still on zone_active_bgs.

2. With a negative reservation, btrfs_can_activate_zone() always
   reports a free active zone for data. When the active zones run out,
   the allocator neither finishes a block group nor waits for one: it
   allocates a chunk it cannot activate, and find_free_extent() returns
   -ENOSPC.

Patch 1 finishes the zones of the relocated block group before it is
removed; by then it is read-only and empty, and its tree blocks are
written. Patch 2 treats a negative reservation as zero for data, as
it can also be negative for a short time without the leak. Patch 1 has
to come first: patch 2 alone leaves no active zone for a new system
block group and runs into the deadlock under "Not fixed here".

Both are marked for stable 7.0 and later only, as
btrfs_relocate_chunk_finish() appeared in 7.0. I can send backports
for older stable trees if that is wanted.

Reproducer
----------

zoned null_blk, 16 MiB zones, 16 open zones, commit=300. Each forced
metadata+system balance after new chunks were allocated leaves one block
group behind; then several writers lose their data:

  mount -t configfs none /sys/kernel/config
  d=/sys/kernel/config/nullb/zdev; mkdir $d
  echo 4096 > $d/blocksize; echo 1 > $d/memory_backed; echo 1 > $d/zoned
  echo 16 > $d/zone_size; echo 8192 > $d/size; echo 16 > $d/zone_max_open
  echo 1 > $d/power
  mkfs.btrfs -f -O zoned -d single -m single /dev/zdev
  mount -o commit=300 /dev/zdev /mnt
  for r in 1 2 3 4 5 6; do
          dd if=/dev/urandom of=/mnt/pre$r bs=1M count=64
          btrfs balance start --force -m -s /mnt
  done
  for i in 1 2 3 4 5 6 7 8; do
          dd if=/dev/urandom of=/tmp/src$i bs=1M count=512
  done
  for i in 1 2 3 4 5 6 7 8; do cp /tmp/src$i /mnt/data$i & done; wait
  sync -f /mnt; sync -f /mnt
  echo 3 > /proc/sys/vm/drop_caches
  for i in 1 2 3 4 5 6 7 8; do cmp /tmp/src$i /mnt/data$i; done

"Zombies" are active metadata/system block groups in mountstats with a
write pointer but used, reserved and unusable all 0; the reservation is
3 minus the active metadata and system block groups.

                    zombies  reservation  cow_file_range  syncfs  files
                                          failures                differ
  for-next                3           -2           31625  fail x2    8/8
  for-next + series       0            1               0  0, 0       0/8
  patch 1 only (v1)       0            1               0  0, 0       0/8
  patch 2 only (v1)  deadlock in balance (see below)

for-next is df5b88a7914e; the last two rows are v1 on master.

Testing
-------

v2 on for-next in a virtme-ng VM with CONFIG_PROVE_LOCKING and zoned
null_blk, data checked on disk after dropping caches: buffered, small
file and O_DIRECT writers with 16 and 128 open zones, filling the
filesystem, and writers with balance in a loop (system, metadata and
full balance, 10 and 16 open zones): no errors, no data loss, no
deadlock. The transaction abort below hit 3 of the 7 runs with
balance, as it does on master, in the commit in relocate_block_group()
before the code changed here. v1 was also tested on master with a ublk
device as in the report: the pack file that came out corrupted on
master was intact with the patches.

Not fixed here
--------------

- Recursive ro_block_group_mutex: btrfs_inc_block_group_ro() ->
  reserve_chunk_space() -> btrfs_zoned_activate_one_bg(info, true) ->
  btrfs_zone_finish_one_bg() -> do_zone_finish() ->
  btrfs_inc_block_group_ro(). Balance and writeback hang on master when
  a system block group is relocated with no active zone left.
- "error while writing out transaction: -EAGAIN" from the commit in
  relocate_block_group() aborts the transaction during balance while
  writing.
- A failed REQ_OP_ZONE_FINISH in call_zone_finish(), and a stripe that
  cannot be activated after others were in btrfs_zone_activate(), leak
  the reservation as well.

I used an AI assistant (Claude) for the investigation, the reproducer
and drafting the patches and this mail; the result was reviewed and
tested as described above.

---
Changes in v2:
- Rebase onto btrfs for-next.
- Patch 1: finish the block group as fully written after waiting for
  extent buffer writeback, instead of do_zone_finish(bg, false), which
  takes it read-only again: for a system block group that can allocate
  a system chunk under ro_block_group_mutex and take it again. Clearing
  the data relocation flag by hand is not needed anymore.
- Patch 1: if finishing fails, warn and remove the block group as
  before, instead of returning the error and keeping an empty read-only
  block group (btrfs_relocate_sys_chunks() would BUG() on the error).
- Patch 2: say in the comments that tree-log block groups count too and
  that the reservation is per zone.
- Mark both patches for stable 7.0 and later only, see above.
- Tests redone with v2 on for-next.
- Shorter cover letter, the v1 one has the details.
- Link to v1: https://lore.kernel.org/r/20261029-btrfs-zoned-active-zone-leak-v1-0-777dd01ff914@gmail.com

---
Mark Korenberg (2):
      btrfs: zoned: finish the zones of a relocated block group
      btrfs: zoned: don't treat a negative zone reservation as free zones

 fs/btrfs/volumes.c |  1 +
 fs/btrfs/zoned.c   | 54 +++++++++++++++++++++++++++++++++++++++++++++++++-----
 fs/btrfs/zoned.h   |  9 ++++++++-
 3 files changed, 58 insertions(+), 6 deletions(-)
---
base-commit: df5b88a7914e18488908ddf13e14e31ab39f954c
change-id: 20261029-btrfs-zoned-active-zone-leak-bb34aa2d981c

Best regards,
-- 
Mark Korenberg <socketpair@gmail.com>

