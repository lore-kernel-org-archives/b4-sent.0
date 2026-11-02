From: Mark Korenberg <socketpair@gmail.com>
Date: Mon, 02 Nov 2026 20:35:04 +0500
Subject: [PATCH v3] btrfs: zoned: reset leaked zones on read-write mount
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-b4-btrfs-zoned-reset-leaked-zones-v3-1-7979bda654ff@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3NwQ6CMBCE4Vche3aTCk1BX8VwADuVjaaYXUKIh
 He3evz+w8xOBhUYXaudFKuYzLmgOVV0n4b8AEssptrV4ewax6PncdFk/JkzIisMC78wPAt+yfg
 SUuh8iF3rPJWdtyLJ9v+49cfxBYk4Ir9zAAAA
X-Change-ID: 20261030-b4-btrfs-zoned-reset-leaked-zones-96f6846d8704
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>
Cc: Johannes Thumshirn <johannes.thumshirn@wdc.com>, 
 Naohiro Aota <naohiro.aota@wdc.com>, linux-btrfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793633703; l=11310;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=SGZbdYOpSOd6VSbPP3PzBj8LyaSlIPUZ/bWhvwvqRSU=;
 b=6F+Ru6OEtfwbW5sjDtI+Z5XLMqB3HBFQ9b43p7hoGqkZLgspwkh3VcSvCeL2hYCNLl2oyCvJr
 ZEDwF8AM6P7AHwhFs1rNgNFHA8vPgi4vR6wuPVtSu71R/X6WSgcKJuv
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If a transaction commit is aborted after the zones of a new block group
were written but before the superblock was, the chunk item and the dev
extent are never persisted and the zones leak. The chunk allocator skips
non-empty zones, so they are never reused, open ones keep counting
against the active zone limit, and btrfs check reports them as
unreferenced.

On a read-write mount, reset every non-empty sequential zone that is
neither a superblock log zone nor allocated to a chunk. Commit the
running transaction under reclaim_bgs_lock first, so that a chunk
removal is not mistaken for a leak, hold chunk_mutex so that no chunk is
allocated meanwhile, and skip it all while a device replace is ongoing,
as no chunk references the replace target yet.

Suggested-by: Johannes Thumshirn <johannes.thumshirn@wdc.com>
Signed-off-by: Mark Korenberg <socketpair@gmail.com>
---
This follows up on my RFC about stale zones in unallocated device space.
Johannes replied to it with v1 of this patch and handed it over to me,
and I posted v2 as an attachment in the same thread. This is v3, now
tested and posted as a regular patch.

RFC: https://lore.kernel.org/all/CAEmTpZGu5x9PS7vFwgc_dFH80rL3cFD4-geuuL_w8i=vFDo8AA@mail.gmail.com/

Changes in v3:
- Don't ask the device for the zone condition under chunk_mutex. On
  virtio-blk a zone report takes vdev_mutex, under which the
  BLKREPORTZONE ioctl copies to user space, and btrfs_fallocate()
  allocates chunks under i_mmap_lock, which a write fault takes. Lockdep
  would report the same kind of cycle as the one fixed by "btrfs: zoned:
  fix lockdep splat on mount". A zone reset takes no such lock.
  As a result, offline and read-only zones are no longer skipped:
  resetting a run that contains one fails, which is logged and
  otherwise ignored.
- Link to v2: https://lore.kernel.org/all/CAEmTpZGifFxr+yaKddZcG8UxhntYvZROygi6s-8goAoxuUzqHQ@mail.gmail.com/

Changes in v2:
- Skip while a device replace is ongoing; v1 reset the data already
  copied to the replace target.
- Hold chunk_mutex; v1 raced with chunk allocation in open_ctree().
- Hold reclaim_bgs_lock and commit first; v1 could reset the zones of a
  chunk removed by a relocating repair before the removal was committed.
- Check coverage in device->alloc_state: covers whole stripes, no
  bitmap allocation, no NULL physical_map case.
- Walk alloc_list (writeable devices) under chunk_mutex instead of the
  device list under device_list_mutex, only up to total_bytes.
- Skip offline and read-only zones, they cannot be reset.
- Reset adjacent zones in one call and log each reset range.
- Link to v1: https://lore.kernel.org/all/52925d79-4dce-4621-b9e1-fd062b47e35d@wdc.com/

Testing: virtme-ng VM, zoned null_blk with 64 MiB zones,
CONFIG_PROVE_LOCKING, this patch plus debug logging of every decision:
- not zoned filesystem: nothing done
- fresh filesystem: the first mount resets zone 3, which mkfs.btrfs
  (btrfs-progs 7.1) leaves written outside any chunk; nothing to do on
  the next mount, btrfs check clean
- zones written behind the back of btrfs: reset, data intact
- a run of leaked zones containing an offline and a read-only zone:
  the reset fails with -EIO and is logged, the mount goes on, both
  zones keep their condition, data intact
