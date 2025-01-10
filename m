From: Ao Xu <ao.xu@amlogic.com>
Date: Fri, 10 Jan 2025 13:39:52 +0800
Subject: [PATCH 02/11] dt-bindings: display: meson-vpu: Add compatible for
 S4 display controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250110-drm-s4-v1-2-cbc2d5edaae8@amlogic.com>
References: <20250110-drm-s4-v1-0-cbc2d5edaae8@amlogic.com>
In-Reply-To: <20250110-drm-s4-v1-0-cbc2d5edaae8@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: dri-devel@lists.freedesktop.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Ao Xu <ao.xu@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736487593; l=2203;
 i=ao.xu@amlogic.com; s=20250103; h=from:subject:message-id;
 bh=7+BtboC52S07wz4NFzmNC6kZHvkpp2eBKVt3C4Xqx5Y=;
 b=CfujSyzUv9OLLfUTtlU/ZasbtyNhObfGZZzeJqGPSuymCtEYkqty8iYTDGqEc3XrrmliBV6r1
 pypNDhmrAXdCOb1JDhpEygzsZ+uDPnUt6CnWrJ0A1eycBeCoOwfv2gV
X-Developer-Key: i=ao.xu@amlogic.com; a=ed25519;
 pk=c0TSXrwQuL4EhPVf3lJ676U27ax2yfFTqmRoseP/fA8=
X-Endpoint-Received: by B4 Relay for ao.xu@amlogic.com/20250103 with auth_id=308
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree document for S4 VPU

Signed-off-by: Ao Xu <ao.xu@amlogic.com>
---
 .../bindings/display/amlogic,meson-vpu.yaml        | 48 ++++++++++++++++++++--
 1 file changed, 44 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/amlogic,meson-vpu.yaml b/Documentation/devicetree/bindings/display/amlogic,meson-vpu.yaml
index cb0a90f0232190031430c08f936b8f0d3b217601..3d7eceb3724e81d9c911039507df072d332a028f 100644
--- a/Documentation/devicetree/bindings/display/amlogic,meson-vpu.yaml
+++ b/Documentation/devicetree/bindings/display/amlogic,meson-vpu.yaml
@@ -66,14 +66,13 @@ properties:
           - const: amlogic,meson-gx-vpu
       - enum:
           - amlogic,meson-g12a-vpu # G12A (S905X2, S905Y2, S905D2)
+          - amlogic,meson-s4-vpu # S4 (S905Y4)
 
   reg:
-    maxItems: 2
+    minItems: 2
 
   reg-names:
-    items:
-      - const: vpu
-      - const: hhi
+    minItems: 2
 
   interrupts:
     maxItems: 1
@@ -117,6 +116,47 @@ required:
   - "#size-cells"
   - amlogic,canvas
 
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: amlogic,meson-s4-vpu
+    then:
+      properties:
+        reg:
+          items:
+            - description: vcbus registers
+            - description: hhi registers
+            - description: clkctrl registers
+            - description: power control registers
+            - description: sysctrl registers
+        reg-names:
+          items:
+            - const: vpu
+            - const: hhi
+            - const: clkctrl
+            - const: pwctrl
+            - const: sysctrl
+        clocks:
+          items:
+            - description: vpu clock
+            - description: vapb clock
+        clock-names:
+          items:
+            - const: vpu
+            - const: vapb
+    else:
+      properties:
+        reg:
+          items:
+            - description: vcbus registers
+            - description: hhi registers
+        reg-names:
+          items:
+            - const: vpu
+            - const: hhi
+
 additionalProperties: false
 
 examples:

-- 
2.43.0

