From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 08 Oct 2026 10:25:37 +0900
Subject: [PATCH v2 2/2] ext4: track zeroed out blocks of unwritten extents
 for fast commit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-ext4-fc-zeroout-v2-2-55cab1e24fa3@samsung.com>
References: <20261008-ext4-fc-zeroout-v2-0-55cab1e24fa3@samsung.com>
In-Reply-To: <20261008-ext4-fc-zeroout-v2-0-55cab1e24fa3@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791422735; l=10967;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=EeLJb4AxMmh8sz/efAgzNlx+RL+D3/GJIG/OmAOBA5k=;
 b=Ls/MyUSqGBiUQSTqKPebNNKw+R1C6Y5tcJBbPHKSTtOejoBOyJ2c+zK2XH2JtHZ3R9MBl7h10
 Uz/HHOhNjcJBhHkeH0XxQdDzw5Elow1ziQ4/Q/bmWEI/evttXg0L/g/
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When ext4_ext_convert_to_initialized() converts part of an unwritten
extent, it may zero out the blocks before and after that range (a side
only if it fits together with the range in s_extent_max_zeroout_kb,
32 KiB by default, and the extent ends within i_disksize or the write)
and convert them to written together with it, instead of splitting them
off. ext4_split_extent() zeroes out the rest of the extent and converts
all of it when a split fails with -ENOSPC, -EDQUOT or -ENOMEM. In both
cases ext4_map_blocks() reports only the mapped range to fast commit, so
the other converted blocks are not tracked.

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

Track the range in ext4_issue_zeroout(), where the zeroes are written,
once the zeroout has succeeded. It takes the handle for that, and so
does ext4_ext_zeroout(). The EXT4_GET_BLOCKS_CONVERT_UNWRITTEN zeroout
in ext4_split_extent_zeroout() and the EXT4_GET_BLOCKS_ZERO one in
ext4_map_create_blocks() zero out the mapped range, which
ext4_map_blocks() tracks anyway.
ext4_alloc_file_blocks() zeroes out without a handle and passes NULL:
ext4_convert_unwritten_extents() right after it tracks the blocks it
converts through ext4_map_blocks(), and blocks that were already
written keep their mapping. The callers with a handle hold i_data_sem,
as fast commit tracking already does when ext4_ext_dirty() changes an
extent kept in the inode (through ext4_mark_inode_dirty()).

Fixes: aa75f4d3daae ("ext4: main fast-commit commit path")
Cc: stable@vger.kernel.org
Suggested-by: Jan Kara <jack@suse.cz>
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/ext4/ext4.h         |  5 +++--
 fs/ext4/ext4_extents.h |  3 ++-
 fs/ext4/extents-test.c |  8 +++++---
 fs/ext4/extents.c      | 31 ++++++++++++++++++++-----------
 fs/ext4/inode.c        | 25 +++++++++++++++++--------
 5 files changed, 47 insertions(+), 25 deletions(-)

diff --git a/fs/ext4/ext4.h b/fs/ext4/ext4.h
index 7fd078de26..f469b3548b 100644
--- a/fs/ext4/ext4.h
+++ b/fs/ext4/ext4.h
@@ -3209,8 +3209,9 @@ extern int ext4_get_projid(struct inode *inode, kprojid_t *projid);
 extern void ext4_da_release_space(struct inode *inode, int to_free);
 extern void ext4_da_update_reserve_space(struct inode *inode,
 					int used, int quota_claim);
