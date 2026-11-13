From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 14 Nov 2026 06:33:33 +0800
Subject: [PATCH 07/19] clk: sunxi-ng: add support for the Allwinner V861
 PRCM CCU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-v861-v1-7-eb71ec3ee523@iscas.ac.cn>
References: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
In-Reply-To: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Guo Ren <guoren@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Han Gao <gaohan@iscas.ac.cn>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Maxime Ripard <mripard@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: Han Gao <rabenda.cn@gmail.com>, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-csky@vger.kernel.org, 
 linux-sunxi@lists.linux.dev, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rtc@vger.kernel.org, 
 linux-gpio@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794609209; l=5653;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=8ySeNhscsjE5lze4jiyfha0KHf5aua/JAy1/q0k9bZM=;
 b=TUadDnW1nSz95FL9u8UFpESvcvkyAkDXY799PTWKc+MXz3CL2hJ0MgSfa4fzi/wKzEafTyb2z
 1/aDVehaxXpD1nxwJWLfn2Jd/OTURblJG5gI4w8XxFdtTqbkeAH1XjH
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the PRCM CCU driver for the V861. It provides the R-AHB and R-APB0
bus clocks and the PPU and RTC gates and resets.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 drivers/clk/sunxi-ng/Kconfig              |  10 +++
 drivers/clk/sunxi-ng/Makefile             |   2 +
 drivers/clk/sunxi-ng/ccu-sun252i-v861-r.c | 110 ++++++++++++++++++++++++++++++
 3 files changed, 122 insertions(+)

diff --git a/drivers/clk/sunxi-ng/Kconfig b/drivers/clk/sunxi-ng/Kconfig
index 890a0cbb45b6..0c591b24f085 100644
--- a/drivers/clk/sunxi-ng/Kconfig
+++ b/drivers/clk/sunxi-ng/Kconfig
@@ -32,6 +32,16 @@ config SUN252I_V861_CCU
 	  reset lines of most peripherals, so it is required on boards
 	  based on this SoC.
 
+config SUN252I_V861_R_CCU
+	tristate "Support for the Allwinner V861 PRCM CCU"
+	default ARCH_SUNXI
+	depends on RISCV || COMPILE_TEST
+	help
+	  Support for the PRCM clock control unit of the Allwinner V861
+	  SoC. It provides the bus clocks and reset lines of the always-on
+	  blocks, such as the RTC and the power management unit, so it is
+	  required on boards based on this SoC.
+
 config SUN50I_A64_CCU
 	tristate "Support for the Allwinner A64 CCU"
 	default ARCH_SUNXI
diff --git a/drivers/clk/sunxi-ng/Makefile b/drivers/clk/sunxi-ng/Makefile
index 01869330dc4e..851c5ae6dc21 100644
--- a/drivers/clk/sunxi-ng/Makefile
+++ b/drivers/clk/sunxi-ng/Makefile
@@ -28,6 +28,7 @@ obj-$(CONFIG_SUNIV_F1C100S_CCU)	+= suniv-f1c100s-ccu.o
 obj-$(CONFIG_SUN20I_D1_CCU)	+= sun20i-d1-ccu.o
 obj-$(CONFIG_SUN20I_D1_R_CCU)	+= sun20i-d1-r-ccu.o
 obj-$(CONFIG_SUN252I_V861_CCU)	+= sun252i-v861-ccu.o
+obj-$(CONFIG_SUN252I_V861_R_CCU)	+= sun252i-v861-r-ccu.o
 obj-$(CONFIG_SUN50I_A64_CCU)	+= sun50i-a64-ccu.o
 obj-$(CONFIG_SUN50I_A100_CCU)	+= sun50i-a100-ccu.o
 obj-$(CONFIG_SUN50I_A100_R_CCU)	+= sun50i-a100-r-ccu.o
@@ -57,6 +58,7 @@ suniv-f1c100s-ccu-y		+= ccu-suniv-f1c100s.o
 sun20i-d1-ccu-y			+= ccu-sun20i-d1.o
 sun20i-d1-r-ccu-y		+= ccu-sun20i-d1-r.o
 sun252i-v861-ccu-y		+= ccu-sun252i-v861.o
+sun252i-v861-r-ccu-y		+= ccu-sun252i-v861-r.o
 sun50i-a64-ccu-y		+= ccu-sun50i-a64.o
 sun50i-a100-ccu-y		+= ccu-sun50i-a100.o
 sun50i-a100-r-ccu-y		+= ccu-sun50i-a100-r.o
