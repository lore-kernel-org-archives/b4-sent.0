From: David Heidelberg <david@ixit.cz>
Date: Sun, 05 Jul 2026 22:06:51 +0200
Subject: [PATCH RFC 1/6] ASoC: qcom: sdm845: Demystify TDM masks a bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-pixel3-audio-v1-1-3b66f33859f1@ixit.cz>
References: <20260705-pixel3-audio-v1-0-3b66f33859f1@ixit.cz>
In-Reply-To: <20260705-pixel3-audio-v1-0-3b66f33859f1@ixit.cz>
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
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2551; i=david@ixit.cz;
 h=from:subject:message-id; bh=SdZUwKx9Q7cw5n6TiL+MxnmjRC4nVh9551uWu1/VrKQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqSrmM5iaDkwTUFKmTmrEPdbLy6ZoRCI3A+eLty
 X3zoxdIkjGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCakq5jAAKCRBgAj/E00kg
 cl/ND/0Z32csvsDHnIh/t24a+rGorlv/oonzDxFJ/u/1A5GD9EeoNg5keq0bRT2TNx7EgExrPoA
 Ur8/xlels0LatmaATpWd53MJ0juml7hnWdPz6uMhSduZyplOP1ANoE8tBAIipKgrZCfOF3XCY7K
 cJwMpbyn89dZOsfCNy1uE3RpWi7naTqDBKiaZ6aLxEPrwI/D3lTw90iRGSwkZ+zbNnfMGOcN/Xy
 vBn3ApV9X3pWpIlKZLaJInjTqcxDmznp4QU5SJCaovhtJ24e1J1SB5OYO/N6F3AVUdb6+fgF9Xz
 76vwalOKAu5YY1WEz5VlJ+WIt9DZzSyDyGztZ63oy60PsS0RFRsIh9ZlY6RJUaEwoqqce8Qf6tk
 NXjaJfPG2C9oQZd2YhNWrUGsFWNFbKLLYM1aBpgPoNyr2hfNTJ0MeUbd3vEMsAFRR3fXzFItZ44
 5hSIA6obzLZZf+MHiINcWZvM9NRbN9MioX5v3OvTwgd39oUqZ2MEvAxr86ZVRAZQ5IhoJYpQJDo
 9gJBVO3zpQ+XJZNN41wY4FUhM4PS2P9n+vv0ay70P/kaNLKWBD3Ug72qBCUlecu6VhbeIU3pJ2v
 FKvBY0vdvDIJKVulA352DH3mhCOK/zKkYPzxZbbzrb5Iqq1YnSCnte9dMspCsjJyCDfrFbAbWml
 R9SVpgGmaP282rw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the mask with the bits used for each RX/TX.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 sound/soc/qcom/sdm845.c | 18 +++++++++++-------
 1 file changed, 11 insertions(+), 7 deletions(-)

diff --git a/sound/soc/qcom/sdm845.c b/sound/soc/qcom/sdm845.c
index 0ce9dff4dc525..edd2cc7a1c74f 100644
--- a/sound/soc/qcom/sdm845.c
+++ b/sound/soc/qcom/sdm845.c
@@ -18,19 +18,21 @@
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
+#define LEFT_SPK_TDM_TX_MASK	(BIT(4) | BIT(5))
+#define RIGHT_SPK_TDM_TX_MASK	(BIT(6) | BIT(7))
 #define NUM_TDM_SLOTS           8
 #define SLIM_MAX_TX_PORTS 16
 #define SLIM_MAX_RX_PORTS 13
 #define WCD934X_DEFAULT_MCLK_RATE	9600000
 
 struct sdm845_snd_data {
 	struct snd_soc_jack jack;
 	bool jack_setup;
@@ -108,34 +110,36 @@ static int sdm845_tdm_snd_hw_params(struct snd_pcm_substream *substream,
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
+					       SPK_TDM_RX_MASK | BIT(2) |
+					       BIT(3), 0,
+					       NUM_TDM_SLOTS, slot_width);
 		if (ret < 0) {
 			dev_err(rtd->dev, "%s: failed to set tdm slot, err:%d\n",
 					__func__, ret);
 			goto end;
 		}
 
 		ret = snd_soc_dai_set_channel_map(cpu_dai, channels,
 				tdm_slot_offset, 0, NULL);

-- 
2.53.0

