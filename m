From: Yang Li <yang.li@amlogic.com>
Date: Mon, 30 Jun 2025 16:02:40 +0800
Subject: [PATCH BlueZ bluez v2 2/2] shared/bap: Add stream state check in
 stream_disable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250630-bap_for_big_sync_lost-v2-2-1491b608cda5@amlogic.com>
References: <20250630-bap_for_big_sync_lost-v2-0-1491b608cda5@amlogic.com>
In-Reply-To: <20250630-bap_for_big_sync_lost-v2-0-1491b608cda5@amlogic.com>
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751270571; l=1241;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=UsgM1iZe4i9C7+GtPzdOMqpUoV1Gz3JjDhaDIde++68=;
 b=jUwskwxo1rLOAtX497vQB88w0zi40z26kj93Bo6nB3ogM6tIQQ8eecS27jPf61iFS8Gr4TKal
 rsUr1rRUMsFCLkKDs+bLc8C5+NpWVqV2klzA6J3oNfol13JaNMD/ea/
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a state check so that stream_disable() is a no-op when the stream
is not in ENABLING or STREAMING state. This prevents unexpected state
transitions or redundant operations during cleanup.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 src/shared/bap.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/src/shared/bap.c b/src/shared/bap.c
index 984ae782d..5445ddd14 100644
--- a/src/shared/bap.c
+++ b/src/shared/bap.c
@@ -2134,10 +2134,14 @@ static uint8_t stream_disable(struct bt_bap_stream *stream, struct iovec *rsp)
 	/* Sink can autonomously transit to QOS while source needs to go to
 	 * Disabling until BT_ASCS_STOP is received.
 	 */
-	if (stream->ep->dir == BT_BAP_SINK)
+	if (stream->ep->dir == BT_BAP_SINK &&
+	   (stream->ep->state == BT_ASCS_ASE_STATE_ENABLING ||
+	    stream->ep->state == BT_ASCS_ASE_STATE_STREAMING))
 		stream_set_state(stream, BT_BAP_STREAM_STATE_QOS);
 
-	if (stream->ep->dir == BT_BAP_SOURCE)
+	if (stream->ep->dir == BT_BAP_SOURCE &&
+	   (stream->ep->state == BT_ASCS_ASE_STATE_ENABLING ||
+	    stream->ep->state == BT_ASCS_ASE_STATE_STREAMING))
 		stream_set_state(stream, BT_BAP_STREAM_STATE_DISABLING);
 
 	return 0;

-- 
2.42.0

