From: Herman van Hazendonk <github.com@herrie.org>
Date: Sat, 06 Jun 2026 21:01:01 +0200
Subject: [PATCH v6 1/2] dt-bindings: media: i2c: add aptina,mt9m113
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-submit-media-mt9m113-v6-1-8f6d0f79f4d1@herrie.org>
References: <20260606-submit-media-mt9m113-v6-0-8f6d0f79f4d1@herrie.org>
In-Reply-To: <20260606-submit-media-mt9m113-v6-0-8f6d0f79f4d1@herrie.org>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Herman van Hazendonk <github.com@herrie.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780772461; l=4184;
 i=github.com@herrie.org; s=20240417; h=from:subject:message-id;
 bh=35DQlR0Pg5rIt3kaI9IOLCic3MJQYDWRefh6BtAw1CY=;
 b=fXCnuviS8g8xsGnt8z3ORj4EWanR2pA4VzipHeR8uQLa+cS7KO51tOnzjBTixRvuvsm+3g/jF
 +98Bx5Z5NDLAGRtFmnTGlepA+1K7g1/X9RW59khRQJ9pbDDnYHgjgab
X-Developer-Key: i=github.com@herrie.org; a=ed25519;
 pk=YYxdq8fb5O9vhkW3n2dCH044FPZZO5718v/du7fRhFw=
X-Endpoint-Received: by B4 Relay for github.com@herrie.org/20240417 with auth_id=809
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the binding for the Aptina (now ON Semiconductor) MT9M113 1.3
megapixel SoC image sensor with on-die ISP. The chip is used as the
front (user-facing) camera on the HP TouchPad tablet and connects
to the host SoC over MIPI CSI-2.

The binding describes the chip's i2c address, optional reset and
standby GPIOs, the per-supply regulators (VDD, VDD_IO, VDDA), the
external clock input, and the CSI-2 endpoint pads exposed via the
"port" subnode.

Assisted-by: Claude:claude-opus-4-7 Sashiko:claude-haiku-4-5 Sparse:0.6.4 Coccinelle:1.1.1
Signed-off-by: Herman van Hazendonk <github.com@herrie.org>
---
 .../bindings/media/i2c/aptina,mt9m113.yaml         | 122 +++++++++++++++++++++
 1 file changed, 122 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/aptina,mt9m113.yaml b/Documentation/devicetree/bindings/media/i2c/aptina,mt9m113.yaml
new file mode 100644
index 000000000000..72b827c47b1d
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/i2c/aptina,mt9m113.yaml
@@ -0,0 +1,122 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/i2c/aptina,mt9m113.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Aptina MT9M113 1.3 Megapixel CMOS Digital Image Sensor
+
+maintainers:
+  - Herman van Hazendonk <github.com@herrie.org>
+
+description:
+  The Aptina MT9M113 is a 1.3 Megapixel CMOS digital image sensor with
+  1280x1024 active pixels. It supports dual context operation
+  Context A (640x480 preview mode with binning) and Context B (1280x1024
+  capture mode). It is programmable through an I2C interface and outputs
+  image data over a 1-lane MIPI CSI-2 connection.
+
+properties:
+  compatible:
+    const: aptina,mt9m113
+
+  reg:
+    description: I2C device address
+    enum:
+      - 0x3c
+      - 0x48
+      - 0x5d
+
+  clocks:
+    description: EXTCLK clock signal (24 MHz typical)
+    maxItems: 1
+
+  vdd-supply:
+    description:
+      Core digital voltage supply, 1.8V
+
+  vddio-supply:
+    description:
+      I/O digital voltage supply, 1.8V or 2.8V
+
+  vaa-supply:
+    description:
+      Analog voltage supply, 2.8V
+
+  reset-gpios:
+    maxItems: 1
+    description:
+      GPIO connected to the RESET_BAR pin, if any (active low). The MT9M113
+      has a single RESET_BAR pin.
+
+  powerdown-gpios:
+    maxItems: 1
+    description:
+      GPIO connected to the STANDBY/PWDN pin, if any (active high). When
+      asserted, the sensor enters low-power standby mode. The MT9M113 has
+      a single STANDBY/PWDN pin.
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
+          bus-type:
+            const: 4
+            description: MIPI CSI-2 D-PHY
+
+        required:
+          - bus-type
+          - link-frequencies
+
+    required:
+      - endpoint
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - vdd-supply
+  - vddio-supply
+  - vaa-supply
+  - port
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+    #include <dt-bindings/media/video-interfaces.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        camera@3c {
+            compatible = "aptina,mt9m113";
+            reg = <0x3c>;
+
+            clocks = <&mmcc 48>;
+
+            reset-gpios = <&pm8058_gpio 29 GPIO_ACTIVE_LOW>;
+            powerdown-gpios = <&pm8058_gpio 30 GPIO_ACTIVE_HIGH>;
+
+            vddio-supply = <&pm8058_l15>;
+            vdd-supply = <&pm8058_l15>;
+            vaa-supply = <&pm8058_l14>;
+
+            port {
+                mt9m113_ep: endpoint {
+                    bus-type = <MEDIA_BUS_TYPE_CSI2_DPHY>;
+                    link-frequencies = /bits/ 64 <384000000>;
+                    remote-endpoint = <&csiphy1_ep>;
+                };
+            };
+        };
+    };
+...

-- 
2.43.0

