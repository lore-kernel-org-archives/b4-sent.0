From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:42 +0000
Subject: [PATCH BlueZ 17/20] obexd: const obex_service_driver instances and
 API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-17-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=9315;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=PLJ5Voc0l/2l/ZQxlBtjyCuSLocbfz1q4Ph0208Vyz0=;
 b=YhPEyfLP2GbmdSEVORIMVCnzP4Iwf/iAA8ZKSCko8DHpG1+u/Ybzf+em2HmevlddcV5dbWAWE
 VE13HVAL1exBrhBC7iw+AKF9d4r5TT5KtNNgNH6wTVU4Lx0fNsez+HE
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 obexd/client/mns.c            |  2 +-
 obexd/plugins/bluetooth.c     |  4 ++--
 obexd/plugins/ftp.c           |  2 +-
 obexd/plugins/irmc.c          |  2 +-
 obexd/plugins/mas.c           |  2 +-
 obexd/plugins/opp.c           |  2 +-
 obexd/plugins/pbap.c          |  2 +-
 obexd/plugins/pcsuite.c       |  2 +-
 obexd/plugins/syncevolution.c |  2 +-
 obexd/src/obex-priv.h         |  2 +-
 obexd/src/server.c            |  2 +-
 obexd/src/service.c           | 20 ++++++++++----------
 obexd/src/service.h           |  6 +++---
 13 files changed, 25 insertions(+), 25 deletions(-)

diff --git a/obexd/client/mns.c b/obexd/client/mns.c
index 3b2ae1076..702cf0367 100644
--- a/obexd/client/mns.c
+++ b/obexd/client/mns.c
@@ -346,7 +346,7 @@ static ssize_t event_report_write(void *obj, const void *buf, size_t count)
 	return count;
 }
 
