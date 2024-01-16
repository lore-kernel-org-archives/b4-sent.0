From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:18:57 +0000
Subject: [PATCH BlueZ 5/8] bluetoothd: remove support for external plugins
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-rm-ext-plugins-v1-5-62990fb07369@gmail.com>
References: <20240116-rm-ext-plugins-v1-0-62990fb07369@gmail.com>
In-Reply-To: <20240116-rm-ext-plugins-v1-0-62990fb07369@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705414735; l=6086;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=AQMiHDtNeHPlogA1d4rfCFp51frNR+9TBH1r214Syp0=;
 b=MmUXCGIx9/DrFr+UCYskgN5zB7gu0MpcQTaNmZ/ky5EivHblRDyMaw61t1ExU3S27MWJ3/6pW
 iyphdCMP4+iDPbzGzGeuSbDmhy2SSe7HbXp8LiggXxCSvaA3BsEQZOy
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

With the final one converted to a builtin, we can drop the now dead
code. As follow-up this will allow us to stop exposing the internal API
of bluetoothd, reducing its size.
---
 Makefile.am  | 10 +--------
 src/btd.h    |  2 +-
 src/plugin.c | 72 +++++-------------------------------------------------------
 src/plugin.h | 14 ------------
 4 files changed, 8 insertions(+), 90 deletions(-)

diff --git a/Makefile.am b/Makefile.am
index ea51b25cc..4db3a2953 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -51,12 +51,6 @@ EXTRA_DIST += src/bluetooth.service.in src/org.bluez.service
 
 plugindir = $(libdir)/bluetooth/plugins
 
-if MAINTAINER_MODE
-build_plugindir = $(abs_top_srcdir)/plugins/.libs
-else
-build_plugindir = $(plugindir)
-endif
-
 if MANPAGES
 man_MANS =
 endif
@@ -337,9 +331,7 @@ src_bluetoothd_DEPENDENCIES = lib/libbluetooth-internal.la \
 				src/libshared-glib.la \
 				src/bluetooth.service
 
-src_bluetoothd_CPPFLAGS = $(AM_CPPFLAGS) -DBLUETOOTH_PLUGIN_BUILTIN \
-					-DPLUGINDIR=\""$(build_plugindir)"\" \
-					$(BACKTRACE_CFLAGS) $(builtin_cppflags)
+src_bluetoothd_CPPFLAGS = $(AM_CPPFLAGS) $(BACKTRACE_CFLAGS) $(builtin_cppflags)
 src_bluetoothd_SHORTNAME = bluetoothd
 
 builtin_files = src/builtin.h $(builtin_nodist)
diff --git a/src/btd.h b/src/btd.h
index b7e7ebd61..7166e2168 100644
--- a/src/btd.h
+++ b/src/btd.h
@@ -155,7 +155,7 @@ struct btd_opts {
 
 extern struct btd_opts btd_opts;
 
-gboolean plugin_init(const char *enable, const char *disable);
+void plugin_init(const char *enable, const char *disable);
 void plugin_cleanup(void);
 
 void rfkill_init(void);
diff --git a/src/plugin.c b/src/plugin.c
index 80990f8c3..1631f201c 100644
--- a/src/plugin.c
+++ b/src/plugin.c
@@ -29,7 +29,6 @@
 static GSList *plugins = NULL;
 
 struct bluetooth_plugin {
-	void *handle;
 	gboolean active;
 	struct bluetooth_plugin_desc *desc;
 };
@@ -42,33 +41,30 @@ static int compare_priority(gconstpointer a, gconstpointer b)
 	return plugin2->desc->priority - plugin1->desc->priority;
 }
 
