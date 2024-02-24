From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 25 Feb 2024 00:56:10 +0800
Subject: [PATCH RFC 2/2] clk: hisilicon: add support for PLL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240225-pll-v1-2-fad6511479c6@outlook.com>
References: <20240225-pll-v1-0-fad6511479c6@outlook.com>
In-Reply-To: <20240225-pll-v1-0-fad6511479c6@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, 
 Igor Opaniuk <igor.opaniuk@foundries.io>, 
 Jorge Ramirez-Ortiz Gmail <jorge.ramirez.ortiz@gmail.com>, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708793775; l=8081;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=oWwFpaJNUWlczClxS/GMcg8U81/j+wConETIKYXB4HI=;
 b=SbAmG842lGDN06+28a5FjrBNA6W9Av+1wuA5R7l59KKOLImNzqhUCqtmNrevecQ1eX3Gu8hzz
 sS4jqFq9gcuCxPCYQuYRKv1fSEgwtN0uJ9SkY0DstM7eJQABvtDeHSy
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for PLL used by various HiSilicon SoCs

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/hisilicon/Makefile  |   2 +-
 drivers/clk/hisilicon/clk-pll.c | 171 ++++++++++++++++++++++++++++++++++++++++
 drivers/clk/hisilicon/clk.c     |  24 ++++++
 drivers/clk/hisilicon/clk.h     |  12 +++
 4 files changed, 208 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/hisilicon/Makefile b/drivers/clk/hisilicon/Makefile
index 2978e56cb876..5e4d54b4cdd3 100644
--- a/drivers/clk/hisilicon/Makefile
+++ b/drivers/clk/hisilicon/Makefile
@@ -3,7 +3,7 @@
 # Hisilicon Clock specific Makefile
 #
 
-obj-y	+= clk.o clkgate-separated.o clkdivider-hi6220.o clk-hisi-phase.o
+obj-y	+= clk.o clkgate-separated.o clkdivider-hi6220.o clk-hisi-phase.o clk-pll.o
 
 obj-$(CONFIG_ARCH_HI3xxx)	+= clk-hi3620.o
 obj-$(CONFIG_ARCH_HIP04)	+= clk-hip04.o
