From: Valerio Setti <vsetti@baylibre.com>
Date: Tue, 07 Oct 2025 00:12:19 +0200
Subject: [PATCH] ASoC: meson: aiu-encoder-i2s: fix bit clock polarity
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251007-fix-i2s-polarity-v1-1-86704d9cda10@baylibre.com>
X-B4-Tracking: v=1; b=H4sIAMI+5GgC/x2MWwqAIBAArxL73YKt9qCrRB9SWy2EhkYU0t2TP
 gdmJkHkIByhLxIEviSKdxmqsoBps25llDkzkKK6UqrBRW4Uinj43QY5H5xbY7TuFkukIWdH4Oz
 8y2F83w/n6ZUSYgAAAA==
X-Change-ID: 20251006-fix-i2s-polarity-d744338fa223
To: Jerome Brunet <jbrunet@baylibre.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-sound@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Valerio Setti <vsetti@baylibre.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1584; i=vsetti@baylibre.com;
 h=from:subject:message-id; bh=yhS4Hp8u/Or3vlCBo8NKBwUHK5bFZ95+lSDqT7ffm68=;
 b=owGbwMvMwCF2z3ty7kUrRgbG02pJDBlP7G7Vcrw8+WNXspbGklMbFI6a5LY+1/gg9v5pfgqHn
 ozu2umiHaUsDGIcDLJiiiws0+/9LihVe2iccLIAZg4rE8gQBi5OAZhIlAzDT0aRdVUTjRINNFhD
 Sg6cPrPmuFXCOu/OksauQpW5T2W/+zIy/FO7m1Wq8VTx9nf/GRt3bdV6nfajzTH9xteVf6afa9P
 azgAA
X-Developer-Key: i=vsetti@baylibre.com; a=openpgp;
 fpr=0497DEFB707526E13360C970DE4B936DD13A0100
X-Endpoint-Received: by B4 Relay for vsetti@baylibre.com/default with auth_id=515
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to I2S specs audio data is sampled on the rising edge of the
clock and it can change on the falling one. When operating in normal mode
this SoC behaves the opposite so a clock polarity inversion is required
in this case.

This was tested on an OdroidC2 (Amlogic S905 SoC) board.

Signed-off-by: Valerio Setti <vsetti@baylibre.com>
---
 sound/soc/meson/aiu-encoder-i2s.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/sound/soc/meson/aiu-encoder-i2s.c b/sound/soc/meson/aiu-encoder-i2s.c
index a0dd914c8ed13616fbcbc0828e36418cfd255391..3b4061508c18047fe8d6f3f98061720f8ce238f2 100644
--- a/sound/soc/meson/aiu-encoder-i2s.c
+++ b/sound/soc/meson/aiu-encoder-i2s.c
@@ -236,8 +236,12 @@ static int aiu_encoder_i2s_set_fmt(struct snd_soc_dai *dai, unsigned int fmt)
 	    inv == SND_SOC_DAIFMT_IB_IF)
 		val |= AIU_CLK_CTRL_LRCLK_INVERT;
 
-	if (inv == SND_SOC_DAIFMT_IB_NF ||
-	    inv == SND_SOC_DAIFMT_IB_IF)
+	/*
+	 * The SoC changes data on the rising edge of the bitclock
+	 * so an inversion of the bitclock is required in normal mode
+	 */
+	if (inv == SND_SOC_DAIFMT_NB_NF ||
+	    inv == SND_SOC_DAIFMT_NB_IF)
 		val |= AIU_CLK_CTRL_AOCLK_INVERT;
 
 	/* Signal skew */
@@ -328,4 +332,3 @@ const struct snd_soc_dai_ops aiu_encoder_i2s_dai_ops = {
 	.startup	= aiu_encoder_i2s_startup,
 	.shutdown	= aiu_encoder_i2s_shutdown,
 };
-

---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20251006-fix-i2s-polarity-d744338fa223

Best regards,
-- 
Valerio Setti <vsetti@baylibre.com>

