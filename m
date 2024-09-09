From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Mon, 09 Sep 2024 11:10:58 +0300
Subject: [PATCH v12 33/38] pwm: ep93xx: drop legacy pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240909-ep93xx-v12-33-e86ab2423d4b@maquefel.me>
References: <20240909-ep93xx-v12-0-e86ab2423d4b@maquefel.me>
In-Reply-To: <20240909-ep93xx-v12-0-e86ab2423d4b@maquefel.me>
To: Hartley Sweeten <hsweeten@visionengravers.com>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Nikita Shubin <nikita.shubin@maquefel.me>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Sergey Shtylyov <s.shtylyov@omp.ru>, Stephen Boyd <sboyd@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pwm@vger.kernel.org
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725869532; l=4449;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=9tWs5wPLeKECQlcQ9rkIh26LRGvwgfxOpMK+JfxreaE=;
 b=8LlTCVgPwNsuMNMFBtSmyyqLFJZVVqR2DwHE8HswXjGfrC8A2R3wAp5Ea2ISPfQDyWCSkb2lS+xA
 2KNXZtXxAnlcC76YYTFNWCmroeQBTVwj8dgcwrSgQpkVWpKYZ9X9
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop legacy gpio request/free since we are using
pinctrl for this now.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
Acked-by: Uwe Kleine-König <u.kleine-koenig@pengutronix.de>
Acked-by: Thierry Reding <thierry.reding@gmail.com>
Acked-by: Linus Walleij <linus.walleij@linaro.org>
---
 arch/arm/mach-ep93xx/core.c       | 42 ---------------------------------------
 drivers/pwm/pwm-ep93xx.c          | 18 -----------------
 include/linux/soc/cirrus/ep93xx.h |  4 ----
 3 files changed, 64 deletions(-)

diff --git a/arch/arm/mach-ep93xx/core.c b/arch/arm/mach-ep93xx/core.c
index b99c46d22c4d..4ddf1a4cba33 100644
--- a/arch/arm/mach-ep93xx/core.c
+++ b/arch/arm/mach-ep93xx/core.c
@@ -577,48 +577,6 @@ void __init ep93xx_register_pwm(int pwm0, int pwm1)
 		platform_device_register(&ep93xx_pwm1_device);
 }
 
-int ep93xx_pwm_acquire_gpio(struct platform_device *pdev)
-{
-	int err;
-
-	if (pdev->id == 0) {
-		err = 0;
-	} else if (pdev->id == 1) {
-		err = gpio_request(EP93XX_GPIO_LINE_EGPIO14,
-				   dev_name(&pdev->dev));
-		if (err)
-			return err;
-		err = gpio_direction_output(EP93XX_GPIO_LINE_EGPIO14, 0);
-		if (err)
-			goto fail;
-
-		/* PWM 1 output on EGPIO[14] */
-		ep93xx_devcfg_set_bits(EP93XX_SYSCON_DEVCFG_PONG);
-	} else {
-		err = -ENODEV;
-	}
-
-	return err;
-
-fail:
-	gpio_free(EP93XX_GPIO_LINE_EGPIO14);
-	return err;
-}
-EXPORT_SYMBOL(ep93xx_pwm_acquire_gpio);
-
-void ep93xx_pwm_release_gpio(struct platform_device *pdev)
-{
-	if (pdev->id == 1) {
-		gpio_direction_input(EP93XX_GPIO_LINE_EGPIO14);
-		gpio_free(EP93XX_GPIO_LINE_EGPIO14);
-
-		/* EGPIO[14] used for GPIO */
-		ep93xx_devcfg_clear_bits(EP93XX_SYSCON_DEVCFG_PONG);
-	}
-}
-EXPORT_SYMBOL(ep93xx_pwm_release_gpio);
-
-
 /*************************************************************************
  * EP93xx video peripheral handling
  *************************************************************************/
diff --git a/drivers/pwm/pwm-ep93xx.c b/drivers/pwm/pwm-ep93xx.c
index 67c3fdbf7ae3..994f89ac43b4 100644
--- a/drivers/pwm/pwm-ep93xx.c
+++ b/drivers/pwm/pwm-ep93xx.c
@@ -27,8 +27,6 @@
 
 #include <asm/div64.h>
 
-#include <linux/soc/cirrus/ep93xx.h>	/* for ep93xx_pwm_{acquire,release}_gpio() */
-
 #define EP93XX_PWMx_TERM_COUNT	0x00
 #define EP93XX_PWMx_DUTY_CYCLE	0x04
 #define EP93XX_PWMx_ENABLE	0x08
@@ -44,20 +42,6 @@ static inline struct ep93xx_pwm *to_ep93xx_pwm(struct pwm_chip *chip)
 	return pwmchip_get_drvdata(chip);
 }
 
-static int ep93xx_pwm_request(struct pwm_chip *chip, struct pwm_device *pwm)
-{
-	struct platform_device *pdev = to_platform_device(pwmchip_parent(chip));
-
-	return ep93xx_pwm_acquire_gpio(pdev);
-}
-
-static void ep93xx_pwm_free(struct pwm_chip *chip, struct pwm_device *pwm)
-{
-	struct platform_device *pdev = to_platform_device(pwmchip_parent(chip));
-
-	ep93xx_pwm_release_gpio(pdev);
-}
-
 static int ep93xx_pwm_apply(struct pwm_chip *chip, struct pwm_device *pwm,
 			    const struct pwm_state *state)
 {
@@ -156,8 +140,6 @@ static int ep93xx_pwm_apply(struct pwm_chip *chip, struct pwm_device *pwm,
 }
 
 static const struct pwm_ops ep93xx_pwm_ops = {
-	.request = ep93xx_pwm_request,
-	.free = ep93xx_pwm_free,
 	.apply = ep93xx_pwm_apply,
 };
 
diff --git a/include/linux/soc/cirrus/ep93xx.h b/include/linux/soc/cirrus/ep93xx.h
index 8942bfaf1545..f6376edc1b33 100644
--- a/include/linux/soc/cirrus/ep93xx.h
+++ b/include/linux/soc/cirrus/ep93xx.h
@@ -37,8 +37,6 @@ struct ep93xx_regmap_adev {
 	container_of((_adev), struct ep93xx_regmap_adev, adev)
 
 #ifdef CONFIG_ARCH_EP93XX
-int ep93xx_pwm_acquire_gpio(struct platform_device *pdev);
-void ep93xx_pwm_release_gpio(struct platform_device *pdev);
 int ep93xx_ide_acquire_gpio(struct platform_device *pdev);
 void ep93xx_ide_release_gpio(struct platform_device *pdev);
 int ep93xx_i2s_acquire(void);
@@ -46,8 +44,6 @@ void ep93xx_i2s_release(void);
 unsigned int ep93xx_chip_revision(void);
 
 #else
-static inline int ep93xx_pwm_acquire_gpio(struct platform_device *pdev) { return 0; }
-static inline void ep93xx_pwm_release_gpio(struct platform_device *pdev) {}
 static inline int ep93xx_ide_acquire_gpio(struct platform_device *pdev) { return 0; }
 static inline void ep93xx_ide_release_gpio(struct platform_device *pdev) {}
 static inline int ep93xx_i2s_acquire(void) { return 0; }

-- 
2.43.2

