From: Mark Korenberg <socketpair@gmail.com>
Subject: [PATCH 0/2] btrfs: zoned: fix silent data loss from leaked active
 zone reservation
Date: Thu, 29 Oct 2026 13:16:43 +0500
Message-Id: <20261029-btrfs-zoned-active-zone-leak-v1-0-777dd01ff914@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQ5AMBAAwK/Inm2iJYKviMO2XWxISSsixN81j
 nOZByIH4Qhd9kDgU6JsPkHlGdiZ/MQoLhl0oWtV6BbNEcaI9+bZIdlDTv6BK9OCxpQVkXZtoyy
 kYg88yvX3/fC+HxCOXHRuAAAA
X-Change-ID: 20261029-btrfs-zoned-active-zone-leak-bb34aa2d981c
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>, 
 Naohiro Aota <naohiro.aota@wdc.com>
Cc: linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793261811; l=8424;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=wHYWPALtrSPUdIYEayA4D8xOo2QJYw+fdvMJ1u+NcPk=;
 b=zT6ML6VF3iW1aQzH+i3Hbsn3F/rQQch1fFdoc8VjdILIGnV7gvtihz/ri1Tej5eZYPBl0EfxZ
 LEiaz0lp1wzCkYaHx9zJwbkPndVd1OQgxQULn6mBBLRZqdBUn2tqVtF
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On zoned btrfs, buffered writeback can fail with -ENOSPC on a device with
plenty of free space, and the data is lost without any error reaching the
writer:

  BTRFS error (device ublkb0): cow_file_range failed, root=5 inode=...
    start=... len=16777216 cur_offset=... cur_alloc_size=0: -28
  BTRFS error (device ublkb0): failed to run delalloc range, ...: -28

cow_file_range() ends the writeback of the range without writing it and
only sets an error on the mapping. write() and close() succeed, rsync and
cp exit with 0, the first syncfs() returns -ENOSPC and the second one 0.
The pages stay in the page cache, so reading the files back right away
does not necessarily show it. In the original report a 3.7 GB git pack
file copied with rsync lost 37 ranges of 16 MiB.

It was seen on a 100 GiB zoned device (ublk, 16 MiB zones, 128 open
zones, no active zone limit, single profiles, commit=300) on 7.2.11 while
copying a kernel tree onto a filesystem that had been filled, emptied and
balanced with -dusage=0 -musage=0 before. The code involved is the same
in current master.

Cause
-----

1. btrfs_relocate_block_group() finishes the zones of the block group
   before relocating it and ignores -EAGAIN. For a metadata or system
   block group with allocated but not yet written tree blocks
   (alloc_offset > meta_write_pointer) and for the data relocation block
   group, do_zone_finish() returns -EAGAIN. The block group is then
   relocated and removed with its zones still active: it stays on
   fs_info->zone_active_bgs, and reserved_active_zones is never given
   back. Caught with bpftrace on the reporter's machine:

     zone_finish failed ret=-11 bg 43419435008 flags 0x2
       alloc_offset 10420224 meta_written 10403840 used 16384 reserved 16384
       btrfs_relocate_block_group <- btrfs_relocate_chunk <- __btrfs_balance
     remove bg 43419435008 type 0x2 <- btrfs_remove_chunk

   reserved_active_zones went from 1 to 0 at that moment and stayed
   there. Before a remount the same filesystem had four such block
   groups (removed from the chunk tree, still listed as active in
   mountstats with used, reserved and unusable all 0) and, read from the
   kernel, max_active_zones 128, active_zones_left 117,
   reserved_active_zones -3.

2. reserved_active_zones is 3 (6 with DUP) minus the active metadata,
   tree-log and system zones, so it can be negative, legitimately too:
   it dropped by 3 for a few seconds during an rm -rf, independently of
   the leak.
   btrfs_can_activate_zone() checks active_zones_left >= 1 + reserved for
   data, which is always true with a negative reservation. So when the
   active zones run out, can_allocate_chunk_zoned() neither finishes a
   block group nor makes the caller wait: a chunk is allocated, its zone
   cannot be activated, and find_free_extent() returns -ENOSPC. On the
   reporter's machine btrfs_can_activate_zone() returned true 45 times,
   each followed by a failed allocation, and btrfs_zone_finish_one_bg()
   was never called.

