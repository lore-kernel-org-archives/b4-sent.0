From: Chuan Liu <chuan.liu@amlogic.com>
Date: Mon, 09 Feb 2026 13:48:51 +0800
Subject: [PATCH 05/13] clk: amlogic: Add composite clock driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260209-a9_clock_driver-v1-5-a9198dc03d2a@amlogic.com>
References: <20260209-a9_clock_driver-v1-0-a9198dc03d2a@amlogic.com>
In-Reply-To: <20260209-a9_clock_driver-v1-0-a9198dc03d2a@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770616142; l=11745;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=TWWc+aiQqxihQg4vOjeQkVQxeCur6RMBVynIc8iopYo=;
 b=LNPPiCONB2hgxdPaHHpq2DgNzZgblos66T+EqeLDCwcYk7iU89TnQ/okG4bo8eeSjsgxjf7NO
 nA0Jw0+vCd3AIY1zLhReQmvd6osJODjnvPgBLzTXkXgy3v6MJzAJEkr
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement clk_ops support for Amlogic composite clocks. Composite clocks
are commonly used clock control units in Amlogic SoCs that integrate
multiplexer, divider, and gate functionality into a single block.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/amlogic/Makefile        |   1 +
 drivers/clk/amlogic/clk-composite.c | 280 ++++++++++++++++++++++++++++++++++++
 drivers/clk/amlogic/clk-composite.h |  20 +++
 drivers/clk/amlogic/clk.c           |   7 +
 drivers/clk/amlogic/clk.h           |   1 +
 5 files changed, 309 insertions(+)

diff --git a/drivers/clk/amlogic/Makefile b/drivers/clk/amlogic/Makefile
index bd9dd5b78b23..58a5e7bc8993 100644
--- a/drivers/clk/amlogic/Makefile
+++ b/drivers/clk/amlogic/Makefile
@@ -4,3 +4,4 @@ obj-$(CONFIG_COMMON_CLK_AMLOGIC) += clk-amlogic.o
 
 clk-amlogic-y += clk.o
 clk-amlogic-y += clk-basic.o
