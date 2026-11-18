From: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
Date: Wed, 18 Nov 2026 10:22:17 -0800
Subject: [PATCH v3] staging: iio: adc: ad7816: use dev_err_probe() for GPIO
 lookups
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-batch1-s3-warn-v3-1-f622d212deeb@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ7CIBQFr9KwFtMPaKkr72FcAP5ajCkGKGqa3
 l2omybG5SRv5k0koLcYyKGaiMdkg3VDBr6piOnVcEVqL5kJq9keoG6oVtH0QAOnT+UHymRrWmk
 aDSBJlh4eO/tagqfzl8Oob2hiqZRFb0N0/r08Jii7v/EEFKjoDJdcgFFcHuOoXdzeVSQlnthKh
 1+dZR2aTuBOADCu1/o8zx/ZkGR3/QAAAA==
X-Change-ID: 20261107-batch1-s3-warn-289c98c7b118
To: nuno.sa@analog.com, andy@kernel.org, gregkh@linuxfoundation.org, 
 jic23@kernel.org, dlechner@baylibre.com, Michael.Hennerich@analog.com
Cc: linux-staging@lists.linux.dev, linux-iio@vger.kernel.org, 
 linux@analog.com, krzk@kernel.org, linux-kernel@vger.kernel.org, 
 crofts@kernel.org, Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2746; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=AmqBcsa25DReGcyElJDVwLM4MEKGLB/bkwyZBeRmiyY=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFl/35pe0kn71vJ75w/V/DXPZgc/8HVdZHlO+53kgt/Lp
 H5fF2Cb2FHKwiDGwSArpsgiJsPzvv6+Tpy11ZwTMHNYmUCGMHBxCsBE9uYwMry6ILJgTVGbdt3l
 3XYb6vO+/pH/+frhPcclj36tEi3/F3+W4a9c5LKFLhdqNopYHj37ZN0z99daO9i2eM6rfPU7SfR
 5tSU3AA==
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
Changes in v3:
- Convert the missed busy-GPIO failure path to dev_err_probe() as well (Joshua Crofts).
- Link to v2: https://patch.msgid.link/20261117-batch1-s3-warn-v2-1-17f4e541123b@tubot.lat

Changes in v2:
- Resend under my real name (From/Signed-off-by: Maximo Manriquez Lizarraga).
- Apologies for the improper sign-off on v1; no code change.
- Link to v1: https://patch.msgid.link/20261107-batch1-s3-warn-v1-1-4fc38341ca38@tubot.lat
---
 drivers/staging/iio/adc/ad7816.c | 27 +++++++++------------------
 1 file changed, 9 insertions(+), 18 deletions(-)

diff --git a/drivers/staging/iio/adc/ad7816.c b/drivers/staging/iio/adc/ad7816.c
index 2a15d7598abb..dc9d89ca04ab 100644
--- a/drivers/staging/iio/adc/ad7816.c
+++ b/drivers/staging/iio/adc/ad7816.c
@@ -381,29 +381,20 @@ static int ad7816_probe(struct spi_device *spi_dev)
 
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
-		if (IS_ERR(chip->busy_pin)) {
-			ret = PTR_ERR(chip->busy_pin);
-			dev_err(&spi_dev->dev, "Failed to request busy GPIO: %d\n",
-				ret);
-			return ret;
-		}
+		if (IS_ERR(chip->busy_pin))
+			return dev_err_probe(&spi_dev->dev, PTR_ERR(chip->busy_pin),
+					     "Failed to request busy GPIO\n");
 	}
 
 	indio_dev->name = spi_get_device_id(spi_dev)->name;

---
base-commit: fa4ad798f6f681031775266044ba1b0cf3c670bd
change-id: 20261107-batch1-s3-warn-289c98c7b118

Best regards,
--  
Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>

