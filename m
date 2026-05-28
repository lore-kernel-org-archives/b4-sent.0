From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 27 May 2026 19:34:31 -0700
Subject: [PATCH v6 2/3] leds: flash: rt8515: Support single-GPIO flash ICs
 with vin supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-expressatt_camera_flash-v6-2-de0f150024e4@gmail.com>
References: <20260527-expressatt_camera_flash-v6-0-de0f150024e4@gmail.com>
In-Reply-To: <20260527-expressatt_camera_flash-v6-0-de0f150024e4@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779935671; l=8840;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=ECsUFWhTz2Rp4ynQ93GJ/pcNMjhSeYMsU+5K5mwgLYA=;
 b=E84r0jz3m/L680wFgNeCdunrTp+3koZAjcqJHxPV5OrepgPKzNhhMIB2klC9prQnRppxiqM4p
 dwM7B/PKPMQBqk1Gvnu8mFSUNjEHIS8vj0EKqklZHCCZt7c346v0GHC
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend the RT8515 driver to support flash ICs that use only a single
GPIO for both flash and torch modes (no separate ENT pin), with an
optional vin regulator that gates power to the flash IC.

When vin-supply is provided, the driver enables the regulator before
activating the LED and disables it when turning off.

Make ent-gpios optional. When ent-gpios is absent, the driver uses
enf-gpios for both flash and torch brightness control.

Assisted-by: Claude:claude-opus-4.6
Reviewed-by: Linus Walleij <linusw@kernel.org>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 drivers/leds/flash/leds-rt8515.c | 148 +++++++++++++++++++++++++++++----------
 1 file changed, 112 insertions(+), 36 deletions(-)

diff --git a/drivers/leds/flash/leds-rt8515.c b/drivers/leds/flash/leds-rt8515.c
index f6b439674c03..0fb84d98211d 100644
--- a/drivers/leds/flash/leds-rt8515.c
+++ b/drivers/leds/flash/leds-rt8515.c
@@ -31,6 +31,7 @@
 #include <linux/platform_device.h>
 #include <linux/property.h>
 #include <linux/regulator/consumer.h>
+#include <linux/workqueue.h>
 
 #include <media/v4l2-flash-led-class.h>
 
@@ -44,6 +45,9 @@
 #define RT8515_TIMEOUT_US	250000U
 #define RT8515_MAX_TIMEOUT_US	300000U
 
