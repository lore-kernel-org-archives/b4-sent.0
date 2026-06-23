From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Tue, 23 Jun 2026 18:44:22 +0200
Subject: [PATCH] iio: imu: inv_icm42600: fix timestamping by limiting FIFO
 reading
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260623-inv-icm42600-fix-watermark-fifo-reading-v1-1-f3f5694a818a@tdk.com>
X-B4-Tracking: v=1; b=H4sIAOW3OmoC/yXN0QrCMAyF4VcZuTZQa63iq8guYpfOKOsknVMYe
 3ejXn5w+M8ClVW4wqlZQHmWKmMxbDcNpCuVnlE6M3jno4t+h1JmlDQEo8Msb3zRxDqQ3k15RGX
 qpPQYfUiU3dEd9gGs9lC29e/p3P5dn5cbp+mbh3X9ACkT4EqLAAAA
X-Change-ID: 20260623-inv-icm42600-fix-watermark-fifo-reading-624caf080754
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Cameron <jic23@kernel.org>, stable@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782233076; l=6594;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=3ssvSfe95gYTtmZ+Ylkig8dkoYCsEu/3jrM6HnnCLEs=;
 b=C3WPzPI1kzun7KRJUGlHPK1Y/sND95/Y9cpUsm1S8n5dtocdhTWgKyMihRQwP6sH4Tyq+rHxX
 4/BB2mc+8IqBO/1ydz5o/bIfyeh/F7MRpjd4Nnu9KA+xW/CK+hkX1i2
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Timestamps are made by measuring the chip clock using the watermark
interrupts. If we read more than watermark samples as done today, we
are reducing the period between interrupts and distort the period
measurement. Fix that by reading only watermark samples in the
interrupt case.

Better watermark computation using gcd and store watermark value for
FIFO reading.

Fixes: 7f85e42a6c54 ("iio: imu: inv_icm42600: add buffer support in iio devices")
Cc: stable@vger.kernel.org
Signed-off-by: Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>
---
Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c | 68 +++++++++-------------
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h |  1 +
 2 files changed, 29 insertions(+), 40 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
index 68a395758031..0972294da227 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
@@ -5,6 +5,7 @@
 
 #include <linux/kernel.h>
 #include <linux/device.h>
+#include <linux/gcd.h>
 #include <linux/minmax.h>
 #include <linux/mutex.h>
 #include <linux/pm_runtime.h>