Patch 1 finishes the zones again before the relocated block group is
removed: the block group is read-only and empty by then, and the commit
at the end of relocate_block_group() has written its tree blocks. With
debug output in a test kernel, the first btrfs_zone_finish() got -EAGAIN
27 times over 6 test runs, and all 1143 calls of the new
btrfs_zone_finish_relocated() succeeded at once. Patch 2 treats a
negative reservation as zero for data. Patch 1 has to come first: with
patch 2 alone the leaked reservation leaves no active zone for a new
system block group, which runs into the deadlock described at the end.

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
  master                  3           -2           29714  fail x2    8/8
  patch 1 only            0            1               0  0, 0       0/8
  patch 2 only     deadlock in balance (see below)
  both                    0            1               0  0, 0       0/8

Testing
-------

virtme-ng VM, CONFIG_PROVE_LOCKING, hung task detector at 60 s, zoned
null_blk with 16 MiB zones and commit=300, data checked on disk after
dropping caches:

- 8 x 512 MiB buffered writers, 16 and 128 open zones: no errors
- 4 x 4000 small files, 16 open zones: no errors
- 8 x 256 MiB O_DIRECT writers, 16 open zones: no errors
- rsync of a 6 GB kernel tree with vm.dirty_bytes of 5 GB, 16 open
  zones: no errors
- filling the filesystem: dd still gets ENOSPC, no hang or retry loop
- the reproducer's balance step on the same kind of ublk device as in
  the original report (100 GiB, 16 MiB zones, 128 open zones), then
  rsync of a kernel tree: master left 3 zombies
  (reservation -2), logged 28 cow_file_range failures, the first
  syncfs() returned -ENOSPC and the second 0, and the same 3.7 GB pack
  file as in the original report differed on disk; patched: no zombies,
  no errors, no differences
- the reproducer above: see the table
- 8 writers with --full-balance in a loop, 16 and 128 open zones, four
  runs each on master and patched: no data loss on either; the issue
  below aborts the transaction in 3 of 4 runs on both, and master also
  deadlocked once

Not fixed here
--------------

These show up with balance while writing on master as well; I did not
want to grow this series:

- Recursive ro_block_group_mutex: btrfs_inc_block_group_ro() ->
  reserve_chunk_space() -> btrfs_zoned_activate_one_bg(info, true) ->
  btrfs_zone_finish_one_bg() -> do_zone_finish() ->
  btrfs_inc_block_group_ro(), with chunk_mutex held, so writeback hangs
  in btrfs_can_activate_zone(). lockdep reports "possible recursive
  locking detected". Seen on master with 8 writers and --full-balance in
  a loop, 16 open zones, and with patch 2 alone in the reproducer.

- "error while writing out transaction: -EAGAIN" from
  btrfs_check_meta_write_pointer() during the commit in
  relocate_block_group(), which aborts the transaction and forces the
  filesystem read-only, in the same balance-while-writing test.

- call_zone_finish() returns before reserved_active_zones++ and
  btrfs_dev_clear_active_zone() when REQ_OP_ZONE_FINISH fails, and
  do_zone_finish() still takes the block group off the active list, so
  an I/O error there leaks the reservation and the active zone.

I used an AI assistant (Claude) for the investigation, the reproducer
and drafting the patches and this mail; the result was reviewed and
tested as described above.

---
Mark Korenberg (2):
      btrfs: zoned: finish the zones of a relocated block group
      btrfs: zoned: don't treat a negative zone reservation as free zones

 fs/btrfs/volumes.c |  3 +++
 fs/btrfs/zoned.c   | 51 +++++++++++++++++++++++++++++++++++++++++++++++----
 fs/btrfs/zoned.h   | 11 ++++++++++-
 3 files changed, 60 insertions(+), 5 deletions(-)
---
base-commit: 65ba8f34ec886ec72b2c07ddc8cf3d815c32869d
change-id: 20261029-btrfs-zoned-active-zone-leak-bb34aa2d981c

Best regards,
-- 
Mark Korenberg <socketpair@gmail.com>

