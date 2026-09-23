From: Vincent Jardin <vjardin@free.fr>
Date: Wed, 23 Sep 2026 14:58:00 +0200
Subject: [PATCH net-next 1/2] dpaa2-eth: use the DPMAC id as the devlink
 physical port number
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-for-upstream-dpaa2_ports-v1-1-b59c865edd00@free.fr>
References: <20260923-for-upstream-dpaa2_ports-v1-0-b59c865edd00@free.fr>
In-Reply-To: <20260923-for-upstream-dpaa2_ports-v1-0-b59c865edd00@free.fr>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Ioana Ciornei <ioana.ciornei@nxp.com>, 
 Vladimir Oltean <vladimir.oltean@nxp.com>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790168287; l=3549;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=a1ht/l9OL+rj8Gq43hwQ4nW5aEEFb+o71Xs4l+T2FOs=;
 b=8OhXCDAp6R2G0XGHyhvYVK3SdGztAT30jbcfdz6GGQD5pRR/FHNQeuXUNoYh75QQy4K7+aMNR
 UXLfZV1sDsOBL6F3bBL2hJPU64c4S/Ynpra6q9/BR50jeB9Npkljsa0
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dpaa2-eth registers every DPNI as a devlink port of flavour physical
without setting a port number. All DPAA2 interfaces therefore report
the same phys_port_name, p0 (see devlink port show).

The DPNI endpoint can change at runtime while the attributes of a
registered devlink port cannot, so log a warning when it happens.

Another benefit: udev rules can match ATTR{phys_port_name} to name an
interface based on its DPMAC.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 .../ethernet/freescale/dpaa2/dpaa2-eth-devlink.c   | 26 ++++++++++++++++++++++
 drivers/net/ethernet/freescale/dpaa2/dpaa2-eth.c   |  2 ++
 drivers/net/ethernet/freescale/dpaa2/dpaa2-eth.h   |  1 +
 3 files changed, 29 insertions(+)

diff --git a/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c b/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c
index 8775c931106b..8b2addd3f83a 100644
--- a/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c
+++ b/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c
@@ -213,16 +213,42 @@ void dpaa2_eth_dl_unregister(struct dpaa2_eth_priv *priv)
 	devlink_unregister(priv->devlink);
 }
 
+static u32 dpaa2_eth_dl_port_number(struct dpaa2_eth_priv *priv)
+{
+	u32 port_number = 0;
+
+	mutex_lock(&priv->mac_lock);
+	if (priv->mac)
+		port_number = priv->mac->mc_dev->obj_desc.id;
+	mutex_unlock(&priv->mac_lock);
+
+	return port_number;
+}
+
 int dpaa2_eth_dl_port_add(struct dpaa2_eth_priv *priv)
 {
 	struct devlink_port *devlink_port = &priv->devlink_port;
 	struct devlink_port_attrs attrs = {};
 
 	attrs.flavour = DEVLINK_PORT_FLAVOUR_PHYSICAL;
+	attrs.phys.port_number = dpaa2_eth_dl_port_number(priv);
 	devlink_port_attrs_set(devlink_port, &attrs);
 	return devlink_port_register(priv->devlink, devlink_port, 0);
 }
 
+void dpaa2_eth_dl_port_check(struct dpaa2_eth_priv *priv)
+{
+	u32 registered = priv->devlink_port.attrs.phys.port_number;
+	u32 current_number = dpaa2_eth_dl_port_number(priv);
+
+	if (registered == current_number)
+		return;
+
+	netdev_warn(priv->net_dev,
+		    "devlink port number %u is stale, the DPMAC endpoint is now %u (0: none); rebind the DPNI to update it\n",
+		    registered, current_number);
+}
+
 void dpaa2_eth_dl_port_del(struct dpaa2_eth_priv *priv)
 {
 	struct devlink_port *devlink_port = &priv->devlink_port;
diff --git a/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth.c b/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth.c
index 6f1046c9cc51..def2d5c0e7f7 100644
--- a/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth.c
+++ b/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth.c
@@ -4771,6 +4771,8 @@ static irqreturn_t dpni_irq0_handler_thread(int irq_num, void *arg)
 			dpaa2_eth_disconnect_mac(priv);
 		else
 			dpaa2_eth_connect_mac(priv);
+
+		dpaa2_eth_dl_port_check(priv);
 	}
 
 	return IRQ_HANDLED;
diff --git a/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth.h b/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth.h
index 834cba8c3a41..071a3d23cf1e 100644
--- a/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth.h
+++ b/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth.h
@@ -802,6 +802,7 @@ void dpaa2_eth_dl_unregister(struct dpaa2_eth_priv *priv);
 
 int dpaa2_eth_dl_port_add(struct dpaa2_eth_priv *priv);
 void dpaa2_eth_dl_port_del(struct dpaa2_eth_priv *priv);
+void dpaa2_eth_dl_port_check(struct dpaa2_eth_priv *priv);
 
 int dpaa2_eth_dl_traps_register(struct dpaa2_eth_priv *priv);
 void dpaa2_eth_dl_traps_unregister(struct dpaa2_eth_priv *priv);

-- 
2.43.0

