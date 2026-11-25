From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Nov 2026 19:12:46 +0100
Subject: [PATCH v4 2/9] dt-bindings: display: panel: s6e3ha8: Add
 AMB630QY01 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-crosshatch-panel-v4-2-120adc58e737@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2487; i=david@ixit.cz;
 h=from:subject:message-id; bh=mC8AWb9/wpYUNjQLE+eLink1Uhfk70DQlwnA9VEtlKc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrByUejL8AtgBYzPVdIcvPj5T6tFrZfzE7x+RoM
 sRRyksk90GJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawclHgAKCRBgAj/E00kg
 ctfQD/90e/k3ENh7szg3P0M33+nPf8hHTEHVPf2DbroDtR9HdOAjEabP3MvL68Jlv7hXMRJkr9A
 NE5pizhQnTXo94A/G6jcegBVYIgsPrnnxNcNUDR7q/fdzh0qBeCMYa0lvoOJglbJIsKFXY5sBu/
 fDnD+EUAn/EXYi50bmnldcvZPGzhiByY6ck36pXfNkN4cWG0nezzDMMfLCnToaJGltQNHt53m+u
 8sRUD1W02vn+j1+j+et9QcWNcY0ixP3fpnr23RNSGH4QW7TGoMztEA3PU5IiOzJ+JsQ5CTnlcEd
 Ystd990v/3mp8wDiO6W4HnfD+Q1i9RmXe4mn0ZuuUTCzojrpjkJ6oZ3+NEuUxOUS1t4dOUoUTSU
 mWdQZpARBjK0icMvPziukP3J4Tjewu53rgT3K0KgZGD42TNppbnoqfzYNOFosVMDPrnoWxvX2Hn
 hSOtMT/T27ZHpyDGGEo6rciv5n7fiDBuqW7nHyK51ALHppKhLR44QMZLdOiUT4fePV5YSwvoFE1
 k3fU8qQNGA0DPuetbtRKE8o0PrMmr6X7Ge0rRnG7O72vb4nr93vqaRh+CFDgjWCwnWe6FX/56D4
 hNr7+8IwDFiGbK4LJO6WXHG7Mo3AlmGNx/OUsEEPZSf6pe+M7zBYU39WbvUhEfKokK2RcjTmOlB
 liVQYombNOJfVqw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Google Pixel 3 XL uses a Samsung AMB630QY01 6.3" 1440x2960 flexible
AMOLED panel with direct ELVDD/ELVSS supplies.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../bindings/display/panel/samsung,s6e3ha8.yaml    | 37 +++++++++++++++++++---
 1 file changed, 32 insertions(+), 5 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/panel/samsung,s6e3ha8.yaml b/Documentation/devicetree/bindings/display/panel/samsung,s6e3ha8.yaml
index ca250b1b91712..db7ebda59c13c 100644
--- a/Documentation/devicetree/bindings/display/panel/samsung,s6e3ha8.yaml
+++ b/Documentation/devicetree/bindings/display/panel/samsung,s6e3ha8.yaml
@@ -7,48 +7,75 @@ $schema: http://devicetree.org/meta-schemas/core.yaml#
 title: Samsung s6e3ha8 AMOLED DSI panel
 
 description: |
   The s6e3ha8 is a display driver IC used in 1440x2960 AMOLED panels from
   Samsung Mobile Displays (SMD).
 
   Known panels:
     - AMB577PX01, 5.77", Samsung Galaxy S9 (samsung,s6e3ha8-amb577px01)
+    - AMB630QY01, 6.3", Google Pixel 3 XL (samsung,s6e3ha8-amb630qy01)
 
 maintainers:
   - Dzmitry Sankouski <dsankouski@gmail.com>
 
-allOf:
-  - $ref: panel-common.yaml#
-
 properties:
   compatible:
     oneOf:
-      - const: samsung,s6e3ha8-amb577px01
+      - enum:
+          - samsung,s6e3ha8-amb577px01
+          - samsung,s6e3ha8-amb630qy01
       - const: samsung,s6e3ha8
         deprecated: true
 
   reg:
     maxItems: 1
 
   vdd3-supply:
     description: VDD regulator
 
   vci-supply:
     description: VCI regulator
 
   vddr-supply:
     description: VDDR regulator
 
+  vddpos-supply:
+    description: positive boost supply regulator (ELVDD)
+
+  vddneg-supply:
+    description: negative boost supply regulator (ELVSS)
+
 required:
   - compatible
   - reset-gpios
   - vdd3-supply
   - vci-supply
-  - vddr-supply
+
+allOf:
+  - $ref: panel-common.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - samsung,s6e3ha8
+              - samsung,s6e3ha8-amb577px01
+    then:
+      required:
+        - vddr-supply
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: samsung,s6e3ha8-amb630qy01
+    then:
+      required:
+        - vddpos-supply
+        - vddneg-supply
 
 unevaluatedProperties: false
 
 examples:
   - |
     #include <dt-bindings/gpio/gpio.h>
 
     dsi {

-- 
2.55.0

