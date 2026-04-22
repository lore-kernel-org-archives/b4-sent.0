From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 22 Apr 2026 15:45:46 +0100
Subject: [PATCH 12/22] iio: dac: ad5686: fix powerdown control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-ad5313r-iio-support-v1-12-ed7dca001d1b@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776869181; l=4907;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=N4j8DVJg39SZkt7C9VDNtfzdCSPJ1WG7gWhxuqNFEEE=;
 b=7ua9qLj9VhnIQ0A0hvD9Fvf4rqTmvWh/iU/Z+jQi9ssuYVydqBRbxnq8QN0SC76Z1CKIACV/8
 PUQMqFH16eaCCadgg6ykK/feD6HMjaESOscoTs4G42QjGqQSChhT+Z7
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch fixes powerdown control issues by protecting the cached
powerdown states with mutex access, and by using a proper bit shift for
the powerdown mask values. During initialization, powerdown bits are
initialized so that unused bits are set to 1 and the correct bit shift is
used.

Dual-channel devices use one-hot encondig in the address and that reflects
on the position of the powerdown bits, which are not channel-index based
for that case. Quad-channel devices also use one-hot encondig for the
channel address but the result of log2(address) coincides with the channel
index value.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.c | 54 +++++++++++++++++++++++++++++++++++++-----------
 1 file changed, 42 insertions(+), 12 deletions(-)

diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 4ca9cd5b6e38..19d791c655b7 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -40,12 +40,26 @@ static int ad5683_control_sync(struct ad5686_state *st)
 			 FIELD_PREP(AD5683_REF_BIT_MSK, !st->use_internal_vref));
 }
 
+static inline int ad5686_pd_mask_shift(const struct iio_chan_spec *chan)
+{
+	if (chan->channel == chan->address)
+		return chan->channel * 2;
+
+	/* one-hot encoding is used in dual/quad channel devices */
+	return __ffs(chan->address) * 2;
+}
+
 static int ad5686_get_powerdown_mode(struct iio_dev *indio_dev,
 				     const struct iio_chan_spec *chan)
 {
 	struct ad5686_state *st = iio_priv(indio_dev);
+	int mode, shift = ad5686_pd_mask_shift(chan);
 
-	return ((st->pwr_down_mode >> (chan->channel * 2)) & 0x3) - 1;
+	mutex_lock(&st->lock);
+	mode = ((st->pwr_down_mode >> shift) & 0x3) - 1;
+	mutex_unlock(&st->lock);
+
+	return mode;
 }
 
 static int ad5686_set_powerdown_mode(struct iio_dev *indio_dev,
@@ -53,9 +67,12 @@ static int ad5686_set_powerdown_mode(struct iio_dev *indio_dev,
 				     unsigned int mode)
 {
 	struct ad5686_state *st = iio_priv(indio_dev);
+	int shift = ad5686_pd_mask_shift(chan);
 
-	st->pwr_down_mode &= ~(0x3 << (chan->channel * 2));
-	st->pwr_down_mode |= ((mode + 1) << (chan->channel * 2));
+	mutex_lock(&st->lock);
+	st->pwr_down_mode &= ~(0x3 << shift);
+	st->pwr_down_mode |= ((mode + 1) << shift);
+	mutex_unlock(&st->lock);
 
 	return 0;
 }
@@ -71,9 +88,13 @@ static ssize_t ad5686_read_dac_powerdown(struct iio_dev *indio_dev,
 		uintptr_t private, const struct iio_chan_spec *chan, char *buf)
 {
 	struct ad5686_state *st = iio_priv(indio_dev);
+	int val, shift = ad5686_pd_mask_shift(chan);
 
-	return sysfs_emit(buf, "%d\n", !!(st->pwr_down_mask &
-				       (0x3 << (chan->channel * 2))));
+	mutex_lock(&st->lock);
+	val = !!(st->pwr_down_mask & (0x3 << shift));
+	mutex_unlock(&st->lock);
+
+	return sysfs_emit(buf, "%d\n", val);
 }
 
 static ssize_t ad5686_write_dac_powerdown(struct iio_dev *indio_dev,
@@ -83,7 +104,7 @@ static ssize_t ad5686_write_dac_powerdown(struct iio_dev *indio_dev,
 					  size_t len)
 {
 	bool readin;
-	int ret;
+	int ret, shift = ad5686_pd_mask_shift(chan);
 	struct ad5686_state *st = iio_priv(indio_dev);
 	unsigned int val;
 	u8 address = 0;
@@ -92,10 +113,12 @@ static ssize_t ad5686_write_dac_powerdown(struct iio_dev *indio_dev,
 	if (ret)
 		return ret;
 
+	mutex_lock(&st->lock);
+
 	if (readin)
-		st->pwr_down_mask |= (0x3 << (chan->channel * 2));
+		st->pwr_down_mask |= (0x3 << shift);
 	else
-		st->pwr_down_mask &= ~(0x3 << (chan->channel * 2));
+		st->pwr_down_mask &= ~(0x3 << shift);
 
 	switch (st->chip_info->regmap_type) {
 	case AD5310_REGMAP:
@@ -116,9 +139,10 @@ static ssize_t ad5686_write_dac_powerdown(struct iio_dev *indio_dev,
 		ret = st->write(st, AD5686_CMD_POWERDOWN_DAC, address, val);
 		break;
 	default:
-		return -EINVAL;
+		ret = -EINVAL;
 	}
 
+	mutex_unlock(&st->lock);
 
 	return ret ? ret : len;
 }
@@ -434,7 +458,7 @@ int ad5686_probe(struct device *dev,
 {
 	struct iio_dev *indio_dev;
 	struct ad5686_state *st;
-	int ret, i;
+	int ret, i, shift;
 
 	indio_dev = devm_iio_device_alloc(dev, sizeof(*st));
 	if (indio_dev == NULL)
@@ -455,8 +479,14 @@ int ad5686_probe(struct device *dev,
 	st->vref_mv = st->use_internal_vref ? st->chip_info->int_vref_mv : ret / 1000;
 
 	/* Set all the power down mode for all channels to 1K pulldown */
-	for (i = 0; i < st->chip_info->num_channels; i++)
-		st->pwr_down_mode |= (0x01 << (i * 2));
+	st->pwr_down_mode = ~0U;
+	st->pwr_down_mask = ~0U;
+	for (i = 0; i < st->chip_info->num_channels; i++) {
+		shift = ad5686_pd_mask_shift(&st->chip_info->channels[i]);
+		st->pwr_down_mask &= ~(0x3 << shift); /* powered up state */
+		st->pwr_down_mode &= ~(0x3 << shift);
+		st->pwr_down_mode |= (0x01 << shift);
+	}
 
 	indio_dev->name = name;
 	indio_dev->info = &ad5686_info;

-- 
2.43.0

