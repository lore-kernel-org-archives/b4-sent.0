From: Theodore Ts'o <tytso@mit.edu>
Date: Tue, 16 Sep 2025 23:22:47 -0400
Subject: [PATCH v2 1/3] ext4: avoid potential buffer over-read in
 parse_apply_sb_mount_options()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250916-tune2fs-v2-1-d594dc7486f0@mit.edu>
References: <20250916-tune2fs-v2-0-d594dc7486f0@mit.edu>
In-Reply-To: <20250916-tune2fs-v2-0-d594dc7486f0@mit.edu>
To: tytso@mit.edu
Cc: linux-ext4@vger.kernel.org, linux-api@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1761; i=tytso@mit.edu;
 h=from:subject:message-id; bh=Zik1NfPQHpKrfWfZaCNq+zMCfiMzKhxquLerrhs7sjY=;
 b=owEBbQGS/pANAwAIAfL5WVaVDYGjAcsmYgBoyimj5RZcrRoqS+cfvdfvm0LHMTEEiscYuIGLN
 fPLWp6r8K+JATMEAAEIAB0WIQQrablU2/4IeSiBN8ny+VlWlQ2BowUCaMopowAKCRDy+VlWlQ2B
 owvBB/9BJHZ610L/JEl1w3n9Vmz4gQ4lD68ipzubm1Z+9Ya+s8ifOoFaBrIGfQHm589r1Y2Hghh
 sbvmrumDoXmgzvDAH+OdqnoxBCgPcFZxCDvzLHMTnozTANi+M2JrpIMkcbkKvGE+VzbRv2f99j2
 KmVyBoUiNK9LokXIQT8IyYdfoKYdIA1GK73pEHMDMFLtzPBvUZ+AjQmc3AWojqSiHEHRsSBVhov
 O+pO45iq4kcNTnJ/4YIyOAnGLJdhAwMUh09u7dU8/I6gDG8HLTM13ob2wuHq8gJKeOVlWYfgMlh
 +9csVZda7zql9r0G62bUP0e4+c9gTXicAQUIu1V6XqhYIQq9
X-Developer-Key: i=tytso@mit.edu; a=openpgp;
 fpr=3AB057B7E78D945C8C5591FBD36F769BC11804F0
X-Endpoint-Received: by B4 Relay for tytso@mit.edu/default with auth_id=517
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unlike other strings in the ext4 superblock, we rely on tune2fs to
make sure s_mount_opts is NUL terminated.  Harden
parse_apply_sb_mount_options() by treating s_mount_opts as a potential
__nonstring.

Cc: stable@vger.kernel.org
Fixes: 8b67f04ab9de ("ext4: Add mount options in superblock")
Signed-off-by: Theodore Ts'o <tytso@mit.edu>
---
 fs/ext4/super.c | 17 +++++------------
 1 file changed, 5 insertions(+), 12 deletions(-)

diff --git a/fs/ext4/super.c b/fs/ext4/super.c
index 699c15db28a82f26809bf68533454a242596f0fd..94c98446c84f9a4614971d246ca7f001de610a8a 100644
--- a/fs/ext4/super.c
+++ b/fs/ext4/super.c
@@ -2460,7 +2460,7 @@ static int parse_apply_sb_mount_options(struct super_block *sb,
 					struct ext4_fs_context *m_ctx)
 {
 	struct ext4_sb_info *sbi = EXT4_SB(sb);
-	char *s_mount_opts = NULL;
+	char s_mount_opts[65];
 	struct ext4_fs_context *s_ctx = NULL;
 	struct fs_context *fc = NULL;
 	int ret = -ENOMEM;
@@ -2468,15 +2468,11 @@ static int parse_apply_sb_mount_options(struct super_block *sb,
 	if (!sbi->s_es->s_mount_opts[0])
 		return 0;
 
-	s_mount_opts = kstrndup(sbi->s_es->s_mount_opts,
-				sizeof(sbi->s_es->s_mount_opts),
-				GFP_KERNEL);
-	if (!s_mount_opts)
-		return ret;
+	strscpy_pad(s_mount_opts, sbi->s_es->s_mount_opts);
 
 	fc = kzalloc(sizeof(struct fs_context), GFP_KERNEL);
 	if (!fc)
-		goto out_free;
+		return -ENOMEM;
 
 	s_ctx = kzalloc(sizeof(struct ext4_fs_context), GFP_KERNEL);
 	if (!s_ctx)
@@ -2508,11 +2504,8 @@ static int parse_apply_sb_mount_options(struct super_block *sb,
 	ret = 0;
 
 out_free:
-	if (fc) {
-		ext4_fc_free(fc);
-		kfree(fc);
-	}
-	kfree(s_mount_opts);
+	ext4_fc_free(fc);
+	kfree(fc);
 	return ret;
 }
 

-- 
2.51.0

