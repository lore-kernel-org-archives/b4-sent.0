From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Mon, 24 Aug 2026 14:30:10 +0200
Subject: [PATCH v2 4/4] iio: imu: inv_icm42600: do not read FIFO count for
 watermark it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-inv-icm42600-enhacements-v2-4-0040837fde12@tdk.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787574695; l=2389;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=Zm48u8KCXMBBkgQlt9czWfmZZ/N82LVph63qdI2PIO8=;
 b=azF5mX7dKXNNp3nyza0VdYJVC4Oo+5WI61bcFnkrbd8vQqx9RXLHAvJHwZNqLy/Cc6VyU3Rzg
 XNt//0Z58zdD/qh5KWJkNhPxeAZvO4kk2m2Gv5D+Asl/GXhsrXBNWtx
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Optimize data reading for high frequencies by not reading FIFO
count in case of watermark interrupt.

We cannot already read more than watermark samples because of the
timestamping mechanism. It is required to not perturb the timing
between the watermark interrupts. Since we also know there is at
least watermark samples in the FIFO, let's just read these watermark
FIFO samples directly without reading FIFO count in this case.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c | 33 ++++++++++------------
 1 file changed, 15 insertions(+), 18 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
index b1a43ca610c4..ded45dfe46a2 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
@@ -477,24 +477,21 @@ int inv_icm42600_buffer_fifo_read(struct inv_icm42600_state *st,
 	st->fifo.nb.accel = 0;
 	st->fifo.nb.total = 0;
 
-	/* compute maximum FIFO read size (watermark for max = 0 interrupt case) */
-	if (max == 0)
-		max = st->fifo.watermark.value;
-	max_count = max * INV_ICM42600_FIFO_2SENSORS_PACKET_SIZE;
-
-	/* read FIFO count value */
-	raw_fifo_count = (__be16 *)st->buffer;
-	ret = regmap_bulk_read(st->map, INV_ICM42600_REG_FIFO_COUNT,
-			       raw_fifo_count, sizeof(*raw_fifo_count));
-	if (ret)
-		return ret;
-	st->fifo.count = be16_to_cpup(raw_fifo_count);
-
-	/* check and clamp FIFO count value */
-	if (st->fifo.count == 0)
-		return 0;
-	if (st->fifo.count > max_count)
-		st->fifo.count = max_count;
+	/* read watermark samples for interrupt case (max = 0) or read FIFO count */
+	if (max == 0) {
+		st->fifo.count = st->fifo.watermark.value *
+				 INV_ICM42600_FIFO_2SENSORS_PACKET_SIZE;
+	} else {
+		raw_fifo_count = (__be16 *)st->buffer;
+		ret = regmap_bulk_read(st->map, INV_ICM42600_REG_FIFO_COUNT,
+					raw_fifo_count, sizeof(*raw_fifo_count));
+		if (ret)
+			return ret;
+		max_count = max * INV_ICM42600_FIFO_2SENSORS_PACKET_SIZE;
+		st->fifo.count = min(be16_to_cpup(raw_fifo_count), max_count);
+		if (st->fifo.count == 0)
+			return 0;
+	}
 
 	/* read all FIFO data in internal buffer */
 	ret = regmap_noinc_read(st->map, INV_ICM42600_REG_FIFO_DATA,

-- 
2.55.0

