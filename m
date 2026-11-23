From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Date: Mon, 23 Nov 2026 17:30:43 +0100
Subject: [meta-webserver][scarthgap][PATCH 4/5] nginx: fix for
 CVE-2026-121810
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-fix_nginx2root-v1-4-1b30332ed757@belden.com>
References: <20261123-fix_nginx2root-v1-0-1b30332ed757@belden.com>
In-Reply-To: <20261123-fix_nginx2root-v1-0-1b30332ed757@belden.com>
To: openembedded-devel@lists.openembedded.org
Cc: Patrick Vogelaar <patrick.vogelaar@belden.com>, 
 patrick.vogelaar.dev@mailbox.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795451453; l=4251;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=18cQc14sXjcoz9SOGDhlCsgkBBPFKk//JMh2eLUdK9A=;
 b=pC1SRYzhL3vC17QEv7HRKy6oX63q72HNN9G+HFGcQoySIFVSv6IjV0jCZFLwZzUeARoPQlSMe
 PqDX1PZrBn5CCXSPazhB8FMaBDWdInmBTYo8PJ7iBoCw+sHVmIUdoFP
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pick patch [0] as mentioned in [1].

[0] https://github.com/nginx/nginx/commit/c58d2a22d12350766185c94f2245bf4be5bcfb7d
[1] https://security-tracker.debian.org/tracker/CVE-2026-121810

Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
 .../nginx/nginx-1.26.3/CVE-2026-121810.patch       | 70 ++++++++++++++++++++++
 meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb |  1 +
 2 files changed, 71 insertions(+)

diff --git a/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-121810.patch b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-121810.patch
new file mode 100644
index 0000000000..5a360bcebf
--- /dev/null
+++ b/meta-webserver/recipes-httpd/nginx/nginx-1.26.3/CVE-2026-121810.patch
@@ -0,0 +1,70 @@
+From 834889f29f789880eb68d4a7b824dc7fd247f65b Mon Sep 17 00:00:00 2001
+From: Roman Arutyunyan <arut@nginx.com>
+Date: Sun, 1 Nov 2026 16:46:22 +0400
+Subject: [PATCH 05/10] QUIC: avoid main connection reuse after creating a
+ stream
+
+Previously, ngx_quic_create_stream() cleared the main connection's
+reusable flag and then called ngx_get_connection() before inserting the
+new stream into the tree.  If the worker was low on free connections,
+the drain inside ngx_get_connection() could close an idle stream of the
+same main connection.  Since the new stream was not in the tree yet,
+that close found no remaining streams and marked the main connection
+reusable again.  Once reusable, the connection could later be drained
+while processing one of its streams, for example when connecting to an
+upstream, freeing it while still in use.
+
+Fix is to insert the new stream into the tree before calling
+ngx_get_connection(), so the main connection is not considered idle.
+
+Reported by Xint.io.
+
+(cherry picked from commit c58d2a22d12350766185c94f2245bf4be5bcfb7d)
+CVE: CVE-2026-121810
+Upstream-Status: Backport [https://github.com/nginx/nginx/commit/c58d2a22d12350766185c94f2245bf4be5bcfb7d]
+
+Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
+---
+ src/event/quic/ngx_event_quic_streams.c | 6 ++++--
+ 1 file changed, 4 insertions(+), 2 deletions(-)
+
+diff --git a/src/event/quic/ngx_event_quic_streams.c b/src/event/quic/ngx_event_quic_streams.c
+index a9a21f578..7fe044750 100644
+--- a/src/event/quic/ngx_event_quic_streams.c
++++ b/src/event/quic/ngx_event_quic_streams.c
+@@ -731,12 +731,15 @@ ngx_quic_create_stream(ngx_connection_t *c, uint64_t id)
+         addr_text.data = NULL;
+     }
+ 
++    ngx_rbtree_insert(&qc->streams.tree, &qs->node);
++
+     reusable = c->reusable;
+     ngx_reusable_connection(c, 0);
+ 
+     sc = ngx_get_connection(c->fd, log);
+     if (sc == NULL) {
+         ngx_destroy_pool(pool);
++        ngx_rbtree_delete(&qc->streams.tree, &qs->node);
+         ngx_queue_insert_tail(&qc->streams.free, &qs->queue);
+         ngx_reusable_connection(c, reusable);
+         return NULL;
+@@ -803,6 +806,7 @@ ngx_quic_create_stream(ngx_connection_t *c, uint64_t id)
+     if (cln == NULL) {
+         ngx_close_connection(sc);
+         ngx_destroy_pool(pool);
++        ngx_rbtree_delete(&qc->streams.tree, &qs->node);
+         ngx_queue_insert_tail(&qc->streams.free, &qs->queue);
+         ngx_reusable_connection(c, reusable);
+         return NULL;
+@@ -811,8 +815,6 @@ ngx_quic_create_stream(ngx_connection_t *c, uint64_t id)
+     cln->handler = ngx_quic_stream_cleanup_handler;
+     cln->data = sc;
+ 
+-    ngx_rbtree_insert(&qc->streams.tree, &qs->node);
+-
+     return qs;
+ }
+ 
+-- 
+2.43.0
+
diff --git a/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb b/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb
index 5d9fae672b..06c33d7846 100644
--- a/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb
+++ b/meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb
@@ -12,6 +12,7 @@ SRC_URI:append = " \
                   file://CVE-2026-123634-01.patch \
                   file://CVE-2026-123634-02.patch \
                   file://CVE-2026-123633.patch \
+                  file://CVE-2026-121810.patch \
                   "
 
 SRC_URI[sha256sum] = "69ee2b237744036e61d24b836668aad3040dda461fe6f570f1787eab570c75aa"

-- 
2.43.0

