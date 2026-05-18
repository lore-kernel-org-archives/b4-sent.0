From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 18 May 2026 09:50:25 +0200
Subject: [PATCH v8 1/5] iio: magnetometer: ak8975: switch to using managed
 resources
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-magnetometer-fixes-post-pickup-v8-1-088d610108a0@gmail.com>
References: <20260518-magnetometer-fixes-post-pickup-v8-0-088d610108a0@gmail.com>
In-Reply-To: <20260518-magnetometer-fixes-post-pickup-v8-0-088d610108a0@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779090640; l=5045;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=givHTS5pQ9lRym85HWLXh4HlEe6bie7ypSYk6PAi+Po=;
 b=ul6qbMTg8niw+bAiPexJiqR8GR3eE7Fot7gNCdyq35CdtfgoMiLTl8ryRN0Zd4tQ4EOgCg7QO
 fYvEzoHm2aTB77cGUcRI6R09K4oYHzHgOzyWcF/LAxLZYescKOHVr9F
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
 drivers/iio/magnetometer/ak8975.c | 77 ++++++++++++++++++++++-----------------
 1 file changed, 43 insertions(+), 34 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index bb74abb648f138352576a68c49d3c7dce7cc068e..de4402201783430fc69369f1accaab35145e9f0c 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -935,9 +935,25 @@ static const struct iio_buffer_setup_ops ak8975_buffer_setup_ops = {
 	.preenable = ak8975_buffer_preenable,
 	.postdisable = ak8975_buffer_postdisable,
 };
+
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
@@ -1005,10 +1021,21 @@ static int ak8975_probe(struct i2c_client *client)
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
 	ret = ak8975_who_i_am(data, data->def->type);
 	if (ret) {
 		dev_err(&client->dev, "Unexpected device\n");
-		goto power_off;
+		return ret;
 	}
 	dev_dbg(&client->dev, "Asahi compass chip %s\n", name);
 
@@ -1016,10 +1043,13 @@ static int ak8975_probe(struct i2c_client *client)
 	ret = ak8975_setup(data);
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
@@ -1027,52 +1057,32 @@ static int ak8975_probe(struct i2c_client *client)
 	indio_dev->modes = INDIO_DIRECT_MODE;
 	indio_dev->name = name;
 
-	ret = iio_triggered_buffer_setup(indio_dev, NULL, ak8975_handle_trigger,
-					 &ak8975_buffer_setup_ops);
+	ret = devm_iio_triggered_buffer_setup(dev, indio_dev, NULL,
+					      ak8975_handle_trigger,
+					      &ak8975_buffer_setup_ops);
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
@@ -1166,7 +1176,6 @@ static struct i2c_driver ak8975_driver = {
 		.acpi_match_table = ak_acpi_match,
 	},
 	.probe		= ak8975_probe,
-	.remove		= ak8975_remove,
 	.id_table	= ak8975_id,
 };
 module_i2c_driver(ak8975_driver);

-- 
2.47.3

