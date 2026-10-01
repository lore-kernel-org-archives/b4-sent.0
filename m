From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 02 Oct 2026 02:13:21 +0800
Subject: [PATCH RFC v2 3/4] gpio: loongson-64bit: Add shared interrupt
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-loongsongpio-v2-3-6e3eb150a4ef@gmail.com>
References: <20261002-loongsongpio-v2-0-6e3eb150a4ef@gmail.com>
In-Reply-To: <20261002-loongsongpio-v2-0-6e3eb150a4ef@gmail.com>
To: Yinbo Zhu <zhuyinbo@loongson.cn>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: Jiaxun Yang <jiaxun.yang@flygoat.com>, linux-gpio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=29273;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=2yp98+GN1A0zejLc7RyYMFKAWyKaUhl/ueqYAvy1qYs=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqvqL0T+h75Wx+DWzkZh8pL/08JHxitDYVezoLd
 i4Vdc9vR+aJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCar6i9AAKCRCwMePKe/7Z
 btw3EAC2Ih3jrLHc0icTML5dmb//Qb2AmtTKyEbF3Qq3gtp71liFoAA77/TFhBMOpncezRcCTDU
 fG7iyI9si5qEcfglsv8dPkNChcnCtTIPx3q/R6KtJW/N7NBhHJjRuLPdJ1fcjePNMj88X4oyVa4
 Zt+C76UeECTkXzPlyVtwny2MYc/eemtmEFgitZbwB6INcKBEAyEM84VgyyPsh+/dnsKVLC5jARO
 wTJMYmlwy9OLQBUeyXVHPdOhSIO1yMqhXEx8jhVl94/7XybmKWx26DRxEn/D5IVZ01jIL5qVQyi
 UsennMnRtsTlwqRIfLozSdxhTaCE8yC4uRUKDJmKkuepP72ttV/orn2pEjHIY+pXB2Y/yczFobY
 Dw5iR/0HYTqKS0Sw7jRuHxJCXTGUVT4C2043w/vWcxpoEOQnd7h9/QbIKYVK70Y7ywyLJGSDZwQ
 EpMnSfh3pXIsogxDSNd6jy0NSL815E6AS7zbY3KZnFm2c6L4frvQKqCwU0Mj4Kgn0ejLuPl5BKs
 VOy3pUmfP7ZVgl2S1A1yssnadLyqAm9NnB5LLwwtm2MHRn8EccQTLR/ter5xTVCCgWAe9WQ5484
 oILRu6TbmkIy57adupjVT+lDKGV/oIhkky/YkCWhgzSCmCxwbcOMEx80BzAWTpbuk5SQguhQc4H
 t44vJ4p9nPkGq6Q==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GPIO controllers found in 2K1000LA, 2K0500, 2K2000 (the first part),
3A5000, 7A1000, 3A6000 lack a dedicated interrupt controller inside it,
instead, they route the input signals via an interrupt enable gate,
controlled by the inten register, to their parent interrupt controller,
letting the latter do the actual interrupt handling. To make things
worse, interrupt signals from multiple GPIO lines are combined into
one interrupt line on the parent interrupt controller, preventing
implementing such controllers as hierarchical interrupt chips. As a
result, the GPIO lines sharing the same parent interrupt line can fall
into the following conditions:

  - Only one of the GPIO lines is in edge-triggered mode, while IRQ on
    other lines cannot be requested.
  - Only one of the GPIO lines is in level-triggered mode, while IRQ on
    other lines cannot be requested, if the register controlling the
    polarity, intpol, is not provided on the GPIO controller, in which
    case, the polarity is controlled by the parent interrupt controller.
  - One or more of the GPIO lines is in level-triggered mode, if intpol
    is provided on the GPIO controller.

Originally gpio_generic_chip.to_irq method was implemented to return the
irq number of the parent interrupt line corresponding to a given GPIO
line and the method unconditionally enable the interrupt on the GPIO
line by writing 1 to the inten register. This approach, however, has
three limitations. Firstly, there is no guarantee that gpio_to_irq will
be called first, so there would be no chance to enable the interrupt on
the GPIO line. Secondly, the sharing of the parent interrupt line among
multiple GPIO lines is not correctly handled, failing to deny requests
for conflicting requests on other GPIO lines. Thirdly, when the irq
requested is released, the interrupt on the GPIO line will never be
disabled. This was discussed in the v5 version of the patch series
introducing this driver [1].

To solve this, this patch implements a cascaded interrupt controller,
which manages the sharing of the parent interrupt line among multiple
GPIO lines, denying conflicting requests and properly enabling or
disabling the interrupt on the GPIO line as needed. To implement this,
mask/unmask/set_type/shutdown handlers should call the handlers of the
parent interrupt controller to manage and change the state of the
interrupts on the parent interrupt line as well.

