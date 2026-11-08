From: Vincent Jardin <vjardin@free.fr>
Date: Sun, 08 Nov 2026 11:06:49 +0100
Subject: [PATCH v3 1/5] dt-bindings: pinctrl: add the NXP LX2160A RCW pad
 mux
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-for-upstream-lx2160a-rcw-pinmux-v1-v3-1-5a0063f1da9e@free.fr>
References: <20261108-for-upstream-lx2160a-rcw-pinmux-v1-v3-0-5a0063f1da9e@free.fr>
In-Reply-To: <20261108-for-upstream-lx2160a-rcw-pinmux-v1-v3-0-5a0063f1da9e@free.fr>
To: Dong Aisheng <aisheng.dong@nxp.com>, Fabio Estevam <festevam@gmail.com>, 
 Frank Li <Frank.Li@nxp.com>, Jacky Bai <ping.bai@nxp.com>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 NXP S32 Linux Team <s32@nxp.com>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-arm-kernel@lists.infradead.org, imx@lists.linux.dev, 
 Vladimir Oltean <vladimir.oltean@nxp.com>, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794132412; l=7863;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=WJEu6Kut0xVF/KDjBMf//ysc0ClXUnn5Bm43TSeWmfA=;
 b=IpNDce5x8e6DnaVw4ejAFhEwC1YAQrx4LohykmQ/W18gOWIX2GpoDq5LE0fEa+crVvG0NUQxN
 yS0RCnwfuuTCU//58QPTs9x+HstcUisy714uwo5Kw/e70OUC4Vt7+Xh
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LX2160A muxes its IIC, XSPI, SDHC, UART, IRQ and EVT pads from
fields of the RCW: read-only in RCWSR12..14 of DCFG, changed at runtime
through the override registers of its DCSR view.

Describe the pad mux as a child of DCFG at its RCWSR12 to RCWSR14
window: the override registers are at the same offset of the DCSR view
of the parent. One group per RCW field, one function per encoding.

Each function lists the groups that take it, so a pair the driver
would refuse, such as can on iic1, is refused by the schema.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 .../bindings/pinctrl/fsl,lx2160a-rcw-pinmux.yaml   | 264 +++++++++++++++++++++
 1 file changed, 264 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/fsl,lx2160a-rcw-pinmux.yaml b/Documentation/devicetree/bindings/pinctrl/fsl,lx2160a-rcw-pinmux.yaml
new file mode 100644
index 000000000000..6bd21c27a00c
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/fsl,lx2160a-rcw-pinmux.yaml
@@ -0,0 +1,264 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pinctrl/fsl,lx2160a-rcw-pinmux.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: NXP LX2160A RCW pad muxes
+
+maintainers:
+  - Vincent Jardin <vjardin@free.fr>
+
+description:
+  The LX2160A muxes its IIC, XSPI, SDHC, UART, IRQ and EVT pads based on its
+  RCW. The related fields are from the read-only RCWSR12 to RCWSR14 registers
+  of DCFG, and can be changed at runtime by writing the RCW override registers
+  in the DCSR view of DCFG. The node is a child of the DCFG node, which owns
+  both views. Its reg is the RCWSR12 to RCWSR14 window of the CCSR view, and
+  the override registers are at the same offset of the DCSR view.
+
+properties:
+  compatible:
+    const: fsl,lx2160a-rcw-pinmux
+
+  reg:
+    maxItems: 1
+
+patternProperties:
+  '-pins$':
+    type: object
+    $ref: pinmux-node.yaml#
+    additionalProperties: false
+
+    properties:
+      function:
+        enum: [ asleep, can, evt, flexspi, flextimer, gpio, i2c, irq,
+                reset-req, sdhc, sdhc-clk, sdhc-data, sdhc-data4, sdhc-spi,
+                spi, uart, uart3, uart4 ]
+
+      groups:
+        items:
+          enum: [ iic1, iic2, iic3, iic4, iic5, iic6, xspi1-data74,
+                  xspi1-data30, xspi1-base, sdhc1-base, sdhc1-dir,
+                  sdhc2-data74, sdhc2-base, uart1-soutsin, uart1-rtscts,
+                  uart2-soutsin, uart2-rtscts, irq11-8, irq7-4, irq3-0,
+                  evt4-3, evt2-0, clk-out, asleep, reset-req ]
+
+    required:
+      - function
+      - groups
+
+    allOf:
+      - if:
+          properties:
+            function:
+              const: asleep
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ asleep ]
+
+      - if:
+          properties:
+            function:
+              const: can
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ iic3, iic4 ]
+
+      - if:
+          properties:
+            function:
+              const: evt
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ iic3, iic4, evt4-3, evt2-0, asleep ]
+
+      - if:
+          properties:
+            function:
+              const: flexspi
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ xspi1-data74, xspi1-data30, xspi1-base,
+                        sdhc2-data74, sdhc2-base ]
+
+      - if:
+          properties:
+            function:
+              const: flextimer
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ iic2, irq7-4, irq3-0, evt4-3, evt2-0, clk-out ]
+
+      - if:
+          properties:
+            function:
+              const: gpio
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ iic2, iic3, iic4, iic5, iic6, xspi1-data74,
+                        xspi1-data30, xspi1-base, sdhc1-base, sdhc1-dir,
+                        sdhc2-data74, sdhc2-base, uart1-soutsin,
+                        uart1-rtscts, uart2-soutsin, uart2-rtscts,
+                        irq11-8, irq7-4, irq3-0, evt4-3, evt2-0, clk-out,
+                        asleep, reset-req, iic1 ]
+
+      - if:
+          properties:
+            function:
+              const: i2c
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ iic2, iic3, iic4, iic5, iic6, sdhc2-data74, iic1 ]
+
+      - if:
+          properties:
+            function:
+              const: irq
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ irq11-8, irq7-4, irq3-0 ]
+
+      - if:
+          properties:
+            function:
+              const: reset-req
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ reset-req ]
+
+      - if:
+          properties:
+            function:
+              const: sdhc
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ iic2, sdhc1-base, sdhc1-dir, sdhc2-data74,
+                        sdhc2-base ]
+
+      - if:
+          properties:
+            function:
+              const: sdhc-clk
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ iic5, iic6 ]
+
+      - if:
+          properties:
+            function:
+              const: sdhc-data
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ sdhc1-dir ]
+
+      - if:
+          properties:
+            function:
+              const: sdhc-data4
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ sdhc1-base ]
+
+      - if:
+          properties:
+            function:
+              const: sdhc-spi
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ sdhc1-base ]
+
+      - if:
+          properties:
+            function:
+              const: spi
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ iic5, sdhc1-base, sdhc1-dir, sdhc2-base ]
+
+      - if:
+          properties:
+            function:
+              const: uart
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ uart1-soutsin, uart1-rtscts, uart2-soutsin,
+                        uart2-rtscts ]
+
+      - if:
+          properties:
+            function:
+              const: uart3
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ uart1-rtscts ]
+
+      - if:
+          properties:
+            function:
+              const: uart4
+        then:
+          properties:
+            groups:
+              items:
+                enum: [ uart2-rtscts ]
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
+    pinctrl@12c {
+        compatible = "fsl,lx2160a-rcw-pinmux";
+        reg = <0x12c 0xc>;
+
+        iic3-i2c-pins {
+            function = "i2c";
+            groups = "iic3";
+        };
+
+        iic3-gpio-pins {
+            function = "gpio";
+            groups = "iic3";
+        };
+    };

-- 
2.43.0

