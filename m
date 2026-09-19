From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Sat, 19 Sep 2026 08:54:34 +0200
Subject: [PATCH RFC v3 06/12] phy: freescale: s32g: Add SerDes subsystem
 PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-s32g_serdes-v3-6-9d68868c1e89@oss.nxp.com>
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
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>, 
 Alexandru-Catalin Ionita <alexandru-catalin.ionita@nxp.com>, 
 Ionut Vicovan <Ionut.Vicovan@nxp.com>, 
 Bogdan Roman <bogdan-gabriel.roman@nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789800879; l=33635;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=EA4TjOULRIuXKKg9xGx/555pCpYvzChROqnpPxi+c/o=;
 b=uAoc/jM+Eg6aj09Oj3eblb69NBflRNLZLyRlksTt3vftpOmW8Q5kKG+6hK6HlFD7MBxAcSR/n
 DEGet1CmgYhD3364tUDtG3qNqMb/Df4zrPVlhAGsEwuwlDmqgsIih0V
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Vincent Guittot <vincent.guittot@linaro.org>

The S32G SoC family includes two SerDes subsystems, each made of one
PCIe controller, two XPCS and a shared 2-lane combo PHY. The lanes can
be configured to carry PCIe and/or SGMII.

Add the SerDes subsystem PHY driver: the PCIe PHY, the shared combo-PHY
bring-up, and the setup of the XPCS instances added by the previous
patch. The MAC obtains its phylink PCS through
s32g_serdes_pcs_create(), which also creates a device link so the MAC
is unbound and suspended before the SerDes it depends on.

The SS_RW_REG_0[SUBSYS_MODE] value is not taken from the devicetree.
It is derived at probe from the per-lane child nodes - the lane
function and, for an SGMII lane, the XPCS instance it feeds. Each
working mode in scope has a unique lane mux, so the first match is the
only match. The reference-clock rate is validated against the derived
mode; it is never used to select it. Per-lane link speed is a runtime
property and does not influence mode selection.

After the subsystem reset is released the PHY needs up to 5.2 ms to
become operational (MPLL_STATE). Poll it before any further PHY or
XPCS PMA access, on every working mode - relying on incidental timing
made the init sequence fragile.

SUBMODE_MASK is GENMASK(2, 0): valid SUBSYS_MODE values are 0 to 4 and
the vendor driver masks the field with 0x7.

Tested on an S32G3-VNP-RDB3 board in both modes the driver derives from
the lane children: mode 1 (PCIe on lane 0, XPCS0 on lane 1) and mode 3
(XPCS0 on lane 0, XPCS1 on lane 1). In mode 1 both consumers of the
shared subsystem are up at the same time - both PCIe root complexes
enumerate and GMAC0 links at 1G over SGMII. Mode 3 routes both lanes to
the XPCS instances, so it has no PCIe consumer.

Signed-off-by: Vincent Guittot <vincent.guittot@linaro.org>
Co-developed-by: Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>
Signed-off-by: Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>
Co-developed-by: Alexandru-Catalin Ionita <alexandru-catalin.ionita@nxp.com>
Signed-off-by: Alexandru-Catalin Ionita <alexandru-catalin.ionita@nxp.com>
Co-developed-by: Ghennadi Procopciuc <ghennadi.procopciuc@nxp.com>
Signed-off-by: Ghennadi Procopciuc <ghennadi.procopciuc@nxp.com>
Co-developed-by: Ionut Vicovan <Ionut.Vicovan@nxp.com>
Signed-off-by: Ionut Vicovan <Ionut.Vicovan@nxp.com>
Co-developed-by: Bogdan Roman <bogdan-gabriel.roman@nxp.com>
Signed-off-by: Bogdan Roman <bogdan-gabriel.roman@nxp.com>
Co-developed-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 drivers/phy/freescale/Kconfig               |    9 +
 drivers/phy/freescale/Makefile              |    1 +
 drivers/phy/freescale/phy-nxp-s32g-serdes.c | 1057 +++++++++++++++++++++++++++
 include/linux/phy/nxp-s32g-serdes.h         |   25 +
 4 files changed, 1092 insertions(+)

diff --git a/drivers/phy/freescale/Kconfig b/drivers/phy/freescale/Kconfig
index 7557b624be8f..59a86597eaa0 100644
--- a/drivers/phy/freescale/Kconfig
+++ b/drivers/phy/freescale/Kconfig
@@ -77,3 +77,12 @@ config PHY_FSL_LYNX_28G
 	  found on NXP's Layerscape platforms such as LX2160A.
 	  Used to change the protocol running on SerDes lanes at runtime.
 	  Only useful for a restricted set of Ethernet protocols.
+
+config PHY_S32G_SERDES
+	tristate "NXP S32G SERDES support"
+	depends on ARCH_S32 || COMPILE_TEST
+	depends on PCS_NXP_S32G_XPCS
+	select GENERIC_PHY
+	help
+	  This option enables support for S32G SerDes PHY used for
+	  PCIe & Ethernet
diff --git a/drivers/phy/freescale/Makefile b/drivers/phy/freescale/Makefile
index 5b0e180d6972..1a0aec790917 100644
--- a/drivers/phy/freescale/Makefile
+++ b/drivers/phy/freescale/Makefile
@@ -8,3 +8,4 @@ obj-$(CONFIG_PHY_FSL_LYNX_CORE)		+= phy-fsl-lynx-core.o
 obj-$(CONFIG_PHY_FSL_LYNX_10G)		+= phy-fsl-lynx-10g.o
 obj-$(CONFIG_PHY_FSL_LYNX_28G)		+= phy-fsl-lynx-28g.o
 obj-$(CONFIG_PHY_FSL_SAMSUNG_HDMI_PHY)	+= phy-fsl-samsung-hdmi.o
