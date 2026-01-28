From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Wed, 28 Jan 2026 22:10:55 +0100
Subject: [PATCH net-next V3 5/7] can: move frame_len to CAN skb extensions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260128-can_skb_ext-v1-5-71b8bcbfd8cf@hartkopp.net>
References: <20260128-can_skb_ext-v1-0-71b8bcbfd8cf@hartkopp.net>
In-Reply-To: <20260128-can_skb_ext-v1-0-71b8bcbfd8cf@hartkopp.net>
To: netdev@vger.kernel.org, linux-can@vger.kernel.org
Cc: Oliver Hartkopp <socketcan@hartkopp.net>, 
 Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769634697; l=3214;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=KuNxrwP9jxa1uMd+k54yrO5yBPLzx5lG49YFAyYxmTI=;
 b=QmpY0IK8YmOcgLhTJMFqLbddvdt6mUI87n2hjXX5J63f8PhOagJb2f2pKvxi09sbBL+E8jm1q
 rPlq2sbxvFXBdxQLBqA43jODlC0adR7p8bNMZLfJTIh29A0xm8pVAh7
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The can_skb_priv::frame_len variable is used to cache a previous
calculated CAN frame length to be passed to BQL queueing disciplines.

Move the can_skb_priv::frame_len content to can_skb_ext::can_framelen.

Signed-off-by: Marc Kleine-Budde <mkl@pengutronix.de>
Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 drivers/net/can/dev/skb.c | 29 +++++++++++++++++++++--------
 1 file changed, 21 insertions(+), 8 deletions(-)

diff --git a/drivers/net/can/dev/skb.c b/drivers/net/can/dev/skb.c
index 470255fe7367b6ff038e45255abc3ea9eed88704..408ee49abce145f49c7837ff30809bc3e42f8ab5 100644
--- a/drivers/net/can/dev/skb.c
+++ b/drivers/net/can/dev/skb.c
@@ -47,10 +47,11 @@ void can_flush_echo_skb(struct net_device *dev)
  */
 int can_put_echo_skb(struct sk_buff *skb, struct net_device *dev,
 		     unsigned int idx, unsigned int frame_len)
 {
 	struct can_priv *priv = netdev_priv(dev);
+	struct can_skb_ext *csx;
 
 	if (idx >= priv->echo_skb_max) {
 		netdev_err(dev, "%s: BUG! Trying to access can_priv::echo_skb out of bounds (%u/max %u)\n",
 			   __func__, idx, priv->echo_skb_max);
 		return -EINVAL;
@@ -73,11 +74,13 @@ int can_put_echo_skb(struct sk_buff *skb, struct net_device *dev,
 		/* make settings for echo to reduce code in irq context */
 		skb->ip_summed = CHECKSUM_UNNECESSARY;
 		skb->dev = dev;
 
 		/* save frame_len to reuse it when transmission is completed */
-		can_skb_prv(skb)->frame_len = frame_len;
+		csx = can_skb_ext_find(skb);
+		if (csx)
+			csx->can_framelen = frame_len;
 
 		if (skb_shinfo(skb)->tx_flags & SKBTX_HW_TSTAMP)
 			skb_shinfo(skb)->tx_flags |= SKBTX_IN_PROGRESS;
 
 		skb_tx_timestamp(skb);
@@ -110,20 +113,25 @@ __can_get_echo_skb(struct net_device *dev, unsigned int idx,
 	if (priv->echo_skb[idx]) {
 		/* Using "struct canfd_frame::len" for the frame
 		 * length is supported on both CAN and CANFD frames.
 		 */
 		struct sk_buff *skb = priv->echo_skb[idx];
-		struct can_skb_priv *can_skb_priv = can_skb_prv(skb);
+		struct can_skb_ext *csx;
 
 		if (skb_shinfo(skb)->tx_flags & SKBTX_IN_PROGRESS)
 			skb_tstamp_tx(skb, skb_hwtstamps(skb));
 
 		/* get the real payload length for netdev statistics */
 		*len_ptr = can_skb_get_data_len(skb);
 
-		if (frame_len_ptr)
-			*frame_len_ptr = can_skb_priv->frame_len;
+		if (frame_len_ptr) {
+			csx = can_skb_ext_find(skb);
+			if (csx)
+				*frame_len_ptr = csx->can_framelen;
+			else
+				*frame_len_ptr = 0;
+		}
 
 		priv->echo_skb[idx] = NULL;
 
 		if (skb->pkt_type == PACKET_LOOPBACK) {
 			skb->pkt_type = PACKET_BROADCAST;
@@ -179,14 +187,19 @@ void can_free_echo_skb(struct net_device *dev, unsigned int idx,
 		return;
 	}
 
 	if (priv->echo_skb[idx]) {
 		struct sk_buff *skb = priv->echo_skb[idx];
-		struct can_skb_priv *can_skb_priv = can_skb_prv(skb);
-
-		if (frame_len_ptr)
-			*frame_len_ptr = can_skb_priv->frame_len;
+		struct can_skb_ext *csx;
+
+		if (frame_len_ptr) {
+			csx = can_skb_ext_find(skb);
+			if (csx)
+				*frame_len_ptr = csx->can_framelen;
+			else
+				*frame_len_ptr = 0;
+		}
 
 		dev_kfree_skb_any(skb);
 		priv->echo_skb[idx] = NULL;
 	}
 }

-- 
2.47.3

