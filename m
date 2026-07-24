From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 24 Jul 2026 13:03:16 +0100
Subject: [PATCH v2 6/6] iio: dac: ad5686: extend device support with new
 parts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-ad5686-extend-dev-support-v2-6-cfc2b30ce988@analog.com>
References: <20260724-ad5686-extend-dev-support-v2-0-cfc2b30ce988@analog.com>
In-Reply-To: <20260724-ad5686-extend-dev-support-v2-0-cfc2b30ce988@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784894592; l=12031;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=r4tTUPqjyaUCmzwMhrMqRzy8M9AM9PAmGC+d3VXToU8=;
 b=H4+5YhZ8Fl2fOCs4vwCDyD+NFeekiMEtVENPpy8smPQlKXrCAqGgmVJAZz1MjwaUOFJxrXNeR
 1bVHtbI8jZSDhz23kO05o1Xgh1gzPkz8vXxkEp4Y/Ln+DEmQoRDK8Uc
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for AD5313R, AD5317R, AD5674, AD5679, AD5687, AD5687R, AD5689,
AD5689R to the AD5686 SPI driver. Also adding support for AD5316R, AD5675,
AD5697R to the AD5696 I2C driver. This includes the creation of seven chip
info struct instances and reuse of existing ones.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/Kconfig      | 12 ++++++----
 drivers/iio/dac/ad5686-spi.c | 16 +++++++++++++
 drivers/iio/dac/ad5686.c     | 55 ++++++++++++++++++++++++++++++++++++++++++++
 drivers/iio/dac/ad5686.h     |  7 ++++++
 drivers/iio/dac/ad5696-i2c.c |  6 +++++
 5 files changed, 91 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/dac/Kconfig b/drivers/iio/dac/Kconfig
index 3ae997939ff5..18a27785e28b 100644
--- a/drivers/iio/dac/Kconfig
+++ b/drivers/iio/dac/Kconfig
@@ -255,12 +255,14 @@ config AD5686_SPI
 	  Digital to Analog Converters:
 	  - Single-channel:
 	    AD5310R, AD5681R, AD5682R, AD5683, AD5683R
+	  - Dual-channel:
+	    AD5313R, AD5687, AD5687R, AD5689, AD5689R
 	  - Quad-channel:
-	    AD5684, AD5684R, AD5685R, AD5686, AD5686R
+	    AD5317R, AD5684, AD5684R, AD5685R, AD5686, AD5686R
 	  - 8-channel:
 	    AD5672R, AD5676, AD5676R
 	  - 16-channel:
-	    AD5674R, AD5679R
+	    AD5674, AD5674R, AD5679, AD5679R
 
 	  To compile this driver as a module, choose M here: the
 	  module will be called ad5686.
@@ -275,11 +277,11 @@ config AD5696_I2C
 	  - Single-channel:
 	    AD5311R, AD5691R, AD5692R, AD5693, AD5693R
 	  - Dual-channel:
-	    AD5338R
+	    AD5338R, AD5697R
 	  - Quad-channel:
-	    AD5694, AD5694R, AD5695R, AD5696, AD5696R
+	    AD5316R, AD5694, AD5694R, AD5695R, AD5696, AD5696R
 	  - 8-channel:
-	    AD5671R, AD5675R
+	    AD5671R, AD5675, AD5675R
 	  - 16-channel:
 	    AD5673R, AD5677R
 
diff --git a/drivers/iio/dac/ad5686-spi.c b/drivers/iio/dac/ad5686-spi.c
index 2689d66c7c20..2a09b448acd4 100644
--- a/drivers/iio/dac/ad5686-spi.c
+++ b/drivers/iio/dac/ad5686-spi.c
@@ -175,10 +175,14 @@ static int ad5686_spi_probe(struct spi_device *spi)
 
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
@@ -190,16 +194,24 @@ static const struct spi_device_id ad5686_spi_id[] = {
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
@@ -210,6 +222,10 @@ static const struct of_device_id ad5686_of_match[] = {
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
index e2beba6d54b1..0cc1c9c22a28 100644
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
index 4a249f9cdb8f..bffe60452c34 100644
--- a/drivers/iio/dac/ad5696-i2c.c
+++ b/drivers/iio/dac/ad5696-i2c.c
@@ -78,10 +78,12 @@ static int ad5686_i2c_probe(struct i2c_client *i2c)
 
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
@@ -93,16 +95,19 @@ static const struct i2c_device_id ad5686_i2c_id[] = {
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
 	{ .compatible = "adi,ad5673r", .data = &ad5674r_chip_info },
+	{ .compatible = "adi,ad5675",  .data = &ad5676_chip_info },
 	{ .compatible = "adi,ad5675r", .data = &ad5676r_chip_info },
 	{ .compatible = "adi,ad5677r", .data = &ad5679r_chip_info },
 	{ .compatible = "adi,ad5691r", .data = &ad5681r_chip_info },
@@ -114,6 +119,7 @@ static const struct of_device_id ad5686_of_match[] = {
 	{ .compatible = "adi,ad5695r", .data = &ad5685r_chip_info },
 	{ .compatible = "adi,ad5696",  .data = &ad5686_chip_info },
 	{ .compatible = "adi,ad5696r", .data = &ad5686r_chip_info },
+	{ .compatible = "adi,ad5697r", .data = &ad5687r_chip_info },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, ad5686_of_match);

-- 
2.43.0