diff --git a/drivers/clk/sunxi-ng/ccu-sun252i-v861-r.c b/drivers/clk/sunxi-ng/ccu-sun252i-v861-r.c
new file mode 100644
index 000000000000..9c8de9643722
--- /dev/null
+++ b/drivers/clk/sunxi-ng/ccu-sun252i-v861-r.c
@@ -0,0 +1,110 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2026 Han Gao <gaohan@iscas.ac.cn>
+ *
+ * Based on the A523 PRCM CCU driver:
+ *   Copyright (C) 2024 Arm Ltd.
+ */
+
+#include <linux/clk-provider.h>
+#include <linux/module.h>
+#include <linux/platform_device.h>
+
+#include <dt-bindings/clock/sun252i-v861-r-ccu.h>
+#include <dt-bindings/reset/sun252i-v861-r-ccu.h>
+
+#include "ccu_common.h"
+#include "ccu_reset.h"
+
+#include "ccu_gate.h"
+#include "ccu_mp.h"
+
+static const struct clk_parent_data r_ahb_apb_parents[] = {
+	{ .fw_name = "hosc" },
+	{ .fw_name = "losc" },
+	{ .fw_name = "iosc" },
+	{ .fw_name = "pll-periph" },
+};
+
+static SUNXI_CCU_MP_DATA_WITH_MUX(r_ahb_clk, "r-ahb", r_ahb_apb_parents, 0x000,
+				  0, 5,		/* M */
+				  8, 2,		/* P */
+				  24, 3,	/* mux */
+				  0);
+static const struct clk_hw *r_ahb_hws[] = { &r_ahb_clk.common.hw };
+
+static SUNXI_CCU_MP_DATA_WITH_MUX(r_apb0_clk, "r-apb0", r_ahb_apb_parents,
+				  0x00c,
+				  0, 5,		/* M */
+				  8, 2,		/* P */
+				  24, 3,	/* mux */
+				  0);
+static const struct clk_hw *r_apb0_hws[] = { &r_apb0_clk.common.hw };
+
+static SUNXI_CCU_GATE_HWS(bus_r_ppu_clk, "bus-r-ppu", r_apb0_hws, 0x1ac,
+			  BIT(0), 0);
+static SUNXI_CCU_GATE_HWS(bus_r_rtc_clk, "bus-r-rtc", r_ahb_hws, 0x20c,
+			  BIT(0), 0);
+
+static struct ccu_common *sun252i_v861_r_ccu_clks[] = {
+	&r_ahb_clk.common,
+	&r_apb0_clk.common,
+	&bus_r_ppu_clk.common,
+	&bus_r_rtc_clk.common,
+};
+
+static struct clk_hw_onecell_data sun252i_v861_r_hw_clks = {
+	.num	= CLK_BUS_R_RTC + 1,
+	.hws	= {
+		[CLK_R_AHB]		= &r_ahb_clk.common.hw,
+		[CLK_R_APB0]		= &r_apb0_clk.common.hw,
+		[CLK_BUS_R_PPU]		= &bus_r_ppu_clk.common.hw,
+		[CLK_BUS_R_RTC]		= &bus_r_rtc_clk.common.hw,
+	},
+};
+
+static const struct ccu_reset_map sun252i_v861_r_ccu_resets[] = {
+	[RST_BUS_R_PPU]		= { 0x1ac, BIT(16) },
+	[RST_BUS_R_RTC]		= { 0x20c, BIT(16) },
+};
+
+static const struct sunxi_ccu_desc sun252i_v861_r_ccu_desc = {
+	.ccu_clks	= sun252i_v861_r_ccu_clks,
+	.num_ccu_clks	= ARRAY_SIZE(sun252i_v861_r_ccu_clks),
+
+	.hw_clks	= &sun252i_v861_r_hw_clks,
+
+	.resets		= sun252i_v861_r_ccu_resets,
+	.num_resets	= ARRAY_SIZE(sun252i_v861_r_ccu_resets),
+};
+
+static int sun252i_v861_r_ccu_probe(struct platform_device *pdev)
+{
+	void __iomem *reg;
+
+	reg = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(reg))
+		return PTR_ERR(reg);
+
+	return devm_sunxi_ccu_probe(&pdev->dev, reg, &sun252i_v861_r_ccu_desc);
+}
+
+static const struct of_device_id sun252i_v861_r_ccu_ids[] = {
+	{ .compatible = "allwinner,sun252i-v861-r-ccu" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, sun252i_v861_r_ccu_ids);
+
+static struct platform_driver sun252i_v861_r_ccu_driver = {
+	.probe	= sun252i_v861_r_ccu_probe,
+	.driver	= {
+		.name			= "sun252i-v861-r-ccu",
+		.suppress_bind_attrs	= true,
+		.of_match_table		= sun252i_v861_r_ccu_ids,
+	},
+};
+module_platform_driver(sun252i_v861_r_ccu_driver);
+
+MODULE_IMPORT_NS("SUNXI_CCU");
+MODULE_DESCRIPTION("Support for the Allwinner V861 PRCM CCU");
+MODULE_LICENSE("GPL");

-- 
2.55.0

