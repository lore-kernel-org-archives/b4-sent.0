From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 03 Nov 2026 15:29:32 +0900
Subject: [PATCH v2 2/3] erofs: treat files shared by inode_share as stacked
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-erofs-fileio-bioset-v2-2-5b91af423f72@samsung.com>
References: <20261103-erofs-fileio-bioset-v2-0-5b91af423f72@samsung.com>
In-Reply-To: <20261103-erofs-fileio-bioset-v2-0-5b91af423f72@samsung.com>
To: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>
Cc: Yue Hu <zbestahu@gmail.com>, Jingbo Xu <jefflexu@163.com>, 
 Sandeep Dhavale <dhavale@google.com>, Hongbo Li <hongbohbli@tencent.com>, 
 Chunhai Guo <guochunhai@vivo.com>, linux-erofs@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Sashiko <sashiko-bot@kernel.org>, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793687370; l=2096;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=KxcTgYYaPu5ba+F2AtFEMVGnO9mL8oKwwj4AMcUNn08=;
 b=S2n4lwsiv48b8UmHOXyIuZvRI8taOqLM2WUyGaIMQkzTKbeosLWqY2VLTTxtt3lXybxjk8GeO
 tfdGCvnzh0AAsqQdRw3rYVFSDUmFZHEXvR9Rr4zYg0qWgt80rOcwHju
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A file-backed mount whose image or extra device is on a block-backed
EROFS passes erofs_is_stacked_file(). If inode_share shares that file,
erofs_real_inode() may pick an inode of a file-backed EROFS in the same
domain to read it. File-backed reads then nest in the same task.

Treat files that use erofs_ishare_fops as stacked.

Fixes: 34096ba919fd ("erofs: support unencoded inodes for page cache share")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Link: https://sashiko.dev/#/patchset/20261030-erofs-fileio-bioset-v1-1-caf47adbb3a3@samsung.com
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/erofs/super.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/fs/erofs/super.c b/fs/erofs/super.c
index ee01a5ef85..e92a7fa90a 100644
--- a/fs/erofs/super.c
+++ b/fs/erofs/super.c
@@ -125,9 +125,12 @@ void *erofs_read_metadata(struct super_block *sb, struct erofs_buf *buf,
 /* see the comment in erofs_fc_fill_super() */
 static bool erofs_is_stacked_file(struct file *file)
 {
-	struct super_block *sb = file_inode(file)->i_sb;
+	struct inode *inode = file_inode(file);
+	struct super_block *sb = inode->i_sb;
 
-	return (sb->s_op == &erofs_sops && !sb->s_bdev) || sb->s_stack_depth;
+	return (sb->s_op == &erofs_sops && !sb->s_bdev) || sb->s_stack_depth ||
+	       (IS_ENABLED(CONFIG_EROFS_FS_PAGE_CACHE_SHARE) &&
+		inode->i_fop == &erofs_ishare_fops);
 }
 
 static int erofs_init_device(struct erofs_buf *buf, struct super_block *sb,
@@ -713,6 +716,9 @@ static int erofs_fc_fill_super(struct super_block *sb, struct fs_context *fc)
 		 * EROFS is the only fs supporting file-backed mounts for now.
 		 * It MUST change if another fs plans to support them, which
 		 * may also require adjusting FILESYSTEM_MAX_STACK_DEPTH.
+		 * Files shared by inode_share may be read through a
+		 * file-backed EROFS in the same domain, so treat them as
+		 * stacked too.
 		 */
 		if (erofs_is_stacked_file(sbi->dif0.file)) {
 			erofs_err(sb, "file-backed mounts cannot be applied to stacked fses");

-- 
2.43.0

