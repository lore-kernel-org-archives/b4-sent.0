From: David Heidelberg <david@ixit.cz>
Date: Sun, 08 Nov 2026 12:32:22 +0000
Subject: [PATCH v3 01/10] dt-bindings: display: panel: s6e3ha8: Adjust to
 reflect the DDIC and panel used
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-crosshatch-panel-v3-1-87dd4ec4f7cc@ixit.cz>
References: <20261108-crosshatch-panel-v3-0-87dd4ec4f7cc@ixit.cz>
In-Reply-To: <20261108-crosshatch-panel-v3-0-87dd4ec4f7cc@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2975; i=david@ixit.cz;
 h=from:subject:message-id; bh=bCI70Ma/U+zJcvXa1KpwjrQ7vo8FAFDbk7uYrnm4lLI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq8GveaIquAhkhLur3qjLmroRnwzNbiX0IWIrKO
 X9wyEQbbRCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavBr3gAKCRBgAj/E00kg
 cjOfEACZu0LbqU0L/NPEBB6vyHGfjXGHAZJUr+mtaLnBVo855ftQx/u5mX6GoxNm48MYITeqhFf
 UN/CwEYcnjP428NT1KPPeaDgdJbuvGp/FEvAyW1sscC+3tiKuMM154elYaNcKRSW1YMbm58ztJq
 pZe/pNVKgTZCz0w0+UtQ1NZj+cOf92o1lANd6XinlyUEMsILRGxS40Z4xD2MuCuSbRQIult0lEV
 rgV4Nq22kXgMVbHk9uwZsKN6iXe2+fiPKjM5VQjLwk2TIvuJx97ShTTvQLAU1OBBlQ81v/jKJUO
 cCakLiNRUDlLGCiKfddNbrGkyXKweu+4Ac3SU8zu1HwAS5hj4fxvYM83iOjLWKSAIky3H79vbpd
 r5bFmxn04rmfDL3frHplZyn6aeUb+liNDUlQFu6lezNsApmMeX3sYNAjDqTBq/73ae7rLRDBsGP
 mJ3sWcb71qb6sGpvAVR5idL9xGb0mqCevTleJInpgrtVm2uTbp+2E9SxFlM44HHNquvc1uS6QQ+
 5tl+zakpziPYC6szDb3dg0hDCg41RE0BnJzqIPfdsVVxoNzPxGCe/kvFiFfpu9Hy4PurkaLRPCc
 6sQl8QC0Mm3PcBMFJdOdcqdtGcHLWOD54CbNOCvP7iGAHeTFx630UH1pz7xTNrQSEw49kKmw6kr
 Ux5vCfVG3UQVaJA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

S6E3HA8 is the DDIC, while the panel used on the Samsung Galaxy S9 is
the Samsung AMB577PX01. Introduce a compatible reflecting that, adjust
the example, and deprecate the DDIC-only samsung,s6e3ha8 compatible.

We're going to introduce another panel with different sequence, so keep
calling original panel sequence just by the DDIC name is confusing.
While we at it, we can cleanly fix reversed GPIO polarity.

Update the polarity to better match newly introduced compatibles with
fixed logic.

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

