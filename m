From: jiebing chen <jiebing.chen@amlogic.com>
Date: Wed, 19 Mar 2025 15:04:48 +0800
Subject: [PATCH v4 5/6] clk: meson: axg-audio: Add the mclk pad div for s4
 chip
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-audio_drvier-v4-5-686867fad719@amlogic.com>
References: <20250319-audio_drvier-v4-0-686867fad719@amlogic.com>
In-Reply-To: <20250319-audio_drvier-v4-0-686867fad719@amlogic.com>
To: Jerome Brunet <jbrunet@baylibre.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 jian.xu@amlogic.com, shuai.li@amlogic.com, zhe.wang@amlogic.com, 
 jiebing chen <jiebing.chen@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742367998; l=20414;
 i=jiebing.chen@amlogic.com; s=20250110; h=from:subject:message-id;
 bh=h6lSCUO2hih98dgxFJ/A35Ixss2SF96tSwWB83V/kpA=;
 b=20yY2gYv9mDO+ibQHxXQsig27v/Eahl3mgn8LfMtm4rAydF+4NhFQsB33ATRZJ2B3POp9DT4c
 s3THzv8k3dVC/8MyAgwoZNtqhpUDQjsnyuyg2eaqHck7DExyZ6g+Ghh
X-Developer-Key: i=jiebing.chen@amlogic.com; a=ed25519;
 pk=6rFvvF45A84pLNRy03hfUHeROxHCnZ+1KAGw/DoqKic=
X-Endpoint-Received: by B4 Relay for jiebing.chen@amlogic.com/20250110 with auth_id=316
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add mclk pad div support, Increased the number of lrclk
and sclk pads to five

Signed-off-by: jiebing chen <jiebing.chen@amlogic.com>
---
 drivers/clk/meson/axg-audio.c | 441 +++++++++++++++++++++++++++++++++++++++++-
 drivers/clk/meson/axg-audio.h |   6 +
 2 files changed, 445 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/meson/axg-audio.c b/drivers/clk/meson/axg-audio.c
