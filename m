From: Mani Tofigh <mt4022@columbia.edu>
Date: Wed, 11 Nov 2026 18:02:46 -0500
Subject: [PATCH 2/3] ext4: fix directory i_blocks after fast commit replay
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-ext4-fc-replay-mkdir-v1-2-4b20be29aed8@columbia.edu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794438165; l=1920;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=A5ACAB6Z0i4TBNy9KhffX8CQhE5dPPIFkDuhFNEF+7c=;
 b=z5Kta/OwhshDxOiEjtidL+vwkayVVceG47GP/Sq70YARwqVC6VvEdzAqCqaoQi9sPNaXycTMO
 Cq6o2Z+Ja+/BsmSoWd0wocqDDzIyu5dVzlZQKiGjf7XdG0aULKBSA55
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After a crash, a directory created by the fast commit replay has an
i_blocks of 0.  e2fsck reports:

  Inode 14, i_blocks is 0, should be 8.

The same happens to a directory that gets new blocks while the replay
adds entries to it, e.g., a new directory that got many files in the
same fast commit:

  Inode 14, i_blocks is 8, should be 24.

Fast commits don't track directories.  The replay allocates their
blocks in ext4_init_new_dir() and __ext4_link() through
ext4_mb_new_blocks_simple(), which leaves i_blocks alone.  For regular
files ext4_fc_replay_inode() recounts i_blocks with
ext4_ext_replay_set_iblocks().  Nothing does that for directories.

Recount i_blocks of the new directory after ext4_init_new_dir() and of
the parent after a new entry is added.

With the fix, e2fsck doesn't find a wrong i_blocks after the replay
anymore.

Fixes: 8016e29f4362 ("ext4: fast commit recovery path")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 fs/ext4/fast_commit.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/fs/ext4/fast_commit.c b/fs/ext4/fast_commit.c
index 0eac7be3f58c..9c170986f0b2 100644
--- a/fs/ext4/fast_commit.c
+++ b/fs/ext4/fast_commit.c
@@ -1858,6 +1858,9 @@ static int ext4_fc_replay_link_internal(struct super_block *sb,
 		goto out;
 	}
 
+	/* The replay allocator doesn't count blocks added to the dir */
+	if (!ret && !ext4_test_inode_flag(dir, EXT4_INODE_INLINE_DATA))
+		ext4_ext_replay_set_iblocks(dir);
 	ret = 0;
 out:
 	if (dir)
@@ -2070,6 +2073,9 @@ static int ext4_fc_replay_create(struct super_block *sb,
 			ret = 0;
 			goto out;
 		}
+		/* The replay allocator doesn't count the new dir block */
+		if (!ext4_test_inode_flag(inode, EXT4_INODE_INLINE_DATA))
+			ext4_ext_replay_set_iblocks(inode);
 	}
 	ret = ext4_fc_replay_link_internal(sb, &darg, inode);
 	if (ret)

-- 
2.53.0