-static gboolean add_plugin(void *handle, struct bluetooth_plugin_desc *desc)
+static void add_plugin(struct bluetooth_plugin_desc *desc)
 {
 	struct bluetooth_plugin *plugin;
 
 	if (desc->init == NULL)
-		return FALSE;
+		return;
 
 	if (g_str_equal(desc->version, VERSION) == FALSE) {
 		error("Version mismatch for %s", desc->name);
-		return FALSE;
+		return;
 	}
 
 	DBG("Loading %s plugin", desc->name);
 
 	plugin = g_try_new0(struct bluetooth_plugin, 1);
 	if (plugin == NULL)
-		return FALSE;
+		return;
 
-	plugin->handle = handle;
 	plugin->active = FALSE;
 	plugin->desc = desc;
 
 	__btd_enable_debug(desc->debug_start, desc->debug_stop);
 
 	plugins = g_slist_insert_sorted(plugins, plugin, compare_priority);
-
-	return TRUE;
 }
 
 static gboolean enable_plugin(const char *name, char **cli_enable,
@@ -99,11 +95,9 @@ static gboolean enable_plugin(const char *name, char **cli_enable,
 
 #include "src/builtin.h"
 
-gboolean plugin_init(const char *enable, const char *disable)
+void plugin_init(const char *enable, const char *disable)
 {
 	GSList *list;
-	GDir *dir;
-	const char *file;
 	char **cli_disabled, **cli_enabled;
 	unsigned int i;
 
@@ -128,58 +122,9 @@ gboolean plugin_init(const char *enable, const char *disable)
 								cli_disabled))
 			continue;
 
-		add_plugin(NULL,  __bluetooth_builtin[i]);
+		add_plugin(__bluetooth_builtin[i]);
 	}
 
-	if (strlen(PLUGINDIR) == 0)
-		goto start;
-
-	DBG("Loading plugins %s", PLUGINDIR);
-
-	dir = g_dir_open(PLUGINDIR, 0, NULL);
-	if (!dir)
-		goto start;
-
-	while ((file = g_dir_read_name(dir)) != NULL) {
-		struct bluetooth_plugin_desc *desc;
-		void *handle;
-		char *filename;
-
-		if (g_str_has_prefix(file, "lib") == TRUE ||
-				g_str_has_suffix(file, ".so") == FALSE)
-			continue;
-
-		filename = g_build_filename(PLUGINDIR, file, NULL);
-
-		handle = dlopen(filename, RTLD_NOW);
-		if (handle == NULL) {
-			error("Can't load plugin %s: %s", filename,
-								dlerror());
-			g_free(filename);
-			continue;
-		}
-
-		g_free(filename);
-
-		desc = dlsym(handle, "bluetooth_plugin_desc");
-		if (desc == NULL) {
-			error("Can't load plugin description: %s", dlerror());
-			dlclose(handle);
-			continue;
-		}
-
-		if (!enable_plugin(desc->name, cli_enabled, cli_disabled)) {
-			dlclose(handle);
-			continue;
-		}
-
-		if (add_plugin(handle, desc) == FALSE)
-			dlclose(handle);
-	}
-
-	g_dir_close(dir);
-
-start:
 	for (list = plugins; list; list = list->next) {
 		struct bluetooth_plugin *plugin = list->data;
 		int err;
@@ -200,8 +145,6 @@ start:
 
 	g_strfreev(cli_enabled);
 	g_strfreev(cli_disabled);
-
-	return TRUE;
 }
 
 void plugin_cleanup(void)
@@ -216,9 +159,6 @@ void plugin_cleanup(void)
 		if (plugin->active == TRUE && plugin->desc->exit)
 			plugin->desc->exit();
 
-		if (plugin->handle != NULL)
-			dlclose(plugin->handle);
-
 		g_free(plugin);
 	}
 
diff --git a/src/plugin.h b/src/plugin.h
index a5f92a557..7ff55e796 100644
--- a/src/plugin.h
+++ b/src/plugin.h
@@ -21,21 +21,7 @@ struct bluetooth_plugin_desc {
 	void *debug_stop;
 };
 
-#ifdef BLUETOOTH_PLUGIN_BUILTIN
 #define BLUETOOTH_PLUGIN_DEFINE(name, version, priority, init, exit) \
 		struct bluetooth_plugin_desc __bluetooth_builtin_ ## name = { \
 			#name, version, priority, init, exit \
 		};
-#else
-#define BLUETOOTH_PLUGIN_DEFINE(name, version, priority, init, exit) \
-		extern struct btd_debug_desc __start___debug[] \
-				__attribute__ ((weak, visibility("hidden"))); \
-		extern struct btd_debug_desc __stop___debug[] \
-				__attribute__ ((weak, visibility("hidden"))); \
-		extern struct bluetooth_plugin_desc bluetooth_plugin_desc \
-				__attribute__ ((visibility("default"))); \
-		struct bluetooth_plugin_desc bluetooth_plugin_desc = { \
-			#name, version, priority, init, exit, \
-			__start___debug, __stop___debug \
-		};
-#endif

-- 
2.43.0

