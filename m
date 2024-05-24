From: Joel Selvaraj <joelselvaraj.oss@gmail.com>
Date: Fri, 24 May 2024 09:39:20 -0500
Subject: [PATCH v2 3/3] Input: novatek-nvt-ts: add support for NT36672A
 touchscreen
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240524-nvt-ts-devicetree-regulator-support-v2-3-b74947038c44@gmail.com>
References: <20240524-nvt-ts-devicetree-regulator-support-v2-0-b74947038c44@gmail.com>
In-Reply-To: <20240524-nvt-ts-devicetree-regulator-support-v2-0-b74947038c44@gmail.com>
To: Hans de Goede <hdegoede@redhat.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 Joel Selvaraj <joelselvaraj.oss@gmail.com>
X-Mailer: b4 0.14-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716561588; l=5429;
 i=joelselvaraj.oss@gmail.com; s=20240420; h=from:subject:message-id;
 bh=iS/qydC+3ZyOwj/BFn5ZeWXmsLtQZbVeeksPZgAo5MU=;
 b=it6bM7idQMfK/9zprRb/BDnQ0I6+EMIqT/GWcPoiI4aCre6zWER6hYdZarF2jpU0n3F47QCl3
 6SnhCHRKA8KCQoBPzdUHXALe+CrZUeBtTpOZgvHZpkQw7yIj73yDMYN
X-Developer-Key: i=joelselvaraj.oss@gmail.com; a=ed25519;
 pk=qT4gsuVtlPE0Dpr+tQA/Fumm7wzVP6qfeVaY+6pX04s=
X-Endpoint-Received: by B4 Relay for joelselvaraj.oss@gmail.com/20240420 with auth_id=165
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend the novatek touchscreen driver to support NT36672A chip which
is found in phones like Xiaomi Poco F1 [1]. Added devicetree support for
the driver and used i2c chip data to handle the variation in chip id and
wake type. Also added vcc and iovcc regulators which are used to power
the touchscreen hardware.

[1] https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts?h=v6.9

Signed-off-by: Joel Selvaraj <joelselvaraj.oss@gmail.com>
---
 drivers/input/touchscreen/novatek-nvt-ts.c | 78 +++++++++++++++++++++++++++---
 1 file changed, 72 insertions(+), 6 deletions(-)

diff --git a/drivers/input/touchscreen/novatek-nvt-ts.c b/drivers/input/touchscreen/novatek-nvt-ts.c
index 224fd112b25a9..7a82a1b09f9d5 100644
--- a/drivers/input/touchscreen/novatek-nvt-ts.c
+++ b/drivers/input/touchscreen/novatek-nvt-ts.c
@@ -31,9 +31,6 @@
 #define NVT_TS_PARAMS_CHIP_ID		0x0e
 #define NVT_TS_PARAMS_SIZE		0x0f
 
-#define NVT_TS_SUPPORTED_WAKE_TYPE	0x05
-#define NVT_TS_SUPPORTED_CHIP_ID	0x05
-
 #define NVT_TS_MAX_TOUCHES		10
 #define NVT_TS_MAX_SIZE			4096
 
@@ -51,11 +48,18 @@ static const int nvt_ts_irq_type[4] = {
 	IRQF_TRIGGER_HIGH
 };
 
+struct nvt_ts_i2c_chip_data {
+	u8 wake_type;
+	u8 chip_id;
+};
+
 struct nvt_ts_data {
 	struct i2c_client *client;
 	struct input_dev *input;
 	struct gpio_desc *reset_gpio;
+	struct regulator_bulk_data regulators[2];
 	struct touchscreen_properties prop;
+	const struct nvt_ts_i2c_chip_data *chip;
 	int max_touches;
 	u8 buf[NVT_TS_TOUCH_SIZE * NVT_TS_MAX_TOUCHES];
 };
@@ -139,9 +143,23 @@ static irqreturn_t nvt_ts_irq(int irq, void *dev_id)
 	return IRQ_HANDLED;
 }
 
+static void nvt_ts_disable_regulators(void *_data)
+{
+	struct nvt_ts_data *data = _data;
+
+	regulator_bulk_disable(ARRAY_SIZE(data->regulators), data->regulators);
+}
+
 static int nvt_ts_start(struct input_dev *dev)
 {
 	struct nvt_ts_data *data = input_get_drvdata(dev);
+	int error;
+
+	error = regulator_bulk_enable(ARRAY_SIZE(data->regulators), data->regulators);
+	if (error) {
+		dev_err(&data->client->dev, "failed to enable regulators\n");
+		return error;
+	}
 
 	enable_irq(data->client->irq);
 	gpiod_set_value_cansleep(data->reset_gpio, 0);
@@ -155,6 +173,7 @@ static void nvt_ts_stop(struct input_dev *dev)
 
 	disable_irq(data->client->irq);
 	gpiod_set_value_cansleep(data->reset_gpio, 1);
+	nvt_ts_disable_regulators(data);
 }
 
 static int nvt_ts_suspend(struct device *dev)
