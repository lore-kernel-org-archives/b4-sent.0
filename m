From: Daejun Park <daejun7.park@samsung.com>
Date: Fri, 30 Oct 2026 12:52:44 +0900
Subject: [PATCH] erofs: apply the stacked fs check to extra file-backed
 devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-erofs-stacked-extra-devices-v1-1-39f7df7ac01b@samsung.com>
X-B4-Tracking: v=1; b=H4sIAIsU5GoC/x3MQQqDQAxA0atI1g1MRrGlV5EuwiTaUNCSiAji3
 R1cvsX/B4S6acC7OcB1s7BlrqBHA+XL86RoUg055Z5SfqH6MgbGyuWngrqvzig1LBooT6aOhBO
 1LdTD33W0/b4Pn/O8AHOgu11tAAAA
To: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>
Cc: Yue Hu <zbestahu@gmail.com>, Jingbo Xu <jefflexu@163.com>, 
 Sandeep Dhavale <dhavale@google.com>, Hongbo Li <hongbohbli@tencent.com>, 
 Chunhai Guo <guochunhai@vivo.com>, linux-erofs@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793332363; l=2715;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=ewjS8koWFn8Z4rafq/egOLIaNXTnJqYTfaJQKrbMB9s=;
 b=Bxud52oBS6RR96umz1PtXO37YvER3b+2EfdcZL8t9uPHVWsq+/Uz3ePCKWAOKbZTXGR7NGnva
 nFn3KIa7gzFAP/HdYKb9DQZFWkBJqKLaV5LyPa3JI2b8LA9yVJcSgKT
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

erofs_fc_fill_super() rejects a file-backed mount whose image is on a
file-backed EROFS or on a filesystem with s_stack_depth set. This
bounds the nesting of reads. Extra devices given by device= are not
checked. File-backed mounts can still nest through them without limit.

Apply the same check to extra devices.

Fixes: fb176750266a ("erofs: add file-backed mount support")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested on erofs dev in a QEMU guest with KASAN and lockdep:

- Blobs on a file-backed EROFS or overlayfs now get -EINVAL.

- Blobs on XFS or a loop-mounted EROFS still mount and read back.

- Lockdep warns about devs->rwsem vs i_rwsem for a device= path inside
  an EROFS mount, with or without this patch.
---
 fs/erofs/super.c | 17 ++++++++++++++---
 1 file changed, 14 insertions(+), 3 deletions(-)

diff --git a/fs/erofs/super.c b/fs/erofs/super.c
index ce05557bd9..ee01a5ef85 100644
--- a/fs/erofs/super.c
+++ b/fs/erofs/super.c
@@ -122,6 +122,14 @@ void *erofs_read_metadata(struct super_block *sb, struct erofs_buf *buf,
 	return buffer;
 }
 
+/* see the comment in erofs_fc_fill_super() */
+static bool erofs_is_stacked_file(struct file *file)
+{
+	struct super_block *sb = file_inode(file)->i_sb;
+
+	return (sb->s_op == &erofs_sops && !sb->s_bdev) || sb->s_stack_depth;
+}
+
 static int erofs_init_device(struct erofs_buf *buf, struct super_block *sb,
 			     struct erofs_device_info *dif, erofs_off_t *pos)
 {
@@ -161,6 +169,11 @@ static int erofs_init_device(struct erofs_buf *buf, struct super_block *sb,
 		} else if (!S_ISREG(file_inode(file)->i_mode)) {
 			fput(file);
 			return -EINVAL;
+		} else if (erofs_is_stacked_file(file)) {
+			erofs_err(sb, "%s: file-backed devices cannot be on stacked fses",
+				  dif->path);
+			fput(file);
+			return -EINVAL;
 		}
 		if (!dif->dax_dev && test_opt(&sbi->opt, DAX_ALWAYS)) {
 			erofs_info(sb, "DAX unsupported by %s. Turning off DAX.",
@@ -701,9 +714,7 @@ static int erofs_fc_fill_super(struct super_block *sb, struct fs_context *fc)
 		 * It MUST change if another fs plans to support them, which
 		 * may also require adjusting FILESYSTEM_MAX_STACK_DEPTH.
 		 */
-		inode = file_inode(sbi->dif0.file);
-		if ((inode->i_sb->s_op == &erofs_sops &&
-		     !inode->i_sb->s_bdev) || inode->i_sb->s_stack_depth) {
+		if (erofs_is_stacked_file(sbi->dif0.file)) {
 			erofs_err(sb, "file-backed mounts cannot be applied to stacked fses");
 			return -ENOTBLK;
 		}

---
base-commit: 209108a5456171ab430e25b54b2dfe083455bfb6
change-id: 20261028-erofs-stacked-extra-devices-d7a141da0133

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

