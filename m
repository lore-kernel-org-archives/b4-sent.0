From: Rudraksha Gupta <guptarud@gmail.com>
Date: Sat, 12 Sep 2026 19:38:09 -0700
Subject: [PATCH v7 2/3] leds: flash: rt8515: Support single-GPIO flash ICs
 with vin supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260912-expressatt_camera_flash-v7-2-e1fd2edc8d84@gmail.com>
References: <20260912-expressatt_camera_flash-v7-0-e1fd2edc8d84@gmail.com>
In-Reply-To: <20260912-expressatt_camera_flash-v7-0-e1fd2edc8d84@gmail.com>
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789267087; l=8605;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=skylHszTLWKkxhvTfuJWw+lsWyDXTn0YaNbK6ScaP3M=;
 b=LJgoC1eV0Q2KJCIvx9SlazOf4UjuPfh5blxHB7+vcLE43bqgjU3hzRd4JhpX2omRYro4sUeTL
 +pyO8/D/fpBBcPMzcVwhtzBf6p+Jdj7ISbqefKynxzhhXw9Rt93yTA2
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend the RT8515 driver to support flash ICs that use only a single
GPIO for both flash and torch modes (no separate ENT pin), with an
optional vin regulator that gates power to the flash IC.

Assisted-by: Claude:claude-opus-4.6
Reviewed-by: Linus Walleij <linusw@kernel.org>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 drivers/leds/flash/leds-rt8515.c | 147 ++++++++++++++++++++++++++++-----------
 1 file changed, 107 insertions(+), 40 deletions(-)

diff --git a/drivers/leds/flash/leds-rt8515.c b/drivers/leds/flash/leds-rt8515.c
index 00904cc90ed6..541f61e13f01 100644
--- a/drivers/leds/flash/leds-rt8515.c
+++ b/drivers/leds/flash/leds-rt8515.c
@@ -30,6 +30,7 @@
 #include <linux/platform_device.h>
 #include <linux/property.h>
 #include <linux/regulator/consumer.h>
+#include <linux/workqueue.h>
 
 #include <media/v4l2-flash-led-class.h>
 
@@ -43,6 +44,9 @@
 #define RT8515_TIMEOUT_US	250000U
 #define RT8515_MAX_TIMEOUT_US	300000U
 
