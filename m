From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 23:54:47 +0300
Subject: [PATCH v3 4/5] pinctrl: Add Cortina Systems CS7542 pin multiplexer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-cs7542-syscon-v3-4-f1c07a1703f8@gmail.com>
References: <20261123-cs7542-syscon-v3-0-f1c07a1703f8@gmail.com>
In-Reply-To: <20261123-cs7542-syscon-v3-0-f1c07a1703f8@gmail.com>
To: Linus Walleij <linusw@kernel.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Arnd Bergmann <arnd@arndb.de>, linux-gpio@vger.kernel.org, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795467283; l=8324;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=UNpZwyEFgKF3jz0tUixduHTlnN10XC0JDB4foaScjk8=;
 b=HrLL6m3lU/7ePkPCXMMAO96hxS4u1wsdc28dFsbqKxdE2p5fhqk/wWlEi8qfBQOYjHEbNUP75
 kZ/ENiGAHEWDdlIbOh8W1DRowjJojqKyer7DToQHyQ4J38ehvcSznPi
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the global syscon regmap for the five GPIO mux registers. Each
bit selects GPIO when set and a peripheral signal when clear. Support
GPIO on all 160 lines and the six UART pins exercised by the OpenWrt
port. Do not guess mux settings for the other peripherals.

Use masked regmap updates so independent pins and users of the shared
block retain their settings. No register changes are made merely by
probing; only a selected state or a GPIO request changes a pin.
Register and initialize the controller before enabling its own hogs.

AI assistance: Codex prepared this change from the existing OpenWrt port
and GPL vendor sources.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/pinctrl/Kconfig          |  13 +++
 drivers/pinctrl/Makefile         |   1 +
 drivers/pinctrl/pinctrl-cs7542.c | 195 +++++++++++++++++++++++++++++++++++++++
 3 files changed, 209 insertions(+)

diff --git a/drivers/pinctrl/Kconfig b/drivers/pinctrl/Kconfig
index dc7138302..89f247cb2 100644
--- a/drivers/pinctrl/Kconfig
+++ b/drivers/pinctrl/Kconfig
@@ -188,6 +188,19 @@ config PINCTRL_BM1880
 	help
 	  Pinctrl driver for Bitmain BM1880 SoC.
 
+config PINCTRL_CS7542
+	tristate "Cortina Systems CS7542 pin multiplexer"
+	depends on OF && HAS_IOMEM
+	select MFD_SYSCON
+	select PINMUX
+	select GENERIC_PINCONF
+	help
+	  Select GPIO mode or the supported peripheral signals in the CS7542
+	  global control block. This driver shares the syscon register map
+	  with the clock provider and leaves unrelated pins unchanged.
+	  Electrical pin configuration and other peripheral routes are not
+	  implemented.
+
 config PINCTRL_CY8C95X0
 	tristate "Cypress CY8C95X0 I2C pinctrl and GPIO driver"
 	depends on I2C
diff --git a/drivers/pinctrl/Makefile b/drivers/pinctrl/Makefile
index ce0825f4f..59541be4d 100644
--- a/drivers/pinctrl/Makefile
+++ b/drivers/pinctrl/Makefile
@@ -23,6 +23,7 @@ obj-$(CONFIG_PINCTRL_AW9523)	+= pinctrl-aw9523.o
 obj-$(CONFIG_PINCTRL_AXP209)	+= pinctrl-axp209.o
 obj-$(CONFIG_PINCTRL_BM1880)	+= pinctrl-bm1880.o
 obj-$(CONFIG_PINCTRL_CY8C95X0)	+= pinctrl-cy8c95x0.o
+obj-$(CONFIG_PINCTRL_CS7542)	+= pinctrl-cs7542.o
 obj-$(CONFIG_PINCTRL_DA850_PUPD) += pinctrl-da850-pupd.o
 obj-$(CONFIG_PINCTRL_DA9062)	+= pinctrl-da9062.o
 obj-$(CONFIG_PINCTRL_DIGICOLOR)	+= pinctrl-digicolor.o
