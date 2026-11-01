From: Igor Velkov <iav@iav.lv>
Date: Sun, 01 Nov 2026 07:53:24 +0200
Subject: [PATCH 2/4] net: lwip: wget: hand the payload to an optional sink
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b4-wget-blk-r4-v1-2-e27a009e4043@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6395; i=iav@iav.lv;
 h=from:subject:message-id; bh=lCIJ4dMzfcMD6q4KqvwuhsLovHe/rjJNuwpcPbY7Jfk=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnPLl9x4EteI91onbLZ94mEx7PT0oqeVfsjbl+xTtpX7
 uu0hUW+o5SFQYyLQVZMkWXCIY1bGUuu/vX3MH8AM4eVCWQIAxenAEwkJ5rhDy+Dn/Ocyl8yQmt2
 O8RwfWqOKPyU1JiYO/uo/cw6t2Nuaxn+x6l/zKx7vF9J/C8H+3Ne+XWOrltusjzdee+RpnDMHQM
 7JgA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wget copies every received block to memory, so a download cannot be
larger than the free RAM. Writing a disk image to a block device while
it arrives needs the blocks one by one instead.

Add a sink callback to struct wget_http_info. When a client sets it,
store_block() passes each block to the sink and copies nothing, and
wget does not set fileaddr. altcp_recved() follows the sink, so the
TCP window reopens only after the sink has taken the data.

lwIP hands the body to the receive callback whatever the HTTP status.
With a sink, wget checks the status in the headers callback and refuses
the body of any reply other than 200, then reports the server error.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 include/net-common.h |  6 +++++
 net/lwip/wget.c      | 76 ++++++++++++++++++++++++++++++++++++++++++++--------
 2 files changed, 71 insertions(+), 11 deletions(-)

diff --git a/include/net-common.h b/include/net-common.h
index f1f670dbd8b..75640d4ba41 100644
--- a/include/net-common.h
+++ b/include/net-common.h
@@ -623,6 +623,10 @@ enum wget_http_method {
  * @hdr_cont_len:	content length according to headers. Filled by wget
  * @headers:		buffer for headers. Filled by wget.
  * @silent:		do not print anything to the console. Filled by client.
+ * @sink:		if set, receives the payload piece by piece, and wget
+ *			writes nothing to the destination address; a negative
+ *			return aborts the transfer. lwIP only. Filled by client.
+ * @sink_priv:		first argument of @sink. Filled by client.
  */
 struct wget_http_info {
 	enum wget_http_method method;
@@ -634,6 +638,8 @@ struct wget_http_info {
 	u32 hdr_cont_len;
 	char *headers;
 	bool silent;
+	int (*sink)(void *priv, const void *buf, size_t len);
+	void *sink_priv;
 };
 
 extern struct wget_http_info default_wget_info;
diff --git a/net/lwip/wget.c b/net/lwip/wget.c
index 615ea035a28..5d275d28a81 100644
--- a/net/lwip/wget.c
+++ b/net/lwip/wget.c
@@ -41,6 +41,8 @@ struct wget_ctx {
 	ulong hash_count;
 	enum done_state done;
 	bool aborted;
+	/* status that made headers_done refuse the body, for the message */
+	u32 bad_status;
 };
 
 static void wget_lwip_fill_info(struct pbuf *hdr, u16_t hdr_len, u32_t hdr_cont_len)
@@ -141,25 +143,19 @@ static int parse_url(char *url, char *host, u16 *port, char **path,
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
-	ulong pos;
-
-	/* Avoid overflow */
-	if (wget_info->buffer_size && wget_info->buffer_size < ctx->size + len)
-		return -1;
 
 	if (CONFIG_IS_ENABLED(LMB) && wget_info->set_bootdev) {
 		if (store_addr + len < store_addr ||
@@ -176,6 +172,35 @@ static int store_block(struct wget_ctx *ctx, void *src, u16_t len)
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
+	ulong pos;
+	int ret;
+
+	/* Avoid overflow */
+	if (wget_info->buffer_size && wget_info->buffer_size < ctx->size + len)
+		return -1;
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
 
@@ -235,6 +260,11 @@ static void httpc_result_cb(void *arg, httpc_result_t httpc_result,
 		ctx->done = FAILURE;
 		return;
 	}
+	if (ctx->bad_status) {
+		log_err("\nHTTP server error %d\n", ctx->bad_status);
+		ctx->done = FAILURE;
+		return;
+	}
 
 	if (httpc_result != HTTPC_RESULT_OK) {
 		log_err("\nHTTP client error %d\n", httpc_result);
@@ -270,7 +300,8 @@ static void httpc_result_cb(void *arg, httpc_result_t httpc_result,
 				rx_content_len);
 	wget_lwip_set_file_size(rx_content_len);
 	if (env_set_hex("filesize", rx_content_len) ||
-	    env_set_hex("fileaddr", ctx->saved_daddr)) {
+	    (!wget_info->sink &&
+	     env_set_hex("fileaddr", ctx->saved_daddr))) {
 		log_err("Could not set filesize or fileaddr\n");
 		ctx->done = FAILURE;
 		return;
@@ -279,13 +310,35 @@ static void httpc_result_cb(void *arg, httpc_result_t httpc_result,
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
 static err_t httpc_headers_done_cb(httpc_state_t *connection, void *arg, struct pbuf *hdr,
 				   u16_t hdr_len, u32_t content_len)
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
+
 	/* lwIP passes U32_MAX when the reply has no usable Content-Length */
 	if (wget_info->check_buffer_size && content_len != U32_MAX &&
 	    (ulong)content_len > wget_info->buffer_size)
@@ -423,6 +476,7 @@ int wget_do_request(ulong dst_addr, char *uri)
 	ctx.content_len = 0;
 	ctx.hash_count = 0;
 	ctx.aborted = false;
+	ctx.bad_status = 0;
 
 	ret = parse_url(uri, ctx.server_name, &ctx.port, &ctx.path, &is_https);
 	if (ret)

-- 
2.43.0

