From: Esteban Urrutia <esteuwu@proton.me>
Date: Sat, 11 Jul 2026 23:10:36 -0400
Subject: [PATCH v2 2/3] clk: qcom: dispcc-sm8450: Migrate to
 qcom_cc_driver_data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260711-sm8450-qol-dispcc-v2-2-fc1a07ac5601@proton.me>
References: <20260711-sm8450-qol-dispcc-v2-0-fc1a07ac5601@proton.me>
In-Reply-To: <20260711-sm8450-qol-dispcc-v2-0-fc1a07ac5601@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, Danila Tikhonov <danila@jiaxyga.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783825891; l=2649;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=PwdqzjnMeRdkC7srNPy0ZM+7B2sU0GfwVPACjedCviQ=;
 b=U7SJM3IHNt/ZbMXtLZBCf07N4fRMeZlzSSaaIkpejagx9223suGXBIVnqXw4mL6ANATt8Hcvx
 HY4UtxlMrFuDaFVM1pigThWj/KkNYYtvNuI/D7ZNMBTi7aSYh5c6ncM
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate to qcom_cc_driver_data, which is used by other clock controller
drivers.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 drivers/clk/qcom/dispcc-sm8450.c | 28 +++++++++++++++++++++-------
 1 file changed, 21 insertions(+), 7 deletions(-)

diff --git a/drivers/clk/qcom/dispcc-sm8450.c b/drivers/clk/qcom/dispcc-sm8450.c
index c7e04bd315d5..07f22b5b5ee5 100644
--- a/drivers/clk/qcom/dispcc-sm8450.c
+++ b/drivers/clk/qcom/dispcc-sm8450.c
@@ -1778,6 +1778,22 @@ static const struct regmap_config disp_cc_sm8450_regmap_config = {
 	.fast_io = true,
 };
 
+static struct clk_alpha_pll *disp_cc_sm8450_plls[] = {
+	&disp_cc_pll0,
+	&disp_cc_pll1,
+};
+
+static const u32 disp_cc_sm8450_critical_cbcrs[] = {
+	0xe05c, /* DISP_CC_XO_CLK */
+};
+
+static const struct qcom_cc_driver_data disp_cc_sm8450_driver_data = {
+	.alpha_plls = disp_cc_sm8450_plls,
+	.num_alpha_plls = ARRAY_SIZE(disp_cc_sm8450_plls),
+	.clk_cbcrs = disp_cc_sm8450_critical_cbcrs,
+	.num_clk_cbcrs = ARRAY_SIZE(disp_cc_sm8450_critical_cbcrs),
+};
+
 static const struct qcom_cc_desc disp_cc_sm8450_desc = {
 	.config = &disp_cc_sm8450_regmap_config,
 	.clks = disp_cc_sm8450_clocks,
@@ -1786,6 +1802,7 @@ static const struct qcom_cc_desc disp_cc_sm8450_desc = {
 	.num_resets = ARRAY_SIZE(disp_cc_sm8450_resets),
 	.gdscs = disp_cc_sm8450_gdscs,
 	.num_gdscs = ARRAY_SIZE(disp_cc_sm8450_gdscs),
+	.driver_data = &disp_cc_sm8450_driver_data,
 };
 
 static const struct of_device_id disp_cc_sm8450_match_table[] = {
@@ -1823,19 +1840,16 @@ static int disp_cc_sm8450_probe(struct platform_device *pdev)
 		disp_cc_pll1.regs = clk_alpha_pll_regs[CLK_ALPHA_PLL_TYPE_LUCID_OLE];
 		disp_cc_pll1.clkr.hw.init = &sm8475_disp_cc_pll1_init;
 
-		clk_lucid_ole_pll_configure(&disp_cc_pll0, regmap, &sm8475_disp_cc_pll0_config);
-		clk_lucid_ole_pll_configure(&disp_cc_pll1, regmap, &sm8475_disp_cc_pll1_config);
+		disp_cc_pll0.config = &sm8475_disp_cc_pll0_config;
+		disp_cc_pll1.config = &sm8475_disp_cc_pll1_config;
 	} else {
-		clk_lucid_evo_pll_configure(&disp_cc_pll0, regmap, &disp_cc_pll0_config);
-		clk_lucid_evo_pll_configure(&disp_cc_pll1, regmap, &disp_cc_pll1_config);
+		disp_cc_pll0.config = &disp_cc_pll0_config;
+		disp_cc_pll1.config = &disp_cc_pll1_config;
 	}
 
 	/* Enable clock gating for MDP clocks */
 	regmap_update_bits(regmap, DISP_CC_MISC_CMD, 0x10, 0x10);
 
-	/* Keep some clocks always-on */
-	qcom_branch_set_clk_en(regmap, 0xe05c); /* DISP_CC_XO_CLK */
-
 	ret = qcom_cc_really_probe(&pdev->dev, &disp_cc_sm8450_desc, regmap);
 	if (ret)
 		goto err_put_rpm;

-- 
2.55.0

