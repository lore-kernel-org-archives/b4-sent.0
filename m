From: Mark Korenberg <socketpair@gmail.com>
Date: Thu, 29 Oct 2026 13:16:44 +0500
Subject: [PATCH 1/2] btrfs: zoned: finish the zones of a relocated block
 group
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-btrfs-zoned-active-zone-leak-v1-1-777dd01ff914@gmail.com>
References: <20261029-btrfs-zoned-active-zone-leak-v1-0-777dd01ff914@gmail.com>
In-Reply-To: <20261029-btrfs-zoned-active-zone-leak-v1-0-777dd01ff914@gmail.com>
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>, 
 Naohiro Aota <naohiro.aota@wdc.com>
Cc: linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793261811; l=4344;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=zRjBI+rJe+s4Uyjpfd78jmh2lrY/Nq7+JPNK4RV1AgQ=;
 b=2nZhBQNgYMl+xskDi0bYJDWXNYH/OIBVapj4dT9o4si/8CQfk9iRtSQt9ILvnEtBaQ3BrlVhS
 XXymjKOZiBpBEdwtZNnuW6Udt46TIcgI78xex0XH+PmTN6lTxuiP2jV
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
block group. It is read-only and empty by then, and relocate_block_group()
has committed the transaction, so its tree blocks are written. Drop its
data relocation role and finish it. Keep the chunk if that fails.

Fixes: 7ae9bd18032e ("btrfs: zoned: finish relocating block group")
Cc: stable@vger.kernel.org
Signed-off-by: Mark Korenberg <socketpair@gmail.com>
---
 fs/btrfs/volumes.c |  3 +++
 fs/btrfs/zoned.c   | 36 ++++++++++++++++++++++++++++++++++++
 fs/btrfs/zoned.h   |  6 ++++++
 3 files changed, 45 insertions(+)

diff --git a/fs/btrfs/volumes.c b/fs/btrfs/volumes.c
index d3e6a9b429dd..112ef1a53199 100644
--- a/fs/btrfs/volumes.c
+++ b/fs/btrfs/volumes.c
@@ -3703,7 +3703,10 @@ static int btrfs_relocate_chunk_finish(struct btrfs_fs_info *fs_info,
 
 	btrfs_discard_cancel_work(&fs_info->discard_ctl, bg);
 	length = bg->length;
+	ret = btrfs_zone_finish_relocated(bg);
 	btrfs_put_block_group(bg);
+	if (ret)
+		return ret;
 
 	/*
 	 * On a zoned file system, discard the whole block group, this will
diff --git a/fs/btrfs/zoned.c b/fs/btrfs/zoned.c
index 1cda88332284..ce8d96a48aa3 100644
--- a/fs/btrfs/zoned.c
+++ b/fs/btrfs/zoned.c
@@ -2649,6 +2649,42 @@ int btrfs_zone_finish(struct btrfs_block_group *block_group)
 	return do_zone_finish(block_group, false);
 }
 
+/*
+ * Finish the zones of a block group emptied by relocation, before removing it.
+ *
+ * btrfs_relocate_block_group() tries this before relocating, but gets -EAGAIN
+ * while tree blocks allocated in the block group are not written yet. If the
+ * block group is then removed with its zones still active, it stays on
+ * fs_info->zone_active_bgs and, for metadata and system, its share of
+ * reserved_active_zones is never given back. After a few balances the
+ * reservation is negative and data writeback fails with -ENOSPC.
+ *
+ * Here the zones can be finished: the block group is read-only, so nothing is
+ * allocated in it, and relocate_block_group() committed the transaction, so
+ * its tree blocks are written.
+ */
+int btrfs_zone_finish_relocated(struct btrfs_block_group *block_group)
+{
+	int ret;
+
+	if (!btrfs_is_zoned(block_group->fs_info))
+		return 0;
+
+	/*
+	 * do_zone_finish() refuses the data relocation block group. This one is
+	 * empty and gets no more relocated data, so drop that role.
+	 */
+	btrfs_clear_data_reloc_bg(block_group);
+	spin_lock(&block_group->lock);
+	clear_bit(BLOCK_GROUP_FLAG_ZONED_DATA_RELOC, &block_group->runtime_flags);
+	spin_unlock(&block_group->lock);
+
+	ret = do_zone_finish(block_group, false);
+	WARN_ON_ONCE(ret == -EAGAIN);
+
+	return ret;
+}
+
 bool btrfs_can_activate_zone(struct btrfs_fs_devices *fs_devices, u64 flags)
 {
 	struct btrfs_fs_info *fs_info = fs_devices->fs_info;
diff --git a/fs/btrfs/zoned.h b/fs/btrfs/zoned.h
index 8e21a836f858..700d6909ee3f 100644
--- a/fs/btrfs/zoned.h
+++ b/fs/btrfs/zoned.h
@@ -82,6 +82,7 @@ int btrfs_sync_zone_write_pointer(struct btrfs_device *tgt_dev, u64 logical,
 				  u64 physical_start, u64 physical_pos);
 bool btrfs_zone_activate(struct btrfs_block_group *block_group);
 int btrfs_zone_finish(struct btrfs_block_group *block_group);
+int btrfs_zone_finish_relocated(struct btrfs_block_group *block_group);
 bool btrfs_can_activate_zone(struct btrfs_fs_devices *fs_devices, u64 flags);
 int btrfs_zone_finish_endio(struct btrfs_fs_info *fs_info, u64 logical,
 			     u64 length);
@@ -238,6 +239,11 @@ static inline int btrfs_zone_finish(struct btrfs_block_group *block_group)
 	return 0;
 }
 
+static inline int btrfs_zone_finish_relocated(struct btrfs_block_group *block_group)
+{
+	return 0;
+}
+
 static inline bool btrfs_can_activate_zone(struct btrfs_fs_devices *fs_devices,
 					   u64 flags)
 {

-- 
2.56.0

