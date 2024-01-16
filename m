From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:41 +0000
Subject: [PATCH BlueZ 16/20] obexd: const obex_mime_type_driver instances
 and API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-16-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=11209;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=SKIZuOUAgBaKwtIir1DXq91Qao7Mu//a+v8uSmhQCl8=;
 b=mZ4y9YbsB8+qtNzU1j+6wPV4649X3hdExMtlrgsbYOtpJwkG0+e8x6XXmU7jqQ25bLQi4wEeS
 +cQE8ldcSt9B1JIaAdS4GN9uap0ypk84GMWWThHTZZr4rYojphdAy8G
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 obexd/client/mns.c            |  2 +-
 obexd/plugins/filesystem.c    |  8 ++++----
 obexd/plugins/irmc.c          |  2 +-
 obexd/plugins/mas.c           | 16 ++++++++--------
 obexd/plugins/pbap.c          |  6 +++---
 obexd/plugins/pcsuite.c       |  2 +-
 obexd/plugins/syncevolution.c |  2 +-
 obexd/src/mimetype.c          | 14 +++++++-------
 obexd/src/mimetype.h          |  6 +++---
 obexd/src/obex-priv.h         |  2 +-
 10 files changed, 30 insertions(+), 30 deletions(-)

diff --git a/obexd/client/mns.c b/obexd/client/mns.c
index e52505642..3b2ae1076 100644
--- a/obexd/client/mns.c
+++ b/obexd/client/mns.c
@@ -356,7 +356,7 @@ static struct obex_service_driver mns = {
 	.disconnect = mns_disconnect,
 };
 
