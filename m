From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 08 Aug 2026 14:01:14 -0500
Subject: [PATCH 1/2] dt-bindings: display: panel: add Ilitek ILI7836A OLED
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-ili7836a-v1-1-07a7becc5636@gmail.com>
References: <20260808-ili7836a-v1-0-07a7becc5636@gmail.com>
In-Reply-To: <20260808-ili7836a-v1-0-07a7becc5636@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786215681; l=1884;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=KJ4KPDrXqqClHxahfT1s53mfTzh06Z1F2OlsPAlwqI4=;
 b=uy4MioV3b9R6fNaLlDeTL/o2zz722SgCtBLMsG61+8a/d3AaL7zR5E+sVWtOi/I0sZM/L1Bn9
 AQNadw9FXqlDtAeqQ8efIVH37hgCexJESW9gHxurHfr6KPiO7wnCI5Q
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Ilitek ILI7836A OLED driver is a single chip solution for MIPI-DSI.
This is used for the Retroid Pocket Nova panel.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 .../bindings/display/panel/ilitek,ili7836a.yaml    | 58 ++++++++++++++++++++++
 1 file changed, 58 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/ilitek,ili7836a.yaml b/Documentation/devicetree/bindings/display/panel/ilitek,ili7836a.yaml
new file mode 100644
index 0000000000000..962cf257ed8d3
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/panel/ilitek,ili7836a.yaml
@@ -0,0 +1,58 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/panel/ilitek,ili7836a.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Ilitek ILI7836A-based OLED panels
+
+maintainers:
+  - Neil Armstrong <neil.armstrong@linaro.org>
+
+allOf:
+  - $ref: panel-common.yaml#
+
+properties:
+  compatible:
+    items:
+      - const: retroidpocket,nova-panel
+      - const: ilitek,ili7836a
+
+  reg:
+    maxItems: 1
+    description: DSI virtual channel
+
+  vddio-supply: true
+  avdd-supply: true
+
+  backlight: true
+  port: true
+  reset-gpios: true
+  rotation: true
+
+required:
+  - compatible
+  - reg
+  - vddio-supply
+  - avdd-supply
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
+            compatible = "retroidpocket,nova-panel", "ilitek,ili7836a";
+            reg = <0>;
+            vddio-supply = <&vdd_disp_1v8>;
+            avdd-supply = <&vdd_disp2_2v8>;
+            reset-gpios = <&tlmm 133 GPIO_ACTIVE_HIGH>;
+        };
+    };
+
+...

-- 
2.54.0

