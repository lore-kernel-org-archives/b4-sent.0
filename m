From: Yang Li <yang.li@amlogic.com>
Date: Wed, 07 Jan 2026 16:51:37 +0800
Subject: [PATCH BlueZ bluez 2/2] bap: add timer to wait for SID update
 before PA sync
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260107-mgmt_ext_adv_sid-v1-2-6832b40813fd@amlogic.com>
References: <20260107-mgmt_ext_adv_sid-v1-0-6832b40813fd@amlogic.com>
In-Reply-To: <20260107-mgmt_ext_adv_sid-v1-0-6832b40813fd@amlogic.com>
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767775901; l=2686;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=YR0LwNu5FiAzaxwLOK2tvD6+VPIsHP6jNefQFy0Z4dM=;
 b=Gwc7w+BPMdlH3cGifxAuvcCn1tAv9D4HChSrXS1yUNB7QH+GHgqPpToiECbXyBNR1PopFItbZ
 HoHsNNA4QSaBMAjPxBwkEHVbR4XzaYuZdUbAeDOeEqs+ZQZXnFJCG86
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a timer to wait for the SID to become valid before triggering
PA sync. Once the SID is available, PA sync is initiated accordingly.

Fixes: https://github.com/bluez/bluez/issues/1758

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 profiles/audio/bap.c | 47 ++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 46 insertions(+), 1 deletion(-)

diff --git a/profiles/audio/bap.c b/profiles/audio/bap.c
index b6eb91ab3..360e0a309 100644
--- a/profiles/audio/bap.c
+++ b/profiles/audio/bap.c
@@ -48,6 +48,7 @@
 #include "src/shared/bap.h"
 #include "src/shared/tmap.h"
 #include "src/shared/gmap.h"
+#include "src/shared/timeout.h"
 
 #include "btio/btio.h"
 #include "src/plugin.h"
@@ -140,6 +141,8 @@ struct bap_data {
 	struct queue *server_streams;
 	GIOChannel *listen_io;
 	unsigned int io_id;
+	unsigned int listen_retry_id;
+	int listen_retry_tries;
 	unsigned int cig_update_id;
 	bool services_ready;
 	bool bap_ready;
@@ -176,6 +179,9 @@ static void bap_data_free(struct bap_data *data)
 {
 	struct queue *bcast_snks = data->bcast_snks;
 
+	if (data->listen_retry_id)
+		timeout_remove(data->listen_retry_id);
+
 	if (data->listen_io) {
 		g_io_channel_shutdown(data->listen_io, TRUE, NULL);
 		g_io_channel_unref(data->listen_io);
@@ -3573,16 +3579,55 @@ static void bap_detached(struct bt_bap *bap, void *user_data)
 	bap_data_remove(data);
 }
 
+static bool pa_sync_retry_cb(gpointer user_data)
+{
+	struct bap_data *data = user_data;
+	uint8_t sid = device_get_sid(data->device);
+
+	if (!data)
+		return FALSE;
+
+	data->listen_retry_tries++;
+	if (data->listen_retry_tries >= 2) {
+		data->listen_retry_id = 0;
+		data->listen_retry_tries = 0;
+		btd_adapter_remove_device(data->adapter, data->device);
+		return FALSE;
+	}
+
+	if (sid != 0xFF) {
+		data->listen_retry_id = 0;
+		data->listen_retry_tries = 0;
+		pa_sync(data);
+		return FALSE;
+	}
+
+	return TRUE;
+}
+
 static int pa_sync(struct bap_data *data)
 {
 	GError *err = NULL;
-	uint8_t sid = 0xff;
+	uint8_t sid = device_get_sid(data->device);
 
 	if (data->listen_io) {
 		DBG("Already probed");
 		return -1;
 	}
 
+	/*
+	 * If SID is not yet available, wait MGMT_EV_EXT_ADV_SID_CHANGED event
+	 * to update it and retry PA sync creation.
+	 */
+	if (sid == 0xFF) {
+		DBG("SID not available, scheduling retry for PA sync");
+		if (data->listen_retry_id == 0)
+			data->listen_retry_id =
+						timeout_add(5, pa_sync_retry_cb, data, NULL);
+
+		return -1;
+	}
+
 	DBG("Create PA sync with this source");
 
 	data->listen_io = bt_io_listen(NULL, iso_pa_sync_confirm_cb, data,

-- 
2.42.0

