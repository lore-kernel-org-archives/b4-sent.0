From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Date: Mon, 23 Nov 2026 17:30:40 +0100
Subject: [meta-webserver][scarthgap][PATCH 1/5] nginx: fix for
 CVE-2026-123007
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-fix_nginx2root-v1-1-1b30332ed757@belden.com>
References: <20261123-fix_nginx2root-v1-0-1b30332ed757@belden.com>
In-Reply-To: <20261123-fix_nginx2root-v1-0-1b30332ed757@belden.com>
To: openembedded-devel@lists.openembedded.org
Cc: Patrick Vogelaar <patrick.vogelaar@belden.com>, 
 patrick.vogelaar.dev@mailbox.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795451453; l=5389;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=sl+SYHio9pl1mwO2VG7JCTHtcn53Bo+ql8yxIo4agnI=;
 b=K+ZA10qVEQcHy1DHwxbn0g2LNijwGvH7hhX0Uy9ITszV2YRnnyHViFNd+68aLHACsda8hbTve
 bGKi0pZ5PTSDdJxZBY/xFZi0BtxtWer3QAdTNER64J1nNenllW4qiwC
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pick patch [0] as mentioned in [1].

[0] https://github.com/nginx/nginx/commit/b89c4100bf6762a45e4a6463eaf4b70368277c94
[1] https://security-tracker.debian.org/tracker/CVE-2026-123007

Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
 .../nginx/nginx-1.26.3/CVE-2026-123007.patch       | 95 ++++++++++++++++++++++
 meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb |  5 +-
 2 files changed, 99 insertions(+), 1 deletion(-)

diff --git a/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-123007.patch b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-123007.patch
new file mode 100644
index 0000000000..80c34af596
--- /dev/null
+++ b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-123007.patch
@@ -0,0 +1,95 @@
+From 2132cbc91feb99db7439ecd195d49f821469085b Mon Sep 17 00:00:00 2001
+From: Roman Arutyunyan <arut@nginx.com>
+Date: Thu, 29 Oct 2026 21:37:05 +0400
+Subject: [PATCH 01/10] HTTP/2: account for queued frames when validating
+ WINDOW_UPDATE
+
+When a stream is terminated, its unsent payload length is refunded back
+to the connection flow control.  Previously, this could increase the
+flow control beyond NGX_HTTP_V2_MAX_WINDOW, if it was increased by the
+client after the stream frames were queued and before the stream was
+terminated.  This eventually resulted in broken buffer size control in
+ngx_http_v2_send_chain() followed by memory corruption and a possible
+segmentation fault.
+
+The fix is to account for the queued frames when validating a client
+WINDOW_UPDATE.  From the client's point of view, the queued frames
+still belong to the flow control window.
+
+Reported by Xint.io.
+
+(cherry picked from commit b89c4100bf6762a45e4a6463eaf4b70368277c94)
+
+CVE: CVE-2026-123007
+Upstream-Status: Backport [https://github.com/nginx/nginx/commit/b89c4100bf6762a45e4a6463eaf4b70368277c94]
+
+Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
+---
+ src/http/v2/ngx_http_v2.c               | 4 ++--
+ src/http/v2/ngx_http_v2.h               | 1 +
+ src/http/v2/ngx_http_v2_filter_module.c | 3 +++
+ 3 files changed, 6 insertions(+), 2 deletions(-)
+
+diff --git a/src/http/v2/ngx_http_v2.c b/src/http/v2/ngx_http_v2.c
+index 0f5bd3de8..7ab97bbf9 100644
+--- a/src/http/v2/ngx_http_v2.c
++++ b/src/http/v2/ngx_http_v2.c
+@@ -2466,13 +2466,13 @@ ngx_http_v2_state_window_update(ngx_http_v2_connection_t *h2c, u_char *pos,
+         return ngx_http_v2_state_complete(h2c, pos, end);
+     }
+ 
+-    if (window > NGX_HTTP_V2_MAX_WINDOW - h2c->send_window) {
++    if (window > NGX_HTTP_V2_MAX_WINDOW - h2c->send_window - h2c->send_queued) {
+         ngx_log_error(NGX_LOG_INFO, h2c->connection->log, 0,
+                       "client violated connection flow control: "
+                       "received WINDOW_UPDATE frame "
+                       "with window increment %uz "
+                       "not allowed for window %uz",
+-                      window, h2c->send_window);
++                      window, h2c->send_window + h2c->send_queued);
+ 
+         return ngx_http_v2_connection_error(h2c, NGX_HTTP_V2_FLOW_CTRL_ERROR);
+     }
+diff --git a/src/http/v2/ngx_http_v2.h b/src/http/v2/ngx_http_v2.h
+index 6751b3026..a64599daf 100644
+--- a/src/http/v2/ngx_http_v2.h
++++ b/src/http/v2/ngx_http_v2.h
+@@ -136,6 +136,7 @@ struct ngx_http_v2_connection_s {
+     ngx_uint_t                       priority_limit;
+ 
+     size_t                           send_window;
++    size_t                           send_queued;
+     size_t                           recv_window;
+     size_t                           init_window;
+ 
+diff --git a/src/http/v2/ngx_http_v2_filter_module.c b/src/http/v2/ngx_http_v2_filter_module.c
+index 1e2cafaf1..c44954067 100644
+--- a/src/http/v2/ngx_http_v2_filter_module.c
++++ b/src/http/v2/ngx_http_v2_filter_module.c
+@@ -1028,6 +1028,7 @@ ngx_http_v2_send_chain(ngx_connection_t *fc, ngx_chain_t *in, off_t limit)
+             ngx_http_v2_queue_frame(h2c, frame);
+ 
+             h2c->send_window -= frame_size;
++            h2c->send_queued += frame_size;
+ 
+             stream->send_window -= frame_size;
+             stream->queued++;
+@@ -1423,6 +1424,7 @@ done:
+     stream->request->header_size += NGX_HTTP_V2_FRAME_HEADER_SIZE;
+ 
+     h2c->payload_bytes += frame->length;
++    h2c->send_queued -= frame->length;
+ 
+     ngx_http_v2_handle_frame(stream, frame);
+ 
+@@ -1557,6 +1559,7 @@ ngx_http_v2_filter_cleanup(void *data)
+     }
+ 
+     h2c->send_window += window;
++    h2c->send_queued -= window;
+ }
+ 
+ 
+-- 
+2.43.0
+
diff --git a/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb b/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb
index 658b1c0fce..18cd8bbfde 100644
--- a/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb
+++ b/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb
@@ -6,7 +6,10 @@ DEFAULT_PREFERENCE = "-1"
 
 LIC_FILES_CHKSUM = "file://LICENSE;md5=a6547d7e5628787ee2a9c5a3480eb628"
 
-SRC_URI:append = " file://CVE-2026-28755.patch"
+SRC_URI:append = " \
+                  file://CVE-2026-28755.patch \
+                  file://CVE-2026-123007.patch \
+                  "
 
 SRC_URI[sha256sum] = "69ee2b237744036e61d24b836668aad3040dda461fe6f570f1787eab570c75aa"
 

-- 
2.43.0

