From: Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>
Date: Mon, 16 Dec 2024 17:55:40 -0500
Subject: [PATCH v3 1/2] dt-bindings: iio: light: Add APDS9160 binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241216-apds9160-driver-v3-1-c29f6c670bdb@dimonoff.com>
References: <20241216-apds9160-driver-v3-0-c29f6c670bdb@dimonoff.com>
In-Reply-To: <20241216-apds9160-driver-v3-0-c29f6c670bdb@dimonoff.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>
Cc: Mikael Gonella-Bolduc <m.gonella.bolduc@gmail.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, llvm@lists.linux.dev, 
 Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>, 
 Hugo Villeneuve <hvilleneuve@dimonoff.com>, 
 Matti Vaittinen <mazziesaccount@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734389751; l=1743;
 i=mgonellabolduc@dimonoff.com; s=20241119; h=from:subject:message-id;
 bh=z+T/dCJyhuoD5A4B8Hhqb+eAjQn23VEvoZX4TORdNlk=;
 b=m0D2X9j7KFF4K/Incs8HGvfLVjGhJdN/5rF5J5/j44hUQSwsQUx4EiBOYy+0Pqzs6MKb+/+rg
 xQx1ln4JmsHBVbmgqQTMJOcEhyPxXZOYQJPwrF2hIyC0CUubxyJsA3x
X-Developer-Key: i=mgonellabolduc@dimonoff.com; a=ed25519;
 pk=p4tvPfGPfXRyChsgHc6s7HwB6YBl2JqqcP3BXtoDitE=
X-Endpoint-Received: by B4 Relay for mgonellabolduc@dimonoff.com/20241119 with auth_id=279
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree bindings for APDS9160
Note: Using alternate email for maintainer

Signed-off-by: Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>
---
 .../bindings/iio/light/brcm,apds9160.yaml          | 51 ++++++++++++++++++++++
 1 file changed, 51 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/light/brcm,apds9160.yaml b/Documentation/devicetree/bindings/iio/light/brcm,apds9160.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..525fba52f156df3b78e24d7d0d445fe9d882eaa7
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/light/brcm,apds9160.yaml
@@ -0,0 +1,51 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/light/brcm,apds9160.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Broadcom Combined Proximity & Ambient light sensor
+
+maintainers:
+  - Mikael Gonella-Bolduc <m.gonella.bolduc@gmail.com>
+
+description: |
+  Datasheet: https://docs.broadcom.com/docs/APDS-9160-003-DS
+
+properties:
+  compatible:
+    enum:
+      - brcm,apds9160
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+
+  vdd-supply: true
+
+required:
+  - compatible
+  - reg
+  - vdd-supply
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        light-sensor@53 {
+            compatible = "brcm,apds9160";
+            reg = <0x53>;
+            vdd-supply = <&vdd_reg>;
+            interrupts = <29 IRQ_TYPE_EDGE_FALLING>;
+            interrupt-parent = <&pinctrl>;
+        };
+    };
+...

-- 
2.34.1

