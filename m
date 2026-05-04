From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 04 May 2026 11:48:23 +0200
Subject: [PATCH v4 11/17] iio: magnetometer: ak8975: reduce usage of magic
 lengths of the buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-magnetometer-fixes-v4-11-a291c2a7c71a@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777888112; l=1861;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=rDrOq3pd2pOssWC4w5NSLBzhEZL5wqsAhnMlBUMsUAw=;
 b=xpEilhhQQBS1oFvUyZvqUyZ2+4m3gSD+asCKlCr5c66+t7A4uji+HUVwJzDsP1qBlMfPe80w2
 yNWRrHkfCXjCIwU14d3WRWK048+Vx/usnyzngqWI5ObB7AQY+p/lKI8
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andy Shevchenko <andriy.shevchenko@linux.intel.com>

Reduce usage of magic lengths of the supplied buffer by replacing them
with the corresponding sizeof():s.

Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 15 +++++++++------
 1 file changed, 9 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index c354ebaba11c86c24ebe2dbc2b20c11f18015151..5f3e8fadf68e1806841a9561fe6aacded08c85ac 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -490,8 +490,10 @@ static int ak8975_who_i_am(struct i2c_client *client,
 	 * AK8975   |  DEVICE_ID |  NA
 	 * AK8963   |  DEVICE_ID |  NA
 	 */
-	ret = i2c_smbus_read_i2c_block_data_or_emulated(
-			client, AK09912_REG_WIA1, 2, wia_val);
+	ret = i2c_smbus_read_i2c_block_data_or_emulated(client,
+							AK09912_REG_WIA1,
+							sizeof(wia_val),
+							wia_val);
 	if (ret < 0) {
 		dev_err(&client->dev, "Error reading WIA\n");
 		return ret;
@@ -610,9 +612,10 @@ static int ak8975_setup(struct i2c_client *client)
 	}
 
 	/* Get asa data and store in the device data. */
-	ret = i2c_smbus_read_i2c_block_data_or_emulated(
-			client, data->def->ctrl_regs[ASA_BASE],
-			3, data->asa);
+	ret = i2c_smbus_read_i2c_block_data_or_emulated(client,
+							data->def->ctrl_regs[ASA_BASE],
+							sizeof(data->asa),
+							data->asa);
 	if (ret < 0) {
 		dev_err(&client->dev, "Not able to read asa data\n");
 		return ret;
@@ -863,7 +866,7 @@ static void ak8975_fill_buffer(struct iio_dev *indio_dev)
 	 */
 	ret = i2c_smbus_read_i2c_block_data_or_emulated(client,
 							def->data_regs[0],
-							3 * sizeof(fval[0]),
+							sizeof(fval),
 							(u8 *)fval);
 	if (ret < 0)
 		goto unlock;

-- 
2.47.3

