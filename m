From: David Heidelberg <david@ixit.cz>
Date: Sun, 20 Sep 2026 13:05:44 +0200
Subject: [PATCH 01/11] dt-bindings: display: panel: s6e3ha8: Adjust to
 reflect the DDIC and panel used
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-crosshatch-panel-v1-1-de6e9512da96@ixit.cz>
References: <20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz>
In-Reply-To: <20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2789; i=david@ixit.cz;
 h=from:subject:message-id; bh=SZkNpsxVS531OAFU8Nu8uN6r2eb+ReEDrV3Xfp7rlS0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqr74IyiBXpEuhuoa9zH03oeZ1IHx3kvi8Ft5Ai
 GguZmi6eTaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaq++CAAKCRBgAj/E00kg
 cuXoD/9gBfxUhLV9WfrD8Mkf0GqB2U7xAvz2TeLu0av9ICb6u95qIEMoF2FWi/NzZDViCW173EK
 3YSzqdXKrRZ+l542y1Lp0yBlgdA1W2Dz3LQBsF6Jx7Ueo8sZp/FJecT9fJ3kQ+bVUwWAanOdua4
 tBXol0mgHocFqxV8oWU32qhvg6ZGrp46NKg5XD/EK7GhQSGUICciuuycqm3E7tmDd28tDN5r77X
 vsQB4mYaYg3H/zj2a47o0BfYOgXFEJ46Hy08kdY0OQO4mXK1AQHPQsB1TeVH+BZV2/ocf+Ye66B
 n9OI5e45weJAKVeSJvYlhlnVc4HInBQIx6N6togKYtRfCozlfo5qOh/2TRSJCUSkBCLdDQBfSBO
 d78bTl2n4W2itha3Qu84OlFTEoNIdQvNm9lYJYMKOWCCuQ6xqGJ52bWgk9fibTSmikd53PFwlF6
 Jy3YF5YCisCiBkwDwL4ciGJPRGTG6n99VSIUrfc7Mr957361RmxPGMKkKXlt9/bFxD6ttsjn8Mj
 yb8MklJWgcD/2xT5rwlC5W9ojwhCjmN61+Dj/ahysS96KZlj8yLP55CiXAok9QmIi1SAy1CM2oy
 g4q4QDudEXUGgEP7sWRRw3XioIIekp7rG0bX+6EXJdKi26VtE/XFe7UZ5+6sNoPJIhELtUFsap6
 dvUe332qo+MC74A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

S6E3HA8 is the DDIC, while the panel used on the Samsung Galaxy S9 is
the Samsung AMB577PX01. Introduce a compatible reflecting that, adjust
the example, and deprecate the DDIC-only samsung,s6e3ha8 compatible.

Update the polarity to better match newly introduced compatibles with
fixed logic.

Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../bindings/display/panel/samsung,s6e3ha8.yaml         | 17 ++++++++++++-----
 1 file changed, 12 insertions(+), 5 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/panel/samsung,s6e3ha8.yaml b/Documentation/devicetree/bindings/display/panel/samsung,s6e3ha8.yaml
index 00ce5a4e1c6be..ca250b1b91712 100644
--- a/Documentation/devicetree/bindings/display/panel/samsung,s6e3ha8.yaml
+++ b/Documentation/devicetree/bindings/display/panel/samsung,s6e3ha8.yaml
@@ -1,28 +1,35 @@
 # SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
 %YAML 1.2
 ---
 $id: http://devicetree.org/schemas/display/panel/samsung,s6e3ha8.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
 title: Samsung s6e3ha8 AMOLED DSI panel
 
-description: The s6e3ha8 is a 1440x2960 DPI display panel from Samsung Mobile
-  Displays (SMD).
+description: |
+  The s6e3ha8 is a display driver IC used in 1440x2960 AMOLED panels from
+  Samsung Mobile Displays (SMD).
+
+  Known panels:
+    - AMB577PX01, 5.77", Samsung Galaxy S9 (samsung,s6e3ha8-amb577px01)
 
 maintainers:
   - Dzmitry Sankouski <dsankouski@gmail.com>
 
 allOf:
   - $ref: panel-common.yaml#
 
 properties:
   compatible:
-    const: samsung,s6e3ha8
+    oneOf:
+      - const: samsung,s6e3ha8-amb577px01
+      - const: samsung,s6e3ha8
+        deprecated: true
 
   reg:
     maxItems: 1
 
   vdd3-supply:
     description: VDD regulator
 
   vci-supply:
@@ -44,23 +51,23 @@ examples:
   - |
     #include <dt-bindings/gpio/gpio.h>
 
     dsi {
         #address-cells = <1>;
         #size-cells = <0>;
 
         panel@0 {
-            compatible = "samsung,s6e3ha8";
+            compatible = "samsung,s6e3ha8-amb577px01";
             reg = <0>;
             vci-supply = <&s2dos05_ldo4>;
             vddr-supply = <&s2dos05_buck1>;
             vdd3-supply = <&s2dos05_ldo1>;
             te-gpios = <&tlmm 10 GPIO_ACTIVE_HIGH>;
-            reset-gpios = <&tlmm 6 GPIO_ACTIVE_HIGH>;
+            reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
             pinctrl-0 = <&sde_dsi_active &sde_te_active_sleep>;
             pinctrl-1 = <&sde_dsi_suspend &sde_te_active_sleep>;
             pinctrl-names = "default", "sleep";
 
             port {
                 panel_in: endpoint {
                     remote-endpoint = <&mdss_dsi0_out>;
                 };

-- 
2.55.0

