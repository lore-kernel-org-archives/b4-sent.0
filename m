From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 30 Sep 2025 17:37:20 +0800
Subject: [PATCH 07/19] clk: amlogic: Add A4 PLL clock controller driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250930-a4_a5_add_clock_driver-v1-7-a9acf7951589@amlogic.com>
References: <20250930-a4_a5_add_clock_driver-v1-0-a9acf7951589@amlogic.com>
In-Reply-To: <20250930-a4_a5_add_clock_driver-v1-0-a9acf7951589@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759225047; l=7766;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=r2T/Rtty/xWtWoEVg0jJRgxPprY4dwBN+xh/xtueO8k=;
 b=FcB2Wk6gT2QTeY8koVeN6tI+VtN3A39+8fj5YUm4B77UN+jDhyuhYUVpzWVCbR5nfOorYaJxB
 4S2rap79zCUAXnugImsaU4Gz0gDUuBNvhUUKbLovHaqfXIaghPKb8mr
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the PLL clock controller driver for the Amlogic A4 SoC family.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/Kconfig  |  13 +++
 drivers/clk/meson/Makefile |   1 +
 drivers/clk/meson/a4-pll.c | 242 +++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 256 insertions(+)

diff --git a/drivers/clk/meson/Kconfig b/drivers/clk/meson/Kconfig
index 71481607a6d5..2339abfa2c4e 100644
--- a/drivers/clk/meson/Kconfig
+++ b/drivers/clk/meson/Kconfig
@@ -132,6 +132,19 @@ config COMMON_CLK_A1_PERIPHERALS
 	  device, A1 SoC Family. Say Y if you want A1 Peripherals clock
 	  controller to work.
 
+config COMMON_CLK_A4_PLL
+	tristate "Amlogic A4 PLL clock controller"
+	depends on ARM64
+	default ARCH_MESON
+	select COMMON_CLK_MESON_REGMAP
+	select COMMON_CLK_MESON_PLL
+	select COMMON_CLK_MESON_CLKC_UTILS
+	imply COMMON_CLK_SCMI
+	help
+	  Support for the PLL clock controller on Amlogic BA40X device, AKA A4.
+	  Say Y if you want the board to work, because PLLs are the parent
+	  of most peripherals.
+
 config COMMON_CLK_C3_PLL
 	tristate "Amlogic C3 PLL clock controller"
 	depends on ARM64
diff --git a/drivers/clk/meson/Makefile b/drivers/clk/meson/Makefile
index c6998e752c68..22312393663f 100644
--- a/drivers/clk/meson/Makefile
+++ b/drivers/clk/meson/Makefile
@@ -19,6 +19,7 @@ obj-$(CONFIG_COMMON_CLK_AXG) += axg.o axg-aoclk.o
 obj-$(CONFIG_COMMON_CLK_AXG_AUDIO) += axg-audio.o
 obj-$(CONFIG_COMMON_CLK_A1_PLL) += a1-pll.o
 obj-$(CONFIG_COMMON_CLK_A1_PERIPHERALS) += a1-peripherals.o
+obj-$(CONFIG_COMMON_CLK_A4_PLL) += a4-pll.o
 obj-$(CONFIG_COMMON_CLK_C3_PLL) += c3-pll.o
 obj-$(CONFIG_COMMON_CLK_C3_PERIPHERALS) += c3-peripherals.o
 obj-$(CONFIG_COMMON_CLK_GXBB) += gxbb.o gxbb-aoclk.o
