From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 22 Apr 2026 15:45:44 +0100
Subject: [PATCH 10/22] iio: dac: ad5686: add of_match table to the spi
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-ad5313r-iio-support-v1-10-ed7dca001d1b@analog.com>
References: <20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com>
In-Reply-To: <20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com>
To: Jonathan Cameron <jic23@kernel.org>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Michael Auchter <michael.auchter@ni.com>, linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776869181; l=1849;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=C7y+tv8tl9vSOd2HafCCTEPh7cdjuxKwc/v91PQUx9E=;
 b=WY9x4RgC1GHSTS1QD9/Q94sNL6zKsziziM763el98x+DfBvcFe4tmyKCLisSjkDIxK4C0CE7f
 UFWhFLHkHdxCMUuvCbOkbiY2GZCQSHCfY1qW6qpYQ0RtOBDl8Jk3GUg
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add of_match table for the SPI device variants to be consistent with the
AD5696 I2C driver.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686-spi.c | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/drivers/iio/dac/ad5686-spi.c b/drivers/iio/dac/ad5686-spi.c
index 7a7a19a01b56..6c9b70880da9 100644
--- a/drivers/iio/dac/ad5686-spi.c
+++ b/drivers/iio/dac/ad5686-spi.c
@@ -118,9 +118,30 @@ static const struct spi_device_id ad5686_spi_id[] = {
 };
 MODULE_DEVICE_TABLE(spi, ad5686_spi_id);
 
+static const struct of_device_id ad5686_of_match[] = {
+	{ .compatible = "adi,ad5310r", .data = &ad5310r_chip_info },
+	{ .compatible = "adi,ad5672r", .data = &ad5672r_chip_info },
+	{ .compatible = "adi,ad5674r", .data = &ad5674r_chip_info },
+	{ .compatible = "adi,ad5676",  .data = &ad5676_chip_info },
+	{ .compatible = "adi,ad5676r", .data = &ad5676r_chip_info },
+	{ .compatible = "adi,ad5679r", .data = &ad5679r_chip_info },
+	{ .compatible = "adi,ad5681r", .data = &ad5681r_chip_info },
+	{ .compatible = "adi,ad5682r", .data = &ad5682r_chip_info },
+	{ .compatible = "adi,ad5683",  .data = &ad5683_chip_info },
+	{ .compatible = "adi,ad5683r", .data = &ad5683r_chip_info },
+	{ .compatible = "adi,ad5684",  .data = &ad5684_chip_info },
+	{ .compatible = "adi,ad5684r", .data = &ad5684r_chip_info },
+	{ .compatible = "adi,ad5685r", .data = &ad5685r_chip_info },
+	{ .compatible = "adi,ad5686",  .data = &ad5686_chip_info },
+	{ .compatible = "adi,ad5686r", .data = &ad5686r_chip_info },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, ad5686_of_match);
+
 static struct spi_driver ad5686_spi_driver = {
 	.driver = {
 		.name = "ad5686",
+		.of_match_table = ad5686_of_match,
 	},
 	.probe = ad5686_spi_probe,
 	.id_table = ad5686_spi_id,

-- 
2.43.0

