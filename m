From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 16 Feb 2024 19:37:54 +0800
Subject: [PATCH RFC 4/4] dt-binding: clock:
 hisilicon,clock-reset-controller: add Hi3798MV200 SoC support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-clk-mv200-v1-4-a29ace29e636@outlook.com>
References: <20240216-clk-mv200-v1-0-a29ace29e636@outlook.com>
In-Reply-To: <20240216-clk-mv200-v1-0-a29ace29e636@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708083473; l=2294;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=RxQshU93zhdnmZ2d/Il86mfOujovTqohz/PSfKt9R1k=;
 b=HeGs7bkTJR06qX5l+QDDNsx44/mocS0/PjmA9206O/LAGsmCIJOVNyiaJ6TNDvBIk1wiN9xRl
 zwHj4z36O6dD6EujUb+qIUvEc4k3PI1Fqfdmb6Q9aTIrSEMq8aW6n47
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This SoC is similar to Hi3798CV200.

Also document the specific DLL regs and add an example for it.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../clock/hisilicon,clock-reset-generator.yaml     | 36 ++++++++++++++++++++++
 1 file changed, 36 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/hisilicon,clock-reset-generator.yaml b/Documentation/devicetree/bindings/clock/hisilicon,clock-reset-generator.yaml
index d37cd892473e..8ee844574eda 100644
--- a/Documentation/devicetree/bindings/clock/hisilicon,clock-reset-generator.yaml
+++ b/Documentation/devicetree/bindings/clock/hisilicon,clock-reset-generator.yaml
@@ -44,12 +44,17 @@ properties:
           - hisilicon,hi3519-crg
           - hisilicon,hi3798cv200-crg
           - hisilicon,hi3798cv200-sysctrl
+          - hisilicon,hi3798mv200-crg
+          - hisilicon,hi3798mv200-sysctrl
       - const: syscon
       - const: simple-mfd
 
   reg:
     maxItems: 1
 
+  ranges:
+    maxItems: 1
+
   '#clock-cells':
     const: 1
 
@@ -87,6 +92,12 @@ properties:
     description: |
       Reset controller for Hi3798CV200 GMAC module
 
+patternProperties:
+  '.*-dll@[0-9a-f]+':
+    type: object
+    description: |
+      eMMC/SD delay-locked-loop (DLL) register subnode
+
 required:
   - compatible
   - '#clock-cells'
@@ -137,3 +148,28 @@ examples:
             #clock-cells = <1>;
         };
     };
+  - |
+    crg: clock-reset-controller@8a22000 {
+        compatible = "hisilicon,hi3798mv200-crg", "syscon", "simple-mfd";
+        reg = <0x8a22000 0x1000>;
+        ranges = <0x0 0x8a22000 0x1000>;
+        #address-cells = <1>;
+        #size-cells = <1>;
+        #clock-cells = <1>;
+        #reset-cells = <2>;
+
+        emmc_sap_dll: sap-dll@39c {
+            compatible = "hisilicon,sdmmc-sap-dll", "syscon", "simple-mfd";
+            reg = <0x39c 0x8>;
+        };
+
+        sdio0_sap_dll: sap-dll@3a4 {
+            compatible = "hisilicon,sdmmc-sap-dll", "syscon", "simple-mfd";
+            reg = <0x3a4 0x8>;
+        };
+
+        sdio1_sap_dll: sap-dll@3ac {
+            compatible = "hisilicon,sdmmc-sap-dll", "syscon", "simple-mfd";
+            reg = <0x3ac 0x8>;
+        };
+    };

-- 
2.43.0

