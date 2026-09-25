From: David Heidelberg <david@ixit.cz>
Date: Fri, 25 Sep 2026 17:28:04 +0200
Subject: [PATCH v5 3/7] ASoC: qcom: sdm845: Use per-speaker RX masks for
 TDM slot assignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-pixel3-audio-v5-3-7ffb32c980bf@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1712; i=david@ixit.cz;
 h=from:subject:message-id; bh=14A2phcTaq+n5b5vOgbuu/Iv8VqqmG6tBsmNAD8ddoE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtpMFvDo534yviiiVsnPJ82ZpF7xhVWf90jNPE
 3KmP1yqV36JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaraTBQAKCRBgAj/E00kg
 cmlyD/9PhzS18ZH69Wc82yA4rsly/gtlTFO12SlAfU26bAZxsn5GfCWR9kcZCguMbgNi34WcuFk
 476QMrhaTdMbX9RbXMhrwqtfWQ5fmu5xy0ERLBmoDu9AH2CUrEDVsL8Gu9ILLsB3de/641+n/zz
 dJe1Wbi/rSoto+rC0q96e0Lyq+44EW+5YOtMwQWyWpVpVHnmedDJYZZadOJBB7yoxaohFpwYVUP
 XsbJYq92eEO5D4aM97QJbCj9eourUgVAubXLZPXb72I3ZoqKsOqI9nj8c+8HBtnwcabGxtgxaoi
 ji4TrRcolsRkXFSpYJJ7a4JGRImwOLQFxiRJOMifuk0BYowDXesXlpR61yQVirHmXJ1vtHsiEkB
 z/JSBtHXGQBzt9zMadVlV6iyfxpSkhIffah4GmDkmitu5iFbHnNbBT5K5FsM/SooQgMmWvq6nTC
 KbH4KMZOsY5tKTIHLian2yitBXeDpG6M3yJiCU4vIbkcUdhAjbwCYYOtt39V3gBtw3ed++cd8L3
 eVdpTvwyuRlwVY0D5lyfWIMkAXehxReRqe9xcql1E0ziH6d/gh4w/ybNDY0ZChMxPbITZOcQJew
 nyvw4Z6vll02xAveUe99I44lnz5aJ76bs4Wp4zTLFUlEWSuBKbsmyRMOuq120+cZh6OP9UAX6UP
 lUlcQeImLnttTTw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both Left and Right codec DAIs were passing the same SPK_TDM_RX_MASK,
both speakers ended up on slot 0, breaking the one speaker in
configuration such as on Pixel 3.

Split SPK_TDM_RX_MASK into per-speaker masks so that the Left codec
gets slot 0 (rx_mask=0x01) and the Right codec gets slot 1
(rx_mask=0x02).

This commit is here, so later CS35L36 receives correct slot for right
and left speakers.

Assisted-by: LLM
Reviewed-by: Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 sound/soc/qcom/sdm845.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/sound/soc/qcom/sdm845.c b/sound/soc/qcom/sdm845.c
index d1cc825fc5cdc..59cfa3b26cd4d 100644
--- a/sound/soc/qcom/sdm845.c
+++ b/sound/soc/qcom/sdm845.c
@@ -152,29 +152,29 @@ static int sdm845_tdm_snd_hw_params(struct snd_pcm_substream *substream,
 		}
 	}
 
 	for_each_rtd_codec_dais(rtd, j, codec_dai) {
 
 		if (!strcmp(codec_dai->component->name_prefix, "Left")) {
 			ret = snd_soc_dai_set_tdm_slot(
 					codec_dai, LEFT_SPK_TDM_TX_MASK,
-					SPK_TDM_RX_MASK, NUM_TDM_SLOTS,
+					LEFT_SPK_TDM_RX_MASK, NUM_TDM_SLOTS,
 					slot_width);
 			if (ret < 0) {
 				dev_err(rtd->dev,
 					"DEV0 TDM slot err:%d\n", ret);
 				return ret;
 			}
 		}
 
 		if (!strcmp(codec_dai->component->name_prefix, "Right")) {
 			ret = snd_soc_dai_set_tdm_slot(
 					codec_dai, RIGHT_SPK_TDM_TX_MASK,
-					SPK_TDM_RX_MASK, NUM_TDM_SLOTS,
+					RIGHT_SPK_TDM_RX_MASK, NUM_TDM_SLOTS,
 					slot_width);
 			if (ret < 0) {
 				dev_err(rtd->dev,
 					"DEV1 TDM slot err:%d\n", ret);
 				return ret;
 			}
 		}
 	}

-- 
2.55.0

