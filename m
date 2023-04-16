From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 16 Apr 2023 17:19:34 +0800
Subject: [PATCH RFC v4 3/4] dt-binding: mmc: hi3798cv200-dw-mshc: convert
 to YAML and rename to histb-dw-mshc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230415-mmc-hi3798mv200-v4-3-44096e187f53@outlook.com>
References: <20230415-mmc-hi3798mv200-v4-0-44096e187f53@outlook.com>
In-Reply-To: <20230415-mmc-hi3798mv200-v4-0-44096e187f53@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1681636790; l=4130;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=x4duf6C0UsmPpNL4gwKd9sFpOmI1G3aqFz1AACwdB8s=;
 b=M4d6nFfKc0nEUGxJdyEQYKaAqmjOWx2hwsSj/T+Z3SrsmBAlhewJIlO/HblM+Ci4jIkSAHzo4
 l6FHmu5X0CHCneXLlg8+7oqv/pivg7SsqOWDBpWJY3FwTxDk2E9cEC7
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The renaming is due to the fact that it is now supporting SoCs other
than Hi3798CV200.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../bindings/mmc/hi3798cv200-dw-mshc.txt           | 40 -------------
 .../bindings/mmc/hisilicon,histb-dw-mshc.yaml      | 69 ++++++++++++++++++++++
 2 files changed, 69 insertions(+), 40 deletions(-)

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
diff --git a/Documentation/devicetree/bindings/mmc/hisilicon,histb-dw-mshc.yaml b/Documentation/devicetree/bindings/mmc/hisilicon,histb-dw-mshc.yaml
new file mode 100644
index 0000000000000..301b6ad39c5af
--- /dev/null
+++ b/Documentation/devicetree/bindings/mmc/hisilicon,histb-dw-mshc.yaml
@@ -0,0 +1,69 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
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
+  SoC with storage medium such as eMMC or SD/MMC cards.
+
+properties:
+  compatible:
+    enum:
+      - hisilicon,hi3798cv200-dw-mshc
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  clocks:
+    maxItems: 4
+
+  clock-names:
+    items:
+      - const: ciu
+      - const: biu
+      - const: ciu-sample
+      - const: ciu-drive
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - clocks
+  - clock-names
+
+allOf:
+  - $ref: synopsys-dw-mshc-common.yaml#
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    emmc: mmc@9830000 {
+      compatible = "hisilicon,hi3798cv200-dw-mshc";
+      reg = <0x9830000 0x10000>;
+      interrupts = <35>;
+      clocks = <&crg 1>,
+               <&crg 2>,
+               <&crg 3>,
+               <&crg 4>;
+      clock-names = "ciu", "biu", "ciu-sample", "ciu-drive";
+      fifo-depth = <256>;
+      clock-frequency = <200000000>;
+      cap-mmc-highspeed;
+      mmc-ddr-1_8v;
+      mmc-hs200-1_8v;
+      non-removable;
+      bus-width = <8>;
+    };

-- 
2.39.2

