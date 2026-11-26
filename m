From: Han Gao <gaohan@iscas.ac.cn>
Date: Thu, 26 Nov 2026 21:41:12 +0800
Subject: [PATCH v2 4/4] pinctrl: sunxi: add support for the Allwinner V861
 R-PIO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-v861-pinctrl-v2-4-b1875a6a9bb8@iscas.ac.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795700469; l=3434;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=2XU7vateLWk9YQRUatN0AylVhwFzxYjWU4A9VGpze8I=;
 b=O0H+bn2Dq5Sb76ZGsyddpbqllcunAK8tkbjlJJtnD/6x1d9dfI94gvMNk+8GecCPdeEbEL6gw
 zmZUjuq4ldABw/p7SDvwGam2C79Qr796BsX/XFdlCREK0vrVLFsCVIa
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the V861 always-on pin controller driver, using the DT based
function tables. The manual calls it RTC_GPIO.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 drivers/pinctrl/sunxi/Kconfig                  | 10 ++++++
 drivers/pinctrl/sunxi/Makefile                 |  1 +
 drivers/pinctrl/sunxi/pinctrl-sun252i-v861-r.c | 47 ++++++++++++++++++++++++++
 3 files changed, 58 insertions(+)

diff --git a/drivers/pinctrl/sunxi/Kconfig b/drivers/pinctrl/sunxi/Kconfig
index 2d5ace1e5f5f..80a53d3619d4 100644
--- a/drivers/pinctrl/sunxi/Kconfig
+++ b/drivers/pinctrl/sunxi/Kconfig
@@ -96,6 +96,16 @@ config PINCTRL_SUN252I_V861
 	  PA and PC to PH banks, and is required on boards based on this
 	  SoC.
 
+config PINCTRL_SUN252I_V861_R
+	bool "Support for the Allwinner V861 R-PIO"
+	default RISCV && ARCH_SUNXI
+	select PINCTRL_SUNXI
+	help
+	  Support for the always-on pin controller of the Allwinner V861
+	  SoC. It provides pin multiplexing, GPIOs and GPIO interrupts for
+	  the PL bank, and is required on boards based on this SoC.
+	  Say Y here if you are building a kernel for such a board.
+
 config PINCTRL_SUN50I_A64
 	bool "Support for the Allwinner A64 PIO"
 	default ARM64 && ARCH_SUNXI
diff --git a/drivers/pinctrl/sunxi/Makefile b/drivers/pinctrl/sunxi/Makefile
index dc7559e260e1..f3e601f61ce3 100644
--- a/drivers/pinctrl/sunxi/Makefile
+++ b/drivers/pinctrl/sunxi/Makefile
@@ -23,6 +23,7 @@ obj-$(CONFIG_PINCTRL_SUN8I_H3_R)	+= pinctrl-sun8i-h3-r.o
 obj-$(CONFIG_PINCTRL_SUN8I_V3S)		+= pinctrl-sun8i-v3s.o
 obj-$(CONFIG_PINCTRL_SUN20I_D1)		+= pinctrl-sun20i-d1.o
 obj-$(CONFIG_PINCTRL_SUN252I_V861)	+= pinctrl-sun252i-v861.o
+obj-$(CONFIG_PINCTRL_SUN252I_V861_R)	+= pinctrl-sun252i-v861-r.o
 obj-$(CONFIG_PINCTRL_SUN50I_H5)		+= pinctrl-sun50i-h5.o
 obj-$(CONFIG_PINCTRL_SUN50I_H6)		+= pinctrl-sun50i-h6.o
 obj-$(CONFIG_PINCTRL_SUN50I_H6_R)	+= pinctrl-sun50i-h6-r.o
diff --git a/drivers/pinctrl/sunxi/pinctrl-sun252i-v861-r.c b/drivers/pinctrl/sunxi/pinctrl-sun252i-v861-r.c
new file mode 100644
index 000000000000..57b2d0ef1e14
--- /dev/null
+++ b/drivers/pinctrl/sunxi/pinctrl-sun252i-v861-r.c
@@ -0,0 +1,47 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Allwinner V861 SoC r-pinctrl driver.
+ *
+ * Copyright (c) 2026 Han Gao <gaohan@iscas.ac.cn>
+ */
+
+#include <linux/platform_device.h>
+#include <linux/pinctrl/pinctrl.h>
+
+#include "pinctrl-sunxi.h"
+
+static const u8 v861_r_nr_bank_pins[SUNXI_PINCTRL_MAX_BANKS] =
+/*	  PL */
+	{  7 };
+
+static const u8 v861_r_irq_bank_muxes[SUNXI_PINCTRL_MAX_BANKS] =
+/*	  PL */
+	{ 14 };
+
+static struct sunxi_pinctrl_desc v861_r_pinctrl_data = {
+	.irq_banks = 1,
+	.irq_reg_base = 0x40,	/* PL_INT_CFG0 */
+	.pin_base = PL_BASE,
+};
+
+static int v861_r_pinctrl_probe(struct platform_device *pdev)
+{
+	return sunxi_pinctrl_dt_table_init(pdev, v861_r_nr_bank_pins,
+					   v861_r_irq_bank_muxes,
+					   &v861_r_pinctrl_data,
+					   SUNXI_PINCTRL_NCAT2_REG_LAYOUT);
+}
+
+static const struct of_device_id v861_r_pinctrl_match[] = {
+	{ .compatible = "allwinner,sun252i-v861-r-pinctrl" },
+	{ }
+};
+
+static struct platform_driver v861_r_pinctrl_driver = {
+	.probe	= v861_r_pinctrl_probe,
+	.driver	= {
+		.name		= "sun252i-v861-r-pinctrl",
+		.of_match_table	= v861_r_pinctrl_match,
+	},
+};
+builtin_platform_driver(v861_r_pinctrl_driver);

-- 
2.55.0

