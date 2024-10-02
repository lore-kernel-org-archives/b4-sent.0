From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 02 Oct 2024 12:51:51 +0200
Subject: [PATCH 2/4] Input: adp5588-keys: refactor adp5589_read()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241002-fix-adp5588-read-refactor-v1-2-28800f1b9773@analog.com>
References: <20241002-fix-adp5588-read-refactor-v1-0-28800f1b9773@analog.com>
In-Reply-To: <20241002-fix-adp5588-read-refactor-v1-0-28800f1b9773@analog.com>
To: Michael Hennerich <michael.hennerich@analog.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727866310; l=5418;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=iHBBKizUY4muCV5YApLvONvBlERTpRBTGQjSMr4hebU=;
 b=syX5Hhj2jn9i5xtdIAlhG5Wakqy6dnfHTAQWop80TdFr6Vx5cGUtvyReOfMQ3JkiHN84BlWFy
 FxHlcIMiOFdBxTc+AziRRZFldzqzouugG+p54KtqAlEvoaiGgECPSeU
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

adp5588_read() now either returns 0 or an error code. The value to read
is passed as an argument to the function. Therefore we don't mix
register values with error codes.

Suggested-by: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/input/keyboard/adp5588-keys.c | 75 ++++++++++++++++++++---------------
 1 file changed, 42 insertions(+), 33 deletions(-)

diff --git a/drivers/input/keyboard/adp5588-keys.c b/drivers/input/keyboard/adp5588-keys.c
index 9ac68baf0117..11a70ee18482 100644
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
@@ -220,16 +223,17 @@ static int adp5588_gpio_get_value(struct gpio_chip *chip, unsigned int off)
 	struct adp5588_kpad *kpad = gpiochip_get_data(chip);
 	unsigned int bank = ADP5588_BANK(kpad->gpiomap[off]);
 	unsigned int bit = ADP5588_BIT(kpad->gpiomap[off]);
-	int val;
+	int error;
+	u8 val;
 
 	guard(mutex)(&kpad->gpio_lock);
 
 	if (kpad->dir[bank] & bit)
 		return !!(kpad->dat_out[bank] & bit);
 
-	val = adp5588_read(kpad->client, GPIO_DAT_STAT1 + bank);
-	if (val < 0)
-		return val;
+	error = adp5588_read(kpad->client, GPIO_DAT_STAT1 + bank, &val);
+	if (error)
+		return error;
 
 	return !!(val & bit);
 }
@@ -455,18 +459,20 @@ static int adp5588_gpio_add(struct adp5588_kpad *kpad)
 	}
 
 	for (i = 0; i <= ADP5588_BANK(ADP5588_MAXGPIO); i++) {
-		kpad->dat_out[i] = adp5588_read(kpad->client,
-						GPIO_DAT_OUT1 + i);
-		if (kpad->dat_out[i] < 0)
-			return kpad->dat_out[i];
+		error = adp5588_read(kpad->client,
+				     GPIO_DAT_OUT1 + i, &kpad->dat_out[i]);
+		if (error)
+			return error;
 
-		kpad->dir[i] = adp5588_read(kpad->client, GPIO_DIR1 + i);
-		if (kpad->dir[i] < 0)
-			return kpad->dir[i];
+		error = adp5588_read(kpad->client, GPIO_DIR1 + i,
+				     &kpad->dir[i]);
+		if (error)
+			return error;
 
-		kpad->pull_dis[i] = adp5588_read(kpad->client, GPIO_PULL1 + i);
-		if (kpad->pull_dis[i] < 0)
-			return kpad->pull_dis[i];
+		error = adp5588_read(kpad->client, GPIO_PULL1 + i,
+				     &kpad->pull_dis[i]);
+		if (error)
+			return error;
 	}
 
 	return 0;
@@ -529,10 +535,11 @@ static void adp5588_report_events(struct adp5588_kpad *kpad, int ev_cnt)
 	int i;
 
 	for (i = 0; i < ev_cnt; i++) {
-		int key, key_val, key_press;
+		u8 key, key_val, key_press;
+		int error;
 
-		key = adp5588_read(kpad->client, KEY_EVENTA + i);
-		if (key < 0)
+		error = adp5588_read(kpad->client, KEY_EVENTA + i, &key);
+		if (error)
 			return;
 
 		key_val = key & KEY_EV_MASK;
@@ -571,7 +578,8 @@ static irqreturn_t adp5588_thread_irq(int irq, void *handle)
 	struct i2c_client *client = kpad->client;
 	ktime_t target_time, now;
 	unsigned long delay;
-	int status, ev_cnt;
+	u8 status, ev_cnt;
+	int error;
 
 	/*
 	 * Readout needs to wait for at least 25ms after the notification
@@ -586,19 +594,19 @@ static irqreturn_t adp5588_thread_irq(int irq, void *handle)
 		}
 	}
 
-	status = adp5588_read(client, INT_STAT);
-	if (status < 0)
+	error = adp5588_read(client, INT_STAT, &status);
+	if (error)
 		return IRQ_HANDLED;
 
 	if (status & ADP5588_OVR_FLOW_INT)	/* Unlikely and should never happen */
 		dev_err(&client->dev, "Event Overflow Error\n");
 
 	if (status & ADP5588_KE_INT) {
-		ev_cnt = adp5588_read(client, KEY_LCK_EC_STAT) & ADP5588_KEC;
-		if (ev_cnt <= 0)
+		error = adp5588_read(client, KEY_LCK_EC_STAT, &ev_cnt);
+		if (error || !(ev_cnt & ADP5588_KEC))
 			goto out_irq;
 
-		adp5588_report_events(kpad, ev_cnt);
+		adp5588_report_events(kpad, ev_cnt & ADP5588_KEC);
 		input_sync(kpad->input);
 	}
 
@@ -612,6 +620,7 @@ static int adp5588_setup(struct adp5588_kpad *kpad)
 {
 	struct i2c_client *client = kpad->client;
 	int i, ret;
+	u8 dummy;
 
 	ret = adp5588_write(client, KP_GPIO1, KP_SEL(kpad->rows));
 	if (ret)
@@ -638,8 +647,8 @@ static int adp5588_setup(struct adp5588_kpad *kpad)
 	}
 
 	for (i = 0; i < KEYP_MAX_EVENT; i++) {
-		ret = adp5588_read(client, KEY_EVENTA);
-		if (ret < 0)
+		ret = adp5588_read(client, KEY_EVENTA, &dummy);
+		if (ret)
 			return ret;
 	}
 
@@ -743,8 +752,8 @@ static int adp5588_probe(struct i2c_client *client)
 	struct input_dev *input;
 	struct gpio_desc *gpio;
 	unsigned int revid;
-	int ret;
 	int error;
+	u8 id;
 
 	if (!i2c_check_functionality(client->adapter,
 				     I2C_FUNC_SMBUS_BYTE_DATA)) {
@@ -781,11 +790,11 @@ static int adp5588_probe(struct i2c_client *client)
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

