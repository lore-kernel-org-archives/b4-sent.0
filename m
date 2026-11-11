From: Cunhao Lu <1579567540@qq.com>
Date: Wed, 11 Nov 2026 14:18:00 +0800
Subject: [PATCH net v9 06/10] can: rockchip_canfd: cancel bus-off restart
 before closing the device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-rockchip-canfd-restart-close-v9-6-6643f3825ba3@qq.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794377925; l=1424;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=FqCrBu6JrjmPJcQNJBNICwgHwS2YwinHx4qtGS13N34=;
 b=NLBEFk8Dzy95cokydtlZ19Ep8PEioLeT3ycyxJpuYcp+8tPLjfp6JuZxhKe1RAB3uYJSrsfFH
 fZxio7G7OohAfN062PEnpiYXsq6OClIiba0x1erH5w1rmUcLB2Z3QL7
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The close path cancels restart_work in close_candev() only after freeing
the IRQ, disabling RX offload and stopping the controller. A concurrent
restart can re-enable the controller and interrupts after IRQ teardown,
or requeue timestamp work that accesses registers after runtime suspend
has disabled the controller clocks.

Call close_candev_cancel_restart_sync() at the start of ndo_stop(), while
the resources needed by a running restart are still available. Keep
close_candev() after IRQ teardown for final cancellation and echo cleanup.

Fixes: ff60bfbaf67f ("can: rockchip_canfd: add driver for Rockchip CAN-FD controller")
Cc: stable@vger.kernel.org
Signed-off-by: Cunhao Lu <1579567540@qq.com>

---
Changes in v7:
- Keep close cancellation separate from restart and open error handling.
---
 drivers/net/can/rockchip/rockchip_canfd-core.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/can/rockchip/rockchip_canfd-core.c b/drivers/net/can/rockchip/rockchip_canfd-core.c
index 1cae86973da5..59a79fe057e6 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-core.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-core.c
@@ -758,6 +758,7 @@ static int rkcanfd_stop(struct net_device *ndev)
 {
 	struct rkcanfd_priv *priv = netdev_priv(ndev);
 
+	close_candev_cancel_restart_sync(ndev);
 	netif_stop_queue(ndev);
 
 	rkcanfd_chip_interrupts_disable(priv);

-- 
2.34.1

