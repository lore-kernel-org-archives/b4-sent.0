From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 21 Nov 2023 11:20:17 +0100
Subject: [PATCH 04/12] iio: adc: ad9467: fix reset gpio handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231121-dev-iio-backend-v1-4-6a3d542eba35@analog.com>
References: <20231121-dev-iio-backend-v1-0-6a3d542eba35@analog.com>
In-Reply-To: <20231121-dev-iio-backend-v1-0-6a3d542eba35@analog.com>
To: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-iio@vger.kernel.org
Cc: Olivier MOYSAN <olivier.moysan@foss.st.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700562016; l=2235;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=FvM763XbCHeFm7zY4qdHtyTPDglD207l1cPfXL+Oe8g=;
 b=P0PYKwMAq5iL7cSwivnC4VVCg/v4uxIFKKFnAFSJextBIv6XHP6HMK5EgXWqu3AOEsvidK4k8
 XV1C7/S/fs3AY8OC0AcvsmPzFVQheDspuKVpvkfZ3R5cLdaYu3EndBB
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The reset gpio was being requested with GPIOD_OUT_LOW which means, not
asserted. Then it was being asserted but never de-asserted which means
the devices was left in reset. Fix it by de-asserting the gpio.

While at it, moved the handling to it's own function and dropped
'reset_gpio' from the 'struct ad9467_state' as we only need it during
probe. On top of that, refactored things so that we now request the gpio
asserted (i.e in reset) and then de-assert it.

Fixes: ad6797120238 ("iio: adc: ad9467: add support AD9467 ADC")
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad9467.c | 33 ++++++++++++++++++++-------------
 1 file changed, 20 insertions(+), 13 deletions(-)

diff --git a/drivers/iio/adc/ad9467.c b/drivers/iio/adc/ad9467.c
index 39eccc28debe..368ea57be117 100644
--- a/drivers/iio/adc/ad9467.c
+++ b/drivers/iio/adc/ad9467.c
@@ -121,7 +121,6 @@ struct ad9467_state {
 	unsigned int			output_mode;
 
 	struct gpio_desc		*pwrdown_gpio;
-	struct gpio_desc		*reset_gpio;
 };
 
 static int ad9467_spi_read(struct spi_device *spi, unsigned int reg)
@@ -378,6 +377,23 @@ static int ad9467_preenable_setup(struct adi_axi_adc_conv *conv)
 	return ad9467_outputmode_set(st->spi, st->output_mode);
 }
 
+static int ad9467_reset(struct device *dev)
+{
+	struct gpio_desc *gpio;
+
+	gpio = devm_gpiod_get_optional(dev, "reset", GPIOD_OUT_HIGH);
+	if (IS_ERR(gpio))
+		return PTR_ERR(gpio);
+	if (!gpio)
+		return 0;
+
+	fsleep(1);
+	gpiod_direction_output(gpio, 0);
+	fsleep(10);
+
+	return 0;
+}
+
 static int ad9467_probe(struct spi_device *spi)
 {
 	const struct ad9467_chip_info *info;
@@ -408,18 +424,9 @@ static int ad9467_probe(struct spi_device *spi)
 	if (IS_ERR(st->pwrdown_gpio))
 		return PTR_ERR(st->pwrdown_gpio);
 
-	st->reset_gpio = devm_gpiod_get_optional(&spi->dev, "reset",
-						 GPIOD_OUT_LOW);
-	if (IS_ERR(st->reset_gpio))
-		return PTR_ERR(st->reset_gpio);
-
-	if (st->reset_gpio) {
-		udelay(1);
-		ret = gpiod_direction_output(st->reset_gpio, 1);
-		if (ret)
-			return ret;
-		mdelay(10);
-	}
+	ret = ad9467_reset(&spi->dev);
+	if (ret)
+		return ret;
 
 	conv->chip_info = &info->axi_adc_info;
 

-- 
2.42.1

