From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 16 Nov 2026 13:10:12 +0530
Subject: [PATCH v2 1/2] dt-bindings: display: panel: Add Ilitek ILI97680A
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-vantage-panel-v2-1-e2ab48645e2c@yahoo.com>
References: <20261116-vantage-panel-v2-0-e2ab48645e2c@yahoo.com>
In-Reply-To: <20261116-vantage-panel-v2-0-e2ab48645e2c@yahoo.com>
To: Venkat Yadlapati <venkat.yadlapati@yahoo.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794814811; l=3218;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=/i7bQzzWSOyoUoPNVeSXBs8XdBsv/giMTK78lHZdqTw=;
 b=YxkREBkmEyYZm6u8PpmMZDOLQ7R9WsxC1tLrmerVmm38oeacUVq0/I9pekUa+qgt6iUDeQOeT
 lfipp6EyC5dAE2kG+H3o9obOuIwGkk3nOo/lEvT14OttX0WMBs6EvkZ
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Ilitek ILI97680A based 1264x2780 AMOLED panel by BOE, a
MIPI DSI command mode panel with DSC 1.2 compression found in the
Motorola Signature.

An LLM was used to help write this commit message.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 .../bindings/display/panel/ilitek,ili97680a.yaml   | 75 ++++++++++++++++++++++
 MAINTAINERS                                        |  6 ++
 2 files changed, 81 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/ilitek,ili97680a.yaml b/Documentation/devicetree/bindings/display/panel/ilitek,ili97680a.yaml
new file mode 100644
index 000000000000..c098b44fef3f
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/panel/ilitek,ili97680a.yaml
@@ -0,0 +1,75 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/panel/ilitek,ili97680a.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Ilitek ILI97680A based AMOLED DSI command mode panel
+
+maintainers:
+  - Venkat Yadlapati <venkat.yadlapati@yahoo.com>
+
+description:
+  AMOLED panels driven by an Ilitek ILI97680A controller over MIPI DSI in
+  command mode with DSC 1.2 compression. The resolution, DSC settings and
+  initialization sequence depend on the panel, so each panel has its own
+  compatible with the controller as fallback.
+
+allOf:
+  - $ref: panel-common.yaml#
+
+properties:
+  compatible:
+    items:
+      - enum:
+          # 1264x2780 BOE panel of the Motorola Signature (vantage)
+          - motorola,vantage-boe-ili97680a
+      - const: ilitek,ili97680a
+
+  reg:
+    maxItems: 1
+    description: DSI virtual channel
+
+  vci-supply: true
+  vdd-supply: true
+  vddio-supply: true
+  port: true
+  reset-gpios: true
+
+required:
+  - compatible
+  - reg
+  - vci-supply
+  - vdd-supply
+  - vddio-supply
+  - port
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
+
+        panel@0 {
+            compatible = "motorola,vantage-boe-ili97680a", "ilitek,ili97680a";
+            reg = <0>;
+
+            vci-supply = <&vreg_l13b_3p1>;
+            vdd-supply = <&vreg_l11b_1p2>;
+            vddio-supply = <&vreg_l10b_1p8>;
+
+            reset-gpios = <&tlmm 146 GPIO_ACTIVE_LOW>;
+
+            port {
+                endpoint {
+                    remote-endpoint = <&mdss_dsi1_out>;
+                };
+            };
+        };
+    };
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index c4f4e48774d0..e2a8093c328a 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -13040,6 +13040,12 @@ M:	Stanislaw Gruszka <stf_xl@wp.pl>
 S:	Maintained
 F:	drivers/usb/atm/ueagle-atm.c
 
+ILITEK ILI97680A PANEL DRIVER
+M:	Venkat Yadlapati <venkat.yadlapati@yahoo.com>
+S:	Maintained
+F:	Documentation/devicetree/bindings/display/panel/ilitek,ili97680a.yaml
+F:	drivers/gpu/drm/panel/panel-ilitek-ili97680a.c
+
 IMAGIS TOUCHSCREEN DRIVER
 M:	Markuss Broks <markuss.broks@gmail.com>
 S:	Maintained

-- 
2.56.1

