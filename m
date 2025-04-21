From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Mon, 21 Apr 2025 20:13:34 +0200
Subject: [PATCH v3 3/5] dt-bindings: power: supply: add max77759-fg flavor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250421-b4-gs101_max77759_fg-v3-3-50cd8caf9017@uclouvain.be>
References: <20250421-b4-gs101_max77759_fg-v3-0-50cd8caf9017@uclouvain.be>
In-Reply-To: <20250421-b4-gs101_max77759_fg-v3-0-50cd8caf9017@uclouvain.be>
To: Rob Herring <robh@kernel.org>, Peter Griffin <peter.griffin@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alim Akhtar <alim.akhtar@samsung.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sebastian Reichel <sre@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745259219; l=2149;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=3csHwNLf51MgGPB35l/jqx2BDbuC5NezSGJ/M4ttHB0=;
 b=hdZ5Rso1TYtabh6eg8jkEmrW24+n8D/oOip4OJEpl0tOPzFFs4tV0EiJ5qsDr9uqLuRHV1LkY
 qVAnT3vizopCgmKHmOf+5qkukpUjrQt83QCOiMFRCY6pmqavfYCltWB
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

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 .../bindings/power/supply/maxim,max17201.yaml      | 34 ++++++++++++++++++++--
 1 file changed, 31 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml b/Documentation/devicetree/bindings/power/supply/maxim,max17201.yaml
index fe3dd9bd5585618e45220c51023391a5b21acfd2..4823021ff16b170db83abd0b974986a307c05089 100644
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
@@ -39,6 +37,36 @@ required:
   - reg
   - reg-names
 
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
+          minItems: 2
+          maxItems: 2
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
+            minItems: 1
+            maxItems: 1
+        shunt-resistor-micro-ohms:
+          description: The value of current sense resistor in microohms.
+      required:
+        - shunt-resistor-micro-ohms
+
 unevaluatedProperties: false
 
 examples:

-- 
2.49.0

