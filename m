From: Alberto Ruiz <aruiz@redhat.com>
Date: Thu, 18 Jun 2026 17:13:45 +0100
Subject: [PATCH RFC 2/2] erofs: add KUnit test for memory-backed compressed
 mount
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260618-erofs-memback-v1-2-5aa7006a241a@redhat.com>
References: <20260618-erofs-memback-v1-0-5aa7006a241a@redhat.com>
In-Reply-To: <20260618-erofs-memback-v1-0-5aa7006a241a@redhat.com>
To: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>, 
 Yue Hu <zbestahu@gmail.com>, Jeffle Xu <jefflexu@linux.alibaba.com>, 
 Sandeep Dhavale <dhavale@google.com>, Hongbo Li <lihongbo22@huawei.com>, 
 Chunhai Guo <guochunhai@vivo.com>
Cc: linux-kernel@vger.kernel.org, linux-erofs@lists.ozlabs.org, 
 Javier Martinez Canillas <javierm@redhat.com>, 
 Brian Masney <bmasney@redhat.com>, Eric Curtin <ericcurtin17@gmail.com>, 
 Alberto Ruiz <aruiz@redhat.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781799229; l=8348;
 i=aruiz@redhat.com; s=20260612; h=from:subject:message-id;
 bh=b9t0SkET5XJY4KK4sxjXiSKjgiQdXm9lWMdLqHk7s2k=;
 b=tbONYBa2EzQSjsUjfTnKYiQ6NLw3Y1EmK9ph1Pt6looSCrto6gVgu7pG38FrLeu/YehLWJG86
 M0S710t0tL9CWy3m1en95zZgJq1Spdp6T/WvwEc4bAkU6HSRztDrp9u
X-Developer-Key: i=aruiz@redhat.com; a=ed25519;
 pk=d1doFQwve1B/jU9nG5oPl1W5d+t+iFrjkkwk/hD97Ow=
X-Endpoint-Received: by B4 Relay for aruiz@redhat.com/20260612 with auth_id=818
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a KUnit test that exercises the EROFS memback mount path with a
compressed (LZ4) image. The test embeds a minimal 8 KiB EROFS image
containing a single file with known content ("The quick brown fox. "
repeated 250 times), mounts it via erofs_memback_set_pending(), reads
back the decompressed file data, and verifies it byte-for-byte.

Since erofs_memback_set_pending() is __init, the test uses
kunit_test_init_section_suites() so it runs during kernel init.

Assisted-by: Claude:claude-opus-4-6
Signed-off-by: Alberto Ruiz <aruiz@redhat.com>
---
 fs/erofs/Kconfig        |  11 ++++
 fs/erofs/Makefile       |   1 +
 fs/erofs/memback_test.c | 151 ++++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 163 insertions(+)

diff --git a/fs/erofs/Kconfig b/fs/erofs/Kconfig
index 97c48ebe8458..adf26e67924c 100644
--- a/fs/erofs/Kconfig
+++ b/fs/erofs/Kconfig
@@ -213,3 +213,14 @@ config EROFS_FS_PAGE_CACHE_SHARE
 	  content fingerprints on the same machine.
 
 	  If unsure, say N.
+
+config EROFS_FS_MEMBACK_KUNIT_TEST
+	bool "Test EROFS memory-backed mount" if !KUNIT_ALL_TESTS
+	depends on EROFS_FS=y && EROFS_FS_ZIP && KUNIT=y
+	default KUNIT_ALL_TESTS
+	help
+	  KUnit test for the EROFS memory-backed mount path. Embeds a small
+	  LZ4-compressed EROFS image and verifies that it can be mounted and
+	  read via the memback interface during kernel init.
+
+	  Say N unless you are running KUnit tests.
diff --git a/fs/erofs/Makefile b/fs/erofs/Makefile
index 8f3b73835328..b98c95e96e85 100644
--- a/fs/erofs/Makefile
+++ b/fs/erofs/Makefile
@@ -12,3 +12,4 @@ erofs-$(CONFIG_EROFS_FS_BACKED_BY_FILE) += fileio.o
 erofs-$(CONFIG_EROFS_FS_ONDEMAND) += fscache.o
 erofs-y += memback.o
 erofs-$(CONFIG_EROFS_FS_PAGE_CACHE_SHARE) += ishare.o