What remain undecided is the firmware interface that declares platform
irq numbers for the GPIO controller. If the GPIO controller has N gpio
lines and M parent interrupt lines, it is to be decided how to list the
platform irq numbers. The first approach could be to list M unique
irq numbers corresponding to the M parent interrupt lines, while the
second approach could be to list N irq numbers corresponding to the N
gpio lines, which might have duplicate entries. Previously the second
approach was chosen and it was found that listing duplicate interrupt
numbers is not restricted by ACPI and platform devices. However,
actual ACPI tables found in the published firmware chose the first
approach. I choose to use the first approach as well temporarily in this
patch, since it would be easier to implement. Thankfully when the driver
is implemented in the first approach, it can accept the data from the
second approach as well, due to the mapping used, except for 2K0500 and
2K1000. I have no sample firmwares for these two platforms and cannot
verify which approach is used.

[1]: https://lore.kernel.org/all/CACRpkdbgP9m40t_Ky4H+SQi9TELikomT2M-JpF7+auKmzOxQdg@mail.gmail.com/
[2]: https://lore.kernel.org/all/allOoYUZXocOfk8F@ashevche-desk.local/

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/gpio/gpio-loongson-64bit.c | 648 +++++++++++++++++++++++++++++++++++++
 1 file changed, 648 insertions(+)

diff --git a/drivers/gpio/gpio-loongson-64bit.c b/drivers/gpio/gpio-loongson-64bit.c
index a1b23ba21f64162af2096131520d1dac27798983..40ff845e21db18fa513d2d3b328bcb7ad16baf6a 100644
--- a/drivers/gpio/gpio-loongson-64bit.c
+++ b/drivers/gpio/gpio-loongson-64bit.c
@@ -7,6 +7,7 @@
 
 #include <linux/kernel.h>
 #include <linux/init.h>
+#include <linux/cleanup.h>
 #include <linux/irq.h>
 #include <linux/irqdesc.h>
 #include <linux/module.h>
@@ -17,6 +18,7 @@
 #include <linux/platform_device.h>
 #include <linux/bitops.h>
 #include <linux/reset.h>
