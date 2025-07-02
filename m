From: Yang Li <yang.li@amlogic.com>
Date: Wed, 02 Jul 2025 09:15:45 +0800
Subject: [PATCH BlueZ bluez v3] shared/bap: Add stream state check in
 stream_disable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250702-bap_for_big_sync_lost-v3-1-d314b60abf7a@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAECIZGgC/4XNTQ6CMBAF4KuYWVszLVDElfcwhvQXmgAlLRKRc
 HdJV7owLt+8zPdWiCY4E+FyWCGY2UXnhz1kxwOoVgyNIU7vGRiyAjnLiRRjbX2opWvquAyq7ny
 cCM/ykiteVlpK2H/HYKx7JvcGsnuYF9z3c+vi5MOS1maayj/wTAklqG2FAm1RaLyKvvONUyfl+
 2TO7MPJ8JfDCBKaV1RyPCstim9n27Y3oWchXgsBAAA=
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751418945; l=2119;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=Li/oG8Hx4idNZ2lePbfz9FOElYrLqbI0dzXwuZBAwXI=;
 b=HBPMJPbCqpIcvpCHxZOQKOt6PknxpqcevJw8a+ImqiIZ+eZ2UKFTdoCDNGhqL0gcxFAFBafD2
 JN1+zfkUcz+D7cnGRPZfuhoqEJ5gsXAQLzCB1E/kxSsWcYnuiOMfDkG
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a state check so that stream_disable() is a no-op when the stream
is not in ENABLING or STREAMING state. This prevents unexpected state
transitions or redundant operations during cleanup.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
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
 src/shared/bap.c | 22 ++++++++++++++--------
 1 file changed, 14 insertions(+), 8 deletions(-)

diff --git a/src/shared/bap.c b/src/shared/bap.c
index 40e1c974b..1790b277b 100644
--- a/src/shared/bap.c
+++ b/src/shared/bap.c
@@ -2131,14 +2131,20 @@ static uint8_t stream_disable(struct bt_bap_stream *stream, struct iovec *rsp)
 
 	ascs_ase_rsp_success(rsp, stream->ep->id);
 
-	/* Sink can autonomously transit to QOS while source needs to go to
-	 * Disabling until BT_ASCS_STOP is received.
-	 */
-	if (stream->ep->dir == BT_BAP_SINK)
-		stream_set_state(stream, BT_BAP_STREAM_STATE_QOS);
-
-	if (stream->ep->dir == BT_BAP_SOURCE)
-		stream_set_state(stream, BT_BAP_STREAM_STATE_DISABLING);
+	switch (stream->ep->state) {
+		case BT_ASCS_ASE_STATE_ENABLING:
+		case BT_ASCS_ASE_STATE_STREAMING:
+			if (stream->ep->dir == BT_BAP_SINK)
+				stream_set_state(stream, BT_BAP_STREAM_STATE_QOS);
+			else if (stream->ep->dir == BT_BAP_SOURCE)
+				/* Sink can autonomously transit to QOS while source needs to go to
+				* Disabling until BT_ASCS_STOP is received.
+				*/
+				stream_set_state(stream, BT_BAP_STREAM_STATE_DISABLING);
+			break;
+		default:
+			break;
+	}
 
 	return 0;
 }

---
base-commit: 55a6763cde8a2309fd23a96479ee4cf2fc23a442
change-id: 20250624-bap_for_big_sync_lost-63476c679dbb

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

