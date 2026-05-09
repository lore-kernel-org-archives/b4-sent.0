From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 09 May 2026 15:18:57 -0500
Subject: [PATCH 1/2] dt-bindings: display: panel: Add Chipone ICNA 35xx
 OLED driver bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260509-icna35xx-v1-1-688d3d4e10f9@gmail.com>
References: <20260509-icna35xx-v1-0-688d3d4e10f9@gmail.com>
In-Reply-To: <20260509-icna35xx-v1-0-688d3d4e10f9@gmail.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778357952; l=2511;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=OoHb7X7TZvRfCQ5uqL7afSM0e2bjFFLjyQXyOiI00xA=;
 b=6uSNnSYmltzddc/2xXICoPnuSAxj8kHy+BduRcIiwJUtDRsx1fsu9VR9C40I6+EpNuFShQDrM
 waiAsJmX+gdCwfXaOi4846s8iVeqEYP5V6psVRWJrIshu46R3nRsS1i
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Chipone ICNA35xx series of DDICs are high refresh, low power
MIPI-DSI drivers for OLED panels. The icna3512 is used by the Ayn Odin 2
Portal and the icna3520 is used by the Ayn Thor top panel and the Ayn
Odin 3.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 .../bindings/display/panel/chipone,icna35xx.yaml   | 77 ++++++++++++++++++++++
 1 file changed, 77 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/chipone,icna35xx.yaml b/Documentation/devicetree/bindings/display/panel/chipone,icna35xx.yaml
new file mode 100644
index 00000000000000..3c497a40101732
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/panel/chipone,icna35xx.yaml
@@ -0,0 +1,77 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/panel/chipone,icna35xx.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Chipone ICNA35xx display drivers
+
+maintainers:
+  - Neil Armstrong <neil.armstrong@linaro.org>
+
+description:
+  The Chipone ICNA35xx are a series of DDICs connected
+  using a MIPI-DSI video interface.
+
+allOf:
+  - $ref: panel-common.yaml#
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - const: ayntec,odin2portal-panel
+          - const: chipone,icna3512
+
+      - items:
+          - enum:
+            - ayntec,odin3-panel
+            - ayntec,thor-panel-top
+          - const: chipone,icna3520
+
+  reg:
+    maxItems: 1
+    description: DSI virtual channel
+
+  vdd-supply: true
+  vddio-supply: true
+  vci-supply: true
+  disp-supply: true
+  blvdd-supply: true
+
+  port: true
+  reset-gpios: true
+  rotation: true
+
+required:
+  - compatible
+  - reg
+  - vdd-supply
+  - vddio-supply
+  - vci-supply
+  - disp-supply
+  - blvdd-supply
+  - reset-gpios
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    dsi {
+        #address-cells = <1>;
+        #size-cells = <0>;
+        panel@0 {
+            compatible = "ayntec,odin2portal-panel", "chipone,icna3512";
+            reg = <0>;
+            vdd-supply = <&vreg_l11b_1p2>;
+            vddio-supply = <&vreg_l12b_1p8>;
+            vci-supply = <&vreg_l13b_3p0>;
+            disp-supply = <&vdd_disp_2v8>;
+            blvdd-supply = <&vdd_bl_5v0>;
+            reset-gpios = <&tlmm 133 GPIO_ACTIVE_LOW>;
+        };
+    };
+
+...

-- 
2.53.0

