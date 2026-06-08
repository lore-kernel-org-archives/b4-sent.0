From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 08 Jun 2026 15:50:48 +0800
Subject: [PATCH v3 1/2] dt-bindings: pinctrl: Add UltraRISC DP1000 pinctrl
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260608-ultrarisc-pinctrl-v3-1-30a09ed74275@ultrarisc.com>
References: <20260608-ultrarisc-pinctrl-v3-0-30a09ed74275@ultrarisc.com>
In-Reply-To: <20260608-ultrarisc-pinctrl-v3-0-30a09ed74275@ultrarisc.com>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780905056; l=6164;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=7wc/wuKQeJWHUpB2jV9O8lTrj2MDNsGF0val+jwMTt0=;
 b=kNDXWzK+1UWP/XsomtpYZC9kyWyikrUUfgyzlmkbSPDh4dGmCQrFwAwdu53+gJB2v/z7mLaqz
 7tFL3+gdEBeAm+unh9tj1BLrSuWeQdQME32e0/MYgazCIFu6+1cDWxh
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add doc for the pinctrl controllers on the UltraRISC DP1000 RISC-V SoC.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 .../bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml | 131 +++++++++++++++++++++
 MAINTAINERS                                        |   6 +
 .../dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h |  63 ++++++++++
 3 files changed, 200 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml
new file mode 100644
index 000000000000..a64fbfc616db
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml
@@ -0,0 +1,131 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pinctrl/ultrarisc,dp1000-pinctrl.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: UltraRISC DP1000 Pin Controller
+
+maintainers:
+  - Jia Wang <wangjia@ultrarisc.com>
+
+description: |
+  UltraRISC RISC-V SoC DP1000 pin controller.
+  The controller manages ports A, B, C, D and LPC. Ports A-D default to
+  GPIO and provide additional SPI, UART, I2C, and PWM mux functions.
+  LPC pins default to the LPC interface and can be muxed to eSPI.
+  All pins also support pin configuration, including drive strength,
+  pull-up, and pull-down settings.
+
+properties:
+  compatible:
+    const: ultrarisc,dp1000-pinctrl
+
+  reg:
+    items:
+      - description: pin controller registers
+
+required:
+  - compatible
+  - reg
+
+patternProperties:
+  '.*-pins$':
+    type: object
+    unevaluatedProperties: false
+    allOf:
+      - $ref: /schemas/pinctrl/pincfg-node.yaml#
+      - $ref: /schemas/pinctrl/pinmux-node.yaml#
+      - if:
+          properties:
+            pins:
+              items:
+                minimum: 40
+                maximum: 52
+        then:
+          properties:
+            function:
+              enum:
+                - lpc
+                - espi
+        else:
+          properties:
+            pins:
+              items:
+                maximum: 39
+            function:
+              enum:
+                - gpio
+                - i2c
+                - pwm
+                - spi
+                - uart
+
+    properties:
+      pins:
+        description: |
+          List of pins affected by this state node, using the numeric pin IDs
+          defined in dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h.
+        $ref: /schemas/types.yaml#/definitions/uint32-array
+        minItems: 1
+        uniqueItems: true
+        items:
+          minimum: 0
+          maximum: 52
+
+      function:
+        description: |
+          Mux function to select for the listed pins. Supported functions
+          depend on the selected pins and match the DP1000 hardware mux
+          table.
+        enum:
+          - gpio
+          - i2c
+          - pwm
+          - spi
+          - uart
+          - lpc
+          - espi
+
+      bias-disable: true
+      bias-high-impedance: true
+      bias-pull-up: true
+      bias-pull-down: true
+
+      drive-strength:
+        description: Output drive strength in mA.
+        enum: [20, 27, 33, 40]
+
+    required:
+      - pins
+      - function
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h>
+
+    soc {
+      #address-cells = <2>;
+      #size-cells = <2>;
+
+      pinctrl@11081000 {
+        compatible = "ultrarisc,dp1000-pinctrl";
+        reg = <0x0 0x11081000 0x0 0x1000>;
+
+        i2c0-pins {
+          pins = <PA12 PA13>;
+          function = "i2c";
+          bias-pull-up;
+          drive-strength = <33>;
+        };
+
+        uart0-pins {
+          pins = <PA8 PA9>;
+          function = "uart";
+          bias-pull-up;
+          drive-strength = <33>;
+        };
+      };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index e035a3be797c..1ef874d342a5 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -27357,6 +27357,12 @@ S:	Maintained
 F:	drivers/usb/common/ulpi.c
 F:	include/linux/ulpi/
 
+ULTRARISC DP1000 PINCTRL DRIVER
+M:	Jia Wang <wangjia@ultrarisc.com>
+L:	linux-gpio@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml
+
 ULTRATRONIK BOARD SUPPORT
 M:	Goran Rađenović <goran.radni@gmail.com>
 M:	Börge Strümpfel <boerge.struempfel@gmail.com>
diff --git a/include/dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h b/include/dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h
new file mode 100644
index 000000000000..f800c9722471
--- /dev/null
+++ b/include/dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h
@@ -0,0 +1,63 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+/*
+ * Copyright (C) 2026 UltraRISC Technology (Shanghai) Co., Ltd.
+ */
+
+#ifndef _DT_BINDINGS_PINCTRL_ULTRARISC_DP1000_H
+#define _DT_BINDINGS_PINCTRL_ULTRARISC_DP1000_H
+
+#define PA0		0
+#define PA1		1
+#define PA2		2
+#define PA3		3
+#define PA4		4
+#define PA5		5
+#define PA6		6
+#define PA7		7
+#define PA8		8
+#define PA9		9
+#define PA10		10
+#define PA11		11
+#define PA12		12
+#define PA13		13
+#define PA14		14
+#define PA15		15
+#define PB0		16
+#define PB1		17
+#define PB2		18
+#define PB3		19
+#define PB4		20
+#define PB5		21
+#define PB6		22
+#define PB7		23
+#define PC0		24
+#define PC1		25
+#define PC2		26
+#define PC3		27
+#define PC4		28
+#define PC5		29
+#define PC6		30
+#define PC7		31
+#define PD0		32
+#define PD1		33
+#define PD2		34
+#define PD3		35
+#define PD4		36
+#define PD5		37
+#define PD6		38
+#define PD7		39
+#define LPC0		40
+#define LPC1		41
+#define LPC2		42
+#define LPC3		43
+#define LPC4		44
+#define LPC5		45
+#define LPC6		46
+#define LPC7		47
+#define LPC8		48
+#define LPC9		49
+#define LPC10		50
+#define LPC11		51
+#define LPC12		52
+
+#endif /* _DT_BINDINGS_PINCTRL_ULTRARISC_DP1000_H */

-- 
2.34.1

