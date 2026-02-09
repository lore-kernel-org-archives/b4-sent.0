From: Chuan Liu <chuan.liu@amlogic.com>
Date: Mon, 09 Feb 2026 13:48:50 +0800
Subject: [PATCH 04/13] clk: amlogic: Add basic clock driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260209-a9_clock_driver-v1-4-a9198dc03d2a@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770616142; l=15565;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=kmFP3lJrdEH0H25Aq+4LfHk+ypLv7d+G/FDfILS/pz8=;
 b=oEGZBOLzaZUMxMxvxbTFD+u0g2mgIFNwDgtYUeLFL1aan+7dtG3j5qkat9xV9GazeSxHDhYzD
 hV+IiYX3B8YCP/0vV/Whsnnndu9xVtfAxrcDIf3IMEXA/Tv0ZBwZMQL
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement core clock driver for Amlogic SoC platforms, supporting
fundamental clock types: mux (multiplexer), div (divider), and gate. The
Amlogic clock architecture heavily utilizes these basic building blocks
throughout its clock tree.

Features included:
- clk_ops implementations for all basic clock types
- Debugfs interface with two diagnostic nodes:
    * clk_type: displays clock type identifier
    * clk_available_rates: shows configurable frequency ranges

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/Kconfig             |   1 +
 drivers/clk/Makefile            |   1 +
 drivers/clk/amlogic/Kconfig     |  12 +++
 drivers/clk/amlogic/Makefile    |   6 ++
 drivers/clk/amlogic/clk-basic.c | 219 ++++++++++++++++++++++++++++++++++++++++
 drivers/clk/amlogic/clk-basic.h |  39 +++++++
 drivers/clk/amlogic/clk.c       | 142 ++++++++++++++++++++++++++
 drivers/clk/amlogic/clk.h       |  38 +++++++
 8 files changed, 458 insertions(+)

diff --git a/drivers/clk/Kconfig b/drivers/clk/Kconfig
index 3a1611008e48..57c13348e7a5 100644
--- a/drivers/clk/Kconfig
+++ b/drivers/clk/Kconfig
@@ -512,6 +512,7 @@ config COMMON_CLK_RPMI
 	  the RISC-V platform management interface (RPMI) specification.
 
 source "drivers/clk/actions/Kconfig"
+source "drivers/clk/amlogic/Kconfig"
 source "drivers/clk/analogbits/Kconfig"
 source "drivers/clk/baikal-t1/Kconfig"
 source "drivers/clk/bcm/Kconfig"
diff --git a/drivers/clk/Makefile b/drivers/clk/Makefile
index 61ec08404442..c667f22aa414 100644
--- a/drivers/clk/Makefile
+++ b/drivers/clk/Makefile
@@ -113,6 +113,7 @@ obj-$(CONFIG_COMMON_CLK_XGENE)		+= clk-xgene.o
 
 # please keep this section sorted lexicographically by directory path name
 obj-y					+= actions/
+obj-$(CONFIG_ARCH_MESON)		+= amlogic/
 obj-y					+= analogbits/
 obj-$(CONFIG_COMMON_CLK_AT91)		+= at91/
 obj-$(CONFIG_ARCH_ARTPEC)		+= axis/
