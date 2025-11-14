From: David Heidelberg <david@ixit.cz>
Date: Fri, 14 Nov 2025 01:14:34 +0100
Subject: [PATCH v2] ASoC: qcom: sdm845: set quaternary MI2S codec DAI to
 I2S format
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251114-sdm845-quaternary-v2-1-9d803bf5f7c9@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAGl0FmkC/z3MQQ7CIBBA0as0rJ0GEGxx5T2MCwrTlgRBh2psm
 t5d4sLlW/y/sYIUsLBzszHCdyghpwp5aJibbZoQgq9mkksthFBQ/L1XGp4vuyAlSyug8SfPBy2
 OzrDaPQjH8Pk9r7fqkfIdlpnQ/k9c8k5o2WnVKtObDgQ4G3FoXU4px7heYqjv3Gaa2L5/AdCv5
 G6mAAAA
X-Change-ID: 20251114-sdm845-quaternary-e9d6d0b513c9
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 "Dr. Git" <drgitx@gmail.com>, Casey Connolly <casey.connolly@linaro.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1341; i=david@ixit.cz;
 h=from:subject:message-id; bh=ARxpTeY9kNYvN6EYXKNHS5nPtDvu8Qayi+gAEHyLru4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFnRseuDCJsmzLI7IxIXZzk7++Dy8Mqn2plbaN
 3Nb4kuFfNWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRZ0bAAKCRBgAj/E00kg
 crilEACvkZu3ZgsuyqRA7SUxj5lMfVN9pu0+B8ucn1W91euBRLxMlqDmLhPILRJAeOZEwwpwaxm
 QLtms3kWoOfpJMBdYLUsvZP43Ke+sVIE7zSPv81i/WRlXSw0TNiHMsFkumBt4whyj011GKkZz18
 wCg8WVbgr1cQBrukb+STxfK83dxBRxsSdHLtYDMtDaNpSYIeVkiqmedSYXGal0BpaQgxLHhZ+cc
 tJqsM+Y1A7J5s3incrmDwXLtIbVH7aA9KteN+ExgZtg5ttBcE/T8O+CFJMMHey7EZgKH3fVNImE
 4Dz87fOPKWHmCRMw5FMfnUu6dZYa4/EzVh8fi7o6sSTjjSyVEBLSKf4y6CKieDvTpfzD5Fu13f3
 V0j9iu3hSElsc8QmBF5LhpSFdCnA5xc3FBYS/lNLI0SQjNRH9A2tAzP3K+VOpr0l3h0k6cixxIx
 5YNxv1aP9bWE4f95Qr9CgtdvpJpybuyEBsRSCjtZuQiEQ0O7hZERNazyFo0YUN4AWQRl7+SmhpB
 Z5n1VYX7wjSiMtRYJ0AQG7yetDQsoaDMvPFRwEkdTgdTY69p+p7qkGSWgWw+ezyZD8cBxvEsfrH
 8sFFsBU37JfeBLtU/xkRkxZffd05B8h/1K/5M3KvbwCYSsMkkd+u6yVGW+1tvSGPZEAENLegYdw
 rFaokJukicQI+Qg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "Dr. Git" <drgitx@gmail.com>

We configure the codec DAI format for primary and secondary but not the
quaternery MI2S path. Add the missing configuration to enable speaker
codecs on the quaternary MI2S like the MAX9827 found on the OnePlus 6.

Signed-off-by: Dr. Git <drgitx@gmail.com>
Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
 - Rebased on top of next-20251113
---
 sound/soc/qcom/sdm845.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/sound/soc/qcom/sdm845.c b/sound/soc/qcom/sdm845.c
index e18a8e44f2db5..0ce9dff4dc525 100644
--- a/sound/soc/qcom/sdm845.c
+++ b/sound/soc/qcom/sdm845.c
@@ -365,10 +365,12 @@ static int sdm845_snd_startup(struct snd_pcm_substream *substream)
 		snd_soc_dai_set_fmt(codec_dai, codec_dai_fmt);
 		break;
 	case QUATERNARY_MI2S_RX:
+		codec_dai_fmt |= SND_SOC_DAIFMT_NB_NF | SND_SOC_DAIFMT_I2S;
 		snd_soc_dai_set_sysclk(cpu_dai,
 			Q6AFE_LPASS_CLK_ID_QUAD_MI2S_IBIT,
 			MI2S_BCLK_RATE, SNDRV_PCM_STREAM_PLAYBACK);
 		snd_soc_dai_set_fmt(cpu_dai, fmt);
+		snd_soc_dai_set_fmt(codec_dai, codec_dai_fmt);
 		break;
 
 	case QUATERNARY_TDM_RX_0:

---
base-commit: 6d7e7251d03f98f26f2ee0dfd21bb0a0480a2178
change-id: 20251114-sdm845-quaternary-e9d6d0b513c9

Best regards,
-- 
David Heidelberg <david@ixit.cz>

