From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 04 May 2026 11:48:24 +0200
Subject: [PATCH v4 12/17] iio: magnetometer: ak8975: unify return code
 variable name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-magnetometer-fixes-v4-12-a291c2a7c71a@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777888112; l=3874;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=X9iwzqEdmrTAX1cnhe2RRxRV4goKvKzK5U+3+kX4kNo=;
 b=ptjNCgxm1u+5ArbNIeJM1eO7Fd6+wC2tJEtiBSpbxtSAl1T1Izb+ydlFGkBQLgA1kEcXY2PJa
 LwHaZSjLPabCYSxeN+ukBGosllR/2/U9HPqZy579hX0JSy+d1wywBKl
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andy Shevchenko <andriy.shevchenko@linux.intel.com>

In one case 'rc' is used in the other 'err', the most use 'ret'.
Make the latter use the former, id est 'ret'.

While at it, drop unneeded ' < 0' checks.

Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 46 +++++++++++++++++++--------------------
 1 file changed, 23 insertions(+), 23 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index 5f3e8fadf68e1806841a9561fe6aacded08c85ac..44cc3db57c6882b5f8add7943d1fad594a47ed1a 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -573,8 +573,8 @@ static irqreturn_t ak8975_irq_handler(int irq, void *data)
 static int ak8975_setup_irq(struct ak8975_data *data)
 {
 	struct i2c_client *client = data->client;
-	int rc;
 	int irq;
+	int ret;
 
 	init_waitqueue_head(&data->data_ready_queue);
 	clear_bit(0, &data->flags);
@@ -583,15 +583,15 @@ static int ak8975_setup_irq(struct ak8975_data *data)
 	else
 		irq = gpiod_to_irq(data->eoc_gpiod);
 
-	rc = devm_request_irq(&client->dev, irq, ak8975_irq_handler,
-			      IRQF_TRIGGER_RISING,
-			      dev_name(&client->dev), data);
-	if (rc < 0)
-		return rc;
+	ret = devm_request_irq(&client->dev, irq, ak8975_irq_handler,
+			       IRQF_TRIGGER_RISING,
+			       dev_name(&client->dev), data);
+	if (ret)
+		return ret;
 
 	data->eoc_irq = irq;
 
-	return rc;
+	return 0;
 }
 
 /*
@@ -905,8 +905,8 @@ static int ak8975_probe(struct i2c_client *client)
 	struct iio_dev *indio_dev;
 	struct gpio_desc *eoc_gpiod;
 	struct gpio_desc *reset_gpiod;
-	int err;
 	const char *name = NULL;
+	int ret;
 
 	/*
 	 * Grab and set up the supplied GPIO.
@@ -941,9 +941,9 @@ static int ak8975_probe(struct i2c_client *client)
 	data->reset_gpiod = reset_gpiod;
 	data->eoc_irq = 0;
 
-	err = iio_read_mount_matrix(&client->dev, &data->orientation);
-	if (err)
-		return err;
+	ret = iio_read_mount_matrix(&client->dev, &data->orientation);
+	if (ret)
+		return ret;
 
 	/* id will be NULL when enumerated via ACPI */
 	data->def = i2c_get_match_data(client);
@@ -964,20 +964,20 @@ static int ak8975_probe(struct i2c_client *client)
 	if (IS_ERR(data->vid))
 		return PTR_ERR(data->vid);
 
-	err = ak8975_power_on(data);
-	if (err)
-		return err;
+	ret = ak8975_power_on(data);
+	if (ret)
+		return ret;
 
-	err = ak8975_who_i_am(client, data->def->type);
-	if (err < 0) {
+	ret = ak8975_who_i_am(client, data->def->type);
+	if (ret) {
 		dev_err(&client->dev, "Unexpected device\n");
 		goto power_off;
 	}
 	dev_dbg(&client->dev, "Asahi compass chip %s\n", name);
 
 	/* Perform some basic start-of-day setup of the device. */
-	err = ak8975_setup(client);
-	if (err < 0) {
+	ret = ak8975_setup(client);
+	if (ret) {
 		dev_err(&client->dev, "%s initialization fails\n", name);
 		goto power_off;
 	}
@@ -990,15 +990,15 @@ static int ak8975_probe(struct i2c_client *client)
 	indio_dev->modes = INDIO_DIRECT_MODE;
 	indio_dev->name = name;
 
-	err = iio_triggered_buffer_setup(indio_dev, NULL, ak8975_handle_trigger,
+	ret = iio_triggered_buffer_setup(indio_dev, NULL, ak8975_handle_trigger,
 					 NULL);
-	if (err) {
+	if (ret) {
 		dev_err(&client->dev, "triggered buffer setup failed\n");
 		goto power_off;
 	}
 
-	err = iio_device_register(indio_dev);
-	if (err) {
+	ret = iio_device_register(indio_dev);
+	if (ret) {
 		dev_err(&client->dev, "device register failed\n");
 		goto cleanup_buffer;
 	}
@@ -1021,7 +1021,7 @@ static int ak8975_probe(struct i2c_client *client)
 	iio_triggered_buffer_cleanup(indio_dev);
 power_off:
 	ak8975_power_off(data);
-	return err;
+	return ret;
 }
 
 static void ak8975_remove(struct i2c_client *client)

-- 
2.47.3

