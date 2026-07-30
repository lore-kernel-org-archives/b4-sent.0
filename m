From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 30 Jul 2026 08:34:37 +0000
Subject: [PATCH 1/2] dt-bindings: thermal: amlogic: Add A9 thermal bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-a9-thermal-v1-1-d786d37cba58@amlogic.com>
References: <20260730-a9-thermal-v1-0-d786d37cba58@amlogic.com>
In-Reply-To: <20260730-a9-thermal-v1-0-d786d37cba58@amlogic.com>
To: Guillaume La Roque <glaroque@baylibre.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785400497; l=2032;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=a2jDBBmn4Im07LAaY1RPp+SwGvK+6Pv6kYhWR+NQIKY=;
 b=5JXLh377xnZAYCkjTOkmo9Amu8ZrBVMLJbqzx0+yVYyODdrh310hP4MJiZA6/Ks+DkT8G86mf
 wL62TLUnu/VCPLkhvreP6/c9OrkpDKkpBmp/r5KBke+mJFpgegMJe9D
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the thermal controller compatibles for the Amlogic A9 SoC.

Describe the required "core" and "plck" clocks, add the optional
"amlogic,hw-reset-temp" property, and update the schema constraints for
A9-specific thermal controllers.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../bindings/thermal/amlogic,thermal.yaml          | 29 +++++++++++++++++++++-
 1 file changed, 28 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/thermal/amlogic,thermal.yaml b/Documentation/devicetree/bindings/thermal/amlogic,thermal.yaml
index 8cfa44dcda58..5f5dc6f12851 100644
--- a/Documentation/devicetree/bindings/thermal/amlogic,thermal.yaml
+++ b/Documentation/devicetree/bindings/thermal/amlogic,thermal.yaml
@@ -23,6 +23,7 @@ properties:
           - const: amlogic,g12a-thermal
       - enum:
           - amlogic,a1-cpu-thermal
+          - amlogic,a9-thermal
           - amlogic,t7-thermal
 
   reg:
@@ -32,7 +33,13 @@ properties:
     maxItems: 1
 
   clocks:
-    maxItems: 1
+    minItems: 1
+    maxItems: 2
+
+  clock-names:
+    items:
+      - const: core
+      - const: pclk
 
   power-domains:
     maxItems: 1
@@ -52,6 +59,10 @@ properties:
           - description: phandle to the secure monitor
           - description: sensor index to get specific calibration data
 
+  amlogic,hw-reset-temp:
+    description: The hardware-controlled reset temperature value.
+    $ref: /schemas/types.yaml#/definitions/uint32
+
 required:
   - compatible
   - reg
@@ -73,6 +84,22 @@ allOf:
       required:
         - amlogic,secure-monitor
 
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - amlogic,a9-thermal
+    then:
+      required:
+        - clock-names
+    else:
+      properties:
+        clocks:
+          maxItems: 1
+        clocks-names: false
+        amlogic,hw-reset-temp: false
+
 unevaluatedProperties: false
 
 examples:

-- 
2.52.0

