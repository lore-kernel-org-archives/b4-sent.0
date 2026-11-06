From: Cunhao Lu <1579567540@qq.com>
Date: Fri, 06 Nov 2026 17:37:24 +0800
Subject: [PATCH net v7 5/7] can: rockchip_canfd: serialize TX with bus-off
 and restart
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-rockchip-canfd-restart-close-v7-5-accdb11bc845@qq.com>
References: <20261106-rockchip-canfd-restart-close-v7-0-accdb11bc845@qq.com>
In-Reply-To: <20261106-rockchip-canfd-restart-close-v7-0-accdb11bc845@qq.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 "David S. Miller" <davem@davemloft.net>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 Oliver Hartkopp <socketcan@hartkopp.net>, kernel@pengutronix.de, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: Cunhao Lu <1579567540@qq.com>, linux-can@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793957851; l=18873;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=DaY8N5KR4Ad6DZT5IPzmFII+CWkusri0LsS/PkZs7Cw=;
 b=TZmlyGkObKLL1lyCOw/RVDukTSGk7v2P85/lVx5ZqhWFJ3PtJqzEPxtl9cGZ9WazNmceu7JXg
 zswK+Sy1azaAlnrBb9AHabCdq5j+gu/Y3FYjpejC8oqRel6Xuvrc0dI
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The bus-off path can reset the controller while TX submission or RX-side
echo handling is active. CAN restart flushes echo skbs before set_mode(),
so disabling TX in that callback is too late to protect the echo ring.

Use tx_lock and tx_enabled to drain TX and RX-side echo users before
publishing CAN_STATE_BUS_OFF. Return NETDEV_TX_BUSY while TX is disabled
and drop consumed RX entries so self-transmitted frames cannot escape
echo filtering as ordinary RX.

Before restart, mask device interrupts and flush the mask write, suspend
shared IRQ access, and drain active handlers and timestamp work. After
reinitialization, restore carrier, TX, IRQ handling and the queue under
tx_lock, so the old bus-off IRQ cannot leave carrier off and a new bus-off
takes precedence. Keep synchronous waits outside the lock and other
shared IRQ users enabled.

Keep IRQ handling suspended until open completes and TX disabled on
close or failed open. Initialize timestamp work once at probe.

Retain the original skb until after unlocking to keep its socket
destructor outside the IRQ-disabled critical section. Preserve the
prerequisite echo failure handling, also rejecting success without an
installed echo skb; neither case may advance tx_head, account BQL or
request hardware TX.

Fixes: ff60bfbaf67f ("can: rockchip_canfd: add driver for Rockchip CAN-FD controller")
Fixes: b6661d73290c ("can: rockchip_canfd: add TX PATH")
Cc: stable@vger.kernel.org
Signed-off-by: Cunhao Lu <1579567540@qq.com>

---
Changes in v7:
- Introduce restart/IRQ synchronization and TX protection together.
- Reuse prerequisite TX locking and adapt to the updated skb ownership.

Changes in v6:
- Defer the original skb's release until after unlocking.
- Abort TX submission if echo preparation fails.

Changes in v5:
- Drop consumed RX FIFO entries when tx_enabled is false under tx_lock,
  rather than skipping only echo filtering and delivering them as RX.

Changes in v3:
- Replace disable_irq()/enable_irq() with device interrupt masking,
  mask readback, an irq_suspended flag and synchronize_irq().
- Pair release/acquire accesses to publish reinitialized state before
  the IRQ handler resumes, without disabling other shared IRQ users.
- Initialize timestamp delayed work once at probe and synchronously
  cancel it before reinitializing the timestamp state during restart.
---
 drivers/net/can/rockchip/rockchip_canfd-core.c     | 64 ++++++++++++++++++++--
 drivers/net/can/rockchip/rockchip_canfd-rx.c       | 59 ++++++++++----------
 .../net/can/rockchip/rockchip_canfd-timestamp.c    |  6 +-
 drivers/net/can/rockchip/rockchip_canfd-tx.c       | 62 ++++++++++++---------
 drivers/net/can/rockchip/rockchip_canfd.h          |  8 ++-
 5 files changed, 134 insertions(+), 65 deletions(-)

diff --git a/drivers/net/can/rockchip/rockchip_canfd-core.c b/drivers/net/can/rockchip/rockchip_canfd-core.c
index d05264605efc2..dcfdd81f940fe 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-core.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-core.c
@@ -20,6 +20,7 @@
 #include <linux/of_device.h>
 #include <linux/platform_device.h>
 #include <linux/pm_runtime.h>
