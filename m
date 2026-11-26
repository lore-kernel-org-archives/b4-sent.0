From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: jic23@kernel.org, dlechner@baylibre.com, nuno.sa@analog.com, 
 andy@kernel.org
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-iio@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH 3/3] iio: adc: mt6359: fix MT6358 VBAT impedance resistance
 ratio
Date: Thu, 26 Nov 2026 00:53:29 +0000
Message-Id: <20261126005326.71926-4-iasnezhkov@gmail.com>
In-Reply-To: <20261126005326.71926-1-iasnezhkov@gmail.com>
References: <20261126005326.71926-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795654406; l=1270;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=WrCKZo+xyngHjDeJ+R154khb7hjNavDC4cJWvorC71s=;
 b=tDW7Y/NLthcr2DkwF9JfTPOHU1B/Q3OlOxtv011CpCaAlHi/aqsbFLxy/dDtM/1q4IZVwtlh+
 a7F767JsXh2AhE/JlfZVzakSpHE7Jq5UwxhZ8fvAEcz5v9kDVXqkdvE
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On MT6358 (and MT6366), both BATADC and the battery impedance VBAT
channel use a 3/1 voltage divider (5400 mV full scale with 1800 mV
VREF). mt6358_auxadc_ch_desc[PMIC_AUXADC_CHAN_VBAT] erroneously uses
7/2 (copied from MT6359), over-reporting VBAT impedance readings by
16.7%.

Change MT6358 VBAT r_ratio from 7/2 to 3/1 to match MT6358 BATADC and
hardware.

Found and drafted with an AI coding assistant.

Fixes: 3587914bf61d ("iio: adc: Add support for MediaTek MT6357/8/9 Auxiliary ADC")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 drivers/iio/adc/mt6359-auxadc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/adc/mt6359-auxadc.c b/drivers/iio/adc/mt6359-auxadc.c
index 4a66253..915378c 100644
--- a/drivers/iio/adc/mt6359-auxadc.c
+++ b/drivers/iio/adc/mt6359-auxadc.c
@@ -285,7 +285,7 @@ static const struct mtk_pmic_auxadc_chan mt6358_auxadc_ch_desc[] = {
 	MTK_PMIC_ADC_CHAN(VGPU_TEMP, PMIC_AUXADC_RQST1, 10, PMIC_AUXADC_IMP0, 8, 8, 1, 1),
 
 	/* Battery impedance channels */
-	MTK_PMIC_ADC_CHAN(VBAT, 0, 0, PMIC_AUXADC_IMP0, 8, 128, 7, 2),
+	MTK_PMIC_ADC_CHAN(VBAT, 0, 0, PMIC_AUXADC_IMP0, 8, 128, 3, 1),
 };
 
 static const u16 mt6358_auxadc_regs[] = {
-- 
2.54.0 (Apple Git-157)


