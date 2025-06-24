From: Yang Li <yang.li@amlogic.com>
Date: Tue, 24 Jun 2025 14:04:17 +0800
Subject: [PATCH BlueZ bluez] shared/bap: Set stream to idle when I/O is
 disconnected
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250624-bap_for_big_sync_lost-v1-1-0df90a0f55d0@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAOA/WmgC/x3MQQqDMBBA0avIrA1oqpF6FSkhE0c7IIlkbNGKd
 29w+Rb/nyCUmAT64oREXxaOIaMuC/BvF2ZSPGaDrnRbGd0odKudYrLIs5UjeLtE2ZR5NJ3xpnu
 OiJDbNdHE+/0dAJcP/eB1XX8TtvK4bgAAAA==
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750745059; l=3551;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=NnW6oCsp7Gte23sNn8PxIxPN0k6NBhSjprOBezp/bpQ=;
 b=geP9VZMgorkMMNCVVZ1CXDo8OloIkJzCS1Q0kLPEe+L3ZiQEcvFbr5nd36JFz39kRaelW9Znl
 dXAf08jHfhsArzKB8bcb4CNZi8qrhsei18iMKyEY8AS8DArPujqleIz
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the CIS link is disconnected, the ASE status transitions from Releasing to
Idle.

  > HCI Event: Disconnect Complete (0x05) plen 4           #1484 [hci0] 67.947425
  		Status: Success (0x00)
  		Handle: 512 Address: 5C:B1:E1:2F:01:B9 (Resolvable)
  		Identity type: Random (0x01)
  		Identity: E8:D5:2B:59:57:A6 (Static)
  		Reason: Remote User Terminated Connection (0x13)
  = bluetoothd: src/shared/bap.c:stream_io_disconnected() stream 0x..   67.948018
  = bluetoothd: src/shared/bap.c:bap_ucast_set_state() stream 0xdff..   67.948145
  = bluetoothd: src/shared/bap.c:stream_notify() stream 0xdffda8 st..   67.948275
  = bluetoothd: src/gatt-database.c:send_notification_to_device() G..   67.948525
  = bluetoothd: profiles/audio/bap.c:bap_state() stream 0xdffda8: r..   67.948679
  = bluetoothd: profiles/audio/transport.c:bap_state_changed() stre..   67.948967
  = bluetoothd: profiles/audio/transport.c:transport_update_playing..   67.949061
  = bluetoothd: profiles/audio/transport.c:media_transport_remove_o..   67.949106
  = bluetoothd: profiles/audio/transport.c:media_owner_free() Owner..   67.949149
  = bluetoothd: profiles/audio/transport.c:media_transport_suspend(..   67.949375
  = bluetoothd: profiles/audio/transport.c:transport_set_state() St..   67.949423
  = bluetoothd: src/shared/bap.c:bap_ucast_detach() stream 0xdffda8..   67.949574
  = bluetoothd: profiles/audio/media.c:pac_clear() endpoint 0xdd2d2..   67.949710

When BIG sync is lost, the stream status transitions from Streaming to Idle.

  > HCI Event: LE Meta Event (0x3e) plen 3                #3189 [hci0] 118.870863
  	LE Broadcast Isochronous Group Sync Lost (0x1e)
  		BIG Handle: 0x00
  		Reason: Remote User Terminated Connection (0x13)
  = bluetoothd: src/shared/bap.c:stream_io_disconnected() stream 0..   118.871183
  = bluetoothd: src/shared/bap.c:bap_bcast_set_state() stream 0xdf..   118.871227
  = bluetoothd: profiles/audio/bap.c:bap_state_bcast_sink() stream..   118.871258
  = bluetoothd: profiles/audio/bass.c:bap_state_changed() stream 0..   118.871307
  = bluetoothd: src/gatt-database.c:send_notification_to_device()...   118.871384
  = bluetoothd: profiles/audio/transport.c:bap_state_changed() str..   118.871452
  = bluetoothd: profiles/audio/transport.c:transport_bap_update_li..   118.871509
  = bluetoothd: profiles/audio/transport.c:transport_update_playin..   118.871555
  = bluetoothd: profiles/audio/transport.c:transport_set_state() S..   118.871610
  = bluetoothd: src/shared/bap.c:bap_bcast_sink_detach() stream 0x..   118.871660
  = bluetoothd: profiles/audio/media.c:pac_clear() endpoint 0xdd25..   118.871689

Fixes: https://github.com/bluez/bluez/issues/1343

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 src/shared/bap.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/src/shared/bap.c b/src/shared/bap.c
index bccbc73ff..d51f3106e 100644
--- a/src/shared/bap.c
+++ b/src/shared/bap.c
@@ -6584,10 +6584,8 @@ static bool stream_io_disconnected(struct io *io, void *user_data)
 
 	DBG(stream->bap, "stream %p io disconnected", stream);
 
-	if (stream->ep->state == BT_ASCS_ASE_STATE_RELEASING)
-		stream_set_state(stream, BT_BAP_STREAM_STATE_CONFIG);
+	stream_set_state(stream, BT_BAP_STREAM_STATE_IDLE);
 
-	bt_bap_stream_set_io(stream, -1);
 	return false;
 }
 

---
base-commit: ae1b7f6ba805f82742bbc32ff275e268248ef9f8
change-id: 20250624-bap_for_big_sync_lost-63476c679dbb

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

