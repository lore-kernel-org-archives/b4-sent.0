From: Igor Velkov <iav@iav.lv>
Date: Mon, 23 Nov 2026 04:03:17 +0000
Subject: [PATCH v2 2/8] net: lwip: wget: accept a reply without
 Content-Length in the size check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-wget-blk-r4-v2-2-073d800a5aaa@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1562; i=iav@iav.lv;
 h=from:subject:message-id; bh=ETSxIbVEcwmENePM4/U6sbJkihZFPwM4HjLMia8Lmh0=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNnMu9m+7Td9KpzOkWKfsl22YkrwvN3ua3kDn8i1WycvT
 jHh/pHSUcrCIMbFICumyDLhkMatjCVX//p7mD+AmcPKBDKEgYtTACbydj/Db5Z/YUWXGa0cZFWr
 Hwttq+3rNA4V37hw/9440UT/qytbGxkZzh6R6uqaeqmAp0TVqZLpTvgO2aydYg852n135s56fD+
 YFwA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

lwIP passes 0xffffffff as the content length when a reply has no usable
Content-Length header. With check_buffer_size set, wget compares that
value with the buffer size and refuses the download whenever the
buffer is smaller than 4 GiB, before any data arrives.

Skip the check when the length is unknown, as the legacy wget does.
store_block() still stops a download that outgrows the buffer. Writing
the download to a block device, later in this series, sets
check_buffer_size and needs this for a reply without a length.

EFI HTTP is the one client that sets check_buffer_size so far. lwIP
wget sends its HEAD requests as GET, into a 64 KiB buffer. Without a
length, a body above 64 KiB now fails that request when the buffer
fills, with status 0 instead of 200. A GET without a length still asks
for a 4 GiB buffer, as before.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 net/lwip/wget.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/net/lwip/wget.c b/net/lwip/wget.c
index 96ee600c5e1..f0ba9b3d1ab 100644
--- a/net/lwip/wget.c
+++ b/net/lwip/wget.c
@@ -285,7 +285,9 @@ static err_t httpc_headers_done_cb(httpc_state_t *connection, void *arg, struct
 
 	wget_lwip_fill_info(hdr, hdr_len, content_len);
 
-	if (wget_info->check_buffer_size && (ulong)content_len > wget_info->buffer_size)
+	if (wget_info->check_buffer_size &&
+	    content_len != HTTPC_CONTENT_LEN_INVALID &&
+	    (ulong)content_len > wget_info->buffer_size)
 		return ERR_BUF;
 
 	ctx->content_len = content_len;

-- 
2.43.0

