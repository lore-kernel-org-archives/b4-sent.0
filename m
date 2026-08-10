From: David Heidelberg <david@ixit.cz>
Date: Mon, 10 Aug 2026 17:21:41 +0200
Subject: [PATCH v5 2/3] Input: stmfts - support FTS5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-stmfts5-v5-2-0c737d929976@ixit.cz>
References: <20260810-stmfts5-v5-0-0c737d929976@ixit.cz>
In-Reply-To: <20260810-stmfts5-v5-0-0c737d929976@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-input@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=24622; i=david@ixit.cz;
 h=from:subject:message-id; bh=uzl29zunwst417gKVqUSjRchNdSL1GDmgRWUEOD+fwA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqeeyNBa9iDaFVbKA7y4/B+xWVmr44CQYNBFmdz
 j3HRko41SSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCannsjQAKCRBgAj/E00kg
 cqzXD/0YPi+lhLf83QqNGWMHYK9pvSBnwLdEHLL/Ezc8cZ8pZFVsWMdf8tZHFGtYBBpqsRNMckH
 dJJenpFf4wMV/lRPQFWXZK6GMR0J58/Nahpctf3JpjowibHhUIDK8WQnv9FnAj+ImtKxUelZbYP
 3J1Z3VeSGQ790wCIUCddnATCVUpUTHCJifRj4yYuqDQLHjUkueemf6HYeBBhNJIO6NP6lWTvNhE
 0NSTF/q68+EmMhbRGp5I542WOw8zxmM9zu5g1ENBy/GBo7mZ9Tv16YxmTsz21xbkBzPKRl5NuV6
 0/3mmrWKCRqD6XiiQd6Wr2OMy83NNXTD1asxaBNiHCxitQoyP14f8RRsR5VSiKhU3/3hQb4m8D1
 AqD6yWSPrsKi1cr2wpmtDB4cGgRS4OLNSx4qSKEfmGonBtA0Yj1JiXq9ZA7TtpgUDmDaxqpFrAS
 V/aHUa+CRkmrN7+fz/8Kh/Wm7Uoa1F5EUBBKdPJI27oIyrjPMt/4Lo/3FGM7IHIitbMEkU7HAvu
 TUwivh5sdylziTXU7tg7MMnvt8OQN5LRFBEK2Zniw1WDj1xyH2389gtoax/eYzg7b8m835+Pn/m
 cij4uSk1ZnnTkrpD3bB1caYtvGe6wVPq0utPqiFFmbpgeooeNv/uUiex0rhSczWmZi/kuW7wpd2
 UVAjVfaVGyRMw+Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FTS support SLPI and AP mode, introduce mode-switch GPIO to switch between
those two. Currently we can handle only full power AP mode, so we just
keep the AP on.

Useful for devices like Pixel 3 (blueline), Pixel 4a (sunfish),
Xiaomi Mi 8 (dipper), and many others.

