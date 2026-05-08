From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 08 May 2026 07:36:56 +0000
Subject: [PATCH 3/3] irqchip/meson-gpio: Add support for Amlogic A9 SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-a9-gpio-irqchip-v1-3-9dc5f3e022e0@amlogic.com>
References: <20260508-a9-gpio-irqchip-v1-0-9dc5f3e022e0@amlogic.com>
In-Reply-To: <20260508-a9-gpio-irqchip-v1-0-9dc5f3e022e0@amlogic.com>
To: Thomas Gleixner <tglx@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778225816; l=5139;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=nAfHIz6N7m4oMjB9PiZJjp678ZGWzDBR5xK3MB5dJRI=;
 b=LQqjSXVX5QTASAePP+dTc5VePmsxGw865S8yEFVsPZYttboDVp/QTlPgVoCGnoRWa2qnYkkxQ
 DSMvkv5e2qJAdEt0U+nTcK7fleZv3bDwgY8ic4O05kPcarkQYcRghC/
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Amlogic A9 SoCs support GPIO interrupt lines:
	A9 IRQ Number:
        - 95:86   10 pins on bank Y
        - 85:84    2 pins on bank CC
        - 83:64   20 pins on bank A
        - 63:48   16 pins on bank Z
        - 47:30   18 pins on bank X
        - 29:22    8 pins on bank H
        - 21:14    8 pins on bank M
        - 13:0    14 pins on bank B

	A9 AO IRQ Number:
        - 38       1 pins on bank TESTN
        - 37:31    7 pins on bank C
        - 30:13   18 pins on bank D
        - 12:0    13 pins on bank AO

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/irqchip/irq-meson-gpio.c | 75 ++++++++++++++++++++++++++++++++++++++++
 1 file changed, 75 insertions(+)

diff --git a/drivers/irqchip/irq-meson-gpio.c b/drivers/irqchip/irq-meson-gpio.c
index 74a376ef452e..f68476b2c538 100644
--- a/drivers/irqchip/irq-meson-gpio.c
+++ b/drivers/irqchip/irq-meson-gpio.c
@@ -27,6 +27,10 @@
 /* use for A1 like chips */
 #define REG_PIN_A1_SEL	0x04
 
