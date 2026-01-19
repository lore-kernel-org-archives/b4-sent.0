From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 19 Jan 2026 14:36:57 +0000
Subject: [PATCH 3/7] iio: amplifiers: ad8366: consume enable gpio for
 applicable parts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260119-iio-ad8366-update-v1-3-8044e23e964a@analog.com>
References: <20260119-iio-ad8366-update-v1-0-8044e23e964a@analog.com>
In-Reply-To: <20260119-iio-ad8366-update-v1-0-8044e23e964a@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768833448; l=1344;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=72lAxpPNNVQiH2FXV5I3I6t6Jbf3Jb9inxis9HKayGg=;
 b=ucKmp4HZErTKFi9sJh+JIsoCqsY/QGNLqSVg7QQSl32tUv5zhJtJfI4iCycjsyP6+xhAmBpXc
 FiUEq/SJwoOCRtUjswdfirRTeW4ZDJdyst3bWb6gfYCsq7yFgtfS5bm
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some parts may consume enable GPIO to set serial mode (PS pin) or
powerup the device (e.g. ADA4961's PWUP pin).

Co-developed-by: Michael Hennerich <michael.hennerich@analog.com>
Signed-off-by: Michael Hennerich <michael.hennerich@analog.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index d06ac786501c..63bb9f0179eb 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -43,6 +43,7 @@ struct ad8366_state {
 	struct regulator	*reg;
 	struct mutex            lock; /* protect sensor state */
 	struct gpio_desc	*reset_gpio;
+	struct gpio_desc	*enable_gpio;
 	unsigned char		ch[2];
 	enum ad8366_type	type;
 	const struct ad8366_info *info;
@@ -281,6 +282,13 @@ static int ad8366_probe(struct spi_device *spi)
 			ret = PTR_ERR(st->reset_gpio);
 			goto error_disable_reg;
 		}
+
+		st->enable_gpio = devm_gpiod_get_optional(&spi->dev, "enable", GPIOD_OUT_HIGH);
+		if (IS_ERR(st->enable_gpio)) {
+			ret = PTR_ERR(st->enable_gpio);
+			goto error_disable_reg;
+		}
+
 		indio_dev->channels = ada4961_channels;
 		indio_dev->num_channels = ARRAY_SIZE(ada4961_channels);
 		break;

-- 
2.43.0

