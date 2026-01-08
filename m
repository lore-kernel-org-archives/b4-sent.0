From: Chuan Liu <chuan.liu@amlogic.com>
Date: Thu, 08 Jan 2026 14:08:17 +0800
Subject: [PATCH v5 3/8] dt-bindings: clock: Add Amlogic A5 peripherals
 clock controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260108-a5-clk-v5-3-9a69fc1ef00a@amlogic.com>
References: <20260108-a5-clk-v5-0-9a69fc1ef00a@amlogic.com>
In-Reply-To: <20260108-a5-clk-v5-0-9a69fc1ef00a@amlogic.com>
To: Chuan Liu <chuan.liu@amlogic.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767852503; l=9596;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=hHd35yALxxbdvq1KX85En5uKgtIsw1h8WtM1CzHm1rY=;
 b=atN8iueNaSD1TaBRACfkI02U9D89XWdFhqLDU6s7qitXF5BqrM3jVSsOvHX/jpwjGL1mfv0yK
 KGQUtPPcsNnBn/93LwJoechgCjr2tVds12mj+KhvYrpxyC9PWWY9AIr
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the peripherals clock controller dt-bindings for the Amlogic A5
SoC family.

Co-developed-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
---
 .../clock/amlogic,a5-peripherals-clkc.yaml         | 134 +++++++++++++++++++++
 .../clock/amlogic,a5-peripherals-clkc.h            | 132 ++++++++++++++++++++
 2 files changed, 266 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/amlogic,a5-peripherals-clkc.yaml b/Documentation/devicetree/bindings/clock/amlogic,a5-peripherals-clkc.yaml
