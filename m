From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 08 May 2026 07:36:55 +0000
Subject: [PATCH 2/3] dt-bindings: interrupt-controller: Add support for
 Amlogic A9 SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-a9-gpio-irqchip-v1-2-9dc5f3e022e0@amlogic.com>
References: <20260508-a9-gpio-irqchip-v1-0-9dc5f3e022e0@amlogic.com>
In-Reply-To: <20260508-a9-gpio-irqchip-v1-0-9dc5f3e022e0@amlogic.com>
To: Thomas Gleixner <tglx@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778225816; l=1795;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=6Ljc1slqURABvNOkxflZQUxRIhozTfJrbGsFoDMyXeA=;
 b=FGj3PF7NeRbke8xYI6Q3J8mraEC49BIYBCUw3ET5JId6vNWy/5ET7h6d/GXrJJR3ROg1CM244
 Ix0Lkab3dU4Au7D4014LTpdOow2YnWClYCdjc0VvCspyBWm2aqbmrT7
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update dt-binding document for GPIO interrupt controller
of Amlogic A9 SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../amlogic,meson-gpio-intc.yaml                    | 21 +++++++++++++++++----
 1 file changed, 17 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/interrupt-controller/amlogic,meson-gpio-intc.yaml b/Documentation/devicetree/bindings/interrupt-controller/amlogic,meson-gpio-intc.yaml
index d0fad930de9d..d26671913e89 100644
--- a/Documentation/devicetree/bindings/interrupt-controller/amlogic,meson-gpio-intc.yaml
+++ b/Documentation/devicetree/bindings/interrupt-controller/amlogic,meson-gpio-intc.yaml
@@ -38,6 +38,8 @@ properties:
               - amlogic,a4-gpio-intc
               - amlogic,a4-gpio-ao-intc
               - amlogic,a5-gpio-intc
+              - amlogic,a9-gpio-intc
+              - amlogic,a9-gpio-ao-intc
               - amlogic,c3-gpio-intc
               - amlogic,s6-gpio-intc
               - amlogic,s7-gpio-intc
@@ -56,7 +58,7 @@ properties:
   amlogic,channel-interrupts:
     description: Array with the upstream hwirq numbers
     minItems: 2
-    maxItems: 12
+    maxItems: 20
     $ref: /schemas/types.yaml#/definitions/uint32-array
 
 required:
@@ -76,9 +78,20 @@ then:
     amlogic,channel-interrupts:
       maxItems: 2
 else:
-  properties:
-    amlogic,channel-interrupts:
-      minItems: 8
+  if:
+    properties:
+      compatible:
+        contains:
+          const: amlogic,a9-gpio-ao-intc
+  then:
+    properties:
+      amlogic,channel-interrupts:
+        minItems: 20
+  else:
+    properties:
+      amlogic,channel-interrupts:
+        minItems: 8
+        maxItems: 12
 
 additionalProperties: false
 

-- 
2.52.0

