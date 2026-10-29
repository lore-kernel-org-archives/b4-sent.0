From: Jian Hu <jian.hu@amlogic.com>
Date: Thu, 29 Oct 2026 17:30:54 +0800
Subject: [PATCH RFC RFT v2 3/3] clk: meson: pll: Remove the dedicated n
 parameter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-meson_refactor_n-v2-3-ff4ac74e527b@amlogic.com>
References: <20261029-meson_refactor_n-v2-0-ff4ac74e527b@amlogic.com>
In-Reply-To: <20261029-meson_refactor_n-v2-0-ff4ac74e527b@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793266267; l=93164;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=g/Atz8luuXig9HOza21acDAbXAR2pfsK3OJYW/ZYamc=;
 b=M/nQKeuEBPPV++YFxmz6bqKWaDqmXIfw3Kr06MPryK9HTjlfMcdlceMQzNFaifxczFEgf2FNl
 40QKxd1cejvDIHHkg5lNGWvCVbGeB5FMKk7R5upsvyWM3CiGRzn3q94
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Meson PLL framework models the PLL pre-divider (N) using a dedicated
field in struct meson_clk_pll_data. Since the common clock framework
already provides a generic divider implementation, there is no need to
keep PLL-specific support for it.

The pre-divider is not intended to be dynamically adjusted. According to
the hardware design, each PLL has a single fixed N value, defined together
with the rest of the PLL. N = 1 for most PLLs, and N = 3 for a few special
cases (the axg PCIe PLL, gxbb Fixed PLL and the meson8b GP0 PLL). The PLL
input frequency constraints are respected by this fixed value.

Remove the dedicated n parameter from the framework and simplify the PLL
rate calculation accordingly. The pre-divider will be represented as a
separate divider clock by platform drivers where needed.

Replace the dedicated PLL pre-divider with a standalone divider clock
for all amlogic SoCs. The PLL DCO now takes the pre-divider clock
as its parent instead of the input clock directly.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 drivers/clk/meson/a1-pll.c     |  69 ++++++++--
 drivers/clk/meson/axg.c        | 230 +++++++++++++++++++++----------
 drivers/clk/meson/c3-pll.c     |  99 +++++++++++---
 drivers/clk/meson/clk-pll.c    | 203 +++++++++++----------------
 drivers/clk/meson/clk-pll.h    |  17 +--
 drivers/clk/meson/clk-regmap.h |   2 +-
 drivers/clk/meson/g12a.c       | 265 ++++++++++++++++++++++++++---------
 drivers/clk/meson/gxbb.c       | 304 +++++++++++++++++++++++++++--------------
 drivers/clk/meson/meson8-ddr.c |  39 +++++-
 drivers/clk/meson/meson8b.c    | 238 +++++++++++++++++++++-----------
 drivers/clk/meson/s4-pll.c     | 128 +++++++++++++----
 drivers/clk/meson/t7-pll.c     | 186 +++++++++++++++++++------
 12 files changed, 1224 insertions(+), 556 deletions(-)

diff --git a/drivers/clk/meson/a1-pll.c b/drivers/clk/meson/a1-pll.c
index 100c4221256e..681ba329d52b 100644
--- a/drivers/clk/meson/a1-pll.c
+++ b/drivers/clk/meson/a1-pll.c
@@ -25,6 +25,36 @@
 
 #include <dt-bindings/clock/amlogic,a1-pll-clkc.h>
 
+/* Keep the pre-divider at 1 to achieve the best PLL performance. */
+static const struct clk_div_table a1_prediv_div_table[] = {
+	{ .val = 1, .div = 1 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap a1_fixed_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = ANACTRL_FIXPLL_CTRL0,
+		.shift  = 10,
+		.width  = 5,
+		.table = a1_prediv_div_table,
+		/*
+		 * The PLL pre-divider have a zero value after reset,
+		 * which does not produce a usable clock. Use
+		 * CLK_DIVIDER_INVALID_ZERO to report this state correctly.
+		 * The pre-dividers below use this flag for the same reason.
+		 */
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "fixed_prediv",
+		.ops = &clk_regmap_divider_ro_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "fixpll_in",
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap a1_fixed_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -37,11 +67,6 @@ static struct clk_regmap a1_fixed_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = ANACTRL_FIXPLL_CTRL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = ANACTRL_FIXPLL_CTRL1,
 			.shift   = 0,
@@ -61,8 +86,8 @@ static struct clk_regmap a1_fixed_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "fixed_pll_dco",
 		.ops = &meson_clk_pll_ro_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "fixpll_in",
+		.parent_hws = (const struct clk_hw *[]) {
+			&a1_fixed_prediv.hw
 		},
 		.num_parents = 1,
 	},
@@ -83,6 +108,24 @@ static struct clk_regmap a1_fixed_pll = {
 	},
 };
 
