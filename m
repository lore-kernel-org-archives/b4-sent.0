From: Yang Li <yang.li@amlogic.com>
Date: Thu, 13 Feb 2025 10:57:52 +0800
Subject: [PATCH BlueZ bluez v3] bap: fixed issue of muting music silent
 after pause and resume.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250213-ascs_bug-v3-1-d5594f0f20c6@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAK9frWcC/2XO3QqCMBwF8FeRXbfYZm6rq94jJPbxVwfOyaZSi
 e/e8iaiy3M4/DgrShAdJHQpVhRhccmFIYfyUCDTqaEF7GzOiBFWEUYkVsmku55bDMJUgla2tNK
 gPB8jNO6xUzek+xleqM51E4PHUxdBfR1KOJ7HNOXS44ViihXlUpy1kE1jr8r3oXXmaIL/wJ1LU
 4jP/eLCdv7/zcKyogUQzizn5PSr1Nu2vQGVTdJB6wAAAA==
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739415474; l=3244;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=CzKtL0pkZRjSLQsuOWTB8/V6Ro3pLYqJB65K2qMqZO0=;
 b=PQHSDBhyLf03aVRjuMGelq/6//pXMVNnECZZYNgpe9Rn8n53ETIIdhc2jh4Im9ncHStBtZFBU
 8Aj1+1cspB/AEIYdwhM192s7bMk1VdrTD66WGOymlU+xTCE9N1PtwDP
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After the ASE state changes (streaming->releasing->idle),
the Client needs to be notified. The process as follows:

...(Sink ASE: ID=1, State=Streaming)
ATT Write Command Packet (ASE Control Point: Op=Release)
ATT Notification Packet (Sink ASE: ID=1, State=Releasing)
ATT Notification Packet (Sink ASE: ID=1, State=Idle)

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v3:
- Solve the compilation error reported by test.bot
- Link to v2: https://patch.msgid.link/20250208-ascs_bug-v2-1-b7e062d6604d@amlogic.com
---
 src/shared/bap.c | 31 ++++++++++++++++++++++---------
 1 file changed, 22 insertions(+), 9 deletions(-)

diff --git a/src/shared/bap.c b/src/shared/bap.c
index 167501282..079f7ede0 100644
--- a/src/shared/bap.c
+++ b/src/shared/bap.c
@@ -930,6 +930,18 @@ static void ascs_ase_rsp_success(struct iovec *iov, uint8_t id)
 					BT_ASCS_REASON_NONE);
 }
 
+static void stream_notify_ase_state(struct bt_bap_stream *stream)
+{
+	struct bt_bap_endpoint *ep = stream->ep;
+	struct bt_ascs_ase_status status;
+
+	status.id = ep->id;
+	status.state = ep->state;
+
+	gatt_db_attribute_notify(ep->attr, (void *)&status, sizeof(status),
+					bt_bap_get_att(stream->bap));
+}
+
 static void stream_notify_config(struct bt_bap_stream *stream)
 {
 	struct bt_bap_endpoint *ep = stream->ep;
@@ -1634,7 +1646,9 @@ static bool stream_notify_state(void *data)
 	struct bt_bap_stream *stream = data;
 	struct bt_bap_endpoint *ep = stream->ep;
 
-	DBG(stream->bap, "stream %p", stream);
+	DBG(stream->bap, "stream %p state %s",
+			stream,
+			bt_bap_stream_statestr(ep->state));
 
 	if (stream->state_id) {
 		timeout_remove(stream->state_id);
@@ -1643,6 +1657,7 @@ static bool stream_notify_state(void *data)
 
 	switch (ep->state) {
 	case BT_ASCS_ASE_STATE_IDLE:
+		stream_notify_ase_state(stream);
 		break;
 	case BT_ASCS_ASE_STATE_CONFIG:
 		stream_notify_config(stream);
@@ -1655,6 +1670,9 @@ static bool stream_notify_state(void *data)
 	case BT_ASCS_ASE_STATE_DISABLING:
 		stream_notify_metadata(stream);
 		break;
+	case BT_ASCS_ASE_STATE_RELEASING:
+		stream_notify_ase_state(stream);
+		break;
 	}
 
 	return false;
@@ -2068,17 +2086,11 @@ static unsigned int bap_ucast_metadata(struct bt_bap_stream *stream,
 
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
@@ -6172,7 +6184,8 @@ static bool stream_io_disconnected(struct io *io, void *user_data)
 
 	DBG(stream->bap, "stream %p io disconnected", stream);
 
-	bt_bap_stream_set_io(stream, -1);
+	if (stream->ep->state == BT_BAP_STREAM_STATE_RELEASING)
+		stream_set_state(stream, BT_BAP_STREAM_STATE_IDLE);
 
 	return false;
 }

---
base-commit: 2ee08ffd4d469781dc627fa50b4a015d9ad68007
change-id: 20250208-ascs_bug-e7c5715d3d8c

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

