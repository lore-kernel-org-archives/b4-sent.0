From: Cunhao Lu <1579567540@qq.com>
Date: Thu, 19 Nov 2026 16:39:44 +0800
Subject: [PATCH net v10 03/10] can: dev: check netif_running() before
 bus-off recovery
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-rockchip-canfd-restart-close-v10-3-df23913aa33a@qq.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795077587; l=6091;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=DnoB8zc7Is7z8ZQl3mTaQJmTJBOXYb3Oll83YYKwpco=;
 b=Q6sI11+/G85CX2GlScT1mPE/VCe4rwglRCRbKwg3SRVIreGD8xrIMIJd/kPbKGFuuM35DNVNR
 GGxUe3Ld746BPm3eI4lWXz5TMp1QpSOHTUIcM3gQp+Og7AT132bfL3f
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The networking core clears __LINK_STATE_START before calling ndo_stop(),
but the CAN core can still schedule or start bus-off recovery after the
interface is down.

Check netif_running() in can_restart() before flushing echo skbs, sending
the restart notification or enabling the carrier. Keep the existing
unsupported-operation check first. In can_bus_off(), schedule recovery
only when the check observes the interface running, and make the log
message reflect that decision. Keep reporting bus-off and disabling the
carrier.

These checks do not wait for recovery that has already passed the check,
nor serialize the check with work submission. Drivers still need to
cancel restart work before tearing down resources and quiesce its
producers before their final cleanup.

Fixes: 39549eef3587 ("can: CAN Network device driver and Netlink interface")
Cc: stable@vger.kernel.org
Signed-off-by: Cunhao Lu <1579567540@qq.com>

---
Changes in v10:
- Limit the recovery documentation to CAN core software recovery and
  checks that observe the interface down; retain driver shutdown
  synchronization requirements.

Changes in v7:
- Clarify the running checks' limits and configure restart-ms while down.

Changes in v6:
- Update the can_bus_off() comment and document the running-interface
  requirement for automatic recovery.

---

Q: Do the running checks serialize recovery with device close?

A: No. A worker can pass the check before close clears the running bit.
FlexCAN cancels restart work after stopping hardware and removing RX
offload, so that worker can restart after shutdown. This race predates
the patch, and the running checks do not widen it. FlexCAN must drain
active restart work before tearing down those resources. That driver fix
is not part of this patch.

Q: Can HI3110 queue restart work after close and outlive the device?

A: Yes. With restart-ms enabled, its IRQ thread can decide to schedule
before close, then enqueue after close_candev() returns. free_irq() drains
the producer but leaves that core work queued. A quick reopen permits
stale recovery and echo cleanup; removal can leave work referring to
freed private data. The driver's private workqueue does not own the core
work. These races predate the patch, and the running checks do not widen
them. HI3110 must stop producers before final cancellation and drain
both core recovery and work queued by its callback before teardown.
That driver fix is not part of this patch.

Q: Why not replace cancellation with disable/enable_delayed_work() here?

A: Disabling work can reject late submissions, but doing it at the end
of ndo_stop() still lets an already running callback overlap teardown.
A core-wide conversion would need to balance disable and enable across
initialization, open, failed open and close. Rockchip instead cancels
restart_work before teardown and again after free_irq(). The restart
races in FlexCAN and HI3110 predate this patch, and the netif_running()
checks do not widen them. Fixes for those drivers are outside this series.

Link: https://netdev-ai.bots.linux.dev/sashiko/#/patchset/20261017-rockchip-canfd-restart-close-v6-0-ed605feb4b6e%40qq.com
Link: https://netdev-ai.bots.linux.dev/sashiko/#/patchset/20261111-rockchip-canfd-restart-close-v9-0-6643f3825ba3%40qq.com
---
 Documentation/networking/can.rst |  9 ++++++++-
 drivers/net/can/dev/dev.c        | 13 ++++++++++---
 2 files changed, 18 insertions(+), 4 deletions(-)

diff --git a/Documentation/networking/can.rst b/Documentation/networking/can.rst
index 51bc70748f753..f44b9c96848de 100644
--- a/Documentation/networking/can.rst
+++ b/Documentation/networking/can.rst
@@ -1376,9 +1376,16 @@ before you can start it to avoid error-prone default settings::
 A device may enter the "bus-off" state if too many errors occurred on
 the CAN bus. Then no more messages are received or sent. An automatic
 bus-off recovery can be enabled by setting the "restart-ms" to a
-non-zero value, e.g.::
+non-zero value while the interface is down, e.g.::
 
+    $ ip link set canX down
     $ ip link set canX type can restart-ms 100
+    $ ip link set canX up
+
+The CAN core checks the interface before queuing a restart and again
+before starting it. If it finds the interface down, it skips that step.
+Drivers must still synchronize recovery with shutdown. Controller-managed
+recovery bypasses these checks.
 
 Alternatively, the application may realize the "bus-off" condition
 by monitoring CAN error message frames and do a restart when
diff --git a/drivers/net/can/dev/dev.c b/drivers/net/can/dev/dev.c
index 769745e22a3c7..a893a49a33813 100644
--- a/drivers/net/can/dev/dev.c
+++ b/drivers/net/can/dev/dev.c
@@ -198,6 +198,9 @@ static int can_restart(struct net_device *dev)
 	if (!priv->do_set_mode)
 		return -EOPNOTSUPP;
 
+	if (!netif_running(dev))
+		return -ENETDOWN;
+
 	if (netif_carrier_ok(dev))
 		netdev_err(dev, "Attempt to restart for bus-off recovery, but carrier is OK?\n");
 
@@ -259,13 +262,17 @@ int can_restart_now(struct net_device *dev)
  *
  * This functions should be called when the device goes bus-off to
  * tell the netif layer that no more packets can be sent or received.
- * If enabled, a timer is started to trigger bus-off recovery.
+ * If automatic recovery is enabled, schedule delayed work unless the
+ * running check observes the interface down. Drivers must still synchronize
+ * recovery with device close.
  */
 void can_bus_off(struct net_device *dev)
 {
 	struct can_priv *priv = netdev_priv(dev);
+	bool restart;
 
-	if (priv->restart_ms)
+	restart = priv->restart_ms && netif_running(dev);
+	if (restart)
 		netdev_info(dev, "bus-off, scheduling restart in %d ms\n",
 			    priv->restart_ms);
 	else
@@ -273,7 +280,7 @@ void can_bus_off(struct net_device *dev)
 
 	netif_carrier_off(dev);
 
-	if (priv->restart_ms)
+	if (restart)
 		schedule_delayed_work(&priv->restart_work,
 				      msecs_to_jiffies(priv->restart_ms));
 }

-- 
2.34.1

