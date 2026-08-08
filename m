From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Sat, 08 Aug 2026 22:28:16 +0530
Subject: [PATCH v5 4/4] iio: accel: mma8452: use guard() to release mutexes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-15-apr-pm-iio-mma8452-v4-temp-v5-4-d177e93ce3f8@gmail.com>
References: <20260808-15-apr-pm-iio-mma8452-v4-temp-v5-0-d177e93ce3f8@gmail.com>
In-Reply-To: <20260808-15-apr-pm-iio-mma8452-v4-temp-v5-0-d177e93ce3f8@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sanjay Chitroda <sanjayembeddedse@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786208304; l=2727;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=OOn777kWwWFjPtK7zt9fE1n7hpyeCG6+jUtusY+qlS8=;
 b=b33Z14shYtJUPnJmEL3kbcN3hl/05xpqEbFgWEPtB7vz/L3aTDEGa3NGAXo6G74/GonguVDbb
 4eRgvRTGpE4AHiPcawogliFAeEzY1ZBCeMSFpQT16ZMKclgci1hNOdy
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace explicit mutex_lock() and mutex_unlock() with the guard() and
scoped_guard() macro for cleaner and safer mutex handling.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>

---
changes in v4:
- add blank line with input from Andy
- v3 link -> https://lore.kernel.org/all/20260505174640.3998281-11-sanjayembedded@gmail.com/
changes in v3:
- Following input from Jonathan extended mutex scope for
  IIO_CHAN_INFO_RAW case to include math operation under lock
- v2 link -> https://lore.kernel.org/all/20260422165643.2148195-7-sanjayembedded@gmail.com/
---
 drivers/iio/accel/mma8452.c | 30 ++++++++++++------------------
 1 file changed, 12 insertions(+), 18 deletions(-)

diff --git a/drivers/iio/accel/mma8452.c b/drivers/iio/accel/mma8452.c
index c78b1b742b08..fe62a903f0e2 100644
--- a/drivers/iio/accel/mma8452.c
+++ b/drivers/iio/accel/mma8452.c
@@ -19,6 +19,7 @@
  */
 
 #include <linux/array_size.h>
+#include <linux/cleanup.h>
 #include <linux/delay.h>
 #include <linux/i2c.h>
 #include <linux/module.h>
@@ -500,9 +501,9 @@ static int mma8452_read_raw(struct iio_dev *indio_dev,
 		if (IIO_DEV_ACQUIRE_FAILED(claim))
 			return -EBUSY;
 
-		mutex_lock(&data->lock);
+		guard(mutex)(&data->lock);
+
 		ret = mma8452_read(data, buffer);
-		mutex_unlock(&data->lock);
 		if (ret < 0)
 			return ret;
 
@@ -600,36 +601,30 @@ static int mma8452_change_config(struct mma8452_data *data, u8 reg, u8 val)
 	int ret;
 	int is_active;
 
-	mutex_lock(&data->lock);
+	guard(mutex)(&data->lock);
 
 	is_active = mma8452_is_active(data);
-	if (is_active < 0) {
-		ret = is_active;
-		goto fail;
-	}
+	if (is_active < 0)
+		return is_active;
 
 	/* config can only be changed when in standby */
 	if (is_active > 0) {
 		ret = mma8452_standby(data);
 		if (ret < 0)
-			goto fail;
+			return ret;
 	}
 
 	ret = i2c_smbus_write_byte_data(data->client, reg, val);
 	if (ret < 0)
-		goto fail;
+		return ret;
 
 	if (is_active > 0) {
 		ret = mma8452_active(data);
 		if (ret < 0)
-			goto fail;
+			return ret;
 	}
 
-	ret = 0;
-fail:
-	mutex_unlock(&data->lock);
-
-	return ret;
+	return 0;
 }
 
 static int mma8452_set_power_mode(struct mma8452_data *data, u8 mode)
@@ -1741,9 +1736,8 @@ static int mma8452_runtime_suspend(struct device *dev)
 	struct mma8452_data *data = iio_priv(indio_dev);
 	int ret;
 
-	mutex_lock(&data->lock);
-	ret = mma8452_standby(data);
-	mutex_unlock(&data->lock);
+	scoped_guard(mutex, &data->lock)
+		ret = mma8452_standby(data);
 	if (ret < 0) {
 		dev_err(dev, "powering off device failed\n");
 		return -EAGAIN;

-- 
2.34.1

