From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Tue, 09 Jun 2026 12:50:24 -0700
Subject: [PATCH net v4 1/4] net: ethernet: oa_tc6: Interrupt is active low,
 level triggered.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260609-level-trigger-v4-1-6f389abdd192@onsemi.com>
References: <20260609-level-trigger-v4-0-6f389abdd192@onsemi.com>
In-Reply-To: <20260609-level-trigger-v4-0-6f389abdd192@onsemi.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Parthiban Veerasooran <Parthiban.Veerasooran@microchip.com>, 
 Andrew Lunn <andrew@lunn.ch>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>, 
 devicetree@vger.kernel.org, Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781034634; l=4799;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=bZcfH7V1Z8MHdt+nWQSb/fIOda9dy2Hl2VbkMljBA1w=;
 b=9gr4xSZH37mafmQ4UaQs9vfCR2Zv/GZ80VUDKHkXRAaQX/4l/8KMF9lXkRThjc1O1Vf/OOBdl
 6eFW5En1j5mBsuYEK9K4b2ldo5qmqXNuvD5DOAu6u7LN71LTZm97g4G
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According OPEN Alliance 10BASET1x MAC-PHY Serial Interface
specification, interrupt is active low, level triggered.

Fixes: 2c6ce5354453 ("net: ethernet: oa_tc6: implement mac-phy interrupt")
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

Changes in v4:
  Interrupt handling mechanism changed to threaded irq because it is
  best suited to handle level triggered interrupt. Threaded irq
  automatically blocks further interrupts until interrupting
  conditions are cleared by its handler.

Changes in v3:
 interrupt registered as level triggerred
---
 drivers/net/ethernet/oa_tc6.c | 61 ++++++++++++-------------------------------
 1 file changed, 17 insertions(+), 44 deletions(-)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 91a906a7918a..e2c0843207f2 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -7,6 +7,7 @@
 
 #include <linux/bitfield.h>
 #include <linux/iopoll.h>
+#include <linux/interrupt.h>
 #include <linux/mdio.h>
 #include <linux/phy.h>
 #include <linux/oa_tc6.h>
@@ -121,8 +122,6 @@ struct oa_tc6 {
 	struct sk_buff *ongoing_tx_skb;
 	struct sk_buff *waiting_tx_skb;
 	struct sk_buff *rx_skb;
-	struct task_struct *spi_thread;
-	wait_queue_head_t spi_wq;
 	u16 tx_skb_offset;
 	u16 spi_data_tx_buf_offset;
 	u16 tx_credits;
@@ -1105,29 +1104,18 @@ static int oa_tc6_try_spi_transfer(struct oa_tc6 *tc6)
 	return 0;
 }
 
-static int oa_tc6_spi_thread_handler(void *data)
+static irqreturn_t oa_tc6_macphy_threaded_irq(int irq, void *data)
 {
 	struct oa_tc6 *tc6 = data;
-	int ret;
-
-	while (likely(!kthread_should_stop())) {
-		/* This kthread will be waken up if there is a tx skb or mac-phy
-		 * interrupt to perform spi transfer with tx chunks.
-		 */
-		wait_event_interruptible(tc6->spi_wq, tc6->int_flag ||
-					 (tc6->waiting_tx_skb &&
-					 tc6->tx_credits) ||
-					 kthread_should_stop());
-
-		if (kthread_should_stop())
-			break;
+	int ret = 0;
 
+	while (tc6->int_flag || (tc6->waiting_tx_skb && tc6->tx_credits)) {
 		ret = oa_tc6_try_spi_transfer(tc6);
 		if (ret)
-			return ret;
+			break;
 	}
 
-	return 0;
+	return IRQ_HANDLED;
 }
 
 static int oa_tc6_update_buffer_status_from_register(struct oa_tc6 *tc6)
@@ -1162,10 +1150,8 @@ static irqreturn_t oa_tc6_macphy_isr(int irq, void *data)
 	 * - extended status event not reported in the previous rx footer.
 	 */
 	tc6->int_flag = true;
-	/* Wake spi kthread to perform spi transfer */
-	wake_up_interruptible(&tc6->spi_wq);
-
-	return IRQ_HANDLED;
+	/* Wake IRQ thread to perform spi transfer */
+	return IRQ_WAKE_THREAD;
 }
 
 /**
@@ -1217,8 +1203,8 @@ netdev_tx_t oa_tc6_start_xmit(struct oa_tc6 *tc6, struct sk_buff *skb)
 	tc6->waiting_tx_skb = skb;
 	spin_unlock_bh(&tc6->tx_skb_lock);
 
-	/* Wake spi kthread to perform spi transfer */
-	wake_up_interruptible(&tc6->spi_wq);
+	/* Wake the threaded IRQ to perform spi transfer. */
+	irq_wake_thread(tc6->spi->irq, tc6);
 
 	return NETDEV_TX_OK;
 }
@@ -1311,24 +1297,15 @@ struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev)
 		goto phy_exit;
 	}
 
-	init_waitqueue_head(&tc6->spi_wq);
-
-	tc6->spi_thread = kthread_run(oa_tc6_spi_thread_handler, tc6,
-				      "oa-tc6-spi-thread");
-	if (IS_ERR(tc6->spi_thread)) {
-		dev_err(&tc6->spi->dev, "Failed to create SPI thread\n");
-		goto phy_exit;
-	}
-
-	sched_set_fifo(tc6->spi_thread);
-
-	ret = devm_request_irq(&tc6->spi->dev, tc6->spi->irq, oa_tc6_macphy_isr,
-			       IRQF_TRIGGER_FALLING, dev_name(&tc6->spi->dev),
-			       tc6);
+	ret = devm_request_threaded_irq(&tc6->spi->dev, tc6->spi->irq,
+					oa_tc6_macphy_isr,
+					oa_tc6_macphy_threaded_irq,
+					IRQF_TRIGGER_LOW | IRQF_ONESHOT,
+					dev_name(&tc6->spi->dev), tc6);
 	if (ret) {
 		dev_err(&tc6->spi->dev, "Failed to request macphy isr %d\n",
 			ret);
-		goto kthread_stop;
+		goto phy_exit;
 	}
 
 	/* oa_tc6_sw_reset_macphy() function resets and clears the MAC-PHY reset
@@ -1338,12 +1315,9 @@ struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev)
 	 * 7.7 and 9.2.8.8 in the OPEN Alliance specification for more details.
 	 */
 	tc6->int_flag = true;
-	wake_up_interruptible(&tc6->spi_wq);
+	irq_wake_thread(tc6->spi->irq, tc6);
 
 	return tc6;
-
-kthread_stop:
-	kthread_stop(tc6->spi_thread);
 phy_exit:
 	oa_tc6_phy_exit(tc6);
 	return NULL;
@@ -1357,7 +1331,6 @@ EXPORT_SYMBOL_GPL(oa_tc6_init);
 void oa_tc6_exit(struct oa_tc6 *tc6)
 {
 	oa_tc6_phy_exit(tc6);
-	kthread_stop(tc6->spi_thread);
 	dev_kfree_skb_any(tc6->ongoing_tx_skb);
 	dev_kfree_skb_any(tc6->waiting_tx_skb);
 	dev_kfree_skb_any(tc6->rx_skb);

-- 
2.43.0

