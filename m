From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 26 Jan 2026 13:51:06 +0000
Subject: [PATCH v2 5/6] iio: amplifiers: ad8366: consume enable gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260126-iio-ad8366-update-v2-5-c9a4d31aeb01@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769436111; l=1405;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=hjO3AF8SajGaQsSNLm/TNA2Z1sFEVvdZwYSoYv5HFf0=;
 b=j0iEMbB69a495oPjVHQreEuRT6rLV60FdpY1TMMc9fs/WRw6oCZPCUz+Q+4AkqDn5FdECcaxD
 Z2bZqDHFNV4DudgdsrwluMu8FCMsOWQ2L5f22sR+Cl+pfU6YpaXdL6K
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some parts may consume enable GPIO to enable serial mode
(HMC1119's and HMC792A P/S pin) or powerup the device
(e.g. ADA4961's PWUP pin).

Co-developed-by: Michael Hennerich <michael.hennerich@analog.com>
Signed-off-by: Michael Hennerich <michael.hennerich@analog.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index 134188db2e15..9ad6a628376c 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -41,6 +41,7 @@ struct ad8366_state {
 	struct spi_device	*spi;
 	struct mutex            lock; /* protect sensor state */
 	struct gpio_desc	*reset_gpio;
+	struct gpio_desc	*enable_gpio;
 	unsigned char		ch[2];
 	const struct ad8366_info *info;
 	/*
@@ -230,6 +231,11 @@ static int ad8366_probe(struct spi_device *spi)
 		return dev_err_probe(dev, PTR_ERR(st->reset_gpio),
 				     "Failed to get reset GPIO\n");
 
+	st->enable_gpio = devm_gpiod_get_optional(dev, "enable", GPIOD_OUT_HIGH);
+	if (IS_ERR(st->enable_gpio))
+		return dev_err_probe(dev, PTR_ERR(st->enable_gpio),
+				     "Failed to get enable GPIO\n");
+
 	indio_dev->name = spi_get_device_id(spi)->name;
 	indio_dev->info = &ad8366_info;
 	indio_dev->modes = INDIO_DIRECT_MODE;

-- 
2.43.0

