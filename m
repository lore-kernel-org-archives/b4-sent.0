From: Yang Li <yang.li@amlogic.com>
Date: Thu, 12 Jun 2025 13:31:02 +0800
Subject: [PATCH BlueZ bluez v2 2/2] shared/bass: Move cb->handle earlier in
 the flow
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250612-bass_for_encrypted_broadcast_source-v2-2-9128a437b595@amlogic.com>
References: <20250612-bass_for_encrypted_broadcast_source-v2-0-9128a437b595@amlogic.com>
In-Reply-To: <20250612-bass_for_encrypted_broadcast_source-v2-0-9128a437b595@amlogic.com>
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749706270; l=1602;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=uizwlgQnQ9OZFKNg9Um1+6VAFUiT2zcih49bxU5xeUU=;
 b=dJ+51dHo2iyOeip4qbM5GpmSZhRboHJtzCMAuH4sq7k2ylztAdpsY8URFxoTVomvIffzqacGq
 Tbh2h6IB8G+BylTrjyrbZIOIRoiT1VG2/cAXVLpeB2M5MUEr5R17hDw
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This change ensures cb->handle is executed even
if the function returns early in the attribute_notify
section. It also allows the stream status to be updated
before notifying the client, improving efficiency.
---
 src/shared/bass.c | 29 ++++++++++++++---------------
 1 file changed, 14 insertions(+), 15 deletions(-)

diff --git a/src/shared/bass.c b/src/shared/bass.c
index 7b9e0da63..11ad59e3b 100644
--- a/src/shared/bass.c
+++ b/src/shared/bass.c
@@ -964,6 +964,20 @@ static void bass_handle_set_bcast_code_op(struct bt_bass *bass,
 
 	gatt_db_attribute_write_result(attrib, id, 0x00);
 
+	for (entry = queue_get_entries(bass->cp_handlers); entry;
+						entry = entry->next) {
+		struct bt_bass_cp_handler *cb = entry->data;
+
+		if (cb->handler) {
+			ret = cb->handler(bcast_src,
+					BT_BASS_SET_BCAST_CODE,
+					params, cb->data);
+			if (ret)
+				DBG(bass, "Unable to handle Set "
+						"Broadcast Code operation");
+		}
+	}
+
 	if (!bass_trigger_big_sync(bcast_src)) {
 		bcast_src->enc = BT_BASS_BIG_ENC_STATE_DEC;
 
@@ -977,21 +991,6 @@ static void bass_handle_set_bcast_code_op(struct bt_bass *bass,
 
 		free(notif->iov_base);
 		free(notif);
-		return;
-	}
-
-	for (entry = queue_get_entries(bass->cp_handlers); entry;
-						entry = entry->next) {
-		struct bt_bass_cp_handler *cb = entry->data;
-
-		if (cb->handler) {
-			ret = cb->handler(bcast_src,
-					BT_BASS_SET_BCAST_CODE,
-					params, cb->data);
-			if (ret)
-				DBG(bass, "Unable to handle Set "
-						"Broadcast Code operation");
-		}
 	}
 }
 

-- 
2.42.0

