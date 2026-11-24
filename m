From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Tue, 24 Nov 2026 23:49:39 +0100
Subject: [PATCH v2 05/11] ntfs: keep delalloc reservations when a cluster
 allocation fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-ntfs-delalloc-fixes-v2-5-f394c800ec03@proton.me>
References: <20261124-b4-ntfs-delalloc-fixes-v2-0-f394c800ec03@proton.me>
In-Reply-To: <20261124-b4-ntfs-delalloc-fixes-v2-0-f394c800ec03@proton.me>
To: Namjae Jeon <linkinjeon@kernel.org>, Hyunchul Lee <hyc.lee@gmail.com>, 
 Baolin Liu <liubaolin12138@163.com>
Cc: Christian Brauner <brauner@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 "Darrick J. Wong" <djwong@kernel.org>, ntfs@lists.linux.dev, 
 linux-fsdevel@vger.kernel.org, linux-xfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Zhan Xusheng <zhanxusheng1024@gmail.com>, 
 stable@vger.kernel.org, Ernest Borowski <ernest.borowski.git@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5991;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=Ll5q/lv6mMUy3lMMuep0U4+NJtbPAmPZTKcpeMqtKPc=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmw2kfoba1KnFa+w/vw9kO3FYpuqyPK+74v33u06bHLe4
 P9k2cs6HaUsDGJcDLJiiiwd/2+E+IR8+7QsTqsPZg4rE8gQBi5OAZjIR1VGhn2C3VLbni4SvVt9
 97vqmdrV625mZlc6l/Y2L+SoMT9Qq8Hwz0omTKHd8eenW2uL2a/0ljncPZ/Xlnvs7/r6IC7OH7x
 fuQA=
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ntfs_cluster_alloc() sets vol->dirty_clusters to 0 when it fails after
the free space check, which in practice means -ENOMEM or -EIO while it
scans the bitmap.  vol->dirty_clusters is the sum of the reservations
of every delalloc run on the volume, and those runs are still there, so
the reset makes statfs() and the next allocations treat the reserved
clusters as free.  Buffered writes then reserve the same clusters a
second time, and writeback of the delayed data later fails with ENOSPC
and loses it.

ntfs_attr_map_cluster() has the converse problem on its own error
paths: once the allocator succeeded for a delalloc run it has taken
that run's reservation, but when the runlist copy, the runlist merge or
the mapping pairs update fails afterwards, the clusters are freed and
the run stays delalloc without a reservation.

Reproducer (fault injection): write 4 MiB to file A without syncing,
then fsync another file with /proc/thread-self/fail-nth set so that the
kvzalloc() in ntfs_cluster_alloc() fails.  statfs() free space jumps
back up by 1025 of the 1028 clusters A holds (4 KiB clusters). Writing a
file of the size statfs() then reports and syncing loses about 4 MiB of
that file's data; on 512 byte, 4 KiB and 64 KiB clusters alike.  Fault
sites after the allocation (the runlist copy in ntfs_attr_map_cluster())
raise the free space by the clusters of the failed request.

Leave vol->dirty_clusters alone when the allocation fails, and hold the
reservation again when ntfs_attr_map_cluster() puts a delalloc run back
after the allocator consumed it, before the clusters are freed, so that
no other writer can reserve them in between.  If freeing them fails too,
the run keeps the clusters and the hold is dropped again.  The error
path after a failed mapping pairs update now returns the error without
also reporting the freed clusters as allocated.

Fixes: 11ccc9107dc4 ("ntfs: update runlist handling and cluster allocator")
Cc: stable@vger.kernel.org
Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 fs/ntfs/attrib.c   | 24 +++++++++++++++++++++++-
 fs/ntfs/lcnalloc.c |  1 -
 2 files changed, 23 insertions(+), 2 deletions(-)

diff --git a/fs/ntfs/attrib.c b/fs/ntfs/attrib.c
index cdac846f37..7711b9df89 100644
--- a/fs/ntfs/attrib.c
+++ b/fs/ntfs/attrib.c
@@ -5428,6 +5428,19 @@ int ntfs_attr_truncate(struct ntfs_inode *ni, const s64 newsize)
 				    HOLES_NO : HOLES_OK);
 }
 
