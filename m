From: Igor Velkov <iav@iav.lv>
Date: Sun, 01 Nov 2026 07:53:25 +0200
Subject: [PATCH 3/4] lib: add a stream sink for block devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b4-wget-blk-r4-v1-3-e27a009e4043@iav.lv>
References: <20261101-b4-wget-blk-r4-v1-0-e27a009e4043@iav.lv>
In-Reply-To: <20261101-b4-wget-blk-r4-v1-0-e27a009e4043@iav.lv>
To: Jerome Forissier <jerome.forissier@arm.com>, 
 Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Adriano Cordova <adrianox@gmail.com>, u-boot@lists.u-boot-project.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=14859; i=iav@iav.lv;
 h=from:subject:message-id; bh=/IGbEaxzLJKAy4pYVeN/1uPnTMj3gs4yMPW15IpAouo=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnPLl+97pj6OVKo7+fbyE+ld1KEd/Cen+xktq4988njx
 r5qoRSzjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCRzFCG/6F2x347XNtWMzHx
 PtOjxClHVDisMhXdK/n42ZLvvP20RYrhF5P62dsVW7XOeibL/vmUlLQ8QjDtwCH287/jDKQCuz0
 MuQE=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Writing a disk image while it downloads needs a writer that takes the
data piece by piece and puts it on a block device, without the whole
image in memory.

Add sink_to_blk(). It takes the input through sink_write() in pieces of
any size and writes it through a write buffer of a size the caller
picks. sink_finish() pads the last block with zeroes, and sink_abort()
drops the buffered tail of a stream that did not complete. Data that
does not fit in the target area fails the stream.

sink_blk_area() turns "<dev>[.<hwpart>][:<part>|#<name>]" and a byte
offset into a block range. Without a partition the range is the whole
device, also on a partitioned one. A partition that lies outside the
device is refused.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 configs/sandbox_defconfig |   1 +
 include/stream_sink.h     |  75 ++++++++++++++++++
 lib/Kconfig               |   8 ++
 lib/Makefile              |   1 +
 lib/stream_sink.c         | 189 ++++++++++++++++++++++++++++++++++++++++++++++
 test/lib/Makefile         |   3 +
 test/lib/stream_sink.c    | 137 +++++++++++++++++++++++++++++++++
 7 files changed, 414 insertions(+)

diff --git a/configs/sandbox_defconfig b/configs/sandbox_defconfig
index a3fa5246082..94ec4a34c62 100644
--- a/configs/sandbox_defconfig
+++ b/configs/sandbox_defconfig
@@ -404,6 +404,7 @@ CONFIG_ECDSA_VERIFY=y
 CONFIG_RSASSA_PSS=y
 CONFIG_TPM=y
 CONFIG_TPM_AUTOSTART=y
+CONFIG_STREAM_SINK=y
 CONFIG_ERRNO_STR=y
 CONFIG_GETOPT=y
 CONFIG_TEST_FDTDEC=y
