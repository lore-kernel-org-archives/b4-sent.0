From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Thu, 02 Jan 2025 12:15:04 +0100
Subject: [PATCH v2 2/4] dt-bindings: power: supply: add max77759-fg flavor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250102-b4-gs101_max77759_fg-v2-2-87959abeb7ff@uclouvain.be>
References: <20250102-b4-gs101_max77759_fg-v2-0-87959abeb7ff@uclouvain.be>
In-Reply-To: <20250102-b4-gs101_max77759_fg-v2-0-87959abeb7ff@uclouvain.be>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735816515; l=2599;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=NQEfG+SwFTGG+va2nEDX792ufRBYG0gtt35ac3EAHLY=;
 b=jM9VyggQ6eUW1RT5Sw+s3vgG3v7+G7XxjmfVHL2taeQU21fLP17pnVRrLZpT7NYIGIpDtxYrk
 OMqxPoSo6FqBEGjo0OnJe41tXf4Ii/jZK6JPj76xV1c1Vmui0kl7rNh
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The max77759 is an IC used to manage the power supply of the battery and
the USB-C. Based on drivers from google, it contains at least a PMIC, a
fuel gauge, a TCPCI and a charger.

Use max77759-fg compatible to avoid conflict with drivers for other
functions.

The max77759 has no non-volatile memory so it doesn't require an address
and instead requires a value for the current sensing resistor.

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 .../bindings/power/supply/maxim,max17201.yaml      | 56 +++++++++++++++++-----
 1 file changed, 43 insertions(+), 13 deletions(-)

diff --git a/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml b/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml
index fe3dd9bd5585618e45220c51023391a5b21acfd2..7e95314508c27d0d90ea92f61bca6b4a2fe0e88e 100644
--- a/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml
+++ b/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml
@@ -9,31 +9,61 @@ title: Maxim MAX17201 fuel gauge
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
           - const: maxim,max17201
 
-  reg:
-    items:
-      - description: ModelGauge m5 registers
-      - description: Nonvolatile registers
-
-  reg-names:
-    items:
-      - const: m5
-      - const: nvmem
-
   interrupts:
     maxItems: 1
 
+allOf:
+  - $ref: power-supply.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - maxim,max17201
+    then:
+      properties:
+        reg:
+          items:
+            - description: ModelGauge m5 registers
+            - description: Nonvolatile registers
+          minItems: 1
+
+        reg-names:
+          items:
+            - const: m5
+            - const: nvmem
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - maxim,max77759-fg
+    then:
+      properties:
+        reg:
+          items:
+            - description: ModelGauge m5 registers
+
+        reg-names:
+          items:
+            - const: m5
+
+        shunt-resistor-micro-ohms:
+          description: The value of current sense resistor.
+
+      required:
+        - shunt-resistor-micro-ohms
+
 required:
   - compatible
   - reg

-- 
2.47.1

