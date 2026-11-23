From: Igor Velkov <iav@iav.lv>
Date: Mon, 23 Nov 2026 04:03:18 +0000
Subject: [PATCH v2 3/8] net: lwip: wget: count the download in 64 bits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-wget-blk-r4-v2-3-073d800a5aaa@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4188; i=iav@iav.lv;
 h=from:subject:message-id; bh=KTvGhk7ZDeUDMXlzfgNhEN22uQJ+f1/rYUDCm6GrcSA=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNnMu9kumx6vaclvWLf+eOpnwd2fOtn2fTi85+WBEwFTG
 uULNK4odJSyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJPBZi+B/voMbJGjBZru71
 h7wnNyOOi73TnWJ36rmlZuL0xW5SEVEM/72qJJZrL9ztevjNxr7qh5o9QRXvduULBVr1b7M5Yrp
 +AhcA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wget keeps the number of bytes received and the content length in a
ulong, and struct wget_http_info keeps the size of the client's buffer,
which the length is checked against, in a ulong too. On a 32-bit board
all three stop at 4 GiB.

Make them u64 and do the progress and speed arithmetic in 64 bits.
wget_lwip_fill_info() takes a 64-bit length and passes on one that does
not fit in the 32-bit hdr_cont_len of struct wget_http_info as U32_MAX,
the value that an absent length has there.
The progress bar does not divide by a content length of zero.

The lwIP HTTP client still hands over 32-bit values: the next patch
widens them.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 include/net-common.h |  2 +-
 net/lwip/wget.c      | 25 ++++++++++++++-----------
 2 files changed, 15 insertions(+), 12 deletions(-)

diff --git a/include/net-common.h b/include/net-common.h
index 844840ce59c..6d671afd4a2 100644
--- a/include/net-common.h
+++ b/include/net-common.h
@@ -665,7 +665,7 @@ struct wget_http_info {
 	enum wget_http_method method;
 	u32 status_code;
 	ulong file_size;
-	ulong buffer_size;
+	u64 buffer_size;
 	bool set_bootdev;
 	bool check_buffer_size;
 	u32 hdr_cont_len;
diff --git a/net/lwip/wget.c b/net/lwip/wget.c
index f0ba9b3d1ab..54c8bc612fd 100644
--- a/net/lwip/wget.c
+++ b/net/lwip/wget.c
@@ -7,6 +7,7 @@
 #include <efi_loader.h>
 #include <env.h>
 #include <linux/kconfig.h>
+#include <linux/math64.h>
 #include <lwip/apps/http_client.h>
 #include "lwip/altcp_tls.h"
 #include <lwip/errno.h>
@@ -33,16 +34,16 @@ struct wget_ctx {
 	char *path;
 	ulong daddr;
 	ulong saved_daddr;
-	ulong size;
+	u64 size;
 	ulong prevsize;
 	ulong start_time;
-	ulong content_len;
+	u64 content_len;
 	ulong hash_count;
 	enum done_state done;
 	bool aborted;
 };
 
-static void wget_lwip_fill_info(struct pbuf *hdr, u16_t hdr_len, u32_t hdr_cont_len)
+static void wget_lwip_fill_info(struct pbuf *hdr, u16_t hdr_len, u64_t hdr_cont_len)
 {
 	if (wget_info->headers) {
 		if (hdr_len < MAX_HTTP_HEADERS_SIZE)
@@ -51,10 +52,11 @@ static void wget_lwip_fill_info(struct pbuf *hdr, u16_t hdr_len, u32_t hdr_cont_
 			hdr_len = 0;
 		wget_info->headers[hdr_len] = 0;
 	}
-	wget_info->hdr_cont_len = (u32)hdr_cont_len;
+	/* hdr_cont_len is 32 bits: a longer length gets the value of none */
+	wget_info->hdr_cont_len = min_t(u64, hdr_cont_len, U32_MAX);
 }
 
-static void wget_lwip_set_file_size(u32_t rx_content_len)
+static void wget_lwip_set_file_size(u64_t rx_content_len)
 {
 	wget_info->file_size = (ulong)rx_content_len;
 }
@@ -154,7 +156,7 @@ static int store_block(struct wget_ctx *ctx, void *src, u16_t len)
 {
 	ulong store_addr = ctx->daddr;
 	uchar *ptr;
-	ulong pos;
+	u64 pos;
 
 	/* Avoid overflow */
 	if (wget_info->buffer_size && wget_info->buffer_size < ctx->size + len)
@@ -181,9 +183,10 @@ static int store_block(struct wget_ctx *ctx, void *src, u16_t len)
 	if (wget_info->silent)
 		return 0;
 
-	pos = clamp(ctx->size, 0UL, ctx->content_len);
+	pos = min(ctx->size, ctx->content_len);
 
-	while (ctx->hash_count < pos * 50 / ctx->content_len) {
+	while (ctx->content_len &&
+	       ctx->hash_count < div64_u64(pos * 50, ctx->content_len)) {
 		putc('#');
 		ctx->hash_count++;
 	}
@@ -260,8 +263,8 @@ static void httpc_result_cb(void *arg, httpc_result_t httpc_result,
 	if (!wget_info->silent) {
 		printf("\n%u bytes transferred in %lu ms (", rx_content_len,
 		       elapsed);
-		print_size(rx_content_len / elapsed * 1000, "/s)\n");
-		printf("Bytes transferred = %lu (%lx hex)\n", ctx->size,
+		print_size(div_u64(rx_content_len, elapsed) * 1000, "/s)\n");
+		printf("Bytes transferred = %llu (%llx hex)\n", ctx->size,
 		       ctx->size);
 	}
 	if (wget_info->set_bootdev)
@@ -287,7 +290,7 @@ static err_t httpc_headers_done_cb(httpc_state_t *connection, void *arg, struct
 
 	if (wget_info->check_buffer_size &&
 	    content_len != HTTPC_CONTENT_LEN_INVALID &&
-	    (ulong)content_len > wget_info->buffer_size)
+	    content_len > wget_info->buffer_size)
 		return ERR_BUF;
 
 	ctx->content_len = content_len;

-- 
2.43.0

