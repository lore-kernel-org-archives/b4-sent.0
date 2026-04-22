From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 22 Apr 2026 15:45:51 +0100
Subject: [PATCH 17/22] iio: dac: ad5686: update device list description
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-ad5313r-iio-support-v1-17-ed7dca001d1b@analog.com>
References: <20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com>
In-Reply-To: <20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com>
To: Jonathan Cameron <jic23@kernel.org>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Michael Auchter <michael.auchter@ni.com>, linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776869181; l=4131;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=6Itx5hy1mvB2bOEpnWldN5TFmPMjDDFuSdP09yLPaJw=;
 b=hx77HXvPzwJU7vo8vGaU4D/eefLuopDVNxdnxF3JVkfTFkGsTVywbh8Xp8uYFrTbzaB2/rr7v
 d2Rwkvie3wDCLMi4Nl5mTdltNknMmQ26qLWEGmsIHnjBOZ8nT7U3I1S
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update device list entries from comment headers for both SPI and I2C
driver files and under Kconfig help text. Adjust comment header for the
core file as supported devices are listed elsewhere. Also update Copyright
notice in comment file headers with the current year.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/Kconfig      | 16 +++++++++-------
 drivers/iio/dac/ad5686-spi.c |  8 ++++----
 drivers/iio/dac/ad5686.c     |  4 ++--
 drivers/iio/dac/ad5696-i2c.c |  7 ++++---
 4 files changed, 19 insertions(+), 16 deletions(-)

diff --git a/drivers/iio/dac/Kconfig b/drivers/iio/dac/Kconfig
index cd4870b65415..8ef4a87d6d6a 100644
--- a/drivers/iio/dac/Kconfig
+++ b/drivers/iio/dac/Kconfig
@@ -235,9 +235,11 @@ config AD5686_SPI
 	depends on SPI
 	select AD5686
 	help
-	  Say yes here to build support for Analog Devices AD5672R, AD5674R,
-	  AD5676, AD5676R, AD5679R, AD5684, AD5684R, AD5684R, AD5685R, AD5686,
-	  AD5686R Voltage Output Digital to Analog Converter.
+	  Say yes here to build support for Analog Devices AD5310R, AD5313R,
+	  AD5317R, AD5672R, AD5674, AD5674R, AD5676, AD5676R, AD5679, AD5679R,
+	  AD5681R, AD5682R, AD5683, AD5683R, AD5684, AD5684R, AD5685R, AD5686,
+	  AD5686R, AD5687, AD5687R, AD5689, AD5689R Voltage Output
+	  Digital to Analog Converter.
 
 	  To compile this driver as a module, choose M here: the
 	  module will be called ad5686.
@@ -247,10 +249,10 @@ config AD5696_I2C
 	depends on I2C
 	select AD5686
 	help
-	  Say yes here to build support for Analog Devices AD5311R, AD5337,
-	  AD5338R, AD5671R, AD5673R, AD5675R, AD5677R, AD5691R, AD5692R, AD5693,
-	  AD5693R, AD5694, AD5694R, AD5695R, AD5696, and AD5696R Digital to
-	  Analog converters.
+	  Say yes here to build support for Analog Devices AD5311R, AD5316R,
+	  AD5338R, AD5671R, AD5673R, AD5675, AD5675R, AD5677R, AD5691R, AD5692R,
+	  AD5693, AD5693R, AD5694, AD5694R, AD5695R, AD5696, AD5696R, AD5697R
+	  Digital to Analog converters.
 
 	  To compile this driver as a module, choose M here: the module will be
 	  called ad5696.
diff --git a/drivers/iio/dac/ad5686-spi.c b/drivers/iio/dac/ad5686-spi.c
index b57dc88eb953..ebfc40efa679 100644
--- a/drivers/iio/dac/ad5686-spi.c
+++ b/drivers/iio/dac/ad5686-spi.c
@@ -1,11 +1,11 @@
 // SPDX-License-Identifier: GPL-2.0
 /*
- * AD5672R, AD5674R, AD5676, AD5676R, AD5679R,
- * AD5681R, AD5682R, AD5683, AD5683R, AD5684,
- * AD5684R, AD5685R, AD5686, AD5686R
+ * AD5310R, AD5313R, AD5317R, AD5672R, AD5674, AD5674R, AD5676, AD5676R,
+ * AD5679, AD5679R, AD5681R, AD5682R, AD5683, AD5683R, AD5684, AD5684R,
+ * AD5685R, AD5686, AD5686R, AD5687, AD5687R, AD5689, AD5689R
  * Digital to analog converters driver
  *
- * Copyright 2018 Analog Devices Inc.
+ * Copyright 2018-2026 Analog Devices Inc.
  */
 
 #include <asm/byteorder.h>
diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index bb661d985626..cfbc1624e01c 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -1,8 +1,8 @@
 // SPDX-License-Identifier: GPL-2.0
 /*
- * AD5686R, AD5685R, AD5684R Digital to analog converters  driver
+ * Core driver for AD5686R and similar Digital to analog converters
  *
- * Copyright 2011 Analog Devices Inc.
+ * Copyright 2011-2026 Analog Devices Inc.
  */
 
 #include <linux/array_size.h>
diff --git a/drivers/iio/dac/ad5696-i2c.c b/drivers/iio/dac/ad5696-i2c.c
index 8fb9da7fde1f..e75c5f8c65aa 100644
--- a/drivers/iio/dac/ad5696-i2c.c
+++ b/drivers/iio/dac/ad5696-i2c.c
@@ -1,10 +1,11 @@
 // SPDX-License-Identifier: GPL-2.0
 /*
- * AD5338R, AD5671R, AD5673R, AD5675R, AD5677R, AD5691R, AD5692R, AD5693,
- * AD5693R, AD5694, AD5694R, AD5695R, AD5696, AD5696R
+ * AD5311R, AD5316R, AD5338R, AD5671R, AD5673R, AD5675, AD5675R, AD5677R,
+ * AD5691R, AD5692R, AD5693, AD5693R, AD5694, AD5694R, AD5695R, AD5696,
+ * AD5696R, AD5697R
  * Digital to analog converters driver
  *
- * Copyright 2018 Analog Devices Inc.
+ * Copyright 2018-2026 Analog Devices Inc.
  */
 
 #include <asm/byteorder.h>

-- 
2.43.0

