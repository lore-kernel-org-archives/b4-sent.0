From: Dhruva Gole <goledhruva@gmail.com>
Date: Tue, 03 Nov 2026 05:14:23 +0000
Subject: [PATCH] btrfs: do not extend a remapped range in btrfs_map_block()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-btrfs-remap-tree-read-boundary-v1-1-3617ae3406d1@gmail.com>
X-B4-Tracking: v=1; b=H4sIAK5t6WoC/zWNQQrCMBAAv1L27ELSaFG/Ij1smq0N6LZsUomU/
 t0oeJu5zGyQWCMnuDYbKL9iirNUsYcGhonkzhhDdWhN21lrHPqsY0LlJy2YlbkiBfTzKoH0jSf
 jvAuhc+fjBWpkUR5j+Q1ufXVPidEryTB9s48oa0HhkvF/gH3/AEFVaQSWAAAA
X-Change-ID: 20261103-btrfs-remap-tree-read-boundary-503b3dd63849
To: goledhruva@gmail.com, David Sterba <dsterba@suse.com>, 
 Chris Mason <mason@kernel.org>, Mark Harmstone <mark@harmstone.com>
Cc: Boris Burkov <boris@bur.io>, linux-btrfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793682878; l=2983;
 i=goledhruva@gmail.com; s=remote-20261025; h=from:subject:message-id;
 bh=JkaXyO8vlkKPkq+yRGR+UNE45KtSSvFP9N/KdcZj144=;
 b=hG6XIN2PD7T88uha7j57W4vKiXvLFHAr7EoqNOD2ZhSXqH7hLejNB5U+ELqzula0pIAshQ/HN
 4pEblv1T1ziDKXpwz4udpZKWz6ts6MvGlRODAb1r8Pz+KIUcmz96pIq
X-Developer-Key: i=goledhruva@gmail.com; a=ed25519;
 pk=OBz78Vw5K+/+HyXjxg9mNOV2Bq087eJgHL749H+Xe/k=
X-Endpoint-Received: by B4 Relay for goledhruva@gmail.com/remote-20261025 with auth_id=1318
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For a logical address in a remapped block group, btrfs_map_block() calls
btrfs_translate_remap() to find the address the data was moved to. That
function sets *length to the size that is contiguous in the destination,
which is at most the end of the remap item that was found.

btrfs_map_block() then overwrites *length with the minimum between what is
left in the destination chunk and the maximum I/O length for it, which
discards the limit set by btrfs_translate_remap(). The caller, such as
btrfs_submit_chunk(), assumes the whole length is mapped contiguously from
the returned address and only splits the bio at that length, so if the
bio spans more than one remap item, its tail is read from the destination
of the first item instead of from the destination of the item it belongs
to.

This happens after relocating a block group with the remap-tree feature
into fragmented free space, where a single extent ends up split in many
remap items. Reading such a file results in:

 - for files with checksums, csum errors that bump the corruption device
   stats and failed O_DIRECT reads;

 - for NOCOW files or files without checksums, silently returning data
   from unrelated locations on the device, which can be the content of
   other files or stale data.

Fix this by saving the length returned by btrfs_translate_remap() and
using it as an additional upper bound for *length.

Fixes: 18ba64992871 ("btrfs: redirect I/O for remapped block groups")
Assisted-by: Claude
Signed-off-by: Dhruva Gole <goledhruva@gmail.com>
---
 fs/btrfs/volumes.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/fs/btrfs/volumes.c b/fs/btrfs/volumes.c
index 3d4ef6725de0..e512d33f1bc4 100644
--- a/fs/btrfs/volumes.c
+++ b/fs/btrfs/volumes.c
@@ -7311,6 +7311,7 @@ int btrfs_map_block(struct btrfs_fs_info *fs_info, enum btrfs_map_op op,
 	bool dev_replace_is_ongoing = false;
 	u16 num_alloc_stripes;
 	u64 max_len;
+	u64 remap_len = U64_MAX;
 
 	ASSERT(bioc_ret);
 
@@ -7329,6 +7330,7 @@ int btrfs_map_block(struct btrfs_fs_info *fs_info, enum btrfs_map_op op,
 		ret = btrfs_translate_remap(fs_info, &new_logical, length);
 		if (ret)
 			goto out;
+		remap_len = *length;
 
 		if (new_logical != logical) {
 			btrfs_free_chunk_map(map);
@@ -7350,7 +7352,7 @@ int btrfs_map_block(struct btrfs_fs_info *fs_info, enum btrfs_map_op op,
 	map_offset = logical - map->start;
 	io_geom.raid56_full_stripe_start = (u64)-1;
 	max_len = btrfs_max_io_len(map, map_offset, &io_geom);
-	*length = min_t(u64, map->chunk_len - map_offset, max_len);
+	*length = min3(map->chunk_len - map_offset, max_len, remap_len);
 	io_geom.use_rst = btrfs_need_stripe_tree_update(fs_info, map->type);
 
 	if (dev_replace->replace_task != current)

---
base-commit: 2637bdec0535a2044cd830eba9a79363651d9043
change-id: 20261103-btrfs-remap-tree-read-boundary-503b3dd63849

Best regards,
--  
Dhruva Gole <goledhruva@gmail.com>

