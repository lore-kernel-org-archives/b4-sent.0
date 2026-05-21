From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Thu, 21 May 2026 11:55:39 +0200
Subject: [PATCH v3 2/7] iio: light: opt3001: use local struct device and
 i2c_client variables
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260521-opt3001-cleanup-v3-2-820169dec8c3@gmail.com>
References: <20260521-opt3001-cleanup-v3-0-820169dec8c3@gmail.com>
In-Reply-To: <20260521-opt3001-cleanup-v3-0-820169dec8c3@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Alexander Koch <mail@alexanderkoch.net>, 
 Michael Hornung <mhornung.linux@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779357341; l=13711;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=KeQZYDuMseJbjGBQbnMphGWz8ys8FsC4yi93yHRm4cY=;
 b=re8AL/CBr4UimuLAxRX5Q+lcYtxROR9+fUkSQRBfnx6DUq5/GqB72ln3c5boYyJl1pELb02SY
 s3RZlCEF3JUAkIyVsNX0e1u/typY7XDuka432pzhZOcnGiSS03knwPr
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch the driver to use local variables for struct device and struct
i2c_client and remove struct device member from struct opt3001, as the
former can be derived from struct client.

While at it, ensure that parentheses alignment is correct in functions
that were changed in this patch.

No functional change.

Suggested-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 149 +++++++++++++++++++++++---------------------
 1 file changed, 78 insertions(+), 71 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index fe53a072b21ddaa26a23c76e82897fdbc1e4d846..5d88a697c245347bcb98254460308fc9a9f375f4 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -101,7 +101,6 @@ struct opt3001_chip_info {
 
 struct opt3001 {
 	struct i2c_client	*client;
-	struct device		*dev;
 
 	struct mutex		lock;
 	bool			ok_to_ignore_lock;
@@ -313,6 +312,8 @@ static const struct iio_chan_spec opt3002_channels[] = {
 
 static int opt3001_get_processed(struct opt3001 *opt, int *val, int *val2)
 {
+	struct i2c_client *client = opt->client;
+	struct device *dev = &client->dev;
 	int ret;
 	u16 mantissa;
 	u16 reg;
@@ -326,12 +327,12 @@ static int opt3001_get_processed(struct opt3001 *opt, int *val, int *val2)
 		 * doing so will overwrite the low-level limit value however we
 		 * will restore this value later on.
 		 */
-		ret = i2c_smbus_write_word_swapped(opt->client,
-					OPT3001_LOW_LIMIT,
-					OPT3001_LOW_LIMIT_EOC_ENABLE);
+		ret = i2c_smbus_write_word_swapped(client,
+						   OPT3001_LOW_LIMIT,
+						   OPT3001_LOW_LIMIT_EOC_ENABLE);
 		if (ret < 0) {
-			dev_err(opt->dev, "failed to write register %02x\n",
-					OPT3001_LOW_LIMIT);
+			dev_err(dev, "failed to write register %02x\n",
+				OPT3001_LOW_LIMIT);
 			return ret;
 		}
 
@@ -343,21 +344,20 @@ static int opt3001_get_processed(struct opt3001 *opt, int *val, int *val2)
 	opt->result_ready = false;
 
 	/* Configure for single-conversion mode and start a new conversion */
-	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_CONFIGURATION);
+	ret = i2c_smbus_read_word_swapped(client, OPT3001_CONFIGURATION);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
-				OPT3001_CONFIGURATION);
+		dev_err(dev, "failed to read register %02x\n",
+			OPT3001_CONFIGURATION);
 		goto err;
 	}
 
 	reg = ret;
 	opt3001_set_mode(opt, &reg, OPT3001_CONFIGURATION_M_SINGLE);
 
-	ret = i2c_smbus_write_word_swapped(opt->client, OPT3001_CONFIGURATION,
-			reg);
+	ret = i2c_smbus_write_word_swapped(client, OPT3001_CONFIGURATION, reg);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to write register %02x\n",
-				OPT3001_CONFIGURATION);
+		dev_err(dev, "failed to write register %02x\n",
+			OPT3001_CONFIGURATION);
 		goto err;
 	}
 
