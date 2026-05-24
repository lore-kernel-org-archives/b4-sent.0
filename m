From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sun, 24 May 2026 11:17:03 +0100
Subject: [PATCH v7 3/8] iio: dac: ad5686: drop enum id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260524-ad5686-fixes-v7-3-b6bf395d08bd@analog.com>
References: <20260524-ad5686-fixes-v7-0-b6bf395d08bd@analog.com>
In-Reply-To: <20260524-ad5686-fixes-v7-0-b6bf395d08bd@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Stefan Popa <stefan.popa@analog.com>, Jonathan Cameron <jic23@cam.ac.uk>, 
 Greg Kroah-Hartman <gregkh@suse.de>, 
 Michael Auchter <michael.auchter@ni.com>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779617840; l=20870;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=X/0nz8wAODOrLwdGmRTIUXkA1EKNyVIp8YCMLJu4Dsc=;
 b=0OFFheb7uSt9Xms29VM3XfaTNZSCvCg2b3kYrvZ5ZY2hteaaVV46cG6CUVoSoCWIS50G2ZjGZ
 K+VLa+bDU6yDb4ue/w/YykynKvEjbMr93SIx0LS7tgTcY64Bo23zejM
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Split chip info table into separate structs and expose them to the spi
i2c drivers. That is the preferrable approach and allows for the drivers
to have knowledge of the device info before the common probe function gets
called. Those chip info structs may be shared by SPI and I2C driver
variants.
Channel declaration definitions are grouped according to channel count and
DECLARE_AD5693_CHANNELS() macro is renamed to DECLARE_AD5683_CHANNELS() to
match the regmap_type enum.
Use spi_get_device_match_data() and i2c_get_match_data() to get chip info
struct reference, passing it as parameter to the core probe function.

Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686-spi.c |  38 +++--
 drivers/iio/dac/ad5686.c     | 358 ++++++++++++++++++++-----------------------
 drivers/iio/dac/ad5686.h     |  66 ++++----
 drivers/iio/dac/ad5696-i2c.c |  65 ++++----
 4 files changed, 241 insertions(+), 286 deletions(-)

diff --git a/drivers/iio/dac/ad5686-spi.c b/drivers/iio/dac/ad5686-spi.c
index cec784b617e6..3a2eafedce92 100644
--- a/drivers/iio/dac/ad5686-spi.c
+++ b/drivers/iio/dac/ad5686-spi.c
@@ -94,29 +94,27 @@ static int ad5686_spi_read(struct ad5686_state *st, u8 addr)
 
 static int ad5686_spi_probe(struct spi_device *spi)
 {
-	const struct spi_device_id *id = spi_get_device_id(spi);
-
-	return ad5686_probe(&spi->dev, id->driver_data, id->name,
-			    ad5686_spi_write, ad5686_spi_read);
+	return ad5686_probe(&spi->dev, spi_get_device_match_data(spi),
+			    spi->modalias, ad5686_spi_write, ad5686_spi_read);
 }
 
 static const struct spi_device_id ad5686_spi_id[] = {
-	{"ad5310r", ID_AD5310R},
-	{"ad5672r", ID_AD5672R},
-	{"ad5674r", ID_AD5674R},
-	{"ad5676", ID_AD5676},
-	{"ad5676r", ID_AD5676R},
-	{"ad5679r", ID_AD5679R},
-	{"ad5681r", ID_AD5681R},
-	{"ad5682r", ID_AD5682R},
-	{"ad5683", ID_AD5683},
-	{"ad5683r", ID_AD5683R},
-	{"ad5684", ID_AD5684},
-	{"ad5684r", ID_AD5684R},
-	{"ad5685", ID_AD5685R}, /* Does not exist */
-	{"ad5685r", ID_AD5685R},
-	{"ad5686", ID_AD5686},
-	{"ad5686r", ID_AD5686R},
+	{ .name = "ad5310r", .driver_data = (kernel_ulong_t)&ad5310r_chip_info },
+	{ .name = "ad5672r", .driver_data = (kernel_ulong_t)&ad5672r_chip_info },
+	{ .name = "ad5674r", .driver_data = (kernel_ulong_t)&ad5674r_chip_info },
+	{ .name = "ad5676",  .driver_data = (kernel_ulong_t)&ad5676_chip_info },
+	{ .name = "ad5676r", .driver_data = (kernel_ulong_t)&ad5676r_chip_info },
+	{ .name = "ad5679r", .driver_data = (kernel_ulong_t)&ad5679r_chip_info },
+	{ .name = "ad5681r", .driver_data = (kernel_ulong_t)&ad5681r_chip_info },
+	{ .name = "ad5682r", .driver_data = (kernel_ulong_t)&ad5682r_chip_info },
+	{ .name = "ad5683",  .driver_data = (kernel_ulong_t)&ad5683_chip_info },
+	{ .name = "ad5683r", .driver_data = (kernel_ulong_t)&ad5683r_chip_info },
+	{ .name = "ad5684",  .driver_data = (kernel_ulong_t)&ad5684_chip_info },
+	{ .name = "ad5684r", .driver_data = (kernel_ulong_t)&ad5684r_chip_info },
+	{ .name = "ad5685",  .driver_data = (kernel_ulong_t)&ad5685r_chip_info }, /* nonexistent */
+	{ .name = "ad5685r", .driver_data = (kernel_ulong_t)&ad5685r_chip_info },
+	{ .name = "ad5686",  .driver_data = (kernel_ulong_t)&ad5686_chip_info },
+	{ .name = "ad5686r", .driver_data = (kernel_ulong_t)&ad5686r_chip_info },
 	{ }
 };
 MODULE_DEVICE_TABLE(spi, ad5686_spi_id);
diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 110ea24c31d1..50d4d5e8acf8 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -219,7 +219,7 @@ static const struct iio_chan_spec_ext_info ad5686_ext_info[] = {
 		.ext_info = ad5686_ext_info,			\
 }
 
-#define DECLARE_AD5693_CHANNELS(name, bits, _shift)		\
+#define DECLARE_AD5683_CHANNELS(name, bits, _shift)		\
 static const struct iio_chan_spec name[] = {			\
 		AD5868_CHANNEL(0, 0, bits, _shift),		\
 }
@@ -270,205 +270,172 @@ static const struct iio_chan_spec name[] = {			\
 		AD5868_CHANNEL(15, 15, bits, _shift),		\
 }
 
-DECLARE_AD5693_CHANNELS(ad5310r_channels, 10, 2);
-DECLARE_AD5693_CHANNELS(ad5311r_channels, 10, 6);
+/* single-channel */
+DECLARE_AD5683_CHANNELS(ad5310r_channels, 10, 2);
+DECLARE_AD5683_CHANNELS(ad5311r_channels, 10, 6);
+DECLARE_AD5683_CHANNELS(ad5681r_channels, 12, 4);
+DECLARE_AD5683_CHANNELS(ad5682r_channels, 14, 2);
+DECLARE_AD5683_CHANNELS(ad5683r_channels, 16, 0);
+
+/* dual-channel */
 DECLARE_AD5338_CHANNELS(ad5337r_channels, 8, 8);
 DECLARE_AD5338_CHANNELS(ad5338r_channels, 10, 6);
-DECLARE_AD5676_CHANNELS(ad5672_channels, 12, 4);
-DECLARE_AD5679_CHANNELS(ad5674r_channels, 12, 4);
-DECLARE_AD5676_CHANNELS(ad5676_channels, 16, 0);
-DECLARE_AD5679_CHANNELS(ad5679r_channels, 16, 0);
-DECLARE_AD5686_CHANNELS(ad5684_channels, 12, 4);
-DECLARE_AD5686_CHANNELS(ad5685r_channels, 14, 2);
-DECLARE_AD5686_CHANNELS(ad5686_channels, 16, 0);
-DECLARE_AD5693_CHANNELS(ad5693_channels, 16, 0);
-DECLARE_AD5693_CHANNELS(ad5692r_channels, 14, 2);
-DECLARE_AD5693_CHANNELS(ad5691r_channels, 12, 4);
 
