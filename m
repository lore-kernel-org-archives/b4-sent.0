From: Cunhao Lu <1579567540@qq.com>
Date: Sun, 08 Nov 2026 19:33:35 +0800
Subject: [PATCH net v8 08/10] can: rockchip_canfd: serialize TX with
 bus-off and restart
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-rockchip-canfd-restart-close-v8-8-3e7a23fd9eae@qq.com>
References: <20261108-rockchip-canfd-restart-close-v8-0-3e7a23fd9eae@qq.com>
In-Reply-To: <20261108-rockchip-canfd-restart-close-v8-0-3e7a23fd9eae@qq.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, kernel@pengutronix.de, 
 Vincent Mailhol <mailhol@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Oliver Hartkopp <socketcan@hartkopp.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Wolfgang Grandegger <wg@grandegger.com>
Cc: Cunhao Lu <1579567540@qq.com>, linux-can@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794137678; l=11324;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=hAuSAw5/dFohWVygYp1eacUIJNThuZakLHSTnH34wzc=;
 b=oX3pUjEeQ094RDo9JACQTtCw+9EyWbEtXjpzHwVqJCQrvAx4RwmcwXFstxk+vzPH3Qc+PWAK7
 MTYW4D/O+PsBtSoktIk6UkZGH4CpR24RywRnt0NUdfDh8zBRh2GoLLv
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

Fixes: ff60bfbaf67f ("can: rockchip_canfd: add driver for Rockchip CAN-FD controller")
Fixes: b6661d73290c ("can: rockchip_canfd: add TX PATH")
Cc: stable@vger.kernel.org
Signed-off-by: Cunhao Lu <1579567540@qq.com>

---
Changes in v8:
- Move skb ownership handling and running TX/RX critical sections to
  the preceding TX patches.

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
 drivers/net/can/rockchip/rockchip_canfd-core.c     | 63 +++++++++++++++++++---
 drivers/net/can/rockchip/rockchip_canfd-rx.c       | 10 +++-
 .../net/can/rockchip/rockchip_canfd-timestamp.c    |  6 ++-
 drivers/net/can/rockchip/rockchip_canfd-tx.c       |  4 ++
 drivers/net/can/rockchip/rockchip_canfd.h          |  5 +-
 5 files changed, 79 insertions(+), 9 deletions(-)

