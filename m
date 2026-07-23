From: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
Date: Thu, 23 Jul 2026 16:40:41 +0530
Subject: [PATCH v3 2/2] clk: qcom: Add LPASS VA CSR heartbeat pulse clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-master-v3-2-3d67b79b0515@oss.qualcomm.com>
References: <20260723-master-v3-0-3d67b79b0515@oss.qualcomm.com>
In-Reply-To: <20260723-master-v3-0-3d67b79b0515@oss.qualcomm.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-sound@vger.kernel.org, prasad.kumpatla@oss.qualcomm.com, 
 konrad.dybcio@oss.qualcomm.com, 
 Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784805040; l=6908;
 i=sarath.ganapathiraju@oss.qualcomm.com; s=default;
 h=from:subject:message-id; bh=i8+xo9VjvVIrebBSHFSC0M7BNRctUA7H58OpvLIZE0c=;
 b=gVrwaFN7gNMgaOedbmyqRwsaNFkAtCAqhe4jEx8ZT9s0deu+bOYd8QTtIx/p0QzSFtRLMT9ZQ
 +Kaqgncel6kA8PMr8AIzdQSJD4JLlkvT2vh+1ujsT1kQEuy6vf16Lul
X-Developer-Key: i=sarath.ganapathiraju@oss.qualcomm.com; a=ed25519;
 pk=4p2FWGXM+F2sir13Lu5stw5aKX5trUymK/ttESvgxQg=
X-Endpoint-Received: by B4 Relay for sarath.ganapathiraju@oss.qualcomm.com/default with auth_id=870
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HeartBeat Pulse (also known as RateGen Pulse) synchronizes the
start of the DMAs and Codec Interfaces for the audio usecases and
can serve as a periodic wakeup source for the DSP.

Add the LPASS VA CSR driver that models the rate generator as a clock
provider so it is enabled and disabled automatically alongside the
other clocks during runtime PM resume and suspend.

Signed-off-by: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
---
 drivers/clk/qcom/Kconfig        |  12 ++++
 drivers/clk/qcom/Makefile       |   1 +
 drivers/clk/qcom/lpass-va-csr.c | 143 ++++++++++++++++++++++++++++++++++++++++
 sound/soc/codecs/Kconfig        |   1 +
 4 files changed, 157 insertions(+)

diff --git a/drivers/clk/qcom/Kconfig b/drivers/clk/qcom/Kconfig
index 63f271aff177..6ebdccfe37e0 100644
--- a/drivers/clk/qcom/Kconfig
+++ b/drivers/clk/qcom/Kconfig
@@ -1998,6 +1998,18 @@ config CLK_GFM_LPASS_SM8250
 	  Support for the Glitch Free Mux (GFM) Low power audio
           subsystem (LPASS) clocks found on SM8250 SoCs.
 
+config QCOM_CLK_LPASS_VA_CSR
+	tristate "Qualcomm LPASS VA CSR heartbeat pulse clock provider"
+	depends on COMMON_CLK
+	select REGMAP_MMIO
+	help
+	  Qualcomm LPASS VA CSR block contains the rate generator hardware
+	  that produces the HeartBeat Pulse (also known as RateGen Pulse).
+	  This driver models the rate generator as a clock provider so
+	  that consumers can enable or disable it via the common clock
+	  framework, and it can be used to synchronize the start of DMAs
+	  and Codec Interfaces or as a periodic wakeup source for the DSP.
+
 config SM_VIDEOCC_8450
 	tristate "SM8450 Video Clock Controller"
 	depends on ARM64 || COMPILE_TEST
diff --git a/drivers/clk/qcom/Makefile b/drivers/clk/qcom/Makefile
index db7689ee5dc6..2be7da737eba 100644
--- a/drivers/clk/qcom/Makefile
+++ b/drivers/clk/qcom/Makefile
@@ -24,6 +24,7 @@ obj-$(CONFIG_CLK_ELIZA_DISPCC) += dispcc-eliza.o
 obj-$(CONFIG_CLK_ELIZA_GCC) += gcc-eliza.o
 obj-$(CONFIG_CLK_ELIZA_TCSRCC) += tcsrcc-eliza.o
 obj-$(CONFIG_CLK_GFM_LPASS_SM8250) += lpass-gfm-sm8250.o
+obj-$(CONFIG_QCOM_CLK_LPASS_VA_CSR) += lpass-va-csr.o
 obj-$(CONFIG_CLK_GLYMUR_CAMCC) += camcc-glymur.o
 obj-$(CONFIG_CLK_GLYMUR_DISPCC) += dispcc-glymur.o
 obj-$(CONFIG_CLK_GLYMUR_EVACC) += evacc-glymur.o
