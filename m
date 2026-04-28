From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 28 Apr 2026 18:02:20 +0100
Subject: [PATCH v3 05/11] iio: dac: ad5686: refactor include headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-ad5686-fixes-v3-5-9cff7bd67a15@analog.com>
References: <20260428-ad5686-fixes-v3-0-9cff7bd67a15@analog.com>
In-Reply-To: <20260428-ad5686-fixes-v3-0-9cff7bd67a15@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Stefan Popa <stefan.popa@analog.com>, Jonathan Cameron <jic23@cam.ac.uk>, 
 Greg Kroah-Hartman <gregkh@suse.de>, 
 Michael Auchter <michael.auchter@ni.com>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777395737; l=2747;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=/NgJQWWQpqiJn15++sviD7O4LcVLZHbwU27WAPG7JPY=;
 b=emxNeb+hCenwPsJSuNPqLVudkqZppR+16jo6SgXqy9uV7Kvl1Xp0Gss6n/XiwQZy9gKXcfvhw
 EoXNZLg6hh7BTwI6TDEi7HOiQpEzYeksUIulUwFCYxj07QZ7EAwTn9X
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apply IWYU principle, replacing unused/generic headers for
specific/missing headers. The resulting include directive lists are sorted
accordingly.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686-spi.c |  9 +++++++--
 drivers/iio/dac/ad5686.c     | 11 ++++-------
 drivers/iio/dac/ad5686.h     |  5 ++---
 drivers/iio/dac/ad5696-i2c.c | 10 +++++++---
 4 files changed, 20 insertions(+), 15 deletions(-)

diff --git a/drivers/iio/dac/ad5686-spi.c b/drivers/iio/dac/ad5686-spi.c
index df8619e0c092..695125238633 100644
--- a/drivers/iio/dac/ad5686-spi.c
+++ b/drivers/iio/dac/ad5686-spi.c
@@ -8,11 +8,16 @@
  * Copyright 2018 Analog Devices Inc.
  */
 
-#include "ad5686.h"
-
+#include <linux/array_size.h>
+#include <linux/err.h>
+#include <linux/mod_devicetable.h>
 #include <linux/module.h>
 #include <linux/spi/spi.h>
 
+#include <asm/byteorder.h>
+
+#include "ad5686.h"
+
 static int ad5686_spi_write(struct ad5686_state *st,
 			    u8 cmd, u8 addr, u16 val)
 {
diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index b31d0ec5415c..70d61ed29aa8 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -5,17 +5,14 @@
  * Copyright 2011 Analog Devices Inc.
  */
 
-#include <linux/interrupt.h>
-#include <linux/fs.h>
-#include <linux/device.h>
+#include <linux/array_size.h>
+#include <linux/err.h>
+#include <linux/export.h>
 #include <linux/module.h>
-#include <linux/kernel.h>
-#include <linux/slab.h>
-#include <linux/sysfs.h>
 #include <linux/regulator/consumer.h>
+#include <linux/sysfs.h>
 
 #include <linux/iio/iio.h>
-#include <linux/iio/sysfs.h>
 
 #include "ad5686.h"
 
diff --git a/drivers/iio/dac/ad5686.h b/drivers/iio/dac/ad5686.h
index 36e16c5c4581..d08160e7fad9 100644
--- a/drivers/iio/dac/ad5686.h
+++ b/drivers/iio/dac/ad5686.h
@@ -8,10 +8,9 @@
 #ifndef __DRIVERS_IIO_DAC_AD5686_H__
 #define __DRIVERS_IIO_DAC_AD5686_H__
 
-#include <linux/types.h>
-#include <linux/cache.h>
+#include <linux/bits.h>
 #include <linux/mutex.h>
-#include <linux/kernel.h>
+#include <linux/types.h>
 
 #include <linux/iio/iio.h>
 
diff --git a/drivers/iio/dac/ad5696-i2c.c b/drivers/iio/dac/ad5696-i2c.c
index d3327bca0e07..e7e1b8a6fc71 100644
--- a/drivers/iio/dac/ad5696-i2c.c
+++ b/drivers/iio/dac/ad5696-i2c.c
@@ -7,10 +7,14 @@
  * Copyright 2018 Analog Devices Inc.
  */
 
-#include "ad5686.h"
-
-#include <linux/module.h>
+#include <linux/err.h>
 #include <linux/i2c.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+
+#include <asm/byteorder.h>
+
+#include "ad5686.h"
 
 static int ad5686_i2c_read(struct ad5686_state *st, u8 addr)
 {

-- 
2.43.0

