From: Long Zhao <longzhao@ambarella.com>
Date: Tue, 15 Sep 2026 19:15:42 +0800
Subject: [PATCH v7 12/15] pinctrl: ambarella: add CV75 pin controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-cv75-v5-v7-12-3297d3fbc9c0@ambarella.com>
References: <20260915-cv75-v5-v7-0-3297d3fbc9c0@ambarella.com>
In-Reply-To: <20260915-cv75-v5-v7-0-3297d3fbc9c0@ambarella.com>
To: Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, soc@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org
Cc: Long Zhao <longzhao@ambarella.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Jerome Brunet <jbrunet@baylibre.com>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Long Zhao <zl020895@163.com>, Lee Jones <lee@kernel.org>, 
 mfd@lists.linux.dev, devicetree@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789470938; l=35629;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=dClZj8UvVy55/J2SmC1vDYMFckFC2D1EN9qKeSem5/k=;
 b=WnkxNfhHn5kRmTl7dr44SO36s8wio4Dq8jqYvyIUNkdo9X7vLo8PahU8lWkGrnficZtiZYG6C
 W9GayuKthoqBE6pZ0aiaTtvZs+D6UMU9d9UnWULlriOc5oYKZkfYEuS
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an Ambarella pinmux-only pinctrl driver with CV75 function/group
tables. GPIO is handled by the PL061 driver.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 drivers/pinctrl/Kconfig                  |  17 +
 drivers/pinctrl/Makefile                 |   2 +
 drivers/pinctrl/pinctrl-ambarella-cv75.c | 554 +++++++++++++++++++++++++++++++
 drivers/pinctrl/pinctrl-ambarella.c      | 554 +++++++++++++++++++++++++++++++
 drivers/pinctrl/pinctrl-ambarella.h      |  44 +++
 5 files changed, 1171 insertions(+)

diff --git a/drivers/pinctrl/Kconfig b/drivers/pinctrl/Kconfig
index c2cdd7b2c49b..08fbe3dc041b 100644
--- a/drivers/pinctrl/Kconfig
+++ b/drivers/pinctrl/Kconfig
@@ -37,6 +37,23 @@ config DEBUG_PINCTRL
 	help
 	  Say Y here to add some extra checks and diagnostics to PINCTRL calls.
 
+config PINCTRL_AMB
+	bool "Ambarella pin controller support"
+	depends on ARCH_AMBARELLA || COMPILE_TEST
+	depends on HAS_IOMEM
+	default y if ARCH_AMBARELLA
+	select GENERIC_PINCONF
+	select GENERIC_PINCTRL_GROUPS
+	select GENERIC_PINMUX_FUNCTIONS
+	select GPIOLIB
+	select GPIO_PL061
+	select MFD_SYSCON
+	select PINCONF
+	select PINMUX
+	help
+	  Say Y here to enable the Ambarella pinmux/pinconf controller.
+	  GPIO is provided by the PL061 driver.
+
 config PINCTRL_AMD
 	bool "AMD GPIO pin control"
 	depends on HAS_IOMEM
diff --git a/drivers/pinctrl/Makefile b/drivers/pinctrl/Makefile
index a35d71135abf..ce0825f4fc1b 100644
--- a/drivers/pinctrl/Makefile
+++ b/drivers/pinctrl/Makefile
@@ -10,6 +10,8 @@ obj-$(CONFIG_GENERIC_PINCONF)	+= pinconf-generic.o
 obj-$(CONFIG_GENERIC_PINCTRL)	+= pinctrl-generic.o
 obj-$(CONFIG_OF)		+= devicetree.o
 
+obj-$(CONFIG_PINCTRL_AMB)	+= pinctrl-ambarella.o
+obj-$(CONFIG_PINCTRL_AMB)	+= pinctrl-ambarella-cv75.o
 obj-$(CONFIG_PINCTRL_AMD)	+= pinctrl-amd.o
 obj-$(CONFIG_PINCTRL_AMDISP)	+= pinctrl-amdisp.o
 obj-$(CONFIG_PINCTRL_APPLE_GPIO) += pinctrl-apple-gpio.o
