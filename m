From: Remi Buisson <remi.buisson@tdk.com>
Date: Fri, 07 Nov 2025 09:13:58 +0000
Subject: [PATCH v4] iio: imu: inv_icm45600: Initializes
 inv_icm45600_buffer_postdisable sleep
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251107-icm45600_fix_buffer_sleep_init-v4-1-5648fbfb57ad@tdk.com>
X-B4-Tracking: v=1; b=H4sIAFW4DWkC/5XNQQ7CIBCF4asY1mIYoFhdeQ9jGqCDTrStgdpoT
 O8u7ca4Upf/ZPK9J0sYCRPbLp4s4kCJujaHXi6YP9n2iJzq3EwKWYBQwMk3ujBCVIHulbuFgLF
 KF8RrRS31vBRGBoNiHUrNMnKNmB/ngf0h94lS38XHvDfAdP2ZHoAD30iNwTkwBZa7vj6vfNewC
 R7kf5jMWOFrLzSC885+YuqNgTBfMZUxtMoGU1qFBt7YOI4vu8A4cWQBAAA=
X-Change-ID: 20251031-icm45600_fix_buffer_sleep_init-8062f6e07f84
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Remi Buisson <remi.buisson@tdk.com>
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762506840; l=1865;
 i=remi.buisson@tdk.com; s=20250411; h=from:subject:message-id;
 bh=KHYZL4PBkFcdTzaWag6cVizPSRawbM+rQCJdwDIqyec=;
 b=LJrkBuBn+oJJ4i6+c9a1Glm0edUU8D+kxrkVzMQbuHuC6IkPGp5tssgL2dXIty231dS0qARbJ
 Z6v8TApjoFpDqyt4gKR2tKvzRy9Ggs1UlGsYuN5dYrIvtKHizzqTyO4
X-Developer-Key: i=remi.buisson@tdk.com; a=ed25519;
 pk=yDVMi4C7RpXN4dififo42A7fDDt3THYzoZoNq9lUZuo=
X-Endpoint-Received: by B4 Relay for remi.buisson@tdk.com/20250411 with auth_id=372
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The sleep variable in inv_icm45600_buffer_postdisable could be used without
being assigned in case of error. It must be initialized to 0 by default.

Fixes: 06674a72cf7a ("iio: imu: inv_icm45600: add buffer support in iio devices")
Closes: https://lore.kernel.org/linux-iio/aPi6Xw-ZoUkW76zR@stanley.mountain/
Signed-off-by: Remi Buisson <remi.buisson@tdk.com>
---
Changes in v4:
- Add space in closse tag in commit message
- Remove extra blank line in commit message
- Link to v3: https://lore.kernel.org/r/20251106-icm45600_fix_buffer_sleep_init-v3-1-ea3af68a3e61@tdk.com

Changes in v3:
- Fix commit message: fix and closes moved to SoB
- Fix assignement of sleep variable after declaration.
- Link to v2: https://lore.kernel.org/r/20251031-icm45600_fix_buffer_sleep_init-v2-1-5cdc04e1bcba@tdk.com

Changes in v2:
- Moving pacth description from cover-letter to single commit
- Link to v1: https://lore.kernel.org/r/20251031-icm45600_fix_buffer_sleep_init-v1-1-924efbb165e8@tdk.com
---
 drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c b/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
index 2efcc177f9d60a6a2509e448c0ddaf4b9e1fd755..2b9ea317385ceb680f013c4c1b2a6a74fbe5d7e7 100644
--- a/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
+++ b/drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c
@@ -370,6 +370,7 @@ static int inv_icm45600_buffer_postdisable(struct iio_dev *indio_dev)
 		return -EINVAL;
 	}
 
+	sleep = 0;
 	scoped_guard(mutex, &st->lock)
 		ret = _inv_icm45600_buffer_postdisable(st, sensor, watermark, &sleep);
 

---
base-commit: 70437bbd7529e9860fb7f0c92a89e0e6abaa994e
change-id: 20251031-icm45600_fix_buffer_sleep_init-8062f6e07f84

Best regards,
-- 
Remi Buisson <remi.buisson@tdk.com>

