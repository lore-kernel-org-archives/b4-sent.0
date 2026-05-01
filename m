From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 01 May 2026 10:15:05 +0100
Subject: [PATCH v5 12/12] iio: dac: ad5686: create bus ops struct
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260501-ad5686-fixes-v5-12-0b2f45488418@analog.com>
References: <20260501-ad5686-fixes-v5-0-0b2f45488418@analog.com>
In-Reply-To: <20260501-ad5686-fixes-v5-0-0b2f45488418@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777626920; l=7630;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=R3ZcXIDA8Ei+0XBUOZtKsoDqu9PKMLX4OLhx5MnXzf0=;
 b=pNzgcwNp6mfiNpncULm36VVKS69kFTxBX/7rHcHR1QHxsF2V8jXQUyPCCN9T3yMxnN+gQ1T6K
 R49neFVqGSvAimE0e1uA8M4Mv1T8xWagrtarYcyM/EvenzgvjZ89+xu
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Create struct with bus operations, which will be used to extend bus
implementation features. Auxiliary functions ad5686_write() and
ad5686_read() are created and ad5686_probe() now receives an ops struct
pointer rather than individual read and write functions.

Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686-spi.c |  7 ++++++-
 drivers/iio/dac/ad5686.c     | 32 ++++++++++++++------------------
 drivers/iio/dac/ad5686.h     | 29 +++++++++++++++++++++--------
 drivers/iio/dac/ad5696-i2c.c |  7 ++++++-
 4 files changed, 47 insertions(+), 28 deletions(-)

diff --git a/drivers/iio/dac/ad5686-spi.c b/drivers/iio/dac/ad5686-spi.c
index 9493511d9e7f..7409624b954b 100644
--- a/drivers/iio/dac/ad5686-spi.c
+++ b/drivers/iio/dac/ad5686-spi.c
@@ -92,10 +92,15 @@ static int ad5686_spi_read(struct ad5686_state *st, u8 addr)
 	return be32_to_cpu(st->data[2].d32);
 }
 