diff --git a/drivers/pinctrl/pinctrl-ambarella-cv75.c b/drivers/pinctrl/pinctrl-ambarella-cv75.c
new file mode 100644
index 000000000000..7db03bb60c15
--- /dev/null
+++ b/drivers/pinctrl/pinctrl-ambarella-cv75.c
@@ -0,0 +1,554 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Ambarella CV75 pinctrl data
+ *
+ * Copyright (C) 2026, Ambarella, Inc.
+ */
+
+#include <linux/array_size.h>
+#include <linux/types.h>
+
+#include <linux/pinctrl/pinctrl.h>
+
+#include "pinctrl-ambarella.h"
+
+#define CV75_PINMUX_GROUP(_name, ...)					\
+	static const u32 cv75_##_name##_pinmux[] = { __VA_ARGS__ }
+
+#define CV75_GROUP(_name)						\
+	{								\
+		.name = #_name,						\
+		.mux = cv75_##_name##_pinmux,				\
+		.nmux = ARRAY_SIZE(cv75_##_name##_pinmux),		\
+	}
+
+#define CV75_FUNCTION(_name)						\
+	PINCTRL_PINFUNCTION(#_name, cv75_##_name##_groups,		\
+			    ARRAY_SIZE(cv75_##_name##_groups))
+
+/* UART */
+CV75_PINMUX_GROUP(uart0, AMBA_PINMUX(44, 1), AMBA_PINMUX(45, 1));
+CV75_PINMUX_GROUP(uart1, AMBA_PINMUX(46, 1), AMBA_PINMUX(47, 1));
+CV75_PINMUX_GROUP(uart1_flow, AMBA_PINMUX(48, 1), AMBA_PINMUX(49, 1));
+CV75_PINMUX_GROUP(uart2_a, AMBA_PINMUX(46, 2), AMBA_PINMUX(47, 2));
+CV75_PINMUX_GROUP(uart2_b, AMBA_PINMUX(50, 2), AMBA_PINMUX(51, 2));
+CV75_PINMUX_GROUP(uart2_c, AMBA_PINMUX(66, 2), AMBA_PINMUX(68, 2));
+CV75_PINMUX_GROUP(uart2_flow_a, AMBA_PINMUX(48, 2), AMBA_PINMUX(49, 2));
+CV75_PINMUX_GROUP(uart2_flow_b, AMBA_PINMUX(65, 3), AMBA_PINMUX(67, 3));
+CV75_PINMUX_GROUP(uart3_a, AMBA_PINMUX(70, 3), AMBA_PINMUX(72, 3));
+CV75_PINMUX_GROUP(uart3_b, AMBA_PINMUX(80, 3), AMBA_PINMUX(79, 3));
+CV75_PINMUX_GROUP(uart3_flow_a, AMBA_PINMUX(71, 3), AMBA_PINMUX(69, 3));
+CV75_PINMUX_GROUP(uart3_flow_b, AMBA_PINMUX(81, 3), AMBA_PINMUX(82, 3));
+CV75_PINMUX_GROUP(uart4_a, AMBA_PINMUX(29, 3), AMBA_PINMUX(30, 3));
+CV75_PINMUX_GROUP(uart4_b, AMBA_PINMUX(76, 3), AMBA_PINMUX(77, 3));
+CV75_PINMUX_GROUP(uart4_flow_a, AMBA_PINMUX(28, 3), AMBA_PINMUX(31, 3));
+CV75_PINMUX_GROUP(uart4_flow_b, AMBA_PINMUX(74, 3), AMBA_PINMUX(75, 3));
+
+/* Flash */
+CV75_PINMUX_GROUP(snand, AMBA_PINMUX(79, 1), AMBA_PINMUX(80, 1),
+		  AMBA_PINMUX(81, 1), AMBA_PINMUX(82, 1),
+		  AMBA_PINMUX(83, 1), AMBA_PINMUX(84, 1));
+CV75_PINMUX_GROUP(spinor, AMBA_PINMUX(79, 2), AMBA_PINMUX(80, 2),
+		  AMBA_PINMUX(81, 2), AMBA_PINMUX(82, 2),
+		  AMBA_PINMUX(83, 2), AMBA_PINMUX(84, 2),
+		  AMBA_PINMUX(85, 2));
+
+/* SD/MMC */
+CV75_PINMUX_GROUP(sdmmc0_cd, AMBA_PINMUX(6, 1));
+CV75_PINMUX_GROUP(sdmmc0_wp, AMBA_PINMUX(7, 1));
+CV75_PINMUX_GROUP(sdmmc0_reset, AMBA_PINMUX(8, 1));
+CV75_PINMUX_GROUP(sdmmc0_hs_sel, AMBA_PINMUX(93, 1));
+CV75_PINMUX_GROUP(sdmmc0_1bit, AMBA_PINMUX(0, 1), AMBA_PINMUX(4, 1),
+		  AMBA_PINMUX(5, 1));
+CV75_PINMUX_GROUP(sdmmc0_4bit, AMBA_PINMUX(0, 1), AMBA_PINMUX(1, 1),
+		  AMBA_PINMUX(2, 1), AMBA_PINMUX(3, 1),
+		  AMBA_PINMUX(4, 1), AMBA_PINMUX(5, 1));
+CV75_PINMUX_GROUP(sdmmc1_cd, AMBA_PINMUX(15, 1));
+CV75_PINMUX_GROUP(sdmmc1_wp, AMBA_PINMUX(16, 1));
+CV75_PINMUX_GROUP(sdmmc1_reset, AMBA_PINMUX(17, 1));
+CV75_PINMUX_GROUP(sdmmc1_hs_sel, AMBA_PINMUX(94, 1));
+CV75_PINMUX_GROUP(sdmmc1_1bit, AMBA_PINMUX(9, 1), AMBA_PINMUX(13, 1),
+		  AMBA_PINMUX(14, 1));
+CV75_PINMUX_GROUP(sdmmc1_4bit, AMBA_PINMUX(9, 1), AMBA_PINMUX(10, 1),
+		  AMBA_PINMUX(11, 1), AMBA_PINMUX(12, 1),
+		  AMBA_PINMUX(13, 1), AMBA_PINMUX(14, 1));
+
+/* Ethernet */
+CV75_PINMUX_GROUP(enet_ext_osc_clk, AMBA_PINMUX(77, 1));
+CV75_PINMUX_GROUP(enet_2nd_ref_clk_a, AMBA_PINMUX(78, 1));
+CV75_PINMUX_GROUP(enet_2nd_ref_clk_b, AMBA_PINMUX(76, 2));
+CV75_PINMUX_GROUP(enet0_ptp_pps_o, AMBA_PINMUX(74, 1));
+CV75_PINMUX_GROUP(rgmii0, AMBA_PINMUX(62, 1), AMBA_PINMUX(63, 1),
+		  AMBA_PINMUX(64, 1), AMBA_PINMUX(65, 1),
+		  AMBA_PINMUX(66, 1), AMBA_PINMUX(67, 1),
+		  AMBA_PINMUX(68, 1), AMBA_PINMUX(69, 1),
+		  AMBA_PINMUX(70, 1), AMBA_PINMUX(71, 1),
+		  AMBA_PINMUX(72, 1), AMBA_PINMUX(73, 1),
+		  AMBA_PINMUX(75, 1), AMBA_PINMUX(76, 1));
+CV75_PINMUX_GROUP(rmii0, AMBA_PINMUX(62, 1), AMBA_PINMUX(63, 1),
+		  AMBA_PINMUX(64, 1), AMBA_PINMUX(67, 1),
+		  AMBA_PINMUX(68, 1), AMBA_PINMUX(71, 1),
+		  AMBA_PINMUX(72, 1), AMBA_PINMUX(73, 1),
+		  AMBA_PINMUX(75, 2));
+
+/* I2C */
+CV75_PINMUX_GROUP(i2c0_a, AMBA_PINMUX(67, 2), AMBA_PINMUX(68, 2));
+CV75_PINMUX_GROUP(i2c0_b, AMBA_PINMUX(86, 1), AMBA_PINMUX(87, 1));
+CV75_PINMUX_GROUP(i2c1_a, AMBA_PINMUX(22, 2), AMBA_PINMUX(23, 2));
+CV75_PINMUX_GROUP(i2c1_b, AMBA_PINMUX(69, 2), AMBA_PINMUX(70, 2));
+CV75_PINMUX_GROUP(i2c2, AMBA_PINMUX(88, 1), AMBA_PINMUX(89, 1));
+CV75_PINMUX_GROUP(i2c3_a, AMBA_PINMUX(24, 2), AMBA_PINMUX(25, 2));
+CV75_PINMUX_GROUP(i2c3_b, AMBA_PINMUX(48, 3), AMBA_PINMUX(49, 3));
+CV75_PINMUX_GROUP(i2c3_c, AMBA_PINMUX(58, 3), AMBA_PINMUX(59, 3));
+CV75_PINMUX_GROUP(i2cs_a, AMBA_PINMUX(19, 2), AMBA_PINMUX(21, 2));
+CV75_PINMUX_GROUP(i2cs_b, AMBA_PINMUX(60, 3), AMBA_PINMUX(61, 3));
+CV75_PINMUX_GROUP(i2cs_c, AMBA_PINMUX(71, 2), AMBA_PINMUX(72, 2));
+CV75_PINMUX_GROUP(i2cs_d, AMBA_PINMUX(86, 2), AMBA_PINMUX(87, 2));
+
+/* CAN, IR, WDT */
+CV75_PINMUX_GROUP(can0, AMBA_PINMUX(50, 1), AMBA_PINMUX(51, 1));
+CV75_PINMUX_GROUP(can1, AMBA_PINMUX(52, 1), AMBA_PINMUX(53, 1));
+CV75_PINMUX_GROUP(ir, AMBA_PINMUX(18, 1));
+CV75_PINMUX_GROUP(wdt_a, AMBA_PINMUX(20, 2));
+CV75_PINMUX_GROUP(wdt_b, AMBA_PINMUX(27, 3));
+CV75_PINMUX_GROUP(wdt_c, AMBA_PINMUX(39, 2));
+CV75_PINMUX_GROUP(wdt_d, AMBA_PINMUX(83, 3));
+CV75_PINMUX_GROUP(wdt_e, AMBA_PINMUX(85, 4));
+CV75_PINMUX_GROUP(wdt_f, AMBA_PINMUX(90, 1));
+
+/* I2S */
+CV75_PINMUX_GROUP(i2s0, AMBA_PINMUX(54, 1), AMBA_PINMUX(55, 1),
+		  AMBA_PINMUX(56, 1), AMBA_PINMUX(57, 1));
+CV75_PINMUX_GROUP(i2s1, AMBA_PINMUX(58, 1), AMBA_PINMUX(59, 1),
+		  AMBA_PINMUX(60, 1), AMBA_PINMUX(61, 1));
+CV75_PINMUX_GROUP(dmic0, AMBA_PINMUX(54, 2), AMBA_PINMUX(55, 2));
+
+/* PWM */
+CV75_PINMUX_GROUP(pwm0, AMBA_PINMUX(40, 1));
+CV75_PINMUX_GROUP(pwm1, AMBA_PINMUX(41, 1));
+CV75_PINMUX_GROUP(pwm2, AMBA_PINMUX(42, 1));
+CV75_PINMUX_GROUP(pwm3, AMBA_PINMUX(43, 1));
+CV75_PINMUX_GROUP(pwm4_a, AMBA_PINMUX(19, 3));
+CV75_PINMUX_GROUP(pwm4_b, AMBA_PINMUX(32, 4));
+CV75_PINMUX_GROUP(pwm5_a, AMBA_PINMUX(20, 3));
+CV75_PINMUX_GROUP(pwm5_b, AMBA_PINMUX(33, 4));
+CV75_PINMUX_GROUP(pwm6_a, AMBA_PINMUX(21, 3));
+CV75_PINMUX_GROUP(pwm6_b, AMBA_PINMUX(34, 4));
+CV75_PINMUX_GROUP(pwm7_a, AMBA_PINMUX(22, 3));
+CV75_PINMUX_GROUP(pwm7_b, AMBA_PINMUX(35, 4));
+CV75_PINMUX_GROUP(pwm8_a, AMBA_PINMUX(23, 3));
+CV75_PINMUX_GROUP(pwm8_b, AMBA_PINMUX(36, 4));
+CV75_PINMUX_GROUP(pwm9_a, AMBA_PINMUX(24, 3));
+CV75_PINMUX_GROUP(pwm9_b, AMBA_PINMUX(37, 4));
+CV75_PINMUX_GROUP(pwm10_a, AMBA_PINMUX(25, 3));
+CV75_PINMUX_GROUP(pwm10_b, AMBA_PINMUX(38, 4));
+CV75_PINMUX_GROUP(pwm11_a, AMBA_PINMUX(26, 3));
+CV75_PINMUX_GROUP(pwm11_b, AMBA_PINMUX(39, 4));
+
+/* SPI */
+CV75_PINMUX_GROUP(spi0, AMBA_PINMUX(19, 1), AMBA_PINMUX(20, 1),
+		  AMBA_PINMUX(21, 1));
+CV75_PINMUX_GROUP(spi1, AMBA_PINMUX(24, 1), AMBA_PINMUX(25, 1),
+		  AMBA_PINMUX(26, 1));
+CV75_PINMUX_GROUP(spi2, AMBA_PINMUX(28, 1), AMBA_PINMUX(29, 1),
+		  AMBA_PINMUX(30, 1));
+CV75_PINMUX_GROUP(spi3_a, AMBA_PINMUX(32, 5), AMBA_PINMUX(33, 5),
+		  AMBA_PINMUX(34, 5));
+CV75_PINMUX_GROUP(spi3_b, AMBA_PINMUX(40, 2), AMBA_PINMUX(41, 2),
+		  AMBA_PINMUX(43, 2));
+CV75_PINMUX_GROUP(spi3_c, AMBA_PINMUX(58, 2), AMBA_PINMUX(59, 2),
+		  AMBA_PINMUX(60, 2));
+CV75_PINMUX_GROUP(spi_slave_a, AMBA_PINMUX(24, 4), AMBA_PINMUX(25, 4),
+		  AMBA_PINMUX(26, 4), AMBA_PINMUX(27, 4));
+CV75_PINMUX_GROUP(spi_slave_b, AMBA_PINMUX(28, 2), AMBA_PINMUX(29, 2),
+		  AMBA_PINMUX(30, 2), AMBA_PINMUX(31, 2));
+CV75_PINMUX_GROUP(spi_slave_c, AMBA_PINMUX(36, 5), AMBA_PINMUX(37, 5),
+		  AMBA_PINMUX(38, 5), AMBA_PINMUX(39, 5));
+CV75_PINMUX_GROUP(spi_slave_d, AMBA_PINMUX(50, 3), AMBA_PINMUX(51, 3),
+		  AMBA_PINMUX(52, 3), AMBA_PINMUX(53, 3));
+CV75_PINMUX_GROUP(spi_slave_e, AMBA_PINMUX(81, 4), AMBA_PINMUX(82, 4),
+		  AMBA_PINMUX(83, 4), AMBA_PINMUX(84, 4));
+
+/* VIN master sync */
+CV75_PINMUX_GROUP(vin_master_sync_a, AMBA_PINMUX(91, 1),
+		  AMBA_PINMUX(92, 1));
+CV75_PINMUX_GROUP(vin_master_sync_b, AMBA_PINMUX(91, 2),
+		  AMBA_PINMUX(92, 2));
+CV75_PINMUX_GROUP(vin_master_sync_c, AMBA_PINMUX(40, 3),
+		  AMBA_PINMUX(41, 3));
+CV75_PINMUX_GROUP(vin_master_sync_d, AMBA_PINMUX(46, 3),
+		  AMBA_PINMUX(47, 3));
+CV75_PINMUX_GROUP(vin_master_sync_e, AMBA_PINMUX(79, 4),
+		  AMBA_PINMUX(80, 4));
+CV75_PINMUX_GROUP(vsync0, AMBA_PINMUX(32, 1));
+CV75_PINMUX_GROUP(vsync1, AMBA_PINMUX(33, 1));
+CV75_PINMUX_GROUP(vsync2, AMBA_PINMUX(34, 1));
+CV75_PINMUX_GROUP(vsync3, AMBA_PINMUX(35, 1));
+CV75_PINMUX_GROUP(hsync0, AMBA_PINMUX(36, 1));
+CV75_PINMUX_GROUP(hsync1, AMBA_PINMUX(37, 1));
+
+static const struct amb_pinmux_group cv75_pin_groups[] = {
+	CV75_GROUP(uart0),
+	CV75_GROUP(uart1), CV75_GROUP(uart1_flow),
+	CV75_GROUP(uart2_a), CV75_GROUP(uart2_b), CV75_GROUP(uart2_c),
+	CV75_GROUP(uart2_flow_a), CV75_GROUP(uart2_flow_b),
+	CV75_GROUP(uart3_a), CV75_GROUP(uart3_b),
+	CV75_GROUP(uart3_flow_a), CV75_GROUP(uart3_flow_b),
+	CV75_GROUP(uart4_a), CV75_GROUP(uart4_b),
+	CV75_GROUP(uart4_flow_a), CV75_GROUP(uart4_flow_b),
+	CV75_GROUP(snand), CV75_GROUP(spinor),
+	CV75_GROUP(sdmmc0_cd), CV75_GROUP(sdmmc0_wp),
+	CV75_GROUP(sdmmc0_reset), CV75_GROUP(sdmmc0_hs_sel),
+	CV75_GROUP(sdmmc0_1bit), CV75_GROUP(sdmmc0_4bit),
+	CV75_GROUP(sdmmc1_cd), CV75_GROUP(sdmmc1_wp),
+	CV75_GROUP(sdmmc1_reset), CV75_GROUP(sdmmc1_hs_sel),
+	CV75_GROUP(sdmmc1_1bit), CV75_GROUP(sdmmc1_4bit),
+	CV75_GROUP(enet_ext_osc_clk), CV75_GROUP(enet_2nd_ref_clk_a),
+	CV75_GROUP(enet_2nd_ref_clk_b), CV75_GROUP(enet0_ptp_pps_o),
+	CV75_GROUP(rgmii0), CV75_GROUP(rmii0),
+	CV75_GROUP(i2c0_a), CV75_GROUP(i2c0_b),
+	CV75_GROUP(i2c1_a), CV75_GROUP(i2c1_b), CV75_GROUP(i2c2),
+	CV75_GROUP(i2c3_a), CV75_GROUP(i2c3_b), CV75_GROUP(i2c3_c),
+	CV75_GROUP(i2cs_a), CV75_GROUP(i2cs_b),
+	CV75_GROUP(i2cs_c), CV75_GROUP(i2cs_d),
+	CV75_GROUP(can0), CV75_GROUP(can1), CV75_GROUP(ir),
+	CV75_GROUP(wdt_a), CV75_GROUP(wdt_b), CV75_GROUP(wdt_c),
+	CV75_GROUP(wdt_d), CV75_GROUP(wdt_e), CV75_GROUP(wdt_f),
+	CV75_GROUP(i2s0), CV75_GROUP(i2s1),
+	CV75_GROUP(dmic0),
+	CV75_GROUP(pwm0), CV75_GROUP(pwm1),
+	CV75_GROUP(pwm2), CV75_GROUP(pwm3),
+	CV75_GROUP(pwm4_a), CV75_GROUP(pwm4_b),
+	CV75_GROUP(pwm5_a), CV75_GROUP(pwm5_b),
+	CV75_GROUP(pwm6_a), CV75_GROUP(pwm6_b),
+	CV75_GROUP(pwm7_a), CV75_GROUP(pwm7_b),
+	CV75_GROUP(pwm8_a), CV75_GROUP(pwm8_b),
+	CV75_GROUP(pwm9_a), CV75_GROUP(pwm9_b),
+	CV75_GROUP(pwm10_a), CV75_GROUP(pwm10_b),
+	CV75_GROUP(pwm11_a), CV75_GROUP(pwm11_b),
+	CV75_GROUP(spi0), CV75_GROUP(spi1), CV75_GROUP(spi2),
+	CV75_GROUP(spi3_a), CV75_GROUP(spi3_b), CV75_GROUP(spi3_c),
+	CV75_GROUP(spi_slave_a), CV75_GROUP(spi_slave_b),
+	CV75_GROUP(spi_slave_c), CV75_GROUP(spi_slave_d),
+	CV75_GROUP(spi_slave_e),
+	CV75_GROUP(vin_master_sync_a), CV75_GROUP(vin_master_sync_b),
+	CV75_GROUP(vin_master_sync_c), CV75_GROUP(vin_master_sync_d),
+	CV75_GROUP(vin_master_sync_e),
+	CV75_GROUP(vsync0), CV75_GROUP(vsync1),
+	CV75_GROUP(vsync2), CV75_GROUP(vsync3),
+	CV75_GROUP(hsync0), CV75_GROUP(hsync1),
+};
+
+static const char * const cv75_uart0_groups[] = {
+	"uart0",
+};
+
+static const char * const cv75_uart1_groups[] = {
+	"uart1",
+	"uart1_flow",
+};
+
+static const char * const cv75_uart2_groups[] = {
+	"uart2_a",
+	"uart2_b",
+	"uart2_c",
+	"uart2_flow_a",
+	"uart2_flow_b",
+};
+
+static const char * const cv75_uart3_groups[] = {
+	"uart3_a",
+	"uart3_b",
+	"uart3_flow_a",
+	"uart3_flow_b",
+};
+
+static const char * const cv75_uart4_groups[] = {
+	"uart4_a",
+	"uart4_b",
+	"uart4_flow_a",
+	"uart4_flow_b",
+};
+
+static const char * const cv75_snand_groups[] = {
+	"snand",
+};
+
+static const char * const cv75_spinor_groups[] = {
+	"spinor",
+};
+
+static const char * const cv75_sdmmc0_groups[] = {
+	"sdmmc0_cd",
+	"sdmmc0_wp",
+	"sdmmc0_reset",
+	"sdmmc0_hs_sel",
+	"sdmmc0_1bit",
+	"sdmmc0_4bit",
+};
+
+static const char * const cv75_sdmmc1_groups[] = {
+	"sdmmc1_cd",
+	"sdmmc1_wp",
+	"sdmmc1_reset",
+	"sdmmc1_hs_sel",
+	"sdmmc1_1bit",
+	"sdmmc1_4bit",
+};
+
+static const char * const cv75_enet0_groups[] = {
+	"enet_ext_osc_clk",
+	"enet_2nd_ref_clk_a",
+	"enet_2nd_ref_clk_b",
+	"enet0_ptp_pps_o",
+	"rgmii0",
+	"rmii0",
+};
+
+static const char * const cv75_i2c0_groups[] = {
+	"i2c0_a",
+	"i2c0_b",
+};
+
+static const char * const cv75_i2c1_groups[] = {
+	"i2c1_a",
+	"i2c1_b",
+};
+
+static const char * const cv75_i2c2_groups[] = {
+	"i2c2",
+};
+
+static const char * const cv75_i2c3_groups[] = {
+	"i2c3_a",
+	"i2c3_b",
+	"i2c3_c",
+};
+
+static const char * const cv75_i2cs_groups[] = {
+	"i2cs_a",
+	"i2cs_b",
+	"i2cs_c",
+	"i2cs_d",
+};
+
+static const char * const cv75_can0_groups[] = {
+	"can0",
+};
+
+static const char * const cv75_can1_groups[] = {
+	"can1",
+};
+
+static const char * const cv75_ir_groups[] = {
+	"ir",
+};
+
+static const char * const cv75_wdt_groups[] = {
+	"wdt_a",
+	"wdt_b",
+	"wdt_c",
+	"wdt_d",
+	"wdt_e",
+	"wdt_f",
+};
+
+static const char * const cv75_i2s0_groups[] = {
+	"i2s0",
+};
+
+static const char * const cv75_i2s1_groups[] = {
+	"i2s1",
+};
+
+static const char * const cv75_dmic0_groups[] = {
+	"dmic0",
+};
+
+static const char * const cv75_pwm0_groups[] = {
+	"pwm0",
+};
+
+static const char * const cv75_pwm1_groups[] = {
+	"pwm1",
+};
+
+static const char * const cv75_pwm2_groups[] = {
+	"pwm2",
+};
+
+static const char * const cv75_pwm3_groups[] = {
+	"pwm3",
+};
+
+static const char * const cv75_pwm4_groups[] = {
+	"pwm4_a",
+	"pwm4_b",
+};
+
+static const char * const cv75_pwm5_groups[] = {
+	"pwm5_a",
+	"pwm5_b",
+};
+
+static const char * const cv75_pwm6_groups[] = {
+	"pwm6_a",
+	"pwm6_b",
+};
+
+static const char * const cv75_pwm7_groups[] = {
+	"pwm7_a",
+	"pwm7_b",
+};
+
+static const char * const cv75_pwm8_groups[] = {
+	"pwm8_a",
+	"pwm8_b",
+};
+
+static const char * const cv75_pwm9_groups[] = {
+	"pwm9_a",
+	"pwm9_b",
+};
+
+static const char * const cv75_pwm10_groups[] = {
+	"pwm10_a",
+	"pwm10_b",
+};
+
+static const char * const cv75_pwm11_groups[] = {
+	"pwm11_a",
+	"pwm11_b",
+};
+
+static const char * const cv75_spi0_groups[] = {
+	"spi0",
+};
+
+static const char * const cv75_spi1_groups[] = {
+	"spi1",
+};
+
+static const char * const cv75_spi2_groups[] = {
+	"spi2",
+};
+
+static const char * const cv75_spi3_groups[] = {
+	"spi3_a",
+	"spi3_b",
+	"spi3_c",
+};
+
+static const char * const cv75_spi_slave_groups[] = {
+	"spi_slave_a",
+	"spi_slave_b",
+	"spi_slave_c",
+	"spi_slave_d",
+	"spi_slave_e",
+};
+
+static const char * const cv75_vin_master_sync_groups[] = {
+	"vin_master_sync_a",
+	"vin_master_sync_b",
+	"vin_master_sync_c",
+	"vin_master_sync_d",
+	"vin_master_sync_e",
+};
+
+static const char * const cv75_vsync0_groups[] = {
+	"vsync0",
+};
+
+static const char * const cv75_vsync1_groups[] = {
+	"vsync1",
+};
+
+static const char * const cv75_vsync2_groups[] = {
+	"vsync2",
+};
+
+static const char * const cv75_vsync3_groups[] = {
+	"vsync3",
+};
+
+static const char * const cv75_hsync0_groups[] = {
+	"hsync0",
+};
+
+static const char * const cv75_hsync1_groups[] = {
+	"hsync1",
+};
+
+static const struct pinfunction cv75_pin_functions[] = {
+	CV75_FUNCTION(uart0),
+	CV75_FUNCTION(uart1),
+	CV75_FUNCTION(uart2),
+	CV75_FUNCTION(uart3),
+	CV75_FUNCTION(uart4),
+	CV75_FUNCTION(snand),
+	CV75_FUNCTION(spinor),
+	CV75_FUNCTION(sdmmc0),
+	CV75_FUNCTION(sdmmc1),
+	CV75_FUNCTION(enet0),
+	CV75_FUNCTION(i2c0),
+	CV75_FUNCTION(i2c1),
+	CV75_FUNCTION(i2c2),
+	CV75_FUNCTION(i2c3),
+	CV75_FUNCTION(i2cs),
+	CV75_FUNCTION(can0),
+	CV75_FUNCTION(can1),
+	CV75_FUNCTION(ir),
+	CV75_FUNCTION(wdt),
+	CV75_FUNCTION(i2s0),
+	CV75_FUNCTION(i2s1),
+	CV75_FUNCTION(dmic0),
+	CV75_FUNCTION(pwm0),
+	CV75_FUNCTION(pwm1),
+	CV75_FUNCTION(pwm2),
+	CV75_FUNCTION(pwm3),
+	CV75_FUNCTION(pwm4),
+	CV75_FUNCTION(pwm5),
+	CV75_FUNCTION(pwm6),
+	CV75_FUNCTION(pwm7),
+	CV75_FUNCTION(pwm8),
+	CV75_FUNCTION(pwm9),
+	CV75_FUNCTION(pwm10),
+	CV75_FUNCTION(pwm11),
+	CV75_FUNCTION(spi0),
+	CV75_FUNCTION(spi1),
+	CV75_FUNCTION(spi2),
+	CV75_FUNCTION(spi3),
+	CV75_FUNCTION(spi_slave),
+	CV75_FUNCTION(vin_master_sync),
+	CV75_FUNCTION(vsync0),
+	CV75_FUNCTION(vsync1),
+	CV75_FUNCTION(vsync2),
+	CV75_FUNCTION(vsync3),
+	CV75_FUNCTION(hsync0),
+	CV75_FUNCTION(hsync1),
+};
+
+const struct amb_pinctrl_data ambarella_cv75_pinctrl_data = {
+	.groups = cv75_pin_groups,
+	.functions = cv75_pin_functions,
+	.ngroups = ARRAY_SIZE(cv75_pin_groups),
+	.nfunctions = ARRAY_SIZE(cv75_pin_functions),
+	.nr_banks = 3,
+	.npins = 96,
+	.ds0 = {
+		0x314, 0x320, 0x32c,
+	},
+	.ds1 = {
+		0x318, 0x324, 0x330,
+	},
+	.ds2 = {
+		0x31c, 0x328, 0x334,
+	},
+	.pull_en = {
+		0x60, 0x64, 0x68,
+	},
+	.pull_dir = {
+		0x7c, 0x80, 0x84,
+	},
+	.have_ds2 = true,
+};
diff --git a/drivers/pinctrl/pinctrl-ambarella.c b/drivers/pinctrl/pinctrl-ambarella.c
new file mode 100644
index 000000000000..0186267a1eec
--- /dev/null
+++ b/drivers/pinctrl/pinctrl-ambarella.c
@@ -0,0 +1,554 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Pinctrl driver for Ambarella SoCs
+ *
+ * Copyright (C) 2012-2026, Ambarella, Inc.
+ */
+
+#include <linux/array_size.h>
+#include <linux/bits.h>
+#include <linux/device.h>
+#include <linux/err.h>
+#include <linux/errno.h>
+#include <linux/init.h>
+#include <linux/io.h>
+#include <linux/mfd/syscon.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/platform_device.h>
+#include <linux/regmap.h>
+#include <linux/slab.h>
+#include <linux/spinlock.h>
+#include <linux/types.h>
+
+#include <linux/pinctrl/pinconf-generic.h>
+#include <linux/pinctrl/pinconf.h>
+#include <linux/pinctrl/pinctrl.h>
+#include <linux/pinctrl/pinmux.h>
+
+#include "core.h"
+#include "pinmux.h"
+#include "pinctrl-ambarella.h"
+
+#define IOMUX_REG(bank, n)		(((bank) * 0xc) + ((n) * 4))
+#define IOMUX_CTRL_SET			0xf0
+
+#define PINID_TO_BANK(p)		((p) >> 5)
+#define PINID_TO_OFFSET(p)		((p) & 0x1f)
+
+struct amb_pinctrl {
+	struct pinctrl_desc desc;
+	void __iomem *iomux_base;
+	struct regmap *ds_regmap;
+	struct regmap *pull_regmap;
+	const struct amb_pinctrl_data *data;
+	struct device *dev;
+	struct pinctrl_dev *pctl;
+	spinlock_t lock;
+};
+
+static const int amb_ds1_ma[] = { 2, 4, 8, 12 };
+static const int amb_ds2_ma[] = { 3, 4, 6, 8, 9, 12 };
+
+static const struct pinctrl_ops amb_pctrl_ops = {
+	.get_groups_count	= pinctrl_generic_get_group_count,
+	.get_group_name		= pinctrl_generic_get_group_name,
+	.get_group_pins		= pinctrl_generic_get_group_pins,
+	.dt_node_to_map		= pinconf_generic_dt_node_to_map_all,
+	.dt_free_map		= pinconf_generic_dt_free_map,
+};
+
+static void amb_iomux_commit(struct amb_pinctrl *ipc)
+{
+	writel(0x1, ipc->iomux_base + IOMUX_CTRL_SET);
+	writel(0x0, ipc->iomux_base + IOMUX_CTRL_SET);
+}
+
+static void amb_pinmux_set_altfunc(struct amb_pinctrl *ipc, u32 bank,
+				   u32 offset, u32 altfunc)
+{
+	if (bank >= ipc->data->nr_banks)
+		return;
+
+	for (unsigned int i = 0; i < 3; i++) {
+		u32 data;
+
+		data = readl_relaxed(ipc->iomux_base + IOMUX_REG(bank, i));
+		data &= ~BIT(offset);
+		data |= ((altfunc >> i) & 1U) << offset;
+		writel_relaxed(data, ipc->iomux_base + IOMUX_REG(bank, i));
+	}
+}
+
+static int amb_pinmux_set_mux(struct pinctrl_dev *pctldev,
+			      unsigned int selector, unsigned int group)
+{
+	struct amb_pinctrl *ipc = pinctrl_dev_get_drvdata(pctldev);
+	struct group_desc *grp;
+	const u32 *mux;
+	unsigned long flags;
+
+	(void)selector;
+
+	grp = pinctrl_generic_get_group(pctldev, group);
+	if (!grp || !grp->data)
+		return -EINVAL;
+
+	mux = grp->data;
+
+	spin_lock_irqsave(&ipc->lock, flags);
+	for (unsigned int i = 0; i < grp->grp.npins; i++) {
+		u32 pin = AMBA_PINMUX_TO_PIN(mux[i]);
+		u32 alt = AMBA_PINMUX_TO_ALT(mux[i]);
+
+		amb_pinmux_set_altfunc(ipc, PINID_TO_BANK(pin),
+				       PINID_TO_OFFSET(pin), alt);
+	}
+	amb_iomux_commit(ipc);
+	spin_unlock_irqrestore(&ipc->lock, flags);
+
+	return 0;
+}
+
+static int amb_pinmux_gpio_request_enable(struct pinctrl_dev *pctldev,
+					  struct pinctrl_gpio_range *range,
+					  unsigned int pin)
+{
+	struct amb_pinctrl *ipc = pinctrl_dev_get_drvdata(pctldev);
+	unsigned long flags;
+
+	if (!range || !range->gc)
+		return -EINVAL;
+
+	if (pin >= ipc->data->npins)
+		return -EINVAL;
+
+	spin_lock_irqsave(&ipc->lock, flags);
+	amb_pinmux_set_altfunc(ipc, PINID_TO_BANK(pin), PINID_TO_OFFSET(pin), 0);
+	amb_iomux_commit(ipc);
+	spin_unlock_irqrestore(&ipc->lock, flags);
+
+	return 0;
+}
+
+static const struct pinmux_ops amb_pinmux_ops = {
+	.get_functions_count	= pinmux_generic_get_function_count,
+	.get_function_name	= pinmux_generic_get_function_name,
+	.get_function_groups	= pinmux_generic_get_function_groups,
+	.set_mux		= amb_pinmux_set_mux,
+	.gpio_request_enable	= amb_pinmux_gpio_request_enable,
+	.strict			= true,
+};
+
+static int amb_drive_strength_to_reg_ds1(u32 strength)
+{
+	for (unsigned int i = 0; i < ARRAY_SIZE(amb_ds1_ma); i++) {
+		if (amb_ds1_ma[i] == strength)
+			return i;
+	}
+
+	return -EINVAL;
+}
+
+static int amb_drive_strength_to_reg_ds2(u32 strength)
+{
+	/* Hardware steps are 3, 4, 6, 8, 9, 12 mA; 5 and 7 are accepted aliases */
+	if (strength == 5)
+		strength = 4;
+	else if (strength == 7)
+		strength = 8;
+
+	for (unsigned int i = 0; i < ARRAY_SIZE(amb_ds2_ma); i++) {
+		if (amb_ds2_ma[i] == strength)
+			return i;
+	}
+
+	return -EINVAL;
+}
+
+static int amb_drive_strength_to_reg(const struct amb_pinctrl *ipc, u32 strength)
+{
+	if (ipc->data->have_ds2)
+		return amb_drive_strength_to_reg_ds2(strength);
+
+	return amb_drive_strength_to_reg_ds1(strength);
+}
+
+static int amb_reg_to_drive_strength(const struct amb_pinctrl *ipc, u32 ds)
+{
+	if (ipc->data->have_ds2) {
+		if (ds >= ARRAY_SIZE(amb_ds2_ma))
+			return -EINVAL;
+		return amb_ds2_ma[ds];
+	}
+
+	if (ds >= ARRAY_SIZE(amb_ds1_ma))
+		return -EINVAL;
+
+	return amb_ds1_ma[ds];
+}
+
+static int amb_pinconf_set(struct pinctrl_dev *pctldev, unsigned int pin,
+			   unsigned long *configs, unsigned int num_configs)
+{
+	struct amb_pinctrl *ipc = pinctrl_dev_get_drvdata(pctldev);
+	u32 bank = PINID_TO_BANK(pin);
+	u32 offset = PINID_TO_OFFSET(pin);
+	int ret;
+
+	if (bank >= ipc->data->nr_banks)
+		return -EINVAL;
+
+	for (unsigned int i = 0; i < num_configs; i++) {
+		enum pin_config_param param = pinconf_to_config_param(configs[i]);
+		u32 arg = pinconf_to_config_argument(configs[i]);
+		int ds;
+
+		switch (param) {
+		case PIN_CONFIG_BIAS_DISABLE:
+			ret = regmap_update_bits(ipc->pull_regmap,
+						 ipc->data->pull_en[bank], BIT(offset), 0);
+			if (ret)
+				return ret;
+			break;
+		case PIN_CONFIG_BIAS_PULL_DOWN:
+		case PIN_CONFIG_BIAS_PULL_UP:
+			ret = regmap_update_bits(ipc->pull_regmap,
+						 ipc->data->pull_dir[bank], BIT(offset),
+						 (param == PIN_CONFIG_BIAS_PULL_UP) ?
+						 BIT(offset) : 0);
+			if (ret)
+				return ret;
+			ret = regmap_update_bits(ipc->pull_regmap,
+						 ipc->data->pull_en[bank], BIT(offset),
+						 BIT(offset));
+			if (ret)
+				return ret;
+			break;
+		case PIN_CONFIG_DRIVE_STRENGTH:
+			ds = amb_drive_strength_to_reg(ipc, arg);
+			if (ds < 0)
+				return ds;
+			if (ipc->data->have_ds2) {
+				ret = regmap_update_bits(ipc->ds_regmap,
+							 ipc->data->ds0[bank], BIT(offset),
+							 (ds & BIT(0)) ? BIT(offset) : 0);
+				if (ret)
+					return ret;
+				ret = regmap_update_bits(ipc->ds_regmap,
+							 ipc->data->ds1[bank], BIT(offset),
+							 (ds & BIT(1)) ? BIT(offset) : 0);
+				if (ret)
+					return ret;
+				ret = regmap_update_bits(ipc->ds_regmap,
+							 ipc->data->ds2[bank], BIT(offset),
+							 (ds & BIT(2)) ? BIT(offset) : 0);
+				if (ret)
+					return ret;
+			} else {
+				ret = regmap_update_bits(ipc->ds_regmap,
+							 ipc->data->ds0[bank], BIT(offset),
+							 (ds & BIT(1)) ? BIT(offset) : 0);
+				if (ret)
+					return ret;
+				ret = regmap_update_bits(ipc->ds_regmap,
+							 ipc->data->ds1[bank], BIT(offset),
+							 (ds & BIT(0)) ? BIT(offset) : 0);
+				if (ret)
+					return ret;
+			}
+			break;
+		default:
+			return -EOPNOTSUPP;
+		}
+	}
+
+	return 0;
+}
+
+static int amb_pinconf_group_set(struct pinctrl_dev *pctldev,
+				 unsigned int selector,
+				 unsigned long *configs,
+				 unsigned int num_configs)
+{
+	const unsigned int *pins;
+	unsigned int npins;
+	int ret;
+
+	ret = pinctrl_generic_get_group_pins(pctldev, selector, &pins, &npins);
+	if (ret)
+		return ret;
+
+	for (unsigned int i = 0; i < npins; i++) {
+		ret = amb_pinconf_set(pctldev, pins[i], configs, num_configs);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+static int amb_pinconf_get(struct pinctrl_dev *pctldev,
+			   unsigned int pin, unsigned long *config)
+{
+	struct amb_pinctrl *ipc = pinctrl_dev_get_drvdata(pctldev);
+	enum pin_config_param param = pinconf_to_config_param(*config);
+	u32 bank = PINID_TO_BANK(pin);
+	u32 offset = PINID_TO_OFFSET(pin);
+	u32 pull_en, pull_dir, ds0, ds1, ds2, ds;
+	int ret, strength;
+
+	if (bank >= ipc->data->nr_banks)
+		return -EINVAL;
+
+	switch (param) {
+	case PIN_CONFIG_BIAS_DISABLE:
+	case PIN_CONFIG_BIAS_PULL_DOWN:
+	case PIN_CONFIG_BIAS_PULL_UP:
+		ret = regmap_read(ipc->pull_regmap, ipc->data->pull_en[bank],
+				  &pull_en);
+		if (ret)
+			return ret;
+
+		ret = regmap_read(ipc->pull_regmap, ipc->data->pull_dir[bank],
+				  &pull_dir);
+		if (ret)
+			return ret;
+
+		pull_en = (pull_en >> offset) & 1;
+		pull_dir = (pull_dir >> offset) & 1;
+
+		if (param == PIN_CONFIG_BIAS_DISABLE) {
+			if (pull_en)
+				return -EINVAL;
+			*config = pinconf_to_config_packed(param, 0);
+			return 0;
+		}
+
+		if (!pull_en)
+			return -EINVAL;
+		if (param == PIN_CONFIG_BIAS_PULL_UP && !pull_dir)
+			return -EINVAL;
+		if (param == PIN_CONFIG_BIAS_PULL_DOWN && pull_dir)
+			return -EINVAL;
+
+		*config = pinconf_to_config_packed(param, 1);
+		return 0;
+
+	case PIN_CONFIG_DRIVE_STRENGTH:
+		ret = regmap_read(ipc->ds_regmap, ipc->data->ds0[bank], &ds0);
+		if (ret)
+			return ret;
+
+		ret = regmap_read(ipc->ds_regmap, ipc->data->ds1[bank], &ds1);
+		if (ret)
+			return ret;
+
+		ds0 = (ds0 >> offset) & 1;
+		ds1 = (ds1 >> offset) & 1;
+		if (ipc->data->have_ds2) {
+			ret = regmap_read(ipc->ds_regmap, ipc->data->ds2[bank],
+					  &ds2);
+			if (ret)
+				return ret;
+
+			ds2 = (ds2 >> offset) & 1;
+			ds = (ds2 << 2) | (ds1 << 1) | ds0;
+		} else {
+			ds = (ds0 << 1) | ds1;
+		}
+
+		strength = amb_reg_to_drive_strength(ipc, ds);
+		if (strength < 0)
+			return strength;
+
+		*config = pinconf_to_config_packed(param, strength);
+		return 0;
+
+	default:
+		return -EOPNOTSUPP;
+	}
+}
+
+static const struct pinconf_ops amb_pinconf_ops = {
+	.is_generic		= true,
+	.pin_config_get		= amb_pinconf_get,
+	.pin_config_set		= amb_pinconf_set,
+	.pin_config_group_set	= amb_pinconf_group_set,
+};
+
+static int amb_pinctrl_add_groups(struct amb_pinctrl *ipc)
+{
+	const struct amb_pinctrl_data *data = ipc->data;
+	unsigned int total_pins = 0;
+	unsigned int *pins;
+
+	for (unsigned int i = 0; i < data->ngroups; i++) {
+		const struct amb_pinmux_group *g = &data->groups[i];
+
+		if (!g->name || !g->mux || !g->nmux)
+			return -EINVAL;
+
+		total_pins += g->nmux;
+	}
+
+	pins = devm_kcalloc(ipc->dev, total_pins, sizeof(*pins), GFP_KERNEL);
+	if (!pins)
+		return -ENOMEM;
+
+	for (unsigned int i = 0; i < data->ngroups; i++) {
+		const struct amb_pinmux_group *g = &data->groups[i];
+		unsigned int *grp_pins = pins;
+		int ret;
+
+		for (unsigned int j = 0; j < g->nmux; j++) {
+			unsigned int pin = AMBA_PINMUX_TO_PIN(g->mux[j]);
+
+			if (pin >= data->npins)
+				return -EINVAL;
+
+			pins[j] = pin;
+		}
+
+		pins += g->nmux;
+
+		ret = pinctrl_generic_add_group(ipc->pctl, g->name, grp_pins,
+						g->nmux, (void *)(uintptr_t)g->mux);
+		if (ret < 0)
+			return ret;
+	}
+
+	return 0;
+}
+
+static int amb_pinctrl_add_functions(struct amb_pinctrl *ipc)
+{
+	const struct amb_pinctrl_data *data = ipc->data;
+
+	for (unsigned int i = 0; i < data->nfunctions; i++) {
+		int ret;
+
+		ret = pinmux_generic_add_pinfunction(ipc->pctl,
+						     &data->functions[i], NULL);
+		if (ret < 0)
+			return ret;
+	}
+
+	return 0;
+}
+
+static int amb_pinctrl_register(struct amb_pinctrl *ipc)
+{
+	struct pinctrl_pin_desc *pindesc;
+	int ret;
+
+	pindesc = devm_kcalloc(ipc->dev, ipc->data->npins, sizeof(*pindesc),
+			       GFP_KERNEL);
+	if (!pindesc)
+		return -ENOMEM;
+
+	for (unsigned int pin = 0; pin < ipc->data->npins; pin++) {
+		pindesc[pin].number = pin;
+		pindesc[pin].name = devm_kasprintf(ipc->dev, GFP_KERNEL,
+						   "io%u", pin);
+		if (!pindesc[pin].name)
+			return -ENOMEM;
+	}
+
+	ipc->desc.name = dev_name(ipc->dev);
+	ipc->desc.pins = pindesc;
+	ipc->desc.npins = ipc->data->npins;
+	ipc->desc.pctlops = &amb_pctrl_ops;
+	ipc->desc.pmxops = &amb_pinmux_ops;
+	ipc->desc.confops = &amb_pinconf_ops;
+	ipc->desc.owner = THIS_MODULE;
+
+	ret = devm_pinctrl_register_and_init(ipc->dev, &ipc->desc, ipc, &ipc->pctl);
+	if (ret)
+		return ret;
+
+	ret = amb_pinctrl_add_groups(ipc);
+	if (ret)
+		return ret;
+
+	ret = amb_pinctrl_add_functions(ipc);
+	if (ret)
+		return ret;
+
+	return pinctrl_enable(ipc->pctl);
+}
+
+static int amb_pinctrl_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct amb_pinctrl *ipc;
+	int ret;
+
+	ipc = devm_kzalloc(dev, sizeof(*ipc), GFP_KERNEL);
+	if (!ipc)
+		return -ENOMEM;
+
+	ipc->dev = dev;
+	ipc->data = device_get_match_data(dev);
+	if (!ipc->data)
+		return dev_err_probe(dev, -EINVAL, "missing SoC data\n");
+
+	if (!ipc->data->nr_banks || ipc->data->nr_banks > AMBA_MAX_BANKS ||
+	    !ipc->data->npins ||
+	    !ipc->data->groups || !ipc->data->ngroups ||
+	    !ipc->data->functions || !ipc->data->nfunctions)
+		return dev_err_probe(dev, -EINVAL, "invalid SoC data\n");
+
+	ipc->iomux_base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(ipc->iomux_base))
+		return PTR_ERR(ipc->iomux_base);
+
+	ipc->ds_regmap = syscon_regmap_lookup_by_phandle(dev_of_node(dev),
+					"ambarella,drive-strength-syscon");
+	if (IS_ERR(ipc->ds_regmap))
+		return dev_err_probe(dev, PTR_ERR(ipc->ds_regmap),
+				     "missing drive-strength syscon\n");
+
+	ipc->pull_regmap = syscon_regmap_lookup_by_phandle(dev_of_node(dev),
+					"ambarella,pull-syscon");
+	if (IS_ERR(ipc->pull_regmap))
+		return dev_err_probe(dev, PTR_ERR(ipc->pull_regmap),
+				     "missing pull syscon\n");
+
+	spin_lock_init(&ipc->lock);
+
+	ret = amb_pinctrl_register(ipc);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to register pinctrl\n");
+
+	platform_set_drvdata(pdev, ipc);
+
+	return 0;
+}
+
+static const struct of_device_id amb_pinctrl_dt_match[] = {
+	{
+		.compatible = "ambarella,cv75-pinctrl",
+		.data = &ambarella_cv75_pinctrl_data,
+	},
+	{ }
+};
+MODULE_DEVICE_TABLE(of, amb_pinctrl_dt_match);
+
+static struct platform_driver amb_pinctrl_driver = {
+	.probe = amb_pinctrl_probe,
+	.driver = {
+		.name = "ambarella-pinctrl",
+		.of_match_table = amb_pinctrl_dt_match,
+	},
+};
+
+static int __init amb_pinctrl_drv_register(void)
+{
+	return platform_driver_register(&amb_pinctrl_driver);
+}
+arch_initcall(amb_pinctrl_drv_register);
+
+MODULE_AUTHOR("Cao Rongrong <rrcao@ambarella.com>");
+MODULE_DESCRIPTION("Ambarella SoC pinctrl driver");
+MODULE_LICENSE("GPL");
diff --git a/drivers/pinctrl/pinctrl-ambarella.h b/drivers/pinctrl/pinctrl-ambarella.h
new file mode 100644
index 000000000000..fc56c19a3087
--- /dev/null
+++ b/drivers/pinctrl/pinctrl-ambarella.h
@@ -0,0 +1,44 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+/*
+ * Ambarella pinctrl SoC data
+ *
+ * Copyright (C) 2012-2026, Ambarella, Inc.
+ */
+
+#ifndef _PINCTRL_AMBARELLA_H
+#define _PINCTRL_AMBARELLA_H
+
+#include <linux/types.h>
+
+#include <linux/pinctrl/pinctrl.h>
+
+#define AMBA_MAX_BANKS			8
+
+#define AMBA_PINMUX(pin, alt)		(((alt) << 12) | (pin))
+#define AMBA_PINMUX_TO_PIN(mux)		((mux) & 0xfff)
+#define AMBA_PINMUX_TO_ALT(mux)		(((mux) >> 12) & 0x7)
+
+struct amb_pinmux_group {
+	const char *name;
+	const u32 *mux;
+	unsigned int nmux;
+};
+
+struct amb_pinctrl_data {
+	const struct amb_pinmux_group *groups;
+	const struct pinfunction *functions;
+	unsigned int ngroups;
+	unsigned int nfunctions;
+	unsigned int nr_banks;
+	unsigned int npins;
+	unsigned int ds0[AMBA_MAX_BANKS];
+	unsigned int ds1[AMBA_MAX_BANKS];
+	unsigned int ds2[AMBA_MAX_BANKS];
+	unsigned int pull_en[AMBA_MAX_BANKS];
+	unsigned int pull_dir[AMBA_MAX_BANKS];
+	bool have_ds2;
+};
+
+extern const struct amb_pinctrl_data ambarella_cv75_pinctrl_data;
+
+#endif /* _PINCTRL_AMBARELLA_H */

-- 
2.34.1