+obj-$(CONFIG_EROFS_FS_MEMBACK_KUNIT_TEST) += memback_test.o
diff --git a/fs/erofs/memback_test.c b/fs/erofs/memback_test.c
new file mode 100644
index 000000000000..9661b76cfa0f
--- /dev/null
+++ b/fs/erofs/memback_test.c
@@ -0,0 +1,151 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * KUnit tests for EROFS memory-backed mount (memback).
+ *
+ * Embeds a minimal LZ4-compressed EROFS image and verifies that the memback
+ * path can mount it and serve decompressed file data correctly.
+ */
+#include <kunit/test.h>
+#include <linux/fs.h>
+#include <linux/init.h>
+#include <linux/init_syscalls.h>
+#include <linux/namei.h>
+#include <linux/slab.h>
+#include <uapi/linux/mount.h>
+#include "internal.h"
+
+#define EROFS_MEMBACK_TEST_DIR "/erofs_memback_test"
+#define EROFS_MEMBACK_TEST_FILE EROFS_MEMBACK_TEST_DIR "/testfile"
+
+/*
+ * "The quick brown fox. " repeated 250 times = 5250 bytes, LZ4-compressed
+ * into a 2-block (4096 x 2) EROFS image by:
+ *   mkfs.erofs -zlz4 -b4096 -x-1 image.img testdir/
+ *
+ * The full image is 8192 bytes but only 384 bytes are non-zero.  We store
+ * just the two non-zero regions (superblock+metadata at offset 1024 and
+ * compressed data at offset 8140) and reconstruct the image at runtime.
+ *
+ * The image is placed at a non-page-aligned offset (3 × 512 = 1536 bytes)
+ * within the allocation to exercise the non-page-aligned memback path.
+ */
+#define EROFS_TEST_IMAGE_SIZE 8192
+#define EROFS_TEST_IMAGE_OFFSET 1536
+
+static const unsigned char erofs_test_metadata[] __initconst = {
+	0xe2, 0xe1, 0xf5, 0xe0, 0xee, 0x93, 0xd1, 0x4a, 0x03, 0x00, 0x00, 0x00,
+	0x0c, 0x00, 0x24, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	0x5d, 0x77, 0x31, 0x6a, 0x00, 0x00, 0x00, 0x00, 0xac, 0xb1, 0x04, 0x00,
+	0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	0x2c, 0x51, 0x16, 0x54, 0xcc, 0x6a, 0x43, 0xdd, 0x96, 0xc4, 0x3e, 0x45,
+	0x16, 0x53, 0x0e, 0x9b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
+	0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00,
+	0xed, 0x41, 0x00, 0x00, 0x2f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	0xff, 0xff, 0xff, 0xff, 0x01, 0x00, 0x00, 0x00, 0xe8, 0x03, 0x00, 0x00,
+	0xe8, 0x03, 0x00, 0x00, 0x50, 0x77, 0x31, 0x6a, 0x00, 0x00, 0x00, 0x00,
+	0x7c, 0x8d, 0x20, 0x14, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	0x24, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x24, 0x00, 0x02, 0x00,
+	0x24, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x25, 0x00, 0x02, 0x00,
+	0x28, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x27, 0x00, 0x01, 0x00,
+	0x2e, 0x2e, 0x2e, 0x74, 0x65, 0x73, 0x74, 0x66, 0x69, 0x6c, 0x65, 0x00,
+	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00, 0xa4, 0x81, 0x00, 0x00,
+	0x82, 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
+	0x02, 0x00, 0x00, 0x00, 0xe8, 0x03, 0x00, 0x00, 0xe8, 0x03, 0x00, 0x00,
+	0x50, 0x77, 0x31, 0x6a, 0x00, 0x00, 0x00, 0x00, 0x2d, 0x3a, 0x37, 0x14,
+	0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
+	0x01, 0x00, 0x00, 0x00, 0x00, 0x10, 0x82, 0x04,
+};
+
+static const unsigned char erofs_test_cdata[] __initconst = {
+	0xff, 0x06, 0x54, 0x68, 0x65, 0x20, 0x71, 0x75, 0x69, 0x63, 0x6b,
+	0x20, 0x62, 0x72, 0x6f, 0x77, 0x6e, 0x20, 0x66, 0x6f, 0x78, 0x2e,
+	0x20, 0x15, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
+	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
+	0xff, 0x69, 0x50, 0x66, 0x6f, 0x78, 0x2e, 0x20,
+};
+
+#define EXPECTED_PATTERN "The quick brown fox. "
+#define EXPECTED_PATTERN_LEN 21
+#define EXPECTED_REPEATS 250
+#define EXPECTED_FILE_SIZE (EXPECTED_PATTERN_LEN * EXPECTED_REPEATS)
+
+static void __init erofs_memback_test_mount_compressed(struct kunit *test)
+{
+	void *buf;
+	struct file *file;
+	char *readbuf;
+	ssize_t nread;
+	int ret, i;
+
+	buf = kzalloc(EROFS_TEST_IMAGE_OFFSET + EROFS_TEST_IMAGE_SIZE,
+		      GFP_KERNEL);
+	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	memcpy(buf + EROFS_TEST_IMAGE_OFFSET + 1024, erofs_test_metadata,
+	       sizeof(erofs_test_metadata));
+	memcpy(buf + EROFS_TEST_IMAGE_OFFSET + 8140, erofs_test_cdata,
+	       sizeof(erofs_test_cdata));
+
+	erofs_memback_set_pending(buf + EROFS_TEST_IMAGE_OFFSET,
+				  EROFS_TEST_IMAGE_SIZE);
+
+	ret = init_mkdir(EROFS_MEMBACK_TEST_DIR, 0700);
+	KUNIT_ASSERT_EQ(test, ret, 0);
+
+	ret = init_mount("none", EROFS_MEMBACK_TEST_DIR, "erofs", MS_RDONLY,
+			 NULL);
+	if (ret) {
+		init_rmdir(EROFS_MEMBACK_TEST_DIR);
+		kfree(buf);
+		KUNIT_FAIL(test, "init_mount failed: %d", ret);
+		return;
+	}
+
+	file = filp_open(EROFS_MEMBACK_TEST_FILE, O_RDONLY, 0);
+	if (IS_ERR(file)) {
+		init_umount(EROFS_MEMBACK_TEST_DIR, 0);
+		init_rmdir(EROFS_MEMBACK_TEST_DIR);
+		kfree(buf);
+		KUNIT_FAIL(test, "filp_open failed: %ld", PTR_ERR(file));
+		return;
+	}
+
+	KUNIT_EXPECT_EQ(test, (int)i_size_read(file_inode(file)),
+			EXPECTED_FILE_SIZE);
+
+	readbuf = kzalloc(EXPECTED_FILE_SIZE, GFP_KERNEL);
+	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, readbuf);
+
+	nread = kernel_read(file, readbuf, EXPECTED_FILE_SIZE, &file->f_pos);
+	KUNIT_EXPECT_EQ(test, (int)nread, EXPECTED_FILE_SIZE);
+
+	for (i = 0; i < EXPECTED_REPEATS && nread == EXPECTED_FILE_SIZE; i++)
+		KUNIT_EXPECT_MEMEQ(test, readbuf + i * EXPECTED_PATTERN_LEN,
+				   EXPECTED_PATTERN, EXPECTED_PATTERN_LEN);
+
+	kfree(readbuf);
+	fput(file);
+	init_umount(EROFS_MEMBACK_TEST_DIR, 0);
+	init_rmdir(EROFS_MEMBACK_TEST_DIR);
+	kfree(buf);
+}
+
+static struct kunit_case erofs_memback_test_cases[] __initdata = {
+	KUNIT_CASE(erofs_memback_test_mount_compressed),
+	{},
+};
+
+static struct kunit_suite __refdata erofs_memback_test_suite = {
+	.name = "erofs_memback",
+	.test_cases = erofs_memback_test_cases,
+};
+kunit_test_init_section_suites(&erofs_memback_test_suite);
+
+MODULE_DESCRIPTION("EROFS memback KUnit test suite");
+MODULE_LICENSE("GPL");

-- 
2.53.0

