From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 02 Oct 2024 12:51:50 +0200
Subject: [PATCH 1/4] Input: adp5588-keys: bail on returned error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241002-fix-adp5588-read-refactor-v1-1-28800f1b9773@analog.com>
References: <20241002-fix-adp5588-read-refactor-v1-0-28800f1b9773@analog.com>
In-Reply-To: <20241002-fix-adp5588-read-refactor-v1-0-28800f1b9773@analog.com>
To: Michael Hennerich <michael.hennerich@analog.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727866310; l=2989;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=jihJnS6nvrxqMZA4GxnLZ7/1dJtPOBtIIDbrJ2sgXYM=;
 b=R0Gw0ynVFWoLMgJefki/YQEbnRkpj5qd6N+tmElPN6xpCVIgkqkPJgW+0O4YHDVFlrxqQm7Ii
 xJpdYC2xbhfDK3TmwLSfJc2YulsAXwLFNNod6KAZFT7MAMJLTLH10Gk
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bail out in case adp5588_read() return an error code. Not doing so is
asking for problems.

While at it, did a small refactor in adp5588_gpio_get_value() to make it
easier to handle checking the return value.

Suggested-by: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/input/keyboard/adp5588-keys.c | 39 ++++++++++++++++++++++++++---------
 1 file changed, 29 insertions(+), 10 deletions(-)

diff --git a/drivers/input/keyboard/adp5588-keys.c b/drivers/input/keyboard/adp5588-keys.c
index d25d63a807f23..9ac68baf01179 100644
--- a/drivers/input/keyboard/adp5588-keys.c
+++ b/drivers/input/keyboard/adp5588-keys.c
@@ -225,9 +225,11 @@ static int adp5588_gpio_get_value(struct gpio_chip *chip, unsigned int off)
 	guard(mutex)(&kpad->gpio_lock);
 
 	if (kpad->dir[bank] & bit)
-		val = kpad->dat_out[bank];
-	else
-		val = adp5588_read(kpad->client, GPIO_DAT_STAT1 + bank);
+		return !!(kpad->dat_out[bank] & bit);
+
+	val = adp5588_read(kpad->client, GPIO_DAT_STAT1 + bank);
+	if (val < 0)
+		return val;
 
 	return !!(val & bit);
 }
@@ -455,8 +457,16 @@ static int adp5588_gpio_add(struct adp5588_kpad *kpad)
 	for (i = 0; i <= ADP5588_BANK(ADP5588_MAXGPIO); i++) {
 		kpad->dat_out[i] = adp5588_read(kpad->client,
 						GPIO_DAT_OUT1 + i);
+		if (kpad->dat_out[i] < 0)
+			return kpad->dat_out[i];
+
 		kpad->dir[i] = adp5588_read(kpad->client, GPIO_DIR1 + i);
+		if (kpad->dir[i] < 0)
+			return kpad->dir[i];
+
 		kpad->pull_dis[i] = adp5588_read(kpad->client, GPIO_PULL1 + i);
+		if (kpad->pull_dis[i] < 0)
+			return kpad->pull_dis[i];
 	}
 
 	return 0;
@@ -519,9 +529,14 @@ static void adp5588_report_events(struct adp5588_kpad *kpad, int ev_cnt)
 	int i;
 
 	for (i = 0; i < ev_cnt; i++) {
-		int key = adp5588_read(kpad->client, KEY_EVENTA + i);
-		int key_val = key & KEY_EV_MASK;
-		int key_press = key & KEY_EV_PRESSED;
+		int key, key_val, key_press;
+
+		key = adp5588_read(kpad->client, KEY_EVENTA + i);
+		if (key < 0)
+			return;
+
+		key_val = key & KEY_EV_MASK;
+		key_press = key & KEY_EV_PRESSED;
 
 		if (key_val >= GPI_PIN_BASE && key_val <= GPI_PIN_END) {
 			/* gpio line used as IRQ source */
@@ -572,18 +587,22 @@ static irqreturn_t adp5588_thread_irq(int irq, void *handle)
 	}
 
 	status = adp5588_read(client, INT_STAT);
+	if (status < 0)
+		return IRQ_HANDLED;
 
 	if (status & ADP5588_OVR_FLOW_INT)	/* Unlikely and should never happen */
 		dev_err(&client->dev, "Event Overflow Error\n");
 
 	if (status & ADP5588_KE_INT) {
 		ev_cnt = adp5588_read(client, KEY_LCK_EC_STAT) & ADP5588_KEC;
-		if (ev_cnt) {
-			adp5588_report_events(kpad, ev_cnt);
-			input_sync(kpad->input);
-		}
+		if (ev_cnt <= 0)
+			goto out_irq;
+
+		adp5588_report_events(kpad, ev_cnt);
+		input_sync(kpad->input);
 	}
 
+out_irq:
 	adp5588_write(client, INT_STAT, status); /* Status is W1C */
 
 	return IRQ_HANDLED;

-- 
2.46.1

