From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 11 May 2026 13:26:10 +0200
Subject: [PATCH v7 1/8] iio: magnetometer: ak8975: modernize polling loops
 with iopoll() macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260511-magnetometer-fixes-post-pickup-v7-1-9d910faa28b6@gmail.com>
References: <20260511-magnetometer-fixes-post-pickup-v7-0-9d910faa28b6@gmail.com>
In-Reply-To: <20260511-magnetometer-fixes-post-pickup-v7-0-9d910faa28b6@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778498777; l=2939;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=kQ9W4qXTnkaxb6Nx4nCjqQxYeSpg8Dr0Owtif3h7z2A=;
 b=5K1lOK3vwdwAa1YCQ5oLKFNufIT/AxyugQS3JPhlgzvpSU3scBX5rPHU/1+MuK6sdPhNFUWTd
 8sWpY6uRc24DaX4wOfMj4N+w8H+H4WU3eAR7CNrb8opF0pWVzgBs8Sm
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
Reviewed-by: Nuno Sá <nuno.sa@analog.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 43 ++++++++++++++++-----------------------
 1 file changed, 18 insertions(+), 25 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index 6be72e1cc0a8321e767da5e65d54c0fe88712304..b990c123e2808c2078abcfaf6b2ef86c09393e6b 100644
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
@@ -672,27 +671,21 @@ static int wait_conversion_complete_polled(struct ak8975_data *data,
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
-	}
-	if (!timeout_ms)
-		return -ETIMEDOUT;
+	ret = read_poll_timeout(i2c_smbus_read_byte_data, val, val != 0,
+				poll_ms * USEC_PER_MSEC,
+				timeout_ms * USEC_PER_MSEC,
+				true,
+				client, data->def->ctrl_regs[ST1]);
+	if (ret)
+		return ret;
+	if (val < 0)
+		dev_err(&client->dev, "Error in reading ST1\n");
 
-	return read_status;
+	return val;
 }
 
 /* Returns 0 if the end of conversion interrupt occurred or -ETIMEDOUT otherwise */

-- 
2.47.3

