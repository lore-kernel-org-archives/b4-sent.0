From: Long Zhao <longzhao@ambarella.com>
Date: Fri, 14 Aug 2026 14:25:44 +0800
Subject: [PATCH v4 4/4] pinctrl: ambarella: add CV75 pin controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260814-cv75-v4-b-v4-4-ef2e83ec0eac@ambarella.com>
References: <20260814-cv75-v4-b-v4-0-ef2e83ec0eac@ambarella.com>
In-Reply-To: <20260814-cv75-v4-b-v4-0-ef2e83ec0eac@ambarella.com>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786688764; l=45530;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=jGylPHgADr+PrQ8LYQ/hyHgOzomkJtfXVzMkjwDzk+o=;
 b=KgwSEV6tDemn2M3NZHETxvMSCFhlk9o3lR1EQQNO8bHE7dxJb91q9c16wF22aI++a8Fdda2Qw
 9NscdebV52iA0kNhrz2auSnPORuAAcx6UllxcfPyncIT1GN2ALvZAHa
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an Ambarella pinmux-only pinctrl driver with CV75 function/group
tables. GPIO is handled by the PL061 driver.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 drivers/pinctrl/Kconfig                  |  13 +
 drivers/pinctrl/Makefile                 |   2 +
 drivers/pinctrl/pinctrl-ambarella-cv75.c | 561 +++++++++++++++++++++
 drivers/pinctrl/pinctrl-ambarella.c      | 839 +++++++++++++++++++++++++++++++
 drivers/pinctrl/pinctrl-ambarella.h      |  50 ++
 5 files changed, 1465 insertions(+)

diff --git a/drivers/pinctrl/Kconfig b/drivers/pinctrl/Kconfig
index c2cdd7b2c49b..119acde60a93 100644
--- a/drivers/pinctrl/Kconfig
+++ b/drivers/pinctrl/Kconfig
@@ -37,6 +37,19 @@ config DEBUG_PINCTRL
 	help
 	  Say Y here to add some extra checks and diagnostics to PINCTRL calls.
 