Based on work of  Petr Hodina <petr.hodina@protonmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 430 ++++++++++++++++++++++++++++++++++---
 1 file changed, 396 insertions(+), 34 deletions(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index 972687797f826..1da113d7197e6 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -1,23 +1,27 @@
 // SPDX-License-Identifier: GPL-2.0
-// STMicroelectronics FTS Touchscreen device driver
-//
-// Copyright (c) 2017 Samsung Electronics Co., Ltd.
-// Copyright (c) 2017 Andi Shyti <andi@etezian.org>
+/* STMicroelectronics FTS Touchscreen device driver
+ *
+ * Copyright 2017 Samsung Electronics Co., Ltd.
+ * Copyright 2017 Andi Shyti <andi@etezian.org>
+ * Copyright David Heidelberg <david@ixit.cz>
+ * Copyright Petr Hodina <petr.hodina@protonmail.com>
+ */
 
 #include <linux/delay.h>
 #include <linux/gpio/consumer.h>
 #include <linux/i2c.h>
 #include <linux/input/mt.h>
 #include <linux/input/touchscreen.h>
 #include <linux/interrupt.h>
 #include <linux/irq.h>
 #include <linux/leds.h>
 #include <linux/module.h>
+#include <linux/of_device.h>
 #include <linux/pm_runtime.h>
 #include <linux/regulator/consumer.h>
 
 /* I2C commands */
 #define STMFTS_READ_INFO			0x80
 #define STMFTS_READ_STATUS			0x84
 #define STMFTS_READ_ONE_EVENT			0x85
 #define STMFTS_READ_ALL_EVENT			0x86
@@ -30,16 +34,17 @@
 #define STMFTS_SS_HOVER_SENSE_ON		0x95
 #define STMFTS_MS_KEY_SENSE_OFF			0x9a
 #define STMFTS_MS_KEY_SENSE_ON			0x9b
 #define STMFTS_SYSTEM_RESET			0xa0
 #define STMFTS_CLEAR_EVENT_STACK		0xa1
 #define STMFTS_FULL_FORCE_CALIBRATION		0xa2
 #define STMFTS_MS_CX_TUNING			0xa3
 #define STMFTS_SS_CX_TUNING			0xa4
+#define STMFTS5_SET_SCAN_MODE			0xa0
 
 /* events */
 #define STMFTS_EV_NO_EVENT			0x00
 #define STMFTS_EV_MULTI_TOUCH_DETECTED		0x02
 #define STMFTS_EV_MULTI_TOUCH_ENTER		0x03
 #define STMFTS_EV_MULTI_TOUCH_LEAVE		0x04
 #define STMFTS_EV_MULTI_TOUCH_MOTION		0x05
 #define STMFTS_EV_HOVER_ENTER			0x07
@@ -47,22 +52,42 @@
 #define STMFTS_EV_HOVER_MOTION			0x09
 #define STMFTS_EV_KEY_STATUS			0x0e
 #define STMFTS_EV_ERROR				0x0f
 #define STMFTS_EV_CONTROLLER_READY		0x10
 #define STMFTS_EV_SLEEP_OUT_CONTROLLER_READY	0x11
 #define STMFTS_EV_STATUS			0x16
 #define STMFTS_EV_DEBUG				0xdb
 
+/* events FTS5 */
+#define STMFTS5_EV_CONTROLLER_READY		0x03
+/* FTM5 event IDs (full byte, not masked) */
+#define STMFTS5_EV_MULTI_TOUCH_ENTER		0x13
+#define STMFTS5_EV_MULTI_TOUCH_MOTION		0x23
+#define STMFTS5_EV_MULTI_TOUCH_LEAVE		0x33
+#define STMFTS5_EV_STATUS_UPDATE		0x43
+#define STMFTS5_EV_USER_REPORT			0x53
+#define STMFTS5_EV_DEBUG			0xe3
+#define STMFTS5_EV_ERROR			0xf3
+
 /* multi touch related event masks */
 #define STMFTS_MASK_EVENT_ID			0x0f
 #define STMFTS_MASK_TOUCH_ID			0xf0
 #define STMFTS_MASK_LEFT_EVENT			0x0f
 #define STMFTS_MASK_X_MSB			0x0f
 #define STMFTS_MASK_Y_LSB			0xf0
+#define STMFTS5_MASK_TOUCH_TYPE			0x0f
+
+/* touch type classifications */
+#define STMFTS_TOUCH_TYPE_INVALID		0x00
+#define STMFTS_TOUCH_TYPE_FINGER		0x01
+#define STMFTS_TOUCH_TYPE_GLOVE			0x02
+#define STMFTS_TOUCH_TYPE_STYLUS		0x03
+#define STMFTS_TOUCH_TYPE_PALM			0x04
+#define STMFTS_TOUCH_TYPE_HOVER			0x05
 
 /* key related event masks */
 #define STMFTS_MASK_KEY_NO_TOUCH		0x00
 #define STMFTS_MASK_KEY_MENU			0x01
 #define STMFTS_MASK_KEY_BACK			0x02
 
 #define STMFTS_EVENT_SIZE	8
 #define STMFTS_STACK_DEPTH	32
@@ -71,19 +96,22 @@
 #define STMFTS_DEV_NAME		"stmfts"
 
 static const struct regulator_bulk_data stmfts_supplies[] = {
 	{ .supply = "vdd" },
 	{ .supply = "avdd" },
 };
 
 struct stmfts_data {
+	const struct stmfts_chip_ops *ops;
+
 	struct i2c_client *client;
 	struct input_dev *input;
 	struct gpio_desc *reset_gpio;
+	struct gpio_desc *mode_switch_gpio;
 	struct led_classdev led_cdev;
 	struct mutex mutex;
 
 	struct touchscreen_properties prop;
 
 	struct regulator_bulk_data *supplies;
 
 	/*
@@ -100,19 +128,31 @@ struct stmfts_data {
 
 	u8 data[STMFTS_DATA_MAX_SIZE];
 
 	struct completion cmd_done;
 
 	bool use_key;
 	bool led_status;
 	bool hover_enabled;
+	bool stylus_enabled;
 	bool running;
 };
 
+struct stmfts_chip_ops {
+	int  (*configure)(struct stmfts_data *sdata);
+	void (*power_off)(struct stmfts_data *sdata);
+	int  (*setup_input)(struct stmfts_data *sdata);
+	int  (*input_open)(struct input_dev *dev);
+	void (*input_close)(struct input_dev *dev);
+	void (*parse_events)(struct stmfts_data *sdata);
+	int  (*set_hover)(struct stmfts_data *sdata, bool enable);
+	int  (*runtime_resume)(struct stmfts_data *sdata);
+};
+
 static int stmfts_brightness_set(struct led_classdev *led_cdev,
 				 enum led_brightness value)
 {
 	struct stmfts_data *sdata = container_of(led_cdev,
 					struct stmfts_data, led_cdev);
 	int err;
 
 	if (value != sdata->led_status && sdata->ledvdd) {
@@ -165,16 +205,17 @@ static int stmfts_read_events(struct stmfts_data *sdata)
 
 	ret = i2c_transfer(sdata->client->adapter, msgs, ARRAY_SIZE(msgs));
 	if (ret < 0)
 		return ret;
 
 	return ret == ARRAY_SIZE(msgs) ? 0 : -EIO;
 }
 
+/* FTS4 event handling functions */
 static void stmfts_report_contact_event(struct stmfts_data *sdata,
 					const u8 event[])
 {
 	u8 slot_id = (event[0] & STMFTS_MASK_TOUCH_ID) >> 4;
 	u16 x = event[1] | ((event[2] & STMFTS_MASK_X_MSB) << 8);
 	u16 y = (event[2] >> 4) | (event[3] << 4);
 	u8 maj = event[4];
 	u8 min = event[5];
@@ -200,16 +241,114 @@ static void stmfts_report_contact_release(struct stmfts_data *sdata,
 	u8 slot_id = (event[0] & STMFTS_MASK_TOUCH_ID) >> 4;
 
 	input_mt_slot(sdata->input, slot_id);
 	input_mt_report_slot_inactive(sdata->input);
 
 	input_sync(sdata->input);
 }
 
+/* FTS5 event handling functions */
+static void stmfts5_report_contact_event(struct stmfts_data *sdata,
+					 const u8 event[])
+{
+	u8 area;
+	u8 maj;
+	u8 min;
+	/* FTM5 event format:
+	 * event[0] = event ID (0x13/0x23)
+	 * event[1] = touch type (low 4 bits) | touch ID (high 4 bits)
+	 * event[2] = X LSB
+	 * event[3] = X MSB (low 4 bits) | Y MSB (high 4 bits)
+	 * event[4] = Y LSB
+	 * event[5] = pressure
+	 * event[6] = major (low 4 bits) | minor (high 4 bits)
+	 * event[7] = minor (high 2 bits)
+	 */
+	u8 touch_id = (event[1] & STMFTS_MASK_TOUCH_ID) >> 4;
+	u8 touch_type = event[1] & STMFTS5_MASK_TOUCH_TYPE;
+	int x, y, distance;
+	unsigned int tool = MT_TOOL_FINGER;
+
+	/* Parse coordinates with better precision */
+	x = (((int)event[3] & STMFTS_MASK_X_MSB) << 8) | event[2];
+	y = ((int)event[4] << 4) | ((event[3] & STMFTS_MASK_Y_LSB) >> 4);
+
+	/* Parse pressure - ensure non-zero for active touch */
+	area = event[5];
+	if (area <= 0 && touch_type != STMFTS_TOUCH_TYPE_HOVER) {
+		/* Should not happen for contact events. Set minimum pressure
+		 * to prevent touch from being dropped
+		 */
+		dev_warn_once(&sdata->client->dev,
+			      "zero pressure on contact event, slot %d\n", touch_id);
+		area = 1;
+	}
+
+	/* Parse touch area with improved bit extraction */
+	maj = (((event[0] & 0x0C) << 2) | ((event[6] & 0xF0) >> 4));
+	min = (((event[7] & 0xC0) >> 2) | (event[6] & 0x0F));
+
+	/* Distance is 0 for touching, max for hovering */
+	distance = 0;
+
+	/* Classify touch type and set appropriate tool and parameters */
+	switch (touch_type) {
+	case STMFTS_TOUCH_TYPE_STYLUS:
+		if (sdata->stylus_enabled) {
+			tool = MT_TOOL_PEN;
+			break;
+		}
+		fallthrough; /* Report as finger if stylus not enabled */
+
+	case STMFTS_TOUCH_TYPE_FINGER:
+	case STMFTS_TOUCH_TYPE_GLOVE:
+		tool = MT_TOOL_FINGER;
+		break;
+
+	case STMFTS_TOUCH_TYPE_PALM:
+		/* Palm touch - report but can be filtered by userspace */
+		tool = MT_TOOL_PALM;
+		break;
+
+	case STMFTS_TOUCH_TYPE_HOVER:
+		tool = MT_TOOL_FINGER;
+		area = 0;
+		distance = 255;
+		break;
+
+	case STMFTS_TOUCH_TYPE_INVALID:
+	default:
+		dev_warn(&sdata->client->dev,
+			 "invalid touch type %d for slot %d\n",
+			 touch_type, touch_id);
+		return;
+	}
+
+	input_mt_slot(sdata->input, touch_id);
+	input_mt_report_slot_state(sdata->input, tool, true);
+
+	input_report_abs(sdata->input, ABS_MT_POSITION_X, x);
+	input_report_abs(sdata->input, ABS_MT_POSITION_Y, y);
+	input_report_abs(sdata->input, ABS_MT_TOUCH_MAJOR, maj);
+	input_report_abs(sdata->input, ABS_MT_TOUCH_MINOR, min);
+	input_report_abs(sdata->input, ABS_MT_PRESSURE, area);
+	input_report_abs(sdata->input, ABS_MT_DISTANCE, distance);
+}
+
+static void stmfts5_report_contact_release(struct stmfts_data *sdata,
+					   const u8 event[])
+{
+	/* FTM5 format: touch ID is in high 4 bits of event[1] */
+	u8 touch_id = (event[1] & STMFTS_MASK_TOUCH_ID) >> 4;
+
+	input_mt_slot(sdata->input, touch_id);
+	input_mt_report_slot_inactive(sdata->input);
+}
+
 static void stmfts_report_hover_event(struct stmfts_data *sdata,
 				      const u8 event[])
 {
 	u16 x = (event[2] << 4) | (event[4] >> 4);
 	u16 y = (event[3] << 4) | (event[4] & STMFTS_MASK_Y_LSB);
 	u8 z = event[5];
 
 	input_report_abs(sdata->input, ABS_X, x);
@@ -292,29 +431,72 @@ static void stmfts_parse_events(struct stmfts_data *sdata)
 
 		default:
 			dev_err(&sdata->client->dev,
 				"unknown event %#02x\n", event[0]);
 		}
 	}
 }
 
+static void stmfts5_parse_events(struct stmfts_data *sdata)
+{
+	for (int i = 0; i < STMFTS_STACK_DEPTH; i++) {
+		u8 *event = &sdata->data[i * STMFTS_EVENT_SIZE];
+
+		switch (event[0]) {
+		case STMFTS5_EV_CONTROLLER_READY:
+			complete(&sdata->cmd_done);
+			fallthrough;
+
+		case STMFTS_EV_NO_EVENT:
+		case STMFTS5_EV_STATUS_UPDATE:
+		case STMFTS5_EV_USER_REPORT:
+		case STMFTS5_EV_DEBUG:
+			goto sync;
+
+		case STMFTS5_EV_MULTI_TOUCH_ENTER:
+		case STMFTS5_EV_MULTI_TOUCH_MOTION:
+			stmfts5_report_contact_event(sdata, event);
+			break;
+
+		case STMFTS5_EV_MULTI_TOUCH_LEAVE:
+			stmfts5_report_contact_release(sdata, event);
+			break;
+
+		case STMFTS5_EV_ERROR:
+			dev_warn(&sdata->client->dev,
+				 "error code: 0x%x%x%x%x%x%x",
+				 event[6], event[5], event[4],
+				 event[3], event[2], event[1]);
+			break;
+
+		default:
+			dev_err(&sdata->client->dev,
+				"unknown FTS5 event %#02x\n", event[0]);
+		}
+	}
+
+sync:
+	input_mt_sync_frame(sdata->input);
+	input_sync(sdata->input);
+}
+
 static irqreturn_t stmfts_irq_handler(int irq, void *dev)
 {
 	struct stmfts_data *sdata = dev;
 	int err;
 
 	guard(mutex)(&sdata->mutex);
 
 	err = stmfts_read_events(sdata);
 	if (unlikely(err))
 		dev_err(&sdata->client->dev,
 			"failed to read events: %d\n", err);
 	else
-		stmfts_parse_events(sdata);
+		sdata->ops->parse_events(sdata);
 
 	return IRQ_HANDLED;
 }
 
 static int stmfts_command(struct stmfts_data *sdata, const u8 cmd)
 {
 	int err;
 
@@ -326,16 +508,29 @@ static int stmfts_command(struct stmfts_data *sdata, const u8 cmd)
 
 	if (!wait_for_completion_timeout(&sdata->cmd_done,
 					 msecs_to_jiffies(1000)))
 		return -ETIMEDOUT;
 
 	return 0;
 }
 
+static int stmfts5_set_scan_mode(struct stmfts_data *sdata, const u8 val)
+{
+	u8 scan_mode_cmd[3] = { STMFTS5_SET_SCAN_MODE, 0x00, val };
+	int err;
+
+	err = i2c_master_send(sdata->client, scan_mode_cmd,
+			      sizeof(scan_mode_cmd));
+	if (err != sizeof(scan_mode_cmd))
+		return err < 0 ? err : -EIO;
+
+	return 0;
+}
+
 static int stmfts_input_open(struct input_dev *dev)
 {
 	struct stmfts_data *sdata = input_get_drvdata(dev);
 	int err;
 
 	err = pm_runtime_resume_and_get(&sdata->client->dev);
 	if (err)
 		return err;
@@ -365,16 +560,37 @@ static int stmfts_input_open(struct input_dev *dev)
 			/* I can still use only the touch screen */
 			dev_warn(&sdata->client->dev,
 				 "failed to enable touchkey\n");
 	}
 
 	return 0;
 }
 
