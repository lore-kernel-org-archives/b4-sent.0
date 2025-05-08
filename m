From: Chen Linxuan <chenlinxuan@uniontech.com>
Date: Thu, 08 May 2025 16:53:46 +0800
Subject: [PATCH v2 3/3] fs: fuse: add more information to fdinfo
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250508-fusectl-backing-files-v2-3-62f564e76984@uniontech.com>
References: <20250508-fusectl-backing-files-v2-0-62f564e76984@uniontech.com>
In-Reply-To: <20250508-fusectl-backing-files-v2-0-62f564e76984@uniontech.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Amir Goldstein <amir73il@gmail.com>, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen Linxuan <chenlinxuan@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2386;
 i=chenlinxuan@uniontech.com; h=from:subject:message-id;
 bh=0Usdqy+7Asx6fqMH6X+wT2PYlWAlDQn+W9qv/u/h9TY=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBoHHEuCjLMX1HS7YeEQWeIQNz8go3kor8PXgOov
 RAJI8eO2XKJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaBxxLgAKCRB2HuYUOZmu
 i0zyD/9UEDcvVt5Xc06A8bhf2eIwwEUupq1sIcxxbaFoZPX7gZltpT9hefdEew6/RqyG3GQgzBk
 bICfKPwTw43zc+NDfiPsFT0nuxnXeCq3XPLWgFv9BLSUFF4wr1Yws89ErCvQAnhyAnCMBWfIN76
 NH44o9vGv6BhWUh88IOIzwARwi+4NHGYEDZbz4RC0+oaF+y2I4qX134XiKGvrixDq9iK3kYR+hi
 kqjEVvcKGYK4HKusJGs2WrOIbUdl8XGTfjhdIsx/nJJg4+tP7GqNbNXVOvPhM1sHMGlRePTF0m5
 8SqeHXrQ+FvnFcn6emtJRc7d0llydUETw37wgjpQOAbdyvzuwTeFkHIx7NYPEjYHcdTmzVjF9So
 7rTSc3Dtj/Rh1jKPpR/idITbjTyH0P5FPlbXIK719IK2FLgu0O1rcfFy5tD+lFLi+cWF6MDFSdE
 jhAlHTuTXhVUcLA2qndYSrnv6JmiqkTNUfn49ZUS317QrWMo5tRD1yRho+7PIwLdWnrJxamO9CU
 nCrPB4FyLQAZi/D3VQ2XRpjzSN0fSFqxCowVRlVSV+f6sUOg95yeMkkCbfWXzH2bTIwuhxaEbpp
 081h74V2r+BEJyQnDxNNnNoe30opiOehVLkUbmZb85RMiy6eyWbjzunfUfrRlnJgEl6jSan4RYY
 FVhMxwBmzFuGMbw==
X-Developer-Key: i=chenlinxuan@uniontech.com; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for chenlinxuan@uniontech.com/default with auth_id=380
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit add fuse connection device id and backing_id, if any, to
fdinfo of opened fuse files.

Related discussions can be found at links below.

Link: https://lore.kernel.org/all/CAOQ4uxgS3OUy9tpphAJKCQFRAn2zTERXXa0QN_KvP6ZOe2KVBw@mail.gmail.com/
Cc: Amir Goldstein <amir73il@gmail.com>
Signed-off-by: Chen Linxuan <chenlinxuan@uniontech.com>
---
1. I wonder if we should display fuse connection device id here.

2. I don't think using idr_for_each_entry is a good idea. But I failed
   to find another way to get backing_id of fuse_backing effectively.
---
 fs/fuse/file.c | 34 ++++++++++++++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/fs/fuse/file.c b/fs/fuse/file.c
index 754378dd9f7159f20fde6376962d45c4c706b868..5cfb806aa5cd22c57814168eb33de77c6f213da0 100644
--- a/fs/fuse/file.c
+++ b/fs/fuse/file.c
@@ -8,6 +8,8 @@
 
 #include "fuse_i.h"
 
+#include "linux/idr.h"
+#include "linux/rcupdate.h"
 #include <linux/pagemap.h>
 #include <linux/slab.h>
 #include <linux/kernel.h>
@@ -3392,6 +3394,35 @@ static ssize_t fuse_copy_file_range(struct file *src_file, loff_t src_off,
 	return ret;
 }
 
+static void fuse_file_show_fdinfo(struct seq_file *m, struct file *f)
+{
+	struct fuse_file *ff = f->private_data;
+	struct fuse_conn *fc = ff->fm->fc;
+	struct fuse_inode *fi = get_fuse_inode(file_inode(f));
+
+	seq_printf(m, "fuse_conn:\t%u\n", fc->dev);
+
+#ifdef CONFIG_FUSE_PASSTHROUGH
+	struct fuse_backing *fb;
+	struct fuse_backing *backing;
+	int backing_id;
+
+	if (ff->open_flags & FOPEN_PASSTHROUGH) {
+		fb = fuse_inode_backing(fi);
+		if (fb) {
+			rcu_read_lock();
+			idr_for_each_entry(&fc->backing_files_map, backing, backing_id) {
+				if (backing == fb) {
+					seq_printf(m, "fuse_backing_id:\t%d\n", backing_id);
+					break;
+				}
+			}
+			rcu_read_unlock();
+		}
+	}
+#endif
+}
+
 static const struct file_operations fuse_file_operations = {
 	.llseek		= fuse_file_llseek,
 	.read_iter	= fuse_file_read_iter,
@@ -3411,6 +3442,9 @@ static const struct file_operations fuse_file_operations = {
 	.poll		= fuse_file_poll,
 	.fallocate	= fuse_file_fallocate,
 	.copy_file_range = fuse_copy_file_range,
+#ifdef CONFIG_PROC_FS
+	.show_fdinfo	= fuse_file_show_fdinfo,
+#endif
 };
 
 static const struct address_space_operations fuse_file_aops  = {

-- 
2.43.0