- ro mount leaves leaked zones, remount,rw resets them
- replace interrupted with remount,ro and resumed with remount,rw: the
  pass is skipped, nothing reset
- no lockdep report or warning from this patch

Not tested: lockdep on a zoned virtio-blk device, the cycle fixed in v3
was found by reading the code. A replace interrupted by umount and
resumed by mount: on master a device replace on this setup aborts the
transaction with -EAGAIN within seconds (commit from
scrub_enumerate_chunks()), and the scrub then waits for itself in
btrfs_scrub_cancel() called from cleanup_transaction(). That is
unrelated to this patch, I will report it separately.

Reviewed with the help of an AI assistant (Claude), which also drafted
the v2 and v3 changes and the tests.
---
 fs/btrfs/disk-io.c |   2 +
 fs/btrfs/zoned.c   | 140 +++++++++++++++++++++++++++++++++++++++++++++++++++++
 fs/btrfs/zoned.h   |   3 ++
 3 files changed, 145 insertions(+)

diff --git a/fs/btrfs/disk-io.c b/fs/btrfs/disk-io.c
index c45cda4290d5..f3e15c575e8a 100644
--- a/fs/btrfs/disk-io.c
+++ b/fs/btrfs/disk-io.c
@@ -3059,6 +3059,8 @@ int btrfs_start_pre_rw_mount(struct btrfs_fs_info *fs_info)
 	int ret;
 	bool rebuild_free_space_tree = false;
 