+static struct clk_regmap a1_hifi_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = ANACTRL_HIFIPLL_CTRL0,
+		.shift = 10,
+		.width = 5,
+		.table = a1_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "hifi_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "hifipll_in",
+		},
+		.num_parents = 1,
+	},
+};
+
 static const struct pll_mult_range a1_hifi_pll_range = {
 	.min = 32,
 	.max = 64,
@@ -108,11 +151,6 @@ static struct clk_regmap a1_hifi_pll = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = ANACTRL_HIFIPLL_CTRL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = ANACTRL_HIFIPLL_CTRL1,
 			.shift   = 0,
@@ -140,10 +178,11 @@ static struct clk_regmap a1_hifi_pll = {
 	.hw.init = &(struct clk_init_data){
 		.name = "hifi_pll",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "hifipll_in",
+		.parent_hws = (const struct clk_hw *[]) {
+			&a1_hifi_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -281,6 +320,7 @@ static struct clk_regmap a1_fclk_div7 = {
 
 /* Array of all clocks registered by this provider */
 static struct clk_hw *a1_pll_hw_clks[] = {
+	[CLKID_FIXED_PREDIV]	= &a1_fixed_prediv.hw,
 	[CLKID_FIXED_PLL_DCO]	= &a1_fixed_pll_dco.hw,
 	[CLKID_FIXED_PLL]	= &a1_fixed_pll.hw,
 	[CLKID_FCLK_DIV2_DIV]	= &a1_fclk_div2_div.hw,
@@ -291,6 +331,7 @@ static struct clk_hw *a1_pll_hw_clks[] = {
 	[CLKID_FCLK_DIV3]	= &a1_fclk_div3.hw,
 	[CLKID_FCLK_DIV5]	= &a1_fclk_div5.hw,
 	[CLKID_FCLK_DIV7]	= &a1_fclk_div7.hw,
+	[CLKID_HIFI_PREDIV]	= &a1_hifi_prediv.hw,
 	[CLKID_HIFI_PLL]	= &a1_hifi_pll.hw,
 };
 
diff --git a/drivers/clk/meson/axg.c b/drivers/clk/meson/axg.c
index 280842e9cb37..e6e6b9a8030c 100644
--- a/drivers/clk/meson/axg.c
+++ b/drivers/clk/meson/axg.c
@@ -107,6 +107,36 @@
 #define HHI_DPLL_TOP_I			0x318
 #define HHI_DPLL_TOP2_I			0x31C
 
+/* Keep the pre-divider at 1 to achieve the best PLL performance. */
+static const struct clk_div_table axg_prediv_div_table[] = {
+	{ .val = 1, .div = 1 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap axg_fixed_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_MPLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = axg_prediv_div_table,
+		/*
+		 * The PLL pre-divider have a zero value after reset,
+		 * which does not produce a usable clock. Use
+		 * CLK_DIVIDER_INVALID_ZERO to report this state correctly.
+		 * The pre-dividers below use this flag for the same reason.
+		 */
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "fixed_prediv",
+		.ops = &clk_regmap_divider_ro_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap axg_fixed_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -119,11 +149,6 @@ static struct clk_regmap axg_fixed_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_MPLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_MPLL_CNTL2,
 			.shift   = 0,
@@ -143,8 +168,8 @@ static struct clk_regmap axg_fixed_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "fixed_pll_dco",
 		.ops = &meson_clk_pll_ro_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&axg_fixed_prediv.hw
 		},
 		.num_parents = 1,
 	},
@@ -171,6 +196,24 @@ static struct clk_regmap axg_fixed_pll = {
 	},
 };
 
+static struct clk_regmap axg_sys_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_SYS_PLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = axg_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "sys_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap axg_sys_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -183,11 +226,6 @@ static struct clk_regmap axg_sys_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_SYS_PLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = HHI_SYS_PLL_CNTL,
 			.shift   = 31,
@@ -202,10 +240,11 @@ static struct clk_regmap axg_sys_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "sys_pll_dco",
 		.ops = &meson_clk_pll_ro_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&axg_sys_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -227,39 +266,57 @@ static struct clk_regmap axg_sys_pll = {
 	},
 };
 
-static const struct pll_params_table axg_gp0_pll_params_table[] = {
-	PLL_PARAMS(40, 1),
-	PLL_PARAMS(41, 1),
-	PLL_PARAMS(42, 1),
-	PLL_PARAMS(43, 1),
-	PLL_PARAMS(44, 1),
-	PLL_PARAMS(45, 1),
-	PLL_PARAMS(46, 1),
-	PLL_PARAMS(47, 1),
-	PLL_PARAMS(48, 1),
-	PLL_PARAMS(49, 1),
-	PLL_PARAMS(50, 1),
-	PLL_PARAMS(51, 1),
-	PLL_PARAMS(52, 1),
-	PLL_PARAMS(53, 1),
-	PLL_PARAMS(54, 1),
-	PLL_PARAMS(55, 1),
-	PLL_PARAMS(56, 1),
-	PLL_PARAMS(57, 1),
-	PLL_PARAMS(58, 1),
-	PLL_PARAMS(59, 1),
-	PLL_PARAMS(60, 1),
-	PLL_PARAMS(61, 1),
-	PLL_PARAMS(62, 1),
-	PLL_PARAMS(63, 1),
-	PLL_PARAMS(64, 1),
-	PLL_PARAMS(65, 1),
-	PLL_PARAMS(66, 1),
-	PLL_PARAMS(67, 1),
-	PLL_PARAMS(68, 1),
+static const struct pll_mult_table axg_gp0_pll_params_table[] = {
+	PLL_MULT(40),
+	PLL_MULT(41),
+	PLL_MULT(42),
+	PLL_MULT(43),
+	PLL_MULT(44),
+	PLL_MULT(45),
+	PLL_MULT(46),
+	PLL_MULT(47),
+	PLL_MULT(48),
+	PLL_MULT(49),
+	PLL_MULT(50),
+	PLL_MULT(51),
+	PLL_MULT(52),
+	PLL_MULT(53),
+	PLL_MULT(54),
+	PLL_MULT(55),
+	PLL_MULT(56),
+	PLL_MULT(57),
+	PLL_MULT(58),
+	PLL_MULT(59),
+	PLL_MULT(60),
+	PLL_MULT(61),
+	PLL_MULT(62),
+	PLL_MULT(63),
+	PLL_MULT(64),
+	PLL_MULT(65),
+	PLL_MULT(66),
+	PLL_MULT(67),
+	PLL_MULT(68),
 	{ /* sentinel */ },
 };
 
+static struct clk_regmap axg_gp0_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_GP0_PLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = axg_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "gp0_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 static const struct reg_sequence axg_gp0_init_regs[] = {
 	{ .reg = HHI_GP0_PLL_CNTL1,	.def = 0xc084b000 },
 	{ .reg = HHI_GP0_PLL_CNTL2,	.def = 0xb75020be },
@@ -280,11 +337,6 @@ static struct clk_regmap axg_gp0_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_GP0_PLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_GP0_PLL_CNTL1,
 			.shift   = 0,
@@ -307,10 +359,11 @@ static struct clk_regmap axg_gp0_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "gp0_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&axg_gp0_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -332,6 +385,24 @@ static struct clk_regmap axg_gp0_pll = {
 	},
 };
 
+static struct clk_regmap axg_hifi_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_HIFI_PLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = axg_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "hifi_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 static const struct reg_sequence axg_hifi_pll_init_regs[] = {
 	{ .reg = HHI_HIFI_PLL_CNTL1,	.def = 0xc084b000 },
 	{ .reg = HHI_HIFI_PLL_CNTL2,	.def = 0xb75020be },
@@ -352,11 +423,6 @@ static struct clk_regmap axg_hifi_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_HIFI_PLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_HIFI_PLL_CNTL5,
 			.shift   = 0,
@@ -380,10 +446,11 @@ static struct clk_regmap axg_hifi_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "hifi_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&axg_hifi_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -771,11 +838,35 @@ static struct clk_regmap axg_mpll3 = {
 	},
 };
 
-static const struct pll_params_table axg_pcie_pll_params_table[] = {
-	{
-		.m = 200,
-		.n = 3,
+/*
+ * A pre-divider value of 3 provides the best performance for
+ * the AXG PCIe PLL.
+ */
+static const struct clk_div_table axg_pcie_prediv_div_table[] = {
+	{ .val = 3, .div = 3 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap axg_pcie_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_PCIE_PLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = axg_pcie_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "pcie_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
 	},
+};
+
+static const struct pll_mult_table axg_pcie_pll_params_table[] = {
+	PLL_MULT(200),
 	{ /* sentinel */ },
 };
 
@@ -801,11 +892,6 @@ static struct clk_regmap axg_pcie_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_PCIE_PLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_PCIE_PLL_CNTL1,
 			.shift   = 0,
@@ -828,10 +914,11 @@ static struct clk_regmap axg_pcie_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "pcie_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&axg_pcie_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -2067,10 +2154,15 @@ static struct clk_hw *axg_hw_clks[] = {
 	[CLKID_GEN_CLK_SEL]		= &axg_gen_clk_sel.hw,
 	[CLKID_GEN_CLK_DIV]		= &axg_gen_clk_div.hw,
 	[CLKID_GEN_CLK]			= &axg_gen_clk.hw,
+	[CLKID_SYS_PREDIV]		= &axg_sys_prediv.hw,
 	[CLKID_SYS_PLL_DCO]		= &axg_sys_pll_dco.hw,
+	[CLKID_FIXED_PREDIV]		= &axg_fixed_prediv.hw,
 	[CLKID_FIXED_PLL_DCO]		= &axg_fixed_pll_dco.hw,
+	[CLKID_GP0_PREDIV]		= &axg_gp0_prediv.hw,
 	[CLKID_GP0_PLL_DCO]		= &axg_gp0_pll_dco.hw,
+	[CLKID_HIFI_PREDIV]		= &axg_hifi_prediv.hw,
 	[CLKID_HIFI_PLL_DCO]		= &axg_hifi_pll_dco.hw,
+	[CLKID_PCIE_PREDIV]		= &axg_pcie_prediv.hw,
 	[CLKID_PCIE_PLL_DCO]		= &axg_pcie_pll_dco.hw,
 	[CLKID_PCIE_PLL_OD]		= &axg_pcie_pll_od.hw,
 	[CLKID_VPU_0_DIV]		= &axg_vpu_0_div.hw,
diff --git a/drivers/clk/meson/c3-pll.c b/drivers/clk/meson/c3-pll.c
index dd047d17488c..57bbd0498811 100644
--- a/drivers/clk/meson/c3-pll.c
+++ b/drivers/clk/meson/c3-pll.c
@@ -230,6 +230,36 @@ static struct clk_regmap c3_fclk_div7 = {
 	},
 };
 
+/* Keep the pre-divider at 1 to achieve the best PLL performance. */
+static const struct clk_div_table c3_prediv_div_table[] = {
+	{ .val = 1, .div = 1 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap c3_gp0_prediv = {
+	.data = &(struct clk_regmap_div_data) {
+		.offset = ANACTRL_GP0PLL_CTRL0,
+		.shift = 10,
+		.width = 5,
+		.table = c3_prediv_div_table,
+		/*
+		 * The PLL pre-divider have a zero value after reset,
+		 * which does not produce a usable clock. Use
+		 * CLK_DIVIDER_INVALID_ZERO to report this state correctly.
+		 * The pre-dividers below use this flag for the same reason.
+		 */
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "gp0_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "top",
+		},
+		.num_parents = 1,
+	},
+};
+
 static const struct reg_sequence c3_gp0_pll_init_regs[] = {
 	{ .reg = ANACTRL_GP0PLL_CTRL2,	.def = 0x0 },
 	{ .reg = ANACTRL_GP0PLL_CTRL3,	.def = 0x48681c00 },
@@ -260,11 +290,6 @@ static struct clk_regmap c3_gp0_pll_dco = {
 			.shift   = 0,
 			.width   = 19,
 		},
-		.n = {
-			.reg_off = ANACTRL_GP0PLL_CTRL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = ANACTRL_GP0PLL_CTRL0,
 			.shift   = 31,
@@ -282,10 +307,11 @@ static struct clk_regmap c3_gp0_pll_dco = {
 	.hw.init = &(struct clk_init_data) {
 		.name = "gp0_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "top",
+		.parent_hws = (const struct clk_hw *[]) {
+			&c3_gp0_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -318,6 +344,24 @@ static struct clk_regmap c3_gp0_pll = {
 	},
 };
 
+static struct clk_regmap c3_hifi_prediv = {
+	.data = &(struct clk_regmap_div_data) {
+		.offset = ANACTRL_HIFIPLL_CTRL0,
+		.shift = 10,
+		.width = 5,
+		.table = c3_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "hifi_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "top",
+		},
+		.num_parents = 1,
+	},
+};
+
 static const struct reg_sequence c3_hifi_pll_init_regs[] = {
 	{ .reg = ANACTRL_HIFIPLL_CTRL2,	.def = 0x0 },
 	{ .reg = ANACTRL_HIFIPLL_CTRL3,	.def = 0x6a285c00 },
@@ -343,11 +387,6 @@ static struct clk_regmap c3_hifi_pll_dco = {
 			.shift   = 0,
 			.width   = 19,
 		},
-		.n = {
-			.reg_off = ANACTRL_HIFIPLL_CTRL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = ANACTRL_HIFIPLL_CTRL0,
 			.shift   = 31,
@@ -366,10 +405,11 @@ static struct clk_regmap c3_hifi_pll_dco = {
 	.hw.init = &(struct clk_init_data) {
 		.name = "hifi_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "top",
+		.parent_hws = (const struct clk_hw *[]) {
+			&c3_hifi_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -391,6 +431,24 @@ static struct clk_regmap c3_hifi_pll = {
 	},
 };
 
+static struct clk_regmap c3_mclk_prediv = {
+	.data = &(struct clk_regmap_div_data) {
+		.offset = ANACTRL_MPLL_CTRL0,
+		.shift = 16,
+		.width = 5,
+		.table = c3_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "mclk_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "mclk",
+		},
+		.num_parents = 1,
+	},
+};
+
 static const struct reg_sequence c3_mclk_pll_init_regs[] = {
 	{ .reg = ANACTRL_MPLL_CTRL1,	.def = 0x1420500f },
 	{ .reg = ANACTRL_MPLL_CTRL2,	.def = 0x00023041 },
@@ -415,11 +473,6 @@ static struct clk_regmap c3_mclk_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = ANACTRL_MPLL_CTRL0,
-			.shift   = 16,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = ANACTRL_MPLL_CTRL0,
 			.shift   = 31,
@@ -437,10 +490,11 @@ static struct clk_regmap c3_mclk_pll_dco = {
 	.hw.init = &(struct clk_init_data) {
 		.name = "mclk_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "mclk",
+		.parent_hws = (const struct clk_hw *[]) {
+			&c3_mclk_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -636,10 +690,13 @@ static struct clk_hw *c3_pll_hw_clks[] = {
 	[CLKID_FCLK_DIV5]	= &c3_fclk_div5.hw,
 	[CLKID_FCLK_DIV7_DIV]	= &c3_fclk_div7_div.hw,
 	[CLKID_FCLK_DIV7]	= &c3_fclk_div7.hw,
+	[CLKID_GP0_PREDIV]	= &c3_gp0_prediv.hw,
 	[CLKID_GP0_PLL_DCO]	= &c3_gp0_pll_dco.hw,
 	[CLKID_GP0_PLL]		= &c3_gp0_pll.hw,
+	[CLKID_HIFI_PREDIV]	= &c3_hifi_prediv.hw,
 	[CLKID_HIFI_PLL_DCO]	= &c3_hifi_pll_dco.hw,
 	[CLKID_HIFI_PLL]	= &c3_hifi_pll.hw,
+	[CLKID_MCLK_PREDIV]	= &c3_mclk_prediv.hw,
 	[CLKID_MCLK_PLL_DCO]	= &c3_mclk_pll_dco.hw,
 	[CLKID_MCLK_PLL_OD]	= &c3_mclk_pll_od.hw,
 	[CLKID_MCLK_PLL]	= &c3_mclk_pll.hw,
diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index 1ea6579a760f..a7e3f8c8eb78 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -14,7 +14,7 @@
  *        +--------------------------------+
  *        |                                |
  *        |             +--+               |
- *  in >>-----[ /N ]--->|  |      +-----+  |
+ *  in >>----------->|  |      +-----+  |
  *        |             |  |------| DCO |---->> out
  *        |  +--------->|  |      +--v--+  |
  *        |  |          +--+         |     |
@@ -23,7 +23,7 @@
  *        |                                |
  *        +--------------------------------+
  *
- * out = in * (m + frac / frac_max) / n
+ * out = in * (m + frac / frac_max)
  */
 
 #include <linux/clk-provider.h>
@@ -52,8 +52,7 @@ static int __pll_round_closest_mult(struct meson_clk_pll_data *pll)
 }
 
 static unsigned long __pll_params_to_rate(unsigned long parent_rate,
-					  unsigned int m, unsigned int n,
-					  unsigned int frac,
+					  unsigned int m, unsigned int frac,
 					  struct meson_clk_pll_data *pll)
 {
 	u64 rate = (u64)parent_rate * m;
@@ -66,7 +65,7 @@ static unsigned long __pll_params_to_rate(unsigned long parent_rate,
 		rate += DIV_ROUND_UP_ULL(frac_rate, frac_max);
 	}
 
-	return DIV_ROUND_UP_ULL(rate, n);
+	return rate;
 }
 
 static unsigned long meson_clk_pll_recalc_rate(struct clk_hw *hw,
@@ -74,17 +73,7 @@ static unsigned long meson_clk_pll_recalc_rate(struct clk_hw *hw,
 {
 	struct clk_regmap *clk = to_clk_regmap(hw);
 	struct meson_clk_pll_data *pll = meson_clk_pll_data(clk);
-	unsigned int m, n, frac;
-
-	n = meson_parm_read(clk->map, &pll->n);
-
-	/*
-	 * On some HW, N is set to zero on init. This value is invalid as
-	 * it would result in a division by zero. The rate can't be
-	 * calculated in this case
-	 */
-	if (n == 0)
-		return 0;
+	unsigned int m, frac;
 
 	m = meson_parm_read(clk->map, &pll->m);
 
@@ -92,21 +81,20 @@ static unsigned long meson_clk_pll_recalc_rate(struct clk_hw *hw,
 		meson_parm_read(clk->map, &pll->frac) :
 		0;
 
-	return __pll_params_to_rate(parent_rate, m, n, frac, pll);
+	return __pll_params_to_rate(parent_rate, m, frac, pll);
 }
 
 static unsigned int __pll_params_with_frac(unsigned long rate,
 					   unsigned long parent_rate,
 					   unsigned int m,
-					   unsigned int n,
 					   struct meson_clk_pll_data *pll)
 {
 	unsigned int frac_max = pll->frac_max ? pll->frac_max :
 						(1 << pll->frac.width);
-	u64 val = (u64)rate * n;
+	u64 val = (u64)rate;
 
 	/* Bail out if we are already over the requested rate */
-	if (rate < parent_rate * m / n)
+	if (rate < parent_rate * m)
 		return 0;
 
 	if (pll->flags & CLK_MESON_PLL_ROUND_CLOSEST)
@@ -119,128 +107,76 @@ static unsigned int __pll_params_with_frac(unsigned long rate,
 	return min((unsigned int)val, (frac_max - 1));
 }
 
-static bool meson_clk_pll_is_better(unsigned long rate,
-				    unsigned long best,
-				    unsigned long now,
-				    struct meson_clk_pll_data *pll)
+static int meson_clk_get_pll_range(unsigned long rate,
+				   unsigned long parent_rate,
+				   unsigned int *m,
+				   struct meson_clk_pll_data *pll)
 {
-	if (__pll_round_closest_mult(pll)) {
-		/* Round Closest */
-		if (abs(now - rate) < abs(best - rate))
-			return true;
-	} else {
-		/* Round down */
-		if (now <= rate && best < now)
-			return true;
+	if (rate <= pll->range->min * parent_rate) {
+		*m = pll->range->min;
+		return -ENODATA;
+	} else if (rate >= pll->range->max * parent_rate) {
+		*m = pll->range->max;
+		return -ENODATA;
 	}
 
-	return false;
-}
+	if (__pll_round_closest_mult(pll))
+		*m = DIV_ROUND_CLOSEST_ULL(rate, parent_rate);
+	else
+		*m = div_u64(rate, parent_rate);
 
-static int meson_clk_get_pll_table_index(unsigned int index,
-					 unsigned int *m,
-					 unsigned int *n,
-					 struct meson_clk_pll_data *pll)
-{
-	if (!pll->table[index].n)
+	/* Multiplier exceeds hardware range */
+	if (*m >= (1 << pll->m.width))
 		return -EINVAL;
 
-	*m = pll->table[index].m;
-	*n = pll->table[index].n;
-
 	return 0;
 }
 
-static unsigned int meson_clk_get_pll_range_m(unsigned long rate,
-					      unsigned long parent_rate,
-					      unsigned int n,
-					      struct meson_clk_pll_data *pll)
+static int meson_clk_get_pll_table(unsigned long rate,
+				   unsigned long parent_rate,
+				   unsigned int *m,
+				   struct meson_clk_pll_data *pll)
 {
-	u64 val = (u64)rate * n;
-
-	if (__pll_round_closest_mult(pll))
-		return DIV_ROUND_CLOSEST_ULL(val, parent_rate);
-
-	return div_u64(val,  parent_rate);
-}
-
-static int meson_clk_get_pll_range_index(unsigned long rate,
-					 unsigned long parent_rate,
-					 unsigned int index,
-					 unsigned int *m,
-					 unsigned int *n,
-					 struct meson_clk_pll_data *pll)
-{
-	*n = index + 1;
+	unsigned int i;
+	int ret;
 
-	/* Check the predivider range */
-	if (*n >= (1 << pll->n.width))
-		return -EINVAL;
+	for (i = 0, ret = 0; !ret; i++) {
+		if (!pll->table[i].m)
+			return -EINVAL;
 
-	if (*n == 1) {
-		/* Get the boundaries out the way */
-		if (rate <= pll->range->min * parent_rate) {
-			*m = pll->range->min;
-			return -ENODATA;
-		} else if (rate >= pll->range->max * parent_rate) {
-			*m = pll->range->max;
-			return -ENODATA;
+		if (pll->table[i].m == rate / parent_rate) {
+			*m = pll->table[i].m;
+			return 0;
 		}
 	}
 
-	*m = meson_clk_get_pll_range_m(rate, parent_rate, *n, pll);
-
-	/* the pre-divider gives a multiplier too big - stop */
-	if (*m >= (1 << pll->m.width))
-		return -EINVAL;
-
 	return 0;
 }
 
-static int meson_clk_get_pll_get_index(unsigned long rate,
-				       unsigned long parent_rate,
-				       unsigned int index,
-				       unsigned int *m,
-				       unsigned int *n,
-				       struct meson_clk_pll_data *pll)
+static int meson_clk_get_pll_multiplier(unsigned long rate,
+					unsigned long parent_rate,
+					unsigned int *m,
+					struct meson_clk_pll_data *pll)
 {
 	if (pll->range)
-		return meson_clk_get_pll_range_index(rate, parent_rate,
-						     index, m, n, pll);
+		return meson_clk_get_pll_range(rate, parent_rate, m, pll);
 	else if (pll->table)
-		return meson_clk_get_pll_table_index(index, m, n, pll);
+		return meson_clk_get_pll_table(rate, parent_rate, m, pll);
 
 	return -EINVAL;
 }
 
-static int meson_clk_get_pll_settings(unsigned long rate,
-				      unsigned long parent_rate,
-				      unsigned int *best_m,
-				      unsigned int *best_n,
-				      struct meson_clk_pll_data *pll)
+static unsigned int meson_clk_get_pll_max_multiplier(struct meson_clk_pll_data *pll)
 {
-	unsigned long best = 0, now = 0;
-	unsigned int i, m, n;
-	int ret;
+	unsigned int i, max_mult = 0;
 
-	for (i = 0, ret = 0; !ret; i++) {
-		ret = meson_clk_get_pll_get_index(rate, parent_rate,
-						  i, &m, &n, pll);
-		if (ret == -EINVAL)
-			break;
-
-		now = __pll_params_to_rate(parent_rate, m, n, 0, pll);
-		if (meson_clk_pll_is_better(rate, best, now, pll)) {
-			best = now;
-			*best_m = m;
-			*best_n = n;
-
-			if (now == rate)
-				break;
-		}
-	}
+	if (pll->range)
+		return pll->range->max;
+
+	for (i = 0; pll->table && pll->table[i].m; i++)
+		max_mult = max(max_mult, pll->table[i].m);
 
-	return best ? 0 : -EINVAL;
+	return max_mult;
 }
 
 static int meson_clk_pll_determine_rate(struct clk_hw *hw,
@@ -248,16 +184,32 @@ static int meson_clk_pll_determine_rate(struct clk_hw *hw,
 {
 	struct clk_regmap *clk = to_clk_regmap(hw);
 	struct meson_clk_pll_data *pll = meson_clk_pll_data(clk);
-	unsigned int m, n, frac;
+	unsigned int max_mult, m, frac;
 	unsigned long round;
 	int ret;
 
-	ret = meson_clk_get_pll_settings(req->rate, req->best_parent_rate,
-					 &m, &n, pll);
-	if (ret)
+	/*
+	 * The pre-divider resets to an invalid zero value and reports a
+	 * zero rate until it gets programmed. Ask the parent for the
+	 * lowest rate which keeps the requested rate reachable; the CCF
+	 * will program the pre-divider when applying the parent rate.
+	 */
+	if (!req->best_parent_rate) {
+		max_mult = meson_clk_get_pll_max_multiplier(pll);
+		if (!max_mult)
+			return -EINVAL;
+
+		req->best_parent_rate = clk_hw_round_rate(req->best_parent_hw,
+							  DIV_ROUND_UP_ULL(req->rate, max_mult));
+		if (!req->best_parent_rate)
+			return -EINVAL;
+	}
+
+	ret = meson_clk_get_pll_multiplier(req->rate, req->best_parent_rate, &m, pll);
+	if (ret && ret != -ENODATA)
 		return ret;
 
-	round = __pll_params_to_rate(req->best_parent_rate, m, n, 0, pll);
+	round = __pll_params_to_rate(req->best_parent_rate, m, 0, pll);
 
 	if (!MESON_PARM_APPLICABLE(&pll->frac) || req->rate == round) {
 		req->rate = round;
@@ -268,8 +220,8 @@ static int meson_clk_pll_determine_rate(struct clk_hw *hw,
 	 * The rate provided by the setting is not an exact match, let's
 	 * try to improve the result using the fractional parameter
 	 */
-	frac = __pll_params_with_frac(req->rate, req->best_parent_rate, m, n, pll);
-	req->rate = __pll_params_to_rate(req->best_parent_rate, m, n, frac, pll);
+	frac = __pll_params_with_frac(req->rate, req->best_parent_rate, m, pll);
+	req->rate = __pll_params_to_rate(req->best_parent_rate, m, frac, pll);
 
 	return 0;
 }
@@ -420,7 +372,7 @@ static int meson_clk_pll_set_rate(struct clk_hw *hw, unsigned long rate,
 {
 	struct clk_regmap *clk = to_clk_regmap(hw);
 	struct meson_clk_pll_data *pll = meson_clk_pll_data(clk);
-	unsigned int enabled, m, n, frac = 0;
+	unsigned int enabled, m, frac = 0;
 	unsigned long old_rate;
 	int ret;
 
@@ -429,19 +381,18 @@ static int meson_clk_pll_set_rate(struct clk_hw *hw, unsigned long rate,
 
 	old_rate = clk_hw_get_rate(hw);
 
-	ret = meson_clk_get_pll_settings(rate, parent_rate, &m, &n, pll);
-	if (ret)
+	ret = meson_clk_get_pll_multiplier(rate, parent_rate, &m, pll);
+	if (ret && ret != -ENODATA)
 		return ret;
 
 	enabled = meson_parm_read(clk->map, &pll->en);
 	if (enabled)
 		meson_clk_pll_disable(hw);
 
-	meson_parm_write(clk->map, &pll->n, n);
 	meson_parm_write(clk->map, &pll->m, m);
 
 	if (MESON_PARM_APPLICABLE(&pll->frac)) {
-		frac = __pll_params_with_frac(rate, parent_rate, m, n, pll);
+		frac = __pll_params_with_frac(rate, parent_rate, m, pll);
 		meson_parm_write(clk->map, &pll->frac, frac);
 	}
 
diff --git a/drivers/clk/meson/clk-pll.h b/drivers/clk/meson/clk-pll.h
index 949157fb7bf5..cf20deaac1ed 100644
--- a/drivers/clk/meson/clk-pll.h
+++ b/drivers/clk/meson/clk-pll.h
@@ -11,9 +11,8 @@
 #include <linux/regmap.h>
 #include "parm.h"
 
-struct pll_params_table {
-	unsigned int	m;
-	unsigned int	n;
+struct pll_mult_table {
+	unsigned int    m;
 };
 
 struct pll_mult_range {
@@ -21,11 +20,10 @@ struct pll_mult_range {
 	unsigned int	max;
 };
 
-#define PLL_PARAMS(_m, _n)						\
-	{								\
-		.m		= (_m),					\
-		.n		= (_n),					\
-	}
+#define PLL_MULT(_m)			\
+{					\
+	.m = (_m),			\
+}
 
 #define CLK_MESON_PLL_ROUND_CLOSEST	BIT(0)
 #define CLK_MESON_PLL_NOINIT_ENABLED	BIT(1)
@@ -33,7 +31,6 @@ struct pll_mult_range {
 struct meson_clk_pll_data {
 	struct parm en;
 	struct parm m;
-	struct parm n;
 	struct parm frac;
 	struct parm l;
 	struct parm rst;
@@ -41,7 +38,7 @@ struct meson_clk_pll_data {
 	struct parm l_detect;
 	const struct reg_sequence *init_regs;
 	unsigned int init_count;
-	const struct pll_params_table *table;
+	const struct pll_mult_table *table;
 	const struct pll_mult_range *range;
 	unsigned int frac_max;
 	u8 flags;
diff --git a/drivers/clk/meson/clk-regmap.h b/drivers/clk/meson/clk-regmap.h
index 8e5c39b023e1..ee2a4b3408f0 100644
--- a/drivers/clk/meson/clk-regmap.h
+++ b/drivers/clk/meson/clk-regmap.h
@@ -75,7 +75,7 @@ struct clk_regmap_div_data {
 	unsigned int	offset;
 	u8		shift;
 	u8		width;
-	u8		flags;
+	u16		flags;
 	const struct clk_div_table	*table;
 };
 
diff --git a/drivers/clk/meson/g12a.c b/drivers/clk/meson/g12a.c
index d0d4c7b6dc82..4be367c89aca 100644
--- a/drivers/clk/meson/g12a.c
+++ b/drivers/clk/meson/g12a.c
@@ -137,6 +137,36 @@
 #define HHI_SYS1_PLL_CNTL5		0x394
 #define HHI_SYS1_PLL_CNTL6		0x398
 
+/* Keep the pre-divider at 1 to achieve the best PLL performance. */
+static const struct clk_div_table g12a_prediv_div_table[] = {
+	{ .val = 1, .div = 1 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap g12a_fixed_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_FIX_PLL_CNTL0,
+		.shift   = 10,
+		.width   = 5,
+		.table = g12a_prediv_div_table,
+		/*
+		 * The PLL pre-divider have a zero value after reset,
+		 * which does not produce a usable clock. Use
+		 * CLK_DIVIDER_INVALID_ZERO to report this state correctly.
+		 * The pre-dividers below use this flag for the same reason.
+		 */
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "fixed_prediv",
+		.ops = &clk_regmap_divider_ro_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap g12a_fixed_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -149,11 +179,6 @@ static struct clk_regmap g12a_fixed_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = HHI_FIX_PLL_CNTL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_FIX_PLL_CNTL1,
 			.shift   = 0,
@@ -173,8 +198,8 @@ static struct clk_regmap g12a_fixed_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "fixed_pll_dco",
 		.ops = &meson_clk_pll_ro_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&g12a_fixed_prediv.hw
 		},
 		.num_parents = 1,
 	},
@@ -206,6 +231,24 @@ static const struct pll_mult_range g12a_sys_pll_mult_range = {
 	.max = 250,
 };
 
+static struct clk_regmap g12a_sys_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_SYS_PLL_CNTL0,
+		.shift   = 10,
+		.width   = 5,
+		.table = g12a_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "sys_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap g12a_sys_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -218,11 +261,6 @@ static struct clk_regmap g12a_sys_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = HHI_SYS_PLL_CNTL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = HHI_SYS_PLL_CNTL0,
 			.shift   = 31,
@@ -238,12 +276,12 @@ static struct clk_regmap g12a_sys_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "sys_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&g12a_sys_prediv.hw
 		},
 		.num_parents = 1,
 		/* This clock feeds the CPU, avoid disabling it */
-		.flags = CLK_IS_CRITICAL,
+		.flags = CLK_SET_RATE_PARENT | CLK_IS_CRITICAL,
 	},
 };
 
@@ -265,6 +303,24 @@ static struct clk_regmap g12a_sys_pll = {
 	},
 };
 
+static struct clk_regmap g12b_sys1_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_SYS1_PLL_CNTL0,
+		.shift   = 10,
+		.width   = 5,
+		.table = g12a_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "sys1_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap g12b_sys1_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -277,11 +333,6 @@ static struct clk_regmap g12b_sys1_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = HHI_SYS1_PLL_CNTL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = HHI_SYS1_PLL_CNTL0,
 			.shift   = 31,
@@ -297,12 +348,12 @@ static struct clk_regmap g12b_sys1_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "sys1_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&g12b_sys1_prediv.hw
 		},
 		.num_parents = 1,
 		/* This clock feeds the CPU, avoid disabling it */
-		.flags = CLK_IS_CRITICAL,
+		.flags = CLK_SET_RATE_PARENT | CLK_IS_CRITICAL,
 	},
 };
 
@@ -386,6 +437,24 @@ static struct clk_fixed_factor g12b_sys1_pll_div16 = {
 	},
 };
 
+static struct clk_regmap g12a_gp0_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_GP0_PLL_CNTL0,
+		.shift   = 10,
+		.width   = 5,
+		.table = g12a_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "gp0_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 static const struct pll_mult_range g12a_gp0_pll_mult_range = {
 	.min = 125,
 	.max = 255,
@@ -415,11 +484,6 @@ static struct clk_regmap g12a_gp0_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = HHI_GP0_PLL_CNTL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_GP0_PLL_CNTL1,
 			.shift   = 0,
@@ -442,10 +506,11 @@ static struct clk_regmap g12a_gp0_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "gp0_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&g12a_gp0_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -468,6 +533,24 @@ static struct clk_regmap g12a_gp0_pll = {
 	},
 };
 
+static struct clk_regmap sm1_gp1_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_GP1_PLL_CNTL0,
+		.shift   = 10,
+		.width   = 5,
+		.table = g12a_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "gp1_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap sm1_gp1_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -480,11 +563,6 @@ static struct clk_regmap sm1_gp1_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = HHI_GP1_PLL_CNTL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_GP1_PLL_CNTL1,
 			.shift   = 0,
@@ -504,12 +582,12 @@ static struct clk_regmap sm1_gp1_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "gp1_pll_dco",
 		.ops = &meson_clk_pll_ro_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&sm1_gp1_prediv.hw
 		},
 		.num_parents = 1,
 		/* This clock feeds the DSU, avoid disabling it */
-		.flags = CLK_IS_CRITICAL,
+		.flags = CLK_SET_RATE_PARENT | CLK_IS_CRITICAL,
 	},
 };
 
@@ -531,6 +609,24 @@ static struct clk_regmap sm1_gp1_pll = {
 	},
 };
 
+static struct clk_regmap g12a_hifi_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_HIFI_PLL_CNTL0,
+		.shift   = 10,
+		.width   = 5,
+		.table = g12a_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "hifi_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 /*
  * Internal hifi pll emulation configuration parameters
  */
@@ -555,11 +651,6 @@ static struct clk_regmap g12a_hifi_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = HHI_HIFI_PLL_CNTL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_HIFI_PLL_CNTL1,
 			.shift   = 0,
@@ -583,10 +674,11 @@ static struct clk_regmap g12a_hifi_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "hifi_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&g12a_hifi_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -609,6 +701,24 @@ static struct clk_regmap g12a_hifi_pll = {
 	},
 };
 
+static struct clk_regmap g12a_pcie_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_PCIE_PLL_CNTL0,
+		.shift   = 10,
+		.width   = 5,
+		.table = g12a_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "pcie_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 /*
  * The Meson G12A PCIE PLL is fined tuned to deliver a very precise
  * 100MHz reference clock for the PCIe Analog PHY, and thus requires
@@ -630,9 +740,9 @@ static const struct reg_sequence g12a_pcie_pll_init_regs[] = {
 };
 
 /* Keep a single entry table for recalc/round_rate() ops */
-static const struct pll_params_table g12a_pcie_pll_table[] = {
-	PLL_PARAMS(150, 1),
-	{0, 0},
+static const struct pll_mult_table g12a_pcie_pll_table[] = {
+	PLL_MULT(150),
+	{ /* sentinel */ },
 };
 
 static struct clk_regmap g12a_pcie_pll_dco = {
@@ -647,11 +757,6 @@ static struct clk_regmap g12a_pcie_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = HHI_PCIE_PLL_CNTL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_PCIE_PLL_CNTL1,
 			.shift   = 0,
@@ -674,10 +779,11 @@ static struct clk_regmap g12a_pcie_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "pcie_pll_dco",
 		.ops = &meson_clk_pcie_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&g12a_pcie_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -729,6 +835,24 @@ static struct clk_fixed_factor g12a_pcie_pll = {
 	},
 };
 
+static struct clk_regmap g12a_hdmi_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_HDMI_PLL_CNTL0,
+		.shift   = 10,
+		.width   = 5,
+		.table = g12a_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "hdmi_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap g12a_hdmi_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -741,11 +865,6 @@ static struct clk_regmap g12a_hdmi_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = HHI_HDMI_PLL_CNTL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_HDMI_PLL_CNTL1,
 			.shift   = 0,
@@ -765,15 +884,15 @@ static struct clk_regmap g12a_hdmi_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll_dco",
 		.ops = &meson_clk_pll_ro_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&g12a_hdmi_prediv.hw
 		},
 		.num_parents = 1,
 		/*
 		 * Display directly handle hdmi pll registers ATM, we need
 		 * NOCACHE to keep our view of the clock as accurate as possible
 		 */
-		.flags = CLK_GET_RATE_NOCACHE,
+		.flags = CLK_SET_RATE_PARENT | CLK_GET_RATE_NOCACHE,
 	},
 };
 
@@ -4593,9 +4712,13 @@ static struct clk_hw *g12a_hw_clks[] = {
 	[CLKID_VCLK2_VENCLMMC]		= &g12a_vclk2_venclmmc.hw,
 	[CLKID_VCLK2_VENCL]		= &g12a_vclk2_vencl.hw,
 	[CLKID_VCLK2_OTHER1]		= &g12a_vclk2_other1.hw,
+	[CLKID_FIXED_PREDIV]		= &g12a_fixed_prediv.hw,
 	[CLKID_FIXED_PLL_DCO]		= &g12a_fixed_pll_dco.hw,
+	[CLKID_SYS_PREDIV]		= &g12a_sys_prediv.hw,
 	[CLKID_SYS_PLL_DCO]		= &g12a_sys_pll_dco.hw,
+	[CLKID_GP0_PREDIV]		= &g12a_gp0_prediv.hw,
 	[CLKID_GP0_PLL_DCO]		= &g12a_gp0_pll_dco.hw,
+	[CLKID_HIFI_PREDIV]		= &g12a_hifi_prediv.hw,
 	[CLKID_HIFI_PLL_DCO]		= &g12a_hifi_pll_dco.hw,
 	[CLKID_DMA]			= &g12a_dma.hw,
 	[CLKID_EFUSE]			= &g12a_efuse.hw,
@@ -4618,6 +4741,7 @@ static struct clk_hw *g12a_hw_clks[] = {
 	[CLKID_VAPB_1]			= &g12a_vapb_1.hw,
 	[CLKID_VAPB_SEL]		= &g12a_vapb_sel.hw,
 	[CLKID_VAPB]			= &g12a_vapb.hw,
+	[CLKID_HDMI_PREDIV]		= &g12a_hdmi_prediv.hw,
 	[CLKID_HDMI_PLL_DCO]		= &g12a_hdmi_pll_dco.hw,
 	[CLKID_HDMI_PLL_OD]		= &g12a_hdmi_pll_od.hw,
 	[CLKID_HDMI_PLL_OD2]		= &g12a_hdmi_pll_od2.hw,
@@ -4693,6 +4817,7 @@ static struct clk_hw *g12a_hw_clks[] = {
 	[CLKID_CPU_CLK_AXI]		= &g12a_cpu_clk_axi.hw,
 	[CLKID_CPU_CLK_TRACE_DIV]	= &g12a_cpu_clk_trace_div.hw,
 	[CLKID_CPU_CLK_TRACE]		= &g12a_cpu_clk_trace.hw,
+	[CLKID_PCIE_PREDIV]		= &g12a_pcie_prediv.hw,
 	[CLKID_PCIE_PLL_DCO]		= &g12a_pcie_pll_dco.hw,
 	[CLKID_PCIE_PLL_DCO_DIV2]	= &g12a_pcie_pll_dco_div2.hw,
 	[CLKID_PCIE_PLL_OD]		= &g12a_pcie_pll_od.hw,
@@ -4820,9 +4945,13 @@ static struct clk_hw *g12b_hw_clks[] = {
 	[CLKID_VCLK2_VENCLMMC]		= &g12a_vclk2_venclmmc.hw,
 	[CLKID_VCLK2_VENCL]		= &g12a_vclk2_vencl.hw,
 	[CLKID_VCLK2_OTHER1]		= &g12a_vclk2_other1.hw,
+	[CLKID_FIXED_PREDIV]		= &g12a_fixed_prediv.hw,
 	[CLKID_FIXED_PLL_DCO]		= &g12a_fixed_pll_dco.hw,
+	[CLKID_SYS_PREDIV]		= &g12a_sys_prediv.hw,
 	[CLKID_SYS_PLL_DCO]		= &g12a_sys_pll_dco.hw,
+	[CLKID_GP0_PREDIV]		= &g12a_gp0_prediv.hw,
 	[CLKID_GP0_PLL_DCO]		= &g12a_gp0_pll_dco.hw,
+	[CLKID_HIFI_PREDIV]		= &g12a_hifi_prediv.hw,
 	[CLKID_HIFI_PLL_DCO]		= &g12a_hifi_pll_dco.hw,
 	[CLKID_DMA]			= &g12a_dma.hw,
 	[CLKID_EFUSE]			= &g12a_efuse.hw,
@@ -4845,6 +4974,7 @@ static struct clk_hw *g12b_hw_clks[] = {
 	[CLKID_VAPB_1]			= &g12a_vapb_1.hw,
 	[CLKID_VAPB_SEL]		= &g12a_vapb_sel.hw,
 	[CLKID_VAPB]			= &g12a_vapb.hw,
+	[CLKID_HDMI_PREDIV]		= &g12a_hdmi_prediv.hw,
 	[CLKID_HDMI_PLL_DCO]		= &g12a_hdmi_pll_dco.hw,
 	[CLKID_HDMI_PLL_OD]		= &g12a_hdmi_pll_od.hw,
 	[CLKID_HDMI_PLL_OD2]		= &g12a_hdmi_pll_od2.hw,
@@ -4920,6 +5050,7 @@ static struct clk_hw *g12b_hw_clks[] = {
 	[CLKID_CPU_CLK_AXI]		= &g12a_cpu_clk_axi.hw,
 	[CLKID_CPU_CLK_TRACE_DIV]	= &g12a_cpu_clk_trace_div.hw,
 	[CLKID_CPU_CLK_TRACE]		= &g12a_cpu_clk_trace.hw,
+	[CLKID_PCIE_PREDIV]		= &g12a_pcie_prediv.hw,
 	[CLKID_PCIE_PLL_DCO]		= &g12a_pcie_pll_dco.hw,
 	[CLKID_PCIE_PLL_DCO_DIV2]	= &g12a_pcie_pll_dco_div2.hw,
 	[CLKID_PCIE_PLL_OD]		= &g12a_pcie_pll_od.hw,
@@ -4935,6 +5066,7 @@ static struct clk_hw *g12b_hw_clks[] = {
 	[CLKID_VDEC_HEVCF]		= &g12a_vdec_hevcf.hw,
 	[CLKID_TS_DIV]			= &g12a_ts_div.hw,
 	[CLKID_TS]			= &g12a_ts.hw,
+	[CLKID_SYS1_PREDIV]		= &g12b_sys1_prediv.hw,
 	[CLKID_SYS1_PLL_DCO]		= &g12b_sys1_pll_dco.hw,
 	[CLKID_SYS1_PLL]		= &g12b_sys1_pll.hw,
 	[CLKID_SYS1_PLL_DIV16_EN]	= &g12b_sys1_pll_div16_en.hw,
@@ -5088,9 +5220,13 @@ static struct clk_hw *sm1_hw_clks[] = {
 	[CLKID_VCLK2_VENCLMMC]		= &g12a_vclk2_venclmmc.hw,
 	[CLKID_VCLK2_VENCL]		= &g12a_vclk2_vencl.hw,
 	[CLKID_VCLK2_OTHER1]		= &g12a_vclk2_other1.hw,
+	[CLKID_FIXED_PREDIV]		= &g12a_fixed_prediv.hw,
 	[CLKID_FIXED_PLL_DCO]		= &g12a_fixed_pll_dco.hw,
+	[CLKID_SYS_PREDIV]		= &g12a_sys_prediv.hw,
 	[CLKID_SYS_PLL_DCO]		= &g12a_sys_pll_dco.hw,
+	[CLKID_GP0_PREDIV]		= &g12a_gp0_prediv.hw,
 	[CLKID_GP0_PLL_DCO]		= &g12a_gp0_pll_dco.hw,
+	[CLKID_HIFI_PREDIV]		= &g12a_hifi_prediv.hw,
 	[CLKID_HIFI_PLL_DCO]		= &g12a_hifi_pll_dco.hw,
 	[CLKID_DMA]			= &g12a_dma.hw,
 	[CLKID_EFUSE]			= &g12a_efuse.hw,
@@ -5113,6 +5249,7 @@ static struct clk_hw *sm1_hw_clks[] = {
 	[CLKID_VAPB_1]			= &g12a_vapb_1.hw,
 	[CLKID_VAPB_SEL]		= &g12a_vapb_sel.hw,
 	[CLKID_VAPB]			= &g12a_vapb.hw,
+	[CLKID_HDMI_PREDIV]		= &g12a_hdmi_prediv.hw,
 	[CLKID_HDMI_PLL_DCO]		= &g12a_hdmi_pll_dco.hw,
 	[CLKID_HDMI_PLL_OD]		= &g12a_hdmi_pll_od.hw,
 	[CLKID_HDMI_PLL_OD2]		= &g12a_hdmi_pll_od2.hw,
@@ -5188,6 +5325,7 @@ static struct clk_hw *sm1_hw_clks[] = {
 	[CLKID_CPU_CLK_AXI]		= &g12a_cpu_clk_axi.hw,
 	[CLKID_CPU_CLK_TRACE_DIV]	= &g12a_cpu_clk_trace_div.hw,
 	[CLKID_CPU_CLK_TRACE]		= &g12a_cpu_clk_trace.hw,
+	[CLKID_PCIE_PREDIV]		= &g12a_pcie_prediv.hw,
 	[CLKID_PCIE_PLL_DCO]		= &g12a_pcie_pll_dco.hw,
 	[CLKID_PCIE_PLL_DCO_DIV2]	= &g12a_pcie_pll_dco_div2.hw,
 	[CLKID_PCIE_PLL_OD]		= &g12a_pcie_pll_od.hw,
@@ -5204,6 +5342,7 @@ static struct clk_hw *sm1_hw_clks[] = {
 	[CLKID_TS_DIV]			= &g12a_ts_div.hw,
 	[CLKID_TS]			= &g12a_ts.hw,
 	[CLKID_GP1_PLL_DCO]		= &sm1_gp1_pll_dco.hw,
+	[CLKID_GP1_PREDIV]		= &sm1_gp1_prediv.hw,
 	[CLKID_GP1_PLL]			= &sm1_gp1_pll.hw,
 	[CLKID_DSU_CLK_DYN0_SEL]	= &sm1_dsu_clk_dyn0_sel.hw,
 	[CLKID_DSU_CLK_DYN0_DIV]	= &sm1_dsu_clk_dyn0_div.hw,
diff --git a/drivers/clk/meson/gxbb.c b/drivers/clk/meson/gxbb.c
index 7a7b104182ff..9d09f13c22fb 100644
--- a/drivers/clk/meson/gxbb.c
+++ b/drivers/clk/meson/gxbb.c
@@ -115,6 +115,35 @@
 #define HHI_BT656_CLK_CNTL		0x3d4
 #define HHI_SAR_CLK_CNTL		0x3d8
 
+static const struct clk_div_table gxbb_fixed_prediv_div_table[] = {
+	{ .val = 3, .div = 3 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap gxbb_fixed_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_MPLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = gxbb_fixed_prediv_div_table,
+		/*
+		 * The PLL pre-divider have a zero value after reset,
+		 * which does not produce a usable clock. Use
+		 * CLK_DIVIDER_INVALID_ZERO to report this state correctly.
+		 * The pre-dividers below use this flag for the same reason.
+		 */
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "fixed_prediv",
+		.ops = &clk_regmap_divider_ro_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap gxbb_fixed_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -127,11 +156,6 @@ static struct clk_regmap gxbb_fixed_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_MPLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_MPLL_CNTL2,
 			.shift   = 0,
@@ -151,8 +175,8 @@ static struct clk_regmap gxbb_fixed_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "fixed_pll_dco",
 		.ops = &meson_clk_pll_ro_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&gxbb_fixed_prediv.hw
 		},
 		.num_parents = 1,
 	},
@@ -192,6 +216,30 @@ static struct clk_fixed_factor gxbb_hdmi_pll_pre_mult = {
 	},
 };
 
+/* Keep the pre-divider at 1 to achieve the best PLL performance. */
+static const struct clk_div_table gxbb_prediv_div_table[] = {
+	{ .val = 1, .div = 1 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap gxbb_hdmi_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_HDMI_PLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = gxbb_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "hdmi_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&gxbb_hdmi_pll_pre_mult.hw
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap gxbb_hdmi_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -204,11 +252,6 @@ static struct clk_regmap gxbb_hdmi_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_HDMI_PLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_HDMI_PLL_CNTL2,
 			.shift   = 0,
@@ -229,14 +272,32 @@ static struct clk_regmap gxbb_hdmi_pll_dco = {
 		.name = "hdmi_pll_dco",
 		.ops = &meson_clk_pll_ro_ops,
 		.parent_hws = (const struct clk_hw *[]) {
-			&gxbb_hdmi_pll_pre_mult.hw
+			&gxbb_hdmi_prediv.hw
 		},
 		.num_parents = 1,
 		/*
 		 * Display directly handle hdmi pll registers ATM, we need
 		 * NOCACHE to keep our view of the clock as accurate as possible
 		 */
-		.flags = CLK_GET_RATE_NOCACHE,
+		.flags = CLK_GET_RATE_NOCACHE | CLK_SET_RATE_PARENT,
+	},
+};
+
+static struct clk_regmap gxl_hdmi_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_HDMI_PLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = gxbb_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "hdmi_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
 	},
 };
 
@@ -252,11 +313,6 @@ static struct clk_regmap gxl_hdmi_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_HDMI_PLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		/*
 		 * On gxl, there is a register shift due to
 		 * HHI_HDMI_PLL_CNTL1 which does not exist on gxbb,
@@ -282,15 +338,15 @@ static struct clk_regmap gxl_hdmi_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll_dco",
 		.ops = &meson_clk_pll_ro_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&gxl_hdmi_prediv.hw
 		},
 		.num_parents = 1,
 		/*
 		 * Display directly handle hdmi pll registers ATM, we need
 		 * NOCACHE to keep our view of the clock as accurate as possible
 		 */
-		.flags = CLK_GET_RATE_NOCACHE,
+		.flags = CLK_GET_RATE_NOCACHE | CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -413,6 +469,24 @@ static struct clk_regmap gxl_hdmi_pll = {
 	},
 };
 
+static struct clk_regmap gxbb_sys_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_SYS_PLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = gxbb_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "sys_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap gxbb_sys_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -425,11 +499,6 @@ static struct clk_regmap gxbb_sys_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_SYS_PLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = HHI_SYS_PLL_CNTL,
 			.shift   = 31,
@@ -444,10 +513,11 @@ static struct clk_regmap gxbb_sys_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "sys_pll_dco",
 		.ops = &meson_clk_pll_ro_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&gxbb_sys_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -469,38 +539,56 @@ static struct clk_regmap gxbb_sys_pll = {
 	},
 };
 
-static const struct pll_params_table gxbb_gp0_pll_params_table[] = {
-	PLL_PARAMS(32, 1),
-	PLL_PARAMS(33, 1),
-	PLL_PARAMS(34, 1),
-	PLL_PARAMS(35, 1),
-	PLL_PARAMS(36, 1),
-	PLL_PARAMS(37, 1),
-	PLL_PARAMS(38, 1),
-	PLL_PARAMS(39, 1),
-	PLL_PARAMS(40, 1),
-	PLL_PARAMS(41, 1),
-	PLL_PARAMS(42, 1),
-	PLL_PARAMS(43, 1),
-	PLL_PARAMS(44, 1),
-	PLL_PARAMS(45, 1),
-	PLL_PARAMS(46, 1),
-	PLL_PARAMS(47, 1),
-	PLL_PARAMS(48, 1),
-	PLL_PARAMS(49, 1),
-	PLL_PARAMS(50, 1),
-	PLL_PARAMS(51, 1),
-	PLL_PARAMS(52, 1),
-	PLL_PARAMS(53, 1),
-	PLL_PARAMS(54, 1),
-	PLL_PARAMS(55, 1),
-	PLL_PARAMS(56, 1),
-	PLL_PARAMS(57, 1),
-	PLL_PARAMS(58, 1),
-	PLL_PARAMS(59, 1),
-	PLL_PARAMS(60, 1),
-	PLL_PARAMS(61, 1),
-	PLL_PARAMS(62, 1),
+static struct clk_regmap gxbb_gp0_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_GP0_PLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = gxbb_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "gp0_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
+static const struct pll_mult_table gxbb_gp0_pll_params_table[] = {
+	PLL_MULT(32),
+	PLL_MULT(33),
+	PLL_MULT(34),
+	PLL_MULT(35),
+	PLL_MULT(36),
+	PLL_MULT(37),
+	PLL_MULT(38),
+	PLL_MULT(39),
+	PLL_MULT(40),
+	PLL_MULT(41),
+	PLL_MULT(42),
+	PLL_MULT(43),
+	PLL_MULT(44),
+	PLL_MULT(45),
+	PLL_MULT(46),
+	PLL_MULT(47),
+	PLL_MULT(48),
+	PLL_MULT(49),
+	PLL_MULT(50),
+	PLL_MULT(51),
+	PLL_MULT(52),
+	PLL_MULT(53),
+	PLL_MULT(54),
+	PLL_MULT(55),
+	PLL_MULT(56),
+	PLL_MULT(57),
+	PLL_MULT(58),
+	PLL_MULT(59),
+	PLL_MULT(60),
+	PLL_MULT(61),
+	PLL_MULT(62),
 	{ /* sentinel */ },
 };
 
@@ -522,11 +610,6 @@ static struct clk_regmap gxbb_gp0_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_GP0_PLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = HHI_GP0_PLL_CNTL,
 			.shift   = 31,
@@ -544,6 +627,25 @@ static struct clk_regmap gxbb_gp0_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "gp0_pll_dco",
 		.ops = &meson_clk_pll_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&gxbb_gp0_prediv.hw
+		},
+		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
+static struct clk_regmap gxl_gp0_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_GP0_PLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = gxbb_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "gp0_prediv",
+		.ops = &clk_regmap_divider_ops,
 		.parent_data = &(const struct clk_parent_data) {
 			.fw_name = "xtal",
 		},
@@ -551,32 +653,32 @@ static struct clk_regmap gxbb_gp0_pll_dco = {
 	},
 };
 
-static const struct pll_params_table gxl_gp0_pll_params_table[] = {
-	PLL_PARAMS(42, 1),
-	PLL_PARAMS(43, 1),
-	PLL_PARAMS(44, 1),
-	PLL_PARAMS(45, 1),
-	PLL_PARAMS(46, 1),
-	PLL_PARAMS(47, 1),
-	PLL_PARAMS(48, 1),
-	PLL_PARAMS(49, 1),
-	PLL_PARAMS(50, 1),
-	PLL_PARAMS(51, 1),
-	PLL_PARAMS(52, 1),
-	PLL_PARAMS(53, 1),
-	PLL_PARAMS(54, 1),
-	PLL_PARAMS(55, 1),
-	PLL_PARAMS(56, 1),
-	PLL_PARAMS(57, 1),
-	PLL_PARAMS(58, 1),
-	PLL_PARAMS(59, 1),
-	PLL_PARAMS(60, 1),
-	PLL_PARAMS(61, 1),
-	PLL_PARAMS(62, 1),
-	PLL_PARAMS(63, 1),
-	PLL_PARAMS(64, 1),
-	PLL_PARAMS(65, 1),
-	PLL_PARAMS(66, 1),
+static const struct pll_mult_table gxl_gp0_pll_params_table[] = {
+	PLL_MULT(42),
+	PLL_MULT(43),
+	PLL_MULT(44),
+	PLL_MULT(45),
+	PLL_MULT(46),
+	PLL_MULT(47),
+	PLL_MULT(48),
+	PLL_MULT(49),
+	PLL_MULT(50),
+	PLL_MULT(51),
+	PLL_MULT(52),
+	PLL_MULT(53),
+	PLL_MULT(54),
+	PLL_MULT(55),
+	PLL_MULT(56),
+	PLL_MULT(57),
+	PLL_MULT(58),
+	PLL_MULT(59),
+	PLL_MULT(60),
+	PLL_MULT(61),
+	PLL_MULT(62),
+	PLL_MULT(63),
+	PLL_MULT(64),
+	PLL_MULT(65),
+	PLL_MULT(66),
 	{ /* sentinel */ },
 };
 
@@ -600,11 +702,6 @@ static struct clk_regmap gxl_gp0_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_GP0_PLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_GP0_PLL_CNTL1,
 			.shift   = 0,
@@ -627,10 +724,11 @@ static struct clk_regmap gxl_gp0_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "gp0_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&gxl_gp0_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -3006,11 +3104,15 @@ static struct clk_hw *gxbb_hw_clks[] = {
 	[CLKID_GEN_CLK_SEL]	    = &gxbb_gen_clk_sel.hw,
 	[CLKID_GEN_CLK_DIV]	    = &gxbb_gen_clk_div.hw,
 	[CLKID_GEN_CLK]		    = &gxbb_gen_clk.hw,
+	[CLKID_FIXED_PREDIV]	    = &gxbb_fixed_prediv.hw,
 	[CLKID_FIXED_PLL_DCO]	    = &gxbb_fixed_pll_dco.hw,
+	[CLKID_HDMI_PREDIV]	    = &gxbb_hdmi_prediv.hw,
 	[CLKID_HDMI_PLL_DCO]	    = &gxbb_hdmi_pll_dco.hw,
 	[CLKID_HDMI_PLL_OD]	    = &gxbb_hdmi_pll_od.hw,
 	[CLKID_HDMI_PLL_OD2]	    = &gxbb_hdmi_pll_od2.hw,
+	[CLKID_SYS_PREDIV]	    = &gxbb_sys_prediv.hw,
 	[CLKID_SYS_PLL_DCO]	    = &gxbb_sys_pll_dco.hw,
+	[CLKID_GP0_PREDIV]	    = &gxbb_gp0_prediv.hw,
 	[CLKID_GP0_PLL_DCO]	    = &gxbb_gp0_pll_dco.hw,
 	[CLKID_VID_PLL_DIV]	    = &gxbb_vid_pll_div.hw,
 	[CLKID_VID_PLL_SEL]	    = &gxbb_vid_pll_sel.hw,
@@ -3213,11 +3315,15 @@ static struct clk_hw *gxl_hw_clks[] = {
 	[CLKID_GEN_CLK_SEL]	    = &gxbb_gen_clk_sel.hw,
 	[CLKID_GEN_CLK_DIV]	    = &gxbb_gen_clk_div.hw,
 	[CLKID_GEN_CLK]		    = &gxbb_gen_clk.hw,
+	[CLKID_FIXED_PREDIV]	    = &gxbb_fixed_prediv.hw,
 	[CLKID_FIXED_PLL_DCO]	    = &gxbb_fixed_pll_dco.hw,
+	[CLKID_HDMI_PREDIV]	    = &gxl_hdmi_prediv.hw,
 	[CLKID_HDMI_PLL_DCO]	    = &gxl_hdmi_pll_dco.hw,
 	[CLKID_HDMI_PLL_OD]	    = &gxl_hdmi_pll_od.hw,
 	[CLKID_HDMI_PLL_OD2]	    = &gxl_hdmi_pll_od2.hw,
+	[CLKID_SYS_PREDIV]	    = &gxbb_sys_prediv.hw,
 	[CLKID_SYS_PLL_DCO]	    = &gxbb_sys_pll_dco.hw,
+	[CLKID_GP0_PREDIV]	    = &gxl_gp0_prediv.hw,
 	[CLKID_GP0_PLL_DCO]	    = &gxl_gp0_pll_dco.hw,
 	[CLKID_VID_PLL_DIV]	    = &gxbb_vid_pll_div.hw,
 	[CLKID_VID_PLL_SEL]	    = &gxbb_vid_pll_sel.hw,
diff --git a/drivers/clk/meson/meson8-ddr.c b/drivers/clk/meson/meson8-ddr.c
index 0f93774f7371..a3f4c47982d9 100644
--- a/drivers/clk/meson/meson8-ddr.c
+++ b/drivers/clk/meson/meson8-ddr.c
@@ -23,6 +23,35 @@
 #define DDR_CLK_CNTL			0x18
 #define DDR_CLK_STS			0x1c
 
+/* Keep the pre-divider at 1 to achieve the best PLL performance. */
+static const struct clk_div_table meson8_ddr_prediv_div_table[] = {
+	{ .val = 1, .div = 1 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap meson8_ddr_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = AM_DDR_PLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = meson8_ddr_prediv_div_table,
+		/*
+		 * The PLL pre-divider have a zero value after reset,
+		 * which does not produce a usable clock. Use
+		 * CLK_DIVIDER_INVALID_ZERO to report this state correctly.
+		 */
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "ddr_prediv",
+		.ops = &clk_regmap_divider_ro_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap meson8_ddr_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -35,11 +64,6 @@ static struct clk_regmap meson8_ddr_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = AM_DDR_PLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = AM_DDR_PLL_CNTL,
 			.shift   = 31,
@@ -54,8 +78,8 @@ static struct clk_regmap meson8_ddr_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "ddr_pll_dco",
 		.ops = &meson_clk_pll_ro_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
+		.parent_hws = (const struct clk_hw *[]) {
+			&meson8_ddr_prediv.hw
 		},
 		.num_parents = 1,
 	},
@@ -79,6 +103,7 @@ static struct clk_regmap meson8_ddr_pll = {
 };
 
 static struct clk_hw *meson8_ddr_hw_clks[] = {
+	[DDR_CLKID_DDR_PREDIV]		= &meson8_ddr_prediv.hw,
 	[DDR_CLKID_DDR_PLL_DCO]		= &meson8_ddr_pll_dco.hw,
 	[DDR_CLKID_DDR_PLL]		= &meson8_ddr_pll.hw,
 };
diff --git a/drivers/clk/meson/meson8b.c b/drivers/clk/meson/meson8b.c
index bc029c6ab622..0c9ba079bc51 100644
--- a/drivers/clk/meson/meson8b.c
+++ b/drivers/clk/meson/meson8b.c
@@ -95,30 +95,61 @@ struct meson8b_clk_reset {
 	struct regmap *regmap;
 };
 
-static const struct pll_params_table sys_pll_params_table[] = {
-	PLL_PARAMS(50, 1),
-	PLL_PARAMS(51, 1),
-	PLL_PARAMS(52, 1),
-	PLL_PARAMS(53, 1),
-	PLL_PARAMS(54, 1),
-	PLL_PARAMS(55, 1),
-	PLL_PARAMS(56, 1),
-	PLL_PARAMS(57, 1),
-	PLL_PARAMS(58, 1),
-	PLL_PARAMS(59, 1),
-	PLL_PARAMS(60, 1),
-	PLL_PARAMS(61, 1),
-	PLL_PARAMS(62, 1),
-	PLL_PARAMS(63, 1),
-	PLL_PARAMS(64, 1),
-	PLL_PARAMS(65, 1),
-	PLL_PARAMS(66, 1),
-	PLL_PARAMS(67, 1),
-	PLL_PARAMS(68, 1),
-	PLL_PARAMS(84, 1),
+static const struct pll_mult_table sys_pll_params_table[] = {
+	PLL_MULT(50),
+	PLL_MULT(51),
+	PLL_MULT(52),
+	PLL_MULT(53),
+	PLL_MULT(54),
+	PLL_MULT(55),
+	PLL_MULT(56),
+	PLL_MULT(57),
+	PLL_MULT(58),
+	PLL_MULT(59),
+	PLL_MULT(60),
+	PLL_MULT(61),
+	PLL_MULT(62),
+	PLL_MULT(63),
+	PLL_MULT(64),
+	PLL_MULT(65),
+	PLL_MULT(66),
+	PLL_MULT(67),
+	PLL_MULT(68),
+	PLL_MULT(84),
 	{ /* sentinel */ },
 };
 
+static const struct clk_div_table meson8b_fixed_prediv_div_table[] = {
+	{ .val = 4, .div = 4 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap meson8b_fixed_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_MPLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = meson8b_fixed_prediv_div_table,
+		/*
+		 * The PLL pre-divider have a zero value after reset,
+		 * which does not produce a usable clock. Use
+		 * CLK_DIVIDER_INVALID_ZERO to report this state correctly.
+		 * The pre-dividers below use this flag for the same reason.
+		 */
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "fixed_prediv",
+		.ops = &clk_regmap_divider_ro_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+			.name = "xtal",
+			.index = -1,
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap meson8b_fixed_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -131,11 +162,6 @@ static struct clk_regmap meson8b_fixed_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_MPLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_MPLL_CNTL2,
 			.shift   = 0,
@@ -155,10 +181,8 @@ static struct clk_regmap meson8b_fixed_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "fixed_pll_dco",
 		.ops = &meson_clk_pll_ro_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
-			.name = "xtal",
-			.index = -1,
+		.parent_hws = (const struct clk_hw *[]) {
+			&meson8b_fixed_prediv.hw
 		},
 		.num_parents = 1,
 	},
@@ -185,15 +209,38 @@ static struct clk_regmap meson8b_fixed_pll = {
 	},
 };
 
+static const struct clk_div_table meson8b_prediv_div_table[] = {
+	{ .val = 1, .div = 1 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap meson8b_hdmi_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_VID_PLL_CNTL,
+		.shift   = 10,
+		.width   = 5,
+		.table = meson8b_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "hdmi_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+			.index = -1,
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_fixed_factor hdmi_pll_dco_in = {
 	.mult = 2,
 	.div = 1,
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll_dco_in",
 		.ops = &clk_fixed_factor_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
-			.index = -1,
+		.parent_hws = (const struct clk_hw *[]) {
+			&meson8b_hdmi_prediv.hw
 		},
 		.num_parents = 1,
 	},
@@ -214,24 +261,24 @@ static const struct reg_sequence meson8b_hdmi_pll_init_regs[] = {
 	{ .reg = HHI_VID2_PLL_CNTL2,	.def = 0x0430a800 },
 };
 
-static const struct pll_params_table meson8b_hdmi_pll_params_table[] = {
-	PLL_PARAMS(40, 1),
-	PLL_PARAMS(42, 1),
-	PLL_PARAMS(44, 1),
-	PLL_PARAMS(45, 1),
-	PLL_PARAMS(49, 1),
-	PLL_PARAMS(52, 1),
-	PLL_PARAMS(54, 1),
-	PLL_PARAMS(56, 1),
-	PLL_PARAMS(59, 1),
-	PLL_PARAMS(60, 1),
-	PLL_PARAMS(61, 1),
-	PLL_PARAMS(62, 1),
-	PLL_PARAMS(64, 1),
-	PLL_PARAMS(66, 1),
-	PLL_PARAMS(68, 1),
-	PLL_PARAMS(71, 1),
-	PLL_PARAMS(82, 1),
+static const struct pll_mult_table meson8b_hdmi_pll_params_table[] = {
+	PLL_MULT(40),
+	PLL_MULT(42),
+	PLL_MULT(44),
+	PLL_MULT(45),
+	PLL_MULT(49),
+	PLL_MULT(52),
+	PLL_MULT(54),
+	PLL_MULT(56),
+	PLL_MULT(59),
+	PLL_MULT(60),
+	PLL_MULT(61),
+	PLL_MULT(62),
+	PLL_MULT(64),
+	PLL_MULT(66),
+	PLL_MULT(68),
+	PLL_MULT(71),
+	PLL_MULT(82),
 	{ /* sentinel */ }
 };
 
@@ -247,11 +294,6 @@ static struct clk_regmap meson8b_hdmi_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_VID_PLL_CNTL,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HHI_VID_PLL_CNTL2,
 			.shift   = 0,
@@ -279,6 +321,7 @@ static struct clk_regmap meson8b_hdmi_pll_dco = {
 			&hdmi_pll_dco_in.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -318,6 +361,26 @@ static struct clk_regmap meson8b_hdmi_pll_hdmi_out = {
 	},
 };
 
+static struct clk_regmap meson8b_sys_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_SYS_PLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = meson8b_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "sys_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+			.name = "xtal",
+			.index = -1,
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap meson8b_sys_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -330,11 +393,6 @@ static struct clk_regmap meson8b_sys_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_SYS_PLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = HHI_SYS_PLL_CNTL,
 			.shift   = 31,
@@ -350,12 +408,11 @@ static struct clk_regmap meson8b_sys_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "sys_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
-			.name = "xtal",
-			.index = -1,
+		.parent_hws = (const struct clk_hw *[]) {
+			&meson8b_sys_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -2035,6 +2092,31 @@ static struct clk_regmap meson8b_mali = {
 	},
 };
 
+static const struct clk_div_table meson8b_gp_prediv_div_table[] = {
+	{ .val = 3, .div = 3 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap meson8m2_gp_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HHI_GP_PLL_CNTL,
+		.shift   = 9,
+		.width   = 5,
+		.table = meson8b_gp_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "gp_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "xtal",
+			.name = "xtal",
+			.index = -1,
+		},
+		.num_parents = 1,
+	},
+};
+
 static const struct reg_sequence meson8m2_gp_pll_init_regs[] = {
 	{ .reg = HHI_GP_PLL_CNTL2,	.def = 0x59c88000 },
 	{ .reg = HHI_GP_PLL_CNTL3,	.def = 0xca463823 },
@@ -2042,8 +2124,8 @@ static const struct reg_sequence meson8m2_gp_pll_init_regs[] = {
 	{ .reg = HHI_GP_PLL_CNTL5,	.def = 0x00003000 },
 };
 
-static const struct pll_params_table meson8m2_gp_pll_params_table[] = {
-	PLL_PARAMS(182, 3),
+static const struct pll_mult_table meson8m2_gp_pll_params_table[] = {
+	PLL_MULT(182),
 	{ /* sentinel */ },
 };
 
@@ -2059,11 +2141,6 @@ static struct clk_regmap meson8m2_gp_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HHI_GP_PLL_CNTL,
-			.shift   = 9,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = HHI_GP_PLL_CNTL,
 			.shift   = 31,
@@ -2081,12 +2158,11 @@ static struct clk_regmap meson8m2_gp_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "gp_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "xtal",
-			.name = "xtal",
-			.index = -1,
+		.parent_hws = (const struct clk_hw *[]) {
+			&meson8m2_gp_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -2920,8 +2996,11 @@ static struct clk_hw *meson8_hw_clks[] = {
 	[CLKID_NAND_SEL]	    = &meson8b_nand_clk_sel.hw,
 	[CLKID_NAND_DIV]	    = &meson8b_nand_clk_div.hw,
 	[CLKID_NAND_CLK]	    = &meson8b_nand_clk.hw,
+	[CLKID_PLL_FIXED_PREDIV]    = &meson8b_fixed_prediv.hw,
 	[CLKID_PLL_FIXED_DCO]	    = &meson8b_fixed_pll_dco.hw,
+	[CLKID_HDMI_PREDIV]	    = &meson8b_hdmi_prediv.hw,
 	[CLKID_HDMI_PLL_DCO]	    = &meson8b_hdmi_pll_dco.hw,
+	[CLKID_PLL_SYS_PREDIV]	    = &meson8b_sys_prediv.hw,
 	[CLKID_PLL_SYS_DCO]	    = &meson8b_sys_pll_dco.hw,
 	[CLKID_CPU_CLK_DIV2]	    = &meson8b_cpu_clk_div2.hw,
 	[CLKID_CPU_CLK_DIV3]	    = &meson8b_cpu_clk_div3.hw,
@@ -3124,8 +3203,11 @@ static struct clk_hw *meson8b_hw_clks[] = {
 	[CLKID_NAND_SEL]	    = &meson8b_nand_clk_sel.hw,
 	[CLKID_NAND_DIV]	    = &meson8b_nand_clk_div.hw,
 	[CLKID_NAND_CLK]	    = &meson8b_nand_clk.hw,
+	[CLKID_PLL_FIXED_PREDIV]    = &meson8b_fixed_prediv.hw,
 	[CLKID_PLL_FIXED_DCO]	    = &meson8b_fixed_pll_dco.hw,
+	[CLKID_HDMI_PREDIV]	    = &meson8b_hdmi_prediv.hw,
 	[CLKID_HDMI_PLL_DCO]	    = &meson8b_hdmi_pll_dco.hw,
+	[CLKID_PLL_SYS_PREDIV]	    = &meson8b_sys_prediv.hw,
 	[CLKID_PLL_SYS_DCO]	    = &meson8b_sys_pll_dco.hw,
 	[CLKID_CPU_CLK_DIV2]	    = &meson8b_cpu_clk_div2.hw,
 	[CLKID_CPU_CLK_DIV3]	    = &meson8b_cpu_clk_div3.hw,
@@ -3339,8 +3421,11 @@ static struct clk_hw *meson8m2_hw_clks[] = {
 	[CLKID_NAND_SEL]	    = &meson8b_nand_clk_sel.hw,
 	[CLKID_NAND_DIV]	    = &meson8b_nand_clk_div.hw,
 	[CLKID_NAND_CLK]	    = &meson8b_nand_clk.hw,
+	[CLKID_PLL_FIXED_PREDIV]    = &meson8b_fixed_prediv.hw,
 	[CLKID_PLL_FIXED_DCO]	    = &meson8b_fixed_pll_dco.hw,
+	[CLKID_HDMI_PREDIV]	    = &meson8b_hdmi_prediv.hw,
 	[CLKID_HDMI_PLL_DCO]	    = &meson8b_hdmi_pll_dco.hw,
+	[CLKID_PLL_SYS_PREDIV]	    = &meson8b_sys_prediv.hw,
 	[CLKID_PLL_SYS_DCO]	    = &meson8b_sys_pll_dco.hw,
 	[CLKID_CPU_CLK_DIV2]	    = &meson8b_cpu_clk_div2.hw,
 	[CLKID_CPU_CLK_DIV3]	    = &meson8b_cpu_clk_div3.hw,
@@ -3410,6 +3495,7 @@ static struct clk_hw *meson8m2_hw_clks[] = {
 	[CLKID_MALI_1_DIV]	    = &meson8b_mali_1_div.hw,
 	[CLKID_MALI_1]		    = &meson8b_mali_1.hw,
 	[CLKID_MALI]		    = &meson8b_mali.hw,
+	[CLKID_GP_PREDIV]	    = &meson8m2_gp_prediv.hw,
 	[CLKID_GP_PLL_DCO]	    = &meson8m2_gp_pll_dco.hw,
 	[CLKID_GP_PLL]		    = &meson8m2_gp_pll.hw,
 	[CLKID_VPU_0_SEL]	    = &meson8m2_vpu_0_sel.hw,
diff --git a/drivers/clk/meson/s4-pll.c b/drivers/clk/meson/s4-pll.c
index 56ce6f566e53..6caa95887971 100644
--- a/drivers/clk/meson/s4-pll.c
+++ b/drivers/clk/meson/s4-pll.c
@@ -44,6 +44,12 @@
 #define ANACTRL_MPLL_CTRL8                         0x1a0
 #define ANACTRL_HDMIPLL_CTRL0                      0x1c0
 
+/* Keep the pre-divider at 1 to achieve the best PLL performance. */
+static const struct clk_div_table s4_prediv_div_table[] = {
+	{ .val = 1, .div = 1 },
+	{ /* sentinel */ }
+};
+
 /*
  * These clock are a fixed value (fixed_pll is 2GHz) that is initialized by ROMcode.
  * The chip was changed fixed pll for security reasons. Fixed PLL registers are not writable
@@ -51,6 +57,30 @@
  * Meanwhile, these clock won't ever change at runtime.
  * For the above reasons, we can only use ro_ops for fixed PLL related clocks.
  */
+static struct clk_regmap s4_fixed_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = ANACTRL_FIXPLL_CTRL0,
+		.shift   = 10,
+		.width   = 5,
+		.table = s4_prediv_div_table,
+		/*
+		 * The PLL pre-divider have a zero value after reset,
+		 * which does not produce a usable clock. Use
+		 * CLK_DIVIDER_INVALID_ZERO to report this state correctly.
+		 * The pre-dividers below use this flag for the same reason.
+		 */
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "fixed_prediv",
+		.ops = &clk_regmap_divider_ro_ops,
+		.parent_data = (const struct clk_parent_data []) {
+			{ .fw_name = "xtal", }
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap s4_fixed_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -68,11 +98,6 @@ static struct clk_regmap s4_fixed_pll_dco = {
 			.shift   = 0,
 			.width   = 17,
 		},
-		.n = {
-			.reg_off = ANACTRL_FIXPLL_CTRL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = ANACTRL_FIXPLL_CTRL0,
 			.shift   = 31,
@@ -87,10 +112,11 @@ static struct clk_regmap s4_fixed_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "fixed_pll_dco",
 		.ops = &meson_clk_pll_ro_ops,
-		.parent_data = (const struct clk_parent_data []) {
-			{ .fw_name = "xtal", }
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_fixed_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -273,6 +299,24 @@ static struct clk_regmap s4_fclk_div2p5 = {
 	},
 };
 
+static struct clk_regmap s4_gp0_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = ANACTRL_GP0PLL_CTRL0,
+		.shift   = 10,
+		.width   = 5,
+		.table = s4_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "gp0_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = (const struct clk_parent_data []) {
+			{ .fw_name = "xtal", }
+		},
+		.num_parents = 1,
+	},
+};
+
 static const struct pll_mult_range s4_gp0_pll_mult_range = {
 	.min = 125,
 	.max = 250,
@@ -302,11 +346,6 @@ static struct clk_regmap s4_gp0_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = ANACTRL_GP0PLL_CTRL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = ANACTRL_GP0PLL_CTRL0,
 			.shift   = 31,
@@ -324,10 +363,11 @@ static struct clk_regmap s4_gp0_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "gp0_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = (const struct clk_parent_data []) {
-			{ .fw_name = "xtal", }
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_gp0_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -350,6 +390,24 @@ static struct clk_regmap s4_gp0_pll = {
 	},
 };
 
+static struct clk_regmap s4_hifi_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = ANACTRL_HIFIPLL_CTRL0,
+		.shift   = 10,
+		.width   = 5,
+		.table = s4_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "hifi_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = (const struct clk_parent_data []) {
+			{ .fw_name = "xtal", }
+		},
+		.num_parents = 1,
+	},
+};
+
 /*
  * Internal hifi pll emulation configuration parameters
  */
@@ -373,11 +431,6 @@ static struct clk_regmap s4_hifi_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = ANACTRL_HIFIPLL_CTRL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = ANACTRL_HIFIPLL_CTRL1,
 			.shift   = 0,
@@ -402,10 +455,11 @@ static struct clk_regmap s4_hifi_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "hifi_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = (const struct clk_parent_data []) {
-			{ .fw_name = "xtal", }
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_hifi_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -428,6 +482,24 @@ static struct clk_regmap s4_hifi_pll = {
 	},
 };
 
+static struct clk_regmap s4_hdmi_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = ANACTRL_HDMIPLL_CTRL0,
+		.shift   = 10,
+		.width   = 5,
+		.table = s4_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "hdmi_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = (const struct clk_parent_data []) {
+			{ .fw_name = "xtal", }
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap s4_hdmi_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -440,11 +512,6 @@ static struct clk_regmap s4_hdmi_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = ANACTRL_HDMIPLL_CTRL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = ANACTRL_HDMIPLL_CTRL0,
 			.shift   = 31,
@@ -460,10 +527,11 @@ static struct clk_regmap s4_hdmi_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = (const struct clk_parent_data []) {
-			{ .fw_name = "xtal", }
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_hdmi_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -760,6 +828,7 @@ static struct clk_regmap s4_mpll3 = {
 
 /* Array of all clocks provided by this provider */
 static struct clk_hw *s4_pll_hw_clks[] = {
+	[CLKID_FIXED_PREDIV]		= &s4_fixed_prediv.hw,
 	[CLKID_FIXED_PLL_DCO]		= &s4_fixed_pll_dco.hw,
 	[CLKID_FIXED_PLL]		= &s4_fixed_pll.hw,
 	[CLKID_FCLK_DIV2_DIV]		= &s4_fclk_div2_div.hw,
@@ -774,10 +843,13 @@ static struct clk_hw *s4_pll_hw_clks[] = {
 	[CLKID_FCLK_DIV7]		= &s4_fclk_div7.hw,
 	[CLKID_FCLK_DIV2P5_DIV]		= &s4_fclk_div2p5_div.hw,
 	[CLKID_FCLK_DIV2P5]		= &s4_fclk_div2p5.hw,
+	[CLKID_GP0_PREDIV]		= &s4_gp0_prediv.hw,
 	[CLKID_GP0_PLL_DCO]		= &s4_gp0_pll_dco.hw,
 	[CLKID_GP0_PLL]			= &s4_gp0_pll.hw,
+	[CLKID_HIFI_PREDIV]		= &s4_hifi_prediv.hw,
 	[CLKID_HIFI_PLL_DCO]		= &s4_hifi_pll_dco.hw,
 	[CLKID_HIFI_PLL]		= &s4_hifi_pll.hw,
+	[CLKID_HDMI_PREDIV]		= &s4_hdmi_prediv.hw,
 	[CLKID_HDMI_PLL_DCO]		= &s4_hdmi_pll_dco.hw,
 	[CLKID_HDMI_PLL_OD]		= &s4_hdmi_pll_od.hw,
 	[CLKID_HDMI_PLL]		= &s4_hdmi_pll.hw,
diff --git a/drivers/clk/meson/t7-pll.c b/drivers/clk/meson/t7-pll.c
index 0a622f45fa36..28d563fcb1bd 100644
--- a/drivers/clk/meson/t7-pll.c
+++ b/drivers/clk/meson/t7-pll.c
@@ -71,6 +71,36 @@
 #define MCLK_PLL_CNTL4		0x10
 #define MCLK_PLL_STS		0x14
 
+/* Keep the pre-divider at 1 to achieve the best PLL performance. */
+static const struct clk_div_table t7_prediv_div_table[] = {
+	{ .val = 1, .div = 1 },
+	{ /* sentinel */ }
+};
+
+static struct clk_regmap t7_gp0_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = GP0PLL_CTRL0,
+		.shift = 10,
+		.width = 5,
+		.table = t7_prediv_div_table,
+		/*
+		 * The PLL pre-divider have a zero value after reset,
+		 * which does not produce a usable clock. Use
+		 * CLK_DIVIDER_INVALID_ZERO to report this state correctly.
+		 * The pre-dividers below use this flag for the same reason.
+		 */
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "gp0_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "in0",
+		},
+		.num_parents = 1,
+	},
+};
+
 static const struct pll_mult_range t7_media_pll_mult_range = {
 	.min = 125,
 	.max = 250,
@@ -97,11 +127,6 @@ static struct clk_regmap t7_gp0_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = GP0PLL_CTRL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = GP0PLL_STS,
 			.shift   = 31,
@@ -119,10 +144,11 @@ static struct clk_regmap t7_gp0_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "gp0_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "in0",
+		.parent_hws = (const struct clk_hw *[]) {
+			&t7_gp0_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -144,6 +170,24 @@ static struct clk_regmap t7_gp0_pll = {
 	},
 };
 
+static struct clk_regmap t7_gp1_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = GP1PLL_CTRL0,
+		.shift = 16,
+		.width = 5,
+		.table = t7_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "gp1_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "in0",
+		},
+		.num_parents = 1,
+	},
+};
+
 /*
  * Compared with GP0 PLL, GP1 PLL is a newly designed PLL with
  * a DCO range of 1.6GHz to 3.2GHz.
@@ -171,11 +215,6 @@ static struct clk_regmap t7_gp1_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = GP1PLL_CTRL0,
-			.shift   = 16,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = GP1PLL_STS,
 			.shift   = 31,
@@ -193,10 +232,11 @@ static struct clk_regmap t7_gp1_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "gp1_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "in0",
+		.parent_hws = (const struct clk_hw *[]) {
+			&t7_gp1_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -218,6 +258,24 @@ static struct clk_regmap t7_gp1_pll = {
 	},
 };
 
+static struct clk_regmap t7_hifi_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HIFIPLL_CTRL0,
+		.shift = 10,
+		.width = 5,
+		.table = t7_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "hifi_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "in0",
+		},
+		.num_parents = 1,
+	},
+};
+
 static const struct reg_sequence t7_hifi_init_regs[] = {
 	{ .reg = HIFIPLL_CTRL1, .def = 0x00000000 },
 	{ .reg = HIFIPLL_CTRL2, .def = 0x00000000 },
@@ -239,11 +297,6 @@ static struct clk_regmap t7_hifi_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = HIFIPLL_CTRL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.frac = {
 			.reg_off = HIFIPLL_CTRL1,
 			.shift   = 0,
@@ -267,10 +320,11 @@ static struct clk_regmap t7_hifi_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "hifi_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "in0",
+		.parent_hws = (const struct clk_hw *[]) {
+			&t7_hifi_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -292,6 +346,24 @@ static struct clk_regmap t7_hifi_pll = {
 	},
 };
 
+static struct clk_regmap t7_pcie_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = PCIEPLL_CTRL0,
+		.shift = 10,
+		.width = 5,
+		.table = t7_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "pcie_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "in0",
+		},
+		.num_parents = 1,
+	},
+};
+
 /*
  * The T7 PCIE PLL is fined tuned to deliver a very precise
  * 100MHz reference clock for the PCIe Analog PHY, and thus requires
@@ -324,11 +396,6 @@ static struct clk_regmap t7_pcie_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = PCIEPLL_CTRL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = PCIEPLL_CTRL0,
 			.shift   = 31,
@@ -345,10 +412,11 @@ static struct clk_regmap t7_pcie_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "pcie_pll_dco",
 		.ops = &meson_clk_pcie_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "in0",
+		.parent_hws = (const struct clk_hw *[]) {
+			&t7_pcie_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -624,6 +692,24 @@ static struct clk_regmap t7_mpll3 = {
 	},
 };
 
+static struct clk_regmap t7_hdmi_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = HDMIPLL_CTRL0,
+		.shift = 10,
+		.width = 5,
+		.table = t7_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "hdmi_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "in0",
+		},
+		.num_parents = 1,
+	},
+};
+
 static const struct reg_sequence t7_hdmi_init_regs[] = {
 	{ .reg = HDMIPLL_CTRL1, .def = 0x00000000 },
 	{ .reg = HDMIPLL_CTRL2, .def = 0x00000000 },
@@ -645,11 +731,6 @@ static struct clk_regmap t7_hdmi_pll_dco = {
 			.shift   = 0,
 			.width   = 9,
 		},
-		.n = {
-			.reg_off = HDMIPLL_CTRL0,
-			.shift   = 10,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = HDMIPLL_CTRL0,
 			.shift   = 31,
@@ -667,10 +748,11 @@ static struct clk_regmap t7_hdmi_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = (const struct clk_parent_data []) {
-			{ .fw_name = "in0", }
+		.parent_hws = (const struct clk_hw *[]) {
+			&t7_hdmi_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -722,6 +804,24 @@ static const struct reg_sequence t7_mclk_init_regs[] = {
 	{ .reg = MCLK_PLL_CNTL4, .def = 0x00180303 },
 };
 
+static struct clk_regmap t7_mclk_prediv = {
+	.data = &(struct clk_regmap_div_data){
+		.offset = MCLK_PLL_CNTL0,
+		.shift = 16,
+		.width = 5,
+		.table = t7_prediv_div_table,
+		.flags = CLK_DIVIDER_INVALID_ZERO,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "mclk_prediv",
+		.ops = &clk_regmap_divider_ops,
+		.parent_data = &(const struct clk_parent_data) {
+			.fw_name = "in0",
+		},
+		.num_parents = 1,
+	},
+};
+
 static struct clk_regmap t7_mclk_pll_dco = {
 	.data = &(struct meson_clk_pll_data){
 		.en = {
@@ -734,11 +834,6 @@ static struct clk_regmap t7_mclk_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
-		.n = {
-			.reg_off = MCLK_PLL_CNTL0,
-			.shift   = 16,
-			.width   = 5,
-		},
 		.l = {
 			.reg_off = MCLK_PLL_CNTL0,
 			.shift   = 31,
@@ -761,10 +856,11 @@ static struct clk_regmap t7_mclk_pll_dco = {
 	.hw.init = &(struct clk_init_data){
 		.name = "mclk_pll_dco",
 		.ops = &meson_clk_pll_ops,
-		.parent_data = &(const struct clk_parent_data) {
-			.fw_name = "in0",
+		.parent_hws = (const struct clk_hw *[]) {
+			&t7_mclk_prediv.hw
 		},
 		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
 	},
 };
 
@@ -939,21 +1035,25 @@ static struct clk_regmap t7_mclk_1 = {
 };
 
 static struct clk_hw *t7_gp0_hw_clks[] = {
+	[CLKID_GP0_PREDIV]		= &t7_gp0_prediv.hw,
 	[CLKID_GP0_PLL_DCO]		= &t7_gp0_pll_dco.hw,
 	[CLKID_GP0_PLL]			= &t7_gp0_pll.hw,
 };
 
 static struct clk_hw *t7_gp1_hw_clks[] = {
+	[CLKID_GP1_PREDIV]		= &t7_gp1_prediv.hw,
 	[CLKID_GP1_PLL_DCO]		= &t7_gp1_pll_dco.hw,
 	[CLKID_GP1_PLL]			= &t7_gp1_pll.hw,
 };
 
 static struct clk_hw *t7_hifi_hw_clks[] = {
+	[CLKID_HIFI_PREDIV]		= &t7_hifi_prediv.hw,
 	[CLKID_HIFI_PLL_DCO]		= &t7_hifi_pll_dco.hw,
 	[CLKID_HIFI_PLL]		= &t7_hifi_pll.hw,
 };
 
 static struct clk_hw *t7_pcie_hw_clks[] = {
+	[CLKID_PCIE_PREDIV]		= &t7_pcie_prediv.hw,
 	[CLKID_PCIE_PLL_DCO]		= &t7_pcie_pll_dco.hw,
 	[CLKID_PCIE_PLL_DCO_DIV2]	= &t7_pcie_pll_dco_div2.hw,
 	[CLKID_PCIE_PLL_OD]		= &t7_pcie_pll_od.hw,
@@ -973,12 +1073,14 @@ static struct clk_hw *t7_mpll_hw_clks[] = {
 };
 
 static struct clk_hw *t7_hdmi_hw_clks[] = {
+	[CLKID_HDMI_PREDIV]		= &t7_hdmi_prediv.hw,
 	[CLKID_HDMI_PLL_DCO]		= &t7_hdmi_pll_dco.hw,
 	[CLKID_HDMI_PLL_OD]		= &t7_hdmi_pll_od.hw,
 	[CLKID_HDMI_PLL]		= &t7_hdmi_pll.hw,
 };
 
 static struct clk_hw *t7_mclk_hw_clks[] = {
+	[CLKID_MCLK_PREDIV]		= &t7_mclk_prediv.hw,
 	[CLKID_MCLK_PLL_DCO]		= &t7_mclk_pll_dco.hw,
 	[CLKID_MCLK_PRE]		= &t7_mclk_pre_od.hw,
 	[CLKID_MCLK_PLL]		= &t7_mclk_pll.hw,

-- 
2.47.1

