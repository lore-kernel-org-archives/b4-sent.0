From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 20 Jul 2026 08:38:06 +0800
Subject: [PATCH v4 3/3] clk: ultrarisc: Add DP1000 clock driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-ultrarisc-clock-v4-3-fe639d63bbac@ultrarisc.com>
References: <20260720-ultrarisc-clock-v4-0-fe639d63bbac@ultrarisc.com>
In-Reply-To: <20260720-ultrarisc-clock-v4-0-fe639d63bbac@ultrarisc.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784507902; l=21628;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=RsuveeDH0OrSqn+BMfKFeaup9uyqwAoepSytlv+EnAw=;
 b=WGvTeMAfW+lyHMD+15gw9H2dVHgpDpUrUDQmNRmljL3I1lhdK6bwLQQ+V///1uSRLutgI7jjF
 9aDUEWYejKYDWENwL+FdtxFP7/7OYDnLwjJVeRHrLzNzqKqbMtFULiG
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a clock driver for the UltraRISC DP1000 SoC.

The clock tree is driven by a SYSPLL and provides fixed-factor clocks for
the subsystem and PCIe, divider-based root clocks for GMAC and the UART,
I2C, and SPI blocks, and per-instance gate clocks for UART0-3, I2C0-3,
and SPI0-1.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 MAINTAINERS                           |   1 +
 drivers/clk/Kconfig                   |   1 +
 drivers/clk/Makefile                  |   1 +
 drivers/clk/ultrarisc/Kconfig         |  18 ++
 drivers/clk/ultrarisc/Makefile        |   4 +
 drivers/clk/ultrarisc/clk-dp1000.c    | 154 +++++++++++++
 drivers/clk/ultrarisc/clk-ultrarisc.c | 399 ++++++++++++++++++++++++++++++++++
 drivers/clk/ultrarisc/clk-ultrarisc.h |  71 ++++++
 8 files changed, 649 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index d646707bb17f..d9a20d5ba13b 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -27676,6 +27676,7 @@ M:	Jia Wang <wangjia@ultrarisc.com>
 L:	linux-clk@vger.kernel.org
 S:	Maintained
 F:	Documentation/devicetree/bindings/clock/ultrarisc,dp1000-clk.yaml
