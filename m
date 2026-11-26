From: Han Gao <gaohan@iscas.ac.cn>
Date: Thu, 26 Nov 2026 21:41:11 +0800
Subject: [PATCH v2 3/4] pinctrl: sunxi: add support for the Allwinner V861
 PIO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-v861-pinctrl-v2-3-b1875a6a9bb8@iscas.ac.cn>
References: <20261126-v861-pinctrl-v2-0-b1875a6a9bb8@iscas.ac.cn>
In-Reply-To: <20261126-v861-pinctrl-v2-0-b1875a6a9bb8@iscas.ac.cn>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795700469; l=3594;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=nN8xYmDYcv3N9AFviBCLM+CGuBvP/TwudQVXeShFtXg=;
 b=l8SVdVOwUKOtdCSxeA4xzNd64+UVrZVIB64NuTsTnvX4uo+ITwlRMRQYzZD+KANVA740ajOjE
 LTJPUQgVLrLCzaFZHryRQeiVKk6XI5AiX7O7THXdR+Y/A0yxNlkcQF1
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the V861 main pin controller driver, using the DT based function
tables.

The 1.8 V mode of bank PF is not supported, as none of the existing I/O
bias variants handles its control register.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 drivers/pinctrl/sunxi/Kconfig                | 10 ++++++
 drivers/pinctrl/sunxi/Makefile               |  1 +
 drivers/pinctrl/sunxi/pinctrl-sun252i-v861.c | 48 ++++++++++++++++++++++++++++
 3 files changed, 59 insertions(+)

diff --git a/drivers/pinctrl/sunxi/Kconfig b/drivers/pinctrl/sunxi/Kconfig
index 831bb1dc9373..2d5ace1e5f5f 100644
--- a/drivers/pinctrl/sunxi/Kconfig
+++ b/drivers/pinctrl/sunxi/Kconfig
@@ -86,6 +86,16 @@ config PINCTRL_SUN20I_D1
 	default MACH_SUN8I || (RISCV && ARCH_SUNXI)
 	select PINCTRL_SUNXI
 
+config PINCTRL_SUN252I_V861
+	bool "Support for the Allwinner V861 PIO"
+	default RISCV && ARCH_SUNXI
+	select PINCTRL_SUNXI
+	help
+	  Support for the main pin controller of the Allwinner V861 SoC.
+	  It provides pin multiplexing, GPIOs and GPIO interrupts for the
+	  PA and PC to PH banks, and is required on boards based on this
+	  SoC.
+
 config PINCTRL_SUN50I_A64
 	bool "Support for the Allwinner A64 PIO"
 	default ARM64 && ARCH_SUNXI
diff --git a/drivers/pinctrl/sunxi/Makefile b/drivers/pinctrl/sunxi/Makefile
index 3658c9d06b49..dc7559e260e1 100644
--- a/drivers/pinctrl/sunxi/Makefile
+++ b/drivers/pinctrl/sunxi/Makefile
@@ -22,6 +22,7 @@ obj-$(CONFIG_PINCTRL_SUN8I_H3)		+= pinctrl-sun8i-h3.o
 obj-$(CONFIG_PINCTRL_SUN8I_H3_R)	+= pinctrl-sun8i-h3-r.o
 obj-$(CONFIG_PINCTRL_SUN8I_V3S)		+= pinctrl-sun8i-v3s.o
 obj-$(CONFIG_PINCTRL_SUN20I_D1)		+= pinctrl-sun20i-d1.o
+obj-$(CONFIG_PINCTRL_SUN252I_V861)	+= pinctrl-sun252i-v861.o
 obj-$(CONFIG_PINCTRL_SUN50I_H5)		+= pinctrl-sun50i-h5.o
 obj-$(CONFIG_PINCTRL_SUN50I_H6)		+= pinctrl-sun50i-h6.o
 obj-$(CONFIG_PINCTRL_SUN50I_H6_R)	+= pinctrl-sun50i-h6-r.o
diff --git a/drivers/pinctrl/sunxi/pinctrl-sun252i-v861.c b/drivers/pinctrl/sunxi/pinctrl-sun252i-v861.c
new file mode 100644
index 000000000000..b133da6ddf8f
--- /dev/null
+++ b/drivers/pinctrl/sunxi/pinctrl-sun252i-v861.c
@@ -0,0 +1,48 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Allwinner V861 SoC pinctrl driver.
+ *
+ * Copyright (c) 2026 Han Gao <gaohan@iscas.ac.cn>
+ */
+
+#include <linux/platform_device.h>
+#include <linux/pinctrl/pinctrl.h>
+
+#include "pinctrl-sunxi.h"
+
+static const u8 v861_nr_bank_pins[SUNXI_PINCTRL_MAX_BANKS] =
+/*	  PA  PB  PC  PD  PE  PF  PG  PH */
+	{ 22,  0, 12, 23, 18,  7,  8, 16 };
+
+static const unsigned int v861_irq_bank_map[] = { 0, 2, 3, 4, 5, 6, 7 };
+
+static const u8 v861_irq_bank_muxes[SUNXI_PINCTRL_MAX_BANKS] =
+/*	  PA  PB  PC  PD  PE  PF  PG  PH */
+	{ 14,  0, 14, 14, 14, 14, 14, 14 };
+
+static struct sunxi_pinctrl_desc v861_pinctrl_data = {
+	.irq_banks = ARRAY_SIZE(v861_irq_bank_map),
+	.irq_bank_map = v861_irq_bank_map,
+};
+
+static int v861_pinctrl_probe(struct platform_device *pdev)
+{
+	return sunxi_pinctrl_dt_table_init(pdev, v861_nr_bank_pins,
+					   v861_irq_bank_muxes,
+					   &v861_pinctrl_data,
+					   SUNXI_PINCTRL_NCAT2_REG_LAYOUT);
+}
+
+static const struct of_device_id v861_pinctrl_match[] = {
+	{ .compatible = "allwinner,sun252i-v861-pinctrl" },
+	{ }
+};
+
+static struct platform_driver v861_pinctrl_driver = {
+	.probe	= v861_pinctrl_probe,
+	.driver	= {
+		.name		= "sun252i-v861-pinctrl",
+		.of_match_table	= v861_pinctrl_match,
+	},
+};
+builtin_platform_driver(v861_pinctrl_driver);

-- 
2.55.0