@@ -375,10 +375,9 @@ static int opt3001_get_processed(struct opt3001 *opt, int *val, int *val2)
 		msleep(timeout);
 
 		/* Check result ready flag */
-		ret = i2c_smbus_read_word_swapped(opt->client,
-						  OPT3001_CONFIGURATION);
+		ret = i2c_smbus_read_word_swapped(client, OPT3001_CONFIGURATION);
 		if (ret < 0) {
-			dev_err(opt->dev, "failed to read register %02x\n",
+			dev_err(dev, "failed to read register %02x\n",
 				OPT3001_CONFIGURATION);
 			goto err;
 		}
@@ -389,9 +388,9 @@ static int opt3001_get_processed(struct opt3001 *opt, int *val, int *val2)
 		}
 
 		/* Obtain value */
-		ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_RESULT);
+		ret = i2c_smbus_read_word_swapped(client, OPT3001_RESULT);
 		if (ret < 0) {
-			dev_err(opt->dev, "failed to read register %02x\n",
+			dev_err(dev, "failed to read register %02x\n",
 				OPT3001_RESULT);
 			goto err;
 		}
@@ -416,12 +415,12 @@ static int opt3001_get_processed(struct opt3001 *opt, int *val, int *val2)
 		 * bit-overlap and therefore can't be done.
 		 */
 		value = (opt->low_thresh_exp << 12) | opt->low_thresh_mantissa;
-		ret = i2c_smbus_write_word_swapped(opt->client,
+		ret = i2c_smbus_write_word_swapped(client,
 						   OPT3001_LOW_LIMIT,
 						   value);
 		if (ret < 0) {
-			dev_err(opt->dev, "failed to write register %02x\n",
-					OPT3001_LOW_LIMIT);
+			dev_err(dev, "failed to write register %02x\n",
+				OPT3001_LOW_LIMIT);
 			return ret;
 		}
 	}
@@ -444,13 +443,15 @@ static int opt3001_get_int_time(struct opt3001 *opt, int *val, int *val2)
 
 static int opt3001_set_int_time(struct opt3001 *opt, int time)
 {
+	struct i2c_client *client = opt->client;
+	struct device *dev = &client->dev;
 	int ret;
 	u16 reg;
 
-	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_CONFIGURATION);
+	ret = i2c_smbus_read_word_swapped(client, OPT3001_CONFIGURATION);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
-				OPT3001_CONFIGURATION);
+		dev_err(dev, "failed to read register %02x\n",
+			OPT3001_CONFIGURATION);
 		return ret;
 	}
 
@@ -469,8 +470,7 @@ static int opt3001_set_int_time(struct opt3001 *opt, int time)
 		return -EINVAL;
 	}
 
-	return i2c_smbus_write_word_swapped(opt->client, OPT3001_CONFIGURATION,
-			reg);
+	return i2c_smbus_write_word_swapped(client, OPT3001_CONFIGURATION, reg);
 }
 
 static int opt3001_read_raw(struct iio_dev *iio,
@@ -565,6 +565,8 @@ static int opt3001_write_event_value(struct iio_dev *iio,
 		int val, int val2)
 {
 	struct opt3001 *opt = iio_priv(iio);
+	struct i2c_client *client = opt->client;
+	struct device *dev = &client->dev;
 	int ret;
 	int whole;
 	int integer;
@@ -583,7 +585,7 @@ static int opt3001_write_event_value(struct iio_dev *iio,
 
 	ret = opt3001_find_scale(opt, val, val2, &exponent);
 	if (ret < 0) {
-		dev_err(opt->dev, "can't find scale for %d.%06u\n", val, val2);
+		dev_err(dev, "can't find scale for %d.%06u\n", val, val2);
 		goto err;
 	}
 
@@ -611,9 +613,9 @@ static int opt3001_write_event_value(struct iio_dev *iio,
 		goto err;
 	}
 
-	ret = i2c_smbus_write_word_swapped(opt->client, reg, value);
+	ret = i2c_smbus_write_word_swapped(client, reg, value);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to write register %02x\n", reg);
+		dev_err(dev, "failed to write register %02x\n", reg);
 		goto err;
 	}
 
@@ -637,6 +639,8 @@ static int opt3001_write_event_config(struct iio_dev *iio,
 		enum iio_event_direction dir, bool state)
 {
 	struct opt3001 *opt = iio_priv(iio);
+	struct i2c_client *client = opt->client;
+	struct device *dev = &client->dev;
 	int ret;
 	u16 mode;
 	u16 reg;
@@ -652,21 +656,20 @@ static int opt3001_write_event_config(struct iio_dev *iio,
 	mode = state ? OPT3001_CONFIGURATION_M_CONTINUOUS
 		: OPT3001_CONFIGURATION_M_SHUTDOWN;
 
-	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_CONFIGURATION);
+	ret = i2c_smbus_read_word_swapped(client, OPT3001_CONFIGURATION);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
-				OPT3001_CONFIGURATION);
+		dev_err(dev, "failed to read register %02x\n",
+			OPT3001_CONFIGURATION);
 		goto err;
 	}
 
 	reg = ret;
 	opt3001_set_mode(opt, &reg, mode);
 
-	ret = i2c_smbus_write_word_swapped(opt->client, OPT3001_CONFIGURATION,
-			reg);
+	ret = i2c_smbus_write_word_swapped(client, OPT3001_CONFIGURATION, reg);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to write register %02x\n",
-				OPT3001_CONFIGURATION);
+		dev_err(dev, "failed to write register %02x\n",
+			OPT3001_CONFIGURATION);
 		goto err;
 	}
 
