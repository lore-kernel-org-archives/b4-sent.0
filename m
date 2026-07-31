From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 31 Jul 2026 09:08:25 +0000
Subject: [PATCH v3 1/4] spi: dt-bindings: amlogic: spisg: Document
 A9-specific properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-a9-spisg-v3-1-a15da3f70029@amlogic.com>
References: <20260731-a9-spisg-v3-0-a15da3f70029@amlogic.com>
In-Reply-To: <20260731-a9-spisg-v3-0-a15da3f70029@amlogic.com>
To: Sunny Luo <sunny.luo@amlogic.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785488907; l=1955;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=QmBAAmHCz75ak/gTg3Z9nJO6Jq52E/H1aEusSVZgdR4=;
 b=6bqBPyY+DBxWpopJLpgnlBtH3rVrZ5+pz5Wlt8IJ1ilczXy3WgZjCdg9Gjx4dtyQzwq4Fyv+6
 yK3E5ed6SLFBwOJq2eLWHDSc2TherqH/VVAuog4cO1XYJs5L8vxb1U8
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Amlogic A9 SPISG controller and its additional Device Tree
properties.

Add the "amlogic,a9-spisg" compatible string and define the A9-specific
"amlogic,mo-idle-output" property, which configure the MOSI idle output
level.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../devicetree/bindings/spi/amlogic,a4-spisg.yaml  | 30 +++++++++++++++++++---
 1 file changed, 26 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/spi/amlogic,a4-spisg.yaml b/Documentation/devicetree/bindings/spi/amlogic,a4-spisg.yaml
index 9bfb8089f7ea..427d8883009c 100644
--- a/Documentation/devicetree/bindings/spi/amlogic,a4-spisg.yaml
+++ b/Documentation/devicetree/bindings/spi/amlogic,a4-spisg.yaml
@@ -11,12 +11,11 @@ maintainers:
   - Xianwei Zhao <xianwei.zhao@amlogic.com>
   - Sunny Luo <sunny.luo@amlogic.com>
 
-allOf:
-  - $ref: spi-controller.yaml#
-
 properties:
   compatible:
-    const: amlogic,a4-spisg
+    enum:
+      - amlogic,a4-spisg
+      - amlogic,a9-spisg
 
   reg:
     maxItems: 1
@@ -35,6 +34,16 @@ properties:
   resets:
     maxItems: 1
 
+  amlogic,mo-idle-output:
+    description: |
+      Controls the MOSI output level when the controller is idle.
+      0 - Drive MOSI low
+      1 - Drive MOSI high
+      2 - Follow the last transmitted bit
+    $ref: /schemas/types.yaml#/definitions/uint32
+    enum: [0, 1, 2]
+    default: 0
+
 required:
   - compatible
   - reg
@@ -42,6 +51,19 @@ required:
   - clocks
   - clock-names
 
+allOf:
+  - $ref: spi-controller.yaml#
+  - if:
+      not:
+        properties:
+          compatible:
+            contains:
+              enum:
+                - amlogic,a9-spisg
+    then:
+      properties:
+        amlogic,mo-idle-output: false
+
 unevaluatedProperties: false
 
 examples:

-- 
2.52.0

