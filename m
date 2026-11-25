From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Wed, 25 Nov 2026 10:33:52 +0100
Subject: [PATCH RFC v4 10/15] net: stmmac: s32: Add SGMII support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-s32g_serdes-v4-10-3bfe0589be8d@oss.nxp.com>
References: <20261125-s32g_serdes-v4-0-3bfe0589be8d@oss.nxp.com>
In-Reply-To: <20261125-s32g_serdes-v4-0-3bfe0589be8d@oss.nxp.com>
To: Vincent Guittot <vincent.guittot@linaro.org>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>, 
 Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>, 
 NXP S32 Linux Team <s32@nxp.com>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Bogdan Hamciuc <bogdan.hamciuc@nxp.com>, 
 Ionut Vicovan <ionut.vicovan@nxp.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chester Lin <chester62515@gmail.com>, Matthias Brugger <mbrugger@suse.com>, 
 Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, 
 linux-pci@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795599274; l=6036;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=SUyLyApZQH6suRK9Yypfm9Q7YRcmaOUjKY8ryatuSDw=;
 b=etNy0UY8GpXg7oCE1TpwE17I/LcnvQGpqZua1jfCFFcl/u+f8R57bnv+fT23gX0w5yekwUfqB
 +0zNN+MG1i5B3FpGw8iprmgufsGDM9qyonqTwuCgLwO0NIj49FEoxlg
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Let the MAC run SGMII over a SerDes lane, with a SerDes XPCS instance
as the PCS:

- Select the PHY interface from phy_interface instead of hard-coding
  RGMII, and add SGMII. RMII and MII stay unsupported. The selector is
  computed once at probe, so an unsupported phy-mode fails the probe
  instead of every init and resume.

- With SGMII, get the PCS in pcs_init from s32g_serdes_pcs_create()
  with the MAC node: pcs-handle points at the SerDes, phys names the
  lane and the XPCS instance. An SGMII MAC without pcs-handle fails to
  probe. There is no exit hook: the PCS is owned by the SerDes device, and
  s32g_serdes_pcs_create() creates a device link to it.

- Keep the MAC transmit clock at 125 MHz for every speed with SGMII:
  10M and 100M use symbol replication in the PCS, while
  stmmac_set_clk_tx_rate() would set 25 MHz / 2.5 MHz.

- Disable EEE with SGMII: the SerDes XPCS does not implement it, but
  stmmac assumes that LPI works through any external PCS.

- Select PHY_S32G_SERDES.

As with dwmac-rzn1 and dwmac-intel, a select_pcs callback means the
core no longer falls back to the integrated PCS.

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 drivers/net/ethernet/stmicro/stmmac/Kconfig     |  1 +
 drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c | 81 ++++++++++++++++++++++++-
 2 files changed, 79 insertions(+), 3 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/Kconfig b/drivers/net/ethernet/stmicro/stmmac/Kconfig
index c6559e749c0c..26dec3f61ea7 100644
--- a/drivers/net/ethernet/stmicro/stmmac/Kconfig
+++ b/drivers/net/ethernet/stmicro/stmmac/Kconfig
@@ -193,6 +193,7 @@ config DWMAC_S32
 	tristate "NXP S32G/S32R GMAC support"
 	default ARCH_S32
 	depends on OF && (ARCH_S32 || COMPILE_TEST)
+	select PHY_S32G_SERDES
 	help
 	  Support for ethernet controller on NXP S32CC SOCs.
 
diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c
index 1f51df491370..1b1e2e2adb77 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-s32.c
@@ -16,12 +16,14 @@
 #include <linux/of_mdio.h>
 #include <linux/of_address.h>
 #include <linux/phy.h>
+#include <linux/phy/nxp-s32g-serdes.h>
 #include <linux/phylink.h>
 #include <linux/platform_device.h>
 #include <linux/regmap.h>
 #include <linux/stmmac.h>
 
 #include "stmmac_platform.h"
+#include "stmmac.h"
 
 #define GMAC_INTF_RATE_125M	125000000	/* 125MHz */
 
@@ -38,25 +40,82 @@ struct s32_priv_data {
 	unsigned int sts_offset;
 	struct device *dev;
 	phy_interface_t *intf_mode;
+	u32 intf_sel;
 	struct clk *tx_clk;
 	struct clk *rx_clk;
 };
 
