From: Chuan Liu <chuan.liu@amlogic.com>
Date: Mon, 09 Feb 2026 13:48:57 +0800
Subject: [PATCH 11/13] clk: amlogic: Add A9 PLL controllers driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260209-a9_clock_driver-v1-11-a9198dc03d2a@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770616143; l=5614;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=HEJHyYkWOeBY3AEh9IomhZ/CgW0wq6tKl6L8+ZYrJkY=;
 b=YxZ2VKXTukTFNqFRgp2yd1g0kK4ojKAcyPYhRHq3251QQtz6MJw7UsWyfuGCAqJr/wb6ZtJ1U
 Bk6f4pdL3/PDjZc/jhiVU3RlnCb1BVOhQtIkaVshdBgmX+kXLGVgOH7
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add PLL controllers driver for the Amlogic A9 SoC family.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/amlogic/Kconfig  |  10 +++
 drivers/clk/amlogic/Makefile |   4 ++
 drivers/clk/amlogic/a9-pll.c | 146 +++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 160 insertions(+)

diff --git a/drivers/clk/amlogic/Kconfig b/drivers/clk/amlogic/Kconfig
index 6e954c9388dc..3177a02ecbd5 100644
--- a/drivers/clk/amlogic/Kconfig
+++ b/drivers/clk/amlogic/Kconfig
@@ -21,11 +21,21 @@ config COMMON_CLK_AMLOGIC_MODEL
 	  these models. Select Y if the current SoC contains these clock control
 	  unit models.
 
+config COMMON_CLK_AMLOGIC_PLL
+	tristate "Amlogic PLL Controller"
+	depends on COMMON_CLK_AMLOGIC
+	help
+	  Supports PLL controller used in Amlogic SoCs. The PLL supports dynamic
+	  configuration of output clock frequency, enabling flexible frequency
+	  settings to provide clocks for other modules. Select Y if the current
+	  SoC contains PLLs.
+
 config COMMON_CLK_AMLOGIC_A9
 	tristate "Amlogic A9 Family Clock Controller"
 	depends on COMMON_CLK_AMLOGIC
 	default COMMON_CLK_AMLOGIC
 	select COMMON_CLK_AMLOGIC_MODEL
+	select COMMON_CLK_AMLOGIC_PLL
 	help
 	  Support for the clock controller present on the Amlogic A9 family
 	  SoCs. Select Y if A9 family SoC needs to support clock controller.
diff --git a/drivers/clk/amlogic/Makefile b/drivers/clk/amlogic/Makefile
index ef3fb57cae9f..74bf84dbd5a8 100644
--- a/drivers/clk/amlogic/Makefile
+++ b/drivers/clk/amlogic/Makefile
@@ -11,3 +11,7 @@ clk-amlogic-y += clk-pll.o
 ifneq ($(CONFIG_COMMON_CLK_AMLOGIC_MODEL),)
 clk-amlogic-y += a9-model-ccu.o
 endif
