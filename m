From: Utsav Agarwal <utsav.agarwal@analog.com>
Date: Mon, 26 Aug 2024 18:22:01 +0100
Subject: [PATCH RESEND v11 1/3] Input: adp5588-keys - use guard notation
 when acquiring mutexes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240826-adp5588_gpio_support-v11-1-3e5ac2bd31b7@analog.com>
References: <20240826-adp5588_gpio_support-v11-0-3e5ac2bd31b7@analog.com>
In-Reply-To: <20240826-adp5588_gpio_support-v11-0-3e5ac2bd31b7@analog.com>
To: Utsav Agarwal <utsav.agarwal@analog.com>, 
 Michael Hennerich <michael.hennerich@analog.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, 
 Vasileios Bimpikas <vasileios.bimpikas@analog.com>, 
 Oliver Gaskell <oliver.gaskell@analog.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724692968; l=4350;
 i=utsav.agarwal@analog.com; s=20240701; h=from:subject:message-id;
 bh=mDwNB6wUzoZc6JGCdhyWFTBkDbZltiAbjw3N6y6sDvU=;
 b=AAdJyyOhUgCmUPcU+xVytmdrFzf5Xvr/7lqcEI+aTafSaazUUOHBVAooW/9GcTZX2WiPUh0ax
 wtmZuSA2tPWD2HEdm/yNgnor5TnJqYfcz1rXWbmRva38bXx5Di2pfgu
X-Developer-Key: i=utsav.agarwal@analog.com; a=ed25519;
 pk=mIG5Dmd3TO5rcICwTsixl2MoUcf/i2u+jYqifd7+fmI=
X-Endpoint-Received: by B4 Relay for utsav.agarwal@analog.com/20240701 with auth_id=178
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Dmitry Torokhov <dmitry.torokhov@gmail.com>

This makes the code more compact and error handling more robust.

Signed-off-by: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Acked-by: Michael Hennerich <michael.hennerich@analog.com>
---
 drivers/input/keyboard/adp5588-keys.c | 49 ++++++++++++-----------------------
 1 file changed, 17 insertions(+), 32 deletions(-)

diff --git a/drivers/input/keyboard/adp5588-keys.c b/drivers/input/keyboard/adp5588-keys.c
index 1b0279393df4..09bcfc6b9408 100644
--- a/drivers/input/keyboard/adp5588-keys.c
+++ b/drivers/input/keyboard/adp5588-keys.c
@@ -221,15 +221,13 @@ static int adp5588_gpio_get_value(struct gpio_chip *chip, unsigned int off)
 	unsigned int bit = ADP5588_BIT(kpad->gpiomap[off]);
 	int val;
 
-	mutex_lock(&kpad->gpio_lock);
+	guard(mutex)(&kpad->gpio_lock);
 
 	if (kpad->dir[bank] & bit)
 		val = kpad->dat_out[bank];
 	else
 		val = adp5588_read(kpad->client, GPIO_DAT_STAT1 + bank);
 
-	mutex_unlock(&kpad->gpio_lock);
-
 	return !!(val & bit);
 }
 
