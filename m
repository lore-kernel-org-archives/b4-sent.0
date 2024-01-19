From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 19 Jan 2024 21:36:19 +0800
Subject: [PATCH RFC 2/2] clk: add clock framework for HiSilicon SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240119-b4-hisi-clk-v1-2-279e38c95ca2@outlook.com>
References: <20240119-b4-hisi-clk-v1-0-279e38c95ca2@outlook.com>
In-Reply-To: <20240119-b4-hisi-clk-v1-0-279e38c95ca2@outlook.com>
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, David Yang <mmyangfl@gmail.com>, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705671378; l=15825;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=i+xZrk7FWbz4ZuuhJeOpgBrY/ytTAtUATqwSHpvu6eA=;
 b=Y3TMYOsqeNuMpmJc/z6ACk5eqtxebfiELmExLt3TR36oOZrjr5IhVBiRxSpKRS8kCUqFSgKDD
 h6uG2FeghEkCGL5/m3JjO+P0Smp3u693cyXl4lczSR6OCoDagvJ/saK
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi3798 Series SoCs have a CRG (Clock Reset Generator) module which
manages all clocks and resets of the SoC.

The first supported chip is Hi3798MV200.  The unused clocks are not
registered to save space and time. Only necessary clocks are
implemented right now.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/Kconfig                     |   7 ++
 drivers/clk/Makefile                    |   1 +
 drivers/clk/hisilicon/Kconfig           |  14 +++
 drivers/clk/hisilicon/Makefile          |   8 ++
 drivers/clk/hisilicon/clk-hi3798mv200.c | 213 ++++++++++++++++++++++++++++++++
 drivers/clk/hisilicon/clk.c             | 102 +++++++++++++++
 drivers/clk/hisilicon/clk.h             |  55 +++++++++
 include/dt-bindings/clock/histb-clock.h |   4 +
 8 files changed, 404 insertions(+)

diff --git a/drivers/clk/Kconfig b/drivers/clk/Kconfig
index 017dd260a5..4c5ac46b26 100644
--- a/drivers/clk/Kconfig
+++ b/drivers/clk/Kconfig
@@ -127,6 +127,12 @@ config CLK_ICS8N3QV01
 	  Crystal Oscillator). The output frequency can be programmed via an
 	  I2C interface.
 
+config CLK_HISI
+	bool "Enable Hisilicon Clock Framework"
+	depends on CLK && CLK_CCF
+	help
+	  Support for Hisilicon Clock Framework.
+
 config CLK_INTEL
 	bool "Enable clock driver for Intel x86"
 	depends on CLK && X86
@@ -249,6 +255,7 @@ config CLK_ZYNQMP
 source "drivers/clk/analogbits/Kconfig"
 source "drivers/clk/at91/Kconfig"
 source "drivers/clk/exynos/Kconfig"
+source "drivers/clk/hisilicon/Kconfig"
 source "drivers/clk/imx/Kconfig"
 source "drivers/clk/meson/Kconfig"
 source "drivers/clk/microchip/Kconfig"
diff --git a/drivers/clk/Makefile b/drivers/clk/Makefile
index 638ad04bae..90e7e1b5f4 100644
--- a/drivers/clk/Makefile
+++ b/drivers/clk/Makefile
@@ -32,6 +32,7 @@ obj-$(CONFIG_CLK_BCM6345) += clk_bcm6345.o
 obj-$(CONFIG_CLK_BOSTON) += clk_boston.o
 obj-$(CONFIG_CLK_CDCE9XX) += clk-cdce9xx.o
 obj-$(CONFIG_CLK_EXYNOS) += exynos/
+obj-$(CONFIG_CLK_HISI) += hisilicon/
 obj-$(CONFIG_CLK_HSDK) += clk-hsdk-cgu.o
 obj-$(CONFIG_CLK_K210) += clk_k210.o
 obj-$(CONFIG_CLK_MPC83XX) += mpc83xx_clk.o
