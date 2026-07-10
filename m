From: Nikolai Burov <nikolai.burov@jolla.com>
Date: Fri, 10 Jul 2026 18:00:23 +0300
Subject: [PATCH 1/3] dt-bindings: pinctrl: mediatek: Add MT6858
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-mt6858-pinctrl-v1-1-f75ab558f0df@jolla.com>
References: <20260710-mt6858-pinctrl-v1-0-f75ab558f0df@jolla.com>
In-Reply-To: <20260710-mt6858-pinctrl-v1-0-f75ab558f0df@jolla.com>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Nikolai Burov <nikolai.burov@jolla.com>, 
 Nikolai Burov <nikolai.burov+review@abscue.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783695712; l=6222;
 i=nikolai.burov@jolla.com; s=20260707; h=from:subject:message-id;
 bh=U7dRrQcnHMvcUYGQp4E4aCTMv/3kcFO5A3mfR3b5VKA=;
 b=HnotYZqqNjHTI6n5qlMRKSVHw1W9kEEfyE9QXNGgwP1ATHxQ6tj83dkPGYQtzxEk8kGcJLy37
 lvuLV55ZwQJBz82+nH896hN2cMrwqh2so7FTxOJpob0uCdU4c7g1YO/
X-Developer-Key: i=nikolai.burov@jolla.com; a=ed25519;
 pk=yzpa+PD+ovHUFMIOBA9o2QqGwI110jM6hdGHLc7jtoQ=
X-Endpoint-Received: by B4 Relay for nikolai.burov@jolla.com/20260707 with auth_id=859
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add new DT bindings for the pin controller found in the MT6858
(MediaTek Dimensity 7100) SoC.

Signed-off-by: Nikolai Burov <nikolai.burov@jolla.com>
---
 .../bindings/pinctrl/mediatek,mt6858-pinctrl.yaml  | 190 +++++++++++++++++++++
 1 file changed, 190 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/mediatek,mt6858-pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/mediatek,mt6858-pinctrl.yaml
new file mode 100644
index 000000000000..263830a6e9db
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/mediatek,mt6858-pinctrl.yaml
@@ -0,0 +1,190 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pinctrl/mediatek,mt6858-pinctrl.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: MediaTek MT6858 Pin Controller
+
+maintainers:
+  - Nikolai Burov <nikolai.burov@jolla.com>
+
+description:
+  The MediaTek's MT6858 Pin controller is used to control SoC pins.
+
+properties:
+  compatible:
+    const: mediatek,mt6858-pinctrl
+
+  reg:
+    items:
+      - description: gpio base
+      - description: lm group IO
+      - description: rb group IO
+      - description: bm2 group IO
+      - description: bm group IO
+      - description: bm1 group IO
+      - description: lt group IO
+      - description: lt1 group IO
+      - description: rt group IO
+      - description: rt1 group IO
+      - description: eint-s group IO
+      - description: eint-w group IO
+      - description: eint-e group IO
+      - description: eint-c group IO
+
+  reg-names:
+    items:
+      - const: base
+      - const: lm
+      - const: rb
+      - const: bm2
+      - const: bm
+      - const: bm1
+      - const: lt
+      - const: lt1
+      - const: rt
+      - const: rt1
+      - const: eint-s
+      - const: eint-w
+      - const: eint-e
+      - const: eint-c
+
+  interrupts:
+    maxItems: 1
+
+  interrupt-controller: true
+
+  '#interrupt-cells':
+    const: 2
+
+  gpio-controller: true
+
+  '#gpio-cells':
+    const: 2
+
+  gpio-ranges:
+    maxItems: 1
+
+  gpio-line-names: true
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
+        $ref: /schemas/pinctrl/pincfg-node.yaml
+        additionalProperties: false
+        description:
+          A pinctrl node should contain at least one subnodes representing the
+          pinctrl groups available on the machine. Each subnode will list the
+          pins it needs, and how they should be configured, with regard to muxer
+          configuration, pullups, drive strength, input enable/disable and input
+          schmitt.
+
+        properties:
+          pinmux:
+            description:
+              Integer array, represents gpio pin number and mux setting.
+              Supported pin number and mux varies for different SoCs, and are
+              defined as macros in arch/arm64/boot/dts/mediatek/mt6858-pinfunc.h
+              for this SoC.
+
+          drive-strength:
+            enum: [2, 4, 6, 8, 10, 12, 14, 16]
+
+          bias-pull-down:
+            oneOf:
+              - type: boolean
+                description: normal pull down.
+              - enum: [100, 101, 102, 103]
+                description: PUPD/R1/R0 pull down type. See MTK_PUPD_SET_R1R0_
+                  defines in dt-bindings/pinctrl/mt65xx.h.
+              - enum: [200, 201, 202, 203]
+                description: RSEL pull down type. See MTK_PULL_SET_RSEL_ defines
+                  in dt-bindings/pinctrl/mt65xx.h.
+
+          bias-pull-up:
+            oneOf:
+              - type: boolean
+                description: normal pull up.
+              - enum: [100, 101, 102, 103]
+                description: PUPD/R1/R0 pull up type. See MTK_PUPD_SET_R1R0_
+                  defines in dt-bindings/pinctrl/mt65xx.h.
+              - enum: [200, 201, 202, 203]
+                description: RSEL pull up type. See MTK_PULL_SET_RSEL_ defines
+                  in dt-bindings/pinctrl/mt65xx.h.
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
+        required:
+          - pinmux
+
+required:
+  - compatible
+  - reg
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
+    #include <dt-bindings/pinctrl/mt65xx.h>
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+    #define PINMUX_GPIO149__FUNC_SCL5 (MTK_PIN_NO(149) | 1)
+    #define PINMUX_GPIO150__FUNC_SDA5 (MTK_PIN_NO(150) | 1)
+
+    pio: pinctrl@10005000 {
+        compatible = "mediatek,mt6858-pinctrl";
+        reg = <0x10005000 0x1000>,
+              <0x11b20000 0x1000>,
+              <0x11c10000 0x1000>,
+              <0x11d10000 0x1000>,
+              <0x11d30000 0x1000>,
+              <0x11d40000 0x1000>,
+              <0x11e20000 0x1000>,
+              <0x11e30000 0x1000>,
+              <0x11ed0000 0x1000>,
+              <0x11ee0000 0x1000>,
+              <0x11b00000 0x1000>,
+              <0x11e60000 0x1000>,
+              <0x11e80000 0x1000>,
+              <0x1c01e000 0x1000>;
+        reg-names = "base", "lm", "rb", "bm2", "bm", "bm1", "lt", "lt1",
+                    "rt", "rt1", "eint-s", "eint-w", "eint-e", "eint-c";
+        gpio-controller;
+        #gpio-cells = <2>;
+        gpio-ranges = <&pio 0 0 197>;
+        interrupt-controller;
+        interrupts = <GIC_SPI 239 IRQ_TYPE_LEVEL_HIGH 0>;
+        #interrupt-cells = <2>;
+
+        i2c5-pins {
+            pins {
+                pinmux = <PINMUX_GPIO149__FUNC_SCL5>,
+                         <PINMUX_GPIO150__FUNC_SDA5>;
+                bias-disable;
+            };
+        };
+    };

-- 
2.54.0

