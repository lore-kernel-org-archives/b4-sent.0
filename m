From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 01 Jun 2026 17:56:34 +0800
Subject: [PATCH v2 1/2] dt-bindings: pinctrl: Add UltraRISC DP1000 pinctrl
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260601-ultrarisc-pinctrl-v2-1-07ac5130a96d@ultrarisc.com>
References: <20260601-ultrarisc-pinctrl-v2-0-07ac5130a96d@ultrarisc.com>
In-Reply-To: <20260601-ultrarisc-pinctrl-v2-0-07ac5130a96d@ultrarisc.com>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780307879; l=4423;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=QbsxCQTIuyBKTJOUlammUU+55ZwaJc2BlpF5Um24hcM=;
 b=y6iuw9elfpivfVlw3O1dOm1WFyTsHFra73s30p3h5CsTovk3B7bdvhVosE4fbUgLAhd9ssjfe
 nbe0/ytDazJBpvloIeCP1nzofeVUTyCwxJBtv8QXUW3UiQ4PCBEOKFf
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add doc for the pinctrl controllers on the UltraRISC DP1000 RISC-V SoC.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 .../bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml | 128 +++++++++++++++++++++
 MAINTAINERS                                        |   6 +
 2 files changed, 134 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml
new file mode 100644
index 000000000000..5100033c18c3
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml
@@ -0,0 +1,128 @@
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
+              contains:
+                pattern: '^LPC([0-9]|1[0-2])$'
+        then:
+          properties:
+            function:
+              enum:
+                - lpc
+                - espi
+
+    properties:
+      pins:
+        description: List of pins affected by this state node.
+        minItems: 1
+        uniqueItems: true
+        items:
+          type: string
+          oneOf:
+            - pattern: '^PA([0-9]|1[0-5])$'
+            - pattern: '^PB[0-7]$'
+            - pattern: '^PC[0-7]$'
+            - pattern: '^PD[0-7]$'
+            - pattern: '^LPC([0-9]|1[0-2])$'
+
+      function:
+        description: |
+          Mux function to select for the listed pins. Supported functions
+          depend on the selected pins and match the DP1000 hardware mux
+          table.
+        enum:
+          - gpio
+          - i2c0
+          - i2c1
+          - i2c2
+          - i2c3
+          - pwm0
+          - pwm1
+          - pwm2
+          - pwm3
+          - spi0
+          - spi1
+          - uart0
+          - uart1
+          - uart2
+          - uart3
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
+    soc {
+      #address-cells = <2>;
+      #size-cells = <2>;
+
+      pinctrl@11081000 {
+        compatible = "ultrarisc,dp1000-pinctrl";
+        reg = <0x0 0x11081000 0x0 0x1000>;
+
+        i2c0-pins {
+          pins = "PA12", "PA13";
+          function = "i2c0";
+          bias-pull-up;
+          drive-strength = <33>;
+        };
+
+        uart0-pins {
+          pins = "PA8", "PA9";
+          function = "uart0";
+          bias-pull-up;
+          drive-strength = <33>;
+        };
+      };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 461a3eed6129..6fd7ce6365fb 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -27356,6 +27356,12 @@ S:	Maintained
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

-- 
2.34.1

