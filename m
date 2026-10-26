From: Ishu Brar <patches@brar.si>
Date: Mon, 26 Oct 2026 22:09:32 +0530
Subject: [PATCH v2 1/2] dt-bindings: display: panel: Add Samsung AMS644VK04
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-panel-ams644vk04-v2-1-e88cafb3e577@brar.si>
References: <20261026-panel-ams644vk04-v2-0-e88cafb3e577@brar.si>
In-Reply-To: <20261026-panel-ams644vk04-v2-0-e88cafb3e577@brar.si>
To: Ishu Brar <patches@brar.si>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793032778; l=3110;
 i=patches@brar.si; h=from:subject:message-id;
 bh=bfWhdhE0MSOyY1CD4dr6wKMiNS0UDbr+4+1vQmvpmkw=;
 b=IcYMly2iqkavOeF+yvnHNLM9kuo1bIZVyMfMCs9+EBmsOxJMS3y9nJMxOYjZJm0PJ7JbO/iKF
 2T7FKRSqD9XDUfPsbkg8jQDq9Z6G/SPN60WxgaIDdIrvSrfgQoWdZht
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Samsung AMS644VK04, a 6.44 inch 1080x2400 MIPI DSI command
mode AMOLED panel with DSC that supports 60 Hz and 90 Hz. It is used in
the OnePlus Nord (SM7250). The panel is powered by three supplies and
has a reset GPIO.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Ishu Brar <patches@brar.si>
---
 .../bindings/display/panel/samsung,ams644vk04.yaml | 76 ++++++++++++++++++++++
 MAINTAINERS                                        |  5 ++
 2 files changed, 81 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/samsung,ams644vk04.yaml b/Documentation/devicetree/bindings/display/panel/samsung,ams644vk04.yaml
new file mode 100644
index 000000000000..fcc720daff11
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/panel/samsung,ams644vk04.yaml
@@ -0,0 +1,76 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/panel/samsung,ams644vk04.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Samsung AMS644VK04 1080x2400 MIPI-DSI Panel
+
+maintainers:
+  - Ishu Brar <patches@brar.si>
+
+description:
+  The Samsung AMS644VK04 is a 6.44 inch 1080x2400 MIPI-DSI command mode AMOLED
+  panel with DSC, supporting 60 Hz and 90 Hz refresh rates. It is used in the
+  OnePlus Nord.
+
+allOf:
+  - $ref: panel-common.yaml#
+
+properties:
+  compatible:
+    const: samsung,ams644vk04
+
+  reg:
+    maxItems: 1
+
+  vddio-supply:
+    description: I/O voltage rail (1.8 V)
+
+  vdd-supply:
+    description: Panel logic voltage rail (3.0 V)
+
+  vout-supply:
+    description: Panel supply rail (1.28 V)
+
+  reset-gpios: true
+  port: true
+
+required:
+  - compatible
+  - reg
+  - vddio-supply
+  - vdd-supply
+  - vout-supply
+  - reset-gpios
+  - port
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
+            compatible = "samsung,ams644vk04";
+            reg = <0>;
+
+            reset-gpios = <&pm8150l_gpios 3 GPIO_ACTIVE_LOW>;
+
+            vdd-supply = <&vreg_l18a_3p0>;
+            vddio-supply = <&vreg_l13a_1p8>;
+            vout-supply = <&vreg_l7a_1p28>;
+
+            port {
+                endpoint {
+                    remote-endpoint = <&mdss_dsi0_out>;
+                };
+            };
+        };
+    };
+
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index a08087fb6e67..19ec9f8b522f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -8462,6 +8462,11 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/display/panel/raydium,rm69220.yaml
 F:	drivers/gpu/drm/panel/panel-raydium-rm69220.c
 
+DRM DRIVER FOR SAMSUNG AMS644VK04 PANEL
+M:	Ishu Brar <patches@brar.si>
+S:	Maintained
+F:	Documentation/devicetree/bindings/display/panel/samsung,ams644vk04.yaml
+
 DRM DRIVER FOR SAMSUNG DB7430 PANELS
 M:	Linus Walleij <linusw@kernel.org>
 S:	Maintained

-- 
2.56.0

