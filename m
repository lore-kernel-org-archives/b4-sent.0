From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:37:01 +0000
Subject: [PATCH net-next v5 2/6] net: stmmac: dwmac-sun8i: Get the EPHY
 clock and reset before the MAC probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-sun8i-emac-mux-uaf-v5-2-0869f2ccdb8b@gmail.com>
References: <20261128-sun8i-emac-mux-uaf-v5-0-0869f2ccdb8b@gmail.com>
In-Reply-To: <20261128-sun8i-emac-mux-uaf-v5-0-0869f2ccdb8b@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795887420; l=3900;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=SUsFtWJfutSd0Ot3xLTIEXYdZNvfXec2HzH4/NUqExU=;
 b=1K36yQLgnoCBX9HZRJ6cDYGhP637fEJkOoUiicw2psv3NY/i+79+PKH1r6rB4gs78/kjllE+s
 DlulXzBhnxtBZy1fhv2/eedKlXDxWOggZXRbPg29FpFIfTeXeIIdBtD
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switching the MDIO mux to the internal PHY uses the EPHY clock and
reset, and a later patch registers the mux from within
stmmac_pltfr_probe(). Look both up before it.

Also defer on the clock, as on the reset, instead of skipping the node.
This only matters if the EPHY clock has another provider than the EMAC
reset; in-tree DTs take both from the CCU.

Reviewed-by: Maxime Chevallier <maxime.chevallier@bootlin.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 34 ++++++++++++++---------
 1 file changed, 21 insertions(+), 13 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
index 26744693e93f..0ae0888467bb 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
@@ -795,16 +795,15 @@ static void sun8i_dwmac_flow_ctrl(struct mac_device_info *hw,
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
 
@@ -812,7 +811,7 @@ static int get_ephy_nodes(struct stmmac_priv *priv)
 						"allwinner,sun8i-h3-mdio-internal");
 	of_node_put(mdio_mux);
 	if (!mdio_internal) {
-		dev_err(priv->device, "Cannot get internal_mdio node\n");
+		dev_err(dev, "Cannot get internal_mdio node\n");
 		return -ENODEV;
 	}
 
@@ -821,8 +820,13 @@ static int get_ephy_nodes(struct stmmac_priv *priv)
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
@@ -834,7 +838,7 @@ static int get_ephy_nodes(struct stmmac_priv *priv)
 			continue;
 		}
 		gmac->ephy_clk = ephy_clk;
-		dev_info(priv->device, "Found internal PHY node\n");
+		dev_info(dev, "Found internal PHY node\n");
 		of_node_put(mdio_internal);
 		return 0;
 	}
@@ -1229,9 +1233,15 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
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
@@ -1250,9 +1260,6 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
 	 * so after stmmac_dvr_probe()
 	 */
 	if (gmac->variant->soc_has_internal_phy) {
-		ret = get_ephy_nodes(priv);
-		if (ret)
-			goto dwmac_remove;
 		ret = sun8i_dwmac_register_mdio_mux(priv);
 		if (ret) {
 			dev_err(&pdev->dev, "Failed to register mux\n");
@@ -1267,10 +1274,11 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
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

