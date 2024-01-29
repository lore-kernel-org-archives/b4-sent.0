From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 29 Jan 2024 14:44:21 +0000
Subject: [PATCH BlueZ v4 7/8] bluetoothd: change plugin loading alike obexd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240129-rm-ext-plugins-v4-7-bfd1e08c7f99@gmail.com>
References: <20240129-rm-ext-plugins-v4-0-bfd1e08c7f99@gmail.com>
In-Reply-To: <20240129-rm-ext-plugins-v4-0-bfd1e08c7f99@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706539455; l=3497;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=DL7N7DwKctcZBFQW2V1+S1oTVHffRx+jI1FmauTGk9w=;
 b=yQ9Y89mRKZzqYkaOBPfK9oBPwzeLplN3zqrA/LUvnTzNvOcxDS+Ay5UX8gKHzdz4tatbzWoxX
 RAJXPy7BeHvAxi4QJyM6ckkD0hSVwjRLjIs0k0Y12txXwZhLQTDLh/1
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

Currently, we print "Loading foobar" for every plugin, before we try the
respective init() callback. Instead we handle the latter in a bunch, at
the end of the process.

Do the init() call early, print "Loaded" once it's actually successful
and drop the no-longer "active" tracking.
---
 src/plugin.c | 53 +++++++++++++++++++++++++++++------------------------
 1 file changed, 29 insertions(+), 24 deletions(-)

diff --git a/src/plugin.c b/src/plugin.c
index b6a84299a..e6d05be4c 100644
--- a/src/plugin.c
+++ b/src/plugin.c
@@ -32,7 +32,6 @@ static GSList *plugins = NULL;
 
 struct bluetooth_plugin {
 	void *handle;
-	gboolean active;
 	const struct bluetooth_plugin_desc *desc;
 };
 
@@ -44,6 +43,22 @@ static int compare_priority(gconstpointer a, gconstpointer b)
 	return plugin2->desc->priority - plugin1->desc->priority;
 }
 
+static int init_plugin(const struct bluetooth_plugin_desc *desc)
+{
+	int err;
+
+	err = desc->init();
+	if (err < 0) {
+		if (err == -ENOSYS || err == -ENOTSUP)
+			warn("System does not support %s plugin",
+						desc->name);
+		else
+			error("Failed to init %s plugin",
+						desc->name);
+	}
+	return err;
+}
+
 static gboolean add_external_plugin(void *handle,
 				const struct bluetooth_plugin_desc *desc)
 {
@@ -57,19 +72,22 @@ static gboolean add_external_plugin(void *handle,
 		return FALSE;
 	}
 
-	DBG("Loading %s plugin", desc->name);
-
 	plugin = g_try_new0(struct bluetooth_plugin, 1);
 	if (plugin == NULL)
 		return FALSE;
 
 	plugin->handle = handle;
-	plugin->active = FALSE;
 	plugin->desc = desc;
 
+	if (init_plugin(desc) < 0) {
+		g_free(plugin);
+		return FALSE;
+	}
+
 	__btd_enable_debug(desc->debug_start, desc->debug_stop);
 
 	plugins = g_slist_insert_sorted(plugins, plugin, compare_priority);
+	DBG("Plugin %s loaded", desc->name);
 
 	return TRUE;
 }
@@ -86,7 +104,13 @@ static void add_plugin(const struct bluetooth_plugin_desc *desc)
 
 	plugin->desc = desc;
 
+	if (init_plugin(desc) < 0) {
+		g_free(plugin);
+		return;
+	}
+
 	plugins = g_slist_insert_sorted(plugins, plugin, compare_priority);
+	DBG("Plugin %s loaded", desc->name);
 }
 
 static gboolean enable_plugin(const char *name, char **cli_enable,
@@ -177,7 +201,6 @@ static void external_plugin_init(char **cli_disabled, char **cli_enabled)
 
 void plugin_init(const char *enable, const char *disable)
 {
-	GSList *list;
 	char **cli_disabled = NULL;
 	char **cli_enabled = NULL;
 	unsigned int i;
@@ -205,24 +228,6 @@ void plugin_init(const char *enable, const char *disable)
 	if IS_ENABLED(EXTERNAL_PLUGINS)
 		external_plugin_init(cli_enabled, cli_disabled);
 
-	for (list = plugins; list; list = list->next) {
-		struct bluetooth_plugin *plugin = list->data;
-		int err;
-
-		err = plugin->desc->init();
-		if (err < 0) {
-			if (err == -ENOSYS || err == -ENOTSUP)
-				warn("System does not support %s plugin",
-							plugin->desc->name);
-			else
-				error("Failed to init %s plugin",
-							plugin->desc->name);
-			continue;
-		}
-
-		plugin->active = TRUE;
-	}
-
 	g_strfreev(cli_enabled);
 	g_strfreev(cli_disabled);
 }
@@ -236,7 +241,7 @@ void plugin_cleanup(void)
 	for (list = plugins; list; list = list->next) {
 		struct bluetooth_plugin *plugin = list->data;
 
-		if (plugin->active == TRUE && plugin->desc->exit)
+		if (plugin->desc->exit)
 			plugin->desc->exit();
 
 		if (plugin->handle != NULL)

-- 
2.43.0

