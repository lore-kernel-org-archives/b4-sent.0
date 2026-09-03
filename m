From: David Heidelberg <david@ixit.cz>
Date: Thu, 03 Sep 2026 20:26:37 +0200
Subject: [PATCH RFC v2 1/6] ASoC: qcom: sdm845: Demystify TDM masks a bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-pixel3-audio-v2-1-7c22ed915291@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2687; i=david@ixit.cz;
 h=from:subject:message-id; bh=cPwrEY4ZNqiKfvbC0ASAoVk96Jl21/NzxFU+I7j9SBQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmbvhxwq/202EQUg7sPGfMmY8UagSnnoYZN3nW
 tFBAMgI0qmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapm74QAKCRBgAj/E00kg
 chwgEACEFfcVpyGEbKOWWdYcMAyngylTuHsY9hAchAakiWMg8mNUjb+G4VdoSIagaaGKzRhrZ/d
 EHSBe5JLdxart/C98n0J49NYtRt2z85WmaIpRXkhBRCV8x0IS5M/ROCppr7gFkO6CtizuavP1rP
 rB+WnwEHyAM07oeZPVeNvz+KOhyK7n/eY76kQuIds+3K+62UVRvrcivSE/fPqhmk8xuzmm15NmD
 7yfIZWCB8Mq1DWqgtOHYhmIWqoTN5cbuAXom5Ul/ij1EtjIgUJZH+cj9CZAmQBM2237g61iyUQG
 Mw86EXqHXBDi38NR8RsO7W0vgrrcn73Y+VV6bFxYbqT08EsbzPPgm1xJrEc822lYhYS4pFCc2Qx
 hrcvnrM+dASSiI4858sDotZCs4U8++MFWJFuMHTwryd3ucEuqHx2mO8UZpzbHU9O7Kobl0y5/No
 yIJ/5EMYJoF3y1DQ0JJ0gx9zVEEFHuC3bcyAcjXdb+0YF+SfVTOIxW07QIWvMJrT7wjkjYUQkEm
 oF2AmKkrpKff/MKX0ZQdIfwfkstiu2azEpycpoCVKSySGhCQmxZ7AKXwggg3/4zSZt/zfJFyYHa
 dnr8veLLOqxMUe8lQf7tst0igh3F4HiDhL7WiQmO6Cfu1+14EmK+oTo9kTiO4ExsoZYNjXtDXG8
 eRWpU1OnOCCwhCQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the mask with the bits used for each RX/TX.

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

