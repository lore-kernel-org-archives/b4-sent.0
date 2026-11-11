From: Mani Tofigh <mt4022@columbia.edu>
Date: Wed, 11 Nov 2026 18:02:47 -0500
Subject: [PATCH 3/3] ext4: fix directory link counts after fast commit
 replay
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-ext4-fc-replay-mkdir-v1-3-4b20be29aed8@columbia.edu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794438165; l=4343;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=ko9jihQar3KC04k0y1s+IAb/JAl7cuqapNyj3EQe9W8=;
 b=pLF4nS+byIWUaB8xt4EXjyOCgmelhl43uGRAj8BFCJFxgSKfonNRmPjwuWpRD3AoANnISTRj3
 Awv9AMvH+7HCnen9i8X+7vQwYezUn2ZCBvEq7XbkHa0L6WZztb1REBo
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After a crash, the fast commit replay of a mkdir leaves the new
directory with one link and its parent with one link too few.  e2fsck
then reports:

  Inode 2 ref count is 3, should be 4.
  Inode 14 ref count is 1, should be 2.

Fast commits don't track directories, so the replay of a CREAT tag has
to redo what ext4_mkdir() does.  ext4_fc_replay_create() sets the
link count of the new inode to 1 even for a directory, and nothing
counts the new ".." in the parent.  The replay of an rmdir has the
opposite problem.  __ext4_unlink() drops only one link of the directory
and the parent keeps the link of the removed "..":

  Inode 2 ref count is 4, should be 3.

Give a new directory 2 links and count it in its parent once its entry
is added.  When an UNLINK tag removes a directory, drop all its links
and one link of the parent like ext4_rmdir() does.  Both halves have to
go together since today a mkdir and an rmdir replayed in sequence
cancel out.

With the fix, e2fsck doesn't find wrong link counts after the replay
anymore.

Fixes: 8016e29f4362 ("ext4: fast commit recovery path")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 fs/ext4/ext4.h        |  2 ++
 fs/ext4/fast_commit.c | 16 ++++++++++++++--
 fs/ext4/namei.c       |  4 ++--
 3 files changed, 18 insertions(+), 4 deletions(-)

diff --git a/fs/ext4/ext4.h b/fs/ext4/ext4.h
index c5044aaddb69..bdba38062e83 100644
--- a/fs/ext4/ext4.h
+++ b/fs/ext4/ext4.h
@@ -3897,6 +3897,8 @@ extern int __ext4_unlink(struct inode *dir, const struct qstr *d_name,
 			 struct inode *inode, struct dentry *dentry);
 extern int __ext4_link(struct inode *dir, struct inode *inode,
 		       const struct qstr *d_name, struct dentry *dentry);
+void ext4_inc_count(struct inode *inode);
+void ext4_dec_count(struct inode *inode);
 
 #define S_SHIFT 12
 static const unsigned char ext4_type_by_mode[(S_IFMT >> S_SHIFT) + 1] = {
diff --git a/fs/ext4/fast_commit.c b/fs/ext4/fast_commit.c
index 9c170986f0b2..3f864ebab1c8 100644
--- a/fs/ext4/fast_commit.c
+++ b/fs/ext4/fast_commit.c
@@ -1824,8 +1824,15 @@ static int ext4_fc_replay_unlink(struct super_block *sb,
 
 	ret = __ext4_unlink(old_parent, &entry, inode, NULL);
 	/* -ENOENT ok coz it might not exist anymore. */
-	if (ret == -ENOENT)
+	if (ret == -ENOENT) {
 		ret = 0;
+	} else if (!ret && S_ISDIR(inode->i_mode)) {
+		/* Like ext4_rmdir(), drop all links of the dir and its ".." */
+		clear_nlink(inode);
+		ext4_mark_inode_dirty(NULL, inode);
+		ext4_dec_count(old_parent);
+		ext4_mark_inode_dirty(NULL, old_parent);
+	}
 	iput(old_parent);
 	iput(inode);
 	return ret;
@@ -1858,6 +1865,11 @@ static int ext4_fc_replay_link_internal(struct super_block *sb,
 		goto out;
 	}
 
+	/* Like ext4_mkdir(), count the new dir's ".." in its parent */
+	if (!ret && S_ISDIR(inode->i_mode)) {
+		ext4_inc_count(dir);
+		ext4_mark_inode_dirty(NULL, dir);
+	}
 	/* The replay allocator doesn't count blocks added to the dir */
 	if (!ret && !ext4_test_inode_flag(dir, EXT4_INODE_INLINE_DATA))
 		ext4_ext_replay_set_iblocks(dir);
@@ -2080,7 +2092,7 @@ static int ext4_fc_replay_create(struct super_block *sb,
 	ret = ext4_fc_replay_link_internal(sb, &darg, inode);
 	if (ret)
 		goto out;
-	set_nlink(inode, 1);
+	set_nlink(inode, S_ISDIR(inode->i_mode) ? 2 : 1);
 	ext4_mark_inode_dirty(NULL, inode);
 out:
 	iput(inode);
diff --git a/fs/ext4/namei.c b/fs/ext4/namei.c
index 354fc2d22df1..7e58f3c609e1 100644
--- a/fs/ext4/namei.c
+++ b/fs/ext4/namei.c
@@ -2758,7 +2758,7 @@ static int ext4_delete_entry(handle_t *handle,
  * for checking S_ISDIR(inode) (since the INODE_INDEX feature will not be set
  * on regular files) and to avoid creating huge/slow non-HTREE directories.
  */
-static void ext4_inc_count(struct inode *inode)
+void ext4_inc_count(struct inode *inode)
 {
 	inc_nlink(inode);
 	if (is_dx(inode) &&
@@ -2770,7 +2770,7 @@ static void ext4_inc_count(struct inode *inode)
  * If a directory had nlink == 1, then we should let it be 1. This indicates
  * directory has >EXT4_LINK_MAX subdirs.
  */
-static void ext4_dec_count(struct inode *inode)
+void ext4_dec_count(struct inode *inode)
 {
 	if (!S_ISDIR(inode->i_mode) || inode->i_nlink > 2)
 		drop_nlink(inode);

-- 
2.53.0

