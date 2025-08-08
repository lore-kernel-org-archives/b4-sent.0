From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 08 Aug 2025 10:00:34 +0800
Subject: [PATCH 1/3] spi: dt-bindings: add doc for Amlogic A113L2 SFC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250808-spifc-v1-1-ff4e30e26a6b@amlogic.com>
References: <20250808-spifc-v1-0-ff4e30e26a6b@amlogic.com>
In-Reply-To: <20250808-spifc-v1-0-ff4e30e26a6b@amlogic.com>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liang Yang <liang.yang@amlogic.com>, 
 Feng Chen <feng.chen@amlogic.com>
Cc: linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754618434; l=3425;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=bLH1YCUDdwpRixxvKPG4oxzNBgBNJNrkBjlYrk9Mqmw=;
 b=gu7g30GKaG1N5QhYx3uprkNWWWZUpQ1YT+TRKt5aQwRTH9zrplfXfOCLLUmjTAGhPVpb50Ke2
 3ZErOJJYgH1ALW5FPI+6iz3oA5mW3DB4OHa2+f/8WkWRXGCk9YAQRbL
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Feng Chen <feng.chen@amlogic.com>

The Flash Controller is derived by adding an SPI path to the original
raw NAND controller. This controller supports two modes: raw mode and
SPI mode. The raw mode has already been implemented in the community,
and the SPI mode is described here.

Add bindings for Amlogic A113L2 SPI Flash Controller.

Signed-off-by: Feng Chen <feng.chen@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../devicetree/bindings/spi/amlogic,a4-spifc.yaml  | 104 +++++++++++++++++++++
 1 file changed, 104 insertions(+)

diff --git a/Documentation/devicetree/bindings/spi/amlogic,a4-spifc.yaml b/Documentation/devicetree/bindings/spi/amlogic,a4-spifc.yaml
new file mode 100644
index 000000000000..712a17a4b117
--- /dev/null
+++ b/Documentation/devicetree/bindings/spi/amlogic,a4-spifc.yaml
@@ -0,0 +1,104 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+# Copyright (C) 2025 Amlogic, Inc. All rights reserved
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/spi/amlogic,a4-spifc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: SPI flash controller for Amlogic ARM SoCs
+
+maintainers:
+  - Liang Yang <liang.yang@amlogic.com>
+  - Feng Chen <feng.chen@amlogic.com>
+  - Xianwei Zhao <xianwei.zhao@amlogic.com>
+
+description:
+  The Amlogic SPI flash controller is an extended version
+  of the Amlogic NAND flash controller. It supports SPI Nor
+  Flash and SPI NAND Flash(where the Host ECC HW engine could
+  be enabled).
+
+allOf:
+  - $ref: /schemas/spi/spi-controller.yaml#
+
+properties:
+  compatible:
+    const: amlogic,a4-spifc
+
+  reg:
+    items:
+      - description: core registers
+      - description: parent clk control registers
+
+  reg-names:
+    items:
+      - const: core
+      - const: pclk
+
+  clocks:
+    items:
+      - description: clock gate
+      - description: clock used for the controller
+      - description: clock used for the SPI bus
+
+  clock-names:
+    items:
+      - const: gate
+      - const: core
+      - const: device
+
+  interrupts:
+    maxItems: 1
+
+  amlogic,sfc-enable-random:
+    description: Enable data scrambling
+    type: boolean
+
+  amlogic,sfc-no-hwecc:
+    description: Disable ECC HW engine
+    type: boolean
+
+  amlogic,rx-adj:
+    description:
+      Adjust sample timing for RX, Sampling time
+      move later by 1 bus clock.
+    $ref: /schemas/types.yaml#/definitions/uint32
+    enum: [0, 1, 2, 3]
+    default: 0
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - clocks
+  - clock-names
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    sfc0: spi@fe08d000 {
+      compatible = "amlogic,a4-spifc";
+      reg = <0xfe08d000 0x800>, <0xfe08c000 0x4>;
+      reg-names = "core", "pclk";
+      clocks = <&clkc_periphs 31>,
+               <&clkc_periphs 102>,
+               <&scmi_clk 13>;
+      clock-names = "gate", "core", "device";
+
+      pinctrl-0 = <&spiflash_default>;
+      pinctrl-names = "default";
+
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      flash@0 {
+          compatible = "spi-nand";
+          reg = <0>;
+          #address-cells = <1>;
+          #size-cells = <1>;
+          nand-ecc-engine = <&sfc0>;
+          nand-ecc-strength = <8>;
+          nand-ecc-step-size = <512>;
+      };
+    };

-- 
2.37.1

