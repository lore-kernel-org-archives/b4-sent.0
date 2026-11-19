From: Igor Velkov <iav@iav.lv>
Date: Fri, 20 Nov 2026 01:14:30 +0200
Subject: [PATCH] irqchip/meson-gpio: Restore the channel setup after
 hibernation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-meson-gpio-hibernate-v1-1-462fdd55810a@iav.lv>
X-B4-Tracking: v=1; b=H4sIANaC/2oC/x2MQQqAIBAAvxJ7bkGFhPpKdChbbQ+paEQg/b2l4
 zDMNKhUmCpMXYNCN1dOUUD3HbhjjYGQd2EwylitjcKTaooYMic8eKMS14twEKdHv1vvLEiaC3l
 +/u28vO8HycQ6aGYAAAA=
To: Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4669; i=iav@iav.lv;
 h=from:subject:message-id; bh=8E657J8E9V1B6VWAcIoFiF9rMDrYJrYzKUQ3uwXqqLM=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFn/m64f63MT/NzBfF2X+ZPwo+Qez9ff7eay8zz+kydnm
 GI1RXJqRykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZiI2yNGhuZkx9wrdnwaKcGS
 pY/F6rbxG+3UO+IQJJuibnAnfVJMAsP/guTL9xgy1gTd+r+b54zcKbYJh8PvWNnf0N31hD3Ch8m
 VEQA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GPIO interrupt mux takes the first free channel when an interrupt is
mapped, so the channel a pad gets depends on probe order. A hibernation
image is restored by a freshly booted kernel that maps the interrupts in
its own order, and the controller may lose power while the image is on
disk. The restored kernel keeps its channel table, but the hardware
routes the pads as the boot kernel set them up.

On ODROID-HC4, after a power cut during hibernation, PIN_03_SEL changed
from 0x54521a3b to 0x001a523b: the PHY and RTC channels swapped, the
PHY interrupt ran the pcf8563 handler and the link was never reported.
This happened on 7 of 11 restores.

Save the register block in syscore suspend and write it back in syscore
resume. create_image() calls them around the snapshot, so the image's
own setup comes back.

Tested on ODROID-HC4: 10 restores after a power cut, the registers and
the network came back every time.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ODROID-HC4 with v7.3.5 and v7.4-rc3 based kernels: hybrid sleep, power removed while asleep, image restored on the next boot.
---
 drivers/irqchip/irq-meson-gpio.c | 53 +++++++++++++++++++++++++++++++++++++++-
 1 file changed, 52 insertions(+), 1 deletion(-)

diff --git a/drivers/irqchip/irq-meson-gpio.c b/drivers/irqchip/irq-meson-gpio.c
index e0329ef5e4a2..009576633ff7 100644
--- a/drivers/irqchip/irq-meson-gpio.c
+++ b/drivers/irqchip/irq-meson-gpio.c
@@ -15,6 +15,7 @@
 #include <linux/irqchip.h>
 #include <linux/of.h>
 #include <linux/of_address.h>
+#include <linux/syscore_ops.h>
 
 #define MAX_NUM_CHANNEL 64
 #define MAX_INPUT_MUX 256
@@ -245,6 +246,9 @@ struct meson_gpio_irq_controller {
 	u32 channel_irqs[MAX_NUM_CHANNEL];
 	DECLARE_BITMAP(channel_map, MAX_NUM_CHANNEL);
 	raw_spinlock_t lock;
+	struct syscore syscore;
+	unsigned int nr_regs;
+	u32 *saved_regs;
 };
 
 static void meson_gpio_irq_update_bits(struct meson_gpio_irq_controller *ctl,
@@ -633,6 +637,35 @@ static const struct irq_domain_ops meson_gpio_irq_domain_ops = {
 	.translate	= meson_gpio_irq_domain_translate,
 };
 
+/*
+ * The kernel that restores a hibernation image routes the channels in its
+ * own order; write back the image's setup.
+ */
+static int meson_gpio_irq_suspend(void *data)
+{
+	struct meson_gpio_irq_controller *ctl = data;
+	unsigned int i;
+
+	for (i = 0; i < ctl->nr_regs; i++)
+		ctl->saved_regs[i] = readl_relaxed(ctl->base + 4 * i);
+
+	return 0;
+}
+
+static void meson_gpio_irq_resume(void *data)
+{
+	struct meson_gpio_irq_controller *ctl = data;
+	unsigned int i;
+
+	for (i = 0; i < ctl->nr_regs; i++)
+		writel_relaxed(ctl->saved_regs[i], ctl->base + 4 * i);
+}
+
+static const struct syscore_ops meson_gpio_irq_syscore_ops = {
+	.suspend	= meson_gpio_irq_suspend,
+	.resume		= meson_gpio_irq_resume,
+};
+
 static int meson_gpio_irq_parse_dt(struct device_node *node, struct meson_gpio_irq_controller *ctl)
 {
 	const struct of_device_id *match;
@@ -664,6 +697,7 @@ static int meson_gpio_irq_probe(struct platform_device *pdev, struct device_node
 	struct device_node *node = pdev->dev.of_node;
 	struct irq_domain *domain, *parent_domain;
 	struct meson_gpio_irq_controller *ctl;
+	struct resource res;
 	int ret;
 
 	if (!parent) {
@@ -683,10 +717,21 @@ static int meson_gpio_irq_probe(struct platform_device *pdev, struct device_node
 
 	raw_spin_lock_init(&ctl->lock);
 
+	ret = of_address_to_resource(node, 0, &res);
+	if (ret)
+		goto free_ctl;
+
+	ctl->nr_regs = resource_size(&res) / 4;
+	ctl->saved_regs = kzalloc_objs(*ctl->saved_regs, ctl->nr_regs);
+	if (!ctl->saved_regs) {
+		ret = -ENOMEM;
+		goto free_ctl;
+	}
+
 	ctl->base = of_iomap(node, 0);
 	if (!ctl->base) {
 		ret = -ENOMEM;
-		goto free_ctl;
+		goto free_saved_regs;
 	}
 
 	ret = meson_gpio_irq_parse_dt(node, ctl);
@@ -704,6 +749,10 @@ static int meson_gpio_irq_probe(struct platform_device *pdev, struct device_node
 		goto free_channel_irqs;
 	}
 
+	ctl->syscore.ops = &meson_gpio_irq_syscore_ops;
+	ctl->syscore.data = ctl;
+	register_syscore(&ctl->syscore);
+
 	pr_info("%d to %d gpio interrupt mux initialized\n",
 		ctl->params->nr_hwirq, ctl->params->nr_channels);
 
@@ -711,6 +760,8 @@ static int meson_gpio_irq_probe(struct platform_device *pdev, struct device_node
 
 free_channel_irqs:
 	iounmap(ctl->base);
+free_saved_regs:
+	kfree(ctl->saved_regs);
 free_ctl:
 	kfree(ctl);
 

---
base-commit: aab02e49f0b54a0837e58c67651c4abdad1a3208
change-id: 20261120-meson-gpio-hibernate-561119fd6fc6

Best regards,
-- 
Igor Velkov <iav@iav.lv>

