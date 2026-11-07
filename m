From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Sat, 07 Nov 2026 20:47:25 +0100
Subject: [PATCH 2/3] dt-bindings: display: panel: Document Anapass ANA38407
 DDIC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-b4-ana38407-v1-2-c8b33147110a@dxdmail.cc>
References: <20261107-b4-ana38407-v1-0-c8b33147110a@dxdmail.cc>
In-Reply-To: <20261107-b4-ana38407-v1-0-c8b33147110a@dxdmail.cc>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794080847; l=2697;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=IsNCu5Dme3lIS4oio6hRleTjSweAdbDj0hJ3QVorX+I=;
 b=eUCnVTxbEIZxTZK2ThW3X7Dabrxqg6d2vaBq/a1h//bK4+PJgUMZeocJwmknJIcyVwUN6CVRN
 Q2i/778WbJ+BGmKBiGA1mcNCXR7cSHYSoyV8MquG9TVNFKYLFmGqrkd
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Anapass ANA38407 DDIC and the Samsung AMSA10FA01 panel
found in the Samsung Galaxy Tab S9 Wi-Fi.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 .../bindings/display/panel/anapass,ana38407.yaml   | 69 ++++++++++++++++++++++
 MAINTAINERS                                        |  5 ++
 2 files changed, 74 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/anapass,ana38407.yaml b/Documentation/devicetree/bindings/display/panel/anapass,ana38407.yaml
new file mode 100644
index 000000000000..5dd221d0bd9f
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/panel/anapass,ana38407.yaml
@@ -0,0 +1,69 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/panel/anapass,ana38407.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Anapass ANA38407 based MIPI-DSI panels
+
+maintainers:
+  - Nizat Mikayilli <nacht@dxdmail.cc>
+
+description:
+  The Anapass ANA38407 is a DSI panel controller used to drive AMOLED
+  panels.
+
+allOf:
+  - $ref: panel-common.yaml#
+
+properties:
+  compatible:
+    items:
+      - enum:
+          - samsung,amsa10fa01
+      - const: anapass,ana38407
+
+  reg:
+    maxItems: 1
+
+  vci-supply:
+    description: Analog voltage rail
+
+  vddio-supply:
+    description: I/O voltage rail
+
+required:
+  - compatible
+  - reg
+  - vci-supply
+  - vddio-supply
+  - reset-gpios
+  - port
+
+unevaluatedProperties: false
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
+            compatible = "samsung,amsa10fa01", "anapass,ana38407";
+            reg = <0>;
+
+            reset-gpios = <&tlmm 125 GPIO_ACTIVE_LOW>;
+            vci-supply = <&panel_vci>;
+            vddio-supply = <&vreg_l12b_1p8>;
+
+            port {
+                panel_in: endpoint {
+                    remote-endpoint = <&dsi0_out>;
+                };
+            };
+        };
+    };
+
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index 93abbb315065..e282fbb04e6e 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -8228,6 +8228,11 @@ S:	Supported
 T:	git https://gitlab.freedesktop.org/drm/misc/kernel.git
 F:	drivers/gpu/drm/sun4i/sun8i*
 
+DRM DRIVER FOR ANAPASS ANA38407 PANELS
+M:	Nizat Mikayilli <nacht@dxdmail.cc>
+S:	Maintained
+F:	Documentation/devicetree/bindings/display/panel/anapass,ana38407.yaml
+
 DRM DRIVER FOR APPLE TOUCH BARS
 M:	Aun-Ali Zaidi <admin@kodeit.net>
 M:	Aditya Garg <aditya.garg@linux.dev>

-- 
2.56.0

