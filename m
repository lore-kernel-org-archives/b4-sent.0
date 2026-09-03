From: David Heidelberg <david@ixit.cz>
Date: Thu, 03 Sep 2026 20:26:39 +0200
Subject: [PATCH RFC v2 3/6] ASoC: qcom: sdm845: Use per-speaker RX masks
 for TDM slot assignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-pixel3-audio-v2-3-7c22ed915291@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1658; i=david@ixit.cz;
 h=from:subject:message-id; bh=VW92RXiOO5nv27+E+RkT/N6Yp/7ZgcRQKzeb8agg9FI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmbvh3NTfrj1m1h88rAOq1LhKiZViyj1q4CoZa
 Pm0BfvwljyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapm74QAKCRBgAj/E00kg
 chH4D/4wKr1ik+rYF/zXmIp1rnXHYXSp7bBAPwx8AdoB6o1dIc9UZwJI873aiGSi6zMofnnTHET
 SuSO912wwU9+Io0tzf3/TeUO+Qt0Mn6/yZqvI1x+kWnawE090OdIGrihSTo24xR20i4y5DFKZb3
 GQzJjYY+4L8sX/t3aN4xn1wNKXBw+K3qv5dhi4j/D2vG7s7WczwAyyERzyGLBz5NxyIC2raBoLZ
 pwykee2wKTrNYL5hmVUl+t4pz0SpMe0XN3WWYjwMj1DyrrHjTlL63hiii+3ytvoA26Os1p0IJRG
 Z1oOEJxR7Z7B+apUSTdRelrBOQbJdkN9dnkpRFlxa7TVInvpdoXeFX/UtHN7EeKJf6mEazfpZwI
 VNzO8HXzwrXEAxrdIgLYsVdR4YVnX7qMfvrXU+gVpSVgT/EVA/JTXLtGV7jt1J4/LvwUjy3A3of
 1oteF+UJJtOpclyKXA7eSggs1vIVk8095W+qjZevih1TXlHWRR2SREjJpXTKFzW4vcCHOFdM4GF
 Gbars/WBKkwFJM77lsGCerKtN2ejYVb1STEr4sUD8L8KzpoIfRMPP8gOcolre0ywafLSZi1wo1u
 +qGDCCMPyXo7einqVNbaNHwtAy8yiQQ7jWonb+Jq/f2rBBdvfGcL7OGk+Gq9ZZ+NdCVSLi0iTaF
 7LJLr95AKYSv/Ig==
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

Assisted-by: Claude:claude-4.6-opus
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

