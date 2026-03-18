From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 18 Mar 2026 11:34:40 -0700
Subject: [PATCH v2 2/3] leds: flash: rt8515: Support single-GPIO flash ICs
 with vin supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260318-expressatt_camera_flash-v2-2-5c2b9a623dcb@gmail.com>
References: <20260318-expressatt_camera_flash-v2-0-5c2b9a623dcb@gmail.com>
In-Reply-To: <20260318-expressatt_camera_flash-v2-0-5c2b9a623dcb@gmail.com>
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773858880; l=5198;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=PKRvCMK0VSbCQ3Z9MBD1bkA0UDBR/q3Gb0zyNbKdvRE=;
 b=MQbNxOMteq4Y3zoIYZ+ythyp8RsNJ2IshduHMf9mzkPG0sMd3jUjq/ybA754Z1jwsX1+ANo6j
 7eJq3o73ZClBiAr+JxcRNpLmcMfmkMGXrMy7WnV41fbgygRSbwbhtP4
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend the RT8515 driver to support flash ICs that use only a single
GPIO for both flash and torch modes (no separate ENT pin), with an
optional vin regulator that gates power to the flash IC.

When vin-supply is provided, the driver enables the regulator before
activating the LED and disables it when turning off.

Make ent-gpios optional and validate at probe time that exactly one of
ent-gpios or vin-supply is provided. When ent-gpios is absent, the
driver uses enf-gpios for both flash and torch brightness control.

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 drivers/leds/flash/leds-rt8515.c | 64 +++++++++++++++++++++++++++++++++++-----
 1 file changed, 56 insertions(+), 8 deletions(-)

diff --git a/drivers/leds/flash/leds-rt8515.c b/drivers/leds/flash/leds-rt8515.c
index f6b439674c03..69cfd5cba921 100644
--- a/drivers/leds/flash/leds-rt8515.c
+++ b/drivers/leds/flash/leds-rt8515.c
@@ -50,6 +50,7 @@ struct rt8515 {
 	struct v4l2_flash *v4l2_flash;
 	struct mutex lock;
 	struct regulator *reg;
+	bool reg_enabled;
 	struct gpio_desc *enable_torch;
 	struct gpio_desc *enable_flash;
 	struct timer_list powerdown_timer;
@@ -66,7 +67,12 @@ static struct rt8515 *to_rt8515(struct led_classdev_flash *fled)
 static void rt8515_gpio_led_off(struct rt8515 *rt)
 {
 	gpiod_set_value(rt->enable_flash, 0);
-	gpiod_set_value(rt->enable_torch, 0);
+	if (rt->enable_torch)
+		gpiod_set_value(rt->enable_torch, 0);
+	if (rt->reg && rt->reg_enabled) {
+		regulator_disable(rt->reg);
+		rt->reg_enabled = false;
+	}
 }
 
 static void rt8515_gpio_brightness_commit(struct gpio_desc *gpiod,
@@ -92,6 +98,7 @@ static int rt8515_led_brightness_set(struct led_classdev *led,
 {
 	struct led_classdev_flash *fled = lcdev_to_flcdev(led);
 	struct rt8515 *rt = to_rt8515(fled);
+	int ret = 0;
 
 	mutex_lock(&rt->lock);
 
@@ -99,16 +106,33 @@ static int rt8515_led_brightness_set(struct led_classdev *led,
 		/* Off */
 		rt8515_gpio_led_off(rt);
 	} else if (brightness < RT8515_TORCH_MAX) {
-		/* Step it up to movie mode brightness using the flash pin */
-		rt8515_gpio_brightness_commit(rt->enable_torch, brightness);
+		/* Enable the vin regulator if needed */
+		if (rt->reg && !rt->reg_enabled) {
+			ret = regulator_enable(rt->reg);
+			if (ret)
+				goto out;
+			rt->reg_enabled = true;
+		}
+		/* Step it up to movie mode brightness */
+		rt8515_gpio_brightness_commit(rt->enable_torch ?
+				rt->enable_torch : rt->enable_flash, brightness);
 	} else {
+		/* Enable the vin regulator if needed */
+		if (rt->reg && !rt->reg_enabled) {
+			ret = regulator_enable(rt->reg);
+			if (ret)
+				goto out;
+			rt->reg_enabled = true;
+		}
 		/* Max torch brightness requested */
-		gpiod_set_value(rt->enable_torch, 1);
+		gpiod_set_value(rt->enable_torch ? rt->enable_torch :
+				rt->enable_flash, 1);
 	}
 
+out:
 	mutex_unlock(&rt->lock);
 
-	return 0;
+	return ret;
 }
 
 static int rt8515_led_flash_strobe_set(struct led_classdev_flash *fled,
@@ -117,10 +141,18 @@ static int rt8515_led_flash_strobe_set(struct led_classdev_flash *fled,
 	struct rt8515 *rt = to_rt8515(fled);
 	struct led_flash_setting *timeout = &fled->timeout;
 	int brightness = rt->flash_max_intensity;
+	int ret = 0;
 
 	mutex_lock(&rt->lock);
 
 	if (state) {
+		/* Enable the vin regulator if needed */
+		if (rt->reg && !rt->reg_enabled) {
+			ret = regulator_enable(rt->reg);
+			if (ret)
+				goto out;
+			rt->reg_enabled = true;
+		}
 		/* Enable LED flash mode and set brightness */
 		rt8515_gpio_brightness_commit(rt->enable_flash, brightness);
 		/* Set timeout */
@@ -135,9 +167,10 @@ static int rt8515_led_flash_strobe_set(struct led_classdev_flash *fled,
 	fled->led_cdev.brightness = LED_OFF;
 	/* After this the torch LED will be disabled */
 
+out:
 	mutex_unlock(&rt->lock);
 
-	return 0;
+	return ret;
 }
 
 static int rt8515_led_flash_strobe_get(struct led_classdev_flash *fled,
@@ -298,12 +331,27 @@ static int rt8515_probe(struct platform_device *pdev)
 		return dev_err_probe(dev, PTR_ERR(rt->enable_flash),
 				     "cannot get ENF (enable flash) GPIO\n");
 
-	/* ENT - Enable Torch line */
-	rt->enable_torch = devm_gpiod_get(dev, "ent", GPIOD_OUT_LOW);
+	/* ENT - Enable Torch line (optional for single-GPIO flash ICs) */
+	rt->enable_torch = devm_gpiod_get_optional(dev, "ent", GPIOD_OUT_LOW);
 	if (IS_ERR(rt->enable_torch))
 		return dev_err_probe(dev, PTR_ERR(rt->enable_torch),
 				     "cannot get ENT (enable torch) GPIO\n");
 
+	/* Optional VIN supply (e.g. GPIO-controlled fixed regulator) */
+	rt->reg = devm_regulator_get_optional(dev, "vin");
+	if (IS_ERR(rt->reg)) {
+		if (PTR_ERR(rt->reg) == -ENODEV)
+			rt->reg = NULL;
+		else
+			return dev_err_probe(dev, PTR_ERR(rt->reg),
+					     "failed to get vin supply\n");
+	}
+
+	/* Exactly one of ENT or VIN must be provided */
+	if (!rt->enable_torch == !rt->reg)
+		return dev_err_probe(dev, -EINVAL,
+				     "exactly one of ent-gpios or vin-supply is required\n");
+
 	child = device_get_next_child_node(dev, NULL);
 	if (!child) {
 		dev_err(dev,

-- 
2.53.0

