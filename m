From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Wed, 19 Feb 2025 10:26:59 +0100
Subject: [PATCH 3/5] media: dt-bindings: Add Apple ISP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250219-isp-v1-3-6d3e89b67c31@gmail.com>
References: <20250219-isp-v1-0-6d3e89b67c31@gmail.com>
In-Reply-To: <20250219-isp-v1-0-6d3e89b67c31@gmail.com>
To: Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>, 
 Ulf Hansson <ulf.hansson@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-media@vger.kernel.org, imx@lists.linux.dev, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739957223; l=5702;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=A9oH4JPrA84M2AIoue7FVKM9TwqTr7E5y+sVJjno88Q=;
 b=XBhltGV9upjAetievVsxuOOHOJqwjFWEQS4CcHPjb8inxvCNo5X/gTHoybc1LTAJ95fVKfZnn
 R/qqq4PjLRxAYmNoyZE26x0HUOU0QvIf2WDp0SQzmEyQYl5M+8cWoMF
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for the ISP used with the webcam in Apple
ARM laptops.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 .../devicetree/bindings/media/apple,isp.yaml       | 151 +++++++++++++++++++++
 MAINTAINERS                                        |   1 +
 2 files changed, 152 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/apple,isp.yaml b/Documentation/devicetree/bindings/media/apple,isp.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..67d536b61851af30fcc5bc452a761138876c6b18
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/apple,isp.yaml
@@ -0,0 +1,151 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/apple,isp.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: An ISP block used in Apple products
+
+maintainers:
+  - Sasha Finkelstein <fnkl.kernel@gmail.com>
+
+description:
+  The ISP in charge of webcams on ARM Apple laptops
+
+properties:
+  compatible:
+    items:
+      - enum:
+          - apple,t8103-isp
+          - apple,t8112-isp
+          - apple,t6000-isp
+          - apple,t6020-isp
+      - const: apple,isp
+
+  reg:
+    items:
+      - description: ASC coprocessor control
+      - description: Peripheral to host mailbox
+      - description: General-purpose ASC IO registers
+      - description: Host to peripheral mailbox
+
+  reg-names:
+    items:
+      - const: coproc
+      - const: mbox
+      - const: gpio
+      - const: mbox2
+
+  iommus:
+    description: All 3 must be kept in sync
+    minItems: 3
+    maxItems: 3
+
+  interrupts:
+    maxItems: 1
+
+  power-domains:
+    minItems: 1
+    maxItems: 20
+    description: All necessary power domains. Driver will enable them in order
+
+  memory-region:
+    maxItems: 1
+
+  apple,dart-vm-size:
+    description: Supported device memory range
+    $ref: /schemas/types.yaml#/definitions/uint64
+
+  apple,platform-id:
+    description: Platform id for firmware
+    $ref: /schemas/types.yaml#/definitions/uint32
+
+  apple,temporal-filter:
+    description: Whether temporal filter should be enabled in firmware
+    $ref: /schemas/types.yaml#/definitions/uint32
+
+  sensor-presets:
+    additionalProperties: false
+
+    patternProperties:
+      '^preset[0-9]+$':
+        type: object
+
+        additionalProperties: false
+
+        properties:
+          apple,config-index:
+            description: Firmware config index
+            $ref: /schemas/types.yaml#/definitions/uint32
+
+          apple,input-size:
+            $ref: /schemas/types.yaml#/definitions/uint32-array
+            minItems: 2
+            maxItems: 2
+            description: Raw sensor size
+
+          apple,output-size:
+            $ref: /schemas/types.yaml#/definitions/uint32-array
+            minItems: 2
+            maxItems: 2
+            description: Cropped and scaled image size
+
+          apple,crop:
+            $ref: /schemas/types.yaml#/definitions/uint32-array
+            minItems: 4
+            maxItems: 4
+            description: Area to crop
+
+        required:
+          - apple,config-index
+          - apple,input-size
+          - apple,output-size
+          - apple,crop
+
+required:
+  - compatible
+  - reg
+  - iommus
+  - interrupts
+  - power-domains
+  - memory-region
+  - apple,dart-vm-size
+  - apple,platform-id
+  - apple,temporal-filter
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/apple-aic.h>
+    isp: isp@2a000000 {
+        compatible = "apple,t8103-isp", "apple,isp";
+        reg = <0x2a000000 0x2000000>,
+              <0x2c104000 0x100>,
+              <0x2c104170 0x100>,
+              <0x2c1043f0 0x100>;
+        reg-names = "coproc", "mbox", "gpio", "mbox2";
+        iommus = <&isp_dart0 0>, <&isp_dart1 0>, <&isp_dart2 0>;
+        interrupt-parent = <&aic>;
+        interrupts = <AIC_IRQ 246 IRQ_TYPE_LEVEL_HIGH>;
+        power-domains = <&ps_isp_sys>, <&ps_isp_set0>,
+                        <&ps_isp_set1>, <&ps_isp_set2>, <&ps_isp_fe>,
+                        <&ps_isp_set4>, <&ps_isp_set5>, <&ps_isp_set6>,
+                        <&ps_isp_set7>, <&ps_isp_set8>, <&ps_isp_set9>,
+                        <&ps_isp_set10>, <&ps_isp_set11>,
+                        <&ps_isp_set12>;
+        memory-region = <&isp_heap>;
+        apple,dart-vm-size = <0x0 0xa0000000>;
+        apple,platform-id = <1>;
+        apple,temporal-filter = <0>;
+
+        sensor-presets {
+            preset0 {
+                apple,config-index = <0>;
+                apple,input-size = <1296 736>;
+                apple,output-size = <1280 720>;
+                apple,crop = <8 8 1280 720>;
+            };
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index efee40ea589f70bc5e4a390072a4543234616743..dea7239ee0f5464b31efed5a2e0e5e602bcb6439 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2228,6 +2228,7 @@ F:	Documentation/devicetree/bindings/interrupt-controller/apple,*
 F:	Documentation/devicetree/bindings/iommu/apple,dart.yaml
 F:	Documentation/devicetree/bindings/iommu/apple,sart.yaml
 F:	Documentation/devicetree/bindings/mailbox/apple,mailbox.yaml
+F:	Documentation/devicetree/bindings/media/apple,isp.yaml
 F:	Documentation/devicetree/bindings/net/bluetooth/brcm,bcm4377-bluetooth.yaml
 F:	Documentation/devicetree/bindings/nvme/apple,nvme-ans.yaml
 F:	Documentation/devicetree/bindings/nvmem/apple,efuses.yaml

-- 
2.48.1

