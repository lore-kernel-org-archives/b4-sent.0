From: Cunhao Lu <1579567540@qq.com>
Date: Thu, 22 Oct 2026 00:11:04 +0800
Subject: [PATCH 07/27] clk: rockchip: Add RK3572 clock and reset support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-add-board-ok3572-c-v1-7-0b0fd85a31ee@qq.com>
References: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
In-Reply-To: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, Lee Jones <lee@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Jisheng Zhang <jszhang@kernel.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>
Cc: Cunhao Lu <1579567540@qq.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 mfd@lists.linux.dev, linux-gpio@vger.kernel.org, netdev@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-mmc@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-phy@lists.infradead.org, 
 linux-usb@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792599138; l=131949;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=WPH8lfw/lEO+ve3pVI8i6iFQ4XWXNbMdV/4+TIJDBNE=;
 b=QLsa+IgW+PfkxTUxBkIeDoWP0EBPweVMgjuGYSAVBLn2JCZPSMAWIVmcIkmL3e20iFzGeI+wO
 rD5GaYNb652Cbq1xwigr0c8IQ0z/1VZxmbQTQWn58ffbsx99tlRh7gC
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CPU clocks are managed by SCMI. Keep BPLL and LPLL enabled for firmware
consumers.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 drivers/clk/rockchip/Kconfig      |    7 +
 drivers/clk/rockchip/Makefile     |    1 +
 drivers/clk/rockchip/clk-rk3572.c | 1972 +++++++++++++++++++++++++++++++++++++
 drivers/clk/rockchip/clk.h        |   36 +
 drivers/clk/rockchip/rst-rk3572.c |  739 ++++++++++++++
 5 files changed, 2755 insertions(+)

diff --git a/drivers/clk/rockchip/Kconfig b/drivers/clk/rockchip/Kconfig
index 4b55f48d72c2..8efd54fd295d 100644
--- a/drivers/clk/rockchip/Kconfig
+++ b/drivers/clk/rockchip/Kconfig
@@ -142,6 +142,13 @@ config CLK_RK3568
 	help
 	  Build the driver for RK3568 Clock Driver.
 
+config CLK_RK3572
+	bool "Rockchip RK3572 clock controller support"
+	depends on ARM64 || COMPILE_TEST
+	default y
+	help
+	  Build the driver for RK3572 Clock Driver.
+
 config CLK_RK3576
 	bool "Rockchip RK3576 clock controller support"
 	depends on ARM64 || COMPILE_TEST
diff --git a/drivers/clk/rockchip/Makefile b/drivers/clk/rockchip/Makefile
index 554b7eb83dc9..d6a194f7ea2b 100644
--- a/drivers/clk/rockchip/Makefile
+++ b/drivers/clk/rockchip/Makefile
@@ -36,5 +36,6 @@ obj-$(CONFIG_CLK_RK3506)	+= clk-rk3506.o rst-rk3506.o
 obj-$(CONFIG_CLK_RK3528)	+= clk-rk3528.o rst-rk3528.o
 obj-$(CONFIG_CLK_RK3562)	+= clk-rk3562.o rst-rk3562.o
 obj-$(CONFIG_CLK_RK3568)	+= clk-rk3568.o
+obj-$(CONFIG_CLK_RK3572)	+= clk-rk3572.o rst-rk3572.o
 obj-$(CONFIG_CLK_RK3576)	+= clk-rk3576.o rst-rk3576.o
 obj-$(CONFIG_CLK_RK3588)	+= clk-rk3588.o rst-rk3588.o
