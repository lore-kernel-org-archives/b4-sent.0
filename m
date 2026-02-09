From: Chuan Liu <chuan.liu@amlogic.com>
Date: Mon, 09 Feb 2026 13:48:55 +0800
Subject: [PATCH 09/13] clk: amlogic: Add DT-based clock registration
 functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260209-a9_clock_driver-v1-9-a9198dc03d2a@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770616142; l=10590;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=bn1W4wBj9kR2bBMVc+TWzhW7ePYmeAS9HgD29Ygxs+k=;
 b=JptUihEMip98DRKPFWIBfkFKyU+hFUTh+CMKTUdN3dzRJIuVh140hOffNm6cPeACf4QLAZO1/
 BCdBK4+aJjHB2TuZyJ2W02UXGWreD/Y33v+ALbk72q/b6HhZQP5BZGf
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic clock controllers require hardware information description in
device tree. This patch provides functions for parsing clock configuration
from DT and performing clock registration after obtaining clock details.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/amlogic/clk.c | 310 +++++++++++++++++++++++++++++++++++++++++++++-
 drivers/clk/amlogic/clk.h |  14 +++
 2 files changed, 323 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/amlogic/clk.c b/drivers/clk/amlogic/clk.c
index 2558c3f48242..f3327c8414be 100644
--- a/drivers/clk/amlogic/clk.c
+++ b/drivers/clk/amlogic/clk.c
@@ -3,12 +3,15 @@
  * Copyright (c) 2026 Amlogic, Inc. All rights reserved
  */
 
+#include <linux/clk.h>
 #include <linux/module.h>
+#include <linux/of_clk.h>
+
+#include "clk.h"
 
 #ifdef CONFIG_DEBUG_FS
 #include <linux/err.h>
 
-#include "clk.h"
 #include "clk-basic.h"
 #include "clk-composite.h"
 #include "clk-noglitch.h"
