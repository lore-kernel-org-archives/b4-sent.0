From: Woodrow Douglass <wdouglass@carnegierobotics.com>
Date: Thu, 04 Sep 2025 16:44:35 -0400
Subject: [PATCH v6 1/2] regulator: pf530x: dt-bindings:
 nxp,pf530x-regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250902-pf530x-v6-1-ae5efea2198d@carnegierobotics.com>
References: <20250902-pf530x-v6-0-ae5efea2198d@carnegierobotics.com>
In-Reply-To: <20250902-pf530x-v6-0-ae5efea2198d@carnegierobotics.com>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Woodrow Douglass <wdouglass@carnegierobotics.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1954;
 i=wdouglass@carnegierobotics.com; h=from:subject:message-id;
 bh=Ltyt1DbuiWkawifRpmJUYq01xxDkOrXle2C+GGe+I+Y=;
 b=owEBbQGS/pANAwAKAewLuLlPNh4UAcsmYgBoufo4UXlGhoVBkmPhfiOp8qT8NFUuAvVwOblPm
 QeIaUEX/Z+JATMEAAEKAB0WIQSIUqjrbDLQw0mgxHLsC7i5TzYeFAUCaLn6OAAKCRDsC7i5TzYe
 FAqIB/9OCZWELHI72du5/94P/xPyQ0YyjcqXPDB8EWCwahbXGr472p7TqoTcJkGOy0GreCSNabJ
 yDfFyQTnNSo80qgpyV9robwos9n+Mfb/ttTPNMkrz9an2QndRyRwddPnRL3bULlNZ6RPMOrC3qF
 HQdZNtlzNDysM1Pxk49LaTSV802p2Ztg82+PVK4C2wqMN5wXlEb/fm2vCRf5hKgdCVKxeLp/Fte
 VjFtLhn+oweHvtIaHt8mNFkhMy0109Pao5R6n3xUTVztstaKKue80A0b9lauEDe6mSlAdCMRDgP
 exRfa2bKozlLWRFDOThcp5s5gJ3ow4YgT02MkYOjTIrxdzfN
X-Developer-Key: i=wdouglass@carnegierobotics.com; a=openpgp;
 fpr=8852A8EB6C32D0C349A0C472EC0BB8B94F361E14
X-Endpoint-Received: by B4 Relay for wdouglass@carnegierobotics.com/default with auth_id=514
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bindings for the pf530x series of voltage regulators

Signed-off-by: Woodrow Douglass <wdouglass@carnegierobotics.com>
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

