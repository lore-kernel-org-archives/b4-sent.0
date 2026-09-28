From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 28 Sep 2026 13:22:46 +0200
Subject: [PATCH net-next v2 2/2] dpaa2-eth: mark DPNIs without a DPMAC as
 virtual devlink ports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-for-upstream-dpaa2_ports-v2-2-1cda148530bf@free.fr>
References: <20260928-for-upstream-dpaa2_ports-v2-0-1cda148530bf@free.fr>
In-Reply-To: <20260928-for-upstream-dpaa2_ports-v2-0-1cda148530bf@free.fr>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Ioana Ciornei <ioana.ciornei@nxp.com>, 
 Vladimir Oltean <vladimir.oltean@nxp.com>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790594566; l=1468;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=3YGJMDPaMDzgW71kznvDVaigwXmYnYuAduxFzGsju8g=;
 b=gpjUniYcuC+Qe5vrx3IlrqALzspy2ZUXoss6j4BUCCbJkk4umwE8zC+vKI0I2iUlpRnCRCEnE
 FzIuJpaxXe8AxIhMRlH2d2DReQwZbxw8WLsDjtpJydh1r588O23Y3Tv
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A DPNI whose endpoint is not a DPMAC has no physical connector: it
may have no endpoint at all, or be connected to another DPNI or to a
DPSW port. Until now, such a DPNI was still registered as a physical
devlink port with number 0, so userspace saw a physical port that does
not exist.

Register these DPNIs as virtual devlink ports instead. A virtual port
has no phys_port_name, so only the DPNIs that serve a DPMAC at probe
time report one, "p<dpmac id>", and those names do not collide.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c b/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c
index 4c0a04c2d458..6defc00199bf 100644
--- a/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c
+++ b/drivers/net/ethernet/freescale/dpaa2/dpaa2-eth-devlink.c
@@ -233,7 +233,10 @@ int dpaa2_eth_dl_port_add(struct dpaa2_eth_priv *priv)
 	priv->dl_port_valid = true;
 	mutex_unlock(&priv->mac_lock);
 
-	attrs.flavour = DEVLINK_PORT_FLAVOUR_PHYSICAL;
+	if (port_number)
+		attrs.flavour = DEVLINK_PORT_FLAVOUR_PHYSICAL;
+	else
+		attrs.flavour = DEVLINK_PORT_FLAVOUR_VIRTUAL;
 	attrs.phys.port_number = port_number;
 	devlink_port_attrs_set(devlink_port, &attrs);
 	err = devlink_port_register(priv->devlink, devlink_port, 0);

-- 
2.43.0

