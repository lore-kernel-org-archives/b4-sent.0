From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 11 May 2026 13:26:15 +0200
Subject: [PATCH v7 6/8] iio: magnetometer: ak8975: use temporary variable
 for struct device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260511-magnetometer-fixes-post-pickup-v7-6-9d910faa28b6@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778498777; l=8291;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=PY+9jDzJWWLpMYvAV7XSLzvkCn5i/WGCjKP/BAdYNTs=;
 b=HbGuwCU+KC1z1w1YyL6YhgLskLX2TtsyRuN4XN7tTfSk6PPOr0jlR4aJG9YRqTjSlbnRDCRFX
 fpYBReZkHifAdUhBjL2JOVQUhOgnES1LhB/YVbwHl1AZgnzNMmy6nwS
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andy Shevchenko <andriy.shevchenko@linux.intel.com>

Use temporary variable for struct device to make code neater.

Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Reviewed-by: Nuno Sá <nuno.sa@analog.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 63 +++++++++++++++++++--------------------
 1 file changed, 31 insertions(+), 32 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index 2f1442e71607873e869351c379a40dae713a1c84..2267928a136912c901e604fe938e9a17c8cd5607 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -433,18 +433,17 @@ struct ak8975_data {
 /* Enable attached power regulator if any. */
 static int ak8975_power_on(const struct ak8975_data *data)
 {
+	struct device *dev = &data->client->dev;
 	int ret;
 
 	ret = regulator_enable(data->vdd);
 	if (ret) {
-		dev_warn(&data->client->dev,
-			 "Failed to enable specified Vdd supply\n");
+		dev_warn(dev, "Failed to enable specified Vdd supply\n");
 		return ret;
 	}
 	ret = regulator_enable(data->vid);
 	if (ret) {
-		dev_warn(&data->client->dev,
-			 "Failed to enable specified Vid supply\n");
+		dev_warn(dev, "Failed to enable specified Vid supply\n");
 		regulator_disable(data->vdd);
 		return ret;
 	}
@@ -572,6 +571,7 @@ static irqreturn_t ak8975_irq_handler(int irq, void *data)
 static int ak8975_setup_irq(struct ak8975_data *data)
 {
 	struct i2c_client *client = data->client;
+	struct device *dev = &client->dev;
 	int irq;
 	int ret;
 
@@ -582,9 +582,8 @@ static int ak8975_setup_irq(struct ak8975_data *data)
 	else
 		irq = gpiod_to_irq(data->eoc_gpiod);
 
-	ret = devm_request_irq(&client->dev, irq, ak8975_irq_handler,
-			       IRQF_TRIGGER_RISING,
-			       dev_name(&client->dev), data);
+	ret = devm_request_irq(dev, irq, ak8975_irq_handler, IRQF_TRIGGER_RISING,
+			       dev_name(dev), data);
 	if (ret)
 		return ret;
 
@@ -600,12 +599,13 @@ static int ak8975_setup_irq(struct ak8975_data *data)
 static int ak8975_setup(struct ak8975_data *data)
 {
 	struct i2c_client *client = data->client;
+	struct device *dev = &client->dev;
 	int ret;
 
 	/* Write the fused rom access mode. */
 	ret = ak8975_set_mode(data, FUSE_ROM);
 	if (ret < 0) {
-		dev_err(&client->dev, "Error in setting fuse access mode\n");
+		dev_err(dev, "Error in setting fuse access mode\n");
 		return ret;
 	}
 
@@ -615,22 +615,21 @@ static int ak8975_setup(struct ak8975_data *data)
 							sizeof(data->asa),
 							data->asa);
 	if (ret < 0) {
-		dev_err(&client->dev, "Not able to read asa data\n");
+		dev_err(dev, "Not able to read asa data\n");
 		return ret;
 	}
 
 	/* After reading fuse ROM data set power-down mode */
 	ret = ak8975_set_mode(data, POWER_DOWN);
 	if (ret < 0) {
-		dev_err(&client->dev, "Error in setting power-down mode\n");
+		dev_err(dev, "Error in setting power-down mode\n");
 		return ret;
 	}
 
 	if (data->eoc_gpiod || client->irq > 0) {
 		ret = ak8975_setup_irq(data);
 		if (ret < 0) {
-			dev_err(&client->dev,
-				"Error setting data ready interrupt\n");
+			dev_err(dev, "Error setting data ready interrupt\n");
 			return ret;
 		}
 	}
@@ -736,10 +735,11 @@ static int ak8975_read_axis(struct iio_dev *indio_dev, int index, int *val)
 	struct ak8975_data *data = iio_priv(indio_dev);
 	const struct i2c_client *client = data->client;
 	const struct ak_def *def = data->def;
+	struct device *dev = &data->client->dev;
 	__le16 rval;
 	int ret;
 
-	pm_runtime_get_sync(&data->client->dev);
+	pm_runtime_get_sync(dev);
 
 	mutex_lock(&data->lock);
 
@@ -757,20 +757,20 @@ static int ak8975_read_axis(struct iio_dev *indio_dev, int index, int *val)
 	/* Read out ST2 for release lock on measurement data. */
 	ret = i2c_smbus_read_byte_data(client, data->def->ctrl_regs[ST2]);
 	if (ret < 0) {
-		dev_err(&client->dev, "Error in reading ST2\n");
+		dev_err(dev, "Error in reading ST2\n");
 		goto exit;
 	}
 
 	if (ret & (data->def->ctrl_masks[ST2_DERR] |
 		   data->def->ctrl_masks[ST2_HOFL])) {
-		dev_err(&client->dev, "ST2 status error 0x%x\n", ret);
+		dev_err(dev, "ST2 status error 0x%x\n", ret);
 		ret = -EINVAL;
 		goto exit;
 	}
 
 	mutex_unlock(&data->lock);
 
-	pm_runtime_put_autosuspend(&data->client->dev);
+	pm_runtime_put_autosuspend(dev);
 
 	/* Swap bytes and convert to valid range. */
 	*val = clamp_t(s16, le16_to_cpu(rval), -def->range, def->range);
@@ -779,8 +779,8 @@ static int ak8975_read_axis(struct iio_dev *indio_dev, int index, int *val)
 
 exit:
 	mutex_unlock(&data->lock);
-	pm_runtime_put_autosuspend(&data->client->dev);
-	dev_err(&client->dev, "Error in reading axis\n");
+	pm_runtime_put_autosuspend(dev);
+	dev_err(dev, "Error in reading axis\n");
 	return ret;
 }
 
@@ -927,7 +927,7 @@ static int ak8975_probe(struct i2c_client *client)
 	 * We may not have a GPIO based IRQ to scan, that is fine, we will
 	 * poll if so.
 	 */
-	eoc_gpiod = devm_gpiod_get_optional(&client->dev, NULL, GPIOD_IN);
+	eoc_gpiod = devm_gpiod_get_optional(dev, NULL, GPIOD_IN);
 	if (IS_ERR(eoc_gpiod))
 		return PTR_ERR(eoc_gpiod);
 	gpiod_set_consumer_name(eoc_gpiod, "ak_8975");
@@ -937,13 +937,12 @@ static int ak8975_probe(struct i2c_client *client)
 	 * deassert reset on ak8975_power_on() and assert reset on
 	 * ak8975_power_off().
 	 */
-	reset_gpiod = devm_gpiod_get_optional(&client->dev,
-					      "reset", GPIOD_OUT_HIGH);
+	reset_gpiod = devm_gpiod_get_optional(dev, "reset", GPIOD_OUT_HIGH);
 	if (IS_ERR(reset_gpiod))
 		return PTR_ERR(reset_gpiod);
 
 	/* Register with IIO */
-	indio_dev = devm_iio_device_alloc(&client->dev, sizeof(*data));
+	indio_dev = devm_iio_device_alloc(dev, sizeof(*data));
 	if (indio_dev == NULL)
 		return -ENOMEM;
 
@@ -955,7 +954,7 @@ static int ak8975_probe(struct i2c_client *client)
 	data->reset_gpiod = reset_gpiod;
 	data->eoc_irq = 0;
 
-	ret = iio_read_mount_matrix(&client->dev, &data->orientation);
+	ret = iio_read_mount_matrix(dev, &data->orientation);
 	if (ret)
 		return ret;
 
@@ -965,16 +964,16 @@ static int ak8975_probe(struct i2c_client *client)
 		return -ENODEV;
 
 	/* If enumerated via firmware node, fix the ABI */
-	if (dev_fwnode(&client->dev))
-		name = dev_name(&client->dev);
+	if (dev_fwnode(dev))
+		name = dev_name(dev);
 	else
 		name = id->name;
 
 	/* Fetch the regulators */
-	data->vdd = devm_regulator_get(&client->dev, "vdd");
+	data->vdd = devm_regulator_get(dev, "vdd");
 	if (IS_ERR(data->vdd))
 		return PTR_ERR(data->vdd);
-	data->vid = devm_regulator_get(&client->dev, "vid");
+	data->vid = devm_regulator_get(dev, "vid");
 	if (IS_ERR(data->vid))
 		return PTR_ERR(data->vid);
 
@@ -996,7 +995,7 @@ static int ak8975_probe(struct i2c_client *client)
 	ret = ak8975_who_i_am(data, data->def->type);
 	if (ret)
 		return dev_err_probe(dev, ret, "Unexpected device\n");
-	dev_dbg(&client->dev, "Asahi compass chip %s\n", name);
+	dev_dbg(dev, "Asahi compass chip %s\n", name);
 
 	/* Perform some basic start-of-day setup of the device. */
 	ret = ak8975_setup(data);
@@ -1031,8 +1030,8 @@ static int ak8975_probe(struct i2c_client *client)
 	 * The device comes online in 500us, so add two orders of magnitude
 	 * of delay before autosuspending: 50 ms.
 	 */
-	pm_runtime_set_autosuspend_delay(&client->dev, 50);
-	pm_runtime_use_autosuspend(&client->dev);
+	pm_runtime_set_autosuspend_delay(dev, 50);
+	pm_runtime_use_autosuspend(dev);
 
 	return 0;
 }
@@ -1047,7 +1046,7 @@ static int ak8975_runtime_suspend(struct device *dev)
 	/* Set the device in power down if it wasn't already */
 	ret = ak8975_set_mode(data, POWER_DOWN);
 	if (ret < 0) {
-		dev_err(&client->dev, "Error in setting power-down mode\n");
+		dev_err(dev, "Error in setting power-down mode\n");
 		return ret;
 	}
 	/* Next cut the regulators */
@@ -1071,7 +1070,7 @@ static int ak8975_runtime_resume(struct device *dev)
 	 */
 	ret = ak8975_set_mode(data, POWER_DOWN);
 	if (ret < 0) {
-		dev_err(&client->dev, "Error in setting power-down mode\n");
+		dev_err(dev, "Error in setting power-down mode\n");
 		return ret;
 	}
 

-- 
2.47.3

