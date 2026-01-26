From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 26 Jan 2026 13:51:05 +0000
Subject: [PATCH v2 4/6] iio: amplifiers: ad8366: add device tree support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260126-iio-ad8366-update-v2-4-c9a4d31aeb01@analog.com>
References: <20260126-iio-ad8366-update-v2-0-c9a4d31aeb01@analog.com>
In-Reply-To: <20260126-iio-ad8366-update-v2-0-c9a4d31aeb01@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769436111; l=10446;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=BlhuFj3wy+WCVV4cdkTh82AUdgR5J3RfyGbE+fBPHkI=;
 b=g2v3Zi/49Ave97BBzPEONFJMzj6pe/w6jUZYWJMDIBQeHJQsHjP2JCBdL2ZH6vTdialugsjnU
 YHj0x5NtKx+CDUK9294AsBS6M5c0vqq/2DNThq/rYCjB/I3LEsCYql4
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device-tree support by dropping the enum ID in favor of extended
chip info table, containing:
- gain_step, indicating with sign the start of the code range;
- num_channels, to indicate the number IIO channels;
- pack_code() function to describe how SPI buffer is populated;

With this, switch cases on the device type were dropped:
- probe() function adjusted accordingly;
- Simplified read_raw() and write_raw() callbacks;
- mutex_lock()/mutex_unlock() replaced for guard(mutex)() to allow
  moving to early returns;

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 259 +++++++++++++++++-----------------------
 1 file changed, 107 insertions(+), 152 deletions(-)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index 0f3fc79ebbf3..134188db2e15 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -11,6 +11,7 @@
  * Copyright 2012-2019 Analog Devices Inc.
  */
 
+#include <linux/cleanup.h>
 #include <linux/device.h>
 #include <linux/kernel.h>
 #include <linux/slab.h>
@@ -20,22 +21,20 @@
 #include <linux/gpio/consumer.h>
 #include <linux/err.h>
 #include <linux/module.h>
+#include <linux/mod_devicetable.h>
 #include <linux/bitrev.h>
 
 #include <linux/iio/iio.h>
 #include <linux/iio/sysfs.h>
 
