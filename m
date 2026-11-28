From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:37:05 +0000
Subject: [PATCH net-next v5 6/6] net: stmmac: dwmac-sun8i: Register the
 MDIO mux in the MDIO setup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-sun8i-emac-mux-uaf-v5-6-0869f2ccdb8b@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795887420; l=3534;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=06xMMbK7YMcRgRF52+HyeLRwttdqVvbxWi3c45LCb9c=;
 b=LedbXetbsn+G/QRIf+sec51VZmTvG7/NHISEeTmdSBC2nRVIuYgkHVQG9THIY7usAiKbTRG34
 WkoFaYfUdsAALnVMg1UMF/a0DDanu0wAxXdZ+MxsSsV1IGXuWiN9aYd
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both PHYs sit behind the mux, but the mux is registered only after
stmmac_pltfr_probe() has registered the netdev, so an early open does
not find the PHY. On remove, the mux goes away before
unregister_netdev(), and unbinding with the link up oopses in
phy_stop().

Register and unregister the mux through the mdio_init() and mdio_exit()
hooks added by "net: stmmac: Add MDIO init and exit platform hooks".

Reviewed-by: Maxime Chevallier <maxime.chevallier@bootlin.com>
Tested-by: Maxime Chevallier <maxime.chevallier@bootlin.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 41 ++++++-----------------
 1 file changed, 10 insertions(+), 31 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
index 0ae0888467bb..09f07546f08c 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
@@ -18,7 +18,6 @@
 #include <linux/of_platform.h>
 #include <linux/phy.h>
 #include <linux/platform_device.h>
-#include <linux/pm_runtime.h>
 #include <linux/regulator/consumer.h>
 #include <linux/regmap.h>
 #include <linux/stmmac.h>
@@ -961,6 +960,13 @@ static int sun8i_dwmac_register_mdio_mux(struct stmmac_priv *priv)
 	return ret;
 }
 
+static void sun8i_dwmac_unregister_mdio_mux(struct stmmac_priv *priv)
+{
+	struct sunxi_priv_data *gmac = priv->plat->bsp_priv;
+
+	mdio_mux_uninit(gmac->mux_handle);
+}
+
 static int sun8i_dwmac_set_syscon(struct device *dev,
 				  struct plat_stmmacenet_data *plat)
 {
@@ -1153,8 +1159,6 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
 	struct stmmac_resources stmmac_res;
 	struct sunxi_priv_data *gmac;
 	struct device *dev = &pdev->dev;
-	struct stmmac_priv *priv;
-	struct net_device *ndev;
 	struct regmap *regmap;
 	int ret;
 
@@ -1237,6 +1241,9 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
 		ret = get_ephy_nodes(dev, gmac);
 		if (ret)
 			return ret;
+
+		plat_dat->mdio_init = sun8i_dwmac_register_mdio_mux;
+		plat_dat->mdio_exit = sun8i_dwmac_unregister_mdio_mux;
 	}
 
 	ret = sun8i_dwmac_set_syscon(&pdev->dev, plat_dat);
@@ -1247,33 +1254,8 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
 	if (ret)
 		goto dwmac_syscon;
 
-	ndev = dev_get_drvdata(&pdev->dev);
-	priv = netdev_priv(ndev);
-
-	/* the MAC is runtime suspended after stmmac_dvr_probe(), so we
-	 * need to ensure the MAC resume back before other operations such
-	 * as reset.
-	 */
-	pm_runtime_get_sync(&pdev->dev);
-
-	/* The mux must be registered after parent MDIO
-	 * so after stmmac_dvr_probe()
-	 */
-	if (gmac->variant->soc_has_internal_phy) {
-		ret = sun8i_dwmac_register_mdio_mux(priv);
-		if (ret) {
-			dev_err(&pdev->dev, "Failed to register mux\n");
-			goto dwmac_remove;
-		}
-	}
-
-	pm_runtime_put(&pdev->dev);
-
 	return 0;
 
-dwmac_remove:
-	pm_runtime_put_noidle(&pdev->dev);
-	stmmac_pltfr_remove(pdev);
 dwmac_syscon:
 	sun8i_dwmac_unset_syscon(gmac);
 dwmac_ephy:
@@ -1289,9 +1271,6 @@ static void sun8i_dwmac_remove(struct platform_device *pdev)
 	struct stmmac_priv *priv = netdev_priv(ndev);
 	struct sunxi_priv_data *gmac = priv->plat->bsp_priv;
 
-	if (gmac->variant->soc_has_internal_phy)
-		mdio_mux_uninit(gmac->mux_handle);
-
 	stmmac_pltfr_remove(pdev);
 	reset_control_put(gmac->rst_ephy);
 	clk_put(gmac->ephy_clk);

-- 
2.55.0

