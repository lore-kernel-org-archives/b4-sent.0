From: HuskerMinion <mocker-mug-unwoven@duck.com>
Date: Fri, 16 Oct 2026 02:14:02 -0600
Subject: [PATCH 2/2] ASoC: mediatek: mt8183: Fix UL1_CH2 I2S0_CH2 routing
 register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-mt8183-afe-fixes-v1-2-f0db51e0c073@duck.com>
References: <20261016-mt8183-afe-fixes-v1-0-f0db51e0c073@duck.com>
In-Reply-To: <20261016-mt8183-afe-fixes-v1-0-f0db51e0c073@duck.com>
To: Mark Brown <broonie@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>
Cc: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 linux-sound@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org, 
 HuskerMinion <mocker-mug-unwoven@duck.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792138468; l=1450;
 i=mocker-mug-unwoven@duck.com; s=20261016; h=from:subject:message-id;
 bh=mEWhlclh4rsOZ/4zrF6u9RE5QWi0z/CRm0Rz/ciL1HE=;
 b=6YXlyoF5BZSa8qalNwQEhwPQZX15OAoWl6Cwl3SmMzWojxGvBMbRuyUf4ivpDoMJbSHk0bkXW
 k1493RQj8XmBmDpzzjLmThkLYOaOUD56lijYARzfS8X/I4voQADCpZL
X-Developer-Key: i=mocker-mug-unwoven@duck.com; a=ed25519;
 pk=Q7l9BnP4XnFimCK28K+NVowcECqTaJNXicdBAInot0k=
X-Endpoint-Received: by B4 Relay for mocker-mug-unwoven@duck.com/20261016 with auth_id=1206
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The "I2S0_CH2" switch of the UL1_CH2 mixer writes AFE_CONN21. That is
the interconnect register for UL1 channel 1 (O21). Channel 2 is O22,
which is AFE_CONN22, as the "ADDA_UL_CH2" switch of the same mixer
already uses.

So enabling the switch routes I2S0 channel 2 into UL1 channel 1, mixed
with channel 1, and UL1 channel 2 gets nothing from I2S0.

Use AFE_CONN22.

Found while adding UL1 capture routes for the four microphones of the
Amazon Echo Show 8 (2nd gen). That board captures from I2S2, so the
I2S0 path itself is only compile tested.

Fixes: d232591c9482 ("ASoC: Mediatek: MT8183: add I2S2 control path from UL2 and UL3")
Signed-off-by: HuskerMinion <mocker-mug-unwoven@duck.com>
---
 sound/soc/mediatek/mt8183/mt8183-afe-pcm.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/soc/mediatek/mt8183/mt8183-afe-pcm.c b/sound/soc/mediatek/mt8183/mt8183-afe-pcm.c
index d6175da3b..2b2ee0575 100644
--- a/sound/soc/mediatek/mt8183/mt8183-afe-pcm.c
+++ b/sound/soc/mediatek/mt8183/mt8183-afe-pcm.c
@@ -301,7 +301,7 @@ static const struct snd_kcontrol_new memif_ul1_ch1_mix[] = {
 static const struct snd_kcontrol_new memif_ul1_ch2_mix[] = {
 	SOC_DAPM_SINGLE_AUTODISABLE("ADDA_UL_CH2", AFE_CONN22,
 				    I_ADDA_UL_CH2, 1, 0),
-	SOC_DAPM_SINGLE_AUTODISABLE("I2S0_CH2", AFE_CONN21,
+	SOC_DAPM_SINGLE_AUTODISABLE("I2S0_CH2", AFE_CONN22,
 				    I_I2S0_CH2, 1, 0),
 };
 

-- 
2.43.0

