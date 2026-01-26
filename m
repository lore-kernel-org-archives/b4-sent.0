From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 26 Jan 2026 13:51:04 +0000
Subject: [PATCH v2 3/6] iio: amplifiers: ad8366: refactor device resource
 management
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260126-iio-ad8366-update-v2-3-c9a4d31aeb01@analog.com>
References: <20260126-iio-ad8366-update-v2-0-c9a4d31aeb01@analog.com>
In-Reply-To: <20260126-iio-ad8366-update-v2-0-c9a4d31aeb01@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769436111; l=3912;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=MSyQPvX4zNZ9Tempwgh6myGBaPDft1zW3aPPK5Ky45k=;
 b=iRrnsTBOCGHBh+cGIhPDTQxDnpG8Q7e5JRwKzVbTLfKy/FyOA9//ebZnMa/kSc9WypPuMuqm8
 HLUaGeXuUF1DmpKrnJ1qMgxo6F1Z7PHxsf0zA6puwETxvAtN5LbAhVl
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adhere modern device resource management with the following:
- Voltage regulator managed and enabled internally;
- Proper mutex lifecycle with devm_mutex_init(), replacing mutex_init();
- IIO device registration handled with devm_iio_device_register();
- removal of goto's from the probe function;
- ad8366_remove() removed as it is not needed anymore;

Also, dev_err_probe() is used to report probe errors with created local
device pointer.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 60 ++++++++++++-----------------------------
 1 file changed, 17 insertions(+), 43 deletions(-)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index d06ac786501c..0f3fc79ebbf3 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -40,7 +40,6 @@ struct ad8366_info {
 
 struct ad8366_state {
 	struct spi_device	*spi;
-	struct regulator	*reg;
 	struct mutex            lock; /* protect sensor state */
 	struct gpio_desc	*reset_gpio;
 	unsigned char		ch[2];
@@ -245,25 +244,25 @@ static const struct iio_chan_spec ada4961_channels[] = {
 
 static int ad8366_probe(struct spi_device *spi)
 {
+	struct device *dev = &spi->dev;
 	struct iio_dev *indio_dev;
 	struct ad8366_state *st;
 	int ret;
 
-	indio_dev = devm_iio_device_alloc(&spi->dev, sizeof(*st));
+	indio_dev = devm_iio_device_alloc(dev, sizeof(*st));
 	if (indio_dev == NULL)
 		return -ENOMEM;
 
 	st = iio_priv(indio_dev);
 
-	st->reg = devm_regulator_get(&spi->dev, "vcc");
-	if (!IS_ERR(st->reg)) {
-		ret = regulator_enable(st->reg);
-		if (ret)
-			return ret;
-	}
+	ret = devm_regulator_get_enable(dev, "vcc");
+	if (ret)
+		return dev_err_probe(dev, ret, "Failed to get regulator\n");
+
+	ret = devm_mutex_init(dev, &st->lock);
+	if (ret)
+		return ret;
 
-	spi_set_drvdata(spi, indio_dev);
-	mutex_init(&st->lock);
 	st->spi = spi;
 	st->type = spi_get_device_id(spi)->driver_data;
 
@@ -276,18 +275,16 @@ static int ad8366_probe(struct spi_device *spi)
 	case ID_ADL5240:
 	case ID_HMC792:
 	case ID_HMC1119:
-		st->reset_gpio = devm_gpiod_get_optional(&spi->dev, "reset", GPIOD_OUT_HIGH);
-		if (IS_ERR(st->reset_gpio)) {
-			ret = PTR_ERR(st->reset_gpio);
-			goto error_disable_reg;
-		}
+		st->reset_gpio = devm_gpiod_get_optional(dev, "reset", GPIOD_OUT_HIGH);
+		if (IS_ERR(st->reset_gpio))
+			return dev_err_probe(dev, PTR_ERR(st->reset_gpio),
+					     "Failed to get reset GPIO\n");
+
 		indio_dev->channels = ada4961_channels;
 		indio_dev->num_channels = ARRAY_SIZE(ada4961_channels);
 		break;
 	default:
-		dev_err(&spi->dev, "Invalid device ID\n");
-		ret = -EINVAL;
-		goto error_disable_reg;
+		return dev_err_probe(dev, -EINVAL, "Invalid device ID\n");
 	}
 
 	st->info = &ad8366_infos[st->type];
@@ -297,31 +294,9 @@ static int ad8366_probe(struct spi_device *spi)
 
 	ret = ad8366_write(indio_dev, 0, 0);
 	if (ret < 0)
-		goto error_disable_reg;
+		return dev_err_probe(dev, ret, "failed to write initial gain\n");
 
-	ret = iio_device_register(indio_dev);
-	if (ret)
-		goto error_disable_reg;
-
-	return 0;
-
-error_disable_reg:
-	if (!IS_ERR(st->reg))
-		regulator_disable(st->reg);
-
-	return ret;
-}
-
-static void ad8366_remove(struct spi_device *spi)
-{
-	struct iio_dev *indio_dev = spi_get_drvdata(spi);
-	struct ad8366_state *st = iio_priv(indio_dev);
-	struct regulator *reg = st->reg;
-
-	iio_device_unregister(indio_dev);
-
-	if (!IS_ERR(reg))
-		regulator_disable(reg);
+	return devm_iio_device_register(dev, indio_dev);
 }
 
 static const struct spi_device_id ad8366_id[] = {
@@ -339,7 +314,6 @@ static struct spi_driver ad8366_driver = {
 		.name	= KBUILD_MODNAME,
 	},
 	.probe		= ad8366_probe,
-	.remove		= ad8366_remove,
 	.id_table	= ad8366_id,
 };
 

-- 
2.43.0

