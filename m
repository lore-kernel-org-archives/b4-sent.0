From: David Heidelberg <david@ixit.cz>
Date: Sun, 05 Jul 2026 22:06:53 +0200
Subject: [PATCH RFC 3/6] ASoC: qcom: sdm845: Use per-speaker RX masks for
 TDM slot assignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-pixel3-audio-v1-3-3b66f33859f1@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1658; i=david@ixit.cz;
 h=from:subject:message-id; bh=TMUrTbPrHE+xNnL2Ezz+7c9lEmNQyl45Nx0PNNPOshE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqSrmMbD27JS8uy65De/uJL29mvkTBDiClKBsj6
 bd3h3qSExyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCakq5jAAKCRBgAj/E00kg
 cm3+EACIB+2F5Pm1eF2JmiEFiB2CHSvQDhE4+1idmNSimWUdpxrQIMFP9qAdttCmS7XJE9FHk3q
 H8VXD56rW9LX1guz8mRFyBcKSz2rqguW4Jg5eBPvciHY8brU7L2lnHmM244UjRgXwfRzQDtvUlQ
 MmPOe+nURMtTZWft1vci9uzGoQiPNXG92vF1MO+KmiFlrA1eT1c6w7FYVQ1/15ht38GCMzu6wMY
 9pZsxdiQREdpCMw6lfdfqyZ/61ZL8I0FbA1yM2d8+4OXHAckAq+uKZj9hKLN3Hz9lm9dyQTu6qd
 9mxAGzoN/DB4GnJqlT+4Q0sgK3z6BBO6p9ZK8f5X6l6oCoR++5J9eMel5J7X4dgj2+ETf7CW4vC
 YfiIYeJRiPTmZiaFeJVgZbV0mohWgrAdXA+4Zcd/6l8Gd7kUgHNNat4AINkiJrhnebhYkWKCMlS
 ih+gpeROoit7aqnxRjeETkZb+5c5VIh8boXfJZg7n+yvlY23MJuYjUedWk8BDXqPJr8LE/N/giV
 M4hZvKAj9b5OL6srXOuBdgwR0Bmu63BT02Jy2M0yBVvwpqIH9dKNaMZyph7TbFzf+fBsIV/wNko
 lRRXCJMYaHupDO4UFlb0eZbbTFCNxwE3/lKYIchinBmfXzonwZDPinnonPfbZRKkKklBCTGda/m
 6tyLGHkdCicqQ+A==
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
index 9de3282bda4be..8b65aa3982d47 100644
--- a/sound/soc/qcom/sdm845.c
+++ b/sound/soc/qcom/sdm845.c
@@ -150,29 +150,29 @@ static int sdm845_tdm_snd_hw_params(struct snd_pcm_substream *substream,
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
2.53.0

