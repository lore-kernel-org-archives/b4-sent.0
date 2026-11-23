From: Igor Velkov <iav@iav.lv>
Date: Mon, 23 Nov 2026 04:03:21 +0000
Subject: [PATCH v2 6/8] net: lwip: wget: hand the payload to an optional
 sink
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-wget-blk-r4-v2-6-073d800a5aaa@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=9081; i=iav@iav.lv;
 h=from:subject:message-id; bh=iN/+r7dWA9RQhEkznfmihv2leqWlkq7f4VQonSjNE6k=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNnMu9m5Ts2Pm/16YleHdazU1rm274P83RObftgarhK+d
 2eZZNvxjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCRG6sZGc79D/X62rAuKDVJ
 8vz//v0Tf249ybuB0yrxZfVziaCEcl9GhmmF7v3nn8lLX87akib24qbTd4kKo2m6/Fca8udZGCe
 E8QAA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wget copies every received block to memory, so a download cannot be
larger than the free RAM. Writing a disk image to a block device while
it arrives needs the blocks one by one instead.

Add a sink callback to struct wget_http_info. When a client sets it,
store_block() passes each block to the sink and copies nothing, and
wget sets neither fileaddr, filesize nor the boot device.
altcp_recved() follows the sink, so the TCP window reopens only after
the sink has taken the data.

lwIP hands the body to the receive callback whatever the HTTP status.
With a sink, wget checks the status in the headers callback and refuses
the body of any reply other than 200, then reports the server error.

lwIP does not decode a transfer coding either, so the chunk framing
would reach the sink as data. With a sink, wget refuses a reply that
has a Transfer-Encoding header.

lwIP also passes on whatever the server sends past the Content-Length
and fails the transfer only when the connection closes. With a sink,
wget fails the transfer before such data reaches the sink.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 include/net-common.h |  12 ++++-
 net/lwip/wget.c      | 122 +++++++++++++++++++++++++++++++++++++++++++++------
 2 files changed, 120 insertions(+), 14 deletions(-)

