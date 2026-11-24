From: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
Date: Tue, 24 Nov 2026 10:28:24 -0800
Subject: [PATCH v5] staging: iio: adc: ad7816: use dev_err_probe() for GPIO
 lookups
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-batch1-s3-warn-v5-1-badf90d5defe@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XOQW7DIBAF0KtErEuVGUjAWeUeVRcwjGOiyo6Au
 K0i372QbqxaXX7pvz/zEJlT5CxOu4dIPMccp7GGw8tO0ODGC8sYaha4xyPA3kjvCg0gs5KfLo0
 SbUedJeMBrKjolriPX8/Bt/ffnO/+ylTaSmsMMZcpfT8vztB6/47PIEHqnpRVGsgpey53P5XXD
 1dEG59xxWHLsXIwveaDBkDl/3K15nbDVeX9ETEgYGDecL3iqDZct+cNBRtM0MTdmi/L8gM2jOW
 QewEAAA==
X-Change-ID: 20261107-batch1-s3-warn-289c98c7b118
To: Michael.Hennerich@analog.com, gregkh@linuxfoundation.org, 
 andy@kernel.org, nuno.sa@analog.com, jic23@kernel.org, 
 dlechner@baylibre.com
Cc: linux@analog.com, linux-staging@lists.linux.dev, 
 linux-iio@vger.kernel.org, crofts@kernel.org, linux-kernel@vger.kernel.org, 
 krzk@kernel.org, Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3468; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=pIPxq0yfo0Ggng/63NlKt3XQGOq6qAvMytmuG849dko=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDNms191l9PJLrwXc8Xj1oVd/Ve3O84efJkWURKRarGevf
 NX5/ObRjlIWBjEOBlkxRRYxGZ739fd14qyt5pyAmcPKBDKEgYtTACbSNZ+Rof9D6bMtElH3Wex5
 OZb1lxozzplrnqK1S2NRZOQeifXTzzMyHKh4Zn8gwSg04XMc74ljPvYGDTNt1xuxPi1IflpmPfE
 bCwA=
X-Developer-Key: i=DelaySystem@tubot.lat; a=openpgp;
 fpr=161C0CEF7FDF2C5E3B3A9CC8E22333A79A058D4B
X-Endpoint-Received: by B4 Relay for DelaySystem@tubot.lat/default with auth_id=1447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

GPIO lookups can return -EPROBE_DEFER.  Convert the rdwr, convert,
and busy GPIO lookup failures in ad7816_probe() to dev_err_probe(),
which suppresses the error message on deferral and records the deferral
reason.

No functional change other than defer handling.

Signed-off-by: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
---
Changes in v5:
- Move struct device *dev to the top of probe to keep the declaration order (Andy Shevchenko).
- Leave the devm_gpiod_get() calls unchanged; only the error lines become dev_err_probe().
- Link to v4: https://patch.msgid.link/20261123-batch1-s3-warn-v4-1-47cd8d7d4ce9@tubot.lat

Changes in v4:
- Add struct device *dev at the top of probe and use it in the touched lines (Andy Shevchenko).
- Link to v3: https://patch.msgid.link/20261118-batch1-s3-warn-v3-1-f622d212deeb@tubot.lat

Changes in v3:
- Convert the missed busy-GPIO failure path to dev_err_probe() as well (Joshua Crofts).
- Link to v2: https://patch.msgid.link/20261117-batch1-s3-warn-v2-1-17f4e541123b@tubot.lat

Changes in v2:
- Resend under my real name (From/Signed-off-by: Maximo Manriquez Lizarraga).
- Apologies for the improper sign-off on v1; no code change.
- Link to v1: https://patch.msgid.link/20261107-batch1-s3-warn-v1-1-4fc38341ca38@tubot.lat
---
 drivers/staging/iio/adc/ad7816.c | 28 ++++++++++------------------
 1 file changed, 10 insertions(+), 18 deletions(-)

diff --git a/drivers/staging/iio/adc/ad7816.c b/drivers/staging/iio/adc/ad7816.c
index 2a15d7598abb..7d9a5f324466 100644
--- a/drivers/staging/iio/adc/ad7816.c
+++ b/drivers/staging/iio/adc/ad7816.c
@@ -362,6 +362,7 @@ static const struct iio_info ad7816_info = {
 
 static int ad7816_probe(struct spi_device *spi_dev)
 {
+	struct device *dev = &spi_dev->dev;
 	struct ad7816_chip_info *chip;
 	struct iio_dev *indio_dev;
 	int i, ret;
@@ -381,29 +382,20 @@ static int ad7816_probe(struct spi_device *spi_dev)
 
 	chip->id = spi_get_device_id(spi_dev)->driver_data;
 	chip->rdwr_pin = devm_gpiod_get(&spi_dev->dev, "rdwr", GPIOD_OUT_HIGH);
-	if (IS_ERR(chip->rdwr_pin)) {
-		ret = PTR_ERR(chip->rdwr_pin);
-		dev_err(&spi_dev->dev, "Failed to request rdwr GPIO: %d\n",
-			ret);
-		return ret;
-	}
+	if (IS_ERR(chip->rdwr_pin))
+		return dev_err_probe(dev, PTR_ERR(chip->rdwr_pin),
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
+		return dev_err_probe(dev, PTR_ERR(chip->convert_pin),
+				     "Failed to request convert GPIO\n");
 	if (chip->id == ID_AD7816 || chip->id == ID_AD7817) {
 		chip->busy_pin = devm_gpiod_get(&spi_dev->dev, "busy",
 						GPIOD_IN);
-		if (IS_ERR(chip->busy_pin)) {
-			ret = PTR_ERR(chip->busy_pin);
-			dev_err(&spi_dev->dev, "Failed to request busy GPIO: %d\n",
-				ret);
-			return ret;
-		}
+		if (IS_ERR(chip->busy_pin))
+			return dev_err_probe(dev, PTR_ERR(chip->busy_pin),
+					     "Failed to request busy GPIO\n");
 	}
 
 	indio_dev->name = spi_get_device_id(spi_dev)->name;

---
base-commit: fa4ad798f6f681031775266044ba1b0cf3c670bd
change-id: 20261107-batch1-s3-warn-289c98c7b118

Best regards,
--  
Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>

