From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 05 May 2026 13:45:57 +0200
Subject: [PATCH v5 01/18] iio: magnetometer: ak8975: sort headers
 alphabetically
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260505-magnetometer-fixes-v5-1-831b9b5550fc@gmail.com>
References: <20260505-magnetometer-fixes-v5-0-831b9b5550fc@gmail.com>
In-Reply-To: <20260505-magnetometer-fixes-v5-0-831b9b5550fc@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777981558; l=1542;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=ifC04FwraxdTSdGAo9jIXh6jMIMFxT5mVabPgLPFhPM=;
 b=JP0N5GLtTNzsJeZEjiK8ZoTjo6aSOZnFtmfohwVm/Y3hKL+nPqM/yyC9PsbhlFDAWz6dcVtYW
 GTFwNtlUOKbBhNfwz7rdhJ+ytWoFkrcuylZsEQxBiZgGBwJkdgLbiWf
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sort include headers alphabetically to improve coding style and
readability.

No functional change.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index 44782c26698bcac5ebfc62ce3740f361078fd0ce..569cd6fa839aec6ee8758a261d0e659fc20131c6 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -7,23 +7,23 @@
  * Copyright (c) 2010, NVIDIA Corporation.
  */
 
-#include <linux/module.h>
-#include <linux/mod_devicetable.h>
-#include <linux/kernel.h>
-#include <linux/slab.h>
+#include <linux/bitops.h>
+#include <linux/delay.h>
+#include <linux/err.h>
+#include <linux/gpio/consumer.h>
 #include <linux/i2c.h>
 #include <linux/interrupt.h>
-#include <linux/err.h>
+#include <linux/kernel.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
 #include <linux/mutex.h>
-#include <linux/delay.h>
-#include <linux/bitops.h>
-#include <linux/gpio/consumer.h>
-#include <linux/regulator/consumer.h>
 #include <linux/pm_runtime.h>
+#include <linux/regulator/consumer.h>
+#include <linux/slab.h>
 
+#include <linux/iio/buffer.h>
 #include <linux/iio/iio.h>
 #include <linux/iio/sysfs.h>
-#include <linux/iio/buffer.h>
 #include <linux/iio/trigger.h>
 #include <linux/iio/trigger_consumer.h>
 #include <linux/iio/triggered_buffer.h>

-- 
2.47.3

