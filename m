From: David Heidelberg <david@ixit.cz>
Date: Fri, 25 Sep 2026 17:28:02 +0200
Subject: [PATCH v5 1/7] ASoC: qcom: sdm845: Demystify TDM masks a bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-pixel3-audio-v5-1-7ffb32c980bf@ixit.cz>
References: <20260925-pixel3-audio-v5-0-7ffb32c980bf@ixit.cz>
In-Reply-To: <20260925-pixel3-audio-v5-0-7ffb32c980bf@ixit.cz>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 David Rhodes <drhodes@opensource.cirrus.com>, 
 Conor Dooley <conor+dt@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Viken Dadhaniya <viken.dadhaniya@oss.qualcomm.com>, 
 linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2760; i=david@ixit.cz;
 h=from:subject:message-id; bh=OBe52DHgRUl+sZAYSKZs/z/tb5vA9VGkR+bezPzuldo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtpMFUNOMOPKIzduzGIgENmg75SgpxDjPEPhjw
 bcu0O2CFUaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaraTBQAKCRBgAj/E00kg
 ciDmD/9p+qBoC4RWKX0CpMecPNtRpZkL97QNBAMkYpBSikF42SuIj0govDX5HTrbR6qI/gcWhnB
 fBROITVmMu30i3tHU7yLdctMegcRBRCntSsDU2xPua3+3jM1scN4DhrppIsqyWbUp+i0zV6YSP4
 dEAHSKqx9P2zYZ/4ylSG8SfW+kxNR34aKnWJ51wgLvkjh74zoGsEQLbBHVDUazf1ZHyMZ0j2Vtz
 dwkhSj2ehBWAhlxdAs8RN4rE2xg6ZFRwF4ODJZFOo1PGw+ZSjh+oflX1s8LyfjgYECepu23gRYq
 YK9KNfhH4GouUabJZXwAMJbcmjeNpsztQbGrgFEjlfhXB3idzcYZ24erAE/0zUJFp4m3jvGuIzt
 WSHlAMCy2KGvMWnFG9uYe+hPq8bdJA7YAZmIk+WAm9yzI89PpqOsU74pBKqECfiv/2N77uNAPQs
 2CfisQ+jzs+4UiJmIyLjs3Oi21x4Uz1Bfmw0/cuPQB33cRmhmbjHunkay18FQlhVU9vI3j5UOKV
 xNksTuoi58hR43Q3fxLUK0/MjYO4ly6dK2B2YD+CGskCUE65lCys85XJY7s4dXkg0W+c11CDfUB
 kNBc/AsG07WNlwCCkuMEJK8M5St8ifEDp7iKAGubB7WFlKwk46cyzJbUCdg6ya0tqKTR4wiGtP6
 lFWnSRhCgxaiJKA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the mask with the bits used for each RX/TX.

Reviewed-by: Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 sound/soc/qcom/sdm845.c | 21 ++++++++++++++-------
 1 file changed, 14 insertions(+), 7 deletions(-)

diff --git a/sound/soc/qcom/sdm845.c b/sound/soc/qcom/sdm845.c
index 6843ab8ba017e..0ce8265ab1c1f 100644
--- a/sound/soc/qcom/sdm845.c
+++ b/sound/soc/qcom/sdm845.c
@@ -18,19 +18,24 @@
 #include "sdw.h"
 #include "../codecs/rt5663.h"
 
 #define DRIVER_NAME	"sdm845"
 #define DEFAULT_SAMPLE_RATE_48K		48000
 #define DEFAULT_MCLK_RATE		24576000
 #define TDM_BCLK_RATE		6144000
 #define MI2S_BCLK_RATE		1536000
-#define LEFT_SPK_TDM_TX_MASK    0x30
-#define RIGHT_SPK_TDM_TX_MASK   0xC0
-#define SPK_TDM_RX_MASK         0x03
+#define LEFT_SPK_TDM_RX_MASK	BIT(0)
+#define RIGHT_SPK_TDM_RX_MASK	BIT(1)
+#define SPK_TDM_RX_MASK		(LEFT_SPK_TDM_RX_MASK | RIGHT_SPK_TDM_RX_MASK)
+#define MIC1_TDM_RX_MASK	BIT(2)
+#define MIC2_TDM_RX_MASK	BIT(3)
+#define MIC_TDM_RX_MASK		(MIC1_TDM_RX_MASK | MIC2_TDM_RX_MASK)
+#define LEFT_SPK_TDM_TX_MASK	(BIT(4) | BIT(5))
+#define RIGHT_SPK_TDM_TX_MASK	(BIT(6) | BIT(7))
 #define NUM_TDM_SLOTS           8
 #define SLIM_MAX_TX_PORTS 16
 #define SLIM_MAX_RX_PORTS 13
 #define WCD934X_DEFAULT_MCLK_RATE	9600000
 
 struct sdm845_snd_data {
 	struct snd_soc_jack jack;
 	bool jack_setup;
@@ -107,34 +112,36 @@ static int sdm845_tdm_snd_hw_params(struct snd_pcm_substream *substream,
 	default:
 		dev_err(rtd->dev, "%s: invalid param format 0x%x\n",
 				__func__, params_format(params));
 		return -EINVAL;
 	}
 
 	channels = params_channels(params);
 	if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK) {
-		ret = snd_soc_dai_set_tdm_slot(cpu_dai, 0, 0x3,
-				8, slot_width);
+		ret = snd_soc_dai_set_tdm_slot(cpu_dai, 0, SPK_TDM_RX_MASK,
+					       NUM_TDM_SLOTS, slot_width);
 		if (ret < 0) {
 			dev_err(rtd->dev, "%s: failed to set tdm slot, err:%d\n",
 					__func__, ret);
 			goto end;
 		}
 
 		ret = snd_soc_dai_set_channel_map(cpu_dai, 0, NULL,
 				channels, tdm_slot_offset);
 		if (ret < 0) {
 			dev_err(rtd->dev, "%s: failed to set channel map, err:%d\n",
 					__func__, ret);
 			goto end;
 		}
 	} else {
-		ret = snd_soc_dai_set_tdm_slot(cpu_dai, 0xf, 0,
-				8, slot_width);
+		ret = snd_soc_dai_set_tdm_slot(cpu_dai,
+					       SPK_TDM_RX_MASK |
+					       MIC_TDM_RX_MASK, 0,
+					       NUM_TDM_SLOTS, slot_width);
 		if (ret < 0) {
 			dev_err(rtd->dev, "%s: failed to set tdm slot, err:%d\n",
 					__func__, ret);
 			goto end;
 		}
 
 		ret = snd_soc_dai_set_channel_map(cpu_dai, channels,
 				tdm_slot_offset, 0, NULL);

-- 
2.55.0

