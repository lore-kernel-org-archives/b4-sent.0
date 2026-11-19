From: Cunhao Lu <1579567540@qq.com>
Date: Thu, 19 Nov 2026 16:39:49 +0800
Subject: [PATCH net v10 08/10] can: rockchip_canfd: retry the outstanding
 TX buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-rockchip-canfd-restart-close-v10-8-df23913aa33a@qq.com>
References: <20261119-rockchip-canfd-restart-close-v10-0-df23913aa33a@qq.com>
In-Reply-To: <20261119-rockchip-canfd-restart-close-v10-0-df23913aa33a@qq.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, kernel@pengutronix.de, 
 Vincent Mailhol <mailhol@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Oliver Hartkopp <socketcan@hartkopp.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Wolfgang Grandegger <wg@grandegger.com>
Cc: linux-can@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, Cunhao Lu <1579567540@qq.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795077587; l=9789;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=kBKb8AmgJ6pzOGhAXdb9opycixy8N3evuqoCl84o4lQ=;
 b=zz5c2loXtLfCkdXEablUzfT0ucsZLa4P3XwhbTrxM6/kbLnFsIQfyN4e3JJYQP6hi3whgo8zz
 F8NLbln+BtCCV6SzDCnrhLuH/cZ6U3WClcyvtXXhEDEy9UnSfIsaU8d
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rkcanfd_xmit_retry() uses tx_head to select the buffer for an erratum 6
retransmission. With two buffers and one outstanding frame, this selects
the next submission slot instead of the slot holding that frame.

A standard frame from another node can match the erratum 6 check while
the original extended frame is still pending: its ID matches the low
11 ID bits, and both have the same RTR flag and length. Data frames must
also have matching payloads. The retry loads the extended frame from the
shared TX registers into the other buffer. In RK3588 tests, the peer
received the current extended frame twice and local sockets received the
extra copy as ordinary RX. When a queued successor reused the buffer
while the retry was active, it was lost, leaving its echo and BQL
accounting pending and the TX queue stopped.

Use tx_tail to retry the original slot. The original request may have
completed by the time the driver processes the matching standard frame,
with its echo still in the RX FIFO. Processing that echo can wake the
queue while the retry is active, allowing a successor to overwrite the
shared TX registers.

Stop the queue and mark the retry pending under tx_lock before issuing
it. Complete the original echo and BQL accounting normally, but return
NETDEV_TX_BUSY for new submissions without consuming their skbs. A worker
polls both TX request bits with a one-jiffy delay, so progress does not
depend on another RX interrupt. Once both bits clear, it releases the
guard and wakes the queue if space is available. Repeated matches do not
postpone a pending check, but worker scheduling can delay the next TX.

Disable retries before publishing BUS_OFF and at close entry so the
retry worker cannot read TX request bits, requeue itself or wake the
queue. Close frees the IRQ before draining the worker. Restart waits
for in-flight IRQ handlers, then drains the worker before resetting the
controller. Both paths wait for the worker outside tx_lock.

On RK3588 with PREEMPT_RT, a higher-priority userspace task delayed the
CAN IRQ thread. The peer had already received the original extended frame
when the driver processed the matching standard frame. With only the
tx_tail change, the peer received a frame with the original CAN ID and
a payload containing bytes from a queued successor. The TX queue stalled.
With new submissions blocked until both TX request bits cleared, the peer
received all queued successors and no mixed frames in the same test.

The guard prevents later submissions from overwriting the shared TX
registers during a retry, but the driver can still filter out a matching
standard frame from another node and send a second complete copy of the
original extended frame.

Fixes: a5605d61c7dd ("can: rockchip_canfd: enable full TX-FIFO depth of 2")
Cc: stable@vger.kernel.org
Signed-off-by: Cunhao Lu <1579567540@qq.com>

---
Changes in v10:
- Block new submissions until both TX request bits clear after a retry.
- Move this patch after the TX/IRQ lifecycle synchronization.

Changes in v8:
- Apply the retry-slot correction after TX serialization.
---
 drivers/net/can/rockchip/rockchip_canfd-core.c | 10 ++++
 drivers/net/can/rockchip/rockchip_canfd-tx.c   | 77 +++++++++++++++++++++++++-
 drivers/net/can/rockchip/rockchip_canfd.h      |  7 +++
 3 files changed, 92 insertions(+), 2 deletions(-)