+static int stmfts5_input_open(struct input_dev *dev)
+{
+	struct stmfts_data *sdata = input_get_drvdata(dev);
+	int err;
+
+	err = pm_runtime_resume_and_get(&sdata->client->dev);
+	if (err)
+		return err;
+
+	err = stmfts5_set_scan_mode(sdata, 0xff);
+	if (err) {
+		pm_runtime_put_sync(&sdata->client->dev);
+		return err;
+	}
+
+	scoped_guard(mutex, &sdata->mutex)
+		sdata->running = true;
+
+	return 0;
+}
+
 static void stmfts_input_close(struct input_dev *dev)
 {
 	struct stmfts_data *sdata = input_get_drvdata(dev);
 	int err;
 
 	err = i2c_smbus_write_byte(sdata->client, STMFTS_MS_MT_SENSE_OFF);
 	if (err)
 		dev_warn(&sdata->client->dev,
@@ -398,16 +614,32 @@ static void stmfts_input_close(struct input_dev *dev)
 		if (err)
 			dev_warn(&sdata->client->dev,
 				 "failed to disable touchkey: %d\n", err);
 	}
 
 	pm_runtime_put_sync(&sdata->client->dev);
 }
 
+static void stmfts5_input_close(struct input_dev *dev)
+{
+	struct stmfts_data *sdata = input_get_drvdata(dev);
+	int err;
+
+	err = stmfts5_set_scan_mode(sdata, 0x00);
+	if (err)
+		dev_warn(&sdata->client->dev,
+			 "failed to disable touchscreen: %d\n", err);
+
+	scoped_guard(mutex, &sdata->mutex)
+		sdata->running = false;
+
+	pm_runtime_put_sync(&sdata->client->dev);
+}
+
 static ssize_t stmfts_sysfs_chip_id(struct device *dev,
 				    struct device_attribute *attr, char *buf)
 {
 	struct stmfts_data *sdata = dev_get_drvdata(dev);
 
 	return sysfs_emit(buf, "%#x\n", sdata->chip_id);
 }
 