diff --git a/drivers/clk/amlogic/Kconfig b/drivers/clk/amlogic/Kconfig
new file mode 100644
index 000000000000..216fe98a413b
--- /dev/null
+++ b/drivers/clk/amlogic/Kconfig
@@ -0,0 +1,12 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+
+config COMMON_CLK_AMLOGIC
+	tristate "Amlogic Common Clock"
+	depends on ARCH_MESON || COMPILE_TEST
+	depends on OF
+	default ARCH_MESON
+	select REGMAP
+	help
+	  This driver provides the basic clock infrastructure for Amlogic SoCs,
+	  offering read and write interfaces for various clock control units.
+	  Select Y if your target SoC needs clock driver support.
diff --git a/drivers/clk/amlogic/Makefile b/drivers/clk/amlogic/Makefile
new file mode 100644
index 000000000000..bd9dd5b78b23
--- /dev/null
+++ b/drivers/clk/amlogic/Makefile
@@ -0,0 +1,6 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+
+obj-$(CONFIG_COMMON_CLK_AMLOGIC) += clk-amlogic.o
+
+clk-amlogic-y += clk.o
+clk-amlogic-y += clk-basic.o
diff --git a/drivers/clk/amlogic/clk-basic.c b/drivers/clk/amlogic/clk-basic.c
new file mode 100644
index 000000000000..1d0d1bc7f24d
--- /dev/null
+++ b/drivers/clk/amlogic/clk-basic.c
@@ -0,0 +1,219 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+/*
+ * Copyright (c) 2026 Amlogic, Inc. All rights reserved
+ */
+
+#include <linux/err.h>
+#include <linux/module.h>
+
+#include "clk.h"
+#include "clk-basic.h"
+
+/*
+ * This file implements the ops functions for basic Amlogic clock models
+ * (mux/div/gate), based on clk-mux.c, clk-divider.c, and clk-gate.c in the CCF.
+ */
+
+static int aml_clk_gate_endisable(struct clk_hw *hw, int enable)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_gate_data *gate = clk->data;
+	int set = gate->flags & CLK_GATE_SET_TO_DISABLE ? 1 : 0;
+
+	set ^= enable;
+
+	return regmap_update_bits(clk->map, gate->reg_offset,
+				  BIT(gate->bit_idx),
+				  set ? BIT(gate->bit_idx) : 0);
+}
+
+static int aml_clk_gate_enable(struct clk_hw *hw)
+{
+	return aml_clk_gate_endisable(hw, 1);
+}
+
+static void aml_clk_gate_disable(struct clk_hw *hw)
+{
+	aml_clk_gate_endisable(hw, 0);
+}
+
+static int aml_clk_gate_is_enabled(struct clk_hw *hw)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_gate_data *gate = clk->data;
+	unsigned int val;
+
+	regmap_read(clk->map, gate->reg_offset, &val);
+	if (gate->flags & CLK_GATE_SET_TO_DISABLE)
+		val ^= BIT(gate->bit_idx);
+
+	val &= BIT(gate->bit_idx);
+
+	return val ? 1 : 0;
+}
+
+#ifdef CONFIG_DEBUG_FS
+#include <linux/debugfs.h>
+
+static void aml_clk_basic_debug_init(struct clk_hw *hw, struct dentry *dentry)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+
+	debugfs_create_file("clk_type", 0444, dentry, hw, &aml_clk_type_fops);
+	if (clk->type == AML_CLKTYPE_DIV)
+		debugfs_create_file("clk_available_rates", 0444, dentry, hw,
+				    &aml_clk_div_available_rates_fops);
+}
+#endif /* CONFIG_DEBUG_FS */
+
+const struct clk_ops aml_clk_gate_ops = {
+	.enable = aml_clk_gate_enable,
+	.disable = aml_clk_gate_disable,
+	.is_enabled = aml_clk_gate_is_enabled,
+#ifdef CONFIG_DEBUG_FS
+	.debug_init = aml_clk_basic_debug_init,
+#endif /* CONFIG_DEBUG_FS */
+};
+EXPORT_SYMBOL_NS_GPL(aml_clk_gate_ops, "CLK_AMLOGIC");
+
+static unsigned long aml_clk_div_recalc_rate(struct clk_hw *hw,
+					     unsigned long prate)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_divider_data *div = clk->data;
+	unsigned int val;
+	int ret;
+
+	ret = regmap_read(clk->map, div->reg_offset, &val);
+	if (ret)
+		/* Gives a hint that something is wrong */
+		return 0;
+
+	val >>= div->shift;
+	val &= clk_div_mask(div->width);
+
+	return divider_recalc_rate(hw, prate, val, div->table, div->flags,
+				   div->width);
+}
+
+static int aml_clk_div_determine_rate(struct clk_hw *hw,
+				      struct clk_rate_request *req)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_divider_data *div = clk->data;
+	unsigned int val;
+	int ret;
+
+	/* if read only, just return current value */
+	if (div->flags & CLK_DIVIDER_READ_ONLY) {
+		ret = regmap_read(clk->map, div->reg_offset, &val);
+		if (ret)
+			return ret;
+
+		val >>= div->shift;
+		val &= clk_div_mask(div->width);
+
+		return divider_ro_determine_rate(hw, req, div->table,
+						 div->width, div->flags, val);
+	}
+
+	return divider_determine_rate(hw, req, div->table, div->width,
+				      div->flags);
+}
+
+static int aml_clk_div_set_rate(struct clk_hw *hw, unsigned long rate,
+				unsigned long parent_rate)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_divider_data *div = clk->data;
+	unsigned int val;
+	int ret;
+
+	ret = divider_get_val(rate, parent_rate, div->table, div->width,
+			      div->flags);
+	if (ret < 0)
+		return ret;
+
+	val = (unsigned int)ret << div->shift;
+
+	return regmap_update_bits(clk->map, div->reg_offset,
+				  clk_div_mask(div->width) << div->shift, val);
+};
+
+const struct clk_ops aml_clk_divider_ops = {
+	.recalc_rate = aml_clk_div_recalc_rate,
+	.determine_rate = aml_clk_div_determine_rate,
+	.set_rate = aml_clk_div_set_rate,
+#ifdef CONFIG_DEBUG_FS
+	.debug_init = aml_clk_basic_debug_init,
+#endif /* CONFIG_DEBUG_FS */
+};
+EXPORT_SYMBOL_NS_GPL(aml_clk_divider_ops, "CLK_AMLOGIC");
+
+const struct clk_ops aml_clk_divider_ro_ops = {
+	.recalc_rate = aml_clk_div_recalc_rate,
+	.determine_rate = aml_clk_div_determine_rate,
+#ifdef CONFIG_DEBUG_FS
+	.debug_init = aml_clk_basic_debug_init,
+#endif /* CONFIG_DEBUG_FS */
+};
+EXPORT_SYMBOL_NS_GPL(aml_clk_divider_ro_ops, "CLK_AMLOGIC");
+
+static u8 aml_clk_mux_get_parent(struct clk_hw *hw)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_mux_data *mux = clk->data;
+	unsigned int val;
+	int ret;
+
+	ret = regmap_read(clk->map, mux->reg_offset, &val);
+	if (ret)
+		return ret;
+
+	val >>= mux->shift;
+	val &= mux->mask;
+	return clk_mux_val_to_index(hw, mux->table, mux->flags, val);
+}
+
+static int aml_clk_mux_set_parent(struct clk_hw *hw, u8 index)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_mux_data *mux = clk->data;
+	unsigned int val = clk_mux_index_to_val(mux->table, mux->flags, index);
+
+	return regmap_update_bits(clk->map, mux->reg_offset,
+				  mux->mask << mux->shift,
+				  val << mux->shift);
+}
+
+static int aml_clk_mux_determine_rate(struct clk_hw *hw,
+				      struct clk_rate_request *req)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_mux_data *mux = clk->data;
+
+	return clk_mux_determine_rate_flags(hw, req, mux->flags);
+}
+
+const struct clk_ops aml_clk_mux_ops = {
+	.get_parent = aml_clk_mux_get_parent,
+	.set_parent = aml_clk_mux_set_parent,
+	.determine_rate = aml_clk_mux_determine_rate,
+#ifdef CONFIG_DEBUG_FS
+	.debug_init = aml_clk_basic_debug_init,
+#endif /* CONFIG_DEBUG_FS */
+};
+EXPORT_SYMBOL_NS_GPL(aml_clk_mux_ops, "CLK_AMLOGIC");
+
+const struct clk_ops aml_clk_mux_ro_ops = {
+	.get_parent = aml_clk_mux_get_parent,
+#ifdef CONFIG_DEBUG_FS
+	.debug_init = aml_clk_basic_debug_init,
+#endif /* CONFIG_DEBUG_FS */
+};
+EXPORT_SYMBOL_NS_GPL(aml_clk_mux_ro_ops, "CLK_AMLOGIC");
+
+MODULE_DESCRIPTION("Amlogic Basic Clock Driver");
+MODULE_AUTHOR("Chuan Liu <chuan.liu@amlogic.com>");
+MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("CLK_AMLOGIC");
diff --git a/drivers/clk/amlogic/clk-basic.h b/drivers/clk/amlogic/clk-basic.h
new file mode 100644
index 000000000000..fb2133fa239b
--- /dev/null
+++ b/drivers/clk/amlogic/clk-basic.h
@@ -0,0 +1,39 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2026 Amlogic, Inc. All rights reserved
+ */
+
+#ifndef __AML_CLK_BASIC_H
+#define __AML_CLK_BASIC_H
+
+#include <linux/clk-provider.h>
+
+struct aml_clk_mux_data {
+	unsigned int	reg_offset;
+	u32		*table;
+	u32		mask;
+	u8		shift;
+	u8		flags;
+};
+
+struct aml_clk_divider_data {
+	unsigned int	reg_offset;
+	u8		shift;
+	u8		width;
+	u16		flags;
+	struct clk_div_table	*table;
+};
+
+struct aml_clk_gate_data {
+	unsigned int	reg_offset;
+	u8		bit_idx;
+	u8		flags;
+};
+
+extern const struct clk_ops aml_clk_gate_ops;
+extern const struct clk_ops aml_clk_divider_ops;
+extern const struct clk_ops aml_clk_divider_ro_ops;
+extern const struct clk_ops aml_clk_mux_ops;
+extern const struct clk_ops aml_clk_mux_ro_ops;
+
+#endif /* __AML_CLK_BASIC_H */
diff --git a/drivers/clk/amlogic/clk.c b/drivers/clk/amlogic/clk.c
new file mode 100644
index 000000000000..03ccfa78c511
--- /dev/null
+++ b/drivers/clk/amlogic/clk.c
@@ -0,0 +1,142 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+/*
+ * Copyright (c) 2026 Amlogic, Inc. All rights reserved
+ */
+
+#include <linux/module.h>
+
+#ifdef CONFIG_DEBUG_FS
+#include <linux/err.h>
+
+#include "clk.h"
+#include "clk-basic.h"
+
+static const struct {
+	unsigned int type;
+	const char *name;
+} clk_types[] = {
+#define ENTRY(f) { f, #f }
+	ENTRY(AML_CLKTYPE_MUX),
+	ENTRY(AML_CLKTYPE_DIV),
+	ENTRY(AML_CLKTYPE_GATE),
+#undef ENTRY
+};
+
+static int aml_clk_type_show(struct seq_file *s, void *data)
+{
+	struct clk_hw *hw = s->private;
+	struct aml_clk *clk = to_aml_clk(hw);
+	int i;
+
+	for (i = 0; i < ARRAY_SIZE(clk_types); i++) {
+		if (clk_types[i].type == clk->type) {
+			seq_printf(s, "%s\n", clk_types[i].name);
+			return 0;
+		}
+	}
+
+	seq_puts(s, "UNKNOWN\n");
+
+	return -EINVAL;
+}
+
+static int aml_clk_type_open(struct inode *inode, struct file *file)
+{
+	return single_open(file, aml_clk_type_show, inode->i_private);
+}
+
+const struct file_operations aml_clk_type_fops = {
+	.owner		= THIS_MODULE,
+	.open		= aml_clk_type_open,
+	.read		= seq_read,
+	.llseek		= seq_lseek,
+	.release	= single_release,
+};
+EXPORT_SYMBOL_NS_GPL(aml_clk_type_fops, "CLK_AMLOGIC");
+
+/*
+ * SoC HW design constrains the maximum frequency for each clock network.
+ * Configuring frequencies beyond these limits may cause module malfunction
+ * or even crosstalk affecting other modules.
+ *
+ * This function synthesizes the HW-constrained frequency range and the
+ * divider's capability to output the permissible frequency range for the
+ * current clock.
+ */
+static int aml_clk_div_available_rates_show(struct seq_file *s, void *data)
+{
+	struct clk_hw *hw = s->private;
+	struct clk_hw *phw = clk_hw_get_parent(hw);
+	struct aml_clk *clk = to_aml_clk(hw);
+	unsigned long min, max, prate;
+	unsigned long range_min, range_max;
+	unsigned int div_val;
+	unsigned long div_width, div_flags = 0;
+	const struct clk_div_table *div_table = NULL;
+
+	if (!phw) {
+		pr_err("%s: Can't get parent\n", clk_hw_get_name(hw));
+
+		return -ENOENT;
+	}
+
+	prate = clk_hw_get_rate(phw);
+	clk_hw_get_rate_range(hw, &range_min, &range_max);
+	max = prate;
+	if (clk->type == AML_CLKTYPE_DIV) {
+		struct aml_clk_divider_data *div = clk->data;
+
+		if (div->flags & CLK_DIVIDER_READ_ONLY) {
+			min = prate;
+			goto out_printf;
+		} else {
+			div_val = (1 << div->width) - 1;
+			div_table = div->table;
+			div_flags = div->flags;
+			div_width = div->width;
+		}
+	} else {
+		pr_err("%s: Unsupported clock type\n", clk_hw_get_name(hw));
+		return -EINVAL;
+	}
+
+	min = divider_recalc_rate(hw, prate, div_val, div_table, div_flags,
+				  div_width);
+
+	clk_hw_get_rate_range(hw, &range_min, &range_max);
+	if (range_min > min)
+		min = range_min;
+
+	if (range_max < max)
+		max = range_max;
+
+	min = divider_round_rate(hw, min, &prate, NULL, div_width, 0);
+	max = divider_round_rate(hw, max, &prate, NULL, div_width, 0);
+
+out_printf:
+	seq_printf(s, "min_rate:%ld\n", min);
+	seq_printf(s, "max_rate:%ld\n", max);
+
+	return 0;
+}
+
+static int aml_clk_div_available_rates_open(struct inode *inode, struct file *file)
+{
+	return single_open(file, aml_clk_div_available_rates_show,
+			   inode->i_private);
+}
+
+const struct file_operations aml_clk_div_available_rates_fops = {
+	.owner		= THIS_MODULE,
+	.open		= aml_clk_div_available_rates_open,
+	.read		= seq_read,
+	.llseek		= seq_lseek,
+	.release	= single_release,
+};
+EXPORT_SYMBOL_NS_GPL(aml_clk_div_available_rates_fops, "CLK_AMLOGIC");
+#endif /* CONFIG_DEBUG_FS */
+
+MODULE_DESCRIPTION("Amlogic Common Clock Driver");
+MODULE_AUTHOR("Chuan Liu <chuan.liu@amlogic.com>");
+MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("CLK_AMLOGIC");
diff --git a/drivers/clk/amlogic/clk.h b/drivers/clk/amlogic/clk.h
new file mode 100644
index 000000000000..ec0547c1354a
--- /dev/null
+++ b/drivers/clk/amlogic/clk.h
@@ -0,0 +1,38 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2026 Amlogic, Inc. All rights reserved
+ */
+
+#ifndef __AML_CLK_H
+#define __AML_CLK_H
+
+#include <linux/clk-provider.h>
+#include <linux/platform_device.h>
+#include <linux/regmap.h>
+
+enum aml_clk_type {
+	AML_CLKTYPE_MUX		= 1,
+	AML_CLKTYPE_DIV		= 2,
+	AML_CLKTYPE_GATE	= 3,
+};
+
+struct aml_clk {
+	struct clk_hw	hw;
+	enum aml_clk_type type;
+	struct regmap	*map;
+	void		*data;
+};
+
+#ifdef CONFIG_DEBUG_FS
+#include <linux/debugfs.h>
+
+extern const struct file_operations aml_clk_type_fops;
+extern const struct file_operations aml_clk_div_available_rates_fops;
+#endif /* CONFIG_DEBUG_FS */
+
+static inline struct aml_clk *to_aml_clk(struct clk_hw *hw)
+{
+	return container_of(hw, struct aml_clk, hw);
+}
+
+#endif /* __AML_CLK_H */

-- 
2.42.0

