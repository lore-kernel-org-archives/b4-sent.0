From: Igor Velkov <iav@iav.lv>
Date: Mon, 23 Nov 2026 04:03:19 +0000
Subject: [PATCH v2 4/8] net: lwip: count the HTTP content length in 64 bits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-wget-blk-r4-v2-4-073d800a5aaa@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=8918; i=iav@iav.lv;
 h=from:subject:message-id; bh=5CTUJBOcYauqHQ1uWGo/mVkfDBDMCrBXuZBD782x8tQ=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNnMu9lqNwS8Oj6zctHiJVq5Kjk5Rx347mS+LnlY4sq4c
 P7GW2k7O0pZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBE7jxm+MXkevpxvJHspev2
 uy//mLlht5aYqM7aS7N+NC+QruHjWM7CyHDqaP2jS+2H/gW67hOQ3FEfJ7PL6d2/O7FLI9cV7Jh
 wdT8fAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HTTP client reads Content-Length with atoi(), here (int)dectoul(),
and keeps the length and the count of received bytes in u32_t. A length
of 2 GiB or more reads as unknown, or, from 4 GiB on, as its low 32
bits when those are below 2 GiB. With an unknown length a download that
the server cuts short ends with HTTPC_RESULT_OK instead of
HTTPC_RESULT_ERR_CONTENT_LEN, and from 4 GiB on the count of received
bytes wraps. Disk images for boards easily exceed 2 GiB now.

Parse the length, of up to 15 digits, into a 64-bit number, keep both
values in u64_t and pass them to the callbacks as u64_t;
HTTPC_CONTENT_LEN_INVALID becomes the largest u64_t. The callbacks of
wget and of the lwIP test change with the callback types.

wget scales its hash marks to the length, so an unknown length, now
the largest u64_t, would leave the bar empty until the end. With the
length unknown, wget prints a mark every 10 received blocks and a new
line every 65 marks, as the legacy wget does per packet.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 lib/lwip/lwip/src/apps/http/http_client.c         | 24 +++++++++++++----------
 lib/lwip/lwip/src/include/lwip/apps/http_client.h |  6 +++---
 net/lwip/wget.c                                   | 22 +++++++++++++++++----
 test/dm/lwip.c                                    |  2 +-
 4 files changed, 36 insertions(+), 18 deletions(-)

diff --git a/lib/lwip/lwip/src/apps/http/http_client.c b/lib/lwip/lwip/src/apps/http/http_client.c
index 06533c55c22..29afa8bf655 100644
--- a/lib/lwip/lwip/src/apps/http/http_client.c
+++ b/lib/lwip/lwip/src/apps/http/http_client.c
@@ -141,8 +141,8 @@ typedef struct _httpc_state
   altcp_recv_fn recv_fn;
   const httpc_connection_t *conn_settings;
   void* callback_arg;
-  u32_t rx_content_len;
-  u32_t hdr_content_len;
+  u64_t rx_content_len;
+  u64_t hdr_content_len;
   httpc_parse_state_t parse_state;
 #if LWIP_DNS
   u8_t dns_pending;
