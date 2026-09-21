From: Long Zhao <longzhao@ambarella.com>
Date: Mon, 21 Sep 2026 12:23:29 +0800
Subject: [PATCH v8 10/18] gpio: pl061: convert register access to regmap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-cv75-v5-v8-10-282ff5d98dda@ambarella.com>
References: <20260921-cv75-v5-v8-0-282ff5d98dda@ambarella.com>
In-Reply-To: <20260921-cv75-v5-v8-0-282ff5d98dda@ambarella.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789964608; l=11255;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=bNMGD8MihqEG4c46cw/A6tznIzR/bR90tX0r5+quMeU=;
 b=CA40djdf4mLPoJECiUp1UGpAicmpzmAXOncX6ZTWV28zd7TZ+RvUi4WcDgEu34RgjQvtee3mV
 Kppqg1dbZD7AXWvos3RwjvUaX/IBiGvfgT1tNI0mlNmycss7mXUNcTT
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace readb()/writeb() with a MMIO regmap while keeping the existing
gpio_chip and girq irqchip. Use a raw spinlock so irq_ack() can run
under the irq descriptor lock.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 drivers/gpio/Kconfig      |   1 +
 drivers/gpio/gpio-pl061.c | 134 ++++++++++++++++++++++++++++++----------------
 2 files changed, 89 insertions(+), 46 deletions(-)

diff --git a/drivers/gpio/Kconfig b/drivers/gpio/Kconfig
index f03c05288376..2a1487bd1a94 100644
--- a/drivers/gpio/Kconfig
+++ b/drivers/gpio/Kconfig
@@ -583,6 +583,7 @@ config GPIO_PL061
 	depends on ARM_AMBA || COMPILE_TEST
 	select IRQ_DOMAIN
 	select GPIOLIB_IRQCHIP
+	select REGMAP_MMIO
 	help
 	  Say yes here to support the PrimeCell PL061 GPIO device.
 
diff --git a/drivers/gpio/gpio-pl061.c b/drivers/gpio/gpio-pl061.c
index 919cf86fd590..66aea0856bc4 100644
--- a/drivers/gpio/gpio-pl061.c
+++ b/drivers/gpio/gpio-pl061.c
@@ -19,9 +19,11 @@
 #include <linux/ioport.h>
 #include <linux/irq.h>
 #include <linux/irqchip/chained_irq.h>
+#include <linux/log2.h>
 #include <linux/module.h>
 #include <linux/pinctrl/consumer.h>
 #include <linux/pm.h>
+#include <linux/regmap.h>
 #include <linux/seq_file.h>
 #include <linux/slab.h>
 #include <linux/spinlock.h>
@@ -36,6 +38,7 @@
 #define GPIOIC  0x41C
 
 #define PL061_GPIO_NR	8
