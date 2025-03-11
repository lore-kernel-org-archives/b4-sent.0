From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 11 Mar 2025 11:08:28 +0800
Subject: [PATCH v5 2/4] irqchip: Add support for Amlogic A4 and A5 SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250311-irqchip-gpio-a4-a5-v5-2-ca4cc276c18c@amlogic.com>
References: <20250311-irqchip-gpio-a4-a5-v5-0-ca4cc276c18c@amlogic.com>
In-Reply-To: <20250311-irqchip-gpio-a4-a5-v5-0-ca4cc276c18c@amlogic.com>
To: Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741662508; l=5499;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=5O2iR5TSppAsjl+rvJ5i1mjskWacRUIg1rYHkAl0n7A=;
 b=Qgg4fm9Jh64QT6USJwPi80nxkTWeLhcrgs6pDBWZok+f7mJwJfx1G2ZW9dMqLjHTx69Z0ijn3
 U8JbwPonfkUDZjWVIkX81oKq87zFbPKE4f8UHneAKKdEStHwNu4Z+Mg
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Amlogic A4 SoCs support 12 GPIO IRQ lines and 2 AO GPIO IRQ lines,
A5 SoCs support 12 GPIO IRQ lines, details are as below.

A4 IRQ Number:
- 72:55   18 pins on bank T
- 54:32   23 pins on bank X
- 31:16   16 pins on bank D
- 15:14    2 pins on bank E
- 13:0    14 pins on bank B

A4 AO IRQ Number:
- 7       1 pin  on bank TESTN
- 6:0     7 pins on bank AO

A5 IRQ Number:
- 98      1 pin  on bank TESTN
- 97:82   16 pins on bank Z
- 81:62   20 pins on bank X
- 61:48   14 pins on bank T
- 47:32   16 pins on bank D
- 31:27    5 pins on bank H
- 26:25    2 pins on bank E
- 24:14   11 pins on bank C
- 13:0    14 pins on bank B

Reviewed-by: Thomas Gleixner <tglx@linutronix.de>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/irqchip/irq-meson-gpio.c | 48 +++++++++++++++++++++++++++++++---------
 1 file changed, 37 insertions(+), 11 deletions(-)

diff --git a/drivers/irqchip/irq-meson-gpio.c b/drivers/irqchip/irq-meson-gpio.c
index cd789fa51519..0a25536a5d07 100644
--- a/drivers/irqchip/irq-meson-gpio.c
+++ b/drivers/irqchip/irq-meson-gpio.c
@@ -26,8 +26,6 @@
 
 /* use for A1 like chips */
 #define REG_PIN_A1_SEL	0x04
