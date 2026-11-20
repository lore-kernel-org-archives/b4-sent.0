From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 20 Nov 2026 10:45:33 +0000
Subject: [PATCH net-next v4 2/5] net: stmmac: dwmac-sun8i: Get the EPHY
 clock and reset before the MAC probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-sun8i-emac-mux-uaf-v4-2-57eba8915f25@gmail.com>
References: <20261120-sun8i-emac-mux-uaf-v4-0-57eba8915f25@gmail.com>
In-Reply-To: <20261120-sun8i-emac-mux-uaf-v4-0-57eba8915f25@gmail.com>
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-stm32@st-md-mailman.stormreply.com, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795171532; l=3805;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=IdMjizPApK7IJxwnRCjJXsAyYZSFVRhsVd8BmZt3Fgs=;
 b=5BvxnoZxuBiioBsyYI1RdFJonVr9LRE4yUrmIvOeDDsGWqhVxmKiIB8x5qTud5s8kzLFgtSzC
 vxqVUydt9h4B/Duiy9kNZCXuUjaygHx8I1I/kyOJPIY84a/6IS9Gor9
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

get_ephy_nodes() runs after stmmac_pltfr_probe() has registered the
netdev, so its -EPROBE_DEFER comes too late. An EPHY clock that is not
ready yet does not defer at all: the node is skipped and the probe
fails with -ENODEV.

Look up the clock and reset before stmmac_pltfr_probe(), and defer on
the clock as on the reset.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 34 ++++++++++++++---------
 1 file changed, 21 insertions(+), 13 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
index 9fb398f7cf9e..4acfda235394 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
@@ -775,16 +775,15 @@ static void sun8i_dwmac_flow_ctrl(struct mac_device_info *hw,
 }
 
 /* Search in mdio-mux node for internal PHY node and get its clk/reset */
-static int get_ephy_nodes(struct stmmac_priv *priv)
+static int get_ephy_nodes(struct device *dev, struct sunxi_priv_data *gmac)
 {
-	struct sunxi_priv_data *gmac = priv->plat->bsp_priv;
 	struct device_node *mdio_internal;
 	struct device_node *mdio_mux;
 	int ret;
 
-	mdio_mux = of_get_child_by_name(priv->device->of_node, "mdio-mux");
+	mdio_mux = of_get_child_by_name(dev->of_node, "mdio-mux");
 	if (!mdio_mux) {
-		dev_err(priv->device, "Cannot get mdio-mux node\n");
+		dev_err(dev, "Cannot get mdio-mux node\n");
 		return -ENODEV;
 	}
 
@@ -792,7 +791,7 @@ static int get_ephy_nodes(struct stmmac_priv *priv)
 						"allwinner,sun8i-h3-mdio-internal");
 	of_node_put(mdio_mux);
 	if (!mdio_internal) {
-		dev_err(priv->device, "Cannot get internal_mdio node\n");
+		dev_err(dev, "Cannot get internal_mdio node\n");
 		return -ENODEV;
 	}
 
@@ -801,8 +800,13 @@ static int get_ephy_nodes(struct stmmac_priv *priv)
 		struct clk *ephy_clk;
 
 		ephy_clk = of_clk_get(iphynode, 0);
-		if (IS_ERR(ephy_clk))
+		if (IS_ERR(ephy_clk)) {
+			if (PTR_ERR(ephy_clk) == -EPROBE_DEFER) {
+				of_node_put(mdio_internal);
+				return -EPROBE_DEFER;
+			}
 			continue;
+		}
 		gmac->rst_ephy = of_reset_control_get_exclusive(iphynode, NULL);
 		if (IS_ERR(gmac->rst_ephy)) {
 			ret = PTR_ERR(gmac->rst_ephy);
@@ -814,7 +818,7 @@ static int get_ephy_nodes(struct stmmac_priv *priv)
 			continue;
 		}
 		gmac->ephy_clk = ephy_clk;
-		dev_info(priv->device, "Found internal PHY node\n");
+		dev_info(dev, "Found internal PHY node\n");
 		of_node_put(mdio_internal);
 		return 0;
 	}
@@ -1209,9 +1213,15 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
 	plat_dat->tx_fifo_size = 4096;
 	plat_dat->rx_fifo_size = 16384;
 
+	if (gmac->variant->soc_has_internal_phy) {
+		ret = get_ephy_nodes(dev, gmac);
+		if (ret)
+			return ret;
+	}
+
 	ret = sun8i_dwmac_set_syscon(&pdev->dev, plat_dat);
 	if (ret)
-		return ret;
+		goto dwmac_ephy;
 
 	ret = stmmac_pltfr_probe(pdev, plat_dat, &stmmac_res);
 	if (ret)
@@ -1230,9 +1240,6 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
 	 * so after stmmac_dvr_probe()
 	 */
 	if (gmac->variant->soc_has_internal_phy) {
-		ret = get_ephy_nodes(priv);
-		if (ret)
-			goto dwmac_remove;
 		ret = sun8i_dwmac_register_mdio_mux(priv);
 		if (ret) {
 			dev_err(&pdev->dev, "Failed to register mux\n");
@@ -1247,10 +1254,11 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
 dwmac_remove:
 	pm_runtime_put_noidle(&pdev->dev);
 	stmmac_pltfr_remove(pdev);
-	reset_control_put(gmac->rst_ephy);
-	clk_put(gmac->ephy_clk);
 dwmac_syscon:
 	sun8i_dwmac_unset_syscon(gmac);
+dwmac_ephy:
+	reset_control_put(gmac->rst_ephy);
+	clk_put(gmac->ephy_clk);
 
 	return ret;
 }

-- 
2.55.0

