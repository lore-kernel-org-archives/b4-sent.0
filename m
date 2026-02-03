From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 03 Feb 2026 11:24:11 +0000
Subject: [PATCH v3 5/9] iio: amplifiers: ad8366: refactor device resource
 management
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260203-iio-ad8366-update-v3-5-5d5636b5181a@analog.com>
References: <20260203-iio-ad8366-update-v3-0-5d5636b5181a@analog.com>
In-Reply-To: <20260203-iio-ad8366-update-v3-0-5d5636b5181a@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770117857; l=3293;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=f+kMNCcEGZUSXT8GVTgbBGh2m45pMNgPC1EpKanwlWg=;
 b=QNUN9HjLyrpZeTAjssfmUhl9ReViIORKF/ARDaupDTw072/+Xik5ksSJHsb8b7p9IJckuEGnj
 /tSnt4l+Qc/AyG5Nf7bysVSf4xJ//MsC7qqaVwxzbu4h6IIkI7/1yBX
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adhere modern device resource management with the following:
- Voltage regulator managed and enabled internally;
- IIO device registration handled with devm_iio_device_register();
- removal of goto's from the probe function;
- ad8366_remove() removed as it is not needed anymore;

With the drop of goto's dev_err_probe() is used to report probe errors.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 50 +++++++++--------------------------------
 1 file changed, 10 insertions(+), 40 deletions(-)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index d6e18eb71bc8..2da10c748362 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -40,7 +40,6 @@ struct ad8366_info {
 
 struct ad8366_state {
 	struct spi_device	*spi;
-	struct regulator	*reg;
 	struct mutex            lock; /* protect sensor state */
 	unsigned char		ch[2];
 	enum ad8366_type	type;
@@ -259,14 +258,10 @@ static int ad8366_probe(struct spi_device *spi)
 	if (ret)
 		return ret;
 
-	st->reg = devm_regulator_get(&spi->dev, "vcc");
-	if (!IS_ERR(st->reg)) {
-		ret = regulator_enable(st->reg);
-		if (ret)
-			return ret;
-	}
+	ret = devm_regulator_get_enable(&spi->dev, "vcc");
+	if (ret)
+		return dev_err_probe(&spi->dev, ret, "Failed to get regulator\n");
 
-	spi_set_drvdata(spi, indio_dev);
 	st->spi = spi;
 	st->type = spi_get_device_id(spi)->driver_data;
 
@@ -280,17 +275,15 @@ static int ad8366_probe(struct spi_device *spi)
 	case ID_HMC792:
 	case ID_HMC1119:
 		reset_gpio = devm_gpiod_get_optional(&spi->dev, "reset", GPIOD_OUT_HIGH);
-		if (IS_ERR(reset_gpio)) {
-			ret = PTR_ERR(reset_gpio);
-			goto error_disable_reg;
-		}
+		if (IS_ERR(reset_gpio))
+			return dev_err_probe(&spi->dev, PTR_ERR(reset_gpio),
+					     "Failed to get reset GPIO\n");
+
 		indio_dev->channels = ada4961_channels;
 		indio_dev->num_channels = ARRAY_SIZE(ada4961_channels);
 		break;
 	default:
-		dev_err(&spi->dev, "Invalid device ID\n");
-		ret = -EINVAL;
-		goto error_disable_reg;
+		return dev_err_probe(&spi->dev, -EINVAL, "Invalid device ID\n");
 	}
 
 	st->info = &ad8366_infos[st->type];
@@ -300,31 +293,9 @@ static int ad8366_probe(struct spi_device *spi)
 
 	ret = ad8366_write(indio_dev, 0, 0);
 	if (ret < 0)
-		goto error_disable_reg;
+		return dev_err_probe(&spi->dev, ret, "failed to write initial gain\n");
 
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
+	return devm_iio_device_register(&spi->dev, indio_dev);
 }
 
 static const struct spi_device_id ad8366_id[] = {
@@ -342,7 +313,6 @@ static struct spi_driver ad8366_driver = {
 		.name	= KBUILD_MODNAME,
 	},
 	.probe		= ad8366_probe,
-	.remove		= ad8366_remove,
 	.id_table	= ad8366_id,
 };
 

-- 
2.43.0