diff --git a/drivers/clk/qcom/lpass-va-csr.c b/drivers/clk/qcom/lpass-va-csr.c
new file mode 100644
index 000000000000..1d0805789e25
--- /dev/null
+++ b/drivers/clk/qcom/lpass-va-csr.c
@@ -0,0 +1,143 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
+ */
+
+#include <linux/clk-provider.h>
+#include <linux/device.h>
+#include <linux/module.h>
+#include <linux/of_clk.h>
+#include <linux/platform_device.h>
+#include <linux/regmap.h>
+
+#define LPASS_RATE_GEN_CTRL		0xd000
+#define LPASS_RATE_GEN_COUNTER_0	0xd004
+#define LPASS_RATE_GEN_DELAY		0xd010
+
+#define LPASS_RATE_GEN_MAX_REG		LPASS_RATE_GEN_DELAY
+
+#define LPASS_RG_CTRL_EN		BIT(0)
+
+struct lpass_va_csr_data {
+	u32 counter_0;
+	u32 delay;
+};
+
+static const struct lpass_va_csr_data hawi_csr_data = {
+	.counter_0 = 0x960,
+	.delay = 0x16,
+};
+
+static const struct regmap_config lpass_rate_gen_regmap_config = {
+	.name = "lpass_rate_gen",
+	.reg_bits = 32,
+	.val_bits = 32,
+	.reg_stride = 4,
+	.max_register = LPASS_RATE_GEN_MAX_REG,
+	.cache_type = REGCACHE_MAPLE,
+};
+
+struct lpass_va_csr {
+	struct regmap *regmap;
+	const struct lpass_va_csr_data *data;
+	struct clk_hw hb_hw;
+};
+
+#define to_lpass_va_csr(_hw) container_of(_hw, struct lpass_va_csr, hb_hw)
+
+static int heartbeat_pulse_prepare(struct clk_hw *hw)
+{
+	struct lpass_va_csr *csr = to_lpass_va_csr(hw);
+	int ret;
+
+	ret = regmap_write(csr->regmap, LPASS_RATE_GEN_COUNTER_0, csr->data->counter_0);
+	if (ret)
+		return ret;
+
+	ret = regmap_write(csr->regmap, LPASS_RATE_GEN_DELAY, csr->data->delay);
+	if (ret)
+		return ret;
+
+	return regmap_set_bits(csr->regmap, LPASS_RATE_GEN_CTRL, LPASS_RG_CTRL_EN);
+}
+
+static void heartbeat_pulse_unprepare(struct clk_hw *hw)
+{
+	struct lpass_va_csr *csr = to_lpass_va_csr(hw);
+
+	regmap_clear_bits(csr->regmap, LPASS_RATE_GEN_CTRL, LPASS_RG_CTRL_EN);
+}
+
+static int heartbeat_pulse_is_prepared(struct clk_hw *hw)
+{
+	struct lpass_va_csr *csr = to_lpass_va_csr(hw);
+
+	return regmap_test_bits(csr->regmap, LPASS_RATE_GEN_CTRL, LPASS_RG_CTRL_EN);
+}
+
+static const struct clk_ops heartbeat_pulse_ops = {
+	.prepare = heartbeat_pulse_prepare,
+	.unprepare = heartbeat_pulse_unprepare,
+	.is_prepared = heartbeat_pulse_is_prepared,
+};
+
+static int lpass_va_csr_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct lpass_va_csr *csr;
+	struct clk_init_data init = {
+		.name = "lpass_heartbeat_pulse",
+		.ops = &heartbeat_pulse_ops,
+	};
+	void __iomem *base;
+	int ret;
+
+	csr = devm_kzalloc(dev, sizeof(*csr), GFP_KERNEL);
+	if (!csr)
+		return -ENOMEM;
+
+	csr->data = of_device_get_match_data(dev);
+	if (!csr->data)
+		return dev_err_probe(dev, -EINVAL, "no variant data for compatible\n");
+
+	base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(base))
+		return PTR_ERR(base);
+
+	csr->regmap = devm_regmap_init_mmio(dev, base,
+					    &lpass_rate_gen_regmap_config);
+	if (IS_ERR(csr->regmap))
+		return dev_err_probe(dev, PTR_ERR(csr->regmap),
+				     "failed to init regmap\n");
+
+	csr->hb_hw.init = &init;
+
+	ret = devm_clk_hw_register(dev, &csr->hb_hw);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to register heartbeat clock\n");
+
+	ret = devm_of_clk_add_hw_provider(dev, of_clk_hw_simple_get, &csr->hb_hw);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to add clock provider\n");
+
+	return 0;
+}
+
+static const struct of_device_id lpass_va_csr_dt_match[] = {
+	{ .compatible = "qcom,hawi-lpass-va-csr", .data = &hawi_csr_data },
+	{}
+};
+MODULE_DEVICE_TABLE(of, lpass_va_csr_dt_match);
+
+static struct platform_driver lpass_va_csr_driver = {
+	.driver = {
+		.name = "qcom-lpass-va-csr",
+		.of_match_table = lpass_va_csr_dt_match,
+	},
+	.probe = lpass_va_csr_probe,
+};
+
+module_platform_driver(lpass_va_csr_driver);
+
+MODULE_DESCRIPTION("Qualcomm LPASS VA CSR heartbeat pulse clock provider");
+MODULE_LICENSE("GPL");
diff --git a/sound/soc/codecs/Kconfig b/sound/soc/codecs/Kconfig
index 76e90144ea91..704401faa147 100644
--- a/sound/soc/codecs/Kconfig
+++ b/sound/soc/codecs/Kconfig
@@ -2907,6 +2907,7 @@ config SND_SOC_LPASS_VA_MACRO
 	depends on PM_CLK
 	select REGMAP_MMIO
 	select SND_SOC_LPASS_MACRO_COMMON
+	select QCOM_CLK_LPASS_VA_CSR
 	tristate "Qualcomm VA Macro in LPASS(Low Power Audio SubSystem)"
 
 config SND_SOC_LPASS_RX_MACRO

-- 
2.34.1

