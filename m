From: Remi Buisson <remi.buisson@tdk.com>
Date: Fri, 31 Oct 2025 13:57:06 +0000
Subject: [PATCH v2] iio: imu: inv_icm45600: Initializes
 inv_icm45600_buffer_postdisable sleep
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251031-icm45600_fix_buffer_sleep_init-v2-1-5cdc04e1bcba@tdk.com>
X-B4-Tracking: v=1; b=H4sIADHABGkC/42NWw7CIBBFt9LMtxhAwOqX+zANsXSwE+0jgI2mY
 e9iV+Dnubk5Z4WIgTDCuVoh4EKRprGA3FXg+tt4R0ZdYZBcasEPgpEblDacW09v2768x2DjE3G
 2NFJiNTfSG+RHXysokjlgOW6Ba1O4p5im8Nl6i/itf6sXwQQ7SYW+bYXRWF9S99i7aYAm5/wFw
 ETtacoAAAA=
X-Change-ID: 20251031-icm45600_fix_buffer_sleep_init-8062f6e07f84
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Remi Buisson <remi.buisson@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761919051; l=1575;
 i=remi.buisson@tdk.com; s=20250411; h=from:subject:message-id;
 bh=Rx62rT5vGu7kFWtOCrCoEMC+ZXlR39elZof20ubLlDA=;
 b=kfjGhVBUaoE4027tfvZxjjDZqatcfqnxl2+OfuvbAz4md8gbYTd6AV3AOtULR8I2Q6O73oLj3
 bI93bDRmPAtCIrCRr1FreWPjr7Pj0TR9Oy9983/Xja55wM8eDT0fbpP
X-Developer-Key: i=remi.buisson@tdk.com; a=ed25519;
 pk=yDVMi4C7RpXN4dififo42A7fDDt3THYzoZoNq9lUZuo=
X-Endpoint-Received: by B4 Relay for remi.buisson@tdk.com/20250411 with auth_id=372
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The sleep variable in inv_icm45600_buffer_postdisable could be used without
being assigned in case of error. It must be initialized to 0 by default.

Fixes: 06674a72cf7a ("iio: imu: inv_icm45600: add buffer support in iio devices")
Smatch static checker warning:

	drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c:377 inv_icm45600_buffer_postdisable()
	error: uninitialized symbol 'sleep'.

Signed-off-by: Remi Buisson <remi.buisson@tdk.com>
---
Changes in v2:
- Moving pacth description from cover-letter to single commit
- Link to v1: https://lore.kernel.org/r/20251031-icm45600_fix_buffer_sleep_init-v1-1-924efbb165e8@tdk.com
---
 drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c b/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
index 2efcc177f9d60a6a2509e448c0ddaf4b9e1fd755..bb8382feddc0fd882a6be2ce5e4fe77ab68f13fd 100644
--- a/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
+++ b/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
@@ -357,7 +357,7 @@ static int inv_icm45600_buffer_postdisable(struct iio_dev *indio_dev)
 	struct device *dev = regmap_get_device(st->map);
 	unsigned int sensor;
 	unsigned int *watermark;
-	unsigned int sleep;
+	unsigned int sleep = 0;
 	int ret;
 
 	if (indio_dev == st->indio_gyro) {

---
base-commit: 70437bbd7529e9860fb7f0c92a89e0e6abaa994e
change-id: 20251031-icm45600_fix_buffer_sleep_init-8062f6e07f84

Best regards,
-- 
Remi Buisson <remi.buisson@tdk.com>

