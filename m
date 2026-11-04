From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 04 Nov 2026 02:22:25 -0500
Subject: [PATCH net-next 2/2] net: stmmac: Add Siflower SF19A2890 glue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sf19a2890-gmac-v1-2-a15965a49574@telaak.dev>
References: <20261104-sf19a2890-gmac-v1-0-a15965a49574@telaak.dev>
In-Reply-To: <20261104-sf19a2890-gmac-v1-0-a15965a49574@telaak.dev>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Giuseppe Cavallaro <peppe.cavallaro@st.com>, 
 Jose Abreu <joabreu@synopsys.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>
Cc: Chuanhong Guo <gch981213@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, linux-mips@vger.kernel.org, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776955; l=7370;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=hGknORcyS13q476eRjeiLb2Zk79yxcwVkAwdDao7hjM=;
 b=UvDJj2152rYIwPD7Z3ui+hy0XsRXl/XtWJZT2wuvysTP0yV80ZWuhg84HkKP6S0iVQDH9jeeM
 yjTs6z8sxxMCAoA0eGxIX/bIje2O84rwfXy7wSm8cTtZtP16aqguaye
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the glue for the DesignWare GMAC of the Siflower SF19A2890. The
interface type is set in the GMAC's configuration block through the
set_phy_intf_sel hook, and so are the RGMII clock delays, which the
MAC adds only where rx-internal-delay-ps or tx-internal-delay-ps is
present.

The delay line's step is not documented. Sweeping each delay over its
whole range with the link at 1000 Mb/s, the working windows repeat every
145 steps, one 8 ns clock period, so a step is about 55 ps; the driver
rounds to the nearest step.