+/* use for A9 like chips */
+#define REG_A9_AO_POL	0x00
+#define REG_A9_AO_EDGE	0x30
+
 /*
  * Note: The S905X3 datasheet reports that BOTH_EDGE is controlled by
  * bits 24 to 31. Tests on the actual HW show that these bits are
@@ -53,6 +57,8 @@ static void meson_a1_gpio_irq_sel_pin(struct meson_gpio_irq_controller *ctl,
 static void meson_a1_gpio_irq_init(struct meson_gpio_irq_controller *ctl);
 static int meson8_gpio_irq_set_type(struct meson_gpio_irq_controller *ctl,
 				    unsigned int type, u32 *channel_hwirq);
+static int meson_a9_ao_gpio_irq_set_type(struct meson_gpio_irq_controller *ctl,
+					 unsigned int type, u32 *channel_hwirq);
 static int meson_s4_gpio_irq_set_type(struct meson_gpio_irq_controller *ctl,
 				      unsigned int type, u32 *channel_hwirq);
 
@@ -116,6 +122,18 @@ struct meson_gpio_irq_params {
 	.pin_sel_mask = 0xff,					\
 	.nr_channels = 2,					\
 
+#define INIT_MESON_A9_AO_COMMON_DATA(irqs)			\
+	INIT_MESON_COMMON(irqs, meson_a1_gpio_irq_init,		\
+			  meson_a1_gpio_irq_sel_pin,		\
+			  meson_a9_ao_gpio_irq_set_type)	\
+	.support_edge_both = true,				\
+	.edge_both_offset = 0,					\
+	.edge_single_offset = 0,				\
+	.edge_pol_reg = 0x2c,					\
+	.pol_low_offset = 0,					\
+	.pin_sel_mask = 0xff,					\
+	.nr_channels = 20,					\
+
 #define INIT_MESON_S4_COMMON_DATA(irqs)				\
 	INIT_MESON_COMMON(irqs, meson_a1_gpio_irq_init,		\
 			  meson_a1_gpio_irq_sel_pin,		\
@@ -170,6 +188,14 @@ static const struct meson_gpio_irq_params a5_params = {
 	INIT_MESON_S4_COMMON_DATA(99)
 };
 
+static const struct meson_gpio_irq_params a9_params = {
+	INIT_MESON_S4_COMMON_DATA(96)
+};
+
+static const struct meson_gpio_irq_params a9_ao_params = {
+	INIT_MESON_A9_AO_COMMON_DATA(39)
+};
+
 static const struct meson_gpio_irq_params s4_params = {
 	INIT_MESON_S4_COMMON_DATA(82)
 };
@@ -203,6 +229,8 @@ static const struct of_device_id meson_irq_gpio_matches[] __maybe_unused = {
 	{ .compatible = "amlogic,a4-gpio-ao-intc", .data = &a4_ao_params },
 	{ .compatible = "amlogic,a4-gpio-intc", .data = &a4_params },
 	{ .compatible = "amlogic,a5-gpio-intc", .data = &a5_params },
+	{ .compatible = "amlogic,a9-gpio-ao-intc", .data = &a9_ao_params },
+	{ .compatible = "amlogic,a9-gpio-intc", .data = &a9_params },
 	{ .compatible = "amlogic,s6-gpio-intc", .data = &s6_params },
 	{ .compatible = "amlogic,s7-gpio-intc", .data = &s7_params },
 	{ .compatible = "amlogic,s7d-gpio-intc", .data = &s7_params },
@@ -375,6 +403,53 @@ static int meson8_gpio_irq_set_type(struct meson_gpio_irq_controller *ctl,
 	return 0;
 }
 
+/*
+ * gpio irq relative registers for a9_ao
+ * -PADCTRL_GPIO_IRQ_CTRL0
+ * bit[31]:    enable/disable all the irq lines
+ * bit[0-19]:  polarity trigger
+ *
+ * -PADCTRL_GPIO_IRQ_CTRL[X]
+ * bit[0-5]: 6 bits to choose gpio source for irq line 2*[X] - 2
+ * bit[16-21]:6 bits to choose gpio source for irq line 2*[X] - 1
+ * where X = 1-10
+ *
+ * -PADCTRL_GPIO_IRQ_CTRL[11]
+ * bit[0-19]: both edge trigger
+ *
+ * -PADCTRL_GPIO_IRQ_CTRL[12]
+ * bit[0-19]: single edge trigger
+ */
+static int meson_a9_ao_gpio_irq_set_type(struct meson_gpio_irq_controller *ctl,
+					 unsigned int type, u32 *channel_hwirq)
+{
+	const struct meson_gpio_irq_params *params = ctl->params;
+	unsigned int idx;
+	u32 val = 0;
+
+	idx = meson_gpio_irq_get_channel_idx(ctl, channel_hwirq);
+
+	type &= IRQ_TYPE_SENSE_MASK;
+
+	meson_gpio_irq_update_bits(ctl, params->edge_pol_reg, BIT(idx), 0);
+
+	if (type == IRQ_TYPE_EDGE_BOTH) {
+		val = BIT(ctl->params->edge_both_offset + idx);
+		meson_gpio_irq_update_bits(ctl, params->edge_pol_reg, val, val);
+		return 0;
+	}
+
+	if (type & (IRQ_TYPE_LEVEL_LOW | IRQ_TYPE_EDGE_FALLING))
+		val = BIT(idx);
+	meson_gpio_irq_update_bits(ctl, REG_A9_AO_POL, BIT(idx), val);
+
+	val = 0;
+	if (type & (IRQ_TYPE_EDGE_RISING | IRQ_TYPE_EDGE_FALLING))
+		val = BIT(idx);
+	meson_gpio_irq_update_bits(ctl, REG_A9_AO_EDGE, BIT(idx), val);
+
+	return 0;
+};
 /*
  * gpio irq relative registers for s4
  * -PADCTRL_GPIO_IRQ_CTRL0

-- 
2.52.0