+static int s32_gmac_phy_intf_sel(phy_interface_t interface)
+{
+	switch (interface) {
+	case PHY_INTERFACE_MODE_SGMII:
+		return S32_PHY_INTF_SEL_SGMII;
+	case PHY_INTERFACE_MODE_RGMII:
+	case PHY_INTERFACE_MODE_RGMII_ID:
+	case PHY_INTERFACE_MODE_RGMII_RXID:
+	case PHY_INTERFACE_MODE_RGMII_TXID:
+		return S32_PHY_INTF_SEL_RGMII;
+	default:
+		return -EINVAL;
+	}
+}
+
 static int s32_gmac_write_phy_intf_select(struct s32_priv_data *gmac)
 {
 	int ret = 0;
 
 	if (gmac->ctrl_sts)
-		writel(S32_PHY_INTF_SEL_RGMII, gmac->ctrl_sts);
+		writel(gmac->intf_sel, gmac->ctrl_sts);
 	else
 		ret = regmap_write(gmac->sts_regmap, gmac->sts_offset,
-				   S32_PHY_INTF_SEL_RGMII);
+				   gmac->intf_sel);
 
 	dev_dbg(gmac->dev, "PHY mode set to %s\n", phy_modes(*gmac->intf_mode));
 
 	return ret;
 }
 
+static int s32_gmac_pcs_init(struct stmmac_priv *priv)
+{
+	struct s32_priv_data *gmac = priv->plat->bsp_priv;
+	struct device_node *np = gmac->dev->of_node;
+	struct phylink_pcs *pcs;
+
+	if (*gmac->intf_mode != PHY_INTERFACE_MODE_SGMII)
+		return 0;
+
+	if (!of_property_present(np, "pcs-handle"))
+		return dev_err_probe(gmac->dev, -EINVAL,
+				     "SGMII needs a pcs-handle\n");
+
+	pcs = s32g_serdes_pcs_create(gmac->dev, np);
+	if (IS_ERR(pcs))
+		return PTR_ERR(pcs);
+
+	priv->hw->phylink_pcs = pcs;
+
+	return 0;
+}
+
+static struct phylink_pcs *s32_gmac_select_pcs(struct stmmac_priv *priv,
+					       phy_interface_t interface)
+{
+	return priv->hw->phylink_pcs;
+}
+
+static int s32_gmac_set_clk_tx_rate(void *bsp_priv, struct clk *clk_tx_i,
+				    phy_interface_t interface, int speed)
+{
+	/*
+	 * With SGMII the MAC transmit clock stays at the 125 MHz set in
+	 * s32_gmac_init(): 10M and 100M use symbol replication in the PCS.
+	 */
+	if (interface == PHY_INTERFACE_MODE_SGMII)
+		return 0;
+
+	return stmmac_set_clk_tx_rate(bsp_priv, clk_tx_i, interface, speed);
+}
+
 static int s32_gmac_init(struct device *dev, void *priv)
 {
 	struct s32_priv_data *gmac = priv;
@@ -192,11 +251,25 @@ static int s32_dwmac_probe(struct platform_device *pdev)
 	gmac->intf_mode = &plat->phy_interface;
 	gmac->ioaddr = res.addr;
 
+	ret = s32_gmac_phy_intf_sel(plat->phy_interface);
+	if (ret < 0)
+		return dev_err_probe(dev, ret,
+				     "Unsupported phy interface mode: %s\n",
+				     phy_modes(plat->phy_interface));
+	gmac->intf_sel = ret;
+
 	/* S32CC core feature set */
 	plat->core_type = DWMAC_CORE_GMAC4;
 	plat->pmt = true;
 	plat->flags |= STMMAC_FLAG_SPH_DISABLE;
 
+	/*
+	 * The SerDes XPCS has no EEE support, but stmmac assumes LPI works
+	 * through any external PCS.
+	 */
+	if (plat->phy_interface == PHY_INTERFACE_MODE_SGMII)
+		plat->flags |= STMMAC_FLAG_EEE_DISABLE;
+
 	s32_gmac_setup_multi_irq(dev, plat, &res);
 
 	plat->rx_fifo_size = 20480;
@@ -204,9 +277,11 @@ static int s32_dwmac_probe(struct platform_device *pdev)
 
 	plat->init = s32_gmac_init;
 	plat->exit = s32_gmac_exit;
+	plat->pcs_init = s32_gmac_pcs_init;
+	plat->select_pcs = s32_gmac_select_pcs;
 
 	plat->clk_tx_i = gmac->tx_clk;
-	plat->set_clk_tx_rate = stmmac_set_clk_tx_rate;
+	plat->set_clk_tx_rate = s32_gmac_set_clk_tx_rate;
 
 	plat->bsp_priv = gmac;
 

-- 
2.55.0

