From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Mon, 12 May 2025 15:46:46 +0100
Subject: [PATCH v5 3/7] include: linux: move adi-axi-common.h out of fpga
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250512-dev-axi-clkgen-limits-v5-3-a86b9a368e05@analog.com>
References: <20250512-dev-axi-clkgen-limits-v5-0-a86b9a368e05@analog.com>
In-Reply-To: <20250512-dev-axi-clkgen-limits-v5-0-a86b9a368e05@analog.com>
To: linux-clk@vger.kernel.org, linux-fpga@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-iio@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-spi@vger.kernel.org
Cc: Stephen Boyd <sboyd@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Moritz Fischer <mdf@kernel.org>, Wu Hao <hao.wu@intel.com>, 
 Xu Yilun <yilun.xu@intel.com>, Tom Rix <trix@redhat.com>, 
 Vinod Koul <vkoul@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Trevor Gamblin <tgamblin@baylibre.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Mark Brown <broonie@kernel.org>, 
 Mike Turquette <mturquette@linaro.org>, Xu Yilun <yilun.xu@linux.intel.com>, 
 Jonathan Cameron <Jonathan.Cameron@huawei.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747061206; l=5316;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=mZpbKU1HpaoNJwEl762s/lHmHssmUWkIC/kfsyk1Mvc=;
 b=DMv0wwuKTdGaMV1zCoTRwmJu5MbDefimnulW/vXacmNeJj4ien8jhIJsJPRNlig+YEJXD2+qg
 5p3MSKBT5jCAOWfmq5fS+qFi8gCzL1K+ETnb8os/CC5UeyBa4l3eajg
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The adi-axi-common.h header has some common defines used in various ADI
IPs. However they are not specific for any fpga manager so it's
questionable for the header to live under include/linux/fpga. Hence
let's just move one directory up and update all users.

Suggested-by: Xu Yilun <yilun.xu@linux.intel.com>
Acked-by: Xu Yilun <yilun.xu@intel.com>
Acked-by: Jonathan Cameron <Jonathan.Cameron@huawei.com> # for IIO
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/clk/clk-axi-clkgen.c              | 2 ++
 drivers/dma/dma-axi-dmac.c                | 2 +-
 drivers/hwmon/axi-fan-control.c           | 2 +-
 drivers/iio/adc/adi-axi-adc.c             | 3 +--
 drivers/iio/dac/adi-axi-dac.c             | 2 +-
 drivers/pwm/pwm-axi-pwmgen.c              | 2 +-
 drivers/spi/spi-axi-spi-engine.c          | 2 +-
 include/linux/{fpga => }/adi-axi-common.h | 0
 8 files changed, 8 insertions(+), 7 deletions(-)

diff --git a/drivers/clk/clk-axi-clkgen.c b/drivers/clk/clk-axi-clkgen.c
index 2a95f9b220234a1245024a821c50e1eb9c104ac9..31915f8f5565f2ef5d17c0b4a0c91a648005b3e6 100644
--- a/drivers/clk/clk-axi-clkgen.c
+++ b/drivers/clk/clk-axi-clkgen.c
@@ -16,6 +16,8 @@
 #include <linux/mod_devicetable.h>
 #include <linux/err.h>
 
+#include <linux/adi-axi-common.h>
+
 #define AXI_CLKGEN_V2_REG_RESET		0x40
 #define AXI_CLKGEN_V2_REG_CLKSEL	0x44
 #define AXI_CLKGEN_V2_REG_DRP_CNTRL	0x70
diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index 36943b0c6d603cbe38606b0d7bde02535f529a9a..5b06b0dc67ee12017c165bf815fb7c0e1bf5abd8 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -6,6 +6,7 @@
  *  Author: Lars-Peter Clausen <lars@metafoo.de>
  */
 
+#include <linux/adi-axi-common.h>
 #include <linux/bitfield.h>
 #include <linux/clk.h>
 #include <linux/device.h>
@@ -22,7 +23,6 @@
 #include <linux/platform_device.h>
 #include <linux/regmap.h>
 #include <linux/slab.h>
-#include <linux/fpga/adi-axi-common.h>
 
 #include <dt-bindings/dma/axi-dmac.h>
 