@@ -688,44 +691,48 @@ static const struct iio_info opt3001_info = {
 
 static int opt3001_read_id(struct opt3001 *opt)
 {
+	struct i2c_client *client = opt->client;
+	struct device *dev = &client->dev;
 	char manufacturer[2];
 	u16 device_id;
 	int ret;
 
-	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_MANUFACTURER_ID);
+	ret = i2c_smbus_read_word_swapped(client, OPT3001_MANUFACTURER_ID);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
-				OPT3001_MANUFACTURER_ID);
+		dev_err(dev, "failed to read register %02x\n",
+			OPT3001_MANUFACTURER_ID);
 		return ret;
 	}
 
 	manufacturer[0] = ret >> 8;
 	manufacturer[1] = ret & 0xff;
 
-	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_DEVICE_ID);
+	ret = i2c_smbus_read_word_swapped(client, OPT3001_DEVICE_ID);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
+		dev_err(dev, "failed to read register %02x\n",
 			OPT3001_DEVICE_ID);
 		return ret;
 	}
 
 	device_id = ret;
 
-	dev_info(opt->dev, "Found %c%c OPT%04x\n", manufacturer[0],
-			manufacturer[1], device_id);
+	dev_info(dev, "Found %c%c OPT%04x\n", manufacturer[0], manufacturer[1],
+		 device_id);
 
 	return 0;
 }
 
 static int opt3001_configure(struct opt3001 *opt)
 {
+	struct i2c_client *client = opt->client;
+	struct device *dev = &client->dev;
 	int ret;
 	u16 reg;
 
-	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_CONFIGURATION);
+	ret = i2c_smbus_read_word_swapped(client, OPT3001_CONFIGURATION);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
-				OPT3001_CONFIGURATION);
+		dev_err(dev, "failed to read register %02x\n",
+			OPT3001_CONFIGURATION);
 		return ret;
 	}
 
@@ -750,28 +757,27 @@ static int opt3001_configure(struct opt3001 *opt)
 	reg &= ~OPT3001_CONFIGURATION_ME;
 	reg &= ~OPT3001_CONFIGURATION_FC_MASK;
 
-	ret = i2c_smbus_write_word_swapped(opt->client, OPT3001_CONFIGURATION,
-			reg);
+	ret = i2c_smbus_write_word_swapped(client, OPT3001_CONFIGURATION, reg);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to write register %02x\n",
-				OPT3001_CONFIGURATION);
+		dev_err(dev, "failed to write register %02x\n",
+			OPT3001_CONFIGURATION);
 		return ret;
 	}
 
-	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_LOW_LIMIT);
+	ret = i2c_smbus_read_word_swapped(client, OPT3001_LOW_LIMIT);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
-				OPT3001_LOW_LIMIT);
+		dev_err(dev, "failed to read register %02x\n",
+			OPT3001_LOW_LIMIT);
 		return ret;
 	}
 
 	opt->low_thresh_mantissa = OPT3001_REG_MANTISSA(ret);
 	opt->low_thresh_exp = OPT3001_REG_EXPONENT(ret);
 