-extern int ext4_issue_zeroout(struct inode *inode, ext4_lblk_t lblk,
-			      ext4_fsblk_t pblk, ext4_lblk_t len);
+extern int ext4_issue_zeroout(handle_t *handle, struct inode *inode,
+			      ext4_lblk_t lblk, ext4_fsblk_t pblk,
+			      ext4_lblk_t len);
 
 static inline bool is_special_ino(struct super_block *sb, unsigned long ino)
 {
diff --git a/fs/ext4/ext4_extents.h b/fs/ext4/ext4_extents.h
index ebaf7cc424..f4218ff084 100644
--- a/fs/ext4/ext4_extents.h
+++ b/fs/ext4/ext4_extents.h
@@ -267,7 +267,8 @@ static inline void ext4_idx_store_pblock(struct ext4_extent_idx *ix,
 extern int __ext4_ext_dirty(const char *where, unsigned int line,
 			    handle_t *handle, struct inode *inode,
 			    struct ext4_ext_path *path);
-extern int ext4_ext_zeroout(struct inode *inode, struct ext4_extent *ex);
+extern int ext4_ext_zeroout(handle_t *handle, struct inode *inode,
+			    struct ext4_extent *ex);
 #if IS_ENABLED(CONFIG_EXT4_KUNIT_TESTS)
 extern int ext4_ext_space_root_idx_test(struct inode *inode, int check);
 extern struct ext4_ext_path *ext4_split_convert_extents_test(
diff --git a/fs/ext4/extents-test.c b/fs/ext4/extents-test.c
index bd7795a826..4e205de575 100644
--- a/fs/ext4/extents-test.c
+++ b/fs/ext4/extents-test.c
@@ -180,7 +180,8 @@ ext4_ext_insert_extent_stub(handle_t *handle, struct inode *inode,
 /*
  * We will zeroout the equivalent range in the data area
  */
-static int ext4_ext_zeroout_stub(struct inode *inode, struct ext4_extent *ex)
+static int ext4_ext_zeroout_stub(handle_t *handle, struct inode *inode,
+				 struct ext4_extent *ex)
 {
 	ext4_lblk_t ee_block, off_blk;
 	loff_t ee_len;
@@ -203,8 +204,9 @@ static int ext4_ext_zeroout_stub(struct inode *inode, struct ext4_extent *ex)
 	return 0;
 }
 
-static int ext4_issue_zeroout_stub(struct inode *inode, ext4_lblk_t lblk,
-				   ext4_fsblk_t pblk, ext4_lblk_t len)
+static int ext4_issue_zeroout_stub(handle_t *handle, struct inode *inode,
+				   ext4_lblk_t lblk, ext4_fsblk_t pblk,
+				   ext4_lblk_t len)
 {
 	ext4_lblk_t off_blk;
 	loff_t off_bytes;
diff --git a/fs/ext4/extents.c b/fs/ext4/extents.c
index d65e30f3c1..aa55e7cf26 100644
--- a/fs/ext4/extents.c
+++ b/fs/ext4/extents.c
@@ -3167,17 +3167,18 @@ static void ext4_zeroout_es(struct inode *inode, struct ext4_extent *ex)
 }
 
 /* FIXME!! we need to try to merge to left or right after zero-out  */
-int ext4_ext_zeroout(struct inode *inode, struct ext4_extent *ex)
+int ext4_ext_zeroout(handle_t *handle, struct inode *inode,
+		     struct ext4_extent *ex)
 {
 	ext4_fsblk_t ee_pblock;
 	unsigned int ee_len;
 
-	KUNIT_STATIC_STUB_REDIRECT(ext4_ext_zeroout, inode, ex);
+	KUNIT_STATIC_STUB_REDIRECT(ext4_ext_zeroout, handle, inode, ex);
 
 	ee_len    = ext4_ext_get_actual_len(ex);
 	ee_pblock = ext4_ext_pblock(ex);
-	return ext4_issue_zeroout(inode, le32_to_cpu(ex->ee_block), ee_pblock,
-				  ee_len);
+	return ext4_issue_zeroout(handle, inode, le32_to_cpu(ex->ee_block),
+				  ee_pblock, ee_len);
 }
 
 /*
@@ -3347,7 +3348,8 @@ static int ext4_split_extent_zeroout(handle_t *handle, struct inode *inode,
 			lblk = ee_block;
 			len = map->m_lblk - ee_block;
 			pblk = ext4_ext_pblock(ex);
-			err = ext4_issue_zeroout(inode, lblk, pblk, len);
+			err = ext4_issue_zeroout(handle, inode, lblk, pblk,
+						 len);
 			if (err)
 				/* ZEROOUT failed, just return original error */
 				return err;
@@ -3358,7 +3360,8 @@ static int ext4_split_extent_zeroout(handle_t *handle, struct inode *inode,
 			lblk = map_end;
 			len = ex_end - map_end;
 			pblk = ext4_ext_pblock(ex) + (map_end - ee_block);
-			err = ext4_issue_zeroout(inode, lblk, pblk, len);
+			err = ext4_issue_zeroout(handle, inode, lblk, pblk,
+						 len);
 			if (err)
 				/* ZEROOUT failed, just return original error */
 				return err;
@@ -3377,7 +3380,7 @@ static int ext4_split_extent_zeroout(handle_t *handle, struct inode *inode,
 		lblk = map->m_lblk;
 		len = map->m_len;
 		pblk = ext4_ext_pblock(ex) + (map->m_lblk - ee_block);
-		err = ext4_issue_zeroout(inode, lblk, pblk, len);
+		err = ext4_issue_zeroout(handle, inode, lblk, pblk, len);
 		if (err)
 			/* ZEROOUT failed, just return original error */
 			return err;
@@ -3754,7 +3757,7 @@ ext4_ext_convert_to_initialized(handle_t *handle, struct inode *inode,
 			ext4_ext_store_pblock(&zero_ex1,
 				ext4_ext_pblock(ex) + split_map.m_lblk +
 				split_map.m_len - ee_block);
-			err = ext4_ext_zeroout(inode, &zero_ex1);
+			err = ext4_ext_zeroout(handle, inode, &zero_ex1);
 			if (err) {
 				zero_ex1.ee_len = 0;
 				goto fallback;
@@ -3770,7 +3773,7 @@ ext4_ext_convert_to_initialized(handle_t *handle, struct inode *inode,
 							ee_block);
 				ext4_ext_store_pblock(&zero_ex2,
 						      ext4_ext_pblock(ex));
-				err = ext4_ext_zeroout(inode, &zero_ex2);
+				err = ext4_ext_zeroout(handle, inode, &zero_ex2);
 				if (err) {
 					zero_ex2.ee_len = 0;
 					goto fallback;
@@ -4693,8 +4696,14 @@ static int ext4_alloc_file_blocks(struct file *file, loff_t offset, loff_t len,
 			WARN_ON_ONCE(map.m_lblk + map.m_len >
 				EXT4_B_TO_LBLK(inode, new_size ?: old_size));
 
-			ret = ext4_issue_zeroout(inode, map.m_lblk, map.m_pblk,
-						 map.m_len);
+			/*
+			 * Zeroed out without a handle, see the comment
+			 * on EXT4_GET_BLOCKS_ZERO above. The conversion
+			 * below tracks the blocks it converts for fast
+			 * commit, and written blocks keep their mapping.
+			 */
+			ret = ext4_issue_zeroout(NULL, inode, map.m_lblk,
+						 map.m_pblk, map.m_len);
 			if (unlikely(ret))
 				break;
 
diff --git a/fs/ext4/inode.c b/fs/ext4/inode.c
index 48ef9bb387..618ce271ba 100644
--- a/fs/ext4/inode.c
+++ b/fs/ext4/inode.c
@@ -406,23 +406,32 @@ static int __check_block_validity(struct inode *inode, const char *func,
 	return 0;
 }
 
-int ext4_issue_zeroout(struct inode *inode, ext4_lblk_t lblk, ext4_fsblk_t pblk,
-		       ext4_lblk_t len)
+/*
+ * The zeroes written here are file data. With a @handle the range is tracked
+ * for fast commit, because some callers zero out blocks outside the range that
+ * ext4_map_blocks() tracks and convert them to written. A caller without a
+ * handle must make sure that the conversion tracks the range.
+ */
+int ext4_issue_zeroout(handle_t *handle, struct inode *inode, ext4_lblk_t lblk,
+		       ext4_fsblk_t pblk, ext4_lblk_t len)
 {
 	int ret;
 
-	KUNIT_STATIC_STUB_REDIRECT(ext4_issue_zeroout, inode, lblk, pblk, len);
+	KUNIT_STATIC_STUB_REDIRECT(ext4_issue_zeroout, handle, inode, lblk, pblk,
+				   len);
 
 	if (IS_ENCRYPTED(inode) && S_ISREG(inode->i_mode))
-		return fscrypt_zeroout_range(inode,
+		ret = fscrypt_zeroout_range(inode,
 				(loff_t)lblk << inode->i_blkbits,
 				pblk << (inode->i_blkbits - SECTOR_SHIFT),
 				(u64)len << inode->i_blkbits);
-
-	ret = sb_issue_zeroout(inode->i_sb, pblk, len, GFP_NOFS);
+	else
+		ret = sb_issue_zeroout(inode->i_sb, pblk, len, GFP_NOFS);
 	if (ret > 0)
 		ret = 0;
 
+	if (!ret && handle)
+		ext4_fc_track_range(handle, inode, lblk, lblk + len - 1);
 	return ret;
 }
 
@@ -657,8 +666,8 @@ int ext4_map_create_blocks(handle_t *handle, struct inode *inode,
 	 */
 	if (flags & EXT4_GET_BLOCKS_ZERO &&
 	    map->m_flags & EXT4_MAP_MAPPED && map->m_flags & EXT4_MAP_NEW) {
-		err = ext4_issue_zeroout(inode, map->m_lblk, map->m_pblk,
-					 map->m_len);
+		err = ext4_issue_zeroout(handle, inode, map->m_lblk,
+					 map->m_pblk, map->m_len);
 		if (err)
 			return err;
 	}

-- 
2.43.0

