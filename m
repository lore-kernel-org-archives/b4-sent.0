From: Han Gao <gaohan@iscas.ac.cn>
Date: Thu, 22 Oct 2026 03:53:28 +0800
Subject: [PATCH 08/18] dt-bindings: pinctrl: add Zhihe A210 pin controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-a210-init-v1-8-5e438f972d24@iscas.ac.cn>
References: <20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn>
In-Reply-To: <20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Icenowy Zheng <uwu@icenowy.me>, 
 Drew Fustini <fustini@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792612403; l=6873;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=UjyMLJHv24b1f1K2PwMfqU3RXI4khSvr/rvgT5wb0RM=;
 b=qH9Md8y4uPL6GMtnPMahiXVxkkXKZosnteylMj1yxR6VvnUb6Xb4zumNbJsvcC3hQIEPRBsTH
 dho8VK7k+RpCcxJ+AQR7N9lz9cxEDGv2o0WGQodBLwQE/TMMpN0AMrD
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>

Add bindings for the four A210 pad controllers. Describe the shared
PERI3 SDIO mux and per-pad bias controls.

Signed-off-by: Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 .../bindings/pinctrl/zhihe,a210-pinctrl.yaml       | 206 +++++++++++++++++++++
 1 file changed, 206 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/zhihe,a210-pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/zhihe,a210-pinctrl.yaml
new file mode 100644
index 000000000000..51cbb0189f47
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/zhihe,a210-pinctrl.yaml
@@ -0,0 +1,206 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pinctrl/zhihe,a210-pinctrl.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: ZhiHe A210 pin controller
+
+maintainers:
+  - Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>
+
+description: |
+  Pinmux and pinconf controller of the ZhiHe A210 RISC-V SoC.
+
+  The pads of the A210 are split into four groups, each managed by its
+  own pad controller with a separate register range:
+
+    AON pad controller     -> zhihe,a210-aon-pinctrl
+    PADCTRL0 (peripheral1) -> zhihe,a210-peri1-pinctrl
+    PADCTRL1 (peripheral2) -> zhihe,a210-peri2-pinctrl
+    PADCTRL2 (peripheral3) -> zhihe,a210-peri3-pinctrl
+
+  Each pad can be muxed individually to up to 8 different functions,
+  though for most pads only a few of those configurations are valid.
+  A few pads in the AON group do not support muxing or configuration
+  at all.
+
+  AON, PERI1 and PERI2 pads support configurable drive strength, bias,
+  input enable, Schmitt trigger and slew rate. PERI3 has a separate pad
+  layout: its six SDIO pads share one mux bit. Select their function with
+  the "sdio" group. Per-pad bias can be configured independently.
+
+properties:
+  compatible:
+    enum:
+      - zhihe,a210-aon-pinctrl
+      - zhihe,a210-peri1-pinctrl
+      - zhihe,a210-peri2-pinctrl
+      - zhihe,a210-peri3-pinctrl
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    maxItems: 1
+
+  clock-names:
+    const: pclk
+
+patternProperties:
+  '-[0-9]+$':
+    type: object
+
+    description:
+      A pinmux group referenced by a consumer's pinctrl phandle. It
+      contains one subnode per set of pads sharing the same pinmux and
+      pinconf settings.
+
+    additionalProperties: false
+
+    patternProperties:
+      '-pins$':
+        type: object
+        $ref: /schemas/pinctrl/pincfg-node.yaml#
+
+        description:
+          A pinctrl node describing the pinmux and pinconf settings of
+          one or more pads.
+
+        properties:
+          pins:
+            $ref: /schemas/pinctrl/pinmux-node.yaml#/properties/pins
+            description: List of pads that properties in the node apply to.
+
+          groups:
+            items:
+              - const: sdio
+
+          function:
+            $ref: /schemas/pinctrl/pinmux-node.yaml#/properties/function
+            enum: [ aouart, aouart_ir, aogpio0, aogpio1, aoi2c0, aoi2c1,
+                    aospi, jtag, reset, por, pmic, dvs, uart0, uart1,
+                    uart2, uart3, uart4, uart5, uart6, uart7, uart8,
+                    uart9, uart0_ir, uart1_ir, uart2_ir, uart3_ir,
+                    uart4_ir, uart5_ir, uart6_ir, uart7_ir, uart8_ir,
+                    uart9_ir, gpio0, gpio1, gpio2, gpio3, gpio4, gmac0,
+                    gmac1, spi0, spi1, qspi0, qspi1, pwm0, pwm1, pwm2,
+                    can0, can1, can2, i2s0, i2s1, i2s2, i2s3, i2c0, i2c1,
+                    i2c2, i2c3, i2c4, i2c5, i2c6, i2c7, i2c7_smb, sdio,
+                    isp0, dptx, usb31, sata_p0, sata_p1, hdmi, zmac,
+                    bsel, dbgm, cdbg, pdm, tdm, pcie_x1, pcie_x4,
+                    sen_vclk ]
+            description: The mux function to select for the given pins.
+
+          bias-disable: true
+
+          bias-pull-up: true
+
+          bias-pull-down: true
+
+          drive-strength:
+            enum: [ 1, 2, 3, 5, 7, 8, 10, 12, 13, 15, 16, 18, 20, 21, 23,
+                    25 ]
+            description: Drive strength in mA.
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
+            maximum: 1
+
+        oneOf:
+          - required: [pins]
+          - required: [groups]
+
+        additionalProperties: false
+
+allOf:
+  - if:
+      properties:
+        compatible:
+          const: zhihe,a210-peri3-pinctrl
+    then:
+      patternProperties:
+        '-[0-9]+$':
+          patternProperties:
+            '-pins$':
+              properties:
+                pins:
+                  items:
+                    enum: [SDIO_CLK, SDIO_CMD, SDIO_DAT0, SDIO_DAT1,
+                           SDIO_DAT2, SDIO_DAT3]
+                function:
+                  enum: [sdio, gpio4]
+                drive-strength: false
+                input-enable: false
+                input-disable: false
+                input-schmitt-enable: false
+                input-schmitt-disable: false
+                slew-rate: false
+              if:
+                required: [function]
+              then:
+                required: [groups]
+    else:
+      patternProperties:
+        '-[0-9]+$':
+          patternProperties:
+            '-pins$':
+              properties:
+                groups: false
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - clock-names
+
+additionalProperties: false
+
+examples:
+  - |
+    pinctrl@2026000 {
+        compatible = "zhihe,a210-peri1-pinctrl";
+        reg = <0x2026000 0x1000>;
+        clocks = <&clk 0>;
+        clock-names = "pclk";
+
+        gmac0-0 {
+            gmac0-pins {
+                bias-disable;
+                drive-strength = <13>;
+                function = "gmac0";
+                input-disable;
+                input-schmitt-disable;
+                pins = "GPIO0_0", "GPIO0_12";
+                slew-rate = <0>;
+            };
+        };
+    };
+
+  - |
+    pinctrl@542000 {
+        compatible = "zhihe,a210-peri3-pinctrl";
+        reg = <0x542000 0x1000>;
+        clocks = <&clk 0>;
+        clock-names = "pclk";
+
+        sdio-0 {
+            cmd-data-pins {
+                bias-pull-up;
+                pins = "SDIO_CMD", "SDIO_DAT0", "SDIO_DAT1",
+                       "SDIO_DAT2", "SDIO_DAT3";
+            };
+
+            sdio-pins {
+                function = "sdio";
+                groups = "sdio";
+            };
+        };
+    };

-- 
2.55.0

