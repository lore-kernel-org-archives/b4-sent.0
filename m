From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 05 May 2026 13:46:03 +0200
Subject: [PATCH v5 07/18] iio: magnetometer: ak8975: modernize polling
 loops with iopoll() macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260505-magnetometer-fixes-v5-7-831b9b5550fc@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777981558; l=2913;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=V41QhCKldiQvyAMY8Wu1TqUXJlT45yolrTnhX4Txgr8=;
 b=BqJ2KGQy3/p/0g3joi4VPc0mD29AXJAYWOiDU9iOTwAoxTwiphXL3qsqyfj70EzO5uq6jZDX1
 9ogfvjyMexJDsteFregXyvvgYDrrF++cOOJZjSh6X7cLlLJysyQqH8P
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver currently uses while loops and msleep() for polling during
conversion waits.

Replace the custom polling loops with readx_poll_timeout() and
read_poll_timeout() macros from <linux/iopoll.h>. This reduces
boilerplate, standardizes timeout handling and improves overall code
readability, keeping the original timing and error behaviour. Add
<linux/time.h> for USEC_PER_MSEC macro instead of using magic numbers.

Assisted-by: Gemini:3.1-Pro
Reviewed-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 43 +++++++++++++++++----------------------
 1 file changed, 19 insertions(+), 24 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index 83878ea28b91d8316d2cc31e57fde6da957af689..129c98c97071b4cf8efa3abf2364a3abbde129ba 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -24,6 +24,7 @@
 #include <linux/pm_runtime.h>
 #include <linux/property.h>
 #include <linux/regulator/consumer.h>
+#include <linux/time.h>
 #include <linux/types.h>
 #include <linux/wait.h>
 
@@ -649,16 +650,14 @@ static int wait_conversion_complete_gpio(struct ak8975_data *data,
 {
 	struct i2c_client *client = data->client;
 	int ret;
+	int val;
 
 	/* Wait for the conversion to complete. */
-	while (timeout_ms) {
-		msleep(poll_ms);
-		if (gpiod_get_value(data->eoc_gpiod))
-			break;
-		timeout_ms -= poll_ms;
-	}
-	if (!timeout_ms)
-		return -ETIMEDOUT;
+	ret = readx_poll_timeout(gpiod_get_value, data->eoc_gpiod, val, val != 0,
+				 poll_ms * USEC_PER_MSEC,
+				 timeout_ms * USEC_PER_MSEC);
+	if (ret)
+		return ret;
 
 	ret = i2c_smbus_read_byte_data(client, data->def->ctrl_regs[ST1]);
 	if (ret < 0)
@@ -672,27 +671,23 @@ static int wait_conversion_complete_polled(struct ak8975_data *data,
 					   unsigned int timeout_ms)
 {
 	struct i2c_client *client = data->client;
-	u8 read_status;
 	int ret;
+	int val;
 
 	/* Wait for the conversion to complete. */
-	while (timeout_ms) {
-		msleep(poll_ms);
-		ret = i2c_smbus_read_byte_data(client,
-					       data->def->ctrl_regs[ST1]);
-		if (ret < 0) {
-			dev_err(&client->dev, "Error in reading ST1\n");
-			return ret;
-		}
-		read_status = ret;
-		if (read_status)
-			break;
-		timeout_ms -= poll_ms;
+	ret = read_poll_timeout(i2c_smbus_read_byte_data, val, val != 0,
+				poll_ms * USEC_PER_MSEC,
+				timeout_ms * USEC_PER_MSEC,
+				true,
+				client, data->def->ctrl_regs[ST1]);
+	if (ret)
+		return ret;
+	if (val < 0) {
+		dev_err(&client->dev, "Error in reading ST1\n");
+		return val;
 	}
-	if (!timeout_ms)
-		return -ETIMEDOUT;
 
-	return read_status;
+	return val;
 }
 
 /* Returns 0 if the end of conversion interrupt occurred or -ETIMEDOUT otherwise */

-- 
2.47.3

