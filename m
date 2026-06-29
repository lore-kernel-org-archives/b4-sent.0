From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 29 Jun 2026 13:30:39 +0800
Subject: [PATCH] gpio: dwapb: Defer clock gating until noirq
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-gpio-dwapb-wakeup-v1-1-3394f02317da@ultrarisc.com>
X-B4-Tracking: v=1; b=H4sIAP4CQmoC/yXMTQqDMBBA4avIrDsQYwzWq5Qu8jPRsaAhqbUg3
 r2pLr/FeztkSkwZ+mqHRB/OvMwF9a0CN5p5IGRfDFJILbS84xB5Qb+ZaHEzL1ojNsqItgvaNVJ
 B6WKiwN/z+XhezqudyL3/IziOH5g8/U51AAAA
X-Change-ID: 20260629-gpio-dwapb-wakeup-34a058f6c324
To: Hoan Tran <hoan@os.amperecomputing.com>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Hoan Tran <hotran@apm.com>, linux-gpio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782711160; l=6202;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=g4rwSAFhgwqLta0rkHzLInNFzAIIrHUuIi0OSa42Ub0=;
 b=x4mGEsqKlYunL0LKb+qqQTNj8uqNdJpycXsa8/lvqwF2LUGlcLZlUiX+5LPBIZUPU053DF6Gb
 7HBNNo9vnQNAFd0tJOT/ywF5RCaw0DPgZTRtllqlLTgy70gDA/izmRC
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

GPIO consumers such as gpio-keys can enable IRQ wake and adjust the wake
trigger type from their suspend callbacks. If the DWAPB controller suspends
first, masking interrupts and disabling its clocks in the normal suspend
phase prevents that late wake configuration from reliably reaching the
hardware. Systems with real DWAPB bus clocks then fail to wake from s2idle
through GPIO keys.

Save the register context in the normal suspend callback, but defer IRQ
masking and clock gating until suspend_noirq. At that point all consumers
have finished configuring wake IRQs, so keep the clocks enabled when wake
lines are armed and only gate them when no wake source is active.
Resume_noirq reenables clocks, if they were gated, before the normal resume
path restores registers.

Propagate wake requests to the parent irqchip while keeping the local wake
mask in sync with failures.

Fixes: 6437c7ba69c3 ("gpio: dwapb: Add wakeup source support")
Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
This one-patch series fixes system wakeup for DesignWare APB GPIO
controllers that have real APB/debounce clocks.

The driver currently masks interrupts and disables its clocks from the
normal suspend callback. That is too early for GPIO consumers such as
gpio-keys, which may still enable IRQ wake or adjust the wake trigger type
from their own suspend callbacks. Once the DWAPB clocks are disabled, those
late wake updates cannot reliably reach the controller, and GPIO-key wake
from s2idle can fail.

Move the final interrupt masking and clock gating to suspend_noirq, after
consumers have completed their wake configuration. If at least one wake
line is armed, leave the clocks running and mark the device as part of the
wakeup path. Otherwise, gate the clocks in noirq and re-enable them from
resume_noirq before restoring the saved register state.

The patch also propagates aggregate wake enable/disable state to the
parent irqchip so a wake-capable parent interrupt is armed only while the
DWAPB controller has at least one local wake source.

Based on v7.2-rc1.
---
 drivers/gpio/gpio-dwapb.c | 76 +++++++++++++++++++++++++++++++++++++++--------
 1 file changed, 64 insertions(+), 12 deletions(-)

diff --git a/drivers/gpio/gpio-dwapb.c b/drivers/gpio/gpio-dwapb.c
index c1f3d83a67c1..504e2d779584 100644
--- a/drivers/gpio/gpio-dwapb.c
+++ b/drivers/gpio/gpio-dwapb.c
@@ -118,6 +118,7 @@ struct dwapb_gpio {
 	unsigned int		flags;
 	struct reset_control	*rst;
 	struct clk_bulk_data	clks[DWAPB_NR_CLOCKS];
+	bool			clocks_on_for_wake;
 	struct dwapb_gpio_port	ports[] __counted_by(nr_ports);
 };
 
@@ -365,11 +366,21 @@ static int dwapb_irq_set_wake(struct irq_data *d, unsigned int enable)
 	struct dwapb_gpio *gpio = to_dwapb_gpio(gc);
 	struct dwapb_context *ctx = gpio->ports[0].ctx;
 	irq_hw_number_t bit = irqd_to_hwirq(d);
+	u32 wake_en = ctx->wake_en;
+	int err;
 
 	if (enable)