+#include <linux/smp.h>
 #include <linux/string.h>
 
 #include "rockchip_canfd.h"
@@ -325,6 +326,35 @@ static void rkcanfd_chip_start(struct rkcanfd_priv *priv)
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
@@ -356,9 +386,18 @@ static int rkcanfd_set_mode(struct net_device *ndev,
 
 	switch (mode) {
 	case CAN_MODE_START:
+		rkcanfd_tx_disable(priv);
+		rkcanfd_chip_interrupts_disable(priv);
+		/* Flush the interrupt mask write before suspending the handler. */
+		rkcanfd_read(priv, RKCANFD_REG_INT_MASK);
+		/* Suspend our IRQ handler while reinitializing the device. */
+		WRITE_ONCE(priv->irq_suspended, true);
+		/* Wait for handlers that already passed the suspended check. */
+		synchronize_irq(ndev->irq);
+		rkcanfd_timestamp_stop_sync(priv);
+
 		rkcanfd_chip_start(priv);
-		rkcanfd_chip_interrupts_enable(priv);
-		netif_wake_queue(ndev);
+		rkcanfd_chip_start_finish(priv);
 		break;
 
 	default:
@@ -592,6 +631,12 @@ static int rkcanfd_handle_state_error_int(struct rkcanfd_priv *priv)
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
@@ -666,6 +711,10 @@ static irqreturn_t rkcanfd_irq(int irq, void *dev_id)
 	struct rkcanfd_priv *priv = dev_id;
 	u32 reg_int_unmasked, reg_int;
 
+	/* Pairs with the release after restart has initialized the device. */
+	if (smp_load_acquire(&priv->irq_suspended))
+		return IRQ_NONE;
+
 	reg_int_unmasked = rkcanfd_read(priv, RKCANFD_REG_INT);
 	reg_int = reg_int_unmasked & ~priv->reg_int_mask_default;
 
@@ -733,6 +782,8 @@ static int rkcanfd_open(struct net_device *ndev)
 	if (err)
 		goto out_close_candev;
 
+	/* A shared IRQ may run as soon as request_irq() succeeds. */
+	WRITE_ONCE(priv->irq_suspended, true);
 	rkcanfd_chip_start(priv);
 	can_rx_offload_enable(&priv->offload);
 
@@ -740,13 +791,12 @@ static int rkcanfd_open(struct net_device *ndev)
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
@@ -760,7 +810,7 @@ static int rkcanfd_stop(struct net_device *ndev)
 	struct rkcanfd_priv *priv = netdev_priv(ndev);
 
 	close_candev_cancel_restart_sync(ndev);
-	netif_stop_queue(ndev);
+	rkcanfd_tx_disable(priv);
 
 	rkcanfd_chip_interrupts_disable(priv);
 	free_irq(ndev->irq, priv);
@@ -937,6 +987,8 @@ static int rkcanfd_probe(struct platform_device *pdev)
 	if (err)
 		goto out_free_candev;
 
+	rkcanfd_timestamp_work_init(priv);
+
 	err = rkcanfd_register(priv);
 	if (err)
 		goto out_can_rx_offload_del;
diff --git a/drivers/net/can/rockchip/rockchip_canfd-rx.c b/drivers/net/can/rockchip/rockchip_canfd-rx.c
index 59420233c9184..7e43a9b470cb3 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-rx.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-rx.c
@@ -91,6 +91,7 @@ rkcanfd_fifo_header_to_cfd_header(const struct rkcanfd_priv *priv,
 	return len + cfd->len;
 }
 
+/* Called with tx_lock held and TX enabled. */
 static int rkcanfd_rxstx_filter(struct rkcanfd_priv *priv,
 				const struct canfd_frame *cfd_rx, const u32 ts,
 				bool *tx_done)
@@ -100,25 +101,16 @@ static int rkcanfd_rxstx_filter(struct rkcanfd_priv *priv,
 	const struct canfd_frame *cfd_nominal;
 	const struct sk_buff *skb;
 	unsigned int tx_tail;
-	unsigned long flags;
-
-	spin_lock_irqsave(&priv->tx_lock, flags);
 
-	if (!rkcanfd_get_tx_pending(priv))
-		goto out_unlock;
+	lockdep_assert_held(&priv->tx_lock);
 
 	tx_tail = rkcanfd_get_tx_tail(priv);
 	skb = priv->can.echo_skb[tx_tail];
 	if (!skb) {
-		const unsigned int tx_head_unmasked = priv->tx_head;
-		const unsigned int tx_tail_unmasked = priv->tx_tail;
-
-		spin_unlock_irqrestore(&priv->tx_lock, flags);
-
 		netdev_err(priv->ndev,
 			   "%s: echo_skb[%u]=NULL tx_head=0x%08x tx_tail=0x%08x\n",
 			   __func__, tx_tail,
-			   tx_head_unmasked, tx_tail_unmasked);
+			   priv->tx_head, priv->tx_tail);
 
 		return -ENOMSG;
 	}
@@ -134,18 +126,17 @@ static int rkcanfd_rxstx_filter(struct rkcanfd_priv *priv,
 		rkcanfd_handle_tx_done_one(priv, ts, &frame_len);
 
 		WRITE_ONCE(priv->tx_tail, priv->tx_tail + 1);
-		*tx_done = true;
-
-		spin_unlock_irqrestore(&priv->tx_lock, flags);
 		netif_subqueue_completed_wake(priv->ndev, 0, 1, frame_len,
 					      rkcanfd_get_effective_tx_free(priv),
 					      RKCANFD_TX_START_THRESHOLD);
 
+		*tx_done = true;
+
 		return 0;
 	}
 
 	if (!(priv->devtype_data.quirks & RKCANFD_QUIRK_RK3568_ERRATUM_6))
-		goto out_unlock;
+		return 0;
 
 	/* Erratum 6: Extended frames may be send as standard frames.
 	 *
@@ -155,7 +146,7 @@ static int rkcanfd_rxstx_filter(struct rkcanfd_priv *priv,
 	 */
 	if (!(cfd_nominal->can_id & CAN_EFF_FLAG) ||
 	    (cfd_rx->can_id & CAN_EFF_FLAG))
-		goto out_unlock;
+		return 0;
 
 	/* Not affected if:
 	 * - standard part and RTR flag of the TX'ed frame
@@ -163,20 +154,20 @@ static int rkcanfd_rxstx_filter(struct rkcanfd_priv *priv,
 	 */
 	if ((cfd_nominal->can_id & (CAN_RTR_FLAG | CAN_SFF_MASK)) !=
 	    (cfd_rx->can_id & (CAN_RTR_FLAG | CAN_SFF_MASK)))
-		goto out_unlock;
+		return 0;
 
 	/* Not affected if:
 	 * - length is not the same
 	 */
 	if (cfd_nominal->len != cfd_rx->len)
-		goto out_unlock;
+		return 0;
 
 	/* Not affected if:
 	 * - the data of non RTR frames is different
 	 */
 	if (!(cfd_nominal->can_id & CAN_RTR_FLAG) &&
 	    memcmp(cfd_nominal->data, cfd_rx->data, cfd_nominal->len))
-		goto out_unlock;
+		return 0;
 
 	/* Affected by Erratum 6 */
 	u64_stats_update_begin(&rkcanfd_stats->syncp);
@@ -197,9 +188,6 @@ static int rkcanfd_rxstx_filter(struct rkcanfd_priv *priv,
 
 	rkcanfd_xmit_retry(priv);
 
-out_unlock:
-	spin_unlock_irqrestore(&priv->tx_lock, flags);
-
 	return 0;
 }
 
@@ -216,9 +204,11 @@ rkcanfd_fifo_header_empty(const struct rkcanfd_fifo_header *header)
 static int rkcanfd_handle_rx_int_one(struct rkcanfd_priv *priv)
 {
 	struct net_device_stats *stats = &priv->ndev->stats;
-	struct canfd_frame cfd[1] = { }, *skb_cfd;
 	struct rkcanfd_fifo_header header[1] = { };
+	struct canfd_frame cfd[1] = { }, *skb_cfd;
+	bool tx_done = false;
 	struct sk_buff *skb;
+	unsigned long flags;
 	unsigned int len;
 	int err;
 
@@ -252,15 +242,24 @@ static int rkcanfd_handle_rx_int_one(struct rkcanfd_priv *priv)
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
diff --git a/drivers/net/can/rockchip/rockchip_canfd-timestamp.c b/drivers/net/can/rockchip/rockchip_canfd-timestamp.c
index 72774cd2f94b7..ad582afbbd682 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-timestamp.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-timestamp.c
@@ -37,6 +37,11 @@ static void rkcanfd_timestamp_work(struct work_struct *work)
 	schedule_delayed_work(&priv->timestamp, priv->work_delay_jiffies);
 }
 
+void rkcanfd_timestamp_work_init(struct rkcanfd_priv *priv)
+{
+	INIT_DELAYED_WORK(&priv->timestamp, rkcanfd_timestamp_work);
+}
+
 void rkcanfd_timestamp_init(struct rkcanfd_priv *priv)
 {
 	const struct can_bittiming *dbt = &priv->can.fd.data_bittiming;
@@ -73,7 +78,6 @@ void rkcanfd_timestamp_init(struct rkcanfd_priv *priv)
 	max_cycles = min(max_cycles, cc->mask);
 	work_delay_ns = clocksource_cyc2ns(max_cycles, cc->mult, cc->shift);
 	priv->work_delay_jiffies = div_u64(work_delay_ns, 3u * NSEC_PER_SEC / HZ);
-	INIT_DELAYED_WORK(&priv->timestamp, rkcanfd_timestamp_work);
 
 	netdev_dbg(priv->ndev, "clock=%lu.%02luMHz bitrate=%lu.%02luMBit/s div=%u rate=%lu.%02luMHz mult=%u shift=%u delay=%lus\n",
 		   priv->can.clock.freq / MEGA,
diff --git a/drivers/net/can/rockchip/rockchip_canfd-tx.c b/drivers/net/can/rockchip/rockchip_canfd-tx.c
index b367341dd0aeb..7bff961c04adf 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-tx.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-tx.c
@@ -35,22 +35,15 @@ static bool rkcanfd_tx_tail_is_eff(const struct rkcanfd_priv *priv)
 	return cfd->can_id & CAN_EFF_FLAG;
 }
 
-unsigned int rkcanfd_get_effective_tx_free(struct rkcanfd_priv *priv)
+unsigned int rkcanfd_get_effective_tx_free(const struct rkcanfd_priv *priv)
 {
-	unsigned int tx_free;
-	unsigned long flags;
-
-	spin_lock_irqsave(&priv->tx_lock, flags);
+	lockdep_assert_held(&priv->tx_lock);
 
 	if (priv->devtype_data.quirks & RKCANFD_QUIRK_RK3568_ERRATUM_6 &&
 	    rkcanfd_tx_tail_is_eff(priv))
-		tx_free = 0;
-	else
-		tx_free = rkcanfd_get_tx_free(priv);
+		return 0;
 
-	spin_unlock_irqrestore(&priv->tx_lock, flags);
-
-	return tx_free;
+	return rkcanfd_get_tx_free(priv);
 }
 
 static void rkcanfd_start_xmit_write_cmd(const struct rkcanfd_priv *priv,
@@ -89,6 +82,12 @@ netdev_tx_t rkcanfd_start_xmit(struct sk_buff *skb, struct net_device *ndev)
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
@@ -99,22 +98,10 @@ netdev_tx_t rkcanfd_start_xmit(struct sk_buff *skb, struct net_device *ndev)
 				    priv->tx_head, priv->tx_tail,
 				    rkcanfd_get_tx_pending(priv));
 
-		return NETDEV_TX_BUSY;
-	}
-
-	spin_lock_irqsave(&priv->tx_lock, flags);
-	tx_head = rkcanfd_get_tx_head(priv);
-	frame_len = can_skb_get_frame_len(skb);
-	err = can_put_echo_skb(skb, ndev, tx_head, frame_len);
-	if (err) {
-		spin_unlock_irqrestore(&priv->tx_lock, flags);
-
-		ndev->stats.tx_dropped++;
-		return NETDEV_TX_OK;
+		goto out_busy;
 	}
 
-	skb = priv->can.echo_skb[tx_head];
-	cfd = (const struct canfd_frame *)skb->data;
+	cfd = (struct canfd_frame *)skb->data;
 
 	if (cfd->can_id & CAN_EFF_FLAG) {
 		reg_frameinfo = RKCANFD_REG_FD_FRAMEINFO_FRAME_FORMAT;
@@ -140,8 +127,17 @@ netdev_tx_t rkcanfd_start_xmit(struct sk_buff *skb, struct net_device *ndev)
 					    cfd->len);
 	}
 
+	tx_head = rkcanfd_get_tx_head(priv);
 	reg_cmd = RKCANFD_REG_CMD_TX_REQ(tx_head);
 
+	/* Keep the original skb alive until IRQs are restored so echo
+	 * preparation cannot invoke its socket destructor under tx_lock.
+	 */
+	frame_len = can_skb_get_frame_len(skb);
+	err = can_put_echo_skb(skb_get(skb), ndev, tx_head, frame_len);
+	if (unlikely(err || !priv->can.echo_skb[tx_head]))
+		goto out_drop;
+
 	rkcanfd_write(priv, RKCANFD_REG_FD_TXFRAMEINFO, reg_frameinfo);
 	rkcanfd_write(priv, RKCANFD_REG_FD_TXID, reg_id);
 	for (i = 0; i < cfd->len; i += 4)
@@ -153,14 +149,28 @@ netdev_tx_t rkcanfd_start_xmit(struct sk_buff *skb, struct net_device *ndev)
 	WRITE_ONCE(priv->tx_head, priv->tx_head + 1);
 
 	rkcanfd_start_xmit_write_cmd(priv, reg_cmd);
-	spin_unlock_irqrestore(&priv->tx_lock, flags);
 
 	netif_subqueue_maybe_stop(priv->ndev, 0,
 				  rkcanfd_get_effective_tx_free(priv),
 				  RKCANFD_TX_STOP_THRESHOLD,
 				  RKCANFD_TX_START_THRESHOLD);
 
+	spin_unlock_irqrestore(&priv->tx_lock, flags);
+	dev_consume_skb_any(skb);
+
 	return NETDEV_TX_OK;
+
+out_drop:
+	ndev->stats.tx_dropped++;
+	spin_unlock_irqrestore(&priv->tx_lock, flags);
+	dev_kfree_skb_any(skb);
+
+	return NETDEV_TX_OK;
+
+out_busy:
+	spin_unlock_irqrestore(&priv->tx_lock, flags);
+
+	return NETDEV_TX_BUSY;
 }
 
 void rkcanfd_handle_tx_done_one(struct rkcanfd_priv *priv, const u32 ts,
diff --git a/drivers/net/can/rockchip/rockchip_canfd.h b/drivers/net/can/rockchip/rockchip_canfd.h
index 2dc3a41afe32d..3664124a8da25 100644
--- a/drivers/net/can/rockchip/rockchip_canfd.h
+++ b/drivers/net/can/rockchip/rockchip_canfd.h
@@ -475,13 +475,16 @@ struct rkcanfd_priv {
 	struct can_rx_offload offload;
 	struct net_device *ndev;
 
-	spinlock_t tx_lock; /* protects tx_head, tx_tail and echo_skb */
+	/* Serialize TX submission/completion with bus-off and restart. */
+	spinlock_t tx_lock;
 	void __iomem *regs;
 	unsigned int tx_head;
 	unsigned int tx_tail;
 
 	u32 reg_mode_default;
 	u32 reg_int_mask_default;
+	bool tx_enabled;
+	bool irq_suspended;
 	struct rkcanfd_devtype_data devtype_data;
 
 	struct cyclecounter cc;
@@ -553,12 +556,13 @@ int rkcanfd_handle_rx_int(struct rkcanfd_priv *priv);
 
 void rkcanfd_skb_set_timestamp(const struct rkcanfd_priv *priv,
 			       struct sk_buff *skb, const u32 timestamp);
+void rkcanfd_timestamp_work_init(struct rkcanfd_priv *priv);
 void rkcanfd_timestamp_init(struct rkcanfd_priv *priv);
 void rkcanfd_timestamp_start(struct rkcanfd_priv *priv);
 void rkcanfd_timestamp_stop(struct rkcanfd_priv *priv);
 void rkcanfd_timestamp_stop_sync(struct rkcanfd_priv *priv);
 
-unsigned int rkcanfd_get_effective_tx_free(struct rkcanfd_priv *priv);
+unsigned int rkcanfd_get_effective_tx_free(const struct rkcanfd_priv *priv);
 void rkcanfd_xmit_retry(struct rkcanfd_priv *priv);
 netdev_tx_t rkcanfd_start_xmit(struct sk_buff *skb, struct net_device *ndev);
 void rkcanfd_handle_tx_done_one(struct rkcanfd_priv *priv, const u32 ts,

-- 
2.34.1

