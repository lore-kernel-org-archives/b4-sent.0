From: Mark Korenberg <socketpair@gmail.com>
Date: Wed, 04 Nov 2026 23:00:20 +0500
Subject: [PATCH v2 2/2] btrfs: zoned: don't treat a negative zone
 reservation as free zones
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-btrfs-zoned-active-zone-leak-v2-2-0cee2ef72171@gmail.com>
References: <20261104-btrfs-zoned-active-zone-leak-v2-0-0cee2ef72171@gmail.com>
In-Reply-To: <20261104-btrfs-zoned-active-zone-leak-v2-0-0cee2ef72171@gmail.com>
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>, 
 Naohiro Aota <naohiro.aota@wdc.com>
Cc: linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Johannes Thumshirn <johannes.thumshirn@wdc.com>, stable@vger.kernel.org, 
 Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793815218; l=3073;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=9ov6vcyfbxQuSIcyp1fix/LygA/f+6EOEeQPQe4ctp4=;
 b=BxSIrWkqQ7jIlbvptF0To6iRBMrgqR04oWtlTiApNObX+NDfp9ARgMOF+xNx9VoGVIFW6CB+V
 O9rjyoCzkWIBrgtPfuQzfZdT2IIlHoy4E0qAacaSxkHpEEaplKG4shY
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

reserved_active_zones goes negative when more metadata and system block
groups are active than were reserved. btrfs_can_activate_zone() then
reports a free active zone for data even when none is left, so the
allocator neither finishes a zone nor waits for one. find_free_extent()
fails with -ENOSPC on a device with plenty of space and cow_file_range()
drops the dirty range; only the next fsync() or syncfs() reports it.

A negative reservation holds nothing back. Treat it as zero for data
block groups.

Fixes: a7e1ac7bdc5a ("btrfs: zoned: reserve zones for an active metadata/system block group")
Cc: stable@vger.kernel.org # 7.0.x
Signed-off-by: Mark Korenberg <socketpair@gmail.com>
---
 fs/btrfs/zoned.c | 17 ++++++++++++-----
 fs/btrfs/zoned.h |  6 +++++-
 2 files changed, 17 insertions(+), 6 deletions(-)

diff --git a/fs/btrfs/zoned.c b/fs/btrfs/zoned.c
index 1d64c6e162ca..20b99325117b 100644
--- a/fs/btrfs/zoned.c
+++ b/fs/btrfs/zoned.c
@@ -2465,12 +2465,13 @@ bool btrfs_zone_activate(struct btrfs_block_group *block_group)
 		if (zinfo->max_active_zones == 0)
 			continue;
 
-		if (is_data)
-			reserved = zinfo->reserved_active_zones;
 		/*
-		 * For the data block group, leave active zones for one
-		 * metadata block group and one system block group.
+		 * For the data block group, leave the active zones reserved
+		 * for metadata, tree-log and system block groups. A negative
+		 * reservation holds nothing back, see btrfs_can_activate_zone().
 		 */
+		if (is_data)
+			reserved = max(zinfo->reserved_active_zones, 0);
 		if (atomic_read(&zinfo->active_zones_left) <= reserved) {
 			ret = false;
 			goto out_unlock;
@@ -2744,8 +2745,14 @@ bool btrfs_can_activate_zone(struct btrfs_fs_devices *fs_devices, u64 flags)
 			break;
 		}
 
+		/*
+		 * A negative reservation holds nothing back. Do not count it
+		 * as free zones: the check below would pass with no active
+		 * zone left, and the caller would allocate a chunk it cannot
+		 * activate instead of finishing a zone, then fail with -ENOSPC.
+		 */
 		if (flags & BTRFS_BLOCK_GROUP_DATA)
-			reserved = zinfo->reserved_active_zones;
+			reserved = max(zinfo->reserved_active_zones, 0);
 
 		switch (flags & BTRFS_BLOCK_GROUP_PROFILE_MASK) {
 		case 0: /* single */
diff --git a/fs/btrfs/zoned.h b/fs/btrfs/zoned.h
index 510e9d118c7c..2225090839f3 100644
--- a/fs/btrfs/zoned.h
+++ b/fs/btrfs/zoned.h
@@ -38,7 +38,11 @@ struct btrfs_zoned_device_info {
 	u32 nr_zones;
 	unsigned int max_active_zones;
 	/*
-	 * Reserved active zones for one metadata and one system block group.
+	 * Reserved active zones for one metadata, one tree-log and one system
+	 * block group: the reservation made at mount minus the zones of such
+	 * block groups active on this device now. It is negative when more of
+	 * them are active than were reserved, which does not mean that there
+	 * are extra active zones.
 	 * It can vary per-device depending on the allocation status.
 	 */
 	int reserved_active_zones;

-- 
2.56.0