@@ -150,6 +153,311 @@ const struct file_operations aml_clk_div_available_rates_fops = {
 EXPORT_SYMBOL_NS_GPL(aml_clk_div_available_rates_fops, "CLK_AMLOGIC");
 #endif /* CONFIG_DEBUG_FS */
 
+struct regmap *aml_clk_regmap_init(struct platform_device *pdev)
+{
+	void __iomem *base;
+	struct resource *res;
+	struct regmap_config clkc_regmap_config = {
+		.reg_bits	= 32,
+		.val_bits	= 32,
+		.reg_stride	= 4,
+	};
+
+	base = devm_platform_get_and_ioremap_resource(pdev, 0, &res);
+	if (IS_ERR(base))
+		return NULL;
+
+	clkc_regmap_config.max_register = resource_size(res) - 4;
+	if (!clkc_regmap_config.max_register)
+		clkc_regmap_config.max_register_is_0 = true;
+
+	return devm_regmap_init_mmio(&pdev->dev, base, &clkc_regmap_config);
+}
+EXPORT_SYMBOL_NS_GPL(aml_clk_regmap_init, "CLK_AMLOGIC");
+
+static inline int of_aml_clk_get_init_reg_count(struct device_node *np)
+{
+	return of_property_count_elems_of_size(np, "amlogic,clock-init-regs",
+					       sizeof(struct reg_sequence));
+}
+
+static inline int of_aml_clk_get_init_reg(struct device_node *np, int reg_count,
+					  struct reg_sequence *init_regs)
+{
+	return of_property_read_u32_array(np, "amlogic,clock-init-regs",
+					  (u32 *)init_regs,
+					  3 * reg_count);
+}
+
+int of_aml_clk_regs_init(struct device *dev)
+{
+	struct device_node *dev_np = dev_of_node(dev);
+	struct regmap *regmap = dev_get_regmap(dev, NULL);
+	int ret, reg_count;
+	struct reg_sequence *init_regs;
+
+	ret = of_aml_clk_get_init_reg_count(dev_np);
+	if (ret < 0)
+		return 0;
+
+	reg_count = ret;
+	init_regs = devm_kcalloc(dev, reg_count, sizeof(*init_regs),
+				 GFP_KERNEL);
+	if (!init_regs)
+		return -ENOMEM;
+
+	ret = of_aml_clk_get_init_reg(dev_np, reg_count, init_regs);
+	if (ret)
+		goto fail;
+
+	ret = regmap_multi_reg_write(regmap, init_regs, reg_count);
+
+fail:
+	devm_kfree(dev, init_regs);
+
+	return ret;
+}
+EXPORT_SYMBOL_NS_GPL(of_aml_clk_regs_init, "CLK_AMLOGIC");
+
+u32 of_aml_clk_get_count(struct device_node *np)
+{
+	/*
+	 * NOTE: Each clock under a clock device node must define the
+	 * "clock-output-names" property, so this property is used here to
+	 * determine how many clocks are contained in the current clock device
+	 * node.
+	 */
+	int ret = of_property_count_strings(np, "clock-output-names");
+
+	if (ret < 0)
+		return 0;
+
+	return ret;
+}
+EXPORT_SYMBOL_NS_GPL(of_aml_clk_get_count, "CLK_AMLOGIC");
+
+const char *of_aml_clk_get_name_index(struct device_node *np, u32 index)
+{
+	const char *name;
+
+	if (of_property_read_string_index(np, "clock-output-names", index,
+					  &name)) {
+		pr_err("<%pOFn>: Invalid clock-output-names, index = %d\n",
+		       np, index);
+		return NULL;
+	}
+
+	return name;
+}
+EXPORT_SYMBOL_NS_GPL(of_aml_clk_get_name_index, "CLK_AMLOGIC");
+
+static bool of_aml_clk_is_dummy_index(struct device_node *np, int index)
+{
+	struct of_phandle_args clk_args;
+	u32 rate;
+	int ret = of_parse_phandle_with_args(np, "clocks", "#clock-cells",
+					     index, &clk_args);
+
+	if (ret < 0)
+		return true;
+
+	/*
+	 * If the device node description specified by clk_args indicates a
+	 * fixed clock with a frequency of 0, the device is considered a dummy
+	 * clock device.
+	 */
+	if (of_device_is_compatible(clk_args.np, "fixed-clock") &&
+	    !of_property_read_u32(clk_args.np, "clock-frequency", &rate) &&
+	    rate == 0)
+		return true;
+
+	return false;
+}
+
+int of_aml_clk_get_parent_num(struct device *dev, int start_index, int end_index)
+{
+	struct device_node *np = dev_of_node(dev);
+	unsigned int pcnt = of_clk_get_parent_count(np);
+	int i, real_pcnt = 0;
+
+	if (end_index < 0 || end_index >= pcnt)
+		/* Get the number of all "clocks" for the current device node */
+		end_index = pcnt - 1;
+
+	if (start_index > end_index ||
+	    start_index > pcnt)
+		return -EINVAL;
+
+	for (i = start_index; i <= end_index; i++) {
+		if (of_aml_clk_is_dummy_index(np, i))
+			continue;
+
+		real_pcnt++;
+	}
+
+	return real_pcnt;
+}
+EXPORT_SYMBOL_NS_GPL(of_aml_clk_get_parent_num, "CLK_AMLOGIC");
+
+static struct clk_hw *of_aml_clk_get_hw(struct device_node *np,
+					struct clk_hw **dev_hws, int index)
+{
+	struct of_phandle_args out_args;
+	struct clk *clk;
+	struct clk_hw *clk_hw;
+	int ret;
+
+	ret = of_parse_phandle_with_args(np, "clocks", "#clock-cells", index,
+					 &out_args);
+	if (ret)
+		return ERR_PTR(ret);
+
+	if (out_args.np == np) {
+		if (!dev_hws)
+			return ERR_PTR(-EFAULT);
+
+		/*
+		 * If a parent clock comes from the device node itself, the
+		 * corresponding clk_hw can be found using the
+		 * "out_args.args[0]" (clock index).
+		 */
+		clk_hw = dev_hws[out_args.args[0]];
+	} else {
+		clk = of_clk_get_from_provider(&out_args);
+		if (IS_ERR(clk)) {
+			if (PTR_ERR(clk) != -EPROBE_DEFER)
+				pr_warn("clk: couldn't get clock for %pOF\n",
+					out_args.np);
+
+			return ERR_CAST(clk);
+		}
+
+		clk_hw = __clk_get_hw(clk);
+		clk_put(clk);
+	}
+
+	return clk_hw;
+}
+
+int of_aml_clk_get_parent_data(struct device *dev, struct clk_hw **dev_hws,
+			       int start_index, int end_index,
+			       struct clk_parent_data *out_pdatas,
+			       u8 *out_num_parents)
+{
+	struct device_node *np = dev_of_node(dev);
+	unsigned int pcnt = of_clk_get_parent_count(np);
+	int i, real_pcnt;
+
+	if (end_index < 0 || end_index >= pcnt)
+		/* Get the number of all "clocks" for the current device node */
+		end_index = pcnt - 1;
+
+	if (start_index > end_index || start_index > pcnt)
+		return -EINVAL;
+
+	for (i = start_index, real_pcnt = 0; i <= end_index; i++) {
+		if (of_aml_clk_is_dummy_index(np, i))
+			continue;
+
+		out_pdatas[real_pcnt].hw = of_aml_clk_get_hw(np, dev_hws, i);
+		if (IS_ERR(out_pdatas[real_pcnt].hw))
+			return PTR_ERR(out_pdatas[real_pcnt].hw);
+
+		real_pcnt++;
+	}
+
+	if (out_num_parents)
+		*out_num_parents = real_pcnt;
+
+	return 0;
+}
+EXPORT_SYMBOL_NS_GPL(of_aml_clk_get_parent_data, "CLK_AMLOGIC");
+
+u32 *of_aml_clk_get_parent_table(struct device *dev, int start_index,
+				 int end_index)
+{
+	struct device_node *np = dev_of_node(dev);
+	bool has_ptab = false;
+	u32 *ptab;
+	unsigned int pcnt = of_clk_get_parent_count(np);
+	int i, real_pcnt, ptab_i;
+
+	real_pcnt = of_aml_clk_get_parent_num(dev, start_index, end_index);
+	if (real_pcnt < 0)
+		return ERR_PTR(-EINVAL);
+	else if (!real_pcnt) /* no parent clock */
+		return NULL;
+
+	if (end_index < 0 || end_index >= pcnt)
+		end_index = pcnt - 1;
+
+	for (i = start_index, ptab_i = 0; i <= end_index; i++) {
+		/* dummy clock exist and ptab needs to be defined */
+		if (of_aml_clk_is_dummy_index(np, i)) {
+			has_ptab = true;
+			break;
+		}
+	}
+	if (!has_ptab)
+		return NULL;
+
+	ptab = devm_kcalloc(dev, real_pcnt, sizeof(*ptab), GFP_KERNEL);
+	if (!ptab)
+		return ERR_PTR(-ENOMEM);
+
+	for (i = start_index, ptab_i = 0; i <= end_index; i++) {
+		if (!of_aml_clk_is_dummy_index(np, i))
+			ptab[ptab_i++] = i - start_index;
+	}
+
+	return ptab;
+}
+EXPORT_SYMBOL_NS_GPL(of_aml_clk_get_parent_table, "CLK_AMLOGIC");
+
+static int of_aml_clk_get_max_rate(struct device_node *np, u32 index,
+			    unsigned long *out_max_rate)
+{
+	int count = of_property_count_u32_elems(np,
+						"amlogic,clock-max-frequency");
+
+	if (count < 0)
+		return count;
+	else if (count == 1)
+		/*
+		 * If the property "amlogic,clock-max-frequency" under the
+		 * current device node defines only a single value, that value
+		 * specifies the maximum frequency limit for all clocks under
+		 * this device node.
+		 */
+		index = 0;
+
+	return of_property_read_u32_index(np, "amlogic,clock-max-frequency",
+					  index, (u32 *)out_max_rate);
+}
+
+int of_aml_clk_register(struct device *dev, struct clk_hw *hw, int clkid)
+{
+	struct device_node *np = dev_of_node(dev);
+	unsigned long max_rate;
+	int ret;
+
+	ret = devm_clk_hw_register(dev, hw);
+	if (ret)
+		return ret;
+
+	ret = of_aml_clk_get_max_rate(np, clkid, &max_rate);
+	if (ret) {
+		if (ret != -EINVAL)
+			return ret;
+	} else {
+		if (max_rate)
+			clk_hw_set_rate_range(hw, 0, max_rate);
+	}
+
+	return 0;
+}
+EXPORT_SYMBOL_NS_GPL(of_aml_clk_register, "CLK_AMLOGIC");
+
 MODULE_DESCRIPTION("Amlogic Common Clock Driver");
 MODULE_AUTHOR("Chuan Liu <chuan.liu@amlogic.com>");
 MODULE_LICENSE("GPL");
diff --git a/drivers/clk/amlogic/clk.h b/drivers/clk/amlogic/clk.h
index b62045aedfbf..3cfe2e650ed4 100644
--- a/drivers/clk/amlogic/clk.h
+++ b/drivers/clk/amlogic/clk.h
@@ -39,4 +39,18 @@ static inline struct aml_clk *to_aml_clk(struct clk_hw *hw)
 	return container_of(hw, struct aml_clk, hw);
 }
 
+struct regmap *aml_clk_regmap_init(struct platform_device *pdev);
+int of_aml_clk_regs_init(struct device *dev);
+u32 of_aml_clk_get_count(struct device_node *np);
+const char *of_aml_clk_get_name_index(struct device_node *np, u32 index);
+int of_aml_clk_get_parent_num(struct device *dev, int start_index,
+			      int end_index);
+int of_aml_clk_get_parent_data(struct device *dev, struct clk_hw **dev_hws,
+			       int start_index, int end_index,
+			       struct clk_parent_data *out_pdatas,
+			       u8 *out_num_parents);
+u32 *of_aml_clk_get_parent_table(struct device *dev, int start_index,
+				 int end_index);
+int of_aml_clk_register(struct device *dev, struct clk_hw *hw, int clkid);
+
 #endif /* __AML_CLK_H */

-- 
2.42.0

