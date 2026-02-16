From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 16 Feb 2026 17:10:54 +0000
Subject: [PATCH v5 10/11] iio: amplifiers: ad8366: consume enable gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260216-iio-ad8366-update-v5-10-7e6091357d02@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771261851; l=1270;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=dDdcU23HlSPG2yMMj26nBGlcwxQIvQ+x8qXHKCHZHlc=;
 b=2Y8JTqvWh8UqelxNGbz30ENpH9AGUnMeAT3aAwJOTOJ0R8j/8XdxpfiyfbkkTJgbRcP2NWZo/
 xJIZFsmAXxGCL8mp/rWGLELLwhFNwrIdkXs5P/UFOWRjHBIjU6Q6uk5
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
index fb787a512bff..d4499af0518a 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -217,6 +217,7 @@ static const struct iio_chan_spec ad8366_channels[] = {
 static int ad8366_probe(struct spi_device *spi)
 {
 	struct device *dev = &spi->dev;
+	struct gpio_desc *enable_gpio;
 	struct reset_control *rstc;
 	struct iio_dev *indio_dev;
 	struct ad8366_state *st;
@@ -239,6 +240,11 @@ static int ad8366_probe(struct spi_device *spi)
 	st->spi = spi;
 	st->info = spi_get_device_match_data(spi);
 
+	enable_gpio = devm_gpiod_get_optional(dev, "enable", GPIOD_OUT_HIGH);
+	if (IS_ERR(enable_gpio))
+		return dev_err_probe(dev, PTR_ERR(enable_gpio),
+				     "Failed to get enable GPIO\n");
+
 	rstc = devm_reset_control_get_optional_exclusive_deasserted(dev, NULL);
 	if (IS_ERR(rstc))
 		return dev_err_probe(dev, PTR_ERR(rstc),

-- 
2.43.0

