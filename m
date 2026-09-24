From: David Heidelberg <david@ixit.cz>
Date: Thu, 24 Sep 2026 14:46:46 +0200
Subject: [PATCH v3 2/8] ASoC: qcom: sdm845: use DSP_A format for TDM codec
 DAIs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-pixel3-audio-v3-2-5d06460fc8a9@ixit.cz>
References: <20260924-pixel3-audio-v3-0-5d06460fc8a9@ixit.cz>
In-Reply-To: <20260924-pixel3-audio-v3-0-5d06460fc8a9@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtRu4TfBa4OcaeqvSI5Uv9tQQkI7jKvBQvRe3a
 QmSPIOyJdKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUbuAAKCRBgAj/E00kg
 cgmZD/4pPbfF8/iUJA2gBQ+rqbJUjgGV7H3RF8wgX34Mv1bMf8XzdhwjDLbNj9KSvB0VmDBsyly
 jn3oYx+U93OH6y7wGvLTVpDJT6vqrlhFAZDvJCdrvnq7NjaLucBwd6TytHQOxQ+T4sMbIqfT8hO
 dhnvcpeKG5la7ZYozBH2pM70Nu//IHDGeT8t74+IU3mG3xYjJ9QzqI050jHMeWSEXXSDX2D0KnF
 C/633UkShiATFF/I43yGUY1jQC6o3K7JoE84XKP7WvgVpHeJvy1n0S1epEFOmKsi1q1hSChrDRO
 86DWG1ETV/Un3bOieXtYHUeTISXzMoT1W3r+wAVMYTO1Wuc6KmWCGeTMOanewRxnfdwbVTlWWyw
 512tL34DFX8DdAoMjS0JzXyoROD+EwS3mWWY6jlpaSAgbkR/j+iXTqWrsNEw1U2WDBwRppW3gNU
 4Ehoc8awUbXueSpnYjYy8yJsQ/AkJaNCaRKV2E2X/WMlh3RjgU593ZOenZ87zdYGxgEQZEpVRtj
 SAioKfBAlXHaTDTukFBn7ErDXn5FoSNh+lnxhDRYSGs620ZcktboxUDqRLTShpzEwXvaAq1Wdzo
 6s4qQI5XEz2XPhaudf663anNPT7n5dAzvu6ThlMShMTqjDA2nj0uxAaeG+CihHctcKSo+oOVkY+
 vzxLj8eSOFwyscg==
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

