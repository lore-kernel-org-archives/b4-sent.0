From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sun, 05 Jul 2026 12:38:58 +0100
Subject: [PATCH v6 3/6] iio: dac: ad5686: implement new sync() op for the
 spi bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-ad5686-new-features-v6-3-269594c7aae5@analog.com>
References: <20260705-ad5686-new-features-v6-0-269594c7aae5@analog.com>
In-Reply-To: <20260705-ad5686-new-features-v6-0-269594c7aae5@analog.com>
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783251560; l=9034;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=PY2fqEcgvTnH2CIIhHv1P/7YTKeX0yKlY6jFvNHEGm0=;
 b=eM2a4u1Ytx3C3kF+ZtNMeoumEeZvGTXMTjU8LKjTkXtqjI/P3dUBkhDRLYtOqZSNAlPwV1SHe
 nA4WqAon0xFB/kCXEe1mWvoe3sKGkHd+fxOJyWJpE9aggkt+ObE/5i1
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use of local SPI bus data to manage a collection of SPI transfers and
flush them to the SPI platform driver with the sync() operation. This
allows for faster handling of multiple channel DAC writes, avoiding kernel
overhead per spi_sync() call, which will be helpful when enabling
triggered buffer support.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686-spi.c | 129 ++++++++++++++++++++++++++++++++-----------
 drivers/iio/dac/ad5686.c     |   4 +-
 drivers/iio/dac/ad5686.h     |   8 ++-
 drivers/iio/dac/ad5696-i2c.c |   2 +-
 4 files changed, 108 insertions(+), 35 deletions(-)

diff --git a/drivers/iio/dac/ad5686-spi.c b/drivers/iio/dac/ad5686-spi.c
index d3b64b4361d5..ae74a17ba48e 100644
--- a/drivers/iio/dac/ad5686-spi.c
+++ b/drivers/iio/dac/ad5686-spi.c
@@ -13,59 +13,95 @@
 #include <linux/errno.h>
 #include <linux/mod_devicetable.h>
 #include <linux/module.h>
+#include <linux/overflow.h>
 #include <linux/spi/spi.h>
 
 #include <asm/byteorder.h>
 
 #include "ad5686.h"
 
