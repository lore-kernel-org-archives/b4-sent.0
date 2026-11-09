From: Gaurav Suman <gauravsuman007@gmail.com>
Date: Mon, 09 Nov 2026 22:38:21 +0000
Subject: [PATCH 3/8] dt-bindings: media: i2c: Add Samsung S5K3M3 image
 sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-sm8150-camera-v1-3-3d2e7b407516@gmail.com>
References: <20261109-sm8150-camera-v1-0-3d2e7b407516@gmail.com>
In-Reply-To: <20261109-sm8150-camera-v1-0-3d2e7b407516@gmail.com>
To: Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Gaurav Suman <gauravsuman007@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-arm-msm@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794263921; l=3463;
 i=gauravsuman007@gmail.com; s=default; h=from:subject:message-id;
 bh=tGZ+zbw9ZERTwhJF6hVQyIufXiB8qRroYi+8OOTYnCg=;
 b=fj9HQAkNpa0WIUCDJfD+j7G+CNH3ZDiHmlxb+fjWp8VoCN8i4gpdbUXHk4ufeNfiVxOpeb60P
 yj6FZn73EiSAQ34CWqxl05T6PYTMNZfb6cb+zqMHcGx6E2QnqhJrMp4
X-Developer-Key: i=gauravsuman007@gmail.com; a=ed25519;
 pk=lnUC0mQfc0KyA0LE73pQ4+QWYVRaCD8Sd3XWxLZO+JY=
X-Endpoint-Received: by B4 Relay for gauravsuman007@gmail.com/default with auth_id=1467
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for the Samsung S5K3M3 (ISOCELL 3M3) 13MP sensor, used
as the wide camera of the LG G8x ThinQ.

This was written and tested with the help of an AI coding assistant
(Claude Opus 5.5, Anthropic); I reviewed the change and the results.

Signed-off-by: Gaurav Suman <gauravsuman007@gmail.com>
---
 .../bindings/media/i2c/samsung,s5k3m3.yaml         | 104 +++++++++++++++++++++
 1 file changed, 104 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/samsung,s5k3m3.yaml b/Documentation/devicetree/bindings/media/i2c/samsung,s5k3m3.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..434f5d4326b726d0a65288a2a91b750e38a8706e
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/i2c/samsung,s5k3m3.yaml
@@ -0,0 +1,104 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/i2c/samsung,s5k3m3.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Samsung S5K3M3 Image Sensor
+
+description:
+  Samsung S5K3M3 (ISOCELL 3M3) is a 13MP image sensor controlled over a
+  serial camera control bus. The driver supports 4160x3120 at 30 frames per
+  second, RAW10 over a 4-lane MIPI D-PHY interface.
+
+maintainers:
+  - Gaurav Suman <gauravsuman007@gmail.com>
+
+allOf:
+  - $ref: /schemas/media/video-interface-devices.yaml#
+
+properties:
+  compatible:
+    const: samsung,s5k3m3
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
+    description: Digital core voltage supply.
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
+          - data-lanes
+          - link-frequencies
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - reset-gpios
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
+              compatible = "samsung,s5k3m3";
+              reg = <0x10>;
+              clocks = <&camera_mclk 0>;
+              assigned-clocks = <&camera_mclk 0>;
+              assigned-clock-rates = <19200000>;
+              reset-gpios = <&tlmm 30 GPIO_ACTIVE_LOW>;
+              vdda-supply = <&vreg_2p8>;
+              vddd-supply = <&vreg_1p05>;
+              vddio-supply = <&vreg_1p8>;
+              orientation = <0>;
+              rotation = <90>;
+
+              port {
+                  endpoint {
+                      data-lanes = <1 2 3 4>;
+                      link-frequencies = /bits/ 64 <595200000>;
+                      remote-endpoint = <&csiphy_ep>;
+                  };
+              };
+          };
+      };
+...

-- 
2.49.1

