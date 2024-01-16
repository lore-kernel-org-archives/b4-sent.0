From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:43 +0000
Subject: [PATCH BlueZ 18/20] obexd: const obex_transport_driver instances
 and API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-18-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=5127;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=JDoUhBi2XiJb/UMjdc14J4bi0Pzc2uyYvi1v/YGGtyk=;
 b=2h9Nl51z4y31plLNxA9+pBsKij7tQV4om4ytOX1ZzbgyGjktrKRZ/81gi7imQBXp53r/rqGmr
 qVOsISJYekPCnRrA2pONBADY3hfu0WmmEPD5BXlDC+1zB1jT+jsvkUV
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 obexd/plugins/bluetooth.c |  2 +-
 obexd/src/obex.c          |  4 ++--
 obexd/src/server.c        |  8 ++++----
 obexd/src/server.h        |  2 +-
 obexd/src/transport.c     | 14 +++++++-------
 obexd/src/transport.h     |  6 +++---
 6 files changed, 18 insertions(+), 18 deletions(-)

diff --git a/obexd/plugins/bluetooth.c b/obexd/plugins/bluetooth.c
index bcf6e1998..51afdc9d0 100644
--- a/obexd/plugins/bluetooth.c
+++ b/obexd/plugins/bluetooth.c
@@ -416,7 +416,7 @@ static int bluetooth_getsockname(GIOChannel *io, char **name)
 	return 0;
 }
 
-static struct obex_transport_driver driver = {
+static const struct obex_transport_driver driver = {
 	.name = "bluetooth",
 	.start = bluetooth_start,
 	.getpeername = bluetooth_getpeername,
diff --git a/obexd/src/obex.c b/obexd/src/obex.c
index 4bf5ad124..526861f40 100644
--- a/obexd/src/obex.c
+++ b/obexd/src/obex.c
@@ -1085,7 +1085,7 @@ ssize_t obex_get_non_header_data(struct obex_session *os,
 
 int obex_getpeername(struct obex_session *os, char **name)
 {
-	struct obex_transport_driver *transport = os->server->transport;
+	const struct obex_transport_driver *transport = os->server->transport;
 
 	if (transport == NULL || transport->getpeername == NULL)
 		return -ENOTSUP;
@@ -1095,7 +1095,7 @@ int obex_getpeername(struct obex_session *os, char **name)
 
 int obex_getsockname(struct obex_session *os, char **name)
 {
-	struct obex_transport_driver *transport = os->server->transport;
+	const struct obex_transport_driver *transport = os->server->transport;
 
 	if (transport == NULL || transport->getsockname == NULL)
 		return -ENOTSUP;
diff --git a/obexd/src/server.c b/obexd/src/server.c
index eef149272..0dca728d2 100644
--- a/obexd/src/server.c
+++ b/obexd/src/server.c
@@ -34,12 +34,12 @@
 
 static GSList *servers = NULL;
 
-static void init_server(uint16_t service, GSList *transports)
+static void init_server(uint16_t service, const GSList *transports)
 {
-	GSList *l;
+	const GSList *l;
 
 	for (l = transports; l; l = l->next) {
-		struct obex_transport_driver *transport = l->data;
+		const struct obex_transport_driver *transport = l->data;
 		struct obex_server *server;
 		int err;
 
@@ -66,7 +66,7 @@ static void init_server(uint16_t service, GSList *transports)
 int obex_server_init(void)
 {
 	GSList *drivers;
-	GSList *transports;
+	const GSList *transports;
 	GSList *l;
 
 	drivers = obex_service_driver_list(0);
diff --git a/obexd/src/server.h b/obexd/src/server.h
index c31236ec0..ec063ae2e 100644
--- a/obexd/src/server.h
+++ b/obexd/src/server.h
@@ -10,7 +10,7 @@
  */
 
 struct obex_server {
-	struct obex_transport_driver *transport;
+	const struct obex_transport_driver *transport;
 	void *transport_data;
 	GSList *drivers;
 };
diff --git a/obexd/src/transport.c b/obexd/src/transport.c
index 4b5895e5d..234a0e004 100644
--- a/obexd/src/transport.c
+++ b/obexd/src/transport.c
@@ -27,13 +27,13 @@
 
 static GSList *drivers = NULL;
 
-static struct obex_transport_driver *obex_transport_driver_find(
+static const struct obex_transport_driver *obex_transport_driver_find(
 							const char *name)
 {
-	GSList *l;
+	const GSList *l;
 
 	for (l = drivers; l; l = l->next) {
-		struct obex_transport_driver *driver = l->data;
+		const struct obex_transport_driver *driver = l->data;
 
 		if (g_strcmp0(name, driver->name) == 0)
 			return driver;
@@ -42,12 +42,12 @@ static struct obex_transport_driver *obex_transport_driver_find(
 	return NULL;
 }
 
-GSList *obex_transport_driver_list(void)
+const GSList *obex_transport_driver_list(void)
 {
 	return drivers;
 }
 
-int obex_transport_driver_register(struct obex_transport_driver *driver)
+int obex_transport_driver_register(const struct obex_transport_driver *driver)
 {
 	if (!driver) {
 		error("Invalid driver");
@@ -62,12 +62,12 @@ int obex_transport_driver_register(struct obex_transport_driver *driver)
 
 	DBG("driver %p transport %s registered", driver, driver->name);
 
-	drivers = g_slist_prepend(drivers, driver);
+	drivers = g_slist_prepend(drivers, (gpointer)driver);
 
 	return 0;
 }
 
-void obex_transport_driver_unregister(struct obex_transport_driver *driver)
+void obex_transport_driver_unregister(const struct obex_transport_driver *driver)
 {
 	if (!g_slist_find(drivers, driver)) {
 		error("Unable to unregister: No such driver %p", driver);
diff --git a/obexd/src/transport.h b/obexd/src/transport.h
index 3a16b7620..fe79432cf 100644
--- a/obexd/src/transport.h
+++ b/obexd/src/transport.h
@@ -17,6 +17,6 @@ struct obex_transport_driver {
 	void (*stop) (void *data);
 };
 
-int obex_transport_driver_register(struct obex_transport_driver *driver);
-void obex_transport_driver_unregister(struct obex_transport_driver *driver);
-GSList *obex_transport_driver_list(void);
+int obex_transport_driver_register(const struct obex_transport_driver *driver);
+void obex_transport_driver_unregister(const struct obex_transport_driver *driver);
+const GSList *obex_transport_driver_list(void);

-- 
2.43.0