diff --git a/drivers/hwmon/axi-fan-control.c b/drivers/hwmon/axi-fan-control.c
index 35c862eb158b0909dac64c2e9f51f0f9f0e8bf72..b7bb325c3ad966ed2a93be4dfbf4e20661568509 100644
--- a/drivers/hwmon/axi-fan-control.c
+++ b/drivers/hwmon/axi-fan-control.c
@@ -4,9 +4,9 @@
  *
  * Copyright 2019 Analog Devices Inc.
  */
+#include <linux/adi-axi-common.h>
 #include <linux/bits.h>
 #include <linux/clk.h>
-#include <linux/fpga/adi-axi-common.h>
 #include <linux/hwmon.h>
 #include <linux/hwmon-sysfs.h>
 #include <linux/interrupt.h>
diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index c7357601f0f869e57636f00bb1e26c059c3ab15c..87fa18f1ec96782556bdfad08bedb5e7549fb93d 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -6,6 +6,7 @@
  * Copyright 2012-2020 Analog Devices Inc.
  */
 
+#include <linux/adi-axi-common.h>
 #include <linux/bitfield.h>
 #include <linux/cleanup.h>
 #include <linux/clk.h>
@@ -20,8 +21,6 @@
 #include <linux/regmap.h>
 #include <linux/slab.h>
 
-#include <linux/fpga/adi-axi-common.h>
-
 #include <linux/iio/backend.h>
 #include <linux/iio/buffer-dmaengine.h>
 #include <linux/iio/buffer.h>
diff --git a/drivers/iio/dac/adi-axi-dac.c b/drivers/iio/dac/adi-axi-dac.c
index b143f7ed6847277aeb49094627d90e5d95eed71c..581a2fe55a7fb35f1a03f96f3a0e95421d1583e7 100644
--- a/drivers/iio/dac/adi-axi-dac.c
+++ b/drivers/iio/dac/adi-axi-dac.c
@@ -5,6 +5,7 @@
  *
  * Copyright 2016-2024 Analog Devices Inc.
  */
+#include <linux/adi-axi-common.h>
 #include <linux/bitfield.h>
 #include <linux/bits.h>
 #include <linux/cleanup.h>
@@ -23,7 +24,6 @@
 #include <linux/regmap.h>
 #include <linux/units.h>
 
-#include <linux/fpga/adi-axi-common.h>
 #include <linux/iio/backend.h>
 #include <linux/iio/buffer-dmaengine.h>
 #include <linux/iio/buffer.h>
diff --git a/drivers/pwm/pwm-axi-pwmgen.c b/drivers/pwm/pwm-axi-pwmgen.c
index 4259a0db9ff45808eecae28680473292d165d1f6..e720191e74558d15f1b04fa18cf2984299f88809 100644
--- a/drivers/pwm/pwm-axi-pwmgen.c
+++ b/drivers/pwm/pwm-axi-pwmgen.c
@@ -18,10 +18,10 @@
  * - Supports normal polarity. Does not support changing polarity.
  * - On disable, the PWM output becomes low (inactive).
  */
+#include <linux/adi-axi-common.h>
 #include <linux/bits.h>
 #include <linux/clk.h>
 #include <linux/err.h>
-#include <linux/fpga/adi-axi-common.h>
 #include <linux/io.h>
 #include <linux/minmax.h>
 #include <linux/module.h>
diff --git a/drivers/spi/spi-axi-spi-engine.c b/drivers/spi/spi-axi-spi-engine.c
index 7c252126b33ea83fe6a6e80c6cb87499243069f5..d498132f1ff6adf20639bf4a21f1687903934bec 100644
--- a/drivers/spi/spi-axi-spi-engine.c
+++ b/drivers/spi/spi-axi-spi-engine.c
@@ -5,9 +5,9 @@
  *  Author: Lars-Peter Clausen <lars@metafoo.de>
  */
 
+#include <linux/adi-axi-common.h>
 #include <linux/clk.h>
 #include <linux/completion.h>
-#include <linux/fpga/adi-axi-common.h>
 #include <linux/interrupt.h>
 #include <linux/io.h>
 #include <linux/of.h>
diff --git a/include/linux/fpga/adi-axi-common.h b/include/linux/adi-axi-common.h
similarity index 100%
rename from include/linux/fpga/adi-axi-common.h
rename to include/linux/adi-axi-common.h

-- 
2.49.0

