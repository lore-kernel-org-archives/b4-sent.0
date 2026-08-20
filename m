From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 20 Aug 2026 21:02:37 +0200
Subject: [PATCH 1/4] iio: imu: inv_icm42600: sleep before enabling FIFO
 data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260820-inv-icm42600-enhacements-v1-1-075a881db557@tdk.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787252562; l=2310;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=+bwsfyS+uWdp/eU+N8iIh3HLaiG1bPAzG41AqLrkjT8=;
 b=zEpsW03HkfJ8KN0pMsxC03QcysYWGYv2K7XFHKKbROlvxXlsVLrNVgpoqzH1JqoIqtdXkXOVE
 lcm06IPv1jBCQm1ngmRqVFbxAjqSdiSMOkUXgLcw//587Tv8vNDc47C
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When turning accel or gyro on, a sleep is required for letting the
mechanical part stabilize before reporting correct data. Do the sleep
before enabling FIFO data to prevent push of incorrect data. This is
required if the FIFO is already on because a sensor is already running.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c | 12 ++++++++----
 drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c  | 12 ++++++++----
 2 files changed, 16 insertions(+), 8 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
index 4b0e3cd8a506..d889c1dceec1 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
@@ -254,15 +254,19 @@ static int inv_icm42600_accel_update_scan_mode(struct iio_dev *indio_dev,
 		fifo_en |= INV_ICM42600_SENSOR_ACCEL;
 	}
 
+	/* sleep maximum required time */
+	sleep = max(sleep_accel, sleep_temp);
+	if (sleep) {
+		mutex_unlock(&st->lock);
+		msleep(sleep);
+		mutex_lock(&st->lock);
+	}
+
 	/* update data FIFO write */
 	ret = inv_icm42600_buffer_set_fifo_en(st, fifo_en | st->fifo.en);
 
 out_unlock:
 	mutex_unlock(&st->lock);
-	/* sleep maximum required time */
-	sleep = max(sleep_accel, sleep_temp);
-	if (sleep)
-		msleep(sleep);
 	return ret;
 }
 
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
index 253bf571439d..34037b9c1f82 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
@@ -126,15 +126,19 @@ static int inv_icm42600_gyro_update_scan_mode(struct iio_dev *indio_dev,
 		fifo_en |= INV_ICM42600_SENSOR_GYRO;
 	}
 
+	/* sleep maximum required time */
+	sleep = max(sleep_gyro, sleep_temp);
+	if (sleep) {
+		mutex_unlock(&st->lock);
+		msleep(sleep);
+		mutex_lock(&st->lock);
+	}
+
 	/* update data FIFO write */
 	ret = inv_icm42600_buffer_set_fifo_en(st, fifo_en | st->fifo.en);
 
 out_unlock:
 	mutex_unlock(&st->lock);
-	/* sleep maximum required time */
-	sleep = max(sleep_gyro, sleep_temp);
-	if (sleep)
-		msleep(sleep);
 	return ret;
 }
 

-- 
2.55.0

