From: Luca Stefani <luca.stefani.ge1@gmail.com>
Date: Wed, 28 Oct 2026 18:55:49 +0100
Subject: [PATCH 1/2] btrfs: account partially completed discards
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-b4-btrfs-fitrim-interruption-v1-1-bf5c53738b3a@gmail.com>
References: <20261028-b4-btrfs-fitrim-interruption-v1-0-bf5c53738b3a@gmail.com>
In-Reply-To: <20261028-b4-btrfs-fitrim-interruption-v1-0-bf5c53738b3a@gmail.com>
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>, 
 Luca Stefani <luca.stefani.ge1@gmail.com>
Cc: Robbie Ko <robbieko@synology.com>, Filipe Manana <fdmanana@suse.com>, 
 linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793210149; l=2358;
 i=luca.stefani.ge1@gmail.com; s=20261028; h=from:subject:message-id;
 bh=F8Pv6qkXxT7wewljV2XNrswlKdtAJgpfaMISGxrcbhU=;
 b=+2gdX7sfz1h0qgzIpAuAL6fcd6qg9uioKN7l5daPZivzQYYj9AoiKdo6Wa+usHadZ3K6F0llM
 pY2vmhhMZxWBC3D/CtV6lD9mGMraSPSEUdx6NAn3kupD90Dn+Tp9bOZ
X-Developer-Key: i=luca.stefani.ge1@gmail.com; a=ed25519;
 pk=0OIKU9oiaC0ALN4kqvw7ZbPFXqsBLvWm7MhEDYv3PyI=
X-Endpoint-Received: by B4 Relay for luca.stefani.ge1@gmail.com/20261028 with auth_id=1347
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A discard can complete part of a range before a later chunk is interrupted
or fails. btrfs_issue_discard() reports the bytes already discarded, but
its callers only accumulate those bytes when the entire operation succeeds.

Link: https://lore.kernel.org/20261028-btrfs-fitrim-freezer-v1-1-0ad1d58aa94d@zliang.me/
Signed-off-by: Luca Stefani <luca.stefani.ge1@gmail.com>
---
 fs/btrfs/extent-tree.c      | 5 ++---
 fs/btrfs/free-space-cache.c | 5 ++---
 2 files changed, 4 insertions(+), 6 deletions(-)

diff --git a/fs/btrfs/extent-tree.c b/fs/btrfs/extent-tree.c
index 9b0a5c6b96f3..242db255cf1c 100644
--- a/fs/btrfs/extent-tree.c
+++ b/fs/btrfs/extent-tree.c
@@ -1463,6 +1463,7 @@ int btrfs_discard_extent(struct btrfs_fs_info *fs_info, u64 bytenr,
 				continue;
 
 			ret = do_discard_extent(stripe, &bytes);
+			discarded_bytes += bytes;
 			if (ret) {
 				/*
 				 * Keep going if discard is not supported by the
@@ -1471,8 +1472,6 @@ int btrfs_discard_extent(struct btrfs_fs_info *fs_info, u64 bytenr,
 				if (ret != -EOPNOTSUPP)
 					break;
 				ret = 0;
-			} else {
-				discarded_bytes += bytes;
 			}
 		}
 		kfree(stripes);
@@ -6703,6 +6702,7 @@ static int btrfs_trim_free_extents_throttle(struct btrfs_device *device,
 
 		ret = btrfs_issue_discard(device->bdev, start, len,
 					  &bytes);
+		*trimmed += bytes;
 		if (!ret)
 			btrfs_set_extent_bit(&device->alloc_state, start,
 					     start + bytes - 1, CHUNK_TRIMMED, NULL);
@@ -6712,7 +6712,6 @@ static int btrfs_trim_free_extents_throttle(struct btrfs_device *device,
 			break;
 
 		start += len;
-		*trimmed += bytes;
 		trim_len += len;
 		if (trim_len >= BTRFS_MAX_TRIM_LENGTH) {
 			*ret_next_pos = start;
diff --git a/fs/btrfs/free-space-cache.c b/fs/btrfs/free-space-cache.c
index bff6e5b372d6..a85806bcf87a 100644
--- a/fs/btrfs/free-space-cache.c
+++ b/fs/btrfs/free-space-cache.c
@@ -2415,10 +2415,9 @@ static int do_trimming(struct btrfs_block_group *block_group,
 	spin_unlock(&space_info->lock);
 
 	ret = btrfs_discard_extent(fs_info, start, bytes, &trimmed, false);
-	if (!ret) {
-		*total_trimmed += trimmed;
+	*total_trimmed += trimmed;
+	if (!ret)
 		trim_state = BTRFS_TRIM_STATE_TRIMMED;
-	}
 
 	if (reserved_start < start)
 		__btrfs_add_free_space(block_group, reserved_start,

-- 
2.56.0

