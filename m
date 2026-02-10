From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 10 Feb 2026 19:42:03 +0000
Subject: [PATCH v4 03/11] iio: amplifiers: ad8366: remove unused include
 headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260210-iio-ad8366-update-v4-3-15505f7b15b4@analog.com>
References: <20260210-iio-ad8366-update-v4-0-15505f7b15b4@analog.com>
In-Reply-To: <20260210-iio-ad8366-update-v4-0-15505f7b15b4@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770752535; l=1638;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=CGbPKYHJlOJ9rYJnPGo0vg0Ptr//Gt2yLe6uykPVd2o=;
 b=3mPIYJQagyjOmd+0ojbhmRX/JbMX/TvzF24B3xqT5vy4n4kq+O9L0k/s4WCzVamj7hSc55pdi
 c+h4s2TTZ10BOP99kLBplrLssqY16/wSUdx07v06+ORihfZDGRxuqao
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apply IWYU principle, removing the following headers:
- linux/device.h: no usage of devm_add_action_or_reset, device_attr...
- linux/kernel.h: no usage of container_of, kasprintf, ...
- linux/slab.h: memory management handled by iio
- linux/sysfs.h: sysfs interaction is managed by iio
- linux/iio/sysfs.h: not using iio device attributes in this driver

Being a small patch, the remaining includes are alphabetically sorted.
In gcc, compiling with -H allows for dependency visualization,
which indicates that except for linux/iio/sysfs.h, all removed
headers are indirectly included by the remaining headers.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 15 +++++----------
 1 file changed, 5 insertions(+), 10 deletions(-)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index d06ac786501c..6382106ee6c7 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -11,19 +11,14 @@
  * Copyright 2012-2019 Analog Devices Inc.
  */
 
-#include <linux/device.h>
-#include <linux/kernel.h>
-#include <linux/slab.h>
-#include <linux/sysfs.h>
-#include <linux/spi/spi.h>
-#include <linux/regulator/consumer.h>
-#include <linux/gpio/consumer.h>
-#include <linux/err.h>
-#include <linux/module.h>
 #include <linux/bitrev.h>
+#include <linux/err.h>
+#include <linux/gpio/consumer.h>
+#include <linux/module.h>
+#include <linux/regulator/consumer.h>
+#include <linux/spi/spi.h>
 
 #include <linux/iio/iio.h>
-#include <linux/iio/sysfs.h>
 
 enum ad8366_type {
 	ID_AD8366,

-- 
2.43.0

