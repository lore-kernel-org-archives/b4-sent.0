From: Ye He <ye.he@amlogic.com>
Date: Tue, 16 Dec 2025 17:55:36 +0800
Subject: [PATCH bluez] bap: add PA sync monitor timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251216-bap-pa-sync-v1-1-b1ada9e1a299@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAJcsQWkC/x3MSwqAMAwA0atI1gZsUAleRVxUjRqQWloUP3h3i
 8u3mHkgSlCJ0GQPBDk06uYSTJ7BsFg3C+qYDFRQZcjU2FuP3mK83IBcsiEhZuIRUuGDTHr+txb
 6dZcbuvf9ANE/uMlkAAAA
X-Change-ID: 20251216-bap-pa-sync-84812e28828d
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765878937; l=3588;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=zdZd1Fkwtc7/GqcEgJ03kSMgb45XmyXlaY7hNJfm7mo=;
 b=Ik/72iMAZtnktvwx96ZNND/rXbVX+XyCvovW5qBZjsASuwWHjMXibO2YvXzFsrXOmQmnjxh2Y
 Q+e7tc/apr9Aw2kiDeqC0ZAuSVjUKxn2Psbn4E6ITn9W5cNhSULAFBx
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When PA sync times out, the BAP broadcast probe may remain
pending and fail to exit, even if LE scanning is triggered
again.

This adds a monitor timeout to ensure the pending probe
is properly aborted when PA sync does not complete, avoiding
stuck states.

err print from kernel:
  hci0: command 0x0000 tx timeout

Signed-off-by: Ye He <ye.he@amlogic.com>
---
 profiles/audio/bap.c | 44 ++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 44 insertions(+)

diff --git a/profiles/audio/bap.c b/profiles/audio/bap.c
index cda10a643fdea8314c8717b81961546403bc2dc3..61aad856ff9156fc9048e7a215397abb4f473458 100644
--- a/profiles/audio/bap.c
+++ b/profiles/audio/bap.c
@@ -48,6 +48,7 @@
 #include "src/shared/bap.h"
 #include "src/shared/tmap.h"
 #include "src/shared/gmap.h"
+#include "src/shared/timeout.h"
 
 #include "btio/btio.h"
 #include "src/plugin.h"
@@ -139,6 +140,7 @@ struct bap_data {
 	struct queue *bcast_snks;
 	struct queue *server_streams;
 	GIOChannel *listen_io;
+	unsigned int listen_timer;
 	unsigned int io_id;
 	unsigned int cig_update_id;
 	bool services_ready;
@@ -174,6 +176,9 @@ static void setup_free(void *data);
 
 static void bap_data_free(struct bap_data *data)
 {
+	if (data->listen_timer)
+		timeout_remove(data->listen_timer);
+
 	if (data->listen_io) {
 		g_io_channel_shutdown(data->listen_io, TRUE, NULL);
 		g_io_channel_unref(data->listen_io);
@@ -1559,6 +1564,11 @@ static gboolean big_info_report_cb(GIOChannel *io, GIOCondition cond,
 
 	DBG("BIG Info received");
 
+	if (data->listen_timer) {
+		timeout_remove(data->listen_timer);
+		data->listen_timer = 0;
+	}
+
 	bt_io_get(io, &err,
 			BT_IO_OPT_BASE, &base,
 			BT_IO_OPT_QOS, &qos,
@@ -3566,6 +3576,21 @@ static void bap_detached(struct bt_bap *bap, void *user_data)
 	bap_data_remove(data);
 }
 
+static bool pa_sync_timeout_callback(gpointer user_data)
+{
+	struct bap_data *data = user_data;
+
+	error("PA sync timeout, remove broadcast source device %s",
+				device_get_path(data->device));
+
+	data->listen_timer = 0;
+
+	/* remove device to force exit from pending bcast probe */
+	btd_adapter_remove_device(data->adapter, data->device);
+
+	return FALSE;
+}
+
 static int pa_sync(struct bap_data *data)
 {
 	GError *err = NULL;
@@ -3595,8 +3620,14 @@ static int pa_sync(struct bap_data *data)
 	if (!data->listen_io) {
 		error("%s", err->message);
 		g_error_free(err);
+		return -1;
 	}
 
+	data->listen_timer = timeout_add(
+				/* unit: 10ms */
+				bap_sink_pa_qos.bcast.sync_timeout * 10,
+				pa_sync_timeout_callback,
+				data, NULL);
 	return 0;
 }
 
@@ -3647,6 +3678,11 @@ static void iso_do_big_sync(GIOChannel *io, void *user_data)
 
 	DBG("PA Sync done");
 
+	if (data->listen_timer) {
+		timeout_remove(data->listen_timer);
+		data->listen_timer = 0;
+	}
+
 	g_io_channel_unref(data->listen_io);
 	g_io_channel_shutdown(data->listen_io, TRUE, NULL);
 	data->listen_io = io;
@@ -3702,7 +3738,15 @@ static void pa_and_big_sync(struct bap_setup *setup)
 	if (!bap_data->listen_io) {
 		error("%s", err->message);
 		g_error_free(err);
+		return;
 	}
+
+	bap_data->listen_timer = timeout_add(
+				/* unit: 10ms */
+				bap_sink_pa_qos.bcast.sync_timeout * 10,
+				pa_sync_timeout_callback,
+				bap_data, NULL);
+
 }
 
 static void bap_ready(struct bt_bap *bap, void *user_data)

---
base-commit: ba4978255c3cfb244a89782b30b115c2c9b58c81
change-id: 20251216-bap-pa-sync-84812e28828d

Best regards,
-- 
Ye He <ye.he@amlogic.com>