+	btrfs_reset_unreferenced_zones(fs_info);
+
 	if (btrfs_test_opt(fs_info, CLEAR_CACHE) &&
 	    btrfs_fs_compat_ro(fs_info, FREE_SPACE_TREE)) {
 		if (btrfs_fs_incompat(fs_info, EXTENT_TREE_V2))
diff --git a/fs/btrfs/zoned.c b/fs/btrfs/zoned.c
index 1cda88332284..56940eaf1594 100644
--- a/fs/btrfs/zoned.c
+++ b/fs/btrfs/zoned.c
@@ -3226,6 +3226,146 @@ int btrfs_reset_unused_block_groups(struct btrfs_space_info *space_info, u64 num
 	return 0;
 }
 
+/*
+ * A zone is leaked if it is a non-empty sequential zone that is neither a
+ * superblock log zone nor part of any stripe of any chunk. Chunk stripes are
+ * looked up in the device's alloc_state, which covers every chunk in the
+ * mapping tree over the whole stripe length.
+ */
+static bool is_leaked_zone(struct btrfs_device *device, u32 zno)
+{
+	struct btrfs_zoned_device_info *zinfo = device->zone_info;
+	u64 start = (u64)zno << zinfo->zone_size_shift;
+
+	if (!btrfs_dev_is_sequential(device, start))
+		return false;
+
+	if (btrfs_dev_is_empty_zone(device, start))
+		return false;
+
+	if (btrfs_test_range_bit_exists(&device->alloc_state, start,
+					start + zinfo->zone_size - 1,
+					CHUNK_ALLOCATED))
+		return false;
+
+	for (int mirror = 0; mirror < BTRFS_SUPER_MIRROR_MAX; mirror++) {
+		u32 sb_zno = sb_zone_number(zinfo->zone_size_shift, mirror);
+
+		if (sb_zno + BTRFS_NR_SB_LOG_ZONES > zinfo->nr_zones)
+			continue;
+		if (zno >= sb_zno && zno < sb_zno + BTRFS_NR_SB_LOG_ZONES)
+			return false;
+	}
+
+	return true;
+}
+
+void btrfs_reset_unreferenced_zones(struct btrfs_fs_info *fs_info)
+{
+	struct btrfs_fs_devices *fs_devices = fs_info->fs_devices;
+	struct btrfs_dev_replace *dev_replace = &fs_info->dev_replace;
+	struct btrfs_device *device;
+	bool replace_ongoing;
+	int ret;
+
+	if (!btrfs_is_zoned(fs_info))
+		return;
+
+	/*
+	 * No chunk stripe points to the target of an interrupted device replace
+	 * until the replace finishes, so the data already copied to it would
+	 * look leaked. The replace resumes from the last committed cursor and
+	 * would never copy that data again.
+	 *
+	 * The target is not on alloc_list, which is walked below, so strictly
+	 * speaking it would be enough to skip only the device that has
+	 * BTRFS_DEV_STATE_REPLACE_TGT set. Still, do not reset anything at all
+	 * while a replace is ongoing, the leaked zones can be reclaimed on the
+	 * next mount after the replace has finished or was canceled.
+	 *
+	 * Do not hold the rwsem across the pass, the replace code takes it
+	 * after chunk_mutex. A replace cannot be started while we are in the
+	 * (re)mount path.
+	 */
+	down_read(&dev_replace->rwsem);
+	replace_ongoing = btrfs_dev_replace_is_ongoing(dev_replace);
+	up_read(&dev_replace->rwsem);
+	if (replace_ongoing) {
+		btrfs_info(fs_info,
+			   "zoned: device replace is ongoing, not resetting leaked zones");
+		return;
+	}
+
+	/*
+	 * Chunks are only removed under reclaim_bgs_lock, and their zones must
+	 * not be reset before the removal is committed. A relocating repair,
+	 * started by a read error during mount, may already have removed one in
+	 * the running transaction, so commit it before looking for leaked zones.
+	 */
+	mutex_lock(&fs_info->reclaim_bgs_lock);
+	ret = btrfs_commit_current_transaction(fs_info->tree_root);
+	if (ret) {
+		btrfs_warn(fs_info,
+			   "zoned: failed to commit transaction, not resetting leaked zones: %pe",
+			   ERR_PTR(ret));
+		goto out;
+	}
+
+	/*
+	 * Hold chunk_mutex, which also protects alloc_list, so that no chunk can
+	 * be allocated between checking a zone and resetting it.
+	 */
+	mutex_lock(&fs_info->chunk_mutex);
+	list_for_each_entry(device, &fs_devices->alloc_list, dev_alloc_list) {
+		struct btrfs_zoned_device_info *zinfo = device->zone_info;
+		u32 nr_zones;
+
+		if (!device->bdev || !zinfo || !bdev_is_zoned(device->bdev))
+			continue;
+
+		/* Nothing is ever allocated beyond total_bytes, leave it alone. */
+		nr_zones = min_t(u64, zinfo->nr_zones,
+				 device->total_bytes >> zinfo->zone_size_shift);
+
+		for (u32 zno = 0; zno < nr_zones; zno++) {
+			u32 first = zno;
+			u64 reset_bytes;
+
+			cond_resched();
+
+			while (zno < nr_zones && is_leaked_zone(device, zno))
+				zno++;
+			if (zno == first)
+				continue;
+
+			ret = btrfs_reset_device_zone(device,
+						      (u64)first << zinfo->zone_size_shift,
+						      (u64)(zno - first) << zinfo->zone_size_shift,
+						      &reset_bytes);
+			/*
+			 * Offline and read-only zones look leaked too, as they are
+			 * never marked empty, but cannot be reset. Don't ask the
+			 * device for the zone condition here: on virtio-blk a zone
+			 * report takes a lock that nests outside of chunk_mutex.
+			 * Just log a failed reset and move on, the run is retried
+			 * on the next mount.
+			 */
+			if (ret)
+				btrfs_warn(fs_info,
+					   "zoned: failed to reset leaked zones %u-%u on device %s (devid %llu): %pe",
+					   first, zno - 1, btrfs_dev_name(device),
+					   device->devid, ERR_PTR(ret));
+			else
+				btrfs_info(fs_info,
+					   "zoned: reset leaked zones %u-%u on device %s (devid %llu)",
+					   first, zno - 1, btrfs_dev_name(device), device->devid);
+		}
+	}
+	mutex_unlock(&fs_info->chunk_mutex);
+out:
+	mutex_unlock(&fs_info->reclaim_bgs_lock);
+}
+
 void btrfs_show_zoned_stats(struct btrfs_fs_info *fs_info, struct seq_file *seq)
 {
 	struct btrfs_block_group *bg;
diff --git a/fs/btrfs/zoned.h b/fs/btrfs/zoned.h
index 8e21a836f858..76b40e81ca32 100644
--- a/fs/btrfs/zoned.h
+++ b/fs/btrfs/zoned.h
@@ -97,6 +97,7 @@ int btrfs_zone_finish_one_bg(struct btrfs_fs_info *fs_info);
 int btrfs_zoned_activate_one_bg(struct btrfs_space_info *space_info, bool do_finish);
 void btrfs_check_active_zone_reservation(struct btrfs_fs_info *fs_info);
 int btrfs_reset_unused_block_groups(struct btrfs_space_info *space_info, u64 num_bytes);
+void btrfs_reset_unreferenced_zones(struct btrfs_fs_info *fs_info);
 void btrfs_show_zoned_stats(struct btrfs_fs_info *fs_info, struct seq_file *seq);
 
 #ifdef CONFIG_BTRFS_FS_RUN_SANITY_TESTS
@@ -287,6 +288,8 @@ static inline int btrfs_reset_unused_block_groups(struct btrfs_space_info *space
 	return 0;
 }
 
+static inline void btrfs_reset_unreferenced_zones(struct btrfs_fs_info *fs_info) { }
+
 static inline int btrfs_show_zoned_stats(struct btrfs_fs_info *fs_info, struct seq_file *seq)
 {
 	return 0;

---
base-commit: d135ab453a7400a34930bdda1ef4bdc8acfac80e
change-id: 20261030-b4-btrfs-zoned-reset-leaked-zones-96f6846d8704

Best regards,
-- 
Mark Korenberg <socketpair@gmail.com>