+#include <linux/interrupt.h>
 #include <asm/types.h>
 
 enum loongson_gpio_mode {
@@ -24,6 +26,8 @@ enum loongson_gpio_mode {
 	BYTE_CTRL_MODE,
 };
 
+struct loongson_gpio_chip;
+
 struct loongson_gpio_chip_data {
 	const char		*label;
 	enum loongson_gpio_mode	mode;
@@ -39,14 +43,19 @@ struct loongson_gpio_chip_data {
 	unsigned int		intr_num;
 	irq_flow_handler_t	irq_handler;
 	const struct irq_chip	*girqchip;
+	unsigned int		(*irq_mapping)(struct loongson_gpio_chip *lgpio,
+					       unsigned int pin);
 	int			(*irq_init)(struct platform_device *pdev,
 					    struct loongson_gpio_chip *lgpio);
 };
 
+struct loongson_gpio_sirq_data;
+
 struct loongson_gpio_chip {
 	struct gpio_generic_chip chip;
 	spinlock_t		lock;
 	void __iomem		*reg_base;
+	struct loongson_gpio_sirq_data *sirq_data;
 	const struct loongson_gpio_chip_data *chip_data;
 };
 
@@ -291,6 +300,607 @@ static int loongson_gpio_init_irqchip(struct platform_device *pdev,
 	return 0;
 }
 
+/*
+ * About shared IRQs for GPIO pins:
+ *
+ * This kind of GPIO controller lacks interrupt status register to identify
+ * edge-triggered interrupts, and the handling of such interrupts must be
+ * deligated to the parent IRQ controller.
+ * This kind of GPIO controller should typically have a inten register to enable
+ * or disable interrupts for individual GPIO pins, intpol register to configure
+ * the interrupt polarity. The signal sent to the parent interrupt controller
+ * is calculated by bit-wise comparing the GPIO line and the intpol register and
+ * then masking with inten.
+ * However, The interrput input lines of the parent IRQ controller is not enough
+ * to 1:1 map to the GPIO pins, necessitating the use of shared IRQs. A mapping
+ * is statically establised to map multiple GPIO pins to a single parent IRQ
+ * line. The level of the parent IRQ is determined by or-ing the levels of all
+ * GPIO pins mapped to it. Suppose gpio pin 0 and gpio pin 8 are mapped to the
+ * same parent IRQ, the level of the parent IRQ is determined by the following
+ * expression:
+ *     (~(gpio[0] ^ intpol[0]) & inten[0]) |
+ *     (~(gpio[8] ^ intpol[8]) & inten[8])
+ * When the intpol register is not available, its value is assumed to be 1, and
+ * the expression becomes:
+ *     (gpio[0] & inten[0]) | (gpio[8] & inten[8])
+ *
+ * According to the hardware design, IRQ can be requested on only one of the
+ * GPIO pins sharing the same parent IRQ, unless the intpol register is
+ * available and all the IRQs are level-triggered.
+ *
+ * Convention on the usage of shared IRQs for GPIO pins:
+ * - When a parent IRQ is exclusively used, the parent IRQ should be masked or
+ *   unmasked accordingly when the irq pin using it is masked or unmasked.
+ * - When a parent IRQ is shared among multiple GPIO pins, the parent IRQ
+ *   should always be unmasked and masking or unmasking individual GPIO pins
+ *   should be done through the GPIO controller's inten register.
+ */
+
+/*
+ * We assume a maximum of 128 GPIOs for the bitmap, which should be
+ * sufficient for all the actual hardware controllers defined in this
+ * driver.
+ */
+enum { MAX_GPIO_WITH_IRQ = 128 };
+
+struct loongson_gpio_sirq_parent_data {
+	unsigned int parent_index;
+	unsigned int parent_irq;
+	/*
+	 * The lock of the irq_desc of the parent irq also protects
+	 * exclusive/usedby below. It must be taken before
+	 * lgpio->sirq_data->lock.
+	 */
+	struct irq_data *parent_irq_data;
+	struct loongson_gpio_chip *lgpio;
+
+	/*
+	 * exclusive: exclusive usage, only one gpio pin can use this parent irq.
+	 *   It will happen in two cases:
+	 *     - The parent irq is used by a gpio pin which is edge triggered, and
+	 *       thus cannot be used by other gpio pins which are mapped to the same
+	 *       parent irq.
+	 *     - The parent irq is used by a gpio pin which is level triggered, and
+	 *       the gpio chip lacks the polarity control register, and thus the
+	 *       interrupt polarity is controlled by the parent irq controller, and
+	 *       thus cannot be used by other gpio pins which are mapped to the
+	 *       same parent irq.
+	 *   When set, the request for other gpio pins which are mapped to this
+	 *   parent irq will be rejected.
+	 */
+	bool exclusive : 1;
+	/*
+	 * usedby: When exclusive is set, indicates the only gpio pin which
+	 *   is using this parent irq. When exclusive is cleared, indicates the
+	 *   number of gpio pins which are using this parent irq.
+	 * When both exclusive and usedby are 0, it means that the parent irq is not
+	 * used by any gpio pin.
+	 */
+	unsigned int usedby : 31;
+};
+
+struct loongson_gpio_sirq_data {
+	/*
+	 * Protects the read/write operations on the irq related registers
+	 */
+	raw_spinlock_t lock;
+	int *irq_in_use;
+	struct loongson_gpio_sirq_parent_data parent_data[];
+};
+
+static void loongson_gpio_write_register(struct loongson_gpio_chip *lgpio,
+					 unsigned int reg_offset,
+					 unsigned int line, u8 value)
+{
+	void __iomem *reg = lgpio->reg_base + reg_offset;
+
+	if (lgpio->chip_data->mode == BIT_CTRL_MODE) {
+		u32 bval;
+
+		reg += (line / 32) * 4;
+		bval = readl(reg);
+
+		if (value)
+			bval |= BIT(line % 32);
+		else
+			bval &= ~BIT(line % 32);
+
+		writel(bval, reg);
+	} else {
+		writeb(value, reg + line);
+	}
+}
+
+static u8 loongson_gpio_read_register(struct loongson_gpio_chip *lgpio,
+				      unsigned int reg_offset,
+				      unsigned int line)
+{
+	void __iomem *reg = lgpio->reg_base + reg_offset;
+
+	if (lgpio->chip_data->mode == BIT_CTRL_MODE) {
+		u32 bval;
+
+		reg += (line / 32) * 4;
+		bval = readl(reg);
+
+		return (bval >> (line % 32)) & 1;
+	}
+
+	return readb(reg + line) & 1;
+}
+
+static void loongson_gpio_shared_mask_locked(struct loongson_gpio_chip *lgpio,
+					     irq_hw_number_t hwirq,
+					     struct loongson_gpio_sirq_parent_data *pirqd)
+{
+	struct irq_data *parent_irq_data = pirqd->parent_irq_data;
+
+	if (pirqd->exclusive)
+		parent_irq_data->chip->irq_mask(parent_irq_data);
+
+	scoped_guard(raw_spinlock_irqsave, &lgpio->sirq_data->lock)
+		loongson_gpio_write_register(lgpio, lgpio->chip_data->inten_offset,
+					     hwirq, 0);
+}
+
+static void loongson_gpio_shared_irq_mask(struct irq_data *data)
+{
+	struct gpio_chip *chip = irq_data_get_irq_chip_data(data);
+	struct loongson_gpio_chip *lgpio = to_loongson_gpio_chip(chip);
+	irq_hw_number_t hwirq = irqd_to_hwirq(data);
+	unsigned int pirq_idx = lgpio->chip_data->irq_mapping(lgpio, hwirq);
+	struct loongson_gpio_sirq_parent_data *pirqd =
+		&lgpio->sirq_data->parent_data[pirq_idx];
+
+	/*
+	 * If irq_in_use is not set, then set_type handler must has not been called
+	 * and no trigger type has been set for this gpio pin, so we should not
+	 * proceed and do nothing.
+	 */
+	if (!lgpio->sirq_data->irq_in_use[hwirq])
+		return;
+
+	guard(raw_spinlock_irqsave)(&irq_data_to_desc(pirqd->parent_irq_data)->lock);
+
+	loongson_gpio_shared_mask_locked(lgpio, hwirq, pirqd);
+}
+
+static void loongson_gpio_shared_irq_unmask(struct irq_data *data)
+{
+	struct gpio_chip *chip = irq_data_get_irq_chip_data(data);
+	struct loongson_gpio_chip *lgpio = to_loongson_gpio_chip(chip);
+	irq_hw_number_t hwirq = irqd_to_hwirq(data);
+	unsigned int pirq_idx = lgpio->chip_data->irq_mapping(lgpio, hwirq);
+	struct loongson_gpio_sirq_parent_data *pirqd =
+		&lgpio->sirq_data->parent_data[pirq_idx];
+	struct irq_data *parent_irq_data = pirqd->parent_irq_data;
+
+	if (!lgpio->sirq_data->irq_in_use[hwirq])
+		return;
+
+	guard(raw_spinlock_irqsave)(&irq_data_to_desc(pirqd->parent_irq_data)->lock);
+
+	if (pirqd->exclusive)
+		parent_irq_data->chip->irq_mask(parent_irq_data);
+
+	scoped_guard(raw_spinlock_irqsave, &lgpio->sirq_data->lock)
+		loongson_gpio_write_register(lgpio, lgpio->chip_data->inten_offset,
+					     hwirq, 1);
+
+	if (pirqd->exclusive)
+		parent_irq_data->chip->irq_unmask(parent_irq_data);
+}
+
+static void loongson_gpio_shared_irq_handler(struct irq_desc *desc);
+
+static int loongson_gpio_shared_irq_set_type(struct irq_data *data, unsigned int type)
+{
+	struct gpio_chip *chip = irq_data_get_irq_chip_data(data);
+	struct loongson_gpio_chip *lgpio = to_loongson_gpio_chip(chip);
+	irq_hw_number_t hwirq = irqd_to_hwirq(data);
+	unsigned int pirq_idx = lgpio->chip_data->irq_mapping(lgpio, hwirq);
+	struct loongson_gpio_sirq_parent_data *pirqd =
+		&lgpio->sirq_data->parent_data[pirq_idx];
+	unsigned int intpol_offset = lgpio->chip_data->intpol_offset;
+	struct irq_data *parent_irq_data = pirqd->parent_irq_data;
+	struct irq_chip *parent_irq_chip = parent_irq_data->chip;
+	int ret = 0;
+
+	type &= IRQ_TYPE_SENSE_MASK;
+
+	if (type != IRQ_TYPE_EDGE_FALLING && type != IRQ_TYPE_EDGE_RISING &&
+	    type != IRQ_TYPE_LEVEL_LOW && type != IRQ_TYPE_LEVEL_HIGH)
+		return -EINVAL;
+
+	guard(raw_spinlock_irqsave)(&irq_data_to_desc(pirqd->parent_irq_data)->lock);
+
+	if (pirqd->exclusive && hwirq != pirqd->usedby)
+		return -EBUSY;
+
+	/*
+	 * When the irq is not exclusively used and is currently shared by
+	 * more than one gpio pin; or is currently used by single gpio pin and
+	 * the gpio pin is not the one requesting to set the irq type, then the
+	 * irq type can only be set to level triggered.
+	 */
+	if (!pirqd->exclusive &&
+	    (pirqd->usedby > 1 ||
+	     (pirqd->usedby == 1 && !lgpio->sirq_data->irq_in_use[hwirq]))) {
+		if (type != IRQ_TYPE_LEVEL_HIGH && type != IRQ_TYPE_LEVEL_LOW)
+			return -EBUSY;
+
+		/*
+		 * When exclusive is not set and usedby at least one, the gpio chip must
+		 * have intpol register to control the interrupt polarity. We will never
+		 * reach here if the gpio chip lacks intpol register, because in that
+		 * case, exclusive will be set no matter what trigger type is requested.
+		 */
+		BUG_ON(!intpol_offset);
+		/*
+		 * Since only level triggered irqs are allowed to be shared, we can
+		 * safely set the intpol register without first disabling the pin in
+		 * inten register.
+		 */
+		scoped_guard(raw_spinlock_irqsave, &lgpio->sirq_data->lock)
+			loongson_gpio_write_register(lgpio, intpol_offset, hwirq,
+						     type == IRQ_TYPE_LEVEL_HIGH);
+
+		if (!lgpio->sirq_data->irq_in_use[hwirq])
+			pirqd->usedby++;
+
+		irq_set_handler_locked(data, handle_level_irq);
+	} else {
+		parent_irq_chip->irq_mask(parent_irq_data);
+
+		if (type == IRQ_TYPE_EDGE_FALLING || type == IRQ_TYPE_EDGE_RISING) {
+			if (intpol_offset) {
+				ret = parent_irq_chip->irq_set_type(parent_irq_data,
+								    IRQ_TYPE_EDGE_RISING);
+				if (ret < 0)
+					goto out_restore_handler;
+
+				scoped_guard(raw_spinlock_irqsave, &lgpio->sirq_data->lock)
+					loongson_gpio_write_register(lgpio, intpol_offset,
+								     hwirq,
+								     type == IRQ_TYPE_EDGE_RISING);
+			} else {
+				ret = parent_irq_chip->irq_set_type(parent_irq_data, type);
+				if (ret < 0)
+					goto out_restore_handler;
+			}
+
+			pirqd->exclusive = true;
+			pirqd->usedby = hwirq;
+
+			/*
+			 * We deliberately set the handler to level_irq even for
+			 * edge-triggered interrupts because we cannot provide .irq_ack()
+			 * handler.
+			 */
+			irq_set_handler_locked(data, handle_level_irq);
+		} else {
+			if (intpol_offset) {
+				ret = parent_irq_chip->irq_set_type(parent_irq_data,
+								    IRQ_TYPE_LEVEL_HIGH);
+				if (ret < 0)
+					goto out_restore_handler;
+
+				scoped_guard(raw_spinlock_irqsave, &lgpio->sirq_data->lock)
+					loongson_gpio_write_register(lgpio, intpol_offset,
+								     hwirq,
+								     type == IRQ_TYPE_LEVEL_HIGH);
+				pirqd->exclusive = false;
+				pirqd->usedby = 1;
+			} else {
+				ret = parent_irq_chip->irq_set_type(parent_irq_data, type);
+				if (ret < 0)
+					goto out_restore_handler;
+
+				pirqd->exclusive = true;
+				pirqd->usedby = hwirq;
+			}
+
+			irq_set_handler_locked(data, handle_level_irq);
+		}
+out_restore_handler:
+		/* ->irq_set_type() would override irq_handler, so restore here */
+		irq_set_handler_locked(parent_irq_data, loongson_gpio_shared_irq_handler);
+		if (ret < 0)
+			goto out;
+	}
+
+	lgpio->sirq_data->irq_in_use[hwirq] = 1;
+
+out:
+	if (pirqd->exclusive) {
+		u8 inten;
+
+		scoped_guard(raw_spinlock_irqsave, &lgpio->sirq_data->lock)
+			inten = loongson_gpio_read_register(lgpio, lgpio->chip_data->inten_offset,
+							    hwirq);
+		if (inten)
+			parent_irq_chip->irq_unmask(parent_irq_data);
+	} else
+		parent_irq_chip->irq_unmask(parent_irq_data);
+
+	return ret;
+}
+
+static void loongson_gpio_shared_irq_shutdown(struct irq_data *data)
+{
+	struct gpio_chip *chip = irq_data_get_irq_chip_data(data);
+	struct loongson_gpio_chip *lgpio = to_loongson_gpio_chip(chip);
+	irq_hw_number_t hwirq = irqd_to_hwirq(data);
+	unsigned int parent_irq_index = lgpio->chip_data->irq_mapping(lgpio, hwirq);
+	struct loongson_gpio_sirq_parent_data *pirqd =
+		&lgpio->sirq_data->parent_data[parent_irq_index];
+
+	if (!lgpio->sirq_data->irq_in_use[hwirq])
+		return;
+
+	guard(raw_spinlock_irqsave)(&irq_data_to_desc(pirqd->parent_irq_data)->lock);
+
+	loongson_gpio_shared_mask_locked(lgpio, hwirq, pirqd);
+
+	if (!pirqd->exclusive) {
+		if (lgpio->sirq_data->irq_in_use[hwirq]) {
+			if (!WARN_ON(pirqd->usedby == 0))
+				pirqd->usedby--;
+		}
+	} else {
+		if (pirqd->usedby == hwirq) {
+			pirqd->usedby = 0;
+			pirqd->exclusive = false;
+		}
+	}
+
+	lgpio->sirq_data->irq_in_use[hwirq] = 0;
+}
+
+static void loongson_gpio_shared_irq_init_valid_mask(struct gpio_chip *gc,
+						     unsigned long *valid_mask,
+						     unsigned int ngpios)
+{
+	struct loongson_gpio_chip *lgpio = to_loongson_gpio_chip(gc);
+	struct loongson_gpio_sirq_data *shared_irq_data = lgpio->sirq_data;
+	const struct loongson_gpio_chip_data *data = lgpio->chip_data;
+	unsigned int i;
+
+	for (i = 0; i < ngpios; i++) {
+		unsigned int parent_irq_index = data->irq_mapping(lgpio, i);
+
+		/*
+		 * A parent_irq of 0 means the corresponding interrupt line is
+		 * absent from the device tree or ACPI namespace.
+		 */
+		if (i >= MAX_GPIO_WITH_IRQ ||
+		    parent_irq_index >= data->intr_num ||
+		    !shared_irq_data->parent_data[parent_irq_index].parent_irq)
+			clear_bit(i, valid_mask);
+	}
+}
+
+static int loongson_gpio_shared_irq_init_hw(struct gpio_chip *gc)
+{
+	struct loongson_gpio_chip *lgpio = to_loongson_gpio_chip(gc);
+	const struct loongson_gpio_chip_data *data = lgpio->chip_data;
+	struct loongson_gpio_sirq_data *sirq_data = lgpio->sirq_data;
+	int i;
+
+	sirq_data->irq_in_use = devm_kcalloc(gc->parent, gc->ngpio,
+					     sizeof(*sirq_data->irq_in_use),
+					     GFP_KERNEL);
+
+	if (!sirq_data->irq_in_use)
+		return -ENOMEM;
+
+	for (i = 0; i < gc->ngpio; i++)
+		loongson_gpio_write_register(lgpio, data->inten_offset, i, 0);
+
+	return 0;
+}
+
+static int loongson_gpio_init_shared_irqchip(struct platform_device *pdev,
+					     struct loongson_gpio_chip *lgpio)
+{
+	const struct loongson_gpio_chip_data *data = lgpio->chip_data;
+	struct gpio_chip *chip = &lgpio->chip.gc;
+	struct loongson_gpio_sirq_data *sirq_data;
+	int i;
+	int available_parent_irqs;
+
+	chip->irq.default_type = IRQ_TYPE_NONE;
+	chip->irq.handler = handle_bad_irq;
+	chip->irq.parent_handler = data->irq_handler;
+	chip->irq.init_valid_mask = loongson_gpio_shared_irq_init_valid_mask;
+	chip->irq.init_hw = loongson_gpio_shared_irq_init_hw;
+
+	sirq_data = devm_kzalloc(&pdev->dev,
+				 struct_size(sirq_data, parent_data, data->intr_num),
+				 GFP_KERNEL);
+	if (!sirq_data)
+		return -ENOMEM;
+
+	lgpio->sirq_data = sirq_data;
+	raw_spin_lock_init(&sirq_data->lock);
+	for (i = 0; i < data->intr_num; i++) {
+		sirq_data->parent_data[i].parent_index = i;
+		sirq_data->parent_data[i].lgpio = lgpio;
+	}
+
+	gpio_irq_chip_set_chip(&chip->irq, data->girqchip);
+
+	chip->irq.parents = devm_kcalloc(&pdev->dev, data->intr_num,
+					 sizeof(*chip->irq.parents), GFP_KERNEL);
+	if (!chip->irq.parents)
+		return -ENOMEM;
+
+	chip->irq.per_parent_data = true;
+	chip->irq.parent_handler_data_array =
+		devm_kcalloc(&pdev->dev, data->intr_num,
+			     sizeof(*chip->irq.parent_handler_data_array),
+			     GFP_KERNEL);
+	if (!chip->irq.parent_handler_data_array)
+		return -ENOMEM;
+
+	for (i = 0, available_parent_irqs = 0; i < data->intr_num; i++) {
+		int ret;
+		struct irq_data *parent_irq_data;
+		int dup = 0, j;
+
+		ret = platform_get_irq_optional(pdev, i);
+
+		if (ret == -ENXIO)
+			continue;
+
+		if (ret < 0)
+			return dev_err_probe(&pdev->dev, ret,
+					     "failed to get IRQ %d\n", i);
+
+		for (j = 0; j < available_parent_irqs; j++)
+			if (chip->irq.parents[j] == ret) {
+				dup = 1;
+				break;
+			}
+		if (dup) {
+			dev_warn(&pdev->dev,
+				 FW_BUG "IRQ for parent index %d is duplicated, skipping\n", i);
+			continue;
+		}
+
+		parent_irq_data = irq_get_irq_data(ret);
+		if (WARN_ON(!parent_irq_data))
+			continue;
+		/* Implementing ->irq_set_type() is required for a parent irqchip */
+		if (parent_irq_data->chip->irq_set_type == NULL)
+			continue;
+
+		chip->irq.parents[available_parent_irqs] = ret;
+		chip->irq.parent_handler_data_array[available_parent_irqs] =
+			&sirq_data->parent_data[i];
+
+		sirq_data->parent_data[i].parent_irq = ret;
+		sirq_data->parent_data[i].parent_irq_data = irq_get_irq_data(ret);
+
+		available_parent_irqs++;
+	}
+	chip->irq.num_parents = available_parent_irqs;
+
+	return 0;
+}
+
+/*
+ * Determine the GPIO pins which are triggering the parent irq given by
+ * pirqd, by comparing each mapped pin's line level against its polarity.
+ */
+static void loongson_gpio_shared_irq_poll(struct loongson_gpio_chip *lgpio,
+					  unsigned int parent_index,
+					  unsigned long *irq_pending_map,
+					  unsigned int ngpio)
+{
+	const struct loongson_gpio_chip_data *data = lgpio->chip_data;
+	unsigned int i;
+
+	for (i = 0; i < ngpio; i++) {
+		u8 inten, intpol, level;
+
+		if (data->irq_mapping(lgpio, i) != parent_index)
+			continue;
+
+		scoped_guard(raw_spinlock_irqsave, &lgpio->sirq_data->lock) {
+			inten = !!loongson_gpio_read_register(lgpio, data->inten_offset, i);
+			intpol = !!loongson_gpio_read_register(lgpio, data->intpol_offset, i);
+			level = !!loongson_gpio_read_register(lgpio, data->in_offset, i);
+		}
+
+		if (inten && intpol == level)
+			bitmap_set(irq_pending_map, i, 1);
+	}
+}
+
+static void loongson_gpio_shared_irq_handler(struct irq_desc *desc)
+{
+	struct loongson_gpio_sirq_parent_data *pirqd = irq_desc_get_handler_data(desc);
+	struct loongson_gpio_chip *lgpio = pirqd->lgpio;
+	struct gpio_chip *chip = &lgpio->chip.gc;
+	struct irq_chip *girqchip = irq_desc_get_chip(desc);
+	unsigned int ngpio = chip->ngpio > MAX_GPIO_WITH_IRQ ? MAX_GPIO_WITH_IRQ : chip->ngpio;
+	unsigned int usedby, i;
+	bool exclusive;
+	DECLARE_BITMAP(irq_pending_map, MAX_GPIO_WITH_IRQ);
+
+	bitmap_clear(irq_pending_map, 0, ngpio);
+
+	chained_irq_enter(girqchip, desc);
+
+	/*
+	 * Release the lock after copying the exclusive and usedby fields.
+	 * This ensures lock ordering and prevents deadlocks.
+	 */
+	scoped_guard(raw_spinlock_irqsave, &desc->lock) {
+		exclusive = pirqd->exclusive;
+		usedby = pirqd->usedby;
+	}
+	if (exclusive && usedby < ngpio)
+		bitmap_set(irq_pending_map, usedby, 1);
+	else if (usedby) {
+		/*
+		 * When a parent irq is shared by more than 1 gpio pin,
+		 * these IRQs must be level-triggered, and the polarity
+		 * register must be available in the GPIO controller to
+		 * determine the triggering GPIO line.
+		 */
+		loongson_gpio_shared_irq_poll(lgpio, pirqd->parent_index, irq_pending_map, ngpio);
+	}
+
+	if (!bitmap_empty(irq_pending_map, ngpio)) {
+		for (i = 0; i < ngpio; i++) {
+			if (test_bit(i, irq_pending_map))
+				generic_handle_domain_irq(chip->irq.domain, i);
+		}
+	}
+
+	chained_irq_exit(girqchip, desc);
+}
+
+static const struct irq_chip loongson_gpio_shared_irqchip = {
+	.irq_mask	= loongson_gpio_shared_irq_mask,
+	.irq_unmask	= loongson_gpio_shared_irq_unmask,
+	.irq_set_type	= loongson_gpio_shared_irq_set_type,
+	.irq_shutdown	= loongson_gpio_shared_irq_shutdown,
+	.flags		= IRQCHIP_IMMUTABLE | IRQCHIP_SKIP_SET_WAKE,
+	GPIOCHIP_IRQ_RESOURCE_HELPERS,
+};
+
+static unsigned int loongson_gpio_irq_mapping_mod8(struct loongson_gpio_chip *lgpio,
+						   unsigned int pin)
+{
+	return pin % 8;
+}
+
+static unsigned int loongson_gpio_irq_mapping_cap4(struct loongson_gpio_chip *lgpio,
+						   unsigned int pin)
+{
+	return pin >= 4 ? 4 : pin;
+}
+
+static unsigned int loongson_gpio_irq_mapping_cap4_2(struct loongson_gpio_chip *lgpio,
+						     unsigned int pin)
+{
+	if (pin < 4)
+		return pin;
+	else if (pin < 32)
+		return 4;
+	else
+		return 5;
+}
+
+static unsigned int loongson_gpio_irq_mapping_div32(struct loongson_gpio_chip *lgpio,
+						    unsigned int pin)
+{
+	return pin / 32;
+}
+
 static int loongson_gpio_init(struct platform_device *pdev, struct loongson_gpio_chip *lgpio,
 			      void __iomem *reg_base)
 {
@@ -371,6 +981,11 @@ static const struct loongson_gpio_chip_data loongson_gpio_ls2k_data = {
 	.in_offset = 0x20,
 	.out_offset = 0x10,
 	.inten_offset = 0x30,
+	.intr_num = 6,
+	.irq_init = loongson_gpio_init_shared_irqchip,
+	.irq_handler = loongson_gpio_shared_irq_handler,
+	.girqchip = &loongson_gpio_shared_irqchip,
+	.irq_mapping = loongson_gpio_irq_mapping_cap4_2,
 };
 
 static const struct loongson_gpio_chip_data loongson_gpio_ls2k0300_data = {
@@ -398,6 +1013,11 @@ static const struct loongson_gpio_chip_data loongson_gpio_ls2k0500_data0 = {
 	.in_offset = 0x8,
 	.out_offset = 0x10,
 	.inten_offset = 0xb0,
+	.intr_num = 2,
+	.irq_init = loongson_gpio_init_shared_irqchip,
+	.irq_handler = loongson_gpio_shared_irq_handler,
+	.girqchip = &loongson_gpio_shared_irqchip,
+	.irq_mapping = loongson_gpio_irq_mapping_div32,
 };
 
 static const struct loongson_gpio_chip_data loongson_gpio_ls2k0500_data1 = {
@@ -407,6 +1027,11 @@ static const struct loongson_gpio_chip_data loongson_gpio_ls2k0500_data1 = {
 	.in_offset = 0x8,
 	.out_offset = 0x10,
 	.inten_offset = 0x98,
+	.intr_num = 2,
+	.irq_init = loongson_gpio_init_shared_irqchip,
+	.irq_handler = loongson_gpio_shared_irq_handler,
+	.girqchip = &loongson_gpio_shared_irqchip,
+	.irq_mapping = loongson_gpio_irq_mapping_div32,
 };
 
 static const struct loongson_gpio_chip_data loongson_gpio_ls2k2000_data0 = {
@@ -416,6 +1041,12 @@ static const struct loongson_gpio_chip_data loongson_gpio_ls2k2000_data0 = {
 	.in_offset = 0xc,
 	.out_offset = 0x8,
 	.inten_offset = 0x14,
+	.intpol_offset = 0x10,
+	.intr_num = 8,
+	.irq_init = loongson_gpio_init_shared_irqchip,
+	.irq_handler = loongson_gpio_shared_irq_handler,
+	.girqchip = &loongson_gpio_shared_irqchip,
+	.irq_mapping = loongson_gpio_irq_mapping_mod8,
 };
 
 static const struct loongson_gpio_chip_data loongson_gpio_ls2k2000_data1 = {
@@ -450,6 +1081,12 @@ static const struct loongson_gpio_chip_data loongson_gpio_ls3a5000_data = {
 	.in_offset = 0xc,
 	.out_offset = 0x8,
 	.inten_offset = 0x14,
+	.intpol_offset = 0x10,
+	.intr_num = 8,
+	.irq_init = loongson_gpio_init_shared_irqchip,
+	.irq_handler = loongson_gpio_shared_irq_handler,
+	.girqchip = &loongson_gpio_shared_irqchip,
+	.irq_mapping = loongson_gpio_irq_mapping_mod8,
 };
 
 static const struct loongson_gpio_chip_data loongson_gpio_ls7a_data = {
@@ -459,6 +1096,11 @@ static const struct loongson_gpio_chip_data loongson_gpio_ls7a_data = {
 	.in_offset = 0xa00,
 	.out_offset = 0x900,
 	.inten_offset = 0xb00,
+	.intr_num = 5,
+	.irq_init = loongson_gpio_init_shared_irqchip,
+	.irq_handler = loongson_gpio_shared_irq_handler,
+	.girqchip = &loongson_gpio_shared_irqchip,
+	.irq_mapping = loongson_gpio_irq_mapping_cap4,
 };
 
 /* LS7A2000 chipset GPIO */
@@ -496,6 +1138,12 @@ static const struct loongson_gpio_chip_data loongson_gpio_ls3a6000_data = {
 	.in_offset = 0xc,
 	.out_offset = 0x8,
 	.inten_offset = 0x14,
+	.intpol_offset = 0x10,
+	.intr_num = 8,
+	.irq_init = loongson_gpio_init_shared_irqchip,
+	.irq_handler = loongson_gpio_shared_irq_handler,
+	.girqchip = &loongson_gpio_shared_irqchip,
+	.irq_mapping = loongson_gpio_irq_mapping_mod8,
 };
 
 static const struct of_device_id loongson_gpio_of_match[] = {

-- 
2.55.0

