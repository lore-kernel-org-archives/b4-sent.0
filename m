From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 03 Feb 2026 11:24:14 +0000
Subject: [PATCH v3 8/9] iio: amplifiers: ad8366: consume enable gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260203-iio-ad8366-update-v3-8-5d5636b5181a@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770117857; l=2016;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=NI6Xmsw6qw3e0XQ9ey2GDgpNHtC2qQOpsDhpudcrNSs=;
 b=ZER9ogdVMM1LC5NtTAY6EUzYEivRrdqa9Z7JDK8lrB2+9ayvCpIvxFYbFnrfBO9qWiV9YtaMV
 WU8YXCibjV5BnBBKUU2aTvOAu0vFUDlB8gHQ3ZyiIFv8fmlsueHNL0u
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some parts may consume enable GPIO to enable serial mode
(HMC1119's and HMC792A P/S pin) or powerup the device
(e.g. ADA4961's PWUP pin). Also, add a comment explaining
that even though chips like HMC271A has a reset gpio, this
driver previously considered the reset pin for parts that
don't actually have a reset gpio, so it might have been
used to enable/power the device.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 13 ++++++++++++-
 1 file changed, 12 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index dc2fe94c53cd..92865ab96ade 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -204,7 +204,7 @@ static const struct iio_chan_spec ad8366_channels[] = {
 
 static int ad8366_probe(struct spi_device *spi)
 {
-	struct gpio_desc *reset_gpio;
+	struct gpio_desc *reset_gpio, *enable_gpio;
 	struct iio_dev *indio_dev;
 	struct ad8366_state *st;
 	int ret;
@@ -226,11 +226,22 @@ static int ad8366_probe(struct spi_device *spi)
 	st->spi = spi;
 	st->info = spi_get_device_match_data(spi);
 
+	/*
+	 * Previously, this driver considered the reset gpio for some devices
+	 * that don't actually have a reset pin, which could have been wired
+	 * up to the enable pin instead, so some users might be relying on this
+	 * to turn the chip on rather than reset it.
+	 */
 	reset_gpio = devm_gpiod_get_optional(&spi->dev, "reset", GPIOD_OUT_HIGH);
 	if (IS_ERR(reset_gpio))
 		return dev_err_probe(&spi->dev, PTR_ERR(reset_gpio),
 				     "Failed to get reset GPIO\n");
 
+	enable_gpio = devm_gpiod_get_optional(&spi->dev, "enable", GPIOD_OUT_HIGH);
+	if (IS_ERR(enable_gpio))
+		return dev_err_probe(&spi->dev, PTR_ERR(enable_gpio),
+				     "Failed to get enable GPIO\n");
+
 	indio_dev->name = spi_get_device_id(spi)->name;
 	indio_dev->info = &ad8366_info;
 	indio_dev->modes = INDIO_DIRECT_MODE;

-- 
2.43.0

