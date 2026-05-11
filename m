From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 11 May 2026 12:04:06 +0200
Subject: [PATCH 1/7] iio: light: opt3001: make headers conform to iwyu
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-opt3001-cleanup-v1-1-f7879dc3455c@gmail.com>
References: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
In-Reply-To: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778493846; l=1404;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=sYBEFSgXpCTsp4tslKj24XkY3mo8Z+wM+iHH5uIcud8=;
 b=RaQLZ5q+3Ed1Kjee8RbUjs4MNQk8sssWqDyvUiES5i/iPY67EdehWu4ZVccI0qzWGPkHXUZ/N
 Vskl+Qs5GLjA+OiR00F4GR7hetb1EExOOAxrqSZ8Gb1vYqcCYRHVHzT
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove kernel.h proxy header, device.h, irq.h, slab.h as they are
unnecessary and add missing headers (array_size.h, dev_printk.h,
errno.h, jiffies.h, wait.h) to enforce IWYU principle and reduce
transitive dependencies. Also, replace bitops.h with bits.h as only
the BIT() macro is used.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 13 +++++++------
 1 file changed, 7 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index 53bc455b7bad142695d9fecc6cabb934fb3ace0c..e6c3665f46be47129097c3997c7551ba9a8f6440 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -8,18 +8,19 @@
  * Based on previous work from: Felipe Balbi <balbi@ti.com>
  */
 
-#include <linux/bitops.h>
+#include <linux/array_size.h>
+#include <linux/bits.h>
 #include <linux/delay.h>
-#include <linux/device.h>
+#include <linux/dev_printk.h>
+#include <linux/errno.h>
 #include <linux/i2c.h>
 #include <linux/interrupt.h>
-#include <linux/irq.h>
-#include <linux/kernel.h>
-#include <linux/module.h>
+#include <linux/jiffies.h>
 #include <linux/mod_devicetable.h>
+#include <linux/module.h>
 #include <linux/mutex.h>
-#include <linux/slab.h>
 #include <linux/types.h>
+#include <linux/wait.h>
 
 #include <linux/iio/events.h>
 #include <linux/iio/iio.h>

-- 
2.47.3