diff --git a/drivers/clk/hisilicon/clk-pll.c b/drivers/clk/hisilicon/clk-pll.c
new file mode 100644
index 000000000000..c5c07a65fcf4
--- /dev/null
+++ b/drivers/clk/hisilicon/clk-pll.c
@@ -0,0 +1,171 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * PLL driver for HiSilicon SoCs
+ *
+ * Copyright 2024 (c) Yang Xiwen <forbidden405@outlook.com>
+ */
+
+#include <linux/bitops.h>
+#include <linux/device.h>
+#include <linux/io.h>
+#include <linux/module.h>
+
+#include "clk.h"
+
+/* PLL has two conf regs in total */
+#define HISI_PLL_CFG(n)		((n) * 4)
+
+/* reg 0 definitions */
+#define HISI_PLL_FRAC		GENMASK(23, 0)
+#define HISI_PLL_POSTDIV1	GENMASK(26, 24)
+#define HISI_PLL_POSTDIV2	GENMASK(30, 28)
+
+/* reg 1 definitions */
+#define HISI_PLL_FBDIV		GENMASK(11, 0)
+#define HISI_PLL_REFDIV		GENMASK(17, 12)
+#define HISI_PLL_PD		BIT(20)
+#define HISI_PLL_FOUTVCOPD	BIT(21)
+#define HISI_PLL_FOUT4PHASEPD	BIT(22)
+#define HISI_PLL_FOUTPOSTDIVPD	BIT(23)
+#define HISI_PLL_DACPD		BIT(24)
+#define HISI_PLL_DSMPD		BIT(25)
+#define HISI_PLL_BYPASS		BIT(26)
+
+/*
+ * Datasheet said the maximum is 3.2GHz,
+ * but tests show it can be very high
+ *
+ * Leave some margin here (8 GHz should be fine)
+ */
+#define HISI_PLL_FOUTVCO_MAX_RATE	8000000000
+/* 800 MHz */
+#define HISI_PLL_FOUTVCO_MIN_RATE	800000000
+
+struct hisi_pll {
+	struct clk_hw	hw;
+	void __iomem	*base;
+	u8		postdiv1, postdiv2, refdiv;
+	u32		divisor;
+};
+
+#define to_hisi_pll(_hw) container_of(_hw, struct hisi_pll, hw)
+
+static int hisi_pll_prepare(struct clk_hw *hw)
+{
+	struct hisi_pll *pll = to_hisi_pll(hw);
+	u32 reg;
+
+	reg = readl(pll->base + HISI_PLL_CFG(0));
+	pll->postdiv1 = FIELD_GET(HISI_PLL_POSTDIV1, reg);
+	pll->postdiv2 = FIELD_GET(HISI_PLL_POSTDIV2, reg);
+	// We don't use frac, clear it
+	reg &= ~HISI_PLL_FRAC;
+	writel(reg, pll->base + HISI_PLL_CFG(0));
+
+	reg = readl(pll->base + HISI_PLL_CFG(1));
+	pll->refdiv = FIELD_GET(HISI_PLL_REFDIV, reg);
+
+	pll->divisor = pll->refdiv * pll->postdiv1 * pll->postdiv2;
+
+	// return -EINVAL if boot loader does not init PLL correctly
+	if (pll->divisor == 0) {
+		pr_err("%s: PLLs are not initialized by boot loader correctly!\n", __func__);
+		return -EINVAL;
+	}
+
+	return 0;
+}
+
+static int hisi_pll_set_rate(struct clk_hw *hw, ulong rate, ulong parent_rate)
+{
+	struct hisi_pll *pll = to_hisi_pll(hw);
+	u64 fbdiv = rate * pll->divisor;
+	u32 reg;
+
+	do_div(fbdiv, parent_rate);
+
+	reg = readl(pll->base + HISI_PLL_CFG(1));
+	reg &= ~HISI_PLL_FBDIV;
+	reg |= FIELD_PREP(HISI_PLL_FBDIV, fbdiv);
+	writel(reg, pll->base + HISI_PLL_CFG(1));
+
+	/* TODO: wait for PLL lock? */
+
+	return 0;
+}
+
+static int hisi_pll_determine_rate(struct clk_hw *hw, struct clk_rate_request *req)
+{
+	struct hisi_pll *pll = to_hisi_pll(hw);
+	u64 vco, ref_rate = req->best_parent_rate;
+
+	if (ref_rate == 0)
+		return -EINVAL;
+
+	do_div(ref_rate, pll->refdiv);
+	vco = clamp(req->rate * (pll->postdiv1 * pll->postdiv2),
+		    HISI_PLL_FOUTVCO_MIN_RATE, HISI_PLL_FOUTVCO_MAX_RATE);
+	vco = rounddown(vco, ref_rate);
+	if (vco < HISI_PLL_FOUTVCO_MIN_RATE)
+		vco += ref_rate;
+
+	do_div(vco, pll->postdiv1 * pll->postdiv2);
+	req->rate = vco;
+
+	return 0;
+}
+
+static ulong hisi_pll_recalc_rate(struct clk_hw *hw, ulong parent_rate)
+{
+	struct hisi_pll *pll = to_hisi_pll(hw);
+	u32 reg, fbdiv;
+
+	reg = readl(pll->base + HISI_PLL_CFG(1));
+	fbdiv = FIELD_GET(HISI_PLL_FBDIV, reg);
+	parent_rate *= fbdiv;
+	do_div(parent_rate, pll->divisor);
+
+	return parent_rate;
+}
+
+static const struct clk_ops hisi_pll_ops = {
+	.prepare	= hisi_pll_prepare,
+	.set_rate	= hisi_pll_set_rate,
+	.determine_rate	= hisi_pll_determine_rate,
+	.recalc_rate	= hisi_pll_recalc_rate,
+};
+
+/*
+ * devm_hisi_pll_register - register a HiSilicon PLL
+ *
+ * @dev: clk provider
+ * @name: clock name
+ * @parent_name: parent clock, usually 24MHz OSC
+ * #flags: CCF common flags
+ * @reg: register address
+ */
+struct clk *devm_clk_register_hisi_pll(struct device *dev, const char *name, const char *parent,
+				       unsigned int flags, void __iomem *reg)
+{
+	struct hisi_pll *pll;
+	struct clk_init_data init;
+
+	pll = devm_kzalloc(dev, sizeof(*pll), GFP_KERNEL);
+	if (!pll)
+		return ERR_PTR(-ENOMEM);
+
+	if (!parent)
+		return ERR_PTR(-EINVAL);
+
+	init.name = name;
+	init.ops = &hisi_pll_ops;
+	init.flags = flags;
+	init.parent_names = &parent;
+	init.num_parents = 1;
+
+	pll->base = reg;
+	pll->hw.init = &init;
+
+	return devm_clk_register(dev, &pll->hw);
+}
+EXPORT_SYMBOL_GPL(devm_clk_register_hisi_pll);
diff --git a/drivers/clk/hisilicon/clk.c b/drivers/clk/hisilicon/clk.c
index 09368fd32bef..0e9b0f13b494 100644
--- a/drivers/clk/hisilicon/clk.c
+++ b/drivers/clk/hisilicon/clk.c
@@ -341,3 +341,27 @@ void __init hi6220_clk_register_divider(const struct hi6220_divider_clock *clks,
 		data->clk_data.clks[clks[i].id] = clk;
 	}
 }
