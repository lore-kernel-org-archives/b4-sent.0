From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 16 Oct 2024 16:21:59 +0200
Subject: [PATCH 1/3] iio: addac: ad74413r: drop reset_gpio from struct
 ad74413r_state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241016-dev-ad74413r-minor-improv-v1-1-13c9c769237d@analog.com>
References: <20241016-dev-ad74413r-minor-improv-v1-0-13c9c769237d@analog.com>
In-Reply-To: <20241016-dev-ad74413r-minor-improv-v1-0-13c9c769237d@analog.com>
To: linux-iio@vger.kernel.org
Cc: Cosmin Tanislav <cosmin.tanislav@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729088521; l=2264;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=pAXfyFHbRW/SCpMOSEqzhiSiKYRJaTQDO64j4kkjfgA=;
 b=ahi318fIe2pK7kqF1zYIn/ZQPsES8alHToNgzcJw+RVj9yTqqp3uOyL3VpwjvOr1pzrt+N934
 mTnvHsXScTKAers5jFF4OmMHFJ0rSn6QHpMY2Dd3qCyTBulhtXs94Jy
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We just need the reset gpio during probe so there's no need to keep it
in our state struct. Hence, move devm_gpiod_get_optional() into
ad74413r_reset() and use a local struct gpio_desc.

While at it, request the gpio in the asserted state (GPIOD_OUT_HIGH) so
that we already perform the reset while requesting the gpio saving us a
call to gpiod_set_value_cansleep().

Also, explicitly include <gpio/consumer.h> for
devm_gpiod_get_optional().

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/addac/ad74413r.c | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

diff --git a/drivers/iio/addac/ad74413r.c b/drivers/iio/addac/ad74413r.c
index e50c896a07668..550e2460e29ca 100644
--- a/drivers/iio/addac/ad74413r.c
+++ b/drivers/iio/addac/ad74413r.c
@@ -9,6 +9,7 @@
 #include <linux/crc8.h>
 #include <linux/device.h>
 #include <linux/err.h>
+#include <linux/gpio/consumer.h>
 #include <linux/gpio/driver.h>
 #include <linux/iio/buffer.h>
 #include <linux/iio/iio.h>
@@ -72,7 +73,6 @@ struct ad74413r_state {
 	struct regmap			*regmap;
 	struct device			*dev;
 	struct iio_trigger		*trig;
-	struct gpio_desc		*reset_gpio;
 
 	size_t			adc_active_channels;
 	struct spi_message	adc_samples_msg;
@@ -407,12 +407,16 @@ static int ad74413r_gpio_set_comp_config(struct gpio_chip *chip,
 
 static int ad74413r_reset(struct ad74413r_state *st)
 {
+	struct gpio_desc *reset_gpio;
 	int ret;
 
-	if (st->reset_gpio) {
-		gpiod_set_value_cansleep(st->reset_gpio, 1);
+	reset_gpio = devm_gpiod_get_optional(st->dev, "reset", GPIOD_OUT_HIGH);
+	if (IS_ERR(reset_gpio))
+		return PTR_ERR(reset_gpio);
+
+	if (reset_gpio) {
 		fsleep(50);
-		gpiod_set_value_cansleep(st->reset_gpio, 0);
+		gpiod_set_value_cansleep(reset_gpio, 0);
 		return 0;
 	}
 
@@ -1378,10 +1382,6 @@ static int ad74413r_probe(struct spi_device *spi)
 	if (IS_ERR(st->regmap))
 		return PTR_ERR(st->regmap);
 
-	st->reset_gpio = devm_gpiod_get_optional(st->dev, "reset", GPIOD_OUT_LOW);
-	if (IS_ERR(st->reset_gpio))
-		return PTR_ERR(st->reset_gpio);
-
 	st->refin_reg = devm_regulator_get(st->dev, "refin");
 	if (IS_ERR(st->refin_reg))
 		return dev_err_probe(st->dev, PTR_ERR(st->refin_reg),

-- 
2.46.1

