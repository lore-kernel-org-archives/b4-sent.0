From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 16 Apr 2023 01:13:18 +0800
Subject: [PATCH RFC v2 3/3] binding: mmc: hi3798cv200-dw-mshc: convert to
 YAML and rename to histb-dw-mshc, add compatible of hi3798mv200
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230415-mmc-hi3798mv200-v2-3-1d274f9b71da@outlook.com>
References: <20230415-mmc-hi3798mv200-v2-0-1d274f9b71da@outlook.com>
In-Reply-To: <20230415-mmc-hi3798mv200-v2-0-1d274f9b71da@outlook.com>
To: Ulf Hansson <ulf.hansson@linaro.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Yang Xiwen <forbidden405@outlook.com>
Cc: tianshuliang <tianshuliang@hisilicon.com>, 
 Jiancheng Xue <xuejiancheng@hisilicon.com>, 
 Shawn Guo <shawn.guo@linaro.org>, David Yang <mmyangfl@gmail.com>, 
 linux-mmc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1681578841; l=4832;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=JIt1WKO/E/jF6bqUj7ql5V34Mtu9RTATejU7vIuUpXk=;
 b=u+DeFJqw2haCSzMfeqhvP2+DgCHXLB0jvJLFSB40eogHx+N9bppnzPPJx/MzKvlvlMTaaDB6y
 OKF8RVoe8f1AkohL1hka/dk8TBQtRha+8gG7Ln7nWYAvebbeBgIxA+B
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi3798MV200 has an extra clock, also document it here.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../bindings/mmc/hi3798cv200-dw-mshc.txt           | 40 ----------
 .../devicetree/bindings/mmc/histb-dw-mshc.yaml     | 90 ++++++++++++++++++++++
 2 files changed, 90 insertions(+), 40 deletions(-)

diff --git a/Documentation/devicetree/bindings/mmc/hi3798cv200-dw-mshc.txt b/Documentation/devicetree/bindings/mmc/hi3798cv200-dw-mshc.txt
deleted file mode 100644
index a0693b7145f2a..0000000000000
--- a/Documentation/devicetree/bindings/mmc/hi3798cv200-dw-mshc.txt
+++ /dev/null
@@ -1,40 +0,0 @@
-* Hisilicon Hi3798CV200 specific extensions to the Synopsys Designware Mobile
-  Storage Host Controller
-
-Read synopsys-dw-mshc.txt for more details
-
-The Synopsys designware mobile storage host controller is used to interface
-a SoC with storage medium such as eMMC or SD/MMC cards. This file documents
-differences between the core Synopsys dw mshc controller properties described
-by synopsys-dw-mshc.txt and the properties used by the Hisilicon Hi3798CV200
-specific extensions to the Synopsys Designware Mobile Storage Host Controller.
-
-Required Properties:
-- compatible: Should contain "hisilicon,hi3798cv200-dw-mshc".
-- clocks: A list of phandle + clock-specifier pairs for the clocks listed
-  in clock-names.
-- clock-names: Should contain the following:
-	"ciu" - The ciu clock described in synopsys-dw-mshc.txt.
-	"biu" - The biu clock described in synopsys-dw-mshc.txt.
-	"ciu-sample" - Hi3798CV200 extended phase clock for ciu sampling.
-	"ciu-drive"  - Hi3798CV200 extended phase clock for ciu driving.
-
-Example:
-
-	emmc: mmc@9830000 {
-		compatible = "hisilicon,hi3798cv200-dw-mshc";
-		reg = <0x9830000 0x10000>;
-		interrupts = <GIC_SPI 35 IRQ_TYPE_LEVEL_HIGH>;
-		clocks = <&crg HISTB_MMC_CIU_CLK>,
-			 <&crg HISTB_MMC_BIU_CLK>,
-			 <&crg HISTB_MMC_SAMPLE_CLK>,
-			 <&crg HISTB_MMC_DRV_CLK>;
-		clock-names = "ciu", "biu", "ciu-sample", "ciu-drive";
-		fifo-depth = <256>;
-		clock-frequency = <200000000>;
-		cap-mmc-highspeed;
-		mmc-ddr-1_8v;
-		mmc-hs200-1_8v;
-		non-removable;
-		bus-width = <8>;
-	};
diff --git a/Documentation/devicetree/bindings/mmc/histb-dw-mshc.yaml b/Documentation/devicetree/bindings/mmc/histb-dw-mshc.yaml
new file mode 100644
index 0000000000000..ea377bd5ea4bf
--- /dev/null
+++ b/Documentation/devicetree/bindings/mmc/histb-dw-mshc.yaml
@@ -0,0 +1,90 @@
+# SPDX-License-Identifier: GPL-2.0
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mmc/histb-dw-mshc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title:
+  Hisilicon HiSTB SoC specific extensions to the Synopsys Designware Mobile
+  Storage Host Controller
+
+maintainers:
+  - Yang Xiwen <forbidden405@outlook.com>
+
+description:
+  The Synopsys designware mobile storage host controller is used to interface a
+  SoC with storage medium such as eMMC or SD/MMC cards. This file documents
+  differences between the core Synopsys dw mshc controller properties described
+  by synopsys-dw-mshc.txt and the properties used by the Hisilicon HiSTB SoC
+  specific extensions to the Synopsys Designware Mobile Storage Host Controller.
+
+allOf:
+  - $ref: "synopsys-dw-mshc-common.yaml#"
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: hisilicon,hi3798mv200-dw-mshc
+    then:
+      properties:
+        clocks:
+          minItems: 5
+
+        clock-names:
+          minItems: 5
+
+properties:
+  compatible:
+    enum:
+      - hisilicon,hi3798cv200-dw-mshc
+      - hisilicon,hi3798mv200-dw-mshc
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    minItems: 4
+    maxItems: 5
+    description: A list of phandles for the clocks listed in clock-names
+
+  clock-names:
+    minItems: 4
+    items:
+      - const: ciu
+      - const: biu
+      - const: ciu-sample
+      - const: ciu-drive
+      - const: sap-dll-mode
+
+unevaluatedProperties: false
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clocks
+  - clock-names
+
+examples:
+  - |
+    emmc: mmc@9830000 {
+            compatible = "hisilicon,hi3798cv200-dw-mshc";
+            reg = <0x9830000 0x10000>;
+            interrupts = <35>;
+            clocks = <&crg 1>,
+                     <&crg 2>,
+                     <&crg 3>,
+                     <&crg 4>;
+            clock-names = "ciu", "biu", "ciu-sample", "ciu-drive";
+            fifo-depth = <256>;
+            clock-frequency = <200000000>;
+            cap-mmc-highspeed;
+            mmc-ddr-1_8v;
+            mmc-hs200-1_8v;
+            non-removable;
+            bus-width = <8>;
+    };
+

-- 
2.39.2