diff --git a/include/net-common.h b/include/net-common.h
index 6d671afd4a2..d77a0b13b54 100644
--- a/include/net-common.h
+++ b/include/net-common.h
@@ -653,13 +653,21 @@ enum wget_http_method {
  * @method:		HTTP Method. Filled by client.
  * @status_code:	HTTP status code. Filled by wget.
  * @file_size:		download size. Filled by wget.
- * @buffer_size:	size of client-provided buffer. Filled by client.
+ * @buffer_size:	size of client-provided buffer, or the most that @sink
+ *			takes. Filled by client.
  * @set_bootdev:	set boot device with download. Filled by client.
  * @check_buffer_size:	check download does not exceed buffer size.
  *			Filled by client.
  * @hdr_cont_len:	content length according to headers. Filled by wget
  * @headers:		buffer for headers. Filled by wget.
  * @silent:		do not print anything to the console. Filled by client.
+ * @sink:		if set, receives the payload piece by piece, and wget
+ *			writes nothing to the destination address and sets
+ *			neither fileaddr, filesize nor the boot device; a
+ *			negative return aborts the transfer. wget then refuses
+ *			a reply with a status other than 200 or with a
+ *			Transfer-Encoding header. lwIP only. Filled by client.
+ * @sink_priv:		first argument of @sink. Filled by client.
  */
 struct wget_http_info {
 	enum wget_http_method method;
@@ -671,6 +679,8 @@ struct wget_http_info {
 	u32 hdr_cont_len;
 	char *headers;
 	bool silent;
+	int (*sink)(void *priv, const void *buf, size_t len);
+	void *sink_priv;
 };
 
 extern struct wget_http_info default_wget_info;
diff --git a/net/lwip/wget.c b/net/lwip/wget.c
index cb31dfd0190..4aeacb35ad7 100644
--- a/net/lwip/wget.c
+++ b/net/lwip/wget.c
@@ -6,6 +6,7 @@
 #include <display_options.h>
 #include <efi_loader.h>
 #include <env.h>
+#include <linux/ctype.h>
 #include <linux/kconfig.h>
 #include <linux/math64.h>
 #include <lwip/apps/http_client.h>
@@ -43,6 +44,9 @@ struct wget_ctx {
 	ulong blocks;
 	enum done_state done;
 	bool aborted;
+	/* why headers_done refused the body, for the message */
+	u32 bad_status;
+	bool coded;
 };
 
 static void wget_lwip_fill_info(struct pbuf *hdr, u16_t hdr_len, u64_t hdr_cont_len)
@@ -144,25 +148,19 @@ static int parse_url(char *url, char *host, u16 *port, char **path,
 }
 
 /**
- * store_block() - copy received data
+ * copy_block() - copy received data to memory
  *
- * This function is called by the receive callback to copy a block of data
- * into its final location (ctx->daddr). Before doing so, it checks if the copy
- * is allowed.
+ * This function copies a block of data into its final location (ctx->daddr).
+ * Before doing so, it checks if the copy is allowed.
  *
  * @ctx: the context for the current transfer
  * @src: the data received from the TCP stack
  * @len: the length of the data
  */
-static int store_block(struct wget_ctx *ctx, void *src, u16_t len)
+static int copy_block(struct wget_ctx *ctx, void *src, u16_t len)
 {
 	ulong store_addr = ctx->daddr;
 	uchar *ptr;
-	u64 pos;
-
-	/* Avoid overflow */
-	if (wget_info->buffer_size && wget_info->buffer_size < ctx->size + len)
-		return -1;
 
 	if (CONFIG_IS_ENABLED(LMB) && wget_info->set_bootdev) {
 		if (store_addr + len < store_addr ||
@@ -179,6 +177,43 @@ static int store_block(struct wget_ctx *ctx, void *src, u16_t len)
 	memcpy(ptr, src, len);
 	unmap_sysmem(ptr);
 
+	return 0;
+}
+
+/**
+ * store_block() - store received data
+ *
+ * The receive callback calls this function to pass a block of data to the
+ * client's sink or, without one, to copy it to memory.
+ *
+ * @ctx: the context for the current transfer
+ * @src: the data received from the TCP stack
+ * @len: the length of the data
+ */
+static int store_block(struct wget_ctx *ctx, void *src, u16_t len)
+{
+	u64 pos;
+	int ret;
+
+	/* Avoid overflow */
+	if (wget_info->buffer_size && wget_info->buffer_size < ctx->size + len)
+		return -1;
+
+	/* data past the Content-Length is no part of the file */
+	if (wget_info->sink && ctx->content_len != HTTPC_CONTENT_LEN_INVALID &&
+	    ctx->size + len > ctx->content_len) {
+		if (!wget_info->silent)
+			log_err("\nwget: the server sent more than its Content-Length\n");
+		return -1;
+	}
+
+	if (wget_info->sink)
+		ret = wget_info->sink(wget_info->sink_priv, src, len);
+	else
+		ret = copy_block(ctx, src, len);
+	if (ret < 0)
+		return -1;
+
 	ctx->daddr += len;
 	ctx->size += len;
 
@@ -249,6 +284,16 @@ static void httpc_result_cb(void *arg, httpc_result_t httpc_result,
 		ctx->done = FAILURE;
 		return;
 	}
+	if (ctx->bad_status) {
+		log_err("\nHTTP server error %d\n", ctx->bad_status);
+		ctx->done = FAILURE;
+		return;
+	}
+	if (ctx->coded) {
+		log_err("\nwget: the server sent a Transfer-Encoding, which wget does not decode\n");
+		ctx->done = FAILURE;
+		return;
+	}
 
 	if (httpc_result != HTTPC_RESULT_OK) {
 		log_err("\nHTTP client error %d\n", httpc_result);
@@ -280,12 +325,14 @@ static void httpc_result_cb(void *arg, httpc_result_t httpc_result,
 		printf("Bytes transferred = %llu (%llx hex)\n", ctx->size,
 		       ctx->size);
 	}
-	if (wget_info->set_bootdev)
+	if (wget_info->set_bootdev && !wget_info->sink)
 		efi_set_bootdev("Http", ctx->server_name, ctx->path, map_sysmem(ctx->saved_daddr, 0),
 				rx_content_len);
 	wget_lwip_set_file_size(rx_content_len);
-	if (env_set_hex("filesize", rx_content_len) ||
-	    env_set_hex("fileaddr", ctx->saved_daddr)) {
+	/* the client of a sink sets filesize once its output is complete */
+	if (!wget_info->sink &&
+	    (env_set_hex("filesize", rx_content_len) ||
+	     env_set_hex("fileaddr", ctx->saved_daddr))) {
 		log_err("Could not set filesize or fileaddr\n");
 		ctx->done = FAILURE;
 		return;
@@ -294,13 +341,60 @@ static void httpc_result_cb(void *arg, httpc_result_t httpc_result,
 	ctx->done = SUCCESS;
 }
 
+/* Status code from the "HTTP/1.x NNN ..." line, or 0 if there is none */
+static u32 http_status(struct pbuf *hdr)
+{
+	char line[16];
+	u16_t n;
+
+	n = pbuf_copy_partial(hdr, line, sizeof(line) - 1, 0);
+	line[n] = '\0';
+	if (n < 12 || strncmp(line, "HTTP/", 5))
+		return 0;
+
+	return simple_strtoul(line + 9, NULL, 10);
+}
+
+/* True if the reply has a Transfer-Encoding header: lwIP decodes none */
+static bool http_transfer_coded(struct pbuf *hdr, u16_t hdr_len)
+{
+	static const char name[] = "\ntransfer-encoding:";
+	u16_t i, n = 0;
+	char c;
+
+	for (i = 0; i < hdr_len; i++) {
+		c = tolower(pbuf_get_at(hdr, i));
+		if (c == name[n]) {
+			if (!name[++n])
+				return true;
+		} else {
+			n = c == name[0];
+		}
+	}
+
+	return false;
+}
+
 static err_t httpc_headers_done_cb(httpc_state_t *connection, void *arg, struct pbuf *hdr,
 				   u16_t hdr_len, u64_t content_len)
 {
 	struct wget_ctx *ctx = arg;
+	u32 status;
 
 	wget_lwip_fill_info(hdr, hdr_len, content_len);
 
+	/* the body of an error page must not reach a sink */
+	status = http_status(hdr);
+	if (wget_info->sink && status != 200) {
+		ctx->bad_status = status;
+		return ERR_VAL;
+	}
+	/* nor must the framing of a transfer coding */
+	if (wget_info->sink && http_transfer_coded(hdr, hdr_len)) {
+		ctx->coded = true;
+		return ERR_VAL;
+	}
+
 	if (wget_info->check_buffer_size &&
 	    content_len != HTTPC_CONTENT_LEN_INVALID &&
 	    content_len > wget_info->buffer_size)
@@ -439,6 +533,8 @@ int wget_do_request(ulong dst_addr, char *uri)
 	ctx.hash_count = 0;
 	ctx.blocks = 0;
 	ctx.aborted = false;
+	ctx.bad_status = 0;
+	ctx.coded = false;
 
 	ret = parse_url(uri, ctx.server_name, &ctx.port, &ctx.path, &is_https);
 	if (ret)

-- 
2.43.0

