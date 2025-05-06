From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 06 May 2025 09:43:36 +0400
Subject: [PATCH v2 4/6] clk: qcom: ipq-cmn-pll: Add IPQ5018 SoC support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250506-ipq5018-cmn-pll-v2-4-c0a9fcced114@outlook.com>
References: <20250506-ipq5018-cmn-pll-v2-0-c0a9fcced114@outlook.com>
In-Reply-To: <20250506-ipq5018-cmn-pll-v2-0-c0a9fcced114@outlook.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Luo Jie <quic_luoj@quicinc.com>, 
 Lee Jones <lee@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746510258; l=4181;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=RLCf5CaWa6JRGj1tMwC22OxTx2xTaEIjQUUkGIrSCqw=;
 b=CK+Io6bobabhxzkFJqjpS4kSr6iNuus3yW3mS3XzztrG48y9lp3tMHgzE++4lSIrx7RsmdvxZ
 HOJGKGP00WbCNAwuSkjYBBr4f/vt5WuQBvtEHmZtcxbXWYp2K5Ogiof
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CMN PLL in IPQ5018 SoC supplies fixed clocks to XO, sleep, and the
ethernet block. The CMN PLL to the ethernet block must be enabled first
by setting a specific register in the TCSR area set in the device tree.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/clk/qcom/ipq-cmn-pll.c | 37 +++++++++++++++++++++++--------------
 1 file changed, 23 insertions(+), 14 deletions(-)

diff --git a/drivers/clk/qcom/ipq-cmn-pll.c b/drivers/clk/qcom/ipq-cmn-pll.c
index b34d6faf67b8dd74402fabdb8dfe5ea52edd52f4..b3d7169c63e5fa7638fee80094a47746a0b6845e 100644
--- a/drivers/clk/qcom/ipq-cmn-pll.c
+++ b/drivers/clk/qcom/ipq-cmn-pll.c
@@ -50,6 +50,7 @@
 #include <linux/regmap.h>
 
 #include <dt-bindings/clock/qcom,ipq-cmn-pll.h>
+#include <dt-bindings/clock/qcom,ipq5018-cmn-pll.h>
 #include <dt-bindings/clock/qcom,ipq5424-cmn-pll.h>
 
 #define CMN_PLL_REFCLK_SRC_SELECTION		0x28
@@ -110,16 +111,10 @@ static const struct regmap_config ipq_cmn_pll_regmap_config = {
 	.fast_io = true,
 };
 
-static const struct cmn_pll_fixed_output_clk ipq9574_output_clks[] = {
-	CLK_PLL_OUTPUT(XO_24MHZ_CLK, "xo-24mhz", 24000000UL),
-	CLK_PLL_OUTPUT(SLEEP_32KHZ_CLK, "sleep-32khz", 32000UL),
-	CLK_PLL_OUTPUT(PCS_31P25MHZ_CLK, "pcs-31p25mhz", 31250000UL),
-	CLK_PLL_OUTPUT(NSS_1200MHZ_CLK, "nss-1200mhz", 1200000000UL),
-	CLK_PLL_OUTPUT(PPE_353MHZ_CLK, "ppe-353mhz", 353000000UL),
-	CLK_PLL_OUTPUT(ETH0_50MHZ_CLK, "eth0-50mhz", 50000000UL),
-	CLK_PLL_OUTPUT(ETH1_50MHZ_CLK, "eth1-50mhz", 50000000UL),
-	CLK_PLL_OUTPUT(ETH2_50MHZ_CLK, "eth2-50mhz", 50000000UL),
-	CLK_PLL_OUTPUT(ETH_25MHZ_CLK, "eth-25mhz", 25000000UL),
+static const struct cmn_pll_fixed_output_clk ipq5018_output_clks[] = {
+	CLK_PLL_OUTPUT(IPQ5018_XO_24MHZ_CLK, "xo-24mhz", 24000000UL),
+	CLK_PLL_OUTPUT(IPQ5018_SLEEP_32KHZ_CLK, "sleep-32khz", 32000UL),
+	CLK_PLL_OUTPUT(IPQ5018_ETH_50MHZ_CLK, "eth-50mhz", 50000000UL),
 	{ /* Sentinel */ }
 };
 
@@ -136,6 +131,19 @@ static const struct cmn_pll_fixed_output_clk ipq5424_output_clks[] = {
 	{ /* Sentinel */ }
 };
 
+static const struct cmn_pll_fixed_output_clk ipq9574_output_clks[] = {
+	CLK_PLL_OUTPUT(XO_24MHZ_CLK, "xo-24mhz", 24000000UL),
+	CLK_PLL_OUTPUT(SLEEP_32KHZ_CLK, "sleep-32khz", 32000UL),
+	CLK_PLL_OUTPUT(PCS_31P25MHZ_CLK, "pcs-31p25mhz", 31250000UL),
+	CLK_PLL_OUTPUT(NSS_1200MHZ_CLK, "nss-1200mhz", 1200000000UL),
+	CLK_PLL_OUTPUT(PPE_353MHZ_CLK, "ppe-353mhz", 353000000UL),
+	CLK_PLL_OUTPUT(ETH0_50MHZ_CLK, "eth0-50mhz", 50000000UL),
+	CLK_PLL_OUTPUT(ETH1_50MHZ_CLK, "eth1-50mhz", 50000000UL),
+	CLK_PLL_OUTPUT(ETH2_50MHZ_CLK, "eth2-50mhz", 50000000UL),
+	CLK_PLL_OUTPUT(ETH_25MHZ_CLK, "eth-25mhz", 25000000UL),
+	{ /* Sentinel */ }
+};
+
 /*
  * CMN PLL has the single parent clock, which supports the several
  * possible parent clock rates, each parent clock rate is reflected
@@ -399,11 +407,11 @@ static int ipq_cmn_pll_clk_probe(struct platform_device *pdev)
 	 */
 	ret = pm_clk_add(dev, "ahb");
 	if (ret)
-		return dev_err_probe(dev, ret, "Fail to add AHB clock\n");
+		return dev_err_probe(dev, ret, "Failed to add AHB clock\n");
 
 	ret = pm_clk_add(dev, "sys");
 	if (ret)
-		return dev_err_probe(dev, ret, "Fail to add SYS clock\n");
+		return dev_err_probe(dev, ret, "Failed to add SYS clock\n");
 
 	ret = pm_runtime_resume_and_get(dev);
 	if (ret)
@@ -414,7 +422,7 @@ static int ipq_cmn_pll_clk_probe(struct platform_device *pdev)
 	pm_runtime_put(dev);
 	if (ret)
 		return dev_err_probe(dev, ret,
-				     "Fail to register CMN PLL clocks\n");
+				     "Failed to register CMN PLL clocks\n");
 
 	return 0;
 }
@@ -439,8 +447,9 @@ static const struct dev_pm_ops ipq_cmn_pll_pm_ops = {
 };
 
 static const struct of_device_id ipq_cmn_pll_clk_ids[] = {
-	{ .compatible = "qcom,ipq9574-cmn-pll", .data = &ipq9574_output_clks },
+	{ .compatible = "qcom,ipq5018-cmn-pll", .data = &ipq5018_output_clks },
 	{ .compatible = "qcom,ipq5424-cmn-pll", .data = &ipq5424_output_clks },
+	{ .compatible = "qcom,ipq9574-cmn-pll", .data = &ipq9574_output_clks },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, ipq_cmn_pll_clk_ids);

-- 
2.49.0

