From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 11 May 2026 13:26:12 +0200
Subject: [PATCH v7 3/8] iio: magnetometer: ak8975: switch to using managed
 resources
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-magnetometer-fixes-post-pickup-v7-3-9d910faa28b6@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778498777; l=4918;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=RK05IzqpmdJLEz+6KcJ2JFwpRKwaEcm/YHbxSZj+oEA=;
 b=D9MEnYd1QotJIvnoQ2wNHXjum/snHcxBif5ZmLZ2/BO3sAU0q4Zsd0mfnJ9l3AHqwX6gQXSLx
 9pK5UoIXDFrC+9Cwj2zpsuu6zXCcGqANF+Xf1KAMvwOBrhaL2Pi/kNP
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andy Shevchenko <andriy.shevchenko@linux.intel.com>

Switch the driver to use managed resources (devm_*) which simplifier
error handling and allows removing ak8975_remove() method from
the driver.

Note, on error path we now also set mode to POWER_DOWN state which is
fine. Even if the device is in that mode, there is no problem to set
that mode again, it should be no-op.

Additionally, remove any pm_runtime_get/put*() function calls that
dummy cycled the counter to autosuspend the device.

Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Co-developed-by: Joshua Crofts <joshua.crofts1@gmail.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 75 +++++++++++++++++++++------------------
 1 file changed, 41 insertions(+), 34 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index 63b6e8465f5f3873841550a1cd03ce86b95d1d67..82ba6f6d7891acf34a3178c185e28238ae63ea3a 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -898,9 +898,24 @@ static irqreturn_t ak8975_handle_trigger(int irq, void *p)
 	return IRQ_HANDLED;
 }
 
+static void devm_ak8975_power_off(void *data)
+{
+	struct ak8975_data *ak = data;
+	struct device *dev = &ak->client->dev;
+
+	/* Only power down if currently active */
+	if (pm_runtime_suspended(dev))
+		return;
+
+	/* Soft-stop the chip before hard-stopping the regulators */
+	ak8975_set_mode(data, POWER_DOWN);
+	ak8975_power_off(data);
+}
+
 static int ak8975_probe(struct i2c_client *client)
 {
 	const struct i2c_device_id *id = i2c_client_get_device_id(client);
+	struct device *dev = &client->dev;
 	struct ak8975_data *data;
 	struct iio_dev *indio_dev;
 	struct gpio_desc *eoc_gpiod;
@@ -968,10 +983,21 @@ static int ak8975_probe(struct i2c_client *client)
 	if (ret)
 		return ret;
 
+	/*
+	 * Set device as active early so pm_runtime_status_suspended() works
+	 * correctly if probe fails before pm_runtime is enabled. Do not attempt
+	 * to move this line lower.
+	 */
+	pm_runtime_set_active(dev);
+
+	ret = devm_add_action_or_reset(dev, devm_ak8975_power_off, data);
+	if (ret)
+		return ret;
+
 	ret = ak8975_who_i_am(client, data->def->type);
 	if (ret) {
 		dev_err(&client->dev, "Unexpected device\n");
-		goto power_off;
+		return ret;
 	}
 	dev_dbg(&client->dev, "Asahi compass chip %s\n", name);
 
@@ -979,10 +1005,13 @@ static int ak8975_probe(struct i2c_client *client)
 	ret = ak8975_setup(client);
 	if (ret) {
 		dev_err(&client->dev, "%s initialization fails\n", name);
-		goto power_off;
+		return ret;
 	}
 
-	mutex_init(&data->lock);
+	ret = devm_mutex_init(dev, &data->lock);
+	if (ret)
+		return ret;
+
 	indio_dev->channels = ak8975_channels;
 	indio_dev->num_channels = ARRAY_SIZE(ak8975_channels);
 	indio_dev->info = &ak8975_info;
@@ -990,52 +1019,31 @@ static int ak8975_probe(struct i2c_client *client)
 	indio_dev->modes = INDIO_DIRECT_MODE;
 	indio_dev->name = name;
 
-	ret = iio_triggered_buffer_setup(indio_dev, NULL, ak8975_handle_trigger,
-					 NULL);
+	ret = devm_iio_triggered_buffer_setup(dev, indio_dev, NULL,
+					      ak8975_handle_trigger, NULL);
 	if (ret) {
 		dev_err(&client->dev, "triggered buffer setup failed\n");
-		goto power_off;
+		return ret;
 	}
 
-	ret = iio_device_register(indio_dev);
+	ret = devm_pm_runtime_enable(dev);
+	if (ret)
+		return ret;
+
+	ret = devm_iio_device_register(dev, indio_dev);
 	if (ret) {
 		dev_err(&client->dev, "device register failed\n");
-		goto cleanup_buffer;
+		return ret;
 	}
 
-	/* Enable runtime PM */
-	pm_runtime_get_noresume(&client->dev);
-	pm_runtime_set_active(&client->dev);
-	pm_runtime_enable(&client->dev);
 	/*
 	 * The device comes online in 500us, so add two orders of magnitude
 	 * of delay before autosuspending: 50 ms.
 	 */
 	pm_runtime_set_autosuspend_delay(&client->dev, 50);
 	pm_runtime_use_autosuspend(&client->dev);
-	pm_runtime_put(&client->dev);
 
 	return 0;
-
-cleanup_buffer:
-	iio_triggered_buffer_cleanup(indio_dev);
-power_off:
-	ak8975_power_off(data);
-	return ret;
-}
-
-static void ak8975_remove(struct i2c_client *client)
-{
-	struct iio_dev *indio_dev = i2c_get_clientdata(client);
-	struct ak8975_data *data = iio_priv(indio_dev);
-
-	pm_runtime_get_sync(&client->dev);
-	pm_runtime_put_noidle(&client->dev);
-	pm_runtime_disable(&client->dev);
-	iio_device_unregister(indio_dev);
-	iio_triggered_buffer_cleanup(indio_dev);
-	ak8975_set_mode(data, POWER_DOWN);
-	ak8975_power_off(data);
 }
 
 static int ak8975_runtime_suspend(struct device *dev)
@@ -1129,7 +1137,6 @@ static struct i2c_driver ak8975_driver = {
 		.acpi_match_table = ak_acpi_match,
 	},
 	.probe		= ak8975_probe,
-	.remove		= ak8975_remove,
 	.id_table	= ak8975_id,
 };
 module_i2c_driver(ak8975_driver);

-- 
2.47.3