new file mode 100644
index 000000000000..88d71d9a72ea
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/amlogic,a5-peripherals-clkc.yaml
@@ -0,0 +1,134 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+# Copyright (C) 2024 Amlogic, Inc. All rights reserved
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/amlogic,a5-peripherals-clkc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Amlogic A5 series Peripheral Clock Controller
+
+maintainers:
+  - Xianwei Zhao <xianwei.zhao@amlogic.com>
+  - Chuan Liu <chuan.liu@amlogic.com>
+
+properties:
+  compatible:
+    const: amlogic,a5-peripherals-clkc
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    minItems: 18
+    items:
+      - description: input oscillator
+      - description: input oscillators multiplexer
+      - description: input fix pll
+      - description: input fclk div 2
+      - description: input fclk div 2p5
+      - description: input fclk div 3
+      - description: input fclk div 4
+      - description: input fclk div 5
+      - description: input fclk div 7
+      - description: input mpll2
+      - description: input mpll3
+      - description: input gp0 pll
+      - description: input gp1 pll
+      - description: input hifi pll
+      - description: input sys clk
+      - description: input axi clk
+      - description: input sys pll div 16
+      - description: input cpu clk div 16
+      - description: input pad clock for rtc clk (optional)
+      - description: input ddr pll (optional)
+      - description: input source from clk-measure (optional)
+      - description: input rtc pll (optional)
+
+  clock-names:
+    minItems: 18
+    items:
+      - const: xtal
+      - const: oscin
+      - const: fix
+      - const: fdiv2
+      - const: fdiv2p5
+      - const: fdiv3
+      - const: fdiv4
+      - const: fdiv5
+      - const: fdiv7
+      - const: mpll2
+      - const: mpll3
+      - const: gp0
+      - const: gp1
+      - const: hifi
+      - const: sysclk
+      - const: axiclk
+      - const: sysplldiv16
+      - const: cpudiv16
+      - const: pad_osc
+      - const: ddr
+      - const: clkmsr
+      - const: rtc
+
+  "#clock-cells":
+    const: 1
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - clock-names
+  - "#clock-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/amlogic,a5-scmi-clkc.h>
+    #include <dt-bindings/clock/amlogic,a5-pll-clkc.h>
+    apb {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        clock-controller@0 {
+            compatible = "amlogic,a5-peripherals-clkc";
+            reg = <0x0 0x0 0x0 0x224>;
+            #clock-cells = <1>;
+            clocks = <&xtal>,
+                     <&scmi_clk CLKID_OSC>,
+                     <&scmi_clk CLKID_FIXED_PLL>,
+                     <&scmi_clk CLKID_FCLK_DIV2>,
+                     <&scmi_clk CLKID_FCLK_DIV2P5>,
+                     <&scmi_clk CLKID_FCLK_DIV3>,
+                     <&scmi_clk CLKID_FCLK_DIV4>,
+                     <&scmi_clk CLKID_FCLK_DIV5>,
+                     <&scmi_clk CLKID_FCLK_DIV7>,
+                     <&clkc_pll CLKID_MPLL2>,
+                     <&clkc_pll CLKID_MPLL3>,
+                     <&clkc_pll CLKID_GP0_PLL>,
+                     <&scmi_clk CLKID_GP1_PLL>,
+                     <&clkc_pll CLKID_HIFI_PLL>,
+                     <&scmi_clk CLKID_SYS_CLK>,
+                     <&scmi_clk CLKID_AXI_CLK>,
+                     <&scmi_clk CLKID_SYS_PLL_DIV16>,
+                     <&scmi_clk CLKID_CPU_CLK_DIV16>;
+            clock-names = "xtal",
+                          "oscin",
+                          "fix",
+                          "fdiv2",
+                          "fdiv2p5",
+                          "fdiv3",
+                          "fdiv4",
+                          "fdiv5",
+                          "fdiv7",
+                          "mpll2",
+                          "mpll3",
+                          "gp0",
+                          "gp1",
+                          "hifi",
+                          "sysclk",
+                          "axiclk",
+                          "sysplldiv16",
+                          "cpudiv16";
+        };
+    };
diff --git a/include/dt-bindings/clock/amlogic,a5-peripherals-clkc.h b/include/dt-bindings/clock/amlogic,a5-peripherals-clkc.h
new file mode 100644
index 000000000000..b8a68b7f29dc
--- /dev/null
+++ b/include/dt-bindings/clock/amlogic,a5-peripherals-clkc.h
@@ -0,0 +1,132 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2024 Amlogic, Inc. All rights reserved.
+ * Author: Chuan Liu <chuan.liu@amlogic.com>
+ */
+
+#ifndef _DT_BINDINGS_CLOCK_AMLOGIC_A5_PERIPHERALS_CLKC_H
+#define _DT_BINDINGS_CLOCK_AMLOGIC_A5_PERIPHERALS_CLKC_H
+
+#define CLKID_RTC_DUALDIV_CLKIN			0
+#define CLKID_RTC_DUALDIV			1
+#define CLKID_RTC_DUALDIV_SEL			2
+#define CLKID_RTC_DUALDIV_CLKOUT		3
+#define CLKID_RTC_CLK				4
+#define CLKID_SYS_RESET_CTRL			5
+#define CLKID_SYS_PWR_CTRL			6
+#define CLKID_SYS_PAD_CTRL			7
+#define CLKID_SYS_CTRL				8
+#define CLKID_SYS_TS_PLL			9
+#define CLKID_SYS_DEV_ARB			10
+#define CLKID_SYS_MAILBOX			11
+#define CLKID_SYS_JTAG_CTRL			12
+#define CLKID_SYS_IR_CTRL			13
+#define CLKID_SYS_MSR_CLK			14
+#define CLKID_SYS_ROM				15
+#define CLKID_SYS_CPU_ARB			16
+#define CLKID_SYS_RSA				17
+#define CLKID_SYS_SARADC			18
+#define CLKID_SYS_STARTUP			19
+#define CLKID_SYS_SECURE			20
+#define CLKID_SYS_SPIFC				21
+#define CLKID_SYS_DSPA				22
+#define CLKID_SYS_NNA				23
+#define CLKID_SYS_ETH_MAC			24
+#define CLKID_SYS_RAMA				25
+#define CLKID_SYS_RAMB				26
+#define CLKID_SYS_AUDIO_TOP			27
+#define CLKID_SYS_AUDIO_VAD			28
+#define CLKID_SYS_USB				29
+#define CLKID_SYS_SD_EMMC_A			30
+#define CLKID_SYS_SD_EMMC_C			31
+#define CLKID_SYS_PWM_AB			32
+#define CLKID_SYS_PWM_CD			33
+#define CLKID_SYS_PWM_EF			34
+#define CLKID_SYS_PWM_GH			35
+#define CLKID_SYS_SPICC_1			36
+#define CLKID_SYS_SPICC_0			37
+#define CLKID_SYS_UART_A			38
+#define CLKID_SYS_UART_B			39
+#define CLKID_SYS_UART_C			40
+#define CLKID_SYS_UART_D			41
+#define CLKID_SYS_UART_E			42
+#define CLKID_SYS_I2C_M_A			43
+#define CLKID_SYS_I2C_M_B			44
+#define CLKID_SYS_I2C_M_C			45
+#define CLKID_SYS_I2C_M_D			46
+#define CLKID_SYS_RTC				47
+#define CLKID_AXI_AUDIO_VAD			48
+#define CLKID_AXI_AUDIO_TOP			49
+#define CLKID_AXI_RAMB				50
+#define CLKID_AXI_RAMA				51
+#define CLKID_AXI_NNA				52
+#define CLKID_AXI_DEV1_DMC			53
+#define CLKID_AXI_DEV0_DMC			54
+#define CLKID_AXI_DSP_DMC			55
+#define CLKID_12_24M_IN				56
+#define CLKID_12M_24M				57
+#define CLKID_FCLK_25M_DIV			58
+#define CLKID_FCLK_25M				59
+#define CLKID_GEN_SEL				60
+#define CLKID_GEN_DIV				61
+#define CLKID_GEN				62
+#define CLKID_SARADC_SEL			63
+#define CLKID_SARADC_DIV			64
+#define CLKID_SARADC				65
+#define CLKID_PWM_A_SEL				66
+#define CLKID_PWM_A_DIV				67
+#define CLKID_PWM_A				68
+#define CLKID_PWM_B_SEL				69
+#define CLKID_PWM_B_DIV				70
+#define CLKID_PWM_B				71
+#define CLKID_PWM_C_SEL				72
+#define CLKID_PWM_C_DIV				73
+#define CLKID_PWM_C				74
+#define CLKID_PWM_D_SEL				75
+#define CLKID_PWM_D_DIV				76
+#define CLKID_PWM_D				77
+#define CLKID_PWM_E_SEL				78
+#define CLKID_PWM_E_DIV				79
+#define CLKID_PWM_E				80
+#define CLKID_PWM_F_SEL				81
+#define CLKID_PWM_F_DIV				82
+#define CLKID_PWM_F				83
+#define CLKID_PWM_G_SEL				84
+#define CLKID_PWM_G_DIV				85
+#define CLKID_PWM_G				86
+#define CLKID_PWM_H_SEL				87
+#define CLKID_PWM_H_DIV				88
+#define CLKID_PWM_H				89
+#define CLKID_SPICC_0_SEL			90
+#define CLKID_SPICC_0_DIV			91
+#define CLKID_SPICC_0				92
+#define CLKID_SPICC_1_SEL			93
+#define CLKID_SPICC_1_DIV			94
+#define CLKID_SPICC_1				95
+#define CLKID_SD_EMMC_A_SEL			96
+#define CLKID_SD_EMMC_A_DIV			97
+#define CLKID_SD_EMMC_A				98
+#define CLKID_SD_EMMC_C_SEL			99
+#define CLKID_SD_EMMC_C_DIV			100
+#define CLKID_SD_EMMC_C				101
+#define CLKID_TS_DIV				102
+#define CLKID_TS				103
+#define CLKID_ETH_125M_DIV			104
+#define CLKID_ETH_125M				105
+#define CLKID_ETH_RMII_DIV			106
+#define CLKID_ETH_RMII				107
+#define CLKID_DSPA_0_SEL			108
+#define CLKID_DSPA_0_DIV			109
+#define CLKID_DSPA_0				110
+#define CLKID_DSPA_1_SEL			111
+#define CLKID_DSPA_1_DIV			112
+#define CLKID_DSPA_1				113
+#define CLKID_DSPA				114
+#define CLKID_NNA_CORE_SEL			115
+#define CLKID_NNA_CORE_DIV			116
+#define CLKID_NNA_CORE				117
+#define CLKID_NNA_AXI_SEL			118
+#define CLKID_NNA_AXI_DIV			119
+#define CLKID_NNA_AXI				120
+
+#endif  /* _DT_BINDINGS_CLOCK_AMLOGIC_A5_PERIPHERALS_CLKC_H */

-- 
2.42.0

