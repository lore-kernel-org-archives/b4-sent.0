From: Julian Stecklina <julian.stecklina@cyberus-technology.de>
Date: Thu, 20 Mar 2025 20:28:23 +0100
Subject: [PATCH] initrd: support erofs as initrd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250320-initrd-erofs-v1-1-35bbb293468a@cyberus-technology.de>
X-B4-Tracking: v=1; b=H4sIAFZs3GcC/x3MTQqAIBBA4avIrBPM0H6uEi1Cx5qNxhgRiHdPW
 n6L9wpkZMIMiyjA+FCmFBv6ToA793igJN8MWmmjBq0kRbrZS+QUshwtztoEH+zkoCUXY6D3361
 brR+PanHjXgAAAA==
X-Change-ID: 20250320-initrd-erofs-76e925fdf68c
To: Christoph Hellwig <hch@lst.de>, Al Viro <viro@zeniv.linux.org.uk>, 
 Linus Torvalds <torvalds@linux-foundation.org>
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Julian Stecklina <julian.stecklina@cyberus-technology.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742498907; l=2366;
 i=julian.stecklina@cyberus-technology.de; s=20250320;
 h=from:subject:message-id; bh=BUYkfXvGRCCRkCmYxAvEbgWOurQPuzo1uS6OSJk5+3k=;
 b=Mk1jtb+JY2aUM8xqHbUFACnyzukucXfSGBBvDhBwvkFBoRCp91HLZZ6pKPzlf05wSG4VWpQlu
 aByHBVWECyeDT1y5hGEB87X8eMiRRUZXkQhuoqjxNo//TRDew7IjVA0
X-Developer-Key: i=julian.stecklina@cyberus-technology.de; a=ed25519;
 pk=m051/8gQfs5AmkACfykwRcD6CUr2T7DQ9OA5eBgyy7c=
X-Endpoint-Received: by B4 Relay for julian.stecklina@cyberus-technology.de/20250320 with auth_id=363
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add erofs detection to the initrd mount code. This allows systems to
boot from an erofs-based initrd in the same way as they can boot from
a squashfs initrd.

Just as squashfs initrds, erofs images as initrds are a good option
for systems that are memory-constrained.

Signed-off-by: Julian Stecklina <julian.stecklina@cyberus-technology.de>
---
 init/do_mounts_rd.c | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/init/do_mounts_rd.c b/init/do_mounts_rd.c
index ac021ae6e6fa78c7b7828a78ab2fa3af3611bef3..7c3f8b45b5ed2eea3c534d7f2e65608542009df5 100644
--- a/init/do_mounts_rd.c
+++ b/init/do_mounts_rd.c
@@ -11,6 +11,7 @@
 
 #include "do_mounts.h"
 #include "../fs/squashfs/squashfs_fs.h"
+#include "../fs/erofs/erofs_fs.h"
 
 #include <linux/decompress/generic.h>
 
@@ -47,6 +48,7 @@ static int __init crd_load(decompress_fn deco);
  *	romfs
  *	cramfs
  *	squashfs
+ *	erofs
  *	gzip
  *	bzip2
  *	lzma
@@ -63,6 +65,7 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 	struct romfs_super_block *romfsb;
 	struct cramfs_super *cramfsb;
 	struct squashfs_super_block *squashfsb;
+	struct erofs_super_block *erofsb;
 	int nblocks = -1;
 	unsigned char *buf;
 	const char *compress_name;
@@ -77,6 +80,7 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 	romfsb = (struct romfs_super_block *) buf;
 	cramfsb = (struct cramfs_super *) buf;
 	squashfsb = (struct squashfs_super_block *) buf;
+	erofsb = (struct erofs_super_block *) buf;
 	memset(buf, 0xe5, size);
 
 	/*
@@ -165,6 +169,21 @@ identify_ramdisk_image(struct file *file, loff_t pos,
 		goto done;
 	}
 
+	/* Try erofs */
+	pos = (start_block * BLOCK_SIZE) + EROFS_SUPER_OFFSET;
+	kernel_read(file, buf, size, &pos);
+
+	if (erofsb->magic == EROFS_SUPER_MAGIC_V1) {
+		printk(KERN_NOTICE
+		       "RAMDISK: erofs filesystem found at block %d\n",
+		       start_block);
+
+		nblocks = ((erofsb->blocks << erofsb->blkszbits) + BLOCK_SIZE - 1)
+			>> BLOCK_SIZE_BITS;
+
+		goto done;
+	}
+
 	printk(KERN_NOTICE
 	       "RAMDISK: Couldn't find valid RAM disk image starting at %d.\n",
 	       start_block);

---
base-commit: 5fc31936081919a8572a3d644f3fbb258038f337
change-id: 20250320-initrd-erofs-76e925fdf68c

Best regards,
-- 
Julian Stecklina <julian.stecklina@cyberus-technology.de>