+
+ifneq ($(CONFIG_COMMON_CLK_AMLOGIC_PLL),)
+clk-amlogic-y += a9-pll.o
+endif
diff --git a/drivers/clk/amlogic/a9-pll.c b/drivers/clk/amlogic/a9-pll.c
new file mode 100644
index 000000000000..c4c695caa8ed
--- /dev/null
+++ b/drivers/clk/amlogic/a9-pll.c
@@ -0,0 +1,146 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+/*
+ * Copyright (c) 2026 Amlogic, Inc. All rights reserved
+ */
+
+#include <linux/err.h>
+#include <linux/module.h>
+
+#include "clk.h"
+#include "clk-pll.h"
+
+static const struct aml_pll_data a9_mclk_pll_data = {
+	.range = {
+		.min = 1400000000,
+		.max = 2800000000,
+	},
+	.od_max = 4,
+};
+
+static const struct aml_pll_data a9_gp_pll_data = {
+	.range = {
+		.min = 1400000000,
+		.max = 2800000000,
+	},
+	.frac_max = 131072, /* 2^17 */
+	.od_max = 4,
+	.flags = AML_PLL_M_EN0P5,
+};
+
+static const struct aml_pll_data a9_hifi_pll_data = {
+	.range = {
+		.min = 1400000000,
+		.max = 2800000000,
+	},
+	/*
+	 * NOTE: The frac_max value of hifi_pll is set to 100000 so that the
+	 * output frequency step can be expressed as an integer value. For
+	 * example, with a 24 MHz input clock, the resulting frequency step is
+	 * 24 MHz / 100000 = 240 Hz.
+	 *
+	 * This design avoids the need for floating-point arithmetic in
+	 * frequency calculations, which helps prevent precision loss in
+	 * scenarios with strict frequency accuracy requirements, such as audio
+	 * and video applications.
+	 */
+	.frac_max = 100000,
+	.od_max = 4,
+	.flags = AML_PLL_M_EN0P5,
+};
+
+static int of_aml_clk_pll_init_register(struct device *dev, struct aml_clk *pll)
+{
+	struct device_node *np = dev_of_node(dev);
+	struct clk_init_data init;
+	struct clk_parent_data pdata;
+	u8 pnum;
+	int ret;
+
+	init.name = of_aml_clk_get_name_index(np, 0);
+	if (!init.name)
+		return -EINVAL;
+
+	ret = of_aml_clk_get_parent_data(dev, NULL, 0, 0, &pdata, &pnum);
+	if (ret)
+		return ret;
+
+	init.ops = &aml_pll_ops;
+	init.num_parents = pnum;
+	init.parent_data = &pdata;
+
+	pll->hw.init = &init;
+	ret = of_aml_clk_register(dev, &pll->hw, 0);
+	if (ret)
+		return ret;
+
+	return 0;
+}
+
+static int of_aml_clk_pll_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct regmap *regmap;
+	struct aml_clk *pll;
+	struct aml_pll_data *pll_data_tmp;
+	int ret;
+
+	pll_data_tmp = (void *)of_device_get_match_data(dev);
+	if (!pll_data_tmp)
+		return -EFAULT;
+
+	pll = devm_kmalloc(dev, sizeof(*pll), GFP_KERNEL);
+	if (!pll)
+		return -ENOMEM;
+
+	pll->data = devm_kmemdup(dev, pll_data_tmp, sizeof(*pll_data_tmp),
+				 GFP_KERNEL);
+	if (!pll->data)
+		return -ENOMEM;
+
+	regmap = aml_clk_regmap_init(pdev);
+	if (IS_ERR_OR_NULL(regmap))
+		return -EIO;
+
+	pll->map = regmap;
+	pll->type = AML_CLKTYPE_PLL;
+	ret = of_aml_clk_regs_init(dev);
+	if (ret)
+		return ret;
+
+	ret = of_aml_clk_pll_init_register(dev, pll);
+	if (ret)
+		return ret;
+
+	return devm_of_clk_add_hw_provider(dev, of_clk_hw_simple_get, &pll->hw);
+}
+
+static const struct of_device_id of_aml_clk_pll_match_table[] = {
+	{
+		.compatible = "amlogic,a9-int-pll",
+		.data = &a9_mclk_pll_data,
+	},
+	{
+		.compatible = "amlogic,a9-frac-pll",
+		.data = &a9_gp_pll_data,
+	},
+	{
+		.compatible = "amlogic,a9-frac-step-pll",
+		.data = &a9_hifi_pll_data,
+	},
+	{}
+};
+MODULE_DEVICE_TABLE(of, of_aml_clk_pll_match_table);
+
+static struct platform_driver of_aml_clk_pll_driver = {
+	.probe		= of_aml_clk_pll_probe,
+	.driver		= {
+		.name	= "aml-pll",
+		.of_match_table = of_aml_clk_pll_match_table,
+	},
+};
+module_platform_driver(of_aml_clk_pll_driver);
+
+MODULE_DESCRIPTION("Amlogic A9 PLL Controllers Driver");
+MODULE_AUTHOR("Chuan Liu <chuan.liu@amlogic.com>");
+MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("CLK_AMLOGIC");

-- 
2.42.0