@@ -182,25 +183,18 @@ static unsigned int inv_icm42600_wm_truncate(unsigned int watermark,
  *
  * FIFO watermark threshold is computed based on the required watermark values
  * set for gyro and accel sensors. Since watermark is all about acceptable data
- * latency, use the smallest setting between the 2. It means choosing the
- * smallest latency but this is not as simple as choosing the smallest watermark
- * value. Latency depends on watermark and ODR. It requires several steps:
- * 1) compute gyro and accel latencies and choose the smallest value.
- * 2) adapt the choosen latency so that it is a multiple of both gyro and accel
- *    ones. Otherwise it is possible that you don't meet a requirement. (for
- *    example with gyro @100Hz wm 4 and accel @100Hz with wm 6, choosing the
- *    value of 4 will not meet accel latency requirement because 6 is not a
- *    multiple of 4. You need to use the value 2.)
- * 3) Since all periods are multiple of each others, watermark is computed by
- *    dividing this computed latency by the smallest period, which corresponds
- *    to the FIFO frequency. Beware that this is only true because we are not
- *    using 500Hz frequency which is not a multiple of the others.
+ * latency, we need to use the biggest latency that is able to cope with accel
+ * gyro latencies. Using the shortest period and computing the gcd of the 2
+ * latencies will give the working result.
+ *
+ * Beware this is only working because we are not using the 500Hz frequency,
+ * resulting in FIFO having a fixed period.
  */
 int inv_icm42600_buffer_update_watermark(struct inv_icm42600_state *st)
 {
 	size_t packet_size, wm_size;
-	unsigned int wm_gyro, wm_accel, watermark;
-	u32 period_gyro, period_accel;
+	unsigned int wm_gyro, wm_accel;
+	u32 period_gyro, period_accel, period;
 	u32 latency_gyro, latency_accel, latency;
 	bool restore;
 	__le16 raw_wm;
@@ -222,32 +216,26 @@ int inv_icm42600_buffer_update_watermark(struct inv_icm42600_state *st)
 		return 0;
 
 	if (latency_gyro == 0) {
-		watermark = wm_accel;
-		st->fifo.watermark.eff_accel = wm_accel;
+		period = period_accel;
+		latency = latency_accel;
 	} else if (latency_accel == 0) {
-		watermark = wm_gyro;
-		st->fifo.watermark.eff_gyro = wm_gyro;
+		period = period_gyro;
+		latency = latency_gyro;
 	} else {
-		/* compute the smallest latency that is a multiple of both */
-		if (latency_gyro <= latency_accel)
-			latency = latency_gyro - (latency_accel % latency_gyro);
-		else
-			latency = latency_accel - (latency_gyro % latency_accel);
-		/* all this works because periods are multiple of each others */
-		watermark = latency / min(period_gyro, period_accel);
-		if (watermark < 1)
-			watermark = 1;
-		/* update effective watermark */
-		st->fifo.watermark.eff_gyro = latency / period_gyro;
-		if (st->fifo.watermark.eff_gyro < 1)
-			st->fifo.watermark.eff_gyro = 1;
-		st->fifo.watermark.eff_accel = latency / period_accel;
-		if (st->fifo.watermark.eff_accel < 1)
-			st->fifo.watermark.eff_accel = 1;
+		/* use the shortest period and the gcd of the latencies */
+		period = min(period_gyro, period_accel);
+		latency = gcd(latency_gyro, latency_accel);
 	}
 
+	/* update effective watemarks */
+	st->fifo.watermark.value = max(latency / period, 1);
+	if (wm_gyro)
+		st->fifo.watermark.eff_gyro = max(latency / period_gyro, 1);
+	if (wm_accel)
+		st->fifo.watermark.eff_accel = max(latency / period_accel, 1);
+
 	/* compute watermark value in bytes */
-	wm_size = watermark * packet_size;
+	wm_size = st->fifo.watermark.value * packet_size;
 
 	/* changing FIFO watermark requires to turn off watermark interrupt */
 	ret = regmap_update_bits_check(st->map, INV_ICM42600_REG_INT_SOURCE0,
@@ -454,11 +442,10 @@ int inv_icm42600_buffer_fifo_read(struct inv_icm42600_state *st,
 	st->fifo.nb.accel = 0;
 	st->fifo.nb.total = 0;
 
-	/* compute maximum FIFO read size */
+	/* compute maximum FIFO read size (watermark for max = 0 interrupt case) */
 	if (max == 0)
-		max_count = sizeof(st->fifo.data);
-	else
-		max_count = max * inv_icm42600_get_packet_size(st->fifo.en);
+		max = st->fifo.watermark.value;
+	max_count = max * inv_icm42600_get_packet_size(st->fifo.en);
 
 	/* read FIFO count value */
 	raw_fifo_count = (__be16 *)st->buffer;
@@ -574,6 +561,7 @@ int inv_icm42600_buffer_init(struct inv_icm42600_state *st)
 
 	st->fifo.watermark.eff_gyro = 1;
 	st->fifo.watermark.eff_accel = 1;
+	st->fifo.watermark.value = 1;
 
 	/*
 	 * Default FIFO configuration (bits 7 to 5)
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h
index ffca4da1e249..88b8b9f780af 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h
@@ -34,6 +34,7 @@ struct inv_icm42600_fifo {
 		unsigned int accel;
 		unsigned int eff_gyro;
 		unsigned int eff_accel;
+		unsigned int value;
 	} watermark;
 	size_t count;
 	struct {

---
base-commit: cc746297b23e89bd5df9f91f3a0ca209e8991763
change-id: 20260623-inv-icm42600-fix-watermark-fifo-reading-624caf080754

Best regards,
--  
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

