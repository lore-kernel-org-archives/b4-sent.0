From: Julian Stecklina <julian.stecklina@cyberus-technology.de>
Date: Sat, 22 Mar 2025 21:34:21 +0100
Subject: [PATCH v2 9/9] fs: erofs: register an initrd fs detector
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250322-initrd-erofs-v2-9-d66ee4a2c756@cyberus-technology.de>
References: <20250322-initrd-erofs-v2-0-d66ee4a2c756@cyberus-technology.de>
In-Reply-To: <20250322-initrd-erofs-v2-0-d66ee4a2c756@cyberus-technology.de>
To: Christoph Hellwig <hch@lst.de>, Al Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>
Cc: Linus Torvalds <torvalds@linux-foundation.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Gao Xiang <xiang@kernel.org>, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-erofs@lists.ozlabs.org, 
 Julian Stecklina <julian.stecklina@cyberus-technology.de>, 
 Niklas Sturm <niklas.sturm@secunet.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742675713; l=1748;
 i=julian.stecklina@cyberus-technology.de; s=20250320;
 h=from:subject:message-id; bh=3yTdTgTHrBXPDCzHQY85SoPI2ekHfJ9SwSVLMJjjpHc=;
 b=gbKgVEbkExOOnYyBMICxer+0rrpqPN7L6a11TGtSHg9nUJDPcH1Az1Dcltfti9MOJD2CWO7NM
 iXnPdA1cJA4Ct+v+ehZ5rvSbO6BmO84OPaQLlG31oC9XmPYYKZEvguk
X-Developer-Key: i=julian.stecklina@cyberus-technology.de; a=ed25519;
 pk=m051/8gQfs5AmkACfykwRcD6CUr2T7DQ9OA5eBgyy7c=
X-Endpoint-Received: by B4 Relay for julian.stecklina@cyberus-technology.de/20250320 with auth_id=363
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow erofs to be used as a filesystem for initrds. It offers similar
advantages as squashfs, but with higher performance and arguably nicer
tooling. If we support squashfs, there is no reason not to support
erofs as well.

Suggested-by: Niklas Sturm <niklas.sturm@secunet.com>
Signed-off-by: Julian Stecklina <julian.stecklina@cyberus-technology.de>
---
 fs/erofs/Makefile |  5 +++++
 fs/erofs/initrd.c | 19 +++++++++++++++++++
 2 files changed, 24 insertions(+)

diff --git a/fs/erofs/Makefile b/fs/erofs/Makefile
index 4331d53c7109550a0518f2ed8df456deecdd2f8c..cea46a51dea2b9e22e4ba1478dd30de3262fe6cb 100644
--- a/fs/erofs/Makefile
+++ b/fs/erofs/Makefile
@@ -9,3 +9,8 @@ erofs-$(CONFIG_EROFS_FS_ZIP_DEFLATE) += decompressor_deflate.o
 erofs-$(CONFIG_EROFS_FS_ZIP_ZSTD) += decompressor_zstd.o
 erofs-$(CONFIG_EROFS_FS_BACKED_BY_FILE) += fileio.o
 erofs-$(CONFIG_EROFS_FS_ONDEMAND) += fscache.o
+
+# If we are built-in, we provide support for erofs on initrds.
+ifeq ($(CONFIG_EROFS_FS),y)
+erofs-objs += initrd.o
+endif
diff --git a/fs/erofs/initrd.c b/fs/erofs/initrd.c
new file mode 100644
index 0000000000000000000000000000000000000000..e2bb313f55211a305e201f529d7da810898252ac
--- /dev/null
+++ b/fs/erofs/initrd.c
@@ -0,0 +1,19 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+#include <linux/initrd.h>
+
+#include "internal.h"
+
+static size_t __init detect_erofs(void *block_data)
+{
+	struct erofs_super_block *erofsb = block_data;
+
+	BUILD_BUG_ON(sizeof(*erofsb) > BLOCK_SIZE);
+
+	if (le32_to_cpu(erofsb->magic) != EROFS_SUPER_MAGIC_V1)
+		return 0;
+
+	return le32_to_cpu(erofsb->blocks) << erofsb->blkszbits;
+}
+
+initrd_fs_detect(detect_erofs, EROFS_SUPER_OFFSET);

-- 
2.47.0

