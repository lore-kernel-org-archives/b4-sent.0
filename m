From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:18:58 +0000
Subject: [PATCH BlueZ 6/8] bluetoothd: remove debug support for external
 plugins
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-rm-ext-plugins-v1-6-62990fb07369@gmail.com>
References: <20240116-rm-ext-plugins-v1-0-62990fb07369@gmail.com>
In-Reply-To: <20240116-rm-ext-plugins-v1-0-62990fb07369@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705414735; l=2192;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=fafLoCDAizTJJNOrgtnDZy+R8cR/ymoouOueLgEdSPU=;
 b=uXHogyiuOm10zo8UiUFx8oN1FqYNC6ia1emcchVEdm1fKJydj8B+h3KSqW0DAqPpGY2OIX+iz
 ujo+fbHT9UFD6H21Z91hRgpwDHZhcZWwqvYIC5aKwu3bTBGbm5cL70r
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

External plugins are gone, drop the associated debug support code.
---
 src/log.c    | 10 +++-------
 src/log.h    |  3 +--
 src/plugin.c |  2 --
 src/plugin.h |  2 --
 4 files changed, 4 insertions(+), 13 deletions(-)

diff --git a/src/log.c b/src/log.c
index 0155a6bba..db855d2b1 100644
--- a/src/log.c
+++ b/src/log.c
@@ -138,15 +138,11 @@ static gboolean is_enabled(struct btd_debug_desc *desc)
 	return 0;
 }
 
-void __btd_enable_debug(struct btd_debug_desc *start,
-					struct btd_debug_desc *stop)
+void __btd_enable_debug(void)
 {
 	struct btd_debug_desc *desc;
 
-	if (start == NULL || stop == NULL)
-		return;
-
-	for (desc = start; desc < stop; desc++) {
+	for (desc = __start___debug; desc < __stop___debug; desc++) {
 		if (is_enabled(desc))
 			desc->flags |= BTD_DEBUG_FLAG_PRINT;
 	}
@@ -167,7 +163,7 @@ void __btd_log_init(const char *debug, int detach)
 	if (debug != NULL)
 		enabled = g_strsplit_set(debug, ":, ", 0);
 
-	__btd_enable_debug(__start___debug, __stop___debug);
+	__btd_enable_debug();
 
 	bt_log_open();
 
diff --git a/src/log.h b/src/log.h
index 1ed742a0d..303fb36df 100644
--- a/src/log.h
+++ b/src/log.h
@@ -36,8 +36,7 @@ struct btd_debug_desc {
 	unsigned int flags;
 } __attribute__((aligned(8)));
 
-void __btd_enable_debug(struct btd_debug_desc *start,
-					struct btd_debug_desc *stop);
+void __btd_enable_debug(void);
 
 /**
  * DBG:
diff --git a/src/plugin.c b/src/plugin.c
index 1631f201c..e3eb12c0c 100644
--- a/src/plugin.c
+++ b/src/plugin.c
@@ -62,8 +62,6 @@ static void add_plugin(struct bluetooth_plugin_desc *desc)
 	plugin->active = FALSE;
 	plugin->desc = desc;
 
-	__btd_enable_debug(desc->debug_start, desc->debug_stop);
-
 	plugins = g_slist_insert_sorted(plugins, plugin, compare_priority);
 }
 
diff --git a/src/plugin.h b/src/plugin.h
index 7ff55e796..7a2d07b3d 100644
--- a/src/plugin.h
+++ b/src/plugin.h
@@ -17,8 +17,6 @@ struct bluetooth_plugin_desc {
 	int priority;
 	int (*init) (void);
 	void (*exit) (void);
-	void *debug_start;
-	void *debug_stop;
 };
 
 #define BLUETOOTH_PLUGIN_DEFINE(name, version, priority, init, exit) \

-- 
2.43.0

