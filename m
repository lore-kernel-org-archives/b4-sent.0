From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 10 Feb 2026 19:42:10 +0000
Subject: [PATCH v4 10/11] iio: amplifiers: ad8366: consume enable gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260210-iio-ad8366-update-v4-10-15505f7b15b4@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770752535; l=1285;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=4a2IBbnyaOJ7gewx1RlFVq18q3wqExfVEKH0FpNfWGQ=;
 b=ODvCtSxIjNnFuIBGHRSZc7k0d0/Cpiigr+61MAjQv2eUbD9QtJwKDAot2rMbFsXoP/k9CJQ3z
 FOKcHLmyF4kAFj06z/HtSpakuGw3V8AJ+Fi8DqTtkJJ5+3ono5w91RE
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some parts may consume enable GPIO to enable serial mode
(HMC1119's and HMC792A P/S pin) or powerup the device
(e.g. ADA4961's PWUP pin).

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index 79fb3119d794..b828b4be7b6e 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -204,6 +204,7 @@ static const struct iio_chan_spec ad8366_channels[] = {
 static int ad8366_probe(struct spi_device *spi)
 {
 	struct device *dev = &spi->dev;
+	struct gpio_desc *enable_gpio;
 	struct reset_control *rstc;
 	struct iio_dev *indio_dev;
 	struct ad8366_state *st;
@@ -231,6 +232,11 @@ static int ad8366_probe(struct spi_device *spi)
 		return dev_err_probe(dev, PTR_ERR(rstc),
 				     "Failed to get reset controller\n");
 
+	enable_gpio = devm_gpiod_get_optional(dev, "enable", GPIOD_OUT_HIGH);
+	if (IS_ERR(enable_gpio))
+		return dev_err_probe(dev, PTR_ERR(enable_gpio),
+				     "Failed to get enable GPIO\n");
+
 	indio_dev->name = spi_get_device_id(spi)->name;
 	indio_dev->info = &ad8366_info;
 	indio_dev->modes = INDIO_DIRECT_MODE;

-- 
2.43.0

