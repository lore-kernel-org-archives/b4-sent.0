From: Long Zhao <longzhao@ambarella.com>
Date: Tue, 10 Nov 2026 12:32:28 +0800
Subject: [PATCH v14 03/14] gpio: regmap: remove gpiochip before tearing
 down irqchip
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-cv75-gpio-v14-3-e586aad0467a@ambarella.com>
References: <20261110-cv75-gpio-v14-0-e586aad0467a@ambarella.com>
In-Reply-To: <20261110-cv75-gpio-v14-0-e586aad0467a@ambarella.com>
To: Bartosz Golaszewski <brgl@kernel.org>, linux-gpio@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, Mika Westerberg <westeri@kernel.org>, 
 devicetree@vger.kernel.org, Long Zhao <longzhao@ambarella.com>, 
 Long Zhao <zl020895@163.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794285162; l=1280;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=hUOMd6dzhgSqIYRo/goV9ScP4Xfisuex5VCHYS0+NCE=;
 b=na1xyTOzbfzZEjqluTbwt9g6U6lD+ZUvJugRpIFG7dQTUdXuUo33Nw/FSIJc9N3AyBKldq0J2
 f6kmVe0CQOOAG02lWvmlU4GzDehd8DA4JXZzZYlWegd8smFsFIFSop3
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gpiochip_remove() calls acpi_gpiochip_free_interrupts() and
gpiod_free_irqs(). Both still need the irq domain.
regmap_del_irq_chip() removes that domain, so remove the
gpiochip first.

Fixes: 553b75d4bfe9 ("gpio: regmap: Allow to allocate regmap-irq device")
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 drivers/gpio/gpio-regmap.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/gpio/gpio-regmap.c b/drivers/gpio/gpio-regmap.c
index 0a44deae3d01..1bfdb00dad95 100644
--- a/drivers/gpio/gpio-regmap.c
+++ b/drivers/gpio/gpio-regmap.c
@@ -445,12 +445,19 @@ EXPORT_SYMBOL_GPL(gpio_regmap_register);
  */
 void gpio_regmap_unregister(struct gpio_regmap *gpio)
 {
+	/*
+	 * gpiochip_remove() runs acpi_gpiochip_free_interrupts() and
+	 * gpiod_free_irqs(). Both still need the irq domain.
+	 * regmap_del_irq_chip() removes that domain, so remove the
+	 * gpiochip first.
+	 */
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

