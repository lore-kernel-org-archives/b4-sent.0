From: Julian Stecklina <julian.stecklina@cyberus-technology.de>
Date: Sat, 22 Mar 2025 21:34:18 +0100
Subject: [PATCH v2 6/9] fs: romfs: register an initrd fs detector
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250322-initrd-erofs-v2-6-d66ee4a2c756@cyberus-technology.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742675713; l=3189;
 i=julian.stecklina@cyberus-technology.de; s=20250320;
 h=from:subject:message-id; bh=DjTVlMjJ9fly1JjbbQ1cABQpspedV4SfXIZDQ9hYyJw=;
 b=bYQM009Se+/99LClCNXj1HPpoPjNjrjKzdTybPVuJsdmCzDLeuSC5fNA+iESxAR+1ZgnWKYDX
 Ev6I3qHnmlqAj9w8p+pdBCatDMx3r8QKy5KB7shQWM2fafgd9gjbT/5
X-Developer-Key: i=julian.stecklina@cyberus-technology.de; a=ed25519;
 pk=m051/8gQfs5AmkACfykwRcD6CUr2T7DQ9OA5eBgyy7c=
X-Endpoint-Received: by B4 Relay for julian.stecklina@cyberus-technology.de/20250320 with auth_id=363
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Port romfs from to the new initrd_fs_detect API. There are no
functional changes.

Signed-off-by: Julian Stecklina <julian.stecklina@cyberus-technology.de>
---
 fs/romfs/Makefile   |  4 ++++
 fs/romfs/initrd.c   | 22 ++++++++++++++++++++++
 init/do_mounts_rd.c | 14 --------------
 3 files changed, 26 insertions(+), 14 deletions(-)

diff --git a/fs/romfs/Makefile b/fs/romfs/Makefile
index 844928f1571160abed9d5aff54152b5508eaf7be..eb15dc3a78721d7f650560a404a92706260e9b63 100644
--- a/fs/romfs/Makefile
+++ b/fs/romfs/Makefile
@@ -11,3 +11,7 @@ ifneq ($(CONFIG_MMU),y)
 romfs-$(CONFIG_ROMFS_ON_MTD) += mmap-nommu.o
 endif
 
+# If we are built-in, we provide support for romfs on initrds.
+ifeq ($(CONFIG_ROMFS_FS),y)
+romfs-y += initrd.o
+endif
diff --git a/fs/romfs/initrd.c b/fs/romfs/initrd.c
new file mode 100644
index 0000000000000000000000000000000000000000..0ec7b4c9d1f79fac892b7fb1d8e17122092008a8
--- /dev/null
+++ b/fs/romfs/initrd.c
@@ -0,0 +1,22 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+#include <linux/fs.h>
+#include <linux/initrd.h>
+#include <linux/magic.h>
+#include <linux/romfs_fs.h>
+
+static size_t __init detect_romfs(void *block_data)
+{
+	struct romfs_super_block *romfsb
+		= (struct romfs_super_block *)block_data;
+	BUILD_BUG_ON(sizeof(*romfsb) > BLOCK_SIZE);
+
+	/* The definitions of ROMSB_WORD* already handle endianness. */
+	if (romfsb->word0 != ROMSB_WORD0 ||
+	    romfsb->word1 != ROMSB_WORD1)
+		return 0;
+
+	return be32_to_cpu(romfsb->size);
+}
+
+initrd_fs_detect(detect_romfs, 0);
diff --git a/init/do_mounts_rd.c b/init/do_mounts_rd.c
index cdc39baaf3a1a65daad5fe6571a82faf3fc95b62..9f9a04cce505e532d444e2aef77037bc2b01da08 100644
--- a/init/do_mounts_rd.c
+++ b/init/do_mounts_rd.c
@@ -2,7 +2,6 @@
 #include <linux/kernel.h>
 #include <linux/fs.h>
 #include <linux/ext2_fs.h>
-#include <linux/romfs_fs.h>
 
 #include <linux/initrd.h>
 #include <linux/string.h>
@@ -42,7 +41,6 @@ static int __init crd_load(decompress_fn deco);
  *
  * We currently check for the following magic numbers:
  *	ext2
- *	romfs
  *	squashfs
  *	gzip
  *	bzip2
@@ -56,7 +54,6 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 		decompress_fn *decompressor)
 {
 	const int size = BLOCK_SIZE;
-	struct romfs_super_block *romfsb;
 
 	struct squashfs_super_block *squashfsb;
 	int nblocks = -1;
@@ -70,7 +67,6 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 	if (!buf)
 		return -ENOMEM;
 
-	romfsb = (struct romfs_super_block *) buf;
 	squashfsb = (struct squashfs_super_block *) buf;
 	memset(buf, 0xe5, size);
 
@@ -92,16 +88,6 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 		goto done;
 	}
 
-	/* romfs is at block zero too */
-	if (romfsb->word0 == ROMSB_WORD0 &&
-	    romfsb->word1 == ROMSB_WORD1) {
-		printk(KERN_NOTICE
-		       "RAMDISK: romfs filesystem found at block %d\n",
-		       start_block);
-		nblocks = (ntohl(romfsb->size)+BLOCK_SIZE-1)>>BLOCK_SIZE_BITS;
-		goto done;
-	}
-
 	/* squashfs is at block zero too */
 	if (le32_to_cpu(squashfsb->s_magic) == SQUASHFS_MAGIC) {
 		printk(KERN_NOTICE

-- 
2.47.0

