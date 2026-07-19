From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sun, 19 Jul 2026 10:52:00 +0100
Subject: [PATCH 4/4] iio: dac: ad5686: update device list and file header
 comments
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260719-ad5686-extend-dev-support-v1-4-841ec75cf5d8@analog.com>
References: <20260719-ad5686-extend-dev-support-v1-0-841ec75cf5d8@analog.com>
In-Reply-To: <20260719-ad5686-extend-dev-support-v1-0-841ec75cf5d8@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784454721; l=4144;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=g87LSQvSH5zO99f8r0mYhWdXFrEI0PIUf10Rds43rLE=;
 b=3kkX5U/Dmb4CYXRm3XMM/lysS2S6upGe2fOml1gdgoaPuEPnI9rOYVatEmXbFniPNsZR/nlbD
 TROlJfiNL6vCKJVrN+vMGP0sDKCxRh/g+SRttCu7epfqFstzxaMTFVs
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update device list entries in Kconfig and remove device description from
file headers. One can rely on the ID table(s) to check for supported
devices. Adjust comment header accordingly and update Copyright notice in
comment file headers with the current year.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/Kconfig      | 31 ++++++++++++++++++++++++-------
 drivers/iio/dac/ad5686-spi.c |  7 ++-----
 drivers/iio/dac/ad5686.c     |  4 ++--
 drivers/iio/dac/ad5696-i2c.c |  6 ++----
 4 files changed, 30 insertions(+), 18 deletions(-)

diff --git a/drivers/iio/dac/Kconfig b/drivers/iio/dac/Kconfig
index d6d560c09e25..ba2065241af3 100644
--- a/drivers/iio/dac/Kconfig
+++ b/drivers/iio/dac/Kconfig
@@ -251,9 +251,18 @@ config AD5686_SPI
 	depends on SPI
 	select AD5686
 	help
-	  Say yes here to build support for Analog Devices AD5672R, AD5674R,
-	  AD5676, AD5676R, AD5679R, AD5684, AD5684R, AD5684R, AD5685R, AD5686,
-	  AD5686R Voltage Output Digital to Analog Converter.
+	  Say yes here to build support for Analog Devices Voltage Output
+	  Digital to Analog Converters:
+	  - Single-channel:
+	    AD5310R, AD5681R, AD5682R, AD5683R, AD5683R
+	  - Dual-channel:
+	    AD5313R, AD5687, AD5687R, AD5689, AD5689R
+	  - Quad-channel:
+	    AD5317R, AD5684, AD5684R, AD5685R, AD5686, AD5686R
+	  - 8-channel:
+	    AD5672R, AD5676, AD5676R
+	  - 16-channel:
+	    AD5674, AD5674R, AD5679, AD5679R
 
 	  To compile this driver as a module, choose M here: the
 	  module will be called ad5686.
@@ -263,10 +272,18 @@ config AD5696_I2C
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
+	    AD5338R, AD5697R
+	  - Quad-channel:
+	    AD5316R, AD5694, AD5694R, AD5695R, AD5696, AD5696R
+	  - 8-channel:
+	    AD5671R, AD5675, AD5675R
+	  - 16-channel:
+	    AD5673R, AD5677R
 
 	  To compile this driver as a module, choose M here: the module will be
 	  called ad5696.
diff --git a/drivers/iio/dac/ad5686-spi.c b/drivers/iio/dac/ad5686-spi.c
index 003541edb742..b4531b49cb22 100644
--- a/drivers/iio/dac/ad5686-spi.c
+++ b/drivers/iio/dac/ad5686-spi.c
@@ -1,11 +1,8 @@
 // SPDX-License-Identifier: GPL-2.0
 /*
- * AD5672R, AD5674R, AD5676, AD5676R, AD5679R,
- * AD5681R, AD5682R, AD5683, AD5683R, AD5684,
- * AD5684R, AD5685R, AD5686, AD5686R
- * Digital to analog converters driver
+ * SPI driver for AD5686 and similar Digital to Analog Converters
  *
- * Copyright 2018 Analog Devices Inc.
+ * Copyright 2018-2026 Analog Devices Inc.
  */
 
 #include <linux/array_size.h>
diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 090707d76d6e..fc0bccfb0a03 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -1,8 +1,8 @@
 // SPDX-License-Identifier: GPL-2.0
 /*
- * AD5686R, AD5685R, AD5684R Digital to analog converters  driver
+ * Core driver for AD5686 and similar Digital to Analog Converters
  *
- * Copyright 2011 Analog Devices Inc.
+ * Copyright 2011-2026 Analog Devices Inc.
  */
 
 #include <linux/array_size.h>
diff --git a/drivers/iio/dac/ad5696-i2c.c b/drivers/iio/dac/ad5696-i2c.c
index 7254bb976388..19605274e787 100644
--- a/drivers/iio/dac/ad5696-i2c.c
+++ b/drivers/iio/dac/ad5696-i2c.c
@@ -1,10 +1,8 @@
 // SPDX-License-Identifier: GPL-2.0
 /*
- * AD5338R, AD5671R, AD5673R, AD5675R, AD5677R, AD5691R, AD5692R, AD5693,
- * AD5693R, AD5694, AD5694R, AD5695R, AD5696, AD5696R
- * Digital to analog converters driver
+ * I2C driver for AD5696 and similar Digital to Analog Converters
  *
- * Copyright 2018 Analog Devices Inc.
+ * Copyright 2018-2026 Analog Devices Inc.
  */
 
 #include <linux/bitfield.h>

-- 
2.43.0

