From: Remi Buisson <remi.buisson@tdk.com>
Date: Fri, 07 Nov 2025 13:49:56 +0000
Subject: [PATCH v5] iio: imu: inv_icm45600: Initializes
 inv_icm45600_buffer_postdisable sleep
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251107-icm45600_fix_buffer_sleep_init-v5-1-45581918ea63@tdk.com>
X-B4-Tracking: v=1; b=H4sIAAP5DWkC/5XOTU7DMBAF4KtUXmPk8V9MV9wDoch2ZugImlR2i
 EBV7o7TTemqsHxPo+/NWVQsjFXsd2dRcOHK09iCe9iJfIjjG0oeWhZaaQfKgOR8tM4r1RN/9em
 TCEtfPxBPPY88y6C8Jo+qo2BFQ04F2+Fl4OW15QPXeSrfl70FtvbP9AIS5JO2SCmBdxie5+H9M
 U9HscGL/h+mG+bykJVFSDnFW8xcMVD+LmYahtFE8iEa9HCL2d9Ydxez22feBkqUXBeHK7au6w+
 UKvD6sQEAAA==
X-Change-ID: 20251031-icm45600_fix_buffer_sleep_init-8062f6e07f84
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Remi Buisson <remi.buisson@tdk.com>
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762523397; l=2135;
 i=remi.buisson@tdk.com; s=20250411; h=from:subject:message-id;
 bh=v52ZqvJfSOkOyp0ViAifF442SwvXQu+wDMWWMy7Pi4I=;
 b=4HSGmUqYEyslnZV/k5FGQ3NsiLYEY0vzSbfuuyOFVuz2CTSZTankBePjUNLDe5l+mOPm3BA/C
 Q8sf3TM3lxtDQc/QCkKECDjG4YCr1UmHRqk7JZQtTWxRv35/JmN+JWH
X-Developer-Key: i=remi.buisson@tdk.com; a=ed25519;
 pk=yDVMi4C7RpXN4dififo42A7fDDt3THYzoZoNq9lUZuo=
X-Endpoint-Received: by B4 Relay for remi.buisson@tdk.com/20250411 with auth_id=372
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The sleep variable in inv_icm45600_buffer_postdisable() could be used without
being assigned in case of error. It must be initialized to 0 by default.

Fixes: 06674a72cf7a ("iio: imu: inv_icm45600: add buffer support in iio devices")
Closes: https://lore.kernel.org/linux-iio/aPi6Xw-ZoUkW76zR@stanley.mountain/
Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>
Signed-off-by: Remi Buisson <remi.buisson@tdk.com>
---
Changes in v5:
- Adding parenthesis to function name in commit message
- Adding Reviewed-by tag
- Link to v4: https://lore.kernel.org/r/20251107-icm45600_fix_buffer_sleep_init-v4-1-5648fbfb57ad@tdk.com

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

