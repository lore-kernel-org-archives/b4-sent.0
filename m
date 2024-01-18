From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Thu, 18 Jan 2024 11:21:09 +0300
Subject: [PATCH v7 26/39] gpio: ep93xx: add DT support for gpio-ep93xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240118-ep93xx-v7-26-d953846ae771@maquefel.me>
References: <20240118-ep93xx-v7-0-d953846ae771@maquefel.me>
In-Reply-To: <20240118-ep93xx-v7-0-d953846ae771@maquefel.me>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, Andy Shevchenko <andy.shevchenko@gmail.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705566176; l=4650;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=veUYE/VzU1y37Z5M8NkA7tAbUvE+Vs49lzqAWz+krrk=;
 b=JTMG/qh/vDZekFRgJzcyfaGrSO16q59j+ZSCqkVPNE/iwmFTqTM0PAw+MouQO26uAVuPu0nPykhZ
 THLAZeJ2BYF9RQ1QqxaquxZ6m8myDdjycGJkZxQ9wWdcHV05Qb1L
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add OF ID match table.

Reviewed-by: Andy Shevchenko <andy.shevchenko@gmail.com>
Reviewed-by: Linus Walleij <linus.walleij@linaro.org>
Acked-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 drivers/gpio/gpio-ep93xx.c | 38 +++++++++++++++++++++++---------------
 1 file changed, 23 insertions(+), 15 deletions(-)

diff --git a/drivers/gpio/gpio-ep93xx.c b/drivers/gpio/gpio-ep93xx.c
index a55f635585f4..ab798c848215 100644
--- a/drivers/gpio/gpio-ep93xx.c
+++ b/drivers/gpio/gpio-ep93xx.c
@@ -12,13 +12,13 @@
 #include <linux/init.h>
 #include <linux/module.h>
 #include <linux/platform_device.h>
+#include <linux/interrupt.h>
 #include <linux/io.h>
 #include <linux/irq.h>
 #include <linux/slab.h>
 #include <linux/gpio/driver.h>
 #include <linux/bitops.h>
 #include <linux/seq_file.h>
-#include <linux/interrupt.h>
 
 struct ep93xx_gpio_irq_chip {
 	void __iomem *base;
@@ -138,7 +138,8 @@ static void ep93xx_gpio_irq_mask_ack(struct irq_data *d)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
 	struct ep93xx_gpio_irq_chip *eic = to_ep93xx_gpio_irq_chip(gc);
-	int port_mask = BIT(irqd_to_hwirq(d));
+	irq_hw_number_t hwirq = irqd_to_hwirq(d);
+	int port_mask = BIT(hwirq);
 
 	if (irqd_get_trigger_type(d) == IRQ_TYPE_EDGE_BOTH)
 		eic->int_type2 ^= port_mask; /* switch edge direction */
@@ -147,26 +148,28 @@ static void ep93xx_gpio_irq_mask_ack(struct irq_data *d)
 	ep93xx_gpio_update_int_params(eic);
 
 	writeb(port_mask, eic->base + EP93XX_INT_EOI_OFFSET);
-	gpiochip_disable_irq(gc, irqd_to_hwirq(d));
+	gpiochip_disable_irq(gc, hwirq);
 }
 
 static void ep93xx_gpio_irq_mask(struct irq_data *d)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
 	struct ep93xx_gpio_irq_chip *eic = to_ep93xx_gpio_irq_chip(gc);
+	irq_hw_number_t hwirq = irqd_to_hwirq(d);
 
-	eic->int_unmasked &= ~BIT(irqd_to_hwirq(d));
+	eic->int_unmasked &= ~BIT(hwirq);
 	ep93xx_gpio_update_int_params(eic);
-	gpiochip_disable_irq(gc, irqd_to_hwirq(d));
+	gpiochip_disable_irq(gc, hwirq);
 }
 
 static void ep93xx_gpio_irq_unmask(struct irq_data *d)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
 	struct ep93xx_gpio_irq_chip *eic = to_ep93xx_gpio_irq_chip(gc);
+	irq_hw_number_t hwirq = irqd_to_hwirq(d);
 
-	gpiochip_enable_irq(gc, irqd_to_hwirq(d));
-	eic->int_unmasked |= BIT(irqd_to_hwirq(d));
+	gpiochip_enable_irq(gc, hwirq);
+	eic->int_unmasked |= BIT(hwirq);
 	ep93xx_gpio_update_int_params(eic);
 }
 
@@ -179,11 +182,11 @@ static int ep93xx_gpio_irq_type(struct irq_data *d, unsigned int type)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
 	struct ep93xx_gpio_irq_chip *eic = to_ep93xx_gpio_irq_chip(gc);
-	irq_hw_number_t offset = irqd_to_hwirq(d);
-	int port_mask = BIT(offset);
+	irq_hw_number_t hwirq = irqd_to_hwirq(d);
+	int port_mask = BIT(hwirq);
 	irq_flow_handler_t handler;
 
-	gc->direction_input(gc, offset);
+	gc->direction_input(gc, hwirq);
 
 	switch (type) {
 	case IRQ_TYPE_EDGE_RISING:
@@ -209,7 +212,7 @@ static int ep93xx_gpio_irq_type(struct irq_data *d, unsigned int type)
 	case IRQ_TYPE_EDGE_BOTH:
 		eic->int_type1 |= port_mask;
 		/* set initial polarity based on current input level */
-		if (gc->get(gc, offset))
+		if (gc->get(gc, hwirq))
 			eic->int_type2 &= ~port_mask; /* falling */
 		else
 			eic->int_type2 |= port_mask; /* rising */
@@ -285,9 +288,8 @@ static int ep93xx_setup_irqs(struct platform_device *pdev,
 	if (girq->num_parents == 0)
 		return -EINVAL;
 
-	girq->parents = devm_kcalloc(dev, girq->num_parents,
-				   sizeof(*girq->parents),
-				   GFP_KERNEL);
+	girq->parents = devm_kcalloc(dev, girq->num_parents, sizeof(*girq->parents),
+				     GFP_KERNEL);
 	if (!girq->parents)
 		return -ENOMEM;
 
@@ -306,7 +308,7 @@ static int ep93xx_setup_irqs(struct platform_device *pdev,
 		girq->parent_handler = ep93xx_gpio_f_irq_handler;
 
 		for (i = 0; i < girq->num_parents; i++) {
-			irq = platform_get_irq(pdev, i);
+			irq = platform_get_irq_optional(pdev, i);
 			if (irq < 0)
 				continue;
 
@@ -359,9 +361,15 @@ static int ep93xx_gpio_probe(struct platform_device *pdev)
 	return devm_gpiochip_add_data(&pdev->dev, gc, egc);
 }
 
+static const struct of_device_id ep93xx_gpio_match[] = {
+	{ .compatible = "cirrus,ep9301-gpio" },
+	{ /* sentinel */ }
+};
+
 static struct platform_driver ep93xx_gpio_driver = {
 	.driver		= {
 		.name	= "gpio-ep93xx",
+		.of_match_table = ep93xx_gpio_match,
 	},
 	.probe		= ep93xx_gpio_probe,
 };

-- 
2.41.0

