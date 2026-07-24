From: Yang Li <yang.li@amlogic.com>
Date: Fri, 24 Jul 2026 17:57:24 +0800
Subject: [PATCH BlueZ bluez] bap: Start BIG sync after receiving BIGInfo
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-big_sync-v1-1-0a35013e30ba@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAAM3Y2oC/x3MWwqAIBBA0a3IfCfoYEVtJSLKJhsIC6XoQXtP+
 jxwuQ9ECkwRavFAoIMjrz5BZwLs3HtHksdkQIWFKtHIgV0XL2+lyS0asqrSqCHlW6CJz3/VwLD
 sdEP7vh8FbU8MYQAAAA==
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784887051; l=2484;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=f+CYjopzc8Xtsy+P4oslA+AV69P7mhWv1FepgB25D2c=;
 b=rl8pmG4sgzce3rqk1xfn/ZblOUmrKeFhKFYSI27ypc/QPBTx/LwVM6HxS5WNVvFXgs8fFOSNF
 m/mMUatdqMqAjWMt2dXj6ZBQ8L3ufBGL52wPqSyY7FEY4yjq7tC86M/
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
 profiles/audio/bap.c | 22 ++++++++++++++++++----
 1 file changed, 18 insertions(+), 4 deletions(-)

diff --git a/profiles/audio/bap.c b/profiles/audio/bap.c
index dd4b3c8ff..9e2cd3658 100644
--- a/profiles/audio/bap.c
+++ b/profiles/audio/bap.c
@@ -3650,7 +3650,7 @@ static void setup_refresh_qos(void *data, void *user_data)
 	setup->qos = *bt_bap_stream_get_qos(stream);
 }
 
-static void iso_do_big_sync(GIOChannel *io, void *user_data)
+static void iso_do_big_sync(GIOChannel *io, GIOCondition cond, void *user_data)
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
@@ -3695,13 +3695,27 @@ static void iso_do_big_sync(GIOChannel *io, void *user_data)
 	}
 }
 
+static void long_pa_sync_confirm_cb(GIOChannel *io, void *user_data)
+{
+	struct bap_setup *setup = user_data;
+	struct bap_data *data = setup->data;
+
+	DBG("Long PA Sync done");
+
+	/* store io and add watch that will call iso_do_big_sync */
+	data->io = io;
+	g_io_channel_ref(data->io);
+	data->io_id = g_io_add_watch(io, G_IO_OUT, iso_do_big_sync,
+							setup);
+}
+
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

