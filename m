From: Igor Velkov <iav@iav.lv>
Date: Mon, 23 Nov 2026 04:03:20 +0000
Subject: [PATCH v2 5/8] net: lwip: find Content-Length whatever its case
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-wget-blk-r4-v2-5-073d800a5aaa@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3980; i=iav@iav.lv;
 h=from:subject:message-id; bh=Z3h3Kvm50eRr8NesbrJTlyqNQpuFDH8M8H2KGyD8ZYM=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNnMu9l7i9p+G9Z5v3FsOHFUVvxYRP/5NV9OPra5/nh+z
 8TaFXWhHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiqnsYGS6ueL50fe/T7prG
 TD+W+CVHqz3Cui/ZMRwUOPX2YqUcgxojw7aNxRNFznmkuJ073PWk9ut187NH1BSX2a/ddup131n
 nWVwA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HTTP client looks for the exact string "Content-Length: " in the
reply. RFC 9110 (5.1) says "Field names are case-insensitive", and in
the field-line rule of RFC 9112 (5) the whitespace after the colon is
optional. A reply with "content-length: 3000000" or
"CONTENT-LENGTH:3000000" reads as one without a length: wget does not
check that the file fits, and a download that the server cuts short
ends with HTTPC_RESULT_OK.

Find the header line by its name without regard to case, and skip
spaces and tabs before the value. The search runs from the start of a
line and stops at the end of the headers: the old one also matched the
string inside another header name, such as X-Foo-Content-Length, or in
the body.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 lib/lwip/lwip/src/apps/http/http_client.c | 42 ++++++++++++++++++++++++++++---
 1 file changed, 38 insertions(+), 4 deletions(-)

diff --git a/lib/lwip/lwip/src/apps/http/http_client.c b/lib/lwip/lwip/src/apps/http/http_client.c
index 29afa8bf655..7914b7cc5aa 100644
--- a/lib/lwip/lwip/src/apps/http/http_client.c
+++ b/lib/lwip/lwip/src/apps/http/http_client.c
@@ -294,6 +294,40 @@ http_parse_response_status(struct pbuf *p, u16_t *http_version, u16_t *http_stat
   return ERR_VAL;
 }
 
+/** Find a header line by its name and return the offset of its value, or
+ * 0xFFFF. A field name is case-insensitive (RFC 9110, 5.1) and whitespace
+ * before the value is optional (RFC 9112, 5). 'name' is in lower case, 'end'
+ * is the offset of the end of the headers. */
+static u16_t
+http_find_header(struct pbuf *p, const char *name, u16_t end)
+{
+  u16_t name_len = (u16_t)strlen(name);
+  /* the first line is the status line */
+  u16_t pos = pbuf_memfind(p, "\r\n", 2, 0);
+
+  while (pos < end) {
+    u16_t i;
+    char c;
+
+    pos = (u16_t)(pos + 2);
+    for (i = 0; i < name_len; i++) {
+      c = (char)pbuf_get_at(p, (u16_t)(pos + i));
+      if (lwip_tolower(c) != name[i]) {
+        break;
+      }
+    }
+    if ((i == name_len) && (pbuf_get_at(p, (u16_t)(pos + i)) == ':')) {
+      pos = (u16_t)(pos + name_len + 1);
+      while ((pbuf_get_at(p, pos) == ' ') || (pbuf_get_at(p, pos) == '\t')) {
+        pos++;
+      }
+      return pos;
+    }
+    pos = pbuf_memfind(p, "\r\n", 2, pos);
+  }
+  return 0xFFFF;
+}
+
 /** Wait for all headers to be received, return its length and content-length (if available) */
 static err_t
 http_wait_headers(struct pbuf *p, u64_t *content_length, u16_t *total_header_len)
@@ -301,19 +335,19 @@ http_wait_headers(struct pbuf *p, u64_t *content_length, u16_t *total_header_len
   u16_t end1 = pbuf_memfind(p, "\r\n\r\n", 4, 0);
   if (end1 < (0xFFFF - 2)) {
     /* all headers received */
-    /* check if we have a content length (@todo: case insensitive?) */
+    /* check if we have a content length */
     u16_t content_len_hdr;
     *content_length = HTTPC_CONTENT_LEN_INVALID;
     *total_header_len = end1 + 4;
 
-    content_len_hdr = pbuf_memfind(p, "Content-Length: ", 16, 0);
+    content_len_hdr = http_find_header(p, "content-length", end1);
     if (content_len_hdr != 0xFFFF) {
       u16_t content_len_line_end = pbuf_memfind(p, "\r\n", 2, content_len_hdr);
       if (content_len_line_end != 0xFFFF) {
         char content_len_num[16];
-        u16_t content_len_num_len = (u16_t)(content_len_line_end - content_len_hdr - 16);
+        u16_t content_len_num_len = (u16_t)(content_len_line_end - content_len_hdr);
         if (content_len_num_len < sizeof(content_len_num)) {
-          if (pbuf_copy_partial(p, content_len_num, content_len_num_len, content_len_hdr + 16) == content_len_num_len) {
+          if (pbuf_copy_partial(p, content_len_num, content_len_num_len, content_len_hdr) == content_len_num_len) {
             u64_t len = 0;
             u16_t i;
             /* at most 15 digits fit in content_len_num: no overflow */

-- 
2.43.0

