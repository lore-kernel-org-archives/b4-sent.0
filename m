From: Chuan Liu <chuan.liu@amlogic.com>
Date: Mon, 09 Feb 2026 13:48:56 +0800
Subject: [PATCH 10/13] clk: amlogic: Add A9 standardized model clock
 control units driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260209-a9_clock_driver-v1-10-a9198dc03d2a@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770616143; l=15986;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=LIC/rr157/JcmUmsWhff3I7WronpOmEnKJiamdc04jU=;
 b=Cn+IlwLfHrOKz84vKbMEjcJCgFP2t1fhGCknPdqWQzUKBbwq0EpLcNhUSHVvN+IZdvSD6B9HK
 uMBtyslg2V7BQypbVB3EUhsVYWfp1VsatS5ODnHB4Tv99kkrXFguZZS
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Amlogic standardized model clock control units on A9
SoC family. The standardized models include:
  - composite-ccu
  - noglitch-ccu
  - sysbus-ccu

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/amlogic/Kconfig        |  19 ++
 drivers/clk/amlogic/Makefile       |   3 +
 drivers/clk/amlogic/a9-model-ccu.c | 465 +++++++++++++++++++++++++++++++++++++
 3 files changed, 487 insertions(+)

diff --git a/drivers/clk/amlogic/Kconfig b/drivers/clk/amlogic/Kconfig
index 216fe98a413b..6e954c9388dc 100644
--- a/drivers/clk/amlogic/Kconfig
+++ b/drivers/clk/amlogic/Kconfig
@@ -10,3 +10,22 @@ config COMMON_CLK_AMLOGIC
 	  This driver provides the basic clock infrastructure for Amlogic SoCs,
 	  offering read and write interfaces for various clock control units.
 	  Select Y if your target SoC needs clock driver support.
+
+config COMMON_CLK_AMLOGIC_MODEL
+	tristate "Amlogic Standardized Model Clock Control Units"
+	depends on COMMON_CLK_AMLOGIC
+	help
+	  Supports standardized model clock control units commonly used in Amlogic
+	  SoC clock trees, such as composite-ccu, noglitch-ccu, and sysbus-ccu.
+	  Most peripheral clock controllers in Amlogic SoCs are composed of
+	  these models. Select Y if the current SoC contains these clock control
+	  unit models.
+
+config COMMON_CLK_AMLOGIC_A9
+	tristate "Amlogic A9 Family Clock Controller"
+	depends on COMMON_CLK_AMLOGIC
+	default COMMON_CLK_AMLOGIC
+	select COMMON_CLK_AMLOGIC_MODEL
+	help
+	  Support for the clock controller present on the Amlogic A9 family
+	  SoCs. Select Y if A9 family SoC needs to support clock controller.
diff --git a/drivers/clk/amlogic/Makefile b/drivers/clk/amlogic/Makefile
index 6956592c41c8..ef3fb57cae9f 100644
--- a/drivers/clk/amlogic/Makefile
+++ b/drivers/clk/amlogic/Makefile
@@ -8,3 +8,6 @@ clk-amlogic-y += clk-composite.o
 clk-amlogic-y += clk-dualdiv.o
 clk-amlogic-y += clk-noglitch.o
 clk-amlogic-y += clk-pll.o
