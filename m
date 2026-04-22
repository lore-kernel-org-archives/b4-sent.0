From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 22 Apr 2026 15:45:55 +0100
Subject: [PATCH 21/22] iio: dac: ad5686: add triggered buffer support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-ad5313r-iio-support-v1-21-ed7dca001d1b@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776869181; l=3587;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=n/jQcRuYKzz2K1D7fdN2/Uolo6lmFJ6ohrN+/ywPH1A=;
 b=8goP76zj/wMm+SjuSmvAExMrATiZuEpHhx17kq6AfjB6Pb6MTqC2fmN1FtDaYzg8r9irxnzEG
 1+gUKCYPOUJBQvcmyLuHUoshgO+k41cgOvWObU0vwb1ERh2qtM6Y3ro
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Trigger handler is implemented by leveraging the LDAC gpio when it is
available. Multiple channel writes can be flushed at once with the sync()
operation.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/Kconfig  |  2 ++
 drivers/iio/dac/ad5686.c | 62 ++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 64 insertions(+)

diff --git a/drivers/iio/dac/Kconfig b/drivers/iio/dac/Kconfig
index 8ef4a87d6d6a..bb4d3bdabef2 100644
--- a/drivers/iio/dac/Kconfig
+++ b/drivers/iio/dac/Kconfig
@@ -229,6 +229,8 @@ config LTC2688
 
 config AD5686
 	tristate
+	select IIO_BUFFER
+	select IIO_TRIGGERED_BUFFER
 
 config AD5686_SPI
 	tristate "Analog Devices AD5686 and similar multi-channel DACs (SPI)"
diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index a065c614c874..bec951afe8d0 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -16,6 +16,11 @@
 #include <linux/sysfs.h>
 #include <linux/wordpart.h>
 
+#include <linux/iio/buffer.h>
+#include <linux/iio/trigger.h>
+#include <linux/iio/trigger_consumer.h>
+#include <linux/iio/triggered_buffer.h>
+
 #include "ad5686.h"
 
 static const char * const ad5686_powerdown_modes[] = {
@@ -227,6 +232,7 @@ static const struct iio_chan_spec_ext_info ad5686_ext_info[] = {
 		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW),	\
 		.info_mask_shared_by_type = BIT(IIO_CHAN_INFO_SCALE),\
 		.address = addr,				\
+		.scan_index = chan,				\
 		.scan_type = {					\
 			.sign = 'u',				\
 			.realbits = (bits),			\
@@ -506,6 +512,55 @@ const struct ad5686_chip_info ad5679r_chip_info = {
 };
 EXPORT_SYMBOL_NS_GPL(ad5679r_chip_info, "IIO_AD5686");
 
+static irqreturn_t ad5686_trigger_handler(int irq, void *p)
+{
+	struct iio_poll_func *pf = p;
+	struct iio_dev *indio_dev = pf->indio_dev;
+	struct iio_buffer *buffer = indio_dev->buffer;
+	struct ad5686_state *st = iio_priv(indio_dev);
+	const struct iio_chan_spec *chan;
+	u16 val[AD5686_MAX_CHANNELS];
+	int ret, ch, i = 0;
+	bool async_update;
+	u8 cmd;
+
+	ret = iio_pop_from_buffer(buffer, val);
+	if (ret)
+		goto out;
+
+	mutex_lock(&st->lock);
+
+	async_update = st->ldac_gpio && bitmap_weight(indio_dev->active_scan_mask,
+						      iio_get_masklength(indio_dev)) > 1;
+	if (async_update) {
+		/* use ldac to update all channels simultaneously */
+		cmd = AD5686_CMD_WRITE_INPUT_N;
+		gpiod_set_value_cansleep(st->ldac_gpio, 0);
+	} else {
+		cmd = AD5686_CMD_WRITE_INPUT_N_UPDATE_N;
+	}
+
+	iio_for_each_active_channel(indio_dev, ch) {
+		chan = &indio_dev->channels[ch];
+		ret = st->ops->write(st, cmd, chan->address,
+				     val[i++] << chan->scan_type.shift);
+		if (ret)
+			break;
+	}
+
+	if (!ret && st->ops->sync)
+		ret = st->ops->sync(st); /* flush all pending transfers */
+
+	if (async_update)
+		gpiod_set_value_cansleep(st->ldac_gpio, 1);
+
+	mutex_unlock(&st->lock);
+out:
+	iio_trigger_notify_done(indio_dev->trig);
+
+	return IRQ_HANDLED;
+}
+
 int ad5686_probe(struct device *dev,
 		 const struct ad5686_chip_info *chip_info,
 		 const char *name, const struct ad5686_bus_ops *ops,
@@ -599,6 +654,13 @@ int ad5686_probe(struct device *dev,
 		return -EINVAL;
 	}
 
+	ret = devm_iio_triggered_buffer_setup_ext(dev, indio_dev, NULL,
+						  &ad5686_trigger_handler,
+						  IIO_BUFFER_DIRECTION_OUT,
+						  NULL, NULL);
+	if (ret)
+		return ret;
+
 	return devm_iio_device_register(dev, indio_dev);
 }
 EXPORT_SYMBOL_NS_GPL(ad5686_probe, "IIO_AD5686");

-- 
2.43.0