@@ -482,20 +714,18 @@ static ssize_t stmfts_sysfs_hover_enable_write(struct device *dev,
 	if (kstrtoul(buf, 0, &value))
 		return -EINVAL;
 
 	hover = !!value;
 
 	guard(mutex)(&sdata->mutex);
 
 	if (hover != sdata->hover_enabled) {
-		if (sdata->running) {
-			err = i2c_smbus_write_byte(sdata->client,
-						   value ? STMFTS_SS_HOVER_SENSE_ON :
-							   STMFTS_SS_HOVER_SENSE_OFF);
+		if (sdata->running && sdata->ops->set_hover) {
+			err = sdata->ops->set_hover(sdata, hover);
 			if (err)
 				return err;
 		}
 
 		sdata->hover_enabled = hover;
 	}
 
 	return len;
@@ -551,16 +781,20 @@ static void stmfts_reset(struct stmfts_data *sdata)
 	gpiod_set_value_cansleep(sdata->reset_gpio, 0);
 	msleep(50);
 }
 
 static int stmfts_configure(struct stmfts_data *sdata)
 {
 	int err;
 
+	err = stmfts_read_system_info(sdata);
+	if (err)
+		return err;
+
 	err = stmfts_command(sdata, STMFTS_SYSTEM_RESET);
 	if (err)
 		return err;
 
 	err = stmfts_command(sdata, STMFTS_SLEEP_OUT);
 	if (err)
 		return err;
 
@@ -596,55 +830,123 @@ static int stmfts_power_on(struct stmfts_data *sdata)
 	 * The datasheet does not specify the power on time, but considering
 	 * that the reset time is < 10ms, I sleep 20ms to be sure
 	 */
 	msleep(20);
 
 	if (sdata->reset_gpio)
 		stmfts_reset(sdata);
 
-	err = stmfts_read_system_info(sdata);
-	if (err)
-		goto err_disable_regulators;
-
 	enable_irq(sdata->client->irq);
 
 	msleep(50);
 
-	err = stmfts_configure(sdata);
+	err = sdata->ops->configure(sdata);
 	if (err)
 		goto err_disable_irq;
 
 	/*
 	 * At this point no one is using the touchscreen
 	 * and I don't really care about the return value
 	 */
 	(void)i2c_smbus_write_byte(sdata->client, STMFTS_SLEEP_IN);
 
 	return 0;
 
 err_disable_irq:
 	disable_irq(sdata->client->irq);
-err_disable_regulators:
 	regulator_bulk_disable(ARRAY_SIZE(stmfts_supplies), sdata->supplies);
 	return err;
 }
 
+static int stmfts5_configure(struct stmfts_data *sdata)
+{
+	u8 event[STMFTS_EVENT_SIZE];
+	int err;
+
+	/* Verify I2C communication */
+	err = i2c_smbus_read_i2c_block_data(sdata->client,
+					    STMFTS_READ_ALL_EVENT,
+					    sizeof(event), event);
+	if (err < 0)
+		return err;
+
+	return 0;
+}
+
+static void stmfts5_chip_power_off(struct stmfts_data *sdata)
+{
+	i2c_smbus_write_byte(sdata->client, STMFTS_SLEEP_IN);
+	msleep(20);
+}
+
 static void stmfts_power_off(void *data)
 {
 	struct stmfts_data *sdata = data;
 
 	disable_irq(sdata->client->irq);
 
 	if (sdata->reset_gpio)
 		gpiod_set_value_cansleep(sdata->reset_gpio, 1);
 
+	if (sdata->ops->power_off)
+		sdata->ops->power_off(sdata);
+
 	regulator_bulk_disable(ARRAY_SIZE(stmfts_supplies), sdata->supplies);
 }
 
+static int stmfts_setup_input(struct stmfts_data *sdata)
+{
+	struct device *dev = &sdata->client->dev;
+
+	input_set_abs_params(sdata->input, ABS_MT_ORIENTATION, 0, 255, 0, 0);
+	input_set_abs_params(sdata->input, ABS_DISTANCE, 0, 255, 0, 0);
+
+	sdata->use_key = device_property_read_bool(dev, "touch-key-connected");
+	if (sdata->use_key) {
+		input_set_capability(sdata->input, EV_KEY, KEY_MENU);
+		input_set_capability(sdata->input, EV_KEY, KEY_BACK);
+	}
+
+	return input_mt_init_slots(sdata->input, STMFTS_MAX_FINGERS,
+				   INPUT_MT_DIRECT);
+}
+
+static int stmfts5_setup_input(struct stmfts_data *sdata)
+{
+	struct device *dev = &sdata->client->dev;
+
+	sdata->mode_switch_gpio = devm_gpiod_get_optional(dev, "mode-switch",
+							  GPIOD_OUT_HIGH);
+	if (IS_ERR(sdata->mode_switch_gpio))
+		return dev_err_probe(dev, PTR_ERR(sdata->mode_switch_gpio),
+				     "Failed to get GPIO 'switch'\n");
+
+	/* Set resolution for accurate calibration */
+	if (!input_abs_get_res(sdata->input, ABS_MT_POSITION_X)) {
+		input_abs_set_res(sdata->input, ABS_MT_POSITION_X, 10);
+		input_abs_set_res(sdata->input, ABS_MT_POSITION_Y, 10);
+	}
+
+	input_set_abs_params(sdata->input, ABS_MT_DISTANCE, 0, 255, 0, 0);
+
+	/* Enable stylus support if requested */
+	sdata->stylus_enabled = device_property_read_bool(dev, "stylus-enabled");
+
+	return input_mt_init_slots(sdata->input, STMFTS_MAX_FINGERS,
+				   INPUT_MT_DIRECT);
+}
+
+static int stmfts_set_hover(struct stmfts_data *sdata, bool enable)
+{
+	return i2c_smbus_write_byte(sdata->client,
+				    enable ? STMFTS_SS_HOVER_SENSE_ON :
+					     STMFTS_SS_HOVER_SENSE_OFF);
+}
+
 static int stmfts_enable_led(struct stmfts_data *sdata)
 {
 	int err;
 
 	/* get the regulator for powering the leds on */
 	sdata->ledvdd = devm_regulator_get(&sdata->client->dev, "ledvdd");
 	if (IS_ERR(sdata->ledvdd))
 		return PTR_ERR(sdata->ledvdd);
@@ -680,16 +982,18 @@ static int stmfts_probe(struct i2c_client *client)
 		return -ENOMEM;
 
 	i2c_set_clientdata(client, sdata);
 
 	sdata->client = client;
 	mutex_init(&sdata->mutex);
 	init_completion(&sdata->cmd_done);
 
+	sdata->ops = of_device_get_match_data(dev);
+
 	err = devm_regulator_bulk_get_const(dev,
 					    ARRAY_SIZE(stmfts_supplies),
 					    stmfts_supplies,
 					    &sdata->supplies);
 	if (err)
 		return err;
 
 	sdata->reset_gpio = devm_gpiod_get_optional(dev, "reset", GPIOD_OUT_HIGH);
@@ -698,37 +1002,28 @@ static int stmfts_probe(struct i2c_client *client)
 				     "Failed to get GPIO 'reset'\n");
 
 	sdata->input = devm_input_allocate_device(dev);
 	if (!sdata->input)
 		return -ENOMEM;
 
 	sdata->input->name = STMFTS_DEV_NAME;
 	sdata->input->id.bustype = BUS_I2C;
-	sdata->input->open = stmfts_input_open;
-	sdata->input->close = stmfts_input_close;
+	sdata->input->open = sdata->ops->input_open;
+	sdata->input->close = sdata->ops->input_close;
 
 	input_set_capability(sdata->input, EV_ABS, ABS_MT_POSITION_X);
 	input_set_capability(sdata->input, EV_ABS, ABS_MT_POSITION_Y);
 	touchscreen_parse_properties(sdata->input, true, &sdata->prop);
 
 	input_set_abs_params(sdata->input, ABS_MT_TOUCH_MAJOR, 0, 255, 0, 0);
 	input_set_abs_params(sdata->input, ABS_MT_TOUCH_MINOR, 0, 255, 0, 0);
-	input_set_abs_params(sdata->input, ABS_MT_ORIENTATION, 0, 255, 0, 0);
 	input_set_abs_params(sdata->input, ABS_MT_PRESSURE, 0, 255, 0, 0);
-	input_set_abs_params(sdata->input, ABS_DISTANCE, 0, 255, 0, 0);
-
-	sdata->use_key = device_property_read_bool(dev, "touch-key-connected");
-	if (sdata->use_key) {
-		input_set_capability(sdata->input, EV_KEY, KEY_MENU);
-		input_set_capability(sdata->input, EV_KEY, KEY_BACK);
-	}
 
-	err = input_mt_init_slots(sdata->input,
-				  STMFTS_MAX_FINGERS, INPUT_MT_DIRECT);
+	err = sdata->ops->setup_input(sdata);
 	if (err)
 		return err;
 
 	input_set_drvdata(sdata->input, sdata);
 
 	/*
 	 * stmfts_power_on expects interrupt to be disabled, but
 	 * at this point the device is still off and I do not trust
@@ -789,27 +1084,71 @@ static int stmfts_runtime_suspend(struct device *dev)
 
 	ret = i2c_smbus_write_byte(sdata->client, STMFTS_SLEEP_IN);
 	if (ret)
 		dev_warn(dev, "failed to suspend device: %d\n", ret);
 
 	return ret;
 }
 
+static int stmfts_chip_runtime_resume(struct stmfts_data *sdata)
+{
+	return i2c_smbus_write_byte(sdata->client, STMFTS_SLEEP_OUT);
+}
+
+static int stmfts5_chip_runtime_resume(struct stmfts_data *sdata)
+{
+	struct i2c_client *client = sdata->client;
+	struct device *dev = &client->dev;
+	u8 int_enable_cmd[4] = { 0xB6, 0x00, 0x2C, 0x01 };
+	int err;
+
+	err = i2c_smbus_write_byte(client, STMFTS_SLEEP_OUT);
+	if (err)
+		return err;
+
+	msleep(20);
+
+	/* Perform capacitance tuning after wakeup */
+	err = i2c_smbus_write_byte(client, STMFTS_MS_CX_TUNING);
+	if (err)
+		dev_warn(dev, "MS_CX_TUNING failed: %d\n", err);
+	msleep(20);
+
+	err = i2c_smbus_write_byte(client, STMFTS_SS_CX_TUNING);
+	if (err)
+		dev_warn(dev, "SS_CX_TUNING failed: %d\n", err);
+	msleep(20);
+
+	/* Force calibration */
+	err = i2c_smbus_write_byte(client, STMFTS_FULL_FORCE_CALIBRATION);
+	if (err)
+		dev_warn(dev, "FORCE_CALIBRATION failed: %d\n", err);
+	msleep(50);
+
+	/* Enable controller interrupts */
+	err = i2c_master_send(client, int_enable_cmd, sizeof(int_enable_cmd));
+	if (err != sizeof(int_enable_cmd))
+		return err < 0 ? err : -EIO;
+
+	msleep(20);
+
+	return 0;
+}
+
 static int stmfts_runtime_resume(struct device *dev)
 {
 	struct stmfts_data *sdata = dev_get_drvdata(dev);
-	struct i2c_client *client = sdata->client;
-	int ret;
+	int err;
 
-	ret = i2c_smbus_write_byte(client, STMFTS_SLEEP_OUT);
-	if (ret)
-		dev_err(dev, "failed to resume device: %d\n", ret);
+	err = sdata->ops->runtime_resume(sdata);
+	if (err)
+		dev_err(dev, "failed to resume device: %d\n", err);
 
-	return ret;
+	return err;
 }
 
 static int stmfts_suspend(struct device *dev)
 {
 	struct stmfts_data *sdata = dev_get_drvdata(dev);
 
 	stmfts_power_off(sdata);
 
@@ -824,18 +1163,39 @@ static int stmfts_resume(struct device *dev)
 }
 
 static const struct dev_pm_ops stmfts_pm_ops = {
 	SYSTEM_SLEEP_PM_OPS(stmfts_suspend, stmfts_resume)
 	RUNTIME_PM_OPS(stmfts_runtime_suspend, stmfts_runtime_resume, NULL)
 };
 
 #ifdef CONFIG_OF
