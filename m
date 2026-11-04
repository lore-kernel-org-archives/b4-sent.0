From: David Heidelberg <david@ixit.cz>
Date: Wed, 04 Nov 2026 13:54:44 +0100
Subject: [PATCH RFC 2/3] Input: edt-ft5x06 - Add wakeup gesture support for
 FT5452
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-ft5x06-double-tap-v1-2-5a1bd80449cc@ixit.cz>
References: <20261104-ft5x06-double-tap-v1-0-5a1bd80449cc@ixit.cz>
In-Reply-To: <20261104-ft5x06-double-tap-v1-0-5a1bd80449cc@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=13370; i=david@ixit.cz;
 h=from:subject:message-id; bh=KmrVG8bORpPlzaoHJqTUKCMDtogeujd5DQdKPAb8i6I=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq6ytM9W23tfBV0hr1CTOPTsuqZgXUPkNuW5/km
 NcF9Vu6/NOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCausrTAAKCRBgAj/E00kg
 cjAAEACEyl4tUCTQckCepGcmcYAlMb2qvzlS8vHcviaU66FCbYNLg0eV9diPIRRi+fBpGq1KRBY
 fvLi4R3FrMfzURPD/z9tLgM5PIltEBobfX5g8B9Wk6PTwI14qDgrgez73mwrQpSpdmBaW8MsLH7
 LKXOqxqjSNAXQNNqhhvYG2jIGz1UNhJU/FL7JlYCEFxR6x05DNuSdQb+Jmw5UVgN4TlQ9TTQlgr
 sfIr+kOpwYv3/X0gazRU5T3C7KYlt+7yOxAkG7/QPKjiC8pwO3lRSqCj1psdXy1TFx1WnSfnAtP
 IUuSIgy9zdvBY5AvlDyYtWekQiFrroPJdnr+UppgaPJdZNBP23GapytuhmFr3RsufT6ZV6I1GKv
 FQl/rEbQoep1D2g77yWQ50klR0iVcueHvh2SG7R530bKkR2frh0CaBDKKLsAA0LokmAwgQBrGl2
 gTDD63lEZKFDQW4diMk5voaLmaHXmkUj4XypUSGAwCAOuvXUldb0G1hfdXFIlT+toMMLnunOqAZ
 U/Tx6Yyx4fKeOsP4qxfBx1amgnghi05StwvGP+8CblZNajHaIpEbXN1z7hf6YkhBamXIANBrPNg
 hy8cTgZEzGcZBM33vknEaefHMB/yKtRUvkbutiFrOr5JRrutLjYbBxUQd12YR3jKNTBBhNu7iBC
 GKFbi9Lj2b+x/gw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FocalTech firmware has a gesture mode in which the controller keeps
looking for the gestures enabled in its mask register and raises the
interrupt when one is seen. Build the mask from the event child nodes
in the device tree and report each detected gesture as the key code the
node carries, on a separate "edt-ft5x06 gestures" input device.

The separate device is what lets the gesture reach userspace when the
touchscreen input device is closed, which is also the moment the
gesture mode is entered: a compositor that closes the touchscreen when
it blanks the display, or inhibits it through the "inhibited"
attribute, can so keep only the gesture device open and turn the screen
back on from a double tap, which is what the vendor kernels do through
their display notifiers. Opening the touchscreen again leaves gesture
mode.

The mode is also entered on system suspend when the device is allowed
to wake the system, in place of powering the controller off, and the
interrupt line is left to the PM core as the wake source.

Boards relying on the current wakeup-source behaviour, where the
controller keeps scanning and any touch wakes the system, are
unaffected: without event nodes nothing changes, and the nodes are only
read for chips known to implement the gesture registers, for now the
FT5452.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/edt-ft5x06.c | 205 ++++++++++++++++++++++++++++++++-
 1 file changed, 201 insertions(+), 4 deletions(-)

