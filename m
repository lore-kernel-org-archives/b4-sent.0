From: Ben Grisdale <bengris32@protonmail.ch>
Date: Tue, 17 Nov 2026 21:00:41 +0000
Subject: [PATCH 1/2] dt-bindings: pinctrl: mediatek: Add MT8163
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-mt8163-pinctrl-v1-1-2cfd12206b17@protonmail.ch>
References: <20261117-mt8163-pinctrl-v1-0-2cfd12206b17@protonmail.ch>
In-Reply-To: <20261117-mt8163-pinctrl-v1-0-2cfd12206b17@protonmail.ch>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794949947; l=48917;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=QBpjlQ0CJTk3u5WPKPWeZsu+7cpsERi+EszvvfQU4/o=;
 b=yaP0OM32IhlVY0XOEcdJvlPPRCSy9IdQ1tGGjo4IWxVM1u08zgk/Y8e6hmv7ynxTHLQjZyS8Q
 7W4RDWvGxMvDeLSaVguKNWwMNs6CEBLsO9Of/DBt+uXPHhxmYmperZk
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree bindings for the pin controller on the MediaTek
MT8163 SoC, along with a header defining the pinmux values.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 .../bindings/pinctrl/mediatek,mt8163-pinctrl.yaml  | 208 ++++++
 .../dt-bindings/pinctrl/mediatek,mt8163-pinfunc.h  | 821 +++++++++++++++++++++
 2 files changed, 1029 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/mediatek,mt8163-pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/mediatek,mt8163-pinctrl.yaml
