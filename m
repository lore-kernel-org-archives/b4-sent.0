From: Mizuno Miotsuki <founder@crepuse.com>
Date: Wed, 14 Oct 2026 06:45:11 +0800
Subject: [PATCH v5 3/3] Input: add Nsiway NS2009 resistive touchscreen
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-review-self-ns2009-v4-20261013-v5-3-0851740cd939@crepuse.com>
References: <20261014-review-self-ns2009-v4-20261013-v5-0-0851740cd939@crepuse.com>
In-Reply-To: <20261014-review-self-ns2009-v4-20261013-v5-0-0851740cd939@crepuse.com>
To: dmitry.torokhov@gmail.com
Cc: krzk+dt@kernel.org, linux-input@vger.kernel.org, 
 linux-kernel@vger.kernel.org, icenowy@aosc.io, conor+dt@kernel.org, 
 robh@kernel.org, devicetree@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=9878; i=founder@crepuse.com;
 s=20261012; h=from:subject:message-id;
 bh=TDCTyGDEUKd8X8csU6CJK+bDq8VurdV+ZeVGdvYWx+w=;
 b=owGbwMvMwCUmds2G2fVJ/hLG02pJDFnntpQ5nvrc3/AllueG4ITiRBMH6+C2kK777/Yl5X69u
 tha1dG+YyILgxgXg6WYIstsUfbyQ80rrs2d0GQHM4eVCWSItEgDAxCwMPDlJuaVGukY6ZlqG+oZ
 GukY6BgzcHEKwFTrLmdkOPCX3Z5p7kbOVYpShXcunWtVM38Rf1DszJ0nv0QTHzz7cIvhn5XsxTN
 t54q32n2eOGm7h8sHLtk6UdXXcYJnYuzY4n0L+AE=
X-Developer-Key: i=founder@crepuse.com; a=openpgp;
 fpr=9B150777C283A8D69D90823E16D63C0345E46FA4
X-Endpoint-Received: by B4 Relay for founder@crepuse.com/20261012 with auth_id=1166
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a polling driver for the NS2009 four-wire resistive touchscreen
controller, derived from Icenowy Zheng's original implementation.

Read 12-bit X, Y and Z1 samples every 30 ms. Validate the two-byte response
and its zero padding, discard incomplete samples and release contact on
read errors. Report touch state on every valid sample so input-core state
resets cannot strand a held contact. Apply common touchscreen transforms
and a configurable raw Z1 contact threshold.

Acquire VDD and an optional external VREF. Enable supplies when input is
opened and disable them after polling stops. Preserve an outstanding
reference if disable fails so reopening cannot accumulate references;
retry cleanup after input unregisters.

Touch reporting and input lifecycle tests passed on an UNIHIKER M10 V1.2
using the real shared vcc_io regulator. Tests used a registration-name-only
validation module and a temporary live-DT supply property. The shared rail
remained always-on; no electrical power switching is claimed.

Signed-off-by: Mizuno Miotsuki <founder@crepuse.com>
---
 MAINTAINERS                        |   1 +
 drivers/input/touchscreen/Kconfig  |  10 ++
 drivers/input/touchscreen/Makefile |   1 +
 drivers/input/touchscreen/ns2009.c | 230 +++++++++++++++++++++++++++++++++++++
 4 files changed, 242 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 696f2badc49c..e282c02ec13f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -19472,6 +19472,7 @@ M:	Mizuno Miotsuki <founder@crepuse.com>
 L:	linux-input@vger.kernel.org
 S:	Maintained
 F:	Documentation/devicetree/bindings/input/touchscreen/nsiway,ns2009.yaml
+F:	drivers/input/touchscreen/ns2009.c
 
 NTB AMD DRIVER
 M:	Basavaraj Natikar <Basavaraj.Natikar@amd.com>
diff --git a/drivers/input/touchscreen/Kconfig b/drivers/input/touchscreen/Kconfig
index 9b9ae8ac3f7f..d4cdf1a7e057 100644
--- a/drivers/input/touchscreen/Kconfig
+++ b/drivers/input/touchscreen/Kconfig
@@ -691,6 +691,16 @@ config TOUCHSCREEN_MTOUCH
 	  To compile this driver as a module, choose M here: the
 	  module will be called mtouch.
 
+config TOUCHSCREEN_NS2009
+	tristate "Nsiway NS2009 touchscreen controller"
+	depends on I2C
+	help
+	  Say Y here if you have a resistive touchscreen using the Nsiway
+	  NS2009 controller connected over I2C.
+
+	  To compile this driver as a module, choose M here: the module will be
+	  called ns2009.
+
 config TOUCHSCREEN_NOVATEK_NVT_TS
 	tristate "Novatek NT11205 touchscreen support"
 	depends on I2C