diff --git a/drivers/input/touchscreen/edt-ft5x06.c b/drivers/input/touchscreen/edt-ft5x06.c
index e69d64c3db2dd..fc810d68409cf 100644
--- a/drivers/input/touchscreen/edt-ft5x06.c
+++ b/drivers/input/touchscreen/edt-ft5x06.c
@@ -58,33 +58,58 @@
 #define EV_REGISTER_OFFSET_X		0x46
 
 #define NO_REGISTER			0xff
 
 #define WORK_REGISTER_OPMODE		0x3c
 #define FACTORY_REGISTER_OPMODE		0x01
 #define PMOD_REGISTER_OPMODE		0xa5
 
+#define GESTURE_REGISTER_EN		0xd0
+#define GESTURE_REGISTER_MASK		0xd1
+#define GESTURE_REGISTER_OUTPUT		0xd3
+
+/*
+ * The gesture ID reported in GESTURE_REGISTER_OUTPUT also gives the position
+ * of the gesture's bit in GESTURE_REGISTER_MASK.
+ */
+#define GESTURE_ID_FIRST		0x20
+
 #define TOUCH_EVENT_DOWN		0x00
 #define TOUCH_EVENT_UP			0x01
 #define TOUCH_EVENT_ON			0x02
 #define TOUCH_EVENT_RESERVED		0x03
 
 #define EDT_NAME_LEN			23
+#define EDT_GESTURE_DEV_NAME		"edt-ft5x06 gestures"
 #define EDT_SWITCH_MODE_RETRIES		10
 #define EDT_SWITCH_MODE_DELAY		5 /* msec */
 #define EDT_RAW_DATA_RETRIES		100
 #define EDT_RAW_DATA_DELAY		1000 /* usec */
 
 #define EDT_DEFAULT_NUM_X		1024
 #define EDT_DEFAULT_NUM_Y		1024
 
 #define M06_REG_CMD(factory) ((factory) ? 0xf3 : 0xfc)
 #define M06_REG_ADDR(factory, addr) ((factory) ? (addr) & 0x7f : (addr) & 0x3f)
 