+#define PL061_DATA_OFFSET	2
 
 struct pl061_context_save_regs {
 	u8 gpio_data;
@@ -49,18 +52,49 @@ struct pl061_context_save_regs {
 struct pl061 {
 	raw_spinlock_t		lock;
 
-	void __iomem		*base;
+	struct regmap		*regmap;
 	struct gpio_chip	gc;
 	int			parent_irq;
 
 	struct pl061_context_save_regs csave_regs;
 };
 
+static bool pl061_is_data_reg(unsigned int reg)
+{
+	return is_power_of_2(reg) &&
+	       reg >= BIT(PL061_DATA_OFFSET) &&
+	       reg <= BIT(PL061_DATA_OFFSET + PL061_GPIO_NR - 1);
+}
+
+static bool pl061_volatile_reg(struct device *dev, unsigned int reg)
+{
+	switch (reg) {
+	case GPIOMIS:
+	case GPIOIC:
+		return true;
+	default:
+		return pl061_is_data_reg(reg);
+	}
+}
+
+static const struct regmap_config pl061_regmap_config = {
+	.reg_bits = 16,
+	.val_bits = 8,
+	.reg_stride = 4,
+	.max_register = GPIOIC,
+	.volatile_reg = pl061_volatile_reg,
+	.fast_io = true,
+	.use_raw_spinlock = true,
+};
+
 static int pl061_get_direction(struct gpio_chip *gc, unsigned offset)
 {
 	struct pl061 *pl061 = gpiochip_get_data(gc);
+	unsigned int gpiodir = 0;
 
-	if (readb(pl061->base + GPIODIR) & BIT(offset))
+	regmap_read(pl061->regmap, GPIODIR, &gpiodir);
+
+	if (gpiodir & BIT(offset))
 		return GPIO_LINE_DIRECTION_OUT;
 
 	return GPIO_LINE_DIRECTION_IN;
@@ -70,12 +104,9 @@ static int pl061_direction_input(struct gpio_chip *gc, unsigned offset)
 {
 	struct pl061 *pl061 = gpiochip_get_data(gc);
 	unsigned long flags;
-	unsigned char gpiodir;
 
 	raw_spin_lock_irqsave(&pl061->lock, flags);
-	gpiodir = readb(pl061->base + GPIODIR);
-	gpiodir &= ~(BIT(offset));
-	writeb(gpiodir, pl061->base + GPIODIR);
+	regmap_update_bits(pl061->regmap, GPIODIR, BIT(offset), 0);
 	raw_spin_unlock_irqrestore(&pl061->lock, flags);
 
 	return 0;
@@ -86,19 +117,19 @@ static int pl061_direction_output(struct gpio_chip *gc, unsigned offset,
 {
 	struct pl061 *pl061 = gpiochip_get_data(gc);
 	unsigned long flags;
-	unsigned char gpiodir;
+	unsigned int mask = BIT(offset);
 
 	raw_spin_lock_irqsave(&pl061->lock, flags);
-	writeb(!!value << offset, pl061->base + (BIT(offset + 2)));
-	gpiodir = readb(pl061->base + GPIODIR);
-	gpiodir |= BIT(offset);
-	writeb(gpiodir, pl061->base + GPIODIR);
+	regmap_write(pl061->regmap, BIT(offset + PL061_DATA_OFFSET),
+		     !!value << offset);
+	regmap_update_bits(pl061->regmap, GPIODIR, mask, mask);
 
 	/*
 	 * gpio value is set again, because pl061 doesn't allow to set value of
 	 * a gpio pin before configuring it in OUT mode.
 	 */
-	writeb(!!value << offset, pl061->base + (BIT(offset + 2)));
+	regmap_write(pl061->regmap, BIT(offset + PL061_DATA_OFFSET),
+		     !!value << offset);
 	raw_spin_unlock_irqrestore(&pl061->lock, flags);
 
 	return 0;
@@ -107,15 +138,19 @@ static int pl061_direction_output(struct gpio_chip *gc, unsigned offset,
 static int pl061_get_value(struct gpio_chip *gc, unsigned offset)
 {
 	struct pl061 *pl061 = gpiochip_get_data(gc);
+	unsigned int val = 0;
+
+	regmap_read(pl061->regmap, BIT(offset + PL061_DATA_OFFSET), &val);
 
-	return !!readb(pl061->base + (BIT(offset + 2)));
+	return !!val;
 }
 
 static int pl061_set_value(struct gpio_chip *gc, unsigned int offset, int value)
 {
 	struct pl061 *pl061 = gpiochip_get_data(gc);
 
-	writeb(!!value << offset, pl061->base + (BIT(offset + 2)));
+	regmap_write(pl061->regmap, BIT(offset + PL061_DATA_OFFSET),
+		     !!value << offset);
 
 	return 0;
 }
@@ -126,8 +161,8 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 	struct pl061 *pl061 = gpiochip_get_data(gc);
 	int offset = irqd_to_hwirq(d);
 	unsigned long flags;
-	u8 gpiois, gpioibe, gpioiev;
-	u8 bit = BIT(offset);
+	unsigned int gpiois = 0, gpioibe = 0, gpioiev = 0;
+	unsigned int bit = BIT(offset);
 
 	if (offset < 0 || offset >= PL061_GPIO_NR)
 		return -EINVAL;
@@ -145,9 +180,9 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 
 	raw_spin_lock_irqsave(&pl061->lock, flags);
 
-	gpioiev = readb(pl061->base + GPIOIEV);
-	gpiois = readb(pl061->base + GPIOIS);
-	gpioibe = readb(pl061->base + GPIOIBE);
+	regmap_read(pl061->regmap, GPIOIEV, &gpioiev);
+	regmap_read(pl061->regmap, GPIOIS, &gpiois);
+	regmap_read(pl061->regmap, GPIOIBE, &gpioibe);
 
 	if (trigger & (IRQ_TYPE_LEVEL_HIGH | IRQ_TYPE_LEVEL_LOW)) {
 		bool polarity = trigger & IRQ_TYPE_LEVEL_HIGH;
@@ -199,9 +234,9 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 			 offset);
 	}
 
-	writeb(gpiois, pl061->base + GPIOIS);
-	writeb(gpioibe, pl061->base + GPIOIBE);
-	writeb(gpioiev, pl061->base + GPIOIEV);
+	regmap_write(pl061->regmap, GPIOIS, gpiois);
+	regmap_write(pl061->regmap, GPIOIBE, gpioibe);
+	regmap_write(pl061->regmap, GPIOIEV, gpioiev);
 
 	raw_spin_unlock_irqrestore(&pl061->lock, flags);
 
@@ -211,6 +246,7 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 static void pl061_irq_handler(struct irq_desc *desc)
 {
 	unsigned long pending;
+	unsigned int mis = 0;
 	int offset;
 	struct gpio_chip *gc = irq_desc_get_handler_data(desc);
 	struct pl061 *pl061 = gpiochip_get_data(gc);
@@ -218,8 +254,9 @@ static void pl061_irq_handler(struct irq_desc *desc)
 
 	chained_irq_enter(irqchip, desc);
 
-	pending = readb(pl061->base + GPIOMIS);
-	if (pending) {
+	regmap_read(pl061->regmap, GPIOMIS, &mis);
+	if (mis) {
+		pending = mis;
 		for_each_set_bit(offset, &pending, PL061_GPIO_NR)
 			generic_handle_domain_irq(gc->irq.domain,
 						  offset);
@@ -233,11 +270,9 @@ static void pl061_irq_mask(struct irq_data *d)
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
 	struct pl061 *pl061 = gpiochip_get_data(gc);
 	u8 mask = BIT(irqd_to_hwirq(d) % PL061_GPIO_NR);
-	u8 gpioie;
 
 	raw_spin_lock(&pl061->lock);
-	gpioie = readb(pl061->base + GPIOIE) & ~mask;
-	writeb(gpioie, pl061->base + GPIOIE);
+	regmap_update_bits(pl061->regmap, GPIOIE, mask, 0);
 	raw_spin_unlock(&pl061->lock);
 
 	gpiochip_disable_irq(gc, d->hwirq);
@@ -248,13 +283,11 @@ static void pl061_irq_unmask(struct irq_data *d)
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
 	struct pl061 *pl061 = gpiochip_get_data(gc);
 	u8 mask = BIT(irqd_to_hwirq(d) % PL061_GPIO_NR);
-	u8 gpioie;
 
 	gpiochip_enable_irq(gc, d->hwirq);
 
 	raw_spin_lock(&pl061->lock);
-	gpioie = readb(pl061->base + GPIOIE) | mask;
-	writeb(gpioie, pl061->base + GPIOIE);
+	regmap_update_bits(pl061->regmap, GPIOIE, mask, mask);
 	raw_spin_unlock(&pl061->lock);
 }
 
@@ -272,9 +305,7 @@ static void pl061_irq_ack(struct irq_data *d)
 	struct pl061 *pl061 = gpiochip_get_data(gc);
 	u8 mask = BIT(irqd_to_hwirq(d) % PL061_GPIO_NR);
 
-	raw_spin_lock(&pl061->lock);
-	writeb(mask, pl061->base + GPIOIC);
-	raw_spin_unlock(&pl061->lock);
+	regmap_write(pl061->regmap, GPIOIC, mask);
 }
 
 static int pl061_irq_set_wake(struct irq_data *d, unsigned int state)
@@ -308,15 +339,20 @@ static int pl061_probe(struct amba_device *adev, const struct amba_id *id)
 	struct device *dev = &adev->dev;
 	struct pl061 *pl061;
 	struct gpio_irq_chip *girq;
+	void __iomem *base;
 	int ret, irq;
 
 	pl061 = devm_kzalloc(dev, sizeof(*pl061), GFP_KERNEL);
 	if (pl061 == NULL)
 		return -ENOMEM;
 
-	pl061->base = devm_ioremap_resource(dev, &adev->res);
-	if (IS_ERR(pl061->base))
-		return PTR_ERR(pl061->base);
+	base = devm_ioremap_resource(dev, &adev->res);
+	if (IS_ERR(base))
+		return PTR_ERR(base);
+
+	pl061->regmap = devm_regmap_init_mmio(dev, base, &pl061_regmap_config);
+	if (IS_ERR(pl061->regmap))
+		return PTR_ERR(pl061->regmap);
 
 	raw_spin_lock_init(&pl061->lock);
 	pl061->gc.request = gpiochip_generic_request;
@@ -335,7 +371,7 @@ static int pl061_probe(struct amba_device *adev, const struct amba_id *id)
 	/*
 	 * irq_chip support
 	 */
-	writeb(0, pl061->base + GPIOIE); /* disable irqs */
+	regmap_write(pl061->regmap, GPIOIE, 0); /* disable irqs */
 	irq = adev->irq[0];
 	if (!irq)
 		dev_warn(&adev->dev, "IRQ support disabled\n");
@@ -366,14 +402,20 @@ static int pl061_probe(struct amba_device *adev, const struct amba_id *id)
 static int pl061_suspend(struct device *dev)
 {
 	struct pl061 *pl061 = dev_get_drvdata(dev);
+	unsigned int val = 0;
 	int offset;
 
 	pl061->csave_regs.gpio_data = 0;
-	pl061->csave_regs.gpio_dir = readb(pl061->base + GPIODIR);
-	pl061->csave_regs.gpio_is = readb(pl061->base + GPIOIS);
-	pl061->csave_regs.gpio_ibe = readb(pl061->base + GPIOIBE);
-	pl061->csave_regs.gpio_iev = readb(pl061->base + GPIOIEV);
-	pl061->csave_regs.gpio_ie = readb(pl061->base + GPIOIE);
+	regmap_read(pl061->regmap, GPIODIR, &val);
+	pl061->csave_regs.gpio_dir = val;
+	regmap_read(pl061->regmap, GPIOIS, &val);
+	pl061->csave_regs.gpio_is = val;
+	regmap_read(pl061->regmap, GPIOIBE, &val);
+	pl061->csave_regs.gpio_ibe = val;
+	regmap_read(pl061->regmap, GPIOIEV, &val);
+	pl061->csave_regs.gpio_iev = val;
+	regmap_read(pl061->regmap, GPIOIE, &val);
+	pl061->csave_regs.gpio_ie = val;
 
 	for (offset = 0; offset < PL061_GPIO_NR; offset++) {
 		if (pl061->csave_regs.gpio_dir & (BIT(offset)))
@@ -398,10 +440,10 @@ static int pl061_resume(struct device *dev)
 			pl061_direction_input(&pl061->gc, offset);
 	}
 
-	writeb(pl061->csave_regs.gpio_is, pl061->base + GPIOIS);
-	writeb(pl061->csave_regs.gpio_ibe, pl061->base + GPIOIBE);
-	writeb(pl061->csave_regs.gpio_iev, pl061->base + GPIOIEV);
-	writeb(pl061->csave_regs.gpio_ie, pl061->base + GPIOIE);
+	regmap_write(pl061->regmap, GPIOIS, pl061->csave_regs.gpio_is);
+	regmap_write(pl061->regmap, GPIOIBE, pl061->csave_regs.gpio_ibe);
+	regmap_write(pl061->regmap, GPIOIEV, pl061->csave_regs.gpio_iev);
+	regmap_write(pl061->regmap, GPIOIE, pl061->csave_regs.gpio_ie);
 
 	return 0;
 }

-- 
2.34.1

