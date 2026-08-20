From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 20 Aug 2026 21:02:40 +0200
Subject: [PATCH 4/4] iio: imu: inv_icm42600: do not read FIFO count for
 watermark it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260820-inv-icm42600-enhacements-v1-4-075a881db557@tdk.com>
References: <20260820-inv-icm42600-enhacements-v1-0-075a881db557@tdk.com>
In-Reply-To: <20260820-inv-icm42600-enhacements-v1-0-075a881db557@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787252562; l=2268;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=OQmQVi4yJ7lu/WvxADoFhgDSPCmfaq3lgsQjBlIiMZo=;
 b=0NCK0EjmfbIqD3uY37VDeTKqiWGqEGfKSkBe6nBp2xvo0aFvRx1fwMmbFe7DbuSnLaq31+GPU
 zHEwQo7Fp/nDmacOz6dhgNo95FOHblt5Ci8yi6FOWW4Y2PVjI8n3u5K
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Optimize data reading for high frequencies by not reading FIFO
count in case of watermark interrupt. We already know there is
watermark samples in the FIFO and we need to not read more than
watermark samples for timestamping mechanism. Let's just read FIFO
data directly without reading FIFO count in this case.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c | 33 ++++++++++------------
 1 file changed, 15 insertions(+), 18 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
index 1428f18408ce..1410096f6e6d 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
@@ -474,24 +474,21 @@ int inv_icm42600_buffer_fifo_read(struct inv_icm42600_state *st,
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