+#define RT8515_OFF		0
+#define RT8515_ON		1
+
 struct rt8515 {
 	struct led_classdev_flash fled;
 	struct device *dev;
@@ -51,7 +55,7 @@ struct rt8515 {
 	struct regulator *reg;
 	struct gpio_desc *enable_torch;
 	struct gpio_desc *enable_flash;
-	struct timer_list powerdown_timer;
+	struct delayed_work powerdown_work;
 	u32 max_timeout; /* Flash max timeout */
 	int flash_max_intensity;
 	int torch_max_intensity;
@@ -62,27 +66,50 @@ static struct rt8515 *to_rt8515(struct led_classdev_flash *fled)
 	return container_of(fled, struct rt8515, fled);
 }
 
-static void rt8515_gpio_led_off(struct rt8515 *rt)
+static int rt8515_gpio_led_off(struct rt8515 *rt)
 {
-	gpiod_set_value(rt->enable_flash, 0);
-	gpiod_set_value(rt->enable_torch, 0);
+	gpiod_set_value(rt->enable_flash, RT8515_OFF);
+	gpiod_set_value(rt->enable_torch, RT8515_OFF);
+
+	if (!rt->reg)
+		return 0;
+
+	return regulator_is_enabled(rt->reg) > 0 ? regulator_disable(rt->reg) : 0;
 }
 
-static void rt8515_gpio_brightness_commit(struct gpio_desc *gpiod,
-					  int brightness)
+static int rt8515_gpio_brightness_commit(struct rt8515 *rt, struct gpio_desc *gpiod, int brightness)
 {
-	int i;
+	int ret;
+
+	/*
+	 * Reset the IC to start brightness from zero,
+	 * then re-enable and pulse to the desired level.
+	 */
+	ret = rt8515_gpio_led_off(rt);
+	if (ret)
+		return ret;
+
+	/* IC needs time to reset its brightness counter */
+	usleep_range(100, 200);
+
+	if (rt->reg) {
+		ret = regulator_enable(rt->reg);
+		if (ret)
+			return ret;
+	}
 
 	/*
 	 * Toggling a GPIO line with a small delay increases the
 	 * brightness one step at a time.
 	 */
-	for (i = 0; i < brightness; i++) {
-		gpiod_set_value(gpiod, 0);
+	for (int i = 0; i < brightness; i++) {
+		gpiod_set_value(gpiod, RT8515_OFF);
 		udelay(1);
-		gpiod_set_value(gpiod, 1);
+		gpiod_set_value(gpiod, RT8515_ON);
 		udelay(1);
 	}
+
+	return 0;
 }
 
 /* This is setting the torch light level */
@@ -91,23 +118,37 @@ static int rt8515_led_brightness_set(struct led_classdev *led,
 {
 	struct led_classdev_flash *fled = lcdev_to_flcdev(led);
 	struct rt8515 *rt = to_rt8515(fled);
+	int ret = 0;
 
 	mutex_lock(&rt->lock);
 
 	if (brightness == LED_OFF) {
-		/* Off */
-		rt8515_gpio_led_off(rt);
+		ret = rt8515_gpio_led_off(rt);
+		if (ret)
+			goto out;
 	} else if (brightness < RT8515_TORCH_MAX) {
-		/* Step it up to movie mode brightness using the flash pin */
-		rt8515_gpio_brightness_commit(rt->enable_torch, brightness);
+		/*
+		 * Step it up to movie mode brightness.
+		 * If there is no separate torch pin, use the flash pin
+		 * for torch as well.
+		 */
+		ret = rt8515_gpio_brightness_commit(rt,
+				rt->enable_torch ?: rt->enable_flash, brightness);
+		if (ret)
+			goto out;
 	} else {
-		/* Max torch brightness requested */
-		gpiod_set_value(rt->enable_torch, 1);
+		/*
+		 * Max torch brightness requested.
+		 * If there is no separate torch pin, use the flash pin
+		 * for torch as well.
+		 */
+		gpiod_set_value(rt->enable_torch ?: rt->enable_flash, RT8515_ON);
 	}
 
+out:
 	mutex_unlock(&rt->lock);
 
-	return 0;
+	return ret;
 }
 
 static int rt8515_led_flash_strobe_set(struct led_classdev_flash *fled,
@@ -116,27 +157,35 @@ static int rt8515_led_flash_strobe_set(struct led_classdev_flash *fled,
 	struct rt8515 *rt = to_rt8515(fled);
 	struct led_flash_setting *timeout = &fled->timeout;
 	int brightness = rt->flash_max_intensity;
+	int ret;
+
+	if (!state) {
+		cancel_delayed_work_sync(&rt->powerdown_work);
+		mutex_lock(&rt->lock);
+		ret = rt8515_gpio_led_off(rt);
+		if (!ret)
+			fled->led_cdev.brightness = LED_OFF;
+		mutex_unlock(&rt->lock);
+		return ret;
+	}
 
 	mutex_lock(&rt->lock);
 
-	if (state) {
-		/* Enable LED flash mode and set brightness */
-		rt8515_gpio_brightness_commit(rt->enable_flash, brightness);
-		/* Set timeout */
-		mod_timer(&rt->powerdown_timer,
-			  jiffies + usecs_to_jiffies(timeout->val));
-	} else {
-		timer_delete_sync(&rt->powerdown_timer);
-		/* Turn the LED off */
-		rt8515_gpio_led_off(rt);
-	}
+	/* Enable LED flash mode and set brightness */
+	ret = rt8515_gpio_brightness_commit(rt, rt->enable_flash, brightness);
+	if (ret)
+		goto out;
+
+	/* Set timeout */
+	schedule_delayed_work(&rt->powerdown_work, usecs_to_jiffies(timeout->val));
 
 	fled->led_cdev.brightness = LED_OFF;
 	/* After this the torch LED will be disabled */
 
+out:
 	mutex_unlock(&rt->lock);
 
-	return 0;
+	return ret;
 }
 
 static int rt8515_led_flash_strobe_get(struct led_classdev_flash *fled,
@@ -144,7 +193,7 @@ static int rt8515_led_flash_strobe_get(struct led_classdev_flash *fled,
 {
 	struct rt8515 *rt = to_rt8515(fled);
 
-	*state = timer_pending(&rt->powerdown_timer);
+	*state = delayed_work_pending(&rt->powerdown_work);
 
 	return 0;
 }
@@ -162,12 +211,17 @@ static const struct led_flash_ops rt8515_flash_ops = {
 	.timeout_set = rt8515_led_flash_timeout_set,
 };
 
-static void rt8515_powerdown_timer(struct timer_list *t)
+static void rt8515_powerdown_work(struct work_struct *work)
 {
-	struct rt8515 *rt = timer_container_of(rt, t, powerdown_timer);
+	struct rt8515 *rt = container_of(work, struct rt8515, powerdown_work.work);
+	int ret;
+
+	mutex_lock(&rt->lock);
+	ret = rt8515_gpio_led_off(rt);
+	mutex_unlock(&rt->lock);
 
-	/* Turn the LED off */
-	rt8515_gpio_led_off(rt);
+	if (ret)
+		dev_err(rt->dev, "failed to turn off LED (%d)\n", ret);
 }
 
 static void rt8515_init_flash_timeout(struct rt8515 *rt)
@@ -297,11 +351,19 @@ static int rt8515_probe(struct platform_device *pdev)
 		return dev_err_probe(dev, PTR_ERR(rt->enable_flash),
 				     "cannot get ENF (enable flash) GPIO\n");
 
-	/* ENT - Enable Torch line */
-	rt->enable_torch = devm_gpiod_get(dev, "ent", GPIOD_OUT_LOW);
+	/* ENT - Enable Torch line (optional for single-GPIO flash ICs) */
+	rt->enable_torch = devm_gpiod_get_optional(dev, "ent", GPIOD_OUT_LOW);
 	if (IS_ERR(rt->enable_torch))
 		return dev_err_probe(dev, PTR_ERR(rt->enable_torch),
-				     "cannot get ENT (enable torch) GPIO\n");
+				     "Failed to obtain the Enable Torch GPIO\n");
+
+	rt->reg = devm_regulator_get_optional(dev, "vin");
+	if (IS_ERR(rt->reg)) {
+		ret = PTR_ERR(rt->reg);
+		if (ret != -ENODEV)
+			return dev_err_probe(dev, ret, "Failed to obtain the input supply\n");
+		rt->reg = NULL;
+	}
 
 	child = device_get_next_child_node(dev, NULL);
 	if (!child) {
@@ -327,12 +389,17 @@ static int rt8515_probe(struct platform_device *pdev)
 		dev_warn(dev,
 			 "flash-max-timeout-us property missing\n");
 	}
-	timer_setup(&rt->powerdown_timer, rt8515_powerdown_timer, 0);
+	INIT_DELAYED_WORK(&rt->powerdown_work, rt8515_powerdown_work);
 	rt8515_init_flash_timeout(rt);
 
 	fled->ops = &rt8515_flash_ops;
 
-	led->max_brightness = rt->torch_max_intensity;
+	/*
+	 * If there is no separate torch pin, use flash max intensity
+	 * as max brightness instead.
+	 */
+	led->max_brightness = rt->enable_torch ?
+		rt->torch_max_intensity : rt->flash_max_intensity;
 	led->brightness_set_blocking = rt8515_led_brightness_set;
 	led->flags |= LED_CORE_SUSPENDRESUME | LED_DEV_CAP_FLASH;
 
@@ -371,7 +438,7 @@ static void rt8515_remove(struct platform_device *pdev)
 	struct rt8515 *rt = platform_get_drvdata(pdev);
 
 	rt8515_v4l2_flash_release(rt);
-	timer_delete_sync(&rt->powerdown_timer);
+	cancel_delayed_work_sync(&rt->powerdown_work);
 	mutex_destroy(&rt->lock);
 }
 

-- 
2.55.0

