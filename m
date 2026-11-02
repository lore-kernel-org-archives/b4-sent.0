From: Long Zhao <longzhao@ambarella.com>
Date: Mon, 02 Nov 2026 14:46:01 +0800
Subject: [PATCH v13 08/13] gpio: regmap: remove gpiochip before tearing
 down irqchip
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-cv75-gpio-v13-8-4f93114ea204@ambarella.com>
References: <20261102-cv75-gpio-v13-0-4f93114ea204@ambarella.com>
In-Reply-To: <20261102-cv75-gpio-v13-0-4f93114ea204@ambarella.com>
To: Bartosz Golaszewski <brgl@kernel.org>, linux-gpio@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, Mika Westerberg <westeri@kernel.org>, 
 linux-acpi@vger.kernel.org, devicetree@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>, Long Zhao <zl020895@163.com>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793602013; l=1791;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=OaUzJvxSKHvAu1q9Z7cujbZIxtxmQOv3Dz1Q60lLuSg=;
 b=/f7+d+2PUAkbck+adNb2ioj2juP3k0EZTnjzDEa6JLN9dXJtNl1WrCrBkZ7H5RNiz0qvaJKLM
 QM7pidA8KgFAbIuR5bnERDt0UfU+g19Id6AWwHIWTq4uLqkC3O1xZtw
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gpio_regmap_unregister() currently calls regmap_del_irq_chip() before
gpiochip_remove(). That disposes the mapped virtual IRQs and frees the
irq_domain while ACPI GPIO-signaled events may still be requested and
while gpiod_free_irqs() still needs gc->irq.domain.

Remove the gpio_chip first so ACPI teardown and USED_AS_IRQ cleanup run
against a live domain, then delete the regmap irqchip. Use the same
order on the registration error path, which previously leaked the
irqchip when gpiochip_irqchip_add_domain() failed after
regmap_add_irq_chip_fwnode().

Cc: Michael Walle <mwalle@kernel.org>
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 drivers/gpio/gpio-regmap.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/gpio/gpio-regmap.c b/drivers/gpio/gpio-regmap.c
index 0a44deae3d01..6b520bd80834 100644
--- a/drivers/gpio/gpio-regmap.c
+++ b/drivers/gpio/gpio-regmap.c
@@ -429,6 +429,11 @@ struct gpio_regmap *gpio_regmap_register(const struct gpio_regmap_config *config
 
 err_remove_gpiochip:
 	gpiochip_remove(chip);
+
+#ifdef CONFIG_REGMAP_IRQ
+	if (gpio->irq_chip_data)
+		regmap_del_irq_chip(gpio->regmap_irq_line, gpio->irq_chip_data);
+#endif
 err_free_bitmap_output:
 	bitmap_free(gpio->fixed_direction_output);
 err_free_bitmap_dirmask:
@@ -445,12 +450,13 @@ EXPORT_SYMBOL_GPL(gpio_regmap_register);
  */
 void gpio_regmap_unregister(struct gpio_regmap *gpio)
 {
+	gpiochip_remove(&gpio->gpio_chip);
+
 #ifdef CONFIG_REGMAP_IRQ
 	if (gpio->irq_chip_data)
 		regmap_del_irq_chip(gpio->regmap_irq_line, gpio->irq_chip_data);
 #endif
 
-	gpiochip_remove(&gpio->gpio_chip);
 	bitmap_free(gpio->fixed_direction_output);
 	bitmap_free(gpio->fixed_direction_mask);
 	kfree(gpio);

-- 
2.34.1

