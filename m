From: Yang Li <yang.li@amlogic.com>
Date: Mon, 07 Jul 2025 14:00:36 +0800
Subject: [PATCH BlueZ bluez v4] shared/bap: Add stream state check in
 stream_disable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250707-bap_for_big_sync_lost-v4-1-bf667d839b72@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAINia2gC/4XOywrCMBAF0F8pWRuZPJpaV/6HSMmzBtqmJLX4o
 P9u6EZFxOWd4Z6ZB0o2epvQvnigaGeffBhy4JsC6bMcWou9yRlRoCUIyrGSY+NCbJRvm3QbdNO
 FNGHBeCW0qGqjFMrdMVrnr6t7RKq72Ds65fHZpynE23ptJuvyDzwTTDAYV4MEV5YGDrLvQuv1V
 od+NWf65jD45VAMmPCaKAE7bWT57bCXUwH95bD8j2GEZ0cqV8lPZ1mWJ2clm/9TAQAA
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751868036; l=2206;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=QcDTUyT4vHCnbF3/fxPXb31LpVpGa5jAHW6VnAkctss=;
 b=Ewi4I2DyVBRlTQM7rwfrVakYiZMKqVucrfxUKP2UOnriPqbt1CX/IM+Pw90eobji8MWcnDxWB
 dgwiyFfIEO3Dk77EMDFF38O4j2Inn2mU1dbxyKvfFyR+X6aqRAuo7/v
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add BT_BAP_STREAM_STATE_CONFIG state check so that stream_disable() is
a no-op when the stream is in CONFIG state. This prevents unexpected state
transitions or redundant operations during cleanup.

Error trace:
bluetoothd[2313]: src/shared/bap.c:stream_io_disconnected() stream 0x1f9fc20 io disconnected
bluetoothd[2313]: src/shared/bap.c:bap_ucast_set_state() stream 0x1f9fc20 dir 0x01: releasing -> config
bluetoothd[2313]: src/shared/bap.c:stream_notify() stream 0x1f9fc20 state 1
bluetoothd[2313]: profiles/audio/transport.c:bap_state_changed() stream 0x1f9fc20: releasing(6) -> config(1)
...
bluetoothd[2313]: src/shared/bap.c:stream_disable() stream 0x1f9fc20
bluetoothd[2313]: src/shared/bap.c:bap_ucast_set_state() stream 0x1f9fc20 dir 0x01: config -> qos

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v4:
- Optimizing the code and update the commit message
- Link to v3: https://patch.msgid.link/20250702-bap_for_big_sync_lost-v3-1-d314b60abf7a@amlogic.com

Changes in v3:
- Optimizing the code
- Link to v2: https://patch.msgid.link/20250630-bap_for_big_sync_lost-v2-0-1491b608cda5@amlogic.com

bap for big sync lost

To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Signed-off-by: Yang Li <yang.li@amlogic.com>

Changes in v2:
- Add state check in stream_disable.
- Add type check in stream_io_disconnected.
- Link to v1: https://patch.msgid.link/20250624-bap_for_big_sync_lost-v1-1-0df90a0f55d0@amlogic.com
---
 src/shared/bap.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/src/shared/bap.c b/src/shared/bap.c
index 40e1c974b..2d4f003c7 100644
--- a/src/shared/bap.c
+++ b/src/shared/bap.c
@@ -2124,6 +2124,7 @@ static unsigned int bap_ucast_start(struct bt_bap_stream *stream,
 static uint8_t stream_disable(struct bt_bap_stream *stream, struct iovec *rsp)
 {
 	if (!stream || stream->ep->state == BT_BAP_STREAM_STATE_QOS ||
+			stream->ep->state == BT_BAP_STREAM_STATE_CONFIG ||
 			stream->ep->state == BT_BAP_STREAM_STATE_IDLE)
 		return 0;
 

---
base-commit: 55a6763cde8a2309fd23a96479ee4cf2fc23a442
change-id: 20250624-bap_for_big_sync_lost-63476c679dbb

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

