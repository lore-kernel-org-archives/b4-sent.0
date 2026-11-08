From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Sun, 08 Nov 2026 09:33:56 +0100
Subject: [PATCH 4/5] Input: s6sy761 - move chip differences into per-chip
 data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-b4-s6sy761-fts1ba90a-v1-4-999b3cfaf82d@dxdmail.cc>
References: <20261108-b4-s6sy761-fts1ba90a-v1-0-999b3cfaf82d@dxdmail.cc>
In-Reply-To: <20261108-b4-s6sy761-fts1ba90a-v1-0-999b3cfaf82d@dxdmail.cc>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andi Shyti <andi.shyti@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794126835; l=9015;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=/BfoC4PWZFkfjkVfh6nROtMvJyQ84ZgSymSbzyjxlG4=;
 b=OzX5ZirB/0QdOT9KDZYCQRqYPZaT/cmHkgxZN/Rvc+QNEBGMGnaRvi4PcpIVkHbOG1BWbKO/Q
 xwwkcAz6kj2AuiZmICzX67KoRc64/EOX7wEJ6kDZmwshGW7cbI8jQuN
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Put what differs between controllers speaking this protocol into
per-chip data, to prepare for adding the ST FTS1BA90A.

No functional change intended.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 drivers/input/touchscreen/s6sy761.c | 133 +++++++++++++++++++++++++++---------
 1 file changed, 99 insertions(+), 34 deletions(-)