diff --git a/drivers/input/touchscreen/Makefile b/drivers/input/touchscreen/Makefile
index bfd9de83389d..c5fc2062d7cf 100644
--- a/drivers/input/touchscreen/Makefile
+++ b/drivers/input/touchscreen/Makefile
@@ -68,6 +68,7 @@ obj-$(CONFIG_TOUCHSCREEN_MIGOR)		+= migor_ts.o
 obj-$(CONFIG_TOUCHSCREEN_MMS114)	+= mms114.o
 obj-$(CONFIG_TOUCHSCREEN_MSG2638)	+= msg2638.o
 obj-$(CONFIG_TOUCHSCREEN_MTOUCH)	+= mtouch.o
+obj-$(CONFIG_TOUCHSCREEN_NS2009)	+= ns2009.o
 obj-$(CONFIG_TOUCHSCREEN_NOVATEK_NVT_TS)	+= novatek-nvt-ts.o
 obj-$(CONFIG_TOUCHSCREEN_HP600)		+= hp680_ts_input.o
 obj-$(CONFIG_TOUCHSCREEN_HP7XX)		+= jornada720_ts.o
diff --git a/drivers/input/touchscreen/ns2009.c b/drivers/input/touchscreen/ns2009.c
new file mode 100644
index 000000000000..9d9af1dc9542
--- /dev/null
+++ b/drivers/input/touchscreen/ns2009.c
@@ -0,0 +1,230 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Nsiway NS2009 resistive touchscreen controller
+ *
+ * Copyright (C) 2017 Icenowy Zheng <icenowy@aosc.xyz>
+ * Portions derived from silead.c:
+ * Copyright (C) 2014-2015 Intel Corporation
+ */
+
+#include <linux/i2c.h>
+#include <linux/input.h>
+#include <linux/input/touchscreen.h>
+#include <linux/module.h>
+#include <linux/property.h>
+#include <linux/regulator/consumer.h>
+
+#define NS2009_POLL_INTERVAL_MS		30
+#define NS2009_MAX_12BIT		0xfff
+
+#define NS2009_READ_X_LOW_POWER_12BIT	0xc0
+#define NS2009_READ_Y_LOW_POWER_12BIT	0xd0
+#define NS2009_READ_Z1_LOW_POWER_12BIT	0xe0
+
+/* Historical driver default; boards may override via firmware properties. */
+#define NS2009_DEFAULT_PEN_DOWN_Z1	80
+
+struct ns2009_data {
+	struct i2c_client *client;
+	struct touchscreen_properties prop;
+	struct regulator_bulk_data supplies[2];
+	unsigned int num_supplies;
+	bool supplies_enabled;
+	u16 pen_down_z1;
+};
+
+static int ns2009_read_data(struct ns2009_data *data, u8 command, u16 *value)
+{
+	u8 raw[2];
+	int error;
+
+	error = i2c_smbus_read_i2c_block_data(data->client, command,
+					      sizeof(raw), raw);
+	if (error < 0)
+		return error;
+	if (error != sizeof(raw))
+		return -EIO;
+	/* The 12-bit result is left-aligned; the remaining bits must be zero. */
+	if (raw[1] & 0x0f) {
+		dev_err_ratelimited(&data->client->dev,
+				    "invalid sample for command %#02x: %02x %02x\n",
+				    command, raw[0], raw[1]);
+		return -EIO;
+	}
+
+	*value = (raw[0] << 4) | (raw[1] >> 4);
+	return 0;
+}
+
+static void ns2009_poll(struct input_dev *input)
+{
+	struct ns2009_data *data = input_get_drvdata(input);
+	u16 x, y, z1;
+	int error;
+
+	error = ns2009_read_data(data, NS2009_READ_Z1_LOW_POWER_12BIT, &z1);
+	if (error)
+		goto read_error;
+
+	if (z1 < data->pen_down_z1)
+		goto release;
+
+	error = ns2009_read_data(data, NS2009_READ_X_LOW_POWER_12BIT, &x);
+	if (error)
+		goto read_error;
+
+	error = ns2009_read_data(data, NS2009_READ_Y_LOW_POWER_12BIT, &y);
+	if (error)
+		goto read_error;
+
+	/* The input core filters repeats and may independently clear key state. */
+	input_report_key(input, BTN_TOUCH, 1);
+	touchscreen_report_pos(input, &data->prop, x, y, false);
+	input_sync(input);
+	return;
+
+read_error:
+	dev_err_ratelimited(&data->client->dev,
+			    "failed to poll touch data: %d\n", error);
+	/* An unreadable sample must not leave an active touch stuck down. */
+release:
+	input_report_key(input, BTN_TOUCH, 0);
+	input_sync(input);
+}
+
+static void ns2009_power_off(void *arg)
+{
+	struct ns2009_data *data = arg;
+	int error;
+
+	if (!data->supplies_enabled)
+		return;
+
+	error = regulator_bulk_disable(data->num_supplies, data->supplies);
+	if (error)
+		dev_err(&data->client->dev, "failed to disable supplies: %d\n",
+			error);
+	else
+		data->supplies_enabled = false;
+}
+
+static int ns2009_open(struct input_dev *input)
+{
+	struct ns2009_data *data = input_get_drvdata(input);
+	int error;
+
+	if (data->supplies_enabled)
+		return 0;
+
+	error = regulator_bulk_enable(data->num_supplies, data->supplies);
+	if (!error)
+		data->supplies_enabled = true;
+	return error;
+}
+
+static void ns2009_close(struct input_dev *input)
+{
+	ns2009_power_off(input_get_drvdata(input));
+}
+
+static int ns2009_probe(struct i2c_client *client)
+{
+	struct device *dev = &client->dev;
+	struct ns2009_data *data;
+	struct input_dev *input;
+	u32 value;
+	int error;
+
+	if (!i2c_check_functionality(client->adapter,
+				     I2C_FUNC_SMBUS_READ_I2C_BLOCK))
+		return dev_err_probe(dev, -EOPNOTSUPP,
+				     "required SMBus block read is unavailable\n");
+
+	data = devm_kzalloc(dev, sizeof(*data), GFP_KERNEL);
+	if (!data)
+		return -ENOMEM;
+
+	data->client = client;
+	data->supplies[0].supply = "vdd";
+	data->num_supplies = 1;
+	if (device_property_present(dev, "vref-supply")) {
+		data->supplies[1].supply = "vref";
+		data->num_supplies++;
+	}
+
+	error = devm_regulator_bulk_get(dev, data->num_supplies, data->supplies);
+	if (error)
+		return dev_err_probe(dev, error, "failed to get supplies\n");
+
+	error = devm_add_action_or_reset(dev, ns2009_power_off, data);
+	if (error)
+		return error;
+
+	input = devm_input_allocate_device(dev);
+	if (!input)
+		return -ENOMEM;
+	data->pen_down_z1 = NS2009_DEFAULT_PEN_DOWN_Z1;
+	if (device_property_present(dev, "touchscreen-min-pressure")) {
+		error = device_property_read_u32(dev, "touchscreen-min-pressure",
+						 &value);
+		if (error)
+			return dev_err_probe(dev, error,
+					     "failed to read touchscreen-min-pressure\n");
+		if (!value || value > NS2009_MAX_12BIT)
+			return dev_err_probe(dev, -EINVAL,
+					     "touchscreen-min-pressure must be 1..4095\n");
+		data->pen_down_z1 = value;
+	}
+	input_set_drvdata(input, data);
+
+	input->name = "ns2009_ts";
+	input->phys = "input/ts";
+	input->open = ns2009_open;
+	input->close = ns2009_close;
+	input->id.bustype = BUS_I2C;
+
+	__set_bit(INPUT_PROP_DIRECT, input->propbit);
+	input_set_capability(input, EV_KEY, BTN_TOUCH);
+	input_set_abs_params(input, ABS_X, 0, NS2009_MAX_12BIT, 32, 0);
+	input_set_abs_params(input, ABS_Y, 0, NS2009_MAX_12BIT, 16, 0);
+	touchscreen_parse_properties(input, false, &data->prop);
+
+	error = input_setup_polling(input, ns2009_poll);
+	if (error)
+		return dev_err_probe(dev, error, "failed to set up polling\n");
+
+	input_set_poll_interval(input, NS2009_POLL_INTERVAL_MS);
+
+	error = input_register_device(input);
+	if (error)
+		return dev_err_probe(dev, error,
+				     "failed to register input device\n");
+
+	return 0;
+}
+
+static const struct i2c_device_id ns2009_id[] = {
+	{ .name = "ns2009" },
+	{ }
+};
+MODULE_DEVICE_TABLE(i2c, ns2009_id);
+
+static const struct of_device_id ns2009_of_match[] = {
+	{ .compatible = "nsiway,ns2009" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, ns2009_of_match);
+
+static struct i2c_driver ns2009_driver = {
+	.driver = {
+		.name = "ns2009",
+		.of_match_table = ns2009_of_match,
+	},
+	.probe = ns2009_probe,
+	.id_table = ns2009_id,
+};
+module_i2c_driver(ns2009_driver);
+
+MODULE_AUTHOR("Icenowy Zheng <icenowy@aosc.xyz>");
+MODULE_DESCRIPTION("Nsiway NS2009 resistive touchscreen controller");
+MODULE_LICENSE("GPL");

-- 
2.56.0

