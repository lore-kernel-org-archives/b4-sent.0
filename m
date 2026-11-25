From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Nov 2026 19:12:45 +0100
Subject: [PATCH v4 1/9] dt-bindings: display: panel: s6e3ha8: Adjust to
 reflect the DDIC and panel used
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-crosshatch-panel-v4-1-120adc58e737@ixit.cz>
References: <20261125-crosshatch-panel-v4-0-120adc58e737@ixit.cz>
In-Reply-To: <20261125-crosshatch-panel-v4-0-120adc58e737@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3098; i=david@ixit.cz;
 h=from:subject:message-id; bh=izTTRiBpx1JipD+dbLjNqF77ZbLX4nMkT+eXkb5bPYw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrByUehr4emA3qeY3gQxZgr/wAfiHOTvNYwo+Kc
 YOA1+5sXx2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawclHgAKCRBgAj/E00kg
 cq2ZD/9ZtNuvtR/a/J56Ln883I8IIqwF8RZlVQb30sIuL9c0rKrIfCxazKZ+poIZKG+p041E1lb
 Z6LNCHtUlmYo/Y0v+L0WjDHKAIdcURh7AeP4YoBfIOssgbIu0zbSI5wsv1Hnyx023dsUpavnxYz
 vMv55atqo2FnMDQCMZkfiEV0YEzAaCLG2MDvL23KDP3G6uwp2VBuC9WJbh/AFcE3IVHel8LafRj
 9aK0MrvrD/UMSjffJKLxk/ffmT1w4gyn+43Z4NxkK8IEHaf3/NXhrNo9vvVhQWaHWiavhv1uA5j
 D2m6ivG4wU8asYllkq6NgZtoLrj3mnN7JfOoH1lqdVZBQQDy2vf8qnVc0BtlpDZz82IPz+uoN7r
 tFybrJD4AkuVoDaVg2acPCzvDu+ickmrBgLpZrR1aaSuI7kbDLfPOqsADirmKWIMhWJukIOUPA9
 TTTpaIC5R+fCj4ga+JtUEN+ERsJ7b/Hu8/p6BAwZF9Hy2Kp5UADscWB5qfUqp7y/x7Q3EknRDmk
 BFuyA3tbGSjp+TBJKD3/a4y0bc+PYp3u7aRa6K6R7yurC77bnAPC//UwM/bSt0rvLmE/wtQ0sEp
 zOL9fHs1DS7peLZBsB8vLFHZ/M73x9xIRilsGcUSPDt7EmnDYXLWQZelYLUlORfxRxAnYgwPJ8x
 60gjP/EteLBSagw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

S6E3HA8 is the DDIC, while the panel used on the Samsung Galaxy S9 is
the Samsung AMB577PX01. Introduce a compatible reflecting that using
established practice 'vendor,ddic-panel' format. Adjust the example,
and deprecate the DDIC-only samsung,s6e3ha8 compatible as
the DDIC isn't able to auto-detect the panel attached anyway.

We're going to introduce another panel with different sequence, so keep
calling original panel sequence just by the DDIC name is confusing.
While we're at it, we can cleanly fix reversed GPIO polarity.

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

