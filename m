From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 24 Feb 2024 01:12:28 +0800
Subject: [PATCH v5 1/6] dt-bindings: clock: convert hisi-crg.txt to YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240224-clk-mv200-v5-1-79f586d6e1a2@outlook.com>
References: <20240224-clk-mv200-v5-0-79f586d6e1a2@outlook.com>
In-Reply-To: <20240224-clk-mv200-v5-0-79f586d6e1a2@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>, Rob Herring <robh@kernel.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708708351; l=4485;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=niqUOxDfJs6Cg8cAew13UfuGWdhc9EO8AxaOkdOzIVU=;
 b=wH/jF90Dc2tYLupJyuJ//DwfoCET37apCDWrTwmfQY4ZChnQ7sHKWC0zbHHOf9Uoqp5ufbMux
 9ZC1XV07OHWBdlCNXZEQJ+YNAB/vPm6hpK62HhOEFiTP0LDp2XBo2Bs
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Also rename to hisilicon,hisi-crg.yaml. While at it, add "syscon" and
"simple-mfd" compatibles to match the existing hi3798cv200.dtsi.

Add reset-controller subnode for hisilicon,hi3798cv200-crg to match the
existing hi3798cv200.dtsi.

Reviewed-by: Rob Herring <robh@kernel.org>
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../devicetree/bindings/clock/hisi-crg.txt         | 50 ---------------
 .../bindings/clock/hisilicon,hisi-crg.yaml         | 74 ++++++++++++++++++++++
 2 files changed, 74 insertions(+), 50 deletions(-)

diff --git a/Documentation/devicetree/bindings/clock/hisi-crg.txt b/Documentation/devicetree/bindings/clock/hisi-crg.txt
deleted file mode 100644
index cc60b3d423f3..000000000000
--- a/Documentation/devicetree/bindings/clock/hisi-crg.txt
+++ /dev/null
@@ -1,50 +0,0 @@
-* HiSilicon Clock and Reset Generator(CRG)
-
-The CRG module provides clock and reset signals to various
-modules within the SoC.
-
-This binding uses the following bindings:
-    Documentation/devicetree/bindings/clock/clock-bindings.txt
-    Documentation/devicetree/bindings/reset/reset.txt
-
-Required Properties:
-
-- compatible: should be one of the following.
-  - "hisilicon,hi3516cv300-crg"
-  - "hisilicon,hi3516cv300-sysctrl"
-  - "hisilicon,hi3519-crg"
-  - "hisilicon,hi3798cv200-crg"
-  - "hisilicon,hi3798cv200-sysctrl"
-
-- reg: physical base address of the controller and length of memory mapped
-  region.
-
-- #clock-cells: should be 1.
-
-Each clock is assigned an identifier and client nodes use this identifier
-to specify the clock which they consume.
-
-All these identifier could be found in <dt-bindings/clock/hi3519-clock.h>.
-
-- #reset-cells: should be 2.
-
-A reset signal can be controlled by writing a bit register in the CRG module.
-The reset specifier consists of two cells. The first cell represents the
-register offset relative to the base address. The second cell represents the
-bit index in the register.
-
-Example: CRG nodes
-CRG: clock-reset-controller@12010000 {
-	compatible = "hisilicon,hi3519-crg";
-	reg = <0x12010000 0x10000>;
-	#clock-cells = <1>;
-	#reset-cells = <2>;
-};
-
-Example: consumer nodes
-i2c0: i2c@12110000 {
-	compatible = "hisilicon,hi3519-i2c";
-	reg = <0x12110000 0x1000>;
-	clocks = <&CRG HI3519_I2C0_RST>;
-	resets = <&CRG 0xe4 0>;
-};
diff --git a/Documentation/devicetree/bindings/clock/hisilicon,hisi-crg.yaml b/Documentation/devicetree/bindings/clock/hisilicon,hisi-crg.yaml
new file mode 100644
index 000000000000..ade84fda1c23
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/hisilicon,hisi-crg.yaml
@@ -0,0 +1,74 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/hisilicon,hisi-crg.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Hisilicon SOC Clock and Reset Generator (CRG) module
+
+maintainers:
+  - Yang Xiwen <forbidden405@foxmail.com>
+
+description: |
+  Hisilicon SOC clock control module which supports the clocks, resets and
+  power domains on various SoCs.
+
+properties:
+  compatible:
+    oneOf:
+      - const: hisilicon,hi3519-crg
+      - items:
+          - enum:
+              - hisilicon,hi3516cv300-crg
+              - hisilicon,hi3516cv300-sysctrl
+              - hisilicon,hi3798cv200-crg
+              - hisilicon,hi3798cv200-sysctrl
+          - const: syscon
+          - const: simple-mfd
+
+  reg:
+    maxItems: 1
+
+  '#clock-cells':
+    const: 1
+
+  '#reset-cells':
+    const: 2
+    description: |
+      First cell is reset request register offset.
+      Second cell is bit offset in reset request register.
+
+  reset-controller:
+    type: object
+    description: |
+      Reset controller for Hi3798CV200 GMAC module
+
+required:
+  - compatible
+  - reg
+  - '#clock-cells'
+  - '#reset-cells'
+
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: hisilicon,hi3798cv200-crg
+    then:
+      required:
+        - reset-controller
+    else:
+      properties:
+        reset-controller: false
+
+additionalProperties: false
+
+examples:
+  - |
+    clock-reset-controller@12010000 {
+        compatible = "hisilicon,hi3519-crg";
+        reg = <0x12010000 0x10000>;
+        #clock-cells = <1>;
+        #reset-cells = <2>;
+    };

-- 
2.43.0