+clk-amlogic-y += clk-composite.o
diff --git a/drivers/clk/amlogic/clk-composite.c b/drivers/clk/amlogic/clk-composite.c
new file mode 100644
index 000000000000..9d34ed4a90b7
--- /dev/null
+++ b/drivers/clk/amlogic/clk-composite.c
@@ -0,0 +1,280 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+/*
+ * Copyright (c) 2026 Amlogic, Inc. All rights reserved
+ */
+
+#include <linux/err.h>
+#include <linux/module.h>
+
+#include "clk.h"
+#include "clk-composite.h"
+
+/*
+ * Amlogic composite clock module:
+ *
+ *             mux       div         gate
+ *              |         |            |
+ *         +----|---------|------------|------+
+ *         |   \|/        |            |      |
+ *         |   |\         |            |      |
+ * clk0 ------>| |        |            |      |
+ * clk1 ------>| |        |            |      |
+ * clk2 ------>| |       \|/          \|/     |
+ * clk3 ------>| |     +-----+     +------+   |
+ *         |   | |---->| div |---->| gate |------> clk out
+ * clk4 ------>| |     +-----+     +------+   |
+ * clk5 ------>| |                            |
+ * clk6 ------>| |                            |
+ * clk7 ------>| |                            |
+ *         |   |/                             |
+ *         |                                  |
+ *         +----------------------------------+
+ *
+ * Amlogic composite clocks support up to 8 clock sources, and the divider width
+ * is configurable.
+ *
+ * The register bit-field allocation rules for mux, div, and gate are as
+ * follows:
+ * mux: bit[11:9] or bit[27:25]
+ * div: bit[7:0] or bit[23:16]
+ * gate: bit[8] or bit[24]
+ */
+
+#define CLK_COMPOSITE_MUX_SHIFT		9
+#define CLK_COMPOSITE_MUX_MASK		0x7
+
+#define CLK_COMPOSITE_DIV_SHIFT		0
+
+#define CLK_COMPOSITE_GATE_SHIFT		8
+
+static u8 aml_clk_composite_get_parent(struct clk_hw *hw)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_composite_data *composite = clk->data;
+	unsigned int val;
+	int ret;
+
+	ret = regmap_read(clk->map, composite->reg_offset, &val);
+	if (ret)
+		return ret;
+
+	val >>=  CLK_COMPOSITE_MUX_SHIFT;
+	val &= CLK_COMPOSITE_MUX_MASK;
+
+	return clk_mux_val_to_index(hw, composite->table, 0, val);
+}
+
+static int aml_clk_composite_set_parent(struct clk_hw *hw, u8 index)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_composite_data *composite = clk->data;
+	unsigned int val = clk_mux_index_to_val(composite->table, 0, index);
+	int mux_shift = composite->bit_offset + CLK_COMPOSITE_MUX_SHIFT;
+
+	return regmap_update_bits(clk->map, composite->reg_offset,
+				  CLK_COMPOSITE_MUX_MASK << mux_shift,
+				  val << mux_shift);
+}
+
+static unsigned long aml_clk_composite_recalc_rate(struct clk_hw *hw,
+						   unsigned long parent_rate)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_composite_data *composite = clk->data;
+	unsigned int val;
+	int ret;
+
+	ret = regmap_read(clk->map, composite->reg_offset, &val);
+	if (ret)
+		/* Gives a hint that something is wrong */
+		return 0;
+
+	val >>= composite->bit_offset + CLK_COMPOSITE_DIV_SHIFT;
+	val &= clk_div_mask(composite->div_width);
+
+	return divider_recalc_rate(hw, parent_rate, val, NULL, 0,
+				   composite->div_width);
+}
+
+static int
+aml_clk_composite_determine_rate_for_parent(struct clk_hw *rate_hw,
+					    struct clk_rate_request *req,
+					    struct clk_hw *parent_hw)
+{
+	struct aml_clk *clk = to_aml_clk(rate_hw);
+	struct aml_clk_composite_data *composite = clk->data;
+
+	req->best_parent_hw = parent_hw;
+	req->best_parent_rate = clk_hw_get_rate(parent_hw);
+
+	return divider_determine_rate(rate_hw, req, NULL,
+				      composite->div_width, 0);
+}
+
+static int aml_clk_composite_determine_rate(struct clk_hw *hw,
+					    struct clk_rate_request *req)
+{
+	struct clk_hw *parent;
+	struct clk_rate_request tmp_req;
+	unsigned long rate_diff;
+	unsigned long best_rate_diff = ULONG_MAX;
+	unsigned long best_rate = 0;
+	int i, ret;
+
+	req->best_parent_hw = NULL;
+
+	parent = clk_hw_get_parent(hw);
+	clk_hw_forward_rate_request(hw, req, parent, &tmp_req, req->rate);
+	ret = aml_clk_composite_determine_rate_for_parent(hw, &tmp_req,
+							  parent);
+	if (ret)
+		return ret;
+
+	/*
+	 * Check if rate can be satisfied by current parent clock. Avoid parent
+	 * switching when possible to reduce glitches.
+	 */
+	if (req->rate == tmp_req.rate ||
+	    (clk_hw_get_flags(hw) & CLK_SET_RATE_NO_REPARENT)) {
+		req->rate = tmp_req.rate;
+		req->best_parent_hw = tmp_req.best_parent_hw;
+		req->best_parent_rate = tmp_req.best_parent_rate;
+
+		return 0;
+	}
+
+	for (i = 0; i < clk_hw_get_num_parents(hw); i++) {
+		parent = clk_hw_get_parent_by_index(hw, i);
+		if (!parent)
+			continue;
+
+		clk_hw_forward_rate_request(hw, req, parent, &tmp_req,
+					    req->rate);
+		ret = aml_clk_composite_determine_rate_for_parent(hw, &tmp_req,
+								  parent);
+		if (ret)
+			continue;
+
+		if (req->rate >= tmp_req.rate)
+			rate_diff = req->rate - tmp_req.rate;
+		else
+			rate_diff = tmp_req.rate - req->rate;
+
+		if (!rate_diff || !req->best_parent_hw ||
+		    best_rate_diff > rate_diff) {
+			req->best_parent_hw = parent;
+			req->best_parent_rate = tmp_req.best_parent_rate;
+			best_rate_diff = rate_diff;
+			best_rate = tmp_req.rate;
+		}
+
+		if (!rate_diff)
+			return 0;
+	}
+
+	req->rate = best_rate;
+	return 0;
+}
+
+static int aml_clk_composite_set_rate(struct clk_hw *hw, unsigned long rate,
+				      unsigned long parent_rate)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_composite_data *composite = clk->data;
+	unsigned int val;
+	int ret;
+	int div_shift = composite->bit_offset + CLK_COMPOSITE_DIV_SHIFT;
+
+	ret = divider_get_val(rate, parent_rate, NULL, composite->div_width, 0);
+	if (ret < 0)
+		return ret;
+
+	val = (unsigned int)ret << div_shift;
+	return regmap_update_bits(clk->map, composite->reg_offset,
+				  clk_div_mask(composite->div_width) <<
+				  div_shift, val);
+}
+
+static int aml_clk_composite_set_rate_and_parent(struct clk_hw *hw,
+						 unsigned long rate,
+						 unsigned long parent_rate,
+						 u8 index)
+{
+	unsigned long temp_rate;
+
+	temp_rate = aml_clk_composite_recalc_rate(hw, parent_rate);
+	if (temp_rate > rate) {
+		aml_clk_composite_set_rate(hw, rate, parent_rate);
+		aml_clk_composite_set_parent(hw, index);
+	} else {
+		aml_clk_composite_set_parent(hw, index);
+		aml_clk_composite_set_rate(hw, rate, parent_rate);
+	}
+
+	return 0;
+}
+
+static int aml_clk_composite_is_enabled(struct clk_hw *hw)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_composite_data *composite = clk->data;
+	unsigned int val;
+
+	regmap_read(clk->map, composite->reg_offset, &val);
+	val &= BIT(composite->bit_offset + CLK_COMPOSITE_GATE_SHIFT);
+
+	return val ? 1 : 0;
+}
+
+static int aml_clk_composite_enable(struct clk_hw *hw)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_composite_data *composite = clk->data;
+	u8 bit_idx = composite->bit_offset + CLK_COMPOSITE_GATE_SHIFT;
+
+	return regmap_update_bits(clk->map, composite->reg_offset,
+				  BIT(bit_idx), BIT(bit_idx));
+}
+
+static void aml_clk_composite_disable(struct clk_hw *hw)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_composite_data *composite = clk->data;
+	u8 bit_idx = composite->bit_offset + CLK_COMPOSITE_GATE_SHIFT;
+
+	regmap_update_bits(clk->map, composite->reg_offset,
+			   BIT(bit_idx), 0);
+}
+
+#ifdef CONFIG_DEBUG_FS
+#include <linux/debugfs.h>
+
+static void aml_clk_composite_debug_init(struct clk_hw *hw,
+					 struct dentry *dentry)
+{
+	debugfs_create_file("clk_type", 0444, dentry, hw, &aml_clk_type_fops);
+	debugfs_create_file("clk_available_rates", 0444, dentry, hw,
+			    &aml_clk_div_available_rates_fops);
+}
+#endif /* CONFIG_DEBUG_FS */
+
+const struct clk_ops aml_clk_composite_ops = {
+	.get_parent = aml_clk_composite_get_parent,
+	.set_parent = aml_clk_composite_set_parent,
+	.determine_rate = aml_clk_composite_determine_rate,
+	.recalc_rate = aml_clk_composite_recalc_rate,
+	.set_rate = aml_clk_composite_set_rate,
+	.set_rate_and_parent = aml_clk_composite_set_rate_and_parent,
+	.enable = aml_clk_composite_enable,
+	.disable = aml_clk_composite_disable,
+	.is_enabled = aml_clk_composite_is_enabled,
+#ifdef CONFIG_DEBUG_FS
+	.debug_init = aml_clk_composite_debug_init,
+#endif /* CONFIG_DEBUG_FS */
+};
+EXPORT_SYMBOL_NS_GPL(aml_clk_composite_ops, "CLK_AMLOGIC");
+
+MODULE_DESCRIPTION("Amlogic Composite Clock Driver");
+MODULE_AUTHOR("Chuan Liu <chuan.liu@amlogic.com>");
+MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("CLK_AMLOGIC");
diff --git a/drivers/clk/amlogic/clk-composite.h b/drivers/clk/amlogic/clk-composite.h
new file mode 100644
index 000000000000..6a356d697b78
--- /dev/null
+++ b/drivers/clk/amlogic/clk-composite.h
@@ -0,0 +1,20 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2026 Amlogic, Inc. All rights reserved
+ */
+
+#ifndef __AML_CLK_COMPOSITE_H
+#define __AML_CLK_COMPOSITE_H
+
+#include <linux/clk-provider.h>
+
+struct aml_clk_composite_data {
+	unsigned int	reg_offset;
+	u8		bit_offset;
+	u8		div_width;
+	u32		*table;
+};
+
+extern const struct clk_ops aml_clk_composite_ops;
+
+#endif /* __AML_CLK_COMPOSITE_H */
diff --git a/drivers/clk/amlogic/clk.c b/drivers/clk/amlogic/clk.c
index 03ccfa78c511..e71dcb6b46b7 100644
--- a/drivers/clk/amlogic/clk.c
+++ b/drivers/clk/amlogic/clk.c
@@ -10,6 +10,7 @@
 
 #include "clk.h"
 #include "clk-basic.h"
