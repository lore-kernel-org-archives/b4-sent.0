From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sun, 19 Jul 2026 10:51:59 +0100
Subject: [PATCH 3/4] iio: dac: ad5686: extend device support with new parts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260719-ad5686-extend-dev-support-v1-3-841ec75cf5d8@analog.com>
References: <20260719-ad5686-extend-dev-support-v1-0-841ec75cf5d8@analog.com>
In-Reply-To: <20260719-ad5686-extend-dev-support-v1-0-841ec75cf5d8@analog.com>
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784454721; l=10989;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=pwyIWIwpbueR4AW5F3cEAEBFNsVvf6IGY71bPbLlF4g=;
 b=AjeIocc/+0xj5fsFGGEJ3FskdB5kdwwYZJCi/KKkus1xND75sEWp0/de/kikfSIEk8dULRYN+
 N4ef89IkYDMAsbQh8DrhPjVY9kyhyueOpCDSct8k+NM9nWaGKI50xAf
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for AD5313R, AD5317R, AD5674, AD5679, AD5687, AD5687R, AD5689,
AD5689R to the AD5686 SPI driver. Also adding support for AD5316R, AD5675,
AD5697R to the AD5696 I2C driver. AD5673R and AD5677R were missing from
the of_match table. This includes the creation of seven chip info struct
instances and reuse of existing ones.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686-spi.c | 16 +++++++++++++
 drivers/iio/dac/ad5686.c     | 55 ++++++++++++++++++++++++++++++++++++++++++++
 drivers/iio/dac/ad5686.h     |  7 ++++++
 drivers/iio/dac/ad5696-i2c.c |  8 +++++++
 4 files changed, 86 insertions(+)

