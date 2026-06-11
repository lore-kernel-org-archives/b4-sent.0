From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 11 Jun 2026 07:54:34 +0000
Subject: [PATCH RFC 2/2] pinctrl: meson: amlogic-a4: support gpiod_to_irq
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260611-gpio-to-irq-v1-2-12201716f23f@amlogic.com>
References: <20260611-gpio-to-irq-v1-0-12201716f23f@amlogic.com>
In-Reply-To: <20260611-gpio-to-irq-v1-0-12201716f23f@amlogic.com>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781164479; l=3292;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=wam4L3P2h/0NFdexAcbLeoEfUZ98TPeWasBAMHYVyak=;
 b=s65JzHoxnO5BzjEeGLbrqC0khJxXlE8BIifX49u9Y9PHSK4mRgDOh3fPDe/XP0mhHRyCgy3Zp
 5sEiMS4ywQNDGuHS8ziMDdXaacMr3Y7C2Mf8kNx3YDj5wdiSytG5hhT
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the to_irq() callback implementation so that
gpiod_to_irq() can map GPIO lines to IRQs correctly.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c | 54 ++++++++++++++++++++++++++++++
 1 file changed, 54 insertions(+)

diff --git a/drivers/pinctrl/meson/pinctrl-amlogic-a4.c b/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
index 5ae0c19d007d..663681887f35 100644
--- a/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
+++ b/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
@@ -10,6 +10,7 @@
 #include <linux/io.h>
 #include <linux/module.h>
 #include <linux/of.h>
+#include <linux/of_irq.h>
 #include <linux/of_address.h>
 #include <linux/platform_device.h>
 #include <linux/regmap.h>
@@ -97,6 +98,8 @@ struct aml_gpio_bank {
 	struct regmap			*reg_gpio;
 	struct regmap			*reg_ds;
 	const struct multi_mux		*p_mux;
+	struct device_node		*of_irq;
+	u32				irq_start;
 };
 
 struct aml_pinctrl {
@@ -836,6 +839,32 @@ static int aml_pctl_parse_functions(struct device_node *np,
 	return 0;
 }
 
+static struct device_node *aml_get_of_irq(struct device_node *np)
+{
+	struct device_node *of_irq;
+
+	of_irq = of_irq_find_parent(np);
+	if (of_irq && of_device_is_compatible(of_irq, "amlogic,meson-gpio-intc")) {
+		of_node_put(of_irq);
+		return of_irq;
+	}
+
+	if (of_irq)
+		of_node_put(of_irq);
+
+	return NULL;
+}
+
+static u32 aml_bank_irq(struct device_node *np)
+{
+	u32 hw_irq;
+
+	if (of_property_read_u32(np, "hw-irq", &hw_irq))
+		return U32_MAX;
+
+	return hw_irq;
+}
+
 static u32 aml_bank_pins(struct device_node *np)
 {
 	struct of_phandle_args of_args;
@@ -1003,6 +1032,27 @@ static int aml_gpio_get(struct gpio_chip *chip, unsigned int gpio)
 	return !!(val & BIT(bit));
 }
 
+static int aml_gpio_to_irq(struct gpio_chip *chip, unsigned int gpio)
+{
+	struct aml_gpio_bank *bank = gpiochip_get_data(chip);
+	struct irq_fwspec fwspec;
+	int hwirq;
+
+	if (bank->irq_start == U32_MAX)
+		return -EINVAL;
+	if (!bank->of_irq)
+		return -EINVAL;
+
+	hwirq = gpio + bank->irq_start;
+
+	fwspec.fwnode = of_fwnode_handle(bank->of_irq);
+	fwspec.param_count = 2;
+	fwspec.param[0] = hwirq;
+	fwspec.param[1] = IRQ_TYPE_NONE;
+
+	return irq_create_fwspec_mapping(&fwspec);
+}
+
 static const struct gpio_chip aml_gpio_template = {
 	.request		= gpiochip_generic_request,
 	.free			= gpiochip_generic_free,
@@ -1012,6 +1062,7 @@ static const struct gpio_chip aml_gpio_template = {
 	.direction_input	= aml_gpio_direction_input,
 	.direction_output	= aml_gpio_direction_output,
 	.get_direction		= aml_gpio_get_direction,
+	.to_irq			= aml_gpio_to_irq,
 	.can_sleep		= true,
 };
 
@@ -1079,6 +1130,7 @@ static int aml_gpiolib_register_bank(struct aml_pinctrl *info,
 		bank->reg_ds = bank->reg_gpio;
 	}
 
+	bank->irq_start = aml_bank_irq(np);
 	bank->gpio_chip = aml_gpio_template;
 	bank->gpio_chip.base = -1;
 	bank->gpio_chip.ngpio = aml_bank_pins(np);
@@ -1154,6 +1206,8 @@ static int aml_pctl_probe_dt(struct platform_device *pdev,
 				pdesc->name = pin_names[j];
 				pdesc++;
 			}
+
+			info->banks[bank].of_irq = aml_get_of_irq(np);
 			bank++;
 		} else {
 			ret = aml_pctl_parse_functions(child, info,

-- 
2.52.0

