From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 25 May 2026 10:20:21 +0200
Subject: [PATCH v4 7/8] iio: light: opt3001: switch driver to managed
 resources
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260525-opt3001-cleanup-v4-7-65b36a174f78@gmail.com>
References: <20260525-opt3001-cleanup-v4-0-65b36a174f78@gmail.com>
In-Reply-To: <20260525-opt3001-cleanup-v4-0-65b36a174f78@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779697227; l=4208;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=Ax4yn5eTBCQuhd8dscEiYEPm4u5j8WqMLN8lqGfUPW8=;
 b=ZBVjkHnu5W1oFl+Vi33mgKrEWOkwIyePP/vQB2OTkmhiWbZQPKmIaCt6tCEvmAohqvHyncV8j
 qY3DT1IJ/fHCM288nmziGz8rLC+O/iEsy7sW6T3qZZFTTDK7+kSJhgN
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the driver to use devm_* functions to automate resource
management and simplify error handling. This also allows removal
of the opt3001_remove() function.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 88 ++++++++++++++++++++-------------------------
 1 file changed, 39 insertions(+), 49 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index 14a0915330672209a8de60fc4f3debdd6d6bba76..e35b5cf665e2651e8b6a576aa34fed5082f4ed19 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -705,6 +705,30 @@ static int opt3001_read_id(struct opt3001 *opt)
 	return 0;
 }
 
+static void opt3001_power_off(void *data)
+{
+	struct opt3001 *opt = data;
+	struct i2c_client *client = opt->client;
+	struct device *dev = &client->dev;
+	u16 reg_val;
+	int ret;
+
+	ret = i2c_smbus_read_word_swapped(client, OPT3001_CONFIGURATION);
+	if (ret < 0) {
+		dev_err(dev, "failed to read register %02x\n",
+			OPT3001_CONFIGURATION);
+		return;
+	}
+
+	reg_val = ret;
+	opt3001_set_mode(opt, &reg_val, OPT3001_CONFIGURATION_M_SHUTDOWN);
+
+	ret = i2c_smbus_write_word_swapped(client, OPT3001_CONFIGURATION, reg_val);
+	if (ret < 0)
+		dev_err(dev, "failed to write to register %02x\n",
+			OPT3001_CONFIGURATION);
+}
+
 static int opt3001_configure(struct opt3001 *opt)
 {
 	struct i2c_client *client = opt->client;
@@ -743,6 +767,11 @@ static int opt3001_configure(struct opt3001 *opt)
 		return dev_err_probe(dev, ret, "failed to write register %02x\n",
 				     OPT3001_CONFIGURATION);
 
+	ret = devm_add_action_or_reset(dev, opt3001_power_off, opt);
+	if (ret)
+		return dev_err_probe(dev, ret,
+				     "failed to register power off function\n");
+
 	ret = i2c_smbus_read_word_swapped(client, OPT3001_LOW_LIMIT);
 	if (ret < 0)
 		return dev_err_probe(dev, ret, "failed to read register %02x\n",
@@ -836,7 +865,10 @@ static int opt3001_probe(struct i2c_client *client)
 	opt->client = client;
 	opt->chip_info = i2c_get_match_data(client);
 
-	mutex_init(&opt->lock);
+	ret = devm_mutex_init(dev, &opt->lock);
+	if (ret)
+		return ret;
+
 	init_waitqueue_head(&opt->result_ready_queue);
 	i2c_set_clientdata(client, iio);
 
@@ -858,59 +890,18 @@ static int opt3001_probe(struct i2c_client *client)
 
 	/* Make use of INT pin only if valid IRQ no. is given */
 	if (irq > 0) {
-		ret = request_threaded_irq(irq, NULL, opt3001_irq,
-					   IRQF_TRIGGER_FALLING | IRQF_ONESHOT,
-					   "opt3001", iio);
+		ret = devm_request_threaded_irq(dev, irq, NULL, opt3001_irq,
+						IRQF_TRIGGER_FALLING | IRQF_ONESHOT,
+						"opt3001", iio);
 		if (ret)
-			return dev_err_probe(dev, ret,
-					     "failed to request IRQ #%d\n",
-					     irq);
+			return ret;
+
 		opt->use_irq = true;
 	} else {
 		dev_dbg(dev, "enabling interrupt-less operation\n");
 	}
 
-	ret = iio_device_register(iio);
-	if (ret)
-		goto free_irq;
-
-	return 0;
-
-free_irq:
-	if (irq > 0)
-		free_irq(irq, iio);
-
-	return ret;
-}
-
-static void opt3001_remove(struct i2c_client *client)
-{
-	struct iio_dev *iio = i2c_get_clientdata(client);
-	struct opt3001 *opt = iio_priv(iio);
-	struct device *dev = &client->dev;
-	int ret;
-	u16 reg;
-
-	iio_device_unregister(iio);
-
-	if (opt->use_irq)
-		free_irq(client->irq, iio);
-
-	ret = i2c_smbus_read_word_swapped(client, OPT3001_CONFIGURATION);
-	if (ret < 0) {
-		dev_err(dev, "failed to read register %02x\n",
-			OPT3001_CONFIGURATION);
-		return;
-	}
-
-	reg = ret;
-	opt3001_set_mode(opt, &reg, OPT3001_CONFIGURATION_M_SHUTDOWN);
-
-	ret = i2c_smbus_write_word_swapped(client, OPT3001_CONFIGURATION, reg);
-	if (ret < 0) {
-		dev_err(dev, "failed to write register %02x\n",
-			OPT3001_CONFIGURATION);
-	}
+	return devm_iio_device_register(dev, iio);
 }
 
 static const struct opt3001_chip_info opt3001_chip_information = {
@@ -951,7 +942,6 @@ MODULE_DEVICE_TABLE(of, opt3001_of_match);
 
 static struct i2c_driver opt3001_driver = {
 	.probe = opt3001_probe,
-	.remove = opt3001_remove,
 	.id_table = opt3001_id,
 
 	.driver = {

-- 
2.47.3

