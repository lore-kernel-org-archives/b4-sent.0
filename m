From: Dang Huynh <dang.huynh@mainlining.org>
Date: Fri, 19 Sep 2025 01:48:44 +0700
Subject: [PATCH 04/10] dt-bindings: mmc: Add RDA SDMMC controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250919-rda8810pl-mmc-v1-4-d4f08a05ba4d@mainlining.org>
References: <20250919-rda8810pl-mmc-v1-0-d4f08a05ba4d@mainlining.org>
In-Reply-To: <20250919-rda8810pl-mmc-v1-0-d4f08a05ba4d@mainlining.org>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Ulf Hansson <ulf.hansson@linaro.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-unisoc@lists.infradead.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-mmc@vger.kernel.org, 
 linux-hardening@vger.kernel.org, Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758221395; l=2667;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=AsSx2jfyiIl9tD1PzUkU8B/80/dNLISAbs6T475/JWo=;
 b=m1jZ5iiJdDLR2oNGhbZc1KvGaZ/RhK/lM0bAsauM7cx684WiuGLwZlK4HFh7moDg6YJ4FQU+R
 ttMceldPwaYBD+EGfHCFOX0uBSgU42qv2H8yNPUABQPx0Skg+RH4jnz
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation describing the SD/MMC controller in RDA Micro
RDA8810PL SoC.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
 Documentation/devicetree/bindings/mmc/rda,mmc.yaml | 92 ++++++++++++++++++++++
 1 file changed, 92 insertions(+)

diff --git a/Documentation/devicetree/bindings/mmc/rda,mmc.yaml b/Documentation/devicetree/bindings/mmc/rda,mmc.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..f3cda38abd66023ca9bc94d1c29df5ae9e211e7c
--- /dev/null
+++ b/Documentation/devicetree/bindings/mmc/rda,mmc.yaml
@@ -0,0 +1,92 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mmc/rda,mmc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: RDA Micro SD/MMC Controller
+
+allOf:
+  - $ref: mmc-controller.yaml
+
+maintainers:
+  - Dang Huynh <dang.huynh@mainlining.org>
+
+properties:
+  compatible:
+    items:
+      - enum:
+          - rda,8810pl-mmc
+      - const: rda,mmc
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    maxItems: 1
+
+  clock-names:
+    const: mclk
+
+  resets:
+    maxItems: 1
+
+  dmas:
+    maxItems: 2
+
+  dma-names:
+    items:
+      - const: tx
+      - const: rx
+
+  rda,mclk-adj:
+    $ref: /schemas/types.yaml#/definitions/uint8
+    description:
+      Some board need MCLK output to be delayed for the card to work.
+      If not present, MCLK output is not delayed.
+    minimum: 0
+    maximum: 255
+
+  rda,mclk-inv:
+    $ref: /schemas/types.yaml#/definitions/flag
+    description:
+      Some board need MCLK to be inverted for the card to work.
+      If not present, MCLK is not inverted.
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clocks
+  - clock-names
+  - resets
+  - dmas
+  - dma-names
+  - vmmc-supply
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
+    #include <dt-bindings/clock/rda,8810pl-apclk.h>
+    #include <dt-bindings/dma/rda-ifc.h>
+    mmc@20950000 {
+      compatible = "rda,8810pl-mmc", "rda,mmc";
+      reg = <0x20950000 0x1000>;
+      interrupts = <3 IRQ_TYPE_LEVEL_HIGH>;
+      clocks = <&ap_syscon CLK_APB2>;
+      clock-names = "mclk";
+      resets = <&ap_syscon RST_APB2_SDMMC1>;
+      dmas = <&ifc IFC_SDMMC1_TX>, <&ifc IFC_SDMMC1_RX>;
+      dma-names = "tx", "rx";
+      vmmc-supply = <&vdd_sdmmc>;
+      rda,mclk-adj = /bits/ 8 <1>;
+      rda,mclk-inv;
+    };
+
+...

-- 
2.51.0