+/*
+ * The allocator has taken the reservation of a delalloc run whose clusters
+ * are about to be freed again, the run staying delalloc: hold the
+ * reservation again first, so that no other writer can reserve the freed
+ * clusters in between.
+ */
+static void ntfs_map_cluster_rehold(struct ntfs_volume *vol, bool was_delalloc,
+				    s64 clu_count)
+{
+	if (was_delalloc)
+		ntfs_hold_dirty_clusters(vol, clu_count);
+}
+
 int ntfs_attr_map_cluster(struct ntfs_inode *ni, s64 vcn_start, s64 *lcn_start,
 		s64 *lcn_count, s64 max_clu_count, bool *balloc, bool update_mp,
 		bool skip_holes)
@@ -5439,6 +5452,7 @@ int ntfs_attr_map_cluster(struct ntfs_inode *ni, s64 vcn_start, s64 *lcn_start,
 	struct runlist_element *old_rl = NULL;
 	s64 vcn = vcn_start, lcn, clu_count;
 	s64 lcn_seek_from = -1;
+	bool was_delalloc;
 	int err = 0;
 	size_t new_rl_count, old_rl_count;
 
@@ -5526,8 +5540,9 @@ int ntfs_attr_map_cluster(struct ntfs_inode *ni, s64 vcn_start, s64 *lcn_start,
 	 * fallocate(), direct I/O or page_mkwrite() have none and must leave
 	 * the reservations of other writers alone.
 	 */
+	was_delalloc = lcn == LCN_DELALLOC;
 	rlc = ntfs_cluster_alloc(vol, vcn, clu_count, lcn_seek_from, DATA_ZONE,
-			false, true, lcn == LCN_DELALLOC);
+			false, true, was_delalloc);
 	if (IS_ERR(rlc)) {
 		err = PTR_ERR(rlc);
 		goto out;
@@ -5541,6 +5556,7 @@ int ntfs_attr_map_cluster(struct ntfs_inode *ni, s64 vcn_start, s64 *lcn_start,
 			 old_rl_count * sizeof(*old_rl), GFP_NOFS);
 	if (!old_rl) {
 		err = -ENOMEM;
+		ntfs_map_cluster_rehold(vol, was_delalloc, clu_count);
 		if (ntfs_cluster_free_from_rl(vol, rlc)) {
 			ntfs_error(vol->sb,
 				   "Failed to free cluster allocation after runlist backup failure.");
@@ -5554,6 +5570,7 @@ int ntfs_attr_map_cluster(struct ntfs_inode *ni, s64 vcn_start, s64 *lcn_start,
 	if (IS_ERR(rl)) {
 		ntfs_error(vol->sb, "Failed to merge runlists");
 		err = PTR_ERR(rl);
+		ntfs_map_cluster_rehold(vol, was_delalloc, clu_count);
 		if (ntfs_cluster_free_from_rl(vol, rlc))
 			ntfs_error(vol->sb, "Failed to free hot clusters.");
 		kvfree(rlc);
@@ -5576,11 +5593,15 @@ int ntfs_attr_map_cluster(struct ntfs_inode *ni, s64 vcn_start, s64 *lcn_start,
 		if (err) {
 			s64 freed;
 
+			ntfs_map_cluster_rehold(vol, was_delalloc, clu_count);
 			freed = ntfs_cluster_free(ni, vcn, clu_count, ctx);
 			if (freed < 0 || freed != clu_count) {
 				ntfs_error(vol->sb,
 					   "Failed to free cluster allocation. Leaving inconsistent metadata.\n");
 				NVolSetErrors(vol);
+				/* The run keeps its clusters: drop the hold again. */
+				if (was_delalloc)
+					ntfs_release_dirty_clusters(vol, clu_count);
 				goto out;
 			}
 
@@ -5598,6 +5619,7 @@ int ntfs_attr_map_cluster(struct ntfs_inode *ni, s64 vcn_start, s64 *lcn_start,
 					   "Failed to restore mapping pairs after allocation rollback.\n");
 				NVolSetErrors(vol);
 			}
+			goto out;
 		}
 	} else {
 		VFS_I(ni)->i_blocks += clu_count << (vol->cluster_size_bits - 9);
diff --git a/fs/ntfs/lcnalloc.c b/fs/ntfs/lcnalloc.c
index 7e00016f42..2fbc24e4c6 100644
--- a/fs/ntfs/lcnalloc.c
+++ b/fs/ntfs/lcnalloc.c
@@ -799,7 +799,6 @@ switch_to_data1_zone:		search_zone = 2;
 	} else if (err == -ENOSPC)
 		ntfs_debug("No space left at all, err = -ENOSPC, first free lcn = 0x%llx.",
 				vol->data1_zone_pos);
-	atomic64_set(&vol->dirty_clusters, 0);
 
 out_restore:
 	up_write(&vol->lcnbmp_lock);

-- 
2.56.1

