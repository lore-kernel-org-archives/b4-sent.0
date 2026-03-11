From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Wed, 11 Mar 2026 11:17:58 +0100
Subject: [PATCH v10 1/5] net: stmmac: Use helper macro for loop over
 queue-based arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260311-dwmac_multi_irq-v10-1-7ab1669759b5@oss.nxp.com>
References: <20260311-dwmac_multi_irq-v10-0-7ab1669759b5@oss.nxp.com>
In-Reply-To: <20260311-dwmac_multi_irq-v10-0-7ab1669759b5@oss.nxp.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chester Lin <chester62515@gmail.com>, Matthias Brugger <mbrugger@suse.com>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>, 
 NXP S32 Linux Team <s32@nxp.com>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Li <Frank.Li@nxp.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, devicetree@vger.kernel.org, rmk+kernel@armlinux.org.uk, 
 vladimir.oltean@nxp.com, boon.khai.ng@altera.com, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773224290; l=4143;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=AN9BxArjvT+LtwWtaoyDzsO4XeDTxufZg6uDwPtH3+8=;
 b=5GmT30ZsmnI//0cQZqIyqmK7gRXf93+3mWuwKF2QsS+zP9qDLp9dVlKTTFuR52dc4rr5IUTEi
 tqlCVS1a1XyDDJB1U7gBvoP4QYZRbSHa1Rav6mqSTjzMn2I9T7rcWXJ
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The stmmac driver contains similar pattern for processing queue-based
arrays, ie. interrupt lines, etc. Factor out the for loop and provide
a macro STMMAC_FOREACH_MTL_QUEUE(var, limit).

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwxgmac2_core.c |  2 +-
 drivers/net/ethernet/stmicro/stmmac/stmmac.h        |  3 +++
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c   | 16 ++++++++--------
 3 files changed, 12 insertions(+), 9 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwxgmac2_core.c b/drivers/net/ethernet/stmicro/stmmac/dwxgmac2_core.c
index 49893b9fb88c..3890e82c69f6 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwxgmac2_core.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwxgmac2_core.c
@@ -233,7 +233,7 @@ static void dwxgmac2_prog_mtl_tx_algorithms(struct mac_device_info *hw,
 	writel(value, ioaddr + XGMAC_MTL_OPMODE);
 
 	/* Set ETS if desired */
-	for (i = 0; i < MTL_MAX_TX_QUEUES; i++) {
+	STMMAC_FOREACH_MTL_QUEUE(i, MTL_MAX_TX_QUEUES) {
 		value = readl(ioaddr + XGMAC_MTL_TCx_ETS_CONTROL(i));
 		value &= ~XGMAC_TSA;
 		if (ets)
diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac.h b/drivers/net/ethernet/stmicro/stmmac/stmmac.h
index 51c96a738151..c972ad8e79f8 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac.h
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac.h
@@ -382,6 +382,9 @@ enum stmmac_state {
 
 extern const struct dev_pm_ops stmmac_simple_pm_ops;
 
+#define STMMAC_FOREACH_MTL_QUEUE(var, limit) \
+	for (var = 0; var < (limit); var++)
+
 int stmmac_mdio_unregister(struct net_device *ndev);
 int stmmac_mdio_register(struct net_device *ndev);
 int stmmac_mdio_reset(struct mii_bus *mii);
diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index edf0799b7236..b920ca17b2be 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -3875,7 +3875,7 @@ static int stmmac_request_irq_multi_msi(struct net_device *dev)
 	}
 
 	/* Request Rx MSI irq */
-	for (i = 0; i < priv->plat->rx_queues_to_use; i++) {
+	STMMAC_FOREACH_MTL_QUEUE(i, priv->plat->rx_queues_to_use) {
 		if (i >= MTL_MAX_RX_QUEUES)
 			break;
 		if (priv->rx_irq[i] == 0)
@@ -3899,7 +3899,7 @@ static int stmmac_request_irq_multi_msi(struct net_device *dev)
 	}
 
 	/* Request Tx MSI irq */
-	for (i = 0; i < priv->plat->tx_queues_to_use; i++) {
+	STMMAC_FOREACH_MTL_QUEUE(i, priv->plat->tx_queues_to_use) {
 		if (i >= MTL_MAX_TX_QUEUES)
 			break;
 		if (priv->tx_irq[i] == 0)
@@ -4084,10 +4084,10 @@ static int __stmmac_open(struct net_device *dev,
 			 struct stmmac_dma_conf *dma_conf)
 {
 	struct stmmac_priv *priv = netdev_priv(dev);
+	int ret, i;
 	u32 chan;
-	int ret;
 
-	for (int i = 0; i < MTL_MAX_TX_QUEUES; i++)
+	STMMAC_FOREACH_MTL_QUEUE(i, MTL_MAX_TX_QUEUES)
 		if (priv->dma_conf.tx_queue[i].tbs & STMMAC_TBS_EN)
 			dma_conf->tx_queue[i].tbs = priv->dma_conf.tx_queue[i].tbs;
 	memcpy(&priv->dma_conf, dma_conf, sizeof(*dma_conf));
@@ -7734,9 +7734,9 @@ static int __stmmac_dvr_probe(struct device *device,
 	priv->device = device;
 	priv->dev = ndev;
 
-	for (i = 0; i < MTL_MAX_RX_QUEUES; i++)
+	STMMAC_FOREACH_MTL_QUEUE(i, MTL_MAX_RX_QUEUES)
 		u64_stats_init(&priv->xstats.rxq_stats[i].napi_syncp);
-	for (i = 0; i < MTL_MAX_TX_QUEUES; i++) {
+	STMMAC_FOREACH_MTL_QUEUE(i, MTL_MAX_TX_QUEUES) {
 		u64_stats_init(&priv->xstats.txq_stats[i].q_syncp);
 		u64_stats_init(&priv->xstats.txq_stats[i].napi_syncp);
 	}
@@ -7759,9 +7759,9 @@ static int __stmmac_dvr_probe(struct device *device,
 	priv->sfty_irq = res->sfty_irq;
 	priv->sfty_ce_irq = res->sfty_ce_irq;
 	priv->sfty_ue_irq = res->sfty_ue_irq;
-	for (i = 0; i < MTL_MAX_RX_QUEUES; i++)
+	STMMAC_FOREACH_MTL_QUEUE(i, MTL_MAX_RX_QUEUES)
 		priv->rx_irq[i] = res->rx_irq[i];
-	for (i = 0; i < MTL_MAX_TX_QUEUES; i++)
+	STMMAC_FOREACH_MTL_QUEUE(i, MTL_MAX_TX_QUEUES)
 		priv->tx_irq[i] = res->tx_irq[i];
 
 	if (!is_zero_ether_addr(res->mac))

-- 
2.47.0

