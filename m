From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Wed, 25 Nov 2026 10:33:50 +0100
Subject: [PATCH RFC v4 08/15] net: pcs: Add NXP S32G XPCS glue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-s32g_serdes-v4-8-3bfe0589be8d@oss.nxp.com>
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
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>, 
 Alexandru-Catalin Ionita <alexandru-catalin.ionita@nxp.com>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@nxp.com>, 
 Ionut Vicovan <Ionut.Vicovan@nxp.com>, 
 Bogdan Roman <bogdan-gabriel.roman@nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795599274; l=21865;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=cSC6lLOEbkrOZG3ilcTZrvCqOCM7a7ykGy31Mfv/IMs=;
 b=FF1Uyog/uEswfTXsufp2zfHlJJriiHZCwwX31PReyVMc7nyeHYOsQYtqXxtdOFXsrxmfGbCdy
 fKX+H8MHSKqD1mYfCn4SJslIezWgMYV5U4uH2tYElijtGyu1+NWEAoy
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Vincent Guittot <vincent.guittot@linaro.org>

Each S32G SerDes subsystem has two DesignWare XPCS instances, driven as
phylink PCS by pcs-xpcs. Add the S32G glue around them.

The XPCS registers sit behind an indirect MMIO window: a page register
selects which 256 registers of the Clause 45 address space the window
shows. Expose each instance to pcs-xpcs as an MDIO bus over that
window, and create the PCS with the generic DesignWare PCS ID and
NXP_S32G_XPCS_PMA_ID declared, which selects the S32G entry of
pcs-xpcs. With both IDs declared pcs-xpcs reads no ID register, which
matters here: the instances are created before the SerDes clocks run.

In the PCIe+SGMII modes the XPCS shares the combo PHY with the PCIe
lane, so it cannot own its reset and PMA/PLL bring-up. The glue exports
the bring-up steps to the SerDes PHY driver, which owns the shared PMA
and orders them, e.g. XPCS1 before XPCS0 in the dual-SGMII mode.

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
[jan.petrous: moved onto pcs-xpcs, the transport becomes an MDIO bus]
Co-developed-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 drivers/net/pcs/Kconfig               |   7 +
 drivers/net/pcs/Makefile              |   1 +
 drivers/net/pcs/pcs-nxp-s32g-xpcs.c   | 569 ++++++++++++++++++++++++++++++++++
 include/linux/pcs/pcs-nxp-s32g-xpcs.h |  41 +++
 4 files changed, 618 insertions(+)

diff --git a/drivers/net/pcs/Kconfig b/drivers/net/pcs/Kconfig
index 108d47257bee..2c29ecbd9c70 100644
--- a/drivers/net/pcs/Kconfig
+++ b/drivers/net/pcs/Kconfig
@@ -33,6 +33,13 @@ config PCS_XPCS_ROCKCHIP
 
 	  If you have a Rockchip SoC with this interface, say Y or M here.
 
+config PCS_NXP_S32G_XPCS
+	tristate
+	help
+	  Glue between the XPCS instances of the NXP S32G SerDes subsystem
+	  and the Synopsys DesignWare XPCS driver. Selected by the S32G
+	  SerDes PHY driver.
+
 endif # PCS_XPCS
 
 config PCS_LYNX
diff --git a/drivers/net/pcs/Makefile b/drivers/net/pcs/Makefile
index 072b8214446b..53c583f8e04d 100644
--- a/drivers/net/pcs/Makefile
+++ b/drivers/net/pcs/Makefile
@@ -10,3 +10,4 @@ obj-$(CONFIG_PCS_XPCS_ROCKCHIP) += pcs-xpcs-rk.o
 obj-$(CONFIG_PCS_LYNX)		+= pcs-lynx.o
 obj-$(CONFIG_PCS_MTK_LYNXI)	+= pcs-mtk-lynxi.o
 obj-$(CONFIG_PCS_RZN1_MIIC)	+= pcs-rzn1-miic.o
