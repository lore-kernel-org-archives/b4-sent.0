From: David Heidelberg <david@ixit.cz>
Date: Thu, 24 Sep 2026 14:46:47 +0200
Subject: [PATCH v3 3/8] ASoC: qcom: sdm845: Use per-speaker RX masks for
 TDM slot assignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-pixel3-audio-v3-3-5d06460fc8a9@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1658; i=david@ixit.cz;
 h=from:subject:message-id; bh=VW92RXiOO5nv27+E+RkT/N6Yp/7ZgcRQKzeb8agg9FI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtRu45pd3UVRz3zIwCFACP7fuikkG4GNk8sBEB
 01zcGp+vfGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUbuAAKCRBgAj/E00kg
 ctjrD/9/Ms11sbeTjATKbqB4Iw3zaN+IjlMf3lxnEqpM/AfFooO+F1JPHCvQIvvTl08HR+ixwCC
 O8kHJ+DOO/6CRRXOa0josy91Yc/6jxtaoAmdVU341rHeLs99PQk+BEjwsfvVxzT+pZq/hI1tbDP
 5tPr9I18C8XBqiof+rn4tHjhOK9+J27OUSj8AJ5Au+NsV0h6gEL+2602QfxFD/09Y/z5Slo0G1F
 SkWmObGWeH1Ezji9MC4OdU7EE+9uZbhCVgUZgMX29Daxz9WgU64kD85Ru4PwVCYS3ze9xKTn090
 bQevp1tGdooVRc0xvuQ8ULYQION7Iy9g+tS/APM3XyWdlR4cu0SmP/lxroVGXiPl4NkLrm9JJyp
 itfc06VcWoesvwHrwtfbhJqyNPKpKbTBRYmbTHQj6ylmsUgNl8mZuSW4h5PrnfWz1wNIozx7f+S
 2MWPegWKiw2eg3DR5tzGK7zl3fbgRXBe4+Gk7huIQ9tQnt1D5ErA4U9CrAJgiXXYG1aEXyQT94k
 d6NLgKGpHNATIxTcQDFod+BnahT0cgCdO+lo8VJoj+6L29GdvIRvH+jemA4zuenu2jODH96kz6v
 9BpEcXFQEHGLj7fFQZFcuM59YlnsOrZPao7bc0fJSwYftuADTGsKzqsHLpLGosMzwxQCu6Ez14I
 DEXz58llmgpgF/Q==
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

