From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 16 Feb 2026 17:10:51 +0000
Subject: [PATCH v5 07/11] iio: amplifiers: ad8366: replace reset-gpio with
 reset controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260216-iio-ad8366-update-v5-7-7e6091357d02@analog.com>
References: <20260216-iio-ad8366-update-v5-0-7e6091357d02@analog.com>
In-Reply-To: <20260216-iio-ad8366-update-v5-0-7e6091357d02@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771261851; l=2412;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=2h/qIlXksRtIPfCMm6MG5JFQw2QvDnxOXehKZUf2GXE=;
 b=PSHg/AGJgN9vG9M3eQuvL3jFUxI9aLv0if+nBm5XzHiTzwmvwwPpbxbUczUBWOGy6iUAD5JAD
 PB5aSlFomFaDz7BX7pgjhKiBlxgd709zhp+G4XUiw3XAKFgUcjC1sEL
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove reset_gpio from the device state struct and use the reset_control
interface instead, using a local variable, as it is not being used
anywhere else. The reset controller init is moved out from the switch case
and optionally initialized for every device variant. Although not all
devices have a reset pin the code does not need to change if it is not
wired.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 13 +++++++------
 1 file changed, 7 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index e8c80551d524..8b3d6825423e 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -23,6 +23,7 @@
 #include <linux/module.h>
 #include <linux/mutex.h>
 #include <linux/regulator/consumer.h>
+#include <linux/reset.h>
 #include <linux/spi/spi.h>
 #include <linux/types.h>
 
@@ -44,7 +45,6 @@ struct ad8366_info {
 struct ad8366_state {
 	struct spi_device	*spi;
 	struct mutex            lock; /* protect sensor state */
-	struct gpio_desc	*reset_gpio;
 	unsigned char		ch[2];
 	enum ad8366_type	type;
 	const struct ad8366_info *info;
@@ -248,6 +248,7 @@ static const struct iio_chan_spec ada4961_channels[] = {
 static int ad8366_probe(struct spi_device *spi)
 {
 	struct device *dev = &spi->dev;
+	struct reset_control *rstc;
 	struct iio_dev *indio_dev;
 	struct ad8366_state *st;
 	int ret;
@@ -278,11 +279,6 @@ static int ad8366_probe(struct spi_device *spi)
 	case ID_ADL5240:
 	case ID_HMC792:
 	case ID_HMC1119:
-		st->reset_gpio = devm_gpiod_get_optional(&spi->dev, "reset", GPIOD_OUT_HIGH);
-		if (IS_ERR(st->reset_gpio))
-			return dev_err_probe(dev, PTR_ERR(st->reset_gpio),
-					     "Failed to get reset gpio\n");
-
 		indio_dev->channels = ada4961_channels;
 		indio_dev->num_channels = ARRAY_SIZE(ada4961_channels);
 		break;
@@ -290,6 +286,11 @@ static int ad8366_probe(struct spi_device *spi)
 		return dev_err_probe(dev, -EINVAL, "Invalid device ID\n");
 	}
 
+	rstc = devm_reset_control_get_optional_exclusive_deasserted(dev, NULL);
+	if (IS_ERR(rstc))
+		return dev_err_probe(dev, PTR_ERR(rstc),
+				     "Failed to get reset controller\n");
+
 	st->info = &ad8366_infos[st->type];
 	indio_dev->name = spi_get_device_id(spi)->name;
 	indio_dev->info = &ad8366_info;

-- 
2.43.0