+obj-$(CONFIG_PHY_S32G_SERDES)		+= phy-nxp-s32g-serdes.o
diff --git a/drivers/phy/freescale/phy-nxp-s32g-serdes.c b/drivers/phy/freescale/phy-nxp-s32g-serdes.c
new file mode 100644
index 000000000000..e81878137f2e
--- /dev/null
+++ b/drivers/phy/freescale/phy-nxp-s32g-serdes.c
@@ -0,0 +1,1057 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * SerDes driver for S32G SoCs
+ *
+ * Copyright 2021-2026 NXP
+ */
+
+#include <linux/bitfield.h>
+#include <linux/clk.h>
+#include <linux/delay.h>
+#include <linux/iopoll.h>
+#include <linux/module.h>
+#include <linux/of_platform.h>
+#include <linux/pcs/pcs-nxp-s32g-xpcs.h>
+#include <linux/phy/nxp-s32g-serdes.h>
+#include <linux/phy/phy.h>
+#include <linux/platform_device.h>
+#include <linux/reset.h>
+#include <linux/units.h>
+
+#define S32G_SERDES_XPCS_MAX			2
+
+#define EXTERNAL_CLK_NAME			"ext"
+#define INTERNAL_CLK_NAME			"ref"
+
+/* Serdes Sub system registers */
+
+#define S32G_PCIE_PHY_GEN_CTRL			0x0
+#define  REF_USE_PAD				BIT(17)
+#define  RX_SRIS_MODE				BIT(9)
+
+#define S32G_PCIE_PHY_MPLLA_CTRL		0x10
+#define  MPLL_STATE				BIT(30)
+
+#define S32G_SS_RW_REG_0			0xF0
+#define  SUBMODE_MASK				GENMASK(2, 0)
+#define  CLKEN_MASK				BIT(23)
+#define  PHY0_CR_PARA_SEL			BIT(9)
+
+/* PCIe phy subsystem registers */
+
+#define S32G_PHY_REG_ADDR			0x0
+#define  PHY_REG_EN				BIT(31)
+
+#define S32G_PHY_REG_DATA			0x4
+
+#define RAWLANE0_DIG_PCS_XF_RX_EQ_DELTA_IQ_OVRD_IN	0x3019
+#define RAWLANE1_DIG_PCS_XF_RX_EQ_DELTA_IQ_OVRD_IN	0x3119
+
+/*
+ * DesignWare PCIe PHY reference-clock architecture, passed as the submode
+ * to phy_set_mode_ext(phy, PHY_MODE_PCIE, submode).
+ *
+ * These describe how the reference clock is distributed and whether spread
+ * spectrum is used, a different axis from the role submodes in
+ * include/linux/phy/pcie.h (PHY_MODE_PCIE_RC/_EP/_BIFURCATION, 20..22), which
+ * they do not overlap. Kept driver-private until a second driver needs a
+ * non-default architecture; pcie-nxp-s32g.c always asks for CRNS.
+ */
+enum pcie_phy_mode {
+	CRNS = 0, /* Common Reference Clock, No Spread Spectrum */
+	CRSS = 1, /* Common Reference Clock, Spread Spectrum */
+	SRNS = 2, /* Separate Reference Clock, No Spread Spectrum */
+	SRIS = 3  /* Separate Reference Clock, Spread Spectrum */
+};
+
+/*
+ * SS_RW_REG_0[SUBSYS_MODE] holds the reference-manual "Mode N" number. It is
+ * not in the devicetree: it is derived from the per-lane child nodes (lane
+ * function + XPCS instance). The reference clock is validated against the
+ * result, never used to select it.
+ */
+
+enum s32g_lane_fn {
+	S32G_LANE_UNUSED = 0,
+	S32G_LANE_PCIE,
+	S32G_LANE_XPCS,
+};
+
+struct s32g_lane_desc {
+	enum s32g_lane_fn fn;
+	u32 xpcs_instance;	/* valid iff fn == S32G_LANE_XPCS */
+};
+
+struct s32g_serdes_mode {
+	u32 submode;			/* SS_RW_REG_0[SUBSYS_MODE] value */
+	struct s32g_lane_desc lane[2];
+	unsigned long refclk[2];	/* permitted reference clock rates (Hz), 0-terminated */
+};
+
+struct s32g_serdes_soc_data {
+	const struct s32g_serdes_mode *modes;
+	unsigned int n_modes;
+};
+
+#define S32G_LANE_IS_PCIE	{ .fn = S32G_LANE_PCIE }
+#define S32G_LANE_IS_XPCS(i)	{ .fn = S32G_LANE_XPCS, .xpcs_instance = (i) }
+
+#define S32G_REFCLK_100MHZ	(100 * HZ_PER_MHZ)
+#define S32G_REFCLK_125MHZ	(125 * HZ_PER_MHZ)
+
+/*
+ * Supported working modes (S32G2/S32G3, 1G). Each row has a unique lane mux.
+ * PCIe needs a 100 MHz reference, so modes 0/1/2 take 100 MHz only; the
+ * dual-XPCS mode 3 takes 100 or 125 MHz.
+ */
+static const struct s32g_serdes_mode s32g_serdes_modes[] = {
+	{ 0, { S32G_LANE_IS_PCIE,    S32G_LANE_IS_PCIE    },
+	  { S32G_REFCLK_100MHZ } },
+	{ 1, { S32G_LANE_IS_PCIE,    S32G_LANE_IS_XPCS(0) },
+	  { S32G_REFCLK_100MHZ } },
+	{ 2, { S32G_LANE_IS_PCIE,    S32G_LANE_IS_XPCS(1) },
+	  { S32G_REFCLK_100MHZ } },
+	{ 3, { S32G_LANE_IS_XPCS(0), S32G_LANE_IS_XPCS(1) },
+	  { S32G_REFCLK_100MHZ, S32G_REFCLK_125MHZ } },
+};
+
+/*
+ * S32G2 and S32G3 share this table for now but keep distinct compatibles with
+ * no fallback: the full RM mode tables differ per SoC and per SerDes instance
+ * (only S32G3 SerDes_1 has the 3.125G dual-XPCS mode 4) and will diverge once
+ * 2500BASE-X lands.
+ */
+static const struct s32g_serdes_soc_data s32g2_serdes_soc_data = {
+	.modes = s32g_serdes_modes,
+	.n_modes = ARRAY_SIZE(s32g_serdes_modes),
+};
+
+static const struct s32g_serdes_soc_data s32g3_serdes_soc_data = {
+	.modes = s32g_serdes_modes,
+	.n_modes = ARRAY_SIZE(s32g_serdes_modes),
+};
+
+struct s32g_serdes_ctrl {
+	void __iomem *ss_base;
+	struct reset_control *rst;
+	struct clk_bulk_data *clks;
+	int nclks;
+	u32 ss_mode;
+	unsigned long ref_clk_rate;
+	bool ext_clk;
+};
+
+struct s32g_pcie_ctrl {
+	void __iomem *phy_base;
+	struct reset_control *rst;
+	struct phy *phy;
+	enum pcie_phy_mode phy_mode;
+	bool powered_on;
+};
+
+struct s32g_xpcs_ctrl {
+	struct s32g_xpcs *phys[2];	/* indexed by XPCS instance */
+	void __iomem *base[2];		/* xpcs0 / xpcs1 register blocks */
+};
+
+struct s32g_serdes {
+	struct s32g_serdes_ctrl ctrl;
+	struct s32g_pcie_ctrl pcie;
+	struct s32g_xpcs_ctrl xpcs;
+	struct s32g_lane_desc lane[2];
+	const struct s32g_serdes_soc_data *soc_data;
+	struct device *dev;
+};
+
+/* PCIe phy subsystem */
+
+#define S32G_SERDES_PCIE_FREQ			(100 * HZ_PER_MHZ)
+
+static int s32g_pcie_check_clk(struct s32g_serdes *serdes)
+{
+	struct s32g_serdes_ctrl *sctrl = &serdes->ctrl;
+	unsigned long rate = sctrl->ref_clk_rate;
+
+	if (rate != S32G_SERDES_PCIE_FREQ) {
+		dev_err(serdes->dev, "PCIe PHY cannot operate at %lu HZ\n", rate);
+		return -EINVAL;
+	}
+
+	return 0;
+}
+
+/* Serdes RM says the PHY is operational within 3.4 to 5.2 ms after reset
+ * release, depending on the reference clock (MPLL_STATE = 1).
+ */
+#define S32G_SERDES_LOCK_TIMEOUT_US	(10 * USEC_PER_MSEC)
+#define S32G_SERDES_LOCK_SLEEP_US	50
+
+/*
+ * MPLL_STATE signals "PHY operational" after the subsystem reset is released.
+ * It must be observed before any PHY or XPCS PMA access in every mode, not
+ * just on the PCIe path: skipping it on the XPCS-only modes left init
+ * dependent on incidental timing, and a printk between reset release and XPCS
+ * setup was enough to break it.
+ */
+static int s32g_serdes_wait_phy_operational(struct s32g_serdes *serdes)
+{
+	void __iomem *reg = serdes->ctrl.ss_base + S32G_PCIE_PHY_MPLLA_CTRL;
+	u32 val;
+	int ret;
+
+	ret = readl_poll_timeout(reg, val, (val & MPLL_STATE),
+				 S32G_SERDES_LOCK_SLEEP_US,
+				 S32G_SERDES_LOCK_TIMEOUT_US);
+	if (ret)
+		dev_err(serdes->dev, "SerDes PHY not operational\n");
+
+	return ret;
+}
+
+static int s32g_pcie_phy_power_on_common(struct s32g_serdes *serdes)
+{
+	struct s32g_serdes_ctrl *sctrl = &serdes->ctrl;
+	struct s32g_pcie_ctrl *pcie = &serdes->pcie;
+	u32 reg;
+	int ret;
+
+	ret = s32g_pcie_check_clk(serdes);
+	if (ret)
+		return ret;
+
+	reg = readl(sctrl->ss_base + S32G_PCIE_PHY_GEN_CTRL);
+
+	if (pcie->phy_mode == SRIS)
+		reg |= RX_SRIS_MODE;
+	else
+		reg &= ~RX_SRIS_MODE;
+
+	if (sctrl->ext_clk)
+		reg |= REF_USE_PAD;
+	else
+		reg &= ~REF_USE_PAD;
+
+	writel(reg, sctrl->ss_base + S32G_PCIE_PHY_GEN_CTRL);
+
+	ret = s32g_serdes_wait_phy_operational(serdes);
+	if (ret)
+		return ret;
+
+	/* Set PHY register access to CR interface */
+	reg = readl(sctrl->ss_base + S32G_SS_RW_REG_0);
+	reg |=  PHY0_CR_PARA_SEL;
+	writel(reg, sctrl->ss_base + S32G_SS_RW_REG_0);
+
+	return 0;
+}
+
+static void s32g_pcie_phy_write(struct s32g_serdes *serdes, u32 reg, u32 val)
+{
+	writel(PHY_REG_EN, serdes->pcie.phy_base + S32G_PHY_REG_ADDR);
+	writel(reg | PHY_REG_EN, serdes->pcie.phy_base + S32G_PHY_REG_ADDR);
+	usleep_range(100, 110);
+	writel(val, serdes->pcie.phy_base + S32G_PHY_REG_DATA);
+	usleep_range(100, 110);
+	writel(0, serdes->pcie.phy_base + S32G_PHY_REG_ADDR);
+}
+
+static int s32g_pcie_phy_power_on(struct s32g_serdes *serdes)
+{
+	struct s32g_pcie_ctrl *pcie = &serdes->pcie;
+	struct s32g_serdes_ctrl *ctrl = &serdes->ctrl;
+	u32 iq_ovrd_in;
+	int ret;
+
+	ret = s32g_pcie_phy_power_on_common(serdes);
+	if (ret)
+		return ret;
+
+	/* RX_EQ_DELTA_IQ_OVRD enable and override value for PCIe lanes */
+	iq_ovrd_in = RAWLANE0_DIG_PCS_XF_RX_EQ_DELTA_IQ_OVRD_IN;
+
+	s32g_pcie_phy_write(serdes, iq_ovrd_in, 0x3);
+	s32g_pcie_phy_write(serdes, iq_ovrd_in, 0x13);
+
+	if (ctrl->ss_mode == 0) {
+		iq_ovrd_in = RAWLANE1_DIG_PCS_XF_RX_EQ_DELTA_IQ_OVRD_IN;
+
+		s32g_pcie_phy_write(serdes, iq_ovrd_in, 0x3);
+		s32g_pcie_phy_write(serdes, iq_ovrd_in, 0x13);
+	}
+
+	pcie->powered_on = true;
+
+	return 0;
+}
+
+/* PCIe phy ops function */
+
+static int s32g_serdes_phy_power_on(struct phy *p)
+{
+	struct s32g_serdes *serdes = phy_get_drvdata(p);
+
+	return s32g_pcie_phy_power_on(serdes);
+}
+
+static int s32g_serdes_phy_power_off(struct phy *p)
+{
+	struct s32g_serdes *serdes = phy_get_drvdata(p);
+
+	serdes->pcie.powered_on = false;
+
+	return 0;
+}
+
+static inline bool is_pcie_phy_mode_valid(int mode)
+{
+	switch (mode) {
+	case CRNS:
+	case CRSS:
+	case SRNS:
+	case SRIS:
+		return true;
+	default:
+		return false;
+	}
+}
+
+static int s32g_serdes_phy_set_mode_ext(struct phy *p,
+					enum phy_mode mode, int submode)
+{
+	struct s32g_serdes *serdes = phy_get_drvdata(p);
+
+	if (mode != PHY_MODE_PCIE)
+		return -EINVAL;
+
+	if (!is_pcie_phy_mode_valid(submode))
+		return -EINVAL;
+
+	/*
+	 * Spread-spectrum and common-reference clocking both need an
+	 * external shared reference, and neither may be combined with an
+	 * SGMII lane on the same subsystem.
+	 */
+	if ((submode == CRSS || submode == SRIS) &&
+	    (serdes->ctrl.ss_mode != 0 || !serdes->ctrl.ext_clk))
+		return -EINVAL;
+
+	if (serdes->pcie.powered_on)
+		dev_warn(serdes->dev, "The phy is already powered on.\n");
+
+	serdes->pcie.phy_mode = submode;
+
+	return 0;
+}
+
+static const struct phy_ops serdes_pcie_ops = {
+	.power_on	= s32g_serdes_phy_power_on,
+	.power_off	= s32g_serdes_phy_power_off,
+	.set_mode	= s32g_serdes_phy_set_mode_ext,
+};
+
+static struct phy *s32g_serdes_phy_xlate(struct device *dev,
+					 const struct of_phandle_args *args)
+{
+	struct s32g_serdes *serdes;
+
+	serdes = dev_get_drvdata(dev);
+	if (!serdes)
+		return ERR_PTR(-EINVAL);
+
+	return serdes->pcie.phy;
+}
+
+/* XPCS subsystem */
+
+static int s32g_serdes_xpcs_setup(struct s32g_serdes *serdes, u32 instance)
+{
+	struct s32g_serdes_ctrl *ctrl = &serdes->ctrl;
+	struct s32g_xpcs_ctrl *xpcs_ctrl = &serdes->xpcs;
+	enum s32g_xpcs_shared shared = S32G_NOT_SHARED;
+	struct device *dev = serdes->dev;
+	struct s32g_xpcs *xpcs;
+
+	/*
+	 * In the PCIe + SGMII modes the XPCS shares the combo PHY with the
+	 * PCIe lane. The 2.5G shared variant (S32G_PCIE_XPCS_2G5) is selected at
+	 * run time and is not wired up yet.
+	 */
+	if (ctrl->ss_mode == 1 || ctrl->ss_mode == 2)
+		shared = S32G_PCIE_XPCS_1G;
+
+	xpcs = s32g_xpcs_create(dev, instance, xpcs_ctrl->base[instance],
+				ctrl->ext_clk, ctrl->ref_clk_rate, shared);
+	if (IS_ERR(xpcs))
+		return PTR_ERR(xpcs);
+
+	xpcs_ctrl->phys[instance] = xpcs;
+
+	return 0;
+}
+
+static int s32g_serdes_init_xpcs(struct s32g_serdes *serdes)
+{
+	struct s32g_serdes_ctrl *ctrl = &serdes->ctrl;
+	struct s32g_xpcs_ctrl *xpcs = &serdes->xpcs;
+	struct s32g_xpcs *order[2];
+	size_t i;
+	int ret;
+
+	/*
+	 * Mode 3 initialises XPCS1 before XPCS0. Carried over from the vendor
+	 * driver and undocumented in the RM. Do not reorder.
+	 */
+	switch (ctrl->ss_mode) {
+	case 0:
+		return 0;
+	case 1:
+		order[0] = xpcs->phys[0];
+		order[1] = NULL;
+		break;
+	case 2:
+		order[0] = xpcs->phys[1];
+		order[1] = NULL;
+		break;
+	case 3:
+		order[0] = xpcs->phys[1];
+		order[1] = xpcs->phys[0];
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	for (i = 0; i < ARRAY_SIZE(order); i++) {
+		if (!order[i])
+			continue;
+
+		ret = s32g_xpcs_init_plls(order[i]);
+		if (ret)
+			return ret;
+	}
+
+	for (i = 0; i < ARRAY_SIZE(order); i++) {
+		if (!order[i])
+			continue;
+
+		s32g_xpcs_vreset(order[i]);
+	}
+
+	for (i = 0; i < ARRAY_SIZE(order); i++) {
+		if (!order[i])
+			continue;
+
+		ret = s32g_xpcs_wait_vreset(order[i]);
+		if (ret)
+			return ret;
+
+		ret = s32g_xpcs_reset_rx(order[i]);
+		if (ret)
+			return ret;
+
+		s32g_xpcs_disable_an(order[i]);
+	}
+
+	return 0;
+}
+
+/* Serdes subsystem */
+
+static int s32g_serdes_assert_reset(struct s32g_serdes *serdes)
+{
+	struct device *dev = serdes->dev;
+	int ret;
+
+	ret = reset_control_assert(serdes->pcie.rst);
+	if (ret) {
+		dev_err(dev, "Failed to assert PCIE reset: %d\n", ret);
+		return ret;
+	}
+
+	ret = reset_control_assert(serdes->ctrl.rst);
+	if (ret) {
+		dev_err(dev, "Failed to assert SerDes reset: %d\n", ret);
+		return ret;
+	}
+
+	return 0;
+}
+
+static int s32g_serdes_deassert_reset(struct s32g_serdes *serdes)
+{
+	struct device *dev = serdes->dev;
+	int ret;
+
+	ret = reset_control_deassert(serdes->pcie.rst);
+	if (ret) {
+		dev_err(dev, "Failed to deassert PCIE reset: %d\n", ret);
+		return ret;
+	}
+
+	ret = reset_control_deassert(serdes->ctrl.rst);
+	if (ret) {
+		dev_err(dev, "Failed to deassert SerDes reset: %d\n", ret);
+		return ret;
+	}
+
+	return 0;
+}
+
+static bool s32g_serdes_lane_matches(const struct s32g_lane_desc *mode_lane,
+				     const struct s32g_lane_desc *req_lane)
+{
+	if (mode_lane->fn != req_lane->fn)
+		return false;
+
+	if (mode_lane->fn == S32G_LANE_XPCS)
+		return mode_lane->xpcs_instance == req_lane->xpcs_instance;
+
+	return true;
+}
+
+static const char *s32g_lane_fn_str(const struct s32g_lane_desc *lane)
+{
+	switch (lane->fn) {
+	case S32G_LANE_PCIE:
+		return "PCIe";
+	case S32G_LANE_XPCS:
+		return lane->xpcs_instance ? "XPCS1" : "XPCS0";
+	default:
+		return "unused";
+	}
+}
+
+static int s32g_serdes_derive_mode(struct s32g_serdes *serdes)
+{
+	const struct s32g_serdes_mode *match = NULL;
+	unsigned int i;
+	bool refclk_ok = false;
+
+	for (i = 0; i < serdes->soc_data->n_modes; i++) {
+		const struct s32g_serdes_mode *m = &serdes->soc_data->modes[i];
+
+		if (s32g_serdes_lane_matches(&m->lane[0], &serdes->lane[0]) &&
+		    s32g_serdes_lane_matches(&m->lane[1], &serdes->lane[1])) {
+			match = m;
+			break;
+		}
+	}
+
+	if (!match)
+		return dev_err_probe(serdes->dev, -EINVAL,
+				     "No SerDes mode matches the lane configuration\n");
+
+	for (i = 0; i < ARRAY_SIZE(match->refclk) && match->refclk[i]; i++) {
+		if (serdes->ctrl.ref_clk_rate == match->refclk[i]) {
+			refclk_ok = true;
+			break;
+		}
+	}
+
+	if (!refclk_ok)
+		return dev_err_probe(serdes->dev, -EINVAL,
+				     "Reference clock %lu Hz invalid for mode %u\n",
+				     serdes->ctrl.ref_clk_rate, match->submode);
+
+	serdes->ctrl.ss_mode = match->submode;
+
+	dev_dbg(serdes->dev,
+		"SerDes mode %u selected: lane0=%s lane1=%s, ref-clk %lu MHz (%s)\n",
+		match->submode,
+		s32g_lane_fn_str(&serdes->lane[0]),
+		s32g_lane_fn_str(&serdes->lane[1]),
+		serdes->ctrl.ref_clk_rate / HZ_PER_MHZ,
+		serdes->ctrl.ext_clk ? "external" : "internal");
+
+	return 0;
+}
+
+static int s32g_serdes_init(struct s32g_serdes *serdes)
+{
+	struct s32g_serdes_ctrl *ctrl = &serdes->ctrl;
+	u32 reg0;
+	int ret;
+
+	ret = clk_bulk_prepare_enable(ctrl->nclks, ctrl->clks);
+	if (ret) {
+		dev_err(serdes->dev, "Failed to enable SerDes clocks\n");
+		return ret;
+	}
+
+	ret = s32g_serdes_assert_reset(serdes);
+	if (ret)
+		goto disable_clks;
+
+	/* Set serdes mode */
+	reg0 = readl(ctrl->ss_base + S32G_SS_RW_REG_0);
+	reg0 &= ~SUBMODE_MASK;
+	reg0 |= FIELD_PREP(SUBMODE_MASK, ctrl->ss_mode);
+	writel(reg0, ctrl->ss_base + S32G_SS_RW_REG_0);
+
+	/* Set Clock source: internal or external */
+	reg0 = readl(ctrl->ss_base + S32G_SS_RW_REG_0);
+	if (ctrl->ext_clk)
+		reg0 &= ~CLKEN_MASK;
+	else
+		reg0 |= CLKEN_MASK;
+
+	writel(reg0, ctrl->ss_base + S32G_SS_RW_REG_0);
+
+	/*
+	 * Route the combo-PHY reference: REF_USE_PAD is 0 for the internal
+	 * reference, 1 for the external pad. s32g_pcie_phy_power_on_common()
+	 * programs it too, but the XPCS lane is brought up before any PCIe
+	 * power-on. Left at the bootloader default the XPCS PMA never powers
+	 * up, VR_RST never self-clears and every register reads back constant.
+	 */
+	reg0 = readl(ctrl->ss_base + S32G_PCIE_PHY_GEN_CTRL);
+	if (ctrl->ext_clk)
+		reg0 |= REF_USE_PAD;
+	else
+		reg0 &= ~REF_USE_PAD;
+	writel(reg0, ctrl->ss_base + S32G_PCIE_PHY_GEN_CTRL);
+	dev_dbg(serdes->dev,
+		"GEN_CTRL after ref-clk route: 0x%08x (REF_USE_PAD=%d)\n",
+		reg0, !!(reg0 & REF_USE_PAD));
+
+	/* Wait for the selection of working mode (as per the manual specs) */
+	usleep_range(100, 110);
+
+	ret = s32g_serdes_deassert_reset(serdes);
+	if (ret)
+		goto disable_clks;
+
+	/*
+	 * The PHY needs up to 5.2 ms after reset release to become
+	 * operational. Nothing may touch the PHY or the XPCS PMA before
+	 * that point.
+	 */
+	ret = s32g_serdes_wait_phy_operational(serdes);
+	if (ret)
+		goto disable_clks;
+
+	ret = s32g_serdes_init_xpcs(serdes);
+	if (ret) {
+		dev_err(serdes->dev, "XPCS init failed\n");
+		goto disable_clks;
+	}
+
+	dev_info(serdes->dev, "SerDes subsystem mode %u (refclk=%lu MHz)\n",
+		 ctrl->ss_mode, ctrl->ref_clk_rate / HZ_PER_MHZ);
+
+	return 0;
+
+disable_clks:
+	/* Already on an error path; ignore the return value. */
+	s32g_serdes_assert_reset(serdes);
+	clk_bulk_disable_unprepare(serdes->ctrl.nclks,
+				   serdes->ctrl.clks);
+
+	return ret;
+}
+
+static void s32g_serdes_disable(void *data)
+{
+	struct s32g_serdes *serdes = data;
+
+	s32g_serdes_assert_reset(serdes);
+	clk_bulk_disable_unprepare(serdes->ctrl.nclks, serdes->ctrl.clks);
+}
+
+static int s32g_serdes_get_ctrl_resources(struct platform_device *pdev,
+					  struct s32g_serdes *serdes)
+{
+	struct s32g_serdes_ctrl *ctrl = &serdes->ctrl;
+	struct device *dev = &pdev->dev;
+	int ret, idx, i;
+
+	ctrl->ss_base = devm_platform_ioremap_resource_byname(pdev, "ss-pcie");
+	if (IS_ERR(ctrl->ss_base))
+		return dev_err_probe(dev, PTR_ERR(ctrl->ss_base),
+				     "Failed to map 'ss-pcie'\n");
+
+	ctrl->rst = devm_reset_control_get_exclusive(dev, "serdes");
+	if (IS_ERR(ctrl->rst))
+		return dev_err_probe(dev, PTR_ERR(ctrl->rst),
+				     "Failed to get 'serdes' reset control\n");
+
+	ctrl->nclks = devm_clk_bulk_get_all(dev, &ctrl->clks);
+	if (ctrl->nclks < 1) {
+		ret = ctrl->nclks ? : -EINVAL;
+		return dev_err_probe(dev, ret,
+				     "Failed to get SerDes clocks\n");
+	}
+
+	idx = -1;
+	for (i = 0; i < ctrl->nclks; i++) {
+		if (!ctrl->clks[i].id)
+			continue;
+
+		if (!strcmp(ctrl->clks[i].id, EXTERNAL_CLK_NAME)) {
+			idx = i;
+			ctrl->ext_clk = true;
+			break;
+		}
+
+		if (!strcmp(ctrl->clks[i].id, INTERNAL_CLK_NAME))
+			idx = i;
+	}
+
+	if (idx < 0) {
+		dev_err(dev, "Failed to get Phy reference clock source\n");
+		return -EINVAL;
+	}
+
+	ctrl->ref_clk_rate = clk_get_rate(ctrl->clks[idx].clk);
+	if (!ctrl->ref_clk_rate) {
+		dev_err(dev, "Failed to get Phy reference clock rate\n");
+		return -EINVAL;
+	}
+
+	return 0;
+}
+
+static int s32g_serdes_get_pcie_resources(struct platform_device *pdev,
+					  struct s32g_serdes *serdes)
+{
+	struct s32g_pcie_ctrl *pcie = &serdes->pcie;
+	struct device *dev = &pdev->dev;
+
+	pcie->phy_base = devm_platform_ioremap_resource_byname(pdev,
+							       "pcie-phy");
+	if (IS_ERR(pcie->phy_base))
+		return dev_err_probe(dev, PTR_ERR(pcie->phy_base),
+				     "Failed to map 'pcie-phy'\n");
+
+	pcie->rst = devm_reset_control_get_exclusive(dev, "pcie");
+	if (IS_ERR(pcie->rst))
+		return dev_err_probe(dev, PTR_ERR(pcie->rst),
+				     "Failed to get 'pcie' reset control\n");
+
+	return 0;
+}
+
+static int s32g_serdes_get_xpcs_resources(struct platform_device *pdev,
+					  struct s32g_serdes *serdes)
+{
+	struct s32g_xpcs_ctrl *xpcs = &serdes->xpcs;
+	struct device *dev = &pdev->dev;
+
+	xpcs->base[0] = devm_platform_ioremap_resource_byname(pdev, "xpcs0");
+	if (IS_ERR(xpcs->base[0]))
+		return dev_err_probe(dev, PTR_ERR(xpcs->base[0]),
+				     "Failed to map 'xpcs0'\n");
+
+	xpcs->base[1] = devm_platform_ioremap_resource_byname(pdev, "xpcs1");
+	if (IS_ERR(xpcs->base[1]))
+		return dev_err_probe(dev, PTR_ERR(xpcs->base[1]),
+				     "Failed to map 'xpcs1'\n");
+
+	return 0;
+}
+
+static int s32g_serdes_parse_lane(struct s32g_serdes *serdes,
+				  struct device_node *child_node)
+{
+	struct device *dev = serdes->dev;
+	u32 index, instance;
+	int ret;
+
+	ret = of_property_read_u32(child_node, "reg", &index);
+	if (ret || index > 1)
+		return dev_err_probe(dev, ret ? : -EINVAL,
+				     "Invalid lane index in %pOFn\n",
+				     child_node);
+
+	if (serdes->lane[index].fn != S32G_LANE_UNUSED)
+		return dev_err_probe(dev, -EINVAL,
+				     "Duplicate lane %u\n", index);
+
+	if (of_device_is_compatible(child_node, "nxp,s32g-serdes-pcie-phy")) {
+		serdes->lane[index].fn = S32G_LANE_PCIE;
+		return 0;
+	}
+
+	if (of_device_is_compatible(child_node, "nxp,s32g-serdes-xpcs")) {
+		ret = of_property_read_u32(child_node, "nxp,xpcs-instance",
+					   &instance);
+		if (ret || instance > 1)
+			return dev_err_probe(dev, ret ? : -EINVAL,
+					     "Invalid nxp,xpcs-instance in %pOFn\n",
+					     child_node);
+
+		serdes->lane[index].fn = S32G_LANE_XPCS;
+		serdes->lane[index].xpcs_instance = instance;
+		return 0;
+	}
+
+	dev_warn(dev, "Skipping unknown child node %pOFn\n", child_node);
+
+	return 0;
+}
+
+static int s32g_serdes_create_pcie_phy(struct s32g_serdes *serdes,
+				       struct device_node *child_node)
+{
+	struct phy_provider *phy_provider;
+	struct device *dev = serdes->dev;
+	struct phy *phy;
+
+	phy = devm_phy_create(dev, child_node, &serdes_pcie_ops);
+	if (IS_ERR(phy))
+		return PTR_ERR(phy);
+
+	phy_set_drvdata(phy, serdes);
+
+	phy->attrs.mode = PHY_MODE_PCIE;
+	serdes->pcie.phy = phy;
+
+	phy_provider = devm_of_phy_provider_register(&phy->dev,
+						     s32g_serdes_phy_xlate);
+	if (IS_ERR(phy_provider))
+		return PTR_ERR(phy_provider);
+
+	return 0;
+}
+
+static int s32g_serdes_parse_lanes(struct device *dev,
+				   struct s32g_serdes *serdes)
+{
+	int ret;
+
+	for_each_available_child_of_node_scoped(dev->of_node, of_port) {
+		ret = s32g_serdes_parse_lane(serdes, of_port);
+		if (ret)
+			return ret;
+	}
+
+	/*
+	 * In the x2 mode both lane children are PCIe, but they form one link
+	 * behind one controller, so create a single phy bound to the first
+	 * PCIe child. One phy per child would register two providers for one
+	 * link.
+	 */
+	for_each_available_child_of_node_scoped(dev->of_node, of_port) {
+		if (!of_device_is_compatible(of_port,
+					     "nxp,s32g-serdes-pcie-phy"))
+			continue;
+
+		ret = s32g_serdes_create_pcie_phy(serdes, of_port);
+		if (ret)
+			return ret;
+
+		break;
+	}
+
+	return 0;
+}
+
+static int s32g_serdes_setup_xpcs_lanes(struct s32g_serdes *serdes)
+{
+	unsigned int i;
+	int ret;
+
+	for (i = 0; i < ARRAY_SIZE(serdes->lane); i++) {
+		if (serdes->lane[i].fn != S32G_LANE_XPCS)
+			continue;
+
+		ret = s32g_serdes_xpcs_setup(serdes,
+					     serdes->lane[i].xpcs_instance);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+static int s32g_serdes_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	const struct s32g_serdes_soc_data *soc_data;
+	struct s32g_serdes *serdes;
+	int ret;
+
+	serdes = devm_kzalloc(dev, sizeof(*serdes), GFP_KERNEL);
+	if (!serdes)
+		return -ENOMEM;
+
+	serdes->dev = dev;
+
+	soc_data = of_device_get_match_data(dev);
+	if (!soc_data)
+		return -EINVAL;
+
+	serdes->soc_data = soc_data;
+
+	ret = s32g_serdes_get_ctrl_resources(pdev, serdes);
+	if (ret)
+		return ret;
+
+	ret = s32g_serdes_get_pcie_resources(pdev, serdes);
+	if (ret)
+		return ret;
+
+	ret = s32g_serdes_get_xpcs_resources(pdev, serdes);
+	if (ret)
+		return ret;
+
+	ret = s32g_serdes_parse_lanes(dev, serdes);
+	if (ret)
+		return ret;
+
+	ret = s32g_serdes_derive_mode(serdes);
+	if (ret)
+		return ret;
+
+	ret = s32g_serdes_setup_xpcs_lanes(serdes);
+	if (ret)
+		return ret;
+
+	ret = s32g_serdes_init(serdes);
+	if (ret)
+		return ret;
+
+	ret = devm_add_action_or_reset(dev, s32g_serdes_disable, serdes);
+	if (ret)
+		return ret;
+
+	/*
+	 * Publish drvdata last: s32g_serdes_pcs_create() takes a NULL drvdata
+	 * as its -EPROBE_DEFER condition, so setting it earlier can hand a MAC
+	 * a PCS while the PLLs are still down, or after a failed probe has
+	 * released it.
+	 */
+	platform_set_drvdata(pdev, serdes);
+
+	return 0;
+}
+
+static int s32g_serdes_suspend(struct device *device)
+{
+	struct s32g_serdes *serdes = dev_get_drvdata(device);
+
+	clk_bulk_disable_unprepare(serdes->ctrl.nclks, serdes->ctrl.clks);
+
+	return 0;
+}
+
+static int s32g_serdes_resume(struct device *device)
+{
+	struct s32g_serdes *serdes = dev_get_drvdata(device);
+	struct s32g_pcie_ctrl *pcie = &serdes->pcie;
+	int ret;
+
+	ret = s32g_serdes_init(serdes);
+	if (ret) {
+		dev_err(device, "Failed to initialize\n");
+		return ret;
+	}
+
+	/* Restore PCIe phy power */
+	if (pcie->powered_on) {
+		ret = s32g_pcie_phy_power_on(serdes);
+		if (ret)
+			dev_err(device, "Failed to power-on PCIe phy\n");
+	}
+
+	return ret;
+}
+
+/**
+ * s32g_serdes_pcs_create() - look up the phylink PCS for a SerDes XPCS lane
+ * @dev: the consumer (MAC) device
+ * @np: the SerDes XPCS lane child node
+ *
+ * A device link is created between @dev and the SerDes device so that the
+ * MAC is unbound before the SerDes it depends on. If the SerDes device has
+ * not probed (far enough) yet, -EPROBE_DEFER is returned so the caller
+ * retries later.
+ *
+ * Return: the phylink_pcs on success, or an ERR_PTR() on failure. The
+ * returned phylink_pcs is owned by the SerDes device and must not be freed
+ * by the caller.
+ */
+struct phylink_pcs *s32g_serdes_pcs_create(struct device *dev,
+					   struct device_node *np)
+{
+	struct platform_device *pdev;
+	struct device_node *pcs_np;
+	struct s32g_serdes *serdes;
+	struct device_link *link;
+	u32 instance;
+
+	/*
+	 * The lane child's unit address is the physical lane; the PCS is
+	 * identified by the XPCS instance routed to that lane.
+	 */
+	if (of_property_read_u32(np, "nxp,xpcs-instance", &instance))
+		return ERR_PTR(-EINVAL);
+
+	if (instance >= S32G_SERDES_XPCS_MAX)
+		return ERR_PTR(-EINVAL);
+
+	pcs_np = of_get_parent(np);
+	if (!pcs_np)
+		return ERR_PTR(-ENODEV);
+
+	if (!of_device_is_available(pcs_np)) {
+		of_node_put(pcs_np);
+		return ERR_PTR(-ENODEV);
+	}
+
+	pdev = of_find_device_by_node(pcs_np);
+	of_node_put(pcs_np);
+	if (!pdev)
+		return ERR_PTR(-EPROBE_DEFER);
+
+	serdes = platform_get_drvdata(pdev);
+	if (!serdes) {
+		put_device(&pdev->dev);
+		return ERR_PTR(-EPROBE_DEFER);
+	}
+
+	if (!serdes->xpcs.phys[instance]) {
+		put_device(&pdev->dev);
+		return ERR_PTR(-EPROBE_DEFER);
+	}
+
+	link = device_link_add(dev, &pdev->dev, DL_FLAG_AUTOREMOVE_CONSUMER);
+	put_device(&pdev->dev);
+	if (!link)
+		return ERR_PTR(-EINVAL);
+
+	return s32g_xpcs_pcs(serdes->xpcs.phys[instance]);
+}
+EXPORT_SYMBOL_GPL(s32g_serdes_pcs_create);
+
+static const struct of_device_id s32g_serdes_match[] = {
+	{
+		.compatible = "nxp,s32g2-serdes",
+		.data = &s32g2_serdes_soc_data,
+	},
+	{
+		.compatible = "nxp,s32g3-serdes",
+		.data = &s32g3_serdes_soc_data,
+	},
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, s32g_serdes_match);
+
+/* noirq, like the PCIe controller using this PHY */
+static const struct dev_pm_ops s32g_serdes_pm_ops = {
+	NOIRQ_SYSTEM_SLEEP_PM_OPS(s32g_serdes_suspend,
+				  s32g_serdes_resume)
+};
+
+static struct platform_driver s32g_serdes_driver = {
+	.probe		= s32g_serdes_probe,
+	.driver		= {
+		.name	= "phy-s32g-serdes",
+		.of_match_table = s32g_serdes_match,
+		.pm = pm_sleep_ptr(&s32g_serdes_pm_ops),
+	},
+};
+module_platform_driver(s32g_serdes_driver);
+
+MODULE_AUTHOR("Ghennadi Procopciuc <ghennadi.procopciuc@nxp.com>");
+MODULE_DESCRIPTION("NXP S32G SerDes driver");
+MODULE_LICENSE("GPL");
diff --git a/include/linux/phy/nxp-s32g-serdes.h b/include/linux/phy/nxp-s32g-serdes.h
new file mode 100644
index 000000000000..d14fcde1d933
--- /dev/null
+++ b/include/linux/phy/nxp-s32g-serdes.h
@@ -0,0 +1,25 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright 2021-2026 NXP
+ */
+#ifndef PHY_NXP_S32G_SERDES_H
+#define PHY_NXP_S32G_SERDES_H
+
+#include <linux/err.h>
+
+struct device;
+struct device_node;
+struct phylink_pcs;
+
+#if IS_REACHABLE(CONFIG_PHY_S32G_SERDES)
+struct phylink_pcs *s32g_serdes_pcs_create(struct device *dev,
+					   struct device_node *np);
+#else
+static inline struct phylink_pcs *
+s32g_serdes_pcs_create(struct device *dev, struct device_node *np)
+{
+	return ERR_PTR(-ENODEV);
+}
+#endif
+
+#endif /* PHY_NXP_S32G_SERDES_H */

-- 
2.55.0

