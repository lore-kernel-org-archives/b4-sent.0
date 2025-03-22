From: Julian Stecklina <julian.stecklina@cyberus-technology.de>
Date: Sat, 22 Mar 2025 21:34:19 +0100
Subject: [PATCH v2 7/9] fs: squashfs: register an initrd fs detector
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250322-initrd-erofs-v2-7-d66ee4a2c756@cyberus-technology.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742675713; l=3201;
 i=julian.stecklina@cyberus-technology.de; s=20250320;
 h=from:subject:message-id; bh=zysxuXEy456UHMgFgfSEAGox0ynSn0NVemXDz0PKiSU=;
 b=nZrNbSLcFivZ71KUl0X/nNQRHCoVKonroEdGfu+uTmwQBjJeOyVqHGkumj6SPGTNn0sy1YrD3
 ejVMVfXX5AHAbW52Bbp6N3qM1+EdspO5bbB9w5pauYrKxkHm/r0zGG2
X-Developer-Key: i=julian.stecklina@cyberus-technology.de; a=ed25519;
 pk=m051/8gQfs5AmkACfykwRcD6CUr2T7DQ9OA5eBgyy7c=
X-Endpoint-Received: by B4 Relay for julian.stecklina@cyberus-technology.de/20250320 with auth_id=363
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Port squashfs from to the new initrd_fs_detect API. There are no
functional changes.

Signed-off-by: Julian Stecklina <julian.stecklina@cyberus-technology.de>
---
 fs/squashfs/Makefile |  5 +++++
 fs/squashfs/initrd.c | 23 +++++++++++++++++++++++
 init/do_mounts_rd.c  | 14 --------------
 3 files changed, 28 insertions(+), 14 deletions(-)

diff --git a/fs/squashfs/Makefile b/fs/squashfs/Makefile
index 477c89a519ee8825e4dfc88f76e09fd733e90625..fa64f0b9a45e52e9b3e78bd16446474c0b3dc158 100644
--- a/fs/squashfs/Makefile
+++ b/fs/squashfs/Makefile
@@ -17,3 +17,8 @@ squashfs-$(CONFIG_SQUASHFS_LZO) += lzo_wrapper.o
 squashfs-$(CONFIG_SQUASHFS_XZ) += xz_wrapper.o
 squashfs-$(CONFIG_SQUASHFS_ZLIB) += zlib_wrapper.o
 squashfs-$(CONFIG_SQUASHFS_ZSTD) += zstd_wrapper.o
+
+# If we are built-in, we provide support for squashfs on initrds.
+ifeq ($(CONFIG_SQUASHFS),y)
+squashfs-y += initrd.o
+endif
diff --git a/fs/squashfs/initrd.c b/fs/squashfs/initrd.c
new file mode 100644
index 0000000000000000000000000000000000000000..bb99fc40083c6c5fdf47b2e28bcdc525d36520b4
--- /dev/null
+++ b/fs/squashfs/initrd.c
@@ -0,0 +1,23 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+#include <linux/initrd.h>
+#include <linux/fs.h>
+#include <linux/magic.h>
+
+#include "squashfs_fs.h"
+
+static size_t __init detect_squashfs(void *block_data)
+{
+	struct squashfs_super_block *squashfsb
+		= (struct squashfs_super_block *)block_data;
+	BUILD_BUG_ON(sizeof(*squashfsb) > BLOCK_SIZE);
+
+		/* squashfs is at block zero too */
+	if (le32_to_cpu(squashfsb->s_magic) != SQUASHFS_MAGIC)
+		return 0;
+
+
+	return le64_to_cpu(squashfsb->bytes_used);
+}
+
+initrd_fs_detect(detect_squashfs, 0);
diff --git a/init/do_mounts_rd.c b/init/do_mounts_rd.c
index 9f9a04cce505e532d444e2aef77037bc2b01da08..2a6cb08d0b4872ef8e861a813ef89dc1e9a150af 100644
--- a/init/do_mounts_rd.c
+++ b/init/do_mounts_rd.c
@@ -8,7 +8,6 @@
 #include <linux/slab.h>
 
 #include "do_mounts.h"
-#include "../fs/squashfs/squashfs_fs.h"
 
 #include <linux/decompress/generic.h>
 
@@ -41,7 +40,6 @@ static int __init crd_load(decompress_fn deco);
  *
  * We currently check for the following magic numbers:
  *	ext2
- *	squashfs
  *	gzip
  *	bzip2
  *	lzma
@@ -55,7 +53,6 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 {
 	const int size = BLOCK_SIZE;
 
-	struct squashfs_super_block *squashfsb;
 	int nblocks = -1;
 	unsigned char *buf;
 	const char *compress_name;
@@ -67,7 +64,6 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 	if (!buf)
 		return -ENOMEM;
 
-	squashfsb = (struct squashfs_super_block *) buf;
 	memset(buf, 0xe5, size);
 
 	/*
@@ -88,16 +84,6 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 		goto done;
 	}
 
-	/* squashfs is at block zero too */
-	if (le32_to_cpu(squashfsb->s_magic) == SQUASHFS_MAGIC) {
-		printk(KERN_NOTICE
-		       "RAMDISK: squashfs filesystem found at block %d\n",
-		       start_block);
-		nblocks = (le64_to_cpu(squashfsb->bytes_used) + BLOCK_SIZE - 1)
-			 >> BLOCK_SIZE_BITS;
-		goto done;
-	}
-
 	/*
 	 * Read block 1 to test for ext2 superblock
 	 */

-- 
2.47.0

