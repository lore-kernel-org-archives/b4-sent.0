From: Woodrow Douglass <wdouglass@carnegierobotics.com>
Date: Fri, 05 Sep 2025 08:39:42 -0400
Subject: [PATCH v7 1/2] regulator: dt-bindings: nxp,pf530x: Add NXP
 PF5300/PF5301/PF5302 PMICs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250902-pf530x-v7-1-10eb2542f944@carnegierobotics.com>
References: <20250902-pf530x-v7-0-10eb2542f944@carnegierobotics.com>
In-Reply-To: <20250902-pf530x-v7-0-10eb2542f944@carnegierobotics.com>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Woodrow Douglass <wdouglass@carnegierobotics.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2021;
 i=wdouglass@carnegierobotics.com; h=from:subject:message-id;
 bh=GD/QKOeIwH6rbORAuBGoRr4qUHkMzXDClFHYwzK9aEo=;
 b=owEBbQGS/pANAwAKAewLuLlPNh4UAcsmYgBoutohx0/o4FKRg04xIhoXtqGt+27lNHYVpW1JX
 3H4P5K3WbCJATMEAAEKAB0WIQSIUqjrbDLQw0mgxHLsC7i5TzYeFAUCaLraIQAKCRDsC7i5TzYe
 FI/dCACW0IxiwITRW1ui2rqoV6KRQAW894ZHeskC9UF9YeYKhmKK8VmMm/AGeH8Vc0wxG8sL/wh
 CvktFGvZp36fXeHSIbbFCHB80o2e0QS74qyw/Pi5klColoZEXLwtEFCdUZNudwX9tRXKPVDUTSc
 dH/XwJH9vo2RjQlfYltjeyp3AT/AB2GyhK/6xDCOCSqMiNKWutKLW93PumnF3mRnzFPat5ojZaM
 Qj3xep1a2WAjhVjTldcHwsVHElyucESvujLeZA9Gn1Q87X9kcQOdwIB0b8/O/87AnQg2zIn7ymX
 JZ5g/65o8mHa0Zrew9iWy2K96v1ptySWSZum7N+v+Md+/g7I
X-Developer-Key: i=wdouglass@carnegierobotics.com; a=openpgp;
 fpr=8852A8EB6C32D0C349A0C472EC0BB8B94F361E14
X-Endpoint-Received: by B4 Relay for wdouglass@carnegierobotics.com/default with auth_id=514
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bindings for the pf530x series of voltage regulators

Signed-off-by: Woodrow Douglass <wdouglass@carnegierobotics.com>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
---
 .../devicetree/bindings/regulator/nxp,pf5300.yaml  | 54 ++++++++++++++++++++++
 1 file changed, 54 insertions(+)

diff --git a/Documentation/devicetree/bindings/regulator/nxp,pf5300.yaml b/Documentation/devicetree/bindings/regulator/nxp,pf5300.yaml
new file mode 100644
index 000000000000..5b9d5d4e48d0
--- /dev/null
+++ b/Documentation/devicetree/bindings/regulator/nxp,pf5300.yaml
@@ -0,0 +1,54 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/regulator/nxp,pf5300.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: NXP PF5300/PF5301/PF5302 PMIC regulators
+
+maintainers:
+  - Woodrow Douglass <wdouglass@carnegierobotics.com>
+
+description: |
+  The PF5300, PF5301, and PF5302 integrate high-performance buck converters,
+  12 A, 8 A, and 15 A, respectively, to power high-end automotive and industrial
+  processors. With adaptive voltage positioning and a high-bandwidth loop, they
+  offer transient regulation to minimize capacitor requirements.
+
+allOf:
+  - $ref: regulator.yaml#
+
+properties:
+  compatible:
+    oneOf:
+      - const: nxp,pf5300
+      - items:
+          - enum:
+              - nxp,pf5301
+              - nxp,pf5302
+          - const: nxp,pf5300
+  reg:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        regulator@28 {
+            compatible = "nxp,pf5302", "nxp,pf5300";
+            reg = <0x28>;
+
+            regulator-always-on;
+            regulator-boot-on;
+            regulator-max-microvolt = <1200000>;
+            regulator-min-microvolt = <500000>;
+        };
+    };

-- 
2.39.5

