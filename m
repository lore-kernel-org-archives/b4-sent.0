From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Mon, 19 Oct 2026 15:37:33 +0200
Subject: [PATCH v2] iio: imu: inv_icm42600: fix parsing of all FIFO frames
 for odr change
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261019-iio-imu-inv-icm42600-fix-odr-change-event-in-all-frames-v2-1-d72a69c327ff@tdk.com>
X-B4-Tracking: v=1; b=H4sIABwd1moC/6WOTQ6CMBBGr0K6dkzbAKIr72FYtGWUUUpNWxoN4
 e4W9AYuX/K+n5kF9ISBnYqZeUwUyI0Z5K5gplfjDYG6zExyWQsuaiByQHYCGhOQsaWsOYcrvcB
 1Hn4RTDjGbIAaBrh6ZTHAoVRHYbRslNQstz895tS2fGm/HCZ9RxPXudXoKUTn39u1JFbv/xdJg
 AAttRZ1o3hViXPsHnvjLGuXZfkAOQ2nmw4BAAA=
X-Change-ID: 20261016-iio-imu-inv-icm42600-fix-odr-change-event-in-all-frames-74a91cb28a2b
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792417055; l=3281;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=kD1/ng0GS6kPMK14Mq3qWLm6q2zMJ+jIcdvPt6Xp/Vo=;
 b=DAWMDcOLqRRr7iqC6DWTped4J4M9UNqklDYVqXiraMEK1fslvlmpH7O4i+UCorQ2C3UCeS0Cw
 dxi5AoZlxs/CjA0LPxi0W3PhIz2XivYnxoetCD1fkKagTl2fqN8/MlJ
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For getting all odr change events, we need to parse all FIFO frames
in each iio device. Fix this correctly by sending effectively all
frames to all iio devices.

Previously only batches of frames containing a matching sensor event
were sent to the corresponding iio device.

Fixes: f670d4d34773 ("iio: imu: inv_icm42600: fix odr change not caught in certain cases")
Cc: stable@vger.kernel.org
Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
Changes in v2:
- Add blank line and direct return at end of functions.
- Link to v1: https://patch.msgid.link/20261016-iio-imu-inv-icm42600-fix-odr-change-event-in-all-frames-v1-1-b2bb168a0551@tdk.com

To: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>
To: David Lechner <dlechner@baylibre.com>
To: Nuno Sá <nuno.sa@analog.com>
To: Andy Shevchenko <andy@kernel.org>
Cc: Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>
Cc: linux-iio@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c | 24 +++++++++-------------
 1 file changed, 10 insertions(+), 14 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
index 2bf9fc29d7d2..5bff2a3a44bc 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
@@ -532,22 +532,20 @@ int inv_icm42600_buffer_fifo_parse(struct inv_icm42600_state *st)
 		ts = &gyro_st->ts;
 		inv_sensors_timestamp_interrupt(ts, st->fifo.watermark.eff_gyro,
 						st->timestamp.gyro);
-		ret = inv_icm42600_gyro_parse_fifo(st->indio_gyro);
-		if (ret)
-			return ret;
 	}
 
+	ret = inv_icm42600_gyro_parse_fifo(st->indio_gyro);
+	if (ret)
+		return ret;
+
 	/* handle accelerometer timestamp and FIFO data parsing */
 	if (st->fifo.nb.accel > 0) {
 		ts = &accel_st->ts;
 		inv_sensors_timestamp_interrupt(ts, st->fifo.watermark.eff_accel,
 						st->timestamp.accel);
-		ret = inv_icm42600_accel_parse_fifo(st->indio_accel);
-		if (ret)
-			return ret;
 	}
 
-	return 0;
+	return inv_icm42600_accel_parse_fifo(st->indio_accel);
 }
 
 int inv_icm42600_buffer_hwfifo_flush(struct inv_icm42600_state *st,
@@ -572,20 +570,18 @@ int inv_icm42600_buffer_hwfifo_flush(struct inv_icm42600_state *st,
 	if (st->fifo.nb.gyro > 0) {
 		ts = &gyro_st->ts;
 		inv_sensors_timestamp_interrupt(ts, st->fifo.nb.gyro, gyro_ts);
-		ret = inv_icm42600_gyro_parse_fifo(st->indio_gyro);
-		if (ret)
-			return ret;
 	}
 
+	ret = inv_icm42600_gyro_parse_fifo(st->indio_gyro);
+	if (ret)
+		return ret;
+
 	if (st->fifo.nb.accel > 0) {
 		ts = &accel_st->ts;
 		inv_sensors_timestamp_interrupt(ts, st->fifo.nb.accel, accel_ts);
-		ret = inv_icm42600_accel_parse_fifo(st->indio_accel);
-		if (ret)
-			return ret;
 	}
 
-	return 0;
+	return inv_icm42600_accel_parse_fifo(st->indio_accel);
 }
 
 int inv_icm42600_buffer_init(struct inv_icm42600_state *st)

---
base-commit: a22dc7ebb21a6bd4c8b63bc2c1dd46a24945aae7
change-id: 20261016-iio-imu-inv-icm42600-fix-odr-change-event-in-all-frames-74a91cb28a2b

Best regards,
--  
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