+#include "clk-composite.h"
 
 static const struct {
 	unsigned int type;
@@ -19,6 +20,7 @@ static const struct {
 	ENTRY(AML_CLKTYPE_MUX),
 	ENTRY(AML_CLKTYPE_DIV),
 	ENTRY(AML_CLKTYPE_GATE),
+	ENTRY(AML_CLKTYPE_COMPOSITE),
 #undef ENTRY
 };
 
@@ -95,6 +97,11 @@ static int aml_clk_div_available_rates_show(struct seq_file *s, void *data)
 			div_flags = div->flags;
 			div_width = div->width;
 		}
+	} else if (clk->type == AML_CLKTYPE_COMPOSITE) {
+		struct aml_clk_composite_data *composite = clk->data;
+
+		div_val = (1 << composite->div_width) - 1;
+		div_width = composite->div_width;
 	} else {
 		pr_err("%s: Unsupported clock type\n", clk_hw_get_name(hw));
 		return -EINVAL;
diff --git a/drivers/clk/amlogic/clk.h b/drivers/clk/amlogic/clk.h
index ec0547c1354a..e5fe85c2969f 100644
--- a/drivers/clk/amlogic/clk.h
+++ b/drivers/clk/amlogic/clk.h
@@ -14,6 +14,7 @@ enum aml_clk_type {
 	AML_CLKTYPE_MUX		= 1,
 	AML_CLKTYPE_DIV		= 2,
 	AML_CLKTYPE_GATE	= 3,
+	AML_CLKTYPE_COMPOSITE	= 4,
 };
 
 struct aml_clk {

-- 
2.42.0

