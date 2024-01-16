From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:40 +0000
Subject: [PATCH BlueZ 15/20] obexd: remove
 obex_mime_type_driver::set_io_watch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-15-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=4552;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=zsTwDFizPZhsw58JcxkEmEoCqpzsEk9q9cIgVjeeEeA=;
 b=NyXbU9u7LdlNGWQ27bcbqF/0lSzH8Ny/exHjIwbMsbRo97CUkGYCyDLKc1VTXw8Xxxj0m1p3v
 4ZI3l7d4oNkD5t5iSWklcTfxr0c3IYQdG3Rxy+2Mxk7aK4utSEE+7J3
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

All the drivers use the default function, where the register function
modifies what should be a constant vtable.

Instead let's remove the indirection, export and use the function as
applicable.

Since we have set and reset, export both functions and cleanup the
users.
---
 obexd/src/mimetype.c | 12 ++----------
 obexd/src/mimetype.h |  6 ++++--
 obexd/src/obex.c     | 12 ++++++------
 3 files changed, 12 insertions(+), 18 deletions(-)

diff --git a/obexd/src/mimetype.c b/obexd/src/mimetype.c
index 212f24b18..cf6e15dc6 100644
--- a/obexd/src/mimetype.c
+++ b/obexd/src/mimetype.c
@@ -73,7 +73,7 @@ static struct io_watch *find_io_watch(void *object)
 	return NULL;
 }
 
-static void reset_io_watch(void *object)
+void obex_object_reset_io_watch(void *object)
 {
 	struct io_watch *watch;
 
@@ -85,16 +85,11 @@ static void reset_io_watch(void *object)
 	g_free(watch);
 }
 
-static int set_io_watch(void *object, obex_object_io_func func,
+int obex_object_set_io_watch(void *object, obex_object_io_func func,
 				void *user_data)
 {
 	struct io_watch *watch;
 
-	if (func == NULL) {
-		reset_io_watch(object);
-		return 0;
-	}
-
 	watch = find_io_watch(object);
 	if (watch)
 		return -EPERM;
@@ -181,9 +176,6 @@ int obex_mime_type_driver_register(struct obex_mime_type_driver *driver)
 		return -EPERM;
 	}
 
-	if (driver->set_io_watch == NULL)
-		driver->set_io_watch = set_io_watch;
-
 	DBG("driver %p mimetype %s registered", driver, driver->mimetype);
 
 	drivers = g_slist_append(drivers, driver);
diff --git a/obexd/src/mimetype.h b/obexd/src/mimetype.h
index e1c14f405..55ddded08 100644
--- a/obexd/src/mimetype.h
+++ b/obexd/src/mimetype.h
@@ -28,8 +28,6 @@ struct obex_mime_type_driver {
 	int (*copy) (const char *name, const char *destname);
 	int (*move) (const char *name, const char *destname);
 	int (*remove) (const char *name);
-	int (*set_io_watch) (void *object, obex_object_io_func func,
-				void *user_data);
 };
 
 int obex_mime_type_driver_register(struct obex_mime_type_driver *driver);
@@ -40,3 +38,7 @@ struct obex_mime_type_driver *obex_mime_type_driver_find(const uint8_t *target,
 				unsigned int who_size);
 
 void obex_object_set_io_flags(void *object, int flags, int err);
+
+void obex_object_reset_io_watch(void *object);
+int obex_object_set_io_watch(void *object, obex_object_io_func func,
+				void *user_data);
diff --git a/obexd/src/obex.c b/obexd/src/obex.c
index 3a68fd66c..4bf5ad124 100644
--- a/obexd/src/obex.c
+++ b/obexd/src/obex.c
@@ -119,7 +119,7 @@ static void os_reset_session(struct obex_session *os)
 	os_session_mark_aborted(os);
 
 	if (os->object) {
-		os->driver->set_io_watch(os->object, NULL, NULL);
+		obex_object_reset_io_watch(os->object);
 		os->driver->close(os->object);
 		if (os->aborted && os->cmd == G_OBEX_OP_PUT && os->path &&
 				os->driver->remove)
@@ -357,7 +357,7 @@ static gssize driver_read(struct obex_session *os, void *buf, gsize size)
 		if (len == -ENOSTR)
 			return 0;
 		if (len == -EAGAIN)
-			os->driver->set_io_watch(os->object, handle_async_io,
+			obex_object_set_io_watch(os->object, handle_async_io,
 									os);
 	}
 
@@ -395,7 +395,7 @@ static void transfer_complete(GObex *obex, GError *err, gpointer user_data)
 	if (os->object && os->driver && os->driver->flush) {
 		if (os->driver->flush(os->object) == -EAGAIN) {
 			g_obex_suspend(os->obex);
-			os->driver->set_io_watch(os->object, handle_async_io,
+			obex_object_set_io_watch(os->object, handle_async_io,
 									os);
 			return;
 		}
@@ -525,7 +525,7 @@ static gboolean recv_data(const void *buf, gsize size, gpointer user_data)
 
 	if (ret == -EAGAIN) {
 		g_obex_suspend(os->obex);
-		os->driver->set_io_watch(os->object, handle_async_io, os);
+		obex_object_set_io_watch(os->object, handle_async_io, os);
 		return TRUE;
 	}
 
@@ -699,7 +699,7 @@ int obex_get_stream_start(struct obex_session *os, const char *filename)
 		return err;
 
 	g_obex_suspend(os->obex);
-	os->driver->set_io_watch(os->object, handle_async_io, os);
+	obex_object_set_io_watch(os->object, handle_async_io, os);
 	return 0;
 }
 
@@ -772,7 +772,7 @@ static gboolean check_put(GObex *obex, GObexPacket *req, void *user_data)
 		break;
 	case -EAGAIN:
 		g_obex_suspend(os->obex);
-		os->driver->set_io_watch(os->object, handle_async_io, os);
+		obex_object_set_io_watch(os->object, handle_async_io, os);
 		return TRUE;
 	default:
 		os_set_response(os, ret);

-- 
2.43.0