@@ -199,9 +218,37 @@ static int nvt_ts_probe(struct i2c_client *client)
 	if (!data)
 		return -ENOMEM;
 
+	data->chip = device_get_match_data(&client->dev);
+	if (!data->chip)
+		return -EINVAL;
+
 	data->client = client;
 	i2c_set_clientdata(client, data);
 
+	/*
+	 * VCC is the analog voltage supply
+	 * IOVCC is the digital voltage supply
+	 */
+	data->regulators[0].supply = "vcc";
+	data->regulators[1].supply = "iovcc";
+	error = devm_regulator_bulk_get(dev, ARRAY_SIZE(data->regulators), data->regulators);
+	if (error) {
+		dev_err(dev, "cannot get regulators: %d\n", error);
+		return error;
+	}
+
+	error = regulator_bulk_enable(ARRAY_SIZE(data->regulators), data->regulators);
+	if (error) {
+		dev_err(dev, "failed to enable regulators\n");
+		return error;
+	}
+
+	error = devm_add_action_or_reset(dev, nvt_ts_disable_regulators, data);
+	if (error) {
+		dev_err(dev, "failed to install regulator disable handler\n");
+		return error;
+	}
+
 	data->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_LOW);
 	error = PTR_ERR_OR_ZERO(data->reset_gpio);
 	if (error) {
@@ -225,8 +272,8 @@ static int nvt_ts_probe(struct i2c_client *client)
 	if (width > NVT_TS_MAX_SIZE || height >= NVT_TS_MAX_SIZE ||
 	    data->max_touches > NVT_TS_MAX_TOUCHES ||
 	    irq_type >= ARRAY_SIZE(nvt_ts_irq_type) ||
-	    data->buf[NVT_TS_PARAMS_WAKE_TYPE] != NVT_TS_SUPPORTED_WAKE_TYPE ||
-	    data->buf[NVT_TS_PARAMS_CHIP_ID] != NVT_TS_SUPPORTED_CHIP_ID) {
+	    data->buf[NVT_TS_PARAMS_WAKE_TYPE] != data->chip->wake_type ||
+	    data->buf[NVT_TS_PARAMS_CHIP_ID] != data->chip->chip_id) {
 		dev_err(dev, "Unsupported touchscreen parameters: %*ph\n",
 			NVT_TS_PARAMS_SIZE, data->buf);
 		return -EIO;
@@ -277,8 +324,26 @@ static int nvt_ts_probe(struct i2c_client *client)
 	return 0;
 }
 
+static const struct nvt_ts_i2c_chip_data nvt_nt11205_ts_data = {
+	.wake_type = 0x05,
+	.chip_id = 0x05,
+};
+
+static const struct nvt_ts_i2c_chip_data nvt_nt36672a_ts_data = {
+	.wake_type = 0x01,
+	.chip_id = 0x08,
+};
+
+static const struct of_device_id nvt_ts_of_match[] = {
+	{ .compatible = "novatek,nt11205-ts", .data = &nvt_nt11205_ts_data },
+	{ .compatible = "novatek,nt36672a-ts", .data = &nvt_nt36672a_ts_data },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, nvt_ts_of_match);
+
 static const struct i2c_device_id nvt_ts_i2c_id[] = {
-	{ "NT11205-ts" },
+	{ "NT11205-ts", (unsigned long) &nvt_nt11205_ts_data },
+	{ "NT36672A-ts", (unsigned long) &nvt_nt36672a_ts_data },
 	{ }
 };
 MODULE_DEVICE_TABLE(i2c, nvt_ts_i2c_id);
@@ -287,6 +352,7 @@ static struct i2c_driver nvt_ts_driver = {
 	.driver = {
 		.name	= "novatek-nvt-ts",
 		.pm	= pm_sleep_ptr(&nvt_ts_pm_ops),
+		.of_match_table = nvt_ts_of_match,
 	},
 	.probe = nvt_ts_probe,
 	.id_table = nvt_ts_i2c_id,

-- 
2.45.1

