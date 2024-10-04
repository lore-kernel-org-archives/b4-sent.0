From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 04 Oct 2024 15:46:50 +0200
Subject: [PATCH v2 1/3] Input: adp5588-keys: bail on returned error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241004-fix-adp5588-read-refactor-v2-1-275a093758ae@analog.com>
References: <20241004-fix-adp5588-read-refactor-v2-0-275a093758ae@analog.com>
In-Reply-To: <20241004-fix-adp5588-read-refactor-v2-0-275a093758ae@analog.com>
To: Michael Hennerich <michael.hennerich@analog.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728049615; l=5780;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=r9TnP/wtMiKjVNaniVP8bwQshEJ/XoHAR/uMSqI/NPU=;
 b=H+p3w+hWRJutVKmRAEmUQrPdCVdGSIULKIFYhn88kmLnJujnm+oWAvXNQgiaf9xZildevoG+6
 d7rc+V9WtsUCUNAo3hRQiFQV5kbyX2x4CnvKy7HCdSc8oPB5MZlrJSk
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bail out in case adp5588_read() return an error code. Not doing so is
asking for problems. In order to making it easier (as some values we
want to read are unsigned), adp5588_read() now either returns 0 or an
error code and the value to read is passed as an argument to the
function.

While at it, did a small refactor in adp5588_gpio_get_value() to make it
easier to handle checking the return value.

Suggested-by: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/input/keyboard/adp5588-keys.c | 84 +++++++++++++++++++++++------------
 1 file changed, 56 insertions(+), 28 deletions(-)

diff --git a/drivers/input/keyboard/adp5588-keys.c b/drivers/input/keyboard/adp5588-keys.c
index d25d63a807f23..11a70ee184825 100644
--- a/drivers/input/keyboard/adp5588-keys.c
+++ b/drivers/input/keyboard/adp5588-keys.c
@@ -200,14 +200,17 @@ struct adp5588_kpad {
 	u8 pull_dis[3];
 };
 
-static int adp5588_read(struct i2c_client *client, u8 reg)
+static int adp5588_read(struct i2c_client *client, u8 reg, u8 *val)
 {
 	int ret = i2c_smbus_read_byte_data(client, reg);
 
-	if (ret < 0)
+	if (ret < 0) {
 		dev_err(&client->dev, "Read Error\n");
+		return ret;
+	}
 
-	return ret;
+	*val = ret;
+	return 0;
 }
 
 static int adp5588_write(struct i2c_client *client, u8 reg, u8 val)
@@ -220,14 +223,17 @@ static int adp5588_gpio_get_value(struct gpio_chip *chip, unsigned int off)
 	struct adp5588_kpad *kpad = gpiochip_get_data(chip);
 	unsigned int bank = ADP5588_BANK(kpad->gpiomap[off]);
 	unsigned int bit = ADP5588_BIT(kpad->gpiomap[off]);
-	int val;
+	int error;
+	u8 val;
 
 	guard(mutex)(&kpad->gpio_lock);
 
 	if (kpad->dir[bank] & bit)
-		val = kpad->dat_out[bank];
-	else
-		val = adp5588_read(kpad->client, GPIO_DAT_STAT1 + bank);
+		return !!(kpad->dat_out[bank] & bit);
+
+	error = adp5588_read(kpad->client, GPIO_DAT_STAT1 + bank, &val);
+	if (error)
+		return error;
 
 	return !!(val & bit);
 }
@@ -453,10 +459,20 @@ static int adp5588_gpio_add(struct adp5588_kpad *kpad)
 	}
 
 	for (i = 0; i <= ADP5588_BANK(ADP5588_MAXGPIO); i++) {
-		kpad->dat_out[i] = adp5588_read(kpad->client,
-						GPIO_DAT_OUT1 + i);
-		kpad->dir[i] = adp5588_read(kpad->client, GPIO_DIR1 + i);
-		kpad->pull_dis[i] = adp5588_read(kpad->client, GPIO_PULL1 + i);
+		error = adp5588_read(kpad->client,
+				     GPIO_DAT_OUT1 + i, &kpad->dat_out[i]);
+		if (error)
+			return error;
+
+		error = adp5588_read(kpad->client, GPIO_DIR1 + i,
+				     &kpad->dir[i]);
+		if (error)
+			return error;
+
+		error = adp5588_read(kpad->client, GPIO_PULL1 + i,
+				     &kpad->pull_dis[i]);
+		if (error)
+			return error;
 	}
 
 	return 0;
