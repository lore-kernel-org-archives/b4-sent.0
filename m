From: David Heidelberg <david@ixit.cz>
Date: Thu, 23 Oct 2025 22:24:25 +0200
Subject: [PATCH v5 1/6] dt-bindings: panel: Add Samsung S6E3FC2X01 DDIC
 with panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251023-s6e3fc2x01-v5-1-8f8852e67417@ixit.cz>
References: <20251023-s6e3fc2x01-v5-0-8f8852e67417@ixit.cz>
In-Reply-To: <20251023-s6e3fc2x01-v5-0-8f8852e67417@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4403; i=david@ixit.cz;
 h=from:subject:message-id; bh=kqa+wQ3/DjHfL2kOwlvKST0xezyy2KSPY0tFwprPaRs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo+o77zml2ozlxbZtplQ7KuU1DF4M5F1lokxsh1
 WqYPxB9u5yJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPqO+wAKCRBgAj/E00kg
 ciZKD/kBB+PKuluUUI4inB3vv85zAsu095I/BCBaBm0XwIYbs1dKPdpS8zcqjvVtEJHmCV6+3kJ
 QytoGMRoQF7TQlwWe0wePZs1Y6+rgyM+tzBN+0TJHXjBS4Ycwi0oNEKehncvn5WVdq9hFbrsHdm
 xKjhPJXZZW3aRgdY+rpSxn39biDilQuxqUtYfJIkusa1qv5wPVc/VkD2qbeXK5JESKKqaK8aBvB
 mMaZfHrdf1Q9i+rILRJEpUrnu/v9JkHn2tP9AwwDkGW6UMtzFIVCDO/RpTxOvH2hoowqgjkICP5
 EX3SelH43uraZ4aKV79Sf0pFyFsJ5VzFH60PVnwsaAi0H0hbXQkN2o/5TzkZCPrBLEjz04nFxRp
 bVeyPlEN3JtPFsEwXaK2u+JtUCSLcOSWVlaRi0y2gBqAVeT27Uya25DJuWIvnYIMCAfqsyIaMw/
 Hl0Dlt5je69Pz5b4ONIahN8sjN5xUnZYxNiqt5Hx1FC+hEIDn/A240dFfo+MCDAHjCpTSWpWLKM
 4O4Ek9b5owQAFby9cK3Z2lRlobMt8lfsWiuEbMbDmgPHw6gWHG//eyRitvMMsjDsqS2LW88FXe3
 D65BuMMvNSxeZfWQqmOn/03eI5p0fc/pwEP6k9w/K9hHOslaWnN940zUtNqpAy0OwgSz0gCeBIE
 nShUbDcLUtr4wLA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Basic description for S6E3FC2X01 DDIC with attached panel AMS641RW.

Samsung AMS641RW is 6.41 inch, 1080x2340 pixels, 19.5:9 ratio panel

This panel has three supplies, while panel-simple-dsi is limited to one.
There is no user of this compatible, nor the compatible make sense.
Remove it from simple DSI panel definitions.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../bindings/display/panel/panel-simple-dsi.yaml   |  3 -
 .../bindings/display/panel/samsung,s6e3fc2x01.yaml | 81 ++++++++++++++++++++++
 MAINTAINERS                                        |  5 ++
 3 files changed, 86 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml b/Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml
index 9b92a05791ccf..ac2db8cf5eb76 100644
--- a/Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml
+++ b/Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml
@@ -56,8 +56,6 @@ properties:
       - panasonic,vvx10f034n00
         # Samsung s6e3fa7 1080x2220 based AMS559NK06 AMOLED panel
       - samsung,s6e3fa7-ams559nk06
-        # Samsung s6e3fc2x01 1080x2340 AMOLED panel
-      - samsung,s6e3fc2x01
         # Samsung sofef00 1080x2280 AMOLED panel
       - samsung,sofef00
         # Shangai Top Display Optoelectronics 7" TL070WSH30 1024x600 TFT LCD panel
@@ -80,7 +78,6 @@ allOf:
       properties:
         compatible:
           enum:
-            - samsung,s6e3fc2x01
             - samsung,sofef00
     then:
       properties:
diff --git a/Documentation/devicetree/bindings/display/panel/samsung,s6e3fc2x01.yaml b/Documentation/devicetree/bindings/display/panel/samsung,s6e3fc2x01.yaml
new file mode 100644
index 0000000000000..d48354fb52ea0
--- /dev/null
+++ b/Documentation/devicetree/bindings/display/panel/samsung,s6e3fc2x01.yaml
@@ -0,0 +1,81 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/display/panel/samsung,s6e3fc2x01.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Samsung S6E3FC2X01 AMOLED DDIC
+
+description: The S6E3FC2X01 is display driver IC with connected panel.
+
+maintainers:
+  - David Heidelberg <david@ixit.cz>
+
+allOf:
+  - $ref: panel-common.yaml#
+
+properties:
+  compatible:
+    items:
+      - enum:
+            # Samsung 6.41 inch, 1080x2340 pixels, 19.5:9 ratio
+          - samsung,s6e3fc2x01-ams641rw
+      - const: samsung,s6e3fc2x01
+
+  reg:
+    maxItems: 1
+
+  reset-gpios: true
+
+  port: true
+
+  vddio-supply:
+    description: VDD regulator
+
+  vci-supply:
+    description: VCI regulator
+
+  poc-supply:
+    description: POC regulator
+
+required:
+  - compatible
+  - reset-gpios
+  - vddio-supply
+  - vci-supply
+  - poc-supply
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
+            compatible = "samsung,s6e3fc2x01-ams641rw", "samsung,s6e3fc2x01";
+            reg = <0>;
+
+            vddio-supply = <&vreg_l14a_1p88>;
+            vci-supply = <&s2dos05_buck1>;
+            poc-supply = <&s2dos05_ldo1>;
+
+            te-gpios = <&tlmm 10 GPIO_ACTIVE_HIGH>;
+            reset-gpios = <&tlmm 6 GPIO_ACTIVE_HIGH>;
+
+            pinctrl-0 = <&sde_dsi_active &sde_te_active_sleep>;
+            pinctrl-1 = <&sde_dsi_suspend &sde_te_active_sleep>;
+            pinctrl-names = "default", "sleep";
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
index be1861bd6f4e3..42be36b42c29b 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -8061,6 +8061,11 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/display/panel/samsung,s6d7aa0.yaml
 F:	drivers/gpu/drm/panel/panel-samsung-s6d7aa0.c
 
+DRM DRIVER FOR SAMSUNG S6E3FC2X01 DDIC
+M:	David Heidelberg <david@ixit.cz>
+S:	Maintained
+F:	Documentation/devicetree/bindings/display/panel/samsung,s6e3fc2x01.yaml
+
 DRM DRIVER FOR SAMSUNG S6E3HA8 PANELS
 M:	Dzmitry Sankouski <dsankouski@gmail.com>
 S:	Maintained

-- 
2.51.0

