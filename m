From: Julian Stecklina <julian.stecklina@cyberus-technology.de>
Date: Sat, 22 Mar 2025 21:34:16 +0100
Subject: [PATCH v2 4/9] fs: minix: register an initrd fs detector
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250322-initrd-erofs-v2-4-d66ee4a2c756@cyberus-technology.de>
References: <20250322-initrd-erofs-v2-0-d66ee4a2c756@cyberus-technology.de>
In-Reply-To: <20250322-initrd-erofs-v2-0-d66ee4a2c756@cyberus-technology.de>
To: Christoph Hellwig <hch@lst.de>, Al Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>
Cc: Linus Torvalds <torvalds@linux-foundation.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Gao Xiang <xiang@kernel.org>, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-erofs@lists.ozlabs.org, 
 Julian Stecklina <julian.stecklina@cyberus-technology.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742675713; l=3689;
 i=julian.stecklina@cyberus-technology.de; s=20250320;
 h=from:subject:message-id; bh=3zpODlrg8j0+m1aMvTBZ6a+FkLj5kE2s9qVHm6gavTI=;
 b=RK7CpwXGolb7amFsuhped3Wg2O4qk4HHkEiGLZYmGhlRWSGT/c3+VOQSXeOamqt73w1pTHf3Y
 GLNFj/9f0xZBXTeTlTZiA+v9cdaZ2Z+AAbSKnSXLqW7gkN2jrLUNoqM
X-Developer-Key: i=julian.stecklina@cyberus-technology.de; a=ed25519;
 pk=m051/8gQfs5AmkACfykwRcD6CUr2T7DQ9OA5eBgyy7c=
X-Endpoint-Received: by B4 Relay for julian.stecklina@cyberus-technology.de/20250320 with auth_id=363
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Port minix to the new initrd_fs_detect API. There are no functional
changes.

This code only supports the minix filesystem v1. This means 64 MiB
filesystem size limit. This would be a good candidate to drop support
for.

Signed-off-by: Julian Stecklina <julian.stecklina@cyberus-technology.de>
---
 fs/minix/Makefile   |  5 +++++
 fs/minix/initrd.c   | 23 +++++++++++++++++++++++
 init/do_mounts_rd.c | 16 +---------------
 3 files changed, 29 insertions(+), 15 deletions(-)

diff --git a/fs/minix/Makefile b/fs/minix/Makefile
index a2d3ab58d1873eeada679a33a65b6cd0c421b3ad..cdd6a1a5b57a0205a1946faa676994c367380c97 100644
--- a/fs/minix/Makefile
+++ b/fs/minix/Makefile
@@ -6,3 +6,8 @@
 obj-$(CONFIG_MINIX_FS) += minix.o
 
 minix-objs := bitmap.o itree_v1.o itree_v2.o namei.o inode.o file.o dir.o
+
+# If we are built-in, we provide support for minix filesystem on initrds.
+ifeq ($(CONFIG_MINIX_FS),y)
+minix-objs += initrd.o
+endif
diff --git a/fs/minix/initrd.c b/fs/minix/initrd.c
new file mode 100644
index 0000000000000000000000000000000000000000..18b39b9afe9994ec3dd9770eb516f9c25c183140
--- /dev/null
+++ b/fs/minix/initrd.c
@@ -0,0 +1,23 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+#include <linux/fs.h>
+#include <linux/initrd.h>
+#include <linux/magic.h>
+#include <linux/minix_fs.h>
+
+static size_t __init detect_minixfs(void *block_data)
+{
+	struct minix_super_block *minixsb =
+		(struct minix_super_block *)block_data;
+	BUILD_BUG_ON(sizeof(*minixsb) > BLOCK_SIZE);
+
+	if (minixsb->s_magic != MINIX_SUPER_MAGIC &&
+	    minixsb->s_magic != MINIX_SUPER_MAGIC2)
+		return 0;
+
+
+	return minixsb->s_nzones
+		<< (minixsb->s_log_zone_size + BLOCK_SIZE_BITS);
+}
+
+initrd_fs_detect(detect_minixfs, BLOCK_SIZE);
diff --git a/init/do_mounts_rd.c b/init/do_mounts_rd.c
index 56c1fa935c7ee780870142923046a3d2fd2d6d96..f7e5d4ccf029b2707bc8524ecdbe200c8b305b00 100644
--- a/init/do_mounts_rd.c
+++ b/init/do_mounts_rd.c
@@ -1,7 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0
 #include <linux/kernel.h>
 #include <linux/fs.h>
-#include <linux/minix_fs.h>
 #include <linux/ext2_fs.h>
 #include <linux/romfs_fs.h>
 #include <uapi/linux/cramfs_fs.h>
@@ -42,7 +41,6 @@ static int __init crd_load(decompress_fn deco);
  * numbers could not be found.
  *
  * We currently check for the following magic numbers:
- *	minix
  *	ext2
  *	romfs
  *	cramfs
@@ -59,7 +57,6 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 		decompress_fn *decompressor)
 {
 	const int size = BLOCK_SIZE;
-	struct minix_super_block *minixsb;
 	struct romfs_super_block *romfsb;
 	struct cramfs_super *cramfsb;
 	struct squashfs_super_block *squashfsb;
@@ -74,7 +71,6 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 	if (!buf)
 		return -ENOMEM;
 
-	minixsb = (struct minix_super_block *) buf;
 	romfsb = (struct romfs_super_block *) buf;
 	cramfsb = (struct cramfs_super *) buf;
 	squashfsb = (struct squashfs_super_block *) buf;
@@ -141,21 +137,11 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 	}
 
 	/*
-	 * Read block 1 to test for minix and ext2 superblock
+	 * Read block 1 to test for ext2 superblock
 	 */
 	pos = (start_block + 1) * BLOCK_SIZE;
 	kernel_read(file, buf, size, &pos);
 
-	/* Try minix */
-	if (minixsb->s_magic == MINIX_SUPER_MAGIC ||
-	    minixsb->s_magic == MINIX_SUPER_MAGIC2) {
-		printk(KERN_NOTICE
-		       "RAMDISK: Minix filesystem found at block %d\n",
-		       start_block);
-		nblocks = minixsb->s_nzones << minixsb->s_log_zone_size;
-		goto done;
-	}
-
 	/* Try ext2 */
 	n = ext2_image_size(buf);
 	if (n) {

-- 
2.47.0