diff --git a/drivers/clk/meson/a4-pll.c b/drivers/clk/meson/a4-pll.c
new file mode 100644
index 000000000000..b77d4f610843
--- /dev/null
+++ b/drivers/clk/meson/a4-pll.c
@@ -0,0 +1,242 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Amlogic A4 PLL Controller Driver
+ *
+ * Copyright (c) 2025 Amlogic, inc.
+ * Author: Chuan Liu <chuan.liu@amlogic.com>
+ */
+
+#include <linux/clk-provider.h>
+#include <linux/platform_device.h>
+#include "clk-regmap.h"
+#include "clk-pll.h"
+#include "meson-clkc-utils.h"
+#include <dt-bindings/clock/amlogic,a4-pll-clkc.h>
+
+#define GP0PLL_CTRL0			0x80
+#define GP0PLL_CTRL1			0x84
+#define GP0PLL_CTRL2			0x88
+#define GP0PLL_CTRL3			0x8c
+#define HIFIPLL_CTRL0			0x100
+#define HIFIPLL_CTRL1			0x104
+#define HIFIPLL_CTRL2			0x108
+#define HIFIPLL_CTRL3			0x10c
+
+static const struct reg_sequence a4_gp0_init_regs[] = {
+	{ .reg = GP0PLL_CTRL1, .def = 0x03a00000 },
+	{ .reg = GP0PLL_CTRL2, .def = 0x00040000 },
+	{ .reg = GP0PLL_CTRL3, .def = 0x090da200 }
+};
+
+static const struct pll_mult_range a4_gp0_pll_mult_range = {
+	.min = 67,
+	.max = 133,
+};
+
+static struct clk_regmap a4_gp0_pll_dco = {
+	.data = &(struct meson_clk_pll_data) {
+		.en = {
+			.reg_off = GP0PLL_CTRL0,
+			.shift   = 28,
+			.width   = 1,
+		},
+		.m = {
+			.reg_off = GP0PLL_CTRL0,
+			.shift   = 0,
+			.width   = 9,
+		},
+		.frac = {
+			.reg_off = GP0PLL_CTRL1,
+			.shift   = 0,
+			.width   = 17,
+		},
+		.n = {
+			.reg_off = GP0PLL_CTRL0,
+			.shift   = 16,
+			.width   = 5,
+		},
+		.l = {
+			.reg_off = GP0PLL_CTRL0,
+			.shift   = 31,
+			.width   = 1,
+		},
+		.rst = {
+			.reg_off = GP0PLL_CTRL0,
+			.shift   = 29,
+			.width   = 1,
+		},
+		.l_detect = {
+			.reg_off = GP0PLL_CTRL3,
+			.shift   = 9,
+			.width   = 1,
+		},
+		.range = &a4_gp0_pll_mult_range,
+		.init_regs = a4_gp0_init_regs,
+		.init_count = ARRAY_SIZE(a4_gp0_init_regs),
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "gp0_pll_dco",
+		.ops = &meson_clk_pll_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
+/* The maximum frequency divider supports is 16, not 128(2^7) */
+static const struct clk_div_table a4_gp0_pll_od_table[] = {
+	{ 0,  1 },
+	{ 1,  2 },
+	{ 2,  4 },
+	{ 3,  8 },
+	{ 4, 16 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap a4_gp0_pll = {
+	.data = &(struct clk_regmap_div_data) {
+		.offset = GP0PLL_CTRL0,
+		.shift = 10,
+		.width = 3,
+		.table = a4_gp0_pll_od_table,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "gp0_pll",
+		.ops = &clk_regmap_divider_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&a4_gp0_pll_dco.hw
+		},
+		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
+static const struct reg_sequence a4_hifi_init_regs[] = {
+	{ .reg = HIFIPLL_CTRL1, .def = 0x03a00000 },
+	{ .reg = HIFIPLL_CTRL2, .def = 0x00040000 },
+	{ .reg = HIFIPLL_CTRL3, .def = 0x0a0da200 }
+};
+
+static const struct pll_mult_range a4_hifi_pll_mult_range = {
+	.min = 67,
+	.max = 133,
+};
+
+static struct clk_regmap a4_hifi_pll_dco = {
+	.data = &(struct meson_clk_pll_data) {
+		.en = {
+			.reg_off = HIFIPLL_CTRL0,
+			.shift   = 28,
+			.width   = 1,
+		},
+		.m = {
+			.reg_off = HIFIPLL_CTRL0,
+			.shift   = 0,
+			.width   = 8,
+		},
+		.frac = {
+			.reg_off = HIFIPLL_CTRL1,
+			.shift   = 0,
+			.width   = 17,
+		},
+		.n = {
+			.reg_off = HIFIPLL_CTRL0,
+			.shift   = 16,
+			.width   = 5,
+		},
+		.l = {
+			.reg_off = HIFIPLL_CTRL0,
+			.shift   = 31,
+			.width   = 1,
+		},
+		.rst = {
+			.reg_off = HIFIPLL_CTRL0,
+			.shift   = 29,
+			.width   = 1,
+		},
+		.l_detect = {
+			.reg_off = HIFIPLL_CTRL3,
+			.shift   = 9,
+			.width   = 1,
+		},
+		.range = &a4_hifi_pll_mult_range,
+		.init_regs = a4_hifi_init_regs,
+		.init_count = ARRAY_SIZE(a4_hifi_init_regs),
+		.frac_max = 100000,
+		.flags = CLK_MESON_PLL_ROUND_CLOSEST,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "hifi_pll_dco",
+		.ops = &meson_clk_pll_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
+/* The maximum frequency divider supports is 16, not 128(2^7) */
+static const struct clk_div_table a4_hifi_pll_od_table[] = {
+	{ 0,  1 },
+	{ 1,  2 },
+	{ 2,  4 },
+	{ 3,  8 },
+	{ 4, 16 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap a4_hifi_pll = {
+	.data = &(struct clk_regmap_div_data) {
+		.offset = HIFIPLL_CTRL0,
+		.shift = 10,
+		.width = 3,
+		.table = a4_hifi_pll_od_table,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "hifi_pll",
+		.ops = &clk_regmap_divider_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&a4_hifi_pll_dco.hw
+		},
+		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
+static struct clk_hw *a4_pll_hw_clks[] = {
+	[CLKID_GP0_PLL_DCO]	= &a4_gp0_pll_dco.hw,
+	[CLKID_GP0_PLL]		= &a4_gp0_pll.hw,
+	[CLKID_HIFI_PLL_DCO]	= &a4_hifi_pll_dco.hw,
+	[CLKID_HIFI_PLL]	= &a4_hifi_pll.hw
+};
+
+static const struct meson_clkc_data a4_pll_clkc_data = {
+	.hw_clks = {
+		.hws = a4_pll_hw_clks,
+		.num = ARRAY_SIZE(a4_pll_hw_clks),
+	},
+};
+
+static const struct of_device_id a4_pll_clkc_match_table[] = {
+	{
+		.compatible = "amlogic,a4-pll-clkc",
+		.data = &a4_pll_clkc_data,
+	},
+	{}
+};
+MODULE_DEVICE_TABLE(of, a4_pll_clkc_match_table);
+
+static struct platform_driver a4_pll_clkc_driver = {
+	.probe = meson_clkc_mmio_probe,
+	.driver = {
+		.name = "a4-pll-clkc",
+		.of_match_table = a4_pll_clkc_match_table,
+	},
+};
+module_platform_driver(a4_pll_clkc_driver);
+
+MODULE_DESCRIPTION("Amlogic A4 PLL Clock Controller driver");
+MODULE_AUTHOR("Chuan Liu <chuan.liu@amlogic.com>");
+MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("CLK_MESON");

-- 
2.42.0

