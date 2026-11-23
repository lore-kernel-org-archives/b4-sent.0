From: Igor Velkov <iav@iav.lv>
Date: Mon, 23 Nov 2026 04:03:16 +0000
Subject: [PATCH v2 1/8] net: lwip: move HTTPC_CONTENT_LEN_INVALID to
 http_client.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-wget-blk-r4-v2-1-073d800a5aaa@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2346; i=iav@iav.lv;
 h=from:subject:message-id; bh=I0WSHlQEBZMTKu3wIKgA7J/V/0zbYXGn/rWQDSqBYc8=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNnMu1kPnDty8CRPTmLJjP2S73bHLvfXLH61g6tvwvmEM
 zmP2phaOkpZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBE9LYw/K/xe5oSliN6eK/+
 79TEGfU67f+7HHL84xYwZobN2N/9ro/hn6rPJWM7V5UPZ4VXnWmO949f3cInszKt661esue1w+7
 MfAA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HTTP client passes HTTPC_CONTENT_LEN_INVALID to the headers callback
when a reply has no usable Content-Length, but the value is defined in
http_client.c only, and the header documents it as -1. Move the define
to the header, so that a callback can test for it by name.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 lib/lwip/lwip/src/apps/http/http_client.c         |  2 --
 lib/lwip/lwip/src/include/lwip/apps/http_client.h | 10 +++++++++-
 2 files changed, 9 insertions(+), 3 deletions(-)

diff --git a/lib/lwip/lwip/src/apps/http/http_client.c b/lib/lwip/lwip/src/apps/http/http_client.c
index 6ed739e13fd..06533c55c22 100644
--- a/lib/lwip/lwip/src/apps/http/http_client.c
+++ b/lib/lwip/lwip/src/apps/http/http_client.c
@@ -87,8 +87,6 @@
 #define HTTPC_POLL_INTERVAL     1
 #define HTTPC_POLL_TIMEOUT      30 /* 15 seconds */
 
-#define HTTPC_CONTENT_LEN_INVALID 0xFFFFFFFF
-
 /* GET request basic */
 #define HTTPC_REQ_11 "GET %s HTTP/1.1\r\n" /* URI */\
     "User-Agent: %s\r\n" /* User-Agent */ \
diff --git a/lib/lwip/lwip/src/include/lwip/apps/http_client.h b/lib/lwip/lwip/src/include/lwip/apps/http_client.h
index 50403fb4cb3..322e51cc852 100644
--- a/lib/lwip/lwip/src/include/lwip/apps/http_client.h
+++ b/lib/lwip/lwip/src/include/lwip/apps/http_client.h
@@ -67,6 +67,13 @@ extern "C" {
  */
 #define HTTP_DEFAULT_PORT         LWIP_IANA_PORT_HTTP
 
+/**
+ * @ingroup httpc
+ * Content length that the headers callback gets when the client read none
+ * from the reply
+ */
+#define HTTPC_CONTENT_LEN_INVALID 0xFFFFFFFF
+
 /**
  * @ingroup httpc
  * HTTP client result codes
@@ -117,7 +124,8 @@ typedef void (*httpc_result_fn)(void *arg, httpc_result_t httpc_result, u32_t rx
  * @param arg argument specified when initiating the request
  * @param hdr header pbuf(s) (may contain data also)
  * @param hdr_len length of the headers in 'hdr'
- * @param content_len content length as received in the headers (-1 if not received)
+ * @param content_len content length as received in the headers
+ *                    (HTTPC_CONTENT_LEN_INVALID if not received)
  * @return if != ERR_OK is returned, the connection is aborted
  */
 typedef err_t (*httpc_headers_done_fn)(httpc_state_t *connection, void *arg, struct pbuf *hdr, u16_t hdr_len, u32_t content_len);

-- 
2.43.0

