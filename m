From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 28 Nov 2025 14:29:14 +0400
Subject: [PATCH v19 2/6] pwm: driver for qualcomm ipq6018 pwm block
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251128-ipq-pwm-v19-2-13bc704cc6a5@outlook.com>
References: <20251128-ipq-pwm-v19-0-13bc704cc6a5@outlook.com>
In-Reply-To: <20251128-ipq-pwm-v19-0-13bc704cc6a5@outlook.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Baruch Siach <baruch@tkos.co.il>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Devi Priya <quic_devipriy@quicinc.com>, 
 Baruch Siach <baruch.siach@siklu.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764325760; l=12302;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=ECLgbGQXvQqaCHleNN2KaOI3IfiJYGfU1o7zDHbZOZo=;
 b=vPkUe390XfPgnR9A+4cm/jNIETdu3JSzsxMjDjX/DTB7RqMnFGjoy8Nh/xGoBmr00hGJQY3dW
 bPY4a3duJVOAtYeG1EbsRAywjXTrIxNLun6ElJfCqutCXvpOyMkvWn0
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Devi Priya <quic_devipriy@quicinc.com>

Driver for the PWM block in Qualcomm IPQ6018 line of SoCs. Based on
driver from downstream Codeaurora kernel tree. Removed support for older
(V1) variants because I have no access to that hardware.

Tested on IPQ5018 and IPQ6010 based hardware.

Co-developed-by: Baruch Siach <baruch.siach@siklu.com>
Signed-off-by: Baruch Siach <baruch.siach@siklu.com>
Signed-off-by: Devi Priya <quic_devipriy@quicinc.com>
Reviewed-by: Bjorn Andersson <andersson@kernel.org>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
v18:

  Added hardware notes and limitations based on own findings as
  requested. NOTE: there's no publically available datasheet though.

  Expanded comment on REG1_UPDATE to indicate that when this bit is set,
  values for div and pre-div take effect. The hardware automatically
  unsets it when the change is completed.

  Added newline between MACRO definition and next comment

  In config_div_and_duty, used mul_u64_u64_div_u64 to avoid overflow

  Removed unncessary restriction of pwm_div to MAX_DIV - 1 after testing

  Constrain pre_div to MAX_DIV is pre_div calculated is > MAX_DIV

  Use of mul_u64_u64_div_u64 in .apply

  Skip calculation of period and duty cycle when PWM_ENABLE REG is unset

  Set duty cycle to period value when calculated duty cycle > period to
  return a valid config

  Removed .npwm as it's taken care of in devm_pwmchip_alloc

  Added call to devm_clk_rate_exclusive_get to lock the clock rate

  Start all kernel messages with a capital letter and end with \n.

v17:

  Removed unnecessary code comments

v16:

  Simplified code to calculate divs and duty cycle as per Uwe's comments

  Removed unused pwm_chip struct from ipq_pwm_chip struct

  Removed unnecessary cast as per Uwe's comment

  Replaced devm_clk_get & clk_prepare_enable by devm_clk_get_enabled

  Replaced pwmchip_add by devm_pwmchip_add and removed .remove function

  Removed .owner from driver struct

v15:

  No change

v14:

  Picked up the R-b tag

v13:

  Updated the file name to match the compatible

  Sorted the properties and updated the order in the required field

  Dropped the syscon node from examples

v12:

  Picked up the R-b tag

v11:

  No change

v10:

  No change

v9:

  Add 'ranges' property to example (Rob)

  Drop label in example (Rob)

v8:

  Add size cell to 'reg' (Rob)

v7:

  Use 'reg' instead of 'offset' (Rob)

  Drop 'clock-names' and 'assigned-clock*' (Bjorn)

  Use single cell address/size in example node (Bjorn)

  Move '#pwm-cells' lower in example node (Bjorn)

  List 'reg' as required

v6:

  Device node is child of TCSR; remove phandle (Rob Herring)

  Add assigned-clocks/assigned-clock-rates (Uwe Kleine-König)

v5: Use qcom,pwm-regs for phandle instead of direct regs (Bjorn
    Andersson, Kathiravan T)

