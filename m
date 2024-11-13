From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Wed, 13 Nov 2024 21:25:45 +0100
Subject: [PATCH] iio: imu: inv_icm42600: fix timestamps after suspend if
 sensor is on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241113-inv_icm42600-fix-timestamps-after-suspend-v1-1-dfc77c394173@tdk.com>
X-B4-Tracking: v=1; b=H4sIAEgLNWcC/x2NwQrCMBAFf6Xs2YVsDAr+iojE9FX3kBiysQil/
 27wODDMbGRoCqPLtFHDqqbvMkAOE6VXLE+wzoPJOx9E5Mha1rumHPzJOV70y10zrMdcjePS0dg
 +VlFmfpwRvCDG4BKNXm0Y/v91ve37DznTSuJ7AAAA
X-Change-ID: 20241113-inv_icm42600-fix-timestamps-after-suspend-b7e421eaa40c
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>, 
 Jonathan Cameron <Jonathan.Cameron@huawei.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731529557; l=1842;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=+tQ9OPlXVb/U7JJzG2A5nQchXayPHGyAcIorXGviVAg=;
 b=sCmRsr4/cO+NzGKXwiE8HMetOoSImgvJtQSIr0Y8XXQZQtaxiApETbdK79AE/3j00YdWcFZjs
 L7nEs9l63s4ChzCaC6wkyTOFE31hgw3QrQR59S+P18fmf0medsGmlo4
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently suspending while sensors are one will result in timestamping
continuing without gap at resume. It can work with monotonic clock but
not with other clocks. Fix that by resetting timestamping.

Fixes: ec74ae9fd37c ("iio: imu: inv_icm42600: add accurate timestamping")
Cc: stable@vger.kernel.org
Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
index 93b5d7a3339ccff16b21bf6c40ed7b2311317cf4..03139e2e4eddbf37e154de2eb486549bc3bdb284 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
@@ -814,6 +814,8 @@ static int inv_icm42600_suspend(struct device *dev)
 static int inv_icm42600_resume(struct device *dev)
 {
 	struct inv_icm42600_state *st = dev_get_drvdata(dev);
+	struct inv_icm42600_sensor_state *gyro_st = iio_priv(st->indio_gyro);
+	struct inv_icm42600_sensor_state *accel_st = iio_priv(st->indio_accel);
 	int ret;
 
 	mutex_lock(&st->lock);
@@ -834,9 +836,12 @@ static int inv_icm42600_resume(struct device *dev)
 		goto out_unlock;
 
 	/* restore FIFO data streaming */
-	if (st->fifo.on)
+	if (st->fifo.on) {
+		inv_sensors_timestamp_reset(&gyro_st->ts);
+		inv_sensors_timestamp_reset(&accel_st->ts);
 		ret = regmap_write(st->map, INV_ICM42600_REG_FIFO_CONFIG,
 				   INV_ICM42600_FIFO_CONFIG_STREAM);
+	}
 
 out_unlock:
 	mutex_unlock(&st->lock);

---
base-commit: 9dd2270ca0b38ee16094817f4a53e7ba78e31567
change-id: 20241113-inv_icm42600-fix-timestamps-after-suspend-b7e421eaa40c

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