-/* Used for s4 chips */
-#define REG_EDGE_POL_S4	0x1c
 
 /*
  * Note: The S905X3 datasheet reports that BOTH_EDGE is controlled by
@@ -72,6 +70,7 @@ struct meson_gpio_irq_params {
 	bool support_edge_both;
 	unsigned int edge_both_offset;
 	unsigned int edge_single_offset;
+	unsigned int edge_pol_reg;
 	unsigned int pol_low_offset;
 	unsigned int pin_sel_mask;
 	struct irq_ctl_ops ops;
@@ -105,6 +104,18 @@ struct meson_gpio_irq_params {
 	.pin_sel_mask = 0x7f,					\
 	.nr_channels = 8,					\
 
+#define INIT_MESON_A4_AO_COMMON_DATA(irqs)			\
+	INIT_MESON_COMMON(irqs, meson_a1_gpio_irq_init,		\
+			  meson_a1_gpio_irq_sel_pin,		\
+			  meson_s4_gpio_irq_set_type)		\
+	.support_edge_both = true,				\
+	.edge_both_offset = 0,					\
+	.edge_single_offset = 12,				\
+	.edge_pol_reg = 0x8,					\
+	.pol_low_offset = 0,					\
+	.pin_sel_mask = 0xff,					\
+	.nr_channels = 2,					\
+
 #define INIT_MESON_S4_COMMON_DATA(irqs)				\
 	INIT_MESON_COMMON(irqs, meson_a1_gpio_irq_init,		\
 			  meson_a1_gpio_irq_sel_pin,		\
@@ -112,6 +123,7 @@ struct meson_gpio_irq_params {
 	.support_edge_both = true,				\
 	.edge_both_offset = 0,					\
 	.edge_single_offset = 12,				\
+	.edge_pol_reg = 0x1c,					\
 	.pol_low_offset = 0,					\
 	.pin_sel_mask = 0xff,					\
 	.nr_channels = 12,					\
@@ -146,6 +158,18 @@ static const struct meson_gpio_irq_params a1_params = {
 	INIT_MESON_A1_COMMON_DATA(62)
 };
 
+static const struct meson_gpio_irq_params a4_params = {
+	INIT_MESON_S4_COMMON_DATA(81)
+};
+
+static const struct meson_gpio_irq_params a4_ao_params = {
+	INIT_MESON_A4_AO_COMMON_DATA(8)
+};
+
+static const struct meson_gpio_irq_params a5_params = {
+	INIT_MESON_S4_COMMON_DATA(99)
+};
+
 static const struct meson_gpio_irq_params s4_params = {
 	INIT_MESON_S4_COMMON_DATA(82)
 };
@@ -168,6 +192,9 @@ static const struct of_device_id meson_irq_gpio_matches[] __maybe_unused = {
 	{ .compatible = "amlogic,meson-sm1-gpio-intc", .data = &sm1_params },
 	{ .compatible = "amlogic,meson-a1-gpio-intc", .data = &a1_params },
 	{ .compatible = "amlogic,meson-s4-gpio-intc", .data = &s4_params },
+	{ .compatible = "amlogic,a4-gpio-ao-intc", .data = &a4_ao_params },
+	{ .compatible = "amlogic,a4-gpio-intc", .data = &a4_params },
+	{ .compatible = "amlogic,a5-gpio-intc", .data = &a5_params },
 	{ .compatible = "amlogic,c3-gpio-intc", .data = &c3_params },
 	{ .compatible = "amlogic,t7-gpio-intc", .data = &t7_params },
 	{ }
@@ -299,11 +326,10 @@ meson_gpio_irq_release_channel(struct meson_gpio_irq_controller *ctl,
 static int meson8_gpio_irq_set_type(struct meson_gpio_irq_controller *ctl,
 				    unsigned int type, u32 *channel_hwirq)
 {
-	u32 val = 0;
+	const struct meson_gpio_irq_params *params = ctl->params;
 	unsigned int idx;
-	const struct meson_gpio_irq_params *params;
+	u32 val = 0;
 
-	params = ctl->params;
 	idx = meson_gpio_irq_get_channel_idx(ctl, channel_hwirq);
 
 	/*
@@ -356,19 +382,19 @@ static int meson8_gpio_irq_set_type(struct meson_gpio_irq_controller *ctl,
 static int meson_s4_gpio_irq_set_type(struct meson_gpio_irq_controller *ctl,
 				      unsigned int type, u32 *channel_hwirq)
 {
-	u32 val = 0;
+	const struct meson_gpio_irq_params *params = ctl->params;
 	unsigned int idx;
+	u32 val = 0;
 
 	idx = meson_gpio_irq_get_channel_idx(ctl, channel_hwirq);
 
 	type &= IRQ_TYPE_SENSE_MASK;
 
-	meson_gpio_irq_update_bits(ctl, REG_EDGE_POL_S4, BIT(idx), 0);
+	meson_gpio_irq_update_bits(ctl, params->edge_pol_reg, BIT(idx), 0);
 
 	if (type == IRQ_TYPE_EDGE_BOTH) {
-		val |= BIT(ctl->params->edge_both_offset + idx);
-		meson_gpio_irq_update_bits(ctl, REG_EDGE_POL_S4,
-					   BIT(ctl->params->edge_both_offset + idx), val);
+		val = BIT(ctl->params->edge_both_offset + idx);
+		meson_gpio_irq_update_bits(ctl, params->edge_pol_reg, val, val);
 		return 0;
 	}
 
@@ -378,7 +404,7 @@ static int meson_s4_gpio_irq_set_type(struct meson_gpio_irq_controller *ctl,
 	if (type & (IRQ_TYPE_EDGE_RISING | IRQ_TYPE_EDGE_FALLING))
 		val |= BIT(ctl->params->edge_single_offset + idx);
 
-	meson_gpio_irq_update_bits(ctl, REG_EDGE_POL,
+	meson_gpio_irq_update_bits(ctl, params->edge_pol_reg,
 				   BIT(idx) | BIT(12 + idx), val);
 	return 0;
 };

-- 
2.37.1

