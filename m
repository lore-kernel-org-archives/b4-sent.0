From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 04 May 2026 11:48:19 +0200
Subject: [PATCH v4 07/17] iio: magnetometer: ak8975: pass conversion
 timeouts as arguments
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-magnetometer-fixes-v4-7-a291c2a7c71a@gmail.com>
References: <20260504-magnetometer-fixes-v4-0-a291c2a7c71a@gmail.com>
In-Reply-To: <20260504-magnetometer-fixes-v4-0-a291c2a7c71a@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777888112; l=4645;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=qxnQu7Xgy4STwvS3w094dryNwTltudyh3dCYho4PdDQ=;
 b=/ITAHBk2iqVJ1j2YhGo5XfEYvqa0Snbo6i6QIek/THQx6xg6j/4rcNGm0qfuSTN1Ze4BzUUD1
 ZoC9Lq6QQpaAxiFaRnRquTCkyyBdQ6W4TIgsNVOVCWU6vpoP0zJAq3N
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andy Shevchenko <andriy.shevchenko@linux.intel.com>

Since we have switched to using macros from iopoll.h it's better to
use poll and timeout values supplied as parameters to the helper
functions. Also added local variables for poll and timeout values
to prevent magic number use.

Besides that, fix the home grown and obviously wrong in some cases the
jiffy-based timeout.

Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Co-developed-by: Joshua Crofts <joshua.crofts1@gmail.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 38 ++++++++++++++++++++------------------
 1 file changed, 20 insertions(+), 18 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index 2e750c151435da57926969a63ba9fe996d774e7a..e399a6508a3e28931ec2efe07924d5f30cebf442 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -16,6 +16,7 @@
 #include <linux/i2c.h>
 #include <linux/interrupt.h>
 #include <linux/iopoll.h>
+#include <linux/jiffies.h>
 #include <linux/minmax.h>
 #include <linux/mod_devicetable.h>
 #include <linux/module.h>
@@ -133,13 +134,6 @@
 
 #define AK09912_MAX_REGS		AK09912_REG_ASAZ
 
-/*
- * Miscellaneous values.
- */
-#define AK8975_MAX_CONVERSION_TIMEOUT	500
-#define AK8975_CONVERSION_DONE_POLL_TIME 10
-#define AK8975_DATA_READY_TIMEOUT	((100*HZ)/1000)
-
 /*
  * Precalculate scale factor (in Gauss units) for each axis and
  * store in the device data.
@@ -650,7 +644,8 @@ static int ak8975_setup(struct i2c_client *client)
 	return 0;
 }
 
-static int wait_conversion_complete_gpio(struct ak8975_data *data)
+static int wait_conversion_complete_gpio(struct ak8975_data *data, int poll_ms,
+					 int timeout_ms)
 {
 	struct i2c_client *client = data->client;
 	int ret;
@@ -658,8 +653,8 @@ static int wait_conversion_complete_gpio(struct ak8975_data *data)
 
 	/* Wait for the conversion to complete. */
 	ret = readx_poll_timeout(gpiod_get_value, data->eoc_gpiod, val, val != 0,
-				 AK8975_CONVERSION_DONE_POLL_TIME * USEC_PER_MSEC,
-				 AK8975_MAX_CONVERSION_TIMEOUT * USEC_PER_MSEC);
+				 poll_ms * USEC_PER_MSEC,
+				 timeout_ms * USEC_PER_MSEC);
 	if (ret)
 		return ret;
 
@@ -670,7 +665,8 @@ static int wait_conversion_complete_gpio(struct ak8975_data *data)
 	return ret;
 }
 
-static int wait_conversion_complete_polled(struct ak8975_data *data)
+static int wait_conversion_complete_polled(struct ak8975_data *data, int poll_ms,
+					   int timeout_ms)
 {
 	struct i2c_client *client = data->client;
 	int ret;
@@ -678,8 +674,8 @@ static int wait_conversion_complete_polled(struct ak8975_data *data)
 
 	/* Wait for the conversion to complete. */
 	ret = read_poll_timeout(i2c_smbus_read_byte_data, val, val != 0,
-				AK8975_CONVERSION_DONE_POLL_TIME * USEC_PER_MSEC,
-				AK8975_MAX_CONVERSION_TIMEOUT * USEC_PER_MSEC,
+				poll_ms * USEC_PER_MSEC,
+				timeout_ms * USEC_PER_MSEC,
 				true,
 				client, data->def->ctrl_regs[ST1]);
 	if (ret)
@@ -693,13 +689,14 @@ static int wait_conversion_complete_polled(struct ak8975_data *data)
 }
 
 /* Returns 0 if the end of conversion interrupt occurred or -ETIMEDOUT otherwise */
-static int wait_conversion_complete_interrupt(struct ak8975_data *data)
+static int wait_conversion_complete_interrupt(struct ak8975_data *data,
+					      int timeout_ms)
 {
 	int ret;
 
 	ret = wait_event_timeout(data->data_ready_queue,
 				 test_bit(0, &data->flags),
-				 AK8975_DATA_READY_TIMEOUT);
+				 msecs_to_jiffies(timeout_ms));
 	clear_bit(0, &data->flags);
 
 	return ret > 0 ? 0 : -ETIMEDOUT;
@@ -708,6 +705,11 @@ static int wait_conversion_complete_interrupt(struct ak8975_data *data)
 static int ak8975_start_read_axis(struct ak8975_data *data,
 				  const struct i2c_client *client)
 {
+	int irq_timeout_ms = 100;
+	int timeout_ms = 500;
+	int poll_ms = 10;
+	int ret;
+
 	/* Set up the device for taking a sample. */
 	int ret = ak8975_set_mode(data, MODE_ONCE);
 
@@ -718,11 +720,11 @@ static int ak8975_start_read_axis(struct ak8975_data *data,
 
 	/* Wait for the conversion to complete. */
 	if (data->eoc_irq)
-		ret = wait_conversion_complete_interrupt(data);
+		ret = wait_conversion_complete_interrupt(data, irq_timeout_ms);
 	else if (data->eoc_gpiod)
-		ret = wait_conversion_complete_gpio(data);
+		ret = wait_conversion_complete_gpio(data, poll_ms, timeout_ms);
 	else
-		ret = wait_conversion_complete_polled(data);
+		ret = wait_conversion_complete_polled(data, poll_ms, timeout_ms);
 	if (ret < 0)
 		return ret;
 

-- 
2.47.3

