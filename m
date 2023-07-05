From: Marc Kleine-Budde <mkl@pengutronix.de>
Date: Wed, 05 Jul 2023 11:39:57 +0200
Subject: [PATCH 6/6] can: gs_usb: convert to NAPI/rx-offload to avoid OoO
 reception
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20230705-gs_usb-rx-offload-v1-6-8e7e46e40137@pengutronix.de>
References: <20230705-gs_usb-rx-offload-v1-0-8e7e46e40137@pengutronix.de>
In-Reply-To: <20230705-gs_usb-rx-offload-v1-0-8e7e46e40137@pengutronix.de>
To: linux-can@vger.kernel.org
Cc: kernel@pengutronix.de, Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.13-dev-099c9
X-Developer-Signature: v=1; a=openpgp-sha256; l=6123; i=mkl@pengutronix.de;
 h=from:subject:message-id; bh=B0W7U/BhVHdH+8Vn/33v7Lkn0yiC4r4e6xikZQIQy8M=;
 b=owEBbQGS/pANAwAKAb5QHEoqigToAcsmYgBkpTqA7l7SVBnmdM4lwr/imfw2FPafN5l0uQTOC
 xXkrRohBLWJATMEAAEKAB0WIQQOzYG9qPI0qV/1MlC+UBxKKooE6AUCZKU6gAAKCRC+UBxKKooE
 6ICxB/9FZiPqN2NzUsAElYuj/ha80cdEFdyQPU5ADinxXABmLUeGrvDrIfmZHGzuSW+yEw7Vm6e
 4eGa6KTwWcawUl4AP5jb/8efIabt3ooulNVSL4Iu91RIiCKyx2lbX8mLqyc0SqVej4IH04ANcJf
 F10QPAjsFeTgpaucGi+MbqpRK1IQcb+kTdnLxuKz8ZPv47sz3AutiPDaRuyGZ8PMSNOmJoSG+s/
 yZvDKI15KsHSN0TLViYhxXMo3t3RaJ3prHA1V5Eex07W57HFRiLhKUTgQvj1LYPABTofr0XHhC9
 b8uu9dXjh3rSB18lT1mJdEOknhGN1h4DNSoKRPVqj0T/4Q1D
X-Developer-Key: i=mkl@pengutronix.de; a=openpgp;
 fpr=C1400BA0B3989E6FBC7D5B5C2B5EE211C58AEA54
X-Endpoint-Received: by B4 Relay for mkl@pengutronix.de/default with auth_id=52
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver used to pass received CAN frames/skbs to the network stack
with netif_rx(). In netif_rx() the skbs are queued to the local CPU.
If IRQs are handled in round robin, OoO packets may occur.

To avoid out-of-order reception convert the driver from netif_rx() to
NAPI.

For USB devices with timestamping support use the rx-offload helper
can_rx_offload_queue_timestamp() for the RX, and
can_rx_offload_get_echo_skb_queue_timestamp() for the TX path. Devices
without timestamping support use can_rx_offload_queue_tail() for RX,
and can_rx_offload_get_echo_skb_queue_tail() for the TX path.

Link: https://lore.kernel.org/all/559D628C.5020100@hartkopp.net
Link: https://github.com/candle-usb/candleLight_fw/issues/166
Signed-off-by: Marc Kleine-Budde <mkl@pengutronix.de>
---
 drivers/net/can/usb/Kconfig  |  1 +
 drivers/net/can/usb/gs_usb.c | 79 +++++++++++++++++++++++++++++++++-----------
 2 files changed, 61 insertions(+), 19 deletions(-)

diff --git a/drivers/net/can/usb/Kconfig b/drivers/net/can/usb/Kconfig
index 58fcd2b34820..d1450722cb3c 100644
--- a/drivers/net/can/usb/Kconfig
+++ b/drivers/net/can/usb/Kconfig
@@ -52,6 +52,7 @@ config CAN_F81604
 
 config CAN_GS_USB
 	tristate "Geschwister Schneider UG and candleLight compatible interfaces"
+	select CAN_RX_OFFLOAD
 	help
 	  This driver supports the Geschwister Schneider and
 	  bytewerk.org candleLight compatible
diff --git a/drivers/net/can/usb/gs_usb.c b/drivers/net/can/usb/gs_usb.c
index 13a6d8b9ba9e..f4968fae01fe 100644
--- a/drivers/net/can/usb/gs_usb.c
+++ b/drivers/net/can/usb/gs_usb.c
@@ -5,6 +5,7 @@
  * Copyright (C) 2013-2016 Geschwister Schneider Technologie-,
  * Entwicklungs- und Vertriebs UG (Haftungsbeschränkt).
  * Copyright (C) 2016 Hubert Denkmair
+ * Copyright (c) 2023 Pengutronix, Marc Kleine-Budde <kernel@pengutronix.de>
  *
  * Many thanks to all socketcan devs!
  */
@@ -24,6 +25,7 @@
 #include <linux/can.h>
 #include <linux/can/dev.h>
 #include <linux/can/error.h>
+#include <linux/can/rx-offload.h>
 
 /* Device specific constants */
 #define USB_GS_USB_1_VENDOR_ID 0x1d50
@@ -295,6 +297,7 @@ struct gs_tx_context {
 struct gs_can {
 	struct can_priv can; /* must be the first member */
 
+	struct can_rx_offload offload;
 	struct gs_usb *parent;
 
 	struct net_device *netdev;
@@ -504,22 +507,59 @@ static void gs_update_state(struct gs_can *dev, struct can_frame *cf)
 	}
 }
 