+config PINCTRL_AMB
+	bool "Ambarella pin controller support"
+	depends on ARCH_AMBARELLA || COMPILE_TEST
+	select GENERIC_PINCONF
+	select GPIOLIB
+	select GPIOLIB_IRQCHIP
+	select GPIO_PL061
+	select MFD_SYSCON
+	select PINCONF
+	select PINMUX
+	help
+	  Say Y here to enable the Ambarella pin controller driver.
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
index 000000000000..e617f0717b31
--- /dev/null
+++ b/drivers/pinctrl/pinctrl-ambarella-cv75.c
@@ -0,0 +1,561 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Ambarella CV75 pinctrl data
+ *
+ * Copyright (C) 2026, Ambarella, Inc.
+ */
+
+#include <linux/kernel.h>
+
+#include "pinctrl-ambarella.h"
+
+#define CV75_PINMUX_GROUP(_name, ...)					\
+	static const u32 cv75_##_name##_pinmux[] = { __VA_ARGS__ }
+
+#define CV75_GROUP(_name)						\
+	{								\
+		.name = #_name,						\
+		.pinmux = cv75_##_name##_pinmux,				\
+		.num_pins = ARRAY_SIZE(cv75_##_name##_pinmux),		\
+	}
+
+#define CV75_FUNCTION(_name)						\
+	{								\
+		.name = #_name,						\
+		.groups = cv75_##_name##_groups,				\
+		.num_groups = ARRAY_SIZE(cv75_##_name##_groups),		\
+	}
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
+CV75_PINMUX_GROUP(clk_au, AMBA_PINMUX(96, 1));
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
+static const struct ambpin_group_desc cv75_pin_groups[] = {
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
+	CV75_GROUP(clk_au), CV75_GROUP(dmic0),
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
+static const char * const cv75_clk_au_groups[] = {
+	"clk_au",
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
+static const struct ambpin_function cv75_pin_functions[] = {
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
+	CV75_FUNCTION(clk_au),
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
+	.clk_au_dedicated_pin = 96,
+	.nr_banks = 3,
+	.npins = 97,
+	.groups = cv75_pin_groups,
+	.nr_groups = ARRAY_SIZE(cv75_pin_groups),
+	.functions = cv75_pin_functions,
+	.nr_functions = ARRAY_SIZE(cv75_pin_functions),
+};
diff --git a/drivers/pinctrl/pinctrl-ambarella.c b/drivers/pinctrl/pinctrl-ambarella.c
new file mode 100644
index 000000000000..fb79a8b02209
--- /dev/null
+++ b/drivers/pinctrl/pinctrl-ambarella.c
@@ -0,0 +1,839 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Pinctrl driver for Ambarella SoCs
+ *
+ * History:
+ *	2013/12/18 - [Cao Rongrong] created file
+ *
+ * Copyright (C) 2012-2026, Ambarella, Inc.
+ */
+
+#include <linux/module.h>
+#include <linux/platform_device.h>
+#include <linux/bitmap.h>
+#include <linux/io.h>
+#include <linux/of.h>
+#include <linux/of_device.h>
+#include <linux/pm.h>
+#include <linux/slab.h>
+#include <linux/regmap.h>
+#include <linux/mfd/syscon.h>
+#include <linux/pinctrl/pinctrl.h>
+#include <linux/pinctrl/pinmux.h>
+#include <linux/pinctrl/pinconf.h>
+#include <linux/pinctrl/pinconf-generic.h>
+#include <linux/seq_file.h>
+
+#include "pinconf.h"
+#include "pinctrl-ambarella.h"
+
+/* ==========================================================================*/
+
+#define IOMUX_OFFSET(bank, n)		(((bank) * 0xc) + ((n) * 4))
+#define IOMUX_CTRL_SET_OFFSET		0xf0
+
+/* ==========================================================================*/
+
+#define AMBA_MAX_PINS			(AMBA_MAX_BANKS * 32)
+
+#define PINID_TO_BANK(p)		((p) >> 5)
+#define PINID_TO_OFFSET(p)		((p) & 0x1f)
+
+struct amb_pinctrl_pm_state {
+	u32 iomux[3];
+	u32 pull[2];
+	u32 ds[3];
+};
+
+struct ambpin_group {
+	const char		*name;
+	const u32		*pinmux;
+	unsigned int		*pins;
+	unsigned int		num_pins;
+};
+
+struct amb_pinctrl_soc_data {
+	struct device			*dev;
+	const struct amb_pinctrl_data	*data;
+	void __iomem			*iomux_base;
+	struct regmap			*ds_regmap;
+	struct regmap			*pull_regmap;
+	unsigned int			npins;
+	unsigned long			used[BITS_TO_LONGS(AMBA_MAX_PINS)];
+	raw_spinlock_t lock;
+
+	struct pinctrl_dev		*pctl;
+
+	const struct ambpin_function	*functions;
+	unsigned int			nr_functions;
+	struct ambpin_group		*groups;
+	unsigned int			nr_groups;
+
+	struct amb_pinctrl_pm_state	pm[AMBA_MAX_BANKS];
+};
+
+/* check if the selector is a valid pin group selector */
+static int amb_get_group_count(struct pinctrl_dev *pctldev)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+
+	return soc->nr_groups;
+}
+
+/* return the name of the group selected by the group selector */
+static const char *amb_get_group_name(struct pinctrl_dev *pctldev,
+				      unsigned int selector)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+
+	return soc->groups[selector].name;
+}
+
+/* return the pin numbers associated with the specified group */
+static int amb_get_group_pins(struct pinctrl_dev *pctldev,
+			      unsigned int selector, const unsigned int **pins,
+			      unsigned int *num_pins)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+
+	*pins = soc->groups[selector].pins;
+	*num_pins = soc->groups[selector].num_pins;
+
+	return 0;
+}
+
+#if IS_ENABLED(CONFIG_DEBUG_FS)
+static void amb_pin_dbg_show(struct pinctrl_dev *pctldev,
+			     struct seq_file *s, unsigned int pin)
+{
+	seq_printf(s, " %s", pinctrl_dev_get_devname(pctldev));
+}
+#endif
+
+/* list of pinctrl callbacks for the pinctrl core */
+static const struct pinctrl_ops amb_pctrl_ops = {
+	.get_groups_count	= amb_get_group_count,
+	.get_group_name		= amb_get_group_name,
+	.get_group_pins		= amb_get_group_pins,
+#if IS_ENABLED(CONFIG_DEBUG_FS)
+	.pin_dbg_show		= amb_pin_dbg_show,
+#endif
+	.dt_node_to_map		= pinconf_generic_dt_node_to_map_all,
+	.dt_free_map		= pinconf_generic_dt_free_map,
+};
+
+/* check if the selector is a valid pin function selector */
+static int amb_pinmux_request(struct pinctrl_dev *pctldev, unsigned int pin)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+
+	if (test_and_set_bit(pin, soc->used))
+		return -EBUSY;
+
+	return 0;
+}
+
+/* check if the selector is a valid pin function selector */
+static int amb_pinmux_free(struct pinctrl_dev *pctldev, unsigned int pin)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+
+	clear_bit(pin, soc->used);
+
+	return 0;
+}
+
+/* check if the selector is a valid pin function selector */
+static int amb_pinmux_get_fcount(struct pinctrl_dev *pctldev)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+
+	return soc->nr_functions;
+}
+
+/* return the name of the pin function specified */
+static const char *amb_pinmux_get_fname(struct pinctrl_dev *pctldev,
+					unsigned int selector)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+
+	return soc->functions[selector].name;
+}
+
+/* return the groups associated for the specified function selector */
+static int amb_pinmux_get_groups(struct pinctrl_dev *pctldev,
+				 unsigned int selector,
+				 const char * const **groups,
+				 unsigned int * const num_groups)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+
+	*groups = soc->functions[selector].groups;
+	*num_groups = soc->functions[selector].num_groups;
+
+	return 0;
+}
+
+static bool amb_iomux_accessible(const struct amb_pinctrl_soc_data *soc)
+{
+	return soc->data->hsm_domain_id == 0;
+}
+
+static void amb_iomux_commit(struct amb_pinctrl_soc_data *soc)
+{
+	if (!amb_iomux_accessible(soc))
+		return;
+
+	writel_relaxed(0x1, soc->iomux_base + IOMUX_CTRL_SET_OFFSET);
+	writel_relaxed(0x0, soc->iomux_base + IOMUX_CTRL_SET_OFFSET);
+}
+
+static void amb_iomux_save_bank(struct amb_pinctrl_soc_data *soc, u32 bank)
+{
+	if (!amb_iomux_accessible(soc) || bank >= AMBA_MAX_BANKS)
+		return;
+
+	soc->pm[bank].iomux[0] =
+		readl_relaxed(soc->iomux_base + IOMUX_OFFSET(bank, 0));
+	soc->pm[bank].iomux[1] =
+		readl_relaxed(soc->iomux_base + IOMUX_OFFSET(bank, 1));
+	soc->pm[bank].iomux[2] =
+		readl_relaxed(soc->iomux_base + IOMUX_OFFSET(bank, 2));
+}
+
+static void amb_iomux_restore_bank(struct amb_pinctrl_soc_data *soc, u32 bank)
+{
+	if (!amb_iomux_accessible(soc) || bank >= AMBA_MAX_BANKS)
+		return;
+
+	writel_relaxed(soc->pm[bank].iomux[0],
+		       soc->iomux_base + IOMUX_OFFSET(bank, 0));
+	writel_relaxed(soc->pm[bank].iomux[1],
+		       soc->iomux_base + IOMUX_OFFSET(bank, 1));
+	writel_relaxed(soc->pm[bank].iomux[2],
+		       soc->iomux_base + IOMUX_OFFSET(bank, 2));
+}
+
+static void amb_pinmux_set_altfunc(struct amb_pinctrl_soc_data *soc,
+				   u32 bank, u32 offset, u32 altfunc)
+{
+	u32 i, data;
+
+	if (!amb_iomux_accessible(soc))
+		return;
+
+	for (i = 0; i < 3; i++) {
+		data = readl_relaxed(soc->iomux_base + IOMUX_OFFSET(bank, i));
+		data &= (~(0x1 << offset));
+		data |= (((altfunc >> i) & 0x1) << offset);
+		writel_relaxed(data, soc->iomux_base + IOMUX_OFFSET(bank, i));
+	}
+
+	amb_iomux_commit(soc);
+}
+
+/* enable a specified pinmux by writing to registers */
+static int amb_pinmux_set_mux(struct pinctrl_dev *pctldev,
+			      unsigned int selector, unsigned int group)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+	const struct ambpin_group *grp;
+	u32 i, pin, alt, bank, offset;
+	unsigned long flags;
+
+	grp = &soc->groups[group];
+
+	raw_spin_lock_irqsave(&soc->lock, flags);
+	for (i = 0; i < grp->num_pins; i++) {
+		pin = AMBA_PINMUX_TO_PIN(grp->pinmux[i]);
+		alt = AMBA_PINMUX_TO_ALT(grp->pinmux[i]);
+		bank = PINID_TO_BANK(pin);
+		offset = PINID_TO_OFFSET(pin);
+		amb_pinmux_set_altfunc(soc, bank, offset, alt);
+	}
+	raw_spin_unlock_irqrestore(&soc->lock, flags);
+
+	return 0;
+}
+
+static int amb_pinmux_gpio_request_enable(struct pinctrl_dev *pctldev,
+					  struct pinctrl_gpio_range *range,
+					  unsigned int pin)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+	u32 bank, offset;
+	unsigned long flags;
+
+	if (!range || !range->gc) {
+		dev_err(soc->dev, "invalid range: %p\n", range);
+		return -EINVAL;
+	}
+
+	if (test_and_set_bit(pin, soc->used))
+		return -EBUSY;
+
+	bank = PINID_TO_BANK(pin);
+	offset = PINID_TO_OFFSET(pin);
+
+	raw_spin_lock_irqsave(&soc->lock, flags);
+	amb_pinmux_set_altfunc(soc, bank, offset, 0);
+	raw_spin_unlock_irqrestore(&soc->lock, flags);
+
+	return 0;
+}
+
+static void amb_pinmux_gpio_disable_free(struct pinctrl_dev *pctldev,
+					 struct pinctrl_gpio_range *range,
+					 unsigned int pin)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+
+	dev_dbg(soc->dev, "disable pin %u as GPIO\n", pin);
+	/* Set the pin to some default state, GPIO is usually default */
+
+	clear_bit(pin, soc->used);
+}
+
+/* list of pinmux callbacks for the pinmux vertical in pinctrl core */
+static const struct pinmux_ops amb_pinmux_ops = {
+	.request		= amb_pinmux_request,
+	.free			= amb_pinmux_free,
+	.get_functions_count	= amb_pinmux_get_fcount,
+	.get_function_name	= amb_pinmux_get_fname,
+	.get_function_groups	= amb_pinmux_get_groups,
+	.set_mux                = amb_pinmux_set_mux,
+	.gpio_request_enable	= amb_pinmux_gpio_request_enable,
+	.gpio_disable_free	= amb_pinmux_gpio_disable_free,
+};
+
+static int amb_drive_strength_to_reg(struct amb_pinctrl_soc_data *soc,
+				     u32 strength)
+{
+	if (soc->data->have_ds2) {
+		switch (strength) {
+		case 3:
+			return 0;
+		case 4:
+		case 5:
+			return 1;
+		case 6:
+			return 2;
+		case 7:
+		case 8:
+			return 3;
+		case 9:
+			return 4;
+		case 12:
+			return 5;
+		default:
+			return -EINVAL;
+		}
+	}
+
+	switch (strength) {
+	case 2:
+		return 0;
+	case 4:
+		return 1;
+	case 8:
+		return 2;
+	case 12:
+		return 3;
+	default:
+		return -EINVAL;
+	}
+}
+
+static int amb_reg_to_drive_strength(struct amb_pinctrl_soc_data *soc, u32 ds)
+{
+	static const int ds2_ma[] = { 3, 4, 6, 8, 9, 12 };
+	static const int ds_ma[] = { 2, 4, 8, 12 };
+
+	if (soc->data->have_ds2) {
+		if (ds >= ARRAY_SIZE(ds2_ma))
+			return -EINVAL;
+
+		return ds2_ma[ds];
+	}
+
+	if (ds >= ARRAY_SIZE(ds_ma))
+		return -EINVAL;
+
+	return ds_ma[ds];
+}
+
+/* set the pin config settings for a specified pin */
+static int amb_pinconf_set(struct pinctrl_dev *pctldev, unsigned int pin,
+			   unsigned long *configs, unsigned int num_configs)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+	u32 i, bank, offset;
+	unsigned long config;
+	enum pin_config_param param;
+	u32 arg;
+	int ds;
+
+	bank = PINID_TO_BANK(pin);
+	if (bank >= soc->data->nr_banks)
+		return -EINVAL;
+
+	offset = PINID_TO_OFFSET(pin);
+
+	for (i = 0; i < num_configs; i++) {
+		config = configs[i];
+		param = pinconf_to_config_param(config);
+		arg = pinconf_to_config_argument(config);
+
+		switch (param) {
+		case PIN_CONFIG_BIAS_DISABLE:
+			regmap_update_bits(soc->pull_regmap,
+					   soc->data->pull_en[bank], BIT(offset), 0);
+			break;
+		case PIN_CONFIG_BIAS_PULL_DOWN:
+		case PIN_CONFIG_BIAS_PULL_UP:
+			regmap_update_bits(soc->pull_regmap, soc->data->pull_dir[bank],
+					   BIT(offset),
+					   (param == PIN_CONFIG_BIAS_PULL_UP) ?
+					   BIT(offset) : 0);
+			regmap_update_bits(soc->pull_regmap, soc->data->pull_en[bank],
+					   BIT(offset), BIT(offset));
+			break;
+		case PIN_CONFIG_DRIVE_STRENGTH:
+			ds = amb_drive_strength_to_reg(soc, arg);
+			if (ds < 0)
+				return ds;
+			if (soc->data->have_ds2) {
+				regmap_update_bits(soc->ds_regmap,
+						   soc->data->ds0[bank], BIT(offset),
+						   (ds & BIT(0)) ? BIT(offset) : 0);
+				regmap_update_bits(soc->ds_regmap,
+						   soc->data->ds1[bank], BIT(offset),
+						   (ds & BIT(1)) ? BIT(offset) : 0);
+				regmap_update_bits(soc->ds_regmap,
+						   soc->data->ds2[bank], BIT(offset),
+						   (ds & BIT(2)) ? BIT(offset) : 0);
+			} else {
+				regmap_update_bits(soc->ds_regmap,
+						   soc->data->ds0[bank], BIT(offset),
+						   (ds & BIT(1)) ? BIT(offset) : 0);
+				regmap_update_bits(soc->ds_regmap,
+						   soc->data->ds1[bank], BIT(offset),
+						   (ds & BIT(0)) ? BIT(offset) : 0);
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
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+	const struct ambpin_group *grp = &soc->groups[selector];
+	int ret;
+	u32 i;
+
+	for (i = 0; i < grp->num_pins; i++) {
+		ret = amb_pinconf_set(pctldev, grp->pins[i], configs,
+				      num_configs);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+/* get the pin config settings for a specified pin */
+static int amb_pinconf_get(struct pinctrl_dev *pctldev,
+			   unsigned int pin, unsigned long *config)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+	enum pin_config_param param = pinconf_to_config_param(*config);
+	u32 bank, offset, pull_en, pull_dir, ds0, ds1, ds2, ds;
+	int ret, strength;
+
+	bank = PINID_TO_BANK(pin);
+	if (bank >= soc->data->nr_banks)
+		return -EINVAL;
+
+	offset = PINID_TO_OFFSET(pin);
+
+	switch (param) {
+	case PIN_CONFIG_BIAS_DISABLE:
+	case PIN_CONFIG_BIAS_PULL_DOWN:
+	case PIN_CONFIG_BIAS_PULL_UP:
+		ret = regmap_read(soc->pull_regmap, soc->data->pull_en[bank],
+				  &pull_en);
+		if (ret)
+			return ret;
+
+		ret = regmap_read(soc->pull_regmap, soc->data->pull_dir[bank],
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
+		ret = regmap_read(soc->ds_regmap, soc->data->ds0[bank], &ds0);
+		if (ret)
+			return ret;
+
+		ret = regmap_read(soc->ds_regmap, soc->data->ds1[bank], &ds1);
+		if (ret)
+			return ret;
+
+		ds0 = (ds0 >> offset) & 1;
+		ds1 = (ds1 >> offset) & 1;
+		if (soc->data->have_ds2) {
+			ret = regmap_read(soc->ds_regmap, soc->data->ds2[bank], &ds2);
+			if (ret)
+				return ret;
+
+			ds2 = (ds2 >> offset) & 1;
+			ds = (ds2 << 2) | (ds1 << 1) | ds0;
+		} else {
+			ds = (ds0 << 1) | ds1;
+		}
+
+		strength = amb_reg_to_drive_strength(soc, ds);
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
+#if IS_ENABLED(CONFIG_DEBUG_FS)
+static void amb_pinconf_dbg_show(struct pinctrl_dev *pctldev,
+				 struct seq_file *s, unsigned int pin)
+{
+	struct amb_pinctrl_soc_data *soc = pinctrl_dev_get_drvdata(pctldev);
+	u32 pull_en, pull_dir, ds0, ds1, ds2, ds;
+	u32 bank, offset;
+	int strength;
+
+	bank = PINID_TO_BANK(pin);
+	if (bank >= soc->data->nr_banks) {
+		seq_puts(s, " (no pinconf)");
+		return;
+	}
+
+	offset = PINID_TO_OFFSET(pin);
+
+	regmap_read(soc->pull_regmap, soc->data->pull_en[bank], &pull_en);
+	pull_en = (pull_en >> offset) & 1;
+	regmap_read(soc->pull_regmap, soc->data->pull_dir[bank], &pull_dir);
+	pull_dir = (pull_dir >> offset) & 1;
+	seq_printf(s, " pull: %s,",
+		   pull_en ? (pull_dir ? "up" : "down") : "disable");
+
+	regmap_read(soc->ds_regmap, soc->data->ds0[bank], &ds0);
+	ds0 = (ds0 >> offset) & 1;
+	regmap_read(soc->ds_regmap, soc->data->ds1[bank], &ds1);
+	ds1 = (ds1 >> offset) & 1;
+	if (soc->data->have_ds2) {
+		regmap_read(soc->ds_regmap, soc->data->ds2[bank], &ds2);
+		ds2 = (ds2 >> offset) & 1;
+		ds = (ds2 << 2) | (ds1 << 1) | ds0;
+	} else {
+		ds = (ds0 << 1) | ds1;
+	}
+
+	strength = amb_reg_to_drive_strength(soc, ds);
+	if (strength < 0)
+		seq_puts(s, " drive-strength: invalid");
+	else
+		seq_printf(s, " drive-strength: %dmA", strength);
+}
+#endif
+
+/* list of pinconfig callbacks for pinconfig vertical in the pinctrl code */
+static const struct pinconf_ops amb_pinconf_ops = {
+	.is_generic		= true,
+	.pin_config_get		= amb_pinconf_get,
+	.pin_config_set		= amb_pinconf_set,
+	.pin_config_group_set	= amb_pinconf_group_set,
+#if IS_ENABLED(CONFIG_DEBUG_FS)
+	.pin_config_dbg_show	= amb_pinconf_dbg_show,
+#endif
+};
+
+/* register the pinctrl interface with the pinctrl subsystem */
+static int amb_pinctrl_register(struct amb_pinctrl_soc_data *soc)
+{
+	struct pinctrl_pin_desc *pindesc;
+	struct pinctrl_desc *amb_pinctrl_desc;
+	unsigned int pin;
+
+	/* dynamically populate the pin number and pin name for pindesc */
+	pindesc = devm_kcalloc(soc->dev, soc->npins, sizeof(*pindesc),
+			       GFP_KERNEL);
+	if (!pindesc)
+		return -ENOMEM;
+
+	for (pin = 0; pin < soc->npins; pin++) {
+		pindesc[pin].number = pin;
+		pindesc[pin].name = devm_kasprintf(soc->dev, GFP_KERNEL,
+						   "io%u", pin);
+		if (!pindesc[pin].name)
+			return -ENOMEM;
+	}
+
+	amb_pinctrl_desc = devm_kzalloc(soc->dev, sizeof(*amb_pinctrl_desc), GFP_KERNEL);
+	if (!amb_pinctrl_desc)
+		return -ENOMEM;
+
+	amb_pinctrl_desc->name = dev_name(soc->dev);
+	amb_pinctrl_desc->pins = pindesc;
+	amb_pinctrl_desc->npins = soc->npins;
+	amb_pinctrl_desc->pctlops = &amb_pctrl_ops;
+	amb_pinctrl_desc->pmxops = &amb_pinmux_ops;
+	amb_pinctrl_desc->confops = &amb_pinconf_ops;
+	amb_pinctrl_desc->owner = THIS_MODULE;
+
+	soc->pctl = devm_pinctrl_register(soc->dev, amb_pinctrl_desc, soc);
+	if (IS_ERR(soc->pctl)) {
+		dev_err(soc->dev, "could not register pinctrl driver\n");
+		return PTR_ERR(soc->pctl);
+	}
+
+	return 0;
+}
+
+static int amb_pinctrl_probe(struct platform_device *pdev)
+{
+	struct amb_pinctrl_soc_data *soc;
+	struct device_node *np;
+	unsigned int *group_pins;
+	unsigned int group, group_pin;
+	size_t nr_group_pins = 0;
+	int rval;
+
+	soc = devm_kzalloc(&pdev->dev, sizeof(*soc), GFP_KERNEL);
+	if (!soc)
+		return -ENOMEM;
+
+	soc->dev = &pdev->dev;
+	soc->data = of_device_get_match_data(&pdev->dev);
+	if (!soc->data)
+		return dev_err_probe(&pdev->dev, -EINVAL, "missing soc data");
+	if (!soc->data->nr_banks ||
+	    soc->data->nr_banks > AMBA_MAX_BANKS ||
+	    !soc->data->npins ||
+	    soc->data->npins > AMBA_MAX_PINS ||
+	    soc->data->nr_banks * 32 > soc->data->npins ||
+	    soc->data->clk_au_dedicated_pin >= soc->data->npins ||
+	    PINID_TO_BANK(soc->data->clk_au_dedicated_pin) >= AMBA_MAX_BANKS)
+		return dev_err_probe(&pdev->dev, -EINVAL,
+				     "invalid bank or pin count\n");
+
+	soc->npins = soc->data->npins;
+
+	np = pdev->dev.of_node;
+	soc->iomux_base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(soc->iomux_base))
+		return dev_err_probe(&pdev->dev, PTR_ERR(soc->iomux_base),
+							 "couldn't get iomux reg");
+
+	soc->ds_regmap = syscon_regmap_lookup_by_phandle(np, "ambarella,drive-strength-syscon");
+	if (IS_ERR(soc->ds_regmap))
+		return dev_err_probe(&pdev->dev, PTR_ERR(soc->ds_regmap),
+				     "couldn't get drive-strength regmap");
+
+	soc->pull_regmap = syscon_regmap_lookup_by_phandle(np, "ambarella,pull-syscon");
+	if (IS_ERR(soc->pull_regmap))
+		return dev_err_probe(&pdev->dev, PTR_ERR(soc->pull_regmap),
+				     "couldn't get pull regmap");
+
+	soc->nr_groups = soc->data->nr_groups;
+	soc->functions = soc->data->functions;
+	soc->nr_functions = soc->data->nr_functions;
+	if (!soc->data->groups || !soc->nr_groups ||
+	    !soc->functions || !soc->nr_functions)
+		return dev_err_probe(&pdev->dev, -EINVAL,
+				     "missing pin groups or functions\n");
+
+	soc->groups = devm_kcalloc(&pdev->dev, soc->nr_groups,
+				   sizeof(*soc->groups), GFP_KERNEL);
+	if (!soc->groups)
+		return -ENOMEM;
+
+	for (group = 0; group < soc->nr_groups; group++) {
+		const struct ambpin_group_desc *desc =
+			&soc->data->groups[group];
+
+		if (!desc->name || !desc->pinmux || !desc->num_pins)
+			return dev_err_probe(&pdev->dev, -EINVAL,
+					     "invalid pin group %u\n", group);
+
+		nr_group_pins += desc->num_pins;
+	}
+
+	group_pins = devm_kcalloc(&pdev->dev, nr_group_pins,
+				  sizeof(*group_pins), GFP_KERNEL);
+	if (!group_pins)
+		return -ENOMEM;
+
+	for (group = 0; group < soc->nr_groups; group++) {
+		const struct ambpin_group_desc *desc =
+			&soc->data->groups[group];
+		struct ambpin_group *grp = &soc->groups[group];
+
+		grp->name = desc->name;
+		grp->pinmux = desc->pinmux;
+		grp->pins = group_pins;
+		grp->num_pins = desc->num_pins;
+		for (group_pin = 0;
+		     group_pin < grp->num_pins;
+		     group_pin++) {
+			u32 pinmux = grp->pinmux[group_pin];
+			unsigned int pin = AMBA_PINMUX_TO_PIN(pinmux);
+			unsigned int alt = AMBA_PINMUX_TO_ALT(pinmux);
+
+			if (pin >= soc->npins || alt > 7)
+				return dev_err_probe(&pdev->dev, -EINVAL,
+						     "group %s has invalid pinmux %#x\n",
+						     grp->name, pinmux);
+
+			grp->pins[group_pin] = pin;
+		}
+		group_pins += grp->num_pins;
+	}
+
+	raw_spin_lock_init(&soc->lock);
+
+	/* Mark all pins unavailable, then clear pins that exist. */
+	bitmap_fill(soc->used, AMBA_MAX_PINS);
+	bitmap_clear(soc->used, 0, soc->data->nr_banks * 32);
+	clear_bit(soc->data->clk_au_dedicated_pin, soc->used);
+
+	rval = amb_pinctrl_register(soc);
+	if (rval)
+		return dev_err_probe(&pdev->dev, rval, "pinctrl register failed!");
+
+	platform_set_drvdata(pdev, soc);
+	dev_info(&pdev->dev, "Ambarella pinctrl driver registered");
+
+	return 0;
+}
+
+static int amb_pinctrl_suspend(struct device *dev)
+{
+	struct amb_pinctrl_soc_data *soc = dev_get_drvdata(dev);
+	u32 bank, dedicated = soc->data->clk_au_dedicated_pin;
+
+	for (bank = 0; bank < soc->data->nr_banks; bank++) {
+		regmap_read(soc->pull_regmap, soc->data->pull_en[bank],
+			    &soc->pm[bank].pull[0]);
+		regmap_read(soc->pull_regmap, soc->data->pull_dir[bank],
+			    &soc->pm[bank].pull[1]);
+
+		regmap_read(soc->ds_regmap, soc->data->ds0[bank],
+			    &soc->pm[bank].ds[0]);
+		regmap_read(soc->ds_regmap, soc->data->ds1[bank],
+			    &soc->pm[bank].ds[1]);
+		if (soc->data->have_ds2)
+			regmap_read(soc->ds_regmap, soc->data->ds2[bank],
+				    &soc->pm[bank].ds[2]);
+
+		amb_iomux_save_bank(soc, bank);
+	}
+
+	if (dedicated >= soc->data->nr_banks * 32)
+		amb_iomux_save_bank(soc, PINID_TO_BANK(dedicated));
+
+	return 0;
+}
+
+static int amb_pinctrl_resume(struct device *dev)
+{
+	struct amb_pinctrl_soc_data *soc = dev_get_drvdata(dev);
+	u32 bank, dedicated = soc->data->clk_au_dedicated_pin;
+
+	for (bank = 0; bank < soc->data->nr_banks; bank++)
+		amb_iomux_restore_bank(soc, bank);
+
+	if (dedicated >= soc->data->nr_banks * 32)
+		amb_iomux_restore_bank(soc, PINID_TO_BANK(dedicated));
+
+	wmb();
+	amb_iomux_commit(soc);
+
+	for (bank = 0; bank < soc->data->nr_banks; bank++) {
+		regmap_write(soc->ds_regmap, soc->data->ds0[bank],
+			     soc->pm[bank].ds[0]);
+		regmap_write(soc->ds_regmap, soc->data->ds1[bank],
+			     soc->pm[bank].ds[1]);
+		if (soc->data->have_ds2)
+			regmap_write(soc->ds_regmap, soc->data->ds2[bank],
+				     soc->pm[bank].ds[2]);
+
+		regmap_write(soc->pull_regmap, soc->data->pull_dir[bank],
+			     soc->pm[bank].pull[1]);
+		regmap_write(soc->pull_regmap, soc->data->pull_en[bank],
+			     soc->pm[bank].pull[0]);
+	}
+
+	return 0;
+}
+
+static DEFINE_SIMPLE_DEV_PM_OPS(amb_pinctrl_pm_ops,
+				amb_pinctrl_suspend,
+				amb_pinctrl_resume);
+
+static const struct of_device_id amb_pinctrl_dt_match[] = {
+	{
+		.compatible = "ambarella,cv75-pinctrl",
+		.data = &ambarella_cv75_pinctrl_data,
+	},
+	{},
+};
+MODULE_DEVICE_TABLE(of, amb_pinctrl_dt_match);
+
+static struct platform_driver amb_pinctrl_driver = {
+	.probe	= amb_pinctrl_probe,
+	.driver	= {
+		.name	= "ambarella-pinctrl",
+		.of_match_table = of_match_ptr(amb_pinctrl_dt_match),
+		.pm = pm_sleep_ptr(&amb_pinctrl_pm_ops),
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
index 000000000000..094639627131
--- /dev/null
+++ b/drivers/pinctrl/pinctrl-ambarella.h
@@ -0,0 +1,50 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+/*
+ * Ambarella pinctrl common data definitions
+ *
+ * Copyright (C) 2012-2026, Ambarella, Inc.
+ */
+
+#ifndef _PINCTRL_AMBARELLA_H
+#define _PINCTRL_AMBARELLA_H
+
+#include <linux/types.h>
+
+#define AMBA_MAX_BANKS			8
+
+#define AMBA_PINMUX(pin, alt)		(((alt) << 12) | (pin))
+#define AMBA_PINMUX_TO_PIN(mux)		((mux) & 0xfff)
+#define AMBA_PINMUX_TO_ALT(mux)		(((mux) >> 12) & 0xf)
+
+struct ambpin_group_desc {
+	const char		*name;
+	const u32		*pinmux;
+	unsigned int		num_pins;
+};
+
+struct ambpin_function {
+	const char		*name;
+	const char * const	*groups;
+	unsigned int		num_groups;
+};
+
+struct amb_pinctrl_data {
+	unsigned int		ds0[AMBA_MAX_BANKS];
+	unsigned int		ds1[AMBA_MAX_BANKS];
+	unsigned int		ds2[AMBA_MAX_BANKS];
+	unsigned int		pull_en[AMBA_MAX_BANKS];
+	unsigned int		pull_dir[AMBA_MAX_BANKS];
+	bool			have_ds2;
+	u32			hsm_domain_id;
+	u32			clk_au_dedicated_pin;
+	unsigned int		nr_banks;
+	unsigned int		npins;
+	const struct ambpin_group_desc *groups;
+	unsigned int		nr_groups;
+	const struct ambpin_function *functions;
+	unsigned int		nr_functions;
+};
+
+extern const struct amb_pinctrl_data ambarella_cv75_pinctrl_data;
+
+#endif /* _PINCTRL_AMBARELLA_H */

-- 
2.34.1