Based on Chuanhong Guo's driver from OpenWrt and his siflower-7.1
branch, which read the delays from a factory flash cell in the delay
line's own units and always applied them. That driver also set
STMMAC_FLAG_HAS_INTEGRATED_PCS, because the core reports a PCS that
does not work in RGMII mode; stmmac now uses the integrated PCS only
for SGMII, and the flag is gone.

Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/net/ethernet/stmicro/stmmac/Kconfig        |  11 ++
 drivers/net/ethernet/stmicro/stmmac/Makefile       |   1 +
 .../net/ethernet/stmicro/stmmac/dwmac-sf19a2890.c  | 158 +++++++++++++++++++++
 3 files changed, 170 insertions(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/Kconfig b/drivers/net/ethernet/stmicro/stmmac/Kconfig
index c6559e749..78efe7859 100644
--- a/drivers/net/ethernet/stmicro/stmmac/Kconfig
+++ b/drivers/net/ethernet/stmicro/stmmac/Kconfig
@@ -201,6 +201,17 @@ config DWMAC_S32
 	  SOCs GMAC ethernet controller, ie. S32G2xx, S32G3xx and
 	  S32R45.
 
+config DWMAC_SF19A2890
+	tristate "Siflower SF19A2890 GMAC support"
+	default MACH_SIFLOWER_MIPS
+	depends on OF && (MACH_SIFLOWER_MIPS || COMPILE_TEST)
+	help
+	  Support for the Ethernet controller of the Siflower SF19A2890 SoC.
+
+	  This selects the SF19A2890 glue layer support for the stmmac
+	  device driver. It sets the interface type and the RGMII clock
+	  delays in the GMAC's configuration block.
+
 config DWMAC_SOCFPGA
 	tristate "SOCFPGA dwmac support"
 	default ARCH_INTEL_SOCFPGA
diff --git a/drivers/net/ethernet/stmicro/stmmac/Makefile b/drivers/net/ethernet/stmicro/stmmac/Makefile
index b16a456b7..9330de094 100644
--- a/drivers/net/ethernet/stmicro/stmmac/Makefile
+++ b/drivers/net/ethernet/stmicro/stmmac/Makefile
@@ -26,6 +26,7 @@ obj-$(CONFIG_DWMAC_RENESAS_GBETH) += dwmac-renesas-gbeth.o
 obj-$(CONFIG_DWMAC_ROCKCHIP)	+= dwmac-rk.o
 obj-$(CONFIG_DWMAC_RZN1)	+= dwmac-rzn1.o
 obj-$(CONFIG_DWMAC_S32)		+= dwmac-s32.o
+obj-$(CONFIG_DWMAC_SF19A2890)	+= dwmac-sf19a2890.o
 obj-$(CONFIG_DWMAC_SOCFPGA)	+= dwmac-altr-socfpga.o
 obj-$(CONFIG_DWMAC_SOPHGO)	+= dwmac-sophgo.o
 obj-$(CONFIG_DWMAC_SPACEMIT)	+= dwmac-spacemit.o
diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sf19a2890.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sf19a2890.c
new file mode 100644
index 000000000..41bfe7a4a
--- /dev/null
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-sf19a2890.c
@@ -0,0 +1,158 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Siflower SF19A2890 GMAC glue
+ *
+ * The SF19A2890 has a DWMAC 3.73a. Its interface type and RGMII clock
+ * delays are set in a register block of their own.
+ *
+ * Based on the driver by Chuanhong Guo <gch981213@gmail.com>.
+ */
+
+#include <linux/bitfield.h>
+#include <linux/clk.h>
+#include <linux/io.h>
+#include <linux/math.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/platform_device.h>
+#include <linux/stmmac.h>
+
+#include "stmmac_platform.h"
+
+/* GMAC configuration block */
+#define SF19A2890_GMAC_MISC		0x0
+#define  SF19A2890_PHY_INTF_SEL		GENMASK(2, 0)
+#define SF19A2890_GMAC_TX_DELAY		0x4
+#define SF19A2890_GMAC_RX_DELAY		0x8
+#define SF19A2890_GMAC_RX_DELAY_EN	0xc
+#define  SF19A2890_DELAY_MAX		0xff
+
+/*
+ * The delay line's step is not documented. Sweeping a full 8 ns RGMII clock
+ * period at 1000 Mb/s takes 145 steps, so one step is about 55 ps.
+ */
+#define SF19A2890_DELAY_STEP_PS		55
+
+struct sf19a2890_gmac {
+	struct device *dev;
+	void __iomem *cfg;
+};
+
+static int sf19a2890_gmac_set_phy_intf_sel(void *bsp_priv, u8 phy_intf_sel)
+{
+	struct sf19a2890_gmac *gmac = bsp_priv;
+	u32 val;
+
+	if (phy_intf_sel != PHY_INTF_SEL_GMII_MII &&
+	    phy_intf_sel != PHY_INTF_SEL_RGMII &&
+	    phy_intf_sel != PHY_INTF_SEL_RMII)
+		return -EINVAL;
+
+	val = readl(gmac->cfg + SF19A2890_GMAC_MISC);
+	val &= ~SF19A2890_PHY_INTF_SEL;
+	val |= FIELD_PREP(SF19A2890_PHY_INTF_SEL, phy_intf_sel);
+	writel(val, gmac->cfg + SF19A2890_GMAC_MISC);
+
+	return 0;
+}
+
+static int sf19a2890_gmac_get_delay(struct sf19a2890_gmac *gmac,
+				    const char *prop, u32 *steps)
+{
+	u32 ps;
+
+	*steps = 0;
+	if (of_property_read_u32(gmac->dev->of_node, prop, &ps))
+		return 0;
+
+	*steps = DIV_ROUND_CLOSEST(ps, SF19A2890_DELAY_STEP_PS);
+	if (*steps > SF19A2890_DELAY_MAX)
+		return dev_err_probe(gmac->dev, -EINVAL,
+				     "%s too large: %u\n", prop, ps);
+
+	return 0;
+}
+
+/* The MAC adds an RGMII delay only where the device tree asks for one */
+static int sf19a2890_gmac_set_delays(struct sf19a2890_gmac *gmac)
+{
+	u32 tx, rx;
+	int ret;
+
+	ret = sf19a2890_gmac_get_delay(gmac, "tx-internal-delay-ps", &tx);
+	if (ret)
+		return ret;
+
+	ret = sf19a2890_gmac_get_delay(gmac, "rx-internal-delay-ps", &rx);
+	if (ret)
+		return ret;
+
+	writel(tx, gmac->cfg + SF19A2890_GMAC_TX_DELAY);
+	writel(rx, gmac->cfg + SF19A2890_GMAC_RX_DELAY);
+	writel(!!rx, gmac->cfg + SF19A2890_GMAC_RX_DELAY_EN);
+
+	return 0;
+}
+
+static int sf19a2890_gmac_probe(struct platform_device *pdev)
+{
+	struct plat_stmmacenet_data *plat_dat;
+	struct stmmac_resources stmmac_res;
+	struct device *dev = &pdev->dev;
+	struct sf19a2890_gmac *gmac;
+	struct clk *clk;
+	int ret;
+
+	gmac = devm_kzalloc(dev, sizeof(*gmac), GFP_KERNEL);
+	if (!gmac)
+		return -ENOMEM;
+
+	gmac->dev = dev;
+
+	gmac->cfg = devm_platform_ioremap_resource(pdev, 1);
+	if (IS_ERR(gmac->cfg))
+		return dev_err_probe(dev, PTR_ERR(gmac->cfg),
+				     "failed to map the configuration block\n");
+
+	clk = devm_clk_get_enabled(dev, "byp_ref");
+	if (IS_ERR(clk))
+		return dev_err_probe(dev, PTR_ERR(clk),
+				     "failed to enable the byp_ref clock\n");
+
+	ret = sf19a2890_gmac_set_delays(gmac);
+	if (ret)
+		return ret;
+
+	ret = stmmac_get_platform_resources(pdev, &stmmac_res);
+	if (ret)
+		return ret;
+
+	plat_dat = devm_stmmac_probe_config_dt(pdev, stmmac_res.mac);
+	if (IS_ERR(plat_dat))
+		return PTR_ERR(plat_dat);
+
+	plat_dat->bsp_priv = gmac;
+	plat_dat->set_phy_intf_sel = sf19a2890_gmac_set_phy_intf_sel;
+
+	return stmmac_dvr_probe(dev, plat_dat, &stmmac_res);
+}
+
+static const struct of_device_id sf19a2890_gmac_match[] = {
+	{ .compatible = "siflower,sf19a2890-gmac" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, sf19a2890_gmac_match);
+
+static struct platform_driver sf19a2890_gmac_driver = {
+	.probe = sf19a2890_gmac_probe,
+	.remove = stmmac_pltfr_remove,
+	.driver = {
+		.name = "sf19a2890-gmac",
+		.pm = &stmmac_pltfr_pm_ops,
+		.of_match_table = sf19a2890_gmac_match,
+	},
+};
+module_platform_driver(sf19a2890_gmac_driver);
+
+MODULE_DESCRIPTION("Siflower SF19A2890 GMAC glue");
+MODULE_LICENSE("GPL");

-- 
Git-155)