-static struct obex_service_driver mns = {
+static const struct obex_service_driver mns = {
 	.name = "Message Notification server",
 	.service = OBEX_MNS,
 	.target = MNS_TARGET,
diff --git a/obexd/plugins/bluetooth.c b/obexd/plugins/bluetooth.c
index d232d3fd5..bcf6e1998 100644
--- a/obexd/plugins/bluetooth.c
+++ b/obexd/plugins/bluetooth.c
@@ -41,7 +41,7 @@
 
 struct bluetooth_profile {
 	struct obex_server *server;
-	struct obex_service_driver *driver;
+	const struct obex_service_driver *driver;
 	char *uuid;
 	char *path;
 };
@@ -355,7 +355,7 @@ static void *bluetooth_start(struct obex_server *server, int *err)
 	const GSList *l;
 
 	for (l = server->drivers; l; l = l->next) {
-		struct obex_service_driver *driver = l->data;
+		const struct obex_service_driver *driver = l->data;
 		struct bluetooth_profile *profile;
 		const char *uuid;
 
diff --git a/obexd/plugins/ftp.c b/obexd/plugins/ftp.c
index 4b04bab06..874fe2b8b 100644
--- a/obexd/plugins/ftp.c
+++ b/obexd/plugins/ftp.c
@@ -494,7 +494,7 @@ static void ftp_reset(struct obex_session *os, void *user_data)
 	manager_emit_transfer_completed(ftp->transfer);
 }
 
-static struct obex_service_driver ftp = {
+static const struct obex_service_driver ftp = {
 	.name = "File Transfer server",
 	.service = OBEX_FTP,
 	.target = FTP_TARGET,
diff --git a/obexd/plugins/irmc.c b/obexd/plugins/irmc.c
index e85cf70a1..cab97b620 100644
--- a/obexd/plugins/irmc.c
+++ b/obexd/plugins/irmc.c
@@ -427,7 +427,7 @@ static const struct obex_mime_type_driver irmc_driver = {
 	.read = irmc_read,
 };
 
-static struct obex_service_driver irmc = {
+static const struct obex_service_driver irmc = {
 	.name = "IRMC Sync server",
 	.service = OBEX_IRMC,
 	.target = IRMC_TARGET,
diff --git a/obexd/plugins/mas.c b/obexd/plugins/mas.c
index f0eaf6d82..10b972d65 100644
--- a/obexd/plugins/mas.c
+++ b/obexd/plugins/mas.c
@@ -781,7 +781,7 @@ static void *notification_registration_open(const char *name, int oflag,
 	return mas;
 }
 
-static struct obex_service_driver mas = {
+static const struct obex_service_driver mas = {
 	.name = "Message Access server",
 	.service = OBEX_MAS,
 	.target = MAS_TARGET,
diff --git a/obexd/plugins/opp.c b/obexd/plugins/opp.c
index 860161303..777f5f8ed 100644
--- a/obexd/plugins/opp.c
+++ b/obexd/plugins/opp.c
@@ -155,7 +155,7 @@ static void opp_reset(struct obex_session *os, void *user_data)
 	manager_emit_transfer_completed(user_data);
 }
 
-static struct obex_service_driver driver = {
+static const struct obex_service_driver driver = {
 	.name = "Object Push server",
 	.service = OBEX_OPP,
 	.connect = opp_connect,
diff --git a/obexd/plugins/pbap.c b/obexd/plugins/pbap.c
index b363c673b..4175f9de8 100644
--- a/obexd/plugins/pbap.c
+++ b/obexd/plugins/pbap.c
@@ -634,7 +634,7 @@ static int pbap_chkput(struct obex_session *os, void *user_data)
 	return -EBADR;
 }
 
-static struct obex_service_driver pbap = {
+static const struct obex_service_driver pbap = {
 	.name = "Phonebook Access server",
 	.service = OBEX_PBAP,
 	.target = PBAP_TARGET,
diff --git a/obexd/plugins/pcsuite.c b/obexd/plugins/pcsuite.c
index d4a0394af..752074c08 100644
--- a/obexd/plugins/pcsuite.c
+++ b/obexd/plugins/pcsuite.c
@@ -231,7 +231,7 @@ static void pcsuite_disconnect(struct obex_session *os, void *user_data)
 	g_free(pcsuite);
 }
 
-static struct obex_service_driver pcsuite = {
+static const struct obex_service_driver pcsuite = {
 	.name = "Nokia OBEX PC Suite Services",
 	.service = OBEX_PCSUITE,
 	.channel = PCSUITE_CHANNEL,
diff --git a/obexd/plugins/syncevolution.c b/obexd/plugins/syncevolution.c
index f0387b986..ae3dc48c4 100644
--- a/obexd/plugins/syncevolution.c
+++ b/obexd/plugins/syncevolution.c
@@ -436,7 +436,7 @@ static const struct obex_mime_type_driver synce_driver = {
 	.write = synce_write,
 };
 
-static struct obex_service_driver synce = {
+static const struct obex_service_driver synce = {
 	.name = "OBEX server for SyncML, using SyncEvolution",
 	.service = OBEX_SYNCEVOLUTION,
 	.channel = SYNCEVOLUTION_CHANNEL,
diff --git a/obexd/src/obex-priv.h b/obexd/src/obex-priv.h
index 994144678..d2c62a596 100644
--- a/obexd/src/obex-priv.h
+++ b/obexd/src/obex-priv.h
@@ -33,7 +33,7 @@ struct obex_session {
 	void *object;
 	gboolean aborted;
 	int err;
-	struct obex_service_driver *service;
+	const struct obex_service_driver *service;
 	void *service_data;
 	struct obex_server *server;
 	gboolean checked;
diff --git a/obexd/src/server.c b/obexd/src/server.c
index a8fc45092..eef149272 100644
--- a/obexd/src/server.c
+++ b/obexd/src/server.c
@@ -82,7 +82,7 @@ int obex_server_init(void)
 	}
 
 	for (l = drivers; l; l = l->next) {
-		struct obex_service_driver *driver = l->data;
+		const struct obex_service_driver *driver = l->data;
 
 		init_server(driver->service, transports);
 	}
diff --git a/obexd/src/service.c b/obexd/src/service.c
index 0f4e420e8..332d61939 100644
--- a/obexd/src/service.c
+++ b/obexd/src/service.c
@@ -26,14 +26,14 @@
 
 static GSList *drivers = NULL;
 
-struct obex_service_driver *obex_service_driver_find(GSList *drivers,
+const struct obex_service_driver *obex_service_driver_find(GSList *drivers,
 			const uint8_t *target, unsigned int target_size,
 			const uint8_t *who, unsigned int who_size)
 {
 	GSList *l;
 
 	for (l = drivers; l; l = l->next) {
-		struct obex_service_driver *driver = l->data;
+		const struct obex_service_driver *driver = l->data;
 
 		/* who is optional, so only check for it if not NULL */
 		if (who != NULL && memncmp0(who, who_size, driver->who,
@@ -57,10 +57,10 @@ GSList *obex_service_driver_list(uint16_t services)
 		return drivers;
 
 	for (l = drivers; l && services; l = l->next) {
-		struct obex_service_driver *driver = l->data;
+		const struct obex_service_driver *driver = l->data;
 
 		if (driver->service & services) {
-			list = g_slist_append(list, driver);
+			list = g_slist_append(list, (gpointer)driver);
 			services &= ~driver->service;
 		}
 	}
@@ -68,12 +68,12 @@ GSList *obex_service_driver_list(uint16_t services)
 	return list;
 }
 
-static struct obex_service_driver *find_driver(uint16_t service)
+static const struct obex_service_driver *find_driver(uint16_t service)
 {
 	GSList *l;
 
 	for (l = drivers; l; l = l->next) {
-		struct obex_service_driver *driver = l->data;
+		const struct obex_service_driver *driver = l->data;
 
 		if (driver->service == service)
 			return driver;
@@ -82,7 +82,7 @@ static struct obex_service_driver *find_driver(uint16_t service)
 	return NULL;
 }
 
-int obex_service_driver_register(struct obex_service_driver *driver)
+int obex_service_driver_register(const struct obex_service_driver *driver)
 {
 	if (!driver) {
 		error("Invalid driver");
@@ -99,14 +99,14 @@ int obex_service_driver_register(struct obex_service_driver *driver)
 
 	/* Drivers that support who has priority */
 	if (driver->who)
-		drivers = g_slist_prepend(drivers, driver);
+		drivers = g_slist_prepend(drivers, (gpointer)driver);
 	else
-		drivers = g_slist_append(drivers, driver);
+		drivers = g_slist_append(drivers, (gpointer)driver);
 
 	return 0;
 }
 
-void obex_service_driver_unregister(struct obex_service_driver *driver)
+void obex_service_driver_unregister(const struct obex_service_driver *driver)
 {
 	if (!g_slist_find(drivers, driver)) {
 		error("Unable to unregister: No such driver %p", driver);
diff --git a/obexd/src/service.h b/obexd/src/service.h
index e3aee3bf3..8d9f70558 100644
--- a/obexd/src/service.h
+++ b/obexd/src/service.h
@@ -32,9 +32,9 @@ struct obex_service_driver {
 	void (*reset) (struct obex_session *os, void *user_data);
 };
 
-int obex_service_driver_register(struct obex_service_driver *driver);
-void obex_service_driver_unregister(struct obex_service_driver *driver);
+int obex_service_driver_register(const struct obex_service_driver *driver);
+void obex_service_driver_unregister(const struct obex_service_driver *driver);
 GSList *obex_service_driver_list(uint16_t services);
-struct obex_service_driver *obex_service_driver_find(GSList *drivers,
+const struct obex_service_driver *obex_service_driver_find(GSList *drivers,
 			const uint8_t *target, unsigned int target_size,
 			const uint8_t *who, unsigned int who_size);

-- 
2.43.0

