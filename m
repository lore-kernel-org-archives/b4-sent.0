From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Mon, 10 Mar 2025 23:07:58 +0100
Subject: [PATCH v3 1/3] dt-bindings: spmi: Add Apple SPMI controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250310-spmi-v3-1-92a82e7d9f0d@gmail.com>
References: <20250310-spmi-v3-0-92a82e7d9f0d@gmail.com>
In-Reply-To: <20250310-spmi-v3-0-92a82e7d9f0d@gmail.com>
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Stephen Boyd <sboyd@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741644479; l=2426;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=pDg6BHX8yhXPsIWO6kJBvdxVHd8GSLyf4Z1JkcNwg+U=;
 b=KiRktVb0Tmmq+7Xhyq0yRNnEROe9ZZyi+ImNWMBOjbCeAmMaUpU005jmU+n3nQ1fYBavPgpa2
 +okBPspZAOyAsCW5lCzO9nyn6DyALt4HgZONMs6/rnNn/kz69oYue3l
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for the SPMI controller present on most Apple SoCs

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Reviewed-by: Sven Peter <sven@svenpeter.dev>
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 .../devicetree/bindings/spmi/apple,spmi.yaml       | 49 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 50 insertions(+)

diff --git a/Documentation/devicetree/bindings/spmi/apple,spmi.yaml b/Documentation/devicetree/bindings/spmi/apple,spmi.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..16bd7eb2b7af2c0b176f0e5b1970f4670af691da
--- /dev/null
+++ b/Documentation/devicetree/bindings/spmi/apple,spmi.yaml
@@ -0,0 +1,49 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/spmi/apple,spmi.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple SPMI controller
+
+maintainers:
+  - Sasha Finkelstein <fnkl.kernel@gmail.com>
+
+description: A SPMI controller present on most Apple SoCs
+
+allOf:
+  - $ref: spmi.yaml#
+
+properties:
+  compatible:
+    items:
+      - enum:
+          - apple,t8103-spmi
+          - apple,t6000-spmi
+          - apple,t8112-spmi
+      - const: apple,spmi
+
+  reg:
+    maxItems: 1
+
+required:
+  - compatible
+  - reg
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/spmi/spmi.h>
+
+    spmi@920a1300 {
+        compatible = "apple,t6000-spmi", "apple,spmi";
+        reg = <0x920a1300 0x100>;
+        #address-cells = <2>;
+        #size-cells = <0>;
+
+        pmic@f {
+            reg = <0xf SPMI_USID>;
+            /* PMIC-specific properties */
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 8e0736dc2ee0e33544fa373a4978b7dae18c040c..271ff8110df83c2d4fe7fbbfffc0a72259460bc5 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2236,6 +2236,7 @@ F:	Documentation/devicetree/bindings/pci/apple,pcie.yaml
 F:	Documentation/devicetree/bindings/pinctrl/apple,pinctrl.yaml
 F:	Documentation/devicetree/bindings/power/apple*
 F:	Documentation/devicetree/bindings/pwm/apple,s5l-fpwm.yaml
+F:	Documentation/devicetree/bindings/spmi/apple,spmi.yaml
 F:	Documentation/devicetree/bindings/watchdog/apple,wdt.yaml
 F:	arch/arm64/boot/dts/apple/
 F:	drivers/bluetooth/hci_bcm4377.c

-- 
2.48.1

