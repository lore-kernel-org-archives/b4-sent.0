From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 07 Oct 2026 09:41:21 +0900
Subject: [PATCH 2/2] ext4: track zeroed out blocks of unwritten extents for
 fast commit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261007-ext4-fc-zeroout-v1-2-b86de6439431@samsung.com>
References: <20261007-ext4-fc-zeroout-v1-0-b86de6439431@samsung.com>
In-Reply-To: <20261007-ext4-fc-zeroout-v1-0-b86de6439431@samsung.com>
To: Theodore Ts'o <tytso@mit.edu>, linux-ext4@vger.kernel.org
Cc: Jan Kara <jack@suse.cz>, Andreas Dilger <adilger.kernel@dilger.ca>, 
 Baokun Li <libaokun@linux.alibaba.com>, 
 Ojaswin Mujoo <ojaswin@linux.ibm.com>, 
 "Ritesh Harjani (IBM)" <ritesh.list@gmail.com>, 
 Zhang Yi <yi.zhang@huawei.com>, Zhang Yi <yi.zhang@huaweicloud.com>, 
 Harshad Shirwadkar <harshadshirwadkar@gmail.com>, Li Chen <me@linux.beauty>, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791333679; l=4004;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=d9SheBZRfYCrMhVNszvP5FRUiKvPyhSXBHKUCm3sE90=;
 b=Oe6J+czpj47YiaLfNZjCZv0tPnykP9GJOHM9ggfO02ilZpNnHomn97vqUrbkn5Hzqa6NXBtc3
 bW0jcDov+XrD0dth0L+cWJBb+DawZSQNDhxwUNKrh/L37CHjfyhAOyl
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When ext4_ext_convert_to_initialized() converts part of an unwritten
extent, it may zero out the blocks before and after that range (a side
only if it fits together with the range in s_extent_max_zeroout_kb,
32 KiB by default, and the extent lies within i_size) and convert them
to written together with it, instead of splitting them off.
ext4_split_extent() zeroes out and converts the whole extent when a
split fails with -ENOSPC, -EDQUOT or -ENOMEM. In both cases
ext4_map_blocks() reports only the mapped range to fast commit, so the
other converted blocks are not tracked.

A later write to one of those blocks overwrites a written block in
place. That changes no mapping and is not tracked either, so the next
fsync is a fast commit that logs the inode but no range for the block.
After a crash, replay starts from the last full commit, where the block
is still part of an unwritten extent, and the fsynced data reads back
as zeroes. Fast commit tracks one [min, max] range per inode, so this
shows only when no other block beyond the zeroed ones was tracked in
the same commit, which makes it easy to miss.

The first conversion runs when writes allocate through ext4_map_blocks()
with EXT4_GET_BLOCKS_CREATE, for example with -o nodelalloc,
-o dioread_lock or DAX. On a 4 KiB block file system made with
-O fast_commit and mounted with -o nodelalloc,commit=60:

  fallocate -l 32k f; sync      # blocks 0-7 unwritten
  write block 0; fsync f        # zeroes out 1-7, tracks only 0
  write block 2; fsync f        # in place, nothing tracked
  crash (kill the VM), mount    # fast commit replay
  block 2 reads back as zeroes

Track the zeroed out blocks in ext4_zeroout_es(), and the whole extent
in ext4_split_extent_zeroout() when it converts one to written. Both run
under i_data_sem, as fast commit tracking already does when
ext4_ext_dirty() changes an extent kept in the inode (through
ext4_mark_inode_dirty()).

Fixes: aa75f4d3daae ("ext4: main fast-commit commit path")
Cc: stable@vger.kernel.org # 7.0.x
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/ext4/extents.c | 21 ++++++++++++++++++---
 1 file changed, 18 insertions(+), 3 deletions(-)

diff --git a/fs/ext4/extents.c b/fs/ext4/extents.c
index d65e30f3c1..3b45b55931 100644
--- a/fs/ext4/extents.c
+++ b/fs/ext4/extents.c
@@ -3149,7 +3149,8 @@ void ext4_ext_release(struct super_block *sb)
 #endif
 }
 
-static void ext4_zeroout_es(struct inode *inode, struct ext4_extent *ex)
+static void ext4_zeroout_es(handle_t *handle, struct inode *inode,
+			    struct ext4_extent *ex)
 {
 	ext4_lblk_t  ee_block;
 	ext4_fsblk_t ee_pblock;
@@ -3164,6 +3165,12 @@ static void ext4_zeroout_es(struct inode *inode, struct ext4_extent *ex)
 
 	ext4_es_insert_extent(inode, ee_block, ee_len, ee_pblock,
 			      EXTENT_STATUS_WRITTEN, false);
+	/*
+	 * The zeroed out blocks became written together with the mapped
+	 * range, but ext4_map_blocks() reports only the mapped range to fast
+	 * commit.
+	 */
+	ext4_fc_track_range(handle, inode, ee_block, ee_block + ee_len - 1);
 }
 
 /* FIXME!! we need to try to merge to left or right after zero-out  */
@@ -3400,6 +3407,14 @@ static int ext4_split_extent_zeroout(handle_t *handle, struct inode *inode,
 	if (err)
 		return err;
 
+	/*
+	 * The whole extent is written now, not only the range in @map that
+	 * ext4_map_blocks() reports to fast commit.
+	 */
+	if (flags & EXT4_GET_BLOCKS_CONVERT)
+		ext4_fc_track_range(handle, inode, ee_block,
+				    ee_block + ee_len - 1);
+
 	return 0;
 }
 
@@ -3790,8 +3805,8 @@ ext4_ext_convert_to_initialized(handle_t *handle, struct inode *inode,
 		return path;
 out:
 	/* If we have gotten a failure, don't zero out status tree */
-	ext4_zeroout_es(inode, &zero_ex1);
-	ext4_zeroout_es(inode, &zero_ex2);
+	ext4_zeroout_es(handle, inode, &zero_ex1);
+	ext4_zeroout_es(handle, inode, &zero_ex2);
 	return path;
 
 errout:

-- 
2.43.0

