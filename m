From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 20 Nov 2026 10:45:32 +0000
Subject: [PATCH net-next v4 1/5] net: stmmac: dwmac-sun8i: Put the EPHY
 clock and reset after the MAC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-sun8i-emac-mux-uaf-v4-1-57eba8915f25@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795171532; l=2122;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=zeDU/ie5mpEDPgDE4ZGiqAqgOX9E3SDKKC5wYWtaBU0=;
 b=t/igZe+xTX/0i5PLRfuaa1Gv+fjIDiunNi9b8S5A+ogJpuhxE/sI+198+B+rfmqwhYg382Lpz
 opxtf4+8pQwC1U4RUjk6F22wyRVooUvNNchEEitqd61roewZ0fdpDIE
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sun8i_dwmac_exit() unpowers the internal PHY through ephy_clk and
rst_ephy, but the probe error path and sun8i_dwmac_remove() put both
before stmmac_pltfr_remove() calls it. If mdio_mux_init() fails after
the scan of the internal bus has powered the PHY, this is a
use-after-free.

Put them after stmmac_pltfr_remove(). The explicit unpower in remove()
is then redundant.

Suggested-by: Chen-Yu Tsai <wens@kernel.org>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 15 ++++++---------
 1 file changed, 6 insertions(+), 9 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
index 2ece7ba9dd73..9fb398f7cf9e 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
@@ -1236,7 +1236,7 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
 		ret = sun8i_dwmac_register_mdio_mux(priv);
 		if (ret) {
 			dev_err(&pdev->dev, "Failed to register mux\n");
-			goto dwmac_mux;
+			goto dwmac_remove;
 		}
 	}
 
@@ -1244,12 +1244,11 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
 
 	return 0;
 
-dwmac_mux:
-	reset_control_put(gmac->rst_ephy);
-	clk_put(gmac->ephy_clk);
 dwmac_remove:
 	pm_runtime_put_noidle(&pdev->dev);
 	stmmac_pltfr_remove(pdev);
+	reset_control_put(gmac->rst_ephy);
+	clk_put(gmac->ephy_clk);
 dwmac_syscon:
 	sun8i_dwmac_unset_syscon(gmac);
 
@@ -1262,14 +1261,12 @@ static void sun8i_dwmac_remove(struct platform_device *pdev)
 	struct stmmac_priv *priv = netdev_priv(ndev);
 	struct sunxi_priv_data *gmac = priv->plat->bsp_priv;
 
-	if (gmac->variant->soc_has_internal_phy) {
+	if (gmac->variant->soc_has_internal_phy)
 		mdio_mux_uninit(gmac->mux_handle);
-		sun8i_dwmac_unpower_internal_phy(gmac);
-		reset_control_put(gmac->rst_ephy);
-		clk_put(gmac->ephy_clk);
-	}
 
 	stmmac_pltfr_remove(pdev);
+	reset_control_put(gmac->rst_ephy);
+	clk_put(gmac->ephy_clk);
 	sun8i_dwmac_unset_syscon(gmac);
 }
 

-- 
2.55.0