diff --git a/include/stream_sink.h b/include/stream_sink.h
new file mode 100644
index 00000000000..f470b86bb02
--- /dev/null
+++ b/include/stream_sink.h
@@ -0,0 +1,75 @@
+/* SPDX-License-Identifier: GPL-2.0+ */
+/*
+ * Write a stream to a block device
+ */
+
+#ifndef __STREAM_SINK_H
+#define __STREAM_SINK_H
+
+#include <blk.h>
+#include <linux/types.h>
+
+struct stream_sink;
+
+/**
+ * sink_to_blk() - start writing a stream to a block device
+ *
+ * @dev:	the device
+ * @start:	first block to write
+ * @count:	blocks available from @start; more output fails the stream
+ * @wbuf:	size of the write buffer, a multiple of the block size
+ * Return:	the sink, or NULL with the reason printed
+ */
+struct stream_sink *sink_to_blk(struct blk_desc *dev, lbaint_t start,
+				lbaint_t count, size_t wbuf);
+
+/**
+ * sink_blk_area() - find the blocks that a command line names
+ *
+ * Without ":<part>" or "#<name>" the area is the whole device (or hardware
+ * partition), which a raw write wants even where the device has a partition
+ * table.
+ *
+ * @ifname:	interface, e.g. "mmc"
+ * @dev_part:	"<dev>[.<hwpart>][:<part>|#<name>]"
+ * @offs:	byte offset into the area, a multiple of the block size
+ * @dev:	returns the device
+ * @start:	returns the first block to write
+ * @count:	returns the blocks from @start to the end of the area
+ * Return:	0, or a negative error with the reason printed
+ */
+int sink_blk_area(const char *ifname, const char *dev_part, u64 offs,
+		  struct blk_desc **dev, lbaint_t *start, lbaint_t *count);
+
+/**
+ * sink_write() - feed the next piece of the stream
+ *
+ * @s:		the sink
+ * @buf:	input data
+ * @len:	length of @buf
+ * Return:	0, or a negative error with the reason printed
+ */
+int sink_write(struct stream_sink *s, const void *buf, size_t len);
+
+/**
+ * sink_finish() - complete the stream and release the sink
+ *
+ * This writes out the last partial block padded with zeroes and frees @s.
+ * After a failed sink_write() it only frees @s and returns that error.
+ *
+ * @s:		the sink
+ * @outlen:	if not NULL, receives the number of output bytes
+ * Return:	0, or a negative error with the reason printed
+ */
+int sink_finish(struct stream_sink *s, u64 *outlen);
+
+/**
+ * sink_abort() - release the sink of a stream that did not complete
+ *
+ * Output already written stays where it is; this drops the buffered tail.
+ *
+ * @s:		the sink
+ */
+void sink_abort(struct stream_sink *s);
+
+#endif /* __STREAM_SINK_H */
diff --git a/lib/Kconfig b/lib/Kconfig
index e23037f1e9c..e7eaae5e5aa 100644
--- a/lib/Kconfig
+++ b/lib/Kconfig
@@ -998,6 +998,14 @@ config ZSTD_LIB_MINIFY
 
 endif
 
+config STREAM_SINK
+	bool "Write a stream to a block device"
+	depends on BLK
+	help
+	  Write data piece by piece as it arrives, for example from wget,
+	  to a block device. Memory use does not grow with the data: the
+	  sink needs only its write buffer.
+
 config SPL_BZIP2
 	bool "Enable bzip2 decompression support for SPL build"
 	depends on SPL
diff --git a/lib/Makefile b/lib/Makefile
index 925cb619807..db14b8804ee 100644
--- a/lib/Makefile
+++ b/lib/Makefile
@@ -91,6 +91,7 @@ obj-$(CONFIG_$(PHASE_)ASN1_DECODER_LEGACY) += asn1_decoder.o
 obj-$(CONFIG_$(PHASE_)ZLIB) += zlib/
 obj-$(CONFIG_$(PHASE_)ZSTD) += zstd/
 obj-$(CONFIG_$(PHASE_)GZIP) += gunzip.o
+obj-$(CONFIG_$(PHASE_)STREAM_SINK) += stream_sink.o
 obj-$(CONFIG_$(PHASE_)LZO) += lzo/
 obj-$(CONFIG_$(PHASE_)LZMA) += lzma/
 obj-$(CONFIG_$(PHASE_)LZ4) += lz4_wrapper.o
