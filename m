From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Date: Mon, 23 Nov 2026 17:30:44 +0100
Subject: [meta-webserver][scarthgap][PATCH 5/5] nginx: fix for
 CVE-2026-113425
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-fix_nginx2root-v1-5-1b30332ed757@belden.com>
References: <20261123-fix_nginx2root-v1-0-1b30332ed757@belden.com>
In-Reply-To: <20261123-fix_nginx2root-v1-0-1b30332ed757@belden.com>
To: openembedded-devel@lists.openembedded.org
Cc: Patrick Vogelaar <patrick.vogelaar@belden.com>, 
 patrick.vogelaar.dev@mailbox.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795451453; l=19523;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=bOBqLCZWpnZg6p/zIFDYxdGRnhGDx9i08rXRsGKspSE=;
 b=tBGtTe7PSm+/xp8QsVdSJ7OvX++2w6VD9iStx3GYyiMJ2K8FQ5rTlp8JMnMXcky0LqGejVohn
 odOUdVm/j6XBLB3wdusp43OPpJhFLK2TceIYI83RTC2baA6nDvUG2ls
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pick patch [0], [1], [2], [3] and [4] as mentioned in [5].

[0] https://github.com/nginx/nginx/commit/9e811a43119ac902f0d0296fb4afb34bb063cf1b
[1] https://github.com/nginx/nginx/commit/df9d8d940ecb83a50b1e55ccc296d0a29cfe774c
[2] https://github.com/nginx/nginx/commit/e2d23d45fa93ed236a9cdedcb54271e0a064c4f3
[3] https://github.com/nginx/nginx/commit/5deda780a9d5d1bcd5c6731d3118fa090ae900cc
[4] https://github.com/nginx/nginx/commit/4c5ace9f1d5419334a2e6772a0885ee7ed3d6e91
[5] https://security-tracker.debian.org/tracker/CVE-2026-113425

Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
 .../nginx/nginx-1.26.3/CVE-2026-113425-01.patch    |  94 +++++++++++++++++
 .../nginx/nginx-1.26.3/CVE-2026-113425-02.patch    |  44 ++++++++
 .../nginx/nginx-1.26.3/CVE-2026-113425-03.patch    |  87 ++++++++++++++++
 .../nginx/nginx-1.26.3/CVE-2026-113425-04.patch    |  72 +++++++++++++
 .../nginx/nginx-1.26.3/CVE-2026-113425-05.patch    | 116 +++++++++++++++++++++
 meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb |   5 +
 6 files changed, 418 insertions(+)

