From: Yang Li <yang.li@amlogic.com>
Date: Mon, 06 Jan 2025 10:50:33 +0800
Subject: [PATCH BlueZ bluez] bap: fixed issue of muting music silent after
 pause and resume.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250106-upstream-v1-1-a16879b78ffd@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAPhEe2cC/x3MSwqAIBRG4a3EHSdoVGBbiQZmf3WhF5oRSXtPG
 n5wOJE8HMNTk0VyuNjzviWoPCM7m22C4CGZCllUUslahMOfDmYVClYb6NoOpqSUHw4j3/+qpX4
 JeKh73w/ykkCDYQAAAA==
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736131842; l=3358;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=0vJza6mORdA09fG39CPF0TZT9NAGC+UO9Oed6hi3bPM=;
 b=pWEyFH+FovdewVUB8NJxC/3swuzP3b3j+tGRFi4lyJh+rCZGQk1ZBkq2nex7ogqvNJ6Pcj+jG
 I9lYtIydM9pCP1dgB2sm0AlOmcj1vuP2P244/62z+TZX/x+sREAnJ/b
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CIS sink need caching the Codec Configured when releasing by Pixel,
state machine is releasing -> Codec. If streamming -> idle, CIS sink
was silent after resume music.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 src/shared/bap.c | 43 +++++++++++++++++++++++++++++++------------
 1 file changed, 31 insertions(+), 12 deletions(-)

diff --git a/src/shared/bap.c b/src/shared/bap.c
index 167501282..a7f5dec92 100644
--- a/src/shared/bap.c
+++ b/src/shared/bap.c
@@ -1063,6 +1063,28 @@ static void stream_notify_metadata(struct bt_bap_stream *stream)
 	free(status);
 }
 
+static void stream_notify_release(struct bt_bap_stream *stream)
+{
+	struct bt_bap_endpoint *ep = stream->ep;
+	struct bt_ascs_ase_status *status;
+	size_t len;
+
+	DBG(stream->bap, "stream %p", stream);
+
+	len = sizeof(*status);
+	status = malloc(len);
+
+	memset(status, 0, len);
+	status->id = ep->id;
+	ep->state = BT_BAP_STREAM_STATE_RELEASING;
+	status->state = ep->state;
+
+	gatt_db_attribute_notify(ep->attr, (void *) status, len,
+					bt_bap_get_att(stream->bap));
+
+	free(status);
+}
+
 static struct bt_bap *bt_bap_ref_safe(struct bt_bap *bap)
 {
 	if (!bap || !bap->ref_count || !queue_find(sessions, NULL, bap))
@@ -1634,7 +1656,7 @@ static bool stream_notify_state(void *data)
 	struct bt_bap_stream *stream = data;
 	struct bt_bap_endpoint *ep = stream->ep;
 
-	DBG(stream->bap, "stream %p", stream);
+	DBG(stream->bap, "stream %p status %d", stream, ep->state);
 
 	if (stream->state_id) {
 		timeout_remove(stream->state_id);
@@ -1655,6 +1677,9 @@ static bool stream_notify_state(void *data)
 	case BT_ASCS_ASE_STATE_DISABLING:
 		stream_notify_metadata(stream);
 		break;
+	case BT_ASCS_ASE_STATE_RELEASING:
+		stream_notify_release(stream);
+		break;
 	}
 
 	return false;
@@ -1936,9 +1961,7 @@ static uint8_t stream_disable(struct bt_bap_stream *stream, struct iovec *rsp)
 	/* Sink can autonomously transit to QOS while source needs to go to
 	 * Disabling until BT_ASCS_STOP is received.
 	 */
-	if (stream->ep->dir == BT_BAP_SINK)
-		stream_set_state(stream, BT_BAP_STREAM_STATE_QOS);
-	else
+	if (stream->ep->dir == BT_BAP_SOURCE)
 		stream_set_state(stream, BT_BAP_STREAM_STATE_DISABLING);
 
 	return 0;
@@ -2068,17 +2091,11 @@ static unsigned int bap_ucast_metadata(struct bt_bap_stream *stream,
 
 static uint8_t stream_release(struct bt_bap_stream *stream, struct iovec *rsp)
 {
-	struct bt_bap_pac *pac;
-
 	DBG(stream->bap, "stream %p", stream);
 
 	ascs_ase_rsp_success(rsp, stream->ep->id);
 
-	pac = stream->lpac;
-	if (pac->ops && pac->ops->clear)
-		pac->ops->clear(stream, pac->user_data);
-
-	stream_set_state(stream, BT_BAP_STREAM_STATE_IDLE);
+	stream_set_state(stream, BT_BAP_STREAM_STATE_RELEASING);
 
 	return 0;
 }
@@ -6172,8 +6189,10 @@ static bool stream_io_disconnected(struct io *io, void *user_data)
 
 	DBG(stream->bap, "stream %p io disconnected", stream);
 
-	bt_bap_stream_set_io(stream, -1);
+	if (stream->ep->state == BT_ASCS_ASE_STATE_RELEASING)
+		stream_set_state(stream, BT_BAP_STREAM_STATE_CONFIG);
 
+	bt_bap_stream_set_io(stream, -1);
 	return false;
 }
 

---
base-commit: dfb1ffdc95a00bc06d81a75c11ab5ad2e24d37bf
change-id: 20250106-upstream-1ec9ae96cda4

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

