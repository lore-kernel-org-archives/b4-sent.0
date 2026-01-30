From: Oliver Hartkopp <socketcan@hartkopp.net>
Date: Fri, 30 Jan 2026 09:42:00 +0100
Subject: [PATCH net-next v6 6/6] can: gw: use can_gw_hops instead of
 sk_buff::csum_start
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260130-can_skb_ext-v6-6-8fceafab7f26@hartkopp.net>
References: <20260130-can_skb_ext-v6-0-8fceafab7f26@hartkopp.net>
In-Reply-To: <20260130-can_skb_ext-v6-0-8fceafab7f26@hartkopp.net>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Oliver Hartkopp <socketcan@hartkopp.net>, 
 Robin van der Gracht <robin@protonic.nl>, 
 Oleksij Rempel <o.rempel@pengutronix.de>, kernel@pengutronix.de, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769762535; l=4389;
 i=socketcan@hartkopp.net; s=20260128; h=from:subject:message-id;
 bh=ZdnaLkXS0i/Yk6gzdfQTbwQzPVjfT/x1mmzPgdZZpG4=;
 b=hOMmONLYju8+bPs/xCIbINgQDXR9fb03f5tZ3KHfnC1NL8isofsnYfN3Xc3bBktYwUZllELUF
 rUdgcPBdBhjAXmYQ9NQWKyla1uIakYKy8o3CpC4b2IsQolEIamEuABM
X-Developer-Key: i=socketcan@hartkopp.net; a=ed25519;
 pk=/gU/7/wBqak3kTsTeFbCCqUi9dnh+1i6ITEkfPj/BvU=
X-Endpoint-Received: by B4 Relay for socketcan@hartkopp.net/20260128 with auth_id=620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As CAN skbs don't use IP checksums the skb->csum_start variable was used to
store the can-gw CAN frame time-to-live counter together with
skb->ip_summed set to CHECKSUM_UNNECESSARY.

Remove the 'hack' using the skb->csum_start variable and move the content
to can_skb_ext::can_gw_hops of the CAN skb extensions.

The module parameter 'max_hops' has been reduced to a single byte to fit
can_skb_ext::can_gw_hops as the maximum value to be stored is 6.

Signed-off-by: Marc Kleine-Budde <mkl@pengutronix.de>
Signed-off-by: Oliver Hartkopp <socketcan@hartkopp.net>
---
 drivers/net/can/vxcan.c |  7 ++++++-
 net/can/gw.c            | 23 ++++++-----------------
 2 files changed, 12 insertions(+), 18 deletions(-)

diff --git a/drivers/net/can/vxcan.c b/drivers/net/can/vxcan.c
index f14c6f02b662..6e642909d6ca 100644
--- a/drivers/net/can/vxcan.c
+++ b/drivers/net/can/vxcan.c
@@ -19,10 +19,11 @@
 #include <linux/can/dev.h>
 #include <linux/can/skb.h>
 #include <linux/can/vxcan.h>
 #include <linux/can/can-ml.h>
 #include <linux/slab.h>
+#include <net/can.h>
 #include <net/rtnetlink.h>
 
 #define DRV_NAME "vxcan"
 
 MODULE_DESCRIPTION("Virtual CAN Tunnel");
@@ -37,10 +38,11 @@ struct vxcan_priv {
 static netdev_tx_t vxcan_xmit(struct sk_buff *oskb, struct net_device *dev)
 {
 	struct vxcan_priv *priv = netdev_priv(dev);
 	struct net_device *peer;
 	struct net_device_stats *peerstats, *srcstats = &dev->stats;
+	struct can_skb_ext *csx;
 	struct sk_buff *skb;
 	unsigned int len;
 
 	if (can_dropped_invalid_skb(dev, oskb))
 		return NETDEV_TX_OK;
@@ -62,11 +64,14 @@ static netdev_tx_t vxcan_xmit(struct sk_buff *oskb, struct net_device *dev)
 		kfree_skb(oskb);
 		goto out_unlock;
 	}
 
 	/* reset CAN GW hop counter */
-	skb->csum_start = 0;
+	csx = can_skb_ext_find(skb);
+	if (csx)
+		csx->can_gw_hops = 0;
+
 	skb->pkt_type   = PACKET_BROADCAST;
 	skb->dev        = peer;
 	skb->ip_summed  = CHECKSUM_UNNECESSARY;
 
 	len = can_skb_get_data_len(skb);
diff --git a/net/can/gw.c b/net/can/gw.c
index 6f158abd61aa..d83fc8242e0b 100644
--- a/net/can/gw.c
+++ b/net/can/gw.c
@@ -69,12 +69,12 @@ MODULE_ALIAS(CAN_GW_NAME);
 
 #define CGW_MIN_HOPS 1
 #define CGW_MAX_HOPS 6
 #define CGW_DEFAULT_HOPS 1
 
-static unsigned int max_hops __read_mostly = CGW_DEFAULT_HOPS;
-module_param(max_hops, uint, 0444);
+static unsigned char max_hops __read_mostly = CGW_DEFAULT_HOPS;
+module_param(max_hops, byte, 0444);
 MODULE_PARM_DESC(max_hops,
 		 "maximum " CAN_GW_NAME " routing hops for CAN frames "
 		 "(valid values: " __stringify(CGW_MIN_HOPS) "-"
 		 __stringify(CGW_MAX_HOPS) " hops, "
 		 "default: " __stringify(CGW_DEFAULT_HOPS) ")");
@@ -478,23 +478,12 @@ static void can_can_gw_rcv(struct sk_buff *skb, void *data)
 		return;
 
 	/* Do not handle CAN frames routed more than 'max_hops' times.
 	 * In general we should never catch this delimiter which is intended
 	 * to cover a misconfiguration protection (e.g. circular CAN routes).
-	 *
-	 * The Controller Area Network controllers only accept CAN frames with
-	 * correct CRCs - which are not visible in the controller registers.
-	 * According to skbuff.h documentation the csum_start element for IP
-	 * checksums is undefined/unused when ip_summed == CHECKSUM_UNNECESSARY.
-	 * Only CAN skbs can be processed here which already have this property.
 	 */
-
-#define cgw_hops(skb) ((skb)->csum_start)
-
-	BUG_ON(skb->ip_summed != CHECKSUM_UNNECESSARY);
-
-	if (cgw_hops(skb) >= max_hops) {
+	if (csx->can_gw_hops >= max_hops) {
 		/* indicate deleted frames due to misconfiguration */
 		gwj->deleted_frames++;
 		return;
 	}
 
@@ -534,15 +523,15 @@ static void can_can_gw_rcv(struct sk_buff *skb, void *data)
 		gwj->dropped_frames++;
 		return;
 	}
 
 	/* put the incremented hop counter in the cloned skb */
-	cgw_hops(nskb) = cgw_hops(skb) + 1;
+	ncsx->can_gw_hops = csx->can_gw_hops + 1;
 
 	/* first processing of this CAN frame -> adjust to private hop limit */
-	if (gwj->limit_hops && cgw_hops(nskb) == 1)
-		cgw_hops(nskb) = max_hops - gwj->limit_hops + 1;
+	if (gwj->limit_hops && ncsx->can_gw_hops == 1)
+		ncsx->can_gw_hops = max_hops - gwj->limit_hops + 1;
 
 	nskb->dev = gwj->dst.dev;
 
 	/* pointer to modifiable CAN frame */
 	cf = (struct canfd_frame *)nskb->data;

-- 
2.51.0

