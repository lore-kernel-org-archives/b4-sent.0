From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 16 Feb 2024 01:46:44 +0800
Subject: [PATCH 3/3] dt-bindings: mmc: dw-mshc-hi3798cv200: rename to
 dw-mshc-histb
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-b4-mmc-hi3798mv200-v1-3-7d46db845ae6@outlook.com>
References: <20240216-b4-mmc-hi3798mv200-v1-0-7d46db845ae6@outlook.com>
In-Reply-To: <20240216-b4-mmc-hi3798mv200-v1-0-7d46db845ae6@outlook.com>
To: Ulf Hansson <ulf.hansson@linaro.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Igor Opaniuk <igor.opaniuk@linaro.org>, 
 tianshuliang <tianshuliang@hisilicon.com>, David Yang <mmyangfl@gmail.com>, 
 linux-kernel@vger.kernel.org, linux-mmc@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708019203; l=4176;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=vyT5SY9rrA1BRKlIPW3ARvBOXeZjjpuC0pdH+zidx+U=;
 b=Tf3Nb3SLoAI+EwCZ6ijWxGYdkpP8wYBMIRw7xswxJo5oZ6AvOrrL3r6U3dllsArYeg57hgvnE
 9OOU7fzbCSNBO41J+nGHqoN6vK/gcrutOvSe/waWCtMDad1zAuLOUIS
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add binding for Hi3798MV200 DWMMC specific extension.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 ...hi3798cv200-dw-mshc.yaml => histb-dw-mshc.yaml} | 60 +++++++++++++++++++---
 1 file changed, 52 insertions(+), 8 deletions(-)

diff --git a/Documentation/devicetree/bindings/mmc/hi3798cv200-dw-mshc.yaml b/Documentation/devicetree/bindings/mmc/histb-dw-mshc.yaml
similarity index 57%
rename from Documentation/devicetree/bindings/mmc/hi3798cv200-dw-mshc.yaml
rename to Documentation/devicetree/bindings/mmc/histb-dw-mshc.yaml
index 5db99cd94b90..d2f5b7bb7a58 100644
--- a/Documentation/devicetree/bindings/mmc/hi3798cv200-dw-mshc.yaml
+++ b/Documentation/devicetree/bindings/mmc/histb-dw-mshc.yaml
@@ -1,11 +1,11 @@
 # SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
 %YAML 1.2
 ---
-$id: http://devicetree.org/schemas/mmc/hi3798cv200-dw-mshc.yaml#
+$id: http://devicetree.org/schemas/mmc/histb-dw-mshc.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
 title:
-  Hisilicon Hi3798CV200 SoC specific extensions to the Synopsys DWMMC controller
+  Hisilicon HiSTB SoCs specific extensions to the Synopsys DWMMC controller
 
 maintainers:
   - Yang Xiwen <forbidden405@outlook.com>
@@ -14,16 +14,14 @@ description:
   The Synopsys designware mobile storage host controller is used to interface
   a SoC with storage medium such as eMMC or SD/MMC cards. This file documents
   differences between the core Synopsys dw mshc controller properties described
-  by synopsys-dw-mshc.txt and the properties used by the Hisilicon Hi3798CV200
-  specific extensions to the Synopsys Designware Mobile Storage Host Controller.
-
-allOf:
-  - $ref: synopsys-dw-mshc-common.yaml#
+  by synopsys-dw-mshc.txt and the properties used by the Hisilicon HiSTB specific
+  extensions to the Synopsys Designware Mobile Storage Host Controller.
 
 properties:
   compatible:
     enum:
       - hisilicon,hi3798cv200-dw-mshc
+      - hisilicon,hi3798mv200-dw-mshc
 
   reg:
     maxItems: 1
@@ -48,6 +46,12 @@ properties:
       control the clock phases, "ciu-sample" is required for tuning
       high speed modes.
 
+  hisilicon,sap-dll-reg:
+    $ref: /schemas/types.yaml#/definitions/phandle
+    description:
+      A phandle points to the sample delay-locked-loop(DLL)
+      syscon node, used for tuning.
+
 required:
   - compatible
   - reg
@@ -55,13 +59,25 @@ required:
   - clocks
   - clock-names
 
+allOf:
+  - $ref: synopsys-dw-mshc-common.yaml#
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: hisilicon,hi3798mv200-dw-mshc
+    then:
+      required:
+        - hisilicon,sap-dll-reg
+
 unevaluatedProperties: false
 
 examples:
   - |
     #include <dt-bindings/clock/histb-clock.h>
     #include <dt-bindings/interrupt-controller/arm-gic.h>
-    emmc: mmc@9830000 {
+    mmc@9830000 {
       compatible = "hisilicon,hi3798cv200-dw-mshc";
       reg = <0x9830000 0x10000>;
       interrupts = <GIC_SPI 35 IRQ_TYPE_LEVEL_HIGH>;
@@ -84,3 +100,31 @@ examples:
       bus-width = <8>;
       status = "okay";
     };
+  - |
+    #include <dt-bindings/clock/histb-clock.h>
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+    mmc@9830000 {
+      compatible = "hisilicon,hi3798mv200-dw-mshc";
+      reg = <0x9830000 0x10000>;
+      interrupts = <GIC_SPI 35 IRQ_TYPE_LEVEL_HIGH>;
+      clocks = <&crg HISTB_MMC_CIU_CLK>,
+               <&crg HISTB_MMC_BIU_CLK>,
+               <&crg HISTB_MMC_SAMPLE_CLK>,
+               <&crg HISTB_MMC_DRV_CLK>;
+      clock-names = "ciu", "biu", "ciu-sample", "ciu-drive";
+      resets = <&crg 0xa0 4>;
+      reset-names = "reset";
+      pinctrl-names = "default";
+      pinctrl-0 = <&emmc_pins>;
+      fifo-depth = <256>;
+      clock-frequency = <50000000>;
+      max-frequency = <150000000>;
+      cap-mmc-highspeed;
+      mmc-ddr-1_8v;
+      mmc-hs200-1_8v;
+      mmc-hs400-1_8v;
+      non-removable;
+      bus-width = <8>;
+      hisilicon,sap-dll-reg = <&emmc_sap_dll_reg>;
+      status = "okay";
+    };

-- 
2.43.0

