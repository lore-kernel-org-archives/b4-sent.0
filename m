From: Ryan Brue <ryanbrue.dev@gmail.com>
Date: Sat, 05 Sep 2026 20:34:34 -0500
Subject: [PATCH 1/2] dt-bindings: display: panel: add Novatek NT51021
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260905-rbrue-drm-panel-add-novatek-nt51021-v1-1-939f59e89fc9@gmail.com>
References: <20260905-rbrue-drm-panel-add-novatek-nt51021-v1-0-939f59e89fc9@gmail.com>
In-Reply-To: <20260905-rbrue-drm-panel-add-novatek-nt51021-v1-0-939f59e89fc9@gmail.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Ryan Brue <ryanbrue.dev@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788658475; l=3260;
 i=ryanbrue.dev@gmail.com; s=20260906; h=from:subject:message-id;
 bh=OucYPSbkdRKOXX71YqLEkAw3zmqM74CD8sy3ta2ahmU=;
 b=PO5JgYFHpu6BgI2fM/vrLk1wZB4hZ/5rErx2tt+ZqYUIvvlMj4yP4Y3HrLUwAg2A2X3qX421g
 G7XEq9T+aibC7+rL8hQK6/c9TtzLqO+v9sA48rNGBPQuNi3i5JUuimW
X-Developer-Key: i=ryanbrue.dev@gmail.com; a=ed25519;
 pk=KsUvVaP//v/2q+ZBuacc7cLbsyEYn+AD71Sn28oZWKo=
X-Endpoint-Received: by B4 Relay for ryanbrue.dev@gmail.com/20260906 with auth_id=1007
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Novatek NT51021 is a DSI panel controller driving 1200x1920 WUXGA
panels over four lanes in video mode. It is fitted in the Amazon Fire HD 10
(2017), on a module carrying BOE glass.

The controller has no readable panel identity. MediaTek's LCM framework
identifies panels through a .compare_id callback and the vendor's driver
for this one leaves it unset, and the glass part number is not recorded
anywhere in the vendor tree -- it names the module only "BOE". I had the
compatible name the module after the board it ships in, the way
xiaomi,elish-boe-nt36523 and lenovo,j606f-boe-nt36523w do for this
situation.

The vendor's bootloader and kernel both carry a second register sequence
for Innolux glass, selected from two board ID straps, so a second module
exists as far as the vendor firmware is concerned. I didn't have an
Innolux unit to test with, and I don't know its part number, so it is not
described here. Naming the glass in the compatible leaves room for it as
a second compatible should someone have the hardware and the need.

The rest is panel-common: a power supply, a reset GPIO, an optional
backlight and the DSI port.

Assisted-by: LLM
Signed-off-by: Ryan Brue <ryanbrue.dev@gmail.com>
---
 .../bindings/display/panel/novatek,nt51021.yaml    | 65 ++++++++++++++++++++++
 1 file changed, 65 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/novatek,nt51021.yaml b/Documentation/devicetree/bindings/display/panel/novatek,nt51021.yaml
new file mode 100644
index 000000000000..ee3adc88ec9b
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/panel/novatek,nt51021.yaml
@@ -0,0 +1,65 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/panel/novatek,nt51021.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Novatek NT51021 based 1200x1920 DSI display panels
+
+maintainers:
+  - Ryan Brue <ryanbrue.dev@gmail.com>
+
+description:
+  The Novatek NT51021 is a DSI panel controller driving 1200x1920 WUXGA
+  panels over four lanes in video mode. The controller carries no readable
+  panel identity, so each panel module it is fitted to needs its own
+  compatible naming the module.
+
+allOf:
+  - $ref: panel-common.yaml#
+
+properties:
+  compatible:
+    items:
+      - const: amazon,suez-boe-nt51021
+      - const: novatek,nt51021
+
+  reg:
+    maxItems: 1
+
+  power-supply: true
+  reset-gpios: true
+  backlight: true
+  port: true
+
+required:
+  - compatible
+  - reg
+  - power-supply
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
+            compatible = "amazon,suez-boe-nt51021", "novatek,nt51021";
+            reg = <0>;
+            backlight = <&backlight_lcd>;
+            power-supply = <&vgp6>;
+            reset-gpios = <&pio 105 GPIO_ACTIVE_LOW>;
+
+            port {
+                endpoint {
+                    remote-endpoint = <&dsi_out>;
+                };
+            };
+        };
+    };

-- 
2.55.0

