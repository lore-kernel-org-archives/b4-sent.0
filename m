From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 15 Sep 2026 22:20:24 +0200
Subject: [PATCH 2/3] dt-bindings: media: i2c: Add
 vision-components,mipi-module-controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-vc-mipi-ctrl-v1-2-8a42b693d889@linux.dev>
References: <20260915-vc-mipi-ctrl-v1-0-8a42b693d889@linux.dev>
In-Reply-To: <20260915-vc-mipi-ctrl-v1-0-8a42b693d889@linux.dev>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: Alexander Stein <alexander.stein@ew.tq-group.com>, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789503653; l=4015;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=F3EydiwWv2sHGxkCKOtN0Vy5CvYWXWGh2eXOMUI/is8=;
 b=/mFaaIINN95LzVmumfEzAH+IQLxjt4TZYEtUG2FD8seOaodAzFisyY7hEx7Kbsp1aiwBx+Nwf
 MQc3ieTJPcrBRLUEKd96NES3Dxsk0+GqII+NYa5AEPd3hVJxnn81Nq9
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for the Vision Components MIPI Camera Module Controller.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 .../vision-components,mipi-module-controller.yaml  | 92 ++++++++++++++++++++++
 MAINTAINERS                                        |  7 ++
 2 files changed, 99 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/vision-components,mipi-module-controller.yaml b/Documentation/devicetree/bindings/media/i2c/vision-components,mipi-module-controller.yaml
new file mode 100644
index 0000000000000..2a031aea68457
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/i2c/vision-components,mipi-module-controller.yaml
@@ -0,0 +1,92 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/i2c/vision-components,mipi-module-controller.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Vision Components MIPI Camera Module Controller
+
+maintainers:
+  - Laurent Pinchart <laurent.pinchart@ideasonboard.com>
+  - Richard Leitner <richard.leitner@linux.dev>
+
+description: |-
+  The MIPI camera module controller is an FPGA-based, I2C-accessible system
+  controller found on MIPI camera modules from Vision Components. It abstracts
+  the camera sensor behind a unified register interface, and controls and
+  sequences the on-board power supplies and clocks.
+
+  The camera sensor abstraction is optional. The controller exposes a tunneled
+  downstream I2C bus used by the attached image sensor. The controller node
+  acts as the upstream device on the host bus, while child node below the
+  controller represent the sensor device reachable through the tunnel.
+
+properties:
+  compatible:
+    const: vision-components,mipi-module-controller
+
+  reg:
+    maxItems: 1
+
+  '#clock-cells':
+    const: 0
+
+  clock-frequency:
+    description: Frequency of the sensor clock provided by the module
+
+  vcc-supply:
+    description: Power supply of the module (3.3V)
+
+  '#address-cells':
+    const: 1
+
+  '#size-cells':
+    const: 0
+
+required:
+  - compatible
+  - reg
+  - '#clock-cells'
+  - clock-frequency
+  - vcc-supply
+  - '#address-cells'
+  - '#size-cells'
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        vc_mipi_ctrl: controller@10 {
+            compatible = "vision-components,mipi-module-controller";
+            reg = <0x10>;
+            #clock-cells = <0>;
+            clock-frequency = <37125000>;
+            vcc-supply = <&cam_3v3>;
+
+            #address-cells = <1>;
+            #size-cells = <0>;
+
+            i2c@0 {
+                #address-cells = <1>;
+                #size-cells = <0>;
+
+                vc_mipi_sensor: camera@60 {
+                    compatible = "ovti,ov9281";
+                    reg = <0x60>;
+
+                    clocks = <&vc_mipi_ctrl>;
+                    clock-names = "inck";
+
+                    avdd-supply = <&vc_mipi_ctrl>;
+                    dvdd-supply = <&vc_mipi_ctrl>;
+                    dovdd-supply = <&vc_mipi_ctrl>;
+                };
+            };
+        };
+    };
+...
+
diff --git a/MAINTAINERS b/MAINTAINERS
index c2414447892c2..3ee3fec098831 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -29106,6 +29106,13 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/iio/light/vishay,veml6075.yaml
 F:	drivers/iio/light/veml6075.c
 
+VISION COMPONENTS MIPI MODULE CONTROLLER DRIVER
+M:	Laurent Pinchart <laurent.pinchart@ideasonboard.com>
+M:	Richard Leitner <richard.leitner@linux.dev>
+L:	linux-media@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/media/i2c/vision-components,mipi-module-controller.yaml
+
 VISL VIRTUAL STATELESS DECODER DRIVER
 M:	Daniel Almeida <daniel.almeida@collabora.com>
 L:	linux-media@vger.kernel.org

-- 
2.53.0

