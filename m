From: Theodore Ts'o <tytso@mit.edu>
Date: Mon, 08 Sep 2025 23:15:48 -0400
Subject: [PATCH 1/3] ext4: avoid potential buffer over-read in
 parse_apply_sb_mount_options()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250908-tune2fs-v1-1-e3a6929f3355@mit.edu>
References: <20250908-tune2fs-v1-0-e3a6929f3355@mit.edu>
In-Reply-To: <20250908-tune2fs-v1-0-e3a6929f3355@mit.edu>
To: tytso@mit.edu
Cc: linux-ext4@vger.kernel.org, linux-api@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1761; i=tytso@mit.edu;
 h=from:subject:message-id; bh=Zik1NfPQHpKrfWfZaCNq+zMCfiMzKhxquLerrhs7sjY=;
 b=owEBbQGS/pANAwAIAfL5WVaVDYGjAcsmYgBov5vlGPsmxg25/2936QiBXqo5LrbMzsXx5+eTP
 uM64RrRXHyJATMEAAEIAB0WIQQrablU2/4IeSiBN8ny+VlWlQ2BowUCaL+b5QAKCRDy+VlWlQ2B
 o74GB/9YF05zTZk+194F0WaTldpxSdRjWm0g1Yq7A6t3+KGENWzoMP48LSQX+/txWWQ5jFYdDaA
 9Tmwrb92gkRrS9RpxjaVXkUgpGXOfnfjDsYKE4iDu2VMNj2Z01jt5IsgbzjCYP76YkSw//wN66z
 cRE97ehAowM9rPrrLpQiVkXTio0J+7W7kEEt0Tp5+r56o0/n38Ocn/RYXflt76YaoV596gC0k4n
 eNq8sM2iVmeteuMqIk6z0vPutHZN3TEiumEUVTXBSAw9zM8kQ9MBBhL8JP+9lMnJODTdwv+GXpy
 aiCUnGUQUO8q+EN+1AMYUw1NH5VtlINJRIXvamoB0AdfbEFp
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

