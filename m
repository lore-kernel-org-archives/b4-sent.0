From: Igor Velkov <iav@iav.lv>
Date: Mon, 23 Nov 2026 04:03:23 +0000
Subject: [PATCH v2 8/8] cmd: lwip: wget: write the download to a block
 device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-wget-blk-r4-v2-8-073d800a5aaa@iav.lv>
References: <20261123-b4-wget-blk-r4-v2-0-073d800a5aaa@iav.lv>
In-Reply-To: <20261123-b4-wget-blk-r4-v2-0-073d800a5aaa@iav.lv>
To: Jerome Forissier <jerome.forissier@arm.com>, 
 Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Adriano Cordova <adrianox@gmail.com>, u-boot@lists.u-boot-project.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=14865; i=iav@iav.lv;
 h=from:subject:message-id; bh=rQDIhohO3RWIzazIUx6tqdDxn3YiGGxeBI20qSwMgjI=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNnMuzn0FTS3lSuv+x7CnznjgfzsdTnri//fiZc6Hme7t
 fOKUM3pjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCR2usMPxkDN3Id363gLP2o
 r5t3k8DhiQzLnLV95zc8ub/11d9dWqsY/mkf87lbmyBd+9xBeMuSN+q+mQ7r9KRTF2y1j3JQrP1
 YxQ4A
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wget loads a file into memory, so a disk image can be written only when
it fits in RAM, and only after the whole download.

