From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 14 Nov 2026 06:33:41 +0800
Subject: [PATCH 15/19] pinctrl: sunxi: add support for the Allwinner V861
 R-PIO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-v861-v1-15-eb71ec3ee523@iscas.ac.cn>
References: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
In-Reply-To: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Guo Ren <guoren@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Han Gao <gaohan@iscas.ac.cn>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Maxime Ripard <mripard@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: Han Gao <rabenda.cn@gmail.com>, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-csky@vger.kernel.org, 
 linux-sunxi@lists.linux.dev, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rtc@vger.kernel.org, 
 linux-gpio@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794609209; l=3471;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=7xONjG+lp46a2hTV2q5H0YzzfrAGY6ULMHzpssbSP/k=;
 b=/oFgWs5YN9Op9atdNmxvGndgT/Pdy+xc5IyN8DLmLOkLQ4P2/EExPX6dzuj9XgE8LlgdjUcK8
 leKgDoRdJmDCL2FkiNczbYcllswSsNf8Mr4q1HKTVAWfI8lYvws8gnd
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
 drivers/pinctrl/sunxi/pinctrl-sun252i-v861-r.c | 48 ++++++++++++++++++++++++++
 3 files changed, 59 insertions(+)

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
index 000000000000..fef0ed2e2684
--- /dev/null
+++ b/drivers/pinctrl/sunxi/pinctrl-sun252i-v861-r.c
@@ -0,0 +1,48 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Allwinner V861 SoC r-pinctrl driver.
+ *
+ * Copyright (c) 2026 Han Gao <gaohan@iscas.ac.cn>
+ */
+
+#include <linux/mod_devicetable.h>
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
+	{ .compatible = "allwinner,sun252i-v861-r-pinctrl", },
+	{}
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

