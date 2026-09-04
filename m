From: Long Zhao <longzhao@ambarella.com>
Date: Fri, 04 Sep 2026 14:38:16 +0800
Subject: [PATCH v6 09/13] gpio: pl061: use gpio-regmap and add Ambarella
 layout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260904-cv75-v5-v6-9-e918514cb3b1@ambarella.com>
References: <20260904-cv75-v5-v6-0-e918514cb3b1@ambarella.com>
In-Reply-To: <20260904-cv75-v5-v6-0-e918514cb3b1@ambarella.com>
To: Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, soc@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org
Cc: Long Zhao <longzhao@ambarella.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Long Zhao <zl020895@163.com>, Lee Jones <lee@kernel.org>, 
 mfd@lists.linux.dev, devicetree@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788503951; l=18274;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=V1wgVvwkEs+6fWnu6vAzP061lTGyxowJwkCsFwebUoA=;
 b=WSk9h9IAGipLjwvvCloqfx8Qa9bZ7od7bKIDIJU0zD1keqZaZRzw1tXXuIW4G0DCnRqcmXGld
 3GJVg5tcEFID81ggrOz88Qa6FT9k07WOBC2PQ0wQ6h1vyXsDN+ODUaA
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert PL061 data and direction handling to gpio-regmap while
keeping the existing PL061 irqchip path. Add an Ambarella CV75
register layout variant on the AMBA bus, without claiming unverified
GPIO suspend/resume support for Ambarella.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 drivers/gpio/Kconfig      |   2 +
 drivers/gpio/gpio-pl061.c | 342 ++++++++++++++++++++++++++++------------------
 include/linux/amba/bus.h  |   1 +
 3 files changed, 212 insertions(+), 133 deletions(-)

diff --git a/drivers/gpio/Kconfig b/drivers/gpio/Kconfig
index f03c05288376..55a129836158 100644
--- a/drivers/gpio/Kconfig
+++ b/drivers/gpio/Kconfig
@@ -583,6 +583,8 @@ config GPIO_PL061
 	depends on ARM_AMBA || COMPILE_TEST
 	select IRQ_DOMAIN
 	select GPIOLIB_IRQCHIP
+	select GPIO_REGMAP
+	select REGMAP_MMIO
 	help
 	  Say yes here to support the PrimeCell PL061 GPIO device.
 
diff --git a/drivers/gpio/gpio-pl061.c b/drivers/gpio/gpio-pl061.c
index 919cf86fd590..6b09031f8664 100644
--- a/drivers/gpio/gpio-pl061.c
+++ b/drivers/gpio/gpio-pl061.c
@@ -13,6 +13,7 @@
 #include <linux/device.h>
 #include <linux/errno.h>
 #include <linux/gpio/driver.h>
+#include <linux/gpio/regmap.h>
 #include <linux/init.h>
 #include <linux/interrupt.h>
 #include <linux/io.h>
@@ -22,20 +23,36 @@
 #include <linux/module.h>
 #include <linux/pinctrl/consumer.h>
 #include <linux/pm.h>
+#include <linux/regmap.h>
 #include <linux/seq_file.h>
 #include <linux/slab.h>
 #include <linux/spinlock.h>
 