new file mode 100644
index 000000000000..e9db839734ba
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/mediatek,mt8163-pinctrl.yaml
@@ -0,0 +1,208 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pinctrl/mediatek,mt8163-pinctrl.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: MediaTek MT8163 Pin Controller
+
+maintainers:
+  - Ben Grisdale <bengris32@protonmail.ch>
+
+description:
+  The MediaTek MT8163 pin controller is used to control SoC pins.
+
+properties:
+  compatible:
+    const: mediatek,mt8163-pinctrl
+
+  reg:
+    items:
+      - description: Pin controller base
+      - description: EINT controller base
+
+  reg-names:
+    items:
+      - const: base
+      - const: eint
+
+  gpio-controller: true
+
+  '#gpio-cells':
+    const: 2
+
+  gpio-ranges:
+    maxItems: 1
+
+  gpio-line-names:
+    maxItems: 155
+
+  interrupts:
+    description: EINT interrupt
+    maxItems: 1
+
+  interrupt-controller: true
+
+  '#interrupt-cells':
+    const: 2
+
+# PIN CONFIGURATION NODES
+patternProperties:
+  '-pins$':
+    type: object
+    additionalProperties: false
+
+    patternProperties:
+      '^pins':
+        type: object
+        allOf:
+          - $ref: /schemas/pinctrl/pincfg-node.yaml
+          - $ref: /schemas/pinctrl/pinmux-node.yaml
+        description:
+          A pinctrl node should contain at least one subnode representing the
+          pinctrl groups available on the machine. Each subnode will list the
+          pins it needs, and how they should be configured, with regard to muxer
+          configuration, pullups, drive strength, input enable/disable and input
+          schmitt.
+
+        properties:
+          pinmux:
+            description:
+              Integer array, represents gpio pin number and mux setting.
+              Supported pin number and mux are defined as macros in
+              dt-bindings/pinctrl/mediatek,mt8163-pinfunc.h for this SoC.
+
+          drive-strength:
+            enum: [2, 4, 6, 8, 10, 12, 14, 16]
+
+          bias-pull-down:
+            oneOf:
+              - type: boolean
+              - enum: [100, 101, 102, 103]
+                description: Pull down PUPD/R0/R1 type define value.
+            description: |
+              For normal pull down type pins, this is a boolean property.
+              For PUPD/R0/R1 type pins (keypad, EINT14-EINT17, EINT21 and MSDC
+              pins), one of the MTK_PUPD_SET_R1R0_* defines from
+              dt-bindings/pinctrl/mt65xx.h is required to select the
+              resistance:
+              MTK_PUPD_SET_R1R0_00 (100): R1 disabled, R0 disabled.
+              MTK_PUPD_SET_R1R0_01 (101): R1 disabled, R0 enabled.
+              MTK_PUPD_SET_R1R0_10 (102): R1 enabled, R0 disabled.
+              MTK_PUPD_SET_R1R0_11 (103): R1 enabled, R0 enabled.
+
+          bias-pull-up:
+            oneOf:
+              - type: boolean
+              - enum: [100, 101, 102, 103]
+                description: Pull up PUPD/R0/R1 type define value.
+            description: |
+              For normal pull up type pins, this is a boolean property.
+              For PUPD/R0/R1 type pins (keypad, EINT14-EINT17, EINT21 and MSDC
+              pins), one of the MTK_PUPD_SET_R1R0_* defines from
+              dt-bindings/pinctrl/mt65xx.h is required to select the
+              resistance:
+              MTK_PUPD_SET_R1R0_00 (100): R1 disabled, R0 disabled.
+              MTK_PUPD_SET_R1R0_01 (101): R1 disabled, R0 enabled.
+              MTK_PUPD_SET_R1R0_10 (102): R1 enabled, R0 disabled.
+              MTK_PUPD_SET_R1R0_11 (103): R1 enabled, R0 enabled.
+
+          bias-disable: true
+
+          output-high: true
+
+          output-low: true
+
+          input-enable: true
+
+          input-disable: true
+
+          input-schmitt-enable: true
+
+          input-schmitt-disable: true
+
+          slew-rate:
+            description: |
+              Set the slew rate. Valid arguments are described as below:
+              0: Normal slew rate
+              1: Slower slew
+            enum: [0, 1]
+
+          mediatek,tdsel:
+            description:
+              An integer describing the steps for output level shifter duty
+              cycle when asserted (high pulse width adjustment).
+            $ref: /schemas/types.yaml#/definitions/uint32
+            maximum: 15
+
+          mediatek,rdsel:
+            description:
+              An integer describing the steps for input level shifter duty cycle
+              when asserted (high pulse width adjustment).
+            $ref: /schemas/types.yaml#/definitions/uint32
+            maximum: 63
+
+        required:
+          - pinmux
+
+        additionalProperties: false
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - interrupts
+  - interrupt-controller
+  - '#interrupt-cells'
+  - gpio-controller
+  - '#gpio-cells'
+  - gpio-ranges
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+    #include <dt-bindings/pinctrl/mediatek,mt8163-pinfunc.h>
+
+    pio: pinctrl@10005000 {
+        compatible = "mediatek,mt8163-pinctrl";
+        reg = <0x10005000 0x1000>,
+              <0x1000b000 0x1000>;
+        reg-names = "base", "eint";
+        gpio-controller;
+        #gpio-cells = <2>;
+        gpio-ranges = <&pio 0 0 155>;
+        interrupt-controller;
+        interrupts = <GIC_SPI 153 IRQ_TYPE_LEVEL_HIGH>;
+        #interrupt-cells = <2>;
+
+        mmc0-default-pins {
+            pins-clk {
+                pinmux = <PINMUX_GPIO133__FUNC_MSDC0_CLK>;
+                bias-pull-down = <MTK_PUPD_SET_R1R0_01>;
+            };
+
+            pins-cmd-dat {
+                pinmux = <PINMUX_GPIO137__FUNC_MSDC0_DAT0>,
+                         <PINMUX_GPIO136__FUNC_MSDC0_DAT1>,
+                         <PINMUX_GPIO135__FUNC_MSDC0_DAT2>,
+                         <PINMUX_GPIO134__FUNC_MSDC0_DAT3>,
+                         <PINMUX_GPIO132__FUNC_MSDC0_CMD>;
+                input-enable;
+                bias-pull-up = <MTK_PUPD_SET_R1R0_01>;
+            };
+        };
+
+        uart0-pins {
+            pins-rx {
+                pinmux = <PINMUX_GPIO79__FUNC_URXD0>;
+                input-enable;
+                bias-pull-up;
+            };
+
+            pins-tx {
+                pinmux = <PINMUX_GPIO80__FUNC_UTXD0>;
+            };
+        };
+    };
diff --git a/include/dt-bindings/pinctrl/mediatek,mt8163-pinfunc.h b/include/dt-bindings/pinctrl/mediatek,mt8163-pinfunc.h
new file mode 100644
index 000000000000..1e932518d231
--- /dev/null
+++ b/include/dt-bindings/pinctrl/mediatek,mt8163-pinfunc.h
@@ -0,0 +1,821 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+/*
+ * Copyright (c) 2026 Ben Grisdale <bengris32@protonmail.ch>
+ */
+
+#ifndef _DT_BINDINGS_PINCTRL_MEDIATEK_MT8163_PINFUNC_H
+#define _DT_BINDINGS_PINCTRL_MEDIATEK_MT8163_PINFUNC_H
+
+#include <dt-bindings/pinctrl/mt65xx.h>
+
+#define PINMUX_GPIO0__FUNC_GPIO0			(MTK_PIN_NO(0) | 0)
+#define PINMUX_GPIO0__FUNC_PWRAP_SPI0_MO		(MTK_PIN_NO(0) | 1)
+#define PINMUX_GPIO0__FUNC_PWRAP_SPI0_MI		(MTK_PIN_NO(0) | 2)
+
+#define PINMUX_GPIO1__FUNC_GPIO1			(MTK_PIN_NO(1) | 0)
+#define PINMUX_GPIO1__FUNC_PWRAP_SPI0_MI		(MTK_PIN_NO(1) | 1)
+#define PINMUX_GPIO1__FUNC_PWRAP_SPI0_MO		(MTK_PIN_NO(1) | 2)
+
+#define PINMUX_GPIO2__FUNC_GPIO2			(MTK_PIN_NO(2) | 0)
+#define PINMUX_GPIO2__FUNC_I2S0_MCK			(MTK_PIN_NO(2) | 1)
+#define PINMUX_GPIO2__FUNC_I2S1_MCK			(MTK_PIN_NO(2) | 4)
+#define PINMUX_GPIO2__FUNC_I2S2_MCK			(MTK_PIN_NO(2) | 5)
+#define PINMUX_GPIO2__FUNC_I2S3_MCK			(MTK_PIN_NO(2) | 6)
+
+#define PINMUX_GPIO3__FUNC_GPIO3			(MTK_PIN_NO(3) | 0)
+#define PINMUX_GPIO3__FUNC_PWRAP_SPI0_CK		(MTK_PIN_NO(3) | 1)
+
+#define PINMUX_GPIO4__FUNC_GPIO4			(MTK_PIN_NO(4) | 0)
+#define PINMUX_GPIO4__FUNC_PWRAP_SPI0_CSN		(MTK_PIN_NO(4) | 1)
+
+#define PINMUX_GPIO5__FUNC_GPIO5			(MTK_PIN_NO(5) | 0)
+#define PINMUX_GPIO5__FUNC_I2S0_MCK			(MTK_PIN_NO(5) | 1)
+#define PINMUX_GPIO5__FUNC_ANT_SEL1			(MTK_PIN_NO(5) | 2)
+#define PINMUX_GPIO5__FUNC_VDEC_TEST_CK			(MTK_PIN_NO(5) | 3)
+#define PINMUX_GPIO5__FUNC_I2S1_MCK			(MTK_PIN_NO(5) | 4)
+#define PINMUX_GPIO5__FUNC_I2S2_MCK			(MTK_PIN_NO(5) | 5)
+#define PINMUX_GPIO5__FUNC_I2S3_MCK			(MTK_PIN_NO(5) | 6)
+#define PINMUX_GPIO5__FUNC_DBG_MON_B_0			(MTK_PIN_NO(5) | 7)
+
+#define PINMUX_GPIO6__FUNC_GPIO6			(MTK_PIN_NO(6) | 0)
+#define PINMUX_GPIO6__FUNC_I2S0_MCK			(MTK_PIN_NO(6) | 1)
+#define PINMUX_GPIO6__FUNC_ANT_SEL0			(MTK_PIN_NO(6) | 2)
+#define PINMUX_GPIO6__FUNC_MM_TEST_CK			(MTK_PIN_NO(6) | 3)
+#define PINMUX_GPIO6__FUNC_I2S1_MCK			(MTK_PIN_NO(6) | 4)
+#define PINMUX_GPIO6__FUNC_I2S2_MCK			(MTK_PIN_NO(6) | 5)
+#define PINMUX_GPIO6__FUNC_I2S3_MCK			(MTK_PIN_NO(6) | 6)
+#define PINMUX_GPIO6__FUNC_DBG_MON_B_1			(MTK_PIN_NO(6) | 7)
+
+#define PINMUX_GPIO7__FUNC_GPIO7			(MTK_PIN_NO(7) | 0)
+#define PINMUX_GPIO7__FUNC_AUD_CLK_MOSI			(MTK_PIN_NO(7) | 1)
+#define PINMUX_GPIO7__FUNC_I2S2_BCK			(MTK_PIN_NO(7) | 2)
+
+#define PINMUX_GPIO8__FUNC_GPIO8			(MTK_PIN_NO(8) | 0)
+#define PINMUX_GPIO8__FUNC_AUD_DAT_MISO			(MTK_PIN_NO(8) | 1)
+#define PINMUX_GPIO8__FUNC_I2S2_DI			(MTK_PIN_NO(8) | 2)
+#define PINMUX_GPIO8__FUNC_AUD_DAT_MOSI			(MTK_PIN_NO(8) | 3)
+
+#define PINMUX_GPIO9__FUNC_GPIO9			(MTK_PIN_NO(9) | 0)
+#define PINMUX_GPIO9__FUNC_AUD_DAT_MOSI			(MTK_PIN_NO(9) | 1)
+#define PINMUX_GPIO9__FUNC_I2S2_LRCK			(MTK_PIN_NO(9) | 2)
+#define PINMUX_GPIO9__FUNC_AUD_DAT_MISO			(MTK_PIN_NO(9) | 3)
+
+#define PINMUX_GPIO10__FUNC_GPIO10			(MTK_PIN_NO(10) | 0)
+#define PINMUX_GPIO10__FUNC_RTC32K_CK			(MTK_PIN_NO(10) | 1)
+
+#define PINMUX_GPIO11__FUNC_GPIO11			(MTK_PIN_NO(11) | 0)
+#define PINMUX_GPIO11__FUNC_WATCHDOG			(MTK_PIN_NO(11) | 1)
+
+#define PINMUX_GPIO12__FUNC_GPIO12			(MTK_PIN_NO(12) | 0)
+#define PINMUX_GPIO12__FUNC_SRCLKENA0			(MTK_PIN_NO(12) | 1)
+
+#define PINMUX_GPIO13__FUNC_GPIO13			(MTK_PIN_NO(13) | 0)
+#define PINMUX_GPIO13__FUNC_SRCLKENAI			(MTK_PIN_NO(13) | 1)
+
+#define PINMUX_GPIO14__FUNC_GPIO14			(MTK_PIN_NO(14) | 0)
+#define PINMUX_GPIO14__FUNC_URXD2			(MTK_PIN_NO(14) | 1)
+#define PINMUX_GPIO14__FUNC_DPI_D5			(MTK_PIN_NO(14) | 2)
+#define PINMUX_GPIO14__FUNC_UTXD2			(MTK_PIN_NO(14) | 3)
+#define PINMUX_GPIO14__FUNC_DBG_SCL			(MTK_PIN_NO(14) | 4)
+#define PINMUX_GPIO14__FUNC_SRCCLKENAI2			(MTK_PIN_NO(14) | 5)
+#define PINMUX_GPIO14__FUNC_I2S0_MCK			(MTK_PIN_NO(14) | 6)
+
+#define PINMUX_GPIO15__FUNC_GPIO15			(MTK_PIN_NO(15) | 0)
+#define PINMUX_GPIO15__FUNC_UTXD2			(MTK_PIN_NO(15) | 1)
+#define PINMUX_GPIO15__FUNC_DPI_HSYNC			(MTK_PIN_NO(15) | 2)
+#define PINMUX_GPIO15__FUNC_URXD2			(MTK_PIN_NO(15) | 3)
+#define PINMUX_GPIO15__FUNC_DBG_SDA			(MTK_PIN_NO(15) | 4)
+#define PINMUX_GPIO15__FUNC_I2S1_MCK			(MTK_PIN_NO(15) | 6)
+
+#define PINMUX_GPIO16__FUNC_GPIO16			(MTK_PIN_NO(16) | 0)
+#define PINMUX_GPIO16__FUNC_URXD3			(MTK_PIN_NO(16) | 1)
+#define PINMUX_GPIO16__FUNC_DPI_DE			(MTK_PIN_NO(16) | 2)
+#define PINMUX_GPIO16__FUNC_UTXD3			(MTK_PIN_NO(16) | 3)
+#define PINMUX_GPIO16__FUNC_UCTS2			(MTK_PIN_NO(16) | 4)
+#define PINMUX_GPIO16__FUNC_PWM_A			(MTK_PIN_NO(16) | 5)
+#define PINMUX_GPIO16__FUNC_I2S2_MCK			(MTK_PIN_NO(16) | 6)
+#define PINMUX_GPIO16__FUNC_TP_URXD3_AO			(MTK_PIN_NO(16) | 7)
+
+#define PINMUX_GPIO17__FUNC_GPIO17			(MTK_PIN_NO(17) | 0)
+#define PINMUX_GPIO17__FUNC_UTXD3			(MTK_PIN_NO(17) | 1)
+#define PINMUX_GPIO17__FUNC_DPI_VSYNC			(MTK_PIN_NO(17) | 2)
+#define PINMUX_GPIO17__FUNC_URXD3			(MTK_PIN_NO(17) | 3)
+#define PINMUX_GPIO17__FUNC_URTS2			(MTK_PIN_NO(17) | 4)
+#define PINMUX_GPIO17__FUNC_PWM_B			(MTK_PIN_NO(17) | 5)
+#define PINMUX_GPIO17__FUNC_I2S3_MCK			(MTK_PIN_NO(17) | 6)
+#define PINMUX_GPIO17__FUNC_TP_UTXD3_AO			(MTK_PIN_NO(17) | 7)
+
+#define PINMUX_GPIO18__FUNC_GPIO18			(MTK_PIN_NO(18) | 0)
+#define PINMUX_GPIO18__FUNC_PCM0_CLK			(MTK_PIN_NO(18) | 1)
+#define PINMUX_GPIO18__FUNC_DPI_D4			(MTK_PIN_NO(18) | 2)
+#define PINMUX_GPIO18__FUNC_I2S0_BCK0			(MTK_PIN_NO(18) | 3)
+#define PINMUX_GPIO18__FUNC_I2S3_BCK			(MTK_PIN_NO(18) | 4)
+#define PINMUX_GPIO18__FUNC_CONN_DSP_JCK		(MTK_PIN_NO(18) | 5)
+#define PINMUX_GPIO18__FUNC_IR				(MTK_PIN_NO(18) | 6)
+#define PINMUX_GPIO18__FUNC_DBG_MON_A_0			(MTK_PIN_NO(18) | 7)
+
+#define PINMUX_GPIO19__FUNC_GPIO19			(MTK_PIN_NO(19) | 0)
+#define PINMUX_GPIO19__FUNC_PCM0_SYNC			(MTK_PIN_NO(19) | 1)
+#define PINMUX_GPIO19__FUNC_DPI_D3			(MTK_PIN_NO(19) | 2)
+#define PINMUX_GPIO19__FUNC_I2S0_LRCK			(MTK_PIN_NO(19) | 3)
+#define PINMUX_GPIO19__FUNC_I2S3_LRCK			(MTK_PIN_NO(19) | 4)
+#define PINMUX_GPIO19__FUNC_CONN_DSP_JINTP		(MTK_PIN_NO(19) | 5)
+#define PINMUX_GPIO19__FUNC_EXT_COL			(MTK_PIN_NO(19) | 6)
+#define PINMUX_GPIO19__FUNC_DBG_MON_A_1			(MTK_PIN_NO(19) | 7)
+
+#define PINMUX_GPIO20__FUNC_GPIO20			(MTK_PIN_NO(20) | 0)
+#define PINMUX_GPIO20__FUNC_PCM0_DI			(MTK_PIN_NO(20) | 1)
+#define PINMUX_GPIO20__FUNC_DPI_D1			(MTK_PIN_NO(20) | 2)
+#define PINMUX_GPIO20__FUNC_I2S0_DI			(MTK_PIN_NO(20) | 3)
+#define PINMUX_GPIO20__FUNC_PCM0_DO			(MTK_PIN_NO(20) | 4)
+#define PINMUX_GPIO20__FUNC_CONN_DSP_JDI		(MTK_PIN_NO(20) | 5)
+#define PINMUX_GPIO20__FUNC_EXT_MDIO			(MTK_PIN_NO(20) | 6)
+#define PINMUX_GPIO20__FUNC_DBG_MON_A_2			(MTK_PIN_NO(20) | 7)
+
+#define PINMUX_GPIO21__FUNC_GPIO21			(MTK_PIN_NO(21) | 0)
+#define PINMUX_GPIO21__FUNC_PCM0_DO			(MTK_PIN_NO(21) | 1)
+#define PINMUX_GPIO21__FUNC_DPI_D2			(MTK_PIN_NO(21) | 2)
+#define PINMUX_GPIO21__FUNC_I2S3_DO			(MTK_PIN_NO(21) | 3)
+#define PINMUX_GPIO21__FUNC_PCM0_DI			(MTK_PIN_NO(21) | 4)
+#define PINMUX_GPIO21__FUNC_CONN_DSP_JMS		(MTK_PIN_NO(21) | 5)
+#define PINMUX_GPIO21__FUNC_EXT_MDC			(MTK_PIN_NO(21) | 6)
+#define PINMUX_GPIO21__FUNC_DBG_MON_A_3			(MTK_PIN_NO(21) | 7)
+
+#define PINMUX_GPIO22__FUNC_GPIO22			(MTK_PIN_NO(22) | 0)
+#define PINMUX_GPIO22__FUNC_PWM_B			(MTK_PIN_NO(22) | 1)
+#define PINMUX_GPIO22__FUNC_DPI_CK			(MTK_PIN_NO(22) | 2)
+#define PINMUX_GPIO22__FUNC_EXT_TXD0			(MTK_PIN_NO(22) | 4)
+#define PINMUX_GPIO22__FUNC_CONN_DSP_JDO		(MTK_PIN_NO(22) | 5)
+#define PINMUX_GPIO22__FUNC_DBG_MON_A_4			(MTK_PIN_NO(22) | 7)
+
+#define PINMUX_GPIO23__FUNC_GPIO23			(MTK_PIN_NO(23) | 0)
+#define PINMUX_GPIO23__FUNC_PWM_C			(MTK_PIN_NO(23) | 1)
+#define PINMUX_GPIO23__FUNC_DPI_D12			(MTK_PIN_NO(23) | 2)
+#define PINMUX_GPIO23__FUNC_EXT_TXD1			(MTK_PIN_NO(23) | 4)
+#define PINMUX_GPIO23__FUNC_CONN_MCU_TDO		(MTK_PIN_NO(23) | 5)
+#define PINMUX_GPIO23__FUNC_DBG_MON_A_5			(MTK_PIN_NO(23) | 7)
+
+#define PINMUX_GPIO24__FUNC_GPIO24			(MTK_PIN_NO(24) | 0)
+#define PINMUX_GPIO24__FUNC_CLKM0			(MTK_PIN_NO(24) | 1)
+#define PINMUX_GPIO24__FUNC_DPI_D13			(MTK_PIN_NO(24) | 2)
+#define PINMUX_GPIO24__FUNC_EXT_TXD2			(MTK_PIN_NO(24) | 4)
+#define PINMUX_GPIO24__FUNC_CONN_MCU_DBGACK_N		(MTK_PIN_NO(24) | 5)
+#define PINMUX_GPIO24__FUNC_DBG_MON_A_6			(MTK_PIN_NO(24) | 7)
+
+#define PINMUX_GPIO25__FUNC_GPIO25			(MTK_PIN_NO(25) | 0)
+#define PINMUX_GPIO25__FUNC_CLKM1			(MTK_PIN_NO(25) | 1)
+#define PINMUX_GPIO25__FUNC_DPI_D14			(MTK_PIN_NO(25) | 2)
+#define PINMUX_GPIO25__FUNC_SPI_MI			(MTK_PIN_NO(25) | 3)
+#define PINMUX_GPIO25__FUNC_EXT_TXD3			(MTK_PIN_NO(25) | 4)
+#define PINMUX_GPIO25__FUNC_CONN_MCU_DBGI_N		(MTK_PIN_NO(25) | 5)
+#define PINMUX_GPIO25__FUNC_DBG_MON_A_7			(MTK_PIN_NO(25) | 7)
+
+#define PINMUX_GPIO26__FUNC_GPIO26			(MTK_PIN_NO(26) | 0)
+#define PINMUX_GPIO26__FUNC_CLKM2			(MTK_PIN_NO(26) | 1)
+#define PINMUX_GPIO26__FUNC_DPI_D15			(MTK_PIN_NO(26) | 2)
+#define PINMUX_GPIO26__FUNC_SPI_MO			(MTK_PIN_NO(26) | 3)
+#define PINMUX_GPIO26__FUNC_EXT_TXC			(MTK_PIN_NO(26) | 4)
+#define PINMUX_GPIO26__FUNC_CONN_MCU_TCK0		(MTK_PIN_NO(26) | 5)
+#define PINMUX_GPIO26__FUNC_CONN_MCU_AICE_JCKC		(MTK_PIN_NO(26) | 6)
+#define PINMUX_GPIO26__FUNC_DBG_MON_A_8			(MTK_PIN_NO(26) | 7)
+
+#define PINMUX_GPIO27__FUNC_GPIO27			(MTK_PIN_NO(27) | 0)
+#define PINMUX_GPIO27__FUNC_UCTS2			(MTK_PIN_NO(27) | 1)
+#define PINMUX_GPIO27__FUNC_DPI_D16			(MTK_PIN_NO(27) | 2)
+#define PINMUX_GPIO27__FUNC_SPI_CSB			(MTK_PIN_NO(27) | 3)
+#define PINMUX_GPIO27__FUNC_EXT_RXER			(MTK_PIN_NO(27) | 4)
+#define PINMUX_GPIO27__FUNC_CONN_MCU_TDI		(MTK_PIN_NO(27) | 5)
+#define PINMUX_GPIO27__FUNC_DBG_MON_A_9			(MTK_PIN_NO(27) | 7)
+
+#define PINMUX_GPIO28__FUNC_GPIO28			(MTK_PIN_NO(28) | 0)
+#define PINMUX_GPIO28__FUNC_URTS2			(MTK_PIN_NO(28) | 1)
+#define PINMUX_GPIO28__FUNC_DPI_D17			(MTK_PIN_NO(28) | 2)
+#define PINMUX_GPIO28__FUNC_SPI_CLK			(MTK_PIN_NO(28) | 3)
+#define PINMUX_GPIO28__FUNC_EXT_RXC			(MTK_PIN_NO(28) | 4)
+#define PINMUX_GPIO28__FUNC_CONN_MCU_TRST_B		(MTK_PIN_NO(28) | 5)
+#define PINMUX_GPIO28__FUNC_DBG_MON_A_10		(MTK_PIN_NO(28) | 7)
+
+#define PINMUX_GPIO29__FUNC_GPIO29			(MTK_PIN_NO(29) | 0)
+#define PINMUX_GPIO29__FUNC_UCTS3			(MTK_PIN_NO(29) | 1)
+#define PINMUX_GPIO29__FUNC_DPI_D6			(MTK_PIN_NO(29) | 2)
+#define PINMUX_GPIO29__FUNC_SDA1_0			(MTK_PIN_NO(29) | 3)
+#define PINMUX_GPIO29__FUNC_EXT_RXDV			(MTK_PIN_NO(29) | 4)
+#define PINMUX_GPIO29__FUNC_CONN_MCU_TMS		(MTK_PIN_NO(29) | 5)
+#define PINMUX_GPIO29__FUNC_CONN_MCU_AICE_JMSC		(MTK_PIN_NO(29) | 6)
+#define PINMUX_GPIO29__FUNC_DBG_MON_A_11		(MTK_PIN_NO(29) | 7)
+
+#define PINMUX_GPIO30__FUNC_GPIO30			(MTK_PIN_NO(30) | 0)
+#define PINMUX_GPIO30__FUNC_URTS3			(MTK_PIN_NO(30) | 1)
+#define PINMUX_GPIO30__FUNC_CLKM3			(MTK_PIN_NO(30) | 2)
+#define PINMUX_GPIO30__FUNC_SCL1_0			(MTK_PIN_NO(30) | 3)
+#define PINMUX_GPIO30__FUNC_EXT_RXD0			(MTK_PIN_NO(30) | 4)
+#define PINMUX_GPIO30__FUNC_ANT_SEL0			(MTK_PIN_NO(30) | 5)
+#define PINMUX_GPIO30__FUNC_DPI_D7			(MTK_PIN_NO(30) | 6)
+#define PINMUX_GPIO30__FUNC_DBG_MON_B_2			(MTK_PIN_NO(30) | 7)
+
+#define PINMUX_GPIO31__FUNC_GPIO31			(MTK_PIN_NO(31) | 0)
+#define PINMUX_GPIO31__FUNC_CLKM4			(MTK_PIN_NO(31) | 1)
+#define PINMUX_GPIO31__FUNC_SDA2_0			(MTK_PIN_NO(31) | 2)
+#define PINMUX_GPIO31__FUNC_EXT_FRAME_SYNC		(MTK_PIN_NO(31) | 3)
+#define PINMUX_GPIO31__FUNC_EXT_RXD1			(MTK_PIN_NO(31) | 4)
+#define PINMUX_GPIO31__FUNC_ANT_SEL1			(MTK_PIN_NO(31) | 5)
+#define PINMUX_GPIO31__FUNC_DPI_D8			(MTK_PIN_NO(31) | 6)
+#define PINMUX_GPIO31__FUNC_DBG_MON_B_3			(MTK_PIN_NO(31) | 7)
+
+#define PINMUX_GPIO32__FUNC_GPIO32			(MTK_PIN_NO(32) | 0)
+#define PINMUX_GPIO32__FUNC_CLKM5			(MTK_PIN_NO(32) | 1)
+#define PINMUX_GPIO32__FUNC_SCL2_0			(MTK_PIN_NO(32) | 2)
+#define PINMUX_GPIO32__FUNC_EXT_FRAME_SYNC		(MTK_PIN_NO(32) | 3)
+#define PINMUX_GPIO32__FUNC_EXT_RXD2			(MTK_PIN_NO(32) | 4)
+#define PINMUX_GPIO32__FUNC_ANT_SEL2			(MTK_PIN_NO(32) | 5)
+#define PINMUX_GPIO32__FUNC_DPI_D9			(MTK_PIN_NO(32) | 6)
+#define PINMUX_GPIO32__FUNC_DBG_MON_B_4			(MTK_PIN_NO(32) | 7)
+
+#define PINMUX_GPIO33__FUNC_GPIO33			(MTK_PIN_NO(33) | 0)
+#define PINMUX_GPIO33__FUNC_KPROW0			(MTK_PIN_NO(33) | 1)
+#define PINMUX_GPIO33__FUNC_IMG_TEST_CK			(MTK_PIN_NO(33) | 4)
+#define PINMUX_GPIO33__FUNC_DBG_MON_A_12		(MTK_PIN_NO(33) | 7)
+
+#define PINMUX_GPIO34__FUNC_GPIO34			(MTK_PIN_NO(34) | 0)
+#define PINMUX_GPIO34__FUNC_KPROW1			(MTK_PIN_NO(34) | 1)
+#define PINMUX_GPIO34__FUNC_IDDIG			(MTK_PIN_NO(34) | 2)
+#define PINMUX_GPIO34__FUNC_EXT_FRAME_SYNC		(MTK_PIN_NO(34) | 3)
+#define PINMUX_GPIO34__FUNC_MFG_TEST_CK			(MTK_PIN_NO(34) | 4)
+#define PINMUX_GPIO34__FUNC_DBG_MON_B_5			(MTK_PIN_NO(34) | 7)
+
+#define PINMUX_GPIO35__FUNC_GPIO35			(MTK_PIN_NO(35) | 0)
+#define PINMUX_GPIO35__FUNC_KPROW2			(MTK_PIN_NO(35) | 1)
+#define PINMUX_GPIO35__FUNC_USB_DRVVBUS			(MTK_PIN_NO(35) | 2)
+#define PINMUX_GPIO35__FUNC_EXT_FRAME_SYNC		(MTK_PIN_NO(35) | 3)
+#define PINMUX_GPIO35__FUNC_CONN_TEST_CK		(MTK_PIN_NO(35) | 4)
+#define PINMUX_GPIO35__FUNC_DBG_MON_B_6			(MTK_PIN_NO(35) | 7)
+
+#define PINMUX_GPIO36__FUNC_GPIO36			(MTK_PIN_NO(36) | 0)
+#define PINMUX_GPIO36__FUNC_KPCOL0			(MTK_PIN_NO(36) | 1)
+#define PINMUX_GPIO36__FUNC_DBG_MON_A_13		(MTK_PIN_NO(36) | 7)
+
+#define PINMUX_GPIO37__FUNC_GPIO37			(MTK_PIN_NO(37) | 0)
+#define PINMUX_GPIO37__FUNC_KPCOL1			(MTK_PIN_NO(37) | 1)
+#define PINMUX_GPIO37__FUNC_MD32_JTAG_TRST		(MTK_PIN_NO(37) | 4)
+#define PINMUX_GPIO37__FUNC_DBG_MON_B_7			(MTK_PIN_NO(37) | 7)
+
+#define PINMUX_GPIO38__FUNC_GPIO38			(MTK_PIN_NO(38) | 0)
+#define PINMUX_GPIO38__FUNC_KPCOL2			(MTK_PIN_NO(38) | 1)
+#define PINMUX_GPIO38__FUNC_IDDIG			(MTK_PIN_NO(38) | 2)
+#define PINMUX_GPIO38__FUNC_EXT_FRAME_SYNC		(MTK_PIN_NO(38) | 3)
+#define PINMUX_GPIO38__FUNC_DBG_MON_B_8			(MTK_PIN_NO(38) | 7)
+
+#define PINMUX_GPIO39__FUNC_GPIO39			(MTK_PIN_NO(39) | 0)
+#define PINMUX_GPIO39__FUNC_JTMS			(MTK_PIN_NO(39) | 1)
+#define PINMUX_GPIO39__FUNC_CONN_MCU_TMS		(MTK_PIN_NO(39) | 2)
+#define PINMUX_GPIO39__FUNC_CONN_MCU_AICE_JMSC		(MTK_PIN_NO(39) | 3)
+#define PINMUX_GPIO39__FUNC_MD32_JTAG_TMS		(MTK_PIN_NO(39) | 4)
+#define PINMUX_GPIO39__FUNC_DFD_TMS_XI			(MTK_PIN_NO(39) | 5)
+
+#define PINMUX_GPIO40__FUNC_GPIO40			(MTK_PIN_NO(40) | 0)
+#define PINMUX_GPIO40__FUNC_JTCK			(MTK_PIN_NO(40) | 1)
+#define PINMUX_GPIO40__FUNC_CONN_MCU_TCK1		(MTK_PIN_NO(40) | 2)
+#define PINMUX_GPIO40__FUNC_CONN_MCU_AICE_JCKC		(MTK_PIN_NO(40) | 3)
+#define PINMUX_GPIO40__FUNC_MD32_JTAG_TCK		(MTK_PIN_NO(40) | 4)
+#define PINMUX_GPIO40__FUNC_DFD_TCK_XI			(MTK_PIN_NO(40) | 5)
+
+#define PINMUX_GPIO41__FUNC_GPIO41			(MTK_PIN_NO(41) | 0)
+#define PINMUX_GPIO41__FUNC_JTDI			(MTK_PIN_NO(41) | 1)
+#define PINMUX_GPIO41__FUNC_CONN_MCU_TDI		(MTK_PIN_NO(41) | 2)
+#define PINMUX_GPIO41__FUNC_MD32_JTAG_TDI		(MTK_PIN_NO(41) | 4)
+#define PINMUX_GPIO41__FUNC_DFD_TDI_XI			(MTK_PIN_NO(41) | 5)
+
+#define PINMUX_GPIO42__FUNC_GPIO42			(MTK_PIN_NO(42) | 0)
+#define PINMUX_GPIO42__FUNC_JTDO			(MTK_PIN_NO(42) | 1)
+#define PINMUX_GPIO42__FUNC_CONN_MCU_TDO		(MTK_PIN_NO(42) | 2)
+#define PINMUX_GPIO42__FUNC_MD32_JTAG_TDO		(MTK_PIN_NO(42) | 4)
+#define PINMUX_GPIO42__FUNC_DFD_TDO			(MTK_PIN_NO(42) | 5)
+
+#define PINMUX_GPIO43__FUNC_GPIO43			(MTK_PIN_NO(43) | 0)
+#define PINMUX_GPIO43__FUNC_CLKM4			(MTK_PIN_NO(43) | 1)
+#define PINMUX_GPIO43__FUNC_PWM_C			(MTK_PIN_NO(43) | 2)
+#define PINMUX_GPIO43__FUNC_ANT_SEL3			(MTK_PIN_NO(43) | 4)
+#define PINMUX_GPIO43__FUNC_DPI_D10			(MTK_PIN_NO(43) | 5)
+#define PINMUX_GPIO43__FUNC_EXT_RXD3			(MTK_PIN_NO(43) | 6)
+#define PINMUX_GPIO43__FUNC_DBG_MON_B_9			(MTK_PIN_NO(43) | 7)
+
+#define PINMUX_GPIO44__FUNC_GPIO44			(MTK_PIN_NO(44) | 0)
+#define PINMUX_GPIO44__FUNC_CLKM5			(MTK_PIN_NO(44) | 1)
+#define PINMUX_GPIO44__FUNC_PWM_A			(MTK_PIN_NO(44) | 2)
+#define PINMUX_GPIO44__FUNC_ANT_SEL4			(MTK_PIN_NO(44) | 4)
+#define PINMUX_GPIO44__FUNC_DPI_D11			(MTK_PIN_NO(44) | 5)
+#define PINMUX_GPIO44__FUNC_EXT_TXEN			(MTK_PIN_NO(44) | 6)
+#define PINMUX_GPIO44__FUNC_DBG_MON_B_10		(MTK_PIN_NO(44) | 7)
+
+#define PINMUX_GPIO45__FUNC_GPIO45			(MTK_PIN_NO(45) | 0)
+#define PINMUX_GPIO45__FUNC_SFCS0			(MTK_PIN_NO(45) | 3)
+#define PINMUX_GPIO45__FUNC_ANT_SEL5			(MTK_PIN_NO(45) | 4)
+#define PINMUX_GPIO45__FUNC_DPI_D0			(MTK_PIN_NO(45) | 5)
+#define PINMUX_GPIO45__FUNC_SPDIF			(MTK_PIN_NO(45) | 6)
+#define PINMUX_GPIO45__FUNC_DBG_MON_B_11		(MTK_PIN_NO(45) | 7)
+
+#define PINMUX_GPIO46__FUNC_GPIO46			(MTK_PIN_NO(46) | 0)
+#define PINMUX_GPIO46__FUNC_TP_GPIO0_AO			(MTK_PIN_NO(46) | 1)
+#define PINMUX_GPIO46__FUNC_I2S1_DO			(MTK_PIN_NO(46) | 2)
+#define PINMUX_GPIO46__FUNC_SFWP_B			(MTK_PIN_NO(46) | 3)
+#define PINMUX_GPIO46__FUNC_ANT_SEL1			(MTK_PIN_NO(46) | 4)
+#define PINMUX_GPIO46__FUNC_CONN_MCU_DBGACK_N		(MTK_PIN_NO(46) | 5)
+#define PINMUX_GPIO46__FUNC_NCLE			(MTK_PIN_NO(46) | 6)
+#define PINMUX_GPIO46__FUNC_DBG_MON_A_14		(MTK_PIN_NO(46) | 7)
+
+#define PINMUX_GPIO47__FUNC_GPIO47			(MTK_PIN_NO(47) | 0)
+#define PINMUX_GPIO47__FUNC_TP_GPIO1_AO			(MTK_PIN_NO(47) | 1)
+#define PINMUX_GPIO47__FUNC_I2S1_LRCK			(MTK_PIN_NO(47) | 2)
+#define PINMUX_GPIO47__FUNC_SFOUT			(MTK_PIN_NO(47) | 3)
+#define PINMUX_GPIO47__FUNC_ANT_SEL2			(MTK_PIN_NO(47) | 4)
+#define PINMUX_GPIO47__FUNC_CONN_MCU_DBGI_N		(MTK_PIN_NO(47) | 5)
+#define PINMUX_GPIO47__FUNC_NCEB1			(MTK_PIN_NO(47) | 6)
+#define PINMUX_GPIO47__FUNC_DBG_MON_A_15		(MTK_PIN_NO(47) | 7)
+
+#define PINMUX_GPIO48__FUNC_GPIO48			(MTK_PIN_NO(48) | 0)
+#define PINMUX_GPIO48__FUNC_I2S1_BCK			(MTK_PIN_NO(48) | 2)
+#define PINMUX_GPIO48__FUNC_SFHOLD			(MTK_PIN_NO(48) | 3)
+#define PINMUX_GPIO48__FUNC_ANT_SEL3			(MTK_PIN_NO(48) | 4)
+#define PINMUX_GPIO48__FUNC_CONN_MCU_TRST_B		(MTK_PIN_NO(48) | 5)
+#define PINMUX_GPIO48__FUNC_NCEB0			(MTK_PIN_NO(48) | 6)
+#define PINMUX_GPIO48__FUNC_DBG_MON_A_16		(MTK_PIN_NO(48) | 7)
+
+#define PINMUX_GPIO49__FUNC_GPIO49			(MTK_PIN_NO(49) | 0)
+#define PINMUX_GPIO49__FUNC_UCTS0			(MTK_PIN_NO(49) | 1)
+#define PINMUX_GPIO49__FUNC_SFIN			(MTK_PIN_NO(49) | 2)
+#define PINMUX_GPIO49__FUNC_CLKM0			(MTK_PIN_NO(49) | 3)
+#define PINMUX_GPIO49__FUNC_IDDIG			(MTK_PIN_NO(49) | 4)
+#define PINMUX_GPIO49__FUNC_ANT_SEL4			(MTK_PIN_NO(49) | 5)
+#define PINMUX_GPIO49__FUNC_NREB			(MTK_PIN_NO(49) | 6)
+#define PINMUX_GPIO49__FUNC_DBG_MON_A_17		(MTK_PIN_NO(49) | 7)
+
+#define PINMUX_GPIO50__FUNC_GPIO50			(MTK_PIN_NO(50) | 0)
+#define PINMUX_GPIO50__FUNC_URTS0			(MTK_PIN_NO(50) | 1)
+#define PINMUX_GPIO50__FUNC_CLKM3			(MTK_PIN_NO(50) | 2)
+#define PINMUX_GPIO50__FUNC_I2S3_LRCK			(MTK_PIN_NO(50) | 3)
+#define PINMUX_GPIO50__FUNC_USB_DRVVBUS			(MTK_PIN_NO(50) | 4)
+#define PINMUX_GPIO50__FUNC_ANT_SEL3			(MTK_PIN_NO(50) | 5)
+#define PINMUX_GPIO50__FUNC_I2S2_BCK			(MTK_PIN_NO(50) | 6)
+#define PINMUX_GPIO50__FUNC_DBG_MON_B_12		(MTK_PIN_NO(50) | 7)
+
+#define PINMUX_GPIO51__FUNC_GPIO51			(MTK_PIN_NO(51) | 0)
+#define PINMUX_GPIO51__FUNC_UCTS1			(MTK_PIN_NO(51) | 1)
+#define PINMUX_GPIO51__FUNC_I2S3_BCK			(MTK_PIN_NO(51) | 3)
+#define PINMUX_GPIO51__FUNC_CLKM1			(MTK_PIN_NO(51) | 4)
+#define PINMUX_GPIO51__FUNC_ANT_SEL4			(MTK_PIN_NO(51) | 5)
+#define PINMUX_GPIO51__FUNC_I2S2_DI			(MTK_PIN_NO(51) | 6)
+#define PINMUX_GPIO51__FUNC_DBG_MON_B_13		(MTK_PIN_NO(51) | 7)
+
+#define PINMUX_GPIO52__FUNC_GPIO52			(MTK_PIN_NO(52) | 0)
+#define PINMUX_GPIO52__FUNC_URTS1			(MTK_PIN_NO(52) | 1)
+#define PINMUX_GPIO52__FUNC_PCM1_DO			(MTK_PIN_NO(52) | 2)
+#define PINMUX_GPIO52__FUNC_I2S3_DO			(MTK_PIN_NO(52) | 3)
+#define PINMUX_GPIO52__FUNC_CLKM2			(MTK_PIN_NO(52) | 4)
+#define PINMUX_GPIO52__FUNC_ANT_SEL5			(MTK_PIN_NO(52) | 5)
+#define PINMUX_GPIO52__FUNC_I2S2_LRCK			(MTK_PIN_NO(52) | 6)
+#define PINMUX_GPIO52__FUNC_DBG_MON_B_14		(MTK_PIN_NO(52) | 7)
+
+#define PINMUX_GPIO53__FUNC_GPIO53			(MTK_PIN_NO(53) | 0)
+#define PINMUX_GPIO53__FUNC_SPI_CSB			(MTK_PIN_NO(53) | 1)
+#define PINMUX_GPIO53__FUNC_I2S0_DI			(MTK_PIN_NO(53) | 3)
+#define PINMUX_GPIO53__FUNC_I2S2_BCK			(MTK_PIN_NO(53) | 4)
+#define PINMUX_GPIO53__FUNC_DBG_MON_B_15		(MTK_PIN_NO(53) | 7)
+
+#define PINMUX_GPIO54__FUNC_GPIO54			(MTK_PIN_NO(54) | 0)
+#define PINMUX_GPIO54__FUNC_SPI_CLK			(MTK_PIN_NO(54) | 1)
+#define PINMUX_GPIO54__FUNC_I2S0_LRCK			(MTK_PIN_NO(54) | 3)
+#define PINMUX_GPIO54__FUNC_I2S2_DI			(MTK_PIN_NO(54) | 4)
+#define PINMUX_GPIO54__FUNC_DBG_MON_B_16		(MTK_PIN_NO(54) | 7)
+
+#define PINMUX_GPIO55__FUNC_GPIO55			(MTK_PIN_NO(55) | 0)
+#define PINMUX_GPIO55__FUNC_SPI_MI			(MTK_PIN_NO(55) | 1)
+#define PINMUX_GPIO55__FUNC_SPI_MO			(MTK_PIN_NO(55) | 2)
+#define PINMUX_GPIO55__FUNC_I2S0_BCK1			(MTK_PIN_NO(55) | 3)
+#define PINMUX_GPIO55__FUNC_I2S2_LRCK			(MTK_PIN_NO(55) | 4)
+#define PINMUX_GPIO55__FUNC_DBG_MON_B_17		(MTK_PIN_NO(55) | 7)
+
+#define PINMUX_GPIO56__FUNC_GPIO56			(MTK_PIN_NO(56) | 0)
+#define PINMUX_GPIO56__FUNC_SPI_MO			(MTK_PIN_NO(56) | 1)
+#define PINMUX_GPIO56__FUNC_SPI_MI			(MTK_PIN_NO(56) | 2)
+#define PINMUX_GPIO56__FUNC_I2S0_MCK			(MTK_PIN_NO(56) | 3)
+#define PINMUX_GPIO56__FUNC_I2S2_MCK			(MTK_PIN_NO(56) | 4)
+#define PINMUX_GPIO56__FUNC_DBG_MON_B_18		(MTK_PIN_NO(56) | 7)
+
+#define PINMUX_GPIO57__FUNC_GPIO57			(MTK_PIN_NO(57) | 0)
+#define PINMUX_GPIO57__FUNC_SDA1_0			(MTK_PIN_NO(57) | 1)
+
+#define PINMUX_GPIO58__FUNC_GPIO58			(MTK_PIN_NO(58) | 0)
+#define PINMUX_GPIO58__FUNC_SCL1_0			(MTK_PIN_NO(58) | 1)
+
+#define PINMUX_GPIO59__FUNC_GPIO59			(MTK_PIN_NO(59) | 0)
+#define PINMUX_GPIO59__FUNC_DISP_PWM			(MTK_PIN_NO(59) | 1)
+#define PINMUX_GPIO59__FUNC_PWM_B			(MTK_PIN_NO(59) | 2)
+#define PINMUX_GPIO59__FUNC_DBG_MON_A_18		(MTK_PIN_NO(59) | 7)
+
+#define PINMUX_GPIO60__FUNC_GPIO60			(MTK_PIN_NO(60) | 0)
+#define PINMUX_GPIO60__FUNC_WB_RSTB			(MTK_PIN_NO(60) | 1)
+#define PINMUX_GPIO60__FUNC_DBG_MON_A_19		(MTK_PIN_NO(60) | 7)
+
+#define PINMUX_GPIO61__FUNC_GPIO61			(MTK_PIN_NO(61) | 0)
+#define PINMUX_GPIO61__FUNC_F2W_DATA			(MTK_PIN_NO(61) | 1)
+#define PINMUX_GPIO61__FUNC_MRG_CLK			(MTK_PIN_NO(61) | 2)
+#define PINMUX_GPIO61__FUNC_DBG_MON_A_20		(MTK_PIN_NO(61) | 7)
+
+#define PINMUX_GPIO62__FUNC_GPIO62			(MTK_PIN_NO(62) | 0)
+#define PINMUX_GPIO62__FUNC_F2W_CK			(MTK_PIN_NO(62) | 1)
+#define PINMUX_GPIO62__FUNC_MRG_DI			(MTK_PIN_NO(62) | 2)
+#define PINMUX_GPIO62__FUNC_DBG_MON_A_21		(MTK_PIN_NO(62) | 7)
+
+#define PINMUX_GPIO63__FUNC_GPIO63			(MTK_PIN_NO(63) | 0)
+#define PINMUX_GPIO63__FUNC_WB_SCLK			(MTK_PIN_NO(63) | 1)
+#define PINMUX_GPIO63__FUNC_MRG_DO			(MTK_PIN_NO(63) | 2)
+#define PINMUX_GPIO63__FUNC_DBG_MON_A_22		(MTK_PIN_NO(63) | 7)
+
+#define PINMUX_GPIO64__FUNC_GPIO64			(MTK_PIN_NO(64) | 0)
+#define PINMUX_GPIO64__FUNC_WB_SDATA			(MTK_PIN_NO(64) | 1)
+#define PINMUX_GPIO64__FUNC_MRG_SYNC			(MTK_PIN_NO(64) | 2)
+#define PINMUX_GPIO64__FUNC_DBG_MON_A_23		(MTK_PIN_NO(64) | 7)
+
+#define PINMUX_GPIO65__FUNC_GPIO65			(MTK_PIN_NO(65) | 0)
+#define PINMUX_GPIO65__FUNC_WB_SEN			(MTK_PIN_NO(65) | 1)
+#define PINMUX_GPIO65__FUNC_DBG_MON_A_24		(MTK_PIN_NO(65) | 7)
+
+#define PINMUX_GPIO66__FUNC_GPIO66			(MTK_PIN_NO(66) | 0)
+#define PINMUX_GPIO66__FUNC_WB_CRTL0			(MTK_PIN_NO(66) | 1)
+#define PINMUX_GPIO66__FUNC_DFD_NTRST_XI		(MTK_PIN_NO(66) | 2)
+#define PINMUX_GPIO66__FUNC_DBG_MON_A_25		(MTK_PIN_NO(66) | 7)
+
+#define PINMUX_GPIO67__FUNC_GPIO67			(MTK_PIN_NO(67) | 0)
+#define PINMUX_GPIO67__FUNC_WB_CRTL1			(MTK_PIN_NO(67) | 1)
+#define PINMUX_GPIO67__FUNC_DFD_TMS_XI			(MTK_PIN_NO(67) | 2)
+#define PINMUX_GPIO67__FUNC_DBG_MON_A_26		(MTK_PIN_NO(67) | 7)
+
+#define PINMUX_GPIO68__FUNC_GPIO68			(MTK_PIN_NO(68) | 0)
+#define PINMUX_GPIO68__FUNC_WB_CRTL2			(MTK_PIN_NO(68) | 1)
+#define PINMUX_GPIO68__FUNC_DFD_TCK_XI			(MTK_PIN_NO(68) | 2)
+#define PINMUX_GPIO68__FUNC_DBG_MON_A_27		(MTK_PIN_NO(68) | 7)
+
+#define PINMUX_GPIO69__FUNC_GPIO69			(MTK_PIN_NO(69) | 0)
+#define PINMUX_GPIO69__FUNC_WB_CRTL3			(MTK_PIN_NO(69) | 1)
+#define PINMUX_GPIO69__FUNC_DFD_TDI_XI			(MTK_PIN_NO(69) | 2)
+#define PINMUX_GPIO69__FUNC_DBG_MON_A_28		(MTK_PIN_NO(69) | 7)
+
+#define PINMUX_GPIO70__FUNC_GPIO70			(MTK_PIN_NO(70) | 0)
+#define PINMUX_GPIO70__FUNC_WB_CRTL4			(MTK_PIN_NO(70) | 1)
+#define PINMUX_GPIO70__FUNC_DFD_TDO			(MTK_PIN_NO(70) | 2)
+#define PINMUX_GPIO70__FUNC_DBG_MON_A_29		(MTK_PIN_NO(70) | 7)
+
+#define PINMUX_GPIO71__FUNC_GPIO71			(MTK_PIN_NO(71) | 0)
+#define PINMUX_GPIO71__FUNC_WB_CRTL5			(MTK_PIN_NO(71) | 1)
+#define PINMUX_GPIO71__FUNC_DBG_MON_A_30		(MTK_PIN_NO(71) | 7)
+
+#define PINMUX_GPIO72__FUNC_GPIO72			(MTK_PIN_NO(72) | 0)
+#define PINMUX_GPIO72__FUNC_I2S0_DI			(MTK_PIN_NO(72) | 1)
+#define PINMUX_GPIO72__FUNC_PCM1_DI			(MTK_PIN_NO(72) | 2)
+#define PINMUX_GPIO72__FUNC_I2S3_DO			(MTK_PIN_NO(72) | 3)
+#define PINMUX_GPIO72__FUNC_I2S1_DO			(MTK_PIN_NO(72) | 4)
+#define PINMUX_GPIO72__FUNC_PWM_A			(MTK_PIN_NO(72) | 5)
+#define PINMUX_GPIO72__FUNC_I2S2_BCK			(MTK_PIN_NO(72) | 6)
+#define PINMUX_GPIO72__FUNC_DBG_MON_B_19		(MTK_PIN_NO(72) | 7)
+
+#define PINMUX_GPIO73__FUNC_GPIO73			(MTK_PIN_NO(73) | 0)
+#define PINMUX_GPIO73__FUNC_I2S0_LRCK			(MTK_PIN_NO(73) | 1)
+#define PINMUX_GPIO73__FUNC_PCM1_SYNC			(MTK_PIN_NO(73) | 2)
+#define PINMUX_GPIO73__FUNC_I2S3_LRCK			(MTK_PIN_NO(73) | 3)
+#define PINMUX_GPIO73__FUNC_I2S1_LRCK			(MTK_PIN_NO(73) | 4)
+#define PINMUX_GPIO73__FUNC_PWM_B			(MTK_PIN_NO(73) | 5)
+#define PINMUX_GPIO73__FUNC_I2S2_DI			(MTK_PIN_NO(73) | 6)
+#define PINMUX_GPIO73__FUNC_DBG_MON_B_20		(MTK_PIN_NO(73) | 7)
+
+#define PINMUX_GPIO74__FUNC_GPIO74			(MTK_PIN_NO(74) | 0)
+#define PINMUX_GPIO74__FUNC_I2S0_BCK2			(MTK_PIN_NO(74) | 1)
+#define PINMUX_GPIO74__FUNC_PCM1_CLK			(MTK_PIN_NO(74) | 2)
+#define PINMUX_GPIO74__FUNC_I2S3_BCK			(MTK_PIN_NO(74) | 3)
+#define PINMUX_GPIO74__FUNC_I2S1_BCK			(MTK_PIN_NO(74) | 4)
+#define PINMUX_GPIO74__FUNC_PWM_C			(MTK_PIN_NO(74) | 5)
+#define PINMUX_GPIO74__FUNC_I2S2_LRCK			(MTK_PIN_NO(74) | 6)
+#define PINMUX_GPIO74__FUNC_DBG_MON_B_21		(MTK_PIN_NO(74) | 7)
+
+#define PINMUX_GPIO75__FUNC_GPIO75			(MTK_PIN_NO(75) | 0)
+#define PINMUX_GPIO75__FUNC_SDA0_0			(MTK_PIN_NO(75) | 1)
+
+#define PINMUX_GPIO76__FUNC_GPIO76			(MTK_PIN_NO(76) | 0)
+#define PINMUX_GPIO76__FUNC_SCL0_0			(MTK_PIN_NO(76) | 1)
+
+#define PINMUX_GPIO77__FUNC_GPIO77			(MTK_PIN_NO(77) | 0)
+#define PINMUX_GPIO77__FUNC_SDA2_0			(MTK_PIN_NO(77) | 1)
+#define PINMUX_GPIO77__FUNC_PWM_B			(MTK_PIN_NO(77) | 2)
+
+#define PINMUX_GPIO78__FUNC_GPIO78			(MTK_PIN_NO(78) | 0)
+#define PINMUX_GPIO78__FUNC_SCL2_0			(MTK_PIN_NO(78) | 1)
+#define PINMUX_GPIO78__FUNC_PWM_C			(MTK_PIN_NO(78) | 2)
+
+#define PINMUX_GPIO79__FUNC_GPIO79			(MTK_PIN_NO(79) | 0)
+#define PINMUX_GPIO79__FUNC_URXD0			(MTK_PIN_NO(79) | 1)
+#define PINMUX_GPIO79__FUNC_UTXD0			(MTK_PIN_NO(79) | 2)
+
+#define PINMUX_GPIO80__FUNC_GPIO80			(MTK_PIN_NO(80) | 0)
+#define PINMUX_GPIO80__FUNC_UTXD0			(MTK_PIN_NO(80) | 1)
+#define PINMUX_GPIO80__FUNC_URXD0			(MTK_PIN_NO(80) | 2)
+
+#define PINMUX_GPIO81__FUNC_GPIO81			(MTK_PIN_NO(81) | 0)
+#define PINMUX_GPIO81__FUNC_URXD1			(MTK_PIN_NO(81) | 1)
+#define PINMUX_GPIO81__FUNC_UTXD1			(MTK_PIN_NO(81) | 2)
+
+#define PINMUX_GPIO82__FUNC_GPIO82			(MTK_PIN_NO(82) | 0)
+#define PINMUX_GPIO82__FUNC_UTXD1			(MTK_PIN_NO(82) | 1)
+#define PINMUX_GPIO82__FUNC_URXD1			(MTK_PIN_NO(82) | 2)
+
+#define PINMUX_GPIO83__FUNC_GPIO83			(MTK_PIN_NO(83) | 0)
+#define PINMUX_GPIO83__FUNC_LCM_RST			(MTK_PIN_NO(83) | 1)
+#define PINMUX_GPIO83__FUNC_VDAC_CK_XI			(MTK_PIN_NO(83) | 2)
+#define PINMUX_GPIO83__FUNC_DBG_MON_A_31		(MTK_PIN_NO(83) | 7)
+
+#define PINMUX_GPIO84__FUNC_GPIO84			(MTK_PIN_NO(84) | 0)
+#define PINMUX_GPIO84__FUNC_DSI_TE			(MTK_PIN_NO(84) | 1)
+#define PINMUX_GPIO84__FUNC_DBG_MON_A_32		(MTK_PIN_NO(84) | 7)
+
+#define PINMUX_GPIO85__FUNC_GPIO85			(MTK_PIN_NO(85) | 0)
+#define PINMUX_GPIO85__FUNC_MSDC2_CMD			(MTK_PIN_NO(85) | 1)
+#define PINMUX_GPIO85__FUNC_ANT_SEL0			(MTK_PIN_NO(85) | 2)
+#define PINMUX_GPIO85__FUNC_SDA1_0			(MTK_PIN_NO(85) | 3)
+#define PINMUX_GPIO85__FUNC_I2S3_BCK			(MTK_PIN_NO(85) | 6)
+#define PINMUX_GPIO85__FUNC_DBG_MON_B_22		(MTK_PIN_NO(85) | 7)
+
+#define PINMUX_GPIO86__FUNC_GPIO86			(MTK_PIN_NO(86) | 0)
+#define PINMUX_GPIO86__FUNC_MSDC2_CLK			(MTK_PIN_NO(86) | 1)
+#define PINMUX_GPIO86__FUNC_ANT_SEL1			(MTK_PIN_NO(86) | 2)
+#define PINMUX_GPIO86__FUNC_SCL1_0			(MTK_PIN_NO(86) | 3)
+#define PINMUX_GPIO86__FUNC_I2S3_LRCK			(MTK_PIN_NO(86) | 6)
+#define PINMUX_GPIO86__FUNC_DBG_MON_B_23		(MTK_PIN_NO(86) | 7)
+
+#define PINMUX_GPIO87__FUNC_GPIO87			(MTK_PIN_NO(87) | 0)
+#define PINMUX_GPIO87__FUNC_MSDC2_DAT0			(MTK_PIN_NO(87) | 1)
+#define PINMUX_GPIO87__FUNC_ANT_SEL2			(MTK_PIN_NO(87) | 2)
+#define PINMUX_GPIO87__FUNC_UTXD0			(MTK_PIN_NO(87) | 5)
+#define PINMUX_GPIO87__FUNC_I2S3_DO			(MTK_PIN_NO(87) | 6)
+#define PINMUX_GPIO87__FUNC_DBG_MON_B_24		(MTK_PIN_NO(87) | 7)
+
+#define PINMUX_GPIO88__FUNC_GPIO88			(MTK_PIN_NO(88) | 0)
+#define PINMUX_GPIO88__FUNC_MSDC2_DAT1			(MTK_PIN_NO(88) | 1)
+#define PINMUX_GPIO88__FUNC_ANT_SEL3			(MTK_PIN_NO(88) | 2)
+#define PINMUX_GPIO88__FUNC_PWM_A			(MTK_PIN_NO(88) | 3)
+#define PINMUX_GPIO88__FUNC_I2S3_MCK			(MTK_PIN_NO(88) | 4)
+#define PINMUX_GPIO88__FUNC_URXD0			(MTK_PIN_NO(88) | 5)
+#define PINMUX_GPIO88__FUNC_PWM_B			(MTK_PIN_NO(88) | 6)
+#define PINMUX_GPIO88__FUNC_DBG_MON_B_25		(MTK_PIN_NO(88) | 7)
+
+#define PINMUX_GPIO89__FUNC_GPIO89			(MTK_PIN_NO(89) | 0)
+#define PINMUX_GPIO89__FUNC_MSDC2_DAT2			(MTK_PIN_NO(89) | 1)
+#define PINMUX_GPIO89__FUNC_ANT_SEL4			(MTK_PIN_NO(89) | 2)
+#define PINMUX_GPIO89__FUNC_SDA2_0			(MTK_PIN_NO(89) | 3)
+#define PINMUX_GPIO89__FUNC_UTXD1			(MTK_PIN_NO(89) | 5)
+#define PINMUX_GPIO89__FUNC_PWM_C			(MTK_PIN_NO(89) | 6)
+#define PINMUX_GPIO89__FUNC_DBG_MON_B_26		(MTK_PIN_NO(89) | 7)
+
+#define PINMUX_GPIO90__FUNC_GPIO90			(MTK_PIN_NO(90) | 0)
+#define PINMUX_GPIO90__FUNC_MSDC2_DAT3			(MTK_PIN_NO(90) | 1)
+#define PINMUX_GPIO90__FUNC_ANT_SEL5			(MTK_PIN_NO(90) | 2)
+#define PINMUX_GPIO90__FUNC_SCL2_0			(MTK_PIN_NO(90) | 3)
+#define PINMUX_GPIO90__FUNC_EXT_FRAME_SYNC		(MTK_PIN_NO(90) | 4)
+#define PINMUX_GPIO90__FUNC_URXD1			(MTK_PIN_NO(90) | 5)
+#define PINMUX_GPIO90__FUNC_PWM_A			(MTK_PIN_NO(90) | 6)
+#define PINMUX_GPIO90__FUNC_DBG_MON_B_27		(MTK_PIN_NO(90) | 7)
+
+#define PINMUX_GPIO91__FUNC_GPI91			(MTK_PIN_NO(91) | 0)
+#define PINMUX_GPIO91__FUNC_TDN3			(MTK_PIN_NO(91) | 1)
+
+#define PINMUX_GPIO92__FUNC_GPI92			(MTK_PIN_NO(92) | 0)
+#define PINMUX_GPIO92__FUNC_TDP3			(MTK_PIN_NO(92) | 1)
+
+#define PINMUX_GPIO93__FUNC_GPI93			(MTK_PIN_NO(93) | 0)
+#define PINMUX_GPIO93__FUNC_TDN2			(MTK_PIN_NO(93) | 1)
+
+#define PINMUX_GPIO94__FUNC_GPI94			(MTK_PIN_NO(94) | 0)
+#define PINMUX_GPIO94__FUNC_TDP2			(MTK_PIN_NO(94) | 1)
+
+#define PINMUX_GPIO95__FUNC_GPI95			(MTK_PIN_NO(95) | 0)
+#define PINMUX_GPIO95__FUNC_TCN				(MTK_PIN_NO(95) | 1)
+
+#define PINMUX_GPIO96__FUNC_GPI96			(MTK_PIN_NO(96) | 0)
+#define PINMUX_GPIO96__FUNC_TCP				(MTK_PIN_NO(96) | 1)
+
+#define PINMUX_GPIO97__FUNC_GPI97			(MTK_PIN_NO(97) | 0)
+#define PINMUX_GPIO97__FUNC_TDN1			(MTK_PIN_NO(97) | 1)
+
+#define PINMUX_GPIO98__FUNC_GPI98			(MTK_PIN_NO(98) | 0)
+#define PINMUX_GPIO98__FUNC_TDP1			(MTK_PIN_NO(98) | 1)
+
+#define PINMUX_GPIO99__FUNC_GPI99			(MTK_PIN_NO(99) | 0)
+#define PINMUX_GPIO99__FUNC_TDN0			(MTK_PIN_NO(99) | 1)
+
+#define PINMUX_GPIO100__FUNC_GPI100			(MTK_PIN_NO(100) | 0)
+#define PINMUX_GPIO100__FUNC_TDP0			(MTK_PIN_NO(100) | 1)
+
+#define PINMUX_GPIO101__FUNC_GPI101			(MTK_PIN_NO(101) | 0)
+#define PINMUX_GPIO101__FUNC_RDN0			(MTK_PIN_NO(101) | 1)
+
+#define PINMUX_GPIO102__FUNC_GPI102			(MTK_PIN_NO(102) | 0)
+#define PINMUX_GPIO102__FUNC_RDP0			(MTK_PIN_NO(102) | 1)
+
+#define PINMUX_GPIO103__FUNC_GPI103			(MTK_PIN_NO(103) | 0)
+#define PINMUX_GPIO103__FUNC_RDN1			(MTK_PIN_NO(103) | 1)
+
+#define PINMUX_GPIO104__FUNC_GPI104			(MTK_PIN_NO(104) | 0)
+#define PINMUX_GPIO104__FUNC_RDP1			(MTK_PIN_NO(104) | 1)
+
+#define PINMUX_GPIO105__FUNC_GPI105			(MTK_PIN_NO(105) | 0)
+#define PINMUX_GPIO105__FUNC_RCN			(MTK_PIN_NO(105) | 1)
+
+#define PINMUX_GPIO106__FUNC_GPI106			(MTK_PIN_NO(106) | 0)
+#define PINMUX_GPIO106__FUNC_RCP			(MTK_PIN_NO(106) | 1)
+
+#define PINMUX_GPIO107__FUNC_GPI107			(MTK_PIN_NO(107) | 0)
+#define PINMUX_GPIO107__FUNC_RDN2			(MTK_PIN_NO(107) | 1)
+#define PINMUX_GPIO107__FUNC_CMDAT8			(MTK_PIN_NO(107) | 2)
+
+#define PINMUX_GPIO108__FUNC_GPI108			(MTK_PIN_NO(108) | 0)
+#define PINMUX_GPIO108__FUNC_RDP2			(MTK_PIN_NO(108) | 1)
+#define PINMUX_GPIO108__FUNC_CMDAT9			(MTK_PIN_NO(108) | 2)
+
+#define PINMUX_GPIO109__FUNC_GPI109			(MTK_PIN_NO(109) | 0)
+#define PINMUX_GPIO109__FUNC_RDN3			(MTK_PIN_NO(109) | 1)
+#define PINMUX_GPIO109__FUNC_CMDAT4			(MTK_PIN_NO(109) | 2)
+
+#define PINMUX_GPIO110__FUNC_GPI110			(MTK_PIN_NO(110) | 0)
+#define PINMUX_GPIO110__FUNC_RDP3			(MTK_PIN_NO(110) | 1)
+#define PINMUX_GPIO110__FUNC_CMDAT5			(MTK_PIN_NO(110) | 2)
+
+#define PINMUX_GPIO111__FUNC_GPI111			(MTK_PIN_NO(111) | 0)
+#define PINMUX_GPIO111__FUNC_RCN_A			(MTK_PIN_NO(111) | 1)
+#define PINMUX_GPIO111__FUNC_CMDAT6			(MTK_PIN_NO(111) | 2)
+
+#define PINMUX_GPIO112__FUNC_GPI112			(MTK_PIN_NO(112) | 0)
+#define PINMUX_GPIO112__FUNC_RCP_A			(MTK_PIN_NO(112) | 1)
+#define PINMUX_GPIO112__FUNC_CMDAT7			(MTK_PIN_NO(112) | 2)
+
+#define PINMUX_GPIO113__FUNC_GPI113			(MTK_PIN_NO(113) | 0)
+#define PINMUX_GPIO113__FUNC_RDN1_A			(MTK_PIN_NO(113) | 1)
+#define PINMUX_GPIO113__FUNC_CMDAT2			(MTK_PIN_NO(113) | 2)
+#define PINMUX_GPIO113__FUNC_CMCSD2			(MTK_PIN_NO(113) | 3)
+
+#define PINMUX_GPIO114__FUNC_GPI114			(MTK_PIN_NO(114) | 0)
+#define PINMUX_GPIO114__FUNC_RDP1_A			(MTK_PIN_NO(114) | 1)
+#define PINMUX_GPIO114__FUNC_CMDAT3			(MTK_PIN_NO(114) | 2)
+#define PINMUX_GPIO114__FUNC_CMCSD3			(MTK_PIN_NO(114) | 3)
+
+#define PINMUX_GPIO115__FUNC_GPI115			(MTK_PIN_NO(115) | 0)
+#define PINMUX_GPIO115__FUNC_RDN0_A			(MTK_PIN_NO(115) | 1)
+#define PINMUX_GPIO115__FUNC_CMHSYNC			(MTK_PIN_NO(115) | 2)
+
+#define PINMUX_GPIO116__FUNC_GPI116			(MTK_PIN_NO(116) | 0)
+#define PINMUX_GPIO116__FUNC_RDP0_A			(MTK_PIN_NO(116) | 1)
+#define PINMUX_GPIO116__FUNC_CMVSYNC			(MTK_PIN_NO(116) | 2)
+
+#define PINMUX_GPIO117__FUNC_GPIO117			(MTK_PIN_NO(117) | 0)
+#define PINMUX_GPIO117__FUNC_CMDAT0			(MTK_PIN_NO(117) | 1)
+#define PINMUX_GPIO117__FUNC_CMCSD0			(MTK_PIN_NO(117) | 2)
+#define PINMUX_GPIO117__FUNC_ANT_SEL2			(MTK_PIN_NO(117) | 3)
+#define PINMUX_GPIO117__FUNC_DBG_MON_B_28		(MTK_PIN_NO(117) | 7)
+
+#define PINMUX_GPIO118__FUNC_GPIO118			(MTK_PIN_NO(118) | 0)
+#define PINMUX_GPIO118__FUNC_CMDAT1			(MTK_PIN_NO(118) | 1)
+#define PINMUX_GPIO118__FUNC_CMCSD1			(MTK_PIN_NO(118) | 2)
+#define PINMUX_GPIO118__FUNC_ANT_SEL3			(MTK_PIN_NO(118) | 3)
+#define PINMUX_GPIO118__FUNC_CMFLASH			(MTK_PIN_NO(118) | 4)
+#define PINMUX_GPIO118__FUNC_DBG_MON_B_29		(MTK_PIN_NO(118) | 7)
+
+#define PINMUX_GPIO119__FUNC_GPIO119			(MTK_PIN_NO(119) | 0)
+#define PINMUX_GPIO119__FUNC_CMMCLK			(MTK_PIN_NO(119) | 1)
+#define PINMUX_GPIO119__FUNC_ANT_SEL4			(MTK_PIN_NO(119) | 3)
+#define PINMUX_GPIO119__FUNC_DBG_MON_B_30		(MTK_PIN_NO(119) | 7)
+
+#define PINMUX_GPIO120__FUNC_GPIO120			(MTK_PIN_NO(120) | 0)
+#define PINMUX_GPIO120__FUNC_CMPCLK			(MTK_PIN_NO(120) | 1)
+#define PINMUX_GPIO120__FUNC_CMCSK			(MTK_PIN_NO(120) | 2)
+#define PINMUX_GPIO120__FUNC_ANT_SEL5			(MTK_PIN_NO(120) | 3)
+#define PINMUX_GPIO120__FUNC_DBG_MON_B_31		(MTK_PIN_NO(120) | 7)
+
+#define PINMUX_GPIO121__FUNC_GPIO121			(MTK_PIN_NO(121) | 0)
+#define PINMUX_GPIO121__FUNC_MSDC1_CMD			(MTK_PIN_NO(121) | 1)
+
+#define PINMUX_GPIO122__FUNC_GPIO122			(MTK_PIN_NO(122) | 0)
+#define PINMUX_GPIO122__FUNC_MSDC1_CLK			(MTK_PIN_NO(122) | 1)
+#define PINMUX_GPIO122__FUNC_MD32_JTAG_TCK		(MTK_PIN_NO(122) | 2)
+
+#define PINMUX_GPIO123__FUNC_GPIO123			(MTK_PIN_NO(123) | 0)
+#define PINMUX_GPIO123__FUNC_MSDC1_DAT0			(MTK_PIN_NO(123) | 1)
+#define PINMUX_GPIO123__FUNC_MD32_JTAG_TMS		(MTK_PIN_NO(123) | 2)
+
+#define PINMUX_GPIO124__FUNC_GPIO124			(MTK_PIN_NO(124) | 0)
+#define PINMUX_GPIO124__FUNC_MSDC1_DAT1			(MTK_PIN_NO(124) | 1)
+#define PINMUX_GPIO124__FUNC_MD32_JTAG_TDI		(MTK_PIN_NO(124) | 2)
+
+#define PINMUX_GPIO125__FUNC_GPIO125			(MTK_PIN_NO(125) | 0)
+#define PINMUX_GPIO125__FUNC_MSDC1_DAT2			(MTK_PIN_NO(125) | 1)
+#define PINMUX_GPIO125__FUNC_MD32_JTAG_TDO		(MTK_PIN_NO(125) | 2)
+
+#define PINMUX_GPIO126__FUNC_GPIO126			(MTK_PIN_NO(126) | 0)
+#define PINMUX_GPIO126__FUNC_MSDC1_DAT3			(MTK_PIN_NO(126) | 1)
+#define PINMUX_GPIO126__FUNC_MD32_JTAG_TRST		(MTK_PIN_NO(126) | 2)
+
+#define PINMUX_GPIO127__FUNC_GPIO127			(MTK_PIN_NO(127) | 0)
+#define PINMUX_GPIO127__FUNC_MSDC0_DAT7			(MTK_PIN_NO(127) | 1)
+#define PINMUX_GPIO127__FUNC_NLD7			(MTK_PIN_NO(127) | 4)
+
+#define PINMUX_GPIO128__FUNC_GPIO128			(MTK_PIN_NO(128) | 0)
+#define PINMUX_GPIO128__FUNC_MSDC0_DAT6			(MTK_PIN_NO(128) | 1)
+#define PINMUX_GPIO128__FUNC_NLD6			(MTK_PIN_NO(128) | 4)
+
+#define PINMUX_GPIO129__FUNC_GPIO129			(MTK_PIN_NO(129) | 0)
+#define PINMUX_GPIO129__FUNC_MSDC0_DAT5			(MTK_PIN_NO(129) | 1)
+#define PINMUX_GPIO129__FUNC_NLD4			(MTK_PIN_NO(129) | 4)
+
+#define PINMUX_GPIO130__FUNC_GPIO130			(MTK_PIN_NO(130) | 0)
+#define PINMUX_GPIO130__FUNC_MSDC0_DAT4			(MTK_PIN_NO(130) | 1)
+#define PINMUX_GPIO130__FUNC_NLD3			(MTK_PIN_NO(130) | 4)
+
+#define PINMUX_GPIO131__FUNC_GPIO131			(MTK_PIN_NO(131) | 0)
+#define PINMUX_GPIO131__FUNC_MSDC0_RSTB			(MTK_PIN_NO(131) | 1)
+#define PINMUX_GPIO131__FUNC_NLD0			(MTK_PIN_NO(131) | 4)
+
+#define PINMUX_GPIO132__FUNC_GPIO132			(MTK_PIN_NO(132) | 0)
+#define PINMUX_GPIO132__FUNC_MSDC0_CMD			(MTK_PIN_NO(132) | 1)
+#define PINMUX_GPIO132__FUNC_NALE			(MTK_PIN_NO(132) | 4)
+
+#define PINMUX_GPIO133__FUNC_GPIO133			(MTK_PIN_NO(133) | 0)
+#define PINMUX_GPIO133__FUNC_MSDC0_CLK			(MTK_PIN_NO(133) | 1)
+#define PINMUX_GPIO133__FUNC_NWEB			(MTK_PIN_NO(133) | 4)
+
+#define PINMUX_GPIO134__FUNC_GPIO134			(MTK_PIN_NO(134) | 0)
+#define PINMUX_GPIO134__FUNC_MSDC0_DAT3			(MTK_PIN_NO(134) | 1)
+#define PINMUX_GPIO134__FUNC_NLD1			(MTK_PIN_NO(134) | 4)
+
+#define PINMUX_GPIO135__FUNC_GPIO135			(MTK_PIN_NO(135) | 0)
+#define PINMUX_GPIO135__FUNC_MSDC0_DAT2			(MTK_PIN_NO(135) | 1)
+#define PINMUX_GPIO135__FUNC_NLD5			(MTK_PIN_NO(135) | 4)
+
+#define PINMUX_GPIO136__FUNC_GPIO136			(MTK_PIN_NO(136) | 0)
+#define PINMUX_GPIO136__FUNC_MSDC0_DAT1			(MTK_PIN_NO(136) | 1)
+#define PINMUX_GPIO136__FUNC_NLD8			(MTK_PIN_NO(136) | 4)
+
+#define PINMUX_GPIO137__FUNC_GPIO137			(MTK_PIN_NO(137) | 0)
+#define PINMUX_GPIO137__FUNC_MSDC0_DAT0			(MTK_PIN_NO(137) | 1)
+#define PINMUX_GPIO137__FUNC_WATCHDOG			(MTK_PIN_NO(137) | 4)
+#define PINMUX_GPIO137__FUNC_NLD2			(MTK_PIN_NO(137) | 5)
+
+#define PINMUX_GPIO138__FUNC_GPIO138			(MTK_PIN_NO(138) | 0)
+#define PINMUX_GPIO138__FUNC_CEC			(MTK_PIN_NO(138) | 1)
+
+#define PINMUX_GPIO139__FUNC_GPIO139			(MTK_PIN_NO(139) | 0)
+#define PINMUX_GPIO139__FUNC_HTPLG			(MTK_PIN_NO(139) | 1)
+
+#define PINMUX_GPIO140__FUNC_GPIO140			(MTK_PIN_NO(140) | 0)
+#define PINMUX_GPIO140__FUNC_HDMISCK			(MTK_PIN_NO(140) | 1)
+
+#define PINMUX_GPIO141__FUNC_GPIO141			(MTK_PIN_NO(141) | 0)
+#define PINMUX_GPIO141__FUNC_HDMISD			(MTK_PIN_NO(141) | 1)
+
+#define PINMUX_GPIO142__FUNC_GPIO142			(MTK_PIN_NO(142) | 0)
+#define PINMUX_GPIO142__FUNC_NRNB			(MTK_PIN_NO(142) | 1)
+#define PINMUX_GPIO142__FUNC_ANT_SEL0			(MTK_PIN_NO(142) | 2)
+#define PINMUX_GPIO142__FUNC_SFCK			(MTK_PIN_NO(142) | 3)
+#define PINMUX_GPIO142__FUNC_DBG_MON_B_32		(MTK_PIN_NO(142) | 7)
+
+#define PINMUX_GPIO143__FUNC_GPIO143			(MTK_PIN_NO(143) | 0)
+#define PINMUX_GPIO143__FUNC_MSDC3_DAT7			(MTK_PIN_NO(143) | 1)
+
+#define PINMUX_GPIO144__FUNC_GPIO144			(MTK_PIN_NO(144) | 0)
+#define PINMUX_GPIO144__FUNC_MSDC3_DAT6			(MTK_PIN_NO(144) | 1)
+
+#define PINMUX_GPIO145__FUNC_GPIO145			(MTK_PIN_NO(145) | 0)
+#define PINMUX_GPIO145__FUNC_MSDC3_DAT5			(MTK_PIN_NO(145) | 1)
+
+#define PINMUX_GPIO146__FUNC_GPIO146			(MTK_PIN_NO(146) | 0)
+#define PINMUX_GPIO146__FUNC_MSDC3_DAT4			(MTK_PIN_NO(146) | 1)
+
+#define PINMUX_GPIO147__FUNC_GPIO147			(MTK_PIN_NO(147) | 0)
+#define PINMUX_GPIO147__FUNC_MSDC3_RSTB			(MTK_PIN_NO(147) | 1)
+
+#define PINMUX_GPIO148__FUNC_GPIO148			(MTK_PIN_NO(148) | 0)
+#define PINMUX_GPIO148__FUNC_MSDC3_CMD			(MTK_PIN_NO(148) | 1)
+
+#define PINMUX_GPIO149__FUNC_GPIO149			(MTK_PIN_NO(149) | 0)
+#define PINMUX_GPIO149__FUNC_MSDC3_CLK			(MTK_PIN_NO(149) | 1)
+
+#define PINMUX_GPIO150__FUNC_GPIO150			(MTK_PIN_NO(150) | 0)
+#define PINMUX_GPIO150__FUNC_MSDC3_DAT3			(MTK_PIN_NO(150) | 1)
+
+#define PINMUX_GPIO151__FUNC_GPIO151			(MTK_PIN_NO(151) | 0)
+#define PINMUX_GPIO151__FUNC_MSDC3_DAT2			(MTK_PIN_NO(151) | 1)
+
+#define PINMUX_GPIO152__FUNC_GPIO152			(MTK_PIN_NO(152) | 0)
+#define PINMUX_GPIO152__FUNC_MSDC3_DAT1			(MTK_PIN_NO(152) | 1)
+
+#define PINMUX_GPIO153__FUNC_GPIO153			(MTK_PIN_NO(153) | 0)
+#define PINMUX_GPIO153__FUNC_MSDC3_DAT0			(MTK_PIN_NO(153) | 1)
+
+#define PINMUX_GPIO154__FUNC_GPIO154			(MTK_PIN_NO(154) | 0)
+#define PINMUX_GPIO154__FUNC_MSDC3_DSL			(MTK_PIN_NO(154) | 1)
+
+#endif /* _DT_BINDINGS_PINCTRL_MEDIATEK_MT8163_PINFUNC_H */

-- 
2.56.0

