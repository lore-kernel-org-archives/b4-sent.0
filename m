From: David Heidelberg <david@ixit.cz>
Date: Thu, 24 Sep 2026 16:01:30 +0200
Subject: [PATCH v2 02/11] dt-bindings: display: panel: samsung,s6e3ha8: Add
 AMB630QY01 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-crosshatch-panel-v2-2-08d5c7bf72fc@ixit.cz>
References: <20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz>
In-Reply-To: <20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz>
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2442; i=david@ixit.cz;
 h=from:subject:message-id; bh=K2rs3ud3gazsmGeLP5fMP4q2yS8qRIDd3AISDM3ybSU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtS08VkRqj0WEof9HjRjSR4hVLdlW/AsFGAVOI
 v956XP148aJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUtPAAKCRBgAj/E00kg
 cs7FEACsE94bBqkeYjQN+BTrH6kDai9p8lc8cqqrU7PHbqyH8sLrTIvvhtgGH49qKVqN2IugIMS
 G292zBUb6rYISii85x84mq742Zi8XDzVYCTzF2ohFsJK3MBloQHJTO/iSTOqlnWF2et7gd4YLd1
 4PG/1VHEy1eDkRo4UsmWwi0UbaiZ3HPzLjv6FnImaLnLefu8yDzTm1P5tQW/8fw8p8/Gc9hS35h
 09M21IGprFKpbEDZ5RtUDWIHUD8tqBgS3bXyKtVm3MF7Lh1rmnXuePierlITiwrs3mY/wYTgenu
 rPt3GLYWNHIrBcdUGbBnEms3TxdnuMVOlK2h8bcM429Tvrn4kT9vB76ZWhCYI3SijO3fxaQSfpr
 pJYBLUd8Da/lCKIBjWA/3Z/V6S5rwcKbgz8WT7BKaqoOH8FK8CRSmAHY/lLHz2YS7xWMIDQlezY
 qYrxxQouNm7luEfT8QYTJuJVGnPtdtRb6FykVEvpJXHkOB8S22QXq7ty7VGL/fdjV4StdjYos+P
 RwAjyPIVT60RO+Lg9nK1pIB1GFxX/TfvDX1dQyYescQ8WSuX3isJcLXZu+vY1rhqAXzbKBzGRK7
 X1ZWyywrWx9Hw48jHUGTuVv97Qd5r+Hgc+Q0KmaOPjpeEVAhXQQ9yYQUJQ2nggRDqFDzsbw9KfE
 bAWQMyXnTExmCKA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Google Pixel 3 XL (crosshatch) uses a Samsung AMB630QY01 6.3"
1440x2960 flexible AMOLED panel.

Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../bindings/display/panel/samsung,s6e3ha8.yaml    | 31 ++++++++++++++++++++--
 1 file changed, 29 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/panel/samsung,s6e3ha8.yaml b/Documentation/devicetree/bindings/display/panel/samsung,s6e3ha8.yaml
index ca250b1b91712..acc2ea2969298 100644
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
 
 unevaluatedProperties: false
 
 examples:
   - |
     #include <dt-bindings/gpio/gpio.h>
 
     dsi {

-- 
2.55.0

