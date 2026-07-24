From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 24 Jul 2026 13:03:13 +0100
Subject: [PATCH v2 3/6] iio: dac: ad5686: refactor device list and file
 header comments
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-ad5686-extend-dev-support-v2-3-cfc2b30ce988@analog.com>
References: <20260724-ad5686-extend-dev-support-v2-0-cfc2b30ce988@analog.com>
In-Reply-To: <20260724-ad5686-extend-dev-support-v2-0-cfc2b30ce988@analog.com>
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784894592; l=3788;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=o2YHmFSPNHfxwtoVvwK2R8/4/1vdStVyZFyqOCVnCto=;
 b=TfN4fMrTTF+iXIVpK9r0Y8PZN/XKQtGNiNkvoYlEUsbXWqHIod7XwG48s4T59lAp3iIlUZSDP
 VUi0NYXfByYB/Lqt2x/B6rSjWqZzQDjHdMp2bwBERv35pp2LX0JydNG
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactor device list in Kconfig, sorting devices by channel count. Also,
remove device description from file headers. One can rely on the ID
table(s) to check for supported devices. AD5337R is ommited as it does
not seem to exist, i.e. its documentation could not be found.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/Kconfig      | 29 ++++++++++++++++++++++-------
 drivers/iio/dac/ad5686-spi.c |  5 +----
 drivers/iio/dac/ad5686.c     |  2 +-
 drivers/iio/dac/ad5696-i2c.c |  4 +---
 4 files changed, 25 insertions(+), 15 deletions(-)

diff --git a/drivers/iio/dac/Kconfig b/drivers/iio/dac/Kconfig
index d6d560c09e25..3ae997939ff5 100644
--- a/drivers/iio/dac/Kconfig
+++ b/drivers/iio/dac/Kconfig
@@ -251,9 +251,16 @@ config AD5686_SPI
 	depends on SPI
 	select AD5686
 	help
-	  Say yes here to build support for Analog Devices AD5672R, AD5674R,
-	  AD5676, AD5676R, AD5679R, AD5684, AD5684R, AD5684R, AD5685R, AD5686,
-	  AD5686R Voltage Output Digital to Analog Converter.
+	  Say yes here to build support for Analog Devices Voltage Output
+	  Digital to Analog Converters:
+	  - Single-channel:
+	    AD5310R, AD5681R, AD5682R, AD5683, AD5683R
+	  - Quad-channel:
+	    AD5684, AD5684R, AD5685R, AD5686, AD5686R
+	  - 8-channel:
+	    AD5672R, AD5676, AD5676R
+	  - 16-channel:
+	    AD5674R, AD5679R
 
 	  To compile this driver as a module, choose M here: the
 	  module will be called ad5686.
@@ -263,10 +270,18 @@ config AD5696_I2C
 	depends on I2C
 	select AD5686
 	help
-	  Say yes here to build support for Analog Devices AD5311R, AD5337,
-	  AD5338R, AD5671R, AD5673R, AD5675R, AD5677R, AD5691R, AD5692R, AD5693,
-	  AD5693R, AD5694, AD5694R, AD5695R, AD5696, and AD5696R Digital to
-	  Analog converters.
+	  Say yes here to build support for Analog Devices Voltage Output
+	  Digital to Analog Converters:
+	  - Single-channel:
+	    AD5311R, AD5691R, AD5692R, AD5693, AD5693R
+	  - Dual-channel:
+	    AD5338R
+	  - Quad-channel:
+	    AD5694, AD5694R, AD5695R, AD5696, AD5696R
+	  - 8-channel:
+	    AD5671R, AD5675R
+	  - 16-channel:
+	    AD5673R, AD5677R
 
 	  To compile this driver as a module, choose M here: the module will be
 	  called ad5696.
diff --git a/drivers/iio/dac/ad5686-spi.c b/drivers/iio/dac/ad5686-spi.c
index 227ddb269669..2689d66c7c20 100644
--- a/drivers/iio/dac/ad5686-spi.c
+++ b/drivers/iio/dac/ad5686-spi.c
@@ -1,9 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0
 /*
- * AD5672R, AD5674R, AD5676, AD5676R, AD5679R,
- * AD5681R, AD5682R, AD5683, AD5683R, AD5684,
- * AD5684R, AD5685R, AD5686, AD5686R
- * Digital to analog converters driver
+ * SPI driver for AD5686 and similar Digital to Analog Converters
  *
  * Copyright 2018 Analog Devices Inc.
  */
diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 873dfb5b9107..e2beba6d54b1 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -1,6 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0
 /*
- * AD5686R, AD5685R, AD5684R Digital to analog converters  driver
+ * Core driver for AD5686 and similar Digital to Analog Converters
  *
  * Copyright 2011 Analog Devices Inc.
  */
diff --git a/drivers/iio/dac/ad5696-i2c.c b/drivers/iio/dac/ad5696-i2c.c
index 4ddf2e151d47..4a249f9cdb8f 100644
--- a/drivers/iio/dac/ad5696-i2c.c
+++ b/drivers/iio/dac/ad5696-i2c.c
@@ -1,8 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0
 /*
- * AD5338R, AD5671R, AD5673R, AD5675R, AD5677R, AD5691R, AD5692R, AD5693,
- * AD5693R, AD5694, AD5694R, AD5695R, AD5696, AD5696R
- * Digital to analog converters driver
+ * I2C driver for AD5696 and similar Digital to Analog Converters
  *
  * Copyright 2018 Analog Devices Inc.
  */

-- 
2.43.0

