From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 10 Jan 2025 19:47:11 +0800
Subject: [PATCH 2/2] clk: amlogic: c3: Limit the rate boundaries of clk_hw
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250110-limit-rate-range-of-clk-v1-2-dd618adc4aa8@amlogic.com>
References: <20250110-limit-rate-range-of-clk-v1-0-dd618adc4aa8@amlogic.com>
In-Reply-To: <20250110-limit-rate-range-of-clk-v1-0-dd618adc4aa8@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-amlogic@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736509666; l=5184;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=8XGEQBOCJSgFZ2f2fpSkVtYBK8fi63dUXKYPxwN2M48=;
 b=1XANFRx0lswzvvpEbiIPFHJx220g4DleCItzkvN2v4pK958nuDuGFr6S5LbRx/TDf3QBtEYA9
 dPCCRpv3EIxAvHymsuRLB4hc03O5pFj7q2xOLSPKf653xN1WxT4rHgr
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PLL can only stably lock within a limited frequency range.

Due to timing constraints, the maximum frequency of the peripheral clock
cannot exceed the design specifications.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/c3-peripherals.c | 21 +++++++++++++++++++++
 drivers/clk/meson/c3-pll.c         |  4 ++++
 2 files changed, 25 insertions(+)

diff --git a/drivers/clk/meson/c3-peripherals.c b/drivers/clk/meson/c3-peripherals.c
index 7dcbf4ebee07..9f0a3990f0d6 100644
--- a/drivers/clk/meson/c3-peripherals.c
+++ b/drivers/clk/meson/c3-peripherals.c
@@ -568,6 +568,7 @@ static const struct clk_parent_data pwm_parent_data[] = {
 		.ops = &clk_regmap_gate_ops,			\
 		.parent_names = (const char *[]) { #_name "_div" },\
 		.num_parents = 1,				\
+		.max_rate = 200000000,				\
 		.flags = CLK_SET_RATE_PARENT,			\
 	},							\
 }
@@ -724,6 +725,7 @@ static struct clk_regmap spicc_a = {
 			&spicc_a_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 500000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -771,6 +773,7 @@ static struct clk_regmap spicc_b = {
 			&spicc_b_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 500000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -829,6 +832,7 @@ static struct clk_regmap spifc = {
 			&spifc_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 167000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -887,6 +891,7 @@ static struct clk_regmap sd_emmc_a = {
 			&sd_emmc_a_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 250000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -934,6 +939,7 @@ static struct clk_regmap sd_emmc_b = {
 			&sd_emmc_b_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 250000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -981,6 +987,7 @@ static struct clk_regmap sd_emmc_c = {
 			&sd_emmc_c_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 1200000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1074,6 +1081,7 @@ static struct clk_regmap eth_rmii = {
 			&eth_rmii_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 50000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1132,6 +1140,7 @@ static struct clk_regmap mipi_dsi_meas = {
 			&mipi_dsi_meas_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 200000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1190,6 +1199,7 @@ static struct clk_regmap dsi_phy = {
 			&dsi_phy_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 1500000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1248,6 +1258,7 @@ static struct clk_regmap vout_mclk = {
 			&vout_mclk_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 334000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1306,6 +1317,7 @@ static struct clk_regmap vout_enc = {
 			&vout_enc_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 200000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1431,6 +1443,7 @@ static struct clk_regmap hcodec = {
 		.ops = &clk_regmap_mux_ops,
 		.parent_data = hcodec_parent_data,
 		.num_parents = ARRAY_SIZE(hcodec_parent_data),
+		.max_rate = 667000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1489,6 +1502,7 @@ static struct clk_regmap vc9000e_aclk = {
 			&vc9000e_aclk_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 667000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1536,6 +1550,7 @@ static struct clk_regmap vc9000e_core = {
 			&vc9000e_core_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 400000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1594,6 +1609,7 @@ static struct clk_regmap csi_phy0 = {
 			&csi_phy0_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 200000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1652,6 +1668,7 @@ static struct clk_regmap dewarpa = {
 			&dewarpa_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 800000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1710,6 +1727,7 @@ static struct clk_regmap isp0 = {
 			&isp0_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 400000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1768,6 +1786,7 @@ static struct clk_regmap nna_core = {
 			&nna_core_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 800000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1826,6 +1845,7 @@ static struct clk_regmap ge2d = {
 			&ge2d_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 667000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
@@ -1884,6 +1904,7 @@ static struct clk_regmap vapb = {
 			&vapb_div.hw
 		},
 		.num_parents = 1,
+		.max_rate = 400000000,
 		.flags = CLK_SET_RATE_PARENT,
 	},
 };
diff --git a/drivers/clk/meson/c3-pll.c b/drivers/clk/meson/c3-pll.c
index 35fda31a19e2..d80d6ee2409d 100644
--- a/drivers/clk/meson/c3-pll.c
+++ b/drivers/clk/meson/c3-pll.c
@@ -286,6 +286,8 @@ static struct clk_regmap gp0_pll_dco = {
 			.fw_name = "top",
 		},
 		.num_parents = 1,
+		.min_rate = 3000000000,
+		.max_rate = 6000000000,
 	},
 };
 
@@ -370,6 +372,8 @@ static struct clk_regmap hifi_pll_dco = {
 			.fw_name = "top",
 		},
 		.num_parents = 1,
+		.min_rate = 3000000000,
+		.max_rate = 6000000000,
 	},
 };
 

-- 
2.42.0