@@ -519,9 +535,15 @@ static void adp5588_report_events(struct adp5588_kpad *kpad, int ev_cnt)
 	int i;
 
 	for (i = 0; i < ev_cnt; i++) {
-		int key = adp5588_read(kpad->client, KEY_EVENTA + i);
-		int key_val = key & KEY_EV_MASK;
-		int key_press = key & KEY_EV_PRESSED;
+		u8 key, key_val, key_press;
+		int error;
+
+		error = adp5588_read(kpad->client, KEY_EVENTA + i, &key);
+		if (error)
+			return;
+
+		key_val = key & KEY_EV_MASK;
+		key_press = key & KEY_EV_PRESSED;
 
 		if (key_val >= GPI_PIN_BASE && key_val <= GPI_PIN_END) {
 			/* gpio line used as IRQ source */
@@ -556,7 +578,8 @@ static irqreturn_t adp5588_thread_irq(int irq, void *handle)
 	struct i2c_client *client = kpad->client;
 	ktime_t target_time, now;
 	unsigned long delay;
-	int status, ev_cnt;
+	u8 status, ev_cnt;
+	int error;
 
 	/*
 	 * Readout needs to wait for at least 25ms after the notification
@@ -571,19 +594,23 @@ static irqreturn_t adp5588_thread_irq(int irq, void *handle)
 		}
 	}
 
-	status = adp5588_read(client, INT_STAT);
+	error = adp5588_read(client, INT_STAT, &status);
+	if (error)
+		return IRQ_HANDLED;
 
 	if (status & ADP5588_OVR_FLOW_INT)	/* Unlikely and should never happen */
 		dev_err(&client->dev, "Event Overflow Error\n");
 
 	if (status & ADP5588_KE_INT) {
-		ev_cnt = adp5588_read(client, KEY_LCK_EC_STAT) & ADP5588_KEC;
-		if (ev_cnt) {
-			adp5588_report_events(kpad, ev_cnt);
-			input_sync(kpad->input);
-		}
+		error = adp5588_read(client, KEY_LCK_EC_STAT, &ev_cnt);
+		if (error || !(ev_cnt & ADP5588_KEC))
+			goto out_irq;
+
+		adp5588_report_events(kpad, ev_cnt & ADP5588_KEC);
+		input_sync(kpad->input);
 	}
 
+out_irq:
 	adp5588_write(client, INT_STAT, status); /* Status is W1C */
 
 	return IRQ_HANDLED;
@@ -593,6 +620,7 @@ static int adp5588_setup(struct adp5588_kpad *kpad)
 {
 	struct i2c_client *client = kpad->client;
 	int i, ret;
+	u8 dummy;
 
 	ret = adp5588_write(client, KP_GPIO1, KP_SEL(kpad->rows));
 	if (ret)
@@ -619,8 +647,8 @@ static int adp5588_setup(struct adp5588_kpad *kpad)
 	}
 
 	for (i = 0; i < KEYP_MAX_EVENT; i++) {
-		ret = adp5588_read(client, KEY_EVENTA);
-		if (ret < 0)
+		ret = adp5588_read(client, KEY_EVENTA, &dummy);
+		if (ret)
 			return ret;
 	}
 
@@ -724,8 +752,8 @@ static int adp5588_probe(struct i2c_client *client)
 	struct input_dev *input;
 	struct gpio_desc *gpio;
 	unsigned int revid;
-	int ret;
 	int error;
+	u8 id;
 
 	if (!i2c_check_functionality(client->adapter,
 				     I2C_FUNC_SMBUS_BYTE_DATA)) {
@@ -762,11 +790,11 @@ static int adp5588_probe(struct i2c_client *client)
 		fsleep(60);
 	}
 
-	ret = adp5588_read(client, DEV_ID);
-	if (ret < 0)
-		return ret;
+	error = adp5588_read(client, DEV_ID, &id);
+	if (error)
+		return error;
 
-	revid = ret & ADP5588_DEVICE_ID_MASK;
+	revid = id & ADP5588_DEVICE_ID_MASK;
 	if (WA_DELAYED_READOUT_REVID(revid))
 		kpad->delay = msecs_to_jiffies(WA_DELAYED_READOUT_TIME);
 

-- 
2.46.1

