From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 05 May 2026 13:46:02 +0200
Subject: [PATCH v5 06/18] iio: magnetometer: ak8975: pass conversion
 timeouts as arguments
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260505-magnetometer-fixes-v5-6-831b9b5550fc@gmail.com>
References: <20260505-magnetometer-fixes-v5-0-831b9b5550fc@gmail.com>
In-Reply-To: <20260505-magnetometer-fixes-v5-0-831b9b5550fc@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777981558; l=4851;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=pvNZI200r8juauqZArl2DmxC7e++xAb3H/RtbpQciUg=;
 b=aYMM8qM+7B28lJ7PQlF3m16HPgb685QIroTfwoULTujyvHqetl7XjY2PJB3Q3R5ZdEj8PcoUn
 PO2lPAuTVwODfUO5t5N1IQpZvPDvMw4ZNZuYOY5F7lgnMPMBE/oM00W
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactor wait_conversion_complete*_() helper function to accept poll
and timeout values directly as parameters. This improves the
readability of the code and does not rely on hardcoded macros.

Besides that, fix the home grown and obviously wrong in some cases the
jiffy-based timeout.

Co-developed-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 42 +++++++++++++++++++--------------------
 1 file changed, 20 insertions(+), 22 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index 57f50c09cca539c3733f516a1617375e9134c349..83878ea28b91d8316d2cc31e57fde6da957af689 100644
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
@@ -132,13 +133,6 @@
 
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
@@ -649,18 +643,19 @@ static int ak8975_setup(struct i2c_client *client)
 	return 0;
 }
 
-static int wait_conversion_complete_gpio(struct ak8975_data *data)
+static int wait_conversion_complete_gpio(struct ak8975_data *data,
+					 unsigned int poll_ms,
+					 unsigned int timeout_ms)
 {
 	struct i2c_client *client = data->client;
-	u32 timeout_ms = AK8975_MAX_CONVERSION_TIMEOUT;
 	int ret;
 
 	/* Wait for the conversion to complete. */
 	while (timeout_ms) {
-		msleep(AK8975_CONVERSION_DONE_POLL_TIME);
+		msleep(poll_ms);
 		if (gpiod_get_value(data->eoc_gpiod))
 			break;
-		timeout_ms -= AK8975_CONVERSION_DONE_POLL_TIME;
+		timeout_ms -= poll_ms;
 	}
 	if (!timeout_ms)
 		return -ETIMEDOUT;
@@ -672,16 +667,17 @@ static int wait_conversion_complete_gpio(struct ak8975_data *data)
 	return ret;
 }
 
-static int wait_conversion_complete_polled(struct ak8975_data *data)
+static int wait_conversion_complete_polled(struct ak8975_data *data,
+					   unsigned int poll_ms,
+					   unsigned int timeout_ms)
 {
 	struct i2c_client *client = data->client;
 	u8 read_status;
-	u32 timeout_ms = AK8975_MAX_CONVERSION_TIMEOUT;
 	int ret;
 
 	/* Wait for the conversion to complete. */
 	while (timeout_ms) {
-		msleep(AK8975_CONVERSION_DONE_POLL_TIME);
+		msleep(poll_ms);
 		ret = i2c_smbus_read_byte_data(client,
 					       data->def->ctrl_regs[ST1]);
 		if (ret < 0) {
@@ -691,7 +687,7 @@ static int wait_conversion_complete_polled(struct ak8975_data *data)
 		read_status = ret;
 		if (read_status)
 			break;
-		timeout_ms -= AK8975_CONVERSION_DONE_POLL_TIME;
+		timeout_ms -= poll_ms;
 	}
 	if (!timeout_ms)
 		return -ETIMEDOUT;
@@ -700,13 +696,14 @@ static int wait_conversion_complete_polled(struct ak8975_data *data)
 }
 
 /* Returns 0 if the end of conversion interrupt occurred or -ETIMEDOUT otherwise */
-static int wait_conversion_complete_interrupt(struct ak8975_data *data)
+static int wait_conversion_complete_interrupt(struct ak8975_data *data,
+					      unsigned int timeout_ms)
 {
 	int ret;
 
 	ret = wait_event_timeout(data->data_ready_queue,
 				 test_bit(0, &data->flags),
-				 AK8975_DATA_READY_TIMEOUT);
+				 msecs_to_jiffies(timeout_ms));
 	clear_bit(0, &data->flags);
 
 	return ret > 0 ? 0 : -ETIMEDOUT;
@@ -715,9 +712,10 @@ static int wait_conversion_complete_interrupt(struct ak8975_data *data)
 static int ak8975_start_read_axis(struct ak8975_data *data,
 				  const struct i2c_client *client)
 {
-	/* Set up the device for taking a sample. */
-	int ret = ak8975_set_mode(data, MODE_ONCE);
+	int ret;
 
+	/* Set up the device for taking a sample. */
+	ret = ak8975_set_mode(data, MODE_ONCE);
 	if (ret < 0) {
 		dev_err(&client->dev, "Error in setting operating mode\n");
 		return ret;
@@ -725,11 +723,11 @@ static int ak8975_start_read_axis(struct ak8975_data *data,
 
 	/* Wait for the conversion to complete. */
 	if (data->eoc_irq)
-		ret = wait_conversion_complete_interrupt(data);
+		ret = wait_conversion_complete_interrupt(data, 100);
 	else if (data->eoc_gpiod)
-		ret = wait_conversion_complete_gpio(data);
+		ret = wait_conversion_complete_gpio(data, 10, 500);
 	else
-		ret = wait_conversion_complete_polled(data);
+		ret = wait_conversion_complete_polled(data, 10, 500);
 	if (ret < 0)
 		return ret;
 

-- 
2.47.3

