From: Long Zhao <longzhao@ambarella.com>
Date: Tue, 03 Nov 2026 12:47:17 +0800
Subject: [PATCH] gpio: regmap: free the irqchip if adding the irq domain
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-gpio-regmap-irqchip-leak-v1-1-d038a20840f7@ambarella.com>
X-B4-Tracking: v=1; b=H4sIAFRn6WoC/yXMQQ6CMBBA0auQWTNJi2DUqxAXpZ2WAYU6FWNCu
 DtFl2/x/wqJhCnBrVhB6MOJ5ylDlwXY3kyBkF02VKo6a61OGCLPKBSeJiLLy/Yc8UFmRHVtvHM
 X72pvIedRyPP3t27vf6elG8i+jx9s2w7js8X4fAAAAA==
X-Change-ID: 20261103-gpio-regmap-irqchip-leak-095fdd8fd4fc
To: Bartosz Golaszewski <brgl@kernel.org>
Cc: Linus Walleij <linusw@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 linux-gpio@vger.kernel.org, Long Zhao <zl020895@163.com>, 
 Long Zhao <longzhao@ambarella.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793681252; l=1350;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=Ps5e/qP45YCSpKvvs/e6pcBfQwAXRSNPUSMOfnRO6O4=;
 b=RIt6MuHFlBF6UlBNw/AyAdNEzdopsxmq+/uqBkgFQHRj+GPJ2T76bvbz3iUiiJYNQ5mjwEfVR
 EWkVPec8AHIBvSCHpPgkQ+chXP3SCcKMhISBI3SZe+Rn6OYtSf0Vxme
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gpio_regmap_register() creates a regmap irqchip and then calls
gpiochip_irqchip_add_domain(). If that call fails, the error path
only removes the gpiochip, so the irqchip and its domain leak.

Free the irqchip there when this function allocated it. An external
irq domain is not affected: irq_chip_data stays NULL and the caller
owns that domain.

Fixes: 553b75d4bfe9 ("gpio: regmap: Allow to allocate regmap-irq device")
Cc: Michael Walle <mwalle@kernel.org>
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 drivers/gpio/gpio-regmap.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/gpio/gpio-regmap.c b/drivers/gpio/gpio-regmap.c
index 51b4d69b8740..7689357e6077 100644
--- a/drivers/gpio/gpio-regmap.c
+++ b/drivers/gpio/gpio-regmap.c
@@ -418,6 +418,11 @@ struct gpio_regmap *gpio_regmap_register(const struct gpio_regmap_config *config
 
 err_remove_gpiochip:
 	gpiochip_remove(chip);
+
+#ifdef CONFIG_REGMAP_IRQ
+	if (gpio->irq_chip_data)
+		regmap_del_irq_chip(gpio->regmap_irq_line, gpio->irq_chip_data);
+#endif
 err_free_bitmap_output:
 	bitmap_free(gpio->fixed_direction_output);
 err_free_bitmap_dirmask:

---
base-commit: 34cf6dafc47441dfb6b356a095b89c3585a93714
change-id: 20261103-gpio-regmap-irqchip-leak-095fdd8fd4fc

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

