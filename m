From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 25 Jun 2026 14:24:52 +0200
Subject: [PATCH v4 1/2] iio: imu: inv_icm42600: reorder all driver headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-inv-icm42600-add-buffer-hwfifo_attributes-v4-1-8b4c8bfa96d7@tdk.com>
References: <20260625-inv-icm42600-add-buffer-hwfifo_attributes-v4-0-8b4c8bfa96d7@tdk.com>
In-Reply-To: <20260625-inv-icm42600-add-buffer-hwfifo_attributes-v4-0-8b4c8bfa96d7@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782390310; l=7887;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=dqJTKh2aunfRO+/DEMHAfa8LgIQtEsznlvfnJJptMOw=;
 b=W4DlU9sb39Yfsr4uGPtShZFkkdajI7idx8cgw2+bRYC21RRVIdXUE+7VkcuQziq+l2VOkVo3s
 EpE8BwWnnSiBfgTdMRuw86fYuzFExx8tfALmzSWU3hZGxnoA7blTxET
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reorder headers includes following linux rules.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600.h        |  8 +++++---
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c  | 13 +++++++------
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c |  7 ++++---
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h |  2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c   | 12 ++++++------
 drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c   | 11 ++++++-----
 drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c    |  8 ++++----
 drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c    |  8 ++++----
 drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c   |  3 ++-
 9 files changed, 39 insertions(+), 33 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600.h b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
index c8b48a5c5ed0..2ab863c9d53a 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600.h
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
@@ -6,13 +6,15 @@
 #ifndef INV_ICM42600_H_
 #define INV_ICM42600_H_
 
-#include <linux/bits.h>
 #include <linux/bitfield.h>
-#include <linux/regmap.h>
+#include <linux/bits.h>
 #include <linux/mutex.h>
-#include <linux/regulator/consumer.h>
 #include <linux/pm.h>
+#include <linux/regmap.h>
+#include <linux/regulator/consumer.h>
+
 #include <linux/iio/iio.h>
+
 #include <linux/iio/common/inv_sensors_timestamp.h>
 
 #include "inv_icm42600_buffer.h"
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
index 532d5fdffaf8..87471e8c9bc7 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
@@ -3,25 +3,26 @@
  * Copyright (C) 2020 Invensense, Inc.
  */
 
-#include <linux/kernel.h>
+#include <linux/delay.h>
 #include <linux/device.h>
+#include <linux/kernel.h>
+#include <linux/math64.h>
+#include <linux/minmax.h>
 #include <linux/mutex.h>
 #include <linux/pm_runtime.h>
 #include <linux/regmap.h>
-#include <linux/delay.h>
-#include <linux/math64.h>
-#include <linux/minmax.h>
 #include <linux/units.h>
 
 #include <linux/iio/buffer.h>
-#include <linux/iio/common/inv_sensors_timestamp.h>
 #include <linux/iio/events.h>
 #include <linux/iio/iio.h>
 #include <linux/iio/kfifo_buf.h>
 
+#include <linux/iio/common/inv_sensors_timestamp.h>
+
 #include "inv_icm42600.h"
-#include "inv_icm42600_temp.h"
 #include "inv_icm42600_buffer.h"
