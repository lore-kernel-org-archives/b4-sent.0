From: Cunhao Lu <1579567540@qq.com>
Date: Wed, 11 Nov 2026 14:18:03 +0800
Subject: [PATCH net v9 09/10] can: rockchip_canfd: prevent timestamp work
 from rearming after bus-off
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-rockchip-canfd-restart-close-v9-9-6643f3825ba3@qq.com>
References: <20261111-rockchip-canfd-restart-close-v9-0-6643f3825ba3@qq.com>
In-Reply-To: <20261111-rockchip-canfd-restart-close-v9-0-6643f3825ba3@qq.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794377925; l=4546;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=z5MuF2TQ0+5PNXm0tzVl2YQVcjJOMQeedOJLqUjpuaU=;
 b=kz2cLZ+hQGR2CiStWVQPY1rcMUHrrNA8sQuQbczFVOCK9kNV2moNhZesjmYl6WQc2MN1CHc1j
 WwflmKbSv3DDh5IkKH8fupTQacbmN2B2JXqpfNpBO2+555+jD9jukvx
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The bus-off IRQ cancels timestamp work asynchronously. If the worker
is already running, it can requeue itself after cancellation and keep
polling during bus-off, causing unnecessary wakeups and counter reads.

Use disable_delayed_work() to block requeueing until startup re-enables
the work. Initialize it disabled and enable it after initializing the
timecounter.

Keep the active check and counter read under timestamp_lock so stop
waits for an in-flight read before the controller is reset. Use the
active flag to avoid disabling work twice when restart or close follows
bus-off.

Keep workqueue operations outside timestamp_lock; the IRQ and restart
paths already serialize start and stop. Synchronous stop waits for the
callback before reinitialization or clock shutdown.

Fixes: 4e1a18bab124 ("can: rockchip_canfd: add hardware timestamping support")
Cc: stable@vger.kernel.org
Signed-off-by: Cunhao Lu <1579567540@qq.com>

---
Changes in v9:
- Use disable_delayed_work() to block self-requeueing, with balanced
  enable/disable calls across repeated stops.
- Move worker requeueing and initial scheduling outside timestamp_lock.
---
 .../net/can/rockchip/rockchip_canfd-timestamp.c    | 30 ++++++++++++++++++++--
 drivers/net/can/rockchip/rockchip_canfd.h          |  3 +++
 2 files changed, 31 insertions(+), 2 deletions(-)

diff --git a/drivers/net/can/rockchip/rockchip_canfd-timestamp.c b/drivers/net/can/rockchip/rockchip_canfd-timestamp.c
index ad582afbbd68..7c7b95343aa8 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-timestamp.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-timestamp.c
@@ -30,18 +30,26 @@ static void rkcanfd_timestamp_work(struct work_struct *work)
 {
 	const struct delayed_work *delayed_work = to_delayed_work(work);
 	struct rkcanfd_priv *priv;
+	unsigned long flags;
 
 	priv = container_of(delayed_work, struct rkcanfd_priv, timestamp);
-	timecounter_read(&priv->tc);
+	spin_lock_irqsave(&priv->timestamp_lock, flags);
+	if (priv->timestamp_active)
+		timecounter_read(&priv->tc);
+	spin_unlock_irqrestore(&priv->timestamp_lock, flags);
 
 	schedule_delayed_work(&priv->timestamp, priv->work_delay_jiffies);
 }
 
 void rkcanfd_timestamp_work_init(struct rkcanfd_priv *priv)
 {
+	spin_lock_init(&priv->timestamp_lock);
+	priv->timestamp_active = false;
 	INIT_DELAYED_WORK(&priv->timestamp, rkcanfd_timestamp_work);
+	disable_delayed_work(&priv->timestamp);
 }
 
+/* The caller must quiesce IRQs and timestamp work before reconfiguration. */
 void rkcanfd_timestamp_init(struct rkcanfd_priv *priv)
 {
 	const struct can_bittiming *dbt = &priv->can.fd.data_bittiming;
@@ -93,17 +101,35 @@ void rkcanfd_timestamp_init(struct rkcanfd_priv *priv)
 
 void rkcanfd_timestamp_start(struct rkcanfd_priv *priv)
 {
+	unsigned long flags;
+
+	spin_lock_irqsave(&priv->timestamp_lock, flags);
 	timecounter_init(&priv->tc, &priv->cc, ktime_get_real_ns());
+	priv->timestamp_active = true;
+	spin_unlock_irqrestore(&priv->timestamp_lock, flags);
 
+	enable_delayed_work(&priv->timestamp);
 	schedule_delayed_work(&priv->timestamp, priv->work_delay_jiffies);
 }
 
 void rkcanfd_timestamp_stop(struct rkcanfd_priv *priv)
 {
-	cancel_delayed_work(&priv->timestamp);
+	unsigned long flags;
+
+	/* Stop counter reads before the caller resets the controller. */
+	spin_lock_irqsave(&priv->timestamp_lock, flags);
+	if (!priv->timestamp_active) {
+		spin_unlock_irqrestore(&priv->timestamp_lock, flags);
+		return;
+	}
+	priv->timestamp_active = false;
+	spin_unlock_irqrestore(&priv->timestamp_lock, flags);
+
+	disable_delayed_work(&priv->timestamp);
 }
 
 void rkcanfd_timestamp_stop_sync(struct rkcanfd_priv *priv)
 {
+	rkcanfd_timestamp_stop(priv);
 	cancel_delayed_work_sync(&priv->timestamp);
 }
diff --git a/drivers/net/can/rockchip/rockchip_canfd.h b/drivers/net/can/rockchip/rockchip_canfd.h
index 8fdb59025bfa..3ce996f52e45 100644
--- a/drivers/net/can/rockchip/rockchip_canfd.h
+++ b/drivers/net/can/rockchip/rockchip_canfd.h
@@ -477,6 +477,8 @@ struct rkcanfd_priv {
 
 	/* Serialize TX submission/completion with bus-off and restart. */
 	spinlock_t tx_lock;
+	/* Serialize timestamp work with start/stop. */
+	spinlock_t timestamp_lock;
 	void __iomem *regs;
 	unsigned int tx_head;
 	unsigned int tx_tail;
@@ -487,6 +489,7 @@ struct rkcanfd_priv {
 
 	bool tx_enabled;
 	bool irq_suspended;
+	bool timestamp_active;
 
 	struct cyclecounter cc;
 	struct timecounter tc;

-- 
2.34.1