diff --git a/drivers/net/can/rockchip/rockchip_canfd-core.c b/drivers/net/can/rockchip/rockchip_canfd-core.c
index a5c6331191d1..38ffd06768a3 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-core.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-core.c
@@ -270,6 +270,8 @@ static void rkcanfd_chip_start(struct rkcanfd_priv *priv)
 {
 	u32 reg;
 
+	rkcanfd_tx_retry_stop_sync(priv);
+
 	rkcanfd_chip_set_reset_mode(priv);
 
 	/* Receiving Filter: accept all */
@@ -329,12 +331,15 @@ static void rkcanfd_chip_start(struct rkcanfd_priv *priv)
 
 	netdev_dbg(priv->ndev, "%s: reg_mode=0x%08x\n", __func__,
 		   rkcanfd_read(priv, RKCANFD_REG_MODE));
+	rkcanfd_tx_retry_start(priv);
 }
 
 static void rkcanfd_tx_disable(struct rkcanfd_priv *priv)
 {
 	unsigned long flags;
 
+	rkcanfd_tx_retry_stop(priv);
+
 	spin_lock_irqsave(&priv->tx_lock, flags);
 	priv->tx_enabled = false;
 	netif_stop_queue(priv->ndev);
@@ -377,6 +382,8 @@ static void rkcanfd_chip_stop(struct rkcanfd_priv *priv, const enum can_state st
 
 static void rkcanfd_chip_stop_sync(struct rkcanfd_priv *priv, const enum can_state state)
 {
+	rkcanfd_tx_retry_stop_sync(priv);
+
 	priv->can.state = state;
 
 	rkcanfd_timestamp_stop_sync(priv);
@@ -811,6 +818,8 @@ static int rkcanfd_stop(struct net_device *ndev)
 {
 	struct rkcanfd_priv *priv = netdev_priv(ndev);
 
+	rkcanfd_tx_retry_stop(priv);
+
 	close_candev_cancel_restart_sync(ndev);
 	rkcanfd_tx_disable(priv);
 
@@ -976,6 +985,7 @@ static int rkcanfd_probe(struct platform_device *pdev)
 	priv->can.do_get_berr_counter = rkcanfd_get_berr_counter;
 	priv->ndev = ndev;
 	spin_lock_init(&priv->tx_lock);
+	rkcanfd_tx_retry_init(priv);
 
 	match = device_get_match_data(&pdev->dev);
 	if (match) {
diff --git a/drivers/net/can/rockchip/rockchip_canfd-tx.c b/drivers/net/can/rockchip/rockchip_canfd-tx.c
index 7e3f478422e0..745029c23645 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-tx.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-tx.c
@@ -39,6 +39,10 @@ unsigned int rkcanfd_get_effective_tx_free(const struct rkcanfd_priv *priv)
 {
 	lockdep_assert_held(&priv->tx_lock);
 
+	/* The original echo can precede completion of a retry. */
+	if (!priv->tx_retry_enabled || priv->tx_retry_pending)
+		return 0;
+
 	if (priv->devtype_data.quirks & RKCANFD_QUIRK_RK3568_ERRATUM_6 &&
 	    rkcanfd_tx_tail_is_eff(priv))
 		return 0;
@@ -46,6 +50,68 @@ unsigned int rkcanfd_get_effective_tx_free(const struct rkcanfd_priv *priv)
 	return rkcanfd_get_tx_free(priv);
 }
 
+static void rkcanfd_tx_retry_work(struct work_struct *work)
+{
+	struct rkcanfd_priv *priv = container_of(to_delayed_work(work),
+						 struct rkcanfd_priv, tx_retry_work);
+	const u32 tx_req = RKCANFD_REG_CMD_TX0_REQ | RKCANFD_REG_CMD_TX1_REQ;
+	unsigned long flags;
+	u32 reg_cmd;
+
+	spin_lock_irqsave(&priv->tx_lock, flags);
+	if (!priv->tx_retry_enabled || !priv->tx_retry_pending)
+		goto out_unlock;
+
+	reg_cmd = rkcanfd_read(priv, RKCANFD_REG_CMD);
+
+	if (reg_cmd & tx_req) {
+		schedule_delayed_work(&priv->tx_retry_work, 1);
+		goto out_unlock;
+	}
+
+	priv->tx_retry_pending = false;
+
+	if (rkcanfd_get_effective_tx_free(priv) >= RKCANFD_TX_START_THRESHOLD)
+		netif_wake_queue(priv->ndev);
+
+out_unlock:
+	spin_unlock_irqrestore(&priv->tx_lock, flags);
+}
+
+void rkcanfd_tx_retry_init(struct rkcanfd_priv *priv)
+{
+	INIT_DELAYED_WORK(&priv->tx_retry_work, rkcanfd_tx_retry_work);
+}
+
+void rkcanfd_tx_retry_start(struct rkcanfd_priv *priv)
+{
+	unsigned long flags;
+
+	spin_lock_irqsave(&priv->tx_lock, flags);
+	priv->tx_retry_enabled = netif_running(priv->ndev);
+	priv->tx_retry_pending = false;
+	spin_unlock_irqrestore(&priv->tx_lock, flags);
+}
+
+void rkcanfd_tx_retry_stop(struct rkcanfd_priv *priv)
+{
+	unsigned long flags;
+
+	spin_lock_irqsave(&priv->tx_lock, flags);
+	priv->tx_retry_enabled = false;
+	priv->tx_retry_pending = false;
+	netif_stop_queue(priv->ndev);
+	spin_unlock_irqrestore(&priv->tx_lock, flags);
+
+	cancel_delayed_work(&priv->tx_retry_work);
+}
+
+void rkcanfd_tx_retry_stop_sync(struct rkcanfd_priv *priv)
+{
+	rkcanfd_tx_retry_stop(priv);
+	cancel_delayed_work_sync(&priv->tx_retry_work);
+}
+
 static void rkcanfd_start_xmit_write_cmd(const struct rkcanfd_priv *priv,
 					 const u32 reg_cmd)
 {
@@ -63,12 +129,19 @@ static void rkcanfd_start_xmit_write_cmd(const struct rkcanfd_priv *priv,
 
 void rkcanfd_xmit_retry(struct rkcanfd_priv *priv)
 {
-	const unsigned int tx_head = rkcanfd_get_tx_head(priv);
-	const u32 reg_cmd = RKCANFD_REG_CMD_TX_REQ(tx_head);
+	const unsigned int tx_tail = rkcanfd_get_tx_tail(priv);
+	const u32 reg_cmd = RKCANFD_REG_CMD_TX_REQ(tx_tail);
 
 	lockdep_assert_held(&priv->tx_lock);
 
+	if (!priv->tx_retry_enabled)
+		return;
+
+	priv->tx_retry_pending = true;
+	netif_stop_queue(priv->ndev);
+
 	rkcanfd_start_xmit_write_cmd(priv, reg_cmd);
+	schedule_delayed_work(&priv->tx_retry_work, 1);
 }
 
 netdev_tx_t rkcanfd_start_xmit(struct sk_buff *skb, struct net_device *ndev)
diff --git a/drivers/net/can/rockchip/rockchip_canfd.h b/drivers/net/can/rockchip/rockchip_canfd.h
index 8fdb59025bfa..07fc5bc605df 100644
--- a/drivers/net/can/rockchip/rockchip_canfd.h
+++ b/drivers/net/can/rockchip/rockchip_canfd.h
@@ -487,10 +487,13 @@ struct rkcanfd_priv {
 
 	bool tx_enabled;
 	bool irq_suspended;
+	bool tx_retry_enabled;
+	bool tx_retry_pending;
 
 	struct cyclecounter cc;
 	struct timecounter tc;
 	struct delayed_work timestamp;
+	struct delayed_work tx_retry_work;
 	unsigned long work_delay_jiffies;
 
 	struct can_berr_counter bec;
@@ -564,6 +567,10 @@ void rkcanfd_timestamp_stop(struct rkcanfd_priv *priv);
 void rkcanfd_timestamp_stop_sync(struct rkcanfd_priv *priv);
 
 unsigned int rkcanfd_get_effective_tx_free(const struct rkcanfd_priv *priv);
+void rkcanfd_tx_retry_init(struct rkcanfd_priv *priv);
+void rkcanfd_tx_retry_start(struct rkcanfd_priv *priv);
+void rkcanfd_tx_retry_stop(struct rkcanfd_priv *priv);
+void rkcanfd_tx_retry_stop_sync(struct rkcanfd_priv *priv);
 void rkcanfd_xmit_retry(struct rkcanfd_priv *priv);
 netdev_tx_t rkcanfd_start_xmit(struct sk_buff *skb, struct net_device *ndev);
 void rkcanfd_handle_tx_done_one(struct rkcanfd_priv *priv, const u32 ts,

-- 
2.34.1

