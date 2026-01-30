From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Fri, 30 Jan 2026 16:38:47 +0100
Subject: [PATCH] iio: imu: inv_icm42600: fix odr switch to the same value
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260130-inv-icm42600-fix-odr-change-v1-1-347a03a57fa1@tdk.com>
X-B4-Tracking: v=1; b=H4sIAIbQfGkC/y3MSwqAMAwA0atI1gb6Q9CriAu1UbOwlRaKULy7Q
 Vw+GKZCpsSUYWgqJCqcOQaBbhtYjznshOzFYJTplLYKORTk9XRChRvfGH3CP+0NuU0vnpzVIIc
 rkRTffZye5wVAScWLbQAAAA==
X-Change-ID: 20260130-inv-icm42600-fix-odr-change-92e4f1bde431
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>, 
 Jonathan Cameron <Jonathan.Cameron@huawei.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769787537; l=2088;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=rFQH6wdMXA8+FMQIBC/54JO8ilgcnHM/BrtDPx5h0/I=;
 b=EGAnytWi+eEGCX/Rq8LlqGxsO1BaSuO5nPpnqPMeEIYUH+ECk/7ptVeJpA58dvB4B6wHh2hYK
 p3BOUUpf/rXCBzfZtxlYUknVBw8p6piQ2na0IwiDZ1HBUYkFY1pPYd1
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ODR switch is done in 2 steps when FIFO is on : change the ODR register
value and acknowledge change when reading the FIFO ODR change flag.
When we are switching to the same odr value, we end up waiting for a
FIFO ODR flag that is never happening.

Fix the issue by doing nothing and exiting properly when we are
switching to the same ODR value.

Fixes: ec74ae9fd37c ("iio: imu: inv_icm42600: add accurate timestamping")
Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Cc: stable@vger.kernel.org
---
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c | 2 ++
 drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c  | 2 ++
 2 files changed, 4 insertions(+)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
index 54760d8f92a279334338fd09e3ab74b2d939a46d..0ab6eddf0543feeb51170271d766a732d1e45544 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
@@ -651,6 +651,8 @@ static int inv_icm42600_accel_write_odr(struct iio_dev *indio_dev,
 		return -EINVAL;
 
 	conf.odr = inv_icm42600_accel_odr_conv[idx / 2];
+	if (conf.odr == st->conf.accel.odr)
+		return 0;
 
 	pm_runtime_get_sync(dev);
 	mutex_lock(&st->lock);
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
index 7ef0a25ec74f6b005ca6e86058d67d0be67327df..11339ddf1da36c85e56de6c4a95486713cbd182a 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c
@@ -358,6 +358,8 @@ static int inv_icm42600_gyro_write_odr(struct iio_dev *indio_dev,
 		return -EINVAL;
 
 	conf.odr = inv_icm42600_gyro_odr_conv[idx / 2];
+	if (conf.odr == st->conf.gyro.odr)
+		return 0;
 
 	pm_runtime_get_sync(dev);
 	mutex_lock(&st->lock);

---
base-commit: 62b44ebc1f2c71db3ca2d4737c52e433f6f03038
change-id: 20260130-inv-icm42600-fix-odr-change-92e4f1bde431

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