-#define GPIODIR 0x400
-#define GPIOIS  0x404
-#define GPIOIBE 0x408
-#define GPIOIEV 0x40C
-#define GPIOIE  0x410
-#define GPIORIS 0x414
-#define GPIOMIS 0x418
-#define GPIOIC  0x41C
-
-#define PL061_GPIO_NR	8
+#define PL061_REG_NONE		((unsigned int)-1)
+
+#define PL061_GPIO_NR		8
+#define AMBARELLA_GPIO_NR	32
+
+struct pl061_variant_data {
+	unsigned int data;
+	unsigned int dir;
+	unsigned int is;
+	unsigned int ibe;
+	unsigned int iev;
+	unsigned int ie;
+	unsigned int ris;
+	unsigned int mis;
+	unsigned int ic;
+	unsigned int mask;
+	unsigned int enable;
+	unsigned int ngpio;
+	bool access_32bit;
+	bool masked_data_address;
+	bool write_data_after_dir;
+	bool clear_irq_on_type;
+	bool pm_save_restore;
+	const struct regmap_config *regmap_config;
+};
 
 struct pl061_context_save_regs {
 	u8 gpio_data;
@@ -48,74 +65,47 @@ struct pl061_context_save_regs {
 
 struct pl061 {
 	raw_spinlock_t		lock;
-
 	void __iomem		*base;
-	struct gpio_chip	gc;
+	const struct pl061_variant_data *variant;
+	struct gpio_irq_chip	girq;
 	int			parent_irq;
 
 	struct pl061_context_save_regs csave_regs;
 };
 
-static int pl061_get_direction(struct gpio_chip *gc, unsigned offset)
-{
-	struct pl061 *pl061 = gpiochip_get_data(gc);
-
-	if (readb(pl061->base + GPIODIR) & BIT(offset))
-		return GPIO_LINE_DIRECTION_OUT;
-
-	return GPIO_LINE_DIRECTION_IN;
-}
-
-static int pl061_direction_input(struct gpio_chip *gc, unsigned offset)
+static struct pl061 *pl061_from_gpio_chip(struct gpio_chip *gc)
 {
-	struct pl061 *pl061 = gpiochip_get_data(gc);
-	unsigned long flags;
-	unsigned char gpiodir;
-
-	raw_spin_lock_irqsave(&pl061->lock, flags);
-	gpiodir = readb(pl061->base + GPIODIR);
-	gpiodir &= ~(BIT(offset));
-	writeb(gpiodir, pl061->base + GPIODIR);
-	raw_spin_unlock_irqrestore(&pl061->lock, flags);
-
-	return 0;
+	return gpio_regmap_get_drvdata(gpiochip_get_data(gc));
 }
 
-static int pl061_direction_output(struct gpio_chip *gc, unsigned offset,
-		int value)
+static u32 pl061_read(struct pl061 *pl061, unsigned int reg)
 {
-	struct pl061 *pl061 = gpiochip_get_data(gc);
-	unsigned long flags;
-	unsigned char gpiodir;
+	if (pl061->variant->access_32bit)
+		return readl(pl061->base + reg);
 
-	raw_spin_lock_irqsave(&pl061->lock, flags);
-	writeb(!!value << offset, pl061->base + (BIT(offset + 2)));
-	gpiodir = readb(pl061->base + GPIODIR);
-	gpiodir |= BIT(offset);
-	writeb(gpiodir, pl061->base + GPIODIR);
-
-	/*
-	 * gpio value is set again, because pl061 doesn't allow to set value of
-	 * a gpio pin before configuring it in OUT mode.
-	 */
-	writeb(!!value << offset, pl061->base + (BIT(offset + 2)));
-	raw_spin_unlock_irqrestore(&pl061->lock, flags);
-
-	return 0;
+	return readb(pl061->base + reg);
 }
 
-static int pl061_get_value(struct gpio_chip *gc, unsigned offset)
+static void pl061_write(struct pl061 *pl061, u32 value, unsigned int reg)
 {
-	struct pl061 *pl061 = gpiochip_get_data(gc);
-
-	return !!readb(pl061->base + (BIT(offset + 2)));
+	if (pl061->variant->access_32bit)
+		writel(value, pl061->base + reg);
+	else
+		writeb(value, pl061->base + reg);
 }
 
-static int pl061_set_value(struct gpio_chip *gc, unsigned int offset, int value)
+static int pl061_reg_mask_xlate(struct gpio_regmap *gpio, unsigned int base,
+				unsigned int offset, unsigned int *reg,
+				unsigned int *mask)
 {
-	struct pl061 *pl061 = gpiochip_get_data(gc);
+	struct pl061 *pl061 = gpio_regmap_get_drvdata(gpio);
 
-	writeb(!!value << offset, pl061->base + (BIT(offset + 2)));
+	/* ARM PL061 data bits use masked addresses: bits [9:2] select pins. */
+	if (base == pl061->variant->data)
+		*reg = BIT(offset + 2);
+	else
+		*reg = base;
+	*mask = BIT(offset);
 
 	return 0;
 }
@@ -123,18 +113,17 @@ static int pl061_set_value(struct gpio_chip *gc, unsigned int offset, int value)
 static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
-	struct pl061 *pl061 = gpiochip_get_data(gc);
+	struct pl061 *pl061 = pl061_from_gpio_chip(gc);
+	const struct pl061_variant_data *variant = pl061->variant;
 	int offset = irqd_to_hwirq(d);
 	unsigned long flags;
-	u8 gpiois, gpioibe, gpioiev;
-	u8 bit = BIT(offset);
+	u32 gpiois, gpioibe, gpioiev;
+	u32 bit = BIT(offset);
 
-	if (offset < 0 || offset >= PL061_GPIO_NR)
+	if (offset < 0 || offset >= (int)gc->ngpio)
 		return -EINVAL;
 
-	if ((trigger & (IRQ_TYPE_LEVEL_HIGH | IRQ_TYPE_LEVEL_LOW)) &&
-	    (trigger & (IRQ_TYPE_EDGE_RISING | IRQ_TYPE_EDGE_FALLING)))
-	{
+	if ((trigger & IRQ_TYPE_LEVEL_MASK) && (trigger & IRQ_TYPE_EDGE_BOTH)) {
 		dev_err(gc->parent,
 			"trying to configure line %d for both level and edge "
 			"detection, choose one!\n",
@@ -142,14 +131,13 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 		return -EINVAL;
 	}
 
-
 	raw_spin_lock_irqsave(&pl061->lock, flags);
 
-	gpioiev = readb(pl061->base + GPIOIEV);
-	gpiois = readb(pl061->base + GPIOIS);
-	gpioibe = readb(pl061->base + GPIOIBE);
+	gpioiev = pl061_read(pl061, variant->iev);
+	gpiois = pl061_read(pl061, variant->is);
+	gpioibe = pl061_read(pl061, variant->ibe);
 
-	if (trigger & (IRQ_TYPE_LEVEL_HIGH | IRQ_TYPE_LEVEL_LOW)) {
+	if (trigger & IRQ_TYPE_LEVEL_MASK) {
 		bool polarity = trigger & IRQ_TYPE_LEVEL_HIGH;
 
 		/* Disable edge detection */
@@ -199,9 +187,11 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 			 offset);
 	}
 
-	writeb(gpiois, pl061->base + GPIOIS);
-	writeb(gpioibe, pl061->base + GPIOIBE);
-	writeb(gpioiev, pl061->base + GPIOIEV);
+	pl061_write(pl061, gpiois, variant->is);
+	pl061_write(pl061, gpioibe, variant->ibe);
+	pl061_write(pl061, gpioiev, variant->iev);
+	if (variant->clear_irq_on_type)
+		pl061_write(pl061, bit, variant->ic);
 
 	raw_spin_unlock_irqrestore(&pl061->lock, flags);
 
@@ -213,16 +203,15 @@ static void pl061_irq_handler(struct irq_desc *desc)
 	unsigned long pending;
 	int offset;
 	struct gpio_chip *gc = irq_desc_get_handler_data(desc);
-	struct pl061 *pl061 = gpiochip_get_data(gc);
+	struct pl061 *pl061 = pl061_from_gpio_chip(gc);
 	struct irq_chip *irqchip = irq_desc_get_chip(desc);
 
 	chained_irq_enter(irqchip, desc);
 
-	pending = readb(pl061->base + GPIOMIS);
+	pending = pl061_read(pl061, pl061->variant->mis);
 	if (pending) {
-		for_each_set_bit(offset, &pending, PL061_GPIO_NR)
-			generic_handle_domain_irq(gc->irq.domain,
-						  offset);
+		for_each_set_bit(offset, &pending, gc->ngpio)
+			generic_handle_domain_irq(gc->irq.domain, offset);
 	}
 
 	chained_irq_exit(irqchip, desc);
@@ -231,13 +220,13 @@ static void pl061_irq_handler(struct irq_desc *desc)
 static void pl061_irq_mask(struct irq_data *d)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
-	struct pl061 *pl061 = gpiochip_get_data(gc);
-	u8 mask = BIT(irqd_to_hwirq(d) % PL061_GPIO_NR);
-	u8 gpioie;
+	struct pl061 *pl061 = pl061_from_gpio_chip(gc);
+	u32 mask = BIT(irqd_to_hwirq(d) % gc->ngpio);
+	u32 gpioie;
 
 	raw_spin_lock(&pl061->lock);
-	gpioie = readb(pl061->base + GPIOIE) & ~mask;
-	writeb(gpioie, pl061->base + GPIOIE);
+	gpioie = pl061_read(pl061, pl061->variant->ie) & ~mask;
+	pl061_write(pl061, gpioie, pl061->variant->ie);
 	raw_spin_unlock(&pl061->lock);
 
 	gpiochip_disable_irq(gc, d->hwirq);
@@ -246,15 +235,15 @@ static void pl061_irq_mask(struct irq_data *d)
 static void pl061_irq_unmask(struct irq_data *d)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
-	struct pl061 *pl061 = gpiochip_get_data(gc);
-	u8 mask = BIT(irqd_to_hwirq(d) % PL061_GPIO_NR);
-	u8 gpioie;
+	struct pl061 *pl061 = pl061_from_gpio_chip(gc);
+	u32 mask = BIT(irqd_to_hwirq(d) % gc->ngpio);
+	u32 gpioie;
 
 	gpiochip_enable_irq(gc, d->hwirq);
 
 	raw_spin_lock(&pl061->lock);
-	gpioie = readb(pl061->base + GPIOIE) | mask;
-	writeb(gpioie, pl061->base + GPIOIE);
+	gpioie = pl061_read(pl061, pl061->variant->ie) | mask;
+	pl061_write(pl061, gpioie, pl061->variant->ie);
 	raw_spin_unlock(&pl061->lock);
 }
 
@@ -269,18 +258,18 @@ static void pl061_irq_unmask(struct irq_data *d)
 static void pl061_irq_ack(struct irq_data *d)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
-	struct pl061 *pl061 = gpiochip_get_data(gc);
-	u8 mask = BIT(irqd_to_hwirq(d) % PL061_GPIO_NR);
+	struct pl061 *pl061 = pl061_from_gpio_chip(gc);
+	u32 mask = BIT(irqd_to_hwirq(d) % gc->ngpio);
 
 	raw_spin_lock(&pl061->lock);
-	writeb(mask, pl061->base + GPIOIC);
+	pl061_write(pl061, mask, pl061->variant->ic);
 	raw_spin_unlock(&pl061->lock);
 }
 
 static int pl061_irq_set_wake(struct irq_data *d, unsigned int state)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
-	struct pl061 *pl061 = gpiochip_get_data(gc);
+	struct pl061 *pl061 = pl061_from_gpio_chip(gc);
 
 	return irq_set_irq_wake(pl061->parent_irq, state);
 }
@@ -306,42 +295,41 @@ static const struct irq_chip pl061_irq_chip = {
 static int pl061_probe(struct amba_device *adev, const struct amba_id *id)
 {
 	struct device *dev = &adev->dev;
+	struct gpio_regmap_config config = {};
+	const struct pl061_variant_data *variant = id->data;
 	struct pl061 *pl061;
 	struct gpio_irq_chip *girq;
+	struct regmap *regmap;
 	int ret, irq;
 
 	pl061 = devm_kzalloc(dev, sizeof(*pl061), GFP_KERNEL);
 	if (pl061 == NULL)
 		return -ENOMEM;
 
+	pl061->variant = variant;
+
 	pl061->base = devm_ioremap_resource(dev, &adev->res);
 	if (IS_ERR(pl061->base))
 		return PTR_ERR(pl061->base);
 
 	raw_spin_lock_init(&pl061->lock);
-	pl061->gc.request = gpiochip_generic_request;
-	pl061->gc.free = gpiochip_generic_free;
-	pl061->gc.base = -1;
-	pl061->gc.get_direction = pl061_get_direction;
-	pl061->gc.direction_input = pl061_direction_input;
-	pl061->gc.direction_output = pl061_direction_output;
-	pl061->gc.get = pl061_get_value;
-	pl061->gc.set = pl061_set_value;
-	pl061->gc.ngpio = PL061_GPIO_NR;
-	pl061->gc.label = dev_name(dev);
-	pl061->gc.parent = dev;
-	pl061->gc.owner = THIS_MODULE;
-
-	/*
-	 * irq_chip support
-	 */
-	writeb(0, pl061->base + GPIOIE); /* disable irqs */
+
+	regmap = devm_regmap_init_mmio(dev, pl061->base, variant->regmap_config);
+	if (IS_ERR(regmap))
+		return PTR_ERR(regmap);
+
+	pl061_write(pl061, 0, variant->ie); /* disable irqs */
+	if (variant->mask != PL061_REG_NONE)
+		pl061_write(pl061, GENMASK(variant->ngpio - 1, 0), variant->mask);
+	if (variant->enable != PL061_REG_NONE)
+		pl061_write(pl061, GENMASK(variant->ngpio - 1, 0), variant->enable);
+
 	irq = adev->irq[0];
 	if (!irq)
 		dev_warn(&adev->dev, "IRQ support disabled\n");
 	pl061->parent_irq = irq;
 
-	girq = &pl061->gc.irq;
+	girq = &pl061->girq;
 	gpio_irq_chip_set_chip(girq, &pl061_irq_chip);
 	girq->parent_handler = pl061_irq_handler;
 	girq->num_parents = 1;
@@ -353,7 +341,19 @@ static int pl061_probe(struct amba_device *adev, const struct amba_id *id)
 	girq->default_type = IRQ_TYPE_NONE;
 	girq->handler = handle_bad_irq;
 
-	ret = devm_gpiochip_add_data(dev, &pl061->gc, pl061);
+	config.parent = dev;
+	config.regmap = regmap;
+	config.ngpio = variant->ngpio;
+	config.reg_dat_base = GPIO_REGMAP_ADDR(variant->data);
+	config.reg_set_base = GPIO_REGMAP_ADDR(variant->data);
+	config.reg_dir_out_base = variant->dir;
+	if (variant->masked_data_address)
+		config.reg_mask_xlate = pl061_reg_mask_xlate;
+	config.write_data_after_dir = variant->write_data_after_dir;
+	config.girq = girq;
+	config.drvdata = pl061;
+
+	ret = PTR_ERR_OR_ZERO(devm_gpio_regmap_register(dev, &config));
 	if (ret)
 		return ret;
 
@@ -366,19 +366,23 @@ static int pl061_probe(struct amba_device *adev, const struct amba_id *id)
 static int pl061_suspend(struct device *dev)
 {
 	struct pl061 *pl061 = dev_get_drvdata(dev);
+	const struct pl061_variant_data *variant = pl061->variant;
 	int offset;
 
+	if (!variant->pm_save_restore)
+		return 0;
+
 	pl061->csave_regs.gpio_data = 0;
-	pl061->csave_regs.gpio_dir = readb(pl061->base + GPIODIR);
-	pl061->csave_regs.gpio_is = readb(pl061->base + GPIOIS);
-	pl061->csave_regs.gpio_ibe = readb(pl061->base + GPIOIBE);
-	pl061->csave_regs.gpio_iev = readb(pl061->base + GPIOIEV);
-	pl061->csave_regs.gpio_ie = readb(pl061->base + GPIOIE);
-
-	for (offset = 0; offset < PL061_GPIO_NR; offset++) {
-		if (pl061->csave_regs.gpio_dir & (BIT(offset)))
+	pl061->csave_regs.gpio_dir = pl061_read(pl061, variant->dir);
+	pl061->csave_regs.gpio_is = pl061_read(pl061, variant->is);
+	pl061->csave_regs.gpio_ibe = pl061_read(pl061, variant->ibe);
+	pl061->csave_regs.gpio_iev = pl061_read(pl061, variant->iev);
+	pl061->csave_regs.gpio_ie = pl061_read(pl061, variant->ie);
+
+	for (offset = 0; offset < variant->ngpio; offset++) {
+		if (pl061->csave_regs.gpio_dir & BIT(offset))
 			pl061->csave_regs.gpio_data |=
-				pl061_get_value(&pl061->gc, offset) << offset;
+				pl061_read(pl061, BIT(offset + 2));
 	}
 
 	return 0;
@@ -387,31 +391,103 @@ static int pl061_suspend(struct device *dev)
 static int pl061_resume(struct device *dev)
 {
 	struct pl061 *pl061 = dev_get_drvdata(dev);
+	const struct pl061_variant_data *variant = pl061->variant;
 	int offset;
 
-	for (offset = 0; offset < PL061_GPIO_NR; offset++) {
-		if (pl061->csave_regs.gpio_dir & (BIT(offset)))
-			pl061_direction_output(&pl061->gc, offset,
-					pl061->csave_regs.gpio_data &
-					(BIT(offset)));
-		else
-			pl061_direction_input(&pl061->gc, offset);
+	if (!variant->pm_save_restore)
+		return 0;
+
+	for (offset = 0; offset < variant->ngpio; offset++) {
+		u32 dir = pl061_read(pl061, variant->dir);
+
+		if (pl061->csave_regs.gpio_dir & BIT(offset)) {
+			u32 value = !!(pl061->csave_regs.gpio_data & BIT(offset)) << offset;
+
+			pl061_write(pl061, value, BIT(offset + 2));
+			pl061_write(pl061, dir | BIT(offset), variant->dir);
+			/*
+			 * gpio value is set again, because pl061 doesn't allow to set value of
+			 * a gpio pin before configuring it in OUT mode.
+			 */
+			pl061_write(pl061, value, BIT(offset + 2));
+		} else {
+			pl061_write(pl061, dir & ~BIT(offset), variant->dir);
+		}
 	}
 
-	writeb(pl061->csave_regs.gpio_is, pl061->base + GPIOIS);
-	writeb(pl061->csave_regs.gpio_ibe, pl061->base + GPIOIBE);
-	writeb(pl061->csave_regs.gpio_iev, pl061->base + GPIOIEV);
-	writeb(pl061->csave_regs.gpio_ie, pl061->base + GPIOIE);
+	pl061_write(pl061, pl061->csave_regs.gpio_is, variant->is);
+	pl061_write(pl061, pl061->csave_regs.gpio_ibe, variant->ibe);
+	pl061_write(pl061, pl061->csave_regs.gpio_iev, variant->iev);
+	pl061_write(pl061, pl061->csave_regs.gpio_ie, variant->ie);
 
 	return 0;
 }
 
 static DEFINE_SIMPLE_DEV_PM_OPS(pl061_dev_pm_ops, pl061_suspend, pl061_resume);
 
+static const struct regmap_config pl061_arm_regmap_config = {
+	.reg_bits = 16,
+	.val_bits = 8,
+	.reg_stride = 4,
+	.max_register = 0x400,
+	.fast_io = true,
+};
+
+static const struct regmap_config pl061_ambarella_regmap_config = {
+	.reg_bits = 32,
+	.val_bits = 32,
+	.reg_stride = 4,
+	.max_register = 0x2c,
+	.fast_io = true,
+};
+
+static struct pl061_variant_data pl061_arm = {
+	.data = 0x000,
+	.dir = 0x400,
+	.is = 0x404,
+	.ibe = 0x408,
+	.iev = 0x40c,
+	.ie = 0x410,
+	.ris = 0x414,
+	.mis = 0x418,
+	.ic = 0x41c,
+	.mask = PL061_REG_NONE,
+	.enable = PL061_REG_NONE,
+	.ngpio = PL061_GPIO_NR,
+	.masked_data_address = true,
+	.write_data_after_dir = true,
+	.pm_save_restore = true,
+	.regmap_config = &pl061_arm_regmap_config,
+};
+
+static struct pl061_variant_data pl061_ambarella = {
+	.data = 0x00,
+	.dir = 0x04,
+	.is = 0x08,
+	.ibe = 0x0c,
+	.iev = 0x10,
+	.ie = 0x14,
+	.ris = 0x1c,
+	.mis = 0x20,
+	.ic = 0x24,
+	.mask = 0x28,
+	.enable = 0x2c,
+	.ngpio = AMBARELLA_GPIO_NR,
+	.access_32bit = true,
+	.clear_irq_on_type = true,
+	.regmap_config = &pl061_ambarella_regmap_config,
+};
+
 static const struct amba_id pl061_ids[] = {
 	{
 		.id	= 0x00041061,
 		.mask	= 0x000fffff,
+		.data	= &pl061_arm,
+	},
+	{
+		.id	= (AMBA_VENDOR_AMBARELLA << 12) | 0x061,
+		.mask	= 0x000fffff,
+		.data	= &pl061_ambarella,
 	},
 	{ 0, 0 },
 };
diff --git a/include/linux/amba/bus.h b/include/linux/amba/bus.h
index 80a74cd2da7e..411533bfa61d 100644
--- a/include/linux/amba/bus.h
+++ b/include/linux/amba/bus.h
@@ -98,6 +98,7 @@ enum amba_vendor {
 	AMBA_VENDOR_ST = 0x80,
 	AMBA_VENDOR_QCOM = 0x51,
 	AMBA_VENDOR_LSI = 0xb6,
+	AMBA_VENDOR_AMBARELLA = 0xe8,
 };
 
 extern const struct bus_type amba_bustype;

-- 
2.34.1

