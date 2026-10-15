From: Cunhao Lu <1579567540@qq.com>
Date: Thu, 15 Oct 2026 17:45:06 +0800
Subject: [PATCH net v5 5/6] can: rockchip_canfd: serialize TX with bus-off
 and restart
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-rockchip-canfd-restart-close-v5-5-ae77327037c9@qq.com>
References: <20261015-rockchip-canfd-restart-close-v5-0-ae77327037c9@qq.com>
In-Reply-To: <20261015-rockchip-canfd-restart-close-v5-0-ae77327037c9@qq.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 "David S. Miller" <davem@davemloft.net>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 Oliver Hartkopp <socketcan@hartkopp.net>, kernel@pengutronix.de
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 stable@vger.kernel.org, Cunhao Lu <1579567540@qq.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792057562; l=9934;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=vX707GeJlnMj7iUOwFvQWZg6cWFMSRmfAPg6cgf2ftE=;
 b=V7FlmfVRPweX3XDM0Qo5VQb2bkMEmZyHiARgfytJbe9XeOgx/SiT+xtzqQMvHMJgU8EZcuZQO
 3sNIdm10BZ/DQ3PcLYPZyNGqbRFs1RJx6I3FlZyo5iqbgPLns/YS+K4
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The bus-off path can reset the controller while ndo_start_xmit() is
active. CAN restart also flushes the echo ring before calling set_mode(),
so disabling TX in that callback is too late to protect echo slots.

Serialize TX submission, RX-side completion and retry with a private
lock and enabled flag. Disable TX and drain these users before publishing
CAN_STATE_BUS_OFF, protecting the core's echo flush during automatic and
manual recovery. Reject further submissions with NETDEV_TX_BUSY.

If close disables TX after an RX IRQ has consumed a self-transmitted
frame, skipping echo filtering alone would deliver it as ordinary RX.
Drop consumed FIFO entries while TX is disabled, checking under the same
lock, and continue draining the FIFO.

After draining the old IRQ and reinitializing the controller, restore
carrier, enable TX, resume IRQ handling and wake the queue under the
lock. This prevents the old bus-off IRQ from leaving manual recovery
with carrier off, while allowing a new bus-off to take precedence.

Keep shared IRQ handling suspended during open until initialization is
complete, and leave TX disabled on close or failed open. Keep resets and
synchronous IRQ/work draining outside the lock.

Fixes: b6661d73290c ("can: rockchip_canfd: add TX PATH")
Cc: stable@vger.kernel.org
Signed-off-by: Cunhao Lu <1579567540@qq.com>

---
Changes in v5:
- Drop consumed RX FIFO entries when tx_enabled is false under tx_lock,
  rather than skipping only echo filtering and delivering them as RX.
---
 drivers/net/can/rockchip/rockchip_canfd-core.c | 51 ++++++++++++++++++++++----
 drivers/net/can/rockchip/rockchip_canfd-rx.c   | 26 +++++++++----
 drivers/net/can/rockchip/rockchip_canfd-tx.c   | 16 +++++++-
 drivers/net/can/rockchip/rockchip_canfd.h      |  3 ++
 4 files changed, 80 insertions(+), 16 deletions(-)

diff --git a/drivers/net/can/rockchip/rockchip_canfd-core.c b/drivers/net/can/rockchip/rockchip_canfd-core.c
index 4b3db07242395..150748c0b6845 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-core.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-core.c
@@ -326,6 +326,35 @@ static void rkcanfd_chip_start(struct rkcanfd_priv *priv)
 		   rkcanfd_read(priv, RKCANFD_REG_MODE));
 }
 
