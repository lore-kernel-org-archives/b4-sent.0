From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Sat, 08 Aug 2026 22:28:15 +0530
Subject: [PATCH v5 3/4] iio: accel: mma8452: Use IIO cleanup helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-15-apr-pm-iio-mma8452-v4-temp-v5-3-d177e93ce3f8@gmail.com>
References: <20260808-15-apr-pm-iio-mma8452-v4-temp-v5-0-d177e93ce3f8@gmail.com>
In-Reply-To: <20260808-15-apr-pm-iio-mma8452-v4-temp-v5-0-d177e93ce3f8@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sanjay Chitroda <sanjayembeddedse@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786208304; l=1940;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=87TYvL0o2QU4xXLjLnpehxWEOumXzmAP5MZuj4hGTOY=;
 b=mW8z+UiW10SlOQe+VbolRQzbz2M+/KCjMLiGOfkD9sAYekBNdfEsrHbjhZorpf03YO5MCVkn1
 0C8AZxvW9hMB4+YgA/ohAFvSFHQL0OovKRkz3qFSthLEj0P0S3nhLq4
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use IIO_DEV_ACQUIRE_DIRECT_MODE() helper to automatically release
direct mode.

Suggested-by: Jonathan Cameron <Jonathan.Cameron@huawei.com>
Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>
---
 drivers/iio/accel/mma8452.c | 16 +++++++---------
 1 file changed, 7 insertions(+), 9 deletions(-)

diff --git a/drivers/iio/accel/mma8452.c b/drivers/iio/accel/mma8452.c
index af0cc5970f3b..c78b1b742b08 100644
--- a/drivers/iio/accel/mma8452.c
+++ b/drivers/iio/accel/mma8452.c
@@ -495,14 +495,14 @@ static int mma8452_read_raw(struct iio_dev *indio_dev,
 	int i, ret;
 
 	switch (mask) {
-	case IIO_CHAN_INFO_RAW:
-		if (!iio_device_claim_direct(indio_dev))
+	case IIO_CHAN_INFO_RAW: {
+		IIO_DEV_ACQUIRE_DIRECT_MODE(indio_dev, claim);
+		if (IIO_DEV_ACQUIRE_FAILED(claim))
 			return -EBUSY;
 
 		mutex_lock(&data->lock);
 		ret = mma8452_read(data, buffer);
 		mutex_unlock(&data->lock);
-		iio_device_release_direct(indio_dev);
 		if (ret < 0)
 			return ret;
 
@@ -511,6 +511,7 @@ static int mma8452_read_raw(struct iio_dev *indio_dev,
 			chan->scan_type.realbits - 1);
 
 		return IIO_VAL_INT;
+	}
 	case IIO_CHAN_INFO_SCALE:
 		i = data->data_cfg & MMA8452_DATA_CFG_FS_MASK;
 		*val = data->chip_info->mma_scales[i][0];
@@ -777,14 +778,11 @@ static int mma8452_write_raw(struct iio_dev *indio_dev,
 			     struct iio_chan_spec const *chan,
 			     int val, int val2, long mask)
 {
-	int ret;
-
-	if (!iio_device_claim_direct(indio_dev))
+	IIO_DEV_ACQUIRE_DIRECT_MODE(indio_dev, claim);
+	if (IIO_DEV_ACQUIRE_FAILED(claim))
 		return -EBUSY;
 
-	ret = __mma8452_write_raw(indio_dev, chan, val, val2, mask);
-	iio_device_release_direct(indio_dev);
-	return ret;
+	return __mma8452_write_raw(indio_dev, chan, val, val2, mask);
 }
 
 static int mma8452_get_event_regs(struct mma8452_data *data,

-- 
2.34.1

