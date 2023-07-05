From: Marc Kleine-Budde <mkl@pengutronix.de>
Date: Wed, 05 Jul 2023 11:39:56 +0200
Subject: [PATCH 5/6] can: gs_usb: gs_usb_receive_bulk_callback(): make use
 of stats
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230705-gs_usb-rx-offload-v1-5-8e7e46e40137@pengutronix.de>
References: <20230705-gs_usb-rx-offload-v1-0-8e7e46e40137@pengutronix.de>
In-Reply-To: <20230705-gs_usb-rx-offload-v1-0-8e7e46e40137@pengutronix.de>
To: linux-can@vger.kernel.org
Cc: kernel@pengutronix.de, Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.13-dev-099c9
X-Developer-Signature: v=1; a=openpgp-sha256; l=1192; i=mkl@pengutronix.de;
 h=from:subject:message-id; bh=KN3xlMkapDK2OZz/dgILcpceIPh3GwGIy1DzYPDL30A=;
 b=owEBbQGS/pANAwAKAb5QHEoqigToAcsmYgBkpTp9RMM20RYXYCLHQ27Fa8VYrhKJ0QF4qXgPA
 DVmOv6vmGGJATMEAAEKAB0WIQQOzYG9qPI0qV/1MlC+UBxKKooE6AUCZKU6fQAKCRC+UBxKKooE
 6F76CACr2zdg7pJISkEtQfIb9bGt8QKJzj0ViMFk4Oe+OMUoVKZqPIhqAcpHG5bOshWI7Ls9EYh
 j+mZYXTArU573ntE+e11g4x5gywnRuVdDCcJTNHLWrVU8PuqD7A4Eh3r4yuFB9eFS0y0NLicyTU
 lZc1JeuYv/bxU5/9waOfJ0bOot/oO67W5E+ggcqr8xpKTxwr2SKZLZFfez56HeCd6AFOfthfqZC
 r6AgJl8AY6AzKcjJyH70TBm4JMDK2ZBFR4BnJdlTVa+wasOIXsoDr08dK9FDXAGyxgZMM5GNIK1
 egwB02NX45juj6QM+1g+mnwnPnHH03yZg6/b4dXlhuo9KA+/
X-Developer-Key: i=mkl@pengutronix.de; a=openpgp;
 fpr=C1400BA0B3989E6FBC7D5B5C2B5EE211C58AEA54
X-Endpoint-Received: by B4 Relay for mkl@pengutronix.de/default with auth_id=52
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use the previously assigned variable stats instead of using
netdev->stats.

Signed-off-by: Marc Kleine-Budde <mkl@pengutronix.de>
---
 drivers/net/can/usb/gs_usb.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/net/can/usb/gs_usb.c b/drivers/net/can/usb/gs_usb.c
index b66af9d0ce6a..13a6d8b9ba9e 100644
--- a/drivers/net/can/usb/gs_usb.c
+++ b/drivers/net/can/usb/gs_usb.c
@@ -591,8 +591,8 @@ static void gs_usb_receive_bulk_callback(struct urb *urb)
 
 		gs_usb_set_timestamp(dev, skb, hf);
 
-		netdev->stats.rx_packets++;
-		netdev->stats.rx_bytes += hf->can_dlc;
+		stats->rx_packets++;
+		stats->rx_bytes += hf->can_dlc;
 
 		netif_rx(skb);
 	} else { /* echo_id == hf->echo_id */
@@ -616,9 +616,9 @@ static void gs_usb_receive_bulk_callback(struct urb *urb)
 		skb = dev->can.echo_skb[hf->echo_id];
 		gs_usb_set_timestamp(dev, skb, hf);
 
-		netdev->stats.tx_packets++;
-		netdev->stats.tx_bytes += can_get_echo_skb(netdev, hf->echo_id,
-							   NULL);
+		stats->tx_packets++;
+		stats->tx_bytes += can_get_echo_skb(netdev, hf->echo_id,
+						    NULL);
 
 		gs_free_tx_context(txc);
 

-- 
2.40.1

