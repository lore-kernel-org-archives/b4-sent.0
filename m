From: David Heidelberg <david@ixit.cz>
Date: Sun, 08 Nov 2026 12:32:23 +0000
Subject: [PATCH v3 02/10] dt-bindings: display: panel: samsung,s6e3ha8: Add
 AMB630QY01 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-crosshatch-panel-v3-2-87dd4ec4f7cc@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2506; i=david@ixit.cz;
 h=from:subject:message-id; bh=pZ1ZmXYMSPnJNhdcyRsXwav3/Ps9JEOeKZPs9vUMmAY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq8GveYsFn4MOgQrLFx0dCv5N497ruFnJpbSIzr
 nMBWJw1ncqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavBr3gAKCRBgAj/E00kg
 cud3D/9NnqzWe1/59sdRxpx6q+S/WSpsUSO/543/8NwT98l019Imrlzk+fmcmGvqKBc9k9f579J
 mShb9iBeXF9QIg7oRHm+ZjEX5TRUz9CAa7HrsCcLto0a1Gy2LUJZPN54qriSbdOKah3GRU+wdLN
 vVkg/+hYMzNy/CAuOYINJeuFGElcSAmiccPkz4Q5Wr9ftACSvOq+w3nKxEmAFspBoge+AOYaIRO
 ltAEDaU9TJAlWoHvPbY/5wyN0VREzZjk7p1pQ8H7jT01UMV/VUYdIwSsc0+tucglWs95tOI/bil
 CTm0m68+O2U9cXvF4dAAxCFH4Ynst8DHxeTFe5QX6aiqdxkcp2TdBtHz/1lFlNUz9GRd11XFRYY
 axVKhBR7HD233/h17dhkYQ5zOZmFiD6eRsEUrnQiMc8PJ52ajo4o9QqdCFh2CmlOVmPRXnKJyfT
 Wubgw8YJFtwXPBdOs6tEj2kzxF8Hq8ovLdIIMLr4cStXgitL5RH9eruK5GElAxHdKMAmSNsGeQ/
 CFpTjNUwrrKvHUg1WE9TjfdM2MQSSY6dDaEhUqqWWm17unBLlmU2Zd8ZvpfabCd/CVNpVytCP3r
 ewaloyOjWglTikrYJNaEpZYis7DhZJ/WgovsDInjDQXTxKUHkcCREJrTzHq9UexsYTLV7bZOFvb
 CLw1kFNtM2Vzbbg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Google Pixel 3 XL (crosshatch) uses a Samsung AMB630QY01 6.3"
1440x2960 flexible AMOLED panel.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../bindings/display/panel/samsung,s6e3ha8.yaml    | 41 ++++++++++++++++++----
 1 file changed, 34 insertions(+), 7 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/panel/samsung,s6e3ha8.yaml b/Documentation/devicetree/bindings/display/panel/samsung,s6e3ha8.yaml
index ca250b1b91712..dcf347fe5ca83 100644
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
 
+required:
+  - compatible
+  - reset-gpios
+  - vdd3-supply
+  - vci-supply
+
 allOf:
   - $ref: panel-common.yaml#
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
 
-required:
-  - compatible
-  - reset-gpios
-  - vdd3-supply
-  - vci-supply
-  - vddr-supply
+  vddpos-supply:
+    description: positive boost supply regulator (ELVDD)
+
+  vddneg-supply:
+    description: negative boost supply regulator (ELVSS)
 
 unevaluatedProperties: false
 
 examples:
   - |
     #include <dt-bindings/gpio/gpio.h>
 
     dsi {

-- 
2.55.0

