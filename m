From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 22 Feb 2024 00:41:04 +0800
Subject: [PATCH v3 1/8] dt-bindings: clock: convert hisi-crg.txt to YAML
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240222-clk-mv200-v3-1-f30795b50318@outlook.com>
References: <20240222-clk-mv200-v3-0-f30795b50318@outlook.com>
In-Reply-To: <20240222-clk-mv200-v3-0-f30795b50318@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708533664; l=2410;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=e4ZAxJ8Lbk3HDBssdHe1QUVePLSWlZsNs3s4SArOgJI=;
 b=o0WcTEzhdU8xHqE/WOiTDhMlymGeAJSbT0qbwwa5mbHfJSLvNwLBA6ccO8D9OH4BioeTEAAGN
 HxVrA4cSw0tBzTfglLHLXYj3jscBdrScWngkPryQiHRP/8l7zCccLUQ
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Also rename to hisilicon,hisi-crg.yaml. While at it, add "syscon" and
"simple-mfd" compatibles to match the existing dts.

Add reset-controller subnode for hisilicon,hi3798cv200-crg to match the
existing hi3798cv200.dtsi.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../bindings/clock/hisilicon,hisi-crg.yaml         | 69 ++++++++++++++++++++++
 1 file changed, 69 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/hisilicon,hisi-crg.yaml b/Documentation/devicetree/bindings/clock/hisilicon,hisi-crg.yaml
new file mode 100644
index 000000000000..2cf21cb5ff27
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/hisilicon,hisi-crg.yaml
@@ -0,0 +1,69 @@
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
+    items:
+      - enum:
+          - hisilicon,hi3516cv300-crg
+          - hisilicon,hi3516cv300-sysctrl
+          - hisilicon,hi3519-crg
+          - hisilicon,hi3798cv200-crg
+          - hisilicon,hi3798cv200-sysctrl
+      - const: syscon
+      - const: simple-mfd
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
+  - '#clock-cells'
+
+allOf:
+  - if:
+      properties:
+        compatible:
+          not:
+            contains:
+              const: hisilicon,hi3798cv200-crg
+    then:
+      properties:
+        reset-controller: false
+
+additionalProperties: false
+
+examples:
+  - |
+    clock-reset-controller@12010000 {
+        compatible = "hisilicon,hi3519-crg", "syscon", "simple-mfd";
+        reg = <0x12010000 0x10000>;
+        #clock-cells = <1>;
+        #reset-cells = <2>;
+    };

-- 
2.43.0