+#include "inv_icm42600_temp.h"
 
 #define INV_ICM42600_ACCEL_CHAN(_modifier, _index, _ext_info)		\
 	{								\
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
index 68a395758031..26817158ec78 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
@@ -3,18 +3,19 @@
  * Copyright (C) 2020 Invensense, Inc.
  */
 
-#include <linux/kernel.h>
+#include <linux/delay.h>
 #include <linux/device.h>
+#include <linux/kernel.h>
 #include <linux/minmax.h>
 #include <linux/mutex.h>
 #include <linux/pm_runtime.h>
 #include <linux/regmap.h>
-#include <linux/delay.h>
 
 #include <linux/iio/buffer.h>
-#include <linux/iio/common/inv_sensors_timestamp.h>
 #include <linux/iio/iio.h>
 
+#include <linux/iio/common/inv_sensors_timestamp.h>
+
 #include "inv_icm42600.h"
 #include "inv_icm42600_buffer.h"
 
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h
index ffca4da1e249..6ab1eb1a0051 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h
@@ -6,8 +6,8 @@
 #ifndef INV_ICM42600_BUFFER_H_
 #define INV_ICM42600_BUFFER_H_
 
-#include <linux/kernel.h>
 #include <linux/bits.h>
+#include <linux/kernel.h>
 
 struct inv_icm42600_state;
 
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
index 76eb22488e5f..dc97d8a274e3 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
@@ -3,18 +3,18 @@
  * Copyright (C) 2020 Invensense, Inc.
  */
 
-#include <linux/kernel.h>
-#include <linux/device.h>
-#include <linux/module.h>
-#include <linux/slab.h>
 #include <linux/delay.h>
-#include <linux/mutex.h>
+#include <linux/device.h>
 #include <linux/interrupt.h>
 #include <linux/irq.h>
-#include <linux/regulator/consumer.h>
+#include <linux/kernel.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
 #include <linux/pm_runtime.h>
 #include <linux/property.h>
 #include <linux/regmap.h>
+#include <linux/regulator/consumer.h>
+#include <linux/slab.h>
 
 #include <linux/iio/iio.h>
 
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
index 11339ddf1da3..ea8aa64a3f33 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
@@ -3,22 +3,23 @@
  * Copyright (C) 2020 Invensense, Inc.
  */
 
-#include <linux/kernel.h>
+#include <linux/delay.h>
 #include <linux/device.h>
+#include <linux/kernel.h>
+#include <linux/math64.h>
 #include <linux/mutex.h>
 #include <linux/pm_runtime.h>
 #include <linux/regmap.h>
-#include <linux/delay.h>
-#include <linux/math64.h>
 
 #include <linux/iio/buffer.h>
-#include <linux/iio/common/inv_sensors_timestamp.h>
 #include <linux/iio/iio.h>
 #include <linux/iio/kfifo_buf.h>
 
+#include <linux/iio/common/inv_sensors_timestamp.h>
+
 #include "inv_icm42600.h"
-#include "inv_icm42600_temp.h"
 #include "inv_icm42600_buffer.h"
+#include "inv_icm42600_temp.h"
 
 #define INV_ICM42600_GYRO_CHAN(_modifier, _index, _ext_info)		\
 	{								\
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c
index 99d37ac53bbe..f422523207ee 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c
@@ -3,13 +3,13 @@
  * Copyright (C) 2020 InvenSense, Inc.
  */
 
-#include <linux/kernel.h>
 #include <linux/device.h>
-#include <linux/module.h>
-#include <linux/mod_devicetable.h>
 #include <linux/i2c.h>
-#include <linux/regmap.h>
+#include <linux/kernel.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
 #include <linux/property.h>
+#include <linux/regmap.h>
 
 #include "inv_icm42600.h"
 
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c
index 13e2e7d38638..ec8dac9f24aa 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c
@@ -3,13 +3,13 @@
  * Copyright (C) 2020 InvenSense, Inc.
  */
 
-#include <linux/kernel.h>
 #include <linux/device.h>
-#include <linux/module.h>
+#include <linux/kernel.h>
 #include <linux/mod_devicetable.h>
-#include <linux/spi/spi.h>
-#include <linux/regmap.h>
+#include <linux/module.h>
 #include <linux/property.h>
+#include <linux/regmap.h>
+#include <linux/spi/spi.h>
 
 #include "inv_icm42600.h"
 
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c
index 727b03d541a5..7f80bda471c3 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c
@@ -3,11 +3,12 @@
  * Copyright (C) 2020 Invensense, Inc.
  */
 
-#include <linux/kernel.h>
 #include <linux/device.h>
+#include <linux/kernel.h>
 #include <linux/mutex.h>
 #include <linux/pm_runtime.h>
 #include <linux/regmap.h>
+
 #include <linux/iio/iio.h>
 
 #include "inv_icm42600.h"

-- 
2.54.0

