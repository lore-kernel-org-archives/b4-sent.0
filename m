From: Ishu Brar <patches@brar.si>
Date: Fri, 23 Oct 2026 13:51:16 +0530
Subject: [PATCH 1/2] dt-bindings: display: panel: Add Samsung AMS644VK04
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-panel-ams644vk04-v1-1-56096aecd0ff@brar.si>
References: <20261023-panel-ams644vk04-v1-0-56096aecd0ff@brar.si>
In-Reply-To: <20261023-panel-ams644vk04-v1-0-56096aecd0ff@brar.si>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792743679; l=3095;
 i=patches@brar.si; h=from:subject:message-id;
 bh=Tt1XsfnXS440HSGg/wswJNMW2cDPJCmbAVKWWsAuN2g=;
 b=o0Gqznn8TvZqQCsIDRMLvYNrNIirR2xp0Z7BhozECpMPgRKrnmjJvRoqtN1rcSdC1jdxyP7SP
 qe0ujG2FtpoBZOi6xSIfYl3P68RNeLyvT9XrpDjis+we2UuJLFYn+K0
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Samsung AMS644VK04, a 6.44 inch 1080x2400 MIPI DSI command
mode AMOLED panel with DSC that supports 60 Hz and 90 Hz. It is used in
the OnePlus Nord (SM7250). The panel is powered by three supplies and
has a reset GPIO.

Signed-off-by: Ishu Brar <patches@brar.si>
---
 .../bindings/display/panel/samsung,ams644vk04.yaml | 76 ++++++++++++++++++++++
 MAINTAINERS                                        |  6 ++
 2 files changed, 82 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/samsung,ams644vk04.yaml b/Documentation/devicetree/bindings/display/panel/samsung,ams644vk04.yaml
new file mode 100644
index 000000000..50f8c516b
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
+            vddio-supply = <&vreg_l13a_1p8>;
+            vdd-supply = <&vreg_l18a_3p0>;
+            vout-supply = <&vreg_l7a_1p28>;
+
+            reset-gpios = <&pm8150l_gpios 3 GPIO_ACTIVE_LOW>;
+
+            port {
+                panel_in: endpoint {
+                    remote-endpoint = <&mdss_dsi0_out>;
+                };
+            };
+        };
+    };
+
+...
diff --git a/MAINTAINERS b/MAINTAINERS
index a08087fb6..1eec53b0e 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -8462,6 +8462,12 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/display/panel/raydium,rm69220.yaml
 F:	drivers/gpu/drm/panel/panel-raydium-rm69220.c
 
+DRM DRIVER FOR SAMSUNG AMS644VK04 PANEL
+M:	Ishu Brar <patches@brar.si>
+S:	Maintained
+T:	git https://gitlab.freedesktop.org/drm/misc/kernel.git
+F:	Documentation/devicetree/bindings/display/panel/samsung,ams644vk04.yaml
+
 DRM DRIVER FOR SAMSUNG DB7430 PANELS
 M:	Linus Walleij <linusw@kernel.org>
 S:	Maintained

-- 
2.56.0

