From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Thu, 25 Jan 2024 00:07:27 +0000
Subject: [PATCH BlueZ v3 2/8] obexd: factor out external plugin support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240125-rm-ext-plugins-v3-2-d141f7870bb6@gmail.com>
References: <20240125-rm-ext-plugins-v3-0-d141f7870bb6@gmail.com>
In-Reply-To: <20240125-rm-ext-plugins-v3-0-d141f7870bb6@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706141247; l=5642;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=pGvGwURoyXDGW5FladnamFTHwTNZsaHX3sUoMvQj5ac=;
 b=pV8O38XCOg7+8a1uxsvUlId50hnGrxTkL40L3c4scHDtvK5p5dFB6kDMTVSRuhXvg9ny4EA0i
 upfu5sowOirD//OTAJr4Wtm/M+gZqF5I8zABnGQO2c7NEoCEPHzM8e/
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

As a whole all plugins should be built-in, otherwise they would be using
internal, undocumented, unversioned, unstable API.

Flesh out the external plugin support into a few pre-processor blocks
and simplify the normal path.

Hide the internal API (omit export-dynamic) when built without external
plugins.
---
 Makefile.obexd     |  2 ++
 obexd/src/obexd.h  |  2 +-
 obexd/src/plugin.c | 93 ++++++++++++++++++++++++++++++++++++------------------
 obexd/src/plugin.h |  4 +++
 4 files changed, 70 insertions(+), 31 deletions(-)

diff --git a/Makefile.obexd b/Makefile.obexd
index 5d1a4ff65..9175de2a4 100644
--- a/Makefile.obexd
+++ b/Makefile.obexd
@@ -86,7 +86,9 @@ obexd_src_obexd_LDADD = lib/libbluetooth-internal.la \
 			$(ICAL_LIBS) $(DBUS_LIBS) $(LIBEBOOK_LIBS) \
 			$(LIBEDATASERVER_LIBS) $(GLIB_LIBS) -ldl
 
+if EXTERNAL_PLUGINS
 obexd_src_obexd_LDFLAGS = $(AM_LDFLAGS) -Wl,--export-dynamic
+endif
 
 obexd_src_obexd_CPPFLAGS = $(AM_CPPFLAGS) $(GLIB_CFLAGS) $(DBUS_CFLAGS) \
 				$(ICAL_CFLAGS) -DOBEX_PLUGIN_BUILTIN \
diff --git a/obexd/src/obexd.h b/obexd/src/obexd.h
index fe312a65b..af5265da5 100644
--- a/obexd/src/obexd.h
+++ b/obexd/src/obexd.h
@@ -18,7 +18,7 @@
 #define OBEX_MAS	(1 << 8)
 #define OBEX_MNS	(1 << 9)
 
-gboolean plugin_init(const char *pattern, const char *exclude);
+void plugin_init(const char *pattern, const char *exclude);
 void plugin_cleanup(void);
 
 gboolean manager_init(void);
diff --git a/obexd/src/plugin.c b/obexd/src/plugin.c
index a3eb24753..212299fa5 100644
--- a/obexd/src/plugin.c
+++ b/obexd/src/plugin.c
@@ -37,11 +37,14 @@
 static GSList *plugins = NULL;
 
 struct obex_plugin {
+#if EXTERNAL_PLUGINS
 	void *handle;
+#endif
 	const struct obex_plugin_desc *desc;
 };
 
-static gboolean add_plugin(void *handle, const struct obex_plugin_desc *desc)
+#if EXTERNAL_PLUGINS
+static gboolean add_external_plugin(void *handle, const struct obex_plugin_desc *desc)
 {
 	struct obex_plugin *plugin;
 
@@ -65,6 +68,26 @@ static gboolean add_plugin(void *handle, const struct obex_plugin_desc *desc)
 
 	return TRUE;
 }
+#endif
+
+static void add_plugin(const struct obex_plugin_desc *desc)
+{
+	struct obex_plugin *plugin;
+
+	plugin = g_try_new0(struct obex_plugin, 1);
+	if (plugin == NULL)
+		return;
+
+	plugin->desc = desc;
+
+	if (desc->init() < 0) {
+		g_free(plugin);
+		return;
+	}
+
+	plugins = g_slist_append(plugins, plugin);
+	DBG("Plugin %s loaded", desc->name);
+}
 
 static gboolean check_plugin(const struct obex_plugin_desc *desc,
 				char **patterns, char **excludes)
