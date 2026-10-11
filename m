From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Date: Sun, 11 Oct 2026 11:13:27 +0200
Subject: [PATCH v4 1/2] dt-bindings: media: i2c: Add Samsung S5K3T2 image
 sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-upstream-s5k3t2-v4-1-d33b12fb3263@proton.me>
References: <20261011-upstream-s5k3t2-v4-0-d33b12fb3263@proton.me>
In-Reply-To: <20261011-upstream-s5k3t2-v4-0-d33b12fb3263@proton.me>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Elgin Perumbilly <elgin.perumbilly@siliconsignals.io>, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791710007; l=4123;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=tkShdLWwWiHuVSzgY4OOZGB7fJdUgKDkchfsedpvqsU=;
 b=qrbbDOG6udm4nN6BZ8ufOJZ2gVee0ggAPFvOpcWVk8XPKQlb4cY24z+kw1XnPUbtDDhhxxc7K
 VpenG4Fo6E1AFwWo05duA6UOqMqxMbtvZgMG4H5IZFHc09abrmztJP1
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung S5K3T2 is a 20 Mpixel CMOS image sensor. It has four MIPI
D-PHY lanes and an I2C control bus.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Armandas Kvietkus <armandas.kvietkus@proton.me>
---
 .../bindings/media/i2c/samsung,s5k3t2.yaml         | 105 +++++++++++++++++++++
 MAINTAINERS                                        |   7 ++
 2 files changed, 112 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/samsung,s5k3t2.yaml b/Documentation/devicetree/bindings/media/i2c/samsung,s5k3t2.yaml
new file mode 100644
index 000000000000..74a1aa23249f
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/i2c/samsung,s5k3t2.yaml
@@ -0,0 +1,105 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/i2c/samsung,s5k3t2.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Samsung S5K3T2 Image Sensor
+
+description:
+  Samsung S5K3T2 (ISOCELL 3T2) image sensor is a 20MP image sensor.
+  The sensor is controlled over a serial camera control bus protocol,
+  the widest supported output image frame size is 5184x3880 at 15 frames
+  per second, data output format is RAW10 transferred over 4-lane
+  MIPI D-PHY interface.
+
+maintainers:
+  - Armandas Kvietkus <armandas.kvietkus@proton.me>
+
+allOf:
+  - $ref: /schemas/media/video-interface-devices.yaml#
+
+properties:
+  compatible:
+    const: samsung,s5k3t2
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    description: MCLK supply clock.
+    maxItems: 1
+
+  reset-gpios:
+    description: Active low GPIO connected to RESET pad of the sensor.
+    maxItems: 1
+
+  vdda-supply:
+    description: Analogue voltage supply, 2.8 volts.
+
+  vddd-supply:
+    description: Digital core voltage supply, 1.05 volts.
+
+  vddio-supply:
+    description: Digital I/O voltage supply, 1.8 volts.
+
+  port:
+    $ref: /schemas/graph.yaml#/$defs/port-base
+    additionalProperties: false
+
+    properties:
+      endpoint:
+        $ref: /schemas/media/video-interfaces.yaml#
+        unevaluatedProperties: false
+
+        properties:
+          data-lanes:
+            items:
+              - const: 1
+              - const: 2
+              - const: 3
+              - const: 4
+
+        required:
+          - link-frequencies
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - vdda-supply
+  - vddd-supply
+  - vddio-supply
+  - port
+
+unevaluatedProperties: false
+
+examples:
+  - |
+      #include <dt-bindings/gpio/gpio.h>
+
+      i2c {
+          #address-cells = <1>;
+          #size-cells = <0>;
+
+          camera@10 {
+              compatible = "samsung,s5k3t2";
+              reg = <0x10>;
+              clocks = <&camera_mclk 0>;
+              assigned-clocks = <&camera_mclk 0>;
+              assigned-clock-rates = <19200000>;
+              reset-gpios = <&gpio1 10 GPIO_ACTIVE_LOW>;
+              vdda-supply = <&vreg_2p8>;
+              vddd-supply = <&vreg_1p05>;
+              vddio-supply = <&vreg_1p8>;
+
+              port {
+                  endpoint {
+                      data-lanes = <1 2 3 4>;
+                      link-frequencies = /bits/ 64 <448000000>;
+                      remote-endpoint = <&mipi_csi2_ep>;
+                  };
+              };
+          };
+      };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index cc3cae2e378b..1924dbd20b57 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -24380,6 +24380,13 @@ T:	git git://linuxtv.org/media_tree.git
 F:	Documentation/devicetree/bindings/media/i2c/samsung,s5k3m5.yaml
 F:	drivers/media/i2c/s5k3m5.c
 
+SAMSUNG S5K3T2 CAMERA DRIVER
+M:	Armandas Kvietkus <armandas.kvietkus@proton.me>
+L:	linux-media@vger.kernel.org
+S:	Maintained
+T:	git git://linuxtv.org/media_tree.git
+F:	Documentation/devicetree/bindings/media/i2c/samsung,s5k3t2.yaml
+
 SAMSUNG S5K5BAF CAMERA DRIVER
 M:	Sylwester Nawrocki <s.nawrocki@samsung.com>
 M:	Andrzej Hajda <andrzej.hajda@intel.com>

-- 
2.56.0

