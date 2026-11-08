From: Igor Velkov <iav@iav.lv>
Date: Sun, 08 Nov 2026 18:13:46 +0000
Subject: [PATCH v2] gpio: rockchip: restore the bank registers after
 hibernation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-b4-gpio-rockchip-hib-v2-1-27d3d510cb73@iav.lv>
X-B4-Tracking: v=1; b=H4sIANm78GoC/4WNQQqDMBBFryKz7hQTjWJX3qO4iHFihhYTkhJax
 Ls39QLlr96H//4OiSJTglu1Q6TMif1WQF4qME5vKyEvhUHWshOi7nFucQ3sMXrzMI4DOp6xr5V
 p7KLk3A5QpiGS5fepvU+FHaeXj5/zJYtf+0eYBZYMtl1E12ilaGSdr88M03EcX1QwGW+1AAAA
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: Heiko Stuebner <heiko@sntech.de>, Jianqun Xu <jay.xu@rock-chips.com>, 
 linux-gpio@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>, stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=8075; i=iav@iav.lv;
 h=from:subject:message-id; bh=pGwx8SsOKIXW7baXOGJItsGIAi4ZK2TYXNeKKRDBN58=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkfdt95v874c0H2PoHHGhw/VZxXOP87cV/G3mLhHoPpv
 00rPD5YdpSyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJ/MthZJhTLW8wI75r9hyP
 mjfSYvFb1S5uOP3o+EObP4srttyaaFXByPDqz1o1JSWmleWdzzK2dnn2XYp/N3XSofMWa483f50
 qwcEOAA==
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
acknowledges it, and the system does not come back.

The rest of the bank also comes back as the boot kernel left it. On
the same board, debounce requested on GPIO3_C1 was off after a power
loss in hybrid sleep.

Save the interrupt registers with the masks and write them back before
unmasking. Save the output values, directions and debounce of every
bank, including banks with no interrupt in use, in the noirq phase,
before the drivers that use the lines resume, and write them back on
resume. gpio-dwapb saves the same registers. When the bank kept its
registers, this writes back what is already there.

Fixes: 936ee2675eee ("gpio/rockchip: add driver for rockchip gpio")
Cc: stable@vger.kernel.org
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on v7.3.3 with the Armbian rockchip64 config:
- ODROID-M1 (RK3568, GPIO v2): hybrid sleep with the power removed during
  sleep 4/4, debounce register bits kept; deep sleep 10/10. Without the
  patch 0/5.
- ROCK Pi 4A (RK3399, GPIO v1): hibernation with the power removed 3/3,
  both-edge emulation and debounce register bits kept. Without the patch
  the debounce bit was lost and the line got a spurious interrupt (1 run).
---
Changes in v2:
- Also save and restore the output values, directions and debounce of
  every bank, in the noirq phase (Heiko asked about them).
- Restore the saved polarity of emulated both-edge lines instead of taking
  it from the pin level, which dropped an edge that came during sleep
  (Sashiko).
- Link to v1: https://lore.kernel.org/r/20261107-b4-gpio-rockchip-hib-v1-1-19f4d163a55e@iav.lv
---
 drivers/gpio/gpio-rockchip.c       | 66 ++++++++++++++++++++++++++++++++++++--
 drivers/pinctrl/pinctrl-rockchip.h | 18 +++++++++++
 2 files changed, 81 insertions(+), 3 deletions(-)

diff --git a/drivers/gpio/gpio-rockchip.c b/drivers/gpio/gpio-rockchip.c
index 0f46ff095a24..4c68a62d7985 100644
--- a/drivers/gpio/gpio-rockchip.c
+++ b/drivers/gpio/gpio-rockchip.c
@@ -487,17 +487,33 @@ static void rockchip_irq_suspend(struct irq_data *d)
 {
 	struct irq_chip_generic *gc = irq_data_get_irq_chip_data(d);
 	struct rockchip_pin_bank *bank = gc->private;
+	const struct rockchip_gpio_regs *reg = bank->gpio_regs;
 
-	bank->saved_masks = irq_reg_readl(gc, bank->gpio_regs->int_mask);
-	irq_reg_writel(gc, ~gc->wake_active, bank->gpio_regs->int_mask);
+	bank->saved_masks = irq_reg_readl(gc, reg->int_mask);
+	bank->saved_en = rockchip_gpio_readl(bank, reg->int_en);
+	bank->saved_type = rockchip_gpio_readl(bank, reg->int_type);
+	bank->saved_polarity = rockchip_gpio_readl(bank, reg->int_polarity);
+	if (bank->gpio_type == GPIO_TYPE_V2)
+		bank->saved_bothedge = rockchip_gpio_readl(bank, reg->int_bothedge);
+	irq_reg_writel(gc, ~gc->wake_active, reg->int_mask);
 }
 
 static void rockchip_irq_resume(struct irq_data *d)
 {
 	struct irq_chip_generic *gc = irq_data_get_irq_chip_data(d);
 	struct rockchip_pin_bank *bank = gc->private;
+	const struct rockchip_gpio_regs *reg = bank->gpio_regs;
 
-	irq_reg_writel(gc, bank->saved_masks, bank->gpio_regs->int_mask);
+	/*
+	 * Restore from hibernation follows a cold boot: write the interrupt
+	 * registers back before we unmask.
+	 */
+	rockchip_gpio_writel(bank, bank->saved_en, reg->int_en);
+	rockchip_gpio_writel(bank, bank->saved_type, reg->int_type);
+	rockchip_gpio_writel(bank, bank->saved_polarity, reg->int_polarity);
+	if (bank->gpio_type == GPIO_TYPE_V2)
+		rockchip_gpio_writel(bank, bank->saved_bothedge, reg->int_bothedge);
+	irq_reg_writel(gc, bank->saved_masks, reg->int_mask);
 }
 
 static void rockchip_irq_enable(struct irq_data *d)
