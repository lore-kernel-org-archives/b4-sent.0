From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: jic23@kernel.org, dlechner@baylibre.com, nuno.sa@analog.com, 
 andy@kernel.org
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-iio@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH v2 2/3] iio: adc: mt6359: fix MT6357 ISENSE/VCDT and MT6358
 VCDT request bits
Date: Thu, 26 Nov 2026 03:10:15 +0000
Message-Id: <20261126031013.27701-3-iasnezhkov@gmail.com>
In-Reply-To: <20261126031013.27701-1-iasnezhkov@gmail.com>
References: <20261126031013.27701-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795662614; l=2570;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=Tm2foiR76Y5F+c07n1fWMZO/zetnJqISUTM3KZbbJ1Y=;
 b=3GIxGW63svjr+l/NjC6o6Ty65Pl/a8/SpLlAM/aXmKmB3+dXDCsTdEHbDIw+FkQx862VMUgYV
 exOlE95VR5BDNrC+pr8EEnInI5ddM/FAWiCw8tlqTfAvuOC3ELz/Vgs
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mt6357_auxadc_ch_desc[] sets req_bit to 0 for both ISENSE and VCDT, and
mt6358_auxadc_ch_desc[] sets req_bit to 0 for VCDT. Bit 0 of
PMIC_AUXADC_RQST0 triggers BATADC (ADC0) rather than ISENSE (ADC1) or
VCDT (ADC2), so polling the ready bit of ADC1/ADC2 times out unless the
channel was triggered externally.

Use the actual hardware request bits in PMIC_AUXADC_RQST0: bit 1 for
MT6357 ISENSE and bit 2 for MT6357/MT6358 VCDT (matching MT6363 VCDT
and the MediaTek PMIC AUXADC hardware registers).

Fixes: 3587914bf61d ("iio: adc: Add support for MediaTek MT6357/8/9 Auxiliary ADC")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
Changes in v2:
- Move AI coding assistant note below ---. No code changes.

Found and drafted with an AI coding assistant.

 drivers/iio/adc/mt6359-auxadc.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/adc/mt6359-auxadc.c b/drivers/iio/adc/mt6359-auxadc.c
index 54c9048..4a66253 100644
--- a/drivers/iio/adc/mt6359-auxadc.c
+++ b/drivers/iio/adc/mt6359-auxadc.c
@@ -224,8 +224,8 @@ static const struct iio_chan_spec mt6357_auxadc_channels[] = {
 
 static const struct mtk_pmic_auxadc_chan mt6357_auxadc_ch_desc[] = {
 	MTK_PMIC_ADC_CHAN(BATADC, PMIC_AUXADC_RQST0, 0, PMIC_AUXADC_IMP0, 8, 128, 3, 1),
-	MTK_PMIC_ADC_CHAN(ISENSE, PMIC_AUXADC_RQST0, 0, PMIC_AUXADC_IMP0, 8, 128, 3, 1),
-	MTK_PMIC_ADC_CHAN(VCDT, PMIC_AUXADC_RQST0, 0, PMIC_AUXADC_IMP0, 8, 8, 1, 1),
+	MTK_PMIC_ADC_CHAN(ISENSE, PMIC_AUXADC_RQST0, 1, PMIC_AUXADC_IMP0, 8, 128, 3, 1),
+	MTK_PMIC_ADC_CHAN(VCDT, PMIC_AUXADC_RQST0, 2, PMIC_AUXADC_IMP0, 8, 8, 1, 1),
 	MTK_PMIC_ADC_CHAN(BAT_TEMP, PMIC_AUXADC_RQST0, 3, PMIC_AUXADC_IMP0, 8, 8, 1, 1),
 	MTK_PMIC_ADC_CHAN(CHIP_TEMP, PMIC_AUXADC_RQST0, 4, PMIC_AUXADC_IMP0, 8, 8, 1, 1),
 	MTK_PMIC_ADC_CHAN(ACCDET, PMIC_AUXADC_RQST0, 5, PMIC_AUXADC_IMP0, 8, 8, 1, 1),
@@ -271,7 +271,7 @@ static const struct iio_chan_spec mt6358_auxadc_channels[] = {
 
 static const struct mtk_pmic_auxadc_chan mt6358_auxadc_ch_desc[] = {
 	MTK_PMIC_ADC_CHAN(BATADC, PMIC_AUXADC_RQST0, 0, PMIC_AUXADC_IMP0, 8, 128, 3, 1),
-	MTK_PMIC_ADC_CHAN(VCDT, PMIC_AUXADC_RQST0, 0, PMIC_AUXADC_IMP0, 8, 8, 1, 1),
+	MTK_PMIC_ADC_CHAN(VCDT, PMIC_AUXADC_RQST0, 2, PMIC_AUXADC_IMP0, 8, 8, 1, 1),
 	MTK_PMIC_ADC_CHAN(BAT_TEMP, PMIC_AUXADC_RQST0, 3, PMIC_AUXADC_IMP0, 8, 8, 2, 1),
 	MTK_PMIC_ADC_CHAN(CHIP_TEMP, PMIC_AUXADC_RQST0, 4, PMIC_AUXADC_IMP0, 8, 8, 1, 1),
 	MTK_PMIC_ADC_CHAN(ACCDET, PMIC_AUXADC_RQST0, 5, PMIC_AUXADC_IMP0, 8, 8, 1, 1),
-- 
2.54.0 (Apple Git-157)