@@ -240,7 +238,7 @@ static void adp5588_gpio_set_value(struct gpio_chip *chip,
 	unsigned int bank = ADP5588_BANK(kpad->gpiomap[off]);
 	unsigned int bit = ADP5588_BIT(kpad->gpiomap[off]);
 
-	mutex_lock(&kpad->gpio_lock);
+	guard(mutex)(&kpad->gpio_lock);
 
 	if (val)
 		kpad->dat_out[bank] |= bit;
@@ -248,8 +246,6 @@ static void adp5588_gpio_set_value(struct gpio_chip *chip,
 		kpad->dat_out[bank] &= ~bit;
 
 	adp5588_write(kpad->client, GPIO_DAT_OUT1 + bank, kpad->dat_out[bank]);
-
-	mutex_unlock(&kpad->gpio_lock);
 }
 
 static int adp5588_gpio_set_config(struct gpio_chip *chip,  unsigned int off,
@@ -259,7 +255,6 @@ static int adp5588_gpio_set_config(struct gpio_chip *chip,  unsigned int off,
 	unsigned int bank = ADP5588_BANK(kpad->gpiomap[off]);
 	unsigned int bit = ADP5588_BIT(kpad->gpiomap[off]);
 	bool pull_disable;
-	int ret;
 
 	switch (pinconf_to_config_param(config)) {
 	case PIN_CONFIG_BIAS_PULL_UP:
@@ -272,19 +267,15 @@ static int adp5588_gpio_set_config(struct gpio_chip *chip,  unsigned int off,
 		return -ENOTSUPP;
 	}
 
-	mutex_lock(&kpad->gpio_lock);
+	guard(mutex)(&kpad->gpio_lock);
 
 	if (pull_disable)
 		kpad->pull_dis[bank] |= bit;
 	else
 		kpad->pull_dis[bank] &= bit;
 
-	ret = adp5588_write(kpad->client, GPIO_PULL1 + bank,
-			    kpad->pull_dis[bank]);
-
-	mutex_unlock(&kpad->gpio_lock);
-
-	return ret;
+	return adp5588_write(kpad->client, GPIO_PULL1 + bank,
+			     kpad->pull_dis[bank]);
 }
 
 static int adp5588_gpio_direction_input(struct gpio_chip *chip, unsigned int off)
@@ -292,16 +283,11 @@ static int adp5588_gpio_direction_input(struct gpio_chip *chip, unsigned int off
 	struct adp5588_kpad *kpad = gpiochip_get_data(chip);
 	unsigned int bank = ADP5588_BANK(kpad->gpiomap[off]);
 	unsigned int bit = ADP5588_BIT(kpad->gpiomap[off]);
-	int ret;
 
-	mutex_lock(&kpad->gpio_lock);
+	guard(mutex)(&kpad->gpio_lock);
 
 	kpad->dir[bank] &= ~bit;
-	ret = adp5588_write(kpad->client, GPIO_DIR1 + bank, kpad->dir[bank]);
-
-	mutex_unlock(&kpad->gpio_lock);
-
-	return ret;
+	return adp5588_write(kpad->client, GPIO_DIR1 + bank, kpad->dir[bank]);
 }
 
 static int adp5588_gpio_direction_output(struct gpio_chip *chip,
@@ -310,9 +296,9 @@ static int adp5588_gpio_direction_output(struct gpio_chip *chip,
 	struct adp5588_kpad *kpad = gpiochip_get_data(chip);
 	unsigned int bank = ADP5588_BANK(kpad->gpiomap[off]);
 	unsigned int bit = ADP5588_BIT(kpad->gpiomap[off]);
-	int ret;
+	int error;
 
-	mutex_lock(&kpad->gpio_lock);
+	guard(mutex)(&kpad->gpio_lock);
 
 	kpad->dir[bank] |= bit;
 
@@ -321,17 +307,16 @@ static int adp5588_gpio_direction_output(struct gpio_chip *chip,
 	else
 		kpad->dat_out[bank] &= ~bit;
 
-	ret = adp5588_write(kpad->client, GPIO_DAT_OUT1 + bank,
-			    kpad->dat_out[bank]);
-	if (ret)
-		goto out_unlock;
-
-	ret = adp5588_write(kpad->client, GPIO_DIR1 + bank, kpad->dir[bank]);
+	error = adp5588_write(kpad->client, GPIO_DAT_OUT1 + bank,
+			      kpad->dat_out[bank]);
+	if (error)
+		return error;
 
-out_unlock:
-	mutex_unlock(&kpad->gpio_lock);
+	error = adp5588_write(kpad->client, GPIO_DIR1 + bank, kpad->dir[bank]);
+	if (error)
+		return error;
 
-	return ret;
+	return 0;
 }
 
 static int adp5588_build_gpiomap(struct adp5588_kpad *kpad)

-- 
2.34.1

