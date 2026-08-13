From: Long Zhao <longzhao@ambarella.com>
Date: Thu, 13 Aug 2026 18:19:37 +0800
Subject: [PATCH v3 2/3] gpio: pl061: add Ambarella CV75 register layout
 variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-cv75-v3-b-v3-2-1d82e18da09b@ambarella.com>
References: <20260813-cv75-v3-b-v3-0-1d82e18da09b@ambarella.com>
In-Reply-To: <20260813-cv75-v3-b-v3-0-1d82e18da09b@ambarella.com>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786616380; l=16958;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=YfYtQj7Xovs5OWqzlv/T3tMKMeKQ2jLFCSoHI0SgglQ=;
 b=5hI1kcH8xUqO/4vT5JZug50+x15BhpORcz5Zn6ZOxmpRH8iMKfIabvlBbggJGMzMigzB661OF
 MCTHKhP4WV/AU8NzYh2taXAYCOiF7BNEVr7C3ZCJ+H9aZCyXc5hVyPK
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend gpio-pl061 with a per-variant register layout so the Ambarella
CV75 GPIO banks can reuse the PL061 driver instead of a duplicate.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 .../devicetree/bindings/gpio/pl061-gpio.yaml       |  35 ++-
 drivers/gpio/gpio-pl061.c                          | 280 ++++++++++++++++-----
 2 files changed, 244 insertions(+), 71 deletions(-)

diff --git a/Documentation/devicetree/bindings/gpio/pl061-gpio.yaml b/Documentation/devicetree/bindings/gpio/pl061-gpio.yaml
index 4d970e55104b..414f8d4a3976 100644
--- a/Documentation/devicetree/bindings/gpio/pl061-gpio.yaml
+++ b/Documentation/devicetree/bindings/gpio/pl061-gpio.yaml
@@ -15,7 +15,9 @@ select:
   properties:
     compatible:
       contains:
-        const: arm,pl061
+        enum:
+          - arm,pl061
+          - ambarella,cv75-gpio
   required:
     - compatible
 
@@ -24,9 +26,20 @@ properties:
     pattern: "^gpio@[0-9a-f]+$"
 
   compatible:
-    items:
-      - const: arm,pl061
-      - const: arm,primecell
+    oneOf:
+      - items:
+          - const: arm,pl061
+          - const: arm,primecell
+      - items:
+          - const: ambarella,cv75-gpio
+          - const: arm,primecell
+
+  arm,primecell-periphid:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description:
+      Value to override the hardware PrimeCell peripheral ID. Ambarella
+      variants use a synthetic ID retaining the PL061 part number because
+      the hardware has no discoverable ID or assigned designer ID.
 
   reg:
     maxItems: 1
@@ -57,6 +70,20 @@ properties:
     minItems: 1
     maxItems: 8
 
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: ambarella,cv75-gpio
+    then:
+      properties:
+        arm,primecell-periphid:
+          const: 0x00000061
+      required:
+        - arm,primecell-periphid
+        - gpio-ranges
+
 required:
   - compatible
   - reg
diff --git a/drivers/gpio/gpio-pl061.c b/drivers/gpio/gpio-pl061.c
index 919cf86fd590..d9e5a9f25681 100644
--- a/drivers/gpio/gpio-pl061.c
+++ b/drivers/gpio/gpio-pl061.c
@@ -26,41 +26,94 @@
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
 #define PL061_GPIO_NR	8
+#define PL061_REG_NONE	U32_MAX
+#define PL061_AMBARELLA_PERIPH_ID	0x00000061
+
+struct pl061_variant_data {
+	u32 data;
+	u32 dir;
+	u32 is;
+	u32 ibe;
+	u32 iev;
+	u32 ie;
+	u32 ris;
+	u32 mis;
+	u32 ic;
+	u32 afsel;
+	u32 mask;
+	u32 enable;
+	unsigned int ngpio;
+	bool access_32bit;
+	bool masked_data_address;
+	bool write_data_after_dir;
+	bool clear_irq_on_type;
+};
 
 struct pl061_context_save_regs {
-	u8 gpio_data;
-	u8 gpio_dir;
-	u8 gpio_is;
-	u8 gpio_ibe;
-	u8 gpio_iev;
-	u8 gpio_ie;
+	u32 gpio_data;
+	u32 gpio_dir;
+	u32 gpio_is;
+	u32 gpio_ibe;
+	u32 gpio_iev;
+	u32 gpio_ie;
+	u32 gpio_afsel;
+	u32 gpio_mask;
 };
 
 struct pl061 {
 	raw_spinlock_t		lock;
 
 	void __iomem		*base;
+	const struct pl061_variant_data *variant;
 	struct gpio_chip	gc;
 	int			parent_irq;
 
 	struct pl061_context_save_regs csave_regs;
 };
 
