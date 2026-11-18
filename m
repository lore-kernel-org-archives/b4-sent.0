From: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
Date: Tue, 17 Nov 2026 16:06:03 -0800
Subject: [PATCH v2] staging: iio: adc: ad7816: use dev_err_probe() for GPIO
 lookups
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-batch1-s3-warn-v2-1-17f4e541123b@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0Jm7RimJVJceQ/Doh2L1Bggbakaw
 t2luHb5kvffXyBY72yAc7GAt8kFNw4biEMB3OvhbtHdNgZRihNRWaPRkXvCIPGl/YBCNdworg2
 Rgm00edu59x68tj8Os3lYjrmSjd6FOPrP/pgoe3/jiZCw6lgqWRFrqS5xNmM8PnWEdl3XL2mLE
 V6+AAAA
X-Change-ID: 20261107-batch1-s3-warn-289c98c7b118
To: jic23@kernel.org, Michael.Hennerich@analog.com, dlechner@baylibre.com, 
 gregkh@linuxfoundation.org, andy@kernel.org, nuno.sa@analog.com
Cc: linux-iio@vger.kernel.org, krzk@kernel.org, linux@analog.com, 
 linux-kernel@vger.kernel.org, linux-staging@lists.linux.dev, 
 Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2256; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=zUcBktwXmCE4oXfyfd9Np1m8huOS/SaVtNAIrPt4qJg=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFl/Xr/+PSPHu2fBstdXOq22WfBt+3NoU++6/09nl4v4d
 S09bnQ3oaOUhUGMg0FWTJFFTIbnff19nThrqzknYOawMoEMYeDiFICJLJFn+J8gJz5hQ/OaRV06
 pvf/von+XL5yxk3R+Ik9FTeCtVfE/zJk+Ge8TWObqUHYEq4Wvnt8BaeVOdrOyL2cv/OvF9c8Ye3
 eXawA
X-Developer-Key: i=DelaySystem@tubot.lat; a=openpgp;
 fpr=161C0CEF7FDF2C5E3B3A9CC8E22333A79A058D4B
X-Endpoint-Received: by B4 Relay for DelaySystem@tubot.lat/default with auth_id=1447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

GPIO lookups can return -EPROBE_DEFER.  Convert the rdwr and convert
GPIO lookup failures in ad7816_probe() to dev_err_probe(), which
suppresses the error message on deferral and records the deferral
reason.  The busy-GPIO path is left untouched: its optionality is the
subject of a separate proposed change.

No functional change other than defer handling.

Signed-off-by: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
---
Changes in v2:
- Resend under my real name (From/Signed-off-by: Maximo Manriquez Lizarraga).
- Apologies for the improper sign-off on v1; no code change.
- Link to v1: https://patch.msgid.link/20261107-batch1-s3-warn-v1-1-4fc38341ca38@tubot.lat
---
 drivers/staging/iio/adc/ad7816.c | 18 ++++++------------
 1 file changed, 6 insertions(+), 12 deletions(-)

diff --git a/drivers/staging/iio/adc/ad7816.c b/drivers/staging/iio/adc/ad7816.c
index 2a15d7598abb..11292216dfb5 100644
--- a/drivers/staging/iio/adc/ad7816.c
+++ b/drivers/staging/iio/adc/ad7816.c
@@ -381,20 +381,14 @@ static int ad7816_probe(struct spi_device *spi_dev)
 
 	chip->id = spi_get_device_id(spi_dev)->driver_data;
 	chip->rdwr_pin = devm_gpiod_get(&spi_dev->dev, "rdwr", GPIOD_OUT_HIGH);
-	if (IS_ERR(chip->rdwr_pin)) {
-		ret = PTR_ERR(chip->rdwr_pin);
-		dev_err(&spi_dev->dev, "Failed to request rdwr GPIO: %d\n",
-			ret);
-		return ret;
-	}
+	if (IS_ERR(chip->rdwr_pin))
+		return dev_err_probe(&spi_dev->dev, PTR_ERR(chip->rdwr_pin),
+				     "Failed to request rdwr GPIO\n");
 	chip->convert_pin = devm_gpiod_get(&spi_dev->dev, "convert",
 					   GPIOD_OUT_HIGH);
-	if (IS_ERR(chip->convert_pin)) {
-		ret = PTR_ERR(chip->convert_pin);
-		dev_err(&spi_dev->dev, "Failed to request convert GPIO: %d\n",
-			ret);
-		return ret;
-	}
+	if (IS_ERR(chip->convert_pin))
+		return dev_err_probe(&spi_dev->dev, PTR_ERR(chip->convert_pin),
+				     "Failed to request convert GPIO\n");
 	if (chip->id == ID_AD7816 || chip->id == ID_AD7817) {
 		chip->busy_pin = devm_gpiod_get(&spi_dev->dev, "busy",
 						GPIOD_IN);

---
base-commit: fa4ad798f6f681031775266044ba1b0cf3c670bd
change-id: 20261107-batch1-s3-warn-289c98c7b118

Best regards,
--  
Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>

