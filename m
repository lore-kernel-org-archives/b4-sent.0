From: Mani Tofigh <mt4022@columbia.edu>
Date: Wed, 11 Nov 2026 18:02:45 -0500
Subject: [PATCH 1/3] ext4: fix directory count after fast commit replay
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-ext4-fc-replay-mkdir-v1-1-4b20be29aed8@columbia.edu>
References: <20261111-ext4-fc-replay-mkdir-v1-0-4b20be29aed8@columbia.edu>
In-Reply-To: <20261111-ext4-fc-replay-mkdir-v1-0-4b20be29aed8@columbia.edu>
To: Theodore Ts'o <tytso@mit.edu>
Cc: Andreas Dilger <adilger.kernel@dilger.ca>, 
 Baokun Li <libaokun@linux.alibaba.com>, Jan Kara <jack@suse.cz>, 
 Ojaswin Mujoo <ojaswin@linux.ibm.com>, 
 "Ritesh Harjani (IBM)" <ritesh.list@gmail.com>, 
 Zhang Yi <yi.zhang@huawei.com>, 
 Harshad Shirwadkar <harshadshirwadkar@gmail.com>, 
 linux-ext4@vger.kernel.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794438165; l=3807;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=ImtH9yBJQanvkzGVDZNAzZ+LpPYNZJVGBXslCGNfD/s=;
 b=HvUFeKc3kMmZOzHYzygqp2gE7e20fECTP9LJ3Q3umKkWKVGzVgtoyRAYsCyueVREf94Qtyui+
 RM1mvs7qBqdBPlQ9BDo6JXeNuoY44Pj2JA122NBBUI++U9jnJxloSbx
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After a crash, the fast commit replay of a mkdir leaves the group's
directory count one short.  e2fsck reports:

  Directories count wrong for group #0 (2, counted=3).

The replay marks the inode of an INODE or CREAT tag used with
ext4_mark_inode_used().  That lowers the group's free inode count but
never raises bg_used_dirs_count since the function doesn't know the
inode's mode.

Pass the mode to ext4_mark_inode_used() and count directories there.
The INODE tag of a new directory comes first and does the counting.
ext4_fc_replay_create() now looks up the inode before marking it used
to get its mode.

With the fix, the directory count is right after the replay.

Fixes: 8016e29f4362 ("ext4: fast commit recovery path")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 fs/ext4/ext4.h        |  2 +-
 fs/ext4/fast_commit.c | 12 ++++++------
 fs/ext4/ialloc.c      |  4 +++-
 3 files changed, 10 insertions(+), 8 deletions(-)

diff --git a/fs/ext4/ext4.h b/fs/ext4/ext4.h
index bf0325ecbec7..c5044aaddb69 100644
--- a/fs/ext4/ext4.h
+++ b/fs/ext4/ext4.h
@@ -3059,7 +3059,7 @@ extern int ext4fs_dirhash(const struct inode *dir, const char *name, int len,
 			  struct dx_hash_info *hinfo);
 
 /* ialloc.c */
-extern int ext4_mark_inode_used(struct super_block *sb, int ino);
+int ext4_mark_inode_used(struct super_block *sb, int ino, umode_t mode);
 extern struct inode *__ext4_new_inode(const struct mnt_idmap *, handle_t *,
 				      struct inode *, umode_t,
 				      const struct qstr *qstr, __u32 goal,
diff --git a/fs/ext4/fast_commit.c b/fs/ext4/fast_commit.c
index 0cac890cf370..0eac7be3f58c 100644
--- a/fs/ext4/fast_commit.c
+++ b/fs/ext4/fast_commit.c
@@ -1984,7 +1984,7 @@ static int ext4_fc_replay_inode(struct super_block *sb,
 	ret = sync_dirty_buffer(iloc.bh);
 	if (ret)
 		goto out_brelse;
-	ret = ext4_mark_inode_used(sb, ino);
+	ret = ext4_mark_inode_used(sb, ino, le16_to_cpu(raw_fc_inode->i_mode));
 	if (ret)
 		goto out_brelse;
 
@@ -2041,11 +2041,6 @@ static int ext4_fc_replay_create(struct super_block *sb,
 	trace_ext4_fc_replay(sb, EXT4_FC_TAG_CREAT, darg.ino,
 			darg.parent_ino, darg.dname_len);
 
-	/* This takes care of update group descriptor and other metadata */
-	ret = ext4_mark_inode_used(sb, darg.ino);
-	if (ret)
-		goto out;
-
 	inode = ext4_iget(sb, darg.ino, EXT4_IGET_NORMAL);
 	if (IS_ERR(inode)) {
 		ext4_debug("inode %d not found.", darg.ino);
@@ -2054,6 +2049,11 @@ static int ext4_fc_replay_create(struct super_block *sb,
 		goto out;
 	}
 
+	/* This takes care of update group descriptor and other metadata */
+	ret = ext4_mark_inode_used(sb, darg.ino, inode->i_mode);
+	if (ret)
+		goto out;
+
 	if (S_ISDIR(inode->i_mode)) {
 		/*
 		 * If we are creating a directory, we need to make sure that the
diff --git a/fs/ext4/ialloc.c b/fs/ext4/ialloc.c
index 527f1f703c3e..e29faa8590c6 100644
--- a/fs/ext4/ialloc.c
+++ b/fs/ext4/ialloc.c
@@ -758,7 +758,7 @@ static int find_inode_bit(struct super_block *sb, ext4_group_t group,
 	return 1;
 }
 
-int ext4_mark_inode_used(struct super_block *sb, int ino)
+int ext4_mark_inode_used(struct super_block *sb, int ino, umode_t mode)
 {
 	unsigned long max_ino = le32_to_cpu(EXT4_SB(sb)->s_es->s_inodes_count);
 	struct buffer_head *inode_bitmap_bh = NULL, *group_desc_bh = NULL;
@@ -860,6 +860,8 @@ int ext4_mark_inode_used(struct super_block *sb, int ino)
 	}
 
 	ext4_free_inodes_set(sb, gdp, ext4_free_inodes_count(sb, gdp) - 1);
+	if (S_ISDIR(mode))
+		ext4_used_dirs_set(sb, gdp, ext4_used_dirs_count(sb, gdp) + 1);
 	if (ext4_has_group_desc_csum(sb)) {
 		ext4_inode_bitmap_csum_set(sb, gdp, inode_bitmap_bh);
 		ext4_group_desc_csum_set(sb, group, gdp);

-- 
2.53.0

