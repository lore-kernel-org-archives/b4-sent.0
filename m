From: David Heidelberg <david@ixit.cz>
Date: Thu, 03 Sep 2026 20:26:38 +0200
Subject: [PATCH RFC v2 2/6] ASoC: qcom: sdm845: use DSP_A format for TDM
 codec DAIs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-pixel3-audio-v2-2-7c22ed915291@ixit.cz>
References: <20260903-pixel3-audio-v2-0-7c22ed915291@ixit.cz>
In-Reply-To: <20260903-pixel3-audio-v2-0-7c22ed915291@ixit.cz>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 David Rhodes <drhodes@opensource.cirrus.com>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1269; i=david@ixit.cz;
 h=from:subject:message-id; bh=1wKqiBzByWUp0kGcvJt9kwURHXbEVlcog8LeXEB9/TU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmbvhddqIGVtEXOs2uUDDcFfq0XRCR8ZgEfEHf
 NbQDtltCjCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapm74QAKCRBgAj/E00kg
 cq4ID/44AlVuaenS6d5+Hs9fVvSs6O+ByXmGPBqTTR2mVxCh1/eh4v8uXSU2Db65McM9SeMBloB
 JjnYK6pP2kWNwBl76u9Pd8/7G0J5KNbtMEJQ9hXADGypqL6d7IvR+l2j/aRR3V6/fP3SiqAB1rd
 PDBApYvFZiQ2GWSy+xhqyTfyUBr6PE9sY+wb6jC3aKT4/sirHAj7wJ4FefEW2TbicphWXbv8OvT
 IeJXiWOBwQiFBuve/7UZhVNq4dsoGgfUMo+FRMJgThjwA12uXk1SOWhycCt4aWjx8vWTzKwQpPq
 irZbwqUgm35a+0MfJZBipHE/QTG8PdOMpXw1nFV+Z1GdxH0mTPBT+hq+NZBiXBpaR4XeSfOurW2
 vb8MDQQe8rvHggvX9BdfaPtYRng7hyQOYMhwnYt3mnff5Cn/69yMvCm9JbgJmzrsJqeVVhRBqwn
 wp0na5sM1z3hs7ptwD/2gwlIN091re9svLEVoiOAEVbf545MOyu6wFjpzHMniP0MtsvIO2qSY3c
 1TSdEM5czTKmj/W+WJExLAhtiuHgYC+R3mCOdNk6wDSdp0P9FtmslNqYK0E35oWUgTWhhAg0LiZ
 Ne0mwldKyD2Vwthaa2Ghe/eFL/n8C5/eQDfeUeyP+M8LGdsP/JRnTmV/FIdUvxOsXdKO5ZwHFvK
 jDnPlI03bLMqisA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Before the DSP_B only worked because the only close-to-mainline consumer
cs35l36 codec was patched to map both DSP_A and DSP_B to the same
hardware register value (asp_fmt = 0), which is inherently DSP_A timing.
Use the right codec (DSP_A) which works as expected.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 sound/soc/qcom/sdm845.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/soc/qcom/sdm845.c b/sound/soc/qcom/sdm845.c
index 0ce8265ab1c1f..d1cc825fc5cdc 100644
--- a/sound/soc/qcom/sdm845.c
+++ b/sound/soc/qcom/sdm845.c
@@ -382,17 +382,17 @@ static int sdm845_snd_startup(struct snd_pcm_substream *substream)
 	case QUATERNARY_TDM_RX_0:
 	case QUATERNARY_TDM_TX_0:
 		if (++(data->quat_tdm_clk_count) == 1) {
 			snd_soc_dai_set_sysclk(cpu_dai,
 				Q6AFE_LPASS_CLK_ID_QUAD_TDM_IBIT,
 				TDM_BCLK_RATE, SNDRV_PCM_STREAM_PLAYBACK);
 		}
 
-		codec_dai_fmt |= SND_SOC_DAIFMT_IB_NF | SND_SOC_DAIFMT_DSP_B;
+		codec_dai_fmt |= SND_SOC_DAIFMT_IB_NF | SND_SOC_DAIFMT_DSP_A;
 
 		for_each_rtd_codec_dais(rtd, j, codec_dai) {
 
 			if (!strcmp(codec_dai->component->name_prefix,
 				    "Left")) {
 				ret = snd_soc_dai_set_fmt(
 						codec_dai, codec_dai_fmt);
 				if (ret < 0) {

-- 
2.55.0

