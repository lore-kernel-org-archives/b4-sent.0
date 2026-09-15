From: Long Zhao <longzhao@ambarella.com>
Date: Tue, 15 Sep 2026 19:15:40 +0800
Subject: [PATCH v7 10/15] gpio: pl061: convert to gpio-regmap and a custom
 irqchip
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-cv75-v5-v7-10-3297d3fbc9c0@ambarella.com>
References: <20260915-cv75-v5-v7-0-3297d3fbc9c0@ambarella.com>
In-Reply-To: <20260915-cv75-v5-v7-0-3297d3fbc9c0@ambarella.com>
To: Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, soc@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org
Cc: Long Zhao <longzhao@ambarella.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Jerome Brunet <jbrunet@baylibre.com>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789470938; l=21342;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=0/xWTlnahFg+Dj0CSJrqyQAxY9Ljob2ksjDxt6GOHl4=;
 b=Vj713LqQc51hfiNA1dFJW3z3e2C0T6wK8p4L9LuUva+cvPcsJlKvDIBUMTykdijh4nHSCwIvI
 y7EgQ7/zV1TDmZ6hmmsacYjZ8vGA64sG5bMILFVRWfXnCzXXOTqpmyP
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move line get/set/direction onto gpio-regmap. Keep the existing ARM
masked data addresses and write-after-direction behaviour.

Do not use gpiochip irqchip setup (girq) or regmap-irq. gpio-regmap
owns gpiochip registration, so girq would have to be plumbed through
that helper. PL061 IRQ type programming needs IS/IBE/IEV, including
both-edge, plus a hardirq chained demux from the parent AMBA IRQ;
regmap-irq is a poor fit for that.

Create a linear irq_domain with gpio_chip as host data, attach it with
gpiochip_irqchip_add_domain(), and chain the parent IRQ in this driver.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 drivers/gpio/Kconfig      |   2 +
 drivers/gpio/gpio-pl061.c | 531 +++++++++++++++++++++++++++++-----------------
 2 files changed, 344 insertions(+), 189 deletions(-)

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
index 919cf86fd590..1d448aafca50 100644
--- a/drivers/gpio/gpio-pl061.c
+++ b/drivers/gpio/gpio-pl061.c
@@ -11,130 +11,109 @@
 #include <linux/amba/bus.h>
 #include <linux/bitops.h>
 #include <linux/device.h>
+#include <linux/err.h>
 #include <linux/errno.h>
-#include <linux/gpio/driver.h>
-#include <linux/init.h>
 #include <linux/interrupt.h>
 #include <linux/io.h>
 #include <linux/ioport.h>
 #include <linux/irq.h>
-#include <linux/irqchip/chained_irq.h>
+#include <linux/irqdomain.h>
+#include <linux/log2.h>
 #include <linux/module.h>
-#include <linux/pinctrl/consumer.h>
 #include <linux/pm.h>
+#include <linux/regmap.h>
 #include <linux/seq_file.h>