+/* FocalTech gestures: DT event node and the gesture ID */
+struct edt_ft5x06_gesture {
+	const char *node;
+	u8 id;
+};
+
+static const struct edt_ft5x06_gesture edt_ft5x06_gestures[] = {
+	{ "event-swipe-left",	0x20 },
+	{ "event-swipe-right",	0x21 },
+	{ "event-swipe-up",	0x22 },
+	{ "event-swipe-down",	0x23 },
+	{ "event-tap-double",	0x24 },
+};
+
 enum edt_pmode {
 	EDT_PMODE_NOT_SUPPORTED,
 	EDT_PMODE_HIBERNATE,
 	EDT_PMODE_POWEROFF,
 };
 
 enum edt_ver {
 	EDT_M06,
@@ -103,16 +128,17 @@ struct edt_reg_addr {
 	int reg_offset_y;
 	int reg_num_x;
 	int reg_num_y;
 };
 
 struct edt_ft5x06_ts_data {
 	struct i2c_client *client;
 	struct input_dev *input;
+	struct input_dev *gesture_input;
 	struct touchscreen_properties prop;
 	u16 num_x;
 	u16 num_y;
 	struct regulator *vcc;
 	struct regulator *iovcc;
 
 	struct gpio_desc *reset_gpio;
 	struct gpio_desc *wake_gpio;
@@ -121,40 +147,44 @@ struct edt_ft5x06_ts_data {
 
 #if defined(CONFIG_DEBUG_FS)
 	u8 *raw_buffer;
 	size_t raw_bufsize;
 #endif
 
 	struct mutex mutex;
 	bool factory_mode;
+	bool in_gesture_mode;
 	enum edt_pmode suspend_mode;
 	int threshold;
 	int gain;
 	int offset;
 	int offset_x;
 	int offset_y;
 	int report_rate;
 	int max_support_points;
 	int point_len;
+	unsigned int gesture_code[ARRAY_SIZE(edt_ft5x06_gestures)];
+	u8 gesture_mask;
 	u8 tdata_cmd;
 	int tdata_len;
 	int tdata_offset;
 
 	char name[EDT_NAME_LEN];
 	char fw_version[EDT_NAME_LEN];
 
 	struct edt_reg_addr reg_addr;
 	enum edt_ver version;
 	unsigned int crc_errors;
 	unsigned int header_errors;
 };
 
 struct edt_i2c_chip_data {
 	int  max_support_points;
+	bool has_wake_gestures;
 };
 
 static const struct regmap_config edt_ft5x06_i2c_regmap_config = {
 	.reg_bits = 8,
 	.val_bits = 8,
 };
 
 static bool edt_ft5x06_ts_check_crc(struct edt_ft5x06_ts_data *tsdata,
@@ -290,24 +320,58 @@ static int edt_M06_i2c_write(void *context, const void *data, size_t count)
 
 static const struct regmap_config edt_M06_i2c_regmap_config = {
 	.reg_bits = 8,
 	.val_bits = 8,
 	.read = edt_M06_i2c_read,
 	.write = edt_M06_i2c_write,
 };
 
+static void edt_ft5x06_ts_report_gesture(struct edt_ft5x06_ts_data *tsdata)
+{
+	struct device *dev = &tsdata->client->dev;
+	unsigned int code = KEY_RESERVED;
+	unsigned int id;
+	int err;
+
+	err = regmap_read(tsdata->regmap, GESTURE_REGISTER_OUTPUT, &id);
+	if (err) {
+		dev_err_ratelimited(dev, "Unable to fetch gesture, error: %d\n",
+				    err);
+		return;
+	}
+
+	for (int i = 0; i < ARRAY_SIZE(edt_ft5x06_gestures); i++)
+		if (edt_ft5x06_gestures[i].id == id)
+			code = tsdata->gesture_code[i];
+
+	if (code == KEY_RESERVED) {
+		dev_dbg(dev, "unhandled gesture %#x\n", id);
+		return;
+	}
+
+	input_report_key(tsdata->gesture_input, code, 1);
+	input_sync(tsdata->gesture_input);
+	input_report_key(tsdata->gesture_input, code, 0);
+	input_sync(tsdata->gesture_input);
+}
+
 static irqreturn_t edt_ft5x06_ts_isr(int irq, void *dev_id)
 {
 	struct edt_ft5x06_ts_data *tsdata = dev_id;
 	struct device *dev = &tsdata->client->dev;
 	u8 rdbuf[63];
 	int i, type, x, y, id;
 	int error;
 
+	if (tsdata->in_gesture_mode) {
+		edt_ft5x06_ts_report_gesture(tsdata);
+		return IRQ_HANDLED;
+	}
+
 	memset(rdbuf, 0, sizeof(rdbuf));
 	error = regmap_bulk_read(tsdata->regmap, tsdata->tdata_cmd, rdbuf,
 				 tsdata->tdata_len);
 	if (error) {
 		dev_err_ratelimited(dev, "Unable to fetch data, error: %d\n",
 				    error);
 		goto out;
 	}
@@ -1108,16 +1172,120 @@ static void edt_ft5x06_exit_regmap(void *arg)
 static void edt_ft5x06_disable_regulators(void *arg)
 {
 	struct edt_ft5x06_ts_data *data = arg;
 
 	regulator_disable(data->vcc);
 	regulator_disable(data->iovcc);
 }
 
+static int edt_ft5x06_ts_set_gesture_mode(struct edt_ft5x06_ts_data *tsdata,
+					  bool enable)
+{
+	int err;
+
+	if (enable) {
+		err = regmap_write(tsdata->regmap, GESTURE_REGISTER_MASK,
+				   tsdata->gesture_mask);
+		if (err)
+			return err;
+	} else {
+		/* let the IRQ thread read the gesture that woke us first */
+		synchronize_irq(tsdata->client->irq);
+	}
+
+	err = regmap_write(tsdata->regmap, GESTURE_REGISTER_EN, enable);
+	if (err)
+		return err;
+
+	tsdata->in_gesture_mode = enable;
+
+	return 0;
+}
+
+/*
+ * The touchscreen is opened and closed by userspace, either by opening and
+ * closing its event device or through the "inhibited" attribute. Closing it
+ * is the moment to start looking for the wakeup gestures.
+ */
+static int edt_ft5x06_ts_open(struct input_dev *input)
+{
+	struct edt_ft5x06_ts_data *tsdata = input_get_drvdata(input);
+
+	if (!tsdata->in_gesture_mode)
+		return 0;
+
+	return edt_ft5x06_ts_set_gesture_mode(tsdata, false);
+}
+
+static void edt_ft5x06_ts_close(struct input_dev *input)
+{
+	struct edt_ft5x06_ts_data *tsdata = input_get_drvdata(input);
+	struct device *dev = &tsdata->client->dev;
+	int err;
+
+	if (!device_may_wakeup(dev))
+		return;
+
+	err = edt_ft5x06_ts_set_gesture_mode(tsdata, true);
+	if (err)
+		dev_warn(dev, "Failed to enter gesture mode: %d\n", err);
+}
+
+/*
+ * The gestures detected in gesture mode are reported on their own input
+ * device, so that they still reach userspace when the touchscreen input
+ * device has been closed.
+ */
+static int edt_ft5x06_ts_setup_gestures(struct edt_ft5x06_ts_data *tsdata)
+{
+	struct device *dev = &tsdata->client->dev;
+	struct input_dev *input = NULL;
+	struct fwnode_handle *child;
+	int err;
+
+	for (int i = 0; i < ARRAY_SIZE(edt_ft5x06_gestures); i++) {
+		const struct edt_ft5x06_gesture *gesture = &edt_ft5x06_gestures[i];
+		unsigned int code;
+
+		child = device_get_named_child_node(dev, gesture->node);
+		if (!child)
+			continue;
+
+		err = fwnode_property_read_u32(child, "linux,code", &code);
+		fwnode_handle_put(child);
+		if (err)
+			return dev_err_probe(dev, err, "%s: failed to read linux,code\n",
+					     gesture->node);
+
+		if (code == KEY_RESERVED)
+			continue;
+
+		if (!input) {
+			input = devm_input_allocate_device(dev);
+			if (!input)
+				return -ENOMEM;
+
+			input->name = EDT_GESTURE_DEV_NAME;
+			input->id.bustype = BUS_I2C;
+		}
+
+		input_set_capability(input, EV_KEY, code);
+		tsdata->gesture_code[i] = code;
+		tsdata->gesture_mask |= BIT(gesture->id - GESTURE_ID_FIRST);
+	}
+
+	if (!input)
+		return 0;
+
+	tsdata->gesture_input = input;
+
+	return input_register_device(input);
+}
+
 static int edt_ft5x06_ts_probe(struct i2c_client *client)
 {
 	const struct i2c_device_id *id = i2c_client_get_device_id(client);
 	const struct edt_i2c_chip_data *chip_data;
 	struct edt_ft5x06_ts_data *tsdata;
 	unsigned int val;
 	struct input_dev *input;
 	unsigned long irq_flags;
@@ -1295,16 +1463,27 @@ static int edt_ft5x06_ts_probe(struct i2c_client *client)
 
 	input_set_abs_params(input, ABS_MT_POSITION_X,
 			     0, tsdata->num_x * 64 - 1, 0, 0);
 	input_set_abs_params(input, ABS_MT_POSITION_Y,
 			     0, tsdata->num_y * 64 - 1, 0, 0);
 
 	touchscreen_parse_properties(input, true, &tsdata->prop);
 
+	if (chip_data->has_wake_gestures) {
+		error = edt_ft5x06_ts_setup_gestures(tsdata);
+		if (error)
+			return error;
+
+		if (tsdata->gesture_input) {
+			input->open = edt_ft5x06_ts_open;
+			input->close = edt_ft5x06_ts_close;
+		}
+	}
+
 	error = input_mt_init_slots(input, tsdata->max_support_points,
 				    INPUT_MT_DIRECT);
 	if (error) {
 		dev_err(&client->dev, "Unable to init MT slots.\n");
 		return error;
 	}
 
 	irq_flags = irq_get_trigger_type(client->irq);
@@ -1315,16 +1494,18 @@ static int edt_ft5x06_ts_probe(struct i2c_client *client)
 	error = devm_request_threaded_irq(&client->dev, client->irq,
 					  NULL, edt_ft5x06_ts_isr, irq_flags,
 					  client->name, tsdata);
 	if (error) {
 		dev_err(&client->dev, "Unable to request touchscreen IRQ.\n");
 		return error;
 	}
 
+	input_set_drvdata(input, tsdata);
+
 	error = input_register_device(input);
 	if (error)
 		return error;
 
 	edt_ft5x06_ts_prepare_debugfs(tsdata);
 
 	dev_dbg(&client->dev,
 		"EDT FT5x06 initialized: IRQ %d, WAKE pin %d, Reset pin %d.\n",
@@ -1344,18 +1525,23 @@ static void edt_ft5x06_ts_remove(struct i2c_client *client)
 
 static int edt_ft5x06_ts_suspend(struct device *dev)
 {
 	struct i2c_client *client = to_i2c_client(dev);
 	struct edt_ft5x06_ts_data *tsdata = i2c_get_clientdata(client);
 	struct gpio_desc *reset_gpio = tsdata->reset_gpio;
 	int ret;
 
-	if (device_may_wakeup(dev))
-		return 0;
+	if (device_may_wakeup(dev)) {
+		/* the IRQ stays enabled, the PM core arms it as the wake source */
+		if (!tsdata->gesture_input || tsdata->in_gesture_mode)
+			return 0;
+
+		return edt_ft5x06_ts_set_gesture_mode(tsdata, true);
+	}
 
 	if (tsdata->suspend_mode == EDT_PMODE_NOT_SUPPORTED)
 		return 0;
 
 	/* Enter hibernate mode. */
 	ret = regmap_write(tsdata->regmap, PMOD_REGISTER_OPMODE,
 			   PMOD_REGISTER_HIBERNATE);
 	if (ret)
@@ -1386,18 +1572,28 @@ static int edt_ft5x06_ts_suspend(struct device *dev)
 }
 
 static int edt_ft5x06_ts_resume(struct device *dev)
 {
 	struct i2c_client *client = to_i2c_client(dev);
 	struct edt_ft5x06_ts_data *tsdata = i2c_get_clientdata(client);
 	int ret = 0;
 
-	if (device_may_wakeup(dev))
-		return 0;
+	if (device_may_wakeup(dev)) {
+		if (!tsdata->in_gesture_mode)
+			return 0;
+
+		guard(mutex)(&tsdata->input->mutex);
+
+		/* stays armed until the input device is opened again */
+		if (!input_device_enabled(tsdata->input))
+			return 0;
+
+		return edt_ft5x06_ts_set_gesture_mode(tsdata, false);
+	}
 
 	if (tsdata->suspend_mode == EDT_PMODE_NOT_SUPPORTED)
 		return 0;
 
 	if (tsdata->suspend_mode == EDT_PMODE_POWEROFF) {
 		struct gpio_desc *reset_gpio = tsdata->reset_gpio;
 
 		/*
@@ -1455,16 +1651,17 @@ static const struct edt_i2c_chip_data edt_ft5x06_data = {
 };
 
 static const struct edt_i2c_chip_data edt_ft3518_data = {
 	.max_support_points = 10,
 };
 
 static const struct edt_i2c_chip_data edt_ft5452_data = {
 	.max_support_points = 5,
+	.has_wake_gestures = true,
 };
 
 static const struct edt_i2c_chip_data edt_ft5506_data = {
 	.max_support_points = 10,
 };
 
 static const struct edt_i2c_chip_data edt_ft6236_data = {
 	.max_support_points = 2,

-- 
2.55.0

