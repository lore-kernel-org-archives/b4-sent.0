From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Date: Sun, 20 Sep 2026 16:58:24 +0200
Subject: [PATCH 1/2] dt-bindings: media: i2c: Add Samsung S5K3T2 image
 sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-upstream-s5k3t2-v1-1-d640740f4013@proton.me>
References: <20260920-upstream-s5k3t2-v1-0-d640740f4013@proton.me>
In-Reply-To: <20260920-upstream-s5k3t2-v1-0-d640740f4013@proton.me>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789916304; l=3990;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=TgTul2Laa66jNxvryXNeahFMUK33hJQG1mYYZfYNCUM=;
 b=bQgodQPp+fDoCdxZRZUpPK8WSYJJCDtOKMBe3Y9A7adf2H3LqLku/kmqW/lBp/S9sq7lQe3dL
 V+c7Y2Wj7a+DKoqjFNdQ2yicCDeJ0LHDJJ+61hGVnEP3KPODomXbYOY
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung S5K3T2 is a 20 Mpixel CMOS image sensor. It has four MIPI
D-PHY lanes and an I2C control bus.

Signed-off-by: Armandas Kvietkus <armandas.kvietkus@proton.me>
---
 .../bindings/media/i2c/samsung,s5k3t2.yaml         | 101 +++++++++++++++++++++
 MAINTAINERS                                        |   7 ++
 2 files changed, 108 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/samsung,s5k3t2.yaml b/Documentation/devicetree/bindings/media/i2c/samsung,s5k3t2.yaml
new file mode 100644
index 000000000..83b3d55a8
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/i2c/samsung,s5k3t2.yaml
@@ -0,0 +1,101 @@
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
index cc3cae2e3..1924dbd20 100644
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
2.55.0

