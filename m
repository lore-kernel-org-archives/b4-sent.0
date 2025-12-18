From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 18 Dec 2025 11:30:59 +0100
Subject: [PATCH] iio: imu: inv_icm45600: fix temperature offset reporting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251218-inv-icm45600-fix-temperature-offset-reporting-v1-1-4872f381cbc2@tdk.com>
X-B4-Tracking: v=1; b=H4sIAOLXQ2kC/x2NMQrDMAwAvxI0VyCbpjT9SukgYjnVENvIbiiE/
 D0m4w13t0MVU6nwGnYw2bRqTh3cbYD5y2kR1NAZPPnRefdETRvqvN7HBxFG/WOTtYhx+5lgjrF
 KQ5OSrWla0E3ENHGIgQP0ZjHpzvV7f47jBCY3kld/AAAA
X-Change-ID: 20251218-inv-icm45600-fix-temperature-offset-reporting-190a09adfdad
To: Remi Buisson <remi.buisson@tdk.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766053871; l=1672;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=xHzUisfu0BLrHdPVA8yrhePvVSwj6H9ilNUk2ycuOgo=;
 b=cn6pEMLtqaKZPYTByBvhgKorl9JZG4k5oW3iwONW+ePPrOxspibxVVJIMVkTAawnI4r0KenX1
 b6F7sJdob0iAYzA6SYBW5r3SjjxlU31UjA9+UFEhkCiNYNyFNuN6rvb
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Correct temperature computation is (raw + offset) * scale and not
apply scale and offset afterward.
Fix temperature offset reporting to the correct value and update
commentaries for the new computation.

Fixes: 27e072bc34d1 ("iio: imu: inv_icm45600: add IMU IIO gyroscope device")

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Cc: stable@vger.kernel.org
---
 drivers/iio/imu/inv_icm45600/inv_icm45600_core.c | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c b/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c
index ab1cb7b9dba435a3280e50ab77cd16e903c7816c..25bd9757a594d0180d7f53b49f959a49a50c64a9 100644
--- a/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c
+++ b/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c
@@ -960,16 +960,17 @@ int inv_icm45600_temp_read_raw(struct iio_dev *indio_dev,
 		return IIO_VAL_INT;
 	/*
 	 * T°C = (temp / 128) + 25
-	 * Tm°C = 1000 * ((temp * 100 / 12800) + 25)
-	 * scale: 100000 / 13248 = 7.8125
-	 * offset: 25000
+	 * Tm°C = ((temp + 25 * 128) / 128)) * 1000
+	 * Tm°C = (temp + 3200) * (1000 / 128)
+	 * scale: 1000 / 128 = 7.8125
+	 * offset: 3200
 	 */
 	case IIO_CHAN_INFO_SCALE:
 		*val = 7;
 		*val2 = 812500;
 		return IIO_VAL_INT_PLUS_MICRO;
 	case IIO_CHAN_INFO_OFFSET:
-		*val = 25000;
+		*val = 3200;
 		return IIO_VAL_INT;
 	default:
 		return -EINVAL;

---
base-commit: a7b10f0963c651a6406d958a5f64b9c5594f84da
change-id: 20251218-inv-icm45600-fix-temperature-offset-reporting-190a09adfdad

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