+static const struct ad5686_bus_ops ad5686_spi_ops = {
+	.write = ad5686_spi_write,
+	.read = ad5686_spi_read,
+};
+
 static int ad5686_spi_probe(struct spi_device *spi)
 {
 	return ad5686_probe(&spi->dev, spi_get_device_match_data(spi),
-			    spi->modalias, ad5686_spi_write, ad5686_spi_read);
+			    spi->modalias, &ad5686_spi_ops);
 }
 
 static const struct spi_device_id ad5686_spi_id[] = {
diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index b94efa6de16e..8ebd1d4c73d4 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -30,18 +30,18 @@ static int ad5310_control_sync(struct ad5686_state *st)
 {
 	unsigned int pd_val = st->pwr_down_mask & st->pwr_down_mode;
 
-	return st->write(st, AD5686_CMD_CONTROL_REG, 0,
-			 FIELD_PREP(AD5310_PD_MSK, pd_val & AD5686_PD_MSK) |
-			 FIELD_PREP(AD5310_REF_BIT_MSK, st->use_internal_vref ? 0 : 1));
+	return ad5686_write(st, AD5686_CMD_CONTROL_REG, 0,
+			    FIELD_PREP(AD5310_PD_MSK, pd_val & AD5686_PD_MSK) |
+			    FIELD_PREP(AD5310_REF_BIT_MSK, st->use_internal_vref ? 0 : 1));
 }
 
 static int ad5683_control_sync(struct ad5686_state *st)
 {
 	unsigned int pd_val = st->pwr_down_mask & st->pwr_down_mode;
 
-	return st->write(st, AD5686_CMD_CONTROL_REG, 0,
-			 FIELD_PREP(AD5683_PD_MSK, pd_val & AD5686_PD_MSK) |
-			 FIELD_PREP(AD5683_REF_BIT_MSK, st->use_internal_vref ? 0 : 1));
+	return ad5686_write(st, AD5686_CMD_CONTROL_REG, 0,
+			    FIELD_PREP(AD5683_PD_MSK, pd_val & AD5686_PD_MSK) |
+			    FIELD_PREP(AD5683_REF_BIT_MSK, st->use_internal_vref ? 0 : 1));
 }
 
 static inline unsigned int ad5686_pd_mask_shift(const struct iio_chan_spec *chan)
@@ -148,7 +148,7 @@ static ssize_t ad5686_write_dac_powerdown(struct iio_dev *indio_dev,
 			address = 0x0;
 			val = lower_16_bits(val);
 		}
-		ret = st->write(st, AD5686_CMD_POWERDOWN_DAC, address, val);
+		ret = ad5686_write(st, AD5686_CMD_POWERDOWN_DAC, address, val);
 		if (ret)
 			return ret;
 		break;
@@ -171,7 +171,7 @@ static int ad5686_read_raw(struct iio_dev *indio_dev,
 	switch (m) {
 	case IIO_CHAN_INFO_RAW:
 		mutex_lock(&st->lock);
-		ret = st->read(st, chan->address);
+		ret = ad5686_read(st, chan->address);
 		mutex_unlock(&st->lock);
 		if (ret < 0)
 			return ret;
@@ -201,10 +201,8 @@ static int ad5686_write_raw(struct iio_dev *indio_dev,
 			return -EINVAL;
 
 		mutex_lock(&st->lock);
-		ret = st->write(st,
-				AD5686_CMD_WRITE_INPUT_N_UPDATE_N,
-				chan->address,
-				val << chan->scan_type.shift);
+		ret = ad5686_write(st, AD5686_CMD_WRITE_INPUT_N_UPDATE_N,
+				   chan->address, val << chan->scan_type.shift);
 		mutex_unlock(&st->lock);
 		break;
 	default:
@@ -465,8 +463,7 @@ EXPORT_SYMBOL_NS_GPL(ad5679r_chip_info, "IIO_AD5686");
 
 int ad5686_probe(struct device *dev,
 		 const struct ad5686_chip_info *chip_info,
-		 const char *name, ad5686_write_func write,
-		 ad5686_read_func read)
+		 const char *name, const struct ad5686_bus_ops *ops)
 {
 	struct ad5686_state *st;
 	struct iio_dev *indio_dev;
@@ -479,8 +476,7 @@ int ad5686_probe(struct device *dev,
 	st = iio_priv(indio_dev);
 
 	st->dev = dev;
-	st->write = write;
-	st->read = read;
+	st->ops = ops;
 	st->chip_info = chip_info;
 
 	ret = devm_regulator_get_enable_read_voltage(dev, "vcc");
@@ -524,8 +520,8 @@ int ad5686_probe(struct device *dev,
 			return ret;
 		break;
 	case AD5686_REGMAP:
-		ret = st->write(st, AD5686_CMD_INTERNAL_REFER_SETUP, 0,
-				st->use_internal_vref ? 0 : AD5686_REF_BIT_MSK);
+		ret = ad5686_write(st, AD5686_CMD_INTERNAL_REFER_SETUP, 0,
+				   st->use_internal_vref ? 0 : AD5686_REF_BIT_MSK);
 		if (ret)
 			return ret;
 		break;
diff --git a/drivers/iio/dac/ad5686.h b/drivers/iio/dac/ad5686.h
index 4c38dd43d4bb..51fb5a8cb756 100644
--- a/drivers/iio/dac/ad5686.h
+++ b/drivers/iio/dac/ad5686.h
@@ -64,10 +64,15 @@ enum ad5686_regmap_type {
 
 struct ad5686_state;
 
-typedef int (*ad5686_write_func)(struct ad5686_state *st,
-				 u8 cmd, u8 addr, u16 val);
-
-typedef int (*ad5686_read_func)(struct ad5686_state *st, u8 addr);
+/**
+ * struct ad5686_bus_ops - bus specific read/write operations
+ * @read: read a register value at the given address
+ * @write: write a command, address and value to the device
+ */
+struct ad5686_bus_ops {
+	int (*read)(struct ad5686_state *st, u8 addr);
+	int (*write)(struct ad5686_state *st, u8 cmd, u8 addr, u16 val);
+};
 
 /**
  * struct ad5686_chip_info - chip specific information
@@ -115,6 +120,7 @@ extern const struct ad5686_chip_info ad5679r_chip_info;
  * struct ad5686_state - driver instance specific data
  * @dev:		device instance
  * @chip_info:		chip model specific constants, available modes etc
+ * @ops:		bus specific operations
  * @vref_mv:		actual reference voltage used
  * @pwr_down_mask:	power down mask
  * @pwr_down_mode:	current power down mode
@@ -126,11 +132,10 @@ extern const struct ad5686_chip_info ad5679r_chip_info;
 struct ad5686_state {
 	struct device			*dev;
 	const struct ad5686_chip_info	*chip_info;
+	const struct ad5686_bus_ops	*ops;
 	unsigned short			vref_mv;
 	unsigned int			pwr_down_mask;
 	unsigned int			pwr_down_mode;
-	ad5686_write_func		write;
-	ad5686_read_func		read;
 	bool				use_internal_vref;
 	struct mutex			lock;
 
@@ -149,8 +154,16 @@ struct ad5686_state {
 
 int ad5686_probe(struct device *dev,
 		 const struct ad5686_chip_info *chip_info,
-		 const char *name, ad5686_write_func write,
-		 ad5686_read_func read);
+		 const char *name, const struct ad5686_bus_ops *ops);
 
+static inline int ad5686_write(struct ad5686_state *st, u8 cmd, u8 addr, u16 val)
+{
+	return st->ops->write(st, cmd, addr, val);
+}
+
+static inline int ad5686_read(struct ad5686_state *st, u8 addr)
+{
+	return st->ops->read(st, addr);
+}
 
 #endif /* __DRIVERS_IIO_DAC_AD5686_H__ */
diff --git a/drivers/iio/dac/ad5696-i2c.c b/drivers/iio/dac/ad5696-i2c.c
index e15b01d0b768..6250c227293c 100644
--- a/drivers/iio/dac/ad5696-i2c.c
+++ b/drivers/iio/dac/ad5696-i2c.c
@@ -62,10 +62,15 @@ static int ad5686_i2c_write(struct ad5686_state *st,
 	return (ret != 3) ? -EIO : 0;
 }
 
+static const struct ad5686_bus_ops ad5686_i2c_ops = {
+	.write = ad5686_i2c_write,
+	.read = ad5686_i2c_read,
+};
+
 static int ad5686_i2c_probe(struct i2c_client *i2c)
 {
 	return ad5686_probe(&i2c->dev, i2c_get_match_data(i2c),
-			    i2c->name, ad5686_i2c_write, ad5686_i2c_read);
+			    i2c->name, &ad5686_i2c_ops);
 }
 
 static const struct i2c_device_id ad5686_i2c_id[] = {

-- 
2.43.0