diff --git a/lib/stream_sink.c b/lib/stream_sink.c
new file mode 100644
index 00000000000..b675712531e
--- /dev/null
+++ b/lib/stream_sink.c
@@ -0,0 +1,189 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Write a stream to a block device
+ *
+ * The input arrives in pieces of any size, and memory use does not depend
+ * on the size of the data.
+ */
+
+#include <blk.h>
+#include <log.h>
+#include <malloc.h>
+#include <memalign.h>
+#include <part.h>
+#include <stream_sink.h>
+#include <u-boot/schedule.h>
+#include <linux/errno.h>
+#include <linux/kernel.h>
+#include <linux/math64.h>
+#include <linux/string.h>
+
+struct stream_sink {
+	u64 outlen;
+	/* first error of sink_write(), returned by every later call */
+	int err;
+
+	struct blk_desc *dev;
+	lbaint_t blk;
+	/* first block past the target area */
+	lbaint_t end;
+	u8 *wbuf;
+	size_t wbuf_size;
+	size_t fill;
+};
+
+static int sink_blk_flush(struct stream_sink *s)
+{
+	lbaint_t blocks = DIV_ROUND_UP(s->fill, s->dev->blksz);
+
+	if (!blocks)
+		return 0;
+	if (s->fill % s->dev->blksz)
+		memset(s->wbuf + s->fill, 0,
+		       blocks * s->dev->blksz - s->fill);
+	if (blocks > s->end - s->blk) {
+		log_err("sink: output does not fit in the target area\n");
+		return -ENOSPC;
+	}
+	if (blk_dwrite(s->dev, s->blk, blocks, s->wbuf) != blocks) {
+		log_err("sink: write error at block " LBAF "\n", s->blk);
+		return -EIO;
+	}
+	s->blk += blocks;
+	s->fill = 0;
+	schedule();
+
+	return 0;
+}
+
+static int sink_blk_write(struct stream_sink *s, const u8 *buf, size_t len)
+{
+	size_t n;
+	int ret;
+
+	while (len) {
+		if (s->fill == s->wbuf_size) {
+			ret = sink_blk_flush(s);
+			if (ret)
+				return ret;
+		}
+		n = min(len, s->wbuf_size - s->fill);
+		memcpy(s->wbuf + s->fill, buf, n);
+		s->fill += n;
+		s->outlen += n;
+		buf += n;
+		len -= n;
+	}
+
+	return 0;
+}
+
+static void sink_free(struct stream_sink *s)
+{
+	free(s->wbuf);
+	free(s);
+}
+
+int sink_blk_area(const char *ifname, const char *dev_part, u64 offs,
+		  struct blk_desc **dev, lbaint_t *start, lbaint_t *count)
+{
+	struct disk_partition info;
+	u64 skip;
+
+	if (strpbrk(dev_part, ":#")) {
+		if (part_get_info_by_dev_and_name_or_num(ifname, dev_part, dev,
+							 &info, 1) < 0)
+			return -ENODEV;
+	} else {
+		if (blk_get_device_by_str(ifname, dev_part, dev) < 0) {
+			log_err("sink: no device %s %s\n", ifname, dev_part);
+			return -ENODEV;
+		}
+		info.start = 0;
+		info.size = (*dev)->lba;
+	}
+
+	/* a broken partition table must not wrap the block math below */
+	if (info.start >= (*dev)->lba || info.size > (*dev)->lba - info.start) {
+		log_err("sink: %s %s lies outside the device\n", ifname,
+			dev_part);
+		return -EINVAL;
+	}
+	if (offs % (*dev)->blksz) {
+		log_err("sink: offset %#llx is not a multiple of the block size %#lx\n",
+			offs, (*dev)->blksz);
+		return -EINVAL;
+	}
+	skip = div_u64(offs, (*dev)->blksz);
+	if (skip >= info.size) {
+		log_err("sink: offset %#llx is past the end of %s %s\n",
+			offs, ifname, dev_part);
+		return -EINVAL;
+	}
+	*start = info.start + skip;
+	*count = info.size - skip;
+
+	return 0;
+}
+
+struct stream_sink *sink_to_blk(struct blk_desc *dev, lbaint_t start,
+				lbaint_t count, size_t wbuf)
+{
+	struct stream_sink *s;
+
+	if (!wbuf || wbuf % dev->blksz) {
+		log_err("sink: write buffer %#zx is not a multiple of the block size %#lx\n",
+			wbuf, dev->blksz);
+		return NULL;
+	}
+	if (!count || start + count < start || start + count > dev->lba) {
+		log_err("sink: blocks " LBAF "+" LBAF " are outside the device\n",
+			start, count);
+		return NULL;
+	}
+
+	s = calloc(1, sizeof(*s));
+	if (!s) {
+		log_err("sink: out of memory\n");
+		return NULL;
+	}
+	s->wbuf = malloc_cache_aligned(wbuf);
+	if (!s->wbuf) {
+		log_err("sink: no memory for a write buffer of %#zx bytes\n",
+			wbuf);
+		sink_free(s);
+		return NULL;
+	}
+	s->dev = dev;
+	s->blk = start;
+	s->end = start + count;
+	s->wbuf_size = wbuf;
+
+	return s;
+}
+
+int sink_write(struct stream_sink *s, const void *buf, size_t len)
+{
+	if (!s->err)
+		s->err = sink_blk_write(s, buf, len);
+
+	return s->err;
+}
+
+int sink_finish(struct stream_sink *s, u64 *outlen)
+{
+	int ret = s->err;
+
+	if (!ret)
+		ret = sink_blk_flush(s);
+	if (outlen)
+		*outlen = s->outlen;
+	sink_free(s);
+
+	return ret;
+}
+
+void sink_abort(struct stream_sink *s)
+{
+	sink_free(s);
+}
diff --git a/test/lib/Makefile b/test/lib/Makefile
index 9fc4a1a9b5d..af099777391 100644
--- a/test/lib/Makefile
+++ b/test/lib/Makefile
@@ -8,6 +8,9 @@ obj-$(CONFIG_$(PHASE_)UT_COMPRESSION) += compression.o
 ifeq ($(CONFIG_XPL_BUILD),)
 obj-y += abuf.o
 obj-y += alist.o
