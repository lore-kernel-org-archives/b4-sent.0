From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Sat, 08 Aug 2026 22:28:14 +0530
Subject: [PATCH v5 2/4] iio: accel: mma8452: use local struct device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-15-apr-pm-iio-mma8452-v4-temp-v5-2-d177e93ce3f8@gmail.com>
References: <20260808-15-apr-pm-iio-mma8452-v4-temp-v5-0-d177e93ce3f8@gmail.com>
In-Reply-To: <20260808-15-apr-pm-iio-mma8452-v4-temp-v5-0-d177e93ce3f8@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sanjay Chitroda <sanjayembeddedse@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786208304; l=4596;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=LXfSnV6rBvAa1+8KwnMa4fMrZA8D3loMbNKlUnNF0CM=;
 b=6z8XKHl+BuAKd8GYNkxz87hJd+hu4XW3WvL62HT2idawPbRJYOaDq1q9SWAYiYQXUYKDprn5S
 p5VoV70kPblB9/h5rzHP0726fVhY5IGlVlIEA7moiXuHZ4RpK4ebteX
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a local struct device pointer derived from &client->dev.
This avoids repeated &client->dev usage and improves readability.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>

---
changes in v4:
- address coding style comment given by Andy
- v3 link -> https://lore.kernel.org/all/20260505174640.3998281-8-sanjayembedded@gmail.com/
---
 drivers/iio/accel/mma8452.c | 39 +++++++++++++++++++--------------------
 1 file changed, 19 insertions(+), 20 deletions(-)

diff --git a/drivers/iio/accel/mma8452.c b/drivers/iio/accel/mma8452.c
index 772463d5ff47..af0cc5970f3b 100644
--- a/drivers/iio/accel/mma8452.c
+++ b/drivers/iio/accel/mma8452.c
@@ -222,15 +222,15 @@ static int mma8452_drdy(struct mma8452_data *data)
 static int mma8452_set_runtime_pm_state(struct i2c_client *client, bool on)
 {
 #ifdef CONFIG_PM
+	struct device *dev = &client->dev;
 	int ret;
 
 	if (on)
-		ret = pm_runtime_resume_and_get(&client->dev);
+		ret = pm_runtime_resume_and_get(dev);
 	else
-		ret = pm_runtime_put_autosuspend(&client->dev);
+		ret = pm_runtime_put_autosuspend(dev);
 	if (ret < 0) {
-		dev_err(&client->dev,
-			"failed to change power state to %d\n", on);
+		dev_err(dev, "failed to change power state to %d\n", on);
 
 		return ret;
 	}
@@ -1552,7 +1552,7 @@ static int mma8452_probe(struct i2c_client *client)
 	struct iio_dev *indio_dev;
 	int ret;
 
-	indio_dev = devm_iio_device_alloc(&client->dev, sizeof(*data));
+	indio_dev = devm_iio_device_alloc(dev, sizeof(*data));
 	if (!indio_dev)
 		return -ENOMEM;
 
@@ -1562,10 +1562,9 @@ static int mma8452_probe(struct i2c_client *client)
 
 	data->chip_info = i2c_get_match_data(client);
 	if (!data->chip_info)
-		return dev_err_probe(&client->dev, -ENODEV,
-				     "unknown device model\n");
+		return dev_err_probe(dev, -ENODEV, "unknown device model\n");
 
-	ret = iio_read_mount_matrix(&client->dev, &data->orientation);
+	ret = iio_read_mount_matrix(dev, &data->orientation);
 	if (ret)
 		return ret;
 
@@ -1598,7 +1597,7 @@ static int mma8452_probe(struct i2c_client *client)
 		goto disable_regulators;
 	}
 
-	dev_info(&client->dev, "registering %s accelerometer; ID 0x%x\n",
+	dev_info(dev, "registering %s accelerometer; ID 0x%x\n",
 		 data->chip_info->name, data->chip_info->chip_id);
 
 	i2c_set_clientdata(client, indio_dev);
@@ -1631,10 +1630,10 @@ static int mma8452_probe(struct i2c_client *client)
 	if (client->irq) {
 		int irq2;
 
-		irq2 = fwnode_irq_get_byname(dev_fwnode(&client->dev), "INT2");
+		irq2 = fwnode_irq_get_byname(dev_fwnode(dev), "INT2");
 
 		if (irq2 == client->irq) {
-			dev_dbg(&client->dev, "using interrupt line INT2\n");
+			dev_dbg(dev, "using interrupt line INT2\n");
 		} else {
 			ret = i2c_smbus_write_byte_data(client,
 							MMA8452_CTRL_REG5,
@@ -1642,7 +1641,7 @@ static int mma8452_probe(struct i2c_client *client)
 			if (ret < 0)
 				goto disable_regulators;
 
-			dev_dbg(&client->dev, "using interrupt line INT1\n");
+			dev_dbg(dev, "using interrupt line INT1\n");
 		}
 
 		ret = i2c_smbus_write_byte_data(client,
@@ -1679,14 +1678,13 @@ static int mma8452_probe(struct i2c_client *client)
 			goto buffer_cleanup;
 	}
 
-	ret = pm_runtime_set_active(&client->dev);
+	ret = pm_runtime_set_active(dev);
 	if (ret < 0)
 		goto free_irq;
 
-	pm_runtime_enable(&client->dev);
-	pm_runtime_set_autosuspend_delay(&client->dev,
-					 MMA8452_AUTO_SUSPEND_DELAY_MS);
-	pm_runtime_use_autosuspend(&client->dev);
+	pm_runtime_enable(dev);
+	pm_runtime_set_autosuspend_delay(dev, MMA8452_AUTO_SUSPEND_DELAY_MS);
+	pm_runtime_use_autosuspend(dev);
 
 	ret = iio_device_register(indio_dev);
 	if (ret < 0)
@@ -1721,11 +1719,12 @@ static void mma8452_remove(struct i2c_client *client)
 {
 	struct iio_dev *indio_dev = i2c_get_clientdata(client);
 	struct mma8452_data *data = iio_priv(indio_dev);
+	struct device *dev = &client->dev;
 
 	iio_device_unregister(indio_dev);
 
-	pm_runtime_disable(&client->dev);
-	pm_runtime_set_suspended(&client->dev);
+	pm_runtime_disable(dev);
+	pm_runtime_set_suspended(dev);
 
 	if (client->irq)
 		free_irq(client->irq, indio_dev);
@@ -1748,7 +1747,7 @@ static int mma8452_runtime_suspend(struct device *dev)
 	ret = mma8452_standby(data);
 	mutex_unlock(&data->lock);
 	if (ret < 0) {
-		dev_err(&data->client->dev, "powering off device failed\n");
+		dev_err(dev, "powering off device failed\n");
 		return -EAGAIN;
 	}
 

-- 
2.34.1