diff --git a/drivers/input/touchscreen/s6sy761.c b/drivers/input/touchscreen/s6sy761.c
index 59166865d397..f000ed0d7a9a 100644
--- a/drivers/input/touchscreen/s6sy761.c
+++ b/drivers/input/touchscreen/s6sy761.c
@@ -99,6 +99,7 @@ enum s6sy761_regulators {
 };
 
 struct s6sy761_data {
+	const struct s6sy761_chip_data *chip;
 	struct i2c_client *client;
 	struct regulator_bulk_data regulators[2];
 	struct input_dev *input;
@@ -112,6 +113,19 @@ struct s6sy761_data {
 	bool powered_up;
 };
 
+struct s6sy761_chip_data {
+	int (*boot)(struct s6sy761_data *sdata);
+	int (*set_sense)(struct s6sy761_data *sdata, bool enable);
+	u16 touch_function;
+	u8 event_size;
+	u8 first_tid;
+	u8 devid_cmd;
+	u8 devid_size;
+	u8 devid_offset;
+	bool has_fw_integrity;
+	bool has_app_mode;
+};
+
 /*
  * We can't simply use i2c_smbus_read_i2c_block_data because we
  * need to read more than 255 bytes
@@ -128,8 +142,8 @@ static int s6sy761_read_events(struct s6sy761_data *sdata, u16 n_events)
 		{
 			.addr	= sdata->client->addr,
 			.flags	= I2C_M_RD,
-			.len	= (n_events * S6SY761_EVENT_SIZE),
-			.buf	= sdata->data + S6SY761_EVENT_SIZE,
+			.len	= (n_events * sdata->chip->event_size),
+			.buf	= sdata->data + sdata->chip->event_size,
 		},
 	};
 	int ret;
@@ -175,10 +189,11 @@ static void s6sy761_handle_coordinates(struct s6sy761_data *sdata, u8 *event)
 	u8 tid;
 	u8 touch_state;
 
-	if (unlikely(!(event[0] & S6SY761_MASK_TID)))
+	tid = (event[0] & S6SY761_MASK_TID) >> 2;
+	if (unlikely(tid < sdata->chip->first_tid))
 		return;
 
-	tid = ((event[0] & S6SY761_MASK_TID) >> 2) - 1;
+	tid -= sdata->chip->first_tid;
 	touch_state = (event[0] & S6SY761_MASK_TOUCH_STATE) >> 6;
 
 	switch (touch_state) {
@@ -200,7 +215,7 @@ static void s6sy761_handle_events(struct s6sy761_data *sdata, u8 n_events)
 	int i;
 
 	for (i = 0; i < n_events; i++) {
-		u8 *event = &sdata->data[i * S6SY761_EVENT_SIZE];
+		u8 *event = &sdata->data[i * sdata->chip->event_size];
 		u8 event_id = event[0] & S6SY761_MASK_EID;
 
 		if (!event[0])
@@ -229,7 +244,7 @@ static irqreturn_t s6sy761_irq_handler(int irq, void *dev)
 
 	ret = i2c_smbus_read_i2c_block_data(sdata->client,
 					    S6SY761_READ_ONE_EVENT,
-					    S6SY761_EVENT_SIZE,
+					    sdata->chip->event_size,
 					    sdata->data);
 	if (ret < 0) {
 		dev_err(&sdata->client->dev, "failed to read events\n");
@@ -256,11 +271,18 @@ static irqreturn_t s6sy761_irq_handler(int irq, void *dev)
 	return IRQ_HANDLED;
 }
 
+static int s6sy761_set_sense(struct s6sy761_data *sdata, bool enable)
+{
+	u8 cmd = enable ? S6SY761_SENSE_ON : S6SY761_SENSE_OFF;
+
+	return i2c_smbus_write_byte(sdata->client, cmd);
+}
+
 static int s6sy761_input_open(struct input_dev *dev)
 {
 	struct s6sy761_data *sdata = input_get_drvdata(dev);
 
-	return i2c_smbus_write_byte(sdata->client, S6SY761_SENSE_ON);
+	return sdata->chip->set_sense(sdata, true);
 }
 
 static void s6sy761_input_close(struct input_dev *dev)
@@ -268,7 +290,7 @@ static void s6sy761_input_close(struct input_dev *dev)
 	struct s6sy761_data *sdata = input_get_drvdata(dev);
 	int ret;
 
-	ret = i2c_smbus_write_byte(sdata->client, S6SY761_SENSE_OFF);
+	ret = sdata->chip->set_sense(sdata, false);
 	if (ret)
 		dev_err(&sdata->client->dev, "failed to turn off sensing\n");
 }
@@ -289,50 +311,68 @@ static struct attribute *s6sy761_sysfs_attrs[] = {
 };
 ATTRIBUTE_GROUPS(s6sy761_sysfs);
 
-static int s6sy761_power_on(struct s6sy761_data *sdata)
+static int s6sy761_boot_complete(struct s6sy761_data *sdata)
 {
 	u8 buffer[S6SY761_EVENT_SIZE];
 	u8 event;
 	int ret;
 
-	ret = regulator_bulk_enable(ARRAY_SIZE(sdata->regulators),
-				    sdata->regulators);
-	if (ret)
-		return ret;
-
-	msleep(140);
-
-	/* double check whether the touch is functional */
 	ret = i2c_smbus_read_i2c_block_data(sdata->client,
 					    S6SY761_READ_ONE_EVENT,
-					    S6SY761_EVENT_SIZE,
+					    sdata->chip->event_size,
 					    buffer);
 	if (ret < 0)
-		goto err_disable_regulators;
+		return ret;
 
 	event = (buffer[0] >> 2) & 0xf;
 
 	if ((event != S6SY761_EVENT_INFO &&
 	     event != S6SY761_EVENT_VENDOR_INFO) ||
-	    buffer[1] != S6SY761_INFO_BOOT_COMPLETE) {
-		ret = -ENODEV;
-		goto err_disable_regulators;
-	}
+	    buffer[1] != S6SY761_INFO_BOOT_COMPLETE)
+		return -ENODEV;
+
+	return 0;
+}
+
+static int s6sy761_boot(struct s6sy761_data *sdata)
+{
+	int ret;
+
+	msleep(140);
+
+	/* double check whether the touch is functional */
+	ret = s6sy761_boot_complete(sdata);
+	if (ret)
+		return ret;
 
 	ret = i2c_smbus_read_byte_data(sdata->client, S6SY761_BOOT_STATUS);
 	if (ret < 0)
-		goto err_disable_regulators;
+		return ret;
 
 	/* for some reasons the device might be stuck in the bootloader */
-	if (ret != S6SY761_BS_APPLICATION) {
-		ret = -ENODEV;
+	if (ret != S6SY761_BS_APPLICATION)
+		return -ENODEV;
+
+	return 0;
+}
+
+static int s6sy761_power_on(struct s6sy761_data *sdata)
+{
+	int ret;
+
+	ret = regulator_bulk_enable(ARRAY_SIZE(sdata->regulators),
+				    sdata->regulators);
+	if (ret)
+		return ret;
+
+	ret = sdata->chip->boot(sdata);
+	if (ret)
 		goto err_disable_regulators;
-	}
 
 	/* enable touch functionality */
 	ret = i2c_smbus_write_word_data(sdata->client,
 					S6SY761_TOUCH_FUNCTION,
-					S6SY761_MASK_TOUCH);
+					sdata->chip->touch_function);
 	if (ret)
 		goto err_disable_regulators;
 