-enum ad8366_type {
-	ID_AD8366,
-	ID_ADA4961,
-	ID_ADL5240,
-	ID_HMC792,
-	ID_HMC1119,
-};
+struct ad8366_state;
 
 struct ad8366_info {
 	int gain_min;
 	int gain_max;
+	int gain_step;
+	int num_channels;
+	size_t (*pack_code)(struct ad8366_state *st);
 };
 
 struct ad8366_state {
@@ -43,7 +42,6 @@ struct ad8366_state {
 	struct mutex            lock; /* protect sensor state */
 	struct gpio_desc	*reset_gpio;
 	unsigned char		ch[2];
-	enum ad8366_type	type;
 	const struct ad8366_info *info;
 	/*
 	 * DMA (thus cache coherency maintenance) may require the
@@ -52,108 +50,91 @@ struct ad8366_state {
 	unsigned char		data[2] __aligned(IIO_DMA_MINALIGN);
 };
 
-static const struct ad8366_info ad8366_infos[] = {
-	[ID_AD8366] = {
-		.gain_min = 4500,
-		.gain_max = 20500,
-	},
-	[ID_ADA4961] = {
-		.gain_min = -6000,
-		.gain_max = 15000,
-	},
-	[ID_ADL5240] = {
-		.gain_min = -11500,
-		.gain_max = 20000,
-	},
-	[ID_HMC792] = {
-		.gain_min = -15750,
-		.gain_max = 0,
-	},
-	[ID_HMC1119] = {
-		.gain_min = -31750,
-		.gain_max = 0,
-	},
+static size_t ad8366_pack_code(struct ad8366_state *st)
+{
+	u8 ch_a = bitrev8(st->ch[0] & 0x3F);
+	u8 ch_b = bitrev8(st->ch[1] & 0x3F);
+
+	st->data[0] = ch_b >> 4;
+	st->data[1] = (ch_b << 4) | (ch_a >> 2);
+	return 2;
+}
+
+static size_t simple_pack_code(struct ad8366_state *st)
+{
+	st->data[0] = st->ch[0];
+	return 1;
+}
+
+static const struct ad8366_info ad8366_chip_info = {
+	.gain_min = 4500,
+	.gain_max = 20500,
+	.gain_step = 253,
+	.num_channels = 2,
+	.pack_code = ad8366_pack_code,
 };
 
-static int ad8366_write(struct iio_dev *indio_dev,
-			unsigned char ch_a, unsigned char ch_b)
+static const struct ad8366_info ada4961_chip_info = {
+	.gain_min = -6000,
+	.gain_max = 15000,
+	.gain_step = -1000,
+	.num_channels = 1,
+	.pack_code = simple_pack_code,
+};
+
+static const struct ad8366_info adl5240_chip_info = {
+	.gain_min = -11500,
+	.gain_max = 20000,
+	.gain_step = 500,
+	.num_channels = 1,
+	.pack_code = simple_pack_code,
+};
+
+static const struct ad8366_info hmc792_chip_info = {
+	.gain_min = -15750,
+	.gain_max = 0,
+	.gain_step = 250,
+	.num_channels = 1,
+	.pack_code = simple_pack_code,
+};
+
+static const struct ad8366_info hmc1119_chip_info = {
+	.gain_min = -31750,
+	.gain_max = 0,
+	.gain_step = -250,
+	.num_channels = 1,
+	.pack_code = simple_pack_code,
+};
+
+static int ad8366_write_code(struct ad8366_state *st)
 {
-	struct ad8366_state *st = iio_priv(indio_dev);
-	int ret;
+	const struct ad8366_info *inf = st->info;
 
-	switch (st->type) {
-	case ID_AD8366:
-		ch_a = bitrev8(ch_a & 0x3F);
-		ch_b = bitrev8(ch_b & 0x3F);
-
-		st->data[0] = ch_b >> 4;
-		st->data[1] = (ch_b << 4) | (ch_a >> 2);
-		break;
-	case ID_ADA4961:
-		st->data[0] = ch_a & 0x1F;
-		break;
-	case ID_ADL5240:
-		st->data[0] = (ch_a & 0x3F);
-		break;
-	case ID_HMC792:
-	case ID_HMC1119:
-		st->data[0] = ch_a;
-		break;
-	}
-
-	ret = spi_write(st->spi, st->data, indio_dev->num_channels);
-	if (ret < 0)
-		dev_err(&indio_dev->dev, "write failed (%d)", ret);
-
-	return ret;
+	return spi_write(st->spi, st->data, inf->pack_code(st));
 }
 
 static int ad8366_read_raw(struct iio_dev *indio_dev,
 			   struct iio_chan_spec const *chan,
 			   int *val,
 			   int *val2,
-			   long m)
+			   long mask)
 {
 	struct ad8366_state *st = iio_priv(indio_dev);
-	int ret;
-	int code, gain = 0;
+	const struct ad8366_info *inf = st->info;
+	int gain = inf->gain_step > 0 ? inf->gain_min : inf->gain_max;
 
-	mutex_lock(&st->lock);
-	switch (m) {
+	guard(mutex)(&st->lock);
+
+	switch (mask) {
 	case IIO_CHAN_INFO_HARDWAREGAIN:
-		code = st->ch[chan->channel];
-
-		switch (st->type) {
-		case ID_AD8366:
-			gain = code * 253 + 4500;
-			break;
-		case ID_ADA4961:
-			gain = 15000 - code * 1000;
-			break;
-		case ID_ADL5240:
-			gain = 20000 - 31500 + code * 500;
-			break;
-		case ID_HMC792:
-			gain = -1 * code * 500;
-			break;
-		case ID_HMC1119:
-			gain = -1 * code * 250;
-			break;
-		}
-
-		/* Values in dB */
+		gain += inf->gain_step * st->ch[chan->channel];
 		*val = gain / 1000;
 		*val2 = (gain % 1000) * 1000;
-
-		ret = IIO_VAL_INT_PLUS_MICRO_DB;
-		break;
+		return IIO_VAL_INT_PLUS_MICRO_DB;
 	default:
-		ret = -EINVAL;
+		return -EINVAL;
 	}
-	mutex_unlock(&st->lock);
-
-	return ret;
-};
+}
 
 static int ad8366_write_raw(struct iio_dev *indio_dev,
 			    struct iio_chan_spec const *chan,
@@ -163,10 +144,8 @@ static int ad8366_write_raw(struct iio_dev *indio_dev,
 {
 	struct ad8366_state *st = iio_priv(indio_dev);
 	const struct ad8366_info *inf = st->info;
-	int code = 0, gain;
-	int ret;
+	int code, gain, gain_base;
 
-	/* Values in dB */
 	if (val < 0)
 		gain = (val * 1000) - (val2 / 1000);
 	else
@@ -175,36 +154,18 @@ static int ad8366_write_raw(struct iio_dev *indio_dev,
 	if (gain > inf->gain_max || gain < inf->gain_min)
 		return -EINVAL;
 
-	switch (st->type) {
-	case ID_AD8366:
-		code = (gain - 4500) / 253;
-		break;
-	case ID_ADA4961:
-		code = (15000 - gain) / 1000;
-		break;
-	case ID_ADL5240:
-		code = ((gain - 500 - 20000) / 500) & 0x3F;
-		break;
-	case ID_HMC792:
-		code = (abs(gain) / 500) & 0x3F;
-		break;
-	case ID_HMC1119:
-		code = (abs(gain) / 250) & 0x7F;
-		break;
-	}
+	gain_base = inf->gain_step > 0 ? inf->gain_min : inf->gain_max;
+	code = DIV_ROUND_CLOSEST(gain - gain_base, inf->gain_step);
+
+	guard(mutex)(&st->lock);
 
-	mutex_lock(&st->lock);
 	switch (mask) {
 	case IIO_CHAN_INFO_HARDWAREGAIN:
 		st->ch[chan->channel] = code;
-		ret = ad8366_write(indio_dev, st->ch[0], st->ch[1]);
-		break;
+		return ad8366_write_code(st);
 	default:
-		ret = -EINVAL;
+		return -EINVAL;
 	}
-	mutex_unlock(&st->lock);
-
-	return ret;
 }
 
 static int ad8366_write_raw_get_fmt(struct iio_dev *indio_dev,
@@ -238,10 +199,6 @@ static const struct iio_chan_spec ad8366_channels[] = {
 	AD8366_CHAN(1),
 };
 
-static const struct iio_chan_spec ada4961_channels[] = {
-	AD8366_CHAN(0),
-};
-
 static int ad8366_probe(struct spi_device *spi)
 {
 	struct device *dev = &spi->dev;
@@ -264,35 +221,22 @@ static int ad8366_probe(struct spi_device *spi)
 		return ret;
 
 	st->spi = spi;
-	st->type = spi_get_device_id(spi)->driver_data;
+	st->info = spi_get_device_match_data(spi);
+	if (!st->info)
+		return dev_err_probe(dev, -EINVAL, "Invalid device info\n");
 
-	switch (st->type) {
-	case ID_AD8366:
-		indio_dev->channels = ad8366_channels;
-		indio_dev->num_channels = ARRAY_SIZE(ad8366_channels);
-		break;
-	case ID_ADA4961:
-	case ID_ADL5240:
-	case ID_HMC792:
-	case ID_HMC1119:
-		st->reset_gpio = devm_gpiod_get_optional(dev, "reset", GPIOD_OUT_HIGH);
-		if (IS_ERR(st->reset_gpio))
-			return dev_err_probe(dev, PTR_ERR(st->reset_gpio),
-					     "Failed to get reset GPIO\n");
+	st->reset_gpio = devm_gpiod_get_optional(dev, "reset", GPIOD_OUT_HIGH);
+	if (IS_ERR(st->reset_gpio))
+		return dev_err_probe(dev, PTR_ERR(st->reset_gpio),
+				     "Failed to get reset GPIO\n");
 
-		indio_dev->channels = ada4961_channels;
-		indio_dev->num_channels = ARRAY_SIZE(ada4961_channels);
-		break;
-	default:
-		return dev_err_probe(dev, -EINVAL, "Invalid device ID\n");
-	}
-
-	st->info = &ad8366_infos[st->type];
 	indio_dev->name = spi_get_device_id(spi)->name;
 	indio_dev->info = &ad8366_info;
 	indio_dev->modes = INDIO_DIRECT_MODE;
+	indio_dev->channels = ad8366_channels;
+	indio_dev->num_channels = st->info->num_channels;
 
-	ret = ad8366_write(indio_dev, 0, 0);
+	ret = ad8366_write_code(st);
 	if (ret < 0)
 		return dev_err_probe(dev, ret, "failed to write initial gain\n");
 
@@ -300,18 +244,29 @@ static int ad8366_probe(struct spi_device *spi)
 }
 
 static const struct spi_device_id ad8366_id[] = {
-	{"ad8366",  ID_AD8366},
-	{"ada4961", ID_ADA4961},
-	{"adl5240", ID_ADL5240},
-	{"hmc792a", ID_HMC792},
-	{"hmc1119", ID_HMC1119},
+	{"ad8366", (kernel_ulong_t)&ad8366_chip_info},
+	{"ada4961", (kernel_ulong_t)&ada4961_chip_info},
+	{"adl5240", (kernel_ulong_t)&adl5240_chip_info},
+	{"hmc792a", (kernel_ulong_t)&hmc792_chip_info},
+	{"hmc1119", (kernel_ulong_t)&hmc1119_chip_info},
 	{ }
 };
 MODULE_DEVICE_TABLE(spi, ad8366_id);
 
+static const struct of_device_id ad8366_of_match[] = {
+	{ .compatible = "adi,ad8366", .data = &ad8366_chip_info },
+	{ .compatible = "adi,ada4961", .data = &ada4961_chip_info },
+	{ .compatible = "adi,adl5240", .data = &adl5240_chip_info },
+	{ .compatible = "adi,hmc792a", .data = &hmc792_chip_info },
+	{ .compatible = "adi,hmc1119", .data = &hmc1119_chip_info },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, ad8366_of_match);
+
 static struct spi_driver ad8366_driver = {
 	.driver = {
-		.name	= KBUILD_MODNAME,
+		.name		= KBUILD_MODNAME,
+		.of_match_table	= ad8366_of_match,
 	},
 	.probe		= ad8366_probe,
 	.id_table	= ad8366_id,

-- 
2.43.0