diff --git a/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-01.patch b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-01.patch
new file mode 100644
index 0000000000..17bf039918
--- /dev/null
+++ b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-01.patch
@@ -0,0 +1,94 @@
+From cb07812b72e5f90a159a0e81e4669a115e8a2c2c Mon Sep 17 00:00:00 2001
+From: Maxim Dounin <mdounin@mdounin.ru>
+Date: Sat, 20 Jun 2026 05:04:41 +0300
+Subject: [PATCH 06/10] Mail: updated ngx_mail_send() to set handlers on
+ s->quit.
+
+Most notably, this fixes potential issues when a fatal error message is
+sent with ngx_mail_send() with s->quit set, but the read handler is not
+updated.  Despite s->quit, ngx_mail_send() might not be able to send the
+error message immediately, and the read handler might be called on read
+events.  In particular, in ngx_mail_auth_http_block_read() and in
+ngx_mail_proxy_block_read() this could potentially cause accesses to
+freed memory or already closed connections in ngx_handle_read_event()
+error handling code paths.
+
+Reported by Evan Hellman,
+https://github.com/freenginx/nginx/issues/23
+https://github.com/freenginx/nginx/issues/24
+
+Signed-off-by: Vadim Zhestikov <v.zhestikov@f5.com>
+Origin: <https://freenginx.org/hg/nginx/rev/87725983f346>
+
+(cherry picked from commit 9e811a43119ac902f0d0296fb4afb34bb063cf1b)
+CVE:CVE-2026-113425
+Upstream-Status: Backport [https://github.com/nginx/nginx/commit/9e811a43119ac902f0d0296fb4afb34bb063cf1b]
+
+Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
+---
+ src/mail/ngx_mail_handler.c | 21 +++++++++++++++++----
+ 1 file changed, 17 insertions(+), 4 deletions(-)
+
+diff --git a/src/mail/ngx_mail_handler.c b/src/mail/ngx_mail_handler.c
+index 1167df3fb..5a8b59446 100644
+--- a/src/mail/ngx_mail_handler.c
++++ b/src/mail/ngx_mail_handler.c
+@@ -14,6 +14,7 @@
+ static void ngx_mail_proxy_protocol_handler(ngx_event_t *rev);
+ static void ngx_mail_init_session_handler(ngx_event_t *rev);
+ static void ngx_mail_init_session(ngx_connection_t *c);
++static void ngx_mail_block_read(ngx_event_t *rev);
+ 
+ #if (NGX_MAIL_SSL)
+ static void ngx_mail_ssl_init_connection(ngx_ssl_t *ssl, ngx_connection_t *c);
+@@ -415,8 +416,6 @@ ngx_mail_verify_cert(ngx_mail_session_t *s, ngx_connection_t *c)
+         s->out = cscf->protocol->cert_error;
+         s->quit = 1;
+ 
+-        c->write->handler = ngx_mail_send;
+-
+         ngx_mail_send(s->connection->write);
+         return NGX_ERROR;
+     }
+@@ -436,8 +435,6 @@ ngx_mail_verify_cert(ngx_mail_session_t *s, ngx_connection_t *c)
+             s->out = cscf->protocol->no_cert;
+             s->quit = 1;
+ 
+-            c->write->handler = ngx_mail_send;
+-
+             ngx_mail_send(s->connection->write);
+             return NGX_ERROR;
+         }
+@@ -818,6 +815,11 @@ again:
+ 
+     ngx_add_timer(c->write, cscf->timeout);
+ 
++    if (s->quit) {
++        c->read->handler = ngx_mail_block_read;
++        c->write->handler = ngx_mail_send;
++    }
++
+     if (ngx_handle_write_event(c->write, 0) != NGX_OK) {
+         ngx_mail_close_connection(c);
+         return;
+@@ -936,6 +938,17 @@ ngx_mail_session_internal_server_error(ngx_mail_session_t *s)
+ }
+ 
+ 
++static void
++ngx_mail_block_read(ngx_event_t *rev)
++{
++    ngx_log_debug0(NGX_LOG_DEBUG_MAIL, rev->log, 0, "mail block read");
++
++    if (ngx_handle_read_event(rev, 0) != NGX_OK) {
++        ngx_mail_close_connection(rev->data);
++    }
++}
++
++
+ void
+ ngx_mail_close_connection(ngx_connection_t *c)
+ {
+-- 
+2.43.0
+
diff --git a/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-02.patch b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-02.patch
new file mode 100644
index 0000000000..b0a2ed8946
--- /dev/null
+++ b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-02.patch
@@ -0,0 +1,44 @@
+From 602d172c5721bfcfb116314e18ef07ac7c96bdc7 Mon Sep 17 00:00:00 2001
+From: Vadim Zhestikov <v.zhestikov@f5.com>
+Date: Wed, 4 Nov 2026 09:54:11 -0800
+Subject: [PATCH 07/10] Mail: fixed use-after-free on client reset during
+ auth_http request
+
+When a client command starts an auth_http request, the default reply
+set by the POP3, IMAP and SMTP auth state handlers remains in s->out,
+though it is never used: the actual reply depends on the auth_http
+response.  With ngx_mail_send() as the client write handler, the reply
+could be sent before the authentication result was known, and if the
+client reset the connection, the failed send destroyed the session
+while the auth_http connection still referenced it.
+
+The queued reply is now discarded when the auth_http request starts,
+similarly to ngx_mail_proxy_init().
+
+Reported by Xint.io.
+
+(cherry picked from commit df9d8d940ecb83a50b1e55ccc296d0a29cfe774c)
+CVE:CVE-2026-113425
+Upstream-Status: Backport [https://github.com/nginx/nginx/commit/df9d8d940ecb83a50b1e55ccc296d0a29cfe774c]
+
+Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
+---
+ src/mail/ngx_mail_auth_http_module.c | 2 ++
+ 1 file changed, 2 insertions(+)
+
+diff --git a/src/mail/ngx_mail_auth_http_module.c b/src/mail/ngx_mail_auth_http_module.c
+index 27f64b92e..0e8b5209c 100644
+--- a/src/mail/ngx_mail_auth_http_module.c
++++ b/src/mail/ngx_mail_auth_http_module.c
+@@ -216,6 +216,8 @@ ngx_mail_auth_http_init(ngx_mail_session_t *s)
+     ctx->peer.connection->data = s;
+     ctx->peer.connection->pool = s->connection->pool;
+ 
++    s->out.len = 0;
++
+     s->connection->read->handler = ngx_mail_auth_http_block_read;
+     ctx->peer.connection->read->handler = ngx_mail_auth_http_read_handler;
+     ctx->peer.connection->write->handler = ngx_mail_auth_http_write_handler;
+-- 
+2.43.0
+
diff --git a/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-03.patch b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-03.patch
new file mode 100644
index 0000000000..e9b67e1559
--- /dev/null
+++ b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-03.patch
@@ -0,0 +1,87 @@
+From 4c09e093caaabc001fa129c52caeec0d48364499 Mon Sep 17 00:00:00 2001
+From: Vadim Zhestikov <v.zhestikov@f5.com>
+Date: Wed, 4 Nov 2026 09:54:11 -0800
+Subject: [PATCH 08/10] Mail: blocked client writes while waiting for auth_http
+ response
+
+While waiting for the auth_http response, the client read handler is
+ngx_mail_auth_http_block_read(), but the write handler was left as
+ngx_mail_send(), so a client write event during the wait was handled
+by a function which can close the client connection, destroying the
+session while the auth_http connection still referenced it.
+
+The client write handler is now blocked while waiting for the auth_http
+response, with proper cleanup on errors, and restored right after the
+auth_http connection is closed.
+
+(cherry picked from commit e2d23d45fa93ed236a9cdedcb54271e0a064c4f3)
+CVE:CVE-2026-113425
+Upstream-Status: Backport [https://github.com/nginx/nginx/commit/e2d23d45fa93ed236a9cdedcb54271e0a064c4f3]
+
+Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
+---
+ src/mail/ngx_mail_auth_http_module.c | 27 +++++++++++++++++++++++++++
+ 1 file changed, 27 insertions(+)
+
+diff --git a/src/mail/ngx_mail_auth_http_module.c b/src/mail/ngx_mail_auth_http_module.c
+index 0e8b5209c..58f7ee61b 100644
+--- a/src/mail/ngx_mail_auth_http_module.c
++++ b/src/mail/ngx_mail_auth_http_module.c
+@@ -70,6 +70,7 @@ static void ngx_mail_auth_sleep_handler(ngx_event_t *rev);
+ static ngx_int_t ngx_mail_auth_http_parse_header_line(ngx_mail_session_t *s,
+     ngx_mail_auth_http_ctx_t *ctx);
+ static void ngx_mail_auth_http_block_read(ngx_event_t *rev);
++static void ngx_mail_auth_http_block_write(ngx_event_t *wev);
+ static void ngx_mail_auth_http_dummy_handler(ngx_event_t *ev);
+ static ngx_buf_t *ngx_mail_auth_http_create_request(ngx_mail_session_t *s,
+     ngx_pool_t *pool, ngx_mail_auth_http_conf_t *ahcf);
+@@ -219,6 +220,7 @@ ngx_mail_auth_http_init(ngx_mail_session_t *s)
+     s->out.len = 0;
+ 
+     s->connection->read->handler = ngx_mail_auth_http_block_read;
++    s->connection->write->handler = ngx_mail_auth_http_block_write;
+     ctx->peer.connection->read->handler = ngx_mail_auth_http_read_handler;
+     ctx->peer.connection->write->handler = ngx_mail_auth_http_write_handler;
+ 
+@@ -690,6 +692,8 @@ ngx_mail_auth_http_process_headers(ngx_mail_session_t *s,
+ 
+             ngx_close_connection(ctx->peer.connection);
+ 
++            s->connection->write->handler = ngx_mail_send;
++
+             if (ctx->err.len) {
+ 
+                 ngx_log_error(NGX_LOG_INFO, s->connection->log, 0,
+@@ -1122,6 +1126,29 @@ ngx_mail_auth_http_block_read(ngx_event_t *rev)
+ }
+ 
+ 
++static void
++ngx_mail_auth_http_block_write(ngx_event_t *wev)
++{
++    ngx_connection_t          *c;
++    ngx_mail_session_t        *s;
++    ngx_mail_auth_http_ctx_t  *ctx;
++
++    ngx_log_debug0(NGX_LOG_DEBUG_MAIL, wev->log, 0,
++                   "mail auth http block write");
++
++    if (ngx_handle_write_event(wev, 0) != NGX_OK) {
++        c = wev->data;
++        s = c->data;
++
++        ctx = ngx_mail_get_module_ctx(s, ngx_mail_auth_http_module);
++
++        ngx_close_connection(ctx->peer.connection);
++        ngx_destroy_pool(ctx->pool);
++        ngx_mail_session_internal_server_error(s);
++    }
++}
++
++
+ static void
+ ngx_mail_auth_http_dummy_handler(ngx_event_t *ev)
+ {
+-- 
+2.43.0
+
diff --git a/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-04.patch b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-04.patch
new file mode 100644
index 0000000000..b38c34564a
--- /dev/null
+++ b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-04.patch
@@ -0,0 +1,72 @@
+From 24408a432f0110f3baf78e306198ebe35d61d82f Mon Sep 17 00:00:00 2001
+From: Vadim Zhestikov <v.zhestikov@f5.com>
+Date: Wed, 4 Nov 2026 09:54:11 -0800
+Subject: [PATCH 09/10] Mail: blocked client writes while connecting to
+ upstream
+
+While connecting to the upstream and reading its greeting, the client
+read handler is ngx_mail_proxy_block_read(), but the client write
+handler was left as it was.  If ngx_handle_write_event() failed in it,
+the client connection was closed without the upstream one, and the next
+upstream event accessed the freed session.
+
+The client write handler is now ngx_mail_proxy_block_write(), which
+closes both connections on errors the same way
+ngx_mail_proxy_block_read() does.
+
+(cherry picked from commit 5deda780a9d5d1bcd5c6731d3118fa090ae900cc)
+CVE: CVE-2026-113425
+Upstream-Status: Backport [https://github.com/nginx/nginx/commit/5deda780a9d5d1bcd5c6731d3118fa090ae900cc]
+
+Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
+---
+ src/mail/ngx_mail_proxy_module.c | 19 +++++++++++++++++++
+ 1 file changed, 19 insertions(+)
+
+diff --git a/src/mail/ngx_mail_proxy_module.c b/src/mail/ngx_mail_proxy_module.c
+index efed9ab3e..de09f2ad3 100644
+--- a/src/mail/ngx_mail_proxy_module.c
++++ b/src/mail/ngx_mail_proxy_module.c
+@@ -24,6 +24,7 @@ typedef struct {
+ 
+ 
+ static void ngx_mail_proxy_block_read(ngx_event_t *rev);
++static void ngx_mail_proxy_block_write(ngx_event_t *wev);
+ static void ngx_mail_proxy_pop3_handler(ngx_event_t *rev);
+ static void ngx_mail_proxy_imap_handler(ngx_event_t *rev);
+ static void ngx_mail_proxy_smtp_handler(ngx_event_t *rev);
+@@ -165,6 +166,7 @@ ngx_mail_proxy_init(ngx_mail_session_t *s, ngx_addr_t *peer)
+     p->upstream.connection->pool = s->connection->pool;
+ 
+     s->connection->read->handler = ngx_mail_proxy_block_read;
++    s->connection->write->handler = ngx_mail_proxy_block_write;
+     p->upstream.connection->write->handler = ngx_mail_proxy_write_handler;
+ 
+     pcf = ngx_mail_get_module_srv_conf(s, ngx_mail_proxy_module);
+@@ -223,6 +225,23 @@ ngx_mail_proxy_block_read(ngx_event_t *rev)
+ }
+ 
+ 
++static void
++ngx_mail_proxy_block_write(ngx_event_t *wev)
++{
++    ngx_connection_t    *c;
++    ngx_mail_session_t  *s;
++
++    ngx_log_debug0(NGX_LOG_DEBUG_MAIL, wev->log, 0, "mail proxy block write");
++
++    if (ngx_handle_write_event(wev, 0) != NGX_OK) {
++        c = wev->data;
++        s = c->data;
++
++        ngx_mail_proxy_close_session(s);
++    }
++}
++
++
+ static void
+ ngx_mail_proxy_pop3_handler(ngx_event_t *rev)
+ {
+-- 
+2.43.0
+
diff --git a/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-05.patch b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-05.patch
new file mode 100644
index 0000000000..5636eabdc8
--- /dev/null
+++ b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-113425-05.patch
@@ -0,0 +1,116 @@
+From 092dab10a5ba4d5d8e951a6284fc493915ef5e34 Mon Sep 17 00:00:00 2001
+From: Vadim Zhestikov <v.zhestikov@f5.com>
+Date: Wed, 4 Nov 2026 09:54:11 -0800
+Subject: [PATCH 10/10] Mail: blocked client writes while resolving SMTP client
+
+While the SMTP client address and name are being resolved, the client
+read handler is ngx_mail_smtp_block_reading(), but the client write
+handler was ngx_mail_send().  If ngx_handle_write_event() failed in it,
+the client connection was closed, but the resolver context was not
+cancelled, and the resolver handler accessed the freed session when the
+resolving completed or timed out.
+
+The client write handler is now ngx_mail_smtp_block_writing(), which
+cancels the resolver context on errors the same way
+ngx_mail_smtp_block_reading() does.  ngx_mail_send() is restored in
+ngx_mail_smtp_greeting(), which is also needed with smtp_greeting_delay,
+where the error is sent without s->quit, and in
+ngx_mail_smtp_resolve_addr_handler() before the posted name resolving,
+where s->resolver_ctx still points to a context which is already done.
+
+(cherry picked from commit 4c5ace9f1d5419334a2e6772a0885ee7ed3d6e91)
+CVE: CVE-2026-113425
+Upstream-Status: Backport [https://github.com/nginx/nginx/commit/4c5ace9f1d5419334a2e6772a0885ee7ed3d6e91]
+
+Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
+---
+ src/mail/ngx_mail_smtp_handler.c | 38 ++++++++++++++++++++++++++++++++
+ 1 file changed, 38 insertions(+)
+
+diff --git a/src/mail/ngx_mail_smtp_handler.c b/src/mail/ngx_mail_smtp_handler.c
+index e68ceedfd..d5b3408fd 100644
+--- a/src/mail/ngx_mail_smtp_handler.c
++++ b/src/mail/ngx_mail_smtp_handler.c
+@@ -16,6 +16,7 @@ static void ngx_mail_smtp_resolve_addr_handler(ngx_resolver_ctx_t *ctx);
+ static void ngx_mail_smtp_resolve_name(ngx_event_t *rev);
+ static void ngx_mail_smtp_resolve_name_handler(ngx_resolver_ctx_t *ctx);
+ static void ngx_mail_smtp_block_reading(ngx_event_t *rev);
++static void ngx_mail_smtp_block_writing(ngx_event_t *wev);
+ static void ngx_mail_smtp_greeting(ngx_mail_session_t *s, ngx_connection_t *c);
+ static void ngx_mail_smtp_invalid_pipelining(ngx_event_t *rev);
+ static ngx_int_t ngx_mail_smtp_create_buffer(ngx_mail_session_t *s,
+@@ -91,6 +92,7 @@ ngx_mail_smtp_init_session(ngx_mail_session_t *s, ngx_connection_t *c)
+ 
+     s->resolver_ctx = ctx;
+     c->read->handler = ngx_mail_smtp_block_reading;
++    c->write->handler = ngx_mail_smtp_block_writing;
+ 
+     if (ngx_resolve_addr(ctx) != NGX_OK) {
+         ngx_mail_close_connection(c);
+@@ -144,6 +146,7 @@ ngx_mail_smtp_resolve_addr_handler(ngx_resolver_ctx_t *ctx)
+                    "address resolved: %V", &s->host);
+ 
+     c->read->handler = ngx_mail_smtp_resolve_name;
++    c->write->handler = ngx_mail_send;
+ 
+     ngx_post_event(c->read, &ngx_posted_events);
+ }
+@@ -175,6 +178,7 @@ ngx_mail_smtp_resolve_name(ngx_event_t *rev)
+ 
+     s->resolver_ctx = ctx;
+     c->read->handler = ngx_mail_smtp_block_reading;
++    c->write->handler = ngx_mail_smtp_block_writing;
+ 
+     if (ngx_resolve_name(ctx) != NGX_OK) {
+         ngx_mail_close_connection(c);
+@@ -277,6 +281,38 @@ ngx_mail_smtp_block_reading(ngx_event_t *rev)
+ }
+ 
+ 
++static void
++ngx_mail_smtp_block_writing(ngx_event_t *wev)
++{
++    ngx_connection_t    *c;
++    ngx_mail_session_t  *s;
++    ngx_resolver_ctx_t  *ctx;
++
++    c = wev->data;
++    s = c->data;
++
++    ngx_log_debug0(NGX_LOG_DEBUG_MAIL, c->log, 0, "smtp writing blocked");
++
++    if (ngx_handle_write_event(wev, 0) != NGX_OK) {
++
++        if (s->resolver_ctx) {
++            ctx = s->resolver_ctx;
++
++            if (ctx->handler == ngx_mail_smtp_resolve_addr_handler) {
++                ngx_resolve_addr_done(ctx);
++
++            } else if (ctx->handler == ngx_mail_smtp_resolve_name_handler) {
++                ngx_resolve_name_done(ctx);
++            }
++
++            s->resolver_ctx = NULL;
++        }
++
++        ngx_mail_close_connection(c);
++    }
++}
++
++
+ static void
+ ngx_mail_smtp_greeting(ngx_mail_session_t *s, ngx_connection_t *c)
+ {
+@@ -301,6 +337,8 @@ ngx_mail_smtp_greeting(ngx_mail_session_t *s, ngx_connection_t *c)
+         ngx_post_event(c->read, &ngx_posted_events);
+     }
+ 
++    c->write->handler = ngx_mail_send;
++
+     if (sscf->greeting_delay) {
+          c->read->handler = ngx_mail_smtp_invalid_pipelining;
+          return;
+-- 
+2.43.0
+
diff --git a/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb b/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb
index 06c33d7846..856bc87492 100644
--- a/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb
+++ b/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb
@@ -13,6 +13,11 @@ SRC_URI:append = " \
                   file://CVE-2026-123634-02.patch \
                   file://CVE-2026-123633.patch \
                   file://CVE-2026-121810.patch \
+                  file://CVE-2026-113425-01.patch \
+                  file://CVE-2026-113425-02.patch \
+                  file://CVE-2026-113425-03.patch \
+                  file://CVE-2026-113425-04.patch \
+                  file://CVE-2026-113425-05.patch \
                   "
 
 SRC_URI[sha256sum] = "69ee2b237744036e61d24b836668aad3040dda461fe6f570f1787eab570c75aa"

-- 
2.43.0