+static void rkcanfd_tx_disable(struct rkcanfd_priv *priv)
+{
+	unsigned long flags;
+
+	spin_lock_irqsave(&priv->tx_lock, flags);
+	priv->tx_enabled = false;
+	netif_stop_queue(priv->ndev);
+	spin_unlock_irqrestore(&priv->tx_lock, flags);
+}
+
+static void rkcanfd_chip_start_finish(struct rkcanfd_priv *priv)
+{
+	unsigned long flags;
+
+	/* Serialize carrier, IRQ enable and queue wake with a new bus-off. */
+	spin_lock_irqsave(&priv->tx_lock, flags);
+	/* A manual restart may have raced with the old bus-off IRQ's
+	 * netif_carrier_off(). That IRQ is now drained; restore carrier
+	 * before resuming IRQ handling so a new bus-off takes precedence.
+	 */
+	netif_carrier_on(priv->ndev);
+	priv->tx_enabled = true;
+	/* Publish the initialized state before resuming IRQ handling. */
+	smp_store_release(&priv->irq_suspended, false);
+	rkcanfd_chip_interrupts_enable(priv);
+	netif_wake_queue(priv->ndev);
+	spin_unlock_irqrestore(&priv->tx_lock, flags);
+}
+
 static void __rkcanfd_chip_stop(struct rkcanfd_priv *priv, const enum can_state state)
 {
 	priv->can.state = state;
@@ -357,6 +386,7 @@ static int rkcanfd_set_mode(struct net_device *ndev,
 
 	switch (mode) {
 	case CAN_MODE_START:
+		rkcanfd_tx_disable(priv);
 		rkcanfd_chip_interrupts_disable(priv);
 		/* Flush the interrupt mask write before suspending the handler. */
 		rkcanfd_read(priv, RKCANFD_REG_INT_MASK);
@@ -367,10 +397,7 @@ static int rkcanfd_set_mode(struct net_device *ndev,
 		rkcanfd_timestamp_stop_sync(priv);
 
 		rkcanfd_chip_start(priv);
-		/* Publish the initialized state before resuming IRQ handling. */
-		smp_store_release(&priv->irq_suspended, false);
-		rkcanfd_chip_interrupts_enable(priv);
-		netif_wake_queue(ndev);
+		rkcanfd_chip_start_finish(priv);
 		break;
 
 	default:
@@ -604,6 +631,12 @@ static int rkcanfd_handle_state_error_int(struct rkcanfd_priv *priv)
 	 * handles cf == NULL.
 	 */
 	skb = rkcanfd_alloc_can_err_skb(priv, &cf, &timestamp);
+	if (new_state == CAN_STATE_BUS_OFF) {
+		/* Drain TX before publishing BUS_OFF, which permits a manual
+		 * restart to flush echo SKBs before calling our set_mode().
+		 */
+		rkcanfd_tx_disable(priv);
+	}
 	can_change_state(ndev, cf, tx_state, rx_state);
 
 	if (new_state == CAN_STATE_BUS_OFF) {
@@ -749,6 +782,8 @@ static int rkcanfd_open(struct net_device *ndev)
 	if (err)
 		goto out_close_candev;
 
+	/* A shared IRQ may run as soon as request_irq() succeeds. */
+	WRITE_ONCE(priv->irq_suspended, true);
 	rkcanfd_chip_start(priv);
 	can_rx_offload_enable(&priv->offload);
 
@@ -756,13 +791,12 @@ static int rkcanfd_open(struct net_device *ndev)
 	if (err)
 		goto out_rkcanfd_chip_stop;
 
-	rkcanfd_chip_interrupts_enable(priv);
-
-	netif_start_queue(ndev);
+	rkcanfd_chip_start_finish(priv);
 
 	return 0;
 
 out_rkcanfd_chip_stop:
+	rkcanfd_tx_disable(priv);
 	can_rx_offload_disable(&priv->offload);
 	rkcanfd_chip_stop_sync(priv, CAN_STATE_STOPPED);
 	pm_runtime_put(ndev->dev.parent);
@@ -776,7 +810,7 @@ static int rkcanfd_stop(struct net_device *ndev)
 	struct rkcanfd_priv *priv = netdev_priv(ndev);
 
 	close_candev_cancel_restart_sync(ndev);
-	netif_stop_queue(ndev);
+	rkcanfd_tx_disable(priv);
 
 	rkcanfd_chip_interrupts_disable(priv);
 	free_irq(ndev->irq, priv);
@@ -939,6 +973,7 @@ static int rkcanfd_probe(struct platform_device *pdev)
 	priv->can.do_set_mode = rkcanfd_set_mode;
 	priv->can.do_get_berr_counter = rkcanfd_get_berr_counter;
 	priv->ndev = ndev;
+	spin_lock_init(&priv->tx_lock);
 
 	match = device_get_match_data(&pdev->dev);
 	if (match) {
diff --git a/drivers/net/can/rockchip/rockchip_canfd-rx.c b/drivers/net/can/rockchip/rockchip_canfd-rx.c
index 24e87daa1df00..5e64317d4eee6 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-rx.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-rx.c
@@ -91,6 +91,7 @@ rkcanfd_fifo_header_to_cfd_header(const struct rkcanfd_priv *priv,
 	return len + cfd->len;
 }
 
+/* Called with tx_lock held and TX enabled. */
 static int rkcanfd_rxstx_filter(struct rkcanfd_priv *priv,
 				const struct canfd_frame *cfd_rx, const u32 ts,
 				bool *tx_done)
@@ -204,7 +205,9 @@ static int rkcanfd_handle_rx_int_one(struct rkcanfd_priv *priv)
 	struct canfd_frame cfd[1] = { }, *skb_cfd;
 	struct rkcanfd_fifo_header header[1] = { };
 	struct sk_buff *skb;
+	unsigned long flags;
 	unsigned int len;
+	bool tx_done = false;
 	int err;
 
 	/* read header into separate struct and convert it later */
@@ -237,15 +240,24 @@ static int rkcanfd_handle_rx_int_one(struct rkcanfd_priv *priv)
 		return 0;
 	}
 
-	if (rkcanfd_get_tx_pending(priv)) {
-		bool tx_done = false;
+	/* Drop FIFO entries while TX is disabled, as they may be self-
+	 * received frames. Do not access the echo ring, retry TX or wake the
+	 * queue while restart owns the ring. The entry is already consumed.
+	 */
+	spin_lock_irqsave(&priv->tx_lock, flags);
+	if (unlikely(!priv->tx_enabled)) {
+		spin_unlock_irqrestore(&priv->tx_lock, flags);
+		return 0;
+	}
 
+	err = 0;
+	if (rkcanfd_get_tx_pending(priv))
 		err = rkcanfd_rxstx_filter(priv, cfd, header->ts, &tx_done);
-		if (err)
-			return err;
-		if (tx_done && !(priv->can.ctrlmode & CAN_CTRLMODE_LOOPBACK))
-			return 0;
-	}
+	spin_unlock_irqrestore(&priv->tx_lock, flags);
+	if (err)
+		return err;
+	if (tx_done && !(priv->can.ctrlmode & CAN_CTRLMODE_LOOPBACK))
+		return 0;
 
 	/* Manual handling of CAN Bus Error counters. See
 	 * rkcanfd_get_corrected_berr_counter() for detailed
diff --git a/drivers/net/can/rockchip/rockchip_canfd-tx.c b/drivers/net/can/rockchip/rockchip_canfd-tx.c
index 12200dcfd3389..f49ed6d2266d9 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-tx.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-tx.c
@@ -69,12 +69,19 @@ netdev_tx_t rkcanfd_start_xmit(struct sk_buff *skb, struct net_device *ndev)
 	u32 reg_frameinfo, reg_id, reg_cmd;
 	unsigned int tx_head, frame_len;
 	const struct canfd_frame *cfd;
+	unsigned long flags;
 	int err;
 	u8 i;
 
 	if (can_dev_dropped_skb(ndev, skb))
 		return NETDEV_TX_OK;
 
+	spin_lock_irqsave(&priv->tx_lock, flags);
+	if (unlikely(!priv->tx_enabled)) {
+		netif_stop_queue(ndev);
+		goto out_busy;
+	}
+
 	if (!netif_subqueue_maybe_stop(priv->ndev, 0,
 				       rkcanfd_get_effective_tx_free(priv),
 				       RKCANFD_TX_STOP_THRESHOLD,
@@ -85,7 +92,7 @@ netdev_tx_t rkcanfd_start_xmit(struct sk_buff *skb, struct net_device *ndev)
 				    priv->tx_head, priv->tx_tail,
 				    rkcanfd_get_tx_pending(priv));
 
-		return NETDEV_TX_BUSY;
+		goto out_busy;
 	}
 
 	cfd = (struct canfd_frame *)skb->data;
@@ -137,7 +144,14 @@ netdev_tx_t rkcanfd_start_xmit(struct sk_buff *skb, struct net_device *ndev)
 				  RKCANFD_TX_STOP_THRESHOLD,
 				  RKCANFD_TX_START_THRESHOLD);
 
+	spin_unlock_irqrestore(&priv->tx_lock, flags);
+
 	return NETDEV_TX_OK;
+
+out_busy:
+	spin_unlock_irqrestore(&priv->tx_lock, flags);
+
+	return NETDEV_TX_BUSY;
 }
 
 void rkcanfd_handle_tx_done_one(struct rkcanfd_priv *priv, const u32 ts,
diff --git a/drivers/net/can/rockchip/rockchip_canfd.h b/drivers/net/can/rockchip/rockchip_canfd.h
index 2743c96ed42f0..4a2bdc205296e 100644
--- a/drivers/net/can/rockchip/rockchip_canfd.h
+++ b/drivers/net/can/rockchip/rockchip_canfd.h
@@ -476,6 +476,9 @@ struct rkcanfd_priv {
 	struct net_device *ndev;
 
 	void __iomem *regs;
+	/* Serialize TX submission/completion with bus-off and restart. */
+	spinlock_t tx_lock;
+	bool tx_enabled;
 	unsigned int tx_head;
 	unsigned int tx_tail;
 

-- 
2.34.1