@@ -356,13 +396,13 @@ static int s6sy761_hw_init(struct s6sy761_data *sdata,
 		return ret;
 
 	ret = i2c_smbus_read_i2c_block_data(sdata->client,
-					    S6SY761_DEVICE_ID,
-					    S6SY761_DEVID_SIZE,
+					    sdata->chip->devid_cmd,
+					    sdata->chip->devid_size,
 					    buffer);
 	if (ret < 0)
 		return ret;
 
-	sdata->devid = get_unaligned_be16(buffer + 1);
+	sdata->devid = get_unaligned_be16(buffer + sdata->chip->devid_offset);
 
 	ret = i2c_smbus_read_i2c_block_data(sdata->client,
 					    S6SY761_PANEL_INFO,
@@ -377,6 +417,9 @@ static int s6sy761_hw_init(struct s6sy761_data *sdata,
 	/* if no tx channels defined, at least keep one */
 	sdata->tx_channel = max_t(u8, buffer[8], 1);
 
+	if (!sdata->chip->has_fw_integrity)
+		return 0;
+
 	ret = i2c_smbus_read_byte_data(sdata->client,
 				       S6SY761_FIRMWARE_INTEGRITY);
 	if (ret < 0)
@@ -415,6 +458,9 @@ static int s6sy761_probe(struct i2c_client *client)
 
 	i2c_set_clientdata(client, sdata);
 	sdata->client = client;
+	sdata->chip = i2c_get_match_data(client);
+	if (!sdata->chip)
+		return -EINVAL;
 
 	sdata->regulators[S6SY761_REGULATOR_VDD].supply = "vdd";
 	sdata->regulators[S6SY761_REGULATOR_AVDD].supply = "avdd";
@@ -486,6 +532,9 @@ static int s6sy761_runtime_suspend(struct device *dev)
 {
 	struct s6sy761_data *sdata = dev_get_drvdata(dev);
 
+	if (!sdata->chip->has_app_mode)
+		return 0;
+
 	return i2c_smbus_write_byte_data(sdata->client,
 				S6SY761_APPLICATION_MODE, S6SY761_APP_SLEEP);
 }
@@ -494,6 +543,9 @@ static int s6sy761_runtime_resume(struct device *dev)
 {
 	struct s6sy761_data *sdata = dev_get_drvdata(dev);
 
+	if (!sdata->chip->has_app_mode)
+		return 0;
+
 	return i2c_smbus_write_byte_data(sdata->client,
 				S6SY761_APPLICATION_MODE, S6SY761_APP_NORMAL);
 }
@@ -517,7 +569,7 @@ static int s6sy761_restore_sense(struct s6sy761_data *sdata)
 	if (!input_device_enabled(sdata->input))
 		return 0;
 
-	return i2c_smbus_write_byte(sdata->client, S6SY761_SENSE_ON);
+	return sdata->chip->set_sense(sdata, true);
 }
 
 static int s6sy761_resume(struct device *dev)
@@ -547,16 +599,29 @@ static const struct dev_pm_ops s6sy761_pm_ops = {
 	RUNTIME_PM_OPS(s6sy761_runtime_suspend, s6sy761_runtime_resume, NULL)
 };
 
+static const struct s6sy761_chip_data s6sy761_chip = {
+	.boot		= s6sy761_boot,
+	.set_sense	= s6sy761_set_sense,
+	.touch_function	= S6SY761_MASK_TOUCH,
+	.event_size	= S6SY761_EVENT_SIZE,
+	.first_tid	= 1,
+	.devid_cmd	= S6SY761_DEVICE_ID,
+	.devid_size	= S6SY761_DEVID_SIZE,
+	.devid_offset	= 1,
+	.has_fw_integrity = true,
+	.has_app_mode	= true,
+};
+
 #ifdef CONFIG_OF
 static const struct of_device_id s6sy761_of_match[] = {
-	{ .compatible = "samsung,s6sy761", },
+	{ .compatible = "samsung,s6sy761", .data = &s6sy761_chip },
 	{ },
 };
 MODULE_DEVICE_TABLE(of, s6sy761_of_match);
 #endif
 
 static const struct i2c_device_id s6sy761_id[] = {
-	{ .name = "s6sy761" },
+	{ .name = "s6sy761", .driver_data = (kernel_ulong_t)&s6sy761_chip },
 	{ }
 };
 MODULE_DEVICE_TABLE(i2c, s6sy761_id);

-- 
2.56.0