+
+int hisi_clk_register_pll(struct device *dev, const struct hisi_pll_clock *clks,
+			  int nums, struct hisi_clock_data *data)
+{
+	struct clk *clk;
+	void __iomem *base = data->base;
+	int i;
+
+	for (i = 0; i < nums; i++) {
+		clk = devm_clk_register_hisi_pll(dev, clks[i].name, clks[i].parent_name,
+						 clks[i].flags, base + clks[i].offset);
+		if (IS_ERR(clk)) {
+			pr_err("%s: failed to register clock %s\n",
+			       __func__, clks[i].name);
+			return PTR_ERR(clk);
+		}
+
+
+		data->clk_data.clks[clks[i].id] = clk;
+	}
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(hisi_clk_register_pll);
diff --git a/drivers/clk/hisilicon/clk.h b/drivers/clk/hisilicon/clk.h
index 7a9b42e1b027..8c59f3927152 100644
--- a/drivers/clk/hisilicon/clk.h
+++ b/drivers/clk/hisilicon/clk.h
@@ -103,6 +103,14 @@ struct hisi_gate_clock {
 	const char		*alias;
 };
 
+struct hisi_pll_clock {
+	unsigned int		id;
+	const char		*name;
+	const char		*parent_name;
+	unsigned long		flags;
+	unsigned long		offset;
+};
+
 struct clk *hisi_register_clkgate_sep(struct device *, const char *,
 				const char *, unsigned long,
 				void __iomem *, u8,
@@ -122,6 +130,8 @@ int hisi_clk_register_mux(const struct hisi_mux_clock *, int,
 struct clk *clk_register_hisi_phase(struct device *dev,
 				const struct hisi_phase_clock *clks,
 				void __iomem *base, spinlock_t *lock);
+struct clk *devm_clk_register_hisi_pll(struct device *dev, const char *name, const char *parent,
+				       unsigned int flags, void __iomem *reg);
 int hisi_clk_register_phase(struct device *dev,
 				const struct hisi_phase_clock *clks,
 				int nums, struct hisi_clock_data *data);
@@ -133,6 +143,8 @@ void hisi_clk_register_gate_sep(const struct hisi_gate_clock *,
 				int, struct hisi_clock_data *);
 void hi6220_clk_register_divider(const struct hi6220_divider_clock *,
 				int, struct hisi_clock_data *);
+int hisi_clk_register_pll(struct device *dev, const struct hisi_pll_clock *clks,
+			  int nums, struct hisi_clock_data *data);
 
 #define hisi_clk_unregister(type) \
 static inline \

-- 
2.43.0

