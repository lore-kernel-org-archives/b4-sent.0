From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 02 Jun 2026 17:33:57 +0100
Subject: [PATCH 10/12] iio: dac: ad5686: add triggered buffer support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-ad5686-new-features-v1-10-691e01883d27@analog.com>
References: <20260602-ad5686-new-features-v1-0-691e01883d27@analog.com>
In-Reply-To: <20260602-ad5686-new-features-v1-0-691e01883d27@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780418030; l=3523;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=NkwPSM/HeIv2TIXju9nekbHoT2W+fYgNfc8kUZ545qg=;
 b=c/nRUD3meAVZeSmZCksdOe5Y+XPs5RMMtGVq3bhKB6U/r/WExqoXDiFZYMYRhSNZKSB2PiLob
 lqaS1TYWJGUABQNb/sQIU7bEnSC2fJoTMClJCzBNu3xY6/B0463pXPZ
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement trigger handler by leveraging the LDAC gpio to update all DAC
channels at once when it is available. Also, the multiple channel writes
can be flushed at once with the sync() operation.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/Kconfig  |  2 ++
 drivers/iio/dac/ad5686.c | 59 ++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 61 insertions(+)

diff --git a/drivers/iio/dac/Kconfig b/drivers/iio/dac/Kconfig
index 657c68e75542..5f14fcd780e2 100644
--- a/drivers/iio/dac/Kconfig
+++ b/drivers/iio/dac/Kconfig
@@ -240,6 +240,8 @@ config LTC2688
 
 config AD5686
 	tristate
+	select IIO_BUFFER
+	select IIO_TRIGGERED_BUFFER
 
 config AD5686_SPI
 	tristate "Analog Devices AD5686 and similar multi-channel DACs (SPI)"
diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index a4cc0f86ea54..5052df44ab1c 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -19,7 +19,11 @@
 #include <linux/sysfs.h>
 #include <linux/wordpart.h>
 
+#include <linux/iio/buffer.h>
 #include <linux/iio/iio.h>
+#include <linux/iio/trigger.h>
+#include <linux/iio/trigger_consumer.h>
+#include <linux/iio/triggered_buffer.h>
 
 #include "ad5686.h"
 
@@ -245,6 +249,7 @@ static const struct iio_chan_spec_ext_info ad5686_ext_info[] = {
 		.info_mask_separate = BIT(IIO_CHAN_INFO_RAW),	\
 		.info_mask_shared_by_type = BIT(IIO_CHAN_INFO_SCALE),\
 		.address = addr,				\
+		.scan_index = chan,				\
 		.scan_type = {					\
 			.sign = 'u',				\
 			.realbits = (bits),			\
@@ -469,6 +474,53 @@ const struct ad5686_chip_info ad5679r_chip_info = {
 };
 EXPORT_SYMBOL_NS_GPL(ad5679r_chip_info, "IIO_AD5686");
 
+static irqreturn_t ad5686_trigger_handler(int irq, void *p)
+{
+	struct iio_poll_func *pf = p;
+	struct iio_dev *indio_dev = pf->indio_dev;
+	struct iio_buffer *buffer = indio_dev->buffer;
+	struct ad5686_state *st = iio_priv(indio_dev);
+	u16 val[AD5686_MAX_CHANNELS] = { };
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
+		ret = st->ops->write(st, cmd, indio_dev->channels[ch].address, val[i++]);
+		if (ret)
+			goto cleanup;
+	}
+
+	if (st->ops->sync)
+		ret = st->ops->sync(st); /* flush all pending transfers */
+
+cleanup:
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
@@ -569,6 +621,13 @@ int ad5686_probe(struct device *dev,
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

