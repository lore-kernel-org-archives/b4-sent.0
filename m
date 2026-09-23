From: Vincent Jardin <vjardin@free.fr>
Date: Wed, 23 Sep 2026 14:58:01 +0200
Subject: [PATCH net-next 2/2] dpaa2-eth: DPNIs without a DPMAC should be
 virtual devlink ports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-for-upstream-dpaa2_ports-v1-2-b59c865edd00@free.fr>
References: <20260923-for-upstream-dpaa2_ports-v1-0-b59c865edd00@free.fr>
In-Reply-To: <20260923-for-upstream-dpaa2_ports-v1-0-b59c865edd00@free.fr>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Ioana Ciornei <ioana.ciornei@nxp.com>, 
 Vladimir Oltean <vladimir.oltean@nxp.com>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790168287; l=1873;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=p/tRI7VLwMp8un0siHeJSm+K06WfFyI311A5CyvuR9c=;
 b=7UbZF4ftv6wUuedkckRvkZ6wyYKYj1SZyQUot5FiHlSjeBR15Ae2+Cr53MJT0/YyFBSDN7j3H
 WCnHvtUiin9D5wAM/lXCz18PUxt+9X9RGCt/ZrDliqWpASckHlu/dev
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A DPNI whose endpoint is not a DPMAC has no physical connector: it
may have no endpoint at all, or be connected to another DPNI or to a
DPSW port. It is still registered as a physical devlink port, number 0,
so userspace sees a physical port that does not exist.

A virtual port has no phys_port_name, so only the DPNIs that serve a
DPMAC report one, and "p<dpmac id>" never collides.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c b/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c
index 8b2addd3f83a..30e6cb2190db 100644
--- a/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c
+++ b/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c
@@ -230,16 +230,23 @@ int dpaa2_eth_dl_port_add(struct dpaa2_eth_priv *priv)
 	struct devlink_port *devlink_port = &priv->devlink_port;
 	struct devlink_port_attrs attrs = {};
 
-	attrs.flavour = DEVLINK_PORT_FLAVOUR_PHYSICAL;
 	attrs.phys.port_number = dpaa2_eth_dl_port_number(priv);
+	if (attrs.phys.port_number)
+		attrs.flavour = DEVLINK_PORT_FLAVOUR_PHYSICAL;
+	else
+		attrs.flavour = DEVLINK_PORT_FLAVOUR_VIRTUAL;
 	devlink_port_attrs_set(devlink_port, &attrs);
 	return devlink_port_register(priv->devlink, devlink_port, 0);
 }
 
 void dpaa2_eth_dl_port_check(struct dpaa2_eth_priv *priv)
 {
-	u32 registered = priv->devlink_port.attrs.phys.port_number;
+	const struct devlink_port_attrs *attrs = &priv->devlink_port.attrs;
 	u32 current_number = dpaa2_eth_dl_port_number(priv);
+	u32 registered = 0;
+
+	if (attrs->flavour == DEVLINK_PORT_FLAVOUR_PHYSICAL)
+		registered = attrs->phys.port_number;
 
 	if (registered == current_number)
 		return;

-- 
2.43.0

