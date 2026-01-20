From: Shrikant Raskar <raskar.shree97@gmail.com>
Date: Wed, 21 Jan 2026 02:05:42 +0530
Subject: [PATCH v6 2/5] iio: proximity: rfd77402: Use kernel helper for
 result polling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260121-b4-rfd77402_v5-v6-2-5b944d0605dd@gmail.com>
References: <20260121-b4-rfd77402_v5-v6-0-5b944d0605dd@gmail.com>
In-Reply-To: <20260121-b4-rfd77402_v5-v6-0-5b944d0605dd@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: skhan@linuxfoundation.org, david.hunter.linux@gmail.com, 
 raskar.shree97@gmail.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768941363; l=2437;
 i=raskar.shree97@gmail.com; s=20260101; h=from:subject:message-id;
 bh=4u2p7u2sPM3ykf44S/Ovsl7IQD1KSPRmN8mf85upMmM=;
 b=53ab3EfsxHhCijHrEzTVEg3uKP9tyeLSOQaUuHCKCptcrU8GtyklVFuyCg/aNe3Y5WU1tPMRH
 aWjgHEGGrO5ADuKzkuc++SKo54qLyJo1frXwVCF37INIBKx4L8cVKmi
X-Developer-Key: i=raskar.shree97@gmail.com; a=ed25519;
 pk=4m2wXDvY0vlXefvRRzawNcNAif88Cy4XvbLkU6iMG/Y=
X-Endpoint-Received: by B4 Relay for raskar.shree97@gmail.com/20260101 with auth_id=589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the manually written polling loop with read_poll_timeout(),
the kernel's standard helper for waiting on hardware status.
Move the polling logic into a dedicated helper function, as it will
be reused by future updates.

This makes the code easier to read and avoids repeating the same
polling code in the driver.

Signed-off-by: Shrikant Raskar <raskar.shree97@gmail.com>
---
 drivers/iio/proximity/rfd77402.c | 34 +++++++++++++++++++---------------
 1 file changed, 19 insertions(+), 15 deletions(-)

diff --git a/drivers/iio/proximity/rfd77402.c b/drivers/iio/proximity/rfd77402.c
index 69cc1505b964..716c9330b14e 100644
--- a/drivers/iio/proximity/rfd77402.c
+++ b/drivers/iio/proximity/rfd77402.c
@@ -12,6 +12,7 @@
 
 #include <linux/delay.h>
 #include <linux/i2c.h>
+#include <linux/iopoll.h>
 #include <linux/module.h>
 
 #include <linux/iio/iio.h>
@@ -110,10 +111,23 @@ static int rfd77402_set_state(struct i2c_client *client, u8 state, u16 check)
 	return 0;
 }
 
-static int rfd77402_measure(struct i2c_client *client)
+static int rfd77402_wait_for_result(struct rfd77402_data *data)
 {
+	struct i2c_client *client = data->client;
+	int ret;
+
+	return read_poll_timeout(i2c_smbus_read_byte_data, ret,
+				 ret & RFD77402_ICSR_RESULT,
+				 10 * USEC_PER_MSEC,
+				 10 * 10 * USEC_PER_MSEC,
+				 false,
+				 client, RFD77402_ICSR);
+}
+
+static int rfd77402_measure(struct rfd77402_data *data)
+{
+	struct i2c_client *client = data->client;
 	int ret;
-	int tries = 10;
 
 	ret = rfd77402_set_state(client, RFD77402_CMD_MCPU_ON,
 				 RFD77402_STATUS_MCPU_ON);
@@ -126,19 +140,9 @@ static int rfd77402_measure(struct i2c_client *client)
 	if (ret < 0)
 		goto err;
 
-	while (tries-- > 0) {
-		ret = i2c_smbus_read_byte_data(client, RFD77402_ICSR);
-		if (ret < 0)
-			goto err;
-		if (ret & RFD77402_ICSR_RESULT)
-			break;
-		msleep(20);
-	}
-
-	if (tries < 0) {
-		ret = -ETIMEDOUT;
+	ret = rfd77402_wait_for_result(data);
+	if (ret < 0)
 		goto err;
-	}
 
 	ret = i2c_smbus_read_word_data(client, RFD77402_RESULT_R);
 	if (ret < 0)
@@ -168,7 +172,7 @@ static int rfd77402_read_raw(struct iio_dev *indio_dev,
 	switch (mask) {
 	case IIO_CHAN_INFO_RAW:
 		mutex_lock(&data->lock);
-		ret = rfd77402_measure(data->client);
+		ret = rfd77402_measure(data);
 		mutex_unlock(&data->lock);
 		if (ret < 0)
 			return ret;

-- 
2.43.0

