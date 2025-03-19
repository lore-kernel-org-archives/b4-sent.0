From: jiebing chen <jiebing.chen@amlogic.com>
Date: Wed, 19 Mar 2025 15:04:47 +0800
Subject: [PATCH v4 4/6] ASoC: meson: g12a-toacodec: Add s4 tocodec driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-audio_drvier-v4-4-686867fad719@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742367998; l=4024;
 i=jiebing.chen@amlogic.com; s=20250110; h=from:subject:message-id;
 bh=eyHcdpkfMqVY347i0/Y7l/fGm8VvnCZTc/KsX9aimF4=;
 b=A36VuBHcvnSfvBeYfUCeLDwCHRTvhRfcikwciTn1IV/brEWs4kxcydgpq9xlEyfjS/XNBvSt1
 t3nR/Wo3v+WCf5Gq7pzx+WvToYMAfaP5jzMhrtjf3g6riD7MnX8Exdu
X-Developer-Key: i=jiebing.chen@amlogic.com; a=ed25519;
 pk=6rFvvF45A84pLNRy03hfUHeROxHCnZ+1KAGw/DoqKic=
X-Endpoint-Received: by B4 Relay for jiebing.chen@amlogic.com/20250110 with auth_id=316
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

S4 tocodec support 8 lane to input, It need to enable
bclk and mclk control bit when work

Signed-off-by: jiebing chen <jiebing.chen@amlogic.com>
---
 sound/soc/meson/g12a-toacodec.c | 46 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 46 insertions(+)

diff --git a/sound/soc/meson/g12a-toacodec.c b/sound/soc/meson/g12a-toacodec.c
index 531bb8707a3ec4c47814d6a0676d5c62c705da75..88f9adabb3b5d7d8881fa110f1d0d51e9ac9c60e 100644
--- a/sound/soc/meson/g12a-toacodec.c
+++ b/sound/soc/meson/g12a-toacodec.c
@@ -41,6 +41,9 @@
 #define  CTRL0_BCLK_SEL_LSB		4
 #define  CTRL0_MCLK_SEL			GENMASK(2, 0)
 
+#define CTRL0_BCLK_ENABLE_SHIFT		30
+#define CTRL0_MCLK_ENABLE_SHIFT		29
+
 #define TOACODEC_OUT_CHMAX		2
 
 struct g12a_toacodec {
@@ -129,6 +132,10 @@ static const struct snd_kcontrol_new g12a_toacodec_out_enable =
 	SOC_DAPM_SINGLE_AUTODISABLE("Switch", TOACODEC_CTRL0,
 				    CTRL0_ENABLE_SHIFT, 1, 0);
 
+static const struct snd_kcontrol_new s4_toacodec_clk_enable =
+	SOC_DAPM_DOUBLE("Switch", TOACODEC_CTRL0,
+			CTRL0_BCLK_ENABLE_SHIFT, CTRL0_MCLK_ENABLE_SHIFT, 1, 0);
+
 static const struct snd_soc_dapm_widget g12a_toacodec_widgets[] = {
 	SND_SOC_DAPM_MUX("SRC", SND_SOC_NOPM, 0, 0,
 			 &g12a_toacodec_mux),
@@ -143,6 +150,19 @@ static const struct snd_soc_dapm_widget sm1_toacodec_widgets[] = {
 			    &g12a_toacodec_out_enable),
 };
 
+/*
+ * FIXME:
+ * On this soc, tocodec need enable mclk and bclk control
+ * just enable it when dapm power widget power on.
+ */
+
+static const struct snd_soc_dapm_widget s4_toacodec_widgets[] = {
+	SND_SOC_DAPM_MUX("SRC", TOACODEC_CTRL0, CTRL0_BCLK_ENABLE_SHIFT, 0,
+			 &sm1_toacodec_mux),
+	SND_SOC_DAPM_SWITCH("OUT EN", TOACODEC_CTRL0, CTRL0_MCLK_ENABLE_SHIFT, 0,
+			    &g12a_toacodec_out_enable),
+};
+
 static int g12a_toacodec_input_hw_params(struct snd_pcm_substream *substream,
 					 struct snd_pcm_hw_params *params,
 					 struct snd_soc_dai *dai)
@@ -236,6 +256,10 @@ static const struct snd_kcontrol_new sm1_toacodec_controls[] = {
 	SOC_SINGLE("Lane Select", TOACODEC_CTRL0, CTRL0_LANE_SEL_SM1, 3, 0),
 };
 
+static const struct snd_kcontrol_new s4_toacodec_controls[] = {
+	SOC_SINGLE("Lane Select", TOACODEC_CTRL0, CTRL0_LANE_SEL_SM1, 7, 0),
+};
+
 static const struct snd_soc_component_driver g12a_toacodec_component_drv = {
 	.probe			= g12a_toacodec_component_probe,
 	.controls		= g12a_toacodec_controls,
@@ -258,6 +282,17 @@ static const struct snd_soc_component_driver sm1_toacodec_component_drv = {
 	.endianness		= 1,
 };
 
+static const struct snd_soc_component_driver s4_toacodec_component_drv = {
+	.probe			= sm1_toacodec_component_probe,
+	.controls		= s4_toacodec_controls,
+	.num_controls		= ARRAY_SIZE(s4_toacodec_controls),
+	.dapm_widgets		= s4_toacodec_widgets,
+	.num_dapm_widgets	= ARRAY_SIZE(s4_toacodec_widgets),
+	.dapm_routes		= g12a_toacodec_routes,
+	.num_dapm_routes	= ARRAY_SIZE(g12a_toacodec_routes),
+	.endianness		= 1,
+};
+
 static const struct regmap_config g12a_toacodec_regmap_cfg = {
 	.reg_bits	= 32,
 	.val_bits	= 32,
@@ -278,6 +313,13 @@ static const struct g12a_toacodec_match_data sm1_toacodec_match_data = {
 	.field_bclk_sel	= REG_FIELD(TOACODEC_CTRL0, 4, 6),
 };
 
+static const struct g12a_toacodec_match_data s4_toacodec_match_data = {
+	.component_drv	= &s4_toacodec_component_drv,
+	.field_dat_sel	= REG_FIELD(TOACODEC_CTRL0, 19, 20),
+	.field_lrclk_sel = REG_FIELD(TOACODEC_CTRL0, 12, 14),
+	.field_bclk_sel	= REG_FIELD(TOACODEC_CTRL0, 4, 6),
+};
+
 static const struct of_device_id g12a_toacodec_of_match[] = {
 	{
 		.compatible = "amlogic,g12a-toacodec",
@@ -287,6 +329,10 @@ static const struct of_device_id g12a_toacodec_of_match[] = {
 		.compatible = "amlogic,sm1-toacodec",
 		.data = &sm1_toacodec_match_data,
 	},
+	{
+		.compatible = "amlogic,s4-toacodec",
+		.data = &s4_toacodec_match_data,
+	},
 	{}
 };
 MODULE_DEVICE_TABLE(of, g12a_toacodec_of_match);

-- 
2.43.0

