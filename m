From: David Heidelberg <david@ixit.cz>
Date: Sat, 22 Aug 2026 04:25:24 +0200
Subject: [PATCH] clk: qcom: camcc-sdm845/670: Raise CSIPHY timer clock
 limit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260822-csiphy-sdm845-limits-v1-1-d360bf7cd38f@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSQqEMBBA0atIrbtA40DwKtILk5Ra4kTKbhTx7
 kZdvsX/Bwh5JoEyOsDTn4XnKSD5RGC7emoJ2QWDilURa6XQCi/djuJGneU48MiroEkodaZucpd
 qCOniqeHt2Vbf1/IzPdn1fsF5XqAI/A14AAAA
X-Change-ID: 20260822-csiphy-sdm845-limits-b1e3dbaf5d38
To: Bjorn Andersson <andersson@kernel.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-media@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5946; i=david@ixit.cz;
 h=from:subject:message-id; bh=DYQKHB8AunZw7f/1fW2n+DYOf95ExVe+TTy2tBTvI1Q=;
 b=kA0DAAgBYAI/xNNJIHIByyZiAGqJCJWjGJGYquDI9eAI1VgPj41qzj2+T/sbzqxfO18UYVgEg
 IkCMwQAAQgAHRYhBNd6Cc/u3Cu9U6cEdGACP8TTSSByBQJqiQiVAAoJEGACP8TTSSBymGoQAL4z
 /9+pDXWW6rn2EaAPVVhf6SvOk18a4gNEbEELXCqsAMhF3Rqgre878k85Q9eO3tnNyG0P9JWeXn/
 xDJbrtP2W1EsV+lWZRKwiaKelkeB7VLKndYdoUlXJwJjK+D2WOxXmnOamRFDeU9WWY5zGu62OrK
 qZp11Ch4Fi7NbQfc1ui6TzYy2DVSj0DYK3lxDF/ChxHbZz05mvfrcXW0zXQCX7Px532P2Eu9PAT
 xf10lEIpLyLgyf/JMfgn5jJ/x6B5eL85nvBbOzfp06CgHXkxas2PMrvT26dvkwnXFUVSViSIsym
 lyb2KkWhGQB9A0u+tGQICNuy+TYazu5oj/sTKZ3PT9HxJgXehFa6zydaq+DbVSl2aEG3vbOtd6P
 2JcsA25eZEHuMVEI5UNz1jS0q4u7CaLYO2R/QoIq4uyE2QjDQF8iLbhjYQcPatEC7LXFGZYqgF2
 pBmq584YxUr3mllKrL5lm9TXnxNLsKZN1hwnb39cORkWPFiIdoK9LDqK6j4aEL+7TxWkEfWuQOL
 vKSOnixIdpQD1PPy0cO7lo11XtIk9beb5I1I/AIgBPfmIEYe7gShR/n/+WPnsNLpzoA+zZORLB/
 1iNJJvYaNgWKvvgHhYb9BjpcrpHK+30AyJ6Kn2E7Lq6lcx2pPiSCDupCKwPSX8MlgIO4lqJ/Jxm
 wJQy5
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The sdm845 CSIPHY timer clock only listed up to 269.33 MHz, capping the
supported CSI link frequency at roughly 1.07 GHz
(CSIPHY timer = link_freq / 4). The Samsung S5K2X7SP camera runs at a
1.15 GHz link frequency, so camss rejected powering up the
pipeline with 'Pixel clock is too high for CSIPHY'.

Add a 288 MHz entry to the shared camcc CSIPHY timer frequency table
(PLL1 VCO 1152 MHz, well within range) and add a 400 MHz entry to the
sdm845 CSIPHY timer clock_rate tables. The camss min_rate check now
passes and the timer clock rounds to 288 MHz, matching the ~287.5 MHz
required by the 1.15 GHz link.

Assisted-by: tencent:hy3
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Tested on SHIFT 6MQ with next-20260820.
---
 drivers/clk/qcom/camcc-sdm845.c           |  1 +
 drivers/media/platform/qcom/camss/camss.c | 14 +++++++-------
 2 files changed, 8 insertions(+), 7 deletions(-)

diff --git a/drivers/clk/qcom/camcc-sdm845.c b/drivers/clk/qcom/camcc-sdm845.c
index 534dc56fc13ca..77bb783b4ef0a 100644
--- a/drivers/clk/qcom/camcc-sdm845.c
+++ b/drivers/clk/qcom/camcc-sdm845.c
@@ -250,16 +250,17 @@ static struct clk_rcg2 cam_cc_cphy_rx_clk_src = {
 		.ops = &clk_rcg2_ops,
 	},
 };
 
 static const struct freq_tbl ftbl_cam_cc_csi0phytimer_clk_src[] = {
 	F(19200000, P_BI_TCXO, 1, 0, 0),
 	F(240000000, P_CAM_CC_PLL2_OUT_EVEN, 2, 0, 0),
 	F(269333333, P_CAM_CC_PLL1_OUT_EVEN, 3, 0, 0),
+	F(288000000, P_CAM_CC_PLL1_OUT_EVEN, 2, 0, 0),
 	{ }
 };
 
 static struct clk_rcg2 cam_cc_csi0phytimer_clk_src = {
 	.cmd_rcgr = 0x5004,
 	.mnd_width = 0,
 	.hid_width = 5,
 	.parent_map = cam_cc_parent_map_0,
diff --git a/drivers/media/platform/qcom/camss/camss.c b/drivers/media/platform/qcom/camss/camss.c
index 2123f6388e3d7..e1bf828cf7af2 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -1070,17 +1070,17 @@ static const struct camss_subdev_resources csiphy_res_670[] = {
 			{ .supply = "vdda-phy", .init_load_uA = 42800 },
 			{ .supply = "vdda-pll", .init_load_uA = 13900 }
 		},
 		.clock = { "soc_ahb", "cpas_ahb",
 			   "csiphy0", "csiphy0_timer" },
 		.clock_rate = { { 0 },
 				{ 0 },
 				{ 0 },
-				{ 19200000, 240000000, 269333333 } },
+				{ 19200000, 240000000, 269333333, 400000000 } },
 		.reg = { "csiphy0" },
 		.interrupt = { "csiphy0" },
 		.csiphy = {
 			.id = 0,
 			.hw_ops = &csiphy_ops_3ph_1_0,
 			.formats = &csiphy_formats_sdm845
 		}
 	},