v4: Update the binding example node as well (Rob Herring's bot)

v3: s/qcom,pwm-ipq6018/qcom,ipq6018-pwm/ (Rob Herring)

v2: Make #pwm-cells const (Rob Herring)
---
 drivers/pwm/Kconfig   |  12 +++
 drivers/pwm/Makefile  |   1 +
 drivers/pwm/pwm-ipq.c | 239 ++++++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 252 insertions(+)

diff --git a/drivers/pwm/Kconfig b/drivers/pwm/Kconfig
index bf2d101f67a1e0ae12a58b5630abd5cfd77ccc99..6393f4e91697ae471b1aba72e7ef3f94c5e18383 100644
--- a/drivers/pwm/Kconfig
+++ b/drivers/pwm/Kconfig
@@ -347,6 +347,18 @@ config PWM_INTEL_LGM
 	  To compile this driver as a module, choose M here: the module
 	  will be called pwm-intel-lgm.
 
+config PWM_IPQ
+	tristate "IPQ PWM support"
+	depends on ARCH_QCOM || COMPILE_TEST
+	depends on HAVE_CLK && HAS_IOMEM
+	help
+	  Generic PWM framework driver for IPQ PWM block which supports
+	  4 pwm channels. Each of the these channels can be configured
+	  independent of each other.
+
+	  To compile this driver as a module, choose M here: the module
+	  will be called pwm-ipq.
+
 config PWM_IQS620A
 	tristate "Azoteq IQS620A PWM support"
 	depends on MFD_IQS62X || COMPILE_TEST
diff --git a/drivers/pwm/Makefile b/drivers/pwm/Makefile
index 0dc0d2b69025dbd27013285cd335d3cb1ca2ab3f..5630a521a7cffeb83ff8c8960e15eb23ddb1c9f8 100644
--- a/drivers/pwm/Makefile
+++ b/drivers/pwm/Makefile
@@ -29,6 +29,7 @@ obj-$(CONFIG_PWM_IMX1)		+= pwm-imx1.o
 obj-$(CONFIG_PWM_IMX27)		+= pwm-imx27.o
 obj-$(CONFIG_PWM_IMX_TPM)	+= pwm-imx-tpm.o
 obj-$(CONFIG_PWM_INTEL_LGM)	+= pwm-intel-lgm.o
+obj-$(CONFIG_PWM_IPQ)		+= pwm-ipq.o
 obj-$(CONFIG_PWM_IQS620A)	+= pwm-iqs620a.o
 obj-$(CONFIG_PWM_JZ4740)	+= pwm-jz4740.o
 obj-$(CONFIG_PWM_KEEMBAY)	+= pwm-keembay.o
diff --git a/drivers/pwm/pwm-ipq.c b/drivers/pwm/pwm-ipq.c
new file mode 100644
index 0000000000000000000000000000000000000000..9955b185bc60f27d770f3833d5acd7f587595324
--- /dev/null
+++ b/drivers/pwm/pwm-ipq.c
@@ -0,0 +1,239 @@
+// SPDX-License-Identifier: BSD-3-Clause OR GPL-2.0
+/*
+ * Copyright (c) 2016-2017, 2020 The Linux Foundation. All rights reserved.
+ *
+ * Hardware notes / Limitations:
+ * - The PWM controller has no publicly available datasheet.
+ * - Each of the four channels is programmed via two 32-bit registers
+ *   (REG0 and REG1 at 8-byte stride).
+ * - Period and duty-cycle reconfiguration is fully atomic: new divider,
+ *   pre-divider, and high-duration values are latched by setting the
+ *   UPDATE bit (bit 30 in REG1). The hardware applies the new settings
+ *   at the beginning of the next period without disabling the output,
+ *   so the currently running period is always completed.
+ * - On disable (clearing the ENABLE bit 31 in REG1), the hardware
+ *   finishes the current period before stopping the output. The pin
+ *   is then driven to the inactive (low) level.
+ * - Upon disabling, the hardware resets the pre-divider (PRE_DIV) and divider
+ *   fields (PWM_DIV) in REG0 and REG1 to 0x0000 and 0x0001 respectively.
+ * - Only normal polarity is supported.
+ */
+
+#include <linux/module.h>
+#include <linux/platform_device.h>
+#include <linux/pwm.h>
+#include <linux/clk.h>
+#include <linux/io.h>
+#include <linux/of.h>
+#include <linux/math64.h>
+#include <linux/of_device.h>
+#include <linux/bitfield.h>
+#include <linux/units.h>
+
+/* The frequency range supported is 1 Hz to clock rate */
+#define IPQ_PWM_MAX_PERIOD_NS	((u64)NSEC_PER_SEC)
+
+/*
+ * The max value specified for each field is based on the number of bits
+ * in the pwm control register for that field
+ */
+#define IPQ_PWM_MAX_DIV		0xFFFF
+
+/*
+ * Two 32-bit registers for each PWM: REG0, and REG1.
+ * Base offset for PWM #i is at 8 * #i.
+ */
+#define IPQ_PWM_REG0			0
+#define IPQ_PWM_REG0_PWM_DIV		GENMASK(15, 0)
+#define IPQ_PWM_REG0_HI_DURATION	GENMASK(31, 16)
+
+#define IPQ_PWM_REG1			4
+#define IPQ_PWM_REG1_PRE_DIV		GENMASK(15, 0)
+
+/*
+ * Enable bit is set to enable output toggling in pwm device.
+ * Update bit is set to trigger the change and is unset automatically
+ * to reflect the changed divider and high duration values in register.
+ */
+#define IPQ_PWM_REG1_UPDATE		BIT(30)
+#define IPQ_PWM_REG1_ENABLE		BIT(31)
+
+struct ipq_pwm_chip {
+	struct clk *clk;
+	void __iomem *mem;
+};
+
+static struct ipq_pwm_chip *ipq_pwm_from_chip(struct pwm_chip *chip)
+{
+	return pwmchip_get_drvdata(chip);
+}
+
+static unsigned int ipq_pwm_reg_read(struct pwm_device *pwm, unsigned int reg)
+{
+	struct ipq_pwm_chip *ipq_chip = ipq_pwm_from_chip(pwm->chip);
+	unsigned int off = 8 * pwm->hwpwm + reg;
+
+	return readl(ipq_chip->mem + off);
+}
+
+static void ipq_pwm_reg_write(struct pwm_device *pwm, unsigned int reg,
+			      unsigned int val)
+{
+	struct ipq_pwm_chip *ipq_chip = ipq_pwm_from_chip(pwm->chip);
+	unsigned int off = 8 * pwm->hwpwm + reg;
+
+	writel(val, ipq_chip->mem + off);
+}
+
+static void config_div_and_duty(struct pwm_device *pwm, unsigned int pre_div,
+				unsigned int pwm_div, unsigned long rate, u64 duty_ns,
+				bool enable)
+{
+	unsigned long hi_dur;
+	unsigned long val = 0;
+
+	/*
+	 * high duration = pwm duty * (pwm div + 1)
+	 * pwm duty = duty_ns / period_ns
+	 */
+	hi_dur = mul_u64_u64_div_u64(duty_ns, rate, (pre_div + 1) * NSEC_PER_SEC);
+
+	val = FIELD_PREP(IPQ_PWM_REG0_HI_DURATION, hi_dur) |
+		FIELD_PREP(IPQ_PWM_REG0_PWM_DIV, pwm_div);
+	ipq_pwm_reg_write(pwm, IPQ_PWM_REG0, val);
+
+	val = FIELD_PREP(IPQ_PWM_REG1_PRE_DIV, pre_div);
+	ipq_pwm_reg_write(pwm, IPQ_PWM_REG1, val);
+
+	/* PWM enable toggle needs a separate write to REG1 */
+	val |= IPQ_PWM_REG1_UPDATE;
+	if (enable)
+		val |= IPQ_PWM_REG1_ENABLE;
+	ipq_pwm_reg_write(pwm, IPQ_PWM_REG1, val);
+}
+
+static int ipq_pwm_apply(struct pwm_chip *chip, struct pwm_device *pwm,
+			 const struct pwm_state *state)
+{
+	struct ipq_pwm_chip *ipq_chip = ipq_pwm_from_chip(chip);
+	unsigned long rate = clk_get_rate(ipq_chip->clk);
+	unsigned int pre_div, pwm_div;
+	u64 period_ns, duty_ns;
+
+	if (state->polarity != PWM_POLARITY_NORMAL)
+		return -EINVAL;
+
+	if (state->period < DIV64_U64_ROUND_UP(NSEC_PER_SEC, rate))
+		return -ERANGE;
+
+	period_ns = min(state->period, IPQ_PWM_MAX_PERIOD_NS);
+	duty_ns = min(state->duty_cycle, period_ns);
+
+	pwm_div = IPQ_PWM_MAX_DIV;
+	pre_div = mul_u64_u64_div_u64(period_ns, rate, (u64)NSEC_PER_SEC * (pwm_div + 1));
+
+	if (pre_div > IPQ_PWM_MAX_DIV)
+		pre_div = IPQ_PWM_MAX_DIV;
+
+	config_div_and_duty(pwm, pre_div, pwm_div, rate, duty_ns, state->enabled);
+
+	return 0;
+}
+
+static int ipq_pwm_get_state(struct pwm_chip *chip, struct pwm_device *pwm,
+			     struct pwm_state *state)
+{
+	struct ipq_pwm_chip *ipq_chip = ipq_pwm_from_chip(chip);
+	unsigned long rate = clk_get_rate(ipq_chip->clk);
+	unsigned int pre_div, pwm_div, hi_dur;
+	u64 effective_div, hi_div;
+	u32 reg0, reg1;
+
+	reg1 = ipq_pwm_reg_read(pwm, IPQ_PWM_REG1);
+	state->enabled = reg1 & IPQ_PWM_REG1_ENABLE;
+
+	if (!state->enabled)
+		return 0;
+
+	reg0 = ipq_pwm_reg_read(pwm, IPQ_PWM_REG0);
+
+	state->polarity = PWM_POLARITY_NORMAL;
+
+	pwm_div = FIELD_GET(IPQ_PWM_REG0_PWM_DIV, reg0);
+	hi_dur = FIELD_GET(IPQ_PWM_REG0_HI_DURATION, reg0);
+	pre_div = FIELD_GET(IPQ_PWM_REG1_PRE_DIV, reg1);
+
+	/* No overflow here, both pre_div and pwm_div <= 0xffff */
+	effective_div = (pre_div + 1) * (pwm_div + 1);
+	state->period = DIV64_U64_ROUND_UP(effective_div * NSEC_PER_SEC, rate);
+
+	hi_div = hi_dur * (pre_div + 1);
+	state->duty_cycle = DIV64_U64_ROUND_UP(hi_div * NSEC_PER_SEC, rate);
+
+	/*
+	 * ensure a valid config is passed back to PWM core in case duty_cycle
+	 * is > period (>100%)
+	 */
+	state->duty_cycle = min(state->duty_cycle, state->period);
+
+	return 0;
+}
+
+static const struct pwm_ops ipq_pwm_ops = {
+	.apply = ipq_pwm_apply,
+	.get_state = ipq_pwm_get_state,
+};
+
+static int ipq_pwm_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct ipq_pwm_chip *pwm;
+	struct pwm_chip *chip;
+	int ret;
+
+	chip = devm_pwmchip_alloc(dev, 4, sizeof(*pwm));
+	if (IS_ERR(chip))
+		return PTR_ERR(chip);
+	pwm = ipq_pwm_from_chip(chip);
+
+	pwm->mem = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(pwm->mem))
+		return dev_err_probe(dev, PTR_ERR(pwm->mem),
+				"Failed to acquire resource\n");
+
+	pwm->clk = devm_clk_get_enabled(dev, NULL);
+	if (IS_ERR(pwm->clk))
+		return dev_err_probe(dev, PTR_ERR(pwm->clk),
+				"Failed to get clock\n");
+
+	ret = devm_clk_rate_exclusive_get(dev, pwm->clk);
+	if (ret)
+		return dev_err_probe(dev, ret,
+				"Failed to lock clock rate\n");
+
+	chip->ops = &ipq_pwm_ops;
+
+	ret = devm_pwmchip_add(dev, chip);
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "Failed to add pwm chip\n");
+
+	return ret;
+}
+
+static const struct of_device_id pwm_ipq_dt_match[] = {
+	{ .compatible = "qcom,ipq6018-pwm", },
+	{}
+};
+MODULE_DEVICE_TABLE(of, pwm_ipq_dt_match);
+
+static struct platform_driver ipq_pwm_driver = {
+	.driver = {
+		.name = "ipq-pwm",
+		.of_match_table = pwm_ipq_dt_match,
+	},
+	.probe = ipq_pwm_probe,
+};
+
+module_platform_driver(ipq_pwm_driver);
+
+MODULE_LICENSE("GPL");

-- 
2.52.0

