From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Mon, 24 Aug 2026 14:30:08 +0200
Subject: [PATCH v2 2/4] iio: imu: inv_icm42600: use 2 sensors fixed packet
 size of 16 bytes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-inv-icm42600-enhacements-v2-2-0040837fde12@tdk.com>
References: <20260824-inv-icm42600-enhacements-v2-0-0040837fde12@tdk.com>
In-Reply-To: <20260824-inv-icm42600-enhacements-v2-0-0040837fde12@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787574695; l=3984;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=mNAm8b4ddHbtiXu6xptZFNN+mbbMV5qtuBUPJ1NmHtE=;
 b=ZuL4YPV/Xrq9Y1ehBN8r95BCijfBgaf7uje8Z6cxyKE8/kyyF+rXybR/Rwpg67vtZII0mU03c
 AIZDCoUZ2evA0V3QOd8Gzpi15ViqRuJLt1WM9X5J4CKnZmf5WKR8RGl
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sometimes dynamic switch between 1 sensor frame to 2 sensors frame is
not working when there are too much frames already in the FIFO. By
moving accel/gyro on sleep before turning FIFO on, we are storing many
FIFO frames before updating the frame format hitting the bug everytime.

Fix that by always using the 2 sensors frame of 16 bytes. Also update
the hwfifo max watermark reported.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600.h        |  4 +--
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c | 34 ++++++++--------------
 2 files changed, 14 insertions(+), 24 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600.h b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
index b55d993f0264..f6c7c84c7e45 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600.h
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
@@ -356,8 +356,8 @@ struct inv_icm42600_sensor_state {
 		cpu_to_le16((_wm) & GENMASK(11, 0))
 /* FIFO is 2048 bytes, let 12 samples for reading latency */
 #define INV_ICM42600_FIFO_WATERMARK_MAX			(2048 - 12 * 16)
-/* INV_ICM42600_FIFO_WATERMARK_MAX / 8 = 232 */
-#define INV_ICM42600_FIFO_WATERMARK_MAX_SAMPLES		232
+/* INV_ICM42600_FIFO_WATERMARK_MAX / 16 = 116 */
+#define INV_ICM42600_FIFO_WATERMARK_MAX_SAMPLES		116
 
 #define INV_ICM42600_REG_INT_CONFIG1			0x0064
 #define INV_ICM42600_INT_CONFIG1_TPULSE_DURATION	BIT(6)
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
index 998d312f7bde..5421122057ee 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
@@ -131,13 +131,16 @@ int inv_icm42600_buffer_set_fifo_en(struct inv_icm42600_state *st,
 		INV_ICM42600_FIFO_CONFIG1_GYRO_EN |
 		INV_ICM42600_FIFO_CONFIG1_ACCEL_EN;
 
-	val = 0;
-	if (fifo_en & INV_ICM42600_SENSOR_GYRO)
-		val |= INV_ICM42600_FIFO_CONFIG1_GYRO_EN;
-	if (fifo_en & INV_ICM42600_SENSOR_ACCEL)
-		val |= INV_ICM42600_FIFO_CONFIG1_ACCEL_EN;
-	if (fifo_en & INV_ICM42600_SENSOR_TEMP)
-		val |= INV_ICM42600_FIFO_CONFIG1_TEMP_EN;
+	/*
+	 * Always enable/disable all bits to ensure we can flawlessly add
+	 * accel/gyro data in the FIFO while it is running.
+	 */
+	if (fifo_en)
+		val = INV_ICM42600_FIFO_CONFIG1_TEMP_EN |
+		      INV_ICM42600_FIFO_CONFIG1_GYRO_EN |
+		      INV_ICM42600_FIFO_CONFIG1_ACCEL_EN;
+	else
+		val = 0;
 
 	ret = regmap_update_bits(st->map, INV_ICM42600_REG_FIFO_CONFIG1, mask, val);
 	if (ret)
@@ -149,19 +152,6 @@ int inv_icm42600_buffer_set_fifo_en(struct inv_icm42600_state *st,
 	return 0;
 }
 
-static size_t inv_icm42600_get_packet_size(unsigned int fifo_en)
-{
-	size_t packet_size;
-
-	if ((fifo_en & INV_ICM42600_SENSOR_GYRO) &&
-	    (fifo_en & INV_ICM42600_SENSOR_ACCEL))
-		packet_size = INV_ICM42600_FIFO_2SENSORS_PACKET_SIZE;
-	else
-		packet_size = INV_ICM42600_FIFO_1SENSOR_PACKET_SIZE;
-
-	return packet_size;
-}
-
 static unsigned int inv_icm42600_wm_truncate(unsigned int watermark,
 					     size_t packet_size)
 {
@@ -209,7 +199,7 @@ int inv_icm42600_buffer_update_watermark(struct inv_icm42600_state *st)
 	__le16 raw_wm;
 	int ret;
 
-	packet_size = inv_icm42600_get_packet_size(st->fifo.en);
+	packet_size = INV_ICM42600_FIFO_2SENSORS_PACKET_SIZE;
 
 	/* compute sensors latency, depending on sensor watermark and odr */
 	wm_gyro = inv_icm42600_wm_truncate(st->fifo.watermark.gyro, packet_size);
@@ -495,7 +485,7 @@ int inv_icm42600_buffer_fifo_read(struct inv_icm42600_state *st,
 	/* compute maximum FIFO read size (watermark for max = 0 interrupt case) */
 	if (max == 0)
 		max = st->fifo.watermark.value;
-	max_count = max * inv_icm42600_get_packet_size(st->fifo.en);
+	max_count = max * INV_ICM42600_FIFO_2SENSORS_PACKET_SIZE;
 
 	/* read FIFO count value */
 	raw_fifo_count = (__be16 *)st->buffer;

-- 
2.55.0