@@ -1091,17 +1091,17 @@ static const struct camss_subdev_resources csiphy_res_670[] = {
 			{ .supply = "vdda-phy", .init_load_uA = 42800 },
 			{ .supply = "vdda-pll", .init_load_uA = 13900 }
 		},
 		.clock = { "soc_ahb", "cpas_ahb",
 			   "csiphy1", "csiphy1_timer" },
 		.clock_rate = { { 0 },
 				{ 0 },
 				{ 0 },
-				{ 19200000, 240000000, 269333333 } },
+				{ 19200000, 240000000, 269333333, 400000000 } },
 		.reg = { "csiphy1" },
 		.interrupt = { "csiphy1" },
 		.csiphy = {
 			.id = 1,
 			.hw_ops = &csiphy_ops_3ph_1_0,
 			.formats = &csiphy_formats_sdm845
 		}
 	},
@@ -1112,17 +1112,17 @@ static const struct camss_subdev_resources csiphy_res_670[] = {
 			{ .supply = "vdda-phy", .init_load_uA = 42800 },
 			{ .supply = "vdda-pll", .init_load_uA = 13900 }
 		},
 		.clock = { "soc_ahb", "cpas_ahb",
 			   "csiphy2", "csiphy2_timer" },
 		.clock_rate = { { 0 },
 				{ 0 },
 				{ 0 },
-				{ 19200000, 240000000, 269333333 } },
+				{ 19200000, 240000000, 269333333, 400000000 } },
 		.reg = { "csiphy2" },
 		.interrupt = { "csiphy2" },
 		.csiphy = {
 			.id = 2,
 			.hw_ops = &csiphy_ops_3ph_1_0,
 			.formats = &csiphy_formats_sdm845
 		}
 	}
@@ -1263,17 +1263,17 @@ static const struct camss_subdev_resources csiphy_res_845[] = {
 				"csiphy0_timer_src", "csiphy0_timer" },
 		.clock_rate = { { 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
-				{ 19200000, 240000000, 269333333 } },
+				{ 19200000, 240000000, 269333333, 400000000 } },
 		.reg = { "csiphy0" },
 		.interrupt = { "csiphy0" },
 		.csiphy = {
 			.id = 0,
 			.hw_ops = &csiphy_ops_3ph_1_0,
 			.formats = &csiphy_formats_sdm845
 		}
 	},
@@ -1286,17 +1286,17 @@ static const struct camss_subdev_resources csiphy_res_845[] = {
 				"csiphy1_timer_src", "csiphy1_timer" },
 		.clock_rate = { { 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
-				{ 19200000, 240000000, 269333333 } },
+				{ 19200000, 240000000, 269333333, 400000000 } },
 		.reg = { "csiphy1" },
 		.interrupt = { "csiphy1" },
 		.csiphy = {
 			.id = 1,
 			.hw_ops = &csiphy_ops_3ph_1_0,
 			.formats = &csiphy_formats_sdm845
 		}
 	},
@@ -1309,17 +1309,17 @@ static const struct camss_subdev_resources csiphy_res_845[] = {
 				"csiphy2_timer_src", "csiphy2_timer" },
 		.clock_rate = { { 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
-				{ 19200000, 240000000, 269333333 } },
+				{ 19200000, 240000000, 269333333, 400000000 } },
 		.reg = { "csiphy2" },
 		.interrupt = { "csiphy2" },
 		.csiphy = {
 			.id = 2,
 			.hw_ops = &csiphy_ops_3ph_1_0,
 			.formats = &csiphy_formats_sdm845
 		}
 	},
@@ -1332,17 +1332,17 @@ static const struct camss_subdev_resources csiphy_res_845[] = {
 				"csiphy3_timer_src", "csiphy3_timer" },
 		.clock_rate = { { 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
 				{ 0 },
-				{ 19200000, 240000000, 269333333 } },
+				{ 19200000, 240000000, 269333333, 400000000 } },
 		.reg = { "csiphy3" },
 		.interrupt = { "csiphy3" },
 		.csiphy = {
 			.id = 3,
 			.hw_ops = &csiphy_ops_3ph_1_0,
 			.formats = &csiphy_formats_sdm845
 		}
 	}

---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260822-csiphy-sdm845-limits-b1e3dbaf5d38

Best regards,
--  
David Heidelberg <david@ixit.cz>

