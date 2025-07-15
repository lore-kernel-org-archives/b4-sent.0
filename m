From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 15 Jul 2025 20:51:39 +0800
Subject: [PATCH 2/2] clk: amlogic: add video-related clocks for S4 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250715-add_video_clk-v1-2-40e7f633f361@amlogic.com>
References: <20250715-add_video_clk-v1-0-40e7f633f361@amlogic.com>
In-Reply-To: <20250715-add_video_clk-v1-0-40e7f633f361@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752583900; l=8635;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=Krtad04/LG3f+yownUO/6hPuVzIprI6Y8mPsJSZ7oMw=;
 b=jMVksC6mymjR/byiSiIbxFAfx7pwBYMaXcaQETql3fxq9FmaUM3nN9ryk8syF2Odt2oCBZWxJ
 RjEY4HOiEX0BWIlX5Euy1Nr9fgwZqRu9fMde0pvZjR6DRkHeT2LdkmL
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add video encoder, demodulator and CVBS clocks.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/s4-peripherals.c | 256 +++++++++++++++++++++++++++++++++++++
 1 file changed, 256 insertions(+)

diff --git a/drivers/clk/meson/s4-peripherals.c b/drivers/clk/meson/s4-peripherals.c
index c9400cf54c84..f43526d506b1 100644
--- a/drivers/clk/meson/s4-peripherals.c
+++ b/drivers/clk/meson/s4-peripherals.c
@@ -44,6 +44,7 @@
 #define CLKCTRL_VDIN_MEAS_CLK_CTRL                 0x0f8
 #define CLKCTRL_VAPBCLK_CTRL                       0x0fc
 #define CLKCTRL_HDCP22_CTRL                        0x100
+#define CLKCTRL_CDAC_CLK_CTRL                      0x108
 #define CLKCTRL_VDEC_CLK_CTRL                      0x140
 #define CLKCTRL_VDEC2_CLK_CTRL                     0x144
 #define CLKCTRL_VDEC3_CLK_CTRL                     0x148
@@ -1117,6 +1118,22 @@ static struct clk_regmap s4_cts_encp_sel = {
 	},
 };
 
