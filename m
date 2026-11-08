From: Cunhao Lu <1579567540@qq.com>
Date: Sun, 08 Nov 2026 19:33:36 +0800
Subject: [PATCH net v8 09/10] can: rockchip_canfd: prevent timestamp work
 from rearming after bus-off
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-rockchip-canfd-restart-close-v8-9-3e7a23fd9eae@qq.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794137678; l=4333;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=SOO163gzYNYZNP6n4OTUiW0fL5Doo8hMgGkDjKR3yOc=;
 b=WztUDbOQL5HOouUAirhh/+HMX/+mQpa1lDUnioP8ldrNJgA3jE6q3OLWG9kYf2wjxf44UzU1v
 6E3Sl7cl9GBCD7PO9AWZsTYOTCndh/8XR8UhOiMf2B01BMBIn5iGjaT
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The bus-off IRQ cancels timestamp work asynchronously. If the worker
is already running, it can requeue itself after cancellation and keep
polling while the controller remains bus-off.

Add a dedicated lock and an active flag, initialized once at probe.
Serialize the worker's active check, counter read and self-requeue with
start and stop. Clear the flag under the lock before cancelling work
so no worker can read the counter or rearm after deactivation. Enable
the flag and schedule the initial work under the same lock at start.

Keep both cancellation calls outside the lock so synchronous stop can
wait for the worker to finish.

Fixes: 4e1a18bab124 ("can: rockchip_canfd: add hardware timestamping support")
Cc: stable@vger.kernel.org
Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 .../net/can/rockchip/rockchip_canfd-timestamp.c    | 34 +++++++++++++++++++---
 drivers/net/can/rockchip/rockchip_canfd.h          |  3 ++
 2 files changed, 33 insertions(+), 4 deletions(-)

diff --git a/drivers/net/can/rockchip/rockchip_canfd-timestamp.c b/drivers/net/can/rockchip/rockchip_canfd-timestamp.c
index ad582afbbd68..1d2a122770dc 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-timestamp.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-timestamp.c
@@ -30,18 +30,27 @@ static void rkcanfd_timestamp_work(struct work_struct *work)
 {
 	const struct delayed_work *delayed_work = to_delayed_work(work);
 	struct rkcanfd_priv *priv;
+	unsigned long flags;
 
 	priv = container_of(delayed_work, struct rkcanfd_priv, timestamp);
-	timecounter_read(&priv->tc);
-
-	schedule_delayed_work(&priv->timestamp, priv->work_delay_jiffies);
+	spin_lock_irqsave(&priv->timestamp_lock, flags);
+	if (priv->timestamp_active) {
+		timecounter_read(&priv->tc);
+
+		/* Serialize requeueing with timestamp deactivation. */
+		schedule_delayed_work(&priv->timestamp, priv->work_delay_jiffies);
+	}
+	spin_unlock_irqrestore(&priv->timestamp_lock, flags);
 }
 
 void rkcanfd_timestamp_work_init(struct rkcanfd_priv *priv)
 {
+	spin_lock_init(&priv->timestamp_lock);
+	priv->timestamp_active = false;
 	INIT_DELAYED_WORK(&priv->timestamp, rkcanfd_timestamp_work);
 }
 
+/* The caller must quiesce IRQs and timestamp work before reconfiguration. */
 void rkcanfd_timestamp_init(struct rkcanfd_priv *priv)
 {
 	const struct can_bittiming *dbt = &priv->can.fd.data_bittiming;
@@ -93,17 +102,34 @@ void rkcanfd_timestamp_init(struct rkcanfd_priv *priv)
 
 void rkcanfd_timestamp_start(struct rkcanfd_priv *priv)
 {
-	timecounter_init(&priv->tc, &priv->cc, ktime_get_real_ns());
+	unsigned long flags;
 
+	spin_lock_irqsave(&priv->timestamp_lock, flags);
+	timecounter_init(&priv->tc, &priv->cc, ktime_get_real_ns());
+	priv->timestamp_active = true;
 	schedule_delayed_work(&priv->timestamp, priv->work_delay_jiffies);
+	spin_unlock_irqrestore(&priv->timestamp_lock, flags);
 }
 
 void rkcanfd_timestamp_stop(struct rkcanfd_priv *priv)
 {
+	unsigned long flags;
+
+	spin_lock_irqsave(&priv->timestamp_lock, flags);
+	priv->timestamp_active = false;
+	spin_unlock_irqrestore(&priv->timestamp_lock, flags);
+
 	cancel_delayed_work(&priv->timestamp);
 }
 
 void rkcanfd_timestamp_stop_sync(struct rkcanfd_priv *priv)
 {
+	unsigned long flags;
+
+	spin_lock_irqsave(&priv->timestamp_lock, flags);
+	priv->timestamp_active = false;
+	spin_unlock_irqrestore(&priv->timestamp_lock, flags);
+
+	/* The worker needs timestamp_lock to finish. */
 	cancel_delayed_work_sync(&priv->timestamp);
 }
diff --git a/drivers/net/can/rockchip/rockchip_canfd.h b/drivers/net/can/rockchip/rockchip_canfd.h
index 3664124a8da2..078876769a05 100644
--- a/drivers/net/can/rockchip/rockchip_canfd.h
+++ b/drivers/net/can/rockchip/rockchip_canfd.h
@@ -477,6 +477,8 @@ struct rkcanfd_priv {
 
 	/* Serialize TX submission/completion with bus-off and restart. */
 	spinlock_t tx_lock;
+	/* Protects timestamp_active and worker reads/requeueing. */
+	spinlock_t timestamp_lock;
 	void __iomem *regs;
 	unsigned int tx_head;
 	unsigned int tx_tail;
@@ -485,6 +487,7 @@ struct rkcanfd_priv {
 	u32 reg_int_mask_default;
 	bool tx_enabled;
 	bool irq_suspended;
+	bool timestamp_active;
 	struct rkcanfd_devtype_data devtype_data;
 
 	struct cyclecounter cc;

-- 
2.34.1