+#define RT8515_OFF		0
+#define RT8515_ON		1
+
 struct rt8515 {
 	struct led_classdev_flash fled;
 	struct device *dev;
@@ -52,7 +56,7 @@ struct rt8515 {
 	struct regulator *reg;
 	struct gpio_desc *enable_torch;
 	struct gpio_desc *enable_flash;
-	struct timer_list powerdown_timer;
+	struct delayed_work powerdown_work;
 	u32 max_timeout; /* Flash max timeout */
 	int flash_max_intensity;
 	int torch_max_intensity;
@@ -63,27 +67,57 @@ static struct rt8515 *to_rt8515(struct led_classdev_flash *fled)
 	return container_of(fled, struct rt8515, fled);
 }
 
-static void rt8515_gpio_led_off(struct rt8515 *rt)
+static int rt8515_gpio_led_off(struct rt8515 *rt)
 {
-	gpiod_set_value(rt->enable_flash, 0);
-	gpiod_set_value(rt->enable_torch, 0);
+	int ret = 0;
+
+	gpiod_set_value(rt->enable_flash, RT8515_OFF);
+	gpiod_set_value(rt->enable_torch, RT8515_OFF);
+
+	if (!rt->reg)
+		return ret;
+
+	ret = regulator_is_enabled(rt->reg);
+	if (ret > 0)
+		ret = regulator_disable(rt->reg);
+
+	return ret;
 }
 
-static void rt8515_gpio_brightness_commit(struct gpio_desc *gpiod,
-					  int brightness)
+static int rt8515_gpio_brightness_commit(struct rt8515 *rt, struct gpio_desc *gpiod, int brightness)
 {
 	int i;
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
 	for (i = 0; i < brightness; i++) {
-		gpiod_set_value(gpiod, 0);
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
@@ -92,23 +126,38 @@ static int rt8515_led_brightness_set(struct led_classdev *led,
 {
 	struct led_classdev_flash *fled = lcdev_to_flcdev(led);
 	struct rt8515 *rt = to_rt8515(fled);
+	int ret = 0;
 
 	mutex_lock(&rt->lock);
 
 	if (brightness == LED_OFF) {
 		/* Off */
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
@@ -117,27 +166,36 @@ static int rt8515_led_flash_strobe_set(struct led_classdev_flash *fled,
 	struct rt8515 *rt = to_rt8515(fled);
 	struct led_flash_setting *timeout = &fled->timeout;
 	int brightness = rt->flash_max_intensity;
+	int ret = 0;
 
-	mutex_lock(&rt->lock);
-
-	if (state) {
-		/* Enable LED flash mode and set brightness */
-		rt8515_gpio_brightness_commit(rt->enable_flash, brightness);
-		/* Set timeout */
-		mod_timer(&rt->powerdown_timer,
-			  jiffies + usecs_to_jiffies(timeout->val));
-	} else {
-		timer_delete_sync(&rt->powerdown_timer);
+	if (!state) {
+		cancel_delayed_work_sync(&rt->powerdown_work);
+		mutex_lock(&rt->lock);
 		/* Turn the LED off */
-		rt8515_gpio_led_off(rt);
+		ret = rt8515_gpio_led_off(rt);
+		if (!ret)
+			fled->led_cdev.brightness = LED_OFF;
+		mutex_unlock(&rt->lock);
+		return ret;
 	}
 
+	mutex_lock(&rt->lock);
+
+	/* Enable LED flash mode and set brightness */
+	ret = rt8515_gpio_brightness_commit(rt, rt->enable_flash, brightness);
+	if (ret)
+		goto out;
+
+	/* Set timeout */
+	schedule_delayed_work(&rt->powerdown_work, usecs_to_jiffies(timeout->val));
+
 	fled->led_cdev.brightness = LED_OFF;
 	/* After this the torch LED will be disabled */
 
+out:
 	mutex_unlock(&rt->lock);
 
-	return 0;
+	return ret;
 }
 
 static int rt8515_led_flash_strobe_get(struct led_classdev_flash *fled,
@@ -145,7 +203,7 @@ static int rt8515_led_flash_strobe_get(struct led_classdev_flash *fled,
 {
 	struct rt8515 *rt = to_rt8515(fled);
 
-	*state = timer_pending(&rt->powerdown_timer);
+	*state = delayed_work_pending(&rt->powerdown_work);
 
 	return 0;
 }
@@ -163,12 +221,18 @@ static const struct led_flash_ops rt8515_flash_ops = {
 	.timeout_set = rt8515_led_flash_timeout_set,
 };
 
-static void rt8515_powerdown_timer(struct timer_list *t)
+static void rt8515_powerdown_work(struct work_struct *work)
 {
-	struct rt8515 *rt = timer_container_of(rt, t, powerdown_timer);
+	struct rt8515 *rt = container_of(work, struct rt8515, powerdown_work.work);
+	int ret;
 
 	/* Turn the LED off */
-	rt8515_gpio_led_off(rt);
+	mutex_lock(&rt->lock);
+	ret = rt8515_gpio_led_off(rt);
+	mutex_unlock(&rt->lock);
+
+	if (ret)
+		dev_err(rt->dev, "failed to turn off LED (%d)\n", ret);
 }
 
 static void rt8515_init_flash_timeout(struct rt8515 *rt)
@@ -298,11 +362,18 @@ static int rt8515_probe(struct platform_device *pdev)
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
+		if (PTR_ERR(rt->reg) == -EPROBE_DEFER)
+			return -EPROBE_DEFER;
+		rt->reg = NULL;
+	}
 
 	child = device_get_next_child_node(dev, NULL);
 	if (!child) {
@@ -328,12 +399,17 @@ static int rt8515_probe(struct platform_device *pdev)
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
 
@@ -372,7 +448,7 @@ static void rt8515_remove(struct platform_device *pdev)
 	struct rt8515 *rt = platform_get_drvdata(pdev);
 
 	rt8515_v4l2_flash_release(rt);
-	timer_delete_sync(&rt->powerdown_timer);
+	cancel_delayed_work_sync(&rt->powerdown_work);
 	mutex_destroy(&rt->lock);
 }
 

-- 
2.54.0

