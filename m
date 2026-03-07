From: Rudraksha Gupta <guptarud@gmail.com>
Date: Fri, 06 Mar 2026 16:58:03 -0800
Subject: [PATCH 2/3] leds: flash: rt8515: Support single-GPIO flash ICs
 with unlock gate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260306-expressatt_camera_flash-v1-2-b1996f7cdfdd@gmail.com>
References: <20260306-expressatt_camera_flash-v1-0-b1996f7cdfdd@gmail.com>
In-Reply-To: <20260306-expressatt_camera_flash-v1-0-b1996f7cdfdd@gmail.com>
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772845083; l=3781;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=eBn8zK2zm3rDt5Cq7ivsaMjK/w9HVVqK9pNgZvC1x40=;
 b=UGnv+rPdrIkDsaPCfH0UYYPewggp5aHqP1G8iGvesY+NLY+lLUq1qPqga3ovVhzNgVzx5sl0w
 SGvmYjjv2mDCarGK2PGGbQNJeXJUO0bubloizi0gW2DiVMpf0Oq6bHu
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend the RT8515 driver to support flash ICs that use only a single
GPIO for both flash and torch modes (no separate ENT pin), with an
optional unlock GPIO that gates the flash circuit.

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 drivers/leds/flash/leds-rt8515.c | 38 ++++++++++++++++++++++++++++++++------
 1 file changed, 32 insertions(+), 6 deletions(-)

diff --git a/drivers/leds/flash/leds-rt8515.c b/drivers/leds/flash/leds-rt8515.c
index f6b439674c03..3164bf91e4c9 100644
--- a/drivers/leds/flash/leds-rt8515.c
+++ b/drivers/leds/flash/leds-rt8515.c
@@ -52,6 +52,7 @@ struct rt8515 {
 	struct regulator *reg;
 	struct gpio_desc *enable_torch;
 	struct gpio_desc *enable_flash;
+	struct gpio_desc *unlock_gpio;
 	struct timer_list powerdown_timer;
 	u32 max_timeout; /* Flash max timeout */
 	int flash_max_intensity;
@@ -66,7 +67,10 @@ static struct rt8515 *to_rt8515(struct led_classdev_flash *fled)
 static void rt8515_gpio_led_off(struct rt8515 *rt)
 {
 	gpiod_set_value(rt->enable_flash, 0);
-	gpiod_set_value(rt->enable_torch, 0);
+	if (rt->enable_torch)
+		gpiod_set_value(rt->enable_torch, 0);
+	if (rt->unlock_gpio)
+		gpiod_set_value_cansleep(rt->unlock_gpio, 0);
 }
 
 static void rt8515_gpio_brightness_commit(struct gpio_desc *gpiod,
@@ -99,11 +103,19 @@ static int rt8515_led_brightness_set(struct led_classdev *led,
 		/* Off */
 		rt8515_gpio_led_off(rt);
 	} else if (brightness < RT8515_TORCH_MAX) {
-		/* Step it up to movie mode brightness using the flash pin */
-		rt8515_gpio_brightness_commit(rt->enable_torch, brightness);
+		/* Unlock the flash circuit if needed */
+		if (rt->unlock_gpio)
+			gpiod_set_value_cansleep(rt->unlock_gpio, 1);
+		/* Step it up to movie mode brightness */
+		rt8515_gpio_brightness_commit(rt->enable_torch ?
+				rt->enable_torch : rt->enable_flash, brightness);
 	} else {
+		/* Unlock the flash circuit if needed */
+		if (rt->unlock_gpio)
+			gpiod_set_value_cansleep(rt->unlock_gpio, 1);
 		/* Max torch brightness requested */
-		gpiod_set_value(rt->enable_torch, 1);
+		gpiod_set_value(rt->enable_torch ? rt->enable_torch :
+				rt->enable_flash, 1);
 	}
 
 	mutex_unlock(&rt->lock);
@@ -121,6 +133,9 @@ static int rt8515_led_flash_strobe_set(struct led_classdev_flash *fled,
 	mutex_lock(&rt->lock);
 
 	if (state) {
+		/* Unlock the flash circuit if needed */
+		if (rt->unlock_gpio)
+			gpiod_set_value_cansleep(rt->unlock_gpio, 1);
 		/* Enable LED flash mode and set brightness */
 		rt8515_gpio_brightness_commit(rt->enable_flash, brightness);
 		/* Set timeout */
@@ -298,12 +313,23 @@ static int rt8515_probe(struct platform_device *pdev)
 		return dev_err_probe(dev, PTR_ERR(rt->enable_flash),
 				     "cannot get ENF (enable flash) GPIO\n");
 
-	/* ENT - Enable Torch line */
-	rt->enable_torch = devm_gpiod_get(dev, "ent", GPIOD_OUT_LOW);
+	/* ENT - Enable Torch line (optional for single-GPIO flash ICs) */
+	rt->enable_torch = devm_gpiod_get_optional(dev, "ent", GPIOD_OUT_LOW);
 	if (IS_ERR(rt->enable_torch))
 		return dev_err_probe(dev, PTR_ERR(rt->enable_torch),
 				     "cannot get ENT (enable torch) GPIO\n");
 
+	/* Optional unlock GPIO (e.g. PMIC MPP to gate flash circuit) */
+	rt->unlock_gpio = devm_gpiod_get_optional(dev, "unlock", GPIOD_OUT_LOW);
+	if (IS_ERR(rt->unlock_gpio))
+		return dev_err_probe(dev, PTR_ERR(rt->unlock_gpio),
+				     "cannot get unlock GPIO\n");
+
+	/* Exactly one of ENT or unlock must be provided */
+	if (!rt->enable_torch == !rt->unlock_gpio)
+		return dev_err_probe(dev, -EINVAL,
+				     "exactly one of ent-gpios or unlock-gpios is required\n");
+
 	child = device_get_next_child_node(dev, NULL);
 	if (!child) {
 		dev_err(dev,

-- 
2.53.0