-	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_HIGH_LIMIT);
+	ret = i2c_smbus_read_word_swapped(client, OPT3001_HIGH_LIMIT);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
-				OPT3001_HIGH_LIMIT);
+		dev_err(dev, "failed to read register %02x\n",
+			OPT3001_HIGH_LIMIT);
 		return ret;
 	}
 
@@ -785,6 +791,8 @@ static irqreturn_t opt3001_irq(int irq, void *_iio)
 {
 	struct iio_dev *iio = _iio;
 	struct opt3001 *opt = iio_priv(iio);
+	struct i2c_client *client = opt->client;
+	struct device *dev = &client->dev;
 	int ret;
 	bool wake_result_ready_queue = false;
 	enum iio_chan_type chan_type = opt->chip_info->chan_type;
@@ -793,10 +801,10 @@ static irqreturn_t opt3001_irq(int irq, void *_iio)
 	if (!ok_to_ignore_lock)
 		mutex_lock(&opt->lock);
 
-	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_CONFIGURATION);
+	ret = i2c_smbus_read_word_swapped(client, OPT3001_CONFIGURATION);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
-				OPT3001_CONFIGURATION);
+		dev_err(dev, "failed to read register %02x\n",
+			OPT3001_CONFIGURATION);
 		goto out;
 	}
 
@@ -815,10 +823,10 @@ static irqreturn_t opt3001_irq(int irq, void *_iio)
 							IIO_EV_DIR_FALLING),
 					iio_get_time_ns(iio));
 	} else if (ret & OPT3001_CONFIGURATION_CRF) {
-		ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_RESULT);
+		ret = i2c_smbus_read_word_swapped(client, OPT3001_RESULT);
 		if (ret < 0) {
-			dev_err(opt->dev, "failed to read register %02x\n",
-					OPT3001_RESULT);
+			dev_err(dev, "failed to read register %02x\n",
+				OPT3001_RESULT);
 			goto out;
 		}
 		opt->result = ret;
@@ -851,7 +859,6 @@ static int opt3001_probe(struct i2c_client *client)
 
 	opt = iio_priv(iio);
 	opt->client = client;
-	opt->dev = dev;
 	opt->chip_info = i2c_get_match_data(client);
 
 	mutex_init(&opt->lock);
@@ -885,7 +892,7 @@ static int opt3001_probe(struct i2c_client *client)
 		}
 		opt->use_irq = true;
 	} else {
-		dev_dbg(opt->dev, "enabling interrupt-less operation\n");
+		dev_dbg(dev, "enabling interrupt-less operation\n");
 	}
 
 	return iio_device_register(iio);
@@ -895,6 +902,7 @@ static void opt3001_remove(struct i2c_client *client)
 {
 	struct iio_dev *iio = i2c_get_clientdata(client);
 	struct opt3001 *opt = iio_priv(iio);
+	struct device *dev = &client->dev;
 	int ret;
 	u16 reg;
 
@@ -903,21 +911,20 @@ static void opt3001_remove(struct i2c_client *client)
 	if (opt->use_irq)
 		free_irq(client->irq, iio);
 
-	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_CONFIGURATION);
+	ret = i2c_smbus_read_word_swapped(client, OPT3001_CONFIGURATION);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
-				OPT3001_CONFIGURATION);
+		dev_err(dev, "failed to read register %02x\n",
+			OPT3001_CONFIGURATION);
 		return;
 	}
 
 	reg = ret;
 	opt3001_set_mode(opt, &reg, OPT3001_CONFIGURATION_M_SHUTDOWN);
 
-	ret = i2c_smbus_write_word_swapped(opt->client, OPT3001_CONFIGURATION,
-			reg);
+	ret = i2c_smbus_write_word_swapped(client, OPT3001_CONFIGURATION, reg);
 	if (ret < 0) {
-		dev_err(opt->dev, "failed to write register %02x\n",
-				OPT3001_CONFIGURATION);
+		dev_err(dev, "failed to write register %02x\n",
+			OPT3001_CONFIGURATION);
 	}
 }
 

-- 
2.47.3

