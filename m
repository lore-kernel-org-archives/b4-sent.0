From: Utsav Agarwal <utsav.agarwal@analog.com>
Date: Tue, 13 Aug 2024 21:07:18 +0100
Subject: [PATCH v11 2/3] Input: adp5588-keys - add support for pure gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240813-adp5588_gpio_support-v11-2-9ea490d6c41d@analog.com>
References: <20240813-adp5588_gpio_support-v11-0-9ea490d6c41d@analog.com>
In-Reply-To: <20240813-adp5588_gpio_support-v11-0-9ea490d6c41d@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723579648; l=2755;
 i=utsav.agarwal@analog.com; s=20240701; h=from:subject:message-id;
 bh=Eu2lV0vTpN9Abv9n1z4OYRsDPkCZkTfQntOwZUtyC/k=;
 b=1gQPzbe8iYWoov9Uzy5TGHtBJeQ7TkGkLCS8ag/Enf4TcEwTwVLg/HT0/xQhB8/V6Na5OTYdQ
 vcbmaPibOmwBMmRnDZ9eOJS1Y2aRxZe1Ww6LUN4UYkOnREHeR3Ei6Pn
X-Developer-Key: i=utsav.agarwal@analog.com; a=ed25519;
 pk=mIG5Dmd3TO5rcICwTsixl2MoUcf/i2u+jYqifd7+fmI=
X-Endpoint-Received: by B4 Relay for utsav.agarwal@analog.com/20240701 with auth_id=178
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Keypad specific setup is relaxed if no keypad rows/columns are specified,
enabling a purely gpio operation.

Reviewed-by: Nuno Sa <nuno.sa@analog.com>
Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
---
 drivers/input/keyboard/adp5588-keys.c | 37 +++++++++++++++++++++++++++++++----
 1 file changed, 33 insertions(+), 4 deletions(-)

diff --git a/drivers/input/keyboard/adp5588-keys.c b/drivers/input/keyboard/adp5588-keys.c
index 09bcfc6b9408..7c32f8b69a3e 100644
--- a/drivers/input/keyboard/adp5588-keys.c
+++ b/drivers/input/keyboard/adp5588-keys.c
@@ -188,6 +188,7 @@ struct adp5588_kpad {
 	u32 cols;
 	u32 unlock_keys[2];
 	int nkeys_unlock;
+	bool gpio_only;
 	unsigned short keycode[ADP5588_KEYMAPSIZE];
 	unsigned char gpiomap[ADP5588_MAXGPIO];
 	struct gpio_chip gc;
@@ -431,10 +432,12 @@ static int adp5588_gpio_add(struct adp5588_kpad *kpad)
 	kpad->gc.label = kpad->client->name;
 	kpad->gc.owner = THIS_MODULE;
 
-	girq = &kpad->gc.irq;
-	gpio_irq_chip_set_chip(girq, &adp5588_irq_chip);
-	girq->handler = handle_bad_irq;
-	girq->threaded = true;
+	if (kpad->client->irq) {
+		girq = &kpad->gc.irq;
+		gpio_irq_chip_set_chip(girq, &adp5588_irq_chip);
+		girq->handler = handle_bad_irq;
+		girq->threaded = true;
+	}
 
 	mutex_init(&kpad->gpio_lock);
 
@@ -632,6 +635,21 @@ static int adp5588_fw_parse(struct adp5588_kpad *kpad)
 	struct i2c_client *client = kpad->client;
 	int ret, i;
 
+	/*
+	 * Check if the device is to be operated purely in GPIO mode. To do
+	 * so, check that no keypad rows or columns have been specified,
+	 * since all GPINS should be configured as GPIO.
+	 */
+	ret = device_property_present(&client->dev,
+			"keypad,num-rows");
+	ret |= device_property_present(&client->dev,
+			"keypad,num-columns");
+	/* If purely GPIO, skip keypad setup */
+	if (!ret) {
+		kpad->gpio_only = true;
+		return 0;
+	}
+
 	ret = matrix_keypad_parse_properties(&client->dev, &kpad->rows,
 					     &kpad->cols);
 	if (ret)
@@ -775,6 +793,11 @@ static int adp5588_probe(struct i2c_client *client)
 	if (error)
 		return error;
 
+	if (kpad->gpio_only && !client->irq) {
+		dev_info(&client->dev, "Rev.%d, started as GPIO only\n", revid);
+		return 0;
+	}
+
 	error = devm_request_threaded_irq(&client->dev, client->irq,
 					  adp5588_hard_irq, adp5588_thread_irq,
 					  IRQF_TRIGGER_FALLING | IRQF_ONESHOT,
@@ -785,6 +808,12 @@ static int adp5588_probe(struct i2c_client *client)
 		return error;
 	}
 
+	if (kpad->gpio_only) {
+		dev_info(&client->dev, "Rev.%d GPIO only, irq %d\n",
+				revid, client->irq);
+		return 0;
+	}
+
 	dev_info(&client->dev, "Rev.%d keypad, irq %d\n", revid, client->irq);
 	return 0;
 }

-- 
2.34.1

