From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 16 Nov 2026 01:50:29 +0530
Subject: [PATCH 2/2] ASoC: qcom: sc8280xp: Add Motorola Signature sound
 card
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-vantage-sndcard-v1-2-df69a8759833@yahoo.com>
References: <20261116-vantage-sndcard-v1-0-df69a8759833@yahoo.com>
In-Reply-To: <20261116-vantage-sndcard-v1-0-df69a8759833@yahoo.com>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794774027; l=2831;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=4FOxSNJEx2JFAz0a5OgUofLrt5b17E6UxlzHA/kMQp4=;
 b=73+28dEXvSGlfy/dWegzNcPu0jfY1zX4cWN7VBCHfqORYJCihq0AE7TYQ2h8V8efKNZLmSSMH
 nlUVnN+c533DsMuqPopvvWzQYHjxHy2hd510AVkTdLIA836KkzIxWQw
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Motorola Signature (vantage) has two TFA9865 amplifiers on the
senary MI2S interface, which expect 32-bit I2S slots. Add an option for
32-bit MI2S backends, enable the MI2S bit clock and add the card.

An LLM was used to help write this commit message.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 sound/soc/qcom/sc8280xp.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/sound/soc/qcom/sc8280xp.c b/sound/soc/qcom/sc8280xp.c
index e136407c56bf..320d4b80b07b 100644
--- a/sound/soc/qcom/sc8280xp.c
+++ b/sound/soc/qcom/sc8280xp.c
@@ -93,6 +93,7 @@ struct qcom_snd_soc_common {
 	bool codec_sysclk_set;
 	bool mi2s_mclk_enable;
 	bool mi2s_bclk_enable;
+	bool mi2s_32bit;
 	bool wcd_jack;
 	const struct sc8280xp_dai_data *dai_data;
 	size_t num_dai_data;
@@ -292,6 +293,7 @@ static int sc8280xp_be_hw_params_fixup(struct snd_soc_pcm_runtime *rtd,
 				     struct snd_pcm_hw_params *params)
 {
 	struct snd_soc_dai *cpu_dai = snd_soc_rtd_to_cpu(rtd, 0);
+	struct sc8280xp_snd_data *data = snd_soc_card_get_drvdata(rtd->card);
 	struct snd_interval *rate = hw_param_interval(params,
 					SNDRV_PCM_HW_PARAM_RATE);
 	struct snd_interval *channels = hw_param_interval(params,
@@ -309,6 +311,15 @@ static int sc8280xp_be_hw_params_fixup(struct snd_soc_pcm_runtime *rtd,
 	case TX_CODEC_DMA_TX_3:
 		channels->min = 1;
 		break;
+	case PRIMARY_MI2S_RX ... QUATERNARY_MI2S_TX:
+	case QUINARY_MI2S_RX ... QUINARY_MI2S_TX:
+	case SENARY_MI2S_RX ... SENARY_MI2S_TX:
+	case LPI_MI2S_RX_0 ... LPI_MI2S_TX_4:
+		if (data->priv->mi2s_32bit) {
+			snd_mask_none(fmt);
+			snd_mask_set_format(fmt, SNDRV_PCM_FORMAT_S32_LE);
+		}
+		break;
 	default:
 		break;
 	}
@@ -562,6 +573,14 @@ static int sc8280xp_platform_probe(struct platform_device *pdev)
 	return devm_snd_soc_register_card(dev, card);
 }
 
+static const struct qcom_snd_soc_common motorola_vantage_priv_data = {
+	.driver_name = "molokai",
+	.dapm_widgets = sc8280xp_dapm_widgets,
+	.num_dapm_widgets = ARRAY_SIZE(sc8280xp_dapm_widgets),
+	.mi2s_bclk_enable = true,
+	.mi2s_32bit = true,
+};
+
 static struct qcom_snd_soc_common ayaneo_ps2_priv_data = {
 	.driver_name = "ayaneo-ps2",
 	.dapm_widgets = sc8280xp_dapm_widgets,
@@ -732,6 +751,7 @@ static const struct qcom_snd_soc_common sm8750_priv_data = {
 
 static const struct of_device_id snd_sc8280xp_dt_match[] = {
 	{ .compatible = "ayaneo,pocket-s2-sndcard", .data = &ayaneo_ps2_priv_data },
+	{ .compatible = "motorola,vantage-sndcard", .data = &motorola_vantage_priv_data },
 	{ .compatible = "qcom,eliza-sndcard", .data = &eliza_priv_data },
 	{ .compatible = "qcom,hawi-sndcard", .data = &hawi_priv_data },
 	{ .compatible = "qcom,kaanapali-sndcard", .data = &kaanapali_priv_data },

-- 
2.56.0