diff --git a/drivers/iio/dac/ad5686-spi.c b/drivers/iio/dac/ad5686-spi.c
index 227ddb269669..003541edb742 100644
--- a/drivers/iio/dac/ad5686-spi.c
+++ b/drivers/iio/dac/ad5686-spi.c
@@ -178,10 +178,14 @@ static int ad5686_spi_probe(struct spi_device *spi)
 
 static const struct spi_device_id ad5686_spi_id[] = {
 	{ .name = "ad5310r", .driver_data = (kernel_ulong_t)&ad5310r_chip_info },
+	{ .name = "ad5313r", .driver_data = (kernel_ulong_t)&ad5338r_chip_info },
+	{ .name = "ad5317r", .driver_data = (kernel_ulong_t)&ad5317r_chip_info },
 	{ .name = "ad5672r", .driver_data = (kernel_ulong_t)&ad5672r_chip_info },
+	{ .name = "ad5674",  .driver_data = (kernel_ulong_t)&ad5674_chip_info },
 	{ .name = "ad5674r", .driver_data = (kernel_ulong_t)&ad5674r_chip_info },
 	{ .name = "ad5676",  .driver_data = (kernel_ulong_t)&ad5676_chip_info },
 	{ .name = "ad5676r", .driver_data = (kernel_ulong_t)&ad5676r_chip_info },
+	{ .name = "ad5679",  .driver_data = (kernel_ulong_t)&ad5679_chip_info },
 	{ .name = "ad5679r", .driver_data = (kernel_ulong_t)&ad5679r_chip_info },
 	{ .name = "ad5681r", .driver_data = (kernel_ulong_t)&ad5681r_chip_info },
 	{ .name = "ad5682r", .driver_data = (kernel_ulong_t)&ad5682r_chip_info },
@@ -193,16 +197,24 @@ static const struct spi_device_id ad5686_spi_id[] = {
 	{ .name = "ad5685r", .driver_data = (kernel_ulong_t)&ad5685r_chip_info },
 	{ .name = "ad5686",  .driver_data = (kernel_ulong_t)&ad5686_chip_info },
 	{ .name = "ad5686r", .driver_data = (kernel_ulong_t)&ad5686r_chip_info },
+	{ .name = "ad5687",  .driver_data = (kernel_ulong_t)&ad5687_chip_info },
+	{ .name = "ad5687r", .driver_data = (kernel_ulong_t)&ad5687r_chip_info },
+	{ .name = "ad5689",  .driver_data = (kernel_ulong_t)&ad5689_chip_info },
+	{ .name = "ad5689r", .driver_data = (kernel_ulong_t)&ad5689r_chip_info },
 	{ }
 };
 MODULE_DEVICE_TABLE(spi, ad5686_spi_id);
 
 static const struct of_device_id ad5686_of_match[] = {
 	{ .compatible = "adi,ad5310r", .data = &ad5310r_chip_info },
+	{ .compatible = "adi,ad5313r", .data = &ad5338r_chip_info },
+	{ .compatible = "adi,ad5317r", .data = &ad5317r_chip_info },
 	{ .compatible = "adi,ad5672r", .data = &ad5672r_chip_info },
+	{ .compatible = "adi,ad5674",  .data = &ad5674_chip_info },
 	{ .compatible = "adi,ad5674r", .data = &ad5674r_chip_info },
 	{ .compatible = "adi,ad5676",  .data = &ad5676_chip_info },
 	{ .compatible = "adi,ad5676r", .data = &ad5676r_chip_info },
+	{ .compatible = "adi,ad5679",  .data = &ad5679_chip_info },
 	{ .compatible = "adi,ad5679r", .data = &ad5679r_chip_info },
 	{ .compatible = "adi,ad5681r", .data = &ad5681r_chip_info },
 	{ .compatible = "adi,ad5682r", .data = &ad5682r_chip_info },
@@ -213,6 +225,10 @@ static const struct of_device_id ad5686_of_match[] = {
 	{ .compatible = "adi,ad5685r", .data = &ad5685r_chip_info },
 	{ .compatible = "adi,ad5686",  .data = &ad5686_chip_info },
 	{ .compatible = "adi,ad5686r", .data = &ad5686r_chip_info },
+	{ .compatible = "adi,ad5687",  .data = &ad5687_chip_info },
+	{ .compatible = "adi,ad5687r", .data = &ad5687r_chip_info },
+	{ .compatible = "adi,ad5689",  .data = &ad5689_chip_info },
+	{ .compatible = "adi,ad5689r", .data = &ad5689r_chip_info },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, ad5686_of_match);
diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 873dfb5b9107..090707d76d6e 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -409,8 +409,11 @@ DECLARE_AD5683_CHANNELS(ad5683r_channels, 16, 0);
 /* dual-channel */
 DECLARE_AD5338_CHANNELS(ad5337r_channels, 8, 8);
 DECLARE_AD5338_CHANNELS(ad5338r_channels, 10, 6);
+DECLARE_AD5338_CHANNELS(ad5687r_channels, 12, 4);
+DECLARE_AD5338_CHANNELS(ad5689r_channels, 16, 0);
 
 /* quad-channel */
+DECLARE_AD5686_CHANNELS(ad5317r_channels, 10, 6);
 DECLARE_AD5686_CHANNELS(ad5684r_channels, 12, 4);
 DECLARE_AD5686_CHANNELS(ad5685r_channels, 14, 2);
 DECLARE_AD5686_CHANNELS(ad5686r_channels, 16, 0);
@@ -486,6 +489,44 @@ const struct ad5686_chip_info ad5338r_chip_info = {
 };
 EXPORT_SYMBOL_NS_GPL(ad5338r_chip_info, "IIO_AD5686");
 
+const struct ad5686_chip_info ad5687_chip_info = {
+	.channels = ad5687r_channels,
+	.num_channels = 2,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5687_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5687r_chip_info = {
+	.channels = ad5687r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 2,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5687r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5689_chip_info = {
+	.channels = ad5689r_channels,
+	.num_channels = 2,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5689_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5689r_chip_info = {
+	.channels = ad5689r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 2,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5689r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5317r_chip_info = {
+	.channels = ad5317r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 4,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5317r_chip_info, "IIO_AD5686");
+
 const struct ad5686_chip_info ad5684_chip_info = {
 	.channels = ad5684r_channels,
 	.num_channels = 4,
@@ -547,6 +588,13 @@ const struct ad5686_chip_info ad5676r_chip_info = {
 };
 EXPORT_SYMBOL_NS_GPL(ad5676r_chip_info, "IIO_AD5686");
 
+const struct ad5686_chip_info ad5674_chip_info = {
+	.channels = ad5674r_channels,
+	.num_channels = 16,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5674_chip_info, "IIO_AD5686");
+
 const struct ad5686_chip_info ad5674r_chip_info = {
 	.channels = ad5674r_channels,
 	.int_vref_mv = 2500,
@@ -555,6 +603,13 @@ const struct ad5686_chip_info ad5674r_chip_info = {
 };
 EXPORT_SYMBOL_NS_GPL(ad5674r_chip_info, "IIO_AD5686");
 
+const struct ad5686_chip_info ad5679_chip_info = {
+	.channels = ad5679r_channels,
+	.num_channels = 16,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5679_chip_info, "IIO_AD5686");
+
 const struct ad5686_chip_info ad5679r_chip_info = {
 	.channels = ad5679r_channels,
 	.int_vref_mv = 2500,
diff --git a/drivers/iio/dac/ad5686.h b/drivers/iio/dac/ad5686.h
index c1222ef83a4f..482bc70515f7 100644
--- a/drivers/iio/dac/ad5686.h
+++ b/drivers/iio/dac/ad5686.h
@@ -106,8 +106,13 @@ extern const struct ad5686_chip_info ad5683r_chip_info;
 /* dual-channel instances */
 extern const struct ad5686_chip_info ad5337r_chip_info;
 extern const struct ad5686_chip_info ad5338r_chip_info;
+extern const struct ad5686_chip_info ad5687_chip_info;
+extern const struct ad5686_chip_info ad5687r_chip_info;
+extern const struct ad5686_chip_info ad5689_chip_info;
+extern const struct ad5686_chip_info ad5689r_chip_info;
 
 /* quad-channel instances */
+extern const struct ad5686_chip_info ad5317r_chip_info;
 extern const struct ad5686_chip_info ad5684_chip_info;
 extern const struct ad5686_chip_info ad5684r_chip_info;
 extern const struct ad5686_chip_info ad5685r_chip_info;
@@ -120,7 +125,9 @@ extern const struct ad5686_chip_info ad5676_chip_info;
 extern const struct ad5686_chip_info ad5676r_chip_info;
 
 /* 16-channel instances */
+extern const struct ad5686_chip_info ad5674_chip_info;
 extern const struct ad5686_chip_info ad5674r_chip_info;
+extern const struct ad5686_chip_info ad5679_chip_info;
 extern const struct ad5686_chip_info ad5679r_chip_info;
 
 /**
diff --git a/drivers/iio/dac/ad5696-i2c.c b/drivers/iio/dac/ad5696-i2c.c
index 31439567f00f..7254bb976388 100644
--- a/drivers/iio/dac/ad5696-i2c.c
+++ b/drivers/iio/dac/ad5696-i2c.c
@@ -80,10 +80,12 @@ static int ad5686_i2c_probe(struct i2c_client *i2c)
 
 static const struct i2c_device_id ad5686_i2c_id[] = {
 	{ .name = "ad5311r", .driver_data = (kernel_ulong_t)&ad5311r_chip_info },
+	{ .name = "ad5316r", .driver_data = (kernel_ulong_t)&ad5317r_chip_info },
 	{ .name = "ad5337r", .driver_data = (kernel_ulong_t)&ad5337r_chip_info },
 	{ .name = "ad5338r", .driver_data = (kernel_ulong_t)&ad5338r_chip_info },
 	{ .name = "ad5671r", .driver_data = (kernel_ulong_t)&ad5672r_chip_info },
 	{ .name = "ad5673r", .driver_data = (kernel_ulong_t)&ad5674r_chip_info },
+	{ .name = "ad5675",  .driver_data = (kernel_ulong_t)&ad5676_chip_info },
 	{ .name = "ad5675r", .driver_data = (kernel_ulong_t)&ad5676r_chip_info },
 	{ .name = "ad5677r", .driver_data = (kernel_ulong_t)&ad5679r_chip_info },
 	{ .name = "ad5691r", .driver_data = (kernel_ulong_t)&ad5681r_chip_info },
@@ -95,16 +97,21 @@ static const struct i2c_device_id ad5686_i2c_id[] = {
 	{ .name = "ad5695r", .driver_data = (kernel_ulong_t)&ad5685r_chip_info },
 	{ .name = "ad5696",  .driver_data = (kernel_ulong_t)&ad5686_chip_info },
 	{ .name = "ad5696r", .driver_data = (kernel_ulong_t)&ad5686r_chip_info },
+	{ .name = "ad5697r", .driver_data = (kernel_ulong_t)&ad5687r_chip_info },
 	{ }
 };
 MODULE_DEVICE_TABLE(i2c, ad5686_i2c_id);
 
 static const struct of_device_id ad5686_of_match[] = {
 	{ .compatible = "adi,ad5311r", .data = &ad5311r_chip_info },
+	{ .compatible = "adi,ad5316r", .data = &ad5317r_chip_info },
 	{ .compatible = "adi,ad5337r", .data = &ad5337r_chip_info },
 	{ .compatible = "adi,ad5338r", .data = &ad5338r_chip_info },
 	{ .compatible = "adi,ad5671r", .data = &ad5672r_chip_info },
+	{ .compatible = "adi,ad5673r", .data = &ad5674r_chip_info },
+	{ .compatible = "adi,ad5675",  .data = &ad5676_chip_info },
 	{ .compatible = "adi,ad5675r", .data = &ad5676r_chip_info },
+	{ .compatible = "adi,ad5677r", .data = &ad5679r_chip_info },
 	{ .compatible = "adi,ad5691r", .data = &ad5681r_chip_info },
 	{ .compatible = "adi,ad5692r", .data = &ad5682r_chip_info },
 	{ .compatible = "adi,ad5693",  .data = &ad5683_chip_info },
@@ -114,6 +121,7 @@ static const struct of_device_id ad5686_of_match[] = {
 	{ .compatible = "adi,ad5695r", .data = &ad5685r_chip_info },
 	{ .compatible = "adi,ad5696",  .data = &ad5686_chip_info },
 	{ .compatible = "adi,ad5696r", .data = &ad5686r_chip_info },
+	{ .compatible = "adi,ad5697r", .data = &ad5687r_chip_info },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, ad5686_of_match);

-- 
2.43.0