@@ -93,42 +116,23 @@ static gboolean check_plugin(const struct obex_plugin_desc *desc,
 }
 
 
-#include "builtin.h"
-
-gboolean plugin_init(const char *pattern, const char *exclude)
+static void external_plugin_init(char **patterns, char **excludes)
 {
-	char **patterns = NULL;
-	char **excludes = NULL;
+#if EXTERNAL_PLUGINS
 	GDir *dir;
 	const char *file;
-	unsigned int i;
 
-	if (strlen(PLUGINDIR) == 0)
-		return FALSE;
-
-	if (pattern)
-		patterns = g_strsplit_set(pattern, ":, ", -1);
-
-	if (exclude)
-		excludes = g_strsplit_set(exclude, ":, ", -1);
-
-	DBG("Loading builtin plugins");
-
-	for (i = 0; __obex_builtin[i]; i++) {
-		if (check_plugin(__obex_builtin[i],
-					patterns, excludes) == FALSE)
-			continue;
+	warn("Using external plugins is not officially supported.\n");
+	warn("Consider upstreaming your plugins into the BlueZ project.");
 
-		add_plugin(NULL,  __obex_builtin[i]);
-	}
+	if (strlen(PLUGINDIR) == 0)
+		return;
 
 	DBG("Loading plugins %s", PLUGINDIR);
 
 	dir = g_dir_open(PLUGINDIR, 0, NULL);
 	if (!dir) {
-		g_strfreev(patterns);
-		g_strfreev(excludes);
-		return FALSE;
+		return;
 	}
 
 	while ((file = g_dir_read_name(dir)) != NULL) {
@@ -164,15 +168,42 @@ gboolean plugin_init(const char *pattern, const char *exclude)
 			continue;
 		}
 
-		if (add_plugin(handle, desc) == FALSE)
+		if (add_external_plugin(handle, desc) == FALSE)
 			dlclose(handle);
 	}
 
 	g_dir_close(dir);
+#endif
+}
+
+#include "builtin.h"
+
+void plugin_init(const char *pattern, const char *exclude)
+{
+	char **patterns = NULL;
+	char **excludes = NULL;
+	unsigned int i;
+
+	if (pattern)
+		patterns = g_strsplit_set(pattern, ":, ", -1);
+
+	if (exclude)
+		excludes = g_strsplit_set(exclude, ":, ", -1);
+
+	DBG("Loading builtin plugins");
+
+	for (i = 0; __obex_builtin[i]; i++) {
+		if (check_plugin(__obex_builtin[i],
+					patterns, excludes) == FALSE)
+			continue;
+
+		add_plugin(__obex_builtin[i]);
+	}
+
+	external_plugin_init(patterns, excludes);
+
 	g_strfreev(patterns);
 	g_strfreev(excludes);
-
-	return TRUE;
 }
 
 void plugin_cleanup(void)
@@ -187,8 +218,10 @@ void plugin_cleanup(void)
 		if (plugin->desc->exit)
 			plugin->desc->exit();
 
+#if EXTERNAL_PLUGINS
 		if (plugin->handle != NULL)
 			dlclose(plugin->handle);
+#endif
 
 		g_free(plugin);
 	}
diff --git a/obexd/src/plugin.h b/obexd/src/plugin.h
index a91746cbc..e1756b9bf 100644
--- a/obexd/src/plugin.h
+++ b/obexd/src/plugin.h
@@ -20,10 +20,14 @@ struct obex_plugin_desc {
 			#name, init, exit \
 		};
 #else
+#if EXTERNAL_PLUGINS
 #define OBEX_PLUGIN_DEFINE(name,init,exit) \
 		extern struct obex_plugin_desc obex_plugin_desc \
 				__attribute__ ((visibility("default"))); \
 		const struct obex_plugin_desc obex_plugin_desc = { \
 			#name, init, exit \
 		};
+#else
+#error "Requested non built-in plugin, while external plugins is disabled"
+#endif
 #endif

-- 
2.43.0

