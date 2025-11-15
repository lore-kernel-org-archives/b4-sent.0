From: David Heidelberg <david@ixit.cz>
Date: Sat, 15 Nov 2025 19:43:58 +0100
Subject: [PATCH v3] ASoC: qcom: sdm845: set quaternary MI2S codec DAI to
 I2S format
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251115-sdm845-quaternary-v3-1-c16bf19128ac@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAO3JGGkC/33OsQ6CMBSF4VcxnS1pCxXq5HsYh9Je5CbY6i0Sk
 PDuVgdHx384X87KEhBCYsfdyggmTBhDjnK/Y6634QocfW6mhNJSyoonf2sqzR9POwIFSwsH4w9
 etFqWzrC8uxN0OH/N8yV3R/HGx57A/iShRC21qnVVVKYxNZfc2QHawsUQ4jAspwGzHYtI1w/ZY
 xojLd+Xk/rA/w5NKnvGN6JsO93VzpxwxrFwL3bZtu0NDFAJtPMAAAA=
X-Change-ID: 20251114-sdm845-quaternary-e9d6d0b513c9
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Robert Oscilowski <drgitx@gmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1499; i=david@ixit.cz;
 h=from:subject:message-id; bh=PHx2oXpAkKgIFICWfAbsH+E/7ElM+CcL2wslsUfnDDc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpGMnvkMOhmQGMZfc9yygG3wSWhLGXXFps+EK6U
 dYBprr6drGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRjJ7wAKCRBgAj/E00kg
 cu9lEACxO+7i0H+nj3YGNeIJ7WxlabxhZHlSgl6KOnCkGrifVMOkAxG+wFCjF3xwy8UXZJj+N+f
 d41fmnrxOKjqO0JfwAM3UYWre9Ig/QR0t9VfB9eYdQBNnuX+kPLU44hDFjKSJFIO+Uro9ylNGKZ
 vJtbkqTlxzSvI0xxMnfc+Bjf/oEkqHj5v5MMAd6UcEUjlTHfYXqcrwX1cOO5S7mdFPAmfvCeyEZ
 /FLXLBz0C7ExgfrxrnvynDdCFHnR/nYxl/eS8ncF6gc+i9FIcVBnb17Bg+fAiD9WGwhgiJ+O2D+
 5Jw1SgrVDFuWgH4HKdIfA0CxXqBvpS1Y+06gumqoDPhQnBUHdaIEcGCgX4/Wk4q57i4tgEy6TPM
 V1EVIoDItvpNv/05xqzpnyDm4uzqaQ+lWqu5ousD8akzt8wN6agkPaFTeYUR/K/K7GmWQ7HSegR
 CIvzfVFIYN+Bbk96g05GPEAxg5HzU4oqLXMv2R0WkVnHoTBOwTSXBEdjeZmJoR7nWoNrggvTXXr
 D+PGokXhp8+TEpYC9RaPNqCkEvuODCTTUOjeYMqZaY9Pl0P/6H7O5MfMENVUbi36sW7zvhjC99R
 qfPEv+rxau+Vk/LzMA1Ef+fkQigvXvY2QKwOklgD9Lfp6NxalyJqIXatPZR/D6CA4kl6KZcOMjH
 Lh/NyPlltdPaw0Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Robert Oscilowski <drgitx@gmail.com>

We configure the codec DAI format for primary and secondary but not the
quaternery MI2S path. Add the missing configuration to enable speaker
codecs on the quaternary MI2S like the MAX9827 found on the OnePlus 6.

Signed-off-by: Robert Oscilowski <drgitx@gmail.com>
Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Updated DrGit name to real name.
- Link to v2: https://lore.kernel.org/r/20251114-sdm845-quaternary-v2-1-9d803bf5f7c9@ixit.cz

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
base-commit: 0f2995693867bfb26197b117cd55624ddc57582f
change-id: 20251114-sdm845-quaternary-e9d6d0b513c9

Best regards,
-- 
David Heidelberg <david@ixit.cz>

