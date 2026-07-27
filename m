From: Yang Li <yang.li@amlogic.com>
Date: Mon, 27 Jul 2026 10:10:18 +0800
Subject: [PATCH BlueZ bluez v2] bap: Start BIG sync after receiving BIGInfo
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260727-big_sync-v2-1-053fd3bcc3be@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAAm+ZmoC/2WNyw7CIBREf6W5azG8qtGV/2EaQ/FKb9KCASXWh
 n+XsHV5ZiZnNkgYCROcuw0iZkoUfAW568BOxjtkdK8MkssDP0rNRnK3tHrLdG+lRstPQgqo82f
 EB32a6grj/MYvDDWeKL1CXNtBFq38d2XBBONG9VwoVHw0F7PMwZHd27DAUEr5Ad+DCSepAAAA
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785118218; l=2963;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=8K/J9AtTMnR/lHprg7bq6f69/gczMTTI4wUhzPwxCDc=;
 b=/bsmj5TwlBDveUOO28rrpCDl4yhwfXtLOA4l5gxhlTGsdgXfBPwr8mEQQEyKrsgmtt0rbt/sV
 aW0aXvhPK5/Br9YouXDQm+w6HhJEAUTC/DXp8ucnlVf0mAH+jr7b7rj
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The current implementation starts BIG sync before receiving a BIGInfo
report. According to the Bluetooth Core Specification, BIG sync should
only be initiated after BIGInfo has been received.

Starting BIG sync too early may cause unexpected controller behavior.

Trigger BIG sync from the BIGInfo callback, following the same approach
used by the short PA flow.

Fixes: https://github.com/bluez/bluez/issues/2345

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v2:
- Fixed build error.
- Link to v1: https://patch.msgid.link/20260724-big_sync-v1-1-0a35013e30ba@amlogic.com
---
 profiles/audio/bap.c | 24 ++++++++++++++++++++----
 1 file changed, 20 insertions(+), 4 deletions(-)

diff --git a/profiles/audio/bap.c b/profiles/audio/bap.c
index dd4b3c8ff..42b7bb04c 100644
--- a/profiles/audio/bap.c
+++ b/profiles/audio/bap.c
@@ -3650,7 +3650,7 @@ static void setup_refresh_qos(void *data, void *user_data)
 	setup->qos = *bt_bap_stream_get_qos(stream);
 }
 
-static void iso_do_big_sync(GIOChannel *io, void *user_data)
+static gboolean iso_do_big_sync(GIOChannel *io, GIOCondition cond, void *user_data)
 {
 	GError *err = NULL;
 	struct bap_setup *setup = user_data;
@@ -3659,7 +3659,7 @@ static void iso_do_big_sync(GIOChannel *io, void *user_data)
 	struct bt_iso_qos qos;
 	struct queue *links = bt_bap_stream_io_get_links(setup->stream);
 
-	DBG("PA Sync done");
+	DBG("BIG info received, do BIG sync");
 
 	g_io_channel_unref(data->listen_io);
 	g_io_channel_shutdown(data->listen_io, TRUE, NULL);
@@ -3682,6 +3682,7 @@ static void iso_do_big_sync(GIOChannel *io, void *user_data)
 			BT_IO_OPT_INVALID)) {
 		error("bt_io_set: %s", err->message);
 		g_error_free(err);
+		return FALSE;
 	}
 
 	if (!bt_io_bcast_accept(io,
@@ -3692,16 +3693,31 @@ static void iso_do_big_sync(GIOChannel *io, void *user_data)
 			iso_bc_addr.bc_bis, BT_IO_OPT_INVALID)) {
 		error("bt_io_bcast_accept: %s", err->message);
 		g_error_free(err);
+		return FALSE;
 	}
+
+	return TRUE;
+}
+
+static void long_pa_sync_confirm_cb(GIOChannel *io, void *user_data)
+{
+	struct bap_setup *setup = user_data;
+	struct bap_data *data = setup->data;
+
+	DBG("Long PA Sync done");
+
+	/* store io and add watch that will call iso_do_big_sync */
+	data->io_id = g_io_add_watch(io, G_IO_OUT, iso_do_big_sync,
+							setup);
 }
 
 static void pa_and_big_sync(struct bap_setup *setup)
 {
 	GError *err = NULL;
 	struct bap_data *bap_data = setup->data;
-
 	DBG("Create PA sync with this source");
-	bap_data->listen_io = bt_io_listen(NULL, iso_do_big_sync, setup,
+
+	bap_data->listen_io = bt_io_listen(NULL, long_pa_sync_confirm_cb, setup,
 			NULL, &err,
 			BT_IO_OPT_SOURCE_BDADDR,
 			btd_adapter_get_address(bap_data->adapter),

---
base-commit: 89d477bb5494eef0b24e5667be62f854da250a97
change-id: 20260724-big_sync-45c24ec09121

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

