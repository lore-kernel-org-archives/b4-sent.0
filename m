From: Mark Korenberg <socketpair@gmail.com>
Date: Thu, 29 Oct 2026 13:16:45 +0500
Subject: [PATCH 2/2] btrfs: zoned: don't treat a negative zone reservation
 as free zones
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-btrfs-zoned-active-zone-leak-v1-2-777dd01ff914@gmail.com>
References: <20261029-btrfs-zoned-active-zone-leak-v1-0-777dd01ff914@gmail.com>
In-Reply-To: <20261029-btrfs-zoned-active-zone-leak-v1-0-777dd01ff914@gmail.com>
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>, 
 Naohiro Aota <naohiro.aota@wdc.com>
Cc: linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793261811; l=2969;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=/DV6VhuvZpqJeMSGpyJDetY348SVMJHO3LESTAMCiLA=;
 b=n0FwG6ZfMT+z5PqxaMtHNErkqGVg6tTpK2oqI0vXqG31LdBPqOVSRbJrYhblRrfNpT8EOyMA0
 LrEDY492yyLBZK3TfLzTCc+QN51vpOFdbqMMWleVFll5pW0VKmiAgcn
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
Cc: stable@vger.kernel.org
Signed-off-by: Mark Korenberg <socketpair@gmail.com>
---
 fs/btrfs/zoned.c | 15 +++++++++++----
 fs/btrfs/zoned.h |  5 ++++-
 2 files changed, 15 insertions(+), 5 deletions(-)

diff --git a/fs/btrfs/zoned.c b/fs/btrfs/zoned.c
index ce8d96a48aa3..47aba2a63bb3 100644
--- a/fs/btrfs/zoned.c
+++ b/fs/btrfs/zoned.c
@@ -2444,12 +2444,13 @@ bool btrfs_zone_activate(struct btrfs_block_group *block_group)
 		if (zinfo->max_active_zones == 0)
 			continue;
 
-		if (is_data)
-			reserved = zinfo->reserved_active_zones;
 		/*
 		 * For the data block group, leave active zones for one
-		 * metadata block group and one system block group.
+		 * metadata block group and one system block group. A negative
+		 * reservation holds nothing back, see btrfs_can_activate_zone().
 		 */
+		if (is_data)
+			reserved = max(zinfo->reserved_active_zones, 0);
 		if (atomic_read(&zinfo->active_zones_left) <= reserved) {
 			ret = false;
 			goto out_unlock;
@@ -2712,8 +2713,14 @@ bool btrfs_can_activate_zone(struct btrfs_fs_devices *fs_devices, u64 flags)
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
index 700d6909ee3f..aa6fa3a0b9a3 100644
--- a/fs/btrfs/zoned.h
+++ b/fs/btrfs/zoned.h
@@ -38,7 +38,10 @@ struct btrfs_zoned_device_info {
 	u32 nr_zones;
 	unsigned int max_active_zones;
 	/*
-	 * Reserved active zones for one metadata and one system block group.
+	 * Reserved active zones for one metadata and one system block group:
+	 * the reservation made at mount minus the metadata and system block
+	 * groups active now. It is negative when more of them are active than
+	 * were reserved, which does not mean that there are extra active zones.
 	 * It can vary per-device depending on the allocation status.
 	 */
 	int reserved_active_zones;

-- 
2.56.0

