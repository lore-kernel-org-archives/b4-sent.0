From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Apr 2025 21:33:28 +0200
Subject: [PATCH v4 5/5] iio: light: al3320a: Implement regmap support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-al3010-iio-regmap-v4-5-d189bea87261@ixit.cz>
References: <20250402-al3010-iio-regmap-v4-0-d189bea87261@ixit.cz>
In-Reply-To: <20250402-al3010-iio-regmap-v4-0-d189bea87261@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5966; i=david@ixit.cz;
 h=from:subject:message-id; bh=KF7wfd386VFn0Qab9eMCBOMC7w8cF3bp15+z7GtVxKg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn7ZEKANUDM7It0EXHF5Zdp51cw6YGYAR+pS7gk
 diU+mWsUt2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+2RCgAKCRBgAj/E00kg
 choBEACyrkpl681CZgf8ZKOvVH6HO5wDcd0B4Hu9xdZHhuETVbVMknY0sYRNDwvdf4gSxjOcCW1
 siWO9ydJeNafHoi3uZZulQc84FnIx1/tC3YLBX9aVPAW9zsJPJM9e04HhW+LJWgOIZidhuzyWIJ
 SlFM4QfEJ82VDsZP58PvcYS2jhldS54Pb0mnUz4Db52zFKkncLclkByBye217sjPlPmwAqoJpcK
 uBaQFfzVW57nn4gB0dpHK5cTlcJtV6yVdbGp30yI84Tiht7wNvLbmUrQnmEeSumxw0vt4oHOSnC
 AvXIorG0/uUM9BnlpWOB9PRtTTlinjihN9iDCPg9ZzOwaFmDmQPWxZcz7EPl/UjhFVA5YdrCIY3
 uHpf7BZdtuVRbIBlurAOK1UmNo/gNODeFyR5Ls9rRXsuJ4KTeeyX9+OLonMujyJ/SlUEPkNtXO/
 pgWAGMCqKKa1jPQ9WTTU+g2N1CVeOMD7JsUMXnV9meQpqbYXtsazOseIYq/NQKgMsqwtkVJh3Ex
 EWx0kKIA1j4AxevvdsWXYyxI3ljTXix1Ke2M9GP7hTPWiRwkKEE2pJUKyxeM9czaLbotnIqhsQa
 /fv02G9Rdg9yb2s6J54xYGZ3F5oHYMtLSlT0Ke/2qRs9XctnnhtywP9d/XpZ9xqAJ6sRSLFAanz
 0qCT5mok3aauaNw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Modernize and clean up the driver using the regmap framework.

With the regmap implementation, the compiler produces
a significantly smaller module.

Size before: 72 kB
Size after:  58 kB

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3320a.c | 89 +++++++++++++++++++++++++--------------------
 1 file changed, 49 insertions(+), 40 deletions(-)

diff --git a/drivers/iio/light/al3320a.c b/drivers/iio/light/al3320a.c
index 1fa693d54ae2a6e5ead3a9c7ac7018afeba9b760..988a3dd3a8449f10c657eb75fd744b2a9db2965e 100644
--- a/drivers/iio/light/al3320a.c
+++ b/drivers/iio/light/al3320a.c
@@ -15,6 +15,7 @@
 #include <linux/bitfield.h>
 #include <linux/i2c.h>
 #include <linux/module.h>
+#include <linux/regmap.h>
 #include <linux/mod_devicetable.h>
 
 #include <linux/iio/iio.h>
@@ -57,8 +58,14 @@ static const int al3320a_scales[][2] = {
 	{0, 512000}, {0, 128000}, {0, 32000}, {0, 10000}
 };
 
