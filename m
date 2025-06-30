From: Yang Li <yang.li@amlogic.com>
Date: Mon, 30 Jun 2025 16:02:39 +0800
Subject: [PATCH BlueZ bluez v2 1/2] shared/bap: Set stream to idle when I/O
 is disconnected
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250630-bap_for_big_sync_lost-v2-1-1491b608cda5@amlogic.com>
References: <20250630-bap_for_big_sync_lost-v2-0-1491b608cda5@amlogic.com>
In-Reply-To: <20250630-bap_for_big_sync_lost-v2-0-1491b608cda5@amlogic.com>
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751270571; l=1928;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=92SydGaaEdJmXbGkfC2lMGKWAMTe2TX3XrYlSHvTicg=;
 b=Ak+o43Nc+GzJ/M6egXdaBv/+cEWN9/0TTZ2kCyuoEnRdFzlJbxgMs5wIWEh8OX1fgIq6xhPDj
 T9IzHgTjv1hDxXP8xzXhwmjjaEYCI7ZjJc5k7fWjwMX/XovZEXMsM3I
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

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
 src/shared/bap.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/src/shared/bap.c b/src/shared/bap.c
index bccbc73ff..984ae782d 100644
--- a/src/shared/bap.c
+++ b/src/shared/bap.c
@@ -6584,6 +6584,11 @@ static bool stream_io_disconnected(struct io *io, void *user_data)
 
 	DBG(stream->bap, "stream %p io disconnected", stream);
 
+	if (stream->lpac->type == BT_BAP_BCAST_SINK) {
+		stream_set_state(stream, BT_BAP_STREAM_STATE_IDLE);
+		return false;
+	}
+
 	if (stream->ep->state == BT_ASCS_ASE_STATE_RELEASING)
 		stream_set_state(stream, BT_BAP_STREAM_STATE_CONFIG);
 

-- 
2.42.0

