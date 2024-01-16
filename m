From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:44 +0000
Subject: [PATCH BlueZ 19/20] obexd: const annotate misc immutable data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-19-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=3937;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=LrDZdJSOkuXg0aaks0vIhPZwBeRbl04SybrYFVckFXg=;
 b=OUeSwrfDljmljB/eO09WAXjnvynxultMG2EumZa87b/P/KGASR+i3PHVEx+aWJScKZHtVxPs0
 q3cHc5NWn0ZDMg6x5xSGZg1R1Tbsosir7IRxgaoQX2ytqXNK9LM/X4h
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 obexd/client/manager.c          | 6 +++---
 obexd/client/map.c              | 4 ++--
 obexd/client/mns.c              | 4 ++--
 obexd/plugins/phonebook-ebook.c | 2 +-
 obexd/src/main.c                | 2 +-
 obexd/src/obex.c                | 2 +-
 6 files changed, 10 insertions(+), 10 deletions(-)

diff --git a/obexd/client/manager.c b/obexd/client/manager.c
index 75f1bfb04..ad1fbb04a 100644
--- a/obexd/client/manager.c
+++ b/obexd/client/manager.c
@@ -241,7 +241,7 @@ static const GDBusMethodTable client_methods[] = {
 
 static DBusConnection *conn = NULL;
 
-static struct obc_module {
+static const struct obc_module {
 	const char *name;
 	int (*init) (void);
 	void (*exit) (void);
@@ -258,7 +258,7 @@ static struct obc_module {
 int client_manager_init(void)
 {
 	DBusError derr;
-	struct obc_module *module;
+	const struct obc_module *module;
 
 	dbus_error_init(&derr);
 
@@ -289,7 +289,7 @@ int client_manager_init(void)
 
 void client_manager_exit(void)
 {
-	struct obc_module *module;
+	const struct obc_module *module;
 
 	if (conn == NULL)
 		return;
diff --git a/obexd/client/map.c b/obexd/client/map.c
index 74828cddb..513dcaf14 100644
--- a/obexd/client/map.c
+++ b/obexd/client/map.c
@@ -1060,7 +1060,7 @@ static void parse_protected(struct map_msg *msg, const char *value)
 						MAP_MSG_INTERFACE, "Protected");
 }
 
-static struct map_msg_parser {
+static const struct map_msg_parser {
 	const char *name;
 	void (*func) (struct map_msg *msg, const char *value);
 } msg_parsers[] = {
@@ -1120,7 +1120,7 @@ static void msg_element(GMarkupParseContext *ctxt, const char *element,
 								&msg->path);
 
 	for (i = 0, key = names[i]; key; key = names[++i]) {
-		struct map_msg_parser *parser;
+		const struct map_msg_parser *parser;
 
 		for (parser = msg_parsers; parser && parser->name; parser++) {
 			if (strcasecmp(key, parser->name) == 0) {
diff --git a/obexd/client/mns.c b/obexd/client/mns.c
index 702cf0367..c7f86afdc 100644
--- a/obexd/client/mns.c
+++ b/obexd/client/mns.c
@@ -233,7 +233,7 @@ static void parse_event_report_priority(struct map_event *event,
 	event->priority = g_strdup(value);
 }
 
-static struct map_event_report_parser {
+static const struct map_event_report_parser {
 	const char *name;
 	void (*func) (struct map_event *event, const char *value);
 } event_report_parsers[] = {
@@ -262,7 +262,7 @@ static void event_report_element(GMarkupParseContext *ctxt,
 		return;
 
 	for (i = 0, key = names[i]; key; key = names[++i]) {
-		struct map_event_report_parser *parser;
+		const struct map_event_report_parser *parser;
 
 		for (parser = event_report_parsers; parser && parser->name;
 								parser++) {
diff --git a/obexd/plugins/phonebook-ebook.c b/obexd/plugins/phonebook-ebook.c
index 29ec9d213..e509dd29a 100644
--- a/obexd/plugins/phonebook-ebook.c
+++ b/obexd/plugins/phonebook-ebook.c
@@ -55,7 +55,7 @@ struct query_context {
 	gboolean canceled;
 };
 
-static char *attribute_mask[] = {
+static const char *attribute_mask[] = {
 /* 0 */		"VERSION",
 		"FN",
 		"N",
diff --git a/obexd/src/main.c b/obexd/src/main.c
index d950883f0..151574afa 100644
--- a/obexd/src/main.c
+++ b/obexd/src/main.c
@@ -138,7 +138,7 @@ static gboolean parse_debug(const char *key, const char *value,
 	return TRUE;
 }
 
-static GOptionEntry options[] = {
+static const GOptionEntry options[] = {
 	{ "debug", 'd', G_OPTION_FLAG_OPTIONAL_ARG,
 				G_OPTION_ARG_CALLBACK, parse_debug,
 				"Enable debug information output", "DEBUG" },
diff --git a/obexd/src/obex.c b/obexd/src/obex.c
index 526861f40..98d6245a4 100644
--- a/obexd/src/obex.c
+++ b/obexd/src/obex.c
@@ -55,7 +55,7 @@ struct auth_header {
 } __attribute__ ((packed));
 
 /* Possible commands */
-static struct {
+static const struct {
 	int cmd;
 	const char *name;
 } obex_command[] = {

-- 
2.43.0