+ifneq ($(CONFIG_COMMON_CLK_AMLOGIC_MODEL),)
+clk-amlogic-y += a9-model-ccu.o
+endif
diff --git a/drivers/clk/amlogic/a9-model-ccu.c b/drivers/clk/amlogic/a9-model-ccu.c
new file mode 100644
index 000000000000..5d5bf1538f73
--- /dev/null
+++ b/drivers/clk/amlogic/a9-model-ccu.c
@@ -0,0 +1,465 @@
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
+#include "clk-composite.h"
+#include "clk-noglitch.h"
+
+/*
+ * The standardized model clock control units of Amlogic includes:
+ *   - composite-ccu
+ *   - noglitch-ccu
+ *   - sysbus-ccu
+ */
+#define MAX_AML_CLK_COMP_PARENTS		8
+
+enum aml_clk_model_type {
+	CLK_MODEL_COMPOSITE	= 1,
+	CLK_MODEL_NOGLITCH	= 2,
+	CLK_MODEL_SYSBUS	= 3,
+};
+
+struct aml_clk_model_data {
+	enum aml_clk_model_type	type;
+};
+
+static int of_aml_clk_model_get_type(struct device *dev,
+				     enum aml_clk_type *out_type)
+{
+	const struct aml_clk_model_data *data;
+
+	data = of_device_get_match_data(dev);
+	if (!data)
+		return -EFAULT;
+
+	switch (data->type) {
+	case CLK_MODEL_COMPOSITE:
+		*out_type = AML_CLKTYPE_COMPOSITE;
+		return 0;
+
+	case CLK_MODEL_NOGLITCH:
+		*out_type = AML_CLKTYPE_NOGLITCH;
+		return 0;
+
+	case CLK_MODEL_SYSBUS:
+		*out_type = AML_CLKTYPE_GATE;
+		return 0;
+
+	default:
+		return -EINVAL;
+	}
+}
+
+/*
+ * A diagram of the A9 composite-ccu is as follows:
+ *         +----------------------------------+
+ *         |                                  |
+ *         |   |\                             |
+ * clk0 ------>| |                            |
+ * clk1 ------>| |                            |
+ * clk2 ------>| |                            |
+ * clk3 ------>| |     +-----+     +------+   |
+ *         |   | |---->| div |---->| gate |------> clk out
+ * clk4 ------>| |     +-----+     +------+   |
+ * clk5 ------>| |                            |
+ * clk6 ------>| |                            |
+ * clk7 ------>| |                            |
+ *         |   |/                             |
+ *         |                                  |
+ *         +----------------------------------+
+ */
+static int
+of_aml_clk_model_composite_init_register(struct device *dev,
+					 struct clk_hw_onecell_data *hw_data)
+{
+	struct device_node *np = dev_of_node(dev);
+	struct aml_clk *clk;
+	struct aml_clk_composite_data *composite;
+	u32 reg_val[3];
+	unsigned int pcnt = of_clk_get_parent_count(np);
+	struct clk_parent_data pdata[MAX_AML_CLK_COMP_PARENTS];
+	struct clk_parent_data pdata_compb[MAX_AML_CLK_COMP_PARENTS];
+	u8 pnum, pnum_compb;
+	u32 *ptab, *ptab_compb;
+	struct clk_init_data init = { 0 };
+	int index;
+	int ret, clkid, i;
+
+	ret = of_aml_clk_get_parent_data(dev, hw_data->hws, 0, 7, pdata, &pnum);
+	if (ret)
+		return ret;
+
+	ptab = of_aml_clk_get_parent_table(dev, 0, 7);
+	if (IS_ERR(ptab))
+		return PTR_ERR(ptab);
+
+	/*
+	 * If the number of "clocks" defined in DT is less than or equal
+	 * to MAX_AML_CLK_COMP_PARENTS, composite-ccu_a and composite-ccu_b
+	 * share the same parent clocks.
+	 *
+	 * If the number of "clocks" defined in the DT is greater than
+	 * MAX_AML_CLK_COMP_PARENTS, composite-ccu_a and composite-ccu_b have
+	 * different parent clocks, the parent clocks specified by
+	 * "clocks" follow the rule below:
+	 *   - for composite-ccu_a: clocks indices 0-7 in "clocks"
+	 *   - for composite-ccu_b: clocks indices 8-15 in "clocks"
+	 */
+	if (pcnt > MAX_AML_CLK_COMP_PARENTS) { /* composite-ccu_b */
+		ret = of_aml_clk_get_parent_data(dev, hw_data->hws, 8, 15,
+						 pdata_compb, &pnum_compb);
+		if (ret)
+			return ret;
+
+		ptab_compb = of_aml_clk_get_parent_table(dev, 8, 15);
+		if (IS_ERR(ptab_compb))
+			return PTR_ERR(ptab_compb);
+	}
+
+	init.ops = &aml_clk_composite_ops;
+	for (clkid = 0; clkid < hw_data->num; clkid++) {
+		init.name = of_aml_clk_get_name_index(np, clkid);
+		if (!init.name)
+			return -EINVAL;
+
+		/*
+		 * The set of "amlogic,reg-layout" attributes of composite_ccu
+		 * contains three u32 data:
+		 *   - reg_offset
+		 *   - bit_offset
+		 *   - div_width
+		 */
+		index = clkid * 3;
+		for (i = 0; i < 3; i++) {
+			ret = of_property_read_u32_index(np,
+							 "amlogic,reg-layout",
+							 index + i, &reg_val[i]);
+			if (ret)
+				return ret;
+		}
+
+		composite = devm_kzalloc(dev, sizeof(*composite), GFP_KERNEL);
+		if (!composite)
+			return -ENOMEM;
+
+		composite->reg_offset = reg_val[0];
+		composite->bit_offset = reg_val[1];
+		composite->div_width = reg_val[2];
+
+		/*
+		 * The register bit allocation for composite-ccu_a and
+		 * composite-ccu_b is as follows:
+		 *   - composite-ccu_a: bit[15: 0]
+		 *   - composite-ccu_b: bit[31: 16]
+		 * A value of "composite->bit_offset == 16" indicates that this
+		 * CCU corresponds to composite-ccu_b.
+		 */
+		if (pcnt > MAX_AML_CLK_COMP_PARENTS &&
+		    composite->bit_offset == 16) { /* composite-ccu_b */
+			init.num_parents = pnum_compb;
+			init.parent_data = pdata_compb;
+
+			if (ptab_compb)
+				composite->table = ptab_compb;
+		} else { /* composite-ccu_a */
+			init.num_parents = pnum;
+			init.parent_data = pdata;
+
+			if (ptab)
+				composite->table = ptab;
+		}
+
+		clk = to_aml_clk(hw_data->hws[clkid]);
+		clk->data = composite;
+
+		hw_data->hws[clkid]->init = &init;
+		ret = of_aml_clk_register(dev, hw_data->hws[clkid], clkid);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+/*
+ * A diagram of the A9 noglitch-ccu is as follows:
+ *         +---------------------------------------------+
+ *         |   |\                                        |
+ * clk0 ------>| |                                       |
+ * clk1 ------>| |                                       |
+ * clk2 ------>| |                                       |
+ * clk3 ------>| |      +-----+      +------+      |\    |
+ *         |   | |----->| div |----->| gate |----->| |   |
+ * clk4 ------>| |      +-----+      +------+      | |   |
+ * clk5 ------>| |                                 | |   |
+ * clk6 ------>| |                                 | |   |
+ * clk7 ------>| |                                 | |   |
+ *         |   |/                                  | |   |
+ *         |                                       | |-------> clk out
+ *         |   |\                                  | |   |
+ * clk0 ------>| |                                 | |   |
+ * clk1 ------>| |                                 | |   |
+ * clk2 ------>| |                                 | |   |
+ * clk3 ------>| |      +-----+     +------+       | |   |
+ *         |   | |----->| div |---->| gate |------>| |   |
+ * clk4 ------>| |      +-----+     +------+       |/    |
+ * clk5 ------>| |                                       |
+ * clk6 ------>| |                                       |
+ * clk7 ------>| |                                       |
+ *         |   |/                                        |
+ *         +---------------------------------------------+
+ */
+static int
+of_aml_clk_model_noglitch_init_register(struct device *dev,
+					struct clk_hw_onecell_data *hw_data)
+{
+	struct device_node *np = dev_of_node(dev);
+	struct aml_clk *clk;
+	struct aml_clk_noglitch_data *noglitch;
+	struct clk_parent_data pdata[MAX_AML_CLK_COMP_PARENTS];
+	u8 pnum;
+	u32 *ptab;
+	struct clk_init_data init = { 0 };
+	int ret, clkid;
+
+	/* noglitch-ccu supports up to eight parent clocks. */
+	ret = of_aml_clk_get_parent_data(dev, hw_data->hws, 0, 7, pdata, &pnum);
+	if (ret)
+		return ret;
+
+	ptab = of_aml_clk_get_parent_table(dev, 0, 7);
+	if (IS_ERR(ptab))
+		return PTR_ERR(ptab);
+
+	init.ops = &aml_clk_noglitch_ops;
+	init.num_parents = pnum;
+	init.parent_data = pdata;
+	for (clkid = 0; clkid < hw_data->num; clkid++) {
+		init.name = of_aml_clk_get_name_index(np, clkid);
+		if (!init.name)
+			return -EINVAL;
+
+		hw_data->hws[clkid]->init = &init;
+
+		noglitch = devm_kzalloc(dev, sizeof(*noglitch), GFP_KERNEL);
+		if (!noglitch)
+			return -ENOMEM;
+
+		ret = of_property_read_u32_index(np, "amlogic,reg-layout",
+						 clkid, &noglitch->reg_offset);
+		if (ret)
+			return ret;
+
+		if (ptab)
+			noglitch->table = ptab;
+
+		clk = to_aml_clk(hw_data->hws[clkid]);
+		clk->data = noglitch;
+
+		ret = of_aml_clk_register(dev, hw_data->hws[clkid], clkid);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+/*
+ * A diagram of the A9 sysbus-ccu is as follows:
+ *         +-------------------+
+ *         |                   |
+ *         |        +------+   |
+ *         |  +---->| gate |----->clkout0
+ *         |  |     +------+   |
+ *         |  |                |
+ *         |  |                |
+ *         |  |                |
+ *         |  |     +------+   |
+ * clk in-----+---->| gate |----->clkout1
+ *         |  |     +------+   |
+ *         |  |        ...     |
+ *         |  |                |
+ *         |  |                |
+ *         |  |     +------+   |
+ *         |  +---->| gate |----->clkoutn
+ *         |        +------+   |
+ *         |                   |
+ *         +-------------------+
+ */
+static int
+of_aml_clk_model_sysbus_init_register(struct device *dev,
+				      struct clk_hw_onecell_data *hw_data)
+{
+	struct device_node *np = dev_of_node(dev);
+	struct aml_clk *clk;
+	struct aml_clk_gate_data *gate;
+	u32 reg_val[2];
+	struct clk_parent_data pdata;
+	u8 pnum;
+	struct clk_init_data init = { 0 };
+	int index;
+	int ret, clkid, i;
+
+	ret = of_aml_clk_get_parent_data(dev, hw_data->hws, 0, 0, &pdata, &pnum);
+	if (ret)
+		return ret;
+
+	init.ops = &aml_clk_gate_ops;
+	init.num_parents = pnum;
+	init.parent_data = &pdata;
+	for (clkid = 0; clkid < hw_data->num; clkid++) {
+		init.name = of_aml_clk_get_name_index(np, clkid);
+		if (!init.name)
+			return -EINVAL;
+
+		/*
+		 * The set of "amlogic,reg-layout" attributes of sysbus_ccu
+		 * contains three u32 data:
+		 *   - reg_offset
+		 *   - bit_idx
+		 */
+		index = clkid * 2;
+		for (i = 0; i < 2; i++) {
+			ret = of_property_read_u32_index(np,
+							 "amlogic,reg-layout",
+							 index + i, &reg_val[i]);
+			if (ret)
+				return ret;
+		}
+
+		gate = devm_kzalloc(dev, sizeof(*gate), GFP_KERNEL);
+		if (!gate)
+			return -ENOMEM;
+
+		gate->reg_offset = reg_val[0];
+		gate->bit_idx = reg_val[1];
+
+		clk = to_aml_clk(hw_data->hws[clkid]);
+		clk->data = gate;
+
+		hw_data->hws[clkid]->init = &init;
+		ret = of_aml_clk_register(dev, hw_data->hws[clkid], clkid);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+static int of_aml_clk_model_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	const struct aml_clk_model_data *data;
+	struct device_node *np = dev_of_node(dev);
+	struct regmap *regmap;
+	struct clk_hw_onecell_data *hw_data;
+	struct aml_clk *clk;
+	enum aml_clk_type clk_type;
+	int clk_num;
+	int ret, i;
+
+	data = of_device_get_match_data(dev);
+	if (!data)
+		return -EFAULT;
+
+	clk_num = of_aml_clk_get_count(np);
+	if (clk_num == 0)
+		return -EINVAL;
+
+	regmap = aml_clk_regmap_init(pdev);
+	if (IS_ERR_OR_NULL(regmap))
+		return -EIO;
+
+	of_aml_clk_regs_init(dev);
+
+	hw_data = devm_kzalloc(dev, struct_size(hw_data, hws, clk_num),
+				GFP_KERNEL);
+	if (!hw_data)
+		return -ENOMEM;
+
+	hw_data->num = clk_num;
+	clk = devm_kcalloc(dev, clk_num, sizeof(*clk), GFP_KERNEL);
+	if (!clk)
+		return -ENOMEM;
+
+	ret = of_aml_clk_model_get_type(dev, &clk_type);
+	if (ret)
+		return ret;
+
+	for (i = 0; i < clk_num; i++) {
+		clk[i].map = regmap;
+		clk[i].type = clk_type;
+		hw_data->hws[i] = &clk[i].hw;
+	}
+
+	if (data->type == CLK_MODEL_COMPOSITE)
+		ret = of_aml_clk_model_composite_init_register(dev, hw_data);
+	else if (data->type == CLK_MODEL_NOGLITCH)
+		ret = of_aml_clk_model_noglitch_init_register(dev, hw_data);
+	else if (data->type == CLK_MODEL_SYSBUS)
+		ret = of_aml_clk_model_sysbus_init_register(dev, hw_data);
+
+	if (clk_num == 1)
+		return devm_of_clk_add_hw_provider(dev, of_clk_hw_simple_get,
+						   &clk->hw);
+	else
+		return devm_of_clk_add_hw_provider(dev, of_clk_hw_onecell_get,
+						   hw_data);
+}
+
+static const struct aml_clk_model_data aml_composite_dev_data = {
+	.type = CLK_MODEL_COMPOSITE,
+};
+
+static const struct aml_clk_model_data aml_noglitch_dev_data = {
+	.type = CLK_MODEL_NOGLITCH,
+};
+
+static const struct aml_clk_model_data aml_sysbus_dev_data = {
+	.type = CLK_MODEL_SYSBUS,
+};
+
+static const struct of_device_id of_aml_clk_model_match_table[] = {
+	{
+		.compatible = "amlogic,a9-composite-ccu",
+		.data = &aml_composite_dev_data,
+	},
+	{
+		.compatible = "amlogic,a9-composite-ccu-mult",
+		.data = &aml_composite_dev_data,
+	},
+	{
+		.compatible = "amlogic,a9-noglitch-ccu",
+		.data = &aml_noglitch_dev_data,
+	},
+	{
+		.compatible = "amlogic,a9-noglitch-ccu-mult",
+		.data = &aml_noglitch_dev_data,
+	},
+	{
+		.compatible = "amlogic,a9-sysbus-ccu",
+		.data = &aml_sysbus_dev_data,
+	},
+	{}
+};
+MODULE_DEVICE_TABLE(of, of_aml_clk_model_match_table);
+
+static struct platform_driver of_aml_clk_model_driver = {
+	.probe		= of_aml_clk_model_probe,
+	.driver		= {
+		.name	= "aml-clk-model",
+		.of_match_table = of_aml_clk_model_match_table,
+	},
+};
+module_platform_driver(of_aml_clk_model_driver);
+
+MODULE_DESCRIPTION("Amlogic A9 Standardized Model Clock Control Units Driver");
+MODULE_AUTHOR("Chuan Liu <chuan.liu@amlogic.com>");
+MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("CLK_AMLOGIC");

-- 
2.42.0

