From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 11 May 2026 12:04:12 +0200
Subject: [PATCH 7/7] iio: light: opt3001: switch driver to managed
 resources
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-opt3001-cleanup-v1-7-f7879dc3455c@gmail.com>
References: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
In-Reply-To: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778493846; l=3774;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=8ovE0Y0dodKlQ5XVRY91rGrO9oJoS2L9RVHQLBYzFz0=;
 b=TwEasXxf3piT93+uKgZLsbAE9vhMlHhXjVS55oEy78azUucyuaePGvbXhPNWqyvt3J3Tv01tB
 /hZ7y4a1WI4C+PMb5f9KEBGO0lTXWTpWelbY/1kMEpF8W9fn3Mj23Z4
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the driver to use devm_* functions to automate resource
management and simplify error handling. This also allows removal
of the opt3001_remove() function.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 67 +++++++++++++++++++++++----------------------
 1 file changed, 34 insertions(+), 33 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index 155794bb28f68a945e20b083e382561ca6ad462e..3ea18d8993da627ae226ac414e8035d8c968861b 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -804,6 +804,29 @@ static irqreturn_t opt3001_irq(int irq, void *_iio)
 	return IRQ_HANDLED;
 }
 
+static void opt3001_power_off(void *data)
+{
+	struct opt3001 *opt = data;
+	int ret;
+	u16 reg;
+
+	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_CONFIGURATION);
+	if (ret < 0) {
+		dev_err(opt->dev, "failed to read register %02x\n",
+			OPT3001_CONFIGURATION);
+		return;
+	}
+
+	reg = ret;
+	opt3001_set_mode(opt, &reg, OPT3001_CONFIGURATION_M_SHUTDOWN);
+
+	ret = i2c_smbus_write_word_swapped(opt->client, OPT3001_CONFIGURATION,
+					   reg);
+	if (ret < 0)
+		dev_err(opt->dev, "failed to write register %02x\n",
+			OPT3001_CONFIGURATION);
+}
+
 static int opt3001_probe(struct i2c_client *client)
 {
 	struct device *dev = &client->dev;
@@ -822,7 +845,10 @@ static int opt3001_probe(struct i2c_client *client)
 	opt->dev = dev;
 	opt->chip_info = i2c_get_match_data(client);
 
-	mutex_init(&opt->lock);
+	ret = devm_mutex_init(dev, &opt->lock);
+	if (ret)
+		return dev_err_probe(dev, ret, "Failed to initialize mutex\n");
+
 	init_waitqueue_head(&opt->result_ready_queue);
 	i2c_set_clientdata(client, iio);
 
@@ -836,6 +862,10 @@ static int opt3001_probe(struct i2c_client *client)
 	if (ret)
 		return ret;
 
+	ret = devm_add_action_or_reset(dev, opt3001_power_off, opt);
+	if (ret)
+		return ret;
+
 	iio->name = client->name;
 	iio->channels = *opt->chip_info->channels;
 	iio->num_channels = opt->chip_info->num_channels;
@@ -849,9 +879,9 @@ static int opt3001_probe(struct i2c_client *client)
 
 	/* Make use of INT pin only if valid IRQ no. is given */
 	if (irq > 0) {
-		ret = request_threaded_irq(irq, NULL, opt3001_irq,
-				IRQF_TRIGGER_FALLING | IRQF_ONESHOT,
-				"opt3001", iio);
+		ret = devm_request_threaded_irq(dev, irq, NULL, opt3001_irq,
+						IRQF_TRIGGER_FALLING | IRQF_ONESHOT,
+						"opt3001", iio);
 		if (ret)
 			return dev_err_probe(dev, ret,
 					     "failed to request IRQ #%d\n",
@@ -864,34 +894,6 @@ static int opt3001_probe(struct i2c_client *client)
 	return 0;
 }
 
-static void opt3001_remove(struct i2c_client *client)
-{
-	struct iio_dev *iio = i2c_get_clientdata(client);
-	struct opt3001 *opt = iio_priv(iio);
-	int ret;
-	u16 reg;
-
-	if (opt->use_irq)
-		free_irq(client->irq, iio);
-
-	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_CONFIGURATION);
-	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
-				OPT3001_CONFIGURATION);
-		return;
-	}
-
-	reg = ret;
-	opt3001_set_mode(opt, &reg, OPT3001_CONFIGURATION_M_SHUTDOWN);
-
-	ret = i2c_smbus_write_word_swapped(opt->client, OPT3001_CONFIGURATION,
-			reg);
-	if (ret < 0) {
-		dev_err(opt->dev, "failed to write register %02x\n",
-				OPT3001_CONFIGURATION);
-	}
-}
-
 static const struct opt3001_chip_info opt3001_chip_information = {
 	.channels = &opt3001_channels,
 	.chan_type = IIO_LIGHT,
@@ -930,7 +932,6 @@ MODULE_DEVICE_TABLE(of, opt3001_of_match);
 
 static struct i2c_driver opt3001_driver = {
 	.probe = opt3001_probe,
-	.remove = opt3001_remove,
 	.id_table = opt3001_id,
 
 	.driver = {

-- 
2.47.3