-		ctx->wake_en |= BIT(bit);
+		wake_en |= BIT(bit);
 	else
-		ctx->wake_en &= ~BIT(bit);
+		wake_en &= ~BIT(bit);
+
+	if (d->parent_data && !!ctx->wake_en != !!wake_en) {
+		err = irq_chip_set_wake_parent(d, enable);
+		if (err)
+			return err;
+	}
+
+	ctx->wake_en = wake_en;
 
 	return 0;
 }
@@ -750,6 +761,8 @@ static int dwapb_gpio_suspend(struct device *dev)
 	int i;
 
 	scoped_guard(gpio_generic_lock_irqsave, gen_gc) {
+		gpio->clocks_on_for_wake = false;
+
 		for (i = 0; i < gpio->nr_ports; i++) {
 			unsigned int offset;
 			unsigned int idx = gpio->ports[i].idx;
@@ -771,11 +784,38 @@ static int dwapb_gpio_suspend(struct device *dev)
 				ctx->int_pol = dwapb_read(gpio, GPIO_INT_POLARITY);
 				ctx->int_type = dwapb_read(gpio, GPIO_INTTYPE_LEVEL);
 				ctx->int_deb = dwapb_read(gpio, GPIO_PORTA_DEBOUNCE);
+			}
+		}
+	}
+
+	return 0;
+}
+
+static int dwapb_gpio_suspend_noirq(struct device *dev)
+{
+	struct dwapb_gpio *gpio = dev_get_drvdata(dev);
+	struct gpio_generic_chip *gen_gc = &gpio->ports[0].chip;
+	bool wake_enabled = false;
+	int i;
+
+	scoped_guard(gpio_generic_lock_irqsave, gen_gc) {
+		for (i = 0; i < gpio->nr_ports; i++) {
+			unsigned int idx = gpio->ports[i].idx;
+			struct dwapb_context *ctx = gpio->ports[i].ctx;
 
-				/* Mask out interrupts */
+			if (idx == 0) {
+				wake_enabled = ctx->wake_en;
 				dwapb_write(gpio, GPIO_INTMASK, ~ctx->wake_en);
+				break;
 			}
 		}
+
+		gpio->clocks_on_for_wake = wake_enabled;
+	}
+
+	if (wake_enabled) {
+		device_set_wakeup_path(dev);
+		return 0;
 	}
 
 	clk_bulk_disable_unprepare(DWAPB_NR_CLOCKS, gpio->clks);
@@ -783,18 +823,27 @@ static int dwapb_gpio_suspend(struct device *dev)
 	return 0;
 }
 
-static int dwapb_gpio_resume(struct device *dev)
+static int dwapb_gpio_resume_noirq(struct device *dev)
 {
 	struct dwapb_gpio *gpio = dev_get_drvdata(dev);
-	struct gpio_chip *gc = &gpio->ports[0].chip.gc;
-	struct gpio_generic_chip *gen_gc = to_gpio_generic_chip(gc);
-	int i, err;
+	int err;
+
+	if (gpio->clocks_on_for_wake)
+		return 0;
 
 	err = clk_bulk_prepare_enable(DWAPB_NR_CLOCKS, gpio->clks);
-	if (err) {
+	if (err)
 		dev_err(gpio->dev, "Cannot reenable APB/Debounce clocks\n");
-		return err;
-	}
+
+	return err;
+}
+
+static int dwapb_gpio_resume(struct device *dev)
+{
+	struct dwapb_gpio *gpio = dev_get_drvdata(dev);
+	struct gpio_chip *gc = &gpio->ports[0].chip.gc;
+	struct gpio_generic_chip *gen_gc = to_gpio_generic_chip(gc);
+	int i;
 
 	guard(gpio_generic_lock_irqsave)(gen_gc);
 
@@ -828,8 +877,11 @@ static int dwapb_gpio_resume(struct device *dev)
 	return 0;
 }
 
-static DEFINE_SIMPLE_DEV_PM_OPS(dwapb_gpio_pm_ops,
-				dwapb_gpio_suspend, dwapb_gpio_resume);
+static const struct dev_pm_ops dwapb_gpio_pm_ops = {
+	SYSTEM_SLEEP_PM_OPS(dwapb_gpio_suspend, dwapb_gpio_resume)
+	NOIRQ_SYSTEM_SLEEP_PM_OPS(dwapb_gpio_suspend_noirq,
+				  dwapb_gpio_resume_noirq)
+};
 
 static struct platform_driver dwapb_gpio_driver = {
 	.driver		= {

---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260629-gpio-dwapb-wakeup-34a058f6c324

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