-static void gs_usb_set_timestamp(struct gs_can *dev, struct sk_buff *skb,
-				 const struct gs_host_frame *hf)
+static u32 gs_usb_set_timestamp(struct gs_can *dev, struct sk_buff *skb,
+				const struct gs_host_frame *hf)
 {
 	u32 timestamp;
 
-	if (!(dev->feature & GS_CAN_FEATURE_HW_TIMESTAMP))
-		return;
-
 	if (hf->flags & GS_CAN_FLAG_FD)
 		timestamp = le32_to_cpu(hf->canfd_ts->timestamp_us);
 	else
 		timestamp = le32_to_cpu(hf->classic_can_ts->timestamp_us);
 
-	gs_usb_skb_set_timestamp(dev, skb, timestamp);
+	if (skb)
+		gs_usb_skb_set_timestamp(dev, skb, timestamp);
 
-	return;
+	return timestamp;
+}
+
+static void gs_usb_rx_offload(struct gs_can *dev, struct sk_buff *skb,
+			      const struct gs_host_frame *hf)
+{
+	struct can_rx_offload *offload = &dev->offload;
+	int rc;
+
+	if (dev->feature & GS_CAN_FEATURE_HW_TIMESTAMP) {
+		const u32 ts = gs_usb_set_timestamp(dev, skb, hf);
+
+		rc = can_rx_offload_queue_timestamp(offload, skb, ts);
+	} else {
+		rc = can_rx_offload_queue_tail(offload, skb);
+	}
+
+	if (rc)
+		dev->netdev->stats.rx_fifo_errors++;
+}
+
+static unsigned int
+gs_usb_get_echo_skb(struct gs_can *dev, struct sk_buff *skb,
+		    const struct gs_host_frame *hf)
+{
+	struct can_rx_offload *offload = &dev->offload;
+	const u32 echo_id = hf->echo_id;
+	unsigned int len;
+
+	if (dev->feature & GS_CAN_FEATURE_HW_TIMESTAMP) {
+		const u32 ts = gs_usb_set_timestamp(dev, skb, hf);
+
+		len = can_rx_offload_get_echo_skb_queue_timestamp(offload, echo_id,
+								  ts, NULL);
+	} else {
+		len = can_rx_offload_get_echo_skb_queue_tail(offload, echo_id,
+							     NULL);
+	}
+
+	return len;
 }
 
 static void gs_usb_receive_bulk_callback(struct urb *urb)
@@ -589,12 +629,7 @@ static void gs_usb_receive_bulk_callback(struct urb *urb)
 				gs_update_state(dev, cf);
 		}
 
-		gs_usb_set_timestamp(dev, skb, hf);
-
-		stats->rx_packets++;
-		stats->rx_bytes += hf->can_dlc;
-
-		netif_rx(skb);
+		gs_usb_rx_offload(dev, skb, hf);
 	} else { /* echo_id == hf->echo_id */
 		if (hf->echo_id >= GS_MAX_TX_URBS) {
 			netdev_err(netdev,
@@ -614,12 +649,8 @@ static void gs_usb_receive_bulk_callback(struct urb *urb)
 		}
 
 		skb = dev->can.echo_skb[hf->echo_id];
-		gs_usb_set_timestamp(dev, skb, hf);
-
 		stats->tx_packets++;
-		stats->tx_bytes += can_get_echo_skb(netdev, hf->echo_id,
-						    NULL);
-
+		stats->tx_bytes += gs_usb_get_echo_skb(dev, skb, hf);
 		gs_free_tx_context(txc);
 
 		atomic_dec(&dev->active_tx_urbs);
@@ -638,9 +669,12 @@ static void gs_usb_receive_bulk_callback(struct urb *urb)
 		cf->can_id |= CAN_ERR_CRTL;
 		cf->len = CAN_ERR_DLC;
 		cf->data[1] = CAN_ERR_CRTL_RX_OVERFLOW;
-		netif_rx(skb);
+
+		gs_usb_rx_offload(dev, skb, hf);
 	}
 
+	can_rx_offload_irq_finish(&dev->offload);
+
  resubmit_urb:
 	usb_fill_bulk_urb(urb, usbcan->udev,
 			  usb_rcvbulkpipe(usbcan->udev, GS_USB_ENDPOINT_IN),
@@ -936,6 +970,10 @@ static int gs_can_open(struct net_device *netdev)
 
 	/* finally start device */
 	dev->can.state = CAN_STATE_ERROR_ACTIVE;
+
+	can_rx_offload_add_manual(netdev, &dev->offload, 32);
+	can_rx_offload_enable(&dev->offload);
+
 	dm.flags = cpu_to_le32(flags);
 	rc = usb_control_msg_send(dev->udev, 0, GS_USB_BREQ_MODE,
 				  USB_DIR_OUT | USB_TYPE_VENDOR | USB_RECIP_INTERFACE,
@@ -1024,6 +1062,9 @@ static int gs_can_close(struct net_device *netdev)
 		dev->tx_context[rc].echo_id = GS_MAX_TX_URBS;
 	}
 
+	can_rx_offload_disable(&dev->offload);
+	can_rx_offload_del(&dev->offload);
+
 	/* close the netdev */
 	close_candev(netdev);
 

-- 
2.40.1

