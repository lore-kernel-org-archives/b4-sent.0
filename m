From: Yang Li <yang.li@amlogic.com>
Date: Wed, 11 Jun 2025 16:57:13 +0800
Subject: [PATCH BlueZ bluez] BASS: support for encrypted broadcast source
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250611-bass_for_encrypted_broadcast_source-v1-1-69b8b156488c@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAOhESWgC/x3NWwrCMBBG4a2UeTbQVG3FrUgJufzRgCRlppXW0
 r0bfPxeztlJwAlC92YnxidJKrlCnxryL5ufUClUU9d217bXWjkrYmJhg+x5m2YE47jY4K3MRsr
 CHir2t4seYgCGM9XSxIhp/V8e5N4LvjQexw/e+SF/fAAAAA==
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749632250; l=5506;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=Qfr9QC5ZGvbsMLaSO57OdwNCExOnVLKS7nkRdPG4ThE=;
 b=frlrfPqIABDhR2naauWJWphL0CHGqb3Zr+Qx3HRwusCJvjUxzL9rC+Do356caIoHbAafc3p1w
 BG9DnBO6cZmDKdCda1xrXziWVi6GzfIrZJSEM6Y/QhqUKEolcW241O7
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the BIS is encrypted as indicated in the BIG Info Report, the
broadcast code needs to be requested from the Assistant.

step 1: Broadcast_Code required
  > HCI Event: LE Meta Event (0x3e) plen 20                 #631 [hci0] 27.176606
        LE Broadcast Isochronous Group Info Advertising Report (0x22)
          Sync Handle: 0x0000
          Number BIS: 2
          NSE: 8
          ISO Interval: 20.00 msec (0x0010)
          BN: 2
          PTO: 2
          IRC: 2
          Maximum PDU: 60
          SDU Interval: 10000 us (0x002710)
          Maximum SDU: 60
          PHY: LE 2M (0x02)
          Framing: Unframed (0x00)
          Encryption: 0x01
  < ACL Data TX: Handle 16 flags 0x00 dlen 44               #633 [hci0] 27.184478
        ATT: Handle Value Notification (0x1b) len 39
          Handle: 0x005f Type: Broadcast Receive State (0x2bc8)
            Data[37]: 01016698a411bb13019f103b02010100000000110d03506978656c20395f32303938020502
            Source_ID: 1
            Source_Address_Type: 1
            Source_Address: 13:BB:11:A4:98:66
            Source_Adv_SID: 1
            Broadcast_ID: 0x3b109f
            PA_Sync_State: Synchronized to PA
            BIG_Encryption: Broadcast_Code required
            Num_Subgroups: 1
            Subgroup #0:
              BIS_Sync State: 0x00000000
              Metadata: #0: len 0x0d type 0x03
              Metadata:   50 69 78 65 6c 20 39 5f 32 30 39 38              Pixel 9_2098
              Metadata: #1: len 0x02 type 0x05
              Metadata:   02
  > ACL Data RX: Handle 16 flags 0x02 dlen 25               #636 [hci0] 27.455744
        ATT: Write Command (0x52) len 20
          Handle: 0x0065 Type: Broadcast Audio Scan Control Point (0x2bc7)
            Data[18]: 04013a4931614b3a2b7c4b7431722b666724
              Opcode: Set Broadcast_Code (0x04)
              Source_ID: 1
              Broadcast_Code[16]: 3a4931614b3a2b7c4b7431722b666724

step 2: Set Broadcast Code when BIG Create Sync
  < HCI Command: LE Broadcast Isoc.. (0x08|0x006b) plen 26  #641 [hci0] 27.669211
          BIG Handle: 0x00
          BIG Sync Handle: 0x0000
          Encryption: Encrypted (0x01)
          Broadcast Code[16]: 3a4931614b3a2b7c4b7431722b666724
          Maximum Number Subevents: 0x00
          Timeout: 20000 ms (0x07d0)
          Number of BIS: 2
          BIS ID: 0x01
          BIS ID: 0x02

Fixes: https://github.com/bluez/bluez/issues/1306
---
Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 profiles/audio/bass.c | 29 +++++++++++++++++++++++++++++
 src/shared/bass.c     | 29 ++++++++++++++---------------
 2 files changed, 43 insertions(+), 15 deletions(-)

diff --git a/profiles/audio/bass.c b/profiles/audio/bass.c
index b27a3fc12..53fde43d6 100644
--- a/profiles/audio/bass.c
+++ b/profiles/audio/bass.c
@@ -427,13 +427,42 @@ static void bap_state_changed(struct bt_bap_stream *stream, uint8_t old_state,
 	}
 }
 
+static void bass_req_bcode_cb(void *user_data, int err)
+{
+	struct bass_setup *setup = user_data;
+
+	if (!err) {
+		if (asprintf(&setup->path, "%s/bis%d",
+			device_get_path(setup->dg->device),
+			setup->bis) < 0)
+			return;
+
+		bt_bap_stream_set_user_data(setup->stream, setup->path);
+
+		bt_bap_stream_config(setup->stream, &setup->qos,
+				setup->config, NULL, NULL);
+		bt_bap_stream_metadata(setup->stream, setup->meta,
+				NULL, NULL);
+	}
+}
+
 static void setup_configure_stream(struct bass_setup *setup)
 {
+	uint8_t empty_bcode[BT_BASS_BCAST_CODE_SIZE] = {0};
+
 	setup->stream = bt_bap_stream_new(setup->dg->bap, setup->lpac, NULL,
 					&setup->qos, setup->config);
 	if (!setup->stream)
 		return;
 
+	if ((setup->qos.bcast.encryption) &&
+	    (!memcmp(setup->qos.bcast.bcode->iov_base,
+		  empty_bcode,
+		  sizeof(empty_bcode)))) {
+		bass_req_bcode(setup->stream, bass_req_bcode_cb, setup, NULL);
+		return;
+	}
+
 	if (asprintf(&setup->path, "%s/bis%d",
 			device_get_path(setup->dg->device),
 			setup->bis) < 0)
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
 

---
base-commit: 95b72bbf1fe42216d02a5ebb99bd18e9b69b6064
change-id: 20250611-bass_for_encrypted_broadcast_source-f68417fdee73

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