@@ -296,7 +296,7 @@ http_parse_response_status(struct pbuf *p, u16_t *http_version, u16_t *http_stat
 
 /** Wait for all headers to be received, return its length and content-length (if available) */
 static err_t
-http_wait_headers(struct pbuf *p, u32_t *content_length, u16_t *total_header_len)
+http_wait_headers(struct pbuf *p, u64_t *content_length, u16_t *total_header_len)
 {
   u16_t end1 = pbuf_memfind(p, "\r\n\r\n", 4, 0);
   if (end1 < (0xFFFF - 2)) {
@@ -314,11 +314,15 @@ http_wait_headers(struct pbuf *p, u32_t *content_length, u16_t *total_header_len
         u16_t content_len_num_len = (u16_t)(content_len_line_end - content_len_hdr - 16);
         if (content_len_num_len < sizeof(content_len_num)) {
           if (pbuf_copy_partial(p, content_len_num, content_len_num_len, content_len_hdr + 16) == content_len_num_len) {
-            int len;
-            content_len_num[content_len_num_len] = 0;
-            len = atoi(content_len_num);
-            if ((len >= 0) && ((u32_t)len < HTTPC_CONTENT_LEN_INVALID)) {
-              *content_length = (u32_t)len;
+            u64_t len = 0;
+            u16_t i;
+            /* at most 15 digits fit in content_len_num: no overflow */
+            for (i = 0; (i < content_len_num_len) &&
+                 (content_len_num[i] >= '0') && (content_len_num[i] <= '9'); i++) {
+              len = len * 10 + (u64_t)(content_len_num[i] - '0');
+            }
+            if (i > 0) {
+              *content_length = len;
             }
           }
         }
@@ -777,7 +781,7 @@ typedef struct _httpc_filestate
   void *callback_arg;
 } httpc_filestate_t;
 
-static void httpc_fs_result(void *arg, httpc_result_t httpc_result, u32_t rx_content_len,
+static void httpc_fs_result(void *arg, httpc_result_t httpc_result, u64_t rx_content_len,
   u32_t srv_res, err_t err);
 
 /** Initialize http client state for download to file system */
@@ -837,7 +841,7 @@ httpc_fs_free(httpc_filestate_t *filestate)
 
 /** Connection closed (success or error) */
 static void
-httpc_fs_result(void *arg, httpc_result_t httpc_result, u32_t rx_content_len,
+httpc_fs_result(void *arg, httpc_result_t httpc_result, u64_t rx_content_len,
                 u32_t srv_res, err_t err)
 {
   httpc_filestate_t *filestate = (httpc_filestate_t *)arg;
diff --git a/lib/lwip/lwip/src/include/lwip/apps/http_client.h b/lib/lwip/lwip/src/include/lwip/apps/http_client.h
index 322e51cc852..79bb090d9d3 100644
--- a/lib/lwip/lwip/src/include/lwip/apps/http_client.h
+++ b/lib/lwip/lwip/src/include/lwip/apps/http_client.h
@@ -72,7 +72,7 @@ extern "C" {
  * Content length that the headers callback gets when the client read none
  * from the reply
  */
-#define HTTPC_CONTENT_LEN_INVALID 0xFFFFFFFF
+#define HTTPC_CONTENT_LEN_INVALID 0xFFFFFFFFFFFFFFFFULL
 
 /**
  * @ingroup httpc
@@ -114,7 +114,7 @@ typedef struct _httpc_state httpc_state_t;
  * @param err an error returned by internal lwip functions, can help to specify
  *            the source of the error but must not necessarily be != ERR_OK
  */
-typedef void (*httpc_result_fn)(void *arg, httpc_result_t httpc_result, u32_t rx_content_len, u32_t srv_res, err_t err);
+typedef void (*httpc_result_fn)(void *arg, httpc_result_t httpc_result, u64_t rx_content_len, u32_t srv_res, err_t err);
 
 /**
  * @ingroup httpc
@@ -128,7 +128,7 @@ typedef void (*httpc_result_fn)(void *arg, httpc_result_t httpc_result, u32_t rx
  *                    (HTTPC_CONTENT_LEN_INVALID if not received)
  * @return if != ERR_OK is returned, the connection is aborted
  */
-typedef err_t (*httpc_headers_done_fn)(httpc_state_t *connection, void *arg, struct pbuf *hdr, u16_t hdr_len, u32_t content_len);
+typedef err_t (*httpc_headers_done_fn)(httpc_state_t *connection, void *arg, struct pbuf *hdr, u16_t hdr_len, u64_t content_len);
 
 typedef struct _httpc_connection {
   ip_addr_t proxy_addr;
diff --git a/net/lwip/wget.c b/net/lwip/wget.c
index 54c8bc612fd..cb31dfd0190 100644
--- a/net/lwip/wget.c
+++ b/net/lwip/wget.c
@@ -21,6 +21,7 @@
 #define SERVER_NAME_SIZE 254
 #define HTTP_PORT_DEFAULT 80
 #define HTTPS_PORT_DEFAULT 443
+#define HASHES_PER_LINE 65
 
 enum done_state {
 	NOT_DONE = 0,
@@ -39,6 +40,7 @@ struct wget_ctx {
 	ulong start_time;
 	u64 content_len;
 	ulong hash_count;
+	ulong blocks;
 	enum done_state done;
 	bool aborted;
 };
@@ -183,6 +185,16 @@ static int store_block(struct wget_ctx *ctx, void *src, u16_t len)
 	if (wget_info->silent)
 		return 0;
 
+	if (ctx->content_len == HTTPC_CONTENT_LEN_INVALID) {
+		/* no length to scale to: a mark every 10 blocks */
+		if (++ctx->blocks % 10)
+			return 0;
+		putc('#');
+		if (++ctx->hash_count % HASHES_PER_LINE == 0)
+			putc('\n');
+		return 0;
+	}
+
 	pos = min(ctx->size, ctx->content_len);
 
 	while (ctx->content_len &&
@@ -222,7 +234,7 @@ out:
 }
 
 static void httpc_result_cb(void *arg, httpc_result_t httpc_result,
-			    u32_t rx_content_len, u32_t srv_res, err_t err)
+			    u64_t rx_content_len, u32_t srv_res, err_t err)
 {
 	struct wget_ctx *ctx = arg;
 	ulong elapsed;
@@ -250,7 +262,8 @@ static void httpc_result_cb(void *arg, httpc_result_t httpc_result,
 	}
 
 	/* Print hash marks for the last packet received */
-	if (!wget_info->silent) {
+	if (!wget_info->silent &&
+	    ctx->content_len != HTTPC_CONTENT_LEN_INVALID) {
 		while (ctx->hash_count < 49) {
 			putc('#');
 			ctx->hash_count++;
@@ -261,7 +274,7 @@ static void httpc_result_cb(void *arg, httpc_result_t httpc_result,
 	if (!elapsed)
 		elapsed = 1;
 	if (!wget_info->silent) {
-		printf("\n%u bytes transferred in %lu ms (", rx_content_len,
+		printf("\n%llu bytes transferred in %lu ms (", rx_content_len,
 		       elapsed);
 		print_size(div_u64(rx_content_len, elapsed) * 1000, "/s)\n");
 		printf("Bytes transferred = %llu (%llx hex)\n", ctx->size,
@@ -282,7 +295,7 @@ static void httpc_result_cb(void *arg, httpc_result_t httpc_result,
 }
 
 static err_t httpc_headers_done_cb(httpc_state_t *connection, void *arg, struct pbuf *hdr,
-				   u16_t hdr_len, u32_t content_len)
+				   u16_t hdr_len, u64_t content_len)
 {
 	struct wget_ctx *ctx = arg;
 
@@ -424,6 +437,7 @@ int wget_do_request(ulong dst_addr, char *uri)
 	ctx.start_time = 0;
 	ctx.content_len = 0;
 	ctx.hash_count = 0;
+	ctx.blocks = 0;
 	ctx.aborted = false;
 
 	ret = parse_url(uri, ctx.server_name, &ctx.port, &ctx.path, &is_https);
diff --git a/test/dm/lwip.c b/test/dm/lwip.c
index 4dd4a562434..acece5a65af 100644
--- a/test/dm/lwip.c
+++ b/test/dm/lwip.c
@@ -60,7 +60,7 @@ struct lwip_test_http_ctx {
 };
 
 static void lwip_test_http_result(void *arg, httpc_result_t result,
-				  u32_t rx_content_len, u32_t server_response,
+				  u64_t rx_content_len, u32_t server_response,
 				  err_t err)
 {
 	struct lwip_test_http_ctx *ctx = arg;

-- 
2.43.0