-#include <linux/slab.h>
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
-
-struct pl061_context_save_regs {
-	u8 gpio_data;
-	u8 gpio_dir;
-	u8 gpio_is;
-	u8 gpio_ibe;
-	u8 gpio_iev;
-	u8 gpio_ie;
+#include <linux/gpio/driver.h>
+#include <linux/gpio/regmap.h>
+#include <linux/irqchip/chained_irq.h>
+
+#define PL061_GPIO_NR		8
+#define PL061_DATA_OFFSET	2
+
+#define PL061_DIR		0x400
+#define PL061_IS		0x404
+#define PL061_IBE		0x408
+#define PL061_IEV		0x40c
+#define PL061_IE		0x410
+#define PL061_MIS		0x418
+#define PL061_IC		0x41c
+
+struct pl061_regs {
+	unsigned int dat;
+	unsigned int dir;
+	unsigned int is;
+	unsigned int ibe;
+	unsigned int iev;
+	unsigned int ie;
+	unsigned int mis;
+	unsigned int ic;
+	unsigned int mask;
+	unsigned int enable;
+};
+
+struct pl061_drvdata {
+	const struct regmap_config *regmap_config;
+	const struct pl061_regs *regs;
+	unsigned int ngpio;
+	bool write_data_after_dir;
+	bool clear_irq_on_type;
+	bool pm;
+	int (*reg_mask_xlate)(struct gpio_regmap *gpio, unsigned int base,
+			      unsigned int offset, unsigned int *reg,
+			      unsigned int *mask);
 };
 
 struct pl061 {
 	raw_spinlock_t		lock;
-
-	void __iomem		*base;
-	struct gpio_chip	gc;
+	struct regmap		*regmap;
+	const struct pl061_drvdata *data;
+	struct irq_domain	*irq_domain;
 	int			parent_irq;
-
-	struct pl061_context_save_regs csave_regs;
+	u32			saved_dat;
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
-{
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
-}
-
-static int pl061_direction_output(struct gpio_chip *gc, unsigned offset,
-		int value)
+static struct pl061 *pl061_from_gpio_chip(struct gpio_chip *gc)
 {
-	struct pl061 *pl061 = gpiochip_get_data(gc);
-	unsigned long flags;
-	unsigned char gpiodir;
-
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
+	return gpio_regmap_get_drvdata(gpiochip_get_data(gc));
 }
 
-static int pl061_get_value(struct gpio_chip *gc, unsigned offset)
+static unsigned int pl061_line_mask(struct pl061 *pl061, irq_hw_number_t hwirq)
 {
-	struct pl061 *pl061 = gpiochip_get_data(gc);
-
-	return !!readb(pl061->base + (BIT(offset + 2)));
+	return BIT(hwirq % pl061->data->ngpio);
 }
 
-static int pl061_set_value(struct gpio_chip *gc, unsigned int offset, int value)
+static int pl061_arm_reg_mask_xlate(struct gpio_regmap *gpio, unsigned int base,
+				    unsigned int offset, unsigned int *reg,
+				    unsigned int *mask)
 {
-	struct pl061 *pl061 = gpiochip_get_data(gc);
-
-	writeb(!!value << offset, pl061->base + (BIT(offset + 2)));
+	if (base == 0)
+		*reg = BIT(offset + PL061_DATA_OFFSET);
+	else
+		*reg = base;
+	*mask = BIT(offset);
 
 	return 0;
 }
 
-static int pl061_irq_type(struct irq_data *d, unsigned trigger)
+static int pl061_irq_type(struct irq_data *d, unsigned int trigger)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
-	struct pl061 *pl061 = gpiochip_get_data(gc);
+	struct pl061 *pl061 = pl061_from_gpio_chip(gc);
+	const struct pl061_regs *regs = pl061->data->regs;
+	unsigned int gpiois, gpioibe, gpioiev;
 	int offset = irqd_to_hwirq(d);
 	unsigned long flags;
-	u8 gpiois, gpioibe, gpioiev;
-	u8 bit = BIT(offset);
+	unsigned int bit;
+	int ret;
 
-	if (offset < 0 || offset >= PL061_GPIO_NR)
+	if (offset < 0 || offset >= pl061->data->ngpio)
 		return -EINVAL;
 
-	if ((trigger & (IRQ_TYPE_LEVEL_HIGH | IRQ_TYPE_LEVEL_LOW)) &&
-	    (trigger & (IRQ_TYPE_EDGE_RISING | IRQ_TYPE_EDGE_FALLING)))
-	{
+	bit = BIT(offset);
+
+	if ((trigger & IRQ_TYPE_LEVEL_MASK) && (trigger & IRQ_TYPE_EDGE_BOTH)) {
 		dev_err(gc->parent,
 			"trying to configure line %d for both level and edge "
 			"detection, choose one!\n",
@@ -142,14 +121,19 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 		return -EINVAL;
 	}
 
-
 	raw_spin_lock_irqsave(&pl061->lock, flags);
 
-	gpioiev = readb(pl061->base + GPIOIEV);
-	gpiois = readb(pl061->base + GPIOIS);
-	gpioibe = readb(pl061->base + GPIOIBE);
+	ret = regmap_read(pl061->regmap, regs->iev, &gpioiev);
+	if (ret)
+		goto out;
+	ret = regmap_read(pl061->regmap, regs->is, &gpiois);
+	if (ret)
+		goto out;
+	ret = regmap_read(pl061->regmap, regs->ibe, &gpioibe);
+	if (ret)
+		goto out;
 
-	if (trigger & (IRQ_TYPE_LEVEL_HIGH | IRQ_TYPE_LEVEL_LOW)) {
+	if (trigger & IRQ_TYPE_LEVEL_MASK) {
 		bool polarity = trigger & IRQ_TYPE_LEVEL_HIGH;
 
 		/* Disable edge detection */
@@ -199,30 +183,38 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 			 offset);
 	}
 
-	writeb(gpiois, pl061->base + GPIOIS);
-	writeb(gpioibe, pl061->base + GPIOIBE);
-	writeb(gpioiev, pl061->base + GPIOIEV);
+	ret = regmap_write(pl061->regmap, regs->is, gpiois);
+	if (ret)
+		goto out;
+	ret = regmap_write(pl061->regmap, regs->ibe, gpioibe);
+	if (ret)
+		goto out;
+	ret = regmap_write(pl061->regmap, regs->iev, gpioiev);
+	if (ret)
+		goto out;
+	if (pl061->data->clear_irq_on_type)
+		ret = regmap_write(pl061->regmap, regs->ic, bit);
 
+out:
 	raw_spin_unlock_irqrestore(&pl061->lock, flags);
-
-	return 0;
+	return ret;
 }
 
 static void pl061_irq_handler(struct irq_desc *desc)
 {
 	unsigned long pending;
+	unsigned int mis;
 	int offset;
 	struct gpio_chip *gc = irq_desc_get_handler_data(desc);
-	struct pl061 *pl061 = gpiochip_get_data(gc);
+	struct pl061 *pl061 = pl061_from_gpio_chip(gc);
 	struct irq_chip *irqchip = irq_desc_get_chip(desc);
 
 	chained_irq_enter(irqchip, desc);
 
-	pending = readb(pl061->base + GPIOMIS);
-	if (pending) {
-		for_each_set_bit(offset, &pending, PL061_GPIO_NR)
-			generic_handle_domain_irq(gc->irq.domain,
-						  offset);
+	if (!regmap_read(pl061->regmap, pl061->data->regs->mis, &mis) && mis) {
+		pending = mis;
+		for_each_set_bit(offset, &pending, pl061->data->ngpio)
+			generic_handle_domain_irq(pl061->irq_domain, offset);
 	}
 
 	chained_irq_exit(irqchip, desc);
@@ -231,31 +223,21 @@ static void pl061_irq_handler(struct irq_desc *desc)
 static void pl061_irq_mask(struct irq_data *d)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
-	struct pl061 *pl061 = gpiochip_get_data(gc);
-	u8 mask = BIT(irqd_to_hwirq(d) % PL061_GPIO_NR);
-	u8 gpioie;
-
-	raw_spin_lock(&pl061->lock);
-	gpioie = readb(pl061->base + GPIOIE) & ~mask;
-	writeb(gpioie, pl061->base + GPIOIE);
-	raw_spin_unlock(&pl061->lock);
+	struct pl061 *pl061 = pl061_from_gpio_chip(gc);
+	unsigned int mask = pl061_line_mask(pl061, irqd_to_hwirq(d));
 
+	regmap_update_bits(pl061->regmap, pl061->data->regs->ie, mask, 0);
 	gpiochip_disable_irq(gc, d->hwirq);
 }
 
 static void pl061_irq_unmask(struct irq_data *d)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
-	struct pl061 *pl061 = gpiochip_get_data(gc);
-	u8 mask = BIT(irqd_to_hwirq(d) % PL061_GPIO_NR);
-	u8 gpioie;
+	struct pl061 *pl061 = pl061_from_gpio_chip(gc);
+	unsigned int mask = pl061_line_mask(pl061, irqd_to_hwirq(d));
 
 	gpiochip_enable_irq(gc, d->hwirq);
-
-	raw_spin_lock(&pl061->lock);
-	gpioie = readb(pl061->base + GPIOIE) | mask;
-	writeb(gpioie, pl061->base + GPIOIE);
-	raw_spin_unlock(&pl061->lock);
+	regmap_update_bits(pl061->regmap, pl061->data->regs->ie, mask, mask);
 }
 
 /**
@@ -269,18 +251,16 @@ static void pl061_irq_unmask(struct irq_data *d)
 static void pl061_irq_ack(struct irq_data *d)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
-	struct pl061 *pl061 = gpiochip_get_data(gc);
-	u8 mask = BIT(irqd_to_hwirq(d) % PL061_GPIO_NR);
+	struct pl061 *pl061 = pl061_from_gpio_chip(gc);
+	unsigned int mask = pl061_line_mask(pl061, irqd_to_hwirq(d));
 
-	raw_spin_lock(&pl061->lock);
-	writeb(mask, pl061->base + GPIOIC);
-	raw_spin_unlock(&pl061->lock);
+	regmap_write(pl061->regmap, pl061->data->regs->ic, mask);
 }
 
 static int pl061_irq_set_wake(struct irq_data *d, unsigned int state)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
-	struct pl061 *pl061 = gpiochip_get_data(gc);
+	struct pl061 *pl061 = pl061_from_gpio_chip(gc);
 
 	return irq_set_irq_wake(pl061->parent_irq, state);
 }
@@ -292,7 +272,8 @@ static void pl061_irq_print_chip(struct irq_data *data, struct seq_file *p)
 	seq_puts(p, dev_name(gc->parent));
 }
 
-static const struct irq_chip pl061_irq_chip = {
+static const struct irq_chip pl061_irqchip = {
+	.name			= "pl061",
 	.irq_ack		= pl061_irq_ack,
 	.irq_mask		= pl061_irq_mask,
 	.irq_unmask		= pl061_irq_unmask,
@@ -303,59 +284,186 @@ static const struct irq_chip pl061_irq_chip = {
 	GPIOCHIP_IRQ_RESOURCE_HELPERS,
 };
 
+static int pl061_irq_domain_map(struct irq_domain *d, unsigned int virq,
+				irq_hw_number_t hwirq)
+{
+	struct gpio_chip *gc = d->host_data;
+	struct pl061 *pl061 = pl061_from_gpio_chip(gc);
+
+	irq_set_chip_data(virq, gc);
+	irq_set_chip_and_handler(virq, &pl061_irqchip, handle_bad_irq);
+	irq_set_noprobe(virq);
+	irq_set_parent(virq, pl061->parent_irq);
+
+	return 0;
+}
+
+static void pl061_irq_domain_unmap(struct irq_domain *d, unsigned int virq)
+{
+	irq_set_chip_and_handler(virq, NULL, NULL);
+	irq_set_chip_data(virq, NULL);
+}
+
+static const struct irq_domain_ops pl061_irq_domain_ops = {
+	.map	= pl061_irq_domain_map,
+	.unmap	= pl061_irq_domain_unmap,
+	.xlate	= irq_domain_xlate_twothreecell,
+};
+
+static void pl061_remove_irq(void *data)
+{
+	struct pl061 *pl061 = data;
+
+	irq_set_chained_handler_and_data(pl061->parent_irq, NULL, NULL);
+
+	for (unsigned int i = 0; i < pl061->data->ngpio; i++) {
+		unsigned int virq = irq_find_mapping(pl061->irq_domain, i);
+
+		if (virq)
+			irq_dispose_mapping(virq);
+	}
+
+	irq_domain_remove(pl061->irq_domain);
+}
+
+static bool pl061_arm_is_data_reg(unsigned int reg)
+{
+	return reg >= BIT(PL061_DATA_OFFSET) &&
+	       reg <= BIT(PL061_DATA_OFFSET + PL061_GPIO_NR - 1) &&
+	       is_power_of_2(reg);
+}
+
+static bool pl061_arm_volatile_reg(struct device *dev, unsigned int reg)
+{
+	switch (reg) {
+	case PL061_MIS:
+	case PL061_IC:
+		return true;
+	default:
+		return pl061_arm_is_data_reg(reg);
+	}
+}
+
+static const struct regmap_config pl061_arm_regmap_config = {
+	.reg_bits = 16,
+	.val_bits = 8,
+	.reg_stride = 4,
+	.max_register = PL061_IC,
+	.volatile_reg = pl061_arm_volatile_reg,
+	.cache_type = REGCACHE_FLAT_S,
+	.fast_io = true,
+};
+
+static const struct pl061_regs pl061_arm_regs = {
+	.dir	= PL061_DIR,
+	.is	= PL061_IS,
+	.ibe	= PL061_IBE,
+	.iev	= PL061_IEV,
+	.ie	= PL061_IE,
+	.mis	= PL061_MIS,
+	.ic	= PL061_IC,
+};
+
+static const struct pl061_drvdata pl061_arm = {
+	.regmap_config		= &pl061_arm_regmap_config,
+	.regs			= &pl061_arm_regs,
+	.ngpio			= PL061_GPIO_NR,
+	.write_data_after_dir	= true,
+	.pm			= true,
+	.reg_mask_xlate		= pl061_arm_reg_mask_xlate,
+};
+
 static int pl061_probe(struct amba_device *adev, const struct amba_id *id)
 {
 	struct device *dev = &adev->dev;
+	const struct pl061_drvdata *data = id->data;
+	const struct pl061_regs *regs;
+	struct gpio_regmap_config config = {};
+	struct gpio_regmap *gpio_regmap;
+	struct gpio_chip *gc;
 	struct pl061 *pl061;
-	struct gpio_irq_chip *girq;
+	void __iomem *base;
 	int ret, irq;
 
+	if (!data)
+		return -EINVAL;
+
+	regs = data->regs;
+
 	pl061 = devm_kzalloc(dev, sizeof(*pl061), GFP_KERNEL);
-	if (pl061 == NULL)
+	if (!pl061)
 		return -ENOMEM;
 
-	pl061->base = devm_ioremap_resource(dev, &adev->res);
-	if (IS_ERR(pl061->base))
-		return PTR_ERR(pl061->base);
-
+	pl061->data = data;
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
+
+	base = devm_ioremap_resource(dev, &adev->res);
+	if (IS_ERR(base))
+		return PTR_ERR(base);
+
+	pl061->regmap = devm_regmap_init_mmio(dev, base, data->regmap_config);
+	if (IS_ERR(pl061->regmap))
+		return PTR_ERR(pl061->regmap);
+
+	if (regs->enable) {
+		ret = regmap_write(pl061->regmap, regs->enable, ~0U);
+		if (ret)
+			return ret;
+	}
+	if (regs->mask) {
+		ret = regmap_write(pl061->regmap, regs->mask, ~0U);
+		if (ret)
+			return ret;
+	}
 
 	/*
 	 * irq_chip support
 	 */
-	writeb(0, pl061->base + GPIOIE); /* disable irqs */
+	ret = regmap_write(pl061->regmap, regs->ie, 0); /* disable irqs */
+	if (ret)
+		return ret;
+
 	irq = adev->irq[0];
 	if (!irq)
-		dev_warn(&adev->dev, "IRQ support disabled\n");
+		dev_warn(dev, "IRQ support disabled\n");
 	pl061->parent_irq = irq;
 
-	girq = &pl061->gc.irq;
-	gpio_irq_chip_set_chip(girq, &pl061_irq_chip);
-	girq->parent_handler = pl061_irq_handler;
-	girq->num_parents = 1;
-	girq->parents = devm_kcalloc(dev, 1, sizeof(*girq->parents),
-				     GFP_KERNEL);
-	if (!girq->parents)
-		return -ENOMEM;
-	girq->parents[0] = irq;
-	girq->default_type = IRQ_TYPE_NONE;
-	girq->handler = handle_bad_irq;
-
-	ret = devm_gpiochip_add_data(dev, &pl061->gc, pl061);
-	if (ret)
-		return ret;
+	config.parent = dev;
+	config.regmap = pl061->regmap;
+	config.ngpio = data->ngpio;
+	config.reg_dat_base = GPIO_REGMAP_ADDR(regs->dat);
+	config.reg_set_base = GPIO_REGMAP_ADDR(regs->dat);
+	config.reg_dir_out_base = regs->dir;
+	config.reg_mask_xlate = data->reg_mask_xlate;
+	config.write_data_after_dir = data->write_data_after_dir;
+	config.drvdata = pl061;
+
+	gpio_regmap = devm_gpio_regmap_register(dev, &config);
+	if (IS_ERR(gpio_regmap))
+		return PTR_ERR(gpio_regmap);
+
+	gc = gpio_regmap_get_chip(gpio_regmap);
+
+	if (irq) {
+		pl061->irq_domain = irq_domain_create_linear(dev_fwnode(dev),
+							     data->ngpio,
+							     &pl061_irq_domain_ops,
+							     gc);
+		if (!pl061->irq_domain)
+			return -ENOMEM;
+
+		ret = gpiochip_irqchip_add_domain(gc, pl061->irq_domain);
+		if (ret) {
+			irq_domain_remove(pl061->irq_domain);
+			return ret;
+		}
+
+		ret = devm_add_action_or_reset(dev, pl061_remove_irq, pl061);
+		if (ret)
+			return ret;
+
+		irq_set_chained_handler_and_data(irq, pl061_irq_handler, gc);
+	}
 
 	amba_set_drvdata(adev, pl061);
 	dev_info(dev, "PL061 GPIO chip registered\n");
@@ -363,22 +471,52 @@ static int pl061_probe(struct amba_device *adev, const struct amba_id *id)
 	return 0;
 }
 
+static int pl061_cache_ctrl_regs(struct pl061 *pl061, unsigned int *dir)
+{
+	const struct pl061_regs *regs = pl061->data->regs;
+	unsigned int val;
+	int ret;
+
+	ret = regmap_read(pl061->regmap, regs->dir, dir);
+	if (ret)
+		return ret;
+	ret = regmap_read(pl061->regmap, regs->is, &val);
+	if (ret)
+		return ret;
+	ret = regmap_read(pl061->regmap, regs->ibe, &val);
+	if (ret)
+		return ret;
+	ret = regmap_read(pl061->regmap, regs->iev, &val);
+	if (ret)
+		return ret;
+
+	return regmap_read(pl061->regmap, regs->ie, &val);
+}
+
 static int pl061_suspend(struct device *dev)
 {
 	struct pl061 *pl061 = dev_get_drvdata(dev);
-	int offset;
+	unsigned int dir, val;
+	int offset, ret;
+
+	if (!pl061->data->pm)
+		return 0;
+
+	ret = pl061_cache_ctrl_regs(pl061, &dir);
+	if (ret)
+		return ret;
 
-	pl061->csave_regs.gpio_data = 0;
-	pl061->csave_regs.gpio_dir = readb(pl061->base + GPIODIR);
-	pl061->csave_regs.gpio_is = readb(pl061->base + GPIOIS);
-	pl061->csave_regs.gpio_ibe = readb(pl061->base + GPIOIBE);
-	pl061->csave_regs.gpio_iev = readb(pl061->base + GPIOIEV);
-	pl061->csave_regs.gpio_ie = readb(pl061->base + GPIOIE);
-
-	for (offset = 0; offset < PL061_GPIO_NR; offset++) {
-		if (pl061->csave_regs.gpio_dir & (BIT(offset)))
-			pl061->csave_regs.gpio_data |=
-				pl061_get_value(&pl061->gc, offset) << offset;
+	pl061->saved_dat = 0;
+	for (offset = 0; offset < pl061->data->ngpio; offset++) {
+		if (!(dir & BIT(offset)))
+			continue;
+
+		ret = regmap_read_bypassed(pl061->regmap,
+					   BIT(offset + PL061_DATA_OFFSET),
+					   &val);
+		if (ret)
+			return ret;
+		pl061->saved_dat |= val;
 	}
 
 	return 0;
@@ -387,23 +525,37 @@ static int pl061_suspend(struct device *dev)
 static int pl061_resume(struct device *dev)
 {
 	struct pl061 *pl061 = dev_get_drvdata(dev);
-	int offset;
+	const struct pl061_regs *regs;
+	unsigned int dir;
+	int offset, ret;
 
-	for (offset = 0; offset < PL061_GPIO_NR; offset++) {
-		if (pl061->csave_regs.gpio_dir & (BIT(offset)))
-			pl061_direction_output(&pl061->gc, offset,
-					pl061->csave_regs.gpio_data &
-					(BIT(offset)));
-		else
-			pl061_direction_input(&pl061->gc, offset);
-	}
+	if (!pl061->data->pm)
+		return 0;
 
-	writeb(pl061->csave_regs.gpio_is, pl061->base + GPIOIS);
-	writeb(pl061->csave_regs.gpio_ibe, pl061->base + GPIOIBE);
-	writeb(pl061->csave_regs.gpio_iev, pl061->base + GPIOIEV);
-	writeb(pl061->csave_regs.gpio_ie, pl061->base + GPIOIE);
+	regs = pl061->data->regs;
 
-	return 0;
+	ret = regmap_read(pl061->regmap, regs->dir, &dir);
+	if (ret)
+		return ret;
+
+	regcache_mark_dirty(pl061->regmap);
+
+	ret = regcache_sync_region(pl061->regmap, regs->dir, regs->dir);
+	if (ret)
+		return ret;
+
+	for (offset = 0; offset < pl061->data->ngpio; offset++) {
+		if (!(dir & BIT(offset)))
+			continue;
+
+		ret = regmap_write(pl061->regmap,
+				   BIT(offset + PL061_DATA_OFFSET),
+				   !!(pl061->saved_dat & BIT(offset)) << offset);
+		if (ret)
+			return ret;
+	}
+
+	return regcache_sync_region(pl061->regmap, regs->is, regs->ie);
 }
 
 static DEFINE_SIMPLE_DEV_PM_OPS(pl061_dev_pm_ops, pl061_suspend, pl061_resume);
@@ -412,6 +564,7 @@ static const struct amba_id pl061_ids[] = {
 	{
 		.id	= 0x00041061,
 		.mask	= 0x000fffff,
+		.data	= (void *)&pl061_arm,
 	},
 	{ 0, 0 },
 };

-- 
2.34.1

