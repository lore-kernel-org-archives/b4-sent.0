From: Utsav Agarwal <utsav.agarwal@analog.com>
Date: Mon, 01 Jul 2024 16:04:50 +0100
Subject: [PATCH v4 1/2] Input: adp5588-keys - add support for pure gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240701-adp5588_gpio_support-v4-1-44bba0445e90@analog.com>
References: <20240701-adp5588_gpio_support-v4-0-44bba0445e90@analog.com>
In-Reply-To: <20240701-adp5588_gpio_support-v4-0-44bba0445e90@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719846302; l=2707;
 i=utsav.agarwal@analog.com; s=20240701; h=from:subject:message-id;
 bh=4MOqqbvu+G4mWGneQ9XlZytwFprVvyttFAs0sfdSVt8=;
 b=AXq4+34Kr6HuK+m3l4PkJn6TEktCmcrhFRM3v2rbScSMc4u+oOQPD/BS95WIgw3aoWo6/JXsM
 6CFL+P6xJfaAcNktKmAsEVrlKdXnVfbm6q5yvInMojx+4CckfWSpWZz
X-Developer-Key: i=utsav.agarwal@analog.com; a=ed25519;
 pk=mIG5Dmd3TO5rcICwTsixl2MoUcf/i2u+jYqifd7+fmI=
X-Endpoint-Received: by B4 Relay for utsav.agarwal@analog.com/20240701 with auth_id=178
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Keypad specific checks in the probe function are relaxed if the
following conditions are met:
	1) "gpio-only" property has been specified for the node
	2) No keypad rows/columns are specified

The "gpio-only" property is introduced to simplify usage since it
serves as a clear indication of the user's intention as opposed to being
inferred from the number of rows and columns specified. This
adds simplicity for the accompanying dt binding update as well
as interpretation of the same.

In such a scenario, additional checks are also introduced to make sure
that keypad and pure GPIO operation are mutually exclusive resulting
in an error if unintentional/incompatible changes are present.

Signed-off-by: Utsav Agarwal <utsav.agarwal@analog.com>
---
 drivers/input/keyboard/adp5588-keys.c | 32 ++++++++++++++++++++++++++++++++
 1 file changed, 32 insertions(+)

diff --git a/drivers/input/keyboard/adp5588-keys.c b/drivers/input/keyboard/adp5588-keys.c
index 1b0279393df4..6f4a52ce20f8 100644
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
@@ -647,6 +648,32 @@ static int adp5588_fw_parse(struct adp5588_kpad *kpad)
 	struct i2c_client *client = kpad->client;
 	int ret, i;
 
+	kpad->gpio_only = device_property_present(&client->dev, "gpio-only");
+	/*
+	 * Check if the device is to be operated purely in GPIO mode. If so,
+	 * confirm that no keypad rows or columns have been specified, since
+	 * all GPINS should be configured as GPIO.
+	 */
+	if (kpad->gpio_only) {
+		ret = device_property_present(&client->dev,
+				"keypad,num-rows");
+		if (ret) {
+			dev_err(&client->dev,
+				"Specified num-rows with mode gpio-only\n");
+			return -EINVAL;
+		}
+
+		ret = device_property_present(&client->dev,
+				"keypad,num-columns");
+		if (ret) {
+			dev_err(&client->dev,
+				"Specified num-columns with mode gpio-only\n");
+			return -EINVAL;
+		}
+
+		return 0;
+	}
+
 	ret = matrix_keypad_parse_properties(&client->dev, &kpad->rows,
 					     &kpad->cols);
 	if (ret)
@@ -790,6 +817,11 @@ static int adp5588_probe(struct i2c_client *client)
 	if (error)
 		return error;
 
+	if (kpad->gpio_only) {
+		dev_info(&client->dev, "Rev.%d, started as GPIO only\n", revid);
+		return 0;
+	}
+
 	error = devm_request_threaded_irq(&client->dev, client->irq,
 					  adp5588_hard_irq, adp5588_thread_irq,
 					  IRQF_TRIGGER_FALLING | IRQF_ONESHOT,

-- 
2.34.1

