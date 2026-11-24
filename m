From: Joseph Telaak <joseph@telaak.dev>
Date: Mon, 23 Nov 2026 23:42:06 -0500
Subject: [PATCH v2 1/2] dt-bindings: pinctrl: Add Siflower SF19A2890 pin
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-sf19a2890-pinctrl-v2-1-a10af32bc844@telaak.dev>
References: <20261123-sf19a2890-pinctrl-v2-0-a10af32bc844@telaak.dev>
In-Reply-To: <20261123-sf19a2890-pinctrl-v2-0-a10af32bc844@telaak.dev>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Chuanhong Guo <gch981213@gmail.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 linux-mips@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795495327; l=4669;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=iTyoSTe09I7B16n7YHrhvYb3JC5vGh8ZVWkZrBFowLk=;
 b=fp8UIVwaXrMyz03ygr5JTFQkQnSbI9eqkHW4ZZPpHFX/Ct2DqTZUR+ORE12pWdHYIMswgy3dX
 lodd2pqWGfSDl2xFIouYtD1Z/ADy48G89Il0mCLI7/fiv1w74mqiI5E
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The pin controller of the Siflower SF19A2890 selects the function of
each of its 49 pins and sets their bias, input enable, Schmitt trigger
and drive strength. Each pin has a register pair of its own, and each
pin state node holds subnodes that set some of its pins.

Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 .../pinctrl/siflower,sf19a2890-pinctrl.yaml        | 113 +++++++++++++++++++++
 MAINTAINERS                                        |   6 ++
 2 files changed, 119 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/siflower,sf19a2890-pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/siflower,sf19a2890-pinctrl.yaml
new file mode 100644
index 000000000000..0bb7c896f9bd
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/siflower,sf19a2890-pinctrl.yaml
@@ -0,0 +1,113 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pinctrl/siflower,sf19a2890-pinctrl.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Siflower SF19A2890 pin controller
+
+maintainers:
+  - Joseph Telaak <joseph@telaak.dev>
+
+description:
+  The pin controller of the Siflower SF19A2890 selects the function of
+  each of its 49 pins and sets their bias, input enable, Schmitt trigger
+  and drive strength. The GPIO function is selected through the GPIO
+  controller, which maps its lines onto these pins with gpio-ranges.
+
+properties:
+  compatible:
+    const: siflower,sf19a2890-pinctrl
+
+  reg:
+    maxItems: 1
+
+patternProperties:
+  '-pins$':
+    type: object
+    description:
+      A pin state. Each subnode sets the function and configuration of
+      some of its pins.
+
+    patternProperties:
+      '^pins(-[a-z0-9]+)*$':
+        type: object
+        allOf:
+          - $ref: /schemas/pinctrl/pincfg-node.yaml#
+          - $ref: /schemas/pinctrl/pinmux-node.yaml#
+
+        properties:
+          pins:
+            items:
+              enum: [JTAG_TDO, JTAG_TDI, JTAG_TMS, JTAG_TCK, JTAG_RST,
+                     SPI_TXD, SPI_RXD, SPI_CLK, SPI_CSN, UART_TX, UART_RX,
+                     I2C_DAT, I2C_CLK, RGMII_GTX_CLK, RGMII_TXCLK,
+                     RGMII_TXD0, RGMII_TXD1, RGMII_TXD2, RGMII_TXD3,
+                     RGMII_TXCTL, RGMII_RXCLK, RGMII_RXD0, RGMII_RXD1,
+                     RGMII_RXD2, RGMII_RXD3, RGMII_RXCTL, RGMII_COL,
+                     RGMII_CRS, RGMII_MDC, RGMII_MDIO, HB0_PA_EN,
+                     HB0_LNA_EN, HB0_SW_CTRL0, HB0_SW_CTRL1, HB1_PA_EN,
+                     HB1_LNA_EN, HB1_SW_CTRL0, HB1_SW_CTRL1, LB0_PA_EN,
+                     LB0_LNA_EN, LB0_SW_CTRL0, LB0_SW_CTRL1, LB1_PA_EN,
+                     LB1_LNA_EN, LB1_SW_CTRL0, LB1_SW_CTRL1, CLK_OUT,
+                     EXT_CLK_IN, DRVVBUS0]
+            minItems: 1
+            maxItems: 49
+
+          function:
+            enum: [i2c0, jtag, mdio, pwm0, pwm1, rgmii, spi, uart0, uart1,
+                   uart2, wlan]
+
+          bias-disable: true
+
+          bias-pull-up: true
+
+          bias-pull-down: true
+
+          input-enable: true
+
+          input-schmitt-enable: true
+
+          input-schmitt-disable: true
+
+          drive-strength:
+            description: Output drive strength in mA.
+            enum: [6, 9, 12, 15, 18, 21, 24, 27]
+
+        required:
+          - pins
+
+        additionalProperties: false
+
+    additionalProperties: false
+
+required:
+  - compatible
+  - reg
+
+allOf:
+  - $ref: pinctrl.yaml#
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    pinctrl@19e3fc00 {
+        compatible = "siflower,sf19a2890-pinctrl";
+        reg = <0x19e3fc00 0x400>;
+
+        uart0-pins {
+            pins-rx {
+                bias-pull-up;
+                function = "uart0";
+                input-enable;
+                pins = "UART_RX";
+            };
+
+            pins-tx {
+                bias-pull-up;
+                function = "uart0";
+                pins = "UART_TX";
+            };
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 9270abea0e12..9a31712feb5d 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25077,6 +25077,12 @@ N:	sifive
 K:	fu[57]40
 K:	[^@]sifive
 
+SIFLOWER SF19A2890 PINCTRL DRIVER
+M:	Joseph Telaak <joseph@telaak.dev>
+L:	linux-gpio@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/pinctrl/siflower,sf19a2890-pinctrl.yaml
+
 SILEAD TOUCHSCREEN DRIVER
 M:	Hans de Goede <hansg@kernel.org>
 L:	linux-input@vger.kernel.org

-- 
Git-155)

