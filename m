From: Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>
Date: Wed, 22 Jan 2025 17:59:33 -0500
Subject: [PATCH v5 1/2] dt-bindings: iio: light: Add APDS9160 binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250122-apds9160-driver-v5-1-5393be10279a@dimonoff.com>
References: <20250122-apds9160-driver-v5-0-5393be10279a@dimonoff.com>
In-Reply-To: <20250122-apds9160-driver-v5-0-5393be10279a@dimonoff.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737586780; l=2849;
 i=mgonellabolduc@dimonoff.com; s=20241119; h=from:subject:message-id;
 bh=hKuTDSH0XmEpjVDIx28SQC5NbWNqqOrY7dOGPzuivBA=;
 b=Fq41pZdHJ4spxfLxY1i88NGOEHaoEpjQQ/622cMdXQlnIRCsHITrR7WwyfmQbtn6De/SFp7CE
 bvaottf/hJHBe2HzYngxx70A7rv1YbcjP4PO9lldmPy5p3+wK/vlCR5
X-Developer-Key: i=mgonellabolduc@dimonoff.com; a=ed25519;
 pk=p4tvPfGPfXRyChsgHc6s7HwB6YBl2JqqcP3BXtoDitE=
X-Endpoint-Received: by B4 Relay for mgonellabolduc@dimonoff.com/20241119 with auth_id=279
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree bindings for APDS9160
Note: Using alternate email for maintainer

Signed-off-by: Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>
---
 .../bindings/iio/light/brcm,apds9160.yaml          | 78 ++++++++++++++++++++++
 1 file changed, 78 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/light/brcm,apds9160.yaml b/Documentation/devicetree/bindings/iio/light/brcm,apds9160.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..bb1cc4404a55760d3f2ef3818d8f5c14782dc5b8
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/light/brcm,apds9160.yaml
@@ -0,0 +1,78 @@
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
+  ps-cancellation-duration:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description:
+      Proximity sensor cancellation pulse duration in half clock cycles.
+      This parameter determines a cancellation pulse duration.
+      The cancellation is applied in the integration phase to cancel out
+      unwanted reflected light from very near objects such as tempered glass
+      in front of the sensor.
+    default: 0
+    maximum: 63
+
+  ps-cancellation-current-picoamp:
+    description:
+      Proximity sensor crosstalk cancellation current in picoampere.
+      This parameter adjusts the current in steps of 2400 pA up to 276000 pA.
+      The provided value must be a multiple of 2400 and in one of these ranges
+      [60000 - 96000]
+      [120000 - 156000]
+      [180000 - 216000]
+      [240000 - 276000]
+      This parameter is used in conjunction with the cancellation duration.
+    minimum: 60000
+    maximum: 276000
+    multipleOf: 2400
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
+            ps-cancellation-duration = <10>;
+            ps-cancellation-current-picoamp = <62400>;
+        };
+    };
+...

-- 
2.34.1

