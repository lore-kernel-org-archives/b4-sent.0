From: Marc Kleine-Budde <mkl@pengutronix.de>
Date: Wed, 05 Jul 2023 11:39:53 +0200
Subject: [PATCH 2/6] can: rx-offload: add
 can_rx_offload_get_echo_skb_queue_tail()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230705-gs_usb-rx-offload-v1-2-8e7e46e40137@pengutronix.de>
References: <20230705-gs_usb-rx-offload-v1-0-8e7e46e40137@pengutronix.de>
In-Reply-To: <20230705-gs_usb-rx-offload-v1-0-8e7e46e40137@pengutronix.de>
To: linux-can@vger.kernel.org
Cc: kernel@pengutronix.de, Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.13-dev-099c9
X-Developer-Signature: v=1; a=openpgp-sha256; l=2893; i=mkl@pengutronix.de;
 h=from:subject:message-id; bh=5ETi2Qe+AiH4EnZHcFNk/HBG7Lj+/2jPeFnqBiQ9zNQ=;
 b=owEBbQGS/pANAwAKAb5QHEoqigToAcsmYgBkpTp0Pj6J/fyCiDEs6JVFLZxlQQlMG+vwL21hw
 8VI1sjdO1WJATMEAAEKAB0WIQQOzYG9qPI0qV/1MlC+UBxKKooE6AUCZKU6dAAKCRC+UBxKKooE
 6B8OB/92uNBuYja44yDZFsv8O9SN7yD8Nd6yQu3qBtgpH+tt4FIKCvMd8ywWDZiKFxiAvE+kFRD
 thoxt6XRgLK8BMd9wp1WEozbP34We7UVB7QchjxMB9LZGy0qtVhgTu3KqL7WwbDZSxcUYxtqz5C
 bkJ7jmMebiVNsdWb6tbpbDbmRDEr5ybfFYo5+NQCkZxk+y1QH7kosOSXgTQAA4LdIGfAuppFrm2
 FP9Cpffs1IiIsJrslx8Z1zrUeL1ZNHPIVqBf83YTemqJzGlsuxDrVFE0uDwp8IQ2RIP2PaCFl+y
 N7K6mybW4rXft+KwIWUA9WEZH1sTX16JEarCtNCZNo5TZzUK
X-Developer-Key: i=mkl@pengutronix.de; a=openpgp;
 fpr=C1400BA0B3989E6FBC7D5B5C2B5EE211C58AEA54
X-Endpoint-Received: by B4 Relay for mkl@pengutronix.de/default with auth_id=52
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add can_rx_offload_get_echo_skb_queue_tail(). This function addds the
echo skb at the end of rx-offload the queue. This is intended for
devices without timestamp support.

Signed-off-by: Marc Kleine-Budde <mkl@pengutronix.de>
---
 drivers/net/can/dev/rx-offload.c | 27 ++++++++++++++++++++++++++-
 include/linux/can/rx-offload.h   |  5 ++++-
 2 files changed, 30 insertions(+), 2 deletions(-)

diff --git a/drivers/net/can/dev/rx-offload.c b/drivers/net/can/dev/rx-offload.c
index 6e87ad908346..77091f7d1fa7 100644
--- a/drivers/net/can/dev/rx-offload.c
+++ b/drivers/net/can/dev/rx-offload.c
@@ -1,7 +1,7 @@
 // SPDX-License-Identifier: GPL-2.0-only
 /* Copyright (c) 2014      Protonic Holland,
  *                         David Jander
- * Copyright (C) 2014-2021 Pengutronix,
+ * Copyright (C) 2014-2021, 2023 Pengutronix,
  *                         Marc Kleine-Budde <kernel@pengutronix.de>
  */
 
@@ -280,6 +280,31 @@ int can_rx_offload_queue_tail(struct can_rx_offload *offload,
 }
 EXPORT_SYMBOL_GPL(can_rx_offload_queue_tail);
 
+unsigned int
+can_rx_offload_get_echo_skb_queue_tail(struct can_rx_offload *offload,
+				       unsigned int idx,
+				       unsigned int *frame_len_ptr)
+{
+	struct net_device *dev = offload->dev;
+	struct net_device_stats *stats = &dev->stats;
+	struct sk_buff *skb;
+	unsigned int len;
+	int err;
+
+	skb = __can_get_echo_skb(dev, idx, &len, frame_len_ptr);
+	if (!skb)
+		return 0;
+
+	err = can_rx_offload_queue_tail(offload, skb);
+	if (err) {
+		stats->rx_errors++;
+		stats->tx_fifo_errors++;
+	}
+
+	return len;
+}
+EXPORT_SYMBOL_GPL(can_rx_offload_get_echo_skb_queue_tail);
+
 void can_rx_offload_irq_finish(struct can_rx_offload *offload)
 {
 	unsigned long flags;
diff --git a/include/linux/can/rx-offload.h b/include/linux/can/rx-offload.h
index e3b4199732c6..d29bb4521947 100644
--- a/include/linux/can/rx-offload.h
+++ b/include/linux/can/rx-offload.h
@@ -3,7 +3,7 @@
  * linux/can/rx-offload.h
  *
  * Copyright (c) 2014 David Jander, Protonic Holland
- * Copyright (c) 2014-2017 Pengutronix, Marc Kleine-Budde <kernel@pengutronix.de>
+ * Copyright (c) 2014-2017, 2023 Pengutronix, Marc Kleine-Budde <kernel@pengutronix.de>
  */
 
 #ifndef _CAN_RX_OFFLOAD_H
@@ -49,6 +49,9 @@ unsigned int can_rx_offload_get_echo_skb_queue_timestamp(struct can_rx_offload *
 							 unsigned int *frame_len_ptr);
 int can_rx_offload_queue_tail(struct can_rx_offload *offload,
 			      struct sk_buff *skb);
+unsigned int can_rx_offload_get_echo_skb_queue_tail(struct can_rx_offload *offload,
+						    unsigned int idx,
+						    unsigned int *frame_len_ptr);
 void can_rx_offload_irq_finish(struct can_rx_offload *offload);
 void can_rx_offload_threaded_irq_finish(struct can_rx_offload *offload);
 void can_rx_offload_del(struct can_rx_offload *offload);

-- 
2.40.1

