From: Han Gao <gaohan@iscas.ac.cn>
Date: Thu, 26 Nov 2026 21:41:09 +0800
Subject: [PATCH v2 1/4] dt-bindings: pinctrl: add the Allwinner V861 pin
 controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-v861-pinctrl-v2-1-b1875a6a9bb8@iscas.ac.cn>
References: <20261126-v861-pinctrl-v2-0-b1875a6a9bb8@iscas.ac.cn>
In-Reply-To: <20261126-v861-pinctrl-v2-0-b1875a6a9bb8@iscas.ac.cn>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>, Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795700469; l=2853;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=+X+OFPTDQ3iXtYAUKsVqLJUtKcjryQ21gQGY0NMVTX0=;
 b=kKjprBu2KIbyopgvjFkBc+pYccd3LmiRde/a/iiQb8DvVj+ZnhEQCbWOaWrIbDSLu52x+EUkF
 44T1CHQ3agiB/E9/1fv2WXsoi3U+n8/mhH2X10bLaoeOyADARDdEhaw
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The V861 main and always-on pin controllers follow the A523 binding.
The always-on one has a single interrupt bank, so lower the top-level
minimum of interrupts and input-debounce to one. The per-SoC conditions
keep the previous minimums for the A523 and A733.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 .../pinctrl/allwinner,sun55i-a523-pinctrl.yaml     | 36 ++++++++++++++++++++--
 1 file changed, 33 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/pinctrl/allwinner,sun55i-a523-pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/allwinner,sun55i-a523-pinctrl.yaml
index d7d0ba32ced4..40fd54af871f 100644
--- a/Documentation/devicetree/bindings/pinctrl/allwinner,sun55i-a523-pinctrl.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/allwinner,sun55i-a523-pinctrl.yaml
@@ -4,7 +4,7 @@
 $id: http://devicetree.org/schemas/pinctrl/allwinner,sun55i-a523-pinctrl.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
-title: Allwinner A523 & A733 Pin Controller
+title: Allwinner A523, A733 & V861 Pin Controller
 
 maintainers:
   - Andre Przywara <andre.przywara@arm.com>
@@ -26,6 +26,8 @@ properties:
 
   compatible:
     enum:
+      - allwinner,sun252i-v861-pinctrl
+      - allwinner,sun252i-v861-r-pinctrl
       - allwinner,sun55i-a523-pinctrl
       - allwinner,sun55i-a523-r-pinctrl
       - allwinner,sun60i-a733-pinctrl
@@ -35,7 +37,7 @@ properties:
     maxItems: 1
 
   interrupts:
-    minItems: 2
+    minItems: 1
     maxItems: 11
     description:
       One interrupt per external interrupt bank supported on the
@@ -62,7 +64,7 @@ properties:
       Debouncing periods in microseconds, one period per interrupt
       bank found in the controller
     $ref: /schemas/types.yaml#/definitions/uint32-array
-    minItems: 2
+    minItems: 1
     maxItems: 11
 
 patternProperties:
@@ -135,6 +137,8 @@ allOf:
         interrupts:
           minItems: 11
           maxItems: 11
+        input-debounce:
+          minItems: 2
 
   - if:
       properties:
@@ -148,6 +152,32 @@ allOf:
         interrupts:
           minItems: 2
           maxItems: 2
+        input-debounce:
+          minItems: 2
+
+  - if:
+      properties:
+        compatible:
+          const: allwinner,sun252i-v861-pinctrl
+    then:
+      properties:
+        interrupts:
+          minItems: 7
+          maxItems: 7
+        input-debounce:
+          minItems: 7
+          maxItems: 7
+
+  - if:
+      properties:
+        compatible:
+          const: allwinner,sun252i-v861-r-pinctrl
+    then:
+      properties:
+        interrupts:
+          maxItems: 1
+        input-debounce:
+          maxItems: 1
 
 additionalProperties: false
 

-- 
2.55.0