@@ -805,6 +821,49 @@ static void rockchip_gpio_remove(struct platform_device *pdev)
 	gpiochip_remove(&bank->gpio_chip);
 }
 
+static int rockchip_gpio_suspend_noirq(struct device *dev)
+{
+	struct rockchip_pin_bank *bank = dev_get_drvdata(dev);
+	const struct rockchip_gpio_regs *reg = bank->gpio_regs;
+	unsigned long flags;
+
+	raw_spin_lock_irqsave(&bank->slock, flags);
+	bank->saved_dr = rockchip_gpio_readl(bank, reg->port_dr);
+	bank->saved_ddr = rockchip_gpio_readl(bank, reg->port_ddr);
+	bank->saved_debounce = rockchip_gpio_readl(bank, reg->debounce);
+	if (bank->gpio_type == GPIO_TYPE_V2) {
+		bank->saved_dbclk_div_en = rockchip_gpio_readl(bank, reg->dbclk_div_en);
+		bank->saved_dbclk_div_con = readl(bank->reg_base + reg->dbclk_div_con);
+	}
+	raw_spin_unlock_irqrestore(&bank->slock, flags);
+
+	return 0;
+}
+
+static int rockchip_gpio_resume_noirq(struct device *dev)
+{
+	struct rockchip_pin_bank *bank = dev_get_drvdata(dev);
+	const struct rockchip_gpio_regs *reg = bank->gpio_regs;
+	unsigned long flags;
+
+	/* Restore from hibernation follows a cold boot: write the bank back. */
+	raw_spin_lock_irqsave(&bank->slock, flags);
+	rockchip_gpio_writel(bank, bank->saved_dr, reg->port_dr);
+	rockchip_gpio_writel(bank, bank->saved_ddr, reg->port_ddr);
+	if (bank->gpio_type == GPIO_TYPE_V2) {
+		writel(bank->saved_dbclk_div_con, bank->reg_base + reg->dbclk_div_con);
+		rockchip_gpio_writel(bank, bank->saved_dbclk_div_en, reg->dbclk_div_en);
+	}
+	rockchip_gpio_writel(bank, bank->saved_debounce, reg->debounce);
+	raw_spin_unlock_irqrestore(&bank->slock, flags);
+
+	return 0;
+}
+
+static DEFINE_NOIRQ_DEV_PM_OPS(rockchip_gpio_pm_ops,
+			       rockchip_gpio_suspend_noirq,
+			       rockchip_gpio_resume_noirq);
+
 static const struct of_device_id rockchip_gpio_match[] = {
 	{ .compatible = "rockchip,gpio-bank" },
 	{ .compatible = "rockchip,rk3188-gpio-bank0" },
@@ -817,6 +876,7 @@ static struct platform_driver rockchip_gpio_driver = {
 	.driver		= {
 		.name	= "rockchip-gpio",
 		.of_match_table = rockchip_gpio_match,
+		.pm	= pm_sleep_ptr(&rockchip_gpio_pm_ops),
 	},
 };
 
diff --git a/drivers/pinctrl/pinctrl-rockchip.h b/drivers/pinctrl/pinctrl-rockchip.h
index 950097699643..855a21bd3703 100644
--- a/drivers/pinctrl/pinctrl-rockchip.h
+++ b/drivers/pinctrl/pinctrl-rockchip.h
@@ -303,6 +303,15 @@ struct rockchip_drv {
  * @db_clk: clock of the gpio debounce
  * @irq: interrupt of the gpio bank
  * @saved_masks: Saved content of GPIO_INTEN at suspend time.
+ * @saved_dr: output values, saved at suspend time.
+ * @saved_ddr: directions, saved at suspend time.
+ * @saved_en: interrupt enables, saved at suspend time.
+ * @saved_type: interrupt level/edge type, saved at suspend time.
+ * @saved_polarity: interrupt polarity, saved at suspend time.
+ * @saved_debounce: debounce enables, saved at suspend time.
+ * @saved_bothedge: interrupt both-edge enables (GPIO v2), saved at suspend time.
+ * @saved_dbclk_div_en: debounce clock divider enables (GPIO v2), saved at suspend time.
+ * @saved_dbclk_div_con: debounce clock divider (GPIO v2), saved at suspend time.
  * @pin_base: first pin number
  * @nr_pins: number of pins in this bank
  * @name: name of the bank
@@ -332,6 +341,15 @@ struct rockchip_pin_bank {
 	struct clk			*db_clk;
 	int				irq;
 	u32				saved_masks;
+	u32				saved_dr;
+	u32				saved_ddr;
+	u32				saved_en;
+	u32				saved_type;
+	u32				saved_polarity;
+	u32				saved_debounce;
+	u32				saved_bothedge;
+	u32				saved_dbclk_div_en;
+	u32				saved_dbclk_div_con;
 	u32				pin_base;
 	u8				nr_pins;
 	char				*name;

---
base-commit: 0fa38ba784896f2fc32c9dacd33822f844b21906
change-id: 20261107-b4-gpio-rockchip-hib-705c3fd52b49

Best regards,
-- 
Igor Velkov <iav@iav.lv>

