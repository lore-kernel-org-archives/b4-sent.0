From: DelaySystem <DelaySystem@tubot.lat>
Date: Sat, 07 Nov 2026 21:13:23 -0800
Subject: [PATCH] staging: iio: adc: ad7816: use dev_err_probe() for GPIO
 lookups
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-batch1-s3-warn-v1-1-4fc38341ca38@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ6CMAyA4VchPdOEjgSGr2I4bKVKPUyzApoQ3
 p2px+/w/zuYZBWDS7VDlk1Nn6mA6gp4DukuqFMxuMZ1RE2PMSw8E1qL75ATOj/w4LmPRB5K9Mp
 y089veB3/tjU+hJfvBY7jBFQOt1hyAAAA
X-Change-ID: 20261107-batch1-s3-warn-289c98c7b118
To: nuno.sa@analog.com, jic23@kernel.org, dlechner@baylibre.com, 
 gregkh@linuxfoundation.org, Michael.Hennerich@analog.com, andy@kernel.org
Cc: linux-staging@lists.linux.dev, linux@analog.com, 
 linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 DelaySystem <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1972; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=/dZESaHHxJHhLeUXDlNHKxcjmakcm6DTe+ZTrXLn33w=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFkfWD4t2bDKqnq67s85Mr/1JV9fvep+fmbqL/Yte2qKN
 LMX+l1P6yhlYRDjYJAVU2QRk+F5X39fJ87aas4JmDmsTCBDGLg4BWAiF4QY/tcG5uh+2zCf3eWD
 zpuSCbnZUR//x5pyS+eEWUWsmdjBfJ/hn+3hwoNS2uoTJBisTGqu876eXBO9la0gSPGTzk32ANa
 /fAA=
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

Signed-off-by: DelaySystem <DelaySystem@tubot.lat>
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
DelaySystem <DelaySystem@tubot.lat>