+/**
+ * struct ad5686_spi_data - SPI bus specific data
+ * @msg: SPI message used for transfers
+ * @size: number of transfers currently in the message
+ * @capacity: maximum number of transfers that can be added to the message
+ * @xfers: array of SPI transfers, allocated with the provided capacity
+ */
+struct ad5686_spi_data {
+	struct spi_message msg;
+	unsigned int size;
+	unsigned int capacity;
+	struct spi_transfer xfers[] __counted_by(capacity);
+};
+
 static int ad5686_spi_write(struct ad5686_state *st,
 			    u8 cmd, u8 addr, u16 val)
 {
-	struct spi_device *spi = to_spi_device(st->dev);
-	u8 tx_len, *buf;
+	struct ad5686_spi_data *bus_data = st->bus_data;
+	struct spi_transfer *xfer;
 
+	if (bus_data->size >= bus_data->capacity)
+		return -E2BIG;
+
+	if (bus_data->size)
+		bus_data->xfers[bus_data->size - 1].cs_change = 1;
+	else
+		spi_message_init(&bus_data->msg);
+
+	xfer = &bus_data->xfers[bus_data->size];
 	switch (st->chip_info->regmap_type) {
 	case AD5310_REGMAP:
-		st->data[0].d16 = cpu_to_be16(FIELD_PREP(AD5310_CMD_MSK, cmd) |
-					      FIELD_PREP(AD5310_DATA_MSK, val));
-		buf = &st->data[0].d8[0];
-		tx_len = 2;
+		st->data[bus_data->size].d16 =
+			cpu_to_be16(FIELD_PREP(AD5310_CMD_MSK, cmd) |
+				    FIELD_PREP(AD5310_DATA_MSK, val));
+		*xfer = (struct spi_transfer) {
+			.tx_buf = &st->data[bus_data->size].d16,
+			.len = sizeof(st->data[bus_data->size].d16),
+		};
 		break;
 	case AD5683_REGMAP:
-		st->data[0].d32 = cpu_to_be32(FIELD_PREP(AD5686_CMD_MSK, cmd) |
-					      FIELD_PREP(AD5683_DATA_MSK, val));
-		buf = &st->data[0].d8[1];
-		tx_len = 3;
+		st->data[bus_data->size].d32 =
+			cpu_to_be32(FIELD_PREP(AD5686_CMD_MSK, cmd) |
+				    FIELD_PREP(AD5683_DATA_MSK, val));
+		*xfer = (struct spi_transfer) {
+			.tx_buf = &st->data[bus_data->size].d8[1],
+			.len = sizeof(st->data[bus_data->size].d8) - 1,
+		};
 		break;
 	case AD5686_REGMAP:
-		st->data[0].d32 = cpu_to_be32(FIELD_PREP(AD5686_CMD_MSK, cmd) |
-					      FIELD_PREP(AD5686_ADDR_MSK, addr) |
-					      FIELD_PREP(AD5686_DATA_MSK, val));
-		buf = &st->data[0].d8[1];
-		tx_len = 3;
+		st->data[bus_data->size].d32 =
+			cpu_to_be32(FIELD_PREP(AD5686_CMD_MSK, cmd) |
+				    FIELD_PREP(AD5686_ADDR_MSK, addr) |
+				    FIELD_PREP(AD5686_DATA_MSK, val));
+		*xfer = (struct spi_transfer) {
+			.tx_buf = &st->data[bus_data->size].d8[1],
+			.len = sizeof(st->data[bus_data->size].d8) - 1,
+		};
 		break;
 	default:
 		return -EINVAL;
 	}
 
-	return spi_write(spi, buf, tx_len);
+	spi_message_add_tail(xfer, &bus_data->msg);
+	bus_data->size++;
+
+	return 0;
+}
+
+static int ad5686_spi_sync(struct ad5686_state *st)
+{
+	struct spi_device *spi = to_spi_device(st->dev);
+	struct ad5686_spi_data *bus_data = st->bus_data;
+
+	bus_data->size = 0; /* always reset, even on sync failure */
+	return spi_sync(spi, &bus_data->msg);
 }
 
 static int ad5686_spi_read(struct ad5686_state *st, u8 addr)
 {
-	struct spi_transfer t[] = {
-		{
-			.tx_buf = &st->data[0].d8[1],
-			.len = 3,
-			.cs_change = 1,
-		}, {
-			.tx_buf = &st->data[1].d8[1],
-			.rx_buf = &st->data[2].d8[1],
-			.len = 3,
-		},
-	};
 	struct spi_device *spi = to_spi_device(st->dev);
+	struct ad5686_spi_data *bus_data = st->bus_data;
+	struct spi_transfer *xfer = &bus_data->xfers[0];
 	u8 cmd = 0;
 	int ret;
 
@@ -86,8 +122,21 @@ static int ad5686_spi_read(struct ad5686_state *st, u8 addr)
 				      FIELD_PREP(AD5686_ADDR_MSK, addr));
 	st->data[1].d32 = cpu_to_be32(FIELD_PREP(AD5686_CMD_MSK, AD5686_CMD_NOOP));
 
-	ret = spi_sync_transfer(spi, t, ARRAY_SIZE(t));
-	if (ret < 0)
+	xfer[0] = (struct spi_transfer) {
+		.tx_buf = &st->data[0].d8[1],
+		.len = sizeof(st->data[0].d8) - 1,
+		.cs_change = 1,
+	};
+	xfer[1] = (struct spi_transfer) {
+		.tx_buf = &st->data[1].d8[1],
+		.rx_buf = &st->data[2].d8[1],
+		.len = sizeof(st->data[1].d8) - 1,
+	};
+
+	spi_message_init_with_transfers(&bus_data->msg, xfer, 2);
+
+	ret = spi_sync(spi, &bus_data->msg);
+	if (ret)
 		return ret;
 
 	return be32_to_cpu(st->data[2].d32);
