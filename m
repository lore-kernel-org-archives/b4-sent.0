From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 03 Feb 2026 11:24:12 +0000
Subject: [PATCH v3 6/9] iio: amplifiers: ad8366: sort header includes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260203-iio-ad8366-update-v3-6-5d5636b5181a@analog.com>
References: <20260203-iio-ad8366-update-v3-0-5d5636b5181a@analog.com>
In-Reply-To: <20260203-iio-ad8366-update-v3-0-5d5636b5181a@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770117857; l=1177;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=s8rA3b2H1BNCIQuGiHV+VZ+q0tCGOGK7fNQac9O3/2A=;
 b=6nC3fXTKZ6yKd6LIm5kdhd1WpXb+6nc/95oKvrPcHm5ISsHtbPa1K5gWxYdl8ecEO9Og96D8X
 pgEXHp8iuFZD5YaPCqylqB8QTeiObfXzBpxgdk014ZMYv5aFWG4Lhhn
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Alphabetically sort include directives and drop include of linux/kernel.h.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/amplifiers/ad8366.c | 18 ++++++++----------
 1 file changed, 8 insertions(+), 10 deletions(-)

diff --git a/drivers/iio/amplifiers/ad8366.c b/drivers/iio/amplifiers/ad8366.c
index 2da10c748362..40b03e417be8 100644
--- a/drivers/iio/amplifiers/ad8366.c
+++ b/drivers/iio/amplifiers/ad8366.c
@@ -11,19 +11,17 @@
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
-
+#include <linux/device.h>
+#include <linux/err.h>
+#include <linux/gpio/consumer.h>
 #include <linux/iio/iio.h>
 #include <linux/iio/sysfs.h>
+#include <linux/module.h>
+#include <linux/regulator/consumer.h>
+#include <linux/slab.h>
+#include <linux/spi/spi.h>
+#include <linux/sysfs.h>
 
 enum ad8366_type {
 	ID_AD8366,

-- 
2.43.0

