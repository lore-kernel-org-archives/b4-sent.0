From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Wed, 24 Jun 2026 18:21:18 +0200
Subject: [PATCH v3 1/2] iio: imu: inv_icm42600: reorder includes for buffer
 module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260624-inv-icm42600-add-buffer-hwfifo_attributes-v3-1-5d9a4c662f50@tdk.com>
References: <20260624-inv-icm42600-add-buffer-hwfifo_attributes-v3-0-5d9a4c662f50@tdk.com>
In-Reply-To: <20260624-inv-icm42600-add-buffer-hwfifo_attributes-v3-0-5d9a4c662f50@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782318086; l=1087;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=/o86TiMkszwM4dpf3wC3v+DIzyJYtoJPgWoTuGRl3jI=;
 b=FcYk9ni7DTyb0ss0gRnbqPeVl6irSAV+InRO7BAdqYnxVpoBfMiv8qvLtFUxQtsPJ7mVxCR3C
 nfp2xUgrMsFBFo9coMfIdrenLMm2lR/jMIPljdcmpHIo60tifmOK3X6
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reorder includes following rules and delete unneeded kernel.h.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
index 68a395758031..8ad6374409a9 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
@@ -3,18 +3,18 @@
  * Copyright (C) 2020 Invensense, Inc.
  */
 
-#include <linux/kernel.h>
+#include <linux/delay.h>
 #include <linux/device.h>
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
 

-- 
2.54.0