@@ -96,12 +145,30 @@ static int ad5686_spi_read(struct ad5686_state *st, u8 addr)
 static const struct ad5686_bus_ops ad5686_spi_ops = {
 	.write = ad5686_spi_write,
 	.read = ad5686_spi_read,
+	.sync = ad5686_spi_sync,
 };
 
 static int ad5686_spi_probe(struct spi_device *spi)
 {
-	return ad5686_probe(&spi->dev, spi_get_device_match_data(spi),
-			    spi->modalias, &ad5686_spi_ops);
+	const struct ad5686_chip_info *info;
+	struct ad5686_spi_data *bus_data;
+	struct device *dev = &spi->dev;
+	unsigned int capacity;
+
+	info = spi_get_device_match_data(spi);
+	if (!info)
+		return -ENODEV;
+
+	/* read operation requires at least 2 transfers */
+	capacity = max(info->num_channels, 2);
+	bus_data = devm_kzalloc(dev, struct_size(bus_data, xfers, capacity),
+				GFP_KERNEL);
+	if (!bus_data)
+		return -ENOMEM;
+
+	bus_data->capacity = capacity;
+
+	return ad5686_probe(dev, info, spi->modalias, &ad5686_spi_ops, bus_data);
 }
 
 static const struct spi_device_id ad5686_spi_id[] = {
diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 713fe71ad1e7..75dd7921c67b 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -472,7 +472,8 @@ EXPORT_SYMBOL_NS_GPL(ad5679r_chip_info, "IIO_AD5686");
 
 int ad5686_probe(struct device *dev,
 		 const struct ad5686_chip_info *chip_info,
-		 const char *name, const struct ad5686_bus_ops *ops)
+		 const char *name, const struct ad5686_bus_ops *ops,
+		 void *bus_data)
 {
 	struct reset_control *rstc;
 	struct ad5686_state *st;
@@ -487,6 +488,7 @@ int ad5686_probe(struct device *dev,
 
 	st->dev = dev;
 	st->ops = ops;
+	st->bus_data = bus_data;
 	st->chip_info = chip_info;
 
 	rstc = devm_reset_control_get_optional_exclusive(dev, NULL);
diff --git a/drivers/iio/dac/ad5686.h b/drivers/iio/dac/ad5686.h
index 56d37191ab37..b1fd1abfe129 100644
--- a/drivers/iio/dac/ad5686.h
+++ b/drivers/iio/dac/ad5686.h
@@ -16,6 +16,7 @@
 
 #define AD5686_ADDR_DAC(chan)			(0x1 << (chan))
 #define AD5686_ADDR_ALL_DAC			0xF
+#define AD5686_MAX_CHANNELS			16
 
 #define AD5686_CMD_NOOP				0x0
 #define AD5686_CMD_WRITE_INPUT_N		0x1
@@ -129,6 +130,7 @@ extern const struct ad5686_chip_info ad5679r_chip_info;
  * @use_internal_vref:	set to true if the internal reference voltage is used
  * @lock:		lock to protect access to state fields, which includes
  *			the data buffer during regmap ops
+ * @bus_data:		bus specific data
  * @data:		transfer buffers
  */
 struct ad5686_state {
@@ -141,6 +143,7 @@ struct ad5686_state {
 	unsigned int			pwr_down_mode;
 	bool				use_internal_vref;
 	struct mutex			lock;
+	void				*bus_data;
 
 	/*
 	 * DMA (thus cache coherency maintenance) may require the
@@ -151,13 +154,14 @@ struct ad5686_state {
 		__be32 d32;
 		__be16 d16;
 		u8 d8[4];
-	} data[3] __aligned(IIO_DMA_MINALIGN);
+	} data[AD5686_MAX_CHANNELS] __aligned(IIO_DMA_MINALIGN);
 };
 
 
 int ad5686_probe(struct device *dev,
 		 const struct ad5686_chip_info *chip_info,
-		 const char *name, const struct ad5686_bus_ops *ops);
+		 const char *name, const struct ad5686_bus_ops *ops,
+		 void *bus_data);
 
 static inline int ad5686_write(struct ad5686_state *st, u8 cmd, u8 addr, u16 val)
 {
diff --git a/drivers/iio/dac/ad5696-i2c.c b/drivers/iio/dac/ad5696-i2c.c
index bd8666a02b47..3f16127ad495 100644
--- a/drivers/iio/dac/ad5696-i2c.c
+++ b/drivers/iio/dac/ad5696-i2c.c
@@ -71,7 +71,7 @@ static const struct ad5686_bus_ops ad5686_i2c_ops = {
 static int ad5686_i2c_probe(struct i2c_client *i2c)
 {
 	return ad5686_probe(&i2c->dev, i2c_get_match_data(i2c),
-			    i2c->name, &ad5686_i2c_ops);
+			    i2c->name, &ad5686_i2c_ops, NULL);
 }
 
 static const struct i2c_device_id ad5686_i2c_id[] = {

-- 
2.43.0

