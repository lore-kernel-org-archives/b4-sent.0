From: Long Zhao <longzhao@ambarella.com>
Date: Thu, 15 Oct 2026 18:53:29 +0800
Subject: [PATCH v10 2/8] gpiolib: regmap: add
 GPIO_REGMAP_QUIRK_SET_AFTER_DIR
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-cv75-gpio-v10-2-3fe3eb315a55@ambarella.com>
References: <20261015-cv75-gpio-v10-0-3fe3eb315a55@ambarella.com>
In-Reply-To: <20261015-cv75-gpio-v10-0-3fe3eb315a55@ambarella.com>
To: Bartosz Golaszewski <brgl@kernel.org>, linux-gpio@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>, Long Zhao <zl020895@163.com>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792061669; l=3542;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=VFsej1RMHsF3Vzr8BgpbrLcUXMG91JkySFB8CuRN2IE=;
 b=TWRaQjnurtGrbeRGXb36IlpQ7MElKmRrFLVb332S2tiJlxzfTPyQ+sQM+Dw7uICvGIw0f9GPi
 rULh4Svz8qbBoPgRjvotVtl+3cwD/WwMeER2Ck870Dlpb2yxh/diLam
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some controllers ignore output writes while a line is still an input.
Add a behaviour flag so the output value is written after the direction
change. This is a legacy quirk. New hardware must not use it.

Reviewed-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Reviewed-by: Michael Walle <mwalle@kernel.org>
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 drivers/gpio/gpio-regmap.c  | 15 +++++++++++++--
 include/linux/gpio/regmap.h | 14 ++++++++++++++
 2 files changed, 27 insertions(+), 2 deletions(-)

diff --git a/drivers/gpio/gpio-regmap.c b/drivers/gpio/gpio-regmap.c
index 51b4d69b8740..0a44deae3d01 100644
--- a/drivers/gpio/gpio-regmap.c
+++ b/drivers/gpio/gpio-regmap.c
@@ -33,6 +33,7 @@ struct gpio_regmap {
 	unsigned int reg_dir_out_base;
 	unsigned long *fixed_direction_mask;
 	unsigned long *fixed_direction_output;
+	unsigned long quirks;
 
 #ifdef CONFIG_REGMAP_IRQ
 	int regmap_irq_line;
@@ -271,9 +272,17 @@ static int gpio_regmap_direction_output(struct gpio_chip *chip,
 			return ret;
 	}
 
-	gpio_regmap_set(chip, offset, value);
+	if (!(gpio->quirks & GPIO_REGMAP_QUIRK_SET_AFTER_DIR))
+		gpio_regmap_set(chip, offset, value);
 
-	return gpio_regmap_set_direction(chip, offset, true);
+	ret = gpio_regmap_set_direction(chip, offset, true);
+	if (ret)
+		return ret;
+
+	if (gpio->quirks & GPIO_REGMAP_QUIRK_SET_AFTER_DIR)
+		gpio_regmap_set(chip, offset, value);
+
+	return 0;
 }
 
 void *gpio_regmap_get_drvdata(struct gpio_regmap *gpio)
@@ -376,6 +385,8 @@ struct gpio_regmap *gpio_regmap_register(const struct gpio_regmap_config *config
 			    config->fixed_direction_output, chip->ngpio);
 	}
 
+	gpio->quirks = config->quirks;
+
 	/* if not set, assume there is only one register */
 	gpio->ngpio_per_reg = config->ngpio_per_reg;
 	if (!gpio->ngpio_per_reg)
diff --git a/include/linux/gpio/regmap.h b/include/linux/gpio/regmap.h
index 06255756710d..f9090073c852 100644
--- a/include/linux/gpio/regmap.h
+++ b/include/linux/gpio/regmap.h
@@ -3,6 +3,8 @@
 #ifndef _LINUX_GPIO_REGMAP_H
 #define _LINUX_GPIO_REGMAP_H
 
+#include <linux/bits.h>
+
 struct device;
 struct fwnode_handle;
 struct gpio_regmap;
@@ -13,6 +15,14 @@ struct regmap;
 #define GPIO_REGMAP_ADDR_ZERO ((unsigned int)(-1))
 #define GPIO_REGMAP_ADDR(addr) ((addr) ? : GPIO_REGMAP_ADDR_ZERO)
 
+/*
+ * Write the output value after the line is switched to output.
+ * Needed when hardware ignores output writes while the line is an input.
+ * This is a legacy quirk; new hardware must not use it. Direction changes
+ * will glitch.
+ */
+#define GPIO_REGMAP_QUIRK_SET_AFTER_DIR BIT(0)
+
 /**
  * struct gpio_regmap_config - Description of a generic regmap gpio_chip.
  * @parent:		The parent device
@@ -48,6 +58,7 @@ struct regmap;
  *			(Optional) Bitmap representing the fixed direction of
  *			the GPIO lines. Useful when there are GPIO lines with a
  *			fixed direction mixed together in the same register.
+ * @quirks:		(Optional) Behaviour flags, OR of GPIO_REGMAP_QUIRK_*.
  * @drvdata:		(Optional) Pointer to driver specific data which is
  *			not used by gpio-remap but is provided "as is" to the
  *			driver callback(s).
@@ -98,6 +109,9 @@ struct gpio_regmap_config {
 	unsigned long *fixed_direction_mask;
 	unsigned long *fixed_direction_output;
 
+	/* Regmap GPIO behaviour flags */
+	unsigned long quirks;
+
 #ifdef CONFIG_REGMAP_IRQ
 	struct regmap_irq_chip *regmap_irq_chip;
 	int regmap_irq_line;

-- 
2.34.1

