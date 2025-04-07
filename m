From: Yang Li <yang.li@amlogic.com>
Date: Mon, 07 Apr 2025 18:34:28 +0800
Subject: [PATCH BlueZ bluez] bap: Add idle notification for ASE State
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250407-bap_aes_state-v1-1-dfc090c49cea@amlogic.com>
X-B4-Tracking: v=1; b=H4sIADOq82cC/x3M3QpAQBBA4VfRXNta/9arSBrMMiW0g0Te3ebyu
 zjnASHHJFAFDzg6WXhdPKIwgH7CZSTFgzfEOs50qgvV4dYiSSs77qRMovPClNaaDME3myPL1/+
 roZsPuqF53w9zOtGrZgAAAA==
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744022071; l=2070;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=WHQVuOtn73gpfFGTGwu0z9z2k9/H8BgH1XFPzS+H9zY=;
 b=r7ZAjl7Of9cxrKOyM0irDmumBtEbBwj5TmeBFNQLiXyySfv4W3E52DtqbFpd1CUca0TZ2krYc
 XfCYArvA75cCm1a4mxCyZRf39YMg/1Sj5/io6o4YzOheKnQ5eIMGV8b
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the ASE state changes from releasing(6) -> idle(0),
the idle state needs to be notified to the Client.

---
Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 src/shared/bap.c | 13 ++++---------
 1 file changed, 4 insertions(+), 9 deletions(-)

diff --git a/src/shared/bap.c b/src/shared/bap.c
index 650bea2f4..c40d6e051 100644
--- a/src/shared/bap.c
+++ b/src/shared/bap.c
@@ -1123,17 +1123,12 @@ static void stream_notify_metadata(struct bt_bap_stream *stream)
 	free(status);
 }
 
-static void stream_notify_release(struct bt_bap_stream *stream)
+static void stream_notify_ase_state(struct bt_bap_stream *stream)
 {
 	struct bt_bap_endpoint *ep = stream->ep;
 	struct bt_ascs_ase_status status;
 
-	DBG(stream->bap, "stream %p", stream);
-
-
-	memset(&status, 0, sizeof(status));
 	status.id = ep->id;
-	ep->state = BT_BAP_STREAM_STATE_RELEASING;
 	status.state = ep->state;
 
 	gatt_db_attribute_notify(ep->attr, (void *)&status, sizeof(status),
@@ -1713,6 +1708,7 @@ static void stream_notify(struct bt_bap_stream *stream, uint8_t state)
 
 	switch (state) {
 	case BT_ASCS_ASE_STATE_IDLE:
+		stream_notify_ase_state(stream);
 		break;
 	case BT_ASCS_ASE_STATE_CONFIG:
 		stream_notify_config(stream);
@@ -1726,7 +1722,7 @@ static void stream_notify(struct bt_bap_stream *stream, uint8_t state)
 		stream_notify_metadata(stream);
 		break;
 	case BT_ASCS_ASE_STATE_RELEASING:
-		stream_notify_release(stream);
+		stream_notify_ase_state(stream);
 		break;
 	}
 }
@@ -6397,9 +6393,8 @@ static bool stream_io_disconnected(struct io *io, void *user_data)
 	DBG(stream->bap, "stream %p io disconnected", stream);
 
 	if (stream->ep->state == BT_ASCS_ASE_STATE_RELEASING)
-		stream_set_state(stream, BT_BAP_STREAM_STATE_CONFIG);
+		stream_set_state(stream, BT_BAP_STREAM_STATE_IDLE);
 
-	bt_bap_stream_set_io(stream, -1);
 	return false;
 }
 

---
base-commit: 0efa20cbf3fb5693c7c2f14ba8cf67053ca029e5
change-id: 20250407-bap_aes_state-9306798ff95a

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

