From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 16 Nov 2026 01:49:28 +0530
Subject: [PATCH 2/2] clk: qcom: gpucc-kaanapali: Add support for Molokai
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-molokai-gpucc-v1-2-07cb3bf37c78@yahoo.com>
References: <20261116-molokai-gpucc-v1-0-07cb3bf37c78@yahoo.com>
In-Reply-To: <20261116-molokai-gpucc-v1-0-07cb3bf37c78@yahoo.com>
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Taniya Das <taniya.das@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794773966; l=2883;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=yTs1V5oRJ/5pxMi1XVakjSMJS3lZkregGBsivc3RB8w=;
 b=HFaMmyr+g4HBttl/+t66I5/U5IHQA0sc5ikItTfsnqq/zCfmmTHH3ycjg6TbmjICwY7P/c1ha
 ADHRwIQMrjUDhBQQ7Rw/YLv8S3rAjgGUs/I+Pp4nEXenirbgHLr5Pme
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The graphics clock controller of Molokai (SM8845) is the Kaanapali one,
except for the PLL0 CONFIG_CTL_HI value and the CX accu shift, DPM and
MEMNOC GFX branch clocks, which sit one register further. Handle it in
the Kaanapali driver.

Assisted-by: LLM
Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 drivers/clk/qcom/Kconfig           |  3 ++-
 drivers/clk/qcom/gpucc-kaanapali.c | 25 +++++++++++++++++++++++++
 2 files changed, 27 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/qcom/Kconfig b/drivers/clk/qcom/Kconfig
index e6c58e8b1849..5d4db3264c5a 100644
--- a/drivers/clk/qcom/Kconfig
+++ b/drivers/clk/qcom/Kconfig
@@ -200,7 +200,8 @@ config CLK_KAANAPALI_GPUCC
 	select CLK_KAANAPALI_GCC
 	default m if ARCH_QCOM
 	help
-	  Support for the graphics clock controller on Kaanapali devices.
+	  Support for the graphics clock controller on Kaanapali and Molokai
+	  devices.
 	  Say Y if you want to support graphics controller devices and
 	  functionality such as 3D graphics.
 
diff --git a/drivers/clk/qcom/gpucc-kaanapali.c b/drivers/clk/qcom/gpucc-kaanapali.c
index f75f2caa2205..ea30a9e07a83 100644
--- a/drivers/clk/qcom/gpucc-kaanapali.c
+++ b/drivers/clk/qcom/gpucc-kaanapali.c
@@ -5,6 +5,7 @@
 
 #include <linux/clk-provider.h>
 #include <linux/module.h>
+#include <linux/of.h>
 #include <linux/platform_device.h>
 #include <linux/regmap.h>
 
@@ -52,6 +53,18 @@ static const struct alpha_pll_config gpu_cc_pll0_config = {
 	.user_ctl_hi_val = 0x00000002,
 };
 
+/* Molokai needs a different PLL0 configuration */
+static const struct alpha_pll_config molokai_gpu_cc_pll0_config = {
+	.l = 0x31,
+	.cal_l = 0x48,
+	.alpha = 0x7aaa,
+	.config_ctl_val = 0x25c400e7,
+	.config_ctl_hi_val = 0x0a8060e0,
+	.config_ctl_hi1_val = 0xf51dea20,
+	.user_ctl_val = 0x00000408,
+	.user_ctl_hi_val = 0x00000002,
+};
+
 static struct clk_alpha_pll gpu_cc_pll0 = {
 	.offset = 0x0,
 	.config = &gpu_cc_pll0_config,
@@ -457,12 +470,24 @@ static const struct qcom_cc_desc gpu_cc_kaanapali_desc = {
 
 static const struct of_device_id gpu_cc_kaanapali_match_table[] = {
 	{ .compatible = "qcom,kaanapali-gpucc" },
+	{ .compatible = "qcom,molokai-gpucc" },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, gpu_cc_kaanapali_match_table);
 
 static int gpu_cc_kaanapali_probe(struct platform_device *pdev)
 {
+	if (of_device_is_compatible(pdev->dev.of_node, "qcom,molokai-gpucc")) {
+		gpu_cc_pll0.config = &molokai_gpu_cc_pll0_config;
+
+		gpu_cc_cx_accu_shift_clk.halt_reg = 0x9108;
+		gpu_cc_cx_accu_shift_clk.clkr.enable_reg = 0x9108;
+		gpu_cc_dpm_clk.halt_reg = 0x910c;
+		gpu_cc_dpm_clk.clkr.enable_reg = 0x910c;
+		gpu_cc_memnoc_gfx_clk.halt_reg = 0x90f0;
+		gpu_cc_memnoc_gfx_clk.clkr.enable_reg = 0x90f0;
+	}
+
 	return qcom_cc_probe(pdev, &gpu_cc_kaanapali_desc);
 }
 

-- 
2.56.0

