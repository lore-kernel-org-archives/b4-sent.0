From: Remi Buisson <remi.buisson@tdk.com>
Date: Fri, 31 Oct 2025 10:58:02 +0000
Subject: [PATCH] iio: imu: inv_icm45600: Initializes
 inv_icm45600_buffer_postdisable sleep
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251031-icm45600_fix_buffer_sleep_init-v1-1-924efbb165e8@tdk.com>
X-B4-Tracking: v=1; b=H4sIADmWBGkC/x2NUQqDMBAFryL73cAmaiq9SilB7dt2oU0lqSKId
 zf4OTDMbJSRFJlu1UYJi2b9xQL2UtH47uMLRp+FybFrLdfW6PhtWs8cRNcwzCJIIX+AKWjUv+n
 YO/Hgq3QNlciUUMRzcH/s+wHd5zjpcAAAAA==
X-Change-ID: 20251031-icm45600_fix_buffer_sleep_init-8062f6e07f84
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Remi Buisson <remi.buisson@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761908285; l=1222;
 i=remi.buisson@tdk.com; s=20250411; h=from:subject:message-id;
 bh=VpdMvsXgKn/COc93uRlwlfHH10F/tvvmLU5wsUZM+qk=;
 b=88NM6IdkF46e5D0ne2znApGOCl5VOkNTq5eKGAlANfUloG09rdBKjBok1Q/3dI34AXfq+nl2o
 SuVaGkLinm2BoJReF8U0Pu5E0VLPHGBQbhxDkzb/zzK+jvBIHl6m1FJ
X-Developer-Key: i=remi.buisson@tdk.com; a=ed25519;
 pk=yDVMi4C7RpXN4dififo42A7fDDt3THYzoZoNq9lUZuo=
X-Endpoint-Received: by B4 Relay for remi.buisson@tdk.com/20250411 with auth_id=372
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes: 06674a72cf7a ("iio: imu: inv_icm45600: add buffer support in iio devices")
---
The sleep variable in inv_icm45600_buffer_postdisable could be used without being
assigned in case f error. It must be initialized to 0 by default.

Signed-off-by: Remi Buisson <remi.buisson@tdk.com>
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

