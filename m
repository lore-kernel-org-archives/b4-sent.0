From: Julian Stecklina <julian.stecklina@cyberus-technology.de>
Date: Sat, 22 Mar 2025 21:34:17 +0100
Subject: [PATCH v2 5/9] fs: cramfs: register an initrd fs detector
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250322-initrd-erofs-v2-5-d66ee4a2c756@cyberus-technology.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742675713; l=4205;
 i=julian.stecklina@cyberus-technology.de; s=20250320;
 h=from:subject:message-id; bh=T+YHuo2Ev8aOIZof+FXA1HNY64MvcwqvCtTXx1JM/p0=;
 b=RV3KMe/LiD+IsfUYYqELk6OGsa0r5a2gi+Mp3Mt0zAMlzR7vGEW8+fcQxMvwhUxUdHoEwczYQ
 s1kE0Q/P68VBeXE1Z9xP0ClFGrMA10OA9KEhkXMn1ftHbf3Zuk1Tjgg
X-Developer-Key: i=julian.stecklina@cyberus-technology.de; a=ed25519;
 pk=m051/8gQfs5AmkACfykwRcD6CUr2T7DQ9OA5eBgyy7c=
X-Endpoint-Received: by B4 Relay for julian.stecklina@cyberus-technology.de/20250320 with auth_id=363
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Port cramfs to the new initrd_fs_detect API. There are no functional
changes.

Signed-off-by: Julian Stecklina <julian.stecklina@cyberus-technology.de>
---
 fs/cramfs/Makefile  |  5 +++++
 fs/cramfs/initrd.c  | 41 +++++++++++++++++++++++++++++++++++++++++
 init/do_mounts_rd.c | 28 ++--------------------------
 3 files changed, 48 insertions(+), 26 deletions(-)

diff --git a/fs/cramfs/Makefile b/fs/cramfs/Makefile
index 8c3ed298241924b0312fb489b1fb54d274d25c22..d10e2b72aae06bf9ac42690e3967cfd90ac34d4f 100644
--- a/fs/cramfs/Makefile
+++ b/fs/cramfs/Makefile
@@ -6,3 +6,8 @@
 obj-$(CONFIG_CRAMFS) += cramfs.o
 
 cramfs-objs := inode.o uncompress.o
+
+# If we are built-in, we provide support for cramfs on initrds.
+ifeq ($(CONFIG_CRAMFS),y)
+cramfs-objs += initrd.o
+endif
diff --git a/fs/cramfs/initrd.c b/fs/cramfs/initrd.c
new file mode 100644
index 0000000000000000000000000000000000000000..c16df09c118226e6350b9f5877863ef31322ab7b
--- /dev/null
+++ b/fs/cramfs/initrd.c
@@ -0,0 +1,41 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+#include <linux/fs.h>
+#include <linux/initrd.h>
+#include <uapi/linux/cramfs_fs.h>
+
+/*
+ * The filesystem start maybe padded by this many bytes to make space
+ * for boot loaders.
+ */
+#define CRAMFS_PAD_OFFSET 512
+
+static size_t __init check_cramfs_sb(struct cramfs_super *cramfsb)
+{
+	if (cramfsb->magic != CRAMFS_MAGIC)
+		return 0;
+
+	return cramfsb->size;
+}
+
+static size_t __init detect_cramfs(void *block_data)
+{
+	size_t fssize;
+
+	BUILD_BUG_ON(sizeof(struct cramfs_super) + CRAMFS_PAD_OFFSET
+		     > BLOCK_SIZE);
+
+	fssize = check_cramfs_sb((struct cramfs_super *)block_data);
+	if (fssize)
+		return fssize;
+
+	/*
+	 * The header padding doesn't influence the total length of
+	 * the filesystem.
+	 */
+	block_data = (char *)block_data + CRAMFS_PAD_OFFSET;
+	fssize = check_cramfs_sb((struct cramfs_super *)block_data);
+	return fssize;
+}
+
+initrd_fs_detect(detect_cramfs, 0);
diff --git a/init/do_mounts_rd.c b/init/do_mounts_rd.c
index f7e5d4ccf029b2707bc8524ecdbe200c8b305b00..cdc39baaf3a1a65daad5fe6571a82faf3fc95b62 100644
--- a/init/do_mounts_rd.c
+++ b/init/do_mounts_rd.c
@@ -3,7 +3,7 @@
 #include <linux/fs.h>
 #include <linux/ext2_fs.h>
 #include <linux/romfs_fs.h>
-#include <uapi/linux/cramfs_fs.h>
+
 #include <linux/initrd.h>
 #include <linux/string.h>
 #include <linux/slab.h>
@@ -43,7 +43,6 @@ static int __init crd_load(decompress_fn deco);
  * We currently check for the following magic numbers:
  *	ext2
  *	romfs
- *	cramfs
  *	squashfs
  *	gzip
  *	bzip2
@@ -58,7 +57,7 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 {
 	const int size = BLOCK_SIZE;
 	struct romfs_super_block *romfsb;
-	struct cramfs_super *cramfsb;
+
 	struct squashfs_super_block *squashfsb;
 	int nblocks = -1;
 	unsigned char *buf;
@@ -72,7 +71,6 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 		return -ENOMEM;
 
 	romfsb = (struct romfs_super_block *) buf;
-	cramfsb = (struct cramfs_super *) buf;
 	squashfsb = (struct squashfs_super_block *) buf;
 	memset(buf, 0xe5, size);
 
@@ -104,14 +102,6 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 		goto done;
 	}
 
-	if (cramfsb->magic == CRAMFS_MAGIC) {
-		printk(KERN_NOTICE
-		       "RAMDISK: cramfs filesystem found at block %d\n",
-		       start_block);
-		nblocks = (cramfsb->size + BLOCK_SIZE - 1) >> BLOCK_SIZE_BITS;
-		goto done;
-	}
-
 	/* squashfs is at block zero too */
 	if (le32_to_cpu(squashfsb->s_magic) == SQUASHFS_MAGIC) {
 		printk(KERN_NOTICE
@@ -122,20 +112,6 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 		goto done;
 	}
 
-	/*
-	 * Read 512 bytes further to check if cramfs is padded
-	 */
-	pos = start_block * BLOCK_SIZE + 0x200;
-	kernel_read(file, buf, size, &pos);
-
-	if (cramfsb->magic == CRAMFS_MAGIC) {
-		printk(KERN_NOTICE
-		       "RAMDISK: cramfs filesystem found at block %d\n",
-		       start_block);
-		nblocks = (cramfsb->size + BLOCK_SIZE - 1) >> BLOCK_SIZE_BITS;
-		goto done;
-	}
-
 	/*
 	 * Read block 1 to test for ext2 superblock
 	 */

-- 
2.47.0