-static const struct ad5686_chip_info ad5686_chip_info_tbl[] = {
-	[ID_AD5310R] = {
-		.channels = ad5310r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 1,
-		.regmap_type = AD5310_REGMAP,
-	},
-	[ID_AD5311R] = {
-		.channels = ad5311r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 1,
-		.regmap_type = AD5683_REGMAP,
-	},
-	[ID_AD5337R] = {
-		.channels = ad5337r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 2,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5338R] = {
-		.channels = ad5338r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 2,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5671R] = {
-		.channels = ad5672_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 8,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5672R] = {
-		.channels = ad5672_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 8,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5673R] = {
-		.channels = ad5674r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 16,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5674R] = {
-		.channels = ad5674r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 16,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5675R] = {
-		.channels = ad5676_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 8,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5676] = {
-		.channels = ad5676_channels,
-		.num_channels = 8,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5676R] = {
-		.channels = ad5676_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 8,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5677R] = {
-		.channels = ad5679r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 16,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5679R] = {
-		.channels = ad5679r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 16,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5681R] = {
-		.channels = ad5691r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 1,
-		.regmap_type = AD5683_REGMAP,
-	},
-	[ID_AD5682R] = {
-		.channels = ad5692r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 1,
-		.regmap_type = AD5683_REGMAP,
-	},
-	[ID_AD5683] = {
-		.channels = ad5693_channels,
-		.num_channels = 1,
-		.regmap_type = AD5683_REGMAP,
-	},
-	[ID_AD5683R] = {
-		.channels = ad5693_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 1,
-		.regmap_type = AD5683_REGMAP,
-	},
-	[ID_AD5684] = {
-		.channels = ad5684_channels,
-		.num_channels = 4,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5684R] = {
-		.channels = ad5684_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 4,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5685R] = {
-		.channels = ad5685r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 4,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5686] = {
-		.channels = ad5686_channels,
-		.num_channels = 4,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5686R] = {
-		.channels = ad5686_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 4,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5691R] = {
-		.channels = ad5691r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 1,
-		.regmap_type = AD5683_REGMAP,
-	},
-	[ID_AD5692R] = {
-		.channels = ad5692r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 1,
-		.regmap_type = AD5683_REGMAP,
-	},
-	[ID_AD5693] = {
-		.channels = ad5693_channels,
-		.num_channels = 1,
-		.regmap_type = AD5683_REGMAP,
-	},
-	[ID_AD5693R] = {
-		.channels = ad5693_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 1,
-		.regmap_type = AD5683_REGMAP,
-	},
-	[ID_AD5694] = {
-		.channels = ad5684_channels,
-		.num_channels = 4,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5694R] = {
-		.channels = ad5684_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 4,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5695R] = {
-		.channels = ad5685r_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 4,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5696] = {
-		.channels = ad5686_channels,
-		.num_channels = 4,
-		.regmap_type = AD5686_REGMAP,
-	},
-	[ID_AD5696R] = {
-		.channels = ad5686_channels,
-		.int_vref_mv = 2500,
-		.num_channels = 4,
-		.regmap_type = AD5686_REGMAP,
-	},
+/* quad-channel */
+DECLARE_AD5686_CHANNELS(ad5684r_channels, 12, 4);
+DECLARE_AD5686_CHANNELS(ad5685r_channels, 14, 2);
+DECLARE_AD5686_CHANNELS(ad5686r_channels, 16, 0);
+
+/* 8-channel */
+DECLARE_AD5676_CHANNELS(ad5672r_channels, 12, 4);
+DECLARE_AD5676_CHANNELS(ad5676r_channels, 16, 0);
+
+/* 16-channel */
+DECLARE_AD5679_CHANNELS(ad5674r_channels, 12, 4);
+DECLARE_AD5679_CHANNELS(ad5679r_channels, 16, 0);
+
+const struct ad5686_chip_info ad5310r_chip_info = {
+	.channels = ad5310r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 1,
+	.regmap_type = AD5310_REGMAP,
 };
+EXPORT_SYMBOL_NS_GPL(ad5310r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5311r_chip_info = {
+	.channels = ad5311r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 1,
+	.regmap_type = AD5683_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5311r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5681r_chip_info = {
+	.channels = ad5681r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 1,
+	.regmap_type = AD5683_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5681r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5682r_chip_info = {
+	.channels = ad5682r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 1,
+	.regmap_type = AD5683_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5682r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5683_chip_info = {
+	.channels = ad5683r_channels,
+	.num_channels = 1,
+	.regmap_type = AD5683_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5683_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5683r_chip_info = {
+	.channels = ad5683r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 1,
+	.regmap_type = AD5683_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5683r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5337r_chip_info = {
+	.channels = ad5337r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 2,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5337r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5338r_chip_info = {
+	.channels = ad5338r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 2,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5338r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5684_chip_info = {
+	.channels = ad5684r_channels,
+	.num_channels = 4,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5684_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5684r_chip_info = {
+	.channels = ad5684r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 4,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5684r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5685r_chip_info = {
+	.channels = ad5685r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 4,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5685r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5686_chip_info = {
+	.channels = ad5686r_channels,
+	.num_channels = 4,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5686_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5686r_chip_info = {
+	.channels = ad5686r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 4,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5686r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5672r_chip_info = {
+	.channels = ad5672r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 8,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5672r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5676_chip_info = {
+	.channels = ad5676r_channels,
+	.num_channels = 8,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5676_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5676r_chip_info = {
+	.channels = ad5676r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 8,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5676r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5674r_chip_info = {
+	.channels = ad5674r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 16,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5674r_chip_info, "IIO_AD5686");
+
+const struct ad5686_chip_info ad5679r_chip_info = {
+	.channels = ad5679r_channels,
+	.int_vref_mv = 2500,
+	.num_channels = 16,
+	.regmap_type = AD5686_REGMAP,
+};
+EXPORT_SYMBOL_NS_GPL(ad5679r_chip_info, "IIO_AD5686");
 
 int ad5686_probe(struct device *dev,
-		 enum ad5686_supported_device_ids chip_type,
+		 const struct ad5686_chip_info *chip_info,
 		 const char *name, ad5686_write_func write,
 		 ad5686_read_func read)
 {
@@ -488,8 +455,7 @@ int ad5686_probe(struct device *dev,
 	st->dev = dev;
 	st->write = write;
 	st->read = read;
-
-	st->chip_info = &ad5686_chip_info_tbl[chip_type];
+	st->chip_info = chip_info;
 
 	ret = devm_regulator_get_enable_read_voltage(dev, "vcc");
 	if (ret < 0 && ret != -ENODEV)
diff --git a/drivers/iio/dac/ad5686.h b/drivers/iio/dac/ad5686.h
index af15994c01ad..caadc7403da1 100644
--- a/drivers/iio/dac/ad5686.h
+++ b/drivers/iio/dac/ad5686.h
@@ -47,42 +47,6 @@
 #define AD5683_REF_BIT_MSK			BIT(12)
 #define AD5686_REF_BIT_MSK			BIT(0)
 
-/**
- * ad5686_supported_device_ids:
- */
-enum ad5686_supported_device_ids {
-	ID_AD5310R,
-	ID_AD5311R,
-	ID_AD5337R,
-	ID_AD5338R,
-	ID_AD5671R,
-	ID_AD5672R,
-	ID_AD5673R,
-	ID_AD5674R,
-	ID_AD5675R,
-	ID_AD5676,
-	ID_AD5676R,
-	ID_AD5677R,
-	ID_AD5679R,
-	ID_AD5681R,
-	ID_AD5682R,
-	ID_AD5683,
-	ID_AD5683R,
-	ID_AD5684,
-	ID_AD5684R,
-	ID_AD5685R,
-	ID_AD5686,
-	ID_AD5686R,
-	ID_AD5691R,
-	ID_AD5692R,
-	ID_AD5693,
-	ID_AD5693R,
-	ID_AD5694,
-	ID_AD5694R,
-	ID_AD5695R,
-	ID_AD5696,
-	ID_AD5696R,
-};
 
 enum ad5686_regmap_type {
 	AD5310_REGMAP,
@@ -112,6 +76,34 @@ struct ad5686_chip_info {
 	enum ad5686_regmap_type		regmap_type;
 };
 
+/* single-channel instances */
+extern const struct ad5686_chip_info ad5310r_chip_info;
+extern const struct ad5686_chip_info ad5311r_chip_info;
+extern const struct ad5686_chip_info ad5681r_chip_info;
+extern const struct ad5686_chip_info ad5682r_chip_info;
+extern const struct ad5686_chip_info ad5683_chip_info;
+extern const struct ad5686_chip_info ad5683r_chip_info;
+
+/* dual-channel instances */
+extern const struct ad5686_chip_info ad5337r_chip_info;
+extern const struct ad5686_chip_info ad5338r_chip_info;
+
+/* quad-channel instances */
+extern const struct ad5686_chip_info ad5684_chip_info;
+extern const struct ad5686_chip_info ad5684r_chip_info;
+extern const struct ad5686_chip_info ad5685r_chip_info;
+extern const struct ad5686_chip_info ad5686_chip_info;
+extern const struct ad5686_chip_info ad5686r_chip_info;
+
+/* 8-channel instances */
+extern const struct ad5686_chip_info ad5672r_chip_info;
+extern const struct ad5686_chip_info ad5676_chip_info;
+extern const struct ad5686_chip_info ad5676r_chip_info;
+
+/* 16-channel instances */
+extern const struct ad5686_chip_info ad5674r_chip_info;
+extern const struct ad5686_chip_info ad5679r_chip_info;
+
 /**
  * struct ad5686_state - driver instance specific data
  * @spi:		spi_device
@@ -149,7 +141,7 @@ struct ad5686_state {
 
 
 int ad5686_probe(struct device *dev,
-		 enum ad5686_supported_device_ids chip_type,
+		 const struct ad5686_chip_info *chip_info,
 		 const char *name, ad5686_write_func write,
 		 ad5686_read_func read);
 
diff --git a/drivers/iio/dac/ad5696-i2c.c b/drivers/iio/dac/ad5696-i2c.c
index 20f04b74d831..c1f3cebabaf8 100644
--- a/drivers/iio/dac/ad5696-i2c.c
+++ b/drivers/iio/dac/ad5696-i2c.c
@@ -64,47 +64,46 @@ static int ad5686_i2c_write(struct ad5686_state *st,
 
 static int ad5686_i2c_probe(struct i2c_client *i2c)
 {
-	const struct i2c_device_id *id = i2c_client_get_device_id(i2c);
-	return ad5686_probe(&i2c->dev, id->driver_data, id->name,
-			    ad5686_i2c_write, ad5686_i2c_read);
+	return ad5686_probe(&i2c->dev, i2c_get_match_data(i2c),
+			    i2c->name, ad5686_i2c_write, ad5686_i2c_read);
 }
 
 static const struct i2c_device_id ad5686_i2c_id[] = {
-	{"ad5311r", ID_AD5311R},
-	{"ad5337r", ID_AD5337R},
-	{"ad5338r", ID_AD5338R},
-	{"ad5671r", ID_AD5671R},
-	{"ad5673r", ID_AD5673R},
-	{"ad5675r", ID_AD5675R},
-	{"ad5677r", ID_AD5677R},
-	{"ad5691r", ID_AD5691R},
-	{"ad5692r", ID_AD5692R},
-	{"ad5693", ID_AD5693},
-	{"ad5693r", ID_AD5693R},
-	{"ad5694", ID_AD5694},
-	{"ad5694r", ID_AD5694R},
-	{"ad5695r", ID_AD5695R},
-	{"ad5696", ID_AD5696},
-	{"ad5696r", ID_AD5696R},
+	{ .name = "ad5311r", .driver_data = (kernel_ulong_t)&ad5311r_chip_info },
+	{ .name = "ad5337r", .driver_data = (kernel_ulong_t)&ad5337r_chip_info },
+	{ .name = "ad5338r", .driver_data = (kernel_ulong_t)&ad5338r_chip_info },
+	{ .name = "ad5671r", .driver_data = (kernel_ulong_t)&ad5672r_chip_info },
+	{ .name = "ad5673r", .driver_data = (kernel_ulong_t)&ad5674r_chip_info },
+	{ .name = "ad5675r", .driver_data = (kernel_ulong_t)&ad5676r_chip_info },
+	{ .name = "ad5677r", .driver_data = (kernel_ulong_t)&ad5679r_chip_info },
+	{ .name = "ad5691r", .driver_data = (kernel_ulong_t)&ad5681r_chip_info },
+	{ .name = "ad5692r", .driver_data = (kernel_ulong_t)&ad5682r_chip_info },
+	{ .name = "ad5693",  .driver_data = (kernel_ulong_t)&ad5683_chip_info },
+	{ .name = "ad5693r", .driver_data = (kernel_ulong_t)&ad5683r_chip_info },
+	{ .name = "ad5694",  .driver_data = (kernel_ulong_t)&ad5684_chip_info },
+	{ .name = "ad5694r", .driver_data = (kernel_ulong_t)&ad5684r_chip_info },
+	{ .name = "ad5695r", .driver_data = (kernel_ulong_t)&ad5685r_chip_info },
+	{ .name = "ad5696",  .driver_data = (kernel_ulong_t)&ad5686_chip_info },
+	{ .name = "ad5696r", .driver_data = (kernel_ulong_t)&ad5686r_chip_info },
 	{ }
 };
 MODULE_DEVICE_TABLE(i2c, ad5686_i2c_id);
 
 static const struct of_device_id ad5686_of_match[] = {
-	{ .compatible = "adi,ad5311r" },
-	{ .compatible = "adi,ad5337r" },
-	{ .compatible = "adi,ad5338r" },
-	{ .compatible = "adi,ad5671r" },
-	{ .compatible = "adi,ad5675r" },
-	{ .compatible = "adi,ad5691r" },
-	{ .compatible = "adi,ad5692r" },
-	{ .compatible = "adi,ad5693" },
-	{ .compatible = "adi,ad5693r" },
-	{ .compatible = "adi,ad5694" },
-	{ .compatible = "adi,ad5694r" },
-	{ .compatible = "adi,ad5695r" },
-	{ .compatible = "adi,ad5696" },
-	{ .compatible = "adi,ad5696r" },
+	{ .compatible = "adi,ad5311r", .data = &ad5311r_chip_info },
+	{ .compatible = "adi,ad5337r", .data = &ad5337r_chip_info },
+	{ .compatible = "adi,ad5338r", .data = &ad5338r_chip_info },
+	{ .compatible = "adi,ad5671r", .data = &ad5672r_chip_info },
+	{ .compatible = "adi,ad5675r", .data = &ad5676r_chip_info },
+	{ .compatible = "adi,ad5691r", .data = &ad5681r_chip_info },
+	{ .compatible = "adi,ad5692r", .data = &ad5682r_chip_info },
+	{ .compatible = "adi,ad5693",  .data = &ad5683_chip_info },
+	{ .compatible = "adi,ad5693r", .data = &ad5683r_chip_info },
+	{ .compatible = "adi,ad5694",  .data = &ad5684_chip_info },
+	{ .compatible = "adi,ad5694r", .data = &ad5684r_chip_info },
+	{ .compatible = "adi,ad5695r", .data = &ad5685r_chip_info },
+	{ .compatible = "adi,ad5696",  .data = &ad5686_chip_info },
+	{ .compatible = "adi,ad5696r", .data = &ad5686r_chip_info },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, ad5686_of_match);

-- 
2.43.0

