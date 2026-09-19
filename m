From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Sat, 19 Sep 2026 08:54:32 +0200
Subject: [PATCH RFC v3 04/12] net: pcs: add NXP SerDes XPCS shared core
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-s32g_serdes-v3-4-9d68868c1e89@oss.nxp.com>
References: <20260919-s32g_serdes-v3-0-9d68868c1e89@oss.nxp.com>
In-Reply-To: <20260919-s32g_serdes-v3-0-9d68868c1e89@oss.nxp.com>
To: Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>, 
 NXP S32 Linux Team <s32@nxp.com>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@nxp.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Magnus Damm <magnus.damm@gmail.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Bogdan Hamciuc <bogdan.hamciuc@nxp.com>, 
 Ionut Vicovan <ionut.vicovan@nxp.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Clark Wang <xiaoning.wang@nxp.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chester Lin <chester62515@gmail.com>, Matthias Brugger <mbrugger@suse.com>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>, 
 Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-renesas-soc@vger.kernel.org, 
 imx@lists.linux.dev, linux-pci@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789800879; l=32040;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=/tGWAZYs+yVQKlNG/JCHWlZQHasfBUZSHRqwcQVhlvs=;
 b=FjC08RMtHpHArGzgP+1CKCxuOTAyhHkPhpSLlK28fXSnCRRPItDjXrqhrhqtHaVlJE7p2NlEF
 Oi2c9f0ZEoGCCCH+/FAEw8BbsZ+WnywR/bUdG1l4htUU5bPBgbZHTGJ
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Clark Wang <xiaoning.wang@nxp.com>

The SerDes subsystems found on NXP S32G and i.MX SoCs integrate a
Synopsys DesignWare Ethernet XPCS and an Ethernet PHY (PMA) with an
identical register layout. Only the register transport differs: indirect
memory mapped access on S32G, Clause 45 MDIO on i.MX.

Add a transport agnostic phylink PCS core which operates on regmaps
provided by the platform glue. It implements the phylink PCS operations,
the Clause 37 SGMII / 2500BASE-X / USXGMII / 10GBASE-R configuration and
link state handling, soft reset and polling helpers, and the common
feature sets. The platform specific register sequences, compatibility
tables and quirks are supplied through a per revision descriptor by the
platform drivers selecting this core.

The register sequences and the feature lists are derived from the
Synopsys pcs-xpcs driver, so its copyright is retained. A separate driver
is needed because struct dw_xpcs is built around an mdio_device and owns
the transport, the reset and the identification of a standalone PCS,
while here the PMA can be shared with a PCIe controller, the bring-up is
sequenced across both XPCS instances by the SerDes PHY driver, and the
transport is not always MDIO.

Tested on an S32G3-VNP-RDB3 board through the S32G platform glue added
by the next patch, in both SerDes working modes this series describes:
mode 1 (PCIe x1 + 1G SGMII) and mode 3 (dual SGMII). GMAC0 links at 1G
over XPCS0 and passes traffic in both.

Signed-off-by: Clark Wang <xiaoning.wang@nxp.com>
[jan.petrous: report in-band SGMII link down until BMSR_ANEGCOMPLETE]
Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 drivers/net/pcs/Kconfig                 |  11 +
 drivers/net/pcs/Makefile                |   1 +
 drivers/net/pcs/pcs-nxp-serdes-xpcs.c   | 853 ++++++++++++++++++++++++++++++++
 include/linux/pcs/pcs-nxp-serdes-xpcs.h | 100 ++++
 4 files changed, 965 insertions(+)

diff --git a/drivers/net/pcs/Kconfig b/drivers/net/pcs/Kconfig
index e417fd66f660..ec4af294003f 100644
--- a/drivers/net/pcs/Kconfig
+++ b/drivers/net/pcs/Kconfig
@@ -12,6 +12,17 @@ config PCS_XPCS
 	  This module provides a driver and helper functions for Synopsys
 	  DesignWare XPCS controllers.
 
+config PCS_NXP_SERDES_XPCS
+	tristate "NXP SerDes XPCS shared core"
+	select PHYLINK
+	select REGMAP
+	help
+	  Transport agnostic phylink PCS core for the Synopsys DesignWare
+	  Ethernet XPCS and Ethernet PHY of the SerDes subsystems found on
+	  NXP S32G and i.MX SoCs. The platform specific register transport
+	  (indirect MMIO on S32G, Clause 45 MDIO on i.MX) is implemented as
+	  regmap callbacks by the platform drivers selecting this core.
+
 config PCS_LYNX
 	tristate
 	help
diff --git a/drivers/net/pcs/Makefile b/drivers/net/pcs/Makefile
index 4f7920618b90..bbf063b18f1f 100644
--- a/drivers/net/pcs/Makefile
+++ b/drivers/net/pcs/Makefile
@@ -5,6 +5,7 @@ pcs_xpcs-$(CONFIG_PCS_XPCS)	:= pcs-xpcs.o pcs-xpcs-plat.o \
 				   pcs-xpcs-nxp.o pcs-xpcs-wx.o
 
 obj-$(CONFIG_PCS_XPCS)		+= pcs_xpcs.o
+obj-$(CONFIG_PCS_NXP_SERDES_XPCS) += pcs-nxp-serdes-xpcs.o
 obj-$(CONFIG_PCS_LYNX)		+= pcs-lynx.o
 obj-$(CONFIG_PCS_MTK_LYNXI)	+= pcs-mtk-lynxi.o
 obj-$(CONFIG_PCS_RZN1_MIIC)	+= pcs-rzn1-miic.o
