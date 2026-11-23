From: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
Date: Mon, 23 Nov 2026 13:47:16 -0800
Subject: [PATCH v4] staging: iio: adc: ad7816: use dev_err_probe() for GPIO
 lookups
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-batch1-s3-warn-v4-1-47cd8d7d4ce9@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XNQQ7CIBCF4asY1mKcAS268h7GBdCpxZjWAK2ap
 ncX6qZqXL5kvn8GFsg7Cmy/GJin3gXXNmnI5YLZWjdn4q5Mm+EatwDrghsdbQ08CH7XvuGodna
 nbGEAFEvo5qlyjyl4PL136MyFbMyVfFG7EFv/nD72kO/+xnvgwGVlhRISrBbqEDvTxtVVR5bjP
 c44/HJMHIpK0kYCoDDfXMy5+uEi8WqLWCJgSfTBx3F8ASco9EI8AQAA
X-Change-ID: 20261107-batch1-s3-warn-289c98c7b118
To: andy@kernel.org, nuno.sa@analog.com, gregkh@linuxfoundation.org, 
 dlechner@baylibre.com, jic23@kernel.org, Michael.Hennerich@analog.com
Cc: linux-staging@lists.linux.dev, krzk@kernel.org, crofts@kernel.org, 
 linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, linux@analog.com, 
 Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3394; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=3qSIiHaUfGU0fUooR+d3SlhKg7lFwrjdgQuTuX1Jf34=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDNksWw7sVfFuZHFZvGGavsr2VZEFSbd2hwu+tSie9zlNf
 XHWl4zrHaUsDGIcDLJiiixiMjzv6+/rxFlbzTkBM4eVCWQIAxenAEzExZThn3HQ2peCYm/KOP52
 9HD3zxdoj3D6rvnSJGvd+fry1T78+xgZ/lQoGsfKn2Bccz2z4Ujw8eIlf0T2GKw/u5XBR9008cQ
 8TgA=
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
 drivers/staging/iio/adc/ad7816.c | 34 +++++++++++++---------------------
 1 file changed, 13 insertions(+), 21 deletions(-)

diff --git a/drivers/staging/iio/adc/ad7816.c b/drivers/staging/iio/adc/ad7816.c
index 2a15d7598abb..2fd0c4658918 100644
--- a/drivers/staging/iio/adc/ad7816.c
+++ b/drivers/staging/iio/adc/ad7816.c
@@ -364,6 +364,7 @@ static int ad7816_probe(struct spi_device *spi_dev)
 {
 	struct ad7816_chip_info *chip;
 	struct iio_dev *indio_dev;
+	struct device *dev = &spi_dev->dev;
 	int i, ret;
 
 	indio_dev = devm_iio_device_alloc(&spi_dev->dev, sizeof(*chip));
@@ -380,30 +381,21 @@ static int ad7816_probe(struct spi_device *spi_dev)
 		chip->oti_data[i] = 203;
 
 	chip->id = spi_get_device_id(spi_dev)->driver_data;
-	chip->rdwr_pin = devm_gpiod_get(&spi_dev->dev, "rdwr", GPIOD_OUT_HIGH);
-	if (IS_ERR(chip->rdwr_pin)) {
-		ret = PTR_ERR(chip->rdwr_pin);
-		dev_err(&spi_dev->dev, "Failed to request rdwr GPIO: %d\n",
-			ret);
-		return ret;
-	}
-	chip->convert_pin = devm_gpiod_get(&spi_dev->dev, "convert",
+	chip->rdwr_pin = devm_gpiod_get(dev, "rdwr", GPIOD_OUT_HIGH);
+	if (IS_ERR(chip->rdwr_pin))
+		return dev_err_probe(dev, PTR_ERR(chip->rdwr_pin),
+				     "Failed to request rdwr GPIO\n");
+	chip->convert_pin = devm_gpiod_get(dev, "convert",
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
-		chip->busy_pin = devm_gpiod_get(&spi_dev->dev, "busy",
+		chip->busy_pin = devm_gpiod_get(dev, "busy",
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

