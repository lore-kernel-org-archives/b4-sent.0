From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 19 Jan 2026 14:36:59 +0000
Subject: [PATCH 5/7] iio: amplifiers: ad8366: use cleanup.h mutex guard
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260119-iio-ad8366-update-v1-5-8044e23e964a@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768833448; l=1898;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=YAYuOUTweoFKOoWx+os6umUAifv0dwftAt5d8TlJqJM=;
 b=XO9ZOAiOXRraSPnBYDMJ92vscFlv6RXnUB1srGcO5GKbPh/9atl/9cKD5LVevvB4MJtc5/IhN
 zfcLQaRgzWQB153uBkHdfmqCo/RgQq41EGJrnzH+zdwQcjWIwq29kC5
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Changes related to mutex handling:
- use guard() from cleanup for mutex locking
- replace mutex_init() for devm_mutex_init()

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 14 +++++++++-----
 1 file changed, 9 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index 160a8ab0c2ee..26856cb4216e 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -17,6 +17,7 @@
  * Copyright 2012-2026 Analog Devices Inc.
  */
 
+#include <linux/cleanup.h>
 #include <linux/device.h>
 #include <linux/kernel.h>
 #include <linux/slab.h>
@@ -164,7 +165,8 @@ static int ad8366_read_raw(struct iio_dev *indio_dev,
 	int ret;
 	int code, gain = 0;
 
-	mutex_lock(&st->lock);
+	guard(mutex)(&st->lock);
+
 	switch (m) {
 	case IIO_CHAN_INFO_HARDWAREGAIN:
 		code = st->ch[chan->channel];
@@ -210,7 +212,6 @@ static int ad8366_read_raw(struct iio_dev *indio_dev,
 	default:
 		ret = -EINVAL;
 	}
-	mutex_unlock(&st->lock);
 
 	return ret;
 };
@@ -267,7 +268,8 @@ static int ad8366_write_raw(struct iio_dev *indio_dev,
 		break;
 	}
 
-	mutex_lock(&st->lock);
+	guard(mutex)(&st->lock);
+
 	switch (mask) {
 	case IIO_CHAN_INFO_HARDWAREGAIN:
 		st->ch[chan->channel] = code;
@@ -276,7 +278,6 @@ static int ad8366_write_raw(struct iio_dev *indio_dev,
 	default:
 		ret = -EINVAL;
 	}
-	mutex_unlock(&st->lock);
 
 	return ret;
 }
@@ -336,10 +337,13 @@ static int ad8366_probe(struct spi_device *spi)
 	}
 
 	spi_set_drvdata(spi, indio_dev);
-	mutex_init(&st->lock);
 	st->spi = spi;
 	st->type = spi_get_device_id(spi)->driver_data;
 
+	ret = devm_mutex_init(&spi->dev, &st->lock);
+	if (ret)
+		return ret;
+
 	switch (st->type) {
 	case ID_AD8366:
 		indio_dev->channels = ad8366_channels;

-- 
2.43.0