index 9df627b142f89788966ede0262aaaf39e13f0b49..50e7c78ddb98ee08121690633c8113489503bc04 100644
--- a/drivers/clk/meson/axg-audio.c
+++ b/drivers/clk/meson/axg-audio.c
@@ -323,6 +323,16 @@ static const struct clk_parent_data lrclk_pad_ctrl_parent_data[] = {
 	AUD_MUX(_name, _reg, 0x7, _shift, 0, _parents,		\
 		CLK_SET_RATE_NO_REPARENT)
 
+#define AUD_MCLK_PAD_MUX(_name, _reg, _shift)					\
+	AUD_MUX(_name##_sel, _reg, 0x7, _shift, CLK_MUX_ROUND_CLOSEST,			\
+		mclk_pad_ctrl_parent_data, 0)
+#define AUD_MCLK_PAD_DIV(_name, _reg, _shift)					\
+	AUD_DIV(_name##_div, _reg, _shift, 8, CLK_DIVIDER_ROUND_CLOSEST,			\
+		aud_##_name##_sel, CLK_SET_RATE_PARENT)
+#define AUD_MCLK_PAD_GATE(_name, _reg, _shift)					\
+	AUD_GATE(_name, _reg, _shift, aud_##_name##_div,			\
+		 CLK_SET_RATE_PARENT)
+
 /* Common Clocks */
 static struct clk_regmap ddr_arb =
 	AUD_PCLK_GATE(ddr_arb, AUDIO_CLK_GATE_EN, 0);
@@ -826,6 +836,49 @@ static struct clk_regmap sm1_tdm_sclk_pad_1 = AUD_TDM_PAD_CTRL(
 static struct clk_regmap sm1_tdm_sclk_pad_2 = AUD_TDM_PAD_CTRL(
 	tdm_sclk_pad_2, AUDIO_SM1_MST_PAD_CTRL1, 8, sclk_pad_ctrl_parent_data);
 
+static struct clk_regmap s4_tdm_mclk_pad0_sel =
+	AUD_MCLK_PAD_MUX(mclk_pad0, AUDIO_S4_MCLK_PAD_CTRL0, 8);
+static struct clk_regmap s4_tdm_mclk_pad1_sel =
+	AUD_MCLK_PAD_MUX(mclk_pad1, AUDIO_S4_MCLK_PAD_CTRL0, 24);
+static struct clk_regmap s4_tdm_mclk_pad2_sel =
+	AUD_MCLK_PAD_MUX(mclk_pad2, AUDIO_S4_MCLK_PAD_CTRL1, 8);
+
+static struct clk_regmap s4_tdm_mclk_pad0_div =
+	AUD_MCLK_PAD_DIV(mclk_pad0, AUDIO_S4_MCLK_PAD_CTRL0, 0);
+static struct clk_regmap s4_tdm_mclk_pad1_div =
+	AUD_MCLK_PAD_DIV(mclk_pad1, AUDIO_S4_MCLK_PAD_CTRL0, 16);
+static struct clk_regmap s4_tdm_mclk_pad2_div =
+	AUD_MCLK_PAD_DIV(mclk_pad2, AUDIO_S4_MCLK_PAD_CTRL1, 0);
+
+static struct clk_regmap s4_tdm_mclk_pad_0 =
+	AUD_MCLK_PAD_GATE(mclk_pad0, AUDIO_S4_MCLK_PAD_CTRL0, 15);
+static struct clk_regmap s4_tdm_mclk_pad_1 =
+	AUD_MCLK_PAD_GATE(mclk_pad1, AUDIO_S4_MCLK_PAD_CTRL0, 31);
+static struct clk_regmap s4_tdm_mclk_pad_2 =
+	AUD_MCLK_PAD_GATE(mclk_pad2, AUDIO_S4_MCLK_PAD_CTRL1, 15);
+
+static struct clk_regmap s4_tdm_sclk_pad_0 =
+	AUD_TDM_PAD_CTRL(tdm_sclk_pad_0, AUDIO_S4_SCLK_PAD_CTRL0, 0, lrclk_pad_ctrl_parent_data);
+static struct clk_regmap s4_tdm_sclk_pad_1 =
+	AUD_TDM_PAD_CTRL(tdm_sclk_pad_1, AUDIO_S4_SCLK_PAD_CTRL0, 4, lrclk_pad_ctrl_parent_data);
+static struct clk_regmap s4_tdm_sclk_pad_2 =
+	AUD_TDM_PAD_CTRL(tdm_sclk_pad_2, AUDIO_S4_SCLK_PAD_CTRL0, 8, lrclk_pad_ctrl_parent_data);
+static struct clk_regmap s4_tdm_sclk_pad_3 =
+	AUD_TDM_PAD_CTRL(tdm_sclk_pad_3, AUDIO_S4_SCLK_PAD_CTRL0, 16, lrclk_pad_ctrl_parent_data);
+static struct clk_regmap s4_tdm_sclk_pad_4 =
+	AUD_TDM_PAD_CTRL(tdm_sclk_pad_4, AUDIO_S4_SCLK_PAD_CTRL0, 20, lrclk_pad_ctrl_parent_data);
+
+static struct clk_regmap s4_tdm_lrclk_pad_0 =
+	AUD_TDM_PAD_CTRL(tdm_lrclk_pad_0, AUDIO_S4_SCLK_PAD_CTRL1, 0, lrclk_pad_ctrl_parent_data);
+static struct clk_regmap s4_tdm_lrclk_pad_1 =
+	AUD_TDM_PAD_CTRL(tdm_lrclk_pad_1, AUDIO_S4_SCLK_PAD_CTRL1, 4, lrclk_pad_ctrl_parent_data);
+static struct clk_regmap s4_tdm_lrclk_pad_2 =
+	AUD_TDM_PAD_CTRL(tdm_lrclk_pad_2, AUDIO_S4_SCLK_PAD_CTRL1, 8, lrclk_pad_ctrl_parent_data);
+static struct clk_regmap s4_tdm_lrclk_pad_3 =
+	AUD_TDM_PAD_CTRL(tdm_lrclk_pad_3, AUDIO_S4_SCLK_PAD_CTRL1, 16, lrclk_pad_ctrl_parent_data);
+static struct clk_regmap s4_tdm_lrclk_pad_4 =
+	AUD_TDM_PAD_CTRL(tdm_lrclk_pad_4, AUDIO_S4_SCLK_PAD_CTRL1, 20, lrclk_pad_ctrl_parent_data);
+
 /*
  * Array of all clocks provided by this provider
  * The input clocks of the controller will be populated at runtime
@@ -1257,6 +1310,177 @@ static struct clk_hw *sm1_audio_hw_clks[] = {
 	[AUD_CLKID_EARCRX_DMAC]		= &sm1_earcrx_dmac_clk.hw,
 };
 
+/*
+ * Array of all S4 clocks provided by this provider
+ * The input clocks of the controller will be populated at runtime
+ */
+static struct clk_hw *s4_audio_hw_clks[] = {
+	[AUD_CLKID_DDR_ARB]		= &ddr_arb.hw,
+	[AUD_CLKID_PDM]			= &pdm.hw,
+	[AUD_CLKID_TDMIN_A]		= &tdmin_a.hw,
+	[AUD_CLKID_TDMIN_B]		= &tdmin_b.hw,
+	[AUD_CLKID_TDMIN_C]		= &tdmin_c.hw,
+	[AUD_CLKID_TDMIN_LB]		= &tdmin_lb.hw,
+	[AUD_CLKID_TDMOUT_A]		= &tdmout_a.hw,
+	[AUD_CLKID_TDMOUT_B]		= &tdmout_b.hw,
+	[AUD_CLKID_TDMOUT_C]		= &tdmout_c.hw,
+	[AUD_CLKID_FRDDR_A]		= &frddr_a.hw,
+	[AUD_CLKID_FRDDR_B]		= &frddr_b.hw,
+	[AUD_CLKID_FRDDR_C]		= &frddr_c.hw,
+	[AUD_CLKID_TODDR_A]		= &toddr_a.hw,
+	[AUD_CLKID_TODDR_B]		= &toddr_b.hw,
+	[AUD_CLKID_TODDR_C]		= &toddr_c.hw,
+	[AUD_CLKID_LOOPBACK]		= &loopback.hw,
+	[AUD_CLKID_SPDIFIN]		= &spdifin.hw,
+	[AUD_CLKID_SPDIFOUT]		= &spdifout.hw,
+	[AUD_CLKID_RESAMPLE]		= &resample.hw,
+	[AUD_CLKID_SPDIFOUT_B]		= &spdifout_b.hw,
+	[AUD_CLKID_MST_A_MCLK_SEL]	= &sm1_mst_a_mclk_sel.hw,
+	[AUD_CLKID_MST_B_MCLK_SEL]	= &sm1_mst_b_mclk_sel.hw,
+	[AUD_CLKID_MST_C_MCLK_SEL]	= &sm1_mst_c_mclk_sel.hw,
+	[AUD_CLKID_MST_D_MCLK_SEL]	= &sm1_mst_d_mclk_sel.hw,
+	[AUD_CLKID_MST_E_MCLK_SEL]	= &sm1_mst_e_mclk_sel.hw,
+	[AUD_CLKID_MST_F_MCLK_SEL]	= &sm1_mst_f_mclk_sel.hw,
+	[AUD_CLKID_MST_A_MCLK_DIV]	= &sm1_mst_a_mclk_div.hw,
+	[AUD_CLKID_MST_B_MCLK_DIV]	= &sm1_mst_b_mclk_div.hw,
+	[AUD_CLKID_MST_C_MCLK_DIV]	= &sm1_mst_c_mclk_div.hw,
+	[AUD_CLKID_MST_D_MCLK_DIV]	= &sm1_mst_d_mclk_div.hw,
+	[AUD_CLKID_MST_E_MCLK_DIV]	= &sm1_mst_e_mclk_div.hw,
+	[AUD_CLKID_MST_F_MCLK_DIV]	= &sm1_mst_f_mclk_div.hw,
+	[AUD_CLKID_MST_A_MCLK]		= &sm1_mst_a_mclk.hw,
+	[AUD_CLKID_MST_B_MCLK]		= &sm1_mst_b_mclk.hw,
+	[AUD_CLKID_MST_C_MCLK]		= &sm1_mst_c_mclk.hw,
+	[AUD_CLKID_MST_D_MCLK]		= &sm1_mst_d_mclk.hw,
+	[AUD_CLKID_MST_E_MCLK]		= &sm1_mst_e_mclk.hw,
+	[AUD_CLKID_MST_F_MCLK]		= &sm1_mst_f_mclk.hw,
+	[AUD_CLKID_SPDIFOUT_CLK_SEL]	= &spdifout_clk_sel.hw,
+	[AUD_CLKID_SPDIFOUT_CLK_DIV]	= &spdifout_clk_div.hw,
+	[AUD_CLKID_SPDIFOUT_CLK]	= &spdifout_clk.hw,
+	[AUD_CLKID_SPDIFOUT_B_CLK_SEL]	= &spdifout_b_clk_sel.hw,
+	[AUD_CLKID_SPDIFOUT_B_CLK_DIV]	= &spdifout_b_clk_div.hw,
+	[AUD_CLKID_SPDIFOUT_B_CLK]	= &spdifout_b_clk.hw,
+	[AUD_CLKID_SPDIFIN_CLK_SEL]	= &spdifin_clk_sel.hw,
+	[AUD_CLKID_SPDIFIN_CLK_DIV]	= &spdifin_clk_div.hw,
+	[AUD_CLKID_SPDIFIN_CLK]		= &spdifin_clk.hw,
+	[AUD_CLKID_PDM_DCLK_SEL]	= &pdm_dclk_sel.hw,
+	[AUD_CLKID_PDM_DCLK_DIV]	= &pdm_dclk_div.hw,
+	[AUD_CLKID_PDM_DCLK]		= &pdm_dclk.hw,
+	[AUD_CLKID_PDM_SYSCLK_SEL]	= &pdm_sysclk_sel.hw,
+	[AUD_CLKID_PDM_SYSCLK_DIV]	= &pdm_sysclk_div.hw,
+	[AUD_CLKID_PDM_SYSCLK]		= &pdm_sysclk.hw,
+	[AUD_CLKID_MST_A_SCLK_PRE_EN]	= &mst_a_sclk_pre_en.hw,
+	[AUD_CLKID_MST_B_SCLK_PRE_EN]	= &mst_b_sclk_pre_en.hw,
+	[AUD_CLKID_MST_C_SCLK_PRE_EN]	= &mst_c_sclk_pre_en.hw,
+	[AUD_CLKID_MST_D_SCLK_PRE_EN]	= &mst_d_sclk_pre_en.hw,
+	[AUD_CLKID_MST_E_SCLK_PRE_EN]	= &mst_e_sclk_pre_en.hw,
+	[AUD_CLKID_MST_F_SCLK_PRE_EN]	= &mst_f_sclk_pre_en.hw,
+	[AUD_CLKID_MST_A_SCLK_DIV]	= &mst_a_sclk_div.hw,
+	[AUD_CLKID_MST_B_SCLK_DIV]	= &mst_b_sclk_div.hw,
+	[AUD_CLKID_MST_C_SCLK_DIV]	= &mst_c_sclk_div.hw,
+	[AUD_CLKID_MST_D_SCLK_DIV]	= &mst_d_sclk_div.hw,
+	[AUD_CLKID_MST_E_SCLK_DIV]	= &mst_e_sclk_div.hw,
+	[AUD_CLKID_MST_F_SCLK_DIV]	= &mst_f_sclk_div.hw,
+	[AUD_CLKID_MST_A_SCLK_POST_EN]	= &mst_a_sclk_post_en.hw,
+	[AUD_CLKID_MST_B_SCLK_POST_EN]	= &mst_b_sclk_post_en.hw,
+	[AUD_CLKID_MST_C_SCLK_POST_EN]	= &mst_c_sclk_post_en.hw,
+	[AUD_CLKID_MST_D_SCLK_POST_EN]	= &mst_d_sclk_post_en.hw,
+	[AUD_CLKID_MST_E_SCLK_POST_EN]	= &mst_e_sclk_post_en.hw,
+	[AUD_CLKID_MST_F_SCLK_POST_EN]	= &mst_f_sclk_post_en.hw,
+	[AUD_CLKID_MST_A_SCLK]		= &mst_a_sclk.hw,
+	[AUD_CLKID_MST_B_SCLK]		= &mst_b_sclk.hw,
+	[AUD_CLKID_MST_C_SCLK]		= &mst_c_sclk.hw,
+	[AUD_CLKID_MST_D_SCLK]		= &mst_d_sclk.hw,
+	[AUD_CLKID_MST_E_SCLK]		= &mst_e_sclk.hw,
+	[AUD_CLKID_MST_F_SCLK]		= &mst_f_sclk.hw,
+	[AUD_CLKID_MST_A_LRCLK_DIV]	= &mst_a_lrclk_div.hw,
+	[AUD_CLKID_MST_B_LRCLK_DIV]	= &mst_b_lrclk_div.hw,
+	[AUD_CLKID_MST_C_LRCLK_DIV]	= &mst_c_lrclk_div.hw,
+	[AUD_CLKID_MST_D_LRCLK_DIV]	= &mst_d_lrclk_div.hw,
+	[AUD_CLKID_MST_E_LRCLK_DIV]	= &mst_e_lrclk_div.hw,
+	[AUD_CLKID_MST_F_LRCLK_DIV]	= &mst_f_lrclk_div.hw,
+	[AUD_CLKID_MST_A_LRCLK]		= &mst_a_lrclk.hw,
+	[AUD_CLKID_MST_B_LRCLK]		= &mst_b_lrclk.hw,
+	[AUD_CLKID_MST_C_LRCLK]		= &mst_c_lrclk.hw,
+	[AUD_CLKID_MST_D_LRCLK]		= &mst_d_lrclk.hw,
+	[AUD_CLKID_MST_E_LRCLK]		= &mst_e_lrclk.hw,
+	[AUD_CLKID_MST_F_LRCLK]		= &mst_f_lrclk.hw,
+	[AUD_CLKID_TDMIN_A_SCLK_SEL]	= &tdmin_a_sclk_sel.hw,
+	[AUD_CLKID_TDMIN_B_SCLK_SEL]	= &tdmin_b_sclk_sel.hw,
+	[AUD_CLKID_TDMIN_C_SCLK_SEL]	= &tdmin_c_sclk_sel.hw,
+	[AUD_CLKID_TDMIN_LB_SCLK_SEL]	= &tdmin_lb_sclk_sel.hw,
+	[AUD_CLKID_TDMOUT_A_SCLK_SEL]	= &tdmout_a_sclk_sel.hw,
+	[AUD_CLKID_TDMOUT_B_SCLK_SEL]	= &tdmout_b_sclk_sel.hw,
+	[AUD_CLKID_TDMOUT_C_SCLK_SEL]	= &tdmout_c_sclk_sel.hw,
+	[AUD_CLKID_TDMIN_A_SCLK_PRE_EN]	= &tdmin_a_sclk_pre_en.hw,
+	[AUD_CLKID_TDMIN_B_SCLK_PRE_EN]	= &tdmin_b_sclk_pre_en.hw,
+	[AUD_CLKID_TDMIN_C_SCLK_PRE_EN]	= &tdmin_c_sclk_pre_en.hw,
+	[AUD_CLKID_TDMIN_LB_SCLK_PRE_EN] = &tdmin_lb_sclk_pre_en.hw,
+	[AUD_CLKID_TDMOUT_A_SCLK_PRE_EN] = &tdmout_a_sclk_pre_en.hw,
+	[AUD_CLKID_TDMOUT_B_SCLK_PRE_EN] = &tdmout_b_sclk_pre_en.hw,
+	[AUD_CLKID_TDMOUT_C_SCLK_PRE_EN] = &tdmout_c_sclk_pre_en.hw,
+	[AUD_CLKID_TDMIN_A_SCLK_POST_EN] = &tdmin_a_sclk_post_en.hw,
+	[AUD_CLKID_TDMIN_B_SCLK_POST_EN] = &tdmin_b_sclk_post_en.hw,
+	[AUD_CLKID_TDMIN_C_SCLK_POST_EN] = &tdmin_c_sclk_post_en.hw,
+	[AUD_CLKID_TDMIN_LB_SCLK_POST_EN] = &tdmin_lb_sclk_post_en.hw,
+	[AUD_CLKID_TDMOUT_A_SCLK_POST_EN] = &tdmout_a_sclk_post_en.hw,
+	[AUD_CLKID_TDMOUT_B_SCLK_POST_EN] = &tdmout_b_sclk_post_en.hw,
+	[AUD_CLKID_TDMOUT_C_SCLK_POST_EN] = &tdmout_c_sclk_post_en.hw,
+	[AUD_CLKID_TDMIN_A_SCLK]	= &tdmin_a_sclk.hw,
+	[AUD_CLKID_TDMIN_B_SCLK]	= &tdmin_b_sclk.hw,
+	[AUD_CLKID_TDMIN_C_SCLK]	= &tdmin_c_sclk.hw,
+	[AUD_CLKID_TDMIN_LB_SCLK]	= &tdmin_lb_sclk.hw,
+	[AUD_CLKID_TDMOUT_A_SCLK]	= &g12a_tdmout_a_sclk.hw,
+	[AUD_CLKID_TDMOUT_B_SCLK]	= &g12a_tdmout_b_sclk.hw,
+	[AUD_CLKID_TDMOUT_C_SCLK]	= &g12a_tdmout_c_sclk.hw,
+	[AUD_CLKID_TDMIN_A_LRCLK]	= &tdmin_a_lrclk.hw,
+	[AUD_CLKID_TDMIN_B_LRCLK]	= &tdmin_b_lrclk.hw,
+	[AUD_CLKID_TDMIN_C_LRCLK]	= &tdmin_c_lrclk.hw,
+	[AUD_CLKID_TDMIN_LB_LRCLK]	= &tdmin_lb_lrclk.hw,
+	[AUD_CLKID_TDMOUT_A_LRCLK]	= &tdmout_a_lrclk.hw,
+	[AUD_CLKID_TDMOUT_B_LRCLK]	= &tdmout_b_lrclk.hw,
+	[AUD_CLKID_TDMOUT_C_LRCLK]	= &tdmout_c_lrclk.hw,
+	[AUD_CLKID_TDM_MCLK_PAD0]	= &s4_tdm_mclk_pad_0.hw,
+	[AUD_CLKID_TDM_MCLK_PAD1]	= &s4_tdm_mclk_pad_1.hw,
+	[AUD_CLKID_TDM_LRCLK_PAD0]	= &s4_tdm_lrclk_pad_0.hw,
+	[AUD_CLKID_TDM_LRCLK_PAD1]	= &s4_tdm_lrclk_pad_1.hw,
+	[AUD_CLKID_TDM_LRCLK_PAD2]	= &s4_tdm_lrclk_pad_2.hw,
+	[AUD_CLKID_TDM_SCLK_PAD0]	= &s4_tdm_sclk_pad_0.hw,
+	[AUD_CLKID_TDM_SCLK_PAD1]	= &s4_tdm_sclk_pad_1.hw,
+	[AUD_CLKID_TDM_SCLK_PAD2]	= &s4_tdm_sclk_pad_2.hw,
+	[AUD_CLKID_TOP]			= &sm1_aud_top.hw,
+	[AUD_CLKID_TORAM]		= &toram.hw,
+	[AUD_CLKID_EQDRC]		= &eqdrc.hw,
+	[AUD_CLKID_RESAMPLE_B]		= &resample_b.hw,
+	[AUD_CLKID_TOVAD]		= &tovad.hw,
+	[AUD_CLKID_LOCKER]		= &locker.hw,
+	[AUD_CLKID_SPDIFIN_LB]		= &spdifin_lb.hw,
+	[AUD_CLKID_FRDDR_D]		= &frddr_d.hw,
+	[AUD_CLKID_TODDR_D]		= &toddr_d.hw,
+	[AUD_CLKID_LOOPBACK_B]		= &loopback_b.hw,
+	[AUD_CLKID_CLK81_EN]		= &sm1_clk81_en.hw,
+	[AUD_CLKID_SYSCLK_A_DIV]	= &sm1_sysclk_a_div.hw,
+	[AUD_CLKID_SYSCLK_A_EN]		= &sm1_sysclk_a_en.hw,
+	[AUD_CLKID_SYSCLK_B_DIV]	= &sm1_sysclk_b_div.hw,
+	[AUD_CLKID_SYSCLK_B_EN]		= &sm1_sysclk_b_en.hw,
+	[AUD_CLKID_EARCRX]		= &earcrx.hw,
+	[AUD_CLKID_EARCRX_CMDC_SEL]	= &sm1_earcrx_cmdc_clk_sel.hw,
+	[AUD_CLKID_EARCRX_CMDC_DIV]	= &sm1_earcrx_cmdc_clk_div.hw,
+	[AUD_CLKID_EARCRX_CMDC]		= &sm1_earcrx_cmdc_clk.hw,
+	[AUD_CLKID_EARCRX_DMAC_SEL]	= &sm1_earcrx_dmac_clk_sel.hw,
+	[AUD_CLKID_EARCRX_DMAC_DIV]	= &sm1_earcrx_dmac_clk_div.hw,
+	[AUD_CLKID_EARCRX_DMAC]		= &sm1_earcrx_dmac_clk.hw,
+	[AUD_CLKID_TDM_MCLK_PAD0_SEL]		= &s4_tdm_mclk_pad0_sel.hw,
+	[AUD_CLKID_TDM_MCLK_PAD1_SEL]       = &s4_tdm_mclk_pad1_sel.hw,
+	[AUD_CLKID_TDM_MCLK_PAD0_DIV]		= &s4_tdm_mclk_pad0_div.hw,
+	[AUD_CLKID_TDM_MCLK_PAD1_DIV]       = &s4_tdm_mclk_pad1_div.hw,
+	[AUD_CLKID_TDM_MCLK_PAD2]	        = &s4_tdm_mclk_pad_2.hw,
+	[AUD_CLKID_TDM_MCLK_PAD2_SEL]		= &s4_tdm_mclk_pad2_sel.hw,
+	[AUD_CLKID_TDM_MCLK_PAD2_DIV]       = &s4_tdm_mclk_pad2_div.hw,
+	[AUD_CLKID_TDM_SCLK_PAD3]	= &s4_tdm_sclk_pad_3.hw,
+	[AUD_CLKID_TDM_SCLK_PAD4]	= &s4_tdm_sclk_pad_4.hw,
+	[AUD_CLKID_TDM_LRCLK_PAD3]	= &s4_tdm_lrclk_pad_3.hw,
+	[AUD_CLKID_TDM_LRCLK_PAD4]	= &s4_tdm_lrclk_pad_4.hw,
+};
 
 /* Convenience table to populate regmap in .probe(). */
 static struct clk_regmap *const axg_clk_regmaps[] = {
@@ -1678,6 +1902,177 @@ static struct clk_regmap *const sm1_clk_regmaps[] = {
 	&sm1_earcrx_dmac_clk,
 };
 
+static struct clk_regmap *const s4_clk_regmaps[] = {
+	&ddr_arb,
+	&pdm,
+	&tdmin_a,
+	&tdmin_b,
+	&tdmin_c,
+	&tdmin_lb,
+	&tdmout_a,
+	&tdmout_b,
+	&tdmout_c,
+	&frddr_a,
+	&frddr_b,
+	&frddr_c,
+	&toddr_a,
+	&toddr_b,
+	&toddr_c,
+	&loopback,
+	&spdifin,
+	&spdifout,
+	&resample,
+	&spdifout_b,
+	&sm1_mst_a_mclk_sel,
+	&sm1_mst_b_mclk_sel,
+	&sm1_mst_c_mclk_sel,
+	&sm1_mst_d_mclk_sel,
+	&sm1_mst_e_mclk_sel,
+	&sm1_mst_f_mclk_sel,
+	&sm1_mst_a_mclk_div,
+	&sm1_mst_b_mclk_div,
+	&sm1_mst_c_mclk_div,
+	&sm1_mst_d_mclk_div,
+	&sm1_mst_e_mclk_div,
+	&sm1_mst_f_mclk_div,
+	&sm1_mst_a_mclk,
+	&sm1_mst_b_mclk,
+	&sm1_mst_c_mclk,
+	&sm1_mst_d_mclk,
+	&sm1_mst_e_mclk,
+	&sm1_mst_f_mclk,
+	&spdifout_clk_sel,
+	&spdifout_clk_div,
+	&spdifout_clk,
+	&spdifin_clk_sel,
+	&spdifin_clk_div,
+	&spdifin_clk,
+	&pdm_dclk_sel,
+	&pdm_dclk_div,
+	&pdm_dclk,
+	&pdm_sysclk_sel,
+	&pdm_sysclk_div,
+	&pdm_sysclk,
+	&mst_a_sclk_pre_en,
+	&mst_b_sclk_pre_en,
+	&mst_c_sclk_pre_en,
+	&mst_d_sclk_pre_en,
+	&mst_e_sclk_pre_en,
+	&mst_f_sclk_pre_en,
+	&mst_a_sclk_div,
+	&mst_b_sclk_div,
+	&mst_c_sclk_div,
+	&mst_d_sclk_div,
+	&mst_e_sclk_div,
+	&mst_f_sclk_div,
+	&mst_a_sclk_post_en,
+	&mst_b_sclk_post_en,
+	&mst_c_sclk_post_en,
+	&mst_d_sclk_post_en,
+	&mst_e_sclk_post_en,
+	&mst_f_sclk_post_en,
+	&mst_a_sclk,
+	&mst_b_sclk,
+	&mst_c_sclk,
+	&mst_d_sclk,
+	&mst_e_sclk,
+	&mst_f_sclk,
+	&mst_a_lrclk_div,
+	&mst_b_lrclk_div,
+	&mst_c_lrclk_div,
+	&mst_d_lrclk_div,
+	&mst_e_lrclk_div,
+	&mst_f_lrclk_div,
+	&mst_a_lrclk,
+	&mst_b_lrclk,
+	&mst_c_lrclk,
+	&mst_d_lrclk,
+	&mst_e_lrclk,
+	&mst_f_lrclk,
+	&tdmin_a_sclk_sel,
+	&tdmin_b_sclk_sel,
+	&tdmin_c_sclk_sel,
+	&tdmin_lb_sclk_sel,
+	&tdmout_a_sclk_sel,
+	&tdmout_b_sclk_sel,
+	&tdmout_c_sclk_sel,
+	&tdmin_a_sclk_pre_en,
+	&tdmin_b_sclk_pre_en,
+	&tdmin_c_sclk_pre_en,
+	&tdmin_lb_sclk_pre_en,
+	&tdmout_a_sclk_pre_en,
+	&tdmout_b_sclk_pre_en,
+	&tdmout_c_sclk_pre_en,
+	&tdmin_a_sclk_post_en,
+	&tdmin_b_sclk_post_en,
+	&tdmin_c_sclk_post_en,
+	&tdmin_lb_sclk_post_en,
+	&tdmout_a_sclk_post_en,
+	&tdmout_b_sclk_post_en,
+	&tdmout_c_sclk_post_en,
+	&tdmin_a_sclk,
+	&tdmin_b_sclk,
+	&tdmin_c_sclk,
+	&tdmin_lb_sclk,
+	&g12a_tdmout_a_sclk,
+	&g12a_tdmout_b_sclk,
+	&g12a_tdmout_c_sclk,
+	&tdmin_a_lrclk,
+	&tdmin_b_lrclk,
+	&tdmin_c_lrclk,
+	&tdmin_lb_lrclk,
+	&tdmout_a_lrclk,
+	&tdmout_b_lrclk,
+	&tdmout_c_lrclk,
+	&spdifout_b_clk_sel,
+	&spdifout_b_clk_div,
+	&spdifout_b_clk,
+	&sm1_aud_top,
+	&toram,
+	&eqdrc,
+	&resample_b,
+	&tovad,
+	&locker,
+	&spdifin_lb,
+	&frddr_d,
+	&toddr_d,
+	&loopback_b,
+	&sm1_clk81_en,
+	&sm1_sysclk_a_div,
+	&sm1_sysclk_a_en,
+	&sm1_sysclk_b_div,
+	&sm1_sysclk_b_en,
+	&earcrx,
+	&sm1_earcrx_cmdc_clk_sel,
+	&sm1_earcrx_cmdc_clk_div,
+	&sm1_earcrx_cmdc_clk,
+	&sm1_earcrx_dmac_clk_sel,
+	&sm1_earcrx_dmac_clk_div,
+	&sm1_earcrx_dmac_clk,
+};
+
+static struct clk_regmap *const s4_clk_pad_regmaps[] = {
+	&s4_tdm_mclk_pad_0,
+	&s4_tdm_mclk_pad_1,
+	&s4_tdm_mclk_pad_2,
+	&s4_tdm_lrclk_pad_0,
+	&s4_tdm_lrclk_pad_1,
+	&s4_tdm_lrclk_pad_2,
+	&s4_tdm_lrclk_pad_3,
+	&s4_tdm_lrclk_pad_4,
+	&s4_tdm_sclk_pad_0,
+	&s4_tdm_sclk_pad_1,
+	&s4_tdm_sclk_pad_2,
+	&s4_tdm_sclk_pad_3,
+	&s4_tdm_sclk_pad_4,
+	&s4_tdm_mclk_pad0_sel,
+	&s4_tdm_mclk_pad1_sel,
+	&s4_tdm_mclk_pad0_div,
+	&s4_tdm_mclk_pad1_div,
+	&s4_tdm_mclk_pad2_sel,
+	&s4_tdm_mclk_pad2_div,
+};
+
 struct axg_audio_reset_data {
 	struct reset_controller_dev rstc;
 	struct regmap *map;
@@ -1764,13 +2159,20 @@ static struct regmap_config axg_audio_regmap_cfg = {
 
 struct audioclk_data {
 	struct clk_regmap *const *regmap_clks;
+	struct clk_regmap *const *regmap_clks_pads;
 	unsigned int regmap_clk_num;
+	unsigned int regmap_clk_pads_num;
 	struct meson_clk_hw_data hw_clks;
 	unsigned int reset_offset;
 	unsigned int reset_num;
 	unsigned int max_register;
 };
 
+static int audio_clock_pad_is_new_regmap(struct device_node *np)
+{
+	return of_device_is_compatible(np, "amlogic,s4-audio-clkc");
+}
+
 static int axg_audio_clkc_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
@@ -1812,6 +2214,25 @@ static int axg_audio_clkc_probe(struct platform_device *pdev)
 	for (i = 0; i < data->regmap_clk_num; i++)
 		data->regmap_clks[i]->map = map;
 
+	/* some amlogic chip clock pad reg domian is different */
+	if (audio_clock_pad_is_new_regmap(dev->of_node)) {
+		struct resource *res;
+		static const struct regmap_config aud_regmap_config = {
+			.reg_bits = 32,
+			.val_bits = 32,
+			.reg_stride = 4,
+		};
+		regs = devm_platform_get_and_ioremap_resource(pdev, 1, &res);
+		if (IS_ERR(regs))
+			return PTR_ERR(regs);
+		aud_regmap_config.max_register = resource_size(res) - 4;
+		aud_regmap_config.name =
+			devm_kasprintf(dev, GFP_KERNEL, "%s-%s", dev->of_node->name, "pads");
+		map = devm_regmap_init_mmio(dev, regs, &aud_regmap_config);
+		/* Populate clk pad regmap for the regmap backed clocks */
+		for (i = 0; i < data->regmap_clk_pads_num; i++)
+			data->regmap_clks_pads[i]->map = map;
+	}
 	/* Take care to skip the registered input clocks */
 	for (i = AUD_CLKID_DDR_ARB; i < data->hw_clks.num; i++) {
 		const char *name;
@@ -1822,7 +2243,6 @@ static int axg_audio_clkc_probe(struct platform_device *pdev)
 			continue;
 
 		name = hw->init->name;
-
 		ret = devm_clk_hw_register(dev, hw);
 		if (ret) {
 			dev_err(dev, "failed to register clock %s\n", name);
@@ -1886,6 +2306,20 @@ static const struct audioclk_data sm1_audioclk_data = {
 	.max_register = AUDIO_EARCRX_DMAC_CLK_CTRL,
 };
 
+static const struct audioclk_data s4_audioclk_data = {
+	.regmap_clks = s4_clk_regmaps,
+	.regmap_clk_num = ARRAY_SIZE(s4_clk_regmaps),
+	.regmap_clks_pads = s4_clk_pad_regmaps,
+	.regmap_clk_pads_num = ARRAY_SIZE(s4_clk_pad_regmaps),
+	.hw_clks = {
+		.hws = s4_audio_hw_clks,
+		.num = ARRAY_SIZE(s4_audio_hw_clks),
+	},
+	.reset_offset = AUDIO_SM1_SW_RESET0,
+	.reset_num = 39,
+	.max_register = AUDIO_EARCRX_DMAC_CLK_CTRL,
+};
+
 static const struct of_device_id clkc_match_table[] = {
 	{
 		.compatible = "amlogic,axg-audio-clkc",
@@ -1896,7 +2330,10 @@ static const struct of_device_id clkc_match_table[] = {
 	}, {
 		.compatible = "amlogic,sm1-audio-clkc",
 		.data = &sm1_audioclk_data
-	}, {}
+	}, {
+		.compatible = "amlogic,s4-audio-clkc",
+		.data = &s4_audioclk_data
+	}, { }
 };
 MODULE_DEVICE_TABLE(of, clkc_match_table);
 
diff --git a/drivers/clk/meson/axg-audio.h b/drivers/clk/meson/axg-audio.h
index 9e7765b630c96a8029140539ffda789b7db5277a..24233c40171034eba86c699db0200f07555926af 100644
--- a/drivers/clk/meson/axg-audio.h
+++ b/drivers/clk/meson/axg-audio.h
@@ -67,4 +67,10 @@
 #define AUDIO_EARCRX_CMDC_CLK_CTRL	0x0D0
 #define AUDIO_EARCRX_DMAC_CLK_CTRL	0x0D4
 
+/* s4 clock pads use new reg base */
+#define AUDIO_S4_MCLK_PAD_CTRL0 0x0
+#define AUDIO_S4_MCLK_PAD_CTRL1 0x4
+#define AUDIO_S4_SCLK_PAD_CTRL0 0x8
+#define AUDIO_S4_SCLK_PAD_CTRL1 0xC
+
 #endif /*__AXG_AUDIO_CLKC_H */

-- 
2.43.0