+ifeq ($(CONFIG_SANDBOX)$(CONFIG_STREAM_SINK),yy)
+obj-y += stream_sink.o
+endif
 obj-$(CONFIG_ECDSA_VERIFY_MBEDTLS) += ecdsa.o
 obj-$(CONFIG_EFI_LOADER) += efi_device_path.o efi_memory.o
 obj-$(CONFIG_EFI_SECURE_BOOT) += efi_image_region.o
diff --git a/test/lib/stream_sink.c b/test/lib/stream_sink.c
new file mode 100644
index 00000000000..a39cf010743
--- /dev/null
+++ b/test/lib/stream_sink.c
@@ -0,0 +1,137 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Tests for writing a stream to a block device
+ */
+
+#include <blk.h>
+#include <part.h>
+#include <stream_sink.h>
+#include <u-boot/uuid.h>
+#include <test/lib.h>
+#include <test/test.h>
+#include <test/ut.h>
+
+#define DATA_LEN	3000
+
+static void fill(u8 *buf, size_t len, unsigned int seed)
+{
+	while (len--) {
+		*buf++ = seed;
+		seed = seed * 43 + 17;
+	}
+}
+
+/* Feed @len bytes of @src in pieces of @piece bytes. */
+static int feed(struct stream_sink *s, const u8 *src, size_t len,
+		size_t piece)
+{
+	size_t done, n;
+	int ret;
+
+	for (done = 0; done < len; done += n) {
+		n = min(piece, len - done);
+		ret = sink_write(s, src + done, n);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+/* Give mmc2 two partitions, as test/cmd/rw.c does. */
+static int setup_partitions(struct unit_test_state *uts,
+			    struct blk_desc **desc)
+{
+	char guid[UUID_STR_LEN + 1] = "";
+	struct disk_partition parts[2] = {
+		{ .start = 48, .size = 8, .name = "data" },
+		{ .start = 56, .size = 16, .name = "log" },
+	};
+
+	ut_asserteq(2, blk_get_device_by_str("mmc", "2", desc));
+	if (CONFIG_IS_ENABLED(RANDOM_UUID)) {
+		gen_rand_uuid_str(parts[0].uuid, UUID_STR_FORMAT_STD);
+		gen_rand_uuid_str(parts[1].uuid, UUID_STR_FORMAT_STD);
+		gen_rand_uuid_str(guid, UUID_STR_FORMAT_STD);
+	}
+	ut_assertok(gpt_restore(*desc, guid, parts, ARRAY_SIZE(parts)));
+
+	return 0;
+}
+
+static int lib_test_sink_blk(struct unit_test_state *uts)
+{
+	u8 src[DATA_LEN], back[4096];
+	struct blk_desc *desc, *dev;
+	lbaint_t start, count;
+	struct stream_sink *s;
+	u64 outlen;
+
+	ut_assertok(setup_partitions(uts, &desc));
+	fill(src, sizeof(src), 2);
+
+	/* the whole device, with a byte offset, also as hardware partition 0 */
+	ut_assertok(sink_blk_area("mmc", "2", 0x400, &dev, &start, &count));
+	ut_asserteq_ptr(desc, dev);
+	ut_asserteq(2, start);
+	ut_asserteq(desc->lba - 2, count);
+	ut_assertok(sink_blk_area("mmc", "2.0", 0, &dev, &start, &count));
+	ut_asserteq(0, start);
+	ut_asserteq(desc->lba, count);
+
+	/* a partition by number and by name */
+	ut_assertok(sink_blk_area("mmc", "2:1", 0, &dev, &start, &count));
+	ut_asserteq(48, start);
+	ut_asserteq(8, count);
+	ut_assertok(sink_blk_area("mmc", "2#log", 0x200, &dev, &start,
+				  &count));
+	ut_asserteq(57, start);
+	ut_asserteq(15, count);
+
+	ut_asserteq(-EINVAL, sink_blk_area("mmc", "2:1", 0x100, &dev, &start,
+					   &count));
+	ut_asserteq(-EINVAL, sink_blk_area("mmc", "2:1", 8 * 512, &dev,
+					   &start, &count));
+	ut_asserteq(-ENODEV, sink_blk_area("mmc", "9", 0, &dev, &start,
+					   &count));
+	ut_asserteq(-ENODEV, sink_blk_area("mmc", "2:7", 0, &dev, &start,
+					   &count));
+
+	/* 3000 bytes into "log", a 1 KiB buffer; the tail block is padded */
+	memset(back, 0xff, sizeof(back));
+	ut_asserteq(sizeof(back) / 512, blk_dwrite(desc, 56, 8, back));
+	ut_assertok(sink_blk_area("mmc", "2#log", 0, &dev, &start, &count));
+	s = sink_to_blk(dev, start, count, 1024);
+	ut_assertnonnull(s);
+	ut_assertok(feed(s, src, sizeof(src), 7));
+	ut_assertok(sink_finish(s, &outlen));
+	ut_asserteq(DATA_LEN, outlen);
+	ut_asserteq(sizeof(back) / 512, blk_dread(desc, 56, 8, back));
+	ut_asserteq_mem(src, back, DATA_LEN);
+	ut_assert(!memchr_inv(back + DATA_LEN, 0, 3072 - DATA_LEN));
+	ut_assert(!memchr_inv(back + 3072, 0xff, sizeof(back) - 3072));
+
+	/* an aborted stream leaves the buffered tail unwritten */
+	memset(back, 0xff, sizeof(back));
+	ut_asserteq(sizeof(back) / 512, blk_dwrite(desc, 56, 8, back));
+	s = sink_to_blk(dev, 56, 8, 1024);
+	ut_assertnonnull(s);
+	ut_assertok(feed(s, src, 1500, 1500));
+	sink_abort(s);
+	ut_asserteq(sizeof(back) / 512, blk_dread(desc, 56, 8, back));
+	ut_asserteq_mem(src, back, 1024);
+	ut_assert(!memchr_inv(back + 1024, 0xff, sizeof(back) - 1024));
+
+	/* "data" is 4 KiB: the flush of the fifth KiB fails */
+	s = sink_to_blk(dev, 48, 8, 1024);
+	ut_assertnonnull(s);
+	ut_assertok(feed(s, src, sizeof(src), sizeof(src)));
+	ut_asserteq(-ENOSPC, feed(s, src, sizeof(src), sizeof(src)));
+	ut_asserteq(-ENOSPC, sink_finish(s, NULL));
+
+	/* the write buffer must be a multiple of the block size */
+	ut_assertnull(sink_to_blk(dev, 48, 8, 1000));
+
+	return 0;
+}
+LIB_TEST(lib_test_sink_blk, UTF_DM | UTF_SCAN_FDT | UTF_CONSOLE);

-- 
2.43.0

