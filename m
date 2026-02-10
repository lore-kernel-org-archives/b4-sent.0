From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 10 Feb 2026 19:42:06 +0000
Subject: [PATCH v4 06/11] iio: amplifiers: ad8366: replace reset-gpio with
 reset controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260210-iio-ad8366-update-v4-6-15505f7b15b4@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770752535; l=1768;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=xxSuKq9E/6bGxE6XgUkOFI+Qx13kgVsTJFs9X9iiQRc=;
 b=dcB2HBQADW0sFtiSzhEK2yJtDD8iig7v+7Xgvf5rjLDEUT3obH+6oIRmcXverU7+0qfG0sNR6
 ziDzhGVfElqBjyssVwVTjhFQU9ReFlABf/kXoAkzP3pocd9D5BOi+8l
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove reset_gpio from the device state struct and use the
reset_control interface instead, using a local variable,
as it is not being used anywhere else.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index f0053a09cbb6..67817dedd75d 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -17,6 +17,7 @@
 #include <linux/module.h>
 #include <linux/mutex.h>
 #include <linux/regulator/consumer.h>
+#include <linux/reset.h>
 #include <linux/spi/spi.h>
 
 #include <linux/iio/iio.h>
@@ -38,7 +39,6 @@ struct ad8366_state {
 	struct spi_device	*spi;
 	struct regulator	*reg;
 	struct mutex            lock; /* protect sensor state */
-	struct gpio_desc	*reset_gpio;
 	unsigned char		ch[2];
 	enum ad8366_type	type;
 	const struct ad8366_info *info;
@@ -242,6 +242,7 @@ static const struct iio_chan_spec ada4961_channels[] = {
 static int ad8366_probe(struct spi_device *spi)
 {
 	struct device *dev = &spi->dev;
+	struct reset_control *rstc;
 	struct iio_dev *indio_dev;
 	struct ad8366_state *st;
 	int ret;
@@ -276,9 +277,9 @@ static int ad8366_probe(struct spi_device *spi)
 	case ID_ADL5240:
 	case ID_HMC792:
 	case ID_HMC1119:
-		st->reset_gpio = devm_gpiod_get_optional(&spi->dev, "reset", GPIOD_OUT_HIGH);
-		if (IS_ERR(st->reset_gpio)) {
-			ret = PTR_ERR(st->reset_gpio);
+		rstc = devm_reset_control_get_optional_exclusive_deasserted(dev, NULL);
+		if (IS_ERR(rstc)) {
+			ret = PTR_ERR(rstc);
 			goto error_disable_reg;
 		}
 		indio_dev->channels = ada4961_channels;

-- 
2.43.0