diff --git a/drivers/net/pcs/pcs-nxp-serdes-xpcs.c b/drivers/net/pcs/pcs-nxp-serdes-xpcs.c
new file mode 100644
index 000000000000..cc739914496e
--- /dev/null
+++ b/drivers/net/pcs/pcs-nxp-serdes-xpcs.c
@@ -0,0 +1,853 @@
+// SPDX-License-Identifier: GPL-2.0
+/* NXP SerDes XPCS / XPCS-PHY shared core
+ *
+ * Transport agnostic phylink PCS driver for the Ethernet XPCS and Ethernet
+ * PHY (XPCS-PHY) of the SerDes subsystems found on NXP S32G and i.MX SoCs.
+ * The platform glue provides the regmaps and a per revision descriptor
+ * with the compatibility table, quirks and PMA programming sequences.
+ *
+ * The XPCS is a Synopsys DesignWare core, so the Clause 37 / 2500BASE-X /
+ * USXGMII / 10GBASE-R register sequences below are shared with the Synopsys
+ * pcs-xpcs driver and were derived from it. This is a separate driver rather
+ * than an extension of pcs-xpcs because struct dw_xpcs is built around an
+ * mdio_device: it owns the transport, the reset and the identification of a
+ * standalone PCS. That model does not fit these SerDes subsystems, where the
+ * PMA belongs to a combo PHY shared with a PCIe controller, the bring-up is
+ * sequenced across both XPCS instances by the PHY driver, and the register
+ * transport is either indirect MMIO or Clause 45 MDIO. What is left here is
+ * the phylink PCS layer on top of a regmap.
+ *
+ * Keep the register sequences in sync with drivers/net/pcs/pcs-xpcs.c when
+ * fixes apply to both.
+ *
+ * Copyright 2023-2026 NXP
+ * Copyright (c) 2020 Synopsys, Inc. and/or its affiliates.
+ */
+
+#include <linux/device.h>
+#include <linux/ethtool.h>
+#include <linux/iopoll.h>
+#include <linux/mdio.h>
+#include <linux/mii.h>
+#include <linux/module.h>
+#include <linux/pcs/pcs-nxp-serdes-xpcs.h>
+#include <linux/phylink.h>
+
+/* SR_MII USXGMII speed selection */
+#define DW_USXGMII_RST			BIT(10)
+#define DW_USXGMII_EN			BIT(9)
+#define DW_USXGMII_FULL			BIT(8)
+#define DW_USXGMII_SS_MASK		(BIT(13) | BIT(6) | BIT(5))
+#define DW_USXGMII_10000		(BIT(13) | BIT(6))
+#define DW_USXGMII_5000			(BIT(13) | BIT(5))
+#define DW_USXGMII_2500			(BIT(5))
+#define DW_USXGMII_1000			(BIT(6))
+#define DW_USXGMII_100			(BIT(13))
+#define DW_USXGMII_10			(0)
+
+/* VR MII MMD registers offsets */
+#define DW_VR_MII_DIG_CTRL1		0x8000
+#define DW_VR_MII_DIG_CTRL1_MAC_AUTO_SW		BIT(9)
+#define DW_VR_MII_DIG_CTRL1_2G5_EN		BIT(2)
+
+#define DW_VR_MII_AN_CTRL		0x8001
+#define DW_VR_MII_TX_CONFIG_MASK		BIT(3)
+#define DW_VR_MII_TX_CONFIG_MAC_SIDE_SGMII	0x0
+#define DW_VR_MII_PCS_MODE_MASK			GENMASK(2, 1)
+#define DW_VR_MII_PCS_MODE_C37_SGMII		0x2
+#define DW_VR_MII_AN_INTR_EN			BIT(0)
+
+#define DW_VR_MII_AN_INTR_STS		0x8002
+#define DW_VR_MII_AN_STS_C37_ANCMPLT_INTR	BIT(0)
+#define DW_VR_MII_AN_STS_C37_ANSGM_FD		BIT(1)
+#define DW_VR_MII_AN_STS_C37_ANSGM_SP		GENMASK(3, 2)
+#define DW_VR_MII_C37_ANSGM_SP_10		0x0
+#define DW_VR_MII_C37_ANSGM_SP_100		0x1
+#define DW_VR_MII_C37_ANSGM_SP_1000		0x2
+#define DW_VR_MII_C37_ANSGM_SP_LNKSTS		BIT(4)
+#define DW_VR_MII_USX_AN_STS_MASK		GENMASK(14, 8)
+
+#define DW_VR_MII_EEE_MCTRL0		0x8006
+#define DW_VR_MII_EEE_LTX_EN			BIT(0)  /* LPI Tx Enable */
+#define DW_VR_MII_EEE_LRX_EN			BIT(1)  /* LPI Rx Enable */
+#define DW_VR_MII_EEE_TX_QUIET_EN		BIT(2)  /* Tx Quiet Enable */
+#define DW_VR_MII_EEE_RX_QUIET_EN		BIT(3)  /* Rx Quiet Enable */
+#define DW_VR_MII_EEE_TX_EN_CTRL		BIT(4)  /* Tx Control Enable */
+#define DW_VR_MII_EEE_RX_EN_CTRL		BIT(7)  /* Rx Control Enable */
+#define DW_VR_MII_EEE_MULT_FACT_100NS		GENMASK(11, 8)
+
+#define DW_VR_MII_EEE_MCTRL1		0x800b
+#define DW_VR_MII_EEE_TRN_LPI		BIT(0)	/* Transparent Mode Enable */
+
+const int nxp_serdes_xpcs_usxgmii_features[] = {
+	ETHTOOL_LINK_MODE_Pause_BIT,
+	ETHTOOL_LINK_MODE_Asym_Pause_BIT,
+	ETHTOOL_LINK_MODE_Autoneg_BIT,
+	ETHTOOL_LINK_MODE_1000baseKX_Full_BIT,
+	ETHTOOL_LINK_MODE_10000baseKX4_Full_BIT,
+	ETHTOOL_LINK_MODE_10000baseKR_Full_BIT,
+	ETHTOOL_LINK_MODE_2500baseX_Full_BIT,
+	__ETHTOOL_LINK_MODE_MASK_NBITS,
+};
+EXPORT_SYMBOL_GPL(nxp_serdes_xpcs_usxgmii_features);
+
+const int nxp_serdes_xpcs_2500basex_features[] = {
+	ETHTOOL_LINK_MODE_Pause_BIT,
+	ETHTOOL_LINK_MODE_Asym_Pause_BIT,
+	ETHTOOL_LINK_MODE_Autoneg_BIT,
+	ETHTOOL_LINK_MODE_2500baseX_Full_BIT,
+	ETHTOOL_LINK_MODE_2500baseT_Full_BIT,
+	__ETHTOOL_LINK_MODE_MASK_NBITS,
+};
+EXPORT_SYMBOL_GPL(nxp_serdes_xpcs_2500basex_features);
+
+const int nxp_serdes_xpcs_sgmii_features[] = {
+	ETHTOOL_LINK_MODE_Pause_BIT,
+	ETHTOOL_LINK_MODE_Asym_Pause_BIT,
+	ETHTOOL_LINK_MODE_Autoneg_BIT,
+	ETHTOOL_LINK_MODE_10baseT_Half_BIT,
+	ETHTOOL_LINK_MODE_10baseT_Full_BIT,
+	ETHTOOL_LINK_MODE_100baseT_Half_BIT,
+	ETHTOOL_LINK_MODE_100baseT_Full_BIT,
+	ETHTOOL_LINK_MODE_1000baseT_Half_BIT,
+	ETHTOOL_LINK_MODE_1000baseT_Full_BIT,
+	__ETHTOOL_LINK_MODE_MASK_NBITS,
+};
+EXPORT_SYMBOL_GPL(nxp_serdes_xpcs_sgmii_features);
+
+static const struct nxp_serdes_xpcs_compat *
+nxp_serdes_xpcs_find_compat(struct nxp_serdes_xpcs *xpcs,
+			    phy_interface_t interface)
+{
+	const struct nxp_serdes_xpcs_compat *compat;
+
+	for (compat = xpcs->desc->compat; compat->supported; compat++)
+		if (compat->interface == interface)
+			return compat;
+
+	return NULL;
+}
+
+static void nxp_serdes_xpcs_get_interfaces(struct nxp_serdes_xpcs *xpcs,
+					   unsigned long *interfaces)
+{
+	const struct nxp_serdes_xpcs_compat *compat;
+
+	for (compat = xpcs->desc->compat; compat->supported; compat++)
+		__set_bit(compat->interface, interfaces);
+}
+
+int nxp_serdes_xpcs_read(struct nxp_serdes_xpcs *xpcs, u8 devad, u32 reg)
+{
+	unsigned int val;
+	int ret;
+
+	ret = regmap_read(xpcs->xpcs_regmap, (devad << 16) | (reg & 0xffff),
+			  &val);
+	if (ret < 0)
+		return ret;
+
+	return val;
+}
+EXPORT_SYMBOL_GPL(nxp_serdes_xpcs_read);
+
+int nxp_serdes_xpcs_write(struct nxp_serdes_xpcs *xpcs, u8 devad, u32 reg,
+			  u16 val)
+{
+	return regmap_write(xpcs->xpcs_regmap, (devad << 16) | (reg & 0xffff),
+			    val);
+}
+EXPORT_SYMBOL_GPL(nxp_serdes_xpcs_write);
+
+int nxp_serdes_xpcs_modify(struct nxp_serdes_xpcs *xpcs, u8 devad, u32 reg,
+			   u16 mask, u16 set)
+{
+	return regmap_update_bits(xpcs->xpcs_regmap,
+				  (devad << 16) | (reg & 0xffff), mask, set);
+}
+EXPORT_SYMBOL_GPL(nxp_serdes_xpcs_modify);
+
+static int nxp_serdes_xpcs_poll_reset(struct nxp_serdes_xpcs *xpcs, int dev)
+{
+	int ret, val;
+
+	ret = read_poll_timeout(nxp_serdes_xpcs_read, val,
+				val < 0 || !(val & BMCR_RESET),
+				50000, 600000, true, xpcs, dev, MII_BMCR);
+	if (val < 0)
+		ret = val;
+
+	return ret;
+}
+
+static int nxp_serdes_xpcs_soft_reset(struct nxp_serdes_xpcs *xpcs,
+				      const struct nxp_serdes_xpcs_compat *compat)
+{
+	int ret, dev;
+
+	switch (compat->an_mode) {
+	case NXP_SERDES_10GBASER:
+		dev = MDIO_MMD_PCS;
+		break;
+	case NXP_SERDES_AN_C37_SGMII:
+	case NXP_SERDES_AN_C37_USXGMII:
+	case NXP_SERDES_2500BASEX:
+		dev = MDIO_MMD_VEND2;
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	ret = nxp_serdes_xpcs_write(xpcs, dev, MII_BMCR, BMCR_RESET);
+	if (ret < 0)
+		return ret;
+
+	return nxp_serdes_xpcs_poll_reset(xpcs, dev);
+}
+
+static int nxp_serdes_xpcs_validate(struct phylink_pcs *pcs,
+				    unsigned long *supported,
+				    const struct phylink_link_state *state)
+{
+	__ETHTOOL_DECLARE_LINK_MODE_MASK(xpcs_supported) = { 0, };
+	const struct nxp_serdes_xpcs_compat *compat;
+	struct nxp_serdes_xpcs *xpcs;
+	int i;
+
+	xpcs = phylink_pcs_to_nxp_serdes_xpcs(pcs);
+	compat = nxp_serdes_xpcs_find_compat(xpcs, state->interface);
+	if (!compat)
+		return -EINVAL;
+
+	for (i = 0; compat->supported[i] != __ETHTOOL_LINK_MODE_MASK_NBITS; i++)
+		set_bit(compat->supported[i], xpcs_supported);
+
+	linkmode_and(supported, supported, xpcs_supported);
+
+	return 0;
+}
+
+static unsigned int nxp_serdes_xpcs_inband_caps(struct phylink_pcs *pcs,
+						phy_interface_t interface)
+{
+	struct nxp_serdes_xpcs *xpcs = phylink_pcs_to_nxp_serdes_xpcs(pcs);
+	const struct nxp_serdes_xpcs_compat *compat;
+
+	compat = nxp_serdes_xpcs_find_compat(xpcs, interface);
+	if (!compat)
+		return 0;
+
+	switch (compat->an_mode) {
+	case NXP_SERDES_AN_C37_USXGMII:
+		return LINK_INBAND_ENABLE;
+
+	case NXP_SERDES_AN_C37_SGMII:
+		return LINK_INBAND_DISABLE | LINK_INBAND_ENABLE;
+
+	case NXP_SERDES_10GBASER:
+	case NXP_SERDES_2500BASEX:
+		return LINK_INBAND_DISABLE;
+
+	default:
+		return 0;
+	}
+}
+
+static void nxp_serdes_xpcs_disable(struct phylink_pcs *pcs)
+{
+	struct nxp_serdes_xpcs *xpcs = phylink_pcs_to_nxp_serdes_xpcs(pcs);
+
+	if (xpcs->desc->reset)
+		xpcs->desc->reset(xpcs);
+}
+
+static void nxp_serdes_xpcs_pre_config(struct phylink_pcs *pcs,
+				       phy_interface_t interface)
+{
+	struct nxp_serdes_xpcs *xpcs = phylink_pcs_to_nxp_serdes_xpcs(pcs);
+	const struct nxp_serdes_xpcs_compat *compat;
+	int ret;
+
+	if (xpcs->interface != interface) {
+		if (interface == PHY_INTERFACE_MODE_SGMII)
+			xpcs->need_reset = true;
+		xpcs->interface = interface;
+	}
+
+	if (xpcs->desc->quirks & NXP_SERDES_QUIRK_NO_POLL)
+		xpcs->pcs.poll = false;
+
+	if (xpcs->desc->quirks & NXP_SERDES_QUIRK_NO_SOFT_RESET)
+		xpcs->need_reset = false;
+
+	if (!xpcs->need_reset)
+		return;
+
+	compat = nxp_serdes_xpcs_find_compat(xpcs, interface);
+	if (!compat) {
+		dev_err(xpcs->dev, "unsupported interface %s\n",
+			phy_modes(interface));
+		return;
+	}
+
+	ret = nxp_serdes_xpcs_soft_reset(xpcs, compat);
+	if (ret)
+		dev_err(xpcs->dev, "soft reset failed: %pe\n", ERR_PTR(ret));
+
+	xpcs->need_reset = false;
+}
+
+static int nxp_serdes_xpcs_config_aneg_c37_sgmii(struct nxp_serdes_xpcs *xpcs,
+						 unsigned int neg_mode)
+{
+	int ret, mdio_ctrl;
+	u16 mask, val;
+
+	/* Disable AN while PCS_MODE and TX_CONFIG are switched to C37 SGMII on
+	 * the MAC side, then re-enable it for in-band mode. MAC_AUTO_SW lets
+	 * the hardware apply the negotiated speed and duplex.
+	 */
+	mdio_ctrl = nxp_serdes_xpcs_read(xpcs, MDIO_MMD_VEND2, MII_BMCR);
+	if (mdio_ctrl < 0)
+		return mdio_ctrl;
+
+	if (mdio_ctrl & BMCR_ANENABLE) {
+		ret = nxp_serdes_xpcs_write(xpcs, MDIO_MMD_VEND2, MII_BMCR,
+					    mdio_ctrl & ~BMCR_ANENABLE);
+		if (ret < 0)
+			return ret;
+	}
+
+	mask = DW_VR_MII_PCS_MODE_MASK | DW_VR_MII_TX_CONFIG_MASK;
+	val = FIELD_PREP(DW_VR_MII_PCS_MODE_MASK,
+			 DW_VR_MII_PCS_MODE_C37_SGMII);
+	val |= FIELD_PREP(DW_VR_MII_TX_CONFIG_MASK,
+			  DW_VR_MII_TX_CONFIG_MAC_SIDE_SGMII);
+
+	ret = nxp_serdes_xpcs_modify(xpcs, MDIO_MMD_VEND2, DW_VR_MII_AN_CTRL,
+				     mask, val);
+	if (ret < 0)
+		return ret;
+
+	val = 0;
+	mask = DW_VR_MII_DIG_CTRL1_2G5_EN | DW_VR_MII_DIG_CTRL1_MAC_AUTO_SW;
+
+	if (neg_mode == PHYLINK_PCS_NEG_INBAND_ENABLED)
+		val = DW_VR_MII_DIG_CTRL1_MAC_AUTO_SW;
+
+	ret = nxp_serdes_xpcs_modify(xpcs, MDIO_MMD_VEND2, DW_VR_MII_DIG_CTRL1,
+				     mask, val);
+	if (ret < 0)
+		return ret;
+
+	if (neg_mode == PHYLINK_PCS_NEG_INBAND_ENABLED)
+		ret = nxp_serdes_xpcs_write(xpcs, MDIO_MMD_VEND2, MII_BMCR,
+					    mdio_ctrl | BMCR_ANENABLE);
+
+	return ret;
+}
+
+static int nxp_serdes_xpcs_config_2500basex(struct nxp_serdes_xpcs *xpcs)
+{
+	int ret;
+
+	ret = nxp_serdes_xpcs_modify(xpcs, MDIO_MMD_VEND2, DW_VR_MII_DIG_CTRL1,
+				     DW_VR_MII_DIG_CTRL1_2G5_EN |
+				     DW_VR_MII_DIG_CTRL1_MAC_AUTO_SW,
+				     DW_VR_MII_DIG_CTRL1_2G5_EN);
+	if (ret < 0)
+		return ret;
+
+	return nxp_serdes_xpcs_modify(xpcs, MDIO_MMD_VEND2, MII_BMCR,
+				      BMCR_ANENABLE | BMCR_SPEED1000 |
+				      BMCR_SPEED100, BMCR_SPEED1000);
+}
+
+static int nxp_serdes_xpcs_config_10gbaser(struct nxp_serdes_xpcs *xpcs)
+{
+	return nxp_serdes_xpcs_modify(xpcs, MDIO_MMD_VEND2, DW_VR_MII_DIG_CTRL1,
+				      DW_VR_MII_DIG_CTRL1_MAC_AUTO_SW, 0);
+}
+
+static int nxp_serdes_xpcs_do_config(struct nxp_serdes_xpcs *xpcs,
+				     phy_interface_t interface,
+				     const unsigned long *advertising,
+				     unsigned int neg_mode)
+{
+	const struct nxp_serdes_xpcs_compat *compat;
+	int ret;
+
+	compat = nxp_serdes_xpcs_find_compat(xpcs, interface);
+	if (!compat)
+		return -ENODEV;
+
+	switch (compat->an_mode) {
+	case NXP_SERDES_10GBASER:
+		ret = nxp_serdes_xpcs_config_10gbaser(xpcs);
+		if (ret)
+			return ret;
+		break;
+	case NXP_SERDES_AN_C37_USXGMII:
+		break;
+	case NXP_SERDES_AN_C37_SGMII:
+		ret = nxp_serdes_xpcs_config_aneg_c37_sgmii(xpcs, neg_mode);
+		if (ret)
+			return ret;
+		break;
+	case NXP_SERDES_2500BASEX:
+		ret = nxp_serdes_xpcs_config_2500basex(xpcs);
+		if (ret)
+			return ret;
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	if (compat->pma_config) {
+		ret = compat->pma_config(xpcs);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+static int nxp_serdes_xpcs_config(struct phylink_pcs *pcs,
+				  unsigned int neg_mode,
+				  phy_interface_t interface,
+				  const unsigned long *advertising,
+				  bool permit_pause_to_mac)
+{
+	struct nxp_serdes_xpcs *xpcs = phylink_pcs_to_nxp_serdes_xpcs(pcs);
+
+	return nxp_serdes_xpcs_do_config(xpcs, interface, advertising, neg_mode);
+}
+
+static int nxp_serdes_xpcs_get_state_c37_sgmii(struct nxp_serdes_xpcs *xpcs,
+					       unsigned int neg_mode,
+					       struct phylink_link_state *state)
+{
+	int ret;
+
+	state->link = false;
+	state->speed = SPEED_UNKNOWN;
+	state->duplex = DUPLEX_UNKNOWN;
+	state->pause = 0;
+
+	/* Until AN completes, the status still holds the previous SGMII word */
+	if (neg_mode == PHYLINK_PCS_NEG_INBAND_ENABLED) {
+		ret = nxp_serdes_xpcs_read(xpcs, MDIO_MMD_VEND2, MII_BMSR);
+		if (ret < 0)
+			return ret;
+
+		if (!(ret & BMSR_ANEGCOMPLETE))
+			return 0;
+	}
+
+	ret = nxp_serdes_xpcs_read(xpcs, MDIO_MMD_VEND2, DW_VR_MII_AN_INTR_STS);
+	if (ret < 0)
+		return ret;
+
+	state->an_complete = ret & DW_VR_MII_AN_STS_C37_ANCMPLT_INTR;
+
+	if (ret & DW_VR_MII_C37_ANSGM_SP_LNKSTS) {
+		int speed_value;
+
+		state->link = true;
+
+		speed_value = FIELD_GET(DW_VR_MII_AN_STS_C37_ANSGM_SP, ret);
+		if (speed_value == DW_VR_MII_C37_ANSGM_SP_1000)
+			state->speed = SPEED_1000;
+		else if (speed_value == DW_VR_MII_C37_ANSGM_SP_100)
+			state->speed = SPEED_100;
+		else
+			state->speed = SPEED_10;
+
+		if (ret & DW_VR_MII_AN_STS_C37_ANSGM_FD)
+			state->duplex = DUPLEX_FULL;
+		else
+			state->duplex = DUPLEX_HALF;
+	} else if (ret == DW_VR_MII_AN_STS_C37_ANCMPLT_INTR) {
+		int speed, duplex;
+
+		state->link = true;
+
+		speed = nxp_serdes_xpcs_read(xpcs, MDIO_MMD_VEND2, MII_BMCR);
+		if (speed < 0)
+			return speed;
+
+		speed &= BMCR_SPEED100 | BMCR_SPEED1000;
+		if (speed == BMCR_SPEED1000)
+			state->speed = SPEED_1000;
+		else if (speed == BMCR_SPEED100)
+			state->speed = SPEED_100;
+		else if (speed == 0)
+			state->speed = SPEED_10;
+
+		duplex = nxp_serdes_xpcs_read(xpcs, MDIO_MMD_VEND2,
+					      MII_ADVERTISE);
+		if (duplex < 0)
+			return duplex;
+
+		if (duplex & ADVERTISE_1000XFULL)
+			state->duplex = DUPLEX_FULL;
+		else if (duplex & ADVERTISE_1000XHALF)
+			state->duplex = DUPLEX_HALF;
+
+		nxp_serdes_xpcs_write(xpcs, MDIO_MMD_VEND2,
+				      DW_VR_MII_AN_INTR_STS, 0);
+	}
+
+	return 0;
+}
+
+static int nxp_serdes_xpcs_get_state_2500basex(struct nxp_serdes_xpcs *xpcs,
+					       struct phylink_link_state *state)
+{
+	int ret;
+
+	ret = nxp_serdes_xpcs_read(xpcs, MDIO_MMD_VEND2, MII_BMSR);
+	if (ret < 0) {
+		state->link = 0;
+		return ret;
+	}
+
+	state->link = !!(ret & BMSR_LSTATUS);
+	if (!state->link)
+		return 0;
+
+	state->speed = SPEED_2500;
+	state->pause |= MLO_PAUSE_TX | MLO_PAUSE_RX;
+	state->duplex = DUPLEX_FULL;
+
+	return 0;
+}
+
+static int nxp_serdes_xpcs_get_state_c37_usxgmii(struct nxp_serdes_xpcs *xpcs,
+						 struct phylink_link_state *state)
+{
+	u16 usxg_an_status;
+	int ret;
+
+	state->link = false;
+	state->speed = SPEED_UNKNOWN;
+	state->duplex = DUPLEX_UNKNOWN;
+	state->pause = 0;
+
+	ret = nxp_serdes_xpcs_read(xpcs, MDIO_MMD_VEND2, DW_VR_MII_AN_INTR_STS);
+	if (ret < 0)
+		return ret;
+
+	usxg_an_status = FIELD_GET(DW_VR_MII_USX_AN_STS_MASK, ret);
+	if (!(usxg_an_status & BIT(6)))
+		return 0;
+
+	state->link = true;
+	state->an_complete = true;
+	phylink_decode_usxgmii_word(state, usxg_an_status << 7);
+
+	return 0;
+}
+
+static void nxp_serdes_xpcs_get_state(struct phylink_pcs *pcs,
+				      unsigned int neg_mode,
+				      struct phylink_link_state *state)
+{
+	struct nxp_serdes_xpcs *xpcs = phylink_pcs_to_nxp_serdes_xpcs(pcs);
+	const struct nxp_serdes_xpcs_compat *compat;
+	int stat1;
+	int ret;
+
+	compat = nxp_serdes_xpcs_find_compat(xpcs, state->interface);
+	if (!compat)
+		return;
+
+	switch (compat->an_mode) {
+	case NXP_SERDES_10GBASER:
+		stat1 = nxp_serdes_xpcs_read(xpcs, MDIO_MMD_PCS, MDIO_STAT1);
+		if (stat1 < 0) {
+			state->link = false;
+			break;
+		}
+
+		if (stat1 & MDIO_STAT1_FAULT)
+			nxp_serdes_xpcs_do_config(xpcs, state->interface, NULL,
+						  PHYLINK_PCS_NEG_NONE);
+
+		state->link = !!(stat1 & MDIO_STAT1_LSTATUS);
+		if (state->link &&
+		    state->interface == PHY_INTERFACE_MODE_10GBASER) {
+			state->speed = SPEED_10000;
+			state->duplex = DUPLEX_FULL;
+		}
+		break;
+	case NXP_SERDES_AN_C37_USXGMII:
+		ret = nxp_serdes_xpcs_get_state_c37_usxgmii(xpcs, state);
+		if (ret)
+			dev_err(xpcs->dev, "%s returned %pe\n",
+				"nxp_serdes_xpcs_get_state_c37_usxgmii",
+				ERR_PTR(ret));
+		break;
+	case NXP_SERDES_AN_C37_SGMII:
+		ret = nxp_serdes_xpcs_get_state_c37_sgmii(xpcs, neg_mode, state);
+		if (ret)
+			dev_err(xpcs->dev, "%s returned %pe\n",
+				"nxp_serdes_xpcs_get_state_c37_sgmii",
+				ERR_PTR(ret));
+		break;
+	case NXP_SERDES_2500BASEX:
+		ret = nxp_serdes_xpcs_get_state_2500basex(xpcs, state);
+		if (ret)
+			dev_err(xpcs->dev, "%s returned %pe\n",
+				"nxp_serdes_xpcs_get_state_2500basex",
+				ERR_PTR(ret));
+		break;
+	default:
+		return;
+	}
+}
+
+static void nxp_serdes_xpcs_link_up_sgmii_1000basex(struct nxp_serdes_xpcs *xpcs,
+						    unsigned int neg_mode,
+						    phy_interface_t interface,
+						    int speed, int duplex)
+{
+	int ret;
+
+	if (neg_mode == PHYLINK_PCS_NEG_INBAND_ENABLED)
+		return;
+
+	if (interface == PHY_INTERFACE_MODE_1000BASEX) {
+		if (speed != SPEED_1000) {
+			dev_err(xpcs->dev, "%s: speed %dMbps not supported\n",
+				__func__, speed);
+			return;
+		}
+
+		if (duplex != DUPLEX_FULL)
+			dev_err(xpcs->dev, "%s: half duplex not supported\n",
+				__func__);
+	}
+
+	ret = nxp_serdes_xpcs_write(xpcs, MDIO_MMD_VEND2, MII_BMCR,
+				    mii_bmcr_encode_fixed(speed, duplex));
+	if (ret)
+		dev_err(xpcs->dev, "%s: write returned %pe\n",
+			__func__, ERR_PTR(ret));
+}
+
+static void nxp_serdes_xpcs_link_up_usxgmii(struct nxp_serdes_xpcs *xpcs,
+					    int speed)
+{
+	int ret, speed_sel;
+
+	switch (speed) {
+	case SPEED_10:
+		speed_sel = DW_USXGMII_10;
+		break;
+	case SPEED_100:
+		speed_sel = DW_USXGMII_100;
+		break;
+	case SPEED_1000:
+		speed_sel = DW_USXGMII_1000;
+		break;
+	case SPEED_2500:
+		speed_sel = DW_USXGMII_2500;
+		break;
+	case SPEED_5000:
+		speed_sel = DW_USXGMII_5000;
+		break;
+	case SPEED_10000:
+		speed_sel = DW_USXGMII_10000;
+		break;
+	default:
+		return;
+	}
+
+	ret = nxp_serdes_xpcs_modify(xpcs, MDIO_MMD_PCS, BIT(15) | MDIO_CTRL1,
+				     DW_USXGMII_EN, DW_USXGMII_EN);
+	if (ret < 0)
+		goto out;
+
+	ret = nxp_serdes_xpcs_modify(xpcs, MDIO_MMD_VEND2, MII_BMCR,
+				     DW_USXGMII_SS_MASK,
+				     speed_sel | DW_USXGMII_FULL);
+	if (ret < 0)
+		goto out;
+
+	ret = nxp_serdes_xpcs_modify(xpcs, MDIO_MMD_PCS, BIT(15) | MDIO_CTRL1,
+				     DW_USXGMII_RST, DW_USXGMII_RST);
+	if (ret < 0)
+		goto out;
+
+	return;
+
+out:
+	dev_err(xpcs->dev, "%s: XPCS access returned %pe\n",
+		__func__, ERR_PTR(ret));
+}
+
+static void nxp_serdes_xpcs_link_up(struct phylink_pcs *pcs,
+				    unsigned int neg_mode,
+				    phy_interface_t interface, int speed,
+				    int duplex)
+{
+	struct nxp_serdes_xpcs *xpcs = phylink_pcs_to_nxp_serdes_xpcs(pcs);
+	const struct nxp_serdes_xpcs_compat *compat;
+	int ret;
+
+	switch (interface) {
+	case PHY_INTERFACE_MODE_USXGMII:
+		nxp_serdes_xpcs_link_up_usxgmii(xpcs, speed);
+		break;
+
+	case PHY_INTERFACE_MODE_SGMII:
+	case PHY_INTERFACE_MODE_1000BASEX:
+		nxp_serdes_xpcs_link_up_sgmii_1000basex(xpcs, neg_mode,
+							interface, speed,
+							duplex);
+		break;
+
+	default:
+		break;
+	}
+
+	compat = nxp_serdes_xpcs_find_compat(xpcs, interface);
+	if (compat && compat->pma_link_up) {
+		ret = compat->pma_link_up(xpcs, speed, duplex);
+		if (ret)
+			dev_err(xpcs->dev, "%s: pma_link_up returned %pe\n",
+				__func__, ERR_PTR(ret));
+	}
+}
+
+static void nxp_serdes_xpcs_an_restart(struct phylink_pcs *pcs)
+{
+	struct nxp_serdes_xpcs *xpcs = phylink_pcs_to_nxp_serdes_xpcs(pcs);
+
+	nxp_serdes_xpcs_modify(xpcs, MDIO_MMD_VEND2, MII_BMCR, BMCR_ANRESTART,
+			       BMCR_ANRESTART);
+}
+
+static int nxp_serdes_xpcs_config_eee(struct nxp_serdes_xpcs *xpcs,
+				      bool enable)
+{
+	u16 mask, val;
+	int ret;
+
+	mask = DW_VR_MII_EEE_LTX_EN | DW_VR_MII_EEE_LRX_EN |
+	       DW_VR_MII_EEE_TX_QUIET_EN | DW_VR_MII_EEE_RX_QUIET_EN |
+	       DW_VR_MII_EEE_TX_EN_CTRL | DW_VR_MII_EEE_RX_EN_CTRL |
+	       DW_VR_MII_EEE_MULT_FACT_100NS;
+
+	if (enable)
+		val = DW_VR_MII_EEE_LTX_EN | DW_VR_MII_EEE_LRX_EN |
+		      DW_VR_MII_EEE_TX_QUIET_EN | DW_VR_MII_EEE_RX_QUIET_EN |
+		      DW_VR_MII_EEE_TX_EN_CTRL | DW_VR_MII_EEE_RX_EN_CTRL |
+		      /* No platform needs a non-default multiply factor */
+		      FIELD_PREP(DW_VR_MII_EEE_MULT_FACT_100NS, 0);
+	else
+		val = 0;
+
+	ret = nxp_serdes_xpcs_modify(xpcs, MDIO_MMD_VEND2,
+				     DW_VR_MII_EEE_MCTRL0, mask, val);
+	if (ret < 0)
+		return ret;
+
+	return nxp_serdes_xpcs_modify(xpcs, MDIO_MMD_VEND2,
+				      DW_VR_MII_EEE_MCTRL1,
+				      DW_VR_MII_EEE_TRN_LPI,
+				      enable ? DW_VR_MII_EEE_TRN_LPI : 0);
+}
+
+static void nxp_serdes_xpcs_disable_eee(struct phylink_pcs *pcs)
+{
+	struct nxp_serdes_xpcs *xpcs = phylink_pcs_to_nxp_serdes_xpcs(pcs);
+
+	if (xpcs->desc->quirks & NXP_SERDES_QUIRK_NO_EEE)
+		return;
+
+	nxp_serdes_xpcs_config_eee(xpcs, false);
+}
+
+static void nxp_serdes_xpcs_enable_eee(struct phylink_pcs *pcs)
+{
+	struct nxp_serdes_xpcs *xpcs = phylink_pcs_to_nxp_serdes_xpcs(pcs);
+
+	if (xpcs->desc->quirks & NXP_SERDES_QUIRK_NO_EEE)
+		return;
+
+	nxp_serdes_xpcs_config_eee(xpcs, true);
+}
+
+static const struct phylink_pcs_ops nxp_serdes_xpcs_phylink_ops = {
+	.pcs_validate = nxp_serdes_xpcs_validate,
+	.pcs_inband_caps = nxp_serdes_xpcs_inband_caps,
+	.pcs_pre_config = nxp_serdes_xpcs_pre_config,
+	.pcs_disable = nxp_serdes_xpcs_disable,
+	.pcs_config = nxp_serdes_xpcs_config,
+	.pcs_get_state = nxp_serdes_xpcs_get_state,
+	.pcs_an_restart = nxp_serdes_xpcs_an_restart,
+	.pcs_link_up = nxp_serdes_xpcs_link_up,
+	.pcs_disable_eee = nxp_serdes_xpcs_disable_eee,
+	.pcs_enable_eee = nxp_serdes_xpcs_enable_eee,
+};
+
+/**
+ * nxp_serdes_xpcs_create() - create a NXP SerDes XPCS phylink PCS
+ * @dev: device the PCS belongs to, used for error reporting
+ * @xpcs_regmap: regmap of the XPCS registers
+ * @phy_regmap: regmap of the XPCS-PHY registers, may be NULL
+ * @desc: revision descriptor, see &struct nxp_serdes_xpcs_desc
+ * @portid: index of the XPCS port, used to select the shared MPLL
+ * @interface: PHY interface mode used for the link
+ *
+ * The regmaps must stay valid until nxp_serdes_xpcs_destroy() has been called.
+ *
+ * Return: a pointer to a &struct phylink_pcs, or an ERR_PTR() on failure.
+ */
+struct phylink_pcs *nxp_serdes_xpcs_create(struct device *dev,
+					   struct regmap *xpcs_regmap,
+					   struct regmap *phy_regmap,
+					   const struct nxp_serdes_xpcs_desc *desc,
+					   u8 portid, phy_interface_t interface)
+{
+	struct nxp_serdes_xpcs *xpcs;
+
+	if (!desc || !desc->compat)
+		return ERR_PTR(-EINVAL);
+
+	xpcs = kzalloc_obj(struct nxp_serdes_xpcs, GFP_KERNEL);
+	if (!xpcs)
+		return ERR_PTR(-ENOMEM);
+
+	xpcs->dev = dev;
+	xpcs->xpcs_regmap = xpcs_regmap;
+	xpcs->phy_regmap = phy_regmap;
+	xpcs->desc = desc;
+	xpcs->pma_id = desc->pma_id;
+	xpcs->portid = portid;
+	xpcs->interface = interface;
+	xpcs->pcs.ops = &nxp_serdes_xpcs_phylink_ops;
+	xpcs->pcs.poll = true;
+	nxp_serdes_xpcs_get_interfaces(xpcs, xpcs->pcs.supported_interfaces);
+	xpcs->need_reset = true;
+
+	return &xpcs->pcs;
+}
+EXPORT_SYMBOL_GPL(nxp_serdes_xpcs_create);
+
+void nxp_serdes_xpcs_destroy(struct phylink_pcs *pcs)
+{
+	struct nxp_serdes_xpcs *xpcs = phylink_pcs_to_nxp_serdes_xpcs(pcs);
+
+	if (!xpcs)
+		return;
+
+	kfree(xpcs);
+}
+EXPORT_SYMBOL_GPL(nxp_serdes_xpcs_destroy);
+
+MODULE_DESCRIPTION("NXP SerDes XPCS shared core");
+MODULE_AUTHOR("Clark Wang <xiaoning.wang@nxp.com>");
+MODULE_LICENSE("GPL");
diff --git a/include/linux/pcs/pcs-nxp-serdes-xpcs.h b/include/linux/pcs/pcs-nxp-serdes-xpcs.h
new file mode 100644
index 000000000000..2579c6b14a61
--- /dev/null
+++ b/include/linux/pcs/pcs-nxp-serdes-xpcs.h
@@ -0,0 +1,100 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * NXP SerDes XPCS shared core
+ * Copyright 2026 NXP
+ */
+
+#ifndef __LINUX_PCS_NXP_SERDES_XPCS_H
+#define __LINUX_PCS_NXP_SERDES_XPCS_H
+
+#include <linux/phy.h>
+#include <linux/phylink.h>
+#include <linux/regmap.h>
+
+/* AN mode values as defined by the DesignWare XPCS */
+enum nxp_serdes_an_mode {
+	NXP_SERDES_AN_C37_SGMII = 2,
+	NXP_SERDES_2500BASEX = 3,
+	NXP_SERDES_10GBASER = 5,
+	NXP_SERDES_AN_C37_USXGMII = 6,
+};
+
+/* The revision runs its own reset sequence, skip the soft reset */
+#define NXP_SERDES_QUIRK_NO_SOFT_RESET	BIT(0)
+/* The revision reports the link state to the MAC, do not poll the PCS */
+#define NXP_SERDES_QUIRK_NO_POLL	BIT(1)
+/* The revision does not implement the VR_MII_EEE_MCTRL0/1 registers */
+#define NXP_SERDES_QUIRK_NO_EEE		BIT(2)
+
+struct nxp_serdes_xpcs;
+
+struct nxp_serdes_xpcs_compat {
+	phy_interface_t interface;
+	const int *supported;
+	enum nxp_serdes_an_mode an_mode;
+	int (*pma_config)(struct nxp_serdes_xpcs *xpcs);
+	int (*pma_link_up)(struct nxp_serdes_xpcs *xpcs, int speed,
+			   int duplex);
+};
+
+/* Description of one SerDes revision, provided by the platform glue */
+struct nxp_serdes_xpcs_desc {
+	const char *name;
+	u32 pma_id;
+	const struct nxp_serdes_xpcs_compat *compat;
+	unsigned int quirks;
+	void (*reset)(struct nxp_serdes_xpcs *xpcs);
+};
+
+struct nxp_serdes_xpcs {
+	struct device *dev;
+	struct regmap *xpcs_regmap;
+	struct regmap *phy_regmap;
+	const struct nxp_serdes_xpcs_desc *desc;
+	struct phylink_pcs pcs;
+	phy_interface_t interface;
+	u32 pma_id;
+	u8 portid;
+	bool need_reset;
+	bool sgmii_internal_ref_clk;
+	void *priv;
+};
+
+#define phylink_pcs_to_nxp_serdes_xpcs(pl_pcs) \
+	container_of((pl_pcs), struct nxp_serdes_xpcs, pcs)
+
+static inline void nxp_serdes_xpcs_set_drvdata(struct nxp_serdes_xpcs *xpcs,
+					       void *priv)
+{
+	xpcs->priv = priv;
+}
+
+static inline void *nxp_serdes_xpcs_get_drvdata(struct nxp_serdes_xpcs *xpcs)
+{
+	return xpcs->priv;
+}
+
+/* Feature sets for struct nxp_serdes_xpcs_compat::supported */
+extern const int nxp_serdes_xpcs_usxgmii_features[];
+extern const int nxp_serdes_xpcs_2500basex_features[];
+extern const int nxp_serdes_xpcs_sgmii_features[];
+
+struct phylink_pcs *nxp_serdes_xpcs_create(struct device *dev,
+					   struct regmap *xpcs_regmap,
+					   struct regmap *phy_regmap,
+					   const struct nxp_serdes_xpcs_desc *desc,
+					   u8 portid,
+					   phy_interface_t interface);
+void nxp_serdes_xpcs_destroy(struct phylink_pcs *pcs);
+
+/* Register accesses are encoded in the regmap as "(devad << 16) | reg", with
+ * "devad" the Clause 45 device address and "reg" the 16-bit register address.
+ * Decoding both fields is up to the regmap of the platform glue.
+ */
+int nxp_serdes_xpcs_read(struct nxp_serdes_xpcs *xpcs, u8 devad, u32 reg);
+int nxp_serdes_xpcs_write(struct nxp_serdes_xpcs *xpcs, u8 devad, u32 reg,
+			  u16 val);
+int nxp_serdes_xpcs_modify(struct nxp_serdes_xpcs *xpcs, u8 devad, u32 reg,
+			   u16 mask, u16 set);
+
+#endif /* __LINUX_PCS_NXP_SERDES_XPCS_H */

-- 
2.55.0

