From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Thu, 30 Apr 2026 17:04:25 +0200
Subject: [PATCH v4 5/8] iio: light: si1133: add missing include headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260430-si1133-checkup-v4-5-fb3e9dce41bf@gmail.com>
References: <20260430-si1133-checkup-v4-0-fb3e9dce41bf@gmail.com>
In-Reply-To: <20260430-si1133-checkup-v4-0-fb3e9dce41bf@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777561514; l=1199;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=62tqivdanwU9bEEYOUM+cBHwVivEihI2W+qJmLI5wfU=;
 b=sfYT1TwUhCwjnHHGpn/6qT2nVJ+rQlJIsU2HqlAf0ijPObiKk3/DqssZiKpW+d/UNrXGsMIf9
 6MBKNaKCgDtCx2uJP2MMCAvc1LPHCtKh+Diui8q9udaIuQvOKkGCVDB
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
index 9abc0a7e2ecf0d2fb1bd3af88eb675e9f1be4665..ab66a5a9ffb4a89bbba7474b6e984ddb61cfeebe 100644
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
+#include <linux/jiffies.h>
+#include <linux/math.h>
+#include <linux/mod_devicetable.h>
 #include <linux/module.h>
+#include <linux/mutex.h>
 #include <linux/regmap.h>
+#include <linux/types.h>
 
 #include <linux/iio/iio.h>
 #include <linux/iio/sysfs.h>

-- 
2.47.3