+static const struct regmap_config al3320a_regmap_config = {
+	.reg_bits = 8,
+	.val_bits = 8,
+	.max_register = AL3320A_REG_HIGH_THRESH_HIGH,
+};
+
 struct al3320a_data {
-	struct i2c_client *client;
+	struct regmap *regmap;
 };
 
 static const struct iio_chan_spec al3320a_channels[] = {
@@ -80,50 +87,47 @@ static const struct attribute_group al3320a_attribute_group = {
 	.attrs = al3320a_attributes,
 };
 
-static int al3320a_set_pwr_on(struct i2c_client *client)
+static int al3320a_set_pwr_on(struct al3320a_data *data)
 {
-	return i2c_smbus_write_byte_data(client, AL3320A_REG_CONFIG, AL3320A_CONFIG_ENABLE);
+	return regmap_write(data->regmap, AL3320A_REG_CONFIG, AL3320A_CONFIG_ENABLE);
 }
 
 static void al3320a_set_pwr_off(void *_data)
 {
 	struct al3320a_data *data = _data;
+	struct device *dev = regmap_get_device(data->regmap);
+	int ret;
 
-	i2c_smbus_write_byte_data(data->client, AL3320A_REG_CONFIG, AL3320A_CONFIG_DISABLE);
+	ret = regmap_write(data->regmap, AL3320A_REG_CONFIG, AL3320A_CONFIG_DISABLE);
+	if (ret)
+		dev_err(dev, "failed to write system register\n");
 }
 
 static int al3320a_init(struct al3320a_data *data)
 {
+	struct device *dev = regmap_get_device(data->regmap);
 	int ret;
 
-	ret = al3320a_set_pwr_on(data->client);
-
-	if (ret < 0)
+	ret = al3320a_set_pwr_on(data);
+	if (ret)
 		return ret;
 
-	ret = devm_add_action_or_reset(&data->client->dev,
-				       al3320a_set_pwr_off,
-				       data);
+	ret = devm_add_action_or_reset(dev, al3320a_set_pwr_off, data);
 	if (ret)
-		return dev_err_probe(&data->client->dev, ret, "failed to add action\n");
-
-	ret = i2c_smbus_write_byte_data(data->client, AL3320A_REG_CONFIG_RANGE,
-					FIELD_PREP(AL3320A_GAIN_MASK,
-						   AL3320A_RANGE_3));
-	if (ret < 0)
-		return ret;
+		return dev_err_probe(dev, ret, "failed to add action\n");
 
-	ret = i2c_smbus_write_byte_data(data->client, AL3320A_REG_MEAN_TIME,
-					AL3320A_DEFAULT_MEAN_TIME);
-	if (ret < 0)
+	ret = regmap_write(data->regmap, AL3320A_REG_CONFIG_RANGE,
+			   FIELD_PREP(AL3320A_GAIN_MASK, AL3320A_RANGE_3));
+	if (ret)
 		return ret;
 
-	ret = i2c_smbus_write_byte_data(data->client, AL3320A_REG_WAIT,
-					AL3320A_DEFAULT_WAIT_TIME);
-	if (ret < 0)
+	ret = regmap_write(data->regmap, AL3320A_REG_MEAN_TIME,
+			   AL3320A_DEFAULT_MEAN_TIME);
+	if (ret)
 		return ret;
 
-	return 0;
+	return regmap_write(data->regmap, AL3320A_REG_WAIT,
+			    AL3320A_DEFAULT_WAIT_TIME);
 }
 
 static int al3320a_read_raw(struct iio_dev *indio_dev,
@@ -131,7 +135,7 @@ static int al3320a_read_raw(struct iio_dev *indio_dev,
 			    int *val2, long mask)
 {
 	struct al3320a_data *data = iio_priv(indio_dev);
-	int ret;
+	int ret, gain, raw;
 
 	switch (mask) {
 	case IIO_CHAN_INFO_RAW:
@@ -140,21 +144,21 @@ static int al3320a_read_raw(struct iio_dev *indio_dev,
 		 * - low byte of output is stored at AL3320A_REG_DATA_LOW
 		 * - high byte of output is stored at AL3320A_REG_DATA_LOW + 1
 		 */
-		ret = i2c_smbus_read_word_data(data->client,
-					       AL3320A_REG_DATA_LOW);
-		if (ret < 0)
+		ret = regmap_read(data->regmap, AL3320A_REG_DATA_LOW, &raw);
+		if (ret)
 			return ret;
-		*val = ret;
+
+		*val = raw;
+
 		return IIO_VAL_INT;
 	case IIO_CHAN_INFO_SCALE:
-		ret = i2c_smbus_read_byte_data(data->client,
-					       AL3320A_REG_CONFIG_RANGE);
-		if (ret < 0)
+		ret = regmap_read(data->regmap, AL3320A_REG_CONFIG_RANGE, &gain);
+		if (ret)
 			return ret;
 
-		ret = FIELD_GET(AL3320A_GAIN_MASK, ret);
-		*val = al3320a_scales[ret][0];
-		*val2 = al3320a_scales[ret][1];
+		gain = FIELD_GET(AL3320A_GAIN_MASK, gain);
+		*val = al3320a_scales[gain][0];
+		*val2 = al3320a_scales[gain][1];
 
 		return IIO_VAL_INT_PLUS_MICRO;
 	}
@@ -175,9 +179,8 @@ static int al3320a_write_raw(struct iio_dev *indio_dev,
 			    val2 != al3320a_scales[i][1])
 				continue;
 
-			return i2c_smbus_write_byte_data(data->client,
-					AL3320A_REG_CONFIG_RANGE,
-					FIELD_PREP(AL3320A_GAIN_MASK, i));
+			return regmap_write(data->regmap, AL3320A_REG_CONFIG_RANGE,
+					    FIELD_PREP(AL3320A_GAIN_MASK, i));
 		}
 		break;
 	}
@@ -203,7 +206,11 @@ static int al3320a_probe(struct i2c_client *client)
 
 	data = iio_priv(indio_dev);
 	i2c_set_clientdata(client, indio_dev);
-	data->client = client;
+
+	data->regmap = devm_regmap_init_i2c(client, &al3320a_regmap_config);
+	if (IS_ERR(data->regmap))
+		return dev_err_probe(dev, PTR_ERR(data->regmap),
+				     "cannot allocate regmap\n");
 
 	indio_dev->info = &al3320a_info;
 	indio_dev->name = "al3320a";
@@ -230,7 +237,9 @@ static int al3320a_suspend(struct device *dev)
 
 static int al3320a_resume(struct device *dev)
 {
-	return al3320a_set_pwr_on(to_i2c_client(dev));
+	struct al3320a_data *data = iio_priv(dev_get_drvdata(dev));
+
+	return al3320a_set_pwr_on(data);
 }
 
 static DEFINE_SIMPLE_DEV_PM_OPS(al3320a_pm_ops, al3320a_suspend,

-- 
2.49.0

