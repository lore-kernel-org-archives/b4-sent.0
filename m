From: Shrikant Raskar <raskar.shree97@gmail.com>
Date: Thu, 01 Jan 2026 21:47:38 +0530
Subject: [PATCH v4 1/4] dt-bindings: iio: proximity: Add RF Digital
 RFD77402 ToF sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-b4-rfd77402_irq-v4-1-42cd54359e9f@gmail.com>
References: <20260101-b4-rfd77402_irq-v4-0-42cd54359e9f@gmail.com>
In-Reply-To: <20260101-b4-rfd77402_irq-v4-0-42cd54359e9f@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: raskar.shree97@gmail.com, skhan@linuxfoundation.org, 
 david.hunter.linux@gmail.com, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767284290; l=2840;
 i=raskar.shree97@gmail.com; s=20260101; h=from:subject:message-id;
 bh=OVYVzLMgPVMO/XnImN7RwZfXGcsHmKgD/1eOSTZgZaQ=;
 b=kIZPx5FzhAN7jjdlvkZ8JEn43fuXoqi+SyBOinIPl6GRMa65POu3IIEjE5Vf8vc83Lb94d7T2
 75OjkeqXlXaCpTBAzOFattW3iO+EcD7CMA03lslwPSituzH5Ch3yJmZ
X-Developer-Key: i=raskar.shree97@gmail.com; a=ed25519;
 pk=4m2wXDvY0vlXefvRRzawNcNAif88Cy4XvbLkU6iMG/Y=
X-Endpoint-Received: by B4 Relay for raskar.shree97@gmail.com/20260101 with auth_id=589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RF Digital RFD77402 is a Time-of-Flight (ToF) proximity and distance
sensor that provides absolute and highly accurate distance measurements
from 100 mm up to 2000 mm over an I2C interface. It includes an optional
interrupt pin that signals when new measurement data is ready.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Shrikant Raskar <raskar.shree97@gmail.com>
---
 .../bindings/iio/proximity/rfdigital,rfd77402.yaml | 53 ++++++++++++++++++++++
 .../devicetree/bindings/vendor-prefixes.yaml       |  2 +
 2 files changed, 55 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/proximity/rfdigital,rfd77402.yaml b/Documentation/devicetree/bindings/iio/proximity/rfdigital,rfd77402.yaml
new file mode 100644
index 000000000000..1ef6326b209e
--- /dev/null
+++ b/Documentation/devicetree/bindings/iio/proximity/rfdigital,rfd77402.yaml
@@ -0,0 +1,53 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/iio/proximity/rfdigital,rfd77402.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: RF Digital RFD77402 ToF sensor
+
+maintainers:
+  - Shrikant Raskar <raskar.shree97@gmail.com>
+
+description:
+  The RF Digital RFD77402 is a Time-of-Flight (ToF) proximity and distance
+  sensor providing up to 200 mm range measurement over an I2C interface.
+
+properties:
+  compatible:
+    const: rfdigital,rfd77402
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 1
+    description:
+      Interrupt asserted when a new distance measurement is available.
+
+  vdd-supply:
+    description: Regulator that provides power to the sensor.
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
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        proximity@4c {
+            compatible = "rfdigital,rfd77402";
+            reg = <0x4c>;
+            vdd-supply = <&vdd_3v3>;
+            interrupt-parent = <&gpio>;
+            interrupts = <4 IRQ_TYPE_EDGE_FALLING>;
+        };
+    };
+...
diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index c7591b2aec2a..59ac4f0756d9 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1361,6 +1361,8 @@ patternProperties:
     description: Revolution Robotics, Inc. (Revotics)
   "^rex,.*":
     description: iMX6 Rex Project
+  "^rfdigital,.*":
+    description: RF Digital Corporation
   "^richtek,.*":
     description: Richtek Technology Corporation
   "^ricoh,.*":

-- 
2.43.0

