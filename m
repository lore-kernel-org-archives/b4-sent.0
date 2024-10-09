From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 09 Oct 2024 16:16:46 +0200
Subject: [PATCH 4/4] iio: frequency: adf4371: make use of dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241009-dev-adf4371-minor-improv-v1-4-97f4f22ed941@analog.com>
References: <20241009-dev-adf4371-minor-improv-v1-0-97f4f22ed941@analog.com>
In-Reply-To: <20241009-dev-adf4371-minor-improv-v1-0-97f4f22ed941@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728483403; l=1733;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=DGH4I8LERGUVBi449GUHzvNvBiAJHsHztF+43+7F+ac=;
 b=WUiHMjYXsVhamHZoKp5SXwyL2fY/16mdslO7qxD9UkUMiZOLD/6K8CR+s4T2Y5EpYdqKf3JQu
 il75xzcUJFnDGY0blvg5wYcCKofRDCiAia3HsHT3jh1gX7rWoGJVxOP
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use dev_err_probe() to simplify probe() error handling. While at it, add
some error log in case we fail to get clkin.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/frequency/adf4371.c | 18 ++++++++----------
 1 file changed, 8 insertions(+), 10 deletions(-)

diff --git a/drivers/iio/frequency/adf4371.c b/drivers/iio/frequency/adf4371.c
index 45c8398a45d0..d752507e0c98 100644
--- a/drivers/iio/frequency/adf4371.c
+++ b/drivers/iio/frequency/adf4371.c
@@ -4,6 +4,7 @@
  *
  * Copyright 2019 Analog Devices Inc.
  */
+#include "linux/dev_printk.h"
 #include <linux/bitfield.h>
 #include <linux/clk.h>
 #include <linux/device.h>
@@ -554,11 +555,9 @@ static int adf4371_probe(struct spi_device *spi)
 		return -ENOMEM;
 
 	regmap = devm_regmap_init_spi(spi, &adf4371_regmap_config);
-	if (IS_ERR(regmap)) {
-		dev_err(&spi->dev, "Error initializing spi regmap: %ld\n",
-			PTR_ERR(regmap));
-		return PTR_ERR(regmap);
-	}
+	if (IS_ERR(regmap))
+		return dev_err_probe(&spi->dev, PTR_ERR(regmap),
+				     "Error initializing spi regmap\n");
 
 	st = iio_priv(indio_dev);
 	st->spi = spi;
@@ -577,15 +576,14 @@ static int adf4371_probe(struct spi_device *spi)
 
 	clkin = devm_clk_get_enabled(&spi->dev, "clkin");
 	if (IS_ERR(clkin))
-		return PTR_ERR(clkin);
+		return dev_err_probe(&spi->dev, PTR_ERR(clkin),
+				     "Failed to get clkin\n");
 
 	st->clkin_freq = clk_get_rate(clkin);
 
 	ret = adf4371_setup(st);
-	if (ret < 0) {
-		dev_err(&spi->dev, "ADF4371 setup failed\n");
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(&spi->dev, ret, "ADF4371 setup failed\n");
 
 	return devm_iio_device_register(&spi->dev, indio_dev);
 }

-- 
2.46.1

