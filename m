From: Chen Linxuan <chenlinxuan@uniontech.com>
Date: Fri, 09 May 2025 14:33:55 +0800
Subject: [PATCH v3 3/3] fs: fuse: add more information to fdinfo
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250509-fusectl-backing-files-v3-3-393761f9b683@uniontech.com>
References: <20250509-fusectl-backing-files-v3-0-393761f9b683@uniontech.com>
In-Reply-To: <20250509-fusectl-backing-files-v3-0-393761f9b683@uniontech.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Amir Goldstein <amir73il@gmail.com>, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen Linxuan <chenlinxuan@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1981;
 i=chenlinxuan@uniontech.com; h=from:subject:message-id;
 bh=dLLqMK4ZOcnisnxvwBa6DIUP279E8lmWmNnP/Jp8VBc=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBoHaHkSaO7ABqs4yzAz39RKANByQf+JUI3TKu7C
 Sr9++vXnGOJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaB2h5AAKCRB2HuYUOZmu
 iziaD/9E0shRqgXj6Cql0vx0z76dvfJg9D8CviOBAIAbIP77+gnQNU80+QhM5vnDs5si+GCg8xF
 YFi1lTMhWqrw9yoLI0t9ZgIRlMoEbajlekgbCu8Ha3YMZ2LlmBd2CPgzss9YyZE+0/Jf/e70oLT
 Uo4kHGgMrp0S3vkO6Perze84j+PIRJW1il7OS8RTH9rlpCNOccbx2my0sqeX1/7zbKp65D/C7EO
 UIUt7tkOHUUp+aunG4dVa1LwvqzSjrK0YHPm0Ya7Ge9jqqf6YEVWnuzjqG64PMnDwvGMDRMwa6g
 GTkSmW5XfKAdzIuf2OTmbo7dg9qYVrS3TMmNBKcD/X5pIgk/KKfDZXbEj8VVEpT8qw0eDac8Pjz
 o8xYyNDl288/ewh/wBtwG3UkfnNUn/AUAZV6voraVM7BiNOn35h+XDtM57lY814ZPYt+BdfV8o3
 UQZC2loVcEiS5cSfyMJqfxousd+9ISENfKlV/UUlZLe06b+PZyk8QTfNIzSAtqg5eb4RKodKe5v
 odc4SHWLxpODtLOpZBUB/lEktMukIiHNmEb562gtEKFrFwPCLEcJrf3d6WGBVoh8ePZEXAsgu3M
 OH4zFfPmP5iiOXA+h45xkrWInOA2mpdqGK+aVbJFwn0GzRG46rozfHYvxq8z7/YX0iA1xNxLl8+
 rZ+1NF5Xx+Us3gA==
X-Developer-Key: i=chenlinxuan@uniontech.com; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for chenlinxuan@uniontech.com/default with auth_id=380
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit add fuse connection device id, open_flags and backing
files, to fdinfo of opened fuse files.

Related discussions can be found at links below.

Link: https://lore.kernel.org/all/CAOQ4uxgS3OUy9tpphAJKCQFRAn2zTERXXa0QN_KvP6ZOe2KVBw@mail.gmail.com/
Link: https://lore.kernel.org/all/CAOQ4uxgkg0uOuAWO2wOPNkMmD9wqd5wMX+gTfCT-zVHBC8CkZg@mail.gmail.com/
Cc: Amir Goldstein <amir73il@gmail.com>
Signed-off-by: Chen Linxuan <chenlinxuan@uniontech.com>
---
 fs/fuse/file.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/fs/fuse/file.c b/fs/fuse/file.c
index 754378dd9f7159f20fde6376962d45c4c706b868..1e54965780e9d625918c22a3dea48ba5a9a5ed1b 100644
--- a/fs/fuse/file.c
+++ b/fs/fuse/file.c
@@ -8,6 +8,8 @@
 
 #include "fuse_i.h"
 
+#include "linux/idr.h"
+#include "linux/rcupdate.h"
 #include <linux/pagemap.h>
 #include <linux/slab.h>
 #include <linux/kernel.h>
@@ -3392,6 +3394,21 @@ static ssize_t fuse_copy_file_range(struct file *src_file, loff_t src_off,
 	return ret;
 }
 
+static void fuse_file_show_fdinfo(struct seq_file *seq, struct file *f)
+{
+	struct fuse_file *ff = f->private_data;
+	struct fuse_conn *fc = ff->fm->fc;
+	struct file *backing_file = fuse_file_passthrough(ff);
+
+	seq_printf(seq, "fuse conn:%u open_flags:%u\n", fc->dev, ff->open_flags);
+
+	if (backing_file) {
+		seq_puts(seq, "fuse backing_file: ");
+		seq_file_path(seq, backing_file, " \t\n\\");
+		seq_puts(seq, "\n");
+	}
+}
+
 static const struct file_operations fuse_file_operations = {
 	.llseek		= fuse_file_llseek,
 	.read_iter	= fuse_file_read_iter,
@@ -3411,6 +3428,9 @@ static const struct file_operations fuse_file_operations = {
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

