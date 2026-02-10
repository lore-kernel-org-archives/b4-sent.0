From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 10 Feb 2026 19:42:08 +0000
Subject: [PATCH v4 08/11] iio: amplifiers: ad8366: prepare for device-tree
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260210-iio-ad8366-update-v4-8-15505f7b15b4@analog.com>
References: <20260210-iio-ad8366-update-v4-0-15505f7b15b4@analog.com>
In-Reply-To: <20260210-iio-ad8366-update-v4-0-15505f7b15b4@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770752535; l=7157;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Zdn1IjVL+LQBedLBJP4SxLg0QqdNykisF4eKilB9Xc4=;
 b=JrMfelEnl3N9RfcUtZKGo+WOxkU4yccNxAYuUHxU/1MuiyMyMc3HLkwfSx7RhM3fwVNVD6EYE
 WEFJ3ejZp/zBLy6U7UYQqhlQZgClhTC6DHdlWlCJf/L3ZglukZ1VUnb
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop switch case on the enum ID in favor of extended chip info table,
containing:
- gain_step, indicating with sign the start of the code range;
- num_channels, to indicate the number IIO channels;
- pack_code() function to describe how SPI buffer is populated;

Which allowed for a simplified read_raw() and write_raw() callbacks.
The probe() function was adjusted accordingly.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 139 +++++++++++++---------------------------
 1 file changed, 46 insertions(+), 93 deletions(-)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index 343f370eae65..1ae75643e89b 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -19,6 +19,7 @@
 #include <linux/regulator/consumer.h>
 #include <linux/reset.h>
 #include <linux/spi/spi.h>
+#include <linux/unaligned.h>
 
 #include <linux/iio/iio.h>
 
@@ -30,16 +31,20 @@ enum ad8366_type {
 	ID_HMC1119,
 };
 
+struct ad8366_state;
+
 struct ad8366_info {
 	int gain_min;
 	int gain_max;
+	int gain_step;
+	int num_channels;
+	size_t (*pack_code)(struct ad8366_state *st);
 };
 
 struct ad8366_state {
 	struct spi_device	*spi;
 	struct mutex            lock; /* protect sensor state */
 	unsigned char		ch[2];
-	enum ad8366_type	type;
 	const struct ad8366_info *info;
 	/*
 	 * DMA (thus cache coherency maintenance) may require the
@@ -48,60 +53,58 @@ struct ad8366_state {
 	unsigned char		data[2] __aligned(IIO_DMA_MINALIGN);
 };
 
+static size_t ad8366_pack_code(struct ad8366_state *st)
+{
+	u8 ch_a = bitrev8(st->ch[0]) >> 2;
+	u8 ch_b = bitrev8(st->ch[1]) >> 2;
+
+	put_unaligned_be16((ch_b << 6) | ch_a, &st->data[0]);
+	return sizeof(__be16);
+}
+
 static const struct ad8366_info ad8366_infos[] = {
 	[ID_AD8366] = {
 		.gain_min = 4500,
 		.gain_max = 20500,
+		.gain_step = 253,
+		.num_channels = 2,
+		.pack_code = ad8366_pack_code,
 	},
 	[ID_ADA4961] = {
 		.gain_min = -6000,
 		.gain_max = 15000,
+		.gain_step = -1000,
+		.num_channels = 1,
 	},
 	[ID_ADL5240] = {
 		.gain_min = -11500,
 		.gain_max = 20000,
+		.gain_step = 500,
+		.num_channels = 1,
 	},
 	[ID_HMC792] = {
 		.gain_min = -15750,
 		.gain_max = 0,
+		.gain_step = 250,
+		.num_channels = 1,
 	},
 	[ID_HMC1119] = {
 		.gain_min = -31750,
 		.gain_max = 0,
+		.gain_step = -250,
+		.num_channels = 1,
 	},
 };
 
-static int ad8366_write(struct iio_dev *indio_dev,
-			unsigned char ch_a, unsigned char ch_b)
+static int ad8366_write_code(struct ad8366_state *st)
 {
-	struct ad8366_state *st = iio_priv(indio_dev);
-	int ret;
+	const struct ad8366_info *inf = st->info;
 
-	switch (st->type) {
-	case ID_AD8366:
-		ch_a = bitrev8(ch_a & 0x3F);
-		ch_b = bitrev8(ch_b & 0x3F);
+	if (inf->pack_code)
+		spi_write(st->spi, st->data, inf->pack_code(st));
 
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
+	st->data[0] = st->ch[0];
+	return spi_write(st->spi, st->data, 1);
 }
 
 static int ad8366_read_raw(struct iio_dev *indio_dev,
@@ -111,6 +114,7 @@ static int ad8366_read_raw(struct iio_dev *indio_dev,
 			   long m)
 {
 	struct ad8366_state *st = iio_priv(indio_dev);
+	const struct ad8366_info *inf = st->info;
 	int ret;
 	int code, gain = 0;
 
@@ -118,25 +122,8 @@ static int ad8366_read_raw(struct iio_dev *indio_dev,
 	switch (m) {
 	case IIO_CHAN_INFO_HARDWAREGAIN:
 		code = st->ch[chan->channel];
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
+		gain = inf->gain_step > 0 ? inf->gain_min : inf->gain_max;
+		gain += inf->gain_step * code;
 		/* Values in dB */
 		*val = gain / 1000;
 		*val2 = (gain % 1000) * 1000;
@@ -171,29 +158,14 @@ static int ad8366_write_raw(struct iio_dev *indio_dev,
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
+	gain -= inf->gain_step > 0 ? inf->gain_min : inf->gain_max;
+	code = DIV_ROUND_CLOSEST(gain, inf->gain_step);
 
 	mutex_lock(&st->lock);
 	switch (mask) {
 	case IIO_CHAN_INFO_HARDWAREGAIN:
 		st->ch[chan->channel] = code;
-		ret = ad8366_write(indio_dev, st->ch[0], st->ch[1]);
+		ret = ad8366_write_code(st);
 		break;
 	default:
 		ret = -EINVAL;
@@ -234,10 +206,6 @@ static const struct iio_chan_spec ad8366_channels[] = {
 	AD8366_CHAN(1),
 };
 
-static const struct iio_chan_spec ada4961_channels[] = {
-	AD8366_CHAN(0),
-};
-
 static int ad8366_probe(struct spi_device *spi)
 {
 	struct device *dev = &spi->dev;
@@ -261,35 +229,20 @@ static int ad8366_probe(struct spi_device *spi)
 		return dev_err_probe(dev, ret, "Failed to get regulator\n");
 
 	st->spi = spi;
-	st->type = spi_get_device_id(spi)->driver_data;
+	st->info = &ad8366_infos[spi_get_device_id(spi)->driver_data];
 
-	switch (st->type) {
-	case ID_AD8366:
-		indio_dev->channels = ad8366_channels;
-		indio_dev->num_channels = ARRAY_SIZE(ad8366_channels);
-		break;
-	case ID_ADA4961:
-	case ID_ADL5240:
-	case ID_HMC792:
-	case ID_HMC1119:
-		rstc = devm_reset_control_get_optional_exclusive_deasserted(dev, NULL);
-		if (IS_ERR(rstc))
-			return dev_err_probe(dev, PTR_ERR(rstc),
-					     "Failed to get reset controller\n");
+	rstc = devm_reset_control_get_optional_exclusive_deasserted(dev, NULL);
+	if (IS_ERR(rstc))
+		return dev_err_probe(dev, PTR_ERR(rstc),
+				     "Failed to get reset controller\n");
 
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
 

-- 
2.43.0

