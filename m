From: Cunhao Lu <1579567540@qq.com>
Date: Wed, 14 Oct 2026 21:24:07 +0800
Subject: [PATCH net v3 5/5] can: rockchip_canfd: serialize TX with bus-off
 and restart
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-rockchip-canfd-restart-close-v3-5-f0eb41090242@qq.com>
References: <20261014-rockchip-canfd-restart-close-v3-0-f0eb41090242@qq.com>
In-Reply-To: <20261014-rockchip-canfd-restart-close-v3-0-f0eb41090242@qq.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 "David S. Miller" <davem@davemloft.net>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 Oliver Hartkopp <socketcan@hartkopp.net>, kernel@pengutronix.de
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 stable@vger.kernel.org, Cunhao Lu <1579567540@qq.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791984254; l=10382;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=uOX1GsOlJq+zkv5WVsHjwJTCn9VI7mrSM6Z2mpy08jQ=;
 b=OMr2Ws3kLqQnjFCzj382kfJY5VcLNNCUzBJab4r6PDP62oagpna6PR/6w2BuGm2Jo9RV9acxJ
 VkauE4erprnC8yRfa/nCUwM5j2k4oXFhA0ih6+NzW1yBib+5VgQMkZT
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The bus-off path resets the controller without waiting for an active
ndo_start_xmit(). CAN restart flushes the echo ring before calling the
driver's set_mode(), and carrier changes do not drain TX. A concurrent
sender can therefore modify an echo slot during the flush or submit a
frame that is discarded by restart while leaving its echo slot occupied.
Disabling TX only in set_mode() is too late to protect the core flush.

Add a private TX lock and an enabled flag. Hold the lock from the enabled
check through the complete TX submission, including the echo slot, BQL,
FIFO index, command write and queue stop decisions. Close the gate and
stop the queue under the same lock before publishing CAN_STATE_BUS_OFF,
resetting the controller or scheduling recovery. This waits for any
accepted sender and also covers manual recovery, which becomes possible
as soon as the bus-off state is visible. A sender arriving after the gate
closes stops the queue and returns NETDEV_TX_BUSY without consuming its
SKB or touching the controller or echo ring.

Serialize RX-side TX completion and retry with the same gate so that they
cannot access old echo slots or wake the queue while restart owns the
ring. After initialization, enable TX, resume IRQ handling, unmask the
controller and wake the queue in one critical section. Suspend shared IRQ
handling during open until this final step, so an early bus-off cannot be
overridden by the final queue wake. Close and failed open also leave TX
disabled. Keep resets and synchronous IRQ/work draining outside the lock.

Restore carrier in the same critical section before resuming IRQ
handling. A manual restart can observe BUS_OFF and let the CAN core set
carrier on before the old bus-off IRQ calls can_bus_off() and clears it.
After synchronize_irq() has drained that IRQ, restore carrier again so
recovery does not leave the initialized device with carrier off. Keeping
this before IRQ resumption ensures a new bus-off takes precedence.

Fixes: b6661d73290c ("can: rockchip_canfd: add TX PATH")
Cc: stable@vger.kernel.org
Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 drivers/net/can/rockchip/rockchip_canfd-core.c | 51 ++++++++++++++++++++++----
 drivers/net/can/rockchip/rockchip_canfd-rx.c   | 22 +++++++----
 drivers/net/can/rockchip/rockchip_canfd-tx.c   | 16 +++++++-
 drivers/net/can/rockchip/rockchip_canfd.h      |  3 ++
 4 files changed, 75 insertions(+), 17 deletions(-)

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
index 24e87daa1df00..9b357bb8fc70e 100644
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
@@ -237,15 +240,18 @@ static int rkcanfd_handle_rx_int_one(struct rkcanfd_priv *priv)
 		return 0;
 	}
 
-	if (rkcanfd_get_tx_pending(priv)) {
-		bool tx_done = false;
-
+	/* Do not consume echo SKBs, retry TX or wake the queue after bus-off
+	 * has handed ownership of the echo ring to the CAN restart path.
+	 */
+	spin_lock_irqsave(&priv->tx_lock, flags);
+	err = 0;
+	if (priv->tx_enabled && rkcanfd_get_tx_pending(priv))
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