diff --git a/drivers/clk/rockchip/clk-rk3572.c b/drivers/clk/rockchip/clk-rk3572.c
new file mode 100644
index 000000000000..78fd35f5f27d
--- /dev/null
+++ b/drivers/clk/rockchip/clk-rk3572.c
@@ -0,0 +1,1972 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (c) 2025 Rockchip Electronics Co., Ltd.
+ * Author: Elaine Zhang <zhangqing@rock-chips.com>
+ */
+
+#include <linux/clk-provider.h>
+#include <linux/mfd/syscon.h>
+#include <linux/of.h>
+#include <linux/of_address.h>
+#include <linux/slab.h>
+#include <dt-bindings/clock/rockchip,rk3572-cru.h>
+#include "clk.h"
+
+#define COMPOSITE_MUXTBL(_id, cname, pnames, num, f, mo, ms, mw, mf,	\
+		 mt, ds, dw, df, go, gs, gf)				\
+	{								\
+		.id		= _id,					\
+		.branch_type	= branch_composite,			\
+		.name		= cname,				\
+		.parent_names	= pnames,				\
+		.num_parents	= num,					\
+		.flags		= f,					\
+		.muxdiv_offset	= mo,					\
+		.mux_shift	= ms,					\
+		.mux_width	= mw,					\
+		.mux_flags	= mf,					\
+		.mux_table	= mt,					\
+		.div_shift	= ds,					\
+		.div_width	= dw,					\
+		.div_flags	= df,					\
+		.gate_offset	= go,					\
+		.gate_shift	= gs,					\
+		.gate_flags	= gf,					\
+	}
+
+#define RK3572_GRF_SOC_STATUS0		0x600
+#define RK3572_PMU0_GRF_OSC_CON6	0x18
+
+enum rk3572_plls {
+	bpll, lpll, vpll, aupll, cpll, gpll, ppll,
+};
+
+static struct rockchip_pll_rate_table rk3572_pll_rates[] = {
+	/* _mhz, _p, _m, _s, _k */
+	RK3588_PLL_RATE(2520000000, 2, 210, 0, 0),
+	RK3588_PLL_RATE(2496000000, 2, 208, 0, 0),
+	RK3588_PLL_RATE(2472000000, 2, 206, 0, 0),
+	RK3588_PLL_RATE(2448000000, 2, 204, 0, 0),
+	RK3588_PLL_RATE(2424000000, 2, 202, 0, 0),
+	RK3588_PLL_RATE(2400000000, 2, 200, 0, 0),
+	RK3588_PLL_RATE(2376000000, 2, 198, 0, 0),
+	RK3588_PLL_RATE(2352000000, 2, 196, 0, 0),
+	RK3588_PLL_RATE(2328000000, 2, 194, 0, 0),
+	RK3588_PLL_RATE(2304000000, 2, 192, 0, 0),
+	RK3588_PLL_RATE(2280000000, 2, 190, 0, 0),
+	RK3588_PLL_RATE(2256000000, 2, 376, 1, 0),
+	RK3588_PLL_RATE(2232000000, 2, 372, 1, 0),
+	RK3588_PLL_RATE(2208000000, 2, 368, 1, 0),
+	RK3588_PLL_RATE(2184000000, 2, 364, 1, 0),
+	RK3588_PLL_RATE(2160000000, 2, 360, 1, 0),
+	RK3588_PLL_RATE(2136000000, 2, 356, 1, 0),
+	RK3588_PLL_RATE(2112000000, 2, 352, 1, 0),
+	RK3588_PLL_RATE(2088000000, 2, 348, 1, 0),
+	RK3588_PLL_RATE(2064000000, 2, 344, 1, 0),
+	RK3588_PLL_RATE(2040000000, 2, 340, 1, 0),
+	RK3588_PLL_RATE(2016000000, 2, 336, 1, 0),
+	RK3588_PLL_RATE(1992000000, 2, 332, 1, 0),
+	RK3588_PLL_RATE(1968000000, 2, 328, 1, 0),
+	RK3588_PLL_RATE(1944000000, 2, 324, 1, 0),
+	RK3588_PLL_RATE(1920000000, 2, 320, 1, 0),
+	RK3588_PLL_RATE(1896000000, 2, 316, 1, 0),
+	RK3588_PLL_RATE(1872000000, 2, 312, 1, 0),
+	RK3588_PLL_RATE(1848000000, 2, 308, 1, 0),
+	RK3588_PLL_RATE(1824000000, 2, 304, 1, 0),
+	RK3588_PLL_RATE(1800000000, 2, 300, 1, 0),
+	RK3588_PLL_RATE(1776000000, 2, 296, 1, 0),
+	RK3588_PLL_RATE(1752000000, 2, 292, 1, 0),
+	RK3588_PLL_RATE(1728000000, 2, 288, 1, 0),
+	RK3588_PLL_RATE(1704000000, 2, 284, 1, 0),
+	RK3588_PLL_RATE(1680000000, 2, 280, 1, 0),
+	RK3588_PLL_RATE(1656000000, 2, 276, 1, 0),
+	RK3588_PLL_RATE(1632000000, 2, 272, 1, 0),
+	RK3588_PLL_RATE(1608000000, 2, 268, 1, 0),
+	RK3588_PLL_RATE(1584000000, 2, 264, 1, 0),
+	RK3588_PLL_RATE(1560000000, 2, 260, 1, 0),
+	RK3588_PLL_RATE(1536000000, 2, 256, 1, 0),
+	RK3588_PLL_RATE(1512000000, 2, 252, 1, 0),
+	RK3588_PLL_RATE(1488000000, 2, 248, 1, 0),
+	RK3588_PLL_RATE(1464000000, 2, 244, 1, 0),
+	RK3588_PLL_RATE(1440000000, 2, 240, 1, 0),
+	RK3588_PLL_RATE(1416000000, 2, 236, 1, 0),
+	RK3588_PLL_RATE(1392000000, 2, 232, 1, 0),
+	RK3588_PLL_RATE(1320000000, 2, 220, 1, 0),
+	RK3588_PLL_RATE(1200000000, 2, 200, 1, 0),
+	RK3588_PLL_RATE(1188000000, 2, 198, 1, 0),
+	RK3588_PLL_RATE(1186814000, 2, 198, 1, 52581),
+	RK3588_PLL_RATE(1186812000, 2, 198, 1, 52559),
+	RK3588_PLL_RATE(1109000000, 3, 554, 2, 32767),
+	RK3588_PLL_RATE(1100000000, 3, 550, 2, 0),
+	RK3588_PLL_RATE(1051000000, 3, 525, 2, 32767),
+	RK3588_PLL_RATE(1008000000, 2, 336, 2, 0),
+	RK3588_PLL_RATE(1000000000, 3, 500, 2, 0),
+	RK3588_PLL_RATE(983040000, 4, 655, 2, 23592),
+	RK3588_PLL_RATE(955520000, 3, 478, 2, -15730),
+	RK3588_PLL_RATE(903168000, 6, 903, 2, 11009),
+	RK3588_PLL_RATE(900000000, 2, 300, 2, 0),
+	RK3588_PLL_RATE(816000000, 2, 272, 2, 0),
+	RK3588_PLL_RATE(786432000, 2, 262, 2, 9437),
+	RK3588_PLL_RATE(786000000, 1, 131, 2, 0),
+	RK3588_PLL_RATE(785560000, 3, 393, 2, -14419),
+	RK3588_PLL_RATE(773000000, 2, 258, 2, 43690),
+	RK3588_PLL_RATE(722534400, 8, 963, 2, 24850),
+	RK3588_PLL_RATE(697000000, 2, 232, 2, 21845),
+	RK3588_PLL_RATE(610400000, 3, 305, 2, 13107),
+	RK3588_PLL_RATE(604800000, 1, 101, 2, 52428),
+	RK3588_PLL_RATE(600000000, 2, 200, 2, 0),
+	RK3588_PLL_RATE(594000000, 2, 198, 2, 0),
+	RK3588_PLL_RATE(408000000, 2, 272, 3, 0),
+	RK3588_PLL_RATE(312000000, 2, 208, 3, 0),
+	RK3588_PLL_RATE(266580000, 1, 178, 4, 47185),
+	RK3588_PLL_RATE(216000000, 2, 288, 4, 0),
+	RK3588_PLL_RATE(96000000, 2, 256, 5, 0),
+	{ /* sentinel */ },
+};
+
+static struct rockchip_pll_rate_table rk3572_ppll_rates[] = {
+	/* _mhz, _p, _m, _s, _k */
+	RK3588_PLL_RATE(1300000000, 3, 325, 2, 0),
+	{ /* sentinel */ },
+};
+
+static struct rockchip_pll_rate_table rk3572_aupll_rates[] = {
+	RK3588_PLL_RATE(786000000, 1, 131, 2, 0),
+	{ /* sentinel */ },
+};
+
+#define RK3572_ACLK_M_BIGCORE_DIV_MASK		0x1f
+#define RK3572_ACLK_M_BIGCORE_DIV_SHIFT		9
+#define RK3572_PCLK_DBG_BIGCORE_DIV_MASK	0x1f
+#define RK3572_PCLK_DBG_BIGCORE_DIV_SHIFT	10
+#define RK3572_ACLK_M_LITCORE_DIV_MASK		0x1f
+#define RK3572_ACLK_M_LITCORE_DIV_SHIFT		2
+#define RK3572_PCLK_DBG_LITCORE_DIV_MASK	0x1f
+#define RK3572_PCLK_DBG_LITCORE_DIV_SHIFT	7
+#define RK3572_ACLK_CCI_DIV_MASK		0x1f
+#define RK3572_ACLK_CCI_DIV_SHIFT		7
+#define RK3572_ACLK_CCI_MUX_MASK		0x3
+#define RK3572_ACLK_CCI_MUX_SHIFT		12
+
+#define RK3572_BIGCORE_CLKSEL1(_amcore)						\
+{										\
+	.reg = RK3572_BIGCORE_CLKSEL_CON(1),					\
+	.val = HIWORD_UPDATE((_amcore) - 1, RK3572_ACLK_M_BIGCORE_DIV_MASK,	\
+			RK3572_ACLK_M_BIGCORE_DIV_SHIFT),			\
+}
+
+#define RK3572_BIGCORE_CLKSEL2(_pclkdbg)					\
+{										\
+	.reg = RK3572_BIGCORE_CLKSEL_CON(2),					\
+	.val = HIWORD_UPDATE((_pclkdbg) - 1, RK3572_PCLK_DBG_BIGCORE_DIV_MASK,	\
+			RK3572_PCLK_DBG_BIGCORE_DIV_SHIFT),			\
+}
+
+#define RK3572_LITCORE0_CLKSEL1(_amcore, _pclkdbg)				\
+{										\
+	.reg = RK3572_LITCORE0_CLKSEL_CON(1),					\
+	.val = HIWORD_UPDATE((_amcore) - 1, RK3572_ACLK_M_LITCORE_DIV_MASK,	\
+			RK3572_ACLK_M_LITCORE_DIV_SHIFT) |			\
+	       HIWORD_UPDATE((_pclkdbg) - 1, RK3572_PCLK_DBG_LITCORE_DIV_MASK,	\
+			RK3572_PCLK_DBG_LITCORE_DIV_SHIFT),			\
+}
+
+#define RK3572_LITCORE1_CLKSEL1(_amcore, _pclkdbg)				\
+{										\
+	.reg = RK3572_LITCORE1_CLKSEL_CON(1),					\
+	.val = HIWORD_UPDATE((_amcore) - 1, RK3572_ACLK_M_LITCORE_DIV_MASK,	\
+			RK3572_ACLK_M_LITCORE_DIV_SHIFT) |			\
+	       HIWORD_UPDATE((_pclkdbg) - 1, RK3572_PCLK_DBG_LITCORE_DIV_MASK,	\
+			RK3572_PCLK_DBG_LITCORE_DIV_SHIFT),			\
+}
+
+#define RK3572_CCI_CLKSEL3(_ccisel, _div)					\
+{										\
+	.reg = RK3572_CCI_CLKSEL_CON(3),					\
+	.val = HIWORD_UPDATE(_ccisel, RK3572_ACLK_CCI_MUX_MASK,			\
+			RK3572_ACLK_CCI_MUX_SHIFT) |				\
+	       HIWORD_UPDATE((_div) - 1, RK3572_ACLK_CCI_DIV_MASK,		\
+			RK3572_ACLK_CCI_DIV_SHIFT),				\
+}
+
+#define RK3572_CPUBCLK_RATE(_prate, _amcore, _pclkdbg)				\
+{										\
+	.prate = _prate##U,							\
+	.divs = {								\
+		RK3572_BIGCORE_CLKSEL1(_amcore),				\
+		RK3572_BIGCORE_CLKSEL2(_pclkdbg),				\
+	},									\
+}
+
+#define RK3572_CPUL0CLK_RATE(_prate, _amcore, _pclkdbg, _ccisel)		\
+{										\
+	.prate = _prate##U,							\
+	.divs = {								\
+		RK3572_LITCORE0_CLKSEL1(_amcore, _pclkdbg),			\
+	},									\
+	.pre_muxs = {								\
+		RK3572_CCI_CLKSEL3(1, 2),					\
+	},									\
+	.post_muxs = {								\
+		RK3572_CCI_CLKSEL3(_ccisel, 2),					\
+	},									\
+}
+
+#define RK3572_CPUL1CLK_RATE(_prate, _amcore, _pclkdbg)				\
+{										\
+	.prate = _prate##U,							\
+	.divs = {								\
+		RK3572_LITCORE1_CLKSEL1(_amcore, _pclkdbg),			\
+	},									\
+}
+
+static struct rockchip_cpuclk_rate_table rk3572_cpubclk_rates[] __initdata = {
+	RK3572_CPUBCLK_RATE(2496000000, 2, 6),
+	RK3572_CPUBCLK_RATE(2400000000, 2, 6),
+	RK3572_CPUBCLK_RATE(2304000000, 2, 6),
+	RK3572_CPUBCLK_RATE(2208000000, 2, 6),
+	RK3572_CPUBCLK_RATE(2184000000, 2, 6),
+	RK3572_CPUBCLK_RATE(2088000000, 2, 6),
+	RK3572_CPUBCLK_RATE(2040000000, 2, 6),
+	RK3572_CPUBCLK_RATE(2016000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1992000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1896000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1800000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1704000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1608000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1584000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1560000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1536000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1512000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1488000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1464000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1440000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1416000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1392000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1368000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1344000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1320000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1296000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1272000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1248000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1224000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1200000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1104000000, 2, 6),
+	RK3572_CPUBCLK_RATE(1008000000, 2, 6),
+	RK3572_CPUBCLK_RATE(912000000, 2, 6),
+	RK3572_CPUBCLK_RATE(816000000, 2, 6),
+	RK3572_CPUBCLK_RATE(696000000, 2, 6),
+	RK3572_CPUBCLK_RATE(600000000, 2, 6),
+	RK3572_CPUBCLK_RATE(408000000, 2, 6),
+	RK3572_CPUBCLK_RATE(312000000, 2, 6),
+	RK3572_CPUBCLK_RATE(216000000, 2, 6),
+	RK3572_CPUBCLK_RATE(96000000, 2, 6),
+};
+
+static const struct rockchip_cpuclk_reg_data rk3572_cpubclk_data = {
+	.core_reg[0] = RK3572_BIGCORE_CLKSEL_CON(1),
+	.div_core_shift[0] = 0,
+	.div_core_mask[0] = 0x1f,
+	.num_cores = 1,
+	.mux_core_alt = 1,
+	.mux_core_main = 0,
+	.mux_core_shift = 5,
+	.mux_core_mask = 0x3,
+};
+
+static struct rockchip_cpuclk_rate_table rk3572_cpul0clk_rates[] __initdata = {
+	RK3572_CPUL0CLK_RATE(2400000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(2304000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(2208000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(2184000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(2088000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(2040000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(2016000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1992000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1896000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1800000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1704000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1608000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1584000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1560000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1536000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1512000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1488000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1464000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1440000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1416000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1392000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1368000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1344000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1320000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1296000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1272000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1248000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1224000000, 2, 6, 0),
+	RK3572_CPUL0CLK_RATE(1200000000, 2, 6, 1),
+	RK3572_CPUL0CLK_RATE(1104000000, 2, 6, 1),
+	RK3572_CPUL0CLK_RATE(1008000000, 2, 6, 1),
+	RK3572_CPUL0CLK_RATE(912000000, 2, 6, 1),
+	RK3572_CPUL0CLK_RATE(816000000, 2, 6, 1),
+	RK3572_CPUL0CLK_RATE(696000000, 2, 6, 1),
+	RK3572_CPUL0CLK_RATE(600000000, 2, 6, 1),
+	RK3572_CPUL0CLK_RATE(408000000, 2, 6, 1),
+	RK3572_CPUL0CLK_RATE(312000000, 2, 6, 1),
+	RK3572_CPUL0CLK_RATE(216000000, 2, 6, 1),
+	RK3572_CPUL0CLK_RATE(96000000, 2, 6, 1),
+};
+
+static const struct rockchip_cpuclk_reg_data rk3572_cpul0clk_data = {
+	.core_reg[0] = RK3572_LITCORE0_CLKSEL_CON(0),
+	.div_core_shift[0] = 3,
+	.div_core_mask[0] = 0x1f,
+	.num_cores = 1,
+	.mux_core_alt = 1,
+	.mux_core_main = 0,
+	.mux_core_shift = 8,
+	.mux_core_mask = 0x3,
+};
+
+static struct rockchip_cpuclk_rate_table rk3572_cpul1clk_rates[] __initdata = {
+	RK3572_CPUL1CLK_RATE(2400000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(2304000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(2208000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(2184000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(2088000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(2040000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(2016000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1992000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1896000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1800000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1704000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1608000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1584000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1560000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1536000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1512000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1488000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1464000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1440000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1416000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1392000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1368000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1344000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1320000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1296000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1272000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1248000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1224000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1200000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1188000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1104000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(1008000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(912000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(816000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(696000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(600000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(594000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(408000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(396000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(312000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(216000000, 2, 6),
+	RK3572_CPUL1CLK_RATE(96000000, 2, 6),
+};
+
+#define MFLAGS CLK_MUX_HIWORD_MASK
+#define DFLAGS CLK_DIVIDER_HIWORD_MASK
+#define GFLAGS (CLK_GATE_HIWORD_MASK | CLK_GATE_SET_TO_DISABLE)
+
+PNAME(mux_aupll_ref_p)			= { "xin24m", "aupll_ref_io" };
+PNAME(mux_pll_p)			= { "xin24m", "xin32k" };
+PNAME(mux_aupll_p)			= { "aupll_ref", "xin32k" };
+PNAME(mux_24m_32k_p)			= { "xin24m", "clk_32k" };
+PNAME(gpll_cpll_p)			= { "gpll", "cpll" };
+PNAME(gpll_cpll_24m_p)			= { "gpll", "cpll", "xin24m" };
+PNAME(gpll_cpll_aupll_p)		= { "gpll", "cpll", "aupll" };
+PNAME(gpll_cpll_aupll_24m_p)		= { "gpll", "cpll", "aupll", "xin24m" };
+PNAME(gpll_cpll_spll_aupll_p)		= { "gpll", "cpll", "spll", "aupll" };
+PNAME(gpll_spll_aupll_bpll_p)		= { "gpll", "spll", "aupll", "bpll_dummy" };
+PNAME(gpll_cpll_spll_aupll_bpll_p)	= { "gpll", "cpll", "spll", "aupll", "bpll_dummy" };
+PNAME(gpll_cpll_spll_aupll_bpll_24m_p) = {
+	"gpll", "cpll", "spll", "aupll", "bpll_dummy", "xin24m",
+};
+
+PNAME(gpll_cpll_24m_spll_p)		= { "gpll", "cpll", "xin24m", "spll" };
+PNAME(gpll_cpll_bpll_p)			= { "gpll", "cpll", "bpll_dummy" };
+PNAME(gpll_cpll_spll_bpll_p)		= { "gpll", "cpll", "spll", "bpll_dummy" };
+PNAME(gpll_cpll_aupll_spll_p)		= { "gpll", "cpll", "aupll", "spll" };
+PNAME(gpll_cpll_aupll_spll_bpll_p)	= { "gpll", "cpll", "aupll", "spll", "bpll_dummy" };
+PNAME(gpll_cpll_spll_aupll_24m_p)	= { "gpll", "cpll", "spll", "aupll", "xin24m" };
+PNAME(gpll_spll_cpll_bpll_p)		= { "gpll", "spll", "cpll", "bpll_dummy" };
+PNAME(gpll_cpll_vpll_aupll_bpll_24m_p) = {
+	"gpll", "cpll", "vpll", "aupll", "bpll_dummy", "xin24m",
+};
+
+PNAME(gpll_spll_isppvtpll_bpll_p)	= { "gpll", "spll", "clk_isp_pvtpll_src", "bpll_dummy" };
+PNAME(gpll_cpll_vpll_bpll_p)		= { "gpll", "cpll", "vpll", "bpll_dummy" };
+PNAME(gpll_24m_32k_p)			= { "gpll", "xin24m", "clk_32k" };
+PNAME(mux_24m_spll_gpll_cpll_p)		= {"xin24m", "spll", "gpll", "cpll" };
+PNAME(mux_100m_24m_p)			= { "clk_cpll_div10", "xin24m" };
+PNAME(mux_100m_24m_32k_p)		= { "clk_cpll_div10", "xin24m", "clk_32k" };
+PNAME(mux_100m_50m_24m_p)		= { "clk_cpll_div10", "clk_cpll_div20", "xin24m" };
+PNAME(mux_100m_50m_24m_rc_p) = {
+	"clk_cpll_div10", "clk_cpll_div20", "xin24m", "clk_rcosc",
+};
+
+PNAME(mux_150m_100m_50m_24m_p) = {
+	"clk_gpll_div8", "clk_cpll_div10", "clk_cpll_div20", "xin24m",
+};
+
+PNAME(mux_200m_100m_50m_24m_p) = {
+	"clk_gpll_div6", "clk_cpll_div10", "clk_cpll_div20", "xin24m",
+};
+
+PNAME(mux_300m_200m_100m_24m_p) = {
+	"clk_gpll_div4", "clk_gpll_div6", "clk_cpll_div10", "xin24m",
+};
+
+PNAME(mux_300m_200m_100m_50m_24m_p) = {
+	"clk_gpll_div4", "clk_gpll_div6", "clk_cpll_div10", "clk_cpll_div20", "xin24m",
+};
+
+PNAME(mux_400m_200m_100m_24m_p) = {
+	"clk_gpll_div3", "clk_gpll_div6", "clk_cpll_div10", "xin24m",
+};
+
+PNAME(mux_600m_400m_300m_24m_p) = {
+	"clk_gpll_div2", "clk_gpll_div3", "clk_gpll_div4", "xin24m",
+};
+
+PNAME(mux_500m_250m_100m_24m_p) = {
+	"clk_cpll_div2", "clk_cpll_div4", "clk_cpll_div10", "xin24m",
+};
+
+PNAME(mux_175m_116m_58m_24m_p) = {
+	"clk_spll_div4", "clk_spll_div6", "clk_spll_div12", "xin24m",
+};
+
+PNAME(mux_116m_58m_24m_p)		= { "clk_spll_div6", "clk_spll_div12", "xin24m" };
+PNAME(clk_uart_src_p) = {
+	"gpll", "cpll", "aupll", "xin24m", "clk_uart_frac_0", "clk_uart_frac_1",
+	"clk_uart_frac_2",
+};
+
+PNAME(ref_pulse_p) = {
+	"usb0_sof_clk", "usb1_sof_clk", "gmac0_ptp_pps", "gmac1_ptp_pps", "asrc_ref_pulse",
+};
+
+PNAME(lrck_asrc_src_p) = {
+	"asrc_sai0_fs_inter", "asrc_sai1_fs_inter", "asrc_sai2_fs_inter", "asrc_sai3_fs_inter",
+	"asrc_sai4_fs_inter", "asrc_sai5_fs_inter", "asrc_pdm0_clk", "asrc_spdifrx0_clk",
+	"asrc_spdifrx1_clk", "mclk_asrc0_src_0", "mclk_asrc1_src_1",
+};
+
+PNAME(lrck_asrc_dst_p) = {
+	"asrc_sai0_fs_inter", "asrc_sai1_fs_inter", "asrc_sai2_fs_inter", "asrc_sai3_fs_inter",
+	"asrc_sai4_fs_inter", "asrc_sai5_fs_inter", "asrc_pdm0_clk", "asrc_spdiftx0_clk",
+	"asrc_spdiftx1_clk", "asrc_spdiftx2_clk", "mclk_asrc0_src_0", "mclk_asrc1_src_1",
+};
+
+PNAME(asrc_ref_pulse_p) = {
+	"asrc_sai0_fs_inter", "asrc_sai1_fs_inter", "asrc_sai2_fs_inter", "asrc_sai3_fs_inter",
+	"asrc_sai4_fs_inter", "asrc_sai5_fs_inter", "asrc_spdifrx0_clk", "asrc_spdifrx1_clk",
+};
+
+PNAME(clk_freq_pwm1_p) = {
+	"sai0_mclk_in", "sai1_mclk_in", "sai2_mclk_in", "sai3_mclk_in", "sai4_mclk_in",
+	"sai_sclkin_freq",
+};
+
+PNAME(clk_counter_pwm1_p) = {
+	"sai0_mclk_in", "sai1_mclk_in", "sai2_mclk_in", "sai3_mclk_in", "sai4_mclk_in",
+	"sai_sclkin_counter",
+};
+
+PNAME(sai_sclkin_freq_p) = {
+	"sai0_sclk_in", "sai1_sclk_in", "sai2_sclk_in", "sai3_sclk_in", "sai4_sclk_in",
+};
+
+PNAME(clk_timer7_p) = {
+	"clk_cpll_div10", "xin24m", "mclk_asrc0_src_0", "mclk_asrc1_src_1",
+};
+
+PNAME(clk_timer8_p) = {
+	"clk_cpll_div10", "xin24m", "mclk_asrc0_src_0", "mclk_asrc1_src_1",
+};
+
+PNAME(clk_gmac0_ptp_ref_src_p)		= { "clk_gmac0_ptp_ref_pre", "gmac0_ptp_refclk_in" };
+PNAME(clk_gmac1_ptp_ref_p)		= { "clk_gmac1_ptp_ref_src", "gmac1_ptp_refclk_in" };
+PNAME(clk_ref_pciephy_p) = {
+	"clk_pcie_100m_src", "clk_pcie_100m_nduty_src", "xin24m",
+};
+
+PNAME(dclk_ebc_p)			= { "dclk_ebc_int_src", "dclk_ebc_frac_src" };
+PNAME(hclk_vi_root_p) = {
+	"clk_gpll_div6", "clk_cpll_div10", "aclk_vi_root_inter", "xin24m",
+};
+
+PNAME(dclk_vp0_p)			= { "dclk_vp0_src", "clk_hdmiphy_pixel0" };
+PNAME(dclk_vp1_p)			= { "dclk_vp1_src", "clk_hdmiphy_pixel0" };
+PNAME(mux_24m_frac_int_mclk4_p) = {
+	"xin24m", "clk_audio_frac_0", "clk_audio_frac_1", "clk_audio_frac_2",
+	"clk_audio_frac_3", "clk_audio_int_0", "clk_audio_int_1", "clk_audio_int_2",
+	"sai0_mclk_in", "sai1_mclk_in", "sai2_mclk_in", "sai3_mclk_in",
+};
+
+PNAME(mclk_sai4_p)			= { "mclk_sai4_src", "sai4_mclk_in" };
+PNAME(mclk_sai5_p)			= { "mclk_sai5_src", "sai4_mclk_in" };
+PNAME(mclk_spdif_tx2_p)			= { "mclk_spdif_tx2_src", "sai4_mclk_in" };
+PNAME(clk_ref_osc_mphy_p)		= { "xin24m", "clk_ref_mphy_26m" };
+PNAME(clk_pwm0_osc_p)			= { "xin24m", "clk_rcosc" };
+PNAME(sclk_uart1_p)			= { "clk_uart1_src_top", "xin24m", "clk_rcosc" };
+PNAME(clk_pdm0_p)			= { "clk_pdm0_src_top", "xin24m", "clk_rcosc" };
+PNAME(mclk_pdm0_p)			= { "mclk_pdm0_src_top", "xin24m", "clk_rcosc" };
+PNAME(pclk_phpsubsys_root_p)		= { "clk_cpll_div10_phpphy", "xin24m" };
+PNAME(mux_armclkl0_p)			= { "lpll", "gpll", "litcore0pvtpll" };
+PNAME(mux_armclkb_p)			= { "bpll", "gpll", "bigcorepvtpll" };
+PNAME(mux_armclkl1_p)			= { "lpll_dummy", "gpll", "litcore1pvtpll" };
+PNAME(sclk_apb2asb_src_p) = {
+	"spll", "clk_gpll_div2", "clk_cpll_div2", "clk_gpll_div3", "clk_gpll_div4",
+};
+
+PNAME(sclk_apb2asb_p) = {
+	"sclk_apb2asb_src", "clk_gpll_div6", "clk_cpll_div10", "xin24m",
+};
+
+PNAME(mux_24m_frac_int_mclki_p) = {
+	"xin24m", "clk_audio_int_0", "clk_audio_int_1", "clk_audio_int_2", "clk_audio_frac_0",
+	"clk_audio_frac_1", "clk_audio_frac_2", "clk_audio_frac_3", "sai0_mclk_in",
+	"sai1_mclk_in", "sai2_mclk_in", "sai3_mclk_in", "sai4_mclk_in",
+};
+
+PNAME(mux_24m_frac_int_mclki_sclki_p) = {
+	"xin24m", "clk_audio_int_0", "clk_audio_int_1", "clk_audio_int_2", "clk_audio_frac_0",
+	"clk_audio_frac_1", "clk_audio_frac_2", "clk_audio_frac_3", "sai0_mclk_in",
+	"sai1_mclk_in", "sai2_mclk_in", "sai3_mclk_in", "sai4_mclk_in", "sai0_sclk_in",
+	"sai1_sclk_in", "sai2_sclk_in", "sai3_sclk_in", "sai4_sclk_in",
+};
+
+static u32 mux_24m_frac_int_mclki_idx[] = {
+	0, 5, 6, 7, 1, 2, 3, 4, 8, 9, 10, 11, 12,
+};
+
+static u32 mux_24m_frac_int_mclki_sclki_idx[] = {
+	0, 5, 6, 7, 1, 2, 3, 4, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
+};
+
+static struct rockchip_pll_clock rk3572_pll_clks[] __initdata = {
+	/* Keep BPLL and LPLL enabled for firmware consumers. */
+	[bpll] = PLL(pll_rk3588_core, PLL_BPLL, "bpll", mux_pll_p,
+		     CLK_IGNORE_UNUSED, RK3572_PLL_CON(0),
+		     RK3572_MODE_CON1, 0, 15, 0, rk3572_pll_rates),
+	[lpll] = PLL(pll_rk3588_core, PLL_LPLL, "lpll", mux_pll_p,
+		     CLK_IGNORE_UNUSED, RK3572_LPLL_CON(16),
+		     RK3572_LPLL_MODE_CON0, 0, 15, 0, rk3572_pll_rates),
+	[vpll] = PLL(pll_rk3588, PLL_VPLL, "vpll", mux_pll_p,
+		     0, RK3572_PLL_CON(88),
+		     RK3572_MODE_CON0, 4, 15, 0, rk3572_pll_rates),
+	[aupll] = PLL(pll_rk3588, PLL_AUPLL, "aupll", mux_aupll_p,
+		     0, RK3572_PLL_CON(96),
+		     RK3572_MODE_CON0, 6, 15, 0, rk3572_aupll_rates),
+	[cpll] = PLL(pll_rk3588, PLL_CPLL, "cpll", mux_pll_p,
+		     0, RK3572_PLL_CON(104),
+		     RK3572_MODE_CON0, 8, 15, 0, rk3572_pll_rates),
+	[gpll] = PLL(pll_rk3588, PLL_GPLL, "gpll", mux_pll_p,
+		     CLK_IGNORE_UNUSED, RK3572_PLL_CON(112),
+		     RK3572_MODE_CON0, 2, 15, 0, rk3572_pll_rates),
+	[ppll] = PLL(pll_rk3588_ddr, PLL_PPLL, "ppll", mux_pll_p,
+		     0, RK3572_PPLL_CON(128),
+		     RK3572_PPLL_CON(134), 15, 15, 0, rk3572_ppll_rates),
+};
+
+static struct rockchip_clk_branch rk3572_clk_branches[] __initdata = {
+	/* fixed */
+	FACTOR(0, "xin12m", "xin24m", 0, 1, 2),
+
+	COMPOSITE_FRACMUX(CLK_32K, "clk_32k", "xin24m", CLK_IS_CRITICAL,
+			  RK3572_PMU_CLKSEL_CON(21), 0,
+			RK3572_PMU_CLKGATE_CON(7), 14, GFLAGS, NULL),
+
+	FACTOR(0, "clk_spll_div12", "spll", 0, 1, 12),
+	FACTOR(0, "clk_spll_div6", "spll", 0, 1, 6),
+	FACTOR(0, "clk_spll_div4", "spll", 0, 1, 4),
+	FACTOR(0, "clk_spll_div2", "spll", 0, 1, 2),
+
+	COMPOSITE(CLK_CPLL_DIV20, "clk_cpll_div20", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(0), 5, 1, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(0), 1, GFLAGS),
+	COMPOSITE(CLK_CPLL_DIV10, "clk_cpll_div10", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(0), 11, 1, MFLAGS, 6, 5, DFLAGS,
+			RK3572_CLKGATE_CON(0), 2, GFLAGS),
+	COMPOSITE(CLK_GPLL_DIV8, "clk_gpll_div8", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(1), 5, 1, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(0), 3, GFLAGS),
+	COMPOSITE(CLK_GPLL_DIV6, "clk_gpll_div6", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(1), 11, 1, MFLAGS, 6, 5, DFLAGS,
+			RK3572_CLKGATE_CON(0), 4, GFLAGS),
+	COMPOSITE(CLK_CPLL_DIV4, "clk_cpll_div4", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(2), 5, 1, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(0), 5, GFLAGS),
+	COMPOSITE(CLK_GPLL_DIV4, "clk_gpll_div4", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(2), 11, 1, MFLAGS, 6, 5, DFLAGS,
+			RK3572_CLKGATE_CON(0), 6, GFLAGS),
+	COMPOSITE(CLK_GPLL_DIV3, "clk_gpll_div3", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(3), 12, 1, MFLAGS, 7, 5, DFLAGS,
+			RK3572_CLKGATE_CON(0), 8, GFLAGS),
+	COMPOSITE(CLK_CPLL_DIV2, "clk_cpll_div2", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(4), 11, 1, MFLAGS, 6, 5, DFLAGS,
+			RK3572_CLKGATE_CON(0), 10, GFLAGS),
+	COMPOSITE(CLK_GPLL_DIV2, "clk_gpll_div2", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(5), 5, 1, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(0), 11, GFLAGS),
+	COMPOSITE_NODIV(SCLK_APB2ASB_SRC, "sclk_apb2asb_src", sclk_apb2asb_src_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(6), 13, 3, MFLAGS,
+			RK3572_CLKGATE_CON(0), 15, GFLAGS),
+	COMPOSITE(CLK_DDRPHY_TOP_SRC, "clk_ddrphy_top_src", gpll_cpll_spll_aupll_p, CLK_IS_CRITICAL,
+		  RK3572_CLKSEL_CON(8), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(1), 1, GFLAGS),
+	COMPOSITE_NODIV(PCLK_TOP_ROOT, "pclk_top_root", mux_100m_50m_24m_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(8), 7, 2, MFLAGS,
+			RK3572_CLKGATE_CON(1), 2, GFLAGS),
+	COMPOSITE(ACLK_TOP, "aclk_top", gpll_cpll_spll_aupll_p, CLK_IS_CRITICAL,
+		  RK3572_CLKSEL_CON(9), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(1), 4, GFLAGS),
+	COMPOSITE(ACLK_TOP_MID, "aclk_top_mid", gpll_cpll_p, CLK_IS_CRITICAL,
+		  RK3572_CLKSEL_CON(10), 5, 1, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(1), 7, GFLAGS),
+	COMPOSITE(ACLK_SECURE_HIGH, "aclk_secure_high", gpll_spll_aupll_bpll_p, CLK_IS_CRITICAL,
+		  RK3572_CLKSEL_CON(10), 11, 2, MFLAGS, 6, 5, DFLAGS,
+			RK3572_CLKGATE_CON(1), 8, GFLAGS),
+	COMPOSITE_NOMUX(CLK_BPLL_DIV, "clk_bpll_div", "bpll", 0,
+			RK3572_CLKSEL_CON(11), 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(1), 9, GFLAGS),
+
+	MUX(CLK_AUDIO_FRAC_0_SRC, "clk_audio_frac_0_src", gpll_cpll_aupll_24m_p, 0,
+	    RK3572_CLKSEL_CON(13), 0, 2, MFLAGS),
+	MUX(CLK_AUDIO_FRAC_1_SRC, "clk_audio_frac_1_src", gpll_cpll_aupll_24m_p, 0,
+	    RK3572_CLKSEL_CON(15), 0, 2, MFLAGS),
+	MUX(CLK_AUDIO_FRAC_2_SRC, "clk_audio_frac_2_src", gpll_cpll_aupll_24m_p, 0,
+	    RK3572_CLKSEL_CON(17), 0, 2, MFLAGS),
+	MUX(CLK_AUDIO_FRAC_3_SRC, "clk_audio_frac_3_src", gpll_cpll_aupll_24m_p, 0,
+	    RK3572_CLKSEL_CON(19), 0, 2, MFLAGS),
+	COMPOSITE_FRAC(CLK_AUDIO_FRAC_3, "clk_audio_frac_3", "clk_audio_frac_3_src", 0,
+		       RK3572_CLKSEL_CON(18), 0,
+			RK3572_CLKGATE_CON(1), 14, GFLAGS),
+	COMPOSITE_NODIV(HCLK_TOP, "hclk_top", mux_200m_100m_50m_24m_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(19), 2, 2, MFLAGS,
+			RK3572_CLKGATE_CON(1), 15, GFLAGS),
+	MUX(CLK_UART_FRAC_0_SRC, "clk_uart_frac_0_src", gpll_cpll_aupll_24m_p, 0,
+	    RK3572_CLKSEL_CON(23), 0, 2, MFLAGS),
+	COMPOSITE_FRAC(CLK_UART_FRAC_0, "clk_uart_frac_0", "clk_uart_frac_0_src", 0,
+		       RK3572_CLKSEL_CON(22), 0,
+			RK3572_CLKGATE_CON(2), 6, GFLAGS),
+	MUX(CLK_UART_FRAC_1_SRC, "clk_uart_frac_1_src", gpll_cpll_aupll_24m_p, 0,
+	    RK3572_CLKSEL_CON(25), 0, 2, MFLAGS),
+	COMPOSITE_FRAC(CLK_UART_FRAC_1, "clk_uart_frac_1", "clk_uart_frac_1_src", 0,
+		       RK3572_CLKSEL_CON(24), 0,
+			RK3572_CLKGATE_CON(2), 7, GFLAGS),
+	MUX(CLK_UART_FRAC_2_SRC, "clk_uart_frac_2_src", gpll_cpll_aupll_24m_p, 0,
+	    RK3572_CLKSEL_CON(27), 0, 2, MFLAGS),
+	COMPOSITE_FRAC(CLK_UART_FRAC_2, "clk_uart_frac_2", "clk_uart_frac_2_src", 0,
+		       RK3572_CLKSEL_CON(26), 0,
+			RK3572_CLKGATE_CON(2), 8, GFLAGS),
+	COMPOSITE(CLK_UART1_SRC_TOP, "clk_uart1_src_top", clk_uart_src_p, 0,
+		  RK3572_CLKSEL_CON(29), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(2), 14, GFLAGS),
+	COMPOSITE_NOMUX(CLK_AUDIO_INT_0, "clk_audio_int_0", "aupll", 0,
+			RK3572_CLKSEL_CON(29), 11, 5, DFLAGS,
+			RK3572_CLKGATE_CON(2), 15, GFLAGS),
+	COMPOSITE_NOMUX(CLK_AUDIO_INT_1, "clk_audio_int_1", "aupll", 0,
+			RK3572_CLKSEL_CON(30), 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(3), 0, GFLAGS),
+	COMPOSITE_NOMUX(CLK_AUDIO_INT_2, "clk_audio_int_2", "aupll", 0,
+			RK3572_CLKSEL_CON(30), 5, 5, DFLAGS,
+			RK3572_CLKGATE_CON(3), 1, GFLAGS),
+	COMPOSITE_MUXTBL(CLK_PDM0_SRC_TOP, "clk_pdm0_src_top", mux_24m_frac_int_mclki_p,
+			 ARRAY_SIZE(mux_24m_frac_int_mclki_p), 0,
+			 RK3572_CLKSEL_CON(31), 9, 4, MFLAGS, mux_24m_frac_int_mclki_idx, 0, 9,
+			 DFLAGS,
+			RK3572_CLKGATE_CON(3), 3, GFLAGS),
+	COMPOSITE_NOMUX(CLK_GMAC0_125M_SRC, "clk_gmac0_125m_src", "cpll", 0,
+			RK3572_CLKSEL_CON(33), 10, 5, DFLAGS,
+			RK3572_CLKGATE_CON(3), 7, GFLAGS),
+	COMPOSITE_NOMUX(CLK_GMAC1_125M_SRC, "clk_gmac1_125m_src", "cpll", 0,
+			RK3572_CLKSEL_CON(34), 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(3), 8, GFLAGS),
+	COMPOSITE_MUXTBL(MCLK_ASRC0_SRC_0, "mclk_asrc0_src_0", mux_24m_frac_int_mclki_sclki_p,
+			 ARRAY_SIZE(mux_24m_frac_int_mclki_sclki_p), 0,
+			 RK3572_CLKSEL_CON(34), 10, 5, MFLAGS, mux_24m_frac_int_mclki_sclki_idx,
+			 5, 5, DFLAGS,
+			RK3572_CLKGATE_CON(3), 11, GFLAGS),
+	COMPOSITE_MUXTBL(MCLK_ASRC1_SRC_1, "mclk_asrc1_src_1", mux_24m_frac_int_mclki_sclki_p,
+			 ARRAY_SIZE(mux_24m_frac_int_mclki_sclki_p), 0,
+			 RK3572_CLKSEL_CON(35), 5, 5, MFLAGS, mux_24m_frac_int_mclki_sclki_idx,
+			 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(3), 12, GFLAGS),
+	COMPOSITE(REF_CLK0_OUT_PLL, "ref_clk0_out_pll", gpll_cpll_spll_aupll_bpll_24m_p, 0,
+		  RK3572_CLKSEL_CON(38), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(4), 2, GFLAGS),
+	COMPOSITE(REF_CLK1_OUT_PLL, "ref_clk1_out_pll", gpll_cpll_spll_aupll_bpll_24m_p, 0,
+		  RK3572_CLKSEL_CON(39), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(4), 3, GFLAGS),
+	COMPOSITE(REF_CLK2_OUT_PLL, "ref_clk2_out_pll", gpll_cpll_spll_aupll_bpll_24m_p, 0,
+		  RK3572_CLKSEL_CON(40), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(4), 4, GFLAGS),
+	COMPOSITE(REFCLKO25M_GMAC0_OUT, "refclko25m_gmac0_out", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(42), 7, 1, MFLAGS, 0, 7, DFLAGS,
+			RK3572_CLKGATE_CON(5), 6, GFLAGS),
+	COMPOSITE(REFCLKO25M_GMAC1_OUT, "refclko25m_gmac1_out", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(42), 15, 1, MFLAGS, 8, 7, DFLAGS,
+			RK3572_CLKGATE_CON(5), 7, GFLAGS),
+	COMPOSITE(CLK_CIFOUT_OUT, "clk_cifout_out", gpll_cpll_24m_spll_p, 0,
+		  RK3572_CLKSEL_CON(43), 8, 2, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(5), 8, GFLAGS),
+	GATE(CLK_GMAC0_RMII_CRU, "clk_gmac0_rmii_cru", "clk_cpll_div20", 0,
+	     RK3572_CLKGATE_CON(5), 9, GFLAGS),
+	GATE(CLK_GMAC1_RMII_CRU, "clk_gmac1_rmii_cru", "clk_cpll_div20", 0,
+	     RK3572_CLKGATE_CON(5), 10, GFLAGS),
+	GATE(CLK_OTPC_AUTO_RD_G, "clk_otpc_auto_rd_g", "xin24m", 0,
+	     RK3572_CLKGATE_CON(5), 11, GFLAGS),
+	COMPOSITE(CAM_CLK0_OUT_IOUT, "cam_clk0_out_iout", mux_24m_spll_gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(44), 8, 2, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(5), 15, GFLAGS),
+	COMPOSITE(CAM_CLK1_OUT_IOUT, "cam_clk1_out_iout", mux_24m_spll_gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(45), 8, 2, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(6), 0, GFLAGS),
+	COMPOSITE(CAM_CLK2_OUT_IOUT, "cam_clk2_out_iout", mux_24m_spll_gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(46), 8, 2, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(6), 1, GFLAGS),
+	COMPOSITE_MUXTBL(MCLK_PDM0_SRC_TOP, "mclk_pdm0_src_top", mux_24m_frac_int_mclki_p,
+			 ARRAY_SIZE(mux_24m_frac_int_mclki_p), 0,
+			 RK3572_CLKSEL_CON(47), 9, 4, MFLAGS, mux_24m_frac_int_mclki_idx, 0, 9,
+			 DFLAGS,
+			RK3572_CLKGATE_CON(6), 10, GFLAGS),
+	COMPOSITE_NODIV(HCLK_AUDIO_ROOT, "hclk_audio_root", mux_200m_100m_50m_24m_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(49), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(7), 1, GFLAGS),
+	GATE(HCLK_ASRC_2CH_0, "hclk_asrc_2ch_0", "hclk_audio_root", 0,
+	     RK3572_CLKGATE_CON(7), 3, GFLAGS),
+	GATE(HCLK_ASRC_2CH_1, "hclk_asrc_2ch_1", "hclk_audio_root", 0,
+	     RK3572_CLKGATE_CON(7), 4, GFLAGS),
+	COMPOSITE(CLK_ASRC_2CH_0, "clk_asrc_2ch_0", gpll_cpll_aupll_p, 0,
+		  RK3572_CLKSEL_CON(49), 7, 2, MFLAGS, 2, 5, DFLAGS,
+			RK3572_CLKGATE_CON(7), 7, GFLAGS),
+	COMPOSITE(CLK_ASRC_2CH_1, "clk_asrc_2ch_1", gpll_cpll_aupll_p, 0,
+		  RK3572_CLKSEL_CON(49), 14, 2, MFLAGS, 9, 5, DFLAGS,
+			RK3572_CLKGATE_CON(7), 8, GFLAGS),
+	COMPOSITE_MUXTBL(MCLK_SAI0, "mclk_sai0", mux_24m_frac_int_mclki_p,
+			 ARRAY_SIZE(mux_24m_frac_int_mclki_p), 0,
+			 RK3572_CLKSEL_CON(51), 11, 4, MFLAGS, mux_24m_frac_int_mclki_idx, 3, 8,
+			 DFLAGS,
+			RK3572_CLKGATE_CON(7), 12, GFLAGS),
+	GATE(HCLK_SAI0, "hclk_sai0", "hclk_audio_root", 0,
+	     RK3572_CLKGATE_CON(7), 13, GFLAGS),
+	GATE(HCLK_SPDIF_RX0, "hclk_spdif_rx0", "hclk_audio_root", 0,
+	     RK3572_CLKGATE_CON(7), 14, GFLAGS),
+	COMPOSITE(MCLK_SPDIF_RX0, "mclk_spdif_rx0", gpll_cpll_aupll_p, 0,
+		  RK3572_CLKSEL_CON(52), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(7), 15, GFLAGS),
+	COMPOSITE_MUXTBL(MCLK_SAI1, "mclk_sai1", mux_24m_frac_int_mclki_p,
+			 ARRAY_SIZE(mux_24m_frac_int_mclki_p), 0,
+			 RK3572_CLKSEL_CON(54), 8, 4, MFLAGS, mux_24m_frac_int_mclki_idx, 0, 8,
+			 DFLAGS,
+			RK3572_CLKGATE_CON(8), 5, GFLAGS),
+	GATE(HCLK_SAI1, "hclk_sai1", "hclk_audio_root", 0,
+	     RK3572_CLKGATE_CON(8), 6, GFLAGS),
+	COMPOSITE_MUXTBL(MCLK_SAI2, "mclk_sai2", mux_24m_frac_int_mclki_p,
+			 ARRAY_SIZE(mux_24m_frac_int_mclki_p), 0,
+			 RK3572_CLKSEL_CON(56), 8, 4, MFLAGS, mux_24m_frac_int_mclki_idx, 0, 8,
+			 DFLAGS,
+			RK3572_CLKGATE_CON(8), 8, GFLAGS),
+	GATE(HCLK_SAI2, "hclk_sai2", "hclk_audio_root", 0,
+	     RK3572_CLKGATE_CON(8), 10, GFLAGS),
+	COMPOSITE_MUXTBL(MCLK_SAI3, "mclk_sai3", mux_24m_frac_int_mclki_p,
+			 ARRAY_SIZE(mux_24m_frac_int_mclki_p), 0,
+			 RK3572_CLKSEL_CON(58), 8, 4, MFLAGS, mux_24m_frac_int_mclki_idx, 0, 8,
+			 DFLAGS,
+			RK3572_CLKGATE_CON(8), 12, GFLAGS),
+	GATE(HCLK_SAI3, "hclk_sai3", "hclk_audio_root", 0,
+	     RK3572_CLKGATE_CON(8), 14, GFLAGS),
+	GATE(CLK_SAI1_MCLKOUT, "clk_sai1_mclkout", "mclk_sai1", 0,
+	     RK3572_CLKGATE_CON(4), 10, GFLAGS),
+	GATE(CLK_SAI2_MCLKOUT, "clk_sai2_mclkout", "mclk_sai2", 0,
+	     RK3572_CLKGATE_CON(4), 11, GFLAGS),
+	GATE(CLK_SAI3_MCLKOUT, "clk_sai3_mclkout", "mclk_sai3", 0,
+	     RK3572_CLKGATE_CON(4), 12, GFLAGS),
+	GATE(CLK_SAI0_MCLKOUT, "clk_sai0_mclkout", "mclk_sai0", 0,
+	     RK3572_CLKGATE_CON(4), 14, GFLAGS),
+	GATE(HCLK_ACDCDIG_DSM, "hclk_acdcdig_dsm", "hclk_audio_root", 0,
+	     RK3572_CLKGATE_CON(8), 15, GFLAGS),
+	GATE(MCLK_ACDCDIG_DSM, "mclk_acdcdig_dsm", "mclk_sai3", 0,
+	     RK3572_CLKGATE_CON(9), 0, GFLAGS),
+	COMPOSITE_NODIV(PCLK_AUDIO_ROOT, "pclk_audio_root", mux_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(60), 12, 2, MFLAGS,
+			RK3572_CLKGATE_CON(9), 3, GFLAGS),
+	GATE(HCLK_SPDIF_TX0, "hclk_spdif_tx0", "hclk_audio_root", 0,
+	     RK3572_CLKGATE_CON(9), 6, GFLAGS),
+	COMPOSITE_MUXTBL(MCLK_SPDIF_TX0, "mclk_spdif_tx0", mux_24m_frac_int_mclki_p,
+			 ARRAY_SIZE(mux_24m_frac_int_mclki_p), 0,
+			 RK3572_CLKSEL_CON(61), 8, 4, MFLAGS, mux_24m_frac_int_mclki_idx, 0, 8,
+			 DFLAGS,
+			RK3572_CLKGATE_CON(9), 7, GFLAGS),
+	GATE(HCLK_SPDIF_TX1, "hclk_spdif_tx1", "hclk_audio_root", 0,
+	     RK3572_CLKGATE_CON(9), 8, GFLAGS),
+	COMPOSITE_MUXTBL(MCLK_SPDIF_TX1, "mclk_spdif_tx1", mux_24m_frac_int_mclki_p,
+			 ARRAY_SIZE(mux_24m_frac_int_mclki_p), 0,
+			 RK3572_CLKSEL_CON(62), 8, 4, MFLAGS, mux_24m_frac_int_mclki_idx, 0, 8,
+			 DFLAGS,
+			RK3572_CLKGATE_CON(9), 9, GFLAGS),
+	COMPOSITE_NODIV(HCLK_BUS_ROOT, "hclk_bus_root", mux_200m_100m_50m_24m_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(64), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(11), 0, GFLAGS),
+	COMPOSITE_NODIV(PCLK_BUS_ROOT, "pclk_bus_root", mux_100m_50m_24m_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(64), 2, 2, MFLAGS,
+			RK3572_CLKGATE_CON(11), 1, GFLAGS),
+	COMPOSITE(ACLK_BUS_ROOT, "aclk_bus_root", gpll_cpll_p, CLK_IS_CRITICAL,
+		  RK3572_CLKSEL_CON(64), 9, 1, MFLAGS, 4, 5, DFLAGS,
+			RK3572_CLKGATE_CON(11), 2, GFLAGS),
+	GATE(HCLK_CAN0, "hclk_can0", "hclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(11), 7, GFLAGS),
+	COMPOSITE(CLK_CAN0, "clk_can0", gpll_cpll_24m_p, 0,
+		  RK3572_CLKSEL_CON(65), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(11), 8, GFLAGS),
+	GATE(HCLK_CAN1, "hclk_can1", "hclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(11), 9, GFLAGS),
+	COMPOSITE(CLK_CAN1, "clk_can1", gpll_cpll_24m_p, 0,
+		  RK3572_CLKSEL_CON(65), 12, 2, MFLAGS, 7, 5, DFLAGS,
+			RK3572_CLKGATE_CON(11), 10, GFLAGS),
+	GATE(HCLK_CAN2, "hclk_can2", "hclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(11), 11, GFLAGS),
+	COMPOSITE(CLK_CAN2, "clk_can2", gpll_cpll_24m_p, 0,
+		  RK3572_CLKSEL_CON(66), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(11), 12, GFLAGS),
+	GATE(HCLK_CAN3, "hclk_can3", "hclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(11), 13, GFLAGS),
+	COMPOSITE(CLK_CAN3, "clk_can3", gpll_cpll_24m_p, 0,
+		  RK3572_CLKSEL_CON(66), 12, 2, MFLAGS, 7, 5, DFLAGS,
+			RK3572_CLKGATE_CON(11), 14, GFLAGS),
+	COMPOSITE(ACLK_DECOM_ROOT, "aclk_decom_root", gpll_cpll_spll_bpll_p, 0,
+		  RK3572_CLKSEL_CON(67), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(11), 15, GFLAGS),
+	GATE(PCLK_I2C1, "pclk_i2c1", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(12), 5, GFLAGS),
+	GATE(PCLK_I2C2, "pclk_i2c2", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(12), 6, GFLAGS),
+	GATE(PCLK_I2C3, "pclk_i2c3", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(12), 7, GFLAGS),
+	GATE(PCLK_I2C4, "pclk_i2c4", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(12), 8, GFLAGS),
+	GATE(PCLK_I2C5, "pclk_i2c5", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(12), 9, GFLAGS),
+	GATE(PCLK_I2C6, "pclk_i2c6", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(12), 10, GFLAGS),
+	GATE(PCLK_I2C7, "pclk_i2c7", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(12), 11, GFLAGS),
+	GATE(PCLK_I2C8, "pclk_i2c8", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(12), 12, GFLAGS),
+	GATE(PCLK_I2C9, "pclk_i2c9", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(12), 13, GFLAGS),
+	GATE(PCLK_WDT_BUSMCU, "pclk_wdt_busmcu", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(12), 14, GFLAGS),
+	GATE(TCLK_WDT_BUSMCU, "tclk_wdt_busmcu", "xin24m", 0,
+	     RK3572_CLKGATE_CON(12), 15, GFLAGS),
+	GATE(ACLK_GIC, "aclk_gic", "aclk_bus_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(13), 0, GFLAGS),
+	COMPOSITE_NODIV(CLK_I2C1, "clk_i2c1", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(67), 7, 2, MFLAGS,
+			RK3572_CLKGATE_CON(13), 5, GFLAGS),
+	COMPOSITE_NODIV(CLK_I2C2, "clk_i2c2", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(67), 9, 2, MFLAGS,
+			RK3572_CLKGATE_CON(13), 6, GFLAGS),
+	COMPOSITE_NODIV(CLK_I2C3, "clk_i2c3", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(67), 11, 2, MFLAGS,
+			RK3572_CLKGATE_CON(13), 7, GFLAGS),
+	COMPOSITE_NODIV(CLK_I2C4, "clk_i2c4", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(67), 13, 2, MFLAGS,
+			RK3572_CLKGATE_CON(13), 8, GFLAGS),
+	COMPOSITE_NODIV(CLK_I2C5, "clk_i2c5", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(68), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(13), 9, GFLAGS),
+	COMPOSITE_NODIV(CLK_I2C6, "clk_i2c6", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(68), 2, 2, MFLAGS,
+			RK3572_CLKGATE_CON(13), 10, GFLAGS),
+	COMPOSITE_NODIV(CLK_I2C7, "clk_i2c7", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(68), 4, 2, MFLAGS,
+			RK3572_CLKGATE_CON(13), 11, GFLAGS),
+	COMPOSITE_NODIV(CLK_I2C8, "clk_i2c8", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(68), 6, 2, MFLAGS,
+			RK3572_CLKGATE_CON(13), 12, GFLAGS),
+	COMPOSITE_NODIV(CLK_I2C9, "clk_i2c9", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(68), 8, 2, MFLAGS,
+			RK3572_CLKGATE_CON(13), 13, GFLAGS),
+	GATE(PCLK_SARADC, "pclk_saradc", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(13), 15, GFLAGS),
+	COMPOSITE(CLK_SARADC, "clk_saradc", gpll_24m_32k_p, 0,
+		  RK3572_CLKSEL_CON(69), 8, 2, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(14), 0, GFLAGS),
+	GATE(PCLK_TSADC, "pclk_tsadc", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(14), 2, GFLAGS),
+	COMPOSITE_NOMUX(CLK_TSADC, "clk_tsadc", "xin24m", 0,
+			RK3572_CLKSEL_CON(70), 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(14), 3, GFLAGS),
+	GATE(PCLK_UART0, "pclk_uart0", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(14), 4, GFLAGS),
+	GATE(PCLK_UART2, "pclk_uart2", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(14), 5, GFLAGS),
+	GATE(PCLK_UART3, "pclk_uart3", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(14), 6, GFLAGS),
+	GATE(PCLK_UART4, "pclk_uart4", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(14), 7, GFLAGS),
+	GATE(PCLK_UART5, "pclk_uart5", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(14), 8, GFLAGS),
+	GATE(PCLK_UART6, "pclk_uart6", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(14), 9, GFLAGS),
+	GATE(PCLK_UART7, "pclk_uart7", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(14), 10, GFLAGS),
+	GATE(PCLK_UART8, "pclk_uart8", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(14), 11, GFLAGS),
+	GATE(PCLK_UART9, "pclk_uart9", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(14), 12, GFLAGS),
+	GATE(PCLK_UART10, "pclk_uart10", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(14), 13, GFLAGS),
+	GATE(PCLK_UART11, "pclk_uart11", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(14), 14, GFLAGS),
+	COMPOSITE(SCLK_UART0, "sclk_uart0", clk_uart_src_p, 0,
+		  RK3572_CLKSEL_CON(71), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(14), 15, GFLAGS),
+	COMPOSITE(SCLK_UART2, "sclk_uart2", clk_uart_src_p, 0,
+		  RK3572_CLKSEL_CON(72), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(15), 0, GFLAGS),
+	COMPOSITE(SCLK_UART3, "sclk_uart3", clk_uart_src_p, 0,
+		  RK3572_CLKSEL_CON(73), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(15), 3, GFLAGS),
+	COMPOSITE(SCLK_UART4, "sclk_uart4", clk_uart_src_p, 0,
+		  RK3572_CLKSEL_CON(74), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(15), 6, GFLAGS),
+	COMPOSITE(SCLK_UART5, "sclk_uart5", clk_uart_src_p, 0,
+		  RK3572_CLKSEL_CON(75), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(15), 9, GFLAGS),
+	COMPOSITE(SCLK_UART6, "sclk_uart6", clk_uart_src_p, 0,
+		  RK3572_CLKSEL_CON(76), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(15), 12, GFLAGS),
+	COMPOSITE(SCLK_UART7, "sclk_uart7", clk_uart_src_p, 0,
+		  RK3572_CLKSEL_CON(77), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(15), 15, GFLAGS),
+	COMPOSITE(SCLK_UART8, "sclk_uart8", clk_uart_src_p, 0,
+		  RK3572_CLKSEL_CON(78), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(16), 2, GFLAGS),
+	COMPOSITE(SCLK_UART9, "sclk_uart9", clk_uart_src_p, 0,
+		  RK3572_CLKSEL_CON(79), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(16), 3, GFLAGS),
+	COMPOSITE(SCLK_UART10, "sclk_uart10", clk_uart_src_p, 0,
+		  RK3572_CLKSEL_CON(80), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(16), 4, GFLAGS),
+	COMPOSITE(SCLK_UART11, "sclk_uart11", clk_uart_src_p, 0,
+		  RK3572_CLKSEL_CON(81), 8, 3, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(16), 5, GFLAGS),
+	GATE(PCLK_SPI0, "pclk_spi0", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(16), 7, GFLAGS),
+	GATE(PCLK_SPI1, "pclk_spi1", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(16), 8, GFLAGS),
+	GATE(PCLK_SPI2, "pclk_spi2", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(16), 9, GFLAGS),
+	GATE(PCLK_SPI3, "pclk_spi3", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(16), 10, GFLAGS),
+	GATE(PCLK_SPI4, "pclk_spi4", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(16), 11, GFLAGS),
+	COMPOSITE_NODIV(CLK_SPI0, "clk_spi0", mux_300m_200m_100m_24m_p, 0,
+			RK3572_CLKSEL_CON(81), 13, 2, MFLAGS,
+			RK3572_CLKGATE_CON(16), 12, GFLAGS),
+	COMPOSITE_NODIV(CLK_SPI1, "clk_spi1", mux_300m_200m_100m_24m_p, 0,
+			RK3572_CLKSEL_CON(82), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(16), 13, GFLAGS),
+	COMPOSITE_NODIV(CLK_SPI2, "clk_spi2", mux_300m_200m_100m_24m_p, 0,
+			RK3572_CLKSEL_CON(82), 2, 2, MFLAGS,
+			RK3572_CLKGATE_CON(16), 14, GFLAGS),
+	COMPOSITE_NODIV(CLK_SPI3, "clk_spi3", mux_300m_200m_100m_24m_p, 0,
+			RK3572_CLKSEL_CON(82), 4, 2, MFLAGS,
+			RK3572_CLKGATE_CON(16), 15, GFLAGS),
+	COMPOSITE_NODIV(CLK_SPI4, "clk_spi4", mux_300m_200m_100m_24m_p, 0,
+			RK3572_CLKSEL_CON(82), 6, 2, MFLAGS,
+			RK3572_CLKGATE_CON(17), 0, GFLAGS),
+	GATE(PCLK_WDT0, "pclk_wdt0", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(17), 1, GFLAGS),
+	GATE(TCLK_WDT0, "tclk_wdt0", "xin24m", 0,
+	     RK3572_CLKGATE_CON(17), 2, GFLAGS),
+	GATE(PCLK_PWM1, "pclk_pwm1", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(17), 4, GFLAGS),
+	COMPOSITE_NODIV(CLK_PWM1, "clk_pwm1", mux_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(82), 8, 2, MFLAGS,
+			RK3572_CLKGATE_CON(17), 5, GFLAGS),
+	GATE(CLK_OSC_PWM1, "clk_osc_pwm1", "xin24m", 0,
+	     RK3572_CLKGATE_CON(17), 6, GFLAGS),
+	GATE(CLK_RC_PWM1, "clk_rc_pwm1", "clk_rcosc", 0,
+	     RK3572_CLKGATE_CON(17), 7, GFLAGS),
+	GATE(PCLK_PWM2, "pclk_pwm2", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(17), 10, GFLAGS),
+	COMPOSITE_NODIV(CLK_PWM2, "clk_pwm2", mux_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(83), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(17), 11, GFLAGS),
+	GATE(CLK_RC_PWM2, "clk_rc_pwm2", "clk_rcosc", 0,
+	     RK3572_CLKGATE_CON(17), 12, GFLAGS),
+	GATE(CLK_OSC_PWM2, "clk_osc_pwm2", "xin24m", 0,
+	     RK3572_CLKGATE_CON(17), 13, GFLAGS),
+	GATE(PCLK_BUSTIMER0, "pclk_bustimer0", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(18), 4, GFLAGS),
+	GATE(PCLK_BUSTIMER1, "pclk_bustimer1", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(18), 5, GFLAGS),
+	COMPOSITE_NODIV(CLK_TIMER0_ROOT, "clk_timer0_root", mux_100m_24m_p, 0,
+			RK3572_CLKSEL_CON(83), 10, 1, MFLAGS,
+			RK3572_CLKGATE_CON(18), 6, GFLAGS),
+	GATE(CLK_TIMER0, "clk_timer0", "clk_timer0_root", 0,
+	     RK3572_CLKGATE_CON(18), 7, GFLAGS),
+	GATE(CLK_TIMER1, "clk_timer1", "clk_timer0_root", 0,
+	     RK3572_CLKGATE_CON(18), 8, GFLAGS),
+	GATE(CLK_TIMER2, "clk_timer2", "clk_timer0_root", 0,
+	     RK3572_CLKGATE_CON(18), 9, GFLAGS),
+	GATE(CLK_TIMER3, "clk_timer3", "clk_timer0_root", 0,
+	     RK3572_CLKGATE_CON(18), 10, GFLAGS),
+	GATE(CLK_TIMER4, "clk_timer4", "clk_timer0_root", 0,
+	     RK3572_CLKGATE_CON(18), 11, GFLAGS),
+	GATE(CLK_TIMER5, "clk_timer5", "clk_timer0_root", 0,
+	     RK3572_CLKGATE_CON(18), 12, GFLAGS),
+	GATE(PCLK_MAILBOX0, "pclk_mailbox0", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(18), 14, GFLAGS),
+	GATE(PCLK_GPIO1, "pclk_gpio1", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(19), 0, GFLAGS),
+	GATE(DBCLK_GPIO1, "dbclk_gpio1", "xin24m", 0,
+	     RK3572_CLKGATE_CON(19), 1, GFLAGS),
+	GATE(PCLK_GPIO2, "pclk_gpio2", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(19), 2, GFLAGS),
+	GATE(DBCLK_GPIO2, "dbclk_gpio2", "xin24m", 0,
+	     RK3572_CLKGATE_CON(19), 3, GFLAGS),
+	GATE(PCLK_GPIO3, "pclk_gpio3", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(19), 4, GFLAGS),
+	GATE(DBCLK_GPIO3, "dbclk_gpio3", "xin24m", 0,
+	     RK3572_CLKGATE_CON(19), 5, GFLAGS),
+	GATE(PCLK_GPIO4, "pclk_gpio4", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(19), 6, GFLAGS),
+	GATE(DBCLK_GPIO4, "dbclk_gpio4", "xin24m", 0,
+	     RK3572_CLKGATE_CON(19), 7, GFLAGS),
+	GATE(ACLK_DECOM, "aclk_decom", "aclk_decom_root", 0,
+	     RK3572_CLKGATE_CON(19), 8, GFLAGS),
+	GATE(PCLK_DECOM, "pclk_decom", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(19), 9, GFLAGS),
+	COMPOSITE(DCLK_DECOM, "dclk_decom", gpll_cpll_spll_bpll_p, 0,
+		  RK3572_CLKSEL_CON(84), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(19), 10, GFLAGS),
+	COMPOSITE_NODIV(CLK_TIMER1_ROOT, "clk_timer1_root", mux_100m_24m_p, 0,
+			RK3572_CLKSEL_CON(84), 7, 1, MFLAGS,
+			RK3572_CLKGATE_CON(19), 11, GFLAGS),
+	GATE(CLK_TIMER6, "clk_timer6", "clk_timer1_root", 0,
+	     RK3572_CLKGATE_CON(19), 12, GFLAGS),
+	COMPOSITE(CLK_TIMER7, "clk_timer7", clk_timer7_p, 0,
+		  RK3572_CLKSEL_CON(84), 13, 2, MFLAGS, 8, 5, DFLAGS,
+			RK3572_CLKGATE_CON(19), 13, GFLAGS),
+	COMPOSITE(CLK_TIMER8, "clk_timer8", clk_timer8_p, 0,
+		  RK3572_CLKSEL_CON(85), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(19), 14, GFLAGS),
+	GATE(CLK_TIMER9, "clk_timer9", "clk_timer1_root", 0,
+	     RK3572_CLKGATE_CON(19), 15, GFLAGS),
+	GATE(CLK_TIMER10, "clk_timer10", "clk_timer1_root", 0,
+	     RK3572_CLKGATE_CON(20), 0, GFLAGS),
+	GATE(CLK_TIMER11, "clk_timer11", "clk_timer1_root", 0,
+	     RK3572_CLKGATE_CON(20), 1, GFLAGS),
+	GATE(ACLK_RKDMA0, "aclk_rkdma0", "aclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(20), 2, GFLAGS),
+	GATE(PCLK_RKDMA0, "pclk_rkdma0", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(20), 3, GFLAGS),
+	GATE(ACLK_RKDMA1, "aclk_rkdma1", "aclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(20), 4, GFLAGS),
+	GATE(PCLK_RKDMA1, "pclk_rkdma1", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(20), 5, GFLAGS),
+	GATE(ACLK_RKDMA2, "aclk_rkdma2", "aclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(20), 6, GFLAGS),
+	GATE(PCLK_RKDMA2, "pclk_rkdma2", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(20), 7, GFLAGS),
+	GATE(ACLK_RKDMA3, "aclk_rkdma3", "aclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(20), 8, GFLAGS),
+	GATE(PCLK_RKDMA3, "pclk_rkdma3", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(20), 9, GFLAGS),
+	GATE(PCLK_SPINLOCK, "pclk_spinlock", "pclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(20), 10, GFLAGS),
+	COMPOSITE_NODIV(CLK_I3C, "clk_i3c", mux_300m_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(85), 7, 3, MFLAGS,
+			RK3572_CLKGATE_CON(20), 12, GFLAGS),
+	GATE(HCLK_I3C, "hclk_i3c", "hclk_bus_root", 0,
+	     RK3572_CLKGATE_CON(20), 13, GFLAGS),
+	COMPOSITE_NODIV(CLK_BUSMCU_ROOT, "clk_busmcu_root", mux_400m_200m_100m_24m_p, 0,
+			RK3572_CLKSEL_CON(85), 13, 2, MFLAGS,
+			RK3572_CLKGATE_CON(21), 0, GFLAGS),
+	GATE(CLK_BUSMCU_CORE_AON, "clk_busmcu_core_aon", "clk_busmcu_root", 0,
+	     RK3572_CLKGATE_CON(21), 2, GFLAGS),
+	COMPOSITE_NOMUX(CLK_MTIME_TOGGLE_A, "clk_mtime_toggle_a", "xin24m", 0,
+			RK3572_CLKSEL_CON(86), 0, 6, DFLAGS,
+			RK3572_CLKGATE_CON(21), 4, GFLAGS),
+	GATE(CLK_DBG_TOGGLE_A, "clk_dbg_toggle_a", "clk_32k", 0,
+	     RK3572_CLKGATE_CON(21), 5, GFLAGS),
+	GATE(CLK_MCU_AXI_INTEGRITY, "clk_mcu_axi_integrity", "clk_busmcu_root", 0,
+	     RK3572_CLKGATE_CON(21), 6, GFLAGS),
+	GATE(PCLK_PMU2, "pclk_pmu2", "pclk_bus_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(21), 7, GFLAGS),
+	GATE(CLK_HDMITXHPD, "clk_hdmitxhpd", "xin24m", 0,
+	     RK3572_CLKGATE_CON(21), 14, GFLAGS),
+	GATE(PCLK_APB2ASB_HDMITX, "pclk_apb2asb_hdmitx", "pclk_bus_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(22), 2, GFLAGS),
+	COMPOSITE_NODIV(SCLK_APB2ASB_HDMITX, "sclk_apb2asb_hdmitx", sclk_apb2asb_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(88), 7, 2, MFLAGS,
+			RK3572_CLKGATE_CON(22), 3, GFLAGS),
+	GATE(PCLK_APB2ASB_MIPICSI, "pclk_apb2asb_mipicsi", "pclk_bus_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(22), 6, GFLAGS),
+	COMPOSITE_NODIV(SCLK_APB2ASB_MIPICSI, "sclk_apb2asb_mipicsi", sclk_apb2asb_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(88), 11, 2, MFLAGS,
+			RK3572_CLKGATE_CON(22), 7, GFLAGS),
+	GATE(PCLK_APB2ASB_VCCIO0_3, "pclk_apb2asb_vccio0_3", "pclk_bus_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(22), 8, GFLAGS),
+	COMPOSITE_NODIV(SCLK_APB2ASB_VCCIO0_3, "sclk_apb2asb_vccio0_3", sclk_apb2asb_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(88), 13, 2, MFLAGS,
+			RK3572_CLKGATE_CON(22), 9, GFLAGS),
+	GATE(PCLK_APB2ASB_VCCIO1_2_4, "pclk_apb2asb_vccio1_2_4", "pclk_bus_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(22), 10, GFLAGS),
+	COMPOSITE_NODIV(SCLK_APB2ASB_VCCIO1_2_4, "sclk_apb2asb_vccio1_2_4", sclk_apb2asb_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(89), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(22), 11, GFLAGS),
+	GATE(PCLK_APB2ASB_VCCIO5_6, "pclk_apb2asb_vccio5_6", "pclk_bus_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(22), 12, GFLAGS),
+	COMPOSITE_NODIV(SCLK_APB2ASB_VCCIO5_6, "sclk_apb2asb_vccio5_6", sclk_apb2asb_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(89), 2, 2, MFLAGS,
+			RK3572_CLKGATE_CON(22), 13, GFLAGS),
+
+	/* pd_ddr */
+	COMPOSITE(PCLK_DDR_ROOT, "pclk_ddr_root", gpll_cpll_24m_p, CLK_IS_CRITICAL,
+		  RK3572_CLKSEL_CON(90), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(23), 0, GFLAGS),
+	COMPOSITE(ACLK_DDR_ROOT, "aclk_ddr_root", gpll_cpll_p, CLK_IS_CRITICAL,
+		  RK3572_CLKSEL_CON(90), 12, 1, MFLAGS, 7, 5, DFLAGS,
+			RK3572_CLKGATE_CON(23), 9, GFLAGS),
+	COMPOSITE_NODIV(LCLK_DDRSCH_BIU, "lclk_ddrsch_biu", mux_100m_50m_24m_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(90), 13, 2, MFLAGS,
+			RK3572_CLKGATE_CON(24), 11, GFLAGS),
+	COMPOSITE_NODIV(CLK_DDR_TIMER_ROOT, "clk_ddr_timer_root", mux_100m_24m_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(90), 15, 1, MFLAGS,
+			RK3572_CLKGATE_CON(25), 3, GFLAGS),
+	GATE(CLK_DDR_TIMER0, "clk_ddr_timer0", "clk_ddr_timer_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(25), 4, GFLAGS),
+	GATE(CLK_DDR_TIMER1, "clk_ddr_timer1", "clk_ddr_timer_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(25), 5, GFLAGS),
+	GATE(TCLK_DDR_WDT, "tclk_ddr_wdt", "xin24m", 0,
+	     RK3572_CLKGATE_CON(25), 6, GFLAGS),
+	GATE(PCLK_WDT, "pclk_wdt", "pclk_ddr_root", 0,
+	     RK3572_CLKGATE_CON(25), 7, GFLAGS),
+	GATE(PCLK_TIMER, "pclk_timer", "pclk_ddr_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(25), 8, GFLAGS),
+	COMPOSITE_NODIV(CLK_DDRMCU_ROOT, "clk_ddrmcu_root", mux_400m_200m_100m_24m_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(91), 6, 2, MFLAGS,
+			RK3572_CLKGATE_CON(26), 15, GFLAGS),
+	GATE(CLK_DDRMCU_CORE_AON, "clk_ddrmcu_core_aon", "clk_ddrmcu_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(27), 1, GFLAGS),
+	COMPOSITE_NOMUX(CLK_MTIME_TOGGLE_A_DDR, "clk_mtime_toggle_a_ddr", "xin24m", 0,
+			RK3572_CLKSEL_CON(91), 8, 6, DFLAGS,
+			RK3572_CLKGATE_CON(27), 3, GFLAGS),
+	GATE(CLK_DBG_TOGGLE_A_DDR, "clk_dbg_toggle_a_ddr", "clk_32k", 0,
+	     RK3572_CLKGATE_CON(27), 4, GFLAGS),
+	GATE(PCLK_DDR_MON, "pclk_ddr_mon", "pclk_ddr_root", 0,
+	     RK3572_CLKGATE_CON(23), 1, GFLAGS),
+
+	/* pd_npu */
+	COMPOSITE(ACLK_RKNN_ROOT, "aclk_rknn_root", gpll_cpll_aupll_spll_p, 0,
+		  RK3572_CLKSEL_CON(95), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(31), 0, GFLAGS),
+	GATE(ACLK_RKNN, "aclk_rknn", "aclk_rknn_root", 0,
+	     RK3572_CLKGATE_CON(31), 2, GFLAGS),
+	COMPOSITE_NODIV(PCLK_RKNN_ROOT, "pclk_rknn_root", mux_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(95), 8, 2, MFLAGS,
+			RK3572_CLKGATE_CON(31), 6, GFLAGS),
+	GATE(CLK_24M_RKNN, "clk_24m_rknn", "xin24m", 0,
+	     RK3572_CLKGATE_CON(31), 11, GFLAGS),
+	COMPOSITE_NODIV(CLK_NPUTIMER_ROOT, "clk_nputimer_root", mux_100m_24m_p, 0,
+			RK3572_CLKSEL_CON(95), 11, 1, MFLAGS,
+			RK3572_CLKGATE_CON(31), 12, GFLAGS),
+	GATE(CLK_NPUTIMER0, "clk_nputimer0", "clk_nputimer_root", 0,
+	     RK3572_CLKGATE_CON(31), 13, GFLAGS),
+	GATE(CLK_NPUTIMER1, "clk_nputimer1", "clk_nputimer_root", 0,
+	     RK3572_CLKGATE_CON(31), 14, GFLAGS),
+	GATE(PCLK_NPU_TIMER, "pclk_npu_timer", "pclk_rknn_root", 0,
+	     RK3572_CLKGATE_CON(31), 15, GFLAGS),
+	GATE(PCLK_NPU_WDT, "pclk_npu_wdt", "pclk_rknn_root", 0,
+	     RK3572_CLKGATE_CON(32), 0, GFLAGS),
+	GATE(TCLK_NPU_WDT, "tclk_npu_wdt", "xin24m", 0,
+	     RK3572_CLKGATE_CON(32), 1, GFLAGS),
+
+	/* pd_php */
+	COMPOSITE_NODIV(PCLK_PHP0_ROOT, "pclk_php0_root", mux_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(97), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(33), 0, GFLAGS),
+	COMPOSITE(ACLK_PHP0_ROOT, "aclk_php0_root", gpll_cpll_p, CLK_IS_CRITICAL,
+		  RK3572_CLKSEL_CON(97), 7, 1, MFLAGS, 2, 5, DFLAGS,
+			RK3572_CLKGATE_CON(33), 3, GFLAGS),
+	GATE(PCLK_PCIE1, "pclk_pcie1", "pclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(33), 7, GFLAGS),
+	GATE(CLK_PCIE1_AUX, "clk_pcie1_aux", "xin24m", 0,
+	     RK3572_CLKGATE_CON(33), 8, GFLAGS),
+	GATE(ACLK_PCIE1_MSTR, "aclk_pcie1_mstr", "aclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(33), 9, GFLAGS),
+	GATE(ACLK_PCIE1_SLV, "aclk_pcie1_slv", "aclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(33), 10, GFLAGS),
+	GATE(ACLK_PCIE1_DBI, "aclk_pcie1_dbi", "aclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(33), 11, GFLAGS),
+	GATE(PCLK_PCIE0, "pclk_pcie0", "pclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(34), 3, GFLAGS),
+	GATE(CLK_PCIE0_AUX, "clk_pcie0_aux", "xin24m", 0,
+	     RK3572_CLKGATE_CON(34), 4, GFLAGS),
+	GATE(ACLK_PCIE0_MSTR, "aclk_pcie0_mstr", "aclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(34), 5, GFLAGS),
+	GATE(ACLK_PCIE0_SLV, "aclk_pcie0_slv", "aclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(34), 6, GFLAGS),
+	GATE(ACLK_PCIE0_DBI, "aclk_pcie0_dbi", "aclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(34), 7, GFLAGS),
+	GATE(ACLK_USB3OTG1, "aclk_usb3otg1", "aclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(34), 9, GFLAGS),
+	GATE(CLK_REF_USB3OTG1, "clk_ref_usb3otg1", "xin24m", 0,
+	     RK3572_CLKGATE_CON(34), 10, GFLAGS),
+	GATE(CLK_SUSPEND_USB3OTG1, "clk_suspend_usb3otg1", "xin24m", 0,
+	     RK3572_CLKGATE_CON(34), 11, GFLAGS),
+	GATE(ACLK_GMAC0, "aclk_gmac0", "aclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(34), 12, GFLAGS),
+	GATE(PCLK_GMAC0, "pclk_gmac0", "pclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(34), 13, GFLAGS),
+	COMPOSITE(ACLK_UFS_ROOT, "aclk_ufs_root", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(97), 15, 1, MFLAGS, 10, 5, DFLAGS,
+			RK3572_CLKGATE_CON(34), 14, GFLAGS),
+	GATE(ACLK_USB3OTG0, "aclk_usb3otg0", "aclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(34), 15, GFLAGS),
+	GATE(CLK_REF_USB3OTG0, "clk_ref_usb3otg0", "xin24m", 0,
+	     RK3572_CLKGATE_CON(35), 0, GFLAGS),
+	GATE(CLK_SUSPEND_USB3OTG0, "clk_suspend_usb3otg0", "xin24m", 0,
+	     RK3572_CLKGATE_CON(35), 1, GFLAGS),
+	GATE(ACLK_UFS_SYS, "aclk_ufs_sys", "aclk_ufs_root", 0,
+	     RK3572_CLKGATE_CON(35), 3, GFLAGS),
+	COMPOSITE(CLK_GMAC0_PTP_REF_PRE, "clk_gmac0_ptp_ref_pre", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(98), 5, 1, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(35), 5, GFLAGS),
+	COMPOSITE_NODIV(CLK_GMAC0_PTP_REF_SRC, "clk_gmac0_ptp_ref_src", clk_gmac0_ptp_ref_src_p, 0,
+			RK3572_CLKSEL_CON(98), 6, 1, MFLAGS,
+			RK3572_CLKGATE_CON(35), 7, GFLAGS),
+	COMPOSITE(CLK_RXOOB0, "clk_rxoob0", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(100), 7, 1, MFLAGS, 0, 7, DFLAGS,
+			RK3572_CLKGATE_CON(37), 0, GFLAGS),
+	GATE(CLK_PMALIVE0, "clk_pmalive0", "xin24m", 0,
+	     RK3572_CLKGATE_CON(37), 1, GFLAGS),
+	GATE(ACLK_SATA0, "aclk_sata0", "aclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(37), 2, GFLAGS),
+	COMPOSITE(CLK_RXOOB1, "clk_rxoob1", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(100), 15, 1, MFLAGS, 8, 7, DFLAGS,
+			RK3572_CLKGATE_CON(37), 3, GFLAGS),
+	GATE(CLK_PMALIVE1, "clk_pmalive1", "xin24m", 0,
+	     RK3572_CLKGATE_CON(37), 4, GFLAGS),
+	GATE(ACLK_SATA1, "aclk_sata1", "aclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(37), 5, GFLAGS),
+	COMPOSITE(CLK_EEE_XPCS, "clk_eee_xpcs", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(101), 7, 1, MFLAGS, 0, 7, DFLAGS,
+			RK3572_CLKGATE_CON(37), 6, GFLAGS),
+	GATE(PCLK_XPCS, "pclk_xpcs", "pclk_php0_root", 0,
+	     RK3572_CLKGATE_CON(37), 7, GFLAGS),
+
+	/* pd_nvm */
+	COMPOSITE_NODIV(HCLK_NVM0_ROOT, "hclk_nvm0_root", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(113), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(42), 0, GFLAGS),
+	COMPOSITE(ACLK_NVM0_ROOT, "aclk_nvm0_root", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(113), 7, 1, MFLAGS, 2, 5, DFLAGS,
+			RK3572_CLKGATE_CON(42), 1, GFLAGS),
+	COMPOSITE_NODIV(PCLK_NVM0_ROOT, "pclk_nvm0_root", mux_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(113), 8, 2, MFLAGS,
+			RK3572_CLKGATE_CON(42), 2, GFLAGS),
+	COMPOSITE(CCLK_SRC_EMMC, "cclk_src_emmc", gpll_cpll_24m_p, 0,
+		  RK3572_CLKSEL_CON(114), 6, 2, MFLAGS, 0, 6, DFLAGS,
+			RK3572_CLKGATE_CON(42), 7, GFLAGS),
+	GATE(HCLK_EMMC, "hclk_emmc", "hclk_nvm0_root", 0,
+	     RK3572_CLKGATE_CON(42), 8, GFLAGS),
+	GATE(ACLK_EMMC, "aclk_emmc", "aclk_nvm0_root", 0,
+	     RK3572_CLKGATE_CON(42), 9, GFLAGS),
+	COMPOSITE_NODIV(BCLK_EMMC, "bclk_emmc", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(114), 8, 2, MFLAGS,
+			RK3572_CLKGATE_CON(42), 10, GFLAGS),
+	GATE(TCLK_EMMC, "tclk_emmc", "xin24m", 0,
+	     RK3572_CLKGATE_CON(42), 11, GFLAGS),
+	COMPOSITE(CLK_GMAC1_PTP_REF_SRC, "clk_gmac1_ptp_ref_src", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(114), 15, 1, MFLAGS, 10, 5, DFLAGS,
+			RK3572_CLKGATE_CON(42), 12, GFLAGS),
+	COMPOSITE_NODIV(CLK_GMAC1_PTP_REF, "clk_gmac1_ptp_ref", clk_gmac1_ptp_ref_p, 0,
+			RK3572_CLKSEL_CON(115), 0, 1, MFLAGS,
+			RK3572_CLKGATE_CON(42), 13, GFLAGS),
+	GATE(ACLK_GMAC1, "aclk_gmac1", "aclk_nvm0_root", 0,
+	     RK3572_CLKGATE_CON(42), 14, GFLAGS),
+	GATE(PCLK_GMAC1, "pclk_gmac1", "pclk_nvm0_root", 0,
+	     RK3572_CLKGATE_CON(42), 15, GFLAGS),
+	COMPOSITE(SCLK_FSPI0_X2, "sclk_fspi0_x2", gpll_cpll_spll_aupll_24m_p, 0,
+		  RK3572_CLKSEL_CON(115), 7, 3, MFLAGS, 1, 6, DFLAGS,
+			RK3572_CLKGATE_CON(43), 0, GFLAGS),
+	GATE(HCLK_FSPI0, "hclk_fspi0", "hclk_nvm0_root", 0,
+	     RK3572_CLKGATE_CON(43), 1, GFLAGS),
+	COMPOSITE(CCLK_SRC_SDMMC1, "cclk_src_sdmmc1", gpll_cpll_24m_p, 0,
+		  RK3572_CLKSEL_CON(116), 6, 2, MFLAGS, 0, 6, DFLAGS,
+			RK3572_CLKGATE_CON(43), 2, GFLAGS),
+	GATE(HCLK_SDMMC1, "hclk_sdmmc1", "hclk_nvm0_root", 0,
+	     RK3572_CLKGATE_CON(43), 3, GFLAGS),
+	COMPOSITE(ACLK_DSMC_ROOT, "aclk_dsmc_root", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(118), 5, 1, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(44), 0, GFLAGS),
+	GATE(ACLK_DSMC, "aclk_dsmc", "aclk_dsmc_root", 0,
+	     RK3572_CLKGATE_CON(44), 2, GFLAGS),
+	COMPOSITE_NODIV(HCLK_DSMC_ROOT, "hclk_dsmc_root", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(118), 6, 2, MFLAGS,
+			RK3572_CLKGATE_CON(44), 3, GFLAGS),
+	GATE(HCLK_DSMC, "hclk_dsmc", "hclk_dsmc_root", 0,
+	     RK3572_CLKGATE_CON(44), 5, GFLAGS),
+	COMPOSITE_NODIV(PCLK_DSMC_ROOT, "pclk_dsmc_root", mux_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(118), 8, 2, MFLAGS,
+			RK3572_CLKGATE_CON(44), 6, GFLAGS),
+	GATE(PCLK_DSMC, "pclk_dsmc", "pclk_dsmc_root", 0,
+	     RK3572_CLKGATE_CON(44), 8, GFLAGS),
+	COMPOSITE(CLK_DSMC_SYS, "clk_dsmc_sys", gpll_cpll_24m_p, 0,
+		  RK3572_CLKSEL_CON(119), 8, 2, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(44), 9, GFLAGS),
+	COMPOSITE_NODIV(HCLK_NVM1_ROOT, "hclk_nvm1_root", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(120), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(45), 0, GFLAGS),
+	COMPOSITE_NODIV(PCLK_NVM1_ROOT, "pclk_nvm1_root", mux_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(120), 8, 2, MFLAGS,
+			RK3572_CLKGATE_CON(45), 2, GFLAGS),
+	COMPOSITE(CCLK_SRC_SDMMC0, "cclk_src_sdmmc0", gpll_cpll_24m_p, 0,
+		  RK3572_CLKSEL_CON(121), 6, 2, MFLAGS, 0, 6, DFLAGS,
+			RK3572_CLKGATE_CON(45), 7, GFLAGS),
+	GATE(HCLK_SDMMC0, "hclk_sdmmc0", "hclk_nvm1_root", 0,
+	     RK3572_CLKGATE_CON(45), 8, GFLAGS),
+	COMPOSITE(SCLK_FSPI1_X2, "sclk_fspi1_x2", gpll_cpll_spll_aupll_24m_p, 0,
+		  RK3572_CLKSEL_CON(122), 6, 3, MFLAGS, 0, 6, DFLAGS,
+			RK3572_CLKGATE_CON(45), 11, GFLAGS),
+	GATE(HCLK_FSPI1, "hclk_fspi1", "hclk_nvm1_root", 0,
+	     RK3572_CLKGATE_CON(45), 12, GFLAGS),
+
+	/* pd_phpphy */
+	COMPOSITE_NODIV(PCLK_PHPSUBSYS_ROOT, "pclk_phpsubsys_root", pclk_phpsubsys_root_p,
+			CLK_IS_CRITICAL,
+			RK3572_PHP_CLKSEL_CON(0), 0, 1, MFLAGS,
+			RK3572_PHP_CLKGATE_CON(0), 2, GFLAGS),
+	GATE(PCLK_PCIE2_COMBOPHY0, "pclk_pcie2_combophy0", "pclk_phpsubsys_root", 0,
+	     RK3572_PHP_CLKGATE_CON(0), 4, GFLAGS),
+	GATE(PCLK_PCIE2_COMBOPHY1, "pclk_pcie2_combophy1", "pclk_phpsubsys_root", 0,
+	     RK3572_PHP_CLKGATE_CON(0), 6, GFLAGS),
+	GATE(PCLK_MPHY, "pclk_mphy", "pclk_phpsubsys_root", 0,
+	     RK3572_PHP_CLKGATE_CON(0), 10, GFLAGS),
+	GATE(PCLK_PCIEPHY2, "pclk_pciephy2", "pclk_phpsubsys_root", 0,
+	     RK3572_PHP_CLKGATE_CON(0), 14, GFLAGS),
+	COMPOSITE(SCLK_APB2ASB_USBMPHY_PHPPHY, "sclk_apb2asb_usbmphy_phpphy", sclk_apb2asb_p,
+		  CLK_IS_CRITICAL,
+		  RK3572_PHP_CLKSEL_CON(0), 6, 2, MFLAGS, 1, 5, DFLAGS,
+			RK3572_PHP_CLKGATE_CON(1), 0, GFLAGS),
+	GATE(PCLK_APB2ASB_USBMPHY_PHPPHY, "pclk_apb2asb_usbmphy_phpphy", "pclk_phpsubsys_root",
+	     CLK_IS_CRITICAL,
+	     RK3572_PHP_CLKGATE_CON(1), 1, GFLAGS),
+	FACTOR_GATE(CLK_CPLL_DIV10_PHPPHY, "clk_cpll_div10_phpphy", "clk_gpll_div6",
+		    CLK_IS_CRITICAL, 1, 2,
+		    RK3572_PHP_CLKGATE_CON(1), 2, GFLAGS),
+	GATE(CLK_PHPPHY_REF, "clk_phpphy_ref", "xin24m", 0,
+	     RK3572_PHP_CLKGATE_CON(1), 3, GFLAGS),
+	COMPOSITE_NOMUX(CLK_PCIE_100M_SRC, "clk_pcie_100m_src", "ppll", 0,
+			RK3572_PHP_CLKSEL_CON(2), 0, 5, DFLAGS,
+			RK3572_PHP_CLKGATE_CON(2), 1, GFLAGS),
+	COMPOSITE_NOMUX(CLK_PCIE_100M_NDUTY_SRC, "clk_pcie_100m_nduty_src", "ppll", 0,
+			RK3572_PHP_CLKSEL_CON(2), 5, 5, DFLAGS,
+			RK3572_PHP_CLKGATE_CON(2), 2, GFLAGS),
+	COMPOSITE_NODIV(CLK_REF_PCIEPHY2, "clk_ref_pciephy2", clk_ref_pciephy_p, 0,
+			RK3572_PHP_CLKSEL_CON(2), 10, 2, MFLAGS,
+			RK3572_PHP_CLKGATE_CON(2), 4, GFLAGS),
+	COMPOSITE_NODIV(CLK_REF_PCIE0_INNER_PHY, "clk_ref_pcie0_inner_phy", clk_ref_pciephy_p, 0,
+			RK3572_PHP_CLKSEL_CON(2), 12, 2, MFLAGS,
+			RK3572_PHP_CLKGATE_CON(2), 5, GFLAGS),
+	COMPOSITE_NODIV(CLK_REF_PCIE1_INNER_PHY, "clk_ref_pcie1_inner_phy", clk_ref_pciephy_p, 0,
+			RK3572_PHP_CLKSEL_CON(2), 14, 2, MFLAGS,
+			RK3572_PHP_CLKGATE_CON(2), 8, GFLAGS),
+	COMPOSITE_NOMUX(CLK_REF_MPHY_26M, "clk_ref_mphy_26m", "ppll", 0,
+			RK3572_PHP_CLKSEL_CON(3), 0, 8, DFLAGS,
+			RK3572_PHP_CLKGATE_CON(2), 9, GFLAGS),
+	COMPOSITE_NOMUX(REF_CLK_FROM_PPLL, "ref_clk_from_ppll", "ppll", 0,
+			RK3572_PHP_CLKSEL_CON(3), 8, 8, DFLAGS,
+			RK3572_PHP_CLKGATE_CON(2), 10, GFLAGS),
+
+	/* pd_rkvdec */
+	COMPOSITE_NODIV(HCLK_RKVDEC_ROOT, "hclk_rkvdec_root", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(130), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(50), 0, GFLAGS),
+	GATE(HCLK_RKVDEC, "hclk_rkvdec", "hclk_rkvdec_root", 0,
+	     RK3572_CLKGATE_CON(50), 3, GFLAGS),
+	COMPOSITE(ACLK_RKVDEC_ROOT, "aclk_rkvdec_root", gpll_cpll_spll_bpll_p, 0,
+		  RK3572_CLKSEL_CON(131), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(50), 7, GFLAGS),
+	COMPOSITE(CLK_RKVDEC_HEVC_CA, "clk_rkvdec_hevc_ca", gpll_cpll_bpll_p, 0,
+		  RK3572_CLKSEL_CON(131), 12, 2, MFLAGS, 7, 5, DFLAGS,
+			RK3572_CLKGATE_CON(50), 8, GFLAGS),
+	GATE(CLK_RKVDEC_CORE, "clk_rkvdec_core", "aclk_rkvdec_root", 0,
+	     RK3572_CLKGATE_CON(50), 9, GFLAGS),
+	COMPOSITE_NODIV(PCLK_VDEC_ROOT, "pclk_vdec_root", mux_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(131), 14, 2, MFLAGS,
+			RK3572_CLKGATE_CON(50), 13, GFLAGS),
+
+	/* pd_vo */
+	COMPOSITE_NODIV(PCLK_VOSUBSYS_ROOT, "pclk_vosubsys_root", mux_100m_50m_24m_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(135), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(52), 0, GFLAGS),
+	GATE(PCLK_APB2ASB_MIPI_HDMI_SUBVO, "pclk_apb2asb_mipi_hdmi_subvo", "pclk_vosubsys_root",
+	     CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(52), 1, GFLAGS),
+	COMPOSITE_NODIV(SCLK_APB2ASB_MIPI_HDMI_SUBVO, "sclk_apb2asb_mipi_hdmi_subvo",
+			sclk_apb2asb_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(135), 2, 2, MFLAGS,
+			RK3572_CLKGATE_CON(52), 2, GFLAGS),
+	GATE(PCLK_APB2ASB_VCCIO0_3_SUBVO, "pclk_apb2asb_vccio0_3_subvo", "pclk_vosubsys_root",
+	     CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(52), 7, GFLAGS),
+	COMPOSITE_NODIV(SCLK_APB2ASB_VCCIO0_3_SUBVO, "sclk_apb2asb_vccio0_3_subvo",
+			sclk_apb2asb_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(135), 8, 2, MFLAGS,
+			RK3572_CLKGATE_CON(52), 8, GFLAGS),
+	GATE(PCLK_HDPTXPHY, "pclk_hdptxphy", "pclk_vosubsys_root", 0,
+	     RK3572_CLKGATE_CON(52), 9, GFLAGS),
+	GATE(PCLK_MIPI_DPHY0, "pclk_mipi_dphy0", "pclk_vosubsys_root", 0,
+	     RK3572_CLKGATE_CON(52), 11, GFLAGS),
+	GATE(CLK_VOSUBSYS_REF, "clk_vosubsys_ref", "xin24m", 0,
+	     RK3572_CLKGATE_CON(53), 0, GFLAGS),
+	GATE(PCLK_IOC_SUBVO, "pclk_ioc_subvo", "pclk_vosubsys_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(53), 3, GFLAGS),
+
+	/* pd_vi */
+	COMPOSITE_NODIV(PCLK_VISUBSYS_ROOT, "pclk_visubsys_root", mux_100m_50m_24m_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(137), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(54), 0, GFLAGS),
+	GATE(PCLK_APB2ASB_VCCIO1_2_4_SUBVI, "pclk_apb2asb_vccio1_2_4_subvi",
+	     "pclk_visubsys_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(54), 1, GFLAGS),
+	COMPOSITE_NODIV(SCLK_APB2ASB_VCCIO1_2_4_SUBVI, "sclk_apb2asb_vccio1_2_4_subvi",
+			sclk_apb2asb_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(137), 2, 2, MFLAGS,
+			RK3572_CLKGATE_CON(54), 2, GFLAGS),
+	GATE(PCLK_APB2ASB_CSIPHY_SUBVI, "pclk_apb2asb_csiphy_subvi", "pclk_visubsys_root",
+	     CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(54), 3, GFLAGS),
+	COMPOSITE_NODIV(SCLK_APB2ASB_CSIPHY_SUBVI, "sclk_apb2asb_csiphy_subvi", sclk_apb2asb_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(137), 4, 2, MFLAGS,
+			RK3572_CLKGATE_CON(54), 4, GFLAGS),
+	GATE(PCLK_CSIPHY0, "pclk_csiphy0", "pclk_visubsys_root", 0,
+	     RK3572_CLKGATE_CON(54), 5, GFLAGS),
+	GATE(PCLK_CSIPHY1, "pclk_csiphy1", "pclk_visubsys_root", 0,
+	     RK3572_CLKGATE_CON(54), 7, GFLAGS),
+	GATE(PCLK_IOC_SUBVI, "pclk_ioc_subvi", "pclk_visubsys_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(54), 9, GFLAGS),
+	GATE(CLK_SDMMC_SWITCH_24M, "clk_sdmmc_switch_24m", "xin24m", 0,
+	     RK3572_CLKGATE_CON(54), 13, GFLAGS),
+
+	COMPOSITE_NODIV(PCLK_DSMCSUBSYS_ROOT, "pclk_dsmcsubsys_root", mux_100m_50m_24m_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(139), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(56), 0, GFLAGS),
+	GATE(PCLK_APB2ASB_VCCIO5_6_SUBDSMC, "pclk_apb2asb_vccio5_6_subdsmc",
+	     "pclk_dsmcsubsys_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(56), 3, GFLAGS),
+	COMPOSITE_NODIV(SCLK_APB2ASB_VCCIO5_6_SUBDSMC, "sclk_apb2asb_vccio5_6_subdsmc",
+			sclk_apb2asb_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(139), 9, 2, MFLAGS,
+			RK3572_CLKGATE_CON(56), 4, GFLAGS),
+
+	/* pd_vpu */
+	COMPOSITE(ACLK_IMG_ROOT, "aclk_img_root", gpll_spll_cpll_bpll_p, CLK_IS_CRITICAL,
+		  RK3572_CLKSEL_CON(141), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(57), 0, GFLAGS),
+	COMPOSITE_NODIV(ACLK_IMG_MID_ROOT, "aclk_img_mid_root", mux_600m_400m_300m_24m_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(141), 7, 2, MFLAGS,
+			RK3572_CLKGATE_CON(57), 1, GFLAGS),
+	COMPOSITE_NODIV(HCLK_IMG_ROOT, "hclk_img_root", mux_200m_100m_50m_24m_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(141), 9, 2, MFLAGS,
+			RK3572_CLKGATE_CON(57), 2, GFLAGS),
+	COMPOSITE(ACLK_JPEG_ROOT, "aclk_jpeg_root", gpll_cpll_aupll_spll_p, 0,
+		  RK3572_CLKSEL_CON(142), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(57), 3, GFLAGS),
+	COMPOSITE_NODIV(ACLK_IMG_LOW_ROOT, "aclk_img_low_root", mux_400m_200m_100m_24m_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(142), 7, 2, MFLAGS,
+			RK3572_CLKGATE_CON(57), 4, GFLAGS),
+	COMPOSITE_NODIV(PCLK_IMG_ROOT, "pclk_img_root", mux_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(142), 9, 2, MFLAGS,
+			RK3572_CLKGATE_CON(57), 6, GFLAGS),
+	GATE(HCLK_RGA2E_0, "hclk_rga2e_0", "hclk_img_root", 0,
+	     RK3572_CLKGATE_CON(58), 0, GFLAGS),
+	GATE(ACLK_RGA2E_0, "aclk_rga2e_0", "aclk_img_root", 0,
+	     RK3572_CLKGATE_CON(58), 1, GFLAGS),
+	COMPOSITE(CLK_CORE_RGA2E_0, "clk_core_rga2e_0", gpll_spll_cpll_bpll_p, 0,
+		  RK3572_CLKSEL_CON(143), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(58), 2, GFLAGS),
+	GATE(ACLK_JPEG, "aclk_jpeg", "aclk_jpeg_root", 0,
+	     RK3572_CLKGATE_CON(58), 3, GFLAGS),
+	GATE(HCLK_JPEG, "hclk_jpeg", "hclk_img_root", 0,
+	     RK3572_CLKGATE_CON(58), 4, GFLAGS),
+	GATE(HCLK_VDPP, "hclk_vdpp", "hclk_img_root", 0,
+	     RK3572_CLKGATE_CON(58), 5, GFLAGS),
+	GATE(ACLK_VDPP, "aclk_vdpp", "aclk_img_mid_root", 0,
+	     RK3572_CLKGATE_CON(58), 6, GFLAGS),
+	COMPOSITE(CLK_CORE_VDPP, "clk_core_vdpp", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(143), 12, 1, MFLAGS, 7, 5, DFLAGS,
+			RK3572_CLKGATE_CON(58), 7, GFLAGS),
+	COMPOSITE_NODIV(DCLK_EBC_SRC_TOP, "dclk_ebc_src_top", gpll_cpll_vpll_aupll_bpll_24m_p,
+			CLK_SET_RATE_NO_REPARENT,
+			RK3572_CLKSEL_CON(143), 13, 3, MFLAGS,
+			RK3572_CLKGATE_CON(58), 10, GFLAGS),
+	COMPOSITE_NOMUX(DCLK_EBC_INT_SRC, "dclk_ebc_int_src", "dclk_ebc_src_top",
+			CLK_SET_RATE_PARENT,
+			RK3572_CLKSEL_CON(144), 0, 9, DFLAGS,
+			RK3572_CLKGATE_CON(58), 11, GFLAGS),
+	COMPOSITE_FRACMUX(DCLK_EBC_FRAC_SRC, "dclk_ebc_frac_src", "dclk_ebc_src_top", 0,
+			  RK3572_CLKSEL_CON(145), 0,
+			RK3572_CLKGATE_CON(58), 12, GFLAGS, NULL),
+	GATE(HCLK_EBC, "hclk_ebc", "hclk_img_root", 0,
+	     RK3572_CLKGATE_CON(58), 13, GFLAGS),
+	GATE(ACLK_EBC, "aclk_ebc", "aclk_img_low_root", 0,
+	     RK3572_CLKGATE_CON(58), 14, GFLAGS),
+	COMPOSITE_NODIV(DCLK_EBC, "dclk_ebc", dclk_ebc_p,
+			CLK_SET_RATE_PARENT | CLK_SET_RATE_NO_REPARENT,
+			RK3572_CLKSEL_CON(146), 0, 1, MFLAGS,
+			RK3572_CLKGATE_CON(58), 15, GFLAGS),
+
+	/* pd_venc */
+	COMPOSITE_NODIV(HCLK_RKVENC_ROOT, "hclk_rkvenc_root", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(148), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(60), 0, GFLAGS),
+	COMPOSITE(ACLK_RKVENC_ROOT, "aclk_rkvenc_root", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(148), 7, 1, MFLAGS, 2, 5, DFLAGS,
+			RK3572_CLKGATE_CON(60), 1, GFLAGS),
+	GATE(HCLK_RKVENC, "hclk_rkvenc", "hclk_rkvenc_root", 0,
+	     RK3572_CLKGATE_CON(60), 4, GFLAGS),
+	GATE(ACLK_RKVENC, "aclk_rkvenc", "aclk_rkvenc_root", 0,
+	     RK3572_CLKGATE_CON(60), 5, GFLAGS),
+	COMPOSITE(CLK_RKVENC_CORE, "clk_rkvenc_core", gpll_cpll_spll_bpll_p, 0,
+		  RK3572_CLKSEL_CON(148), 13, 2, MFLAGS, 8, 5, DFLAGS,
+			RK3572_CLKGATE_CON(60), 6, GFLAGS),
+
+	/* pd_vi */
+	COMPOSITE(ACLK_VI_ROOT, "aclk_vi_root", gpll_spll_isppvtpll_bpll_p, CLK_IS_CRITICAL,
+		  RK3572_CLKSEL_CON(154), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(63), 0, GFLAGS),
+	COMPOSITE_NODIV(HCLK_VI_ROOT, "hclk_vi_root", hclk_vi_root_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(154), 7, 2, MFLAGS,
+			RK3572_CLKGATE_CON(63), 1, GFLAGS),
+	COMPOSITE_NODIV(PCLK_VI_ROOT, "pclk_vi_root", mux_100m_50m_24m_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(154), 9, 2, MFLAGS,
+			RK3572_CLKGATE_CON(63), 2, GFLAGS),
+	COMPOSITE(DCLK_VICAP, "dclk_vicap", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(155), 5, 1, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(63), 6, GFLAGS),
+	GATE(ACLK_VICAP, "aclk_vicap", "aclk_vi_root", 0,
+	     RK3572_CLKGATE_CON(63), 7, GFLAGS),
+	GATE(HCLK_VICAP, "hclk_vicap", "hclk_vi_root", 0,
+	     RK3572_CLKGATE_CON(63), 8, GFLAGS),
+	COMPOSITE(CLK_ISP_CORE, "clk_isp_core", gpll_spll_isppvtpll_bpll_p, 0,
+		  RK3572_CLKSEL_CON(155), 11, 2, MFLAGS, 6, 5, DFLAGS,
+			RK3572_CLKGATE_CON(63), 9, GFLAGS),
+	GATE(CLK_ISP_CORE_MARVIN, "clk_isp_core_marvin", "clk_isp_core", 0,
+	     RK3572_CLKGATE_CON(63), 10, GFLAGS),
+	GATE(CLK_ISP_CORE_VICAP, "clk_isp_core_vicap", "clk_isp_core", 0,
+	     RK3572_CLKGATE_CON(63), 11, GFLAGS),
+	GATE(ACLK_ISP, "aclk_isp", "aclk_vi_root", 0,
+	     RK3572_CLKGATE_CON(63), 12, GFLAGS),
+	GATE(HCLK_ISP, "hclk_isp", "hclk_vi_root", 0,
+	     RK3572_CLKGATE_CON(63), 13, GFLAGS),
+	GATE(ACLK_VPSS, "aclk_vpss", "aclk_vi_root", 0,
+	     RK3572_CLKGATE_CON(63), 15, GFLAGS),
+	GATE(HCLK_VPSS, "hclk_vpss", "hclk_vi_root", 0,
+	     RK3572_CLKGATE_CON(64), 0, GFLAGS),
+	GATE(CLK_CORE_VPSS, "clk_core_vpss", "clk_isp_core", 0,
+	     RK3572_CLKGATE_CON(64), 1, GFLAGS),
+	GATE(PCLK_CSI_HOST_0, "pclk_csi_host_0", "pclk_vi_root", 0,
+	     RK3572_CLKGATE_CON(64), 4, GFLAGS),
+	GATE(PCLK_CSI_HOST_1, "pclk_csi_host_1", "pclk_vi_root", 0,
+	     RK3572_CLKGATE_CON(64), 5, GFLAGS),
+	GATE(PCLK_CSI_HOST_2, "pclk_csi_host_2", "pclk_vi_root", 0,
+	     RK3572_CLKGATE_CON(64), 6, GFLAGS),
+	GATE(PCLK_CSI_HOST_3, "pclk_csi_host_3", "pclk_vi_root", 0,
+	     RK3572_CLKGATE_CON(64), 7, GFLAGS),
+	GATE(DCLK_VICAP_CSIHOST0, "dclk_vicap_csihost0", "dclk_vicap", 0,
+	     RK3572_CLKGATE_CON(64), 10, GFLAGS),
+	GATE(DCLK_VICAP_CSIHOST1, "dclk_vicap_csihost1", "dclk_vicap", 0,
+	     RK3572_CLKGATE_CON(64), 11, GFLAGS),
+	GATE(DCLK_VICAP_CSIHOST2, "dclk_vicap_csihost2", "dclk_vicap", 0,
+	     RK3572_CLKGATE_CON(64), 12, GFLAGS),
+	GATE(DCLK_VICAP_CSIHOST3, "dclk_vicap_csihost3", "dclk_vicap", 0,
+	     RK3572_CLKGATE_CON(64), 13, GFLAGS),
+	COMPOSITE_NOMUX(ACLK_VI_ROOT_INTER, "aclk_vi_root_inter", "aclk_vi_root", 0,
+			RK3572_CLKSEL_CON(156), 8, 3, DFLAGS,
+			RK3572_CLKGATE_CON(65), 4, GFLAGS),
+
+	/* pd_vop */
+	COMPOSITE(ACLK_VOP_ROOT, "aclk_vop_root", gpll_cpll_aupll_spll_bpll_p, CLK_IS_CRITICAL,
+		  RK3572_CLKSEL_CON(174), 5, 3, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(74), 0, GFLAGS),
+	COMPOSITE_NODIV(HCLK_VOP_ROOT, "hclk_vop_root", mux_200m_100m_50m_24m_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(174), 10, 2, MFLAGS,
+			RK3572_CLKGATE_CON(74), 2, GFLAGS),
+	COMPOSITE_NODIV(PCLK_VOP_ROOT, "pclk_vop_root", mux_100m_50m_24m_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(174), 12, 2, MFLAGS,
+			RK3572_CLKGATE_CON(74), 3, GFLAGS),
+	GATE(HCLK_VOP, "hclk_vop", "hclk_vop_root", 0,
+	     RK3572_CLKGATE_CON(74), 8, GFLAGS),
+	GATE(ACLK_VOP, "aclk_vop", "aclk_vop_root", 0,
+	     RK3572_CLKGATE_CON(74), 9, GFLAGS),
+	COMPOSITE(DCLK_VP0_SRC, "dclk_vp0_src", gpll_cpll_vpll_bpll_p, CLK_SET_RATE_NO_REPARENT,
+		  RK3572_CLKSEL_CON(175), 8, 2, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(74), 10, GFLAGS),
+	COMPOSITE(DCLK_VP1_SRC, "dclk_vp1_src", gpll_cpll_vpll_bpll_p, CLK_SET_RATE_NO_REPARENT,
+		  RK3572_CLKSEL_CON(176), 8, 2, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(74), 11, GFLAGS),
+	COMPOSITE_NODIV(DCLK_VP0, "dclk_vp0", dclk_vp0_p,
+			CLK_SET_RATE_PARENT | CLK_SET_RATE_NO_REPARENT,
+			RK3572_CLKSEL_CON(177), 11, 1, MFLAGS,
+			RK3572_CLKGATE_CON(74), 13, GFLAGS),
+	COMPOSITE_NODIV(DCLK_VP1, "dclk_vp1", dclk_vp1_p,
+			CLK_SET_RATE_PARENT | CLK_SET_RATE_NO_REPARENT,
+			RK3572_CLKSEL_CON(177), 12, 1, MFLAGS,
+			RK3572_CLKGATE_CON(75), 0, GFLAGS),
+	GATE(PCLK_DSIHOST0, "pclk_dsihost0", "pclk_vo_root", 0,
+	     RK3572_CLKGATE_CON(78), 1, GFLAGS),
+
+	/* pd_vo */
+	COMPOSITE(ACLK_VO_ROOT, "aclk_vo_root", gpll_cpll_bpll_p, 0,
+		  RK3572_CLKSEL_CON(185), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(78), 5, GFLAGS),
+	COMPOSITE_NODIV(HCLK_VO_ROOT, "hclk_vo_root", mux_200m_100m_50m_24m_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(185), 7, 2, MFLAGS,
+			RK3572_CLKGATE_CON(78), 6, GFLAGS),
+	COMPOSITE_NODIV(PCLK_VO_ROOT, "pclk_vo_root", mux_150m_100m_50m_24m_p, CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(185), 11, 2, MFLAGS,
+			RK3572_CLKGATE_CON(78), 8, GFLAGS),
+	GATE(PCLK_HDCP0_TRNG_NS, "pclk_hdcp0_trng_ns", "pclk_vo_root", 0,
+	     RK3572_CLKGATE_CON(79), 0, GFLAGS),
+	GATE(ACLK_HDCP0, "aclk_hdcp0", "aclk_vo_root", 0,
+	     RK3572_CLKGATE_CON(79), 1, GFLAGS),
+	GATE(HCLK_HDCP0, "hclk_hdcp0", "hclk_vo_root", 0,
+	     RK3572_CLKGATE_CON(79), 2, GFLAGS),
+	GATE(PCLK_HDCP0, "pclk_hdcp0", "pclk_vo_root", 0,
+	     RK3572_CLKGATE_CON(79), 3, GFLAGS),
+	GATE(CLK_TRNG0_SKP, "clk_trng0_skp", "aclk_hdcp0", 0,
+	     RK3572_CLKGATE_CON(79), 9, GFLAGS),
+	GATE(PCLK_HDMITX0, "pclk_hdmitx0", "pclk_vo_root", 0,
+	     RK3572_CLKGATE_CON(79), 14, GFLAGS),
+	COMPOSITE(CLK_HDMITX0_EARC, "clk_hdmitx0_earc", gpll_cpll_p, 0,
+		  RK3572_CLKSEL_CON(188), 15, 1, MFLAGS, 10, 5, DFLAGS,
+			RK3572_CLKGATE_CON(79), 15, GFLAGS),
+	GATE(CLK_HDMITX0_REF, "clk_hdmitx0_ref", "aclk_vo_root", 0,
+	     RK3572_CLKGATE_CON(80), 0, GFLAGS),
+	GATE(PCLK_EDP0, "pclk_edp0", "pclk_vo_root", 0,
+	     RK3572_CLKGATE_CON(80), 2, GFLAGS),
+	GATE(CLK_EDP0_24M, "clk_edp0_24m", "xin24m", 0,
+	     RK3572_CLKGATE_CON(80), 3, GFLAGS),
+	COMPOSITE_NODIV(CLK_EDP0_200M, "clk_edp0_200m", mux_200m_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(189), 0, 2, MFLAGS,
+			RK3572_CLKGATE_CON(80), 4, GFLAGS),
+	COMPOSITE(MCLK_SAI4_SRC, "mclk_sai4_src", mux_24m_frac_int_mclk4_p, 0,
+		  RK3572_CLKSEL_CON(189), 10, 4, MFLAGS, 2, 8, DFLAGS,
+			RK3572_CLKGATE_CON(80), 5, GFLAGS),
+	COMPOSITE_NODIV(MCLK_SAI4, "mclk_sai4", mclk_sai4_p, CLK_SET_RATE_PARENT,
+			RK3572_CLKSEL_CON(189), 14, 1, MFLAGS,
+			RK3572_CLKGATE_CON(80), 6, GFLAGS),
+	GATE(HCLK_SAI4, "hclk_sai4", "hclk_vo_root", 0,
+	     RK3572_CLKGATE_CON(80), 7, GFLAGS),
+	COMPOSITE(MCLK_SAI5_SRC, "mclk_sai5_src", mux_24m_frac_int_mclk4_p, 0,
+		  RK3572_CLKSEL_CON(190), 8, 4, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(80), 8, GFLAGS),
+	COMPOSITE_NODIV(MCLK_SAI5, "mclk_sai5", mclk_sai5_p, CLK_SET_RATE_PARENT,
+			RK3572_CLKSEL_CON(190), 12, 1, MFLAGS,
+			RK3572_CLKGATE_CON(80), 9, GFLAGS),
+	GATE(HCLK_SAI5, "hclk_sai5", "hclk_vo_root", 0,
+	     RK3572_CLKGATE_CON(80), 10, GFLAGS),
+	GATE(HCLK_SPDIF_TX2, "hclk_spdif_tx2", "hclk_vo_root", 0,
+	     RK3572_CLKGATE_CON(80), 11, GFLAGS),
+	COMPOSITE(MCLK_SPDIF_TX2_SRC, "mclk_spdif_tx2_src", mux_24m_frac_int_mclk4_p, 0,
+		  RK3572_CLKSEL_CON(191), 8, 4, MFLAGS, 0, 8, DFLAGS,
+			RK3572_CLKGATE_CON(80), 12, GFLAGS),
+	COMPOSITE_NODIV(MCLK_SPDIF_TX2, "mclk_spdif_tx2", mclk_spdif_tx2_p, CLK_SET_RATE_PARENT,
+			RK3572_CLKSEL_CON(191), 12, 1, MFLAGS,
+			RK3572_CLKGATE_CON(80), 13, GFLAGS),
+	GATE(HCLK_SPDIF_RX1, "hclk_spdif_rx1", "hclk_vo_root", 0,
+	     RK3572_CLKGATE_CON(80), 14, GFLAGS),
+	COMPOSITE(MCLK_SPDIF_RX1, "mclk_spdif_rx1", gpll_cpll_aupll_p, 0,
+		  RK3572_CLKSEL_CON(192), 5, 2, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(80), 15, GFLAGS),
+	GATE(CLK_SAI4_MCLKOUT, "clk_sai4_mclkout", "mclk_sai4", 0,
+	     RK3572_CLKGATE_CON(81), 12, GFLAGS),
+
+	/* pd_gpu */
+	COMPOSITE(CLK_GPU_SRC, "clk_gpu_src", gpll_cpll_aupll_spll_bpll_p, 0,
+		  RK3572_CLKSEL_CON(202), 5, 3, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(84), 1, GFLAGS),
+	GATE(CLK_GPU, "clk_gpu", "clk_gpu_src", 0,
+	     RK3572_CLKGATE_CON(84), 3, GFLAGS),
+	COMPOSITE_NOMUX(CLK_GPU_COREGROUP, "clk_gpu_coregroup", "clk_gpu_src", 0,
+			RK3572_CLKSEL_CON(202), 9, 5, DFLAGS,
+			RK3572_CLKGATE_CON(84), 5, GFLAGS),
+	COMPOSITE_NOMUX(CLK_GPU_STACKS, "clk_gpu_stacks", "clk_gpu_src", 0,
+			RK3572_CLKSEL_CON(203), 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(84), 6, GFLAGS),
+	COMPOSITE_NODIV(PCLK_GPU_ROOT, "pclk_gpu_root", mux_100m_50m_24m_p, 0,
+			RK3572_CLKSEL_CON(203), 5, 2, MFLAGS,
+			RK3572_CLKGATE_CON(84), 7, GFLAGS),
+
+	/* pd_center */
+	COMPOSITE(ACLK_CENTER_ROOT, "aclk_center_root", gpll_cpll_spll_aupll_bpll_p,
+		  CLK_IS_CRITICAL,
+		  RK3572_CLKSEL_CON(206), 5, 3, MFLAGS, 0, 5, DFLAGS,
+			RK3572_CLKGATE_CON(86), 0, GFLAGS),
+	COMPOSITE_NODIV(ACLK_CENTER_LOW_ROOT, "aclk_center_low_root", mux_500m_250m_100m_24m_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(206), 8, 2, MFLAGS,
+			RK3572_CLKGATE_CON(86), 1, GFLAGS),
+	COMPOSITE_NODIV(HCLK_CENTER_ROOT, "hclk_center_root", mux_200m_100m_50m_24m_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(206), 10, 2, MFLAGS,
+			RK3572_CLKGATE_CON(86), 2, GFLAGS),
+	COMPOSITE_NODIV(PCLK_CENTER_ROOT, "pclk_center_root", mux_200m_100m_50m_24m_p,
+			CLK_IS_CRITICAL,
+			RK3572_CLKSEL_CON(206), 12, 2, MFLAGS,
+			RK3572_CLKGATE_CON(86), 3, GFLAGS),
+	GATE(ACLK_DMA2DDR, "aclk_dma2ddr", "aclk_center_root", 0,
+	     RK3572_CLKGATE_CON(86), 8, GFLAGS),
+	GATE(ACLK_DDR_SHAREMEM, "aclk_ddr_sharemem", "aclk_center_low_root", CLK_IS_CRITICAL,
+	     RK3572_CLKGATE_CON(86), 9, GFLAGS),
+	GATE(PCLK_DMA2DDR, "pclk_dma2ddr", "pclk_center_root", 0,
+	     RK3572_CLKGATE_CON(86), 15, GFLAGS),
+
+	/* pd_secure */
+	COMPOSITE_NODIV(HCLK_SECURE_NS_ROOT, "hclk_secure_ns_root", mux_175m_116m_58m_24m_p,
+			CLK_IS_CRITICAL,
+			RK3572_SECURE_NS_CLKSEL_CON(0), 2, 2, MFLAGS,
+			RK3572_SECURE_NS_CLKGATE_CON(0), 1, GFLAGS),
+	COMPOSITE_NODIV(PCLK_SECURE_NS_ROOT, "pclk_secure_ns_root", mux_116m_58m_24m_p, 0,
+			RK3572_SECURE_NS_CLKSEL_CON(0), 4, 2, MFLAGS,
+			RK3572_SECURE_NS_CLKGATE_CON(0), 2, GFLAGS),
+	GATE(HCLK_CRYPTO_NS, "hclk_crypto_ns", "hclk_secure_ns_root", 0,
+	     RK3572_SECURE_NS_CLKGATE_CON(0), 3, GFLAGS),
+	GATE(HCLK_TRNG_NS, "hclk_trng_ns", "hclk_secure_ns_root", 0,
+	     RK3572_SECURE_NS_CLKGATE_CON(0), 4, GFLAGS),
+	GATE(PCLK_OTPC_NS, "pclk_otpc_ns", "pclk_secure_ns_root", 0,
+	     RK3572_SECURE_NS_CLKGATE_CON(0), 8, GFLAGS),
+	GATE(CLK_OTPC_NS, "clk_otpc_ns", "xin24m", 0,
+	     RK3572_SECURE_NS_CLKGATE_CON(0), 9, GFLAGS),
+	GATE(ACLK_CRYPTO_NS, "aclk_crypto_ns", "clk_spll_div2", 0,
+	     RK3572_NON_SECURE_GATING_CON00, 2, GFLAGS),
+	GATE(CLK_PKA_CRYPTO_NS, "clk_pka_crypto_ns", "clk_spll_div2", 0,
+	     RK3572_NON_SECURE_GATING_CON00, 1, GFLAGS),
+
+	/* pd_pmu */
+	MUX(CLK_REF_OSC_MPHY, "clk_ref_osc_mphy", clk_ref_osc_mphy_p, 0,
+	    RK3572_PMU_CLKSEL_CON(3), 0, 1, MFLAGS),
+	GATE(CLK_REF_UFS_CLKOUT, "clk_ref_ufs_clkout", "clk_ref_osc_mphy", 0,
+	     RK3572_PMU_CLKGATE_CON(2), 5, GFLAGS),
+	COMPOSITE_NODIV(HCLK_PMU1_ROOT, "hclk_pmu1_root", mux_200m_100m_50m_24m_p, CLK_IS_CRITICAL,
+			RK3572_PMU_CLKSEL_CON(4), 0, 2, MFLAGS,
+			RK3572_PMU_CLKGATE_CON(3), 0, GFLAGS),
+	COMPOSITE_NODIV(HCLK_PMU_CM0_ROOT, "hclk_pmu_cm0_root", mux_200m_100m_50m_24m_p, 0,
+			RK3572_PMU_CLKSEL_CON(4), 2, 2, MFLAGS,
+			RK3572_PMU_CLKGATE_CON(3), 1, GFLAGS),
+	COMPOSITE_NODIV(PCLK_PMU0_ROOT, "pclk_pmu0_root", mux_100m_50m_24m_p, 0,
+			RK3572_PMU_CLKSEL_CON(20), 0, 2, MFLAGS,
+			RK3572_PMU_CLKGATE_CON(7), 0, GFLAGS),
+	GATE(PCLK_PMU1_ROOT, "pclk_pmu1_root", "pclk_pmu0_root", 0,
+	     RK3572_PMU_CLKGATE_CON(7), 10, GFLAGS),
+	GATE(PCLK_APB2ASB_PMU1, "pclk_apb2asb_pmu1", "pclk_pmu1_root", CLK_IS_CRITICAL,
+	     RK3572_PMU_CLKGATE_CON(3), 6, GFLAGS),
+	COMPOSITE_NODIV(SCLK_APB2ASB_PMU1, "sclk_apb2asb_pmu1", sclk_apb2asb_p, CLK_IS_CRITICAL,
+			RK3572_PMU_CLKSEL_CON(4), 4, 2, MFLAGS,
+			RK3572_PMU_CLKGATE_CON(3), 7, GFLAGS),
+	GATE(CLK_PMUMCU_CORE_AON, "clk_pmumcu_core_aon", "hclk_pmu_cm0_root", 0,
+	     RK3572_PMU_CLKGATE_CON(3), 13, GFLAGS),
+	COMPOSITE(CLK_MTIME_TOGGLE_A_PMU, "clk_mtime_toggle_a_pmu", mux_24m_32k_p, 0,
+		  RK3572_PMU_CLKSEL_CON(4), 12, 1, MFLAGS, 6, 6, DFLAGS,
+			RK3572_PMU_CLKGATE_CON(3), 15, GFLAGS),
+	GATE(PCLK_PMU1, "pclk_pmu1", "pclk_pmu1_root", CLK_IS_CRITICAL,
+	     RK3572_PMU_CLKGATE_CON(4), 0, GFLAGS),
+	GATE(CLK_PMU1, "clk_pmu1", "xin24m", CLK_IS_CRITICAL,
+	     RK3572_PMU_CLKGATE_CON(4), 3, GFLAGS),
+	GATE(PCLK_PMU1WDT, "pclk_pmu1wdt", "pclk_pmu1_root", 0,
+	     RK3572_PMU_CLKGATE_CON(4), 6, GFLAGS),
+	COMPOSITE_NODIV(TCLK_PMU1WDT, "tclk_pmu1wdt", mux_24m_32k_p, 0,
+			RK3572_PMU_CLKSEL_CON(4), 13, 1, MFLAGS,
+			RK3572_PMU_CLKGATE_CON(4), 7, GFLAGS),
+	GATE(PCLK_PMUTIMER, "pclk_pmutimer", "pclk_pmu1_root", 0,
+	     RK3572_PMU_CLKGATE_CON(4), 8, GFLAGS),
+	COMPOSITE_NODIV(CLK_PMUTIMER_ROOT, "clk_pmutimer_root", mux_100m_24m_32k_p, 0,
+			RK3572_PMU_CLKSEL_CON(4), 14, 2, MFLAGS,
+			RK3572_PMU_CLKGATE_CON(4), 9, GFLAGS),
+	GATE(CLK_PMUTIMER0, "clk_pmutimer0", "clk_pmutimer_root", 0,
+	     RK3572_PMU_CLKGATE_CON(4), 10, GFLAGS),
+	GATE(CLK_PMUTIMER1, "clk_pmutimer1", "clk_pmutimer_root", 0,
+	     RK3572_PMU_CLKGATE_CON(4), 11, GFLAGS),
+	GATE(PCLK_PWM0, "pclk_pwm0", "pclk_pmu1_root", 0,
+	     RK3572_PMU_CLKGATE_CON(4), 12, GFLAGS),
+	COMPOSITE_NODIV(CLK_PWM0, "clk_pwm0", mux_100m_50m_24m_rc_p, 0,
+			RK3572_PMU_CLKSEL_CON(5), 0, 2, MFLAGS,
+			RK3572_PMU_CLKGATE_CON(4), 13, GFLAGS),
+	COMPOSITE_NODIV(CLK_PWM0_OSC, "clk_pwm0_osc", clk_pwm0_osc_p, 0,
+			RK3572_PMU_CLKSEL_CON(5), 2, 1, MFLAGS,
+			RK3572_PMU_CLKGATE_CON(4), 14, GFLAGS),
+	GATE(PCLK_PMUPHY_ROOT, "pclk_pmuphy_root", "pclk_pmu1_root", CLK_IS_CRITICAL,
+	     RK3572_PMU_CLKGATE_CON(5), 1, GFLAGS),
+	GATE(PCLK_I2C0, "pclk_i2c0", "pclk_pmu1_root", 0,
+	     RK3572_PMU_CLKGATE_CON(5), 2, GFLAGS),
+	COMPOSITE_NODIV(CLK_I2C0, "clk_i2c0", mux_200m_100m_50m_24m_p, 0,
+			RK3572_PMU_CLKSEL_CON(6), 7, 2, MFLAGS,
+			RK3572_PMU_CLKGATE_CON(5), 3, GFLAGS),
+	COMPOSITE_NODIV(SCLK_UART1, "sclk_uart1", sclk_uart1_p, 0,
+			RK3572_PMU_CLKSEL_CON(8), 0, 2, MFLAGS,
+			RK3572_PMU_CLKGATE_CON(5), 6, GFLAGS),
+	GATE(PCLK_UART1, "pclk_uart1", "pclk_pmu1_root", 0,
+	     RK3572_PMU_CLKGATE_CON(5), 7, GFLAGS),
+	GATE(CLK_PWM0_RC, "clk_pwm0_rc", "clk_rcosc", 0,
+	     RK3572_PMU_CLKGATE_CON(5), 8, GFLAGS),
+	COMPOSITE(CLK_PDM0, "clk_pdm0", clk_pdm0_p, CLK_SET_RATE_PARENT,
+		  RK3572_PMU_CLKSEL_CON(8), 14, 2, MFLAGS, 8, 6, DFLAGS,
+			RK3572_PMU_CLKGATE_CON(5), 14, GFLAGS),
+	GATE(HCLK_PDM0, "hclk_pdm0", "hclk_pmu1_root", 0,
+	     RK3572_PMU_CLKGATE_CON(6), 0, GFLAGS),
+	COMPOSITE_NODIV(MCLK_PDM0, "mclk_pdm0", mclk_pdm0_p, CLK_SET_RATE_PARENT,
+			RK3572_PMU_CLKSEL_CON(9), 0, 2, MFLAGS,
+			RK3572_PMU_CLKGATE_CON(6), 1, GFLAGS),
+	GATE(HCLK_VAD, "hclk_vad", "hclk_pmu1_root", 0,
+	     RK3572_PMU_CLKGATE_CON(6), 2, GFLAGS),
+	GATE(CLK_PDM0_OUT, "clk_pdm0_out", "clk_pdm0", 0,
+	     RK3572_PMU_CLKGATE_CON(6), 9, GFLAGS),
+	GATE(PCLK_PMU0, "pclk_pmu0", "pclk_pmu0_root", CLK_IS_CRITICAL,
+	     RK3572_PMU_CLKGATE_CON(7), 3, GFLAGS),
+	GATE(PCLK_GPIO0, "pclk_gpio0", "pclk_pmu0_root", 0,
+	     RK3572_PMU_CLKGATE_CON(7), 6, GFLAGS),
+	COMPOSITE_NODIV(DBCLK_GPIO0, "dbclk_gpio0", mux_24m_32k_p, 0,
+			RK3572_PMU_CLKSEL_CON(20), 2, 1, MFLAGS,
+			RK3572_PMU_CLKGATE_CON(7), 7, GFLAGS),
+
+	COMPOSITE_NODIV(SAI_SCLKIN_FREQ, "sai_sclkin_freq", sai_sclkin_freq_p, 0,
+			RK3572_CLKSEL_CON(83), 4, 3, MFLAGS,
+			RK3572_CLKGATE_CON(18), 2, GFLAGS),
+	COMPOSITE_NODIV(SAI_SCLKIN_COUNTER, "sai_sclkin_counter", sai_sclkin_freq_p, 0,
+			RK3572_CLKSEL_CON(83), 7, 3, MFLAGS,
+			RK3572_CLKGATE_CON(18), 3, GFLAGS),
+	COMPOSITE_NODIV(CLK_FREQ_PWM1, "clk_freq_pwm1", clk_freq_pwm1_p, 0,
+			RK3572_CLKSEL_CON(82), 10, 3, MFLAGS,
+			RK3572_CLKGATE_CON(17), 8, GFLAGS),
+	COMPOSITE_NODIV(CLK_COUNTER_PWM1, "clk_counter_pwm1", clk_counter_pwm1_p, 0,
+			RK3572_CLKSEL_CON(82), 13, 3, MFLAGS,
+			RK3572_CLKGATE_CON(17), 9, GFLAGS),
+	MUX(ASRC_REF_PULSE, "asrc_ref_pulse", asrc_ref_pulse_p, 0,
+	    RK3572_CLKSEL_CON(62), 12, 3, MFLAGS),
+	MUX(LRCK_ASRC_2CH0_SRC, "lrck_asrc_2ch0_src", lrck_asrc_src_p, 0,
+	    RK3572_CLKSEL_CON(59), 0, 4, MFLAGS),
+	MUX(LRCK_ASRC_2CH0_DST, "lrck_asrc_2ch0_dst", lrck_asrc_dst_p, 0,
+	    RK3572_CLKSEL_CON(59), 4, 4, MFLAGS),
+	MUX(LRCK_ASRC_2CH1_SRC, "lrck_asrc_2ch1_src", lrck_asrc_src_p, 0,
+	    RK3572_CLKSEL_CON(59), 8, 4, MFLAGS),
+	MUX(LRCK_ASRC_2CH1_DST, "lrck_asrc_2ch1_dst", lrck_asrc_dst_p, 0,
+	    RK3572_CLKSEL_CON(59), 12, 4, MFLAGS),
+	MUX(REF_PULSE_CLK_AUDIO_FRAC_0, "ref_pulse_clk_audio_frac_0", ref_pulse_p, 0,
+	    RK3572_CLKSEL_CON(40), 13, 3, MFLAGS),
+	MUX(REF_PULSE_CLK_AUDIO_FRAC_1, "ref_pulse_clk_audio_frac_1", ref_pulse_p, 0,
+	    RK3572_CLKSEL_CON(41), 0, 3, MFLAGS),
+	MUX(REF_PULSE_CLK_AUDIO_FRAC_2, "ref_pulse_clk_audio_frac_2", ref_pulse_p, 0,
+	    RK3572_CLKSEL_CON(41), 3, 3, MFLAGS),
+	MUX(REF_PULSE_FRACDIV_3, "ref_pulse_fracdiv_3", ref_pulse_p, 0,
+	    RK3572_CLKSEL_CON(41), 6, 3, MFLAGS),
+	MUX(REF_PULSE_AUPLL, "ref_pulse_aupll", ref_pulse_p, 0,
+	    RK3572_CLKSEL_CON(41), 9, 3, MFLAGS),
+};
+
+static struct rockchip_clk_branch rk3572_armclkl1 __initdata =
+	COMPOSITE_NOGATE(ARMCLK_L1, "armclk_l1", mux_armclkl1_p, CLK_IS_CRITICAL,
+			 RK3572_LITCORE1_CLKSEL_CON(0), 8, 2, MFLAGS, 3, 5, DFLAGS);
+
+static struct rockchip_clk_branch rk3572_aupll_ref_branches[] __initdata = {
+	MUXGRF(AUPLL_REF, "aupll_ref", mux_aupll_ref_p, CLK_IS_CRITICAL,
+	       RK3572_PMU0_GRF_OSC_CON6, 0, 1, MFLAGS, grf_type_pmu0),
+};
+
+static void __init rk3572_clk_init(struct device_node *np)
+{
+	struct rockchip_clk_provider *ctx;
+	void __iomem *reg_base;
+	struct regmap *pmu0_grf;
+	int ret;
+
+	reg_base = of_iomap(np, 0);
+	if (!reg_base) {
+		pr_err("%s: could not map cru region\n", __func__);
+		return;
+	}
+
+	ctx = rockchip_clk_init(np, reg_base, CLK_NR_CLKS);
+	if (IS_ERR(ctx)) {
+		pr_err("%s: rockchip clk init failed\n", __func__);
+		iounmap(reg_base);
+		return;
+	}
+	pmu0_grf = ctx->grf;
+	if (IS_ERR(pmu0_grf)) {
+		pr_err("%s: could not get PMU0 GRF\n", __func__);
+		goto err_free;
+	}
+
+	ret = rockchip_clk_add_grf(ctx, pmu0_grf, grf_type_pmu0);
+	if (ret)
+		goto err_free;
+
+	rockchip_clk_register_branches(ctx, rk3572_aupll_ref_branches,
+				       ARRAY_SIZE(rk3572_aupll_ref_branches));
+
+	rockchip_clk_register_plls(ctx, rk3572_pll_clks,
+				   ARRAY_SIZE(rk3572_pll_clks),
+				   RK3572_GRF_SOC_STATUS0);
+
+	rockchip_clk_register_armclk(ctx, ARMCLK_L0, "armclk_l0",
+				     mux_armclkl0_p, ARRAY_SIZE(mux_armclkl0_p),
+				     &rk3572_cpul0clk_data, rk3572_cpul0clk_rates,
+				     ARRAY_SIZE(rk3572_cpul0clk_rates));
+
+	rockchip_clk_register_armclk(ctx, ARMCLK_B, "armclk_b",
+				     mux_armclkb_p, ARRAY_SIZE(mux_armclkb_p),
+				     &rk3572_cpubclk_data, rk3572_cpubclk_rates,
+				     ARRAY_SIZE(rk3572_cpubclk_rates));
+
+	rockchip_clk_register_branches(ctx, rk3572_clk_branches,
+				       ARRAY_SIZE(rk3572_clk_branches));
+
+	rockchip_clk_register_armclk_multi_pll(ctx, &rk3572_armclkl1,
+					       rk3572_cpul1clk_rates,
+					ARRAY_SIZE(rk3572_cpul1clk_rates));
+
+	rk3572_rst_init(np, reg_base);
+
+	rockchip_register_restart_notifier(ctx, RK3572_GLB_SRST_FST, NULL);
+
+	rockchip_clk_of_add_provider(np, ctx);
+	return;
+
+err_free:
+	kfree(ctx->clk_data.clks);
+	kfree(ctx);
+	iounmap(reg_base);
+}
+
+CLK_OF_DECLARE(rk3572_cru, "rockchip,rk3572-cru", rk3572_clk_init);
diff --git a/drivers/clk/rockchip/clk.h b/drivers/clk/rockchip/clk.h
index 72b36bba3152..b77f440e9104 100644
--- a/drivers/clk/rockchip/clk.h
+++ b/drivers/clk/rockchip/clk.h
@@ -426,6 +426,41 @@ struct clk;
 #define RK3568_PMU_CLKGATE_CON(x)	((x) * 0x4 + 0x180)
 #define RK3568_PMU_SOFTRST_CON(x)	((x) * 0x4 + 0x200)
 
+#define RK3572_PHP_CRU_BASE		0x8000
+#define RK3572_SECURE_NS_CRU_BASE	0x10000
+#define RK3572_PMU_CRU_BASE		0x20000
+#define RK3572_BIGCORE_CRU_BASE		0x40000
+#define RK3572_LITCORE0_CRU_BASE	0x48000
+#define RK3572_LITCORE1_CRU_BASE	0x50000
+#define RK3572_CCI_CRU_BASE		0x58000
+
+#define RK3572_PLL_CON(x)		(RK2928_PLL_CON(x) + 0x4000)
+#define RK3572_MODE_CON0		0x4280
+#define RK3572_MODE_CON1		0x4284
+#define RK3572_CLKSEL_CON(x)		((x) * 0x4 + 0x300)
+#define RK3572_CLKGATE_CON(x)		((x) * 0x4 + 0x800)
+#define RK3572_SOFTRST_CON(x)		((x) * 0x4 + 0xa00)
+#define RK3572_GLB_SRST_FST		0xc08
+#define RK3572_NON_SECURE_GATING_CON00	0xc48
+
+#define RK3572_PPLL_CON(x)		((x) * 0x4 + RK3572_PHP_CRU_BASE)
+#define RK3572_PHP_CLKSEL_CON(x)	((x) * 0x4 + RK3572_PHP_CRU_BASE + 0x300)
+#define RK3572_PHP_CLKGATE_CON(x)	((x) * 0x4 + RK3572_PHP_CRU_BASE + 0x800)
+
+#define RK3572_PMU_CLKSEL_CON(x)	((x) * 0x4 + RK3572_PMU_CRU_BASE + 0x300)
+#define RK3572_PMU_CLKGATE_CON(x)	((x) * 0x4 + RK3572_PMU_CRU_BASE + 0x800)
+
+#define RK3572_SECURE_NS_CLKSEL_CON(x)	((x) * 0x4 + RK3572_SECURE_NS_CRU_BASE + 0x300)
+#define RK3572_SECURE_NS_CLKGATE_CON(x)	((x) * 0x4 + RK3572_SECURE_NS_CRU_BASE + 0x800)
+
+#define RK3572_LPLL_CON(x)		((x) * 0x4 + RK3572_CCI_CRU_BASE)
+#define RK3572_LPLL_MODE_CON0		(0x280 + RK3572_CCI_CRU_BASE)
+#define RK3572_CCI_CLKSEL_CON(x)	((x) * 0x4 + RK3572_CCI_CRU_BASE + 0x300)
+
+#define RK3572_BIGCORE_CLKSEL_CON(x)	((x) * 0x4 + RK3572_BIGCORE_CRU_BASE + 0x300)
+#define RK3572_LITCORE0_CLKSEL_CON(x)	((x) * 0x4 + RK3572_LITCORE0_CRU_BASE + 0x300)
+#define RK3572_LITCORE1_CLKSEL_CON(x)	((x) * 0x4 + RK3572_LITCORE1_CRU_BASE + 0x300)
+
 #define RK3576_PHP_CRU_BASE		0x8000
 #define RK3576_SECURE_NS_CRU_BASE	0x10000
 #define RK3576_PMU_CRU_BASE		0x20000
@@ -1396,6 +1431,7 @@ void rv1126b_rst_init(struct device_node *np, void __iomem *reg_base);
 void rk3506_rst_init(struct device_node *np, void __iomem *reg_base);
 void rk3528_rst_init(struct device_node *np, void __iomem *reg_base);
 void rk3562_rst_init(struct device_node *np, void __iomem *reg_base);
+void rk3572_rst_init(struct device_node *np, void __iomem *reg_base);
 void rk3576_rst_init(struct device_node *np, void __iomem *reg_base);
 void rk3588_rst_init(struct device_node *np, void __iomem *reg_base);
 
diff --git a/drivers/clk/rockchip/rst-rk3572.c b/drivers/clk/rockchip/rst-rk3572.c
new file mode 100644
index 000000000000..a07f88dadc00
--- /dev/null
+++ b/drivers/clk/rockchip/rst-rk3572.c
@@ -0,0 +1,739 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Copyright (c) 2025 Rockchip Electronics Co., Ltd.
+ * Author: Elaine Zhang <zhangqing@rock-chips.com>
+ */
+
+#include <linux/module.h>
+#include <linux/of.h>
+#include <dt-bindings/reset/rockchip,rk3572-cru.h>
+#include "clk.h"
+
+#define CRU_RESET_OFFSET(id, reg, bit)[id] = (0x00000 * 4 + (reg) * 16 + (bit))
+#define PHPPHY_CRU_RESET_OFFSET(id, reg, bit)[id] = (0x08000 * 4 + (reg) * 16 + (bit))
+#define SECURE_CRU_RESET_OFFSET(id, reg, bit)[id] = (0x10000 * 4 + (reg) * 16 + (bit))
+#define PMU1_CRU_RESET_OFFSET(id, reg, bit)[id] = (0x20000 * 4 + (reg) * 16 + (bit))
+#define DDR0_CRU_RESET_OFFSET(id, reg, bit)[id] = (0x30000 * 4 + (reg) * 16 + (bit))
+#define BIGCORE_CRU_RESET_OFFSET(id, reg, bit)[id] = (0x40000 * 4 + (reg) * 16 + (bit))
+#define LITCORE0_CRU_RESET_OFFSET(id, reg, bit)[id] = (0x48000 * 4 + (reg) * 16 + (bit))
+#define LITCORE1_CRU_RESET_OFFSET(id, reg, bit)[id] = (0x50000 * 4 + (reg) * 16 + (bit))
+#define CCI_CRU_RESET_OFFSET(id, reg, bit)[id] = (0x58000 * 4 + (reg) * 16 + (bit))
+
+static const int rk3572_register_offset[] = {
+	/* CRU-->SOFTRST_CON01 */
+	CRU_RESET_OFFSET(SRST_ARESETN_TOP_BIU, 1, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_TOP_BIU, 1, 6),
+	CRU_RESET_OFFSET(SRST_ARESETN_TOP_MID_BIU, 1, 7),
+	CRU_RESET_OFFSET(SRST_HRESETN_TOP_BIU, 1, 15),
+
+	/* CRU-->SOFTRST_CON02 */
+	CRU_RESET_OFFSET(SRST_HRESETN_TOP_FW, 2, 0),
+
+	/* CRU-->SOFTRST_CON06 */
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_TOP, 6, 2),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_TOP, 6, 3),
+
+	/* CRU-->SOFTRST_CON07 */
+	CRU_RESET_OFFSET(SRST_HRESETN_AUDIO_BIU, 7, 2),
+	CRU_RESET_OFFSET(SRST_HRESETN_ASRC_2CH_0, 7, 3),
+	CRU_RESET_OFFSET(SRST_HRESETN_ASRC_2CH_1, 7, 4),
+	CRU_RESET_OFFSET(SRST_RESETN_ASRC_2CH_0, 7, 7),
+	CRU_RESET_OFFSET(SRST_RESETN_ASRC_2CH_1, 7, 8),
+	CRU_RESET_OFFSET(SRST_MRESETN_SAI0, 7, 12),
+	CRU_RESET_OFFSET(SRST_HRESETN_SAI0, 7, 13),
+	CRU_RESET_OFFSET(SRST_HRESETN_SPDIF_RX0, 7, 14),
+	CRU_RESET_OFFSET(SRST_MRESETN_SPDIF_RX0, 7, 15),
+
+	/* CRU-->SOFTRST_CON08 */
+	CRU_RESET_OFFSET(SRST_MRESETN_SAI1, 8, 5),
+	CRU_RESET_OFFSET(SRST_HRESETN_SAI1, 8, 6),
+	CRU_RESET_OFFSET(SRST_MRESETN_SAI2, 8, 8),
+	CRU_RESET_OFFSET(SRST_HRESETN_SAI2, 8, 10),
+	CRU_RESET_OFFSET(SRST_MRESETN_SAI3, 8, 12),
+	CRU_RESET_OFFSET(SRST_HRESETN_SAI3, 8, 14),
+	CRU_RESET_OFFSET(SRST_HRESETN_ACDCDIG_DSM, 8, 15),
+
+	/* CRU-->SOFTRST_CON09 */
+	CRU_RESET_OFFSET(SRST_MRESETN_ACDCDIG_DSM, 9, 0),
+	CRU_RESET_OFFSET(SRST_PRESETN_AUDIO_BIU, 9, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_AUDIO_GRF, 9, 5),
+	CRU_RESET_OFFSET(SRST_HRESETN_SPDIF_TX0, 9, 6),
+	CRU_RESET_OFFSET(SRST_MRESETN_SPDIF_TX0, 9, 7),
+	CRU_RESET_OFFSET(SRST_HRESETN_SPDIF_TX1, 9, 8),
+	CRU_RESET_OFFSET(SRST_MRESETN_SPDIF_TX1, 9, 9),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_AUDIO, 9, 10),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_AUDIO, 9, 11),
+
+	/* CRU-->SOFTRST_CON11 */
+	CRU_RESET_OFFSET(SRST_ARESETN_BUS_BIU, 11, 3),
+	CRU_RESET_OFFSET(SRST_ARESETN_BUS_FW, 11, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_BUS_BIU, 11, 5),
+	CRU_RESET_OFFSET(SRST_PRESETN_CRU, 11, 6),
+	CRU_RESET_OFFSET(SRST_HRESETN_CAN0, 11, 7),
+	CRU_RESET_OFFSET(SRST_RESETN_CAN0, 11, 8),
+	CRU_RESET_OFFSET(SRST_HRESETN_CAN1, 11, 9),
+	CRU_RESET_OFFSET(SRST_RESETN_CAN1, 11, 10),
+	CRU_RESET_OFFSET(SRST_HRESETN_CAN2, 11, 11),
+	CRU_RESET_OFFSET(SRST_RESETN_CAN2, 11, 12),
+	CRU_RESET_OFFSET(SRST_HRESETN_CAN3, 11, 13),
+	CRU_RESET_OFFSET(SRST_RESETN_CAN3, 11, 14),
+
+	/* CRU-->SOFTRST_CON12 */
+	CRU_RESET_OFFSET(SRST_ARESETN_DECOM_BIU, 12, 0),
+	CRU_RESET_OFFSET(SRST_HRESETN_BUS_BIU, 12, 3),
+	CRU_RESET_OFFSET(SRST_RESETN_KEY_SHIFT, 12, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_I2C1, 12, 5),
+	CRU_RESET_OFFSET(SRST_PRESETN_I2C2, 12, 6),
+	CRU_RESET_OFFSET(SRST_PRESETN_I2C3, 12, 7),
+	CRU_RESET_OFFSET(SRST_PRESETN_I2C4, 12, 8),
+	CRU_RESET_OFFSET(SRST_PRESETN_I2C5, 12, 9),
+	CRU_RESET_OFFSET(SRST_PRESETN_I2C6, 12, 10),
+	CRU_RESET_OFFSET(SRST_PRESETN_I2C7, 12, 11),
+	CRU_RESET_OFFSET(SRST_PRESETN_I2C8, 12, 12),
+	CRU_RESET_OFFSET(SRST_PRESETN_I2C9, 12, 13),
+	CRU_RESET_OFFSET(SRST_PRESETN_WDT_BUSMCU, 12, 14),
+	CRU_RESET_OFFSET(SRST_TRESETN_WDT_BUSMCU, 12, 15),
+
+	/* CRU-->SOFTRST_CON13 */
+	CRU_RESET_OFFSET(SRST_ARESETN_GIC, 13, 0),
+	CRU_RESET_OFFSET(SRST_RESETN_I2C1, 13, 5),
+	CRU_RESET_OFFSET(SRST_RESETN_I2C2, 13, 6),
+	CRU_RESET_OFFSET(SRST_RESETN_I2C3, 13, 7),
+	CRU_RESET_OFFSET(SRST_RESETN_I2C4, 13, 8),
+	CRU_RESET_OFFSET(SRST_RESETN_I2C5, 13, 9),
+	CRU_RESET_OFFSET(SRST_RESETN_I2C6, 13, 10),
+	CRU_RESET_OFFSET(SRST_RESETN_I2C7, 13, 11),
+	CRU_RESET_OFFSET(SRST_RESETN_I2C8, 13, 12),
+	CRU_RESET_OFFSET(SRST_RESETN_I2C9, 13, 13),
+	CRU_RESET_OFFSET(SRST_PRESETN_SARADC, 13, 15),
+
+	/* CRU-->SOFTRST_CON14 */
+	CRU_RESET_OFFSET(SRST_RESETN_SARADC, 14, 0),
+	CRU_RESET_OFFSET(SRST_RESETN_SARADC_32K, 14, 1),
+	CRU_RESET_OFFSET(SRST_PRESETN_TSADC, 14, 2),
+	CRU_RESET_OFFSET(SRST_RESETN_TSADC, 14, 3),
+	CRU_RESET_OFFSET(SRST_PRESETN_UART0, 14, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_UART2, 14, 5),
+	CRU_RESET_OFFSET(SRST_PRESETN_UART3, 14, 6),
+	CRU_RESET_OFFSET(SRST_PRESETN_UART4, 14, 7),
+	CRU_RESET_OFFSET(SRST_PRESETN_UART5, 14, 8),
+	CRU_RESET_OFFSET(SRST_PRESETN_UART6, 14, 9),
+	CRU_RESET_OFFSET(SRST_PRESETN_UART7, 14, 10),
+	CRU_RESET_OFFSET(SRST_PRESETN_UART8, 14, 11),
+	CRU_RESET_OFFSET(SRST_PRESETN_UART9, 14, 12),
+	CRU_RESET_OFFSET(SRST_PRESETN_UART10, 14, 13),
+	CRU_RESET_OFFSET(SRST_PRESETN_UART11, 14, 14),
+	CRU_RESET_OFFSET(SRST_SRESETN_UART0, 14, 15),
+
+	/* CRU-->SOFTRST_CON15 */
+	CRU_RESET_OFFSET(SRST_SRESETN_UART2, 15, 0),
+	CRU_RESET_OFFSET(SRST_SRESETN_UART3, 15, 3),
+	CRU_RESET_OFFSET(SRST_SRESETN_UART4, 15, 6),
+	CRU_RESET_OFFSET(SRST_SRESETN_UART5, 15, 9),
+	CRU_RESET_OFFSET(SRST_SRESETN_UART6, 15, 12),
+	CRU_RESET_OFFSET(SRST_SRESETN_UART7, 15, 15),
+
+	/* CRU-->SOFTRST_CON16 */
+	CRU_RESET_OFFSET(SRST_SRESETN_UART8, 16, 2),
+	CRU_RESET_OFFSET(SRST_SRESETN_UART9, 16, 3),
+	CRU_RESET_OFFSET(SRST_SRESETN_UART10, 16, 4),
+	CRU_RESET_OFFSET(SRST_SRESETN_UART11, 16, 5),
+	CRU_RESET_OFFSET(SRST_PRESETN_SPI0, 16, 7),
+	CRU_RESET_OFFSET(SRST_PRESETN_SPI1, 16, 8),
+	CRU_RESET_OFFSET(SRST_PRESETN_SPI2, 16, 9),
+	CRU_RESET_OFFSET(SRST_PRESETN_SPI3, 16, 10),
+	CRU_RESET_OFFSET(SRST_PRESETN_SPI4, 16, 11),
+	CRU_RESET_OFFSET(SRST_RESETN_SPI0, 16, 12),
+	CRU_RESET_OFFSET(SRST_RESETN_SPI1, 16, 13),
+	CRU_RESET_OFFSET(SRST_RESETN_SPI2, 16, 14),
+	CRU_RESET_OFFSET(SRST_RESETN_SPI3, 16, 15),
+
+	/* CRU-->SOFTRST_CON17 */
+	CRU_RESET_OFFSET(SRST_RESETN_SPI4, 17, 0),
+	CRU_RESET_OFFSET(SRST_PRESETN_WDT0, 17, 1),
+	CRU_RESET_OFFSET(SRST_TRESETN_WDT0, 17, 2),
+	CRU_RESET_OFFSET(SRST_PRESETN_SYS_GRF, 17, 3),
+	CRU_RESET_OFFSET(SRST_PRESETN_PWM1, 17, 4),
+	CRU_RESET_OFFSET(SRST_RESETN_PWM1, 17, 5),
+	CRU_RESET_OFFSET(SRST_PRESETN_PWM2, 17, 10),
+	CRU_RESET_OFFSET(SRST_RESETN_PWM2, 17, 11),
+
+	/* CRU-->SOFTRST_CON18 */
+	CRU_RESET_OFFSET(SRST_PRESETN_BUSTIMER0, 18, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_BUSTIMER1, 18, 5),
+	CRU_RESET_OFFSET(SRST_RESETN_TIMER0, 18, 7),
+	CRU_RESET_OFFSET(SRST_RESETN_TIMER1, 18, 8),
+	CRU_RESET_OFFSET(SRST_RESETN_TIMER2, 18, 9),
+	CRU_RESET_OFFSET(SRST_RESETN_TIMER3, 18, 10),
+	CRU_RESET_OFFSET(SRST_RESETN_TIMER4, 18, 11),
+	CRU_RESET_OFFSET(SRST_RESETN_TIMER5, 18, 12),
+	CRU_RESET_OFFSET(SRST_PRESETN_MAILBOX0, 18, 14),
+
+	/* CRU-->SOFTRST_CON19 */
+	CRU_RESET_OFFSET(SRST_PRESETN_GPIO1, 19, 0),
+	CRU_RESET_OFFSET(SRST_DBRESETN_GPIO1, 19, 1),
+	CRU_RESET_OFFSET(SRST_PRESETN_GPIO2, 19, 2),
+	CRU_RESET_OFFSET(SRST_DBRESETN_GPIO2, 19, 3),
+	CRU_RESET_OFFSET(SRST_PRESETN_GPIO3, 19, 4),
+	CRU_RESET_OFFSET(SRST_DBRESETN_GPIO3, 19, 5),
+	CRU_RESET_OFFSET(SRST_PRESETN_GPIO4, 19, 6),
+	CRU_RESET_OFFSET(SRST_DBRESETN_GPIO4, 19, 7),
+	CRU_RESET_OFFSET(SRST_ARESETN_DECOM, 19, 8),
+	CRU_RESET_OFFSET(SRST_PRESETN_DECOM, 19, 9),
+	CRU_RESET_OFFSET(SRST_DRESETN_DECOM, 19, 10),
+	CRU_RESET_OFFSET(SRST_RESETN_TIMER6, 19, 12),
+	CRU_RESET_OFFSET(SRST_RESETN_TIMER7, 19, 13),
+	CRU_RESET_OFFSET(SRST_RESETN_TIMER8, 19, 14),
+	CRU_RESET_OFFSET(SRST_RESETN_TIMER9, 19, 15),
+
+	/* CRU-->SOFTRST_CON20 */
+	CRU_RESET_OFFSET(SRST_RESETN_TIMER10, 20, 0),
+	CRU_RESET_OFFSET(SRST_RESETN_TIMER11, 20, 1),
+	CRU_RESET_OFFSET(SRST_ARESETN_RKDMA0, 20, 2),
+	CRU_RESET_OFFSET(SRST_PRESETN_RKDMA0, 20, 3),
+	CRU_RESET_OFFSET(SRST_ARESETN_RKDMA1, 20, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_RKDMA1, 20, 5),
+	CRU_RESET_OFFSET(SRST_ARESETN_RKDMA2, 20, 6),
+	CRU_RESET_OFFSET(SRST_PRESETN_RKDMA2, 20, 7),
+	CRU_RESET_OFFSET(SRST_ARESETN_RKDMA3, 20, 8),
+	CRU_RESET_OFFSET(SRST_PRESETN_RKDMA3, 20, 9),
+	CRU_RESET_OFFSET(SRST_PRESETN_SPINLOCK, 20, 10),
+	CRU_RESET_OFFSET(SRST_RESETN_REF_PVTPLL_BUS, 20, 11),
+	CRU_RESET_OFFSET(SRST_RESETN_I3C, 20, 12),
+	CRU_RESET_OFFSET(SRST_HRESETN_I3C, 20, 13),
+
+	/* CRU-->SOFTRST_CON21 */
+	CRU_RESET_OFFSET(SRST_RESETN_BUSMCU_BIU, 21, 1),
+	CRU_RESET_OFFSET(SRST_CORERESETN_N320, 21, 2),
+	CRU_RESET_OFFSET(SRST_PORESETN_N320, 21, 3),
+	CRU_RESET_OFFSET(SRST_RESETN_MCU_AXI_INTEGRITY, 21, 6),
+	CRU_RESET_OFFSET(SRST_PRESETN_INTMUX2PMU, 21, 8),
+	CRU_RESET_OFFSET(SRST_PRESETN_INTMUX2DDR, 21, 9),
+	CRU_RESET_OFFSET(SRST_PRESETN_PVTPLL_BUS, 21, 11),
+	CRU_RESET_OFFSET(SRST_RESETN_HDMITXHPD, 21, 14),
+
+	/* CRU-->SOFTRST_CON22 */
+	CRU_RESET_OFFSET(SRST_PRESETN_APB2ASB_HDMITX, 22, 2),
+	CRU_RESET_OFFSET(SRST_SRESETN_APB2ASB_HDMITX, 22, 3),
+	CRU_RESET_OFFSET(SRST_PRESETN_APB2ASB_MIPICSI, 22, 6),
+	CRU_RESET_OFFSET(SRST_SRESETN_APB2ASB_MIPICSI, 22, 7),
+	CRU_RESET_OFFSET(SRST_PRESETN_APB2ASB_VCCIO0_3, 22, 8),
+	CRU_RESET_OFFSET(SRST_SRESETN_APB2ASB_VCCIO0_3, 22, 9),
+	CRU_RESET_OFFSET(SRST_PRESETN_APB2ASB_VCCIO1_2_4, 22, 10),
+	CRU_RESET_OFFSET(SRST_SRESETN_APB2ASB_VCCIO1_2_4, 22, 11),
+	CRU_RESET_OFFSET(SRST_PRESETN_APB2ASB_VCCIO5_6, 22, 12),
+	CRU_RESET_OFFSET(SRST_SRESETN_APB2ASB_VCCIO5_6, 22, 13),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_BUS, 22, 14),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_BUS, 22, 15),
+
+	/* CRU-->SOFTRST_CON23 */
+	CRU_RESET_OFFSET(SRST_PRESETN_DDR_MON, 23, 1),
+	CRU_RESET_OFFSET(SRST_PRESETN_DDR_BIU, 23, 2),
+	CRU_RESET_OFFSET(SRST_PRESETN_DDR_UPCTL, 23, 3),
+	CRU_RESET_OFFSET(SRST_TMRESETN_DDR_MON, 23, 4),
+	CRU_RESET_OFFSET(SRST_ARESETN_DDR_BIU, 23, 5),
+	CRU_RESET_OFFSET(SRST_PRESETN_DDR_BIU_FW, 23, 6),
+	CRU_RESET_OFFSET(SRST_RESETN_DDR_MON, 23, 10),
+	CRU_RESET_OFFSET(SRST_PRESETN_DDR_HWLP, 23, 13),
+
+	/* CRU-->SOFTRST_CON24 */
+	CRU_RESET_OFFSET(SRST_ARESETN_DDR_MSCH_BIU, 24, 3),
+	CRU_RESET_OFFSET(SRST_ARESETN_DDR_MSCH_FW, 24, 4),
+	CRU_RESET_OFFSET(SRST_RESETN_DDR_SCRAMBLE, 24, 9),
+	CRU_RESET_OFFSET(SRST_LRESETN_DDRSCH_BIU, 24, 11),
+
+	/* CRU-->SOFTRST_CON25 */
+	CRU_RESET_OFFSET(SRST_RESETN_DDR_TIMER0, 25, 4),
+	CRU_RESET_OFFSET(SRST_RESETN_DDR_TIMER1, 25, 5),
+	CRU_RESET_OFFSET(SRST_TRESETN_DDR_WDT, 25, 6),
+	CRU_RESET_OFFSET(SRST_PRESETN_WDT, 25, 7),
+	CRU_RESET_OFFSET(SRST_PRESETN_TIMER, 25, 8),
+	CRU_RESET_OFFSET(SRST_PRESETN_DDR_GRF, 25, 11),
+
+	/* CRU-->SOFTRST_CON26 */
+	CRU_RESET_OFFSET(SRST_RESETN_DDR_UPCTL, 26, 1),
+	CRU_RESET_OFFSET(SRST_ARESETN_DDR_UPCTL_0, 26, 2),
+	CRU_RESET_OFFSET(SRST_ARESETN_DDR_UPCTL_1, 26, 3),
+	CRU_RESET_OFFSET(SRST_ARESETN_DDR_UPCTL_2, 26, 4),
+	CRU_RESET_OFFSET(SRST_ARESETN_DDR_UPCTL_3, 26, 5),
+	CRU_RESET_OFFSET(SRST_ARESETN_DDR_UPCTL_4, 26, 6),
+	CRU_RESET_OFFSET(SRST_ARESETN_DDR_UPCTL_5, 26, 7),
+
+	/* CRU-->SOFTRST_CON27 */
+	CRU_RESET_OFFSET(SRST_RESETN_DDRMCU_BIU, 27, 0),
+	CRU_RESET_OFFSET(SRST_CORERESETN_N320_DDR, 27, 1),
+	CRU_RESET_OFFSET(SRST_PORESETN_N320_DDR, 27, 2),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_DDR, 27, 6),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_DDR, 27, 7),
+
+	/* CRU-->SOFTRST_CON31 */
+	CRU_RESET_OFFSET(SRST_ARESETN_RKNN, 31, 2),
+	CRU_RESET_OFFSET(SRST_ARESETN_RKNN_RV, 31, 3),
+	CRU_RESET_OFFSET(SRST_ARESETN_RKNN_BIU, 31, 4),
+	CRU_RESET_OFFSET(SRST_ARESETN_RKNN_FW, 31, 5),
+	CRU_RESET_OFFSET(SRST_PRESETN_RKNN_BIU, 31, 7),
+	CRU_RESET_OFFSET(SRST_PRESETN_PVTPLL_NPU, 31, 8),
+	CRU_RESET_OFFSET(SRST_RESETN_NPU_PVTPLL, 31, 9),
+	CRU_RESET_OFFSET(SRST_RESETN_24M_RKNN, 31, 11),
+	CRU_RESET_OFFSET(SRST_RESETN_NPUTIMER0, 31, 13),
+	CRU_RESET_OFFSET(SRST_RESETN_NPUTIMER1, 31, 14),
+	CRU_RESET_OFFSET(SRST_PRESETN_NPU_TIMER, 31, 15),
+
+	/* CRU-->SOFTRST_CON32 */
+	CRU_RESET_OFFSET(SRST_PRESETN_NPU_WDT, 32, 0),
+	CRU_RESET_OFFSET(SRST_TRESETN_NPU_WDT, 32, 1),
+	CRU_RESET_OFFSET(SRST_PRESETN_RKNN_GRF, 32, 2),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_NPU, 32, 3),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_NPU, 32, 4),
+
+	/* CRU-->SOFTRST_CON33 */
+	CRU_RESET_OFFSET(SRST_PRESETN_PHP0_GRF, 33, 1),
+	CRU_RESET_OFFSET(SRST_PRESETN_PHP0_BIU, 33, 2),
+	CRU_RESET_OFFSET(SRST_ARESETN_PHP0_BIU, 33, 5),
+	CRU_RESET_OFFSET(SRST_ARESETN_PHP0_FW, 33, 6),
+	CRU_RESET_OFFSET(SRST_PRESETN_PCIE1, 33, 7),
+	CRU_RESET_OFFSET(SRST_RESETN_PCIE1_POWER_UP, 33, 9),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_PHP0, 33, 14),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_PHP0, 33, 15),
+
+	/* CRU-->SOFTRST_CON34 */
+	CRU_RESET_OFFSET(SRST_PRESETN_PCIE0, 34, 3),
+	CRU_RESET_OFFSET(SRST_RESETN_PCIE0_POWER_UP, 34, 5),
+	CRU_RESET_OFFSET(SRST_ARESETN_USB3OTG1, 34, 9),
+	CRU_RESET_OFFSET(SRST_ARESETN_GMAC0, 34, 12),
+	CRU_RESET_OFFSET(SRST_ARESETN_USB3OTG0, 34, 15),
+
+	/* CRU-->SOFTRST_CON35 */
+	CRU_RESET_OFFSET(SRST_ARESETN_UFS_BIU, 35, 2),
+	CRU_RESET_OFFSET(SRST_ARESETN_UFS_SYS, 35, 3),
+	CRU_RESET_OFFSET(SRST_ARESETN_UFS, 35, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_UFS_GRF, 35, 6),
+
+	/* CRU-->SOFTRST_CON37 */
+	CRU_RESET_OFFSET(SRST_RESETN_RXOOB0, 37, 0),
+	CRU_RESET_OFFSET(SRST_RESETN_PMALIVE0, 37, 1),
+	CRU_RESET_OFFSET(SRST_ARESETN_SATA0, 37, 2),
+	CRU_RESET_OFFSET(SRST_RESETN_RXOOB1, 37, 3),
+	CRU_RESET_OFFSET(SRST_RESETN_PMALIVE1, 37, 4),
+	CRU_RESET_OFFSET(SRST_ARESETN_SATA1, 37, 5),
+	CRU_RESET_OFFSET(SRST_RESETN_XPCS_PWR_ON, 37, 6),
+	CRU_RESET_OFFSET(SRST_RESETN_ASIC0, 37, 8),
+	CRU_RESET_OFFSET(SRST_RESETN_ASIC1, 37, 9),
+
+	/* CRU-->SOFTRST_CON42 */
+	CRU_RESET_OFFSET(SRST_PRESETN_NVM0_GRF, 42, 3),
+	CRU_RESET_OFFSET(SRST_PRESETN_NVM0_BIU, 42, 4),
+	CRU_RESET_OFFSET(SRST_ARESETN_NVM0_BIU, 42, 5),
+	CRU_RESET_OFFSET(SRST_HRESETN_NVM0_BIU, 42, 6),
+	CRU_RESET_OFFSET(SRST_CRESETN_EMMC, 42, 7),
+	CRU_RESET_OFFSET(SRST_HRESETN_EMMC, 42, 8),
+	CRU_RESET_OFFSET(SRST_ARESETN_EMMC, 42, 9),
+	CRU_RESET_OFFSET(SRST_BRESETN_EMMC, 42, 10),
+	CRU_RESET_OFFSET(SRST_TRESETN_EMMC, 42, 11),
+	CRU_RESET_OFFSET(SRST_ARESETN_GMAC1, 42, 14),
+
+	/* CRU-->SOFTRST_CON43 */
+	CRU_RESET_OFFSET(SRST_SRESETN_FSPI0, 43, 0),
+	CRU_RESET_OFFSET(SRST_HRESETN_FSPI0, 43, 1),
+	CRU_RESET_OFFSET(SRST_HRESETN_SDMMC1, 43, 3),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_NVM0, 43, 5),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_NVM0, 43, 6),
+
+	/* CRU-->SOFTRST_CON44 */
+	CRU_RESET_OFFSET(SRST_ARESETN_DSMC_BIU, 44, 1),
+	CRU_RESET_OFFSET(SRST_ARESETN_DSMC, 44, 2),
+	CRU_RESET_OFFSET(SRST_HRESETN_DSMC_BIU, 44, 4),
+	CRU_RESET_OFFSET(SRST_HRESETN_DSMC, 44, 5),
+	CRU_RESET_OFFSET(SRST_PRESETN_DSMC_BIU, 44, 7),
+	CRU_RESET_OFFSET(SRST_PRESETN_DSMC, 44, 8),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_DSMC, 44, 10),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_DSMC, 44, 11),
+	CRU_RESET_OFFSET(SRST_PRESETN_DSMC_GRF, 44, 13),
+
+	/* CRU-->SOFTRST_CON45 */
+	CRU_RESET_OFFSET(SRST_PRESETN_NVM1_GRF, 45, 3),
+	CRU_RESET_OFFSET(SRST_PRESETN_NVM1_BIU, 45, 4),
+	CRU_RESET_OFFSET(SRST_HRESETN_NVM1_BIU, 45, 6),
+	CRU_RESET_OFFSET(SRST_HRESETN_SDMMC0, 45, 8),
+	CRU_RESET_OFFSET(SRST_SRESETN_FSPI1, 45, 11),
+	CRU_RESET_OFFSET(SRST_HRESETN_FSPI1, 45, 12),
+
+	/* CRU-->SOFTRST_CON46 */
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_NVM1, 46, 4),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_NVM1, 46, 5),
+
+	/* CRU-->SOFTRST_CON50 */
+	CRU_RESET_OFFSET(SRST_HRESETN_RKVDEC, 50, 3),
+	CRU_RESET_OFFSET(SRST_HRESETN_RKVDEC_BIU, 50, 5),
+	CRU_RESET_OFFSET(SRST_ARESETN_RKVDEC_BIU, 50, 6),
+	CRU_RESET_OFFSET(SRST_RESETN_RKVDEC_HEVC_CA, 50, 8),
+	CRU_RESET_OFFSET(SRST_RESETN_RKVDEC_CORE, 50, 9),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_VDEC, 50, 10),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_VDEC, 50, 11),
+	CRU_RESET_OFFSET(SRST_PRESETN_VDEC_BIU, 50, 14),
+	CRU_RESET_OFFSET(SRST_PRESETN_VDEC_GRF, 50, 15),
+
+	/* CRU-->SOFTRST_CON52 */
+	CRU_RESET_OFFSET(SRST_PRESETN_APB2ASB_MIPI_HDMI_SUBVO, 52, 1),
+	CRU_RESET_OFFSET(SRST_SRESETN_APB2ASB_MIPI_HDMI_SUBVO, 52, 2),
+	CRU_RESET_OFFSET(SRST_PRESETN_APB2ASB_VCCIO0_3_SUBVO, 52, 7),
+	CRU_RESET_OFFSET(SRST_SRESETN_APB2ASB_VCCIO0_3_SUBVO, 52, 8),
+	CRU_RESET_OFFSET(SRST_PRESETN_HDPTXPHY, 52, 9),
+	CRU_RESET_OFFSET(SRST_PRESETN_HDPTXPHY_GRF, 52, 10),
+	CRU_RESET_OFFSET(SRST_PRESETN_MIPI_DPHY0, 52, 11),
+
+	/* CRU-->SOFTRST_CON53 */
+	CRU_RESET_OFFSET(SRST_RESETN_HDPTX_INIT, 53, 0),
+	CRU_RESET_OFFSET(SRST_RESETN_HDPTX_CMN, 53, 1),
+	CRU_RESET_OFFSET(SRST_RESETN_HDPTX_LANE, 53, 2),
+	CRU_RESET_OFFSET(SRST_PRESETN_IOC_SUBVO, 53, 3),
+	CRU_RESET_OFFSET(SRST_RESETN_GMAC1_SUBVO_ASYNC, 53, 4),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_SUBSYSVO, 53, 5),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_SUBSYSVO, 53, 6),
+
+	/* CRU-->SOFTRST_CON54 */
+	CRU_RESET_OFFSET(SRST_PRESETN_APB2ASB_VCCIO1_2_4_SUBVI, 54, 1),
+	CRU_RESET_OFFSET(SRST_SRESETN_APB2ASB_VCCIO1_2_4_SUBVI, 54, 2),
+	CRU_RESET_OFFSET(SRST_PRESETN_APB2ASB_CSIPHY_SUBVI, 54, 3),
+	CRU_RESET_OFFSET(SRST_SRESETN_APB2ASB_CSIPHY_SUBVI, 54, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_CSIPHY0, 54, 5),
+	CRU_RESET_OFFSET(SRST_PRESETN_CSIPHY0_GRF, 54, 6),
+	CRU_RESET_OFFSET(SRST_PRESETN_CSIPHY1, 54, 7),
+	CRU_RESET_OFFSET(SRST_PRESETN_CSIPHY1_GRF, 54, 8),
+	CRU_RESET_OFFSET(SRST_PRESETN_IOC_SUBVI, 54, 9),
+	CRU_RESET_OFFSET(SRST_RESETN_GMAC0_SUBVI_ASYNC, 54, 10),
+	CRU_RESET_OFFSET(SRST_SCAN_RESETN_CSIPHY0, 54, 11),
+	CRU_RESET_OFFSET(SRST_SCAN_RESETN_CSIPHY1, 54, 12),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_SUBSYSVI, 54, 14),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_SUBSYSVI, 54, 15),
+
+	/* CRU-->SOFTRST_CON56 */
+	CRU_RESET_OFFSET(SRST_PRESETN_APB2ASB_VCCIO5_6_SUBDSMC, 56, 3),
+	CRU_RESET_OFFSET(SRST_SRESETN_APB2ASB_VCCIO5_6_SUBDSMC, 56, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_VCCIO5_6, 56, 5),
+	CRU_RESET_OFFSET(SRST_RESETN_GMAC1_ASYNC, 56, 6),
+
+	/* CRU-->SOFTRST_CON57 */
+	CRU_RESET_OFFSET(SRST_PRESETN_IMG_BIU, 57, 7),
+	CRU_RESET_OFFSET(SRST_PRESETN_IMG_GRF, 57, 8),
+	CRU_RESET_OFFSET(SRST_HRESETN_IMG_BIU, 57, 9),
+	CRU_RESET_OFFSET(SRST_ARESETN_JPEG_BIU, 57, 10),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_IMG, 57, 11),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_IMG, 57, 12),
+	CRU_RESET_OFFSET(SRST_ARESETN_RGA_BIU, 57, 13),
+	CRU_RESET_OFFSET(SRST_ARESETN_VDPP_BIU, 57, 14),
+	CRU_RESET_OFFSET(SRST_ARESETN_EBC_BIU, 57, 15),
+
+	/* CRU-->SOFTRST_CON58 */
+	CRU_RESET_OFFSET(SRST_HRESETN_RGA2E_0, 58, 0),
+	CRU_RESET_OFFSET(SRST_ARESETN_RGA2E_0, 58, 1),
+	CRU_RESET_OFFSET(SRST_RESETN_CORE_RGA2E_0, 58, 2),
+	CRU_RESET_OFFSET(SRST_ARESETN_JPEG, 58, 3),
+	CRU_RESET_OFFSET(SRST_HRESETN_JPEG, 58, 4),
+	CRU_RESET_OFFSET(SRST_HRESETN_VDPP, 58, 5),
+	CRU_RESET_OFFSET(SRST_ARESETN_VDPP, 58, 6),
+	CRU_RESET_OFFSET(SRST_RESETN_CORE_VDPP, 58, 7),
+	CRU_RESET_OFFSET(SRST_HRESETN_EBC, 58, 13),
+	CRU_RESET_OFFSET(SRST_ARESETN_EBC, 58, 14),
+	CRU_RESET_OFFSET(SRST_DRESETN_EBC, 58, 15),
+
+	/* CRU-->SOFTRST_CON60 */
+	CRU_RESET_OFFSET(SRST_HRESETN_RKVENC_BIU, 60, 2),
+	CRU_RESET_OFFSET(SRST_ARESETN_RKVENC_BIU, 60, 3),
+	CRU_RESET_OFFSET(SRST_HRESETN_RKVENC, 60, 4),
+	CRU_RESET_OFFSET(SRST_ARESETN_RKVENC, 60, 5),
+	CRU_RESET_OFFSET(SRST_RESETN_RKVENC_CORE, 60, 6),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_VENC, 60, 7),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_VENC, 60, 8),
+
+	/* CRU-->SOFTRST_CON63 */
+	CRU_RESET_OFFSET(SRST_ARESETN_VI_BIU, 63, 3),
+	CRU_RESET_OFFSET(SRST_HRESETN_VI_BIU, 63, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_VI_BIU, 63, 5),
+	CRU_RESET_OFFSET(SRST_DRESETN_VICAP, 63, 6),
+	CRU_RESET_OFFSET(SRST_ARESETN_VICAP, 63, 7),
+	CRU_RESET_OFFSET(SRST_HRESETN_VICAP, 63, 8),
+	CRU_RESET_OFFSET(SRST_RESETN_ISP, 63, 10),
+	CRU_RESET_OFFSET(SRST_RESETN_ISP_VICAP, 63, 11),
+
+	/* CRU-->SOFTRST_CON64 */
+	CRU_RESET_OFFSET(SRST_RESETN_CORE_VPSS, 64, 1),
+	CRU_RESET_OFFSET(SRST_PRESETN_VI_GRF, 64, 2),
+	CRU_RESET_OFFSET(SRST_PRESETN_CSI_HOST_0, 64, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_CSI_HOST_1, 64, 5),
+	CRU_RESET_OFFSET(SRST_PRESETN_CSI_HOST_2, 64, 6),
+	CRU_RESET_OFFSET(SRST_PRESETN_CSI_HOST_3, 64, 7),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_VI, 64, 14),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_VI, 64, 15),
+
+	/* CRU-->SOFTRST_CON72 */
+	CRU_RESET_OFFSET(SRST_RESETN_CIFIN, 72, 0),
+
+	/* CRU-->SOFTRST_CON74 */
+	CRU_RESET_OFFSET(SRST_ARESETN_VOP_BIU, 74, 4),
+	CRU_RESET_OFFSET(SRST_ARESETN_VOP_FW, 74, 5),
+	CRU_RESET_OFFSET(SRST_HRESETN_VOP_BIU, 74, 6),
+	CRU_RESET_OFFSET(SRST_PRESETN_VOP_BIU, 74, 7),
+	CRU_RESET_OFFSET(SRST_HRESETN_VOP, 74, 8),
+	CRU_RESET_OFFSET(SRST_ARESETN_VOP, 74, 9),
+	CRU_RESET_OFFSET(SRST_DRESETN_VP0, 74, 13),
+
+	/* CRU-->SOFTRST_CON75 */
+	CRU_RESET_OFFSET(SRST_DRESETN_VP1, 75, 0),
+	CRU_RESET_OFFSET(SRST_PRESETN_VOPGRF, 75, 3),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_VOP, 75, 4),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_VOP, 75, 5),
+
+	/* CRU-->SOFTRST_CON78 */
+	CRU_RESET_OFFSET(SRST_PRESETN_DSIHOST0, 78, 1),
+	CRU_RESET_OFFSET(SRST_HRESETN_VO_BIU, 78, 10),
+	CRU_RESET_OFFSET(SRST_PRESETN_VO_BIU, 78, 12),
+	CRU_RESET_OFFSET(SRST_ARESETN_HDCP0_BIU, 78, 14),
+	CRU_RESET_OFFSET(SRST_PRESETN_VO_GRF, 78, 15),
+
+	/* CRU-->SOFTRST_CON79 */
+	CRU_RESET_OFFSET(SRST_PRESETN_HDCP0_TRNG_NS, 79, 0),
+	CRU_RESET_OFFSET(SRST_ARESETN_HDCP0, 79, 1),
+	CRU_RESET_OFFSET(SRST_HRESETN_HDCP0, 79, 2),
+	CRU_RESET_OFFSET(SRST_RESETN_HDCP0, 79, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_HDMITX0, 79, 14),
+	CRU_RESET_OFFSET(SRST_RESETN_HDMITX0_EARC, 79, 15),
+
+	/* CRU-->SOFTRST_CON80 */
+	CRU_RESET_OFFSET(SRST_RESETN_HDMITX0_REF, 80, 0),
+	CRU_RESET_OFFSET(SRST_PRESETN_EDP0, 80, 2),
+	CRU_RESET_OFFSET(SRST_RESETN_EDP0_24M, 80, 3),
+	CRU_RESET_OFFSET(SRST_MRESETN_SAI4, 80, 6),
+	CRU_RESET_OFFSET(SRST_HRESETN_SAI4, 80, 7),
+	CRU_RESET_OFFSET(SRST_MRESETN_SAI5, 80, 9),
+	CRU_RESET_OFFSET(SRST_HRESETN_SAI5, 80, 10),
+	CRU_RESET_OFFSET(SRST_HRESETN_SPDIF_TX2, 80, 11),
+	CRU_RESET_OFFSET(SRST_MRESETN_SPDIF_TX2, 80, 13),
+	CRU_RESET_OFFSET(SRST_HRESETN_SPDIF_RX1, 80, 14),
+	CRU_RESET_OFFSET(SRST_MRESETN_SPDIF_RX1, 80, 15),
+
+	/* CRU-->SOFTRST_CON81 */
+	CRU_RESET_OFFSET(SRST_RESETN_EBC_VOP_DCLK_VO, 81, 2),
+
+	/* CRU-->SOFTRST_CON82 */
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_VO, 82, 9),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_VO, 82, 10),
+
+	/* CRU-->SOFTRST_CON84 */
+	CRU_RESET_OFFSET(SRST_RESETN_GPU, 84, 3),
+	CRU_RESET_OFFSET(SRST_SYSRESETN_GPU, 84, 4),
+	CRU_RESET_OFFSET(SRST_PRESETN_GPU_BIU, 84, 8),
+	CRU_RESET_OFFSET(SRST_PORESETN_GPU_JTAG, 84, 10),
+	CRU_RESET_OFFSET(SRST_PRESETN_GPU_GRF, 84, 12),
+	CRU_RESET_OFFSET(SRST_RESETN_GPU_PVTPLL, 84, 13),
+	CRU_RESET_OFFSET(SRST_PRESETN_PVTPLL_GPU, 84, 14),
+	CRU_RESET_OFFSET(SRST_ARESETN_SLV_GPU_BIU, 84, 15),
+
+	/* CRU-->SOFTRST_CON85 */
+	CRU_RESET_OFFSET(SRST_ARESETN_GPU_BIU, 85, 0),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_GPU, 85, 1),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_GPU, 85, 2),
+
+	/* CRU-->SOFTRST_CON86 */
+	CRU_RESET_OFFSET(SRST_ARESETN_CENTER_BIU, 86, 4),
+	CRU_RESET_OFFSET(SRST_ARESETN_CENTER_FW_DDR, 86, 5),
+	CRU_RESET_OFFSET(SRST_ARESETN_CENTER_FW_GPU, 86, 7),
+	CRU_RESET_OFFSET(SRST_ARESETN_DMA2DDR, 86, 8),
+	CRU_RESET_OFFSET(SRST_ARESETN_DDR_SHAREMEM, 86, 9),
+	CRU_RESET_OFFSET(SRST_ARESETN_DDR_SHAREMEM_BIU, 86, 10),
+	CRU_RESET_OFFSET(SRST_ARESETN_DDR_SHAREMEM_FW, 86, 11),
+	CRU_RESET_OFFSET(SRST_HRESETN_CENTER_BIU, 86, 12),
+	CRU_RESET_OFFSET(SRST_HRESETN_CENTER_FW, 86, 13),
+	CRU_RESET_OFFSET(SRST_PRESETN_CENTER_GRF, 86, 14),
+	CRU_RESET_OFFSET(SRST_PRESETN_DMA2DDR, 86, 15),
+
+	/* CRU-->SOFTRST_CON87 */
+	CRU_RESET_OFFSET(SRST_PRESETN_CENTER_BIU, 87, 1),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_CENTER, 87, 2),
+	CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_CENTER, 87, 3),
+	CRU_RESET_OFFSET(SRST_RESETN_LINKSYM_HDMITXPHY0, 87, 9),
+
+	/* PHPPHY_CRU-->SOFTRST_CON00 */
+	PHPPHY_CRU_RESET_OFFSET(SRST_PRESETN_PHPPHY_CRU, 0, 1),
+	PHPPHY_CRU_RESET_OFFSET(SRST_PRESETN_PCIE2_COMBOPHY0, 0, 4),
+	PHPPHY_CRU_RESET_OFFSET(SRST_PRESETN_PCIE2_COMBOPHY0_GRF, 0, 5),
+	PHPPHY_CRU_RESET_OFFSET(SRST_PRESETN_PCIE2_COMBOPHY1, 0, 6),
+	PHPPHY_CRU_RESET_OFFSET(SRST_PRESETN_PCIE2_COMBOPHY1_GRF, 0, 7),
+	PHPPHY_CRU_RESET_OFFSET(SRST_PRESETN_USBPHY_GRF_0, 0, 8),
+	PHPPHY_CRU_RESET_OFFSET(SRST_PRESETN_USBPHY_GRF_1, 0, 9),
+	PHPPHY_CRU_RESET_OFFSET(SRST_RESETN_MPHY_INIT, 0, 10),
+	PHPPHY_CRU_RESET_OFFSET(SRST_PRESETN_MPHY_GRF, 0, 11),
+	PHPPHY_CRU_RESET_OFFSET(SRST_PRESETN_VCCIO7_IOC, 0, 12),
+	PHPPHY_CRU_RESET_OFFSET(SRST_RESETN_USB2DEBUG, 0, 13),
+	PHPPHY_CRU_RESET_OFFSET(SRST_PRESETN_PCIEPHY2, 0, 14),
+	PHPPHY_CRU_RESET_OFFSET(SRST_PRESETN_PCIEPHY2_GRF, 0, 15),
+
+	/* PHPPHY_CRU-->SOFTRST_CON01 */
+	PHPPHY_CRU_RESET_OFFSET(SRST_SRESETN_APB2ASB_USBMPHY_PHPPHY, 1, 0),
+	PHPPHY_CRU_RESET_OFFSET(SRST_PRESETN_APB2ASB_USBMPHY_PHPPHY, 1, 1),
+	PHPPHY_CRU_RESET_OFFSET(SRST_RESETN_OTGPHY_0, 1, 4),
+	PHPPHY_CRU_RESET_OFFSET(SRST_RESETN_OTGPHY_1, 1, 5),
+	PHPPHY_CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_PHPPHY, 1, 6),
+	PHPPHY_CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_PHPPHY, 1, 7),
+
+	/* PHPPHY_CRU-->SOFTRST_CON02 */
+	PHPPHY_CRU_RESET_OFFSET(SRST_RESETN_PCIEPHY2, 2, 4),
+	PHPPHY_CRU_RESET_OFFSET(SRST_RESETN_PCIE0_PIPE_PHY, 2, 5),
+	PHPPHY_CRU_RESET_OFFSET(SRST_RESETN_PCIE1_PIPE_PHY, 2, 8),
+
+	/* SECURE_CRU-->SOFTRST_CON00 */
+	SECURE_CRU_RESET_OFFSET(SRST_HRESETN_CRYPTO_NS, 0, 3),
+	SECURE_CRU_RESET_OFFSET(SRST_HRESETN_TRNG_NS, 0, 4),
+	SECURE_CRU_RESET_OFFSET(SRST_PRESETN_SECURE_NS_BIU, 0, 5),
+	SECURE_CRU_RESET_OFFSET(SRST_ARESETN_SECURE_HIGH_BIU, 0, 6),
+	SECURE_CRU_RESET_OFFSET(SRST_HRESETN_SECURE_NS_BIU, 0, 7),
+	SECURE_CRU_RESET_OFFSET(SRST_PRESETN_OTPC_NS, 0, 8),
+	SECURE_CRU_RESET_OFFSET(SRST_RESETN_OTPC_NS, 0, 9),
+
+	/* PMU1_CRU-->SOFTRST_CON03 */
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_APB2ASB_PMU1, 3, 6),
+	PMU1_CRU_RESET_OFFSET(SRST_SRESETN_APB2ASB_PMU1, 3, 7),
+	PMU1_CRU_RESET_OFFSET(SRST_HRESETN_PMU1_BIU, 3, 9),
+	PMU1_CRU_RESET_OFFSET(SRST_HRESETN_PMU1_FW, 3, 10),
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_PMU1_BIU, 3, 11),
+	PMU1_CRU_RESET_OFFSET(SRST_HRESETN_PMU_CM0_BIU, 3, 12),
+	PMU1_CRU_RESET_OFFSET(SRST_CORERESETN_N100, 3, 13),
+	PMU1_CRU_RESET_OFFSET(SRST_PORESETN_N100, 3, 14),
+
+	/* PMU1_CRU-->SOFTRST_CON04 */
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_CRU_PMU1, 4, 2),
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_PMU1_GRF, 4, 4),
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_PMU1_IOC, 4, 5),
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_PMU1WDT, 4, 6),
+	PMU1_CRU_RESET_OFFSET(SRST_TRESETN_PMU1WDT, 4, 7),
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_PMUTIMER, 4, 8),
+	PMU1_CRU_RESET_OFFSET(SRST_RESETN_PMUTIMER0, 4, 10),
+	PMU1_CRU_RESET_OFFSET(SRST_RESETN_PMUTIMER1, 4, 11),
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_PWM0, 4, 12),
+	PMU1_CRU_RESET_OFFSET(SRST_RESETN_PWM0, 4, 13),
+
+	/* PMU1_CRU-->SOFTRST_CON05 */
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_I2C0, 5, 2),
+	PMU1_CRU_RESET_OFFSET(SRST_RESETN_I2C0, 5, 3),
+	PMU1_CRU_RESET_OFFSET(SRST_SRESETN_UART1, 5, 6),
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_UART1, 5, 7),
+	PMU1_CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_PMU1, 5, 12),
+	PMU1_CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_PMU1, 5, 13),
+	PMU1_CRU_RESET_OFFSET(SRST_RESETN_PDM0, 5, 14),
+
+	/* PMU1_CRU-->SOFTRST_CON06 */
+	PMU1_CRU_RESET_OFFSET(SRST_HRESETN_PDM0, 6, 0),
+	PMU1_CRU_RESET_OFFSET(SRST_MRESETN_PDM0, 6, 1),
+	PMU1_CRU_RESET_OFFSET(SRST_HRESETN_VAD, 6, 2),
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_RCOSC, 6, 10),
+	PMU1_CRU_RESET_OFFSET(SRST_RESETN_RCOSC, 6, 11),
+
+	/* PMU1_CRU-->SOFTRST_CON07 */
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_PMU0GRF, 7, 4),
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_PMU0IOC, 7, 5),
+	PMU1_CRU_RESET_OFFSET(SRST_PRESETN_GPIO0, 7, 6),
+	PMU1_CRU_RESET_OFFSET(SRST_DBRESETN_GPIO0, 7, 7),
+
+	/* DDR0_CRU-->SOFTRST_CON00 */
+	DDR0_CRU_RESET_OFFSET(SRST_RESETN_DDRPHY1X, 0, 1),
+
+	/* DDR0_CRU-->SOFTRST_CON01 */
+	DDR0_CRU_RESET_OFFSET(SRST_PRESETN_DDRPHY_CRU, 1, 3),
+	DDR0_CRU_RESET_OFFSET(SRST_PRESETN_DDRPHY, 1, 4),
+
+	/* BIGCORE_CRU-->SOFTRST_CON00 */
+	BIGCORE_CRU_RESET_OFFSET(SRST_RESETN_REF_PVTPLL_BIGCORE, 0, 4),
+	BIGCORE_CRU_RESET_OFFSET(SRST_PRESETN_BIGCORE_BIU, 0, 6),
+	BIGCORE_CRU_RESET_OFFSET(SRST_PRESETN_BIGCORE_GRF, 0, 7),
+	BIGCORE_CRU_RESET_OFFSET(SRST_PRESETN_BIGCORE_CRU, 0, 8),
+	BIGCORE_CRU_RESET_OFFSET(SRST_PRESETN_PVTPLL_BIGCORE, 0, 9),
+	BIGCORE_CRU_RESET_OFFSET(SRST_NBIGCOREPORESET0, 0, 12),
+	BIGCORE_CRU_RESET_OFFSET(SRST_NBIGCOREPORESET1, 0, 13),
+	BIGCORE_CRU_RESET_OFFSET(SRST_NBIGCORESET0, 0, 14),
+	BIGCORE_CRU_RESET_OFFSET(SRST_NBIGCORESET1, 0, 15),
+
+	/* BIGCORE_CRU-->SOFTRST_CON01 */
+	BIGCORE_CRU_RESET_OFFSET(SRST_NL2RESET_BIGCORE, 1, 0),
+	BIGCORE_CRU_RESET_OFFSET(SRST_ARESETN_ADB400_A73_ACE, 1, 4),
+	BIGCORE_CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_BIGCORE, 1, 5),
+	BIGCORE_CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_BIGCORE, 1, 6),
+	BIGCORE_CRU_RESET_OFFSET(SRST_PRESETN_DBG_BIGCORE, 1, 7),
+
+	/* LITCORE0_CRU-->SOFTRST_CON00 */
+	LITCORE0_CRU_RESET_OFFSET(SRST_RESETN_REF_LITCORE0_PVTPLL, 0, 0),
+	LITCORE0_CRU_RESET_OFFSET(SRST_NLITCOREPORESET0, 0, 4),
+	LITCORE0_CRU_RESET_OFFSET(SRST_NLITCOREPORESET1, 0, 5),
+	LITCORE0_CRU_RESET_OFFSET(SRST_NLITCOREPORESET2, 0, 6),
+	LITCORE0_CRU_RESET_OFFSET(SRST_NLITCOREPORESET3, 0, 7),
+	LITCORE0_CRU_RESET_OFFSET(SRST_NLITCORESET0, 0, 8),
+	LITCORE0_CRU_RESET_OFFSET(SRST_NLITCORESET1, 0, 9),
+	LITCORE0_CRU_RESET_OFFSET(SRST_NLITCORESET2, 0, 10),
+	LITCORE0_CRU_RESET_OFFSET(SRST_NLITCORESET3, 0, 11),
+	LITCORE0_CRU_RESET_OFFSET(SRST_NL2RESET_LITCORE0, 0, 12),
+	LITCORE0_CRU_RESET_OFFSET(SRST_PRESETN_DBG_LITCORE0, 0, 14),
+	LITCORE0_CRU_RESET_OFFSET(SRST_ARESETN_ADB400_A53_ACE_LITCORE0, 0, 15),
+
+	/* LITCORE0_CRU-->SOFTRST_CON01 */
+	LITCORE0_CRU_RESET_OFFSET(SRST_PRESETN_LITCORE0_GRF, 1, 2),
+	LITCORE0_CRU_RESET_OFFSET(SRST_PRESETN_LITCORE0_BIU, 1, 3),
+	LITCORE0_CRU_RESET_OFFSET(SRST_PRESETN_PVTPLL_LITCORE0, 1, 4),
+	LITCORE0_CRU_RESET_OFFSET(SRST_PRESETN_LITCORE0_CRU, 1, 5),
+	LITCORE0_CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_LITCORE0, 1, 6),
+	LITCORE0_CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_LITCORE0, 1, 7),
+
+	/* LITCORE1_CRU-->SOFTRST_CON00 */
+	LITCORE1_CRU_RESET_OFFSET(SRST_RESETN_REF_LITCORE1_PVTPLL, 0, 0),
+	LITCORE1_CRU_RESET_OFFSET(SRST_NLITCOREPORESET4, 0, 4),
+	LITCORE1_CRU_RESET_OFFSET(SRST_NLITCOREPORESET5, 0, 5),
+	LITCORE1_CRU_RESET_OFFSET(SRST_NLITCORESET4, 0, 6),
+	LITCORE1_CRU_RESET_OFFSET(SRST_NLITCORESET5, 0, 7),
+	LITCORE1_CRU_RESET_OFFSET(SRST_NL2RESET_LITCORE1, 0, 8),
+	LITCORE1_CRU_RESET_OFFSET(SRST_PRESETN_DBG_LITCORE1, 0, 10),
+	LITCORE1_CRU_RESET_OFFSET(SRST_ARESETN_ADB400_A53_ACE_LITCORE1, 0, 11),
+	LITCORE1_CRU_RESET_OFFSET(SRST_PRESETN_LITCORE1_GRF, 0, 14),
+	LITCORE1_CRU_RESET_OFFSET(SRST_PRESETN_LITCORE1_BIU, 0, 15),
+
+	/* LITCORE1_CRU-->SOFTRST_CON01 */
+	LITCORE1_CRU_RESET_OFFSET(SRST_PRESETN_PVTPLL_LITCORE1, 1, 0),
+	LITCORE1_CRU_RESET_OFFSET(SRST_PRESETN_LITCORE1_CRU, 1, 1),
+	LITCORE1_CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_LITCORE1, 1, 2),
+	LITCORE1_CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_LITCORE1, 1, 3),
+
+	/* CCI_CRU-->SOFTRST_CON01 */
+	CCI_CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_24M_CCI, 1, 7),
+	CCI_CRU_RESET_OFFSET(SRST_RESETN_TEST_JUDGE_CCI, 1, 8),
+	CCI_CRU_RESET_OFFSET(SRST_ARESETN_CPE, 1, 11),
+	CCI_CRU_RESET_OFFSET(SRST_PRESETN_CCI_BIU, 1, 12),
+	CCI_CRU_RESET_OFFSET(SRST_PRESETN_CCI_FW, 1, 13),
+	CCI_CRU_RESET_OFFSET(SRST_ARESETN_CCI_BIU, 1, 14),
+	CCI_CRU_RESET_OFFSET(SRST_ARESETN_CCI_FW, 1, 15),
+
+	/* CCI_CRU-->SOFTRST_CON02 */
+	CCI_CRU_RESET_OFFSET(SRST_PRESETN_DBG_SYS, 2, 0),
+	CCI_CRU_RESET_OFFSET(SRST_PRESETN_CCI_GRF, 2, 1),
+	CCI_CRU_RESET_OFFSET(SRST_PRESETN_CCI_CRU, 2, 2),
+	CCI_CRU_RESET_OFFSET(SRST_ARESETN_CCI, 2, 3),
+	CCI_CRU_RESET_OFFSET(SRST_PORESETN_JTAG, 2, 4),
+	CCI_CRU_RESET_OFFSET(SRST_PRESETN_DBG_M, 2, 5),
+	CCI_CRU_RESET_OFFSET(SRST_ARESETN_ADB400_CCI_A73, 2, 6),
+	CCI_CRU_RESET_OFFSET(SRST_ARESETN_ADB400_CCI_A53_0, 2, 7),
+	CCI_CRU_RESET_OFFSET(SRST_ARESETN_ADB400_CCI_A53_1, 2, 8),
+	CCI_CRU_RESET_OFFSET(SRST_PRESETN_PVTPLL_CCI, 2, 9),
+	CCI_CRU_RESET_OFFSET(SRST_PRESETN_CCI_SPINLOCK, 2, 10),
+	CCI_CRU_RESET_OFFSET(SRST_PRESETN_DBG_M_BIU, 2, 11),
+	CCI_CRU_RESET_OFFSET(SRST_RESETN_REF_CCI_PVTPLL, 2, 12),
+};
+
+void rk3572_rst_init(struct device_node *np, void __iomem *reg_base)
+{
+	rockchip_register_softrst_lut(np,
+				      rk3572_register_offset,
+				      ARRAY_SIZE(rk3572_register_offset),
+				      reg_base + RK3572_SOFTRST_CON(0),
+				      ROCKCHIP_SOFTRST_HIWORD_MASK);
+}
+EXPORT_SYMBOL_GPL(rk3572_rst_init);
+
+MODULE_LICENSE("GPL");
+MODULE_DESCRIPTION("Rockchip RK3572 Soft Reset Driver");
+MODULE_AUTHOR("Elaine Zhang <zhangqing@rock-chips.com>");

-- 
2.34.1

