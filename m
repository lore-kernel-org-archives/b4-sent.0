From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 04 May 2026 11:48:14 +0200
Subject: [PATCH v4 02/17] iio: magnetometer: ak8975: update headers per
 IWYU principle
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-magnetometer-fixes-v4-2-a291c2a7c71a@gmail.com>
References: <20260504-magnetometer-fixes-v4-0-a291c2a7c71a@gmail.com>
In-Reply-To: <20260504-magnetometer-fixes-v4-0-a291c2a7c71a@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777888111; l=1776;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=BdAwGxFbW7o2amP8FH9H+4YQxsDM8p5KHZL35H1tc4w=;
 b=gCXO8QDFJElmD8P9ntRVSiZLMIYN8dNWWacyJf210PxdmVwIlpTOt5TFyWw8chMlsh2RThDb4
 0rWRC8dyGPyDT0iEprTHYtWmrh/+xPmkbg8KKB2YFLNm16I0+5+iDrr
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove kernel.h proxy header and unused headers (slab.h, iio/sysfs.h,
iio/trigger.h). Add missing headers to ensure atomicity (array_size.h,
dev_printk.h, asm/byteorder.h, irqreturn.h, minmax.h, property.h,
types.h, wait.h).

Audited using the include-what-you-use tool.

Co-developed-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index 569cd6fa839aec6ee8758a261d0e659fc20131c6..dac0a90c33eebd43f8aeed846c9cbf5fd1a6ab91 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -7,24 +7,29 @@
  * Copyright (c) 2010, NVIDIA Corporation.
  */
 
+#include <linux/array_size.h>
 #include <linux/bitops.h>
 #include <linux/delay.h>
+#include <linux/dev_printk.h>
 #include <linux/err.h>
 #include <linux/gpio/consumer.h>
 #include <linux/i2c.h>
 #include <linux/interrupt.h>
-#include <linux/kernel.h>
+#include <linux/iopoll.h>
+#include <linux/minmax.h>
 #include <linux/mod_devicetable.h>
 #include <linux/module.h>
 #include <linux/mutex.h>
 #include <linux/pm_runtime.h>
+#include <linux/property.h>
 #include <linux/regulator/consumer.h>
-#include <linux/slab.h>
+#include <linux/types.h>
+#include <linux/wait.h>
+
+#include <asm/byteorder.h>
 
 #include <linux/iio/buffer.h>
 #include <linux/iio/iio.h>
-#include <linux/iio/sysfs.h>
-#include <linux/iio/trigger.h>
 #include <linux/iio/trigger_consumer.h>
 #include <linux/iio/triggered_buffer.h>
 

-- 
2.47.3

