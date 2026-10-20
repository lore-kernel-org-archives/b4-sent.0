From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Tue, 20 Oct 2026 10:42:30 +0200
Subject: [PATCH] iio: imu: inv_icm42600: update gyro start and stop delay
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-iio-imu-inv-icm42600-update-gyro-start-stop-delay-v1-1-ed52290a4ca4@tdk.com>
X-B4-Tracking: v=1; b=H4sIAHUp12oC/yXNywrCMBCF4Vcps3ZgEiSoryIuYjKtIzYJuRRL6
 bsbdXPg25x/g8JZuMBl2CDzIkVi6FCHAdzDholRfDdo0kaROqNIRJkbSlhQ3HzUhghb8rYyTmu
 OWKrNtW9M6PllVzQnb0dWhrQi6L8p8yjvX/N6+7u0+5Nd/YZg3z/AlwJJlQAAAA==
X-Change-ID: 20261019-iio-imu-inv-icm42600-update-gyro-start-stop-delay-68dafe160210
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792485752; l=1399;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=rYltn7fKB8YhPW/iRMCE7L2yTLJevy0EmSTjB4xuN+c=;
 b=Un0R6vJGxLUzCcYGg0lb1WZ/8zxo6QNxOlLOvC8TBtfKqpRC72aMq0j11LKV9QpxNaww07QeS
 xL6+W6DGsRuCs+oQOsGrSPRHubEQyds4kp5RK32/fcVVsu+z6GbbdlC
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Following datasheet gyroscope specifications, the maximum start time
for gyroscope is 45ms. Stop time is required for letting gyroscope
mechanical structure settle down before enabling it back. 50ms is a
sufficient value for that.

Update values to these numbers.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600.h | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600.h b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
index 3737e79dbcc1..c4a928fd3b8a 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600.h
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
@@ -439,8 +439,8 @@ struct inv_icm42600_sensor_state {
 #define INV_ICM42600_POWER_UP_TIME_MS		100
 #define INV_ICM42600_RESET_TIME_MS		1
 #define INV_ICM42600_ACCEL_STARTUP_TIME_MS	20
-#define INV_ICM42600_GYRO_STARTUP_TIME_MS	60
-#define INV_ICM42600_GYRO_STOP_TIME_MS		150
+#define INV_ICM42600_GYRO_STARTUP_TIME_MS	45
+#define INV_ICM42600_GYRO_STOP_TIME_MS		50
 #define INV_ICM42600_TEMP_STARTUP_TIME_MS	14
 #define INV_ICM42600_SUSPEND_DELAY_MS		2000
 

---
base-commit: 43ffda3c7f8456bbe641ae8249a077a361b97880
change-id: 20261019-iio-imu-inv-icm42600-update-gyro-start-stop-delay-68dafe160210

Best regards,
--  
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