+static u32 pl061_read(struct pl061 *pl061, u32 offset)
+{
+	if (pl061->variant->access_32bit)
+		return readl_relaxed(pl061->base + offset);
+
+	return readb_relaxed(pl061->base + offset);
+}
+
+static void pl061_write(struct pl061 *pl061, u32 value, u32 offset)
+{
+	if (pl061->variant->access_32bit)
+		writel_relaxed(value, pl061->base + offset);
+	else
+		writeb_relaxed(value, pl061->base + offset);
+}
+
+static int pl061_get_data(struct pl061 *pl061, unsigned int offset)
+{
+	if (pl061->variant->masked_data_address)
+		return !!readb_relaxed(pl061->base + BIT(offset + 2));
+
+	pl061_write(pl061, BIT(offset), pl061->variant->mask);
+	return !!(pl061_read(pl061, pl061->variant->data) & BIT(offset));
+}
+
+static void pl061_set_data(struct pl061 *pl061, unsigned int offset, int value)
+{
+	if (pl061->variant->masked_data_address) {
+		writeb_relaxed(!!value << offset,
+			       pl061->base + BIT(offset + 2));
+		return;
+	}
+
+	pl061_write(pl061, BIT(offset), pl061->variant->mask);
+	pl061_write(pl061, value ? BIT(offset) : 0, pl061->variant->data);
+}
+
 static int pl061_get_direction(struct gpio_chip *gc, unsigned offset)
 {
 	struct pl061 *pl061 = gpiochip_get_data(gc);
 
-	if (readb(pl061->base + GPIODIR) & BIT(offset))
+	if (pl061_read(pl061, pl061->variant->dir) & BIT(offset))
 		return GPIO_LINE_DIRECTION_OUT;
 
 	return GPIO_LINE_DIRECTION_IN;
@@ -70,12 +123,12 @@ static int pl061_direction_input(struct gpio_chip *gc, unsigned offset)
 {
 	struct pl061 *pl061 = gpiochip_get_data(gc);
 	unsigned long flags;
-	unsigned char gpiodir;
+	u32 gpiodir;
 
 	raw_spin_lock_irqsave(&pl061->lock, flags);
-	gpiodir = readb(pl061->base + GPIODIR);
+	gpiodir = pl061_read(pl061, pl061->variant->dir);
 	gpiodir &= ~(BIT(offset));
-	writeb(gpiodir, pl061->base + GPIODIR);
+	pl061_write(pl061, gpiodir, pl061->variant->dir);
 	raw_spin_unlock_irqrestore(&pl061->lock, flags);
 
 	return 0;
@@ -86,19 +139,20 @@ static int pl061_direction_output(struct gpio_chip *gc, unsigned offset,
 {
 	struct pl061 *pl061 = gpiochip_get_data(gc);
 	unsigned long flags;
-	unsigned char gpiodir;
+	u32 gpiodir;
 
 	raw_spin_lock_irqsave(&pl061->lock, flags);
-	writeb(!!value << offset, pl061->base + (BIT(offset + 2)));
-	gpiodir = readb(pl061->base + GPIODIR);
+	pl061_set_data(pl061, offset, value);
+	gpiodir = pl061_read(pl061, pl061->variant->dir);
 	gpiodir |= BIT(offset);
-	writeb(gpiodir, pl061->base + GPIODIR);
+	pl061_write(pl061, gpiodir, pl061->variant->dir);
 
 	/*
 	 * gpio value is set again, because pl061 doesn't allow to set value of
 	 * a gpio pin before configuring it in OUT mode.
 	 */
-	writeb(!!value << offset, pl061->base + (BIT(offset + 2)));
+	if (pl061->variant->write_data_after_dir)
+		pl061_set_data(pl061, offset, value);
 	raw_spin_unlock_irqrestore(&pl061->lock, flags);
 
 	return 0;
@@ -107,15 +161,24 @@ static int pl061_direction_output(struct gpio_chip *gc, unsigned offset,
 static int pl061_get_value(struct gpio_chip *gc, unsigned offset)
 {
 	struct pl061 *pl061 = gpiochip_get_data(gc);
+	unsigned long flags;
+	int value;
 
-	return !!readb(pl061->base + (BIT(offset + 2)));
+	raw_spin_lock_irqsave(&pl061->lock, flags);
+	value = pl061_get_data(pl061, offset);
+	raw_spin_unlock_irqrestore(&pl061->lock, flags);
+
+	return value;
 }
 
 static int pl061_set_value(struct gpio_chip *gc, unsigned int offset, int value)
 {
 	struct pl061 *pl061 = gpiochip_get_data(gc);
+	unsigned long flags;
 
-	writeb(!!value << offset, pl061->base + (BIT(offset + 2)));
+	raw_spin_lock_irqsave(&pl061->lock, flags);
+	pl061_set_data(pl061, offset, value);
+	raw_spin_unlock_irqrestore(&pl061->lock, flags);
 
 	return 0;
 }
@@ -126,15 +189,14 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 	struct pl061 *pl061 = gpiochip_get_data(gc);
 	int offset = irqd_to_hwirq(d);
 	unsigned long flags;
-	u8 gpiois, gpioibe, gpioiev;
-	u8 bit = BIT(offset);
+	u32 gpiois, gpioibe, gpioiev;
+	u32 bit = BIT(offset);
 
-	if (offset < 0 || offset >= PL061_GPIO_NR)
+	if (offset < 0 || offset >= gc->ngpio)
 		return -EINVAL;
 
 	if ((trigger & (IRQ_TYPE_LEVEL_HIGH | IRQ_TYPE_LEVEL_LOW)) &&
-	    (trigger & (IRQ_TYPE_EDGE_RISING | IRQ_TYPE_EDGE_FALLING)))
-	{
+	    (trigger & (IRQ_TYPE_EDGE_RISING | IRQ_TYPE_EDGE_FALLING))) {
 		dev_err(gc->parent,
 			"trying to configure line %d for both level and edge "
 			"detection, choose one!\n",
@@ -142,12 +204,11 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 		return -EINVAL;
 	}
 
-
 	raw_spin_lock_irqsave(&pl061->lock, flags);
 
-	gpioiev = readb(pl061->base + GPIOIEV);
-	gpiois = readb(pl061->base + GPIOIS);
-	gpioibe = readb(pl061->base + GPIOIBE);
+	gpioiev = pl061_read(pl061, pl061->variant->iev);
+	gpiois = pl061_read(pl061, pl061->variant->is);
+	gpioibe = pl061_read(pl061, pl061->variant->ibe);
 
 	if (trigger & (IRQ_TYPE_LEVEL_HIGH | IRQ_TYPE_LEVEL_LOW)) {
 		bool polarity = trigger & IRQ_TYPE_LEVEL_HIGH;
@@ -199,9 +260,11 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 			 offset);
 	}
 
-	writeb(gpiois, pl061->base + GPIOIS);
-	writeb(gpioibe, pl061->base + GPIOIBE);
-	writeb(gpioiev, pl061->base + GPIOIEV);
+	pl061_write(pl061, gpiois, pl061->variant->is);
+	pl061_write(pl061, gpioibe, pl061->variant->ibe);
+	pl061_write(pl061, gpioiev, pl061->variant->iev);
+	if (pl061->variant->clear_irq_on_type)
+		pl061_write(pl061, bit, pl061->variant->ic);
 
 	raw_spin_unlock_irqrestore(&pl061->lock, flags);
 
@@ -218,9 +281,9 @@ static void pl061_irq_handler(struct irq_desc *desc)
 
 	chained_irq_enter(irqchip, desc);
 
-	pending = readb(pl061->base + GPIOMIS);
+	pending = pl061_read(pl061, pl061->variant->mis);
 	if (pending) {
-		for_each_set_bit(offset, &pending, PL061_GPIO_NR)
+		for_each_set_bit(offset, &pending, gc->ngpio)
 			generic_handle_domain_irq(gc->irq.domain,
 						  offset);
 	}
@@ -232,12 +295,12 @@ static void pl061_irq_mask(struct irq_data *d)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
 	struct pl061 *pl061 = gpiochip_get_data(gc);
-	u8 mask = BIT(irqd_to_hwirq(d) % PL061_GPIO_NR);
-	u8 gpioie;
+	u32 mask = BIT(irqd_to_hwirq(d));
+	u32 gpioie;
 
 	raw_spin_lock(&pl061->lock);
-	gpioie = readb(pl061->base + GPIOIE) & ~mask;
-	writeb(gpioie, pl061->base + GPIOIE);
+	gpioie = pl061_read(pl061, pl061->variant->ie) & ~mask;
+	pl061_write(pl061, gpioie, pl061->variant->ie);
 	raw_spin_unlock(&pl061->lock);
 
 	gpiochip_disable_irq(gc, d->hwirq);
@@ -247,14 +310,14 @@ static void pl061_irq_unmask(struct irq_data *d)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
 	struct pl061 *pl061 = gpiochip_get_data(gc);
-	u8 mask = BIT(irqd_to_hwirq(d) % PL061_GPIO_NR);
-	u8 gpioie;
+	u32 mask = BIT(irqd_to_hwirq(d));
+	u32 gpioie;
 
 	gpiochip_enable_irq(gc, d->hwirq);
 
 	raw_spin_lock(&pl061->lock);
-	gpioie = readb(pl061->base + GPIOIE) | mask;
-	writeb(gpioie, pl061->base + GPIOIE);
+	gpioie = pl061_read(pl061, pl061->variant->ie) | mask;
+	pl061_write(pl061, gpioie, pl061->variant->ie);
 	raw_spin_unlock(&pl061->lock);
 }
 
@@ -270,10 +333,10 @@ static void pl061_irq_ack(struct irq_data *d)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
 	struct pl061 *pl061 = gpiochip_get_data(gc);
-	u8 mask = BIT(irqd_to_hwirq(d) % PL061_GPIO_NR);
+	u32 mask = BIT(irqd_to_hwirq(d));
 
 	raw_spin_lock(&pl061->lock);
-	writeb(mask, pl061->base + GPIOIC);
+	pl061_write(pl061, mask, pl061->variant->ic);
 	raw_spin_unlock(&pl061->lock);
 }
 
@@ -314,6 +377,10 @@ static int pl061_probe(struct amba_device *adev, const struct amba_id *id)
 	if (pl061 == NULL)
 		return -ENOMEM;
 
+	pl061->variant = id->data;
+	if (!pl061->variant)
+		return dev_err_probe(dev, -EINVAL, "missing variant data\n");
+
 	pl061->base = devm_ioremap_resource(dev, &adev->res);
 	if (IS_ERR(pl061->base))
 		return PTR_ERR(pl061->base);
@@ -327,7 +394,7 @@ static int pl061_probe(struct amba_device *adev, const struct amba_id *id)
 	pl061->gc.direction_output = pl061_direction_output;
 	pl061->gc.get = pl061_get_value;
 	pl061->gc.set = pl061_set_value;
-	pl061->gc.ngpio = PL061_GPIO_NR;
+	pl061->gc.ngpio = pl061->variant->ngpio;
 	pl061->gc.label = dev_name(dev);
 	pl061->gc.parent = dev;
 	pl061->gc.owner = THIS_MODULE;
@@ -335,7 +402,14 @@ static int pl061_probe(struct amba_device *adev, const struct amba_id *id)
 	/*
 	 * irq_chip support
 	 */
-	writeb(0, pl061->base + GPIOIE); /* disable irqs */
+	pl061_write(pl061, 0, pl061->variant->ie); /* disable irqs */
+	if (pl061->variant->enable != PL061_REG_NONE)
+		pl061_write(pl061, GENMASK(pl061->gc.ngpio - 1, 0),
+			    pl061->variant->enable);
+	if (pl061->variant->afsel != PL061_REG_NONE)
+		pl061_write(pl061, 0, pl061->variant->afsel);
+	if (pl061->variant->mask != PL061_REG_NONE)
+		pl061_write(pl061, 0, pl061->variant->mask);
 	irq = adev->irq[0];
 	if (!irq)
 		dev_warn(&adev->dev, "IRQ support disabled\n");
@@ -366,20 +440,37 @@ static int pl061_probe(struct amba_device *adev, const struct amba_id *id)
 static int pl061_suspend(struct device *dev)
 {
 	struct pl061 *pl061 = dev_get_drvdata(dev);
+	unsigned long flags;
 	int offset;
 
+	raw_spin_lock_irqsave(&pl061->lock, flags);
 	pl061->csave_regs.gpio_data = 0;
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
+	pl061->csave_regs.gpio_dir =
+		pl061_read(pl061, pl061->variant->dir);
+	pl061->csave_regs.gpio_is =
+		pl061_read(pl061, pl061->variant->is);
+	pl061->csave_regs.gpio_ibe =
+		pl061_read(pl061, pl061->variant->ibe);
+	pl061->csave_regs.gpio_iev =
+		pl061_read(pl061, pl061->variant->iev);
+	pl061->csave_regs.gpio_ie =
+		pl061_read(pl061, pl061->variant->ie);
+	if (pl061->variant->afsel != PL061_REG_NONE)
+		pl061->csave_regs.gpio_afsel =
+			pl061_read(pl061, pl061->variant->afsel);
+	if (pl061->variant->mask != PL061_REG_NONE)
+		pl061->csave_regs.gpio_mask =
+			pl061_read(pl061, pl061->variant->mask);
+
+	for (offset = 0; offset < pl061->gc.ngpio; offset++) {
+		if ((pl061->csave_regs.gpio_dir & BIT(offset)) &&
+		    pl061_get_data(pl061, offset))
+			pl061->csave_regs.gpio_data |= BIT(offset);
 	}
+	if (pl061->variant->mask != PL061_REG_NONE)
+		pl061_write(pl061, pl061->csave_regs.gpio_mask,
+			    pl061->variant->mask);
+	raw_spin_unlock_irqrestore(&pl061->lock, flags);
 
 	return 0;
 }
@@ -389,7 +480,7 @@ static int pl061_resume(struct device *dev)
 	struct pl061 *pl061 = dev_get_drvdata(dev);
 	int offset;
 
-	for (offset = 0; offset < PL061_GPIO_NR; offset++) {
+	for (offset = 0; offset < pl061->gc.ngpio; offset++) {
 		if (pl061->csave_regs.gpio_dir & (BIT(offset)))
 			pl061_direction_output(&pl061->gc, offset,
 					pl061->csave_regs.gpio_data &
@@ -398,20 +489,75 @@ static int pl061_resume(struct device *dev)
 			pl061_direction_input(&pl061->gc, offset);
 	}
 
-	writeb(pl061->csave_regs.gpio_is, pl061->base + GPIOIS);
-	writeb(pl061->csave_regs.gpio_ibe, pl061->base + GPIOIBE);
-	writeb(pl061->csave_regs.gpio_iev, pl061->base + GPIOIEV);
-	writeb(pl061->csave_regs.gpio_ie, pl061->base + GPIOIE);
+	pl061_write(pl061, pl061->csave_regs.gpio_is,
+		    pl061->variant->is);
+	pl061_write(pl061, pl061->csave_regs.gpio_ibe,
+		    pl061->variant->ibe);
+	pl061_write(pl061, pl061->csave_regs.gpio_iev,
+		    pl061->variant->iev);
+	pl061_write(pl061, pl061->csave_regs.gpio_ie,
+		    pl061->variant->ie);
+	if (pl061->variant->afsel != PL061_REG_NONE)
+		pl061_write(pl061, pl061->csave_regs.gpio_afsel,
+			    pl061->variant->afsel);
+	if (pl061->variant->mask != PL061_REG_NONE)
+		pl061_write(pl061, pl061->csave_regs.gpio_mask,
+			    pl061->variant->mask);
+	if (pl061->variant->enable != PL061_REG_NONE)
+		pl061_write(pl061, GENMASK(pl061->gc.ngpio - 1, 0),
+			    pl061->variant->enable);
 
 	return 0;
 }
 
 static DEFINE_SIMPLE_DEV_PM_OPS(pl061_dev_pm_ops, pl061_suspend, pl061_resume);
 
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
+	.afsel = PL061_REG_NONE,
+	.mask = PL061_REG_NONE,
+	.enable = PL061_REG_NONE,
+	.ngpio = PL061_GPIO_NR,
+	.masked_data_address = true,
+	.write_data_after_dir = true,
+};
+
+static struct pl061_variant_data pl061_ambarella = {
+	.data = 0x00,
+	.dir = 0x04,
+	.is = 0x08,
+	.ibe = 0x0c,
+	.iev = 0x10,
+	.ie = 0x14,
+	.afsel = 0x18,
+	.ris = 0x1c,
+	.mis = 0x20,
+	.ic = 0x24,
+	.mask = 0x28,
+	.enable = 0x2c,
+	.ngpio = 32,
+	.access_32bit = true,
+	.clear_irq_on_type = true,
+};
+
 static const struct amba_id pl061_ids[] = {
 	{
 		.id	= 0x00041061,
 		.mask	= 0x000fffff,
+		.data	= &pl061_arm,
+	},
+	{
+		.id	= PL061_AMBARELLA_PERIPH_ID,
+		.mask	= 0xffffffff,
+		.data	= &pl061_ambarella,
 	},
 	{ 0, 0 },
 };

-- 
2.34.1