-static struct obex_mime_type_driver mime_event_report = {
+static const struct obex_mime_type_driver mime_event_report = {
 	.target = MNS_TARGET,
 	.target_size = TARGET_SIZE,
 	.mimetype = "x-bt/MAP-event-report",
diff --git a/obexd/plugins/filesystem.c b/obexd/plugins/filesystem.c
index 09bff8ad0..f52927541 100644
--- a/obexd/plugins/filesystem.c
+++ b/obexd/plugins/filesystem.c
@@ -642,7 +642,7 @@ done:
 	return err;
 }
 
-static struct obex_mime_type_driver file = {
+static const struct obex_mime_type_driver file = {
 	.open = filesystem_open,
 	.close = filesystem_close,
 	.read = filesystem_read,
@@ -652,7 +652,7 @@ static struct obex_mime_type_driver file = {
 	.copy = filesystem_copy,
 };
 
-static struct obex_mime_type_driver capability = {
+static const struct obex_mime_type_driver capability = {
 	.target = FTP_TARGET,
 	.target_size = FTP_TARGET_SIZE,
 	.mimetype = "x-obex/capability",
@@ -661,7 +661,7 @@ static struct obex_mime_type_driver capability = {
 	.read = capability_read,
 };
 
-static struct obex_mime_type_driver folder = {
+static const struct obex_mime_type_driver folder = {
 	.target = FTP_TARGET,
 	.target_size = FTP_TARGET_SIZE,
 	.mimetype = "x-obex/folder-listing",
@@ -670,7 +670,7 @@ static struct obex_mime_type_driver folder = {
 	.read = folder_read,
 };
 
-static struct obex_mime_type_driver pcsuite = {
+static const struct obex_mime_type_driver pcsuite = {
 	.target = FTP_TARGET,
 	.target_size = FTP_TARGET_SIZE,
 	.who = PCSUITE_WHO,
diff --git a/obexd/plugins/irmc.c b/obexd/plugins/irmc.c
index cd143e7a3..e85cf70a1 100644
--- a/obexd/plugins/irmc.c
+++ b/obexd/plugins/irmc.c
@@ -419,7 +419,7 @@ static ssize_t irmc_read(void *object, void *buf, size_t count)
 	return len;
 }
 
-static struct obex_mime_type_driver irmc_driver = {
+static const struct obex_mime_type_driver irmc_driver = {
 	.target = IRMC_TARGET,
 	.target_size = IRMC_TARGET_SIZE,
 	.open = irmc_open,
diff --git a/obexd/plugins/mas.c b/obexd/plugins/mas.c
index 5d00bc563..f0eaf6d82 100644
--- a/obexd/plugins/mas.c
+++ b/obexd/plugins/mas.c
@@ -793,7 +793,7 @@ static struct obex_service_driver mas = {
 	.disconnect = mas_disconnect,
 };
 
-static struct obex_mime_type_driver mime_map = {
+static const struct obex_mime_type_driver mime_map = {
 	.target = MAS_TARGET,
 	.target_size = TARGET_SIZE,
 	.mimetype = NULL,
@@ -803,7 +803,7 @@ static struct obex_mime_type_driver mime_map = {
 	.write = any_write,
 };
 
-static struct obex_mime_type_driver mime_message = {
+static const struct obex_mime_type_driver mime_message = {
 	.target = MAS_TARGET,
 	.target_size = TARGET_SIZE,
 	.mimetype = "x-bt/message",
@@ -813,7 +813,7 @@ static struct obex_mime_type_driver mime_message = {
 	.write = any_write,
 };
 
-static struct obex_mime_type_driver mime_folder_listing = {
+static const struct obex_mime_type_driver mime_folder_listing = {
 	.target = MAS_TARGET,
 	.target_size = TARGET_SIZE,
 	.mimetype = "x-obex/folder-listing",
@@ -824,7 +824,7 @@ static struct obex_mime_type_driver mime_folder_listing = {
 	.write = any_write,
 };
 
-static struct obex_mime_type_driver mime_msg_listing = {
+static const struct obex_mime_type_driver mime_msg_listing = {
 	.target = MAS_TARGET,
 	.target_size = TARGET_SIZE,
 	.mimetype = "x-bt/MAP-msg-listing",
@@ -835,7 +835,7 @@ static struct obex_mime_type_driver mime_msg_listing = {
 	.write = any_write,
 };
 
-static struct obex_mime_type_driver mime_notification_registration = {
+static const struct obex_mime_type_driver mime_notification_registration = {
 	.target = MAS_TARGET,
 	.target_size = TARGET_SIZE,
 	.mimetype = "x-bt/MAP-NotificationRegistration",
@@ -845,7 +845,7 @@ static struct obex_mime_type_driver mime_notification_registration = {
 	.write = any_write,
 };
 
-static struct obex_mime_type_driver mime_message_status = {
+static const struct obex_mime_type_driver mime_message_status = {
 	.target = MAS_TARGET,
 	.target_size = TARGET_SIZE,
 	.mimetype = "x-bt/messageStatus",
@@ -855,7 +855,7 @@ static struct obex_mime_type_driver mime_message_status = {
 	.write = any_write,
 };
 
-static struct obex_mime_type_driver mime_message_update = {
+static const struct obex_mime_type_driver mime_message_update = {
 	.target = MAS_TARGET,
 	.target_size = TARGET_SIZE,
 	.mimetype = "x-bt/MAP-messageUpdate",
@@ -865,7 +865,7 @@ static struct obex_mime_type_driver mime_message_update = {
 	.write = any_write,
 };
 
-static struct obex_mime_type_driver *map_drivers[] = {
+static const struct obex_mime_type_driver *map_drivers[] = {
 	&mime_map,
 	&mime_message,
 	&mime_folder_listing,
diff --git a/obexd/plugins/pbap.c b/obexd/plugins/pbap.c
index ab5236316..b363c673b 100644
--- a/obexd/plugins/pbap.c
+++ b/obexd/plugins/pbap.c
@@ -929,7 +929,7 @@ static ssize_t vobject_vcard_read(void *object, void *buf, size_t count)
 	return string_read(obj->buffer, buf, count);
 }
 
-static struct obex_mime_type_driver mime_pull = {
+static const struct obex_mime_type_driver mime_pull = {
 	.target = PBAP_TARGET,
 	.target_size = TARGET_SIZE,
 	.mimetype = "x-bt/phonebook",
@@ -939,7 +939,7 @@ static struct obex_mime_type_driver mime_pull = {
 	.get_next_header = vobject_pull_get_next_header,
 };
 
-static struct obex_mime_type_driver mime_list = {
+static const struct obex_mime_type_driver mime_list = {
 	.target = PBAP_TARGET,
 	.target_size = TARGET_SIZE,
 	.mimetype = "x-bt/vcard-listing",
@@ -949,7 +949,7 @@ static struct obex_mime_type_driver mime_list = {
 	.get_next_header = vobject_list_get_next_header,
 };
 
-static struct obex_mime_type_driver mime_vcard = {
+static const struct obex_mime_type_driver mime_vcard = {
 	.target = PBAP_TARGET,
 	.target_size = TARGET_SIZE,
 	.mimetype = "x-bt/vcard",
diff --git a/obexd/plugins/pcsuite.c b/obexd/plugins/pcsuite.c
index f5a9d9ae8..d4a0394af 100644
--- a/obexd/plugins/pcsuite.c
+++ b/obexd/plugins/pcsuite.c
@@ -467,7 +467,7 @@ static int backup_flush(void *object)
 	return 0;
 }
 
-static struct obex_mime_type_driver backup = {
+static const struct obex_mime_type_driver backup = {
 	.target = FTP_TARGET,
 	.target_size = TARGET_SIZE,
 	.mimetype = "application/vnd.nokia-backup",
diff --git a/obexd/plugins/syncevolution.c b/obexd/plugins/syncevolution.c
index 88744f28a..f0387b986 100644
--- a/obexd/plugins/syncevolution.c
+++ b/obexd/plugins/syncevolution.c
@@ -427,7 +427,7 @@ static ssize_t synce_write(void *object, const void *buf, size_t count)
 	return -EAGAIN;
 }
 
-static struct obex_mime_type_driver synce_driver = {
+static const struct obex_mime_type_driver synce_driver = {
 	.target = SYNCML_TARGET,
 	.target_size = SYNCML_TARGET_SIZE,
 	.open = synce_open,
diff --git a/obexd/src/mimetype.c b/obexd/src/mimetype.c
index cf6e15dc6..462d4ba2f 100644
--- a/obexd/src/mimetype.c
+++ b/obexd/src/mimetype.c
@@ -104,7 +104,7 @@ int obex_object_set_io_watch(void *object, obex_object_io_func func,
 	return 0;
 }
 
-static struct obex_mime_type_driver *find_driver(const uint8_t *target,
+static const struct obex_mime_type_driver *find_driver(const uint8_t *target,
 				unsigned int target_size,
 				const char *mimetype, const uint8_t *who,
 				unsigned int who_size)
@@ -112,7 +112,7 @@ static struct obex_mime_type_driver *find_driver(const uint8_t *target,
 	GSList *l;
 
 	for (l = drivers; l; l = l->next) {
-		struct obex_mime_type_driver *driver = l->data;
+		const struct obex_mime_type_driver *driver = l->data;
 
 		if (memncmp0(target, target_size, driver->target, driver->target_size))
 			continue;
@@ -134,12 +134,12 @@ static struct obex_mime_type_driver *find_driver(const uint8_t *target,
 	return NULL;
 }
 
-struct obex_mime_type_driver *obex_mime_type_driver_find(const uint8_t *target,
+const struct obex_mime_type_driver *obex_mime_type_driver_find(const uint8_t *target,
 				unsigned int target_size,
 				const char *mimetype, const uint8_t *who,
 				unsigned int who_size)
 {
-	struct obex_mime_type_driver *driver;
+	const struct obex_mime_type_driver *driver;
 
 	driver = find_driver(target, target_size, mimetype, who, who_size);
 	if (driver == NULL) {
@@ -162,7 +162,7 @@ struct obex_mime_type_driver *obex_mime_type_driver_find(const uint8_t *target,
 	return driver;
 }
 
-int obex_mime_type_driver_register(struct obex_mime_type_driver *driver)
+int obex_mime_type_driver_register(const struct obex_mime_type_driver *driver)
 {
 	if (!driver) {
 		error("Invalid driver");
@@ -178,12 +178,12 @@ int obex_mime_type_driver_register(struct obex_mime_type_driver *driver)
 
 	DBG("driver %p mimetype %s registered", driver, driver->mimetype);
 
-	drivers = g_slist_append(drivers, driver);
+	drivers = g_slist_append(drivers, (gpointer)driver);
 
 	return 0;
 }
 
-void obex_mime_type_driver_unregister(struct obex_mime_type_driver *driver)
+void obex_mime_type_driver_unregister(const struct obex_mime_type_driver *driver)
 {
 	if (!g_slist_find(drivers, driver)) {
 		error("Unable to unregister: No such driver %p", driver);
diff --git a/obexd/src/mimetype.h b/obexd/src/mimetype.h
index 55ddded08..35346bb46 100644
--- a/obexd/src/mimetype.h
+++ b/obexd/src/mimetype.h
@@ -30,9 +30,9 @@ struct obex_mime_type_driver {
 	int (*remove) (const char *name);
 };
 
-int obex_mime_type_driver_register(struct obex_mime_type_driver *driver);
-void obex_mime_type_driver_unregister(struct obex_mime_type_driver *driver);
-struct obex_mime_type_driver *obex_mime_type_driver_find(const uint8_t *target,
+int obex_mime_type_driver_register(const struct obex_mime_type_driver *driver);
+void obex_mime_type_driver_unregister(const struct obex_mime_type_driver *driver);
+const struct obex_mime_type_driver *obex_mime_type_driver_find(const uint8_t *target,
 				unsigned int target_size,
 				const char *mimetype, const uint8_t *who,
 				unsigned int who_size);
diff --git a/obexd/src/obex-priv.h b/obexd/src/obex-priv.h
index db409e7e4..994144678 100644
--- a/obexd/src/obex-priv.h
+++ b/obexd/src/obex-priv.h
@@ -38,7 +38,7 @@ struct obex_session {
 	struct obex_server *server;
 	gboolean checked;
 	GObex *obex;
-	struct obex_mime_type_driver *driver;
+	const struct obex_mime_type_driver *driver;
 	gboolean headers_sent;
 };
 

-- 
2.43.0