diff --git a/drivers/pinctrl/pinctrl-cs7542.c b/drivers/pinctrl/pinctrl-cs7542.c
new file mode 100644
index 000000000..748682675
--- /dev/null
+++ b/drivers/pinctrl/pinctrl-cs7542.c
@@ -0,0 +1,195 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/* Cortina Systems CS7542 GPIO/peripheral pin multiplexer */
+
+#include <linux/bits.h>
+#include <linux/err.h>
+#include <linux/mfd/syscon.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/platform_device.h>
+#include <linux/regmap.h>
+#include <linux/slab.h>
+
+#include <linux/pinctrl/pinconf-generic.h>
+#include <linux/pinctrl/pinctrl.h>
+#include <linux/pinctrl/pinmux.h>
+
+#include "pinctrl-utils.h"
+
+#define CS7542_GPIO_MUX		0x1c
+#define CS7542_NUM_PINS		160
+#define CS7542_UART_FIRST	72
+#define CS7542_UART_LAST	77
+
+enum cs7542_function {
+	CS7542_FUNCTION_GPIO,
+	CS7542_FUNCTION_UART,
+};
+
+struct cs7542_pinctrl {
+	struct regmap *map;
+	struct pinctrl_desc desc;
+	struct pinctrl_pin_desc pins[CS7542_NUM_PINS];
+	const char *groups[CS7542_NUM_PINS];
+};
+
+static const char * const cs7542_functions[] = { "gpio", "uart" };
+static const char * const cs7542_uart_groups[] = {
+	"gpio72", "gpio73", "gpio74", "gpio75", "gpio76", "gpio77",
+};
+
+static int cs7542_get_groups_count(struct pinctrl_dev *pctldev)
+{
+	return CS7542_NUM_PINS;
+}
+
+static const char *cs7542_get_group_name(struct pinctrl_dev *pctldev,
+					 unsigned int group)
+{
+	struct cs7542_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);
+
+	return pctl->groups[group];
+}
+
+static int cs7542_get_group_pins(struct pinctrl_dev *pctldev,
+				 unsigned int group, const unsigned int **pins,
+				 unsigned int *num_pins)
+{
+	struct cs7542_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);
+
+	*pins = &pctl->pins[group].number;
+	*num_pins = 1;
+	return 0;
+}
+
+static const struct pinctrl_ops cs7542_pinctrl_ops = {
+	.get_groups_count = cs7542_get_groups_count,
+	.get_group_name = cs7542_get_group_name,
+	.get_group_pins = cs7542_get_group_pins,
+	.dt_node_to_map = pinconf_generic_dt_node_to_map_pin,
+	.dt_free_map = pinctrl_utils_free_map,
+};
+
+static int cs7542_get_functions_count(struct pinctrl_dev *pctldev)
+{
+	return ARRAY_SIZE(cs7542_functions);
+}
+
+static const char *cs7542_get_function_name(struct pinctrl_dev *pctldev,
+					    unsigned int function)
+{
+	return cs7542_functions[function];
+}
+
+static int cs7542_get_function_groups(struct pinctrl_dev *pctldev,
+				      unsigned int function,
+				      const char * const **groups,
+				      unsigned int *num_groups)
+{
+	struct cs7542_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);
+
+	if (function == CS7542_FUNCTION_GPIO) {
+		*groups = pctl->groups;
+		*num_groups = CS7542_NUM_PINS;
+	} else {
+		*groups = cs7542_uart_groups;
+		*num_groups = ARRAY_SIZE(cs7542_uart_groups);
+	}
+	return 0;
+}
+
+static int cs7542_set_mux(struct pinctrl_dev *pctldev, unsigned int function,
+			  unsigned int group)
+{
+	struct cs7542_pinctrl *pctl = pinctrl_dev_get_drvdata(pctldev);
+	unsigned int mask;
+
+	if (group >= CS7542_NUM_PINS || function >= ARRAY_SIZE(cs7542_functions))
+		return -EINVAL;
+	if (function == CS7542_FUNCTION_UART &&
+	    (group < CS7542_UART_FIRST || group > CS7542_UART_LAST))
+		return -EINVAL;
+
+	mask = BIT(group % 32);
+	return regmap_update_bits(pctl->map, CS7542_GPIO_MUX + (group / 32) * 4,
+				  mask, function == CS7542_FUNCTION_GPIO ? mask : 0);
+}
+
+static int cs7542_gpio_request_enable(struct pinctrl_dev *pctldev,
+				      struct pinctrl_gpio_range *range,
+				      unsigned int pin)
+{
+	return cs7542_set_mux(pctldev, CS7542_FUNCTION_GPIO, pin);
+}
+
+static bool cs7542_function_is_gpio(struct pinctrl_dev *pctldev,
+				    unsigned int selector)
+{
+	return selector == CS7542_FUNCTION_GPIO;
+}
+
+static const struct pinmux_ops cs7542_pinmux_ops = {
+	.get_functions_count = cs7542_get_functions_count,
+	.get_function_name = cs7542_get_function_name,
+	.get_function_groups = cs7542_get_function_groups,
+	.function_is_gpio = cs7542_function_is_gpio,
+	.set_mux = cs7542_set_mux,
+	.gpio_request_enable = cs7542_gpio_request_enable,
+	.strict = true,
+};
+
+static int cs7542_pinctrl_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct cs7542_pinctrl *pctl;
+	struct pinctrl_dev *pctldev;
+	unsigned int i;
+	int ret;
+
+	pctl = devm_kzalloc(dev, sizeof(*pctl), GFP_KERNEL);
+	if (!pctl)
+		return -ENOMEM;
+
+	pctl->map = syscon_node_to_regmap(dev->of_node->parent);
+	if (IS_ERR(pctl->map))
+		return dev_err_probe(dev, PTR_ERR(pctl->map), "cannot get global regmap\n");
+
+	for (i = 0; i < CS7542_NUM_PINS; i++) {
+		pctl->groups[i] = devm_kasprintf(dev, GFP_KERNEL, "gpio%u", i);
+		if (!pctl->groups[i])
+			return -ENOMEM;
+		pctl->pins[i].number = i;
+		pctl->pins[i].name = pctl->groups[i];
+	}
+
+	pctl->desc.name = dev_name(dev);
+	pctl->desc.owner = THIS_MODULE;
+	pctl->desc.pins = pctl->pins;
+	pctl->desc.npins = CS7542_NUM_PINS;
+	pctl->desc.pctlops = &cs7542_pinctrl_ops;
+	pctl->desc.pmxops = &cs7542_pinmux_ops;
+
+	ret = devm_pinctrl_register_and_init(dev, &pctl->desc, pctl, &pctldev);
+	if (ret)
+		return dev_err_probe(dev, ret, "cannot register pin controller\n");
+
+	return pinctrl_enable(pctldev);
+}
+
+static const struct of_device_id cs7542_pinctrl_match[] = {
+	{ .compatible = "cortina,cs7542-pinctrl" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, cs7542_pinctrl_match);
+
+static struct platform_driver cs7542_pinctrl_driver = {
+	.probe = cs7542_pinctrl_probe,
+	.driver = {
+		.name = "cs7542-pinctrl",
+		.of_match_table = cs7542_pinctrl_match,
+	},
+};
+module_platform_driver(cs7542_pinctrl_driver);
+
+MODULE_DESCRIPTION("Cortina Systems CS7542 pin multiplexer");
+MODULE_LICENSE("GPL");

-- 
2.53.0

