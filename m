From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Fri, 23 May 2025 14:51:46 +0200
Subject: [PATCH v4 3/5] dt-bindings: power: supply: add max77759-fg flavor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250523-b4-gs101_max77759_fg-v4-3-b49904e35a34@uclouvain.be>
References: <20250523-b4-gs101_max77759_fg-v4-0-b49904e35a34@uclouvain.be>
In-Reply-To: <20250523-b4-gs101_max77759_fg-v4-0-b49904e35a34@uclouvain.be>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748004727; l=2682;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=GU2WoKOxlaWJoWfEaZr2bJ8lw3s+AOWQv0h8uwcwC90=;
 b=1zMV5uiw+xStEJWY23TLxuRPfW60BpaXrb6tMzTSEz/FqhcXCpWyL8y858ymE4+QoyVLSt7Fu
 iIKgAx0Q2TYCrw1JC4VQmzIV0StD/KwzRrwQOyp3yvofsr+hC59GTRu
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Maxim MAX77759 is an IC used to manage the power supply of the battery
and the USB-C. Based on drivers from google, it contains at least a PMIC,
a fuel gauge, a TCPCI and a charger.

Use max77759-fg compatible to avoid conflict with drivers for other
functions.

The Maxim MAX77759 has no non-volatile memory so it doesn't require an
address and instead requires a value for the current sensing resistor.

Keep shunt-resistor-micro-ohms optional for the MAX17201/MAX17205 as it is
not be used at the moment but could be in the future. (e.g. as a default
value to be used in case of nvmem failure)

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 .../bindings/power/supply/maxim,max17201.yaml      | 42 ++++++++++++++++++++--
 1 file changed, 39 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml b/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml
index fe3dd9bd5585618e45220c51023391a5b21acfd2..2fb826b4b160eb9abe6604185ac2192447d90b8c 100644
--- a/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml
+++ b/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml
@@ -9,13 +9,11 @@ title: Maxim MAX17201 fuel gauge
 maintainers:
   - Dimitri Fedrau <dima.fedrau@gmail.com>
 
-allOf:
-  - $ref: power-supply.yaml#
-
 properties:
   compatible:
     oneOf:
       - const: maxim,max17201
+      - const: maxim,max77759-fg
       - items:
           - enum:
               - maxim,max17205
@@ -25,11 +23,18 @@ properties:
     items:
       - description: ModelGauge m5 registers
       - description: Nonvolatile registers
+    minItems: 1
+    maxItems: 2
 
   reg-names:
     items:
       - const: m5
       - const: nvmem
+    minItems: 1
+    maxItems: 2
+
+  shunt-resistor-micro-ohms:
+    description: The value of current sense resistor in microohms.
 
   interrupts:
     maxItems: 1
@@ -39,6 +44,37 @@ required:
   - reg
   - reg-names
 
+allOf:
+  - $ref: power-supply.yaml#
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - maxim,max17201
+    then:
+      properties:
+        reg:
+          minItems: 2
+        reg-names:
+          minItems: 2
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - maxim,max77759-fg
+    then:
+      properties:
+        reg:
+          maxItems: 1
+        reg-names:
+          maxItems: 1
+      required:
+        - shunt-resistor-micro-ohms
+
 unevaluatedProperties: false
 
 examples:

-- 
2.49.0

