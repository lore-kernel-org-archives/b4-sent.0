From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:45 +0000
Subject: [PATCH BlueZ 20/20] obexd: const annotate obex_plugin_desc
 entrypoint
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-20-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=2465;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=NqOjgJzWeyVBPk28dTgOSntse3r5l3o0yfOgLtILLQY=;
 b=xeyoPUXasnGeNeZ/P9F3naSPrGJAwtxNp0n5k37lCwevB+fJIkRYGYrNf6xkaWYCH+YeBf+u3
 sPqffyCUj1yBqKGbUAK+Z0lQEwRHpFBUrhqKc5LJMIgKJXIdFfqO4ic
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 obexd/src/genbuiltin | 4 ++--
 obexd/src/plugin.c   | 8 ++++----
 obexd/src/plugin.h   | 4 ++--
 3 files changed, 8 insertions(+), 8 deletions(-)

diff --git a/obexd/src/genbuiltin b/obexd/src/genbuiltin
index 39f773527..e60b5189a 100755
--- a/obexd/src/genbuiltin
+++ b/obexd/src/genbuiltin
@@ -2,11 +2,11 @@
 
 for i in $*
 do
-	echo "extern struct obex_plugin_desc __obex_builtin_$i;"
+	echo "extern const struct obex_plugin_desc __obex_builtin_$i;"
 done
 
 echo
-echo "static struct obex_plugin_desc *__obex_builtin[] = {"
+echo "static const struct obex_plugin_desc *__obex_builtin[] = {"
 
 for i in $*
 do
diff --git a/obexd/src/plugin.c b/obexd/src/plugin.c
index 0df9d5258..a3eb24753 100644
--- a/obexd/src/plugin.c
+++ b/obexd/src/plugin.c
@@ -38,10 +38,10 @@ static GSList *plugins = NULL;
 
 struct obex_plugin {
 	void *handle;
-	struct obex_plugin_desc *desc;
+	const struct obex_plugin_desc *desc;
 };
 
-static gboolean add_plugin(void *handle, struct obex_plugin_desc *desc)
+static gboolean add_plugin(void *handle, const struct obex_plugin_desc *desc)
 {
 	struct obex_plugin *plugin;
 
@@ -66,7 +66,7 @@ static gboolean add_plugin(void *handle, struct obex_plugin_desc *desc)
 	return TRUE;
 }
 
-static gboolean check_plugin(struct obex_plugin_desc *desc,
+static gboolean check_plugin(const struct obex_plugin_desc *desc,
 				char **patterns, char **excludes)
 {
 	if (excludes) {
@@ -132,7 +132,7 @@ gboolean plugin_init(const char *pattern, const char *exclude)
 	}
 
 	while ((file = g_dir_read_name(dir)) != NULL) {
-		struct obex_plugin_desc *desc;
+		const struct obex_plugin_desc *desc;
 		void *handle;
 		char *filename;
 
diff --git a/obexd/src/plugin.h b/obexd/src/plugin.h
index 703878460..a91746cbc 100644
--- a/obexd/src/plugin.h
+++ b/obexd/src/plugin.h
@@ -16,14 +16,14 @@ struct obex_plugin_desc {
 
 #ifdef OBEX_PLUGIN_BUILTIN
 #define OBEX_PLUGIN_DEFINE(name, init, exit) \
-		struct obex_plugin_desc __obex_builtin_ ## name = { \
+		const struct obex_plugin_desc __obex_builtin_ ## name = { \
 			#name, init, exit \
 		};
 #else
 #define OBEX_PLUGIN_DEFINE(name,init,exit) \
 		extern struct obex_plugin_desc obex_plugin_desc \
 				__attribute__ ((visibility("default"))); \
-		struct obex_plugin_desc obex_plugin_desc = { \
+		const struct obex_plugin_desc obex_plugin_desc = { \
 			#name, init, exit \
 		};
 #endif

-- 
2.43.0