+static struct clk_regmap s4_cts_encl_sel = {
+	.data = &(struct clk_regmap_mux_data){
+		.offset = CLKCTRL_VIID_CLK_DIV,
+		.mask = 0xf,
+		.shift = 12,
+		.table = mux_table_cts_sel,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "cts_encl_sel",
+		.ops = &clk_regmap_mux_ops,
+		.parent_hws = s4_cts_parent_hws,
+		.num_parents = ARRAY_SIZE(s4_cts_parent_hws),
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
 static struct clk_regmap s4_cts_vdac_sel = {
 	.data = &(struct clk_regmap_mux_data){
 		.offset = CLKCTRL_VIID_CLK_DIV,
@@ -1196,6 +1213,22 @@ static struct clk_regmap s4_cts_encp = {
 	},
 };
 
+static struct clk_regmap s4_cts_encl = {
+	.data = &(struct clk_regmap_gate_data){
+		.offset = CLKCTRL_VID_CLK_CTRL2,
+		.bit_idx = 3,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "cts_encl",
+		.ops = &clk_regmap_gate_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_cts_encl_sel.hw
+		},
+		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
 static struct clk_regmap s4_cts_vdac = {
 	.data = &(struct clk_regmap_gate_data){
 		.offset = CLKCTRL_VID_CLK_CTRL2,
@@ -1228,6 +1261,56 @@ static struct clk_regmap s4_hdmi_tx = {
 	},
 };
 
+static struct clk_regmap s4_lcd_an_sel = {
+	.data = &(struct clk_regmap_mux_data){
+		.offset = CLKCTRL_VIID_CLK_DIV,
+		.mask = 0x1,
+		.shift = 11,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "lcd_an_sel",
+		.ops = &clk_regmap_mux_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_vclk_div6.hw,
+			&s4_vclk_div12.hw,
+		},
+		.num_parents = 2,
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
+static struct clk_regmap s4_lcd_an_ph2 = {
+	.data = &(struct clk_regmap_gate_data){
+		.offset = CLKCTRL_VID_CLK_CTRL2,
+		.bit_idx = 7,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "lcd_an_ph2",
+		.ops = &clk_regmap_gate_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_lcd_an_sel.hw
+		},
+		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
+static struct clk_regmap s4_lcd_an_ph3 = {
+	.data = &(struct clk_regmap_gate_data){
+		.offset = CLKCTRL_VID_CLK_CTRL2,
+		.bit_idx = 7,
+	},
+	.hw.init = &(struct clk_init_data) {
+		.name = "lcd_an_ph3",
+		.ops = &clk_regmap_gate_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_lcd_an_sel.hw
+		},
+		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
 /* HDMI Clocks */
 static const struct clk_parent_data s4_hdmi_parent_data[] = {
 	{ .fw_name = "xtal", },
@@ -3174,6 +3257,165 @@ static struct clk_regmap s4_gen_clk = {
 	},
 };
 
+/* CVBS DAC */
+static struct clk_regmap s4_cdac_sel = {
+	.data = &(struct clk_regmap_mux_data) {
+		.offset = CLKCTRL_CDAC_CLK_CTRL,
+		.mask = 0x3,
+		.shift = 16,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "cdac_sel",
+		.ops = &clk_regmap_mux_ops,
+		.parent_data = (const struct clk_parent_data []) {
+			{ .fw_name = "xtal", },
+			{ .fw_name = "fclk_div5" },
+		},
+		.num_parents = 2,
+	},
+};
+
+static struct clk_regmap s4_cdac_div = {
+	.data = &(struct clk_regmap_div_data) {
+		.offset = CLKCTRL_CDAC_CLK_CTRL,
+		.shift = 0,
+		.width = 16,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "cdac_div",
+		.ops = &clk_regmap_divider_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_cdac_sel.hw
+		},
+		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
+static struct clk_regmap s4_cdac = {
+	.data = &(struct clk_regmap_gate_data) {
+		.offset = CLKCTRL_CDAC_CLK_CTRL,
+		.bit_idx = 20,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "cdac",
+		.ops = &clk_regmap_gate_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_cdac_div.hw
+		},
+		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
+static struct clk_regmap s4_demod_core_sel = {
+	.data = &(struct clk_regmap_mux_data) {
+		.offset = CLKCTRL_DEMOD_CLK_CTRL,
+		.mask = 0x3,
+		.shift = 9,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "demod_core_sel",
+		.ops = &clk_regmap_mux_ops,
+		.parent_data = (const struct clk_parent_data []) {
+			{ .fw_name = "xtal" },
+			{ .fw_name = "fclk_div7" },
+			{ .fw_name = "fclk_div4" }
+		},
+		.num_parents = 3,
+	},
+};
+
+static struct clk_regmap s4_demod_core_div = {
+	.data = &(struct clk_regmap_div_data) {
+		.offset = CLKCTRL_DEMOD_CLK_CTRL,
+		.shift = 0,
+		.width = 7,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "demod_core_div",
+		.ops = &clk_regmap_divider_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_demod_core_sel.hw
+		},
+		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
+static struct clk_regmap s4_demod_core = {
+	.data = &(struct clk_regmap_gate_data) {
+		.offset = CLKCTRL_DEMOD_CLK_CTRL,
+		.bit_idx = 8
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "demod_core",
+		.ops = &clk_regmap_gate_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_demod_core_div.hw
+		},
+		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
+/* CVBS ADC */
+static struct clk_regmap s4_adc_extclk_in_sel = {
+	.data = &(struct clk_regmap_mux_data) {
+		.offset = CLKCTRL_DEMOD_CLK_CTRL,
+		.mask = 0x7,
+		.shift = 25,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "adc_extclk_in_sel",
+		.ops = &clk_regmap_mux_ops,
+		.parent_data = (const struct clk_parent_data []) {
+			{ .fw_name = "xtal" },
+			{ .fw_name = "fclk_div4" },
+			{ .fw_name = "fclk_div3" },
+			{ .fw_name = "fclk_div5" },
+			{ .fw_name = "fclk_div7" },
+			{ .fw_name = "mpll2" },
+			{ .fw_name = "gp0_pll" },
+			{ .fw_name = "hifi_pll" }
+		},
+		.num_parents = 8,
+	},
+};
+
+static struct clk_regmap s4_adc_extclk_in_div = {
+	.data = &(struct clk_regmap_div_data) {
+		.offset = CLKCTRL_DEMOD_CLK_CTRL,
+		.shift = 16,
+		.width = 7,
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "adc_extclk_in_div",
+		.ops = &clk_regmap_divider_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_adc_extclk_in_sel.hw
+		},
+		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
+static struct clk_regmap s4_adc_extclk_in = {
+	.data = &(struct clk_regmap_gate_data) {
+		.offset = CLKCTRL_DEMOD_CLK_CTRL,
+		.bit_idx = 24
+	},
+	.hw.init = &(struct clk_init_data){
+		.name = "adc_extclk_in",
+		.ops = &clk_regmap_gate_ops,
+		.parent_hws = (const struct clk_hw *[]) {
+			&s4_adc_extclk_in_div.hw
+		},
+		.num_parents = 1,
+		.flags = CLK_SET_RATE_PARENT,
+	},
+};
+
 #define MESON_GATE(_name, _reg, _bit) \
 	MESON_PCLK(_name, _reg, _bit, &s4_sys_clk.hw)
 
@@ -3453,6 +3695,20 @@ static struct clk_hw *s4_periphs_hw_clks[] = {
 	[CLKID_HDCP22_SKPCLK_SEL]	= &s4_hdcp22_skpclk_mux.hw,
 	[CLKID_HDCP22_SKPCLK_DIV]	= &s4_hdcp22_skpclk_div.hw,
 	[CLKID_HDCP22_SKPCLK]		= &s4_hdcp22_skpclk_gate.hw,
+	[CLKID_CTS_ENCL_SEL]		= &s4_cts_encl_sel.hw,
+	[CLKID_CTS_ENCL]		= &s4_cts_encl.hw,
+	[CLKID_LCD_AN_SEL]		= &s4_lcd_an_sel.hw,
+	[CLKID_LCD_AN_PH2]		= &s4_lcd_an_ph2.hw,
+	[CLKID_LCD_AN_PH3]		= &s4_lcd_an_ph3.hw,
+	[CLKID_CDAC_SEL]		= &s4_cdac_sel.hw,
+	[CLKID_CDAC_DIV]		= &s4_cdac_div.hw,
+	[CLKID_CDAC]			= &s4_cdac.hw,
+	[CLKID_DEMOD_CORE_SEL]		= &s4_demod_core_sel.hw,
+	[CLKID_DEMOD_CORE_DIV]		= &s4_demod_core_div.hw,
+	[CLKID_DEMOD_CORE]		= &s4_demod_core.hw,
+	[CLKID_ADC_EXTCLK_IN_SEL]	= &s4_adc_extclk_in_sel.hw,
+	[CLKID_ADC_EXTCLK_IN_DIV]	= &s4_adc_extclk_in_div.hw,
+	[CLKID_ADC_EXTCLK_IN]		= &s4_adc_extclk_in.hw,
 };
 
 static const struct regmap_config clkc_regmap_config = {

-- 
2.42.0

