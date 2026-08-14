From: Long Zhao <longzhao@ambarella.com>
Date: Fri, 14 Aug 2026 14:25:42 +0800
Subject: [PATCH v4 2/4] dt-bindings: gpio: pl061: add Ambarella CV75
 variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260814-cv75-v4-b-v4-2-ef2e83ec0eac@ambarella.com>
References: <20260814-cv75-v4-b-v4-0-ef2e83ec0eac@ambarella.com>
In-Reply-To: <20260814-cv75-v4-b-v4-0-ef2e83ec0eac@ambarella.com>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786688764; l=1941;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=Pngr7p+U3E/qWLbm7iUMOUjiAHv8IZUzMpz2/ZKNyVk=;
 b=9gDEX+Je0r5Q2wLy6qzP4LRjhNA9Jm5Y17qdFenFRkBmS6C5TEkdv4mfj5//eQwNfdo1gNbZe
 AnDzcY4Zc+QAdoBtRImv+Xgcd58ndHF2UNlNVE1ZGjknMdPprU8pm+l
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Ambarella CV75 GPIO bank compatible and the synthetic
arm,primecell-periphid used with the PL061 binding.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 .../devicetree/bindings/gpio/pl061-gpio.yaml       | 35 +++++++++++++++++++---
 1 file changed, 31 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/gpio/pl061-gpio.yaml b/Documentation/devicetree/bindings/gpio/pl061-gpio.yaml
index 4d970e55104b..414f8d4a3976 100644
--- a/Documentation/devicetree/bindings/gpio/pl061-gpio.yaml
+++ b/Documentation/devicetree/bindings/gpio/pl061-gpio.yaml
@@ -15,7 +15,9 @@ select:
   properties:
     compatible:
       contains:
-        const: arm,pl061
+        enum:
+          - arm,pl061
+          - ambarella,cv75-gpio
   required:
     - compatible
 
@@ -24,9 +26,20 @@ properties:
     pattern: "^gpio@[0-9a-f]+$"
 
   compatible:
-    items:
-      - const: arm,pl061
-      - const: arm,primecell
+    oneOf:
+      - items:
+          - const: arm,pl061
+          - const: arm,primecell
+      - items:
+          - const: ambarella,cv75-gpio
+          - const: arm,primecell
+
+  arm,primecell-periphid:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description:
+      Value to override the hardware PrimeCell peripheral ID. Ambarella
+      variants use a synthetic ID retaining the PL061 part number because
+      the hardware has no discoverable ID or assigned designer ID.
 
   reg:
     maxItems: 1
@@ -57,6 +70,20 @@ properties:
     minItems: 1
     maxItems: 8
 
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: ambarella,cv75-gpio
+    then:
+      properties:
+        arm,primecell-periphid:
+          const: 0x00000061
+      required:
+        - arm,primecell-periphid
+        - gpio-ranges
+
 required:
   - compatible
   - reg

-- 
2.34.1

