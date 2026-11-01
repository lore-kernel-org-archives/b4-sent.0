From: Igor Velkov <iav@iav.lv>
Date: Sun, 01 Nov 2026 07:53:23 +0200
Subject: [PATCH 1/4] net: lwip: wget: accept a reply without Content-Length
 in the size check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b4-wget-blk-r4-v1-1-e27a009e4043@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1460; i=iav@iav.lv;
 h=from:subject:message-id; bh=TDF9ci9SZKFcxvNZwjYU/0WyvOpe+mObPBtoevX1nRA=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnPLl+ZovaepyXj6qmVT3bNN6/0f9ExledQr1f5Sb1tf
 GxpX5be6ihlYRDjYpAVU2SZcEjjVsaSq3/9PcwfwMxhZQIZwsDFKQAT8QxiZOhUe83Ae0fsj9ii
 PzMUZvb4u+z6tJzr3D/Dp8Gico2yBksZ/gppTxVtKd+a88irzHt/YKdW1SEX38l92fveS/QcFAg
 W4gMA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

lwIP passes 0xffffffff as the content length when a reply has no usable
Content-Length header. With check_buffer_size set, wget compares that
value with the buffer size and refuses the download whenever the
buffer is smaller than 4 GiB, before any data arrives.

Skip the check when the length is unknown, as the legacy wget does.
store_block() still stops a download that outgrows the buffer.

Fixes: 1327c2a8d651 ("net/lwip: wget: integrate struct wget_info into wget code")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 net/lwip/wget.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/net/lwip/wget.c b/net/lwip/wget.c
index 96ee600c5e1..615ea035a28 100644
--- a/net/lwip/wget.c
+++ b/net/lwip/wget.c
@@ -6,6 +6,7 @@
 #include <display_options.h>
 #include <efi_loader.h>
 #include <env.h>
+#include <limits.h>
 #include <linux/kconfig.h>
 #include <lwip/apps/http_client.h>
 #include "lwip/altcp_tls.h"
@@ -285,7 +286,9 @@ static err_t httpc_headers_done_cb(httpc_state_t *connection, void *arg, struct
 
 	wget_lwip_fill_info(hdr, hdr_len, content_len);
 
-	if (wget_info->check_buffer_size && (ulong)content_len > wget_info->buffer_size)
+	/* lwIP passes U32_MAX when the reply has no usable Content-Length */
+	if (wget_info->check_buffer_size && content_len != U32_MAX &&
+	    (ulong)content_len > wget_info->buffer_size)
 		return ERR_BUF;
 
 	ctx->content_len = content_len;

-- 
2.43.0

