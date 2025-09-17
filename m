From: Theodore Ts'o <tytso@mit.edu>
Date: Tue, 16 Sep 2025 23:22:48 -0400
Subject: [PATCH v2 2/3] ext4: add support for 32-bit default reserved uid
 and gid values
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250916-tune2fs-v2-2-d594dc7486f0@mit.edu>
References: <20250916-tune2fs-v2-0-d594dc7486f0@mit.edu>
In-Reply-To: <20250916-tune2fs-v2-0-d594dc7486f0@mit.edu>
To: tytso@mit.edu
Cc: linux-ext4@vger.kernel.org, linux-api@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3279; i=tytso@mit.edu;
 h=from:subject:message-id; bh=RgbVLDQ1SgNDZyk7YrOPD3panle4KdyrPTxmbmUXY9M=;
 b=owEBbQGS/pANAwAIAfL5WVaVDYGjAcsmYgBoyimkTvFqVyQTwHQR43hpXjOnM9+jcYiLVC9jh
 aODE0IZPpSJATMEAAEIAB0WIQQrablU2/4IeSiBN8ny+VlWlQ2BowUCaMoppAAKCRDy+VlWlQ2B
 o+bKB/9T9TwAmTqrX4URGnx9SuNjJ/3hTBSutYKhwfFDctI5WQ0w26nUZN0X1Mp8vxqttKsB4LJ
 OHZQ7HZGVXrmvsBs5/x19m7aE+svXAD3BtO7bZxhPld1ifDx8DRBfHM/X9xpzV6ZDJq/Q41QH3d
 imDsyv9oqIAF5b4HYs58wwm/JhkVKrDW2PawE5RMYhbVWWRUYulILHqbZA0wsdrLWqHgL4/ReTX
 Ct7N+K5K6kos1L+PuMyUgp8sRBmHGZt2W845PiNZjLcWxn86dWWn/adEM6juY5UyNz8Mq31wmlJ
 /FiEtINhJO/Z5z8hTgRnGK0AFAhGebaa2litDGJ2jPZJGR7N
X-Developer-Key: i=tytso@mit.edu; a=openpgp;
 fpr=3AB057B7E78D945C8C5591FBD36F769BC11804F0
X-Endpoint-Received: by B4 Relay for tytso@mit.edu/default with auth_id=517
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support for specifying the default user id and group id that is
allowed to use the reserved block space was added way back when Linux
only supported 16-bit uid's and gid's.  (Yeah, that long ago.)  It's
not a commonly used feature, but let's add support for 32-bit user and
group id's.

Signed-off-by: Theodore Ts'o <tytso@mit.edu>
---
 fs/ext4/ext4.h  | 16 +++++++++++++++-
 fs/ext4/super.c |  8 ++++----
 2 files changed, 19 insertions(+), 5 deletions(-)

diff --git a/fs/ext4/ext4.h b/fs/ext4/ext4.h
index 01a6e2de7fc3ef0e20b039d3200b9c9bd656f59f..4bfcd5f0c74fda30db4009ee28fbee00a2f6b76f 100644
--- a/fs/ext4/ext4.h
+++ b/fs/ext4/ext4.h
@@ -1442,7 +1442,9 @@ struct ext4_super_block {
 	__le16  s_encoding;		/* Filename charset encoding */
 	__le16  s_encoding_flags;	/* Filename charset encoding flags */
 	__le32  s_orphan_file_inum;	/* Inode for tracking orphan inodes */
-	__le32	s_reserved[94];		/* Padding to the end of the block */
+	__le16	s_def_resuid_hi;
+	__le16	s_def_resgid_hi;
+	__le32	s_reserved[93];		/* Padding to the end of the block */
 	__le32	s_checksum;		/* crc32c(superblock) */
 };
 
@@ -1812,6 +1814,18 @@ static inline int ext4_valid_inum(struct super_block *sb, unsigned long ino)
 		 ino <= le32_to_cpu(EXT4_SB(sb)->s_es->s_inodes_count));
 }
 
+static inline int ext4_get_resuid(struct ext4_super_block *es)
+{
+	return(le16_to_cpu(es->s_def_resuid) |
+	       (le16_to_cpu(es->s_def_resuid_hi) << 16));
+}
+
+static inline int ext4_get_resgid(struct ext4_super_block *es)
+{
+	return(le16_to_cpu(es->s_def_resgid) |
+	       (le16_to_cpu(es->s_def_resgid_hi) << 16));
+}
+
 /*
  * Returns: sbi->field[index]
  * Used to access an array element from the following sbi fields which require
diff --git a/fs/ext4/super.c b/fs/ext4/super.c
index 94c98446c84f9a4614971d246ca7f001de610a8a..0256c8f7c6cee2b8d9295f2fa9a7acd904382e83 100644
--- a/fs/ext4/super.c
+++ b/fs/ext4/super.c
@@ -2951,11 +2951,11 @@ static int _ext4_show_options(struct seq_file *seq, struct super_block *sb,
 	}
 
 	if (nodefs || !uid_eq(sbi->s_resuid, make_kuid(&init_user_ns, EXT4_DEF_RESUID)) ||
-	    le16_to_cpu(es->s_def_resuid) != EXT4_DEF_RESUID)
+	    ext4_get_resuid(es) != EXT4_DEF_RESUID)
 		SEQ_OPTS_PRINT("resuid=%u",
 				from_kuid_munged(&init_user_ns, sbi->s_resuid));
 	if (nodefs || !gid_eq(sbi->s_resgid, make_kgid(&init_user_ns, EXT4_DEF_RESGID)) ||
-	    le16_to_cpu(es->s_def_resgid) != EXT4_DEF_RESGID)
+	    ext4_get_resgid(es) != EXT4_DEF_RESGID)
 		SEQ_OPTS_PRINT("resgid=%u",
 				from_kgid_munged(&init_user_ns, sbi->s_resgid));
 	def_errors = nodefs ? -1 : le16_to_cpu(es->s_errors);
@@ -5270,8 +5270,8 @@ static int __ext4_fill_super(struct fs_context *fc, struct super_block *sb)
 
 	ext4_set_def_opts(sb, es);
 
-	sbi->s_resuid = make_kuid(&init_user_ns, le16_to_cpu(es->s_def_resuid));
-	sbi->s_resgid = make_kgid(&init_user_ns, le16_to_cpu(es->s_def_resgid));
+	sbi->s_resuid = make_kuid(&init_user_ns, ext4_get_resuid(es));
+	sbi->s_resgid = make_kgid(&init_user_ns, ext4_get_resuid(es));
 	sbi->s_commit_interval = JBD2_DEFAULT_MAX_COMMIT_AGE * HZ;
 	sbi->s_min_batch_time = EXT4_DEF_MIN_BATCH_TIME;
 	sbi->s_max_batch_time = EXT4_DEF_MAX_BATCH_TIME;

-- 
2.51.0

