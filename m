From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 18 Dec 2025 10:21:17 +0100
Subject: [PATCH] iio: imu: inv_icm42600: enable temp polling when buffer is
 on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251218-inv-icm42600-do-not-block-temperature-polling-v1-1-909fbd4e240a@tdk.com>
X-B4-Tracking: v=1; b=H4sIAIzHQ2kC/x3NTQrCMBBA4auUWTuQHxPEq4iLNp3WwXQSkliE0
 rsbXH6b9w6oVJgq3IcDCu1cOUmHvgwQXqOshDx3g1HGaaNvyLIjh+1qvFI4J5TUcIopvLHRlqm
 M7VMIc4qRZUXvrFXOh8mqBXozF1r4+/89nuf5A7Em3ER/AAAA
X-Change-ID: 20251218-inv-icm42600-do-not-block-temperature-polling-6533056cb30f
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766049687; l=1221;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=f8du7ktVd1utCvuUW65hpIirqMUqmiPXKFlXcsmlnPs=;
 b=ZCNYy2rpUCxw6rObHvdBmygmmhqh6cvA9p/fHoah6C5d4KEC7oI0wBA4vKneYKveRBdIztIz3
 ARuX7tUQSklA7BLdxaksTEBK8KTcLDGPeXLfI1MTmD17irg00I1I0kG
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Delete iio_device_claim_direct_mode() when reading temperature.
It enables polling of temperature data while buffer is on and it
doesn't have any impact on the other sensors.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c | 3 ---
 1 file changed, 3 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c
index 30f6a9595eea2308ef9ab0660210fc14ca758198..727b03d541a58a27cc9d793da78d1f4a1c460297 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c
@@ -59,10 +59,7 @@ int inv_icm42600_temp_read_raw(struct iio_dev *indio_dev,
 
 	switch (mask) {
 	case IIO_CHAN_INFO_RAW:
-		if (!iio_device_claim_direct(indio_dev))
-			return -EBUSY;
 		ret = inv_icm42600_temp_read(st, &temp);
-		iio_device_release_direct(indio_dev);
 		if (ret)
 			return ret;
 		*val = temp;

---
base-commit: a7b10f0963c651a6406d958a5f64b9c5594f84da
change-id: 20251218-inv-icm42600-do-not-block-temperature-polling-6533056cb30f

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