diff --git a/drivers/net/can/rockchip/rockchip_canfd-core.c b/drivers/net/can/rockchip/rockchip_canfd-core.c
index d05264605efc2..536d9bc812afe 100644
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
@@ -356,9 +386,17 @@ static int rkcanfd_set_mode(struct net_device *ndev,
 
 	switch (mode) {
 	case CAN_MODE_START:
+		rkcanfd_tx_disable(priv);
+		rkcanfd_chip_interrupts_disable(priv);
+		/* Flush the interrupt mask write before suspending the handler. */
+		rkcanfd_read(priv, RKCANFD_REG_INT_MASK);
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
@@ -592,6 +630,12 @@ static int rkcanfd_handle_state_error_int(struct rkcanfd_priv *priv)
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
@@ -666,6 +710,10 @@ static irqreturn_t rkcanfd_irq(int irq, void *dev_id)
 	struct rkcanfd_priv *priv = dev_id;
 	u32 reg_int_unmasked, reg_int;
 
+	/* Pairs with smp_store_release() in rkcanfd_chip_start_finish(). */
+	if (smp_load_acquire(&priv->irq_suspended))
+		return IRQ_NONE;
+
 	reg_int_unmasked = rkcanfd_read(priv, RKCANFD_REG_INT);
 	reg_int = reg_int_unmasked & ~priv->reg_int_mask_default;
 
@@ -733,6 +781,8 @@ static int rkcanfd_open(struct net_device *ndev)
 	if (err)
 		goto out_close_candev;
 
+	/* The shared IRQ handler may run before request_irq() returns. */
+	WRITE_ONCE(priv->irq_suspended, true);
 	rkcanfd_chip_start(priv);
 	can_rx_offload_enable(&priv->offload);
 
@@ -740,13 +790,12 @@ static int rkcanfd_open(struct net_device *ndev)
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
@@ -760,7 +809,7 @@ static int rkcanfd_stop(struct net_device *ndev)
 	struct rkcanfd_priv *priv = netdev_priv(ndev);
 
 	close_candev_cancel_restart_sync(ndev);
-	netif_stop_queue(ndev);
+	rkcanfd_tx_disable(priv);
 
 	rkcanfd_chip_interrupts_disable(priv);
 	free_irq(ndev->irq, priv);
@@ -937,6 +986,8 @@ static int rkcanfd_probe(struct platform_device *pdev)
 	if (err)
 		goto out_free_candev;
 
+	rkcanfd_timestamp_work_init(priv);
+
 	err = rkcanfd_register(priv);
 	if (err)
 		goto out_can_rx_offload_del;
diff --git a/drivers/net/can/rockchip/rockchip_canfd-rx.c b/drivers/net/can/rockchip/rockchip_canfd-rx.c
index 23476a334d6c3..fb98dd0da4913 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-rx.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-rx.c
@@ -91,7 +91,7 @@ rkcanfd_fifo_header_to_cfd_header(const struct rkcanfd_priv *priv,
 	return len + cfd->len;
 }
 
-/* Called with tx_lock held. */
+/* Called with tx_lock held and TX enabled. */
 static int rkcanfd_rxstx_filter(struct rkcanfd_priv *priv,
 				const struct canfd_frame *cfd_rx, const u32 ts,
 				bool *tx_done)
@@ -242,7 +242,15 @@ static int rkcanfd_handle_rx_int_one(struct rkcanfd_priv *priv)
 		return 0;
 	}
 
+	/* Drop consumed FIFO entries while TX is disabled to avoid delivering
+	 * self-received frames as ordinary RX without echo filtering.
+	 */
 	spin_lock_irqsave(&priv->tx_lock, flags);
+	if (unlikely(!priv->tx_enabled)) {
+		spin_unlock_irqrestore(&priv->tx_lock, flags);
+		return 0;
+	}
+
 	err = 0;
 	if (rkcanfd_get_tx_pending(priv))
 		err = rkcanfd_rxstx_filter(priv, cfd, header->ts, &tx_done);
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
index 8998b7855d15d..6f60d4119812f 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-tx.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-tx.c
@@ -85,6 +85,10 @@ netdev_tx_t rkcanfd_start_xmit(struct sk_buff *skb, struct net_device *ndev)
 		return NETDEV_TX_OK;
 
 	spin_lock_irqsave(&priv->tx_lock, flags);
+	if (unlikely(!priv->tx_enabled)) {
+		netif_stop_queue(ndev);
+		goto out_busy;
+	}
 
 	if (!netif_subqueue_maybe_stop(priv->ndev, 0,
 				       rkcanfd_get_effective_tx_free(priv),
diff --git a/drivers/net/can/rockchip/rockchip_canfd.h b/drivers/net/can/rockchip/rockchip_canfd.h
index 077dd57d42de9..3664124a8da25 100644
--- a/drivers/net/can/rockchip/rockchip_canfd.h
+++ b/drivers/net/can/rockchip/rockchip_canfd.h
@@ -475,7 +475,7 @@ struct rkcanfd_priv {
 	struct can_rx_offload offload;
 	struct net_device *ndev;
 
-	/* Protect running TX/RX echo state, queue updates and TX commands. */
+	/* Serialize TX submission/completion with bus-off and restart. */
 	spinlock_t tx_lock;
 	void __iomem *regs;
 	unsigned int tx_head;
@@ -483,6 +483,8 @@ struct rkcanfd_priv {
 
 	u32 reg_mode_default;
 	u32 reg_int_mask_default;
+	bool tx_enabled;
+	bool irq_suspended;
 	struct rkcanfd_devtype_data devtype_data;
 
 	struct cyclecounter cc;
@@ -554,6 +556,7 @@ int rkcanfd_handle_rx_int(struct rkcanfd_priv *priv);
 
 void rkcanfd_skb_set_timestamp(const struct rkcanfd_priv *priv,
 			       struct sk_buff *skb, const u32 timestamp);
+void rkcanfd_timestamp_work_init(struct rkcanfd_priv *priv);
 void rkcanfd_timestamp_init(struct rkcanfd_priv *priv);
 void rkcanfd_timestamp_start(struct rkcanfd_priv *priv);
 void rkcanfd_timestamp_stop(struct rkcanfd_priv *priv);

-- 
2.34.1