+static const struct stmfts_chip_ops stmfts4_ops = {
+	.configure	= stmfts_configure,
+	.setup_input	= stmfts_setup_input,
+	.input_open	= stmfts_input_open,
+	.input_close	= stmfts_input_close,
+	.parse_events	= stmfts_parse_events,
+	.set_hover	= stmfts_set_hover,
+	.runtime_resume	= stmfts_chip_runtime_resume,
+};
+
+static const struct stmfts_chip_ops stmfts5_ops = {
+	.configure	= stmfts5_configure,
+	.power_off	= stmfts5_chip_power_off,
+	.setup_input	= stmfts5_setup_input,
+	.input_open	= stmfts5_input_open,
+	.input_close	= stmfts5_input_close,
+	.parse_events	= stmfts5_parse_events,
+	.runtime_resume	= stmfts5_chip_runtime_resume,
+};
+
 static const struct of_device_id stmfts_of_match[] = {
-	{ .compatible = "st,stmfts", },
+	{ .compatible = "st,stmfts",	.data = &stmfts4_ops },
+	{ .compatible = "st,stmfts5",	.data = &stmfts5_ops },
 	{ },
 };
 MODULE_DEVICE_TABLE(of, stmfts_of_match);
 #endif
 
 static const struct i2c_device_id stmfts_id[] = {
 	{ .name = "stmfts" },
 	{ }
@@ -853,10 +1213,12 @@ static struct i2c_driver stmfts_driver = {
 	.probe = stmfts_probe,
 	.remove = stmfts_remove,
 	.id_table = stmfts_id,
 };
 
 module_i2c_driver(stmfts_driver);
 
 MODULE_AUTHOR("Andi Shyti <andi.shyti@samsung.com>");
+MODULE_AUTHOR("David Heidelberg <david@ixit.cz>");
+MODULE_AUTHOR("Petr Hodina <petr.hodina@protonmail.com>");
 MODULE_DESCRIPTION("STMicroelectronics FTS Touch Screen");
 MODULE_LICENSE("GPL");

-- 
2.55.0

