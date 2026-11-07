From: Igor Velkov <iav@iav.lv>
Date: Sat, 07 Nov 2026 07:55:00 +0200
Subject: [PATCH] gpio: rockchip: restore interrupt settings after
 hibernation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-b4-gpio-rockchip-hib-v1-1-19f4d163a55e@iav.lv>
X-B4-Tracking: v=1; b=H4sIADS97moC/x3MQQqAIBBA0avErBtQy6KuEi1SpxyCFIUIpLsnL
 d/i/wKZElOGuSmQ6ObM4aqQbQPWb9dByK4alFCDlGJE0+MROWAK9rSeI3o2OAptu91pZfoJaho
 T7fz822V93w+7uc8zZgAAAA==
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: Heiko Stuebner <heiko@sntech.de>, Jianqun Xu <jay.xu@rock-chips.com>, 
 linux-gpio@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>, stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4448; i=iav@iav.lv;
 h=from:subject:message-id; bh=Dk4H/o+1eyRMlxB1wc6jS7hkgNHj7wT6TPN6Ut/qDU4=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnv9po6dYmpXb28vvvIlp/mXtva1HY+EvnfE9X0OUCqO
 fYz99KIjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCR8xGMDI8aXPqLJyzbVBVo
 vm3T2zVfH91ZWvvCJtXQgP/k3vVctsEM/9P1/fnerJbZtzOyccbmzfME7BNft7Xl+gX92Kddv+A
 4ExMA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Restore from hibernation follows a cold boot. The boot kernel probes
the GPIO banks, sets every interrupt enable bit, leaves the trigger of
each line it did not request at the reset value, and then hands over
to the image. The image restores only the interrupt masks, so a line
it had set up for both edges comes back with the reset trigger.

On ODROID-M1 the headphone detect line (GPIO0_B0) is requested for
both edges and is low with nothing plugged in. After a power loss in
hybrid sleep its reset trigger fires again as soon as the edge handler
acknowledges it, and the system does not come back. With this patch
the board resumed 4 of 4 times, without it 0 of 5.

Save the interrupt enable, type, polarity and both-edge registers with
the masks and write them back before unmasking. In a normal suspend
the bank keeps its registers, so this writes back what is already
there. For lines that emulate both edges on GPIO v1, take the polarity
from the current pin level.

Fixes: 936ee2675eee ("gpio/rockchip: add driver for rockchip gpio")
Cc: stable@vger.kernel.org
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ODROID-M1 (RK3568, GPIO v2): hybrid sleep with power removed
during sleep 4/4, deep sleep 10/10. The GPIO v1 path was not tested on
hardware.
---
 drivers/gpio/gpio-rockchip.c       | 21 +++++++++++++++++++++
 drivers/pinctrl/pinctrl-rockchip.h |  8 ++++++++
 2 files changed, 29 insertions(+)

diff --git a/drivers/gpio/gpio-rockchip.c b/drivers/gpio/gpio-rockchip.c
index 0f46ff095a24..83a5cc8f3fe6 100644
--- a/drivers/gpio/gpio-rockchip.c
+++ b/drivers/gpio/gpio-rockchip.c
@@ -489,6 +489,11 @@ static void rockchip_irq_suspend(struct irq_data *d)
 	struct rockchip_pin_bank *bank = gc->private;
 
 	bank->saved_masks = irq_reg_readl(gc, bank->gpio_regs->int_mask);
+	bank->saved_en = rockchip_gpio_readl(bank, bank->gpio_regs->int_en);
+	bank->saved_type = rockchip_gpio_readl(bank, bank->gpio_regs->int_type);
+	bank->saved_polarity = rockchip_gpio_readl(bank, bank->gpio_regs->int_polarity);
+	if (bank->gpio_type == GPIO_TYPE_V2)
+		bank->saved_bothedge = rockchip_gpio_readl(bank, bank->gpio_regs->int_bothedge);
 	irq_reg_writel(gc, ~gc->wake_active, bank->gpio_regs->int_mask);
 }
 
@@ -496,7 +501,23 @@ static void rockchip_irq_resume(struct irq_data *d)
 {
 	struct irq_chip_generic *gc = irq_data_get_irq_chip_data(d);
 	struct rockchip_pin_bank *bank = gc->private;
+	u32 polarity = bank->saved_polarity;
+
+	/*
+	 * Restore from hibernation follows a cold boot: write the enables and
+	 * the trigger back before we unmask.
+	 */
+	if (bank->toggle_edge_mode) {
+		u32 data = readl(bank->reg_base + bank->gpio_regs->ext_port);
 
+		polarity &= ~bank->toggle_edge_mode;
+		polarity |= ~data & bank->toggle_edge_mode;
+	}
+	rockchip_gpio_writel(bank, bank->saved_en, bank->gpio_regs->int_en);
+	rockchip_gpio_writel(bank, bank->saved_type, bank->gpio_regs->int_type);
+	rockchip_gpio_writel(bank, polarity, bank->gpio_regs->int_polarity);
+	if (bank->gpio_type == GPIO_TYPE_V2)
+		rockchip_gpio_writel(bank, bank->saved_bothedge, bank->gpio_regs->int_bothedge);
 	irq_reg_writel(gc, bank->saved_masks, bank->gpio_regs->int_mask);
 }
 
diff --git a/drivers/pinctrl/pinctrl-rockchip.h b/drivers/pinctrl/pinctrl-rockchip.h
index 950097699643..ea280843fcb9 100644
--- a/drivers/pinctrl/pinctrl-rockchip.h
+++ b/drivers/pinctrl/pinctrl-rockchip.h
@@ -303,6 +303,10 @@ struct rockchip_drv {
  * @db_clk: clock of the gpio debounce
  * @irq: interrupt of the gpio bank
  * @saved_masks: Saved content of GPIO_INTEN at suspend time.
+ * @saved_en: interrupt enables, saved at suspend time.
+ * @saved_type: interrupt level/edge type, saved at suspend time.
+ * @saved_polarity: interrupt polarity, saved at suspend time.
+ * @saved_bothedge: interrupt both-edge enables (GPIO v2), saved at suspend time.
  * @pin_base: first pin number
  * @nr_pins: number of pins in this bank
  * @name: name of the bank
@@ -332,6 +336,10 @@ struct rockchip_pin_bank {
 	struct clk			*db_clk;
 	int				irq;
 	u32				saved_masks;
+	u32				saved_en;
+	u32				saved_type;
+	u32				saved_polarity;
+	u32				saved_bothedge;
 	u32				pin_base;
 	u8				nr_pins;
 	char				*name;

---
base-commit: 0fa38ba784896f2fc32c9dacd33822f844b21906
change-id: 20261107-b4-gpio-rockchip-hib-705c3fd52b49

Best regards,
-- 
Igor Velkov <iav@iav.lv>

