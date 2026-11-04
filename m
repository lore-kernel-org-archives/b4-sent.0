From: Mark Korenberg <socketpair@gmail.com>
Date: Wed, 04 Nov 2026 23:00:19 +0500
Subject: [PATCH v2 1/2] btrfs: zoned: finish the zones of a relocated block
 group
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-btrfs-zoned-active-zone-leak-v2-1-0cee2ef72171@gmail.com>
References: <20261104-btrfs-zoned-active-zone-leak-v2-0-0cee2ef72171@gmail.com>
In-Reply-To: <20261104-btrfs-zoned-active-zone-leak-v2-0-0cee2ef72171@gmail.com>
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>, 
 Naohiro Aota <naohiro.aota@wdc.com>
Cc: linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Johannes Thumshirn <johannes.thumshirn@wdc.com>, stable@vger.kernel.org, 
 Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793815218; l=4749;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=gaQLP1Y985cx5GItFHMmB9iX4pBxq93xF+S4CSWbcYE=;
 b=FdcQYVMwhqgmuO7gDR7Qvzk1Wd9lvERd+SIlrF64oCKvUxnABa6U324HBDzTWM0DOV/s4UN7n
 4tXLN1rluagBwyTGw9p5g2PH/WlAAah38fLXozSjBdhqbotAFM9PBB+
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

btrfs_relocate_block_group() ignores -EAGAIN from btrfs_zone_finish().
A metadata or system block group with tree blocks not written yet, or
the data relocation block group, is then relocated and removed with its
zone still active: it stays on zone_active_bgs and its share of
reserved_active_zones is never given back. Repeated balances drive the
reservation negative, which ends in -ENOSPC and lost data in writeback
(see the next patch).

Finish the zone in btrfs_relocate_chunk_finish() before removing the
block group. Nothing is left to write in it by then: it is read-only
and empty, and relocate_block_group() has committed the transaction.
So only wait for extent buffer writeback and finish it as fully
written. Taking it read-only again, as btrfs_zone_finish() does, can
allocate a system chunk under ro_block_group_mutex for a system block
group and take the mutex again to finish another block group. If
finishing fails, warn and remove the block group as before.

Fixes: 7ae9bd18032e ("btrfs: zoned: finish relocating block group")
Cc: stable@vger.kernel.org # 7.0.x
Signed-off-by: Mark Korenberg <socketpair@gmail.com>
---
 fs/btrfs/volumes.c |  1 +
 fs/btrfs/zoned.c   | 37 +++++++++++++++++++++++++++++++++++++
 fs/btrfs/zoned.h   |  3 +++
 3 files changed, 41 insertions(+)

diff --git a/fs/btrfs/volumes.c b/fs/btrfs/volumes.c
index 3d4ef6725de0..1547eee60612 100644
--- a/fs/btrfs/volumes.c
+++ b/fs/btrfs/volumes.c
@@ -3720,6 +3720,7 @@ static int btrfs_relocate_chunk_finish(struct btrfs_fs_info *fs_info,
 
 	btrfs_discard_cancel_work(&fs_info->discard_ctl, bg);
 	length = bg->length;
+	btrfs_zone_finish_relocated(bg);
 	btrfs_put_block_group(bg);
 
 	/*
diff --git a/fs/btrfs/zoned.c b/fs/btrfs/zoned.c
index 3192b86669b9..1d64c6e162ca 100644
--- a/fs/btrfs/zoned.c
+++ b/fs/btrfs/zoned.c
@@ -2680,6 +2680,43 @@ int btrfs_zone_finish(struct btrfs_block_group *block_group)
 	return do_zone_finish(block_group, false);
 }
 
+/*
+ * Finish the zones of a block group emptied by relocation, before removing it.
+ *
+ * btrfs_relocate_block_group() tries this before relocating, but gets -EAGAIN
+ * while tree blocks allocated in the block group are not written yet, and for
+ * the data relocation block group. If the block group is then removed with its
+ * zones still active, it stays on fs_info->zone_active_bgs and, for metadata
+ * and system, its share of reserved_active_zones is never given back. After a
+ * few balances the reservation is negative and data writeback fails with
+ * -ENOSPC.
+ *
+ * Here nothing is left to write: the block group is read-only and empty,
+ * relocation waited for its reservations and ordered extents, and
+ * relocate_block_group() committed the transaction. So only wait for extent
+ * buffer writeback and finish it as fully written. do_zone_finish(bg, false)
+ * would take it read-only again, which for a system block group can allocate
+ * a system chunk under ro_block_group_mutex and finish another block group to
+ * activate it, taking the mutex again.
+ */
+void btrfs_zone_finish_relocated(struct btrfs_block_group *block_group)
+{
+	struct btrfs_fs_info *fs_info = block_group->fs_info;
+	int ret;
+
+	if (!btrfs_is_zoned(fs_info))
+		return;
+
+	if (block_group->flags & (BTRFS_BLOCK_GROUP_METADATA | BTRFS_BLOCK_GROUP_SYSTEM))
+		wait_eb_writebacks(block_group);
+
+	ret = do_zone_finish(block_group, true);
+	if (ret)
+		btrfs_warn(fs_info,
+			   "failed to finish zones of relocated block group %llu: %d",
+			   block_group->start, ret);
+}
+
 bool btrfs_can_activate_zone(struct btrfs_fs_devices *fs_devices, u64 flags)
 {
 	struct btrfs_fs_info *fs_info = fs_devices->fs_info;
diff --git a/fs/btrfs/zoned.h b/fs/btrfs/zoned.h
index 8e21a836f858..510e9d118c7c 100644
--- a/fs/btrfs/zoned.h
+++ b/fs/btrfs/zoned.h
@@ -82,6 +82,7 @@ int btrfs_sync_zone_write_pointer(struct btrfs_device *tgt_dev, u64 logical,
 				  u64 physical_start, u64 physical_pos);
 bool btrfs_zone_activate(struct btrfs_block_group *block_group);
 int btrfs_zone_finish(struct btrfs_block_group *block_group);
+void btrfs_zone_finish_relocated(struct btrfs_block_group *block_group);
 bool btrfs_can_activate_zone(struct btrfs_fs_devices *fs_devices, u64 flags);
 int btrfs_zone_finish_endio(struct btrfs_fs_info *fs_info, u64 logical,
 			     u64 length);
@@ -238,6 +239,8 @@ static inline int btrfs_zone_finish(struct btrfs_block_group *block_group)
 	return 0;
 }
 
+static inline void btrfs_zone_finish_relocated(struct btrfs_block_group *block_group) { }
+
 static inline bool btrfs_can_activate_zone(struct btrfs_fs_devices *fs_devices,
 					   u64 flags)
 {

-- 
2.56.0