+obj-$(CONFIG_PCS_NXP_S32G_XPCS)	+= pcs-nxp-s32g-xpcs.o
diff --git a/drivers/net/pcs/pcs-nxp-s32g-xpcs.c b/drivers/net/pcs/pcs-nxp-s32g-xpcs.c
new file mode 100644
index 000000000000..3a0e85e1695d
--- /dev/null
+++ b/drivers/net/pcs/pcs-nxp-s32g-xpcs.c
@@ -0,0 +1,569 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright 2021-2026 NXP
+ *
+ * S32G SerDes XPCS glue: the indirect register window of each XPCS instance
+ * exposed as an MDIO bus for pcs-xpcs, plus the PMA/PLL bring-up steps that
+ * the SerDes PHY driver sequences across both instances.
+ */
+
+#include <linux/bitfield.h>
+#include <linux/device.h>
+#include <linux/err.h>
+#include <linux/errno.h>
+#include <linux/io.h>
+#include <linux/iopoll.h>
+#include <linux/mdio.h>
+#include <linux/mii.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/pcs/pcs-nxp-s32g-xpcs.h>
+#include <linux/pcs/pcs-xpcs.h>
+#include <linux/phy.h>
+#include <linux/phylink.h>
+#include <linux/units.h>
+
+#include "pcs-xpcs.h"
+
+struct s32g_xpcs {
+	void __iomem *base;
+	struct device *dev;
+	unsigned char id;
+	/* Serialises the two step access through the indirect window */
+	struct mutex lock;
+	bool ext_clk;
+	bool mhz125;
+	enum s32g_xpcs_shared pcie_shared;
+	struct phylink_pcs *pcs;
+};
+
+#define XPCS_TIMEOUT_US				(300 * USEC_PER_MSEC)
+#define XPCS_POLL_SLEEP_US			100
+
+/* Page select register of the indirect access window */
+#define S32G_XPCS_VIEWPORT			0x3fc
+
+/* DW_VR_MII_DIG_CTRL1 bit used by the bring-up, next to DW_VR_RST */
+#define   BYP_PWRUP				BIT(1)
+/* Holds the DW_PSEQ_ST power sequencer state */
+#define VR_MII_DIG_STS				0x8010
+#define VR_MII_GEN5_12G_16G_TX_RATE_CTRL	0x8034
+#define   TX0_RATE_MASK				GENMASK(2, 0)
+#define     TX0_BAUD_DIV_4			2
+#define VR_MII_GEN5_12G_16G_TX_EQ_CTRL0		0x8036
+#define   TX_EQ_MAIN_MASK			GENMASK(13, 8)
+#define VR_MII_CONSUMER_10G_TX_TERM_CTRL	0x803c
+#define   TX0_TERM_MASK				GENMASK(2, 0)
+#define VR_MII_GEN5_12G_16G_RX_GENCTRL1		0x8051
+#define   RX_RST_0				BIT(4)
+#define VR_MII_GEN5_12G_16G_RX_RATE_CTRL	0x8054
+#define   RX0_RATE_MASK				GENMASK(1, 0)
+#define     RX0_BAUD_DIV_8			0x3
+#define VR_MII_GEN5_12G_16G_CDR_CTRL		0x8056
+#define   VCO_LOW_FREQ_0			BIT(8)
+#define VR_MII_GEN5_12G_16G_MPLL_CMN_CTRL	0x8070
+#define   MPLLB_SEL_0				BIT(4)
+#define VR_MII_GEN5_12G_16G_MPLLA_CTRL0		0x8071
+#define   MPLLA_CAL_DISABLE			BIT(15)
+#define   MLLA_MULTIPLIER_MASK			GENMASK(7, 0)
+#define VR_MII_GEN5_12G_MPLLA_CTRL1		0x8072
+#define   MPLLA_FRACN_CTRL_MASK			GENMASK(15, 5)
+#define VR_MII_GEN5_12G_16G_MPLLA_CTRL2		0x8073
+#define   MPLLA_TX_CLK_DIV_MASK			GENMASK(13, 11)
+#define   MPLLA_DIV10_CLK_EN			BIT(9)
+#define VR_MII_GEN5_12G_16G_MPLLB_CTRL0		0x8074
+#define   MPLLB_CAL_DISABLE			BIT(15)
+#define   MLLB_MULTIPLIER_MASK			GENMASK(7, 0)
+#define VR_MII_GEN5_12G_MPLLB_CTRL1		0x8075
+#define   MPLLB_FRACN_CTRL_MASK			GENMASK(15, 5)
+#define VR_MII_GEN5_12G_16G_MPLLB_CTRL2		0x8076
+#define   MPLLB_TX_CLK_DIV_MASK			GENMASK(13, 11)
+#define   MPLLB_DIV10_CLK_EN			BIT(9)
+#define VR_MII_GEN5_12G_MPLLA_CTRL3		0x8077
+#define   MPLLA_BANDWIDTH_MASK			GENMASK(15, 0)
+#define VR_MII_GEN5_12G_MPLLB_CTRL3		0x8078
+#define   MPLLB_BANDWIDTH_MASK			GENMASK(15, 0)
+#define VR_MII_GEN5_12G_16G_REF_CLK_CTRL	0x8091
+#define   REF_USE_PAD				BIT(1)
+#define   REF_CLK_DIV2				BIT(2)
+#define   REF_RANGE_MASK			GENMASK(5, 3)	/* shared by both PLLs */
+#define     RANGE_26_53_MHZ			0x1
+#define     RANGE_52_78_MHZ			0x2
+#define   REF_MPLLA_DIV2			BIT(6)
+#define   REF_MPLLB_DIV2			BIT(7)
+#define VR_MII_GEN5_12G_16G_VCO_CAL_LD0		0x8092
+#define   VCO_LD_VAL_0_MASK			GENMASK(12, 0)
+#define VR_MII_GEN5_12G_VCO_CAL_REF0		0x8096
+#define   VCO_REF_LD_0_MASK			GENMASK(5, 0)
+
+/*
+ * The XPCS registers are reached through a 256 register window: the upper
+ * bits of the Clause 45 address "(devad << 16) | reg" select the page in
+ * S32G_XPCS_VIEWPORT, the low byte the register within the page. Registers
+ * are 16 bit wide, on a 4 byte stride.
+ */
+static void __iomem *s32g_xpcs_select(struct s32g_xpcs *xpcs, u16 reg)
+{
+	u32 addr = FIELD_PREP(GENMASK(20, 16), MDIO_MMD_VEND2) | reg;
+
+	lockdep_assert_held(&xpcs->lock);
+
+	writew(addr >> 8, xpcs->base + S32G_XPCS_VIEWPORT);
+
+	return xpcs->base + (addr & 0xff) * 4;
+}
+
+static u16 s32g_xpcs_read(struct s32g_xpcs *xpcs, u16 reg)
+{
+	guard(mutex)(&xpcs->lock);
+
+	return readw(s32g_xpcs_select(xpcs, reg));
+}
+
+static void s32g_xpcs_write(struct s32g_xpcs *xpcs, u16 reg, u16 val)
+{
+	guard(mutex)(&xpcs->lock);
+
+	writew(val, s32g_xpcs_select(xpcs, reg));
+}
+
+static void s32g_xpcs_write_bits(struct s32g_xpcs *xpcs, u16 reg, u16 mask,
+				 u16 value)
+{
+	void __iomem *data;
+	u16 val;
+
+	guard(mutex)(&xpcs->lock);
+
+	data = s32g_xpcs_select(xpcs, reg);
+	val = readw(data);
+	writew((val & ~mask) | (value & mask), data);
+}
+
+/* MDIO bus view of one XPCS instance, for pcs-xpcs: MDIO_MMD_VEND2 only */
+static int s32g_xpcs_mdio_read_c45(struct mii_bus *bus, int addr, int devad,
+				   int reg)
+{
+	struct s32g_xpcs *xpcs = bus->priv;
+
+	if (addr != 0 || devad != MDIO_MMD_VEND2)
+		return 0xffff;
+
+	return s32g_xpcs_read(xpcs, reg);
+}
+
+static int s32g_xpcs_mdio_write_c45(struct mii_bus *bus, int addr, int devad,
+				    int reg, u16 val)
+{
+	struct s32g_xpcs *xpcs = bus->priv;
+
+	if (addr != 0 || devad != MDIO_MMD_VEND2)
+		return -EINVAL;
+
+	s32g_xpcs_write(xpcs, reg, val);
+
+	return 0;
+}
+
+/*
+ * "Step N" refers to the XPCS initialization sequence of the S32G reference
+ * manual, SerDes subsystem chapter.
+ */
+
+static int s32g_xpcs_wait_power_good_state(struct s32g_xpcs *xpcs)
+{
+	u16 val;
+
+	return read_poll_timeout(s32g_xpcs_read, val,
+				 (val & DW_PSEQ_ST) == DW_PSEQ_ST_GOOD,
+				 XPCS_POLL_SLEEP_US, XPCS_TIMEOUT_US, false,
+				 xpcs, VR_MII_DIG_STS);
+}
+
+/**
+ * s32g_xpcs_vreset() - start the vendor specific soft reset (step 19)
+ * @xpcs: handle from s32g_xpcs_create()
+ *
+ * Call after s32g_xpcs_init_plls(), then wait with s32g_xpcs_wait_vreset().
+ *
+ * Context: may sleep.
+ */
+void s32g_xpcs_vreset(struct s32g_xpcs *xpcs)
+{
+	s32g_xpcs_write_bits(xpcs, DW_VR_MII_DIG_CTRL1, DW_VR_RST, DW_VR_RST);
+}
+EXPORT_SYMBOL_GPL(s32g_xpcs_vreset);
+
+/**
+ * s32g_xpcs_wait_vreset() - wait for the soft reset to complete (step 20)
+ * @xpcs: handle from s32g_xpcs_create()
+ *
+ * Context: may sleep, for up to 300 ms.
+ *
+ * Return: 0, or -ETIMEDOUT if the XPCS stays in reset.
+ */
+int s32g_xpcs_wait_vreset(struct s32g_xpcs *xpcs)
+{
+	u16 val;
+	int ret;
+
+	ret = read_poll_timeout(s32g_xpcs_read, val, !(val & DW_VR_RST),
+				XPCS_POLL_SLEEP_US, XPCS_TIMEOUT_US, false,
+				xpcs, DW_VR_MII_DIG_CTRL1);
+	if (ret)
+		dev_err(xpcs->dev, "XPCS%d is in reset\n", xpcs->id);
+
+	return ret;
+}
+EXPORT_SYMBOL_GPL(s32g_xpcs_wait_vreset);
+
+/**
+ * s32g_xpcs_reset_rx() - reset the receive path (steps 21 and 22)
+ * @xpcs: handle from s32g_xpcs_create()
+ *
+ * Call after s32g_xpcs_wait_vreset(). Unless the lane is shared with PCIe,
+ * this first waits for the power sequencer to reach POWER_GOOD.
+ *
+ * Context: may sleep, for up to 300 ms.
+ *
+ * Return: 0, or -ETIMEDOUT if POWER_GOOD is not reached.
+ */
+int s32g_xpcs_reset_rx(struct s32g_xpcs *xpcs)
+{
+	int ret = 0;
+
+	/*
+	 * On the shared 1G lane the PCIe side gates the PMA power-up and
+	 * BYP_PWRUP stays set, so the sequencer never reaches POWER_GOOD.
+	 */
+	if (xpcs->pcie_shared != S32G_PCIE_XPCS_1G) {
+		ret = s32g_xpcs_wait_power_good_state(xpcs);
+		if (ret) {
+			dev_err(xpcs->dev, "Failed to enter in PGOOD state after vendor reset\n");
+			return ret;
+		}
+	}
+
+	/* Step 21 */
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_RX_GENCTRL1,
+			     RX_RST_0, RX_RST_0);
+
+	/* Step 22 */
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_RX_GENCTRL1,
+			     RX_RST_0, 0);
+
+	return ret;
+}
+EXPORT_SYMBOL_GPL(s32g_xpcs_reset_rx);
+
+static void s32g_xpcs_electrical_configure(struct s32g_xpcs *xpcs)
+{
+	/* Step 2 */
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_TX_EQ_CTRL0,
+			     TX_EQ_MAIN_MASK, FIELD_PREP(TX_EQ_MAIN_MASK, 0xc));
+
+	/* Step 3 */
+	s32g_xpcs_write_bits(xpcs, VR_MII_CONSUMER_10G_TX_TERM_CTRL,
+			     TX0_TERM_MASK, FIELD_PREP(TX0_TERM_MASK, 0x4));
+}
+
+static void s32g_xpcs_vco_cfg(struct s32g_xpcs *xpcs)
+{
+	unsigned int vco_ld, vco_ref;
+
+	if (xpcs->mhz125) {
+		vco_ld = FIELD_PREP(VCO_LD_VAL_0_MASK, 1360);
+		vco_ref = FIELD_PREP(VCO_REF_LD_0_MASK, 17);
+	} else {
+		vco_ld = FIELD_PREP(VCO_LD_VAL_0_MASK, 1350);
+		vco_ref = FIELD_PREP(VCO_REF_LD_0_MASK, 27);
+	}
+
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_VCO_CAL_LD0,
+			     VCO_LD_VAL_0_MASK, vco_ld);
+
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_VCO_CAL_REF0,
+			     VCO_REF_LD_0_MASK, vco_ref);
+
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_TX_RATE_CTRL,
+			     TX0_RATE_MASK,
+			     FIELD_PREP(TX0_RATE_MASK, TX0_BAUD_DIV_4));
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_RX_RATE_CTRL,
+			     RX0_RATE_MASK,
+			     FIELD_PREP(RX0_RATE_MASK, RX0_BAUD_DIV_8));
+
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_CDR_CTRL,
+			     VCO_LOW_FREQ_0, 0);
+}
+
+static void s32g_xpcs_init_mplla(struct s32g_xpcs *xpcs)
+{
+	unsigned int val;
+
+	/* Step 7 */
+	val = 0;
+	if (xpcs->ext_clk)
+		val |= REF_USE_PAD;
+
+	if (xpcs->mhz125) {
+		val |= REF_MPLLA_DIV2;
+		val |= REF_CLK_DIV2;
+		val |= FIELD_PREP(REF_RANGE_MASK, RANGE_52_78_MHZ);
+	} else {
+		val |= FIELD_PREP(REF_RANGE_MASK, RANGE_26_53_MHZ);
+	}
+
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_REF_CLK_CTRL,
+			     REF_MPLLA_DIV2 | REF_USE_PAD | REF_RANGE_MASK |
+			     REF_CLK_DIV2, val);
+
+	/* Step 8 */
+	if (xpcs->mhz125)
+		val = FIELD_PREP(MLLA_MULTIPLIER_MASK, 80);
+	else
+		val = FIELD_PREP(MLLA_MULTIPLIER_MASK, 25);
+
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_MPLLA_CTRL0,
+			     MPLLA_CAL_DISABLE | MLLA_MULTIPLIER_MASK,
+			     val);
+
+	/* Step 9 */
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_MPLLA_CTRL1,
+			     MPLLA_FRACN_CTRL_MASK, 0);
+
+	/* Step 10 */
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_MPLLA_CTRL2,
+			     MPLLA_TX_CLK_DIV_MASK | MPLLA_DIV10_CLK_EN,
+			     FIELD_PREP(MPLLA_TX_CLK_DIV_MASK, 1) | MPLLA_DIV10_CLK_EN);
+
+	/* Step 11 */
+	if (xpcs->mhz125)
+		val = FIELD_PREP(MPLLA_BANDWIDTH_MASK, 43);
+	else
+		val = FIELD_PREP(MPLLA_BANDWIDTH_MASK, 357);
+
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_MPLLA_CTRL3,
+			     MPLLA_BANDWIDTH_MASK, val);
+}
+
+static void s32g_xpcs_init_mpllb(struct s32g_xpcs *xpcs)
+{
+	unsigned int val;
+
+	/* Step 7 */
+	val = 0;
+	if (xpcs->ext_clk)
+		val |= REF_USE_PAD;
+
+	if (xpcs->mhz125) {
+		val |= REF_MPLLB_DIV2;
+		val |= REF_CLK_DIV2;
+		val |= FIELD_PREP(REF_RANGE_MASK, RANGE_52_78_MHZ);
+	} else {
+		val |= FIELD_PREP(REF_RANGE_MASK, RANGE_26_53_MHZ);
+	}
+
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_REF_CLK_CTRL,
+			     REF_MPLLB_DIV2 | REF_USE_PAD | REF_RANGE_MASK |
+			     REF_CLK_DIV2, val);
+
+	/* Step 8 */
+	if (xpcs->mhz125)
+		val = FIELD_PREP(MLLB_MULTIPLIER_MASK, 125);
+	else
+		val = FIELD_PREP(MLLB_MULTIPLIER_MASK, 39);
+
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_MPLLB_CTRL0,
+			     MPLLB_CAL_DISABLE | MLLB_MULTIPLIER_MASK,
+			     val);
+
+	/* Step 9 */
+	if (xpcs->mhz125)
+		val = FIELD_PREP(MPLLB_FRACN_CTRL_MASK, 0);
+	else
+		val = FIELD_PREP(MPLLB_FRACN_CTRL_MASK, 1044);
+
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_MPLLB_CTRL1,
+			     MPLLB_FRACN_CTRL_MASK, val);
+
+	/* Step 10 */
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_MPLLB_CTRL2,
+			     MPLLB_TX_CLK_DIV_MASK | MPLLB_DIV10_CLK_EN,
+			     FIELD_PREP(MPLLB_TX_CLK_DIV_MASK, 5) | MPLLB_DIV10_CLK_EN);
+
+	/* Step 11 */
+	if (xpcs->mhz125)
+		val = FIELD_PREP(MPLLB_BANDWIDTH_MASK, 68);
+	else
+		val = FIELD_PREP(MPLLB_BANDWIDTH_MASK, 102);
+
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_MPLLB_CTRL3,
+			     MPLLB_BANDWIDTH_MASK, val);
+}
+
+/**
+ * s32g_xpcs_init_plls() - configure the PMA and both PLLs (steps 1 to 18)
+ * @xpcs: handle from s32g_xpcs_create()
+ *
+ * First step of the bring-up, followed by s32g_xpcs_vreset(). The lane is
+ * put on MPLLA, the 1G PLL.
+ *
+ * Context: may sleep, for up to 300 ms with an external reference clock.
+ *
+ * Return: 0, or -ETIMEDOUT if POWER_GOOD is not reached.
+ */
+int s32g_xpcs_init_plls(struct s32g_xpcs *xpcs)
+{
+	int ret;
+
+	if (!xpcs->ext_clk) {
+		/* Step 1 */
+		s32g_xpcs_write_bits(xpcs, DW_VR_MII_DIG_CTRL1, BYP_PWRUP,
+				     BYP_PWRUP);
+	} else if (xpcs->pcie_shared == S32G_NOT_SHARED) {
+		ret = s32g_xpcs_wait_power_good_state(xpcs);
+		if (ret)
+			return ret;
+	}
+
+	s32g_xpcs_electrical_configure(xpcs);
+
+	/* The lane runs from MPLLA */
+	s32g_xpcs_write_bits(xpcs, VR_MII_GEN5_12G_16G_MPLL_CMN_CTRL,
+			     MPLLB_SEL_0, 0);
+	s32g_xpcs_init_mplla(xpcs);
+	s32g_xpcs_init_mpllb(xpcs);
+	s32g_xpcs_vco_cfg(xpcs);
+
+	/*
+	 * Step 18: clear BYP_PWRUP (Step 1) so that the PMA powers up. The
+	 * shared 1G lane keeps it set: PCIe drives its power-up.
+	 */
+	if (!xpcs->ext_clk && xpcs->pcie_shared != S32G_PCIE_XPCS_1G)
+		s32g_xpcs_write_bits(xpcs, DW_VR_MII_DIG_CTRL1, BYP_PWRUP, 0);
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(s32g_xpcs_init_plls);
+
+/**
+ * s32g_xpcs_disable_an() - leave the XPCS in full duplex, AN off
+ * @xpcs: handle from s32g_xpcs_create()
+ *
+ * Last step of the bring-up. DW_VR_RST restores the BMCR defaults, so this
+ * has to follow s32g_xpcs_reset_rx(). pcs-xpcs enables AN again if the MAC
+ * uses in-band mode.
+ *
+ * Context: may sleep.
+ */
+void s32g_xpcs_disable_an(struct s32g_xpcs *xpcs)
+{
+	s32g_xpcs_write_bits(xpcs, MII_BMCR, BMCR_FULLDPLX, BMCR_FULLDPLX);
+	s32g_xpcs_write_bits(xpcs, MII_BMCR, BMCR_ANENABLE, 0);
+}
+EXPORT_SYMBOL_GPL(s32g_xpcs_disable_an);
+
+/*
+ * The XPCS reports the generic DesignWare PCS ID; the S32G PMA integration
+ * selects the S32G pcs-xpcs entry. Both are declared, as the instances are
+ * created before the SerDes clocks run and pcs-xpcs then reads no ID.
+ */
+DW_XPCS_INFO_DECLARE(s32g_xpcs_info, DW_XPCS_ID, NXP_S32G_XPCS_PMA_ID);
+
+static void s32g_xpcs_pcs_destroy(void *pcs)
+{
+	xpcs_destroy_pcs(pcs);
+}
+
+/**
+ * s32g_xpcs_create() - set up one XPCS instance
+ * @dev: the SerDes device the XPCS belongs to
+ * @id: XPCS instance within the SerDes subsystem (0 or 1)
+ * @base: mapped register block of the instance
+ * @ext_clk: the reference comes from the external pad
+ * @rate: reference clock rate, 100 or 125 MHz
+ * @pcie_shared: whether the lane shares the combo PHY with PCIe
+ *
+ * The instance is devm-managed against @dev.
+ *
+ * Return: the XPCS handle, or an ERR_PTR() on failure.
+ */
+struct s32g_xpcs *s32g_xpcs_create(struct device *dev, unsigned char id,
+				   void __iomem *base, bool ext_clk,
+				   unsigned long rate,
+				   enum s32g_xpcs_shared pcie_shared)
+{
+	struct phylink_pcs *pcs;
+	struct s32g_xpcs *xpcs;
+	struct mii_bus *bus;
+	int ret;
+
+	if (rate != (125 * HZ_PER_MHZ) && rate != (100 * HZ_PER_MHZ)) {
+		dev_err(dev, "XPCS cannot operate @%lu HZ\n", rate);
+		return ERR_PTR(-EINVAL);
+	}
+
+	xpcs = devm_kzalloc(dev, sizeof(*xpcs), GFP_KERNEL);
+	if (!xpcs)
+		return ERR_PTR(-ENOMEM);
+
+	ret = devm_mutex_init(dev, &xpcs->lock);
+	if (ret)
+		return ERR_PTR(ret);
+
+	xpcs->base = base;
+	xpcs->ext_clk = ext_clk;
+	xpcs->id = id;
+	xpcs->dev = dev;
+	xpcs->pcie_shared = pcie_shared;
+	xpcs->mhz125 = rate == (125 * HZ_PER_MHZ);
+
+	bus = devm_mdiobus_alloc(dev);
+	if (!bus)
+		return ERR_PTR(-ENOMEM);
+
+	bus->name = "NXP S32G XPCS";
+	snprintf(bus->id, MII_BUS_ID_SIZE, "%s-xpcs%u", dev_name(dev), id);
+	bus->read_c45 = s32g_xpcs_mdio_read_c45;
+	bus->write_c45 = s32g_xpcs_mdio_write_c45;
+	bus->priv = xpcs;
+	bus->parent = dev;
+	/* The XPCS is the only device on the bus, at address 0; no scan */
+	bus->phy_mask = ~0;
+
+	ret = devm_mdiobus_register(dev, bus);
+	if (ret)
+		return ERR_PTR(dev_err_probe(dev, ret,
+					     "Failed to register XPCS%u MDIO bus\n",
+					     id));
+
+	pcs = xpcs_create_pcs_mdiodev_info(bus, 0, &s32g_xpcs_info);
+	if (IS_ERR(pcs))
+		return ERR_PTR(dev_err_probe(dev, PTR_ERR(pcs),
+					     "Failed to create XPCS%u PCS\n", id));
+
+	ret = devm_add_action_or_reset(dev, s32g_xpcs_pcs_destroy, pcs);
+	if (ret)
+		return ERR_PTR(ret);
+
+	xpcs->pcs = pcs;
+
+	return xpcs;
+}
+EXPORT_SYMBOL_GPL(s32g_xpcs_create);
+
+/**
+ * s32g_xpcs_pcs() - the phylink PCS of an XPCS instance
+ * @xpcs: handle from s32g_xpcs_create()
+ *
+ * Return: the phylink_pcs, owned by the SerDes device.
+ */
+struct phylink_pcs *s32g_xpcs_pcs(struct s32g_xpcs *xpcs)
+{
+	return xpcs->pcs;
+}
+EXPORT_SYMBOL_GPL(s32g_xpcs_pcs);
+
+MODULE_DESCRIPTION("NXP S32G SerDes XPCS driver");
+MODULE_AUTHOR("Jan Petrous (OSS) <jan.petrous@oss.nxp.com>");
+MODULE_LICENSE("GPL");
diff --git a/include/linux/pcs/pcs-nxp-s32g-xpcs.h b/include/linux/pcs/pcs-nxp-s32g-xpcs.h
new file mode 100644
index 000000000000..721c5ca4c54c
--- /dev/null
+++ b/include/linux/pcs/pcs-nxp-s32g-xpcs.h
@@ -0,0 +1,41 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright 2021-2026 NXP
+ */
+#ifndef PCS_NXP_S32G_XPCS_H
+#define PCS_NXP_S32G_XPCS_H
+
+#include <linux/types.h>
+
+struct device;
+struct phylink_pcs;
+
+struct s32g_xpcs;
+
+/*
+ * Whether the XPCS shares the combo PHY with the PCIe lane. If it does, the
+ * PMA power-up is driven from the PCIe side.
+ */
+enum s32g_xpcs_shared {
+	S32G_NOT_SHARED,
+	S32G_PCIE_XPCS_1G,
+};
+
+struct s32g_xpcs *s32g_xpcs_create(struct device *dev, unsigned char id,
+				   void __iomem *base, bool ext_clk,
+				   unsigned long rate,
+				   enum s32g_xpcs_shared pcie_shared);
+struct phylink_pcs *s32g_xpcs_pcs(struct s32g_xpcs *xpcs);
+
+/*
+ * Bring-up steps, called by the SerDes PHY driver in the order below. With
+ * both lanes on XPCS, the instance without control over the PHY common
+ * signals goes first.
+ */
+int s32g_xpcs_init_plls(struct s32g_xpcs *xpcs);
+void s32g_xpcs_vreset(struct s32g_xpcs *xpcs);
+int s32g_xpcs_wait_vreset(struct s32g_xpcs *xpcs);
+int s32g_xpcs_reset_rx(struct s32g_xpcs *xpcs);
+void s32g_xpcs_disable_an(struct s32g_xpcs *xpcs);
+
+#endif /* PCS_NXP_S32G_XPCS_H */

-- 
2.55.0

