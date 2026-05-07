From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Thu, 07 May 2026 16:35:53 +0200
Subject: [PATCH 4/8] iio: magnetometer: ak8975: consistently use 'data'
 parameter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260507-magnetometer-fixes-post-pickup-v1-4-37827ca68fb3@gmail.com>
References: <20260507-magnetometer-fixes-post-pickup-v1-0-37827ca68fb3@gmail.com>
In-Reply-To: <20260507-magnetometer-fixes-post-pickup-v1-0-37827ca68fb3@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778164567; l=3366;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=aBXD1UqgNsG/B0TM6+2/HkyCvJBTEDR+pG1fondDO7Q=;
 b=7I1UR1HjOTylM2/T4A2ng3AWxqNThhbNwHMvWaRpVC9412OG5O3CH33YiXTFWuPx5ATLrC8eI
 wfWthoukwVdAX6Soq7PbssMICCte6ZwlLpPa/CNfjShR6hpCb0cvx/9
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andy Shevchenko <andriy.shevchenko@linux.intel.com>

Some of the functions use 'client', some use 'data', and some use both.
Refactor the driver to consistently use 'data' in all cases.

Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 25 +++++++++++++------------
 1 file changed, 13 insertions(+), 12 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index 1d8f448d5179fe9b33af989cc2f456ac91bc2f17..e575d252076acc3639cfbb718a76811636fe56d2 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -474,9 +474,10 @@ static void ak8975_power_off(const struct ak8975_data *data)
  * Return 0 if the i2c device is the one we expect.
  * return a negative error number otherwise
  */
-static int ak8975_who_i_am(struct i2c_client *client,
+static int ak8975_who_i_am(const struct ak8975_data *data,
 			   enum asahi_compass_chipset type)
 {
+	struct i2c_client *client = data->client;
 	u8 wia_val[2];
 	int ret;
 
@@ -598,10 +599,9 @@ static int ak8975_setup_irq(struct ak8975_data *data)
  * Perform some start-of-day setup, including reading the asa calibration
  * values and caching them.
  */
-static int ak8975_setup(struct i2c_client *client)
+static int ak8975_setup(struct ak8975_data *data)
 {
-	struct iio_dev *indio_dev = i2c_get_clientdata(client);
-	struct ak8975_data *data = iio_priv(indio_dev);
+	struct i2c_client *client = data->client;
 	int ret;
 
 	/* Write the fused rom access mode. */
@@ -706,12 +706,13 @@ static int wait_conversion_complete_interrupt(struct ak8975_data *data,
 	return ret > 0 ? 0 : -ETIMEDOUT;
 }
 
-static int ak8975_start_read_axis(struct ak8975_data *data,
-				  const struct i2c_client *client)
+static int ak8975_start_read_axis(struct ak8975_data *data)
 {
-	/* Set up the device for taking a sample. */
-	int ret = ak8975_set_mode(data, MODE_ONCE);
+	struct i2c_client *client = data->client;
+	int ret;
 
+	/* Set up the device for taking a sample. */
+	ret = ak8975_set_mode(data, MODE_ONCE);
 	if (ret < 0) {
 		dev_err(&client->dev, "Error in setting operating mode\n");
 		return ret;
@@ -744,7 +745,7 @@ static int ak8975_read_axis(struct iio_dev *indio_dev, int index, int *val)
 
 	mutex_lock(&data->lock);
 
-	ret = ak8975_start_read_axis(data, client);
+	ret = ak8975_start_read_axis(data);
 	if (ret)
 		goto exit;
 
@@ -856,7 +857,7 @@ static void ak8975_fill_buffer(struct iio_dev *indio_dev)
 
 	mutex_lock(&data->lock);
 
-	ret = ak8975_start_read_axis(data, client);
+	ret = ak8975_start_read_axis(data);
 	if (ret)
 		goto unlock;
 
@@ -994,7 +995,7 @@ static int ak8975_probe(struct i2c_client *client)
 	if (ret)
 		return ret;
 
-	ret = ak8975_who_i_am(client, data->def->type);
+	ret = ak8975_who_i_am(data, data->def->type);
 	if (ret) {
 		dev_err(&client->dev, "Unexpected device\n");
 		return ret;
@@ -1002,7 +1003,7 @@ static int ak8975_probe(struct i2c_client *client)
 	dev_dbg(&client->dev, "Asahi compass chip %s\n", name);
 
 	/* Perform some basic start-of-day setup of the device. */
-	ret = ak8975_setup(client);
+	ret = ak8975_setup(data);
 	if (ret) {
 		dev_err(&client->dev, "%s initialization fails\n", name);
 		return ret;

-- 
2.47.3