Add options to the lwIP wget command that write the download to a block
device while it arrives:

  -o <if> <dev>[.<hwpart>][:<part>|#<name>]   the target
  -s <offs>                                   byte offset into it
  -b <wbuf>                                   write buffer size

Without a partition the target is the whole device, also on a
partitioned one. The target size goes to wget as the buffer size, so a
file whose Content-Length exceeds it is refused before anything is
written, and wget says when a download does not fit. A reply other
than 200 writes nothing, and a download that fails halfway drops the
buffered tail. On success filesize holds the number of bytes written
and fileaddr is deleted.
WGET_STREAM enables the options; sandbox64_lwip builds them.

A ROCK Pi 4A writes a 1.86 GB image to its SD card this way in 3 min
16 s to 3 min 35 s with a 4 MiB buffer.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 cmd/Kconfig                      |   9 +++
 cmd/lwip/wget.c                  | 130 ++++++++++++++++++++++++++++++++++++++-
 configs/sandbox64_lwip_defconfig |   1 +
 doc/usage/cmd/wget.rst           |  95 +++++++++++++++++++++++++++-
 net/lwip/wget.c                  |  12 +++-
 5 files changed, 243 insertions(+), 4 deletions(-)

diff --git a/cmd/Kconfig b/cmd/Kconfig
index c64ca1807ef..b60e7b84939 100644
--- a/cmd/Kconfig
+++ b/cmd/Kconfig
@@ -2353,6 +2353,15 @@ config WGET_HTTPS
 	help
 	  Enable TLS over http for wget.
 
+config WGET_STREAM
+	bool "wget -o: write the download to a block device"
+	depends on CMD_WGET && NET_LWIP && BLK && PARTITIONS
+	select STREAM_SINK
+	help
+	  Add wget options that write the download to a block device, or
+	  a partition of it, while it arrives, so a disk image never has
+	  to fit in RAM.
+
 config WGET_CACERT
 	bool "wget cacert"
 	depends on CMD_WGET
diff --git a/cmd/lwip/wget.c b/cmd/lwip/wget.c
index 531e886e986..499b464cdda 100644
--- a/cmd/lwip/wget.c
+++ b/cmd/lwip/wget.c
@@ -4,10 +4,16 @@
 #include <command.h>
 #include <env.h>
 #include <image.h>
+#include <limits.h>
+#include <log.h>
 #include <net.h>
+#include <stream_sink.h>
+#include <vsprintf.h>
 #include <lwip/altcp_tls.h>
+#include <linux/ctype.h>
+#include <linux/sizes.h>
 
-U_BOOT_CMD(wget, 4, 1, do_wget,
+U_BOOT_CMD(wget, 9, 1, do_wget,
 	   "boot image via network using HTTP/HTTPS protocol"
 #if defined(CONFIG_WGET_CACERT)
 	   "\nwget cacert - configure wget root certificates"
@@ -16,6 +22,14 @@ U_BOOT_CMD(wget, 4, 1, do_wget,
 	   "[loadAddress] url\n"
 	   "wget [loadAddress] [host:]path\n"
 	   "    - load file"
+#if defined(CONFIG_WGET_STREAM)
+	   "\nwget -o <interface> <dev>[.<hwpart>][:<part>|#<name>]\n"
+	   "     [-s offs] [-b wbuf] url\n"
+	   "    - write the file to a block device while it arrives;\n"
+	   "      without a partition to the whole device; offs is a byte\n"
+	   "      offset (hex) into the device or partition; wbuf is the\n"
+	   "      write buffer size (hex, default 100000)"
+#endif
 #if defined(CONFIG_WGET_CACERT)
 	   "\nwget cacert <address> <length>\n"
 	   "    - provide CA certificates (0 0 to remove current)"
@@ -176,15 +190,126 @@ static int parse_legacy_arg(char *arg, char *nurl, size_t rem)
 	return 0;
 }
 
+static int wget_stream_sink(void *priv, const void *buf, size_t len)
+{
+	return sink_write(priv, buf, len);
+}
+
+/*
+ * Parse a hex number of 1 to 16 digits, with or without 0x; 0 on success.
+ * simple_strtoull() alone takes "0x" for 0.
+ */
+static int parse_hex_u64(const char *str, u64 *val)
+{
+	const char *digits = str;
+	char *end;
+
+	if (digits[0] == '0' && tolower(digits[1]) == 'x')
+		digits += 2;
+	*val = simple_strtoull(str, &end, 16);
+	if (end == digits || end - digits > 16 || *end)
+		return -EINVAL;
+
+	return 0;
+}
+
+/* Download @url and write it to a block device while it arrives. */
+static int wget_stream(const char *ifname, const char *dev_part, u64 offs,
+		       ulong wbuf, char *url)
+{
+	struct wget_http_info info = {
+		.method = WGET_HTTP_METHOD_GET,
+		.sink = wget_stream_sink,
+	};
+	struct stream_sink *s;
+	struct blk_desc *dev;
+	lbaint_t start, count;
+	char size[17];
+	u64 outlen;
+	int ret;
+
+	if (sink_blk_area(ifname, dev_part, offs, &dev, &start, &count))
+		return CMD_RET_FAILURE;
+	s = sink_to_blk(dev, start, count, wbuf);
+	if (!s)
+		return CMD_RET_FAILURE;
+
+	/* refuse a file that cannot fit before any of it is written */
+	info.buffer_size = (u64)count * dev->blksz;
+	info.check_buffer_size = true;
+	info.sink_priv = s;
+	ret = wget_request(0, url, &info);
+	wget_info = &default_wget_info;
+
+	/* a failed download leaves its buffered tail unwritten */
+	if (ret) {
+		sink_abort(s);
+		return CMD_RET_FAILURE;
+	}
+	if (sink_finish(s, &outlen))
+		return CMD_RET_FAILURE;
+
+	/* the file is not in memory: no fileaddr goes with this filesize */
+	snprintf(size, sizeof(size), "%llx", outlen);
+	if (env_set("filesize", size) || env_set("fileaddr", NULL)) {
+		log_err("Could not set filesize or delete fileaddr\n");
+		return CMD_RET_FAILURE;
+	}
+	printf("%llu bytes written\n", outlen);
+
+	return CMD_RET_SUCCESS;
+}
+
 int do_wget(struct cmd_tbl *cmdtp, int flag, int argc, char * const argv[])
 {
 	char *end;
 	char *url;
 	ulong dst_addr;
 	char nurl[1024];
+	const char *ifname = NULL, *dev_part = NULL;
+	u64 offs = 0, val;
+	ulong wbuf = SZ_1M;
+	bool has_offs = false, has_wbuf = false;
 
 	wget_info = &default_wget_info;
 
+	while (CONFIG_IS_ENABLED(WGET_STREAM) && argc > 1 &&
+	       argv[1][0] == '-') {
+		if (!strcmp(argv[1], "-o") && argc > 3 && !ifname) {
+			ifname = argv[2];
+			dev_part = argv[3];
+			argc -= 3;
+			argv += 3;
+		} else if (!strcmp(argv[1], "-s") && argc > 2 && !has_offs) {
+			if (parse_hex_u64(argv[2], &offs))
+				return CMD_RET_USAGE;
+			has_offs = true;
+			argc -= 2;
+			argv += 2;
+		} else if (!strcmp(argv[1], "-b") && argc > 2 && !has_wbuf) {
+			if (parse_hex_u64(argv[2], &val) || val > ULONG_MAX)
+				return CMD_RET_USAGE;
+			wbuf = val;
+			has_wbuf = true;
+			argc -= 2;
+			argv += 2;
+		} else if (!strcmp(argv[1], "-o") || !strcmp(argv[1], "-s") ||
+			   !strcmp(argv[1], "-b")) {
+			return CMD_RET_USAGE;
+		} else {
+			/* a path that starts with '-' */
+			break;
+		}
+	}
+	/* -s and -b need -o, and -o takes nothing but a URL */
+	if ((has_offs || has_wbuf) && !ifname)
+		return CMD_RET_USAGE;
+	if (ifname && argc != 2)
+		return CMD_RET_USAGE;
+	/* an empty line must not write the device again */
+	if (ifname && (flag & CMD_FLAG_REPEAT))
+		return CMD_RET_SUCCESS;
+
 #if CONFIG_IS_ENABLED(WGET_CACERT)
 	if (argc == 4 && !strncmp(argv[1], "cacert", strlen("cacert")))
 		return set_cacert(argv[2], argv[3]);
@@ -219,6 +344,9 @@ int do_wget(struct cmd_tbl *cmdtp, int flag, int argc, char * const argv[])
 	if (parse_legacy_arg(url, nurl, sizeof(nurl)))
 		return CMD_RET_FAILURE;
 
+	if (CONFIG_IS_ENABLED(WGET_STREAM) && ifname)
+		return wget_stream(ifname, dev_part, offs, wbuf, nurl);
+
 	if (wget_do_request(dst_addr, nurl))
 		return CMD_RET_FAILURE;
 
diff --git a/configs/sandbox64_lwip_defconfig b/configs/sandbox64_lwip_defconfig
index 0e92728533f..ce5c503583e 100644
--- a/configs/sandbox64_lwip_defconfig
+++ b/configs/sandbox64_lwip_defconfig
@@ -3,3 +3,4 @@
 CONFIG_SANDBOX=y
 
 CONFIG_NET_LWIP=y
+CONFIG_WGET_STREAM=y
diff --git a/doc/usage/cmd/wget.rst b/doc/usage/cmd/wget.rst
index e6c33b87431..d14b70844c7 100644
--- a/doc/usage/cmd/wget.rst
+++ b/doc/usage/cmd/wget.rst
@@ -15,6 +15,8 @@ Synopsis
     wget [address] url                  # lwIP only
     wget cacert none|optional|required  # lwIP only
     wget cacert <address> <size>        # lwIP only
+    wget -o <interface> <dev>[.<hwpart>][:<part>|#<name>]
+         [-s offs] [-b wbuf] url        # lwIP only
 
 
 Description
@@ -81,6 +83,44 @@ required
     certificate verification is mandatory. If no root certificates have been
     configured, HTTPS transfers will fail.
 
+Writing to a block device (lwIP only)
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+With -o, wget writes the file to a block device while it arrives instead of
+loading it into memory, so a disk image larger than RAM can be written. wget
+pads the last partial block with zeroes. A file whose Content-Length exceeds
+the target area is refused before anything is written; one sent without a
+length fails only when it reaches the end of the area, if it does not fit.
+Without a length, a connection that closes early looks like the end of the
+file: wget keeps what arrived and succeeds. A transfer that ends before its
+Content-Length fails, and so does one that goes past it, before the data past
+it is written. When the server answers with a status other than 200, or with
+a Transfer-Encoding such as chunked, which wget does not decode, wget writes
+nothing. A transfer that fails halfway leaves on the device what arrived,
+except the last write buffer; a failed write may leave part of the buffer it
+was writing. On success wget sets the filesize variable to the number of
+bytes written and deletes fileaddr. Each option may be given once.
+
+\-o <interface> <dev>[.<hwpart>][:<part>|#<name>]
+    the target. Without a partition the target is the whole device (or the
+    hardware partition), also when the device has a partition table; :0
+    names it too. With a partition number (hex, as in other commands) or
+    name the target is that partition. A ':' without a number and ':auto'
+    are refused, and so are an empty device number and an empty name, so
+    that U-Boot does not pick the device or the partition to write. A
+    hardware partition that the device does not have is refused: one
+    above 7 on MMC, one other than 0 elsewhere.
+
+\-s offs
+    byte offset (hex) into the target, a multiple of the block size; 0 by
+    default.
+
+\-b wbuf
+    size (hex) of the write buffer, a multiple of the block size; 100000
+    (1 MiB) by default. A larger buffer gives fewer, longer writes.
+
+-s and -b need -o; a download into memory goes to the address given.
+
 
 Examples
 --------
@@ -172,6 +212,58 @@ https://cacerts.digicert.com/DigiCertTLSRSA4096RootG5.crt.
    # The builtin certificates can be restored at any time
    => wget cacert builtin
 
+Each form of the target, on an eMMC with a GPT that holds the partitions
+"boot" and "rootfs":
+
+::
+
+   => wget ${loadaddr} http://192.168.1.65/disk.img     # into memory: no -o
+   => wget -o mmc 0 http://192.168.1.65/disk.img        # the whole device
+   => wget -o mmc 0:0 http://192.168.1.65/disk.img      # the same
+   => wget -o mmc 0 -s 8000 http://192.168.1.65/idbloader.img
+                                         # 32 KiB in, where a Rockchip SoC
+                                         # looks for its boot loader
+   => wget -o mmc 0:1 http://192.168.1.65/boot.img      # partition 1
+   => wget -o mmc 0#rootfs http://192.168.1.65/root.img # partition "rootfs"
+   => wget -o mmc 0#rootfs -s 400000 http://192.168.1.65/part.img
+                                         # 4 MiB into "rootfs"
+   => wget -o mmc 0.1 http://192.168.1.65/u-boot.bin    # boot0
+   => wget -o mmc 0.2 -s 40000 http://192.168.1.65/env.bin
+                                         # 256 KiB into boot1
+   => wget -o mmc 0.0:1 http://192.168.1.65/boot.img    # partition 1 of the
+                                         # user area, the same as 0:1
+   => wget -o mmc 0 -b 400000 http://192.168.1.65/disk.img
+                                         # with a 4 MiB write buffer
+   => wget cacert none
+   => wget -o mmc 0 https://example.com/disk.img        # HTTPS, the server
+                                         # not authenticated
+
+Writing into a partition, and two targets that wget refuses:
+
+::
+
+   => wget -o mmc 0#rootfs -s 400000 http://10.0.2.2:8099/small.bin
+   ##################################################
+   3000000 bytes transferred in 5282 ms (553.7 KiB/s)
+   Bytes transferred = 3000000 (2dc6c0 hex)
+   3000000 bytes written
+   => wget -o mmc 0: http://10.0.2.2:8099/boot.bin
+   sink: no partition number in mmc 0:
+   => wget -o mmc 0#boot http://10.0.2.2:8099/big.bin
+   wget: 12582912 bytes do not fit in 8388608 bytes
+
+Writing a disk image to the SD card of a ROCK Pi 4A with a 4 MiB write
+buffer:
+
+::
+
+   => dhcp
+   => wget -o mmc 1 -b 400000 http://192.168.1.65/ub-test/armbian.img
+   ##################################################
+   1862270976 bytes transferred in 197525 ms (9 MiB/s)
+   Bytes transferred = 1862270976 (6f000000 hex)
+   1862270976 bytes written
+
 Configuration
 -------------
 
@@ -179,7 +271,8 @@ The command is only available if CONFIG_CMD_WGET=y.
 To enable lwIP support set CONFIG_NET_LWIP=y. In this case, root certificates
 support can be enabled via CONFIG_WGET_BUILTIN_CACERT=y
 CONFIG_WGET_BUILTIN_CACERT_PATH=<some path> (for built-in certificates) and/or
-CONFIG_WGET_CACERT=y (for the wget cacert command).
+CONFIG_WGET_CACERT=y (for the wget cacert command). CONFIG_WGET_STREAM=y adds
+the -o, -s and -b options.
 
 TCP Selective Acknowledgments in the legacy network stack can be enabled via
 CONFIG_PROT_TCP_SACK=y. This will improve the download speed. Selective
diff --git a/net/lwip/wget.c b/net/lwip/wget.c
index 4aeacb35ad7..cb4e7530f30 100644
--- a/net/lwip/wget.c
+++ b/net/lwip/wget.c
@@ -196,8 +196,12 @@ static int store_block(struct wget_ctx *ctx, void *src, u16_t len)
 	int ret;
 
 	/* Avoid overflow */
-	if (wget_info->buffer_size && wget_info->buffer_size < ctx->size + len)
+	if (wget_info->buffer_size && wget_info->buffer_size < ctx->size + len) {
+		if (!wget_info->silent)
+			log_err("\nwget: the file does not fit in %llu bytes\n",
+				wget_info->buffer_size);
 		return -1;
+	}
 
 	/* data past the Content-Length is no part of the file */
 	if (wget_info->sink && ctx->content_len != HTTPC_CONTENT_LEN_INVALID &&
@@ -397,8 +401,12 @@ static err_t httpc_headers_done_cb(httpc_state_t *connection, void *arg, struct
 
 	if (wget_info->check_buffer_size &&
 	    content_len != HTTPC_CONTENT_LEN_INVALID &&
-	    content_len > wget_info->buffer_size)
+	    content_len > wget_info->buffer_size) {
+		if (!wget_info->silent)
+			log_err("wget: %llu bytes do not fit in %llu bytes\n",
+				content_len, wget_info->buffer_size);
 		return ERR_BUF;
+	}
 
 	ctx->content_len = content_len;
 

-- 
2.43.0

