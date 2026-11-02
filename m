From: Han Gao <gaohan@iscas.ac.cn>
Date: Tue, 03 Nov 2026 03:45:09 +0800
Subject: [PATCH RFC v3 06/17] dt-bindings: pinctrl: add Zhihe A210 pin
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-a210-scmi-v3-6-ee6b31580808@iscas.ac.cn>
References: <20261103-a210-scmi-v3-0-ee6b31580808@iscas.ac.cn>
In-Reply-To: <20261103-a210-scmi-v3-0-ee6b31580808@iscas.ac.cn>
To: Sudeep Holla <sudeep.holla@kernel.org>, 
 Cristian Marussi <cristian.marussi@arm.com>, 
 Michal Simek <michal.simek@amd.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Jassi Brar <jassisinghbrar@gmail.com>, Linus Walleij <linusw@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 Icenowy Zheng <uwu@icenowy.me>, Inochi Amaoto <inochiama@gmail.com>, 
 Vivian Wang <wangruikang@iscas.ac.cn>, Yao Zi <me@ziyao.cc>, 
 Jiaxun Yang <jiaxun.yang@flygoat.com>
Cc: arm-scmi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-gpio@vger.kernel.org, 
 Paul Walmsley <paul.walmsley@sifive.com>, linux-clk@vger.kernel.org, 
 linux-serial@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793648705; l=5149;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=ViPTWWQQeexsnyAa+LU8olyP5is0pfShY5chI2/PszU=;
 b=BUGfjsDUMGXJ2Xsl51TLYgelij2NnYdnV7+1jqBYXjvnS9TJfLhs32lM54YtvZYZw9lZI3FfS
 kRmBjNho0QBARTjyq1+DvWmWrg62TTXpZJKnuFH9TXcD2UGfrsUCdNY
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>

Add a binding for the AON, PERI1 and PERI2 pad controllers of the Zhihe
A210. Every pad is muxed and configured on its own. Functions of the same
kind share one name unless a pad can select more than one instance of
them, as with the UARTs.

Signed-off-by: Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 .../bindings/pinctrl/zhihe,a210-pinctrl.yaml       | 146 +++++++++++++++++++++
 1 file changed, 146 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/zhihe,a210-pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/zhihe,a210-pinctrl.yaml
new file mode 100644
index 000000000000..96c46b59d147
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/zhihe,a210-pinctrl.yaml
@@ -0,0 +1,146 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pinctrl/zhihe,a210-pinctrl.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Zhihe A210 pin controller
+
+maintainers:
+  - Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>
+
+description: |
+  Pinmux and pinconf controller of the Zhihe A210 RISC-V SoC.
+
+  Most pads of the A210 are split into three groups, each managed by its
+  own pad controller with a separate register range:
+
+    AON pad controller   -> zhihe,a210-aon-pinctrl
+    Peripheral 1 pads    -> zhihe,a210-peri1-pinctrl
+    Peripheral 2 pads    -> zhihe,a210-peri2-pinctrl
+
+  Each pad can be muxed individually to up to 8 different functions,
+  though for most pads only a few of those settings are valid. A few pads
+  in the AON group do not support muxing or configuration at all.
+
+  The pads support configurable drive strength, bias, input enable,
+  Schmitt trigger and slew rate.
+
+properties:
+  compatible:
+    enum:
+      - zhihe,a210-aon-pinctrl
+      - zhihe,a210-peri1-pinctrl
+      - zhihe,a210-peri2-pinctrl
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
+  resets:
+    maxItems: 1
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
+          function:
+            $ref: /schemas/pinctrl/pinmux-node.yaml#/properties/function
+            enum: [ aouart, aouart_ir, aogpio, aoi2c, aospi, jtag, reset,
+                    por, pmic, dvs, uart0, uart1, uart2, uart3, uart4,
+                    uart5, uart6, uart7, uart8, uart9, uart_ir, gpio,
+                    gmac0, gmac1, spi, qspi, pwm, can, i2s0, i2s1, i2s2,
+                    i2s3, i2c0, i2c1, i2c2, i2c3, i2c4, i2c5, i2c6, i2c7,
+                    i2c7_smb, sdio, isp0, dptx, usb31, sata, hdmi, zmac,
+                    bsel, dbgm, cdbg, pdm, tdm, pcie, sen_vclk ]
+            description: |
+              The mux function to select for the given pins. Functions of
+              the same kind share one name, such as spi or pwm, unless a
+              pad can select more than one instance. For example GPIO0_16
+              selects UART0 or UART1, so the UARTs are named uart0 to
+              uart9.
+
+          bias-disable: true
+
+          bias-pull-up: true
+
+          bias-pull-down: true
+
+          drive-strength:
+            minimum: 1
+            maximum: 25
+            description:
+              Drive strength in mA. The pads support 1, 2, 3, 5, 7, 8, 10,
+              12, 13, 15, 16, 18, 20, 21, 23 and 25 mA. Other values select
+              the next higher strength.
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
+        required:
+          - pins
+
+        additionalProperties: false
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
+                pins = "GPIO0_0", "GPIO0_12";
+                function = "gmac0";
+                bias-disable;
+                drive-strength = <13>;
+                input-disable;
+                input-schmitt-disable;
+                slew-rate = <0>;
+            };
+        };
+    };

-- 
2.55.0

