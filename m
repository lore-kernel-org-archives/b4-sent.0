From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 12 May 2026 12:57:22 +0200
Subject: [PATCH v2 02/10] iio: light: opt3001: make headers conform to iwyu
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-opt3001-cleanup-v2-2-8018cf3a8a0a@gmail.com>
References: <20260512-opt3001-cleanup-v2-0-8018cf3a8a0a@gmail.com>
In-Reply-To: <20260512-opt3001-cleanup-v2-0-8018cf3a8a0a@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Alexander Koch <mail@alexanderkoch.net>, 
 Michael Hornung <mhornung.linux@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778583471; l=1404;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=ijeiUs5HBQdNjkWh4WwS9ZTfUT28aBbKAdKEloUkhy8=;
 b=lakw/ozJZMdiTR1Qbov+ph0nozd1LImRurYgk4l4JQN0i5KH1A/gVh40gXV4RjTVX8FkLegEN
 I+rmj16iR5pDTuMdTK086ctOFE5KBYjY94rQd2UjRB5jWm7og3Uh/l2
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
index 3c79e0c4ca32fedf33e318d047d6ab3f62b6c03b..7efd92875c3f8c86b00a8aff8fab664457399983 100644
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

