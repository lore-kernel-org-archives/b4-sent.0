From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Date: Mon, 23 Nov 2026 17:30:42 +0100
Subject: [meta-webserver][scarthgap][PATCH 3/5] nginx: fix for
 CVE-2026-123633
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-fix_nginx2root-v1-3-1b30332ed757@belden.com>
References: <20261123-fix_nginx2root-v1-0-1b30332ed757@belden.com>
In-Reply-To: <20261123-fix_nginx2root-v1-0-1b30332ed757@belden.com>
To: openembedded-devel@lists.openembedded.org
Cc: Patrick Vogelaar <patrick.vogelaar@belden.com>, 
 patrick.vogelaar.dev@mailbox.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795451453; l=3503;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=8ne8Hq06KrKlw3C0lbV9QNheDv1YKDvPDzLvmEPxz9o=;
 b=9nej8tvsik2E5fs8WUY68Yzp8ceoOkN6xh6NmpOuXy44JgoT2Kh6MQRiaJPh6aitm4AVsur4z
 3NBJ999awAKCSwB8TMpqe22sda+C+zAUjV3TP1NBxitGDlNBwwK5h5H
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pick patch [0] as mentioned in [1].

[0] https://github.com/nginx/nginx/commit/0c87dd1db413e440a4e3ef7ee8acc518509e8809
[1] https://security-tracker.debian.org/tracker/CVE-2026-123633

Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
 .../nginx/nginx-1.26.3/CVE-2026-123633.patch       | 52 ++++++++++++++++++++++
 meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb |  1 +
 2 files changed, 53 insertions(+)

diff --git a/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-123633.patch b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-123633.patch
new file mode 100644
index 0000000000..2656fdb2fd
--- /dev/null
+++ b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-123633.patch
@@ -0,0 +1,52 @@
+From af325f83ebfa3ed843f691c2542d58e321b8faad Mon Sep 17 00:00:00 2001
+From: Roman Arutyunyan <arut@nginx.com>
+Date: Thu, 17 Sep 2026 16:10:11 +0400
+Subject: [PATCH 02/10] HTTP/2: reset reusable connection status on stream
+ creation
+
+Previously, an HTTP/2 connection could be reusable while having streams.
+This could result in an attempt to drain the connection while processing
+one if its streams, for example when connecting to an upstream.  After
+recognizing that the connection has streams, an attempt to send the
+GOAWAY frame was made.  On send failure, the connection was immediately
+closed and its pool released.  This triggered a use-after-free up the
+stack.
+
+Having an HTTP/2 connection with streams registered as reusable became
+possible after 76672e650.  A connection with no streams and a partial
+frame read from client was registered as reusable to avoid DoS attacks.
+So if a client sends only the first HEADERS frame byte, the connection
+becomes reusable.  Later, when the remaining HEADERS bytes are received
+and a new stream is created, the reusable status is not reset until the
+connection becomes idle.
+
+Fix is to mark the connection non-reusable upon stream creation.
+
+Reported by Albert @ Vexera AI.
+
+(cherry picked from commit 0c87dd1db413e440a4e3ef7ee8acc518509e8809)
+
+CVE: CVE-2026-123633
+Upstream-Status: Backport [https://github.com/nginx/nginx/commit/0c87dd1db413e440a4e3ef7ee8acc518509e8809]
+
+Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
+---
+ src/http/v2/ngx_http_v2.c | 2 ++
+ 1 file changed, 2 insertions(+)
+
+diff --git a/src/http/v2/ngx_http_v2.c b/src/http/v2/ngx_http_v2.c
+index 7ab97bbf9..4a7395227 100644
+--- a/src/http/v2/ngx_http_v2.c
++++ b/src/http/v2/ngx_http_v2.c
+@@ -3091,6 +3091,8 @@ ngx_http_v2_create_stream(ngx_http_v2_connection_t *h2c)
+ 
+     h2c->processing++;
+ 
++    ngx_reusable_connection(h2c->connection, 0);
++
+     h2c->priority_limit += h2scf->concurrent_streams;
+ 
+     if (h2c->connection->read->timer_set) {
+-- 
+2.43.0
+
diff --git a/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb b/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb
index 2b392fd6d6..5d9fae672b 100644
--- a/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb
+++ b/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb
@@ -11,6 +11,7 @@ SRC_URI:append = " \
                   file://CVE-2026-123007.patch \
                   file://CVE-2026-123634-01.patch \
                   file://CVE-2026-123634-02.patch \
+                  file://CVE-2026-123633.patch \
                   "
 
 SRC_URI[sha256sum] = "69ee2b237744036e61d24b836668aad3040dda461fe6f570f1787eab570c75aa"

-- 
2.43.0

