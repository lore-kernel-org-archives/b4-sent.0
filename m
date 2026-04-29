From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Wed, 29 Apr 2026 17:04:51 +0200
Subject: [PATCH v3 3/8] iio: light: si1133: add missing include headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-si1133-checkup-v3-3-469f21d960eb@gmail.com>
References: <20260429-si1133-checkup-v3-0-469f21d960eb@gmail.com>
In-Reply-To: <20260429-si1133-checkup-v3-0-469f21d960eb@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777475147; l=1193;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=OWle6DMZJq2w2RARzbyed/7OgweWtx5OkO036pgenT0=;
 b=1nk+G3fThs90hmUvMW0haSI5r1UjL8V18mpb30LWGYtqSMrSBuIQKRzJfKBP2vCidOmOYBnSu
 H+ZLOm564PGD3dIyMdrQI63Sv+ecomBQyKV5ul0qjg94HJP9M3xIhPf
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add missing include headers to prevent compilation relying on transient
dependencies (array_size.h, bitops.h, completion.h, dev_printk.h, err.h,
irqreturn.h, jiffies.h, math.h, mutex.h, types.h).

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/si1133.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/iio/light/si1133.c b/drivers/iio/light/si1133.c
index 136436c0379aa732a2c93d40b08734ae4fc2a45f..dabb1aae05535313e77441b7d066bce931de79f9 100644
--- a/drivers/iio/light/si1133.c
+++ b/drivers/iio/light/si1133.c
@@ -6,11 +6,21 @@
  * Copyright 2018 Maxime Roussin-Belanger <maxime.roussinbelanger@gmail.com>
  */
 
+#include <linux/array_size.h>
+#include <linux/bitops.h>
+#include <linux/completion.h>
 #include <linux/delay.h>
+#include <linux/dev_printk.h>
+#include <linux/err.h>
 #include <linux/i2c.h>
 #include <linux/interrupt.h>
+#include <linux/irqreturn.h>
+#include <linux/jiffies.h>
+#include <linux/math.h>
 #include <linux/module.h>
+#include <linux/mutex.h>
 #include <linux/regmap.h>
+#include <linux/types.h>
 
 #include <linux/iio/iio.h>
 #include <linux/iio/sysfs.h>

-- 
2.47.3

