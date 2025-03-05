From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 05 Mar 2025 18:02:56 +0800
Subject: [PATCH v3 1/4] dt-bindings: interrupt-controller: Add support for
 Amlogic A4 and A5 SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250305-irqchip-gpio-a4-a5-v3-1-1eec70352fea@amlogic.com>
References: <20250305-irqchip-gpio-a4-a5-v3-0-1eec70352fea@amlogic.com>
In-Reply-To: <20250305-irqchip-gpio-a4-a5-v3-0-1eec70352fea@amlogic.com>
To: Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741168977; l=1783;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=OtlX8UcJ+H1FILMyJjS4Bk1MwFvAcPTPGY/5f/EGqhc=;
 b=4wZeRoU6l7Aj8hPhoOsLF5THFXD8UqzSXyDROQXOoEDx/vXtMbkGDyO5kuYWx1z6El7eCqUl9
 3vjbfPxwPt1Bxr853P4Cj7wfw/2NEhT2n7CLT6izVvjs4qUVMVGnvDa
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update dt-binding document for GPIO interrupt controller
of Amlogic A4 and A5 SoCs

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../amlogic,meson-gpio-intc.yaml                    | 21 +++++++++++++++++++--
 1 file changed, 19 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/interrupt-controller/amlogic,meson-gpio-intc.yaml b/Documentation/devicetree/bindings/interrupt-controller/amlogic,meson-gpio-intc.yaml
index a93744763787..3c5853c71efa 100644
--- a/Documentation/devicetree/bindings/interrupt-controller/amlogic,meson-gpio-intc.yaml
+++ b/Documentation/devicetree/bindings/interrupt-controller/amlogic,meson-gpio-intc.yaml
@@ -35,6 +35,9 @@ properties:
               - amlogic,meson-sm1-gpio-intc
               - amlogic,meson-a1-gpio-intc
               - amlogic,meson-s4-gpio-intc
+              - amlogic,a4-gpio-intc
+              - amlogic,a4-gpio-ao-intc
+              - amlogic,a5-gpio-intc
               - amlogic,c3-gpio-intc
               - amlogic,t7-gpio-intc
           - const: amlogic,meson-gpio-intc
@@ -49,8 +52,6 @@ properties:
 
   amlogic,channel-interrupts:
     description: Array with the upstream hwirq numbers
-    minItems: 8
-    maxItems: 12
     $ref: /schemas/types.yaml#/definitions/uint32-array
 
 required:
@@ -60,6 +61,22 @@ required:
   - "#interrupt-cells"
   - amlogic,channel-interrupts
 
+if:
+  properties:
+    compatible:
+      contains:
+        const: amlogic,a4-gpio-ao-intc
+then:
+  properties:
+    amlogic,channel-interrupts:
+      minItems: 2
+      maxItems: 12
+else:
+  properties:
+    amlogic,channel-interrupts:
+      minItems: 8
+      maxItems: 12
+
 additionalProperties: false
 
 examples:

-- 
2.37.1