+F:	drivers/clk/ultrarisc/*
 F:	include/dt-bindings/clock/ultrarisc,dp1000-clk.h
 
 ULTRARISC DP1000 PINCTRL DRIVER
diff --git a/drivers/clk/Kconfig b/drivers/clk/Kconfig
index 1717ce75a907..b33a0d93d909 100644
--- a/drivers/clk/Kconfig
+++ b/drivers/clk/Kconfig
@@ -541,6 +541,7 @@ source "drivers/clk/tenstorrent/Kconfig"
 source "drivers/clk/thead/Kconfig"
 source "drivers/clk/stm32/Kconfig"
 source "drivers/clk/ti/Kconfig"
+source "drivers/clk/ultrarisc/Kconfig"
 source "drivers/clk/uniphier/Kconfig"
 source "drivers/clk/visconti/Kconfig"
 source "drivers/clk/x86/Kconfig"
diff --git a/drivers/clk/Makefile b/drivers/clk/Makefile
index cc108a75a900..c66621a8b6cd 100644
--- a/drivers/clk/Makefile
+++ b/drivers/clk/Makefile
@@ -159,6 +159,7 @@ obj-$(CONFIG_ARCH_TEGRA)		+= tegra/
 obj-y					+= tenstorrent/
 obj-$(CONFIG_ARCH_THEAD)		+= thead/
 obj-y					+= ti/
+obj-y					+= ultrarisc/
 obj-$(CONFIG_CLK_UNIPHIER)		+= uniphier/
 obj-$(CONFIG_ARCH_U8500)		+= ux500/
 obj-y					+= versatile/
diff --git a/drivers/clk/ultrarisc/Kconfig b/drivers/clk/ultrarisc/Kconfig
new file mode 100644
index 000000000000..2eecc6ac3119
--- /dev/null
+++ b/drivers/clk/ultrarisc/Kconfig
@@ -0,0 +1,18 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+config CLK_ULTRARISC
+	tristate
+	depends on OF
+	depends on ARCH_ULTRARISC || COMPILE_TEST
+
+config CLK_ULTRARISC_DP1000
+	tristate "UltraRISC DP1000 clock controller"
+	select CLK_ULTRARISC
+	depends on OF && HAS_IOMEM
+	depends on ARCH_ULTRARISC || COMPILE_TEST
+	default ARCH_ULTRARISC
+	help
+	  This driver provides the clock controller for the UltraRISC
+	  DP1000 SoC. It exposes the PLL output, derived fixed-factor
+	  clocks, programmable divider clocks, and peripheral gate
+	  clocks to Linux consumers.
diff --git a/drivers/clk/ultrarisc/Makefile b/drivers/clk/ultrarisc/Makefile
new file mode 100644
index 000000000000..b013708c9444
--- /dev/null
+++ b/drivers/clk/ultrarisc/Makefile
@@ -0,0 +1,4 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+obj-$(CONFIG_CLK_ULTRARISC) += clk-ultrarisc.o
+obj-$(CONFIG_CLK_ULTRARISC_DP1000) += clk-dp1000.o
diff --git a/drivers/clk/ultrarisc/clk-dp1000.c b/drivers/clk/ultrarisc/clk-dp1000.c
new file mode 100644
index 000000000000..ffea77c4cca0
--- /dev/null
+++ b/drivers/clk/ultrarisc/clk-dp1000.c
@@ -0,0 +1,154 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (C) 2026 UltraRISC Technology (Shanghai) Co., Ltd.
+ */
+
+#include <linux/module.h>
+
+#include <dt-bindings/clock/ultrarisc,dp1000-clk.h>
+
+#include "clk-ultrarisc.h"
+
+#define DP1000_PLL_CFG1_OFFSET		0x400
+#define DP1000_PLL_CFG2_OFFSET		0x404
+
+#define DP1000_CCR_UART_OFFSET		0x220
+#define DP1000_CCR_I2C_OFFSET		0x224
+#define DP1000_CCR_GMAC_OFFSET		0x228
+#define DP1000_CCR_SPI_OFFSET		0x22c
+#define DP1000_PERI_CLKENA_OFFSET	0x270
+
+#define DP1000_CCR_LOAD			BIT(16)
+
+#define DP1000_PERI_MAX_RATE		62500000UL
+#define DP1000_CLK_NUM			21
+
+static const struct ultrarisc_pll_layout dp1000_pll_layout = {
+	.cfg1_offset = DP1000_PLL_CFG1_OFFSET,
+	.cfg2_offset = DP1000_PLL_CFG2_OFFSET,
+	.frac_mask = GENMASK(23, 0),
+	.m_mask = GENMASK(23, 16),
+	.n_mask = GENMASK(11, 6),
+	.oddiv1_mask = GENMASK(1, 0),
+	.oddiv2_mask = GENMASK(4, 3),
+};
+
+static const struct ultrarisc_pll_desc dp1000_plls[] = {
+	{
+		.id = DP1000_CLK_SYSPLL,
+		.name = "syspll_clk",
+	},
+};
+
+#define DP1000_FIXED_FACTOR(_id, _name, _parent, _mult, _div)	\
+	{							\
+		.id = (_id),					\
+		.name = (_name),				\
+		.parent_id = (_parent),				\
+		.mult = (_mult),				\
+		.div = (_div),					\
+	}
+
+#define DP1000_DIV(_id, _name, _offset, _parent, _max_rate)	\
+	{							\
+		.id = (_id),					\
+		.name = (_name),				\
+		.offset = (_offset),				\
+		.parent_id = (_parent),				\
+		.max_rate = (_max_rate),			\
+		.load_mask = DP1000_CCR_LOAD,			\
+		.div_shift = 8,					\
+		.div_width = 4,					\
+		.gate_bit = 0,					\
+		.divider_flags = CLK_DIVIDER_ONE_BASED,		\
+		.gate_flags = 0,				\
+	}
+
+#define DP1000_GATE(_id, _name, _parent, _bit)		\
+	{							\
+		.id = (_id),					\
+		.name = (_name),				\
+		.offset = DP1000_PERI_CLKENA_OFFSET,		\
+		.parent_id = (_parent),				\
+		.gate_bit = (_bit),				\
+		.gate_flags = 0,				\
+	}
+
+static const struct ultrarisc_fixed_factor_desc dp1000_fixed_factor_clks[] = {
+	DP1000_FIXED_FACTOR(DP1000_CLK_SYSPLL_DIV2, "syspll_div2_clk",
+			    DP1000_CLK_SYSPLL, 1, 2),
+	DP1000_FIXED_FACTOR(DP1000_CLK_SUBSYS, "subsys_clk",
+			    DP1000_CLK_SYSPLL_DIV2, 1, 2),
+	DP1000_FIXED_FACTOR(DP1000_CLK_PCIE_DBI, "pcie_dbi_clk",
+			    DP1000_CLK_SYSPLL, 1, 10),
+	DP1000_FIXED_FACTOR(DP1000_CLK_PCIEX4_CORE, "pciex4_core_clk",
+			    DP1000_CLK_SYSPLL, 1, 2),
+	DP1000_FIXED_FACTOR(DP1000_CLK_PCIEX16_CORE, "pciex16_core_clk",
+			    DP1000_CLK_SYSPLL, 1, 1),
+	DP1000_FIXED_FACTOR(DP1000_CLK_PCIE_AUX, "pcie_aux_clk",
+			    DP1000_CLK_SYSPLL, 1, 40),
+};
+
+static const struct ultrarisc_divider_desc dp1000_divider_clks[] = {
+	DP1000_DIV(DP1000_CLK_GMAC, "gmac_clk", DP1000_CCR_GMAC_OFFSET,
+		   DP1000_CLK_SYSPLL_DIV2, 0),
+	DP1000_DIV(DP1000_CLK_UART_ROOT, "uart_root_clk",
+		   DP1000_CCR_UART_OFFSET, DP1000_CLK_SUBSYS,
+		   DP1000_PERI_MAX_RATE),
+	DP1000_DIV(DP1000_CLK_I2C_ROOT, "i2c_root_clk",
+		   DP1000_CCR_I2C_OFFSET, DP1000_CLK_SUBSYS,
+		   DP1000_PERI_MAX_RATE),
+	DP1000_DIV(DP1000_CLK_SPI_ROOT, "spi_root_clk",
+		   DP1000_CCR_SPI_OFFSET, DP1000_CLK_SUBSYS,
+		   DP1000_PERI_MAX_RATE),
+};
+
+static const struct ultrarisc_gate_desc dp1000_gate_clks[] = {
+	DP1000_GATE(DP1000_CLK_UART0, "uart0_clk", DP1000_CLK_UART_ROOT, 0),
+	DP1000_GATE(DP1000_CLK_UART1, "uart1_clk", DP1000_CLK_UART_ROOT, 1),
+	DP1000_GATE(DP1000_CLK_UART2, "uart2_clk", DP1000_CLK_UART_ROOT, 2),
+	DP1000_GATE(DP1000_CLK_UART3, "uart3_clk", DP1000_CLK_UART_ROOT, 3),
+	DP1000_GATE(DP1000_CLK_I2C0, "i2c0_clk", DP1000_CLK_I2C_ROOT, 4),
+	DP1000_GATE(DP1000_CLK_I2C1, "i2c1_clk", DP1000_CLK_I2C_ROOT, 5),
+	DP1000_GATE(DP1000_CLK_I2C2, "i2c2_clk", DP1000_CLK_I2C_ROOT, 6),
+	DP1000_GATE(DP1000_CLK_I2C3, "i2c3_clk", DP1000_CLK_I2C_ROOT, 7),
+	DP1000_GATE(DP1000_CLK_SPI0, "spi0_clk", DP1000_CLK_SPI_ROOT, 8),
+	DP1000_GATE(DP1000_CLK_SPI1, "spi1_clk", DP1000_CLK_SPI_ROOT, 9),
+};
+
+static const struct ultrarisc_clk_soc_data dp1000_clk_soc_data = {
+	.num_clks = DP1000_CLK_NUM,
+	.pll_layout = &dp1000_pll_layout,
+	.plls = dp1000_plls,
+	.num_plls = ARRAY_SIZE(dp1000_plls),
+	.fixed_factors = dp1000_fixed_factor_clks,
+	.num_fixed_factors = ARRAY_SIZE(dp1000_fixed_factor_clks),
+	.dividers = dp1000_divider_clks,
+	.num_dividers = ARRAY_SIZE(dp1000_divider_clks),
+	.gates = dp1000_gate_clks,
+	.num_gates = ARRAY_SIZE(dp1000_gate_clks),
+};
+
+static int dp1000_clk_probe(struct platform_device *pdev)
+{
+	return ultrarisc_clk_probe(pdev, &dp1000_clk_soc_data);
+}
+
+static const struct of_device_id dp1000_clk_of_match[] = {
+	{ .compatible = "ultrarisc,dp1000-clk" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, dp1000_clk_of_match);
+
+static struct platform_driver dp1000_clk_driver = {
+	.probe = dp1000_clk_probe,
+	.driver = {
+		.name = "ultrarisc-dp1000-clk",
+		.of_match_table = dp1000_clk_of_match,
+	},
+};
+module_platform_driver(dp1000_clk_driver);
+
+MODULE_IMPORT_NS("CLK_ULTRARISC");
+MODULE_DESCRIPTION("UltraRISC DP1000 clock controller");
+MODULE_LICENSE("GPL");
diff --git a/drivers/clk/ultrarisc/clk-ultrarisc.c b/drivers/clk/ultrarisc/clk-ultrarisc.c
new file mode 100644
index 000000000000..bbcd2234ea71
--- /dev/null
+++ b/drivers/clk/ultrarisc/clk-ultrarisc.c
@@ -0,0 +1,399 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (C) 2026 UltraRISC Technology (Shanghai) Co., Ltd.
+ */
+
+#include <linux/bitfield.h>
+#include <linux/clk-provider.h>
+#include <linux/io.h>
+#include <linux/math64.h>
+#include <linux/module.h>
+#include <linux/platform_device.h>
+
+#include "clk-ultrarisc.h"
+
+struct ultrarisc_pll_clk {
+	struct clk_hw hw;
+	void __iomem *base;
+	const struct ultrarisc_pll_layout *layout;
+};
+
+struct ultrarisc_divider_clk {
+	struct clk_divider divider;
+	struct clk_gate gate;
+	u32 load_mask;
+};
+
+#define to_ultrarisc_pll_clk(_hw) \
+	container_of(_hw, struct ultrarisc_pll_clk, hw)
+
+static inline struct ultrarisc_divider_clk *to_ultrarisc_divider_clk(struct clk_hw *hw)
+{
+	struct clk_divider *divider = to_clk_divider(hw);
+
+	return container_of(divider, struct ultrarisc_divider_clk, divider);
+}
+
+static unsigned long ultrarisc_pll_recalc_rate(struct clk_hw *hw,
+					       unsigned long parent_rate)
+{
+	struct ultrarisc_pll_clk *pll = to_ultrarisc_pll_clk(hw);
+	const struct ultrarisc_pll_layout *layout = pll->layout;
+	u32 oddiv1_div, oddiv2_div;
+	u64 mult, rate, den;
+	u32 frac, m, n;
+	u32 cfg1, cfg2;
+
+	cfg1 = readl_relaxed(pll->base + layout->cfg1_offset);
+	cfg2 = readl_relaxed(pll->base + layout->cfg2_offset);
+
+	frac = field_get(layout->frac_mask, cfg1);
+	m = field_get(layout->m_mask, cfg2);
+	n = field_get(layout->n_mask, cfg2);
+	if (!n)
+		return 0;
+
+	oddiv1_div = 1U << field_get(layout->oddiv1_mask, cfg2);
+	oddiv2_div = 1U << field_get(layout->oddiv2_mask, cfg2);
+
+	/*
+	 * The output frequency is calculated as:
+	 * fvco = parent * (m + frac / 2^24) / n
+	 * fout = fvco / (2^oddiv1_raw * 2^oddiv2_raw)
+	 *
+	 * The output divider values are derived from the raw register field values as:
+	 * oddivX_div = 1 << oddivX_raw
+	 */
+	mult = ((u64)m << 24) + frac;
+	rate = (u64)parent_rate * mult;
+	den = ((u64)n << 24) * oddiv1_div * oddiv2_div;
+
+	return div64_u64(rate + (den >> 1), den);
+}
+
+static const struct clk_ops ultrarisc_pll_ro_ops = {
+	.recalc_rate = ultrarisc_pll_recalc_rate,
+};
+
+static unsigned long ultrarisc_divider_recalc_rate(struct clk_hw *hw,
+						   unsigned long parent_rate)
+{
+	struct clk_divider *divider = to_clk_divider(hw);
+	u32 val;
+
+	val = readl_relaxed(divider->reg) >> divider->shift;
+	val &= clk_div_mask(divider->width);
+
+	return divider_recalc_rate(hw, parent_rate, val, divider->table,
+				   divider->flags, divider->width);
+}
+
+static int ultrarisc_divider_determine_rate(struct clk_hw *hw,
+					    struct clk_rate_request *req)
+{
+	struct clk_divider *divider = to_clk_divider(hw);
+
+	return divider_determine_rate(hw, req, divider->table, divider->width,
+				      divider->flags);
+}
+
+static int ultrarisc_divider_set_rate(struct clk_hw *hw, unsigned long rate,
+				      unsigned long parent_rate)
+{
+	struct ultrarisc_divider_clk *divider_clk = to_ultrarisc_divider_clk(hw);
+	struct clk_divider *divider = &divider_clk->divider;
+	int value;
+	u32 val;
+
+	value = divider_get_val(rate, parent_rate, divider->table,
+				divider->width, divider->flags);
+	if (value < 0)
+		return value;
+
+	scoped_guard(spinlock_irqsave, divider->lock) {
+		val = readl_relaxed(divider->reg);
+		val &= ~(clk_div_mask(divider->width) << divider->shift);
+		val |= value << divider->shift;
+		writel_relaxed(val, divider->reg);
+
+		if (divider_clk->load_mask) {
+			/*
+			 * Program the new divider field, then write 1 to the
+			 * load bit to trigger the update. The load bit is
+			 * write-triggered and reads back as 0 on this hardware.
+			 */
+			writel_relaxed(val | divider_clk->load_mask, divider->reg);
+		}
+	}
+
+	return 0;
+}
+
+static const struct clk_ops ultrarisc_divider_ops = {
+	.recalc_rate = ultrarisc_divider_recalc_rate,
+	.determine_rate = ultrarisc_divider_determine_rate,
+	.set_rate = ultrarisc_divider_set_rate,
+};
+
+static struct clk_hw *ultrarisc_clk_register_pll(struct device *dev,
+						 const struct ultrarisc_pll_desc *desc,
+						 const struct ultrarisc_pll_layout *layout,
+						 void __iomem *base)
+{
+	struct clk_parent_data pdata = { .index = 0 };
+	struct ultrarisc_pll_clk *pll;
+	struct clk_init_data init = {
+		.name = desc->name,
+		.ops = &ultrarisc_pll_ro_ops,
+		.parent_data = &pdata,
+		.num_parents = 1,
+		.flags = CLK_GET_RATE_NOCACHE,
+	};
+	int ret;
+
+	pll = devm_kzalloc(dev, sizeof(*pll), GFP_KERNEL);
+	if (!pll)
+		return ERR_PTR(-ENOMEM);
+
+	pll->base = base;
+	pll->layout = layout;
+	pll->hw.init = &init;
+
+	ret = devm_clk_hw_register(dev, &pll->hw);
+	if (ret)
+		return ERR_PTR(ret);
+
+	return &pll->hw;
+}
+
+static struct clk_hw *
+ultrarisc_clk_register_divider(struct device *dev,
+			       const struct ultrarisc_divider_desc *desc,
+			       struct clk_hw *parent_hw, void __iomem *base,
+			       spinlock_t *lock)
+{
+	const struct clk_parent_data pdata = { .hw = parent_hw };
+	void __iomem *reg = base + desc->offset;
+	struct ultrarisc_divider_clk *divider;
+
+	if (!desc->div_width)
+		return ERR_PTR(-EINVAL);
+
+	if (!lock)
+		return ERR_PTR(-EINVAL);
+
+	divider = devm_kzalloc(dev, sizeof(*divider), GFP_KERNEL);
+	if (!divider)
+		return ERR_PTR(-ENOMEM);
+
+	divider->divider.reg = reg;
+	divider->divider.shift = desc->div_shift;
+	divider->divider.width = desc->div_width;
+	divider->divider.flags = desc->divider_flags;
+	divider->divider.lock = lock;
+	divider->load_mask = desc->load_mask;
+	divider->gate.reg = reg;
+	divider->gate.bit_idx = desc->gate_bit;
+	divider->gate.flags = desc->gate_flags;
+	divider->gate.lock = lock;
+
+	return devm_clk_hw_register_composite_pdata(dev, desc->name,
+						    &pdata, 1, NULL, NULL,
+						    &divider->divider.hw,
+						    &ultrarisc_divider_ops,
+						    &divider->gate.hw,
+						    &clk_gate_ops, 0);
+}
+
+static int ultrarisc_clk_register_fixed_factors(struct device *dev,
+						struct clk_hw_onecell_data *clk_data,
+						const struct ultrarisc_clk_soc_data *soc_data)
+{
+	u32 i;
+
+	for (i = 0; i < soc_data->num_fixed_factors; i++) {
+		const struct ultrarisc_fixed_factor_desc *desc;
+		struct clk_hw *parent_hw;
+		struct clk_hw *hw;
+
+		desc = &soc_data->fixed_factors[i];
+		if (desc->id >= clk_data->num || desc->parent_id >= clk_data->num)
+			return -EINVAL;
+
+		parent_hw = clk_data->hws[desc->parent_id];
+		if (!parent_hw)
+			return -EINVAL;
+
+		hw = devm_clk_hw_register_fixed_factor_parent_hw(dev, desc->name,
+								 parent_hw, 0,
+								 desc->mult,
+								 desc->div);
+		if (IS_ERR(hw))
+			return PTR_ERR(hw);
+
+		clk_data->hws[desc->id] = hw;
+	}
+
+	return 0;
+}
+
+static int ultrarisc_clk_register_plls(struct platform_device *pdev,
+				       struct clk_hw_onecell_data *clk_data,
+				       const struct ultrarisc_clk_soc_data *soc_data,
+				       void __iomem *base)
+{
+	struct device *dev = &pdev->dev;
+	u32 i;
+
+	for (i = 0; i < soc_data->num_plls; i++) {
+		const struct ultrarisc_pll_desc *desc = &soc_data->plls[i];
+		struct clk_hw *hw;
+
+		if (desc->id >= clk_data->num) {
+			dev_err(dev, "%s invalid clock ID %u >= %u\n",
+				desc->name, desc->id, clk_data->num);
+			return -EINVAL;
+		}
+
+		hw = ultrarisc_clk_register_pll(dev, desc, soc_data->pll_layout, base);
+		if (IS_ERR(hw))
+			return PTR_ERR(hw);
+
+		clk_data->hws[desc->id] = hw;
+	}
+
+	return 0;
+}
+
+static int ultrarisc_clk_register_dividers(struct platform_device *pdev,
+					   struct clk_hw_onecell_data *clk_data,
+					   const struct ultrarisc_clk_soc_data *soc_data,
+					   void __iomem *base,
+					   spinlock_t *lock)
+{
+	struct device *dev = &pdev->dev;
+	u32 i;
+
+	for (i = 0; i < soc_data->num_dividers; i++) {
+		const struct ultrarisc_divider_desc *desc;
+		struct clk_hw *parent_hw;
+		struct clk_hw *hw;
+
+		desc = &soc_data->dividers[i];
+		if (desc->id >= clk_data->num || desc->parent_id >= clk_data->num)
+			return -EINVAL;
+
+		parent_hw = clk_data->hws[desc->parent_id];
+		if (!parent_hw)
+			return -EINVAL;
+
+		hw = ultrarisc_clk_register_divider(dev, desc, parent_hw, base,
+						    lock);
+		if (IS_ERR(hw))
+			return PTR_ERR(hw);
+
+		if (desc->max_rate)
+			clk_hw_set_rate_range(hw, 0, desc->max_rate);
+
+		clk_data->hws[desc->id] = hw;
+	}
+
+	return 0;
+}
+
+static int ultrarisc_clk_register_gates(struct platform_device *pdev,
+					struct clk_hw_onecell_data *clk_data,
+					const struct ultrarisc_clk_soc_data *soc_data,
+					void __iomem *base,
+					spinlock_t *lock)
+{
+	struct device *dev = &pdev->dev;
+	u32 i;
+
+	for (i = 0; i < soc_data->num_gates; i++) {
+		const struct ultrarisc_gate_desc *desc;
+		struct clk_hw *parent_hw;
+		struct clk_hw *hw;
+
+		desc = &soc_data->gates[i];
+		if (desc->id >= clk_data->num || desc->parent_id >= clk_data->num)
+			return -EINVAL;
+
+		parent_hw = clk_data->hws[desc->parent_id];
+		if (!parent_hw)
+			return -EINVAL;
+
+		hw = devm_clk_hw_register_gate_parent_hw(dev, desc->name,
+							 parent_hw, 0,
+							 base + desc->offset,
+							 desc->gate_bit,
+							 desc->gate_flags,
+							 lock);
+		if (IS_ERR(hw))
+			return PTR_ERR(hw);
+
+		clk_data->hws[desc->id] = hw;
+	}
+
+	return 0;
+}
+
+int ultrarisc_clk_probe(struct platform_device *pdev,
+			const struct ultrarisc_clk_soc_data *soc_data)
+{
+	struct clk_hw_onecell_data *clk_data;
+	struct device *dev = &pdev->dev;
+	void __iomem *base;
+	spinlock_t *lock;
+	int ret;
+
+	if (!soc_data)
+		return -EINVAL;
+
+	lock = devm_kzalloc(dev, sizeof(*lock), GFP_KERNEL);
+	if (!lock)
+		return -ENOMEM;
+
+	spin_lock_init(lock);
+
+	clk_data = devm_kzalloc(dev, struct_size(clk_data, hws,
+						 soc_data->num_clks),
+				GFP_KERNEL);
+	if (!clk_data)
+		return -ENOMEM;
+
+	clk_data->num = soc_data->num_clks;
+
+	base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(base))
+		return PTR_ERR(base);
+
+	ret = ultrarisc_clk_register_plls(pdev, clk_data, soc_data, base);
+	if (ret)
+		return ret;
+
+	ret = ultrarisc_clk_register_fixed_factors(dev, clk_data, soc_data);
+	if (ret)
+		return ret;
+
+	ret = ultrarisc_clk_register_dividers(pdev, clk_data, soc_data, base, lock);
+	if (ret)
+		return ret;
+
+	ret = ultrarisc_clk_register_gates(pdev, clk_data, soc_data, base, lock);
+	if (ret)
+		return ret;
+
+	for (int i = 0; i < clk_data->num; i++) {
+		if (!clk_data->hws[i]) {
+			dev_err(dev, "missing clock ID %u\n", i);
+			return -EINVAL;
+		}
+	}
+
+	return devm_of_clk_add_hw_provider(dev, of_clk_hw_onecell_get, clk_data);
+}
+EXPORT_SYMBOL_NS_GPL(ultrarisc_clk_probe, "CLK_ULTRARISC");
+
+MODULE_DESCRIPTION("UltraRISC clock core driver");
+MODULE_LICENSE("GPL");
diff --git a/drivers/clk/ultrarisc/clk-ultrarisc.h b/drivers/clk/ultrarisc/clk-ultrarisc.h
new file mode 100644
index 000000000000..8202b7ed0e31
--- /dev/null
+++ b/drivers/clk/ultrarisc/clk-ultrarisc.h
@@ -0,0 +1,71 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+#ifndef __ULTRARISC_CLK_ULTRARISC_H
+#define __ULTRARISC_CLK_ULTRARISC_H
+
+#include <linux/clk-provider.h>
+#include <linux/platform_device.h>
+#include <linux/types.h>
+
+struct ultrarisc_pll_layout {
+	u32 cfg1_offset;
+	u32 cfg2_offset;
+	u32 frac_mask;
+	u32 m_mask;
+	u32 n_mask;
+	u32 oddiv1_mask;
+	u32 oddiv2_mask;
+};
+
+struct ultrarisc_pll_desc {
+	u32 id;
+	const char *name;
+};
+
+struct ultrarisc_fixed_factor_desc {
+	u32 id;
+	const char *name;
+	u32 parent_id;
+	u32 mult;
+	u32 div;
+};
+
+struct ultrarisc_divider_desc {
+	u32 id;
+	const char *name;
+	u32 offset;
+	u32 parent_id;
+	unsigned long max_rate;
+	u32 load_mask;
+	u8 div_shift;
+	u8 div_width;
+	u8 gate_bit;
+	u16 divider_flags;
+	u8 gate_flags;
+};
+
+struct ultrarisc_gate_desc {
+	u32 id;
+	const char *name;
+	u32 offset;
+	u32 parent_id;
+	u8 gate_bit;
+	u8 gate_flags;
+};
+
+struct ultrarisc_clk_soc_data {
+	const struct ultrarisc_pll_layout *pll_layout;
+	const struct ultrarisc_pll_desc *plls;
+	u32 num_plls;
+	const struct ultrarisc_fixed_factor_desc *fixed_factors;
+	u32 num_fixed_factors;
+	const struct ultrarisc_divider_desc *dividers;
+	u32 num_dividers;
+	const struct ultrarisc_gate_desc *gates;
+	u32 num_gates;
+	u32 num_clks;
+};
+
+int ultrarisc_clk_probe(struct platform_device *pdev,
+			const struct ultrarisc_clk_soc_data *soc_data);
+
+#endif /* __ULTRARISC_CLK_ULTRARISC_H */

-- 
2.34.1

