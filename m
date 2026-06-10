From: Jia Wang <wangjia@ultrarisc.com>
Date: Wed, 10 Jun 2026 13:29:55 +0800
Subject: [PATCH v4 1/2] dt-bindings: pinctrl: Add UltraRISC DP1000 pinctrl
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260610-ultrarisc-pinctrl-v4-1-b7e9b2a8ed84@ultrarisc.com>
References: <20260610-ultrarisc-pinctrl-v4-0-b7e9b2a8ed84@ultrarisc.com>
In-Reply-To: <20260610-ultrarisc-pinctrl-v4-0-b7e9b2a8ed84@ultrarisc.com>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781069395; l=4553;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=HDhBrs4WQFdifP+U6mC2pKW12Nvlscm7MFaLWDp8vUI=;
 b=6MhhPtIU8EPspqTjVIy5+cc3s5GzUmDoxiSOq2Xhq4WEL+4NWF9dTgnu6yEf4oO8YQl1FfJ6d
 WhjotP0i7zxAsd+BwQdWKSoa/auZL6G6Pr+OZkly2iWRkBxs/Na+poN
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add doc for the pinctrl controllers on the UltraRISC DP1000 RISC-V SoC.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
Reviewed-by: Conor Dooley <conor.dooley@microchip.com>
---
 .../bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml | 130 +++++++++++++++++++++
 MAINTAINERS                                        |   6 +
 2 files changed, 136 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml
new file mode 100644
index 000000000000..c2332e6e60c2
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml
@@ -0,0 +1,130 @@
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
+          List of pins affected by this state node, using numeric pin IDs.
+          Pins 0-39 correspond to ports A-D, and pins 40-52 correspond
+          to LPC0-LPC12.
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
+    soc {
+      #address-cells = <2>;
+      #size-cells = <2>;
+
+      pinctrl@11081000 {
+        compatible = "ultrarisc,dp1000-pinctrl";
+        reg = <0x0 0x11081000 0x0 0x1000>;
+
+        i2c0-pins {
+          pins = <12 13>;
+          function = "i2c";
+          bias-pull-up;
+          drive-strength = <33>;
+        };
+
+        uart0-pins {
+          pins = <8 9>;
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

-- 
2.34.1