diff --git a/drivers/clk/hisilicon/Kconfig b/drivers/clk/hisilicon/Kconfig
new file mode 100644
index 0000000000..caa51b7831
--- /dev/null
+++ b/drivers/clk/hisilicon/Kconfig
@@ -0,0 +1,14 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+if CLK_HISI
+menu "HiSilicon CRG Driver"
+
+config COMMON_CLK_HI3798MV200
+	tristate "Hi3798MV200 CRG Driver"
+	select RESET_HISILICON
+	depends on ARCH_HISTB
+	help
+	  Build the CRG driver for Hi3798MV200.
+
+endmenu
+endif
diff --git a/drivers/clk/hisilicon/Makefile b/drivers/clk/hisilicon/Makefile
new file mode 100644
index 0000000000..85a0ffb4a1
--- /dev/null
+++ b/drivers/clk/hisilicon/Makefile
@@ -0,0 +1,8 @@
+# SPDX-License-Identifier: GPL-2.0
+#
+# Hisilicon Clock specific Makefile
+#
+
+obj-y	+= clk.o
+
+obj-$(CONFIG_COMMON_CLK_HI3798MV200)	+= clk-hi3798mv200.o
diff --git a/drivers/clk/hisilicon/clk-hi3798mv200.c b/drivers/clk/hisilicon/clk-hi3798mv200.c
new file mode 100644
index 0000000000..01bb20d940
--- /dev/null
+++ b/drivers/clk/hisilicon/clk-hi3798mv200.c
@@ -0,0 +1,213 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Hi3798MV200 Clock and Reset Generator Driver.
+ * Adapted from clk-hi3798cv200.c.
+ *
+ * Copyright (c) 2024 Yang Xiwen <forbidden405@outlook.com>
+ * Copyright (c) 2016 HiSilicon Technologies Co., Ltd.
+ */
+
+#include <dt-bindings/clock/histb-clock.h>
+#include <linux/clk-provider.h>
+#include <dm/device.h>
+#include <dm/lists.h>
+#include <dm/read.h>
+
+#include "clk.h"
+
+/* hi3798MV200 core CRG */
+#define HI3798MV200_INNER_CLK_OFFSET		64
+#define HI3798MV200_FIXED_12M			65
+#define HI3798MV200_FIXED_24M			66
+#define HI3798MV200_FIXED_25M			67
+#define HI3798MV200_FIXED_27M			68
+#define HI3798MV200_FIXED_48M			69
+#define HI3798MV200_FIXED_50M			70
+#define HI3798MV200_FIXED_54M			71
+#define HI3798MV200_FIXED_60M			72
+#define HI3798MV200_FIXED_75M			73
+#define HI3798MV200_FIXED_100M			74
+#define HI3798MV200_FIXED_150M			75
+#define HI3798MV200_FIXED_166P5M		76
+#define HI3798MV200_FIXED_200M			77
+#define HI3798MV200_FIXED_250M			78
+#define HI3798MV200_FIXED_300M			79
+#define HI3798MV200_FIXED_400M			80
+#define HI3798MV200_MMC_MUX			81
+#define HI3798MV200_COMBPHY1_MUX		82
+#define HI3798MV200_SDIO0_MUX			83
+#define HI3798MV200_COMBPHY0_MUX		84
+#define HI3798MV200_SDIO1_MUX			85
+#define HI3798MV200_ETH_MUX			86
+
+static const struct hisi_fixed_rate_clock hi3798mv200_fixed_rate_clks[] = {
+	{ HISTB_OSC_CLK, "clk_osc", 24000000, },
+	{ HISTB_APB_CLK, "clk_apb", 100000000, },
+	{ HISTB_AHB_CLK, "clk_ahb", 200000000, },
+	{ HI3798MV200_FIXED_12M, "12m", 12000000, },
+	{ HI3798MV200_FIXED_24M, "24m", 24000000, },
+	{ HI3798MV200_FIXED_25M, "25m", 25000000, },
+	{ HI3798MV200_FIXED_27M, "27m", 27000000, },
+	{ HI3798MV200_FIXED_48M, "48m", 48000000, },
+	{ HI3798MV200_FIXED_50M, "50m", 50000000, },
+	{ HI3798MV200_FIXED_54M, "54m", 54000000, },
+	{ HI3798MV200_FIXED_60M, "60m", 60000000, },
+	{ HI3798MV200_FIXED_75M, "75m", 75000000, },
+	{ HI3798MV200_FIXED_100M, "100m", 100000000, },
+	{ HI3798MV200_FIXED_150M, "150m", 150000000, },
+	{ HI3798MV200_FIXED_166P5M, "166p5m", 165000000, },
+	{ HI3798MV200_FIXED_200M, "200m", 200000000, },
+	{ HI3798MV200_FIXED_250M, "250m", 250000000, },
+};
+
+static const char *const mmc_mux_p[] = {
+		"100m", "50m", "25m", "200m", "150m" };
+static u32 mmc_mux_table[] = {0, 1, 2, 3, 6};
+
+static const char *const comphy_mux_p[] = {
+		"25m", "100m"};
+static u32 comphy_mux_table[] = {0, 1};
+
+static const char *const sdio_mux_p[] = {
+		"100m", "50m", "150m", "166p5m" };
+static u32 sdio_mux_table[] = {0, 1, 2, 3};
+
+static const char *const eth_mux_p[] = {
+		"54m", "27m" };
+static u32 eth_mux_table[] = {0, 1};
+
+static struct hisi_mux_clock hi3798mv200_mux_clks[] = {
+	{ HI3798MV200_MMC_MUX, "mmc_mux", mmc_mux_p, ARRAY_SIZE(mmc_mux_p),
+		CLK_SET_RATE_PARENT, 0xa0, 8, 3, 0, mmc_mux_table, },
+	{ HI3798MV200_COMBPHY0_MUX, "combphy0_mux",
+		comphy_mux_p, ARRAY_SIZE(comphy_mux_p),
+		CLK_SET_RATE_PARENT, 0x188, 3, 1, 0, comphy_mux_table, },
+	{ HI3798MV200_SDIO0_MUX, "sdio0_mux", sdio_mux_p,
+		ARRAY_SIZE(sdio_mux_p), CLK_SET_RATE_PARENT,
+		0x9c, 8, 2, 0, sdio_mux_table, },
+	{ HI3798MV200_SDIO1_MUX, "sdio1_mux", sdio_mux_p,
+		ARRAY_SIZE(sdio_mux_p), CLK_SET_RATE_PARENT,
+		0x28c, 8, 2, 0, sdio_mux_table, },
+	{ HI3798MV200_ETH_MUX, "eth_mux", eth_mux_p,
+		ARRAY_SIZE(eth_mux_p), CLK_SET_RATE_PARENT,
+		0xd0, 2, 1, 0, eth_mux_table, },
+};
+
+static const struct hisi_gate_clock hi3798mv200_gate_clks[] = {
+	/* SDIO0 */
+	{ HISTB_SDIO0_BIU_CLK, "clk_sdio0_biu", "200m",
+			CLK_SET_RATE_PARENT, 0x9c, 0, 0, },
+	{ HISTB_SDIO0_CIU_CLK, "clk_sdio0_ciu", "sdio0_mux",
+		CLK_SET_RATE_PARENT, 0x9c, 1, 0, },
+	/* EMMC */
+	{ HISTB_MMC_BIU_CLK, "clk_mmc_biu", "200m",
+		CLK_SET_RATE_PARENT, 0xa0, 0, 0, },
+	{ HISTB_MMC_CIU_CLK, "clk_mmc_ciu", "mmc_mux",
+		CLK_SET_RATE_PARENT, 0xa0, 1, 0, },
+	/* Ethernet */
+	{ HI3798MV200_GMAC_CLK, "clk_gmac", "75m",
+		CLK_SET_RATE_PARENT, 0xcc, 2, 0, },
+	{ HI3798MV200_GMACIF_CLK, "clk_gmacif", NULL,
+		CLK_SET_RATE_PARENT, 0xcc, 0, 0, },
+	{ HI3798MV200_FEMAC_CLK, "clk_femac", "eth_mux",
+		CLK_SET_RATE_PARENT, 0xd0, 1, 0, },
+	{ HI3798MV200_FEMACIF_CLK, "clk_femacif", NULL,
+		CLK_SET_RATE_PARENT, 0xd0, 0, 0, },
+	{ HI3798MV200_FEPHY_CLK, "clk_fephy", NULL,
+		0, 0x388, 0, 0, },
+	/* COMBPHY */
+	{ HISTB_COMBPHY0_CLK, "clk_combphy0", "combphy0_mux",
+		CLK_SET_RATE_PARENT, 0x188, 0, 0, },
+	/* USB2 */
+	{ HISTB_USB2_BUS_CLK, "clk_u2_bus", "clk_ahb",
+		CLK_SET_RATE_PARENT, 0xb8, 0, 0, },
+	{ HISTB_USB2_PHY_CLK, "clk_u2_phy", "60m",
+		CLK_SET_RATE_PARENT, 0xb8, 4, 0, },
+	{ HISTB_USB2_12M_CLK, "clk_u2_12m", "12m",
+		CLK_SET_RATE_PARENT, 0xb8, 2, 0 },
+	{ HISTB_USB2_48M_CLK, "clk_u2_48m", "48m",
+		CLK_SET_RATE_PARENT, 0xb8, 1, 0 },
+	{ HISTB_USB2_UTMI_CLK, "clk_u2_utmi", "60m",
+		CLK_SET_RATE_PARENT, 0xb8, 5, 0 },
+	{ HISTB_USB2_OTG_UTMI_CLK, "clk_u2_otg_utmi", "60m",
+		CLK_SET_RATE_PARENT, 0xb8, 3, 0 },
+	{ HISTB_USB2_PHY1_REF_CLK, "clk_u2_phy1_ref", "24m",
+		CLK_SET_RATE_PARENT, 0xbc, 0, 0 },
+	{ HISTB_USB2_PHY2_REF_CLK, "clk_u2_phy2_ref", "24m",
+		CLK_SET_RATE_PARENT, 0xbc, 2, 0 },
+	/* USB3 */
+	{ HISTB_USB3_BUS_CLK, "clk_u3_bus", NULL,
+		CLK_SET_RATE_PARENT, 0xb0, 0, 0 },
+	{ HISTB_USB3_UTMI_CLK, "clk_u3_utmi", NULL,
+		CLK_SET_RATE_PARENT, 0xb0, 4, 0 },
+	{ HISTB_USB3_PIPE_CLK, "clk_u3_pipe", NULL,
+		CLK_SET_RATE_PARENT, 0xb0, 3, 0 },
+	{ HISTB_USB3_SUSPEND_CLK, "clk_u3_suspend", NULL,
+		CLK_SET_RATE_PARENT, 0xb0, 2, 0 },
+	{ HISTB_USB3_BUS_CLK1, "clk_u3_bus1", NULL,
+		CLK_SET_RATE_PARENT, 0xb0, 16, 0 },
+	{ HISTB_USB3_UTMI_CLK1, "clk_u3_utmi1", NULL,
+		CLK_SET_RATE_PARENT, 0xb0, 20, 0 },
+	{ HISTB_USB3_PIPE_CLK1, "clk_u3_pipe1", NULL,
+		CLK_SET_RATE_PARENT, 0xb0, 19, 0 },
+	{ HISTB_USB3_SUSPEND_CLK1, "clk_u3_suspend1", NULL,
+		CLK_SET_RATE_PARENT, 0xb0, 18, 0 },
+	/* Watchdog */
+	{ HISTB_WDG0_CLK, "clk_wdg0", "24m",
+		CLK_SET_RATE_PARENT, 0x178, 0, 0 },
+	/* SDIO1 */
+	{ HISTB_SDIO1_BIU_CLK, "clk_sdio1_biu", "200m",
+			CLK_SET_RATE_PARENT, 0x28c, 0, 0, },
+	{ HISTB_SDIO1_CIU_CLK, "clk_sdio1_ciu", "sdio1_mux",
+		CLK_SET_RATE_PARENT, 0x28c, 1, 0, },
+};
+
+static int hi3798mv200_clk_init(struct udevice *pdev)
+{
+	struct hisi_clock_data *data = dev_get_priv(pdev);
+
+	return hisi_clk_init(pdev, data);
+}
+
+static int hi3798mv200_clk_register(struct udevice *pdev)
+{
+	struct hisi_clock_data *clk_data = dev_get_priv(pdev);
+	int ret;
+
+	ret = hisi_clk_register_fixed_rate(NULL, hi3798mv200_fixed_rate_clks,
+					   ARRAY_SIZE(hi3798mv200_fixed_rate_clks));
+	if (ret)
+		return ret;
+
+	ret = hisi_clk_register_mux(NULL, hi3798mv200_mux_clks,
+				    ARRAY_SIZE(hi3798mv200_mux_clks), clk_data);
+	if (ret)
+		return ret;
+
+	return hisi_clk_register_gate(NULL, hi3798mv200_gate_clks,
+				      ARRAY_SIZE(hi3798mv200_gate_clks), clk_data);
+}
+
+static int hi3798mv200_clk_bind(struct udevice *pdev)
+{
+	ofnode node = dev_ofnode(pdev);
+
+	/* bind hisilicon_reset driver to our device tree node */
+	return device_bind_driver_to_node(pdev, "hisilicon_reset", "hisilicon_reset", node, NULL);
+};
+
+static const struct udevice_id hi3798mv200_crg_compat[] = {
+	{ .compatible = "hisilicon,hi3798mv200-crg", },
+	{ }
+};
+
+U_BOOT_DRIVER(hi3798mv200_crg) = {
+	.name		= "hi3798mv200_crg",
+	.id		= UCLASS_CLK,
+	.bind		= hi3798mv200_clk_bind,
+	.of_to_plat	= hi3798mv200_clk_init,
+	.priv_auto	= sizeof(struct hisi_clock_data),
+	.probe		= hi3798mv200_clk_register,
+	.of_match	= hi3798mv200_crg_compat,
+	.ops		= &ccf_clk_ops,
+};
diff --git a/drivers/clk/hisilicon/clk.c b/drivers/clk/hisilicon/clk.c
new file mode 100644
index 0000000000..6bd7f9ef60
--- /dev/null
+++ b/drivers/clk/hisilicon/clk.c
@@ -0,0 +1,102 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Hisilicon clock driver
+ * Adapted from linux kernel
+ */
+
+#include <dm/read.h>
+#include <linux/clk-provider.h>
+#include "clk.h"
+
+static spinlock_t lock;
+
+int hisi_clk_init(struct udevice *dev, struct hisi_clock_data *data)
+{
+	data->base = dev_remap_addr(dev);
+	if (!data->base)
+		return -EINVAL;
+
+	return 0;
+}
+
+int hisi_clk_register_fixed_rate(struct device *dev, const struct hisi_fixed_rate_clock *clks,
+				 int nums)
+{
+	struct clk *clk;
+	int i;
+
+	for (i = 0; i < nums; i++) {
+		clk = clk_register_fixed_rate(dev, clks[i].name,
+					      clks[i].fixed_rate);
+		if (IS_ERR(clk)) {
+			pr_err("%s: failed to register clock %s\n",
+			       __func__, clks[i].name);
+			goto err;
+		}
+		clk_dm(clks[i].id, clk);
+	}
+	return 0;
+
+err:
+	return PTR_ERR(clk);
+}
+
+int hisi_clk_register_mux(struct device *dev,
+			  const struct hisi_mux_clock *clks,
+			  int nums,
+			  const struct hisi_clock_data *data)
+{
+	struct clk *clk;
+	void __iomem *base = data->base;
+	int i;
+
+	for (i = 0; i < nums; i++) {
+		u32 mask = BIT(clks[i].width) - 1;
+
+		clk = clk_register_mux_table(dev, clks[i].name,
+					     clks[i].parent_names,
+					     clks[i].num_parents, clks[i].flags,
+					     base + clks[i].offset, clks[i].shift,
+					     mask, clks[i].mux_flags, clks[i].table);
+		if (IS_ERR(clk)) {
+			pr_err("%s: failed to register clock %s\n",
+			       __func__, clks[i].name);
+			goto err;
+		}
+
+		clk_dm(clks[i].id, clk);
+	}
+	return 0;
+
+err:
+	return PTR_ERR(clk);
+}
+
+int hisi_clk_register_gate(struct device *dev, const struct hisi_gate_clock *clks,
+			   int nums, const struct hisi_clock_data *data)
+{
+	struct clk *clk;
+	void __iomem *base = data->base;
+	int i;
+
+	for (i = 0; i < nums; i++) {
+		clk = clk_register_gate(dev, clks[i].name,
+					clks[i].parent_name,
+					clks[i].flags,
+					base + clks[i].offset,
+					clks[i].bit_idx,
+					clks[i].gate_flags,
+					&lock);
+		if (IS_ERR(clk)) {
+			pr_err("%s: failed to register clock %s\n",
+			       __func__, clks[i].name);
+			goto err;
+		}
+
+		clk_dm(clks[i].id, clk);
+	}
+	return 0;
+
+err:
+	return PTR_ERR(clk);
+}
diff --git a/drivers/clk/hisilicon/clk.h b/drivers/clk/hisilicon/clk.h
new file mode 100644
index 0000000000..67c889025d
--- /dev/null
+++ b/drivers/clk/hisilicon/clk.h
@@ -0,0 +1,55 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+/*
+ * Adapted from linux kernel, some functionalities are removed to keep it simple.
+ */
+
+#ifndef	__HISI_CLK_H
+#define	__HISI_CLK_H
+
+#include <linux/types.h>
+
+struct udevice;
+struct device;
+
+struct hisi_clock_data {
+	void __iomem		*base;
+};
+
+struct hisi_fixed_rate_clock {
+	unsigned int		id;
+	char			*name;
+	unsigned long		fixed_rate;
+};
+
+struct hisi_mux_clock {
+	unsigned int		id;
+	const char		*name;
+	const char		*const *parent_names;
+	u8			num_parents;
+	unsigned long		flags;
+	unsigned long		offset;
+	u8			shift;
+	u8			width;
+	u8			mux_flags;
+	u32			*table;
+};
+
+struct hisi_gate_clock {
+	unsigned int		id;
+	const char		*name;
+	const char		*parent_name;
+	unsigned long		flags;
+	unsigned long		offset;
+	u8			bit_idx;
+	u8			gate_flags;
+};
+
+int hisi_clk_init(struct udevice *dev, struct hisi_clock_data *data);
+int hisi_clk_register_fixed_rate(struct device *dev, const struct hisi_fixed_rate_clock *fixed,
+				 int nums);
+int hisi_clk_register_mux(struct device *dev, const struct hisi_mux_clock *mux,
+			  int nums, const struct hisi_clock_data *data);
+int hisi_clk_register_gate(struct device *dev, const struct hisi_gate_clock *gate,
+			   int nums, const struct hisi_clock_data *data);
+
+#endif	/* __HISI_CLK_H */
diff --git a/include/dt-bindings/clock/histb-clock.h b/include/dt-bindings/clock/histb-clock.h
index 8a05790d1a..929e2a4488 100644
--- a/include/dt-bindings/clock/histb-clock.h
+++ b/include/dt-bindings/clock/histb-clock.h
@@ -74,6 +74,9 @@
 #define HISTB_SDIO1_CIU_CLK		52
 #define HISTB_SDIO1_DRV_CLK		53
 #define HISTB_SDIO1_SAMPLE_CLK		54
+#define HISTB_ETH0_PHY_CLK		55
+#define HISTB_ETH1_PHY_CLK		56
+#define HISTB_WDG0_CLK			57
 
 /* Hi3798MV200 specific clocks */
 
@@ -82,6 +85,7 @@
 #define HI3798MV200_GMACIF_CLK		HISTB_ETH0_MACIF_CLK
 #define HI3798MV200_FEMAC_CLK		HISTB_ETH1_MAC_CLK
 #define HI3798MV200_FEMACIF_CLK		HISTB_ETH1_MACIF_CLK
+#define HI3798MV200_FEPHY_CLK		HISTB_ETH1_PHY_CLK
 
 /* clocks provided by mcu CRG */
 #define HISTB_MCE_CLK			1

-- 
2.43.0

