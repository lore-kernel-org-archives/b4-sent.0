From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 17 Feb 2024 05:02:31 +0800
Subject: [PATCH v3 3/4] dt-bindings: mmc: dw-mshc-hi3798cv200: convert to
 YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240217-b4-mmc-hi3798mv200-v3-3-f15464176947@outlook.com>
References: <20240217-b4-mmc-hi3798mv200-v3-0-f15464176947@outlook.com>
In-Reply-To: <20240217-b4-mmc-hi3798mv200-v3-0-f15464176947@outlook.com>
To: Ulf Hansson <ulf.hansson@linaro.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Igor Opaniuk <igor.opaniuk@linaro.org>, 
 tianshuliang <tianshuliang@hisilicon.com>, David Yang <mmyangfl@gmail.com>, 
 linux-kernel@vger.kernel.org, linux-mmc@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708117349; l=4642;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=2gvcPOcC0W9JjDo7uuJyb8+Jf0I4Z6n3x2BDfI4hOUA=;
 b=XQLOvaUzbqwudm3uFoDFpaPXJ74fVzy8FO5758AmTMQ5ydj2UwcnG5gkaFV8xtWgmuQ8n6bdB
 7IXYLHTxOSvAYTbQeGJbgmbRh5aI1LtH8q/KibB5viAWCr9MLt+UmZz
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

convert the legacy txt binding to modern YAML and rename to
hisilicon,hi3798cv200-dw-mshc.yaml. No semantic change.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../bindings/mmc/hi3798cv200-dw-mshc.txt           | 40 ------------
 .../mmc/hisilicon,hi3798cv200-dw-mshc.yaml         | 75 ++++++++++++++++++++++
 2 files changed, 75 insertions(+), 40 deletions(-)

diff --git a/Documentation/devicetree/bindings/mmc/hi3798cv200-dw-mshc.txt b/Documentation/devicetree/bindings/mmc/hi3798cv200-dw-mshc.txt
deleted file mode 100644
index a0693b7145f2..000000000000
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
diff --git a/Documentation/devicetree/bindings/mmc/hisilicon,hi3798cv200-dw-mshc.yaml b/Documentation/devicetree/bindings/mmc/hisilicon,hi3798cv200-dw-mshc.yaml
new file mode 100644
index 000000000000..f3dc973cb490
--- /dev/null
+++ b/Documentation/devicetree/bindings/mmc/hisilicon,hi3798cv200-dw-mshc.yaml
@@ -0,0 +1,75 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mmc/hisilicon,hi3798cv200-dw-mshc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Hisilicon Hi3798CV200 SoC specific extensions to the Synopsys DWMMC controller
+
+maintainers:
+  - Yang Xiwen <forbidden405@outlook.com>
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
+    items:
+      - description: bus interface unit clock
+      - description: card interface unit clock
+      - description: card input sample phase clock
+      - description: controller output drive phase clock
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
+    #include <dt-bindings/clock/histb-clock.h>
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    mmc@9830000 {
+        compatible = "hisilicon,hi3798cv200-dw-mshc";
+        reg = <0x9830000 0x10000>;
+        interrupts = <GIC_SPI 35 IRQ_TYPE_LEVEL_HIGH>;
+        clocks = <&crg HISTB_MMC_CIU_CLK>,
+                 <&crg HISTB_MMC_BIU_CLK>,
+                 <&crg HISTB_MMC_SAMPLE_CLK>,
+                 <&crg HISTB_MMC_DRV_CLK>;
+        clock-names = "ciu", "biu", "ciu-sample", "ciu-drive";
+        resets = <&crg 0xa0 4>;
+        reset-names = "reset";
+        pinctrl-names = "default";
+        pinctrl-0 = <&emmc_pins_1 &emmc_pins_2
+                     &emmc_pins_3 &emmc_pins_4>;
+        fifo-depth = <256>;
+        clock-frequency = <200000000>;
+        cap-mmc-highspeed;
+        mmc-ddr-1_8v;
+        mmc-hs200-1_8v;
+        non-removable;
+        bus-width = <8>;
+    };

-- 
2.43.0

