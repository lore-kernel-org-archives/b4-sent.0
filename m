From: David Heidelberg <david@ixit.cz>
Date: Sun, 20 Sep 2026 13:05:45 +0200
Subject: [PATCH 02/11] dt-bindings: display: panel: samsung,s6e3ha8: Add
 AMB630QY01 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-crosshatch-panel-v1-2-de6e9512da96@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2442; i=david@ixit.cz;
 h=from:subject:message-id; bh=K2rs3ud3gazsmGeLP5fMP4q2yS8qRIDd3AISDM3ybSU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqr74I3rDmLkqGSsIZDN+9uz4f1LGgo8qyM3CXq
 6B0H9X7JeyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaq++CAAKCRBgAj/E00kg
 clSTD/9L6pf3JrF6YXl/a7X0d8gmOHJJqwinoKrwkOWltUBnw4VeXVFWZjcQzUn1B2DQPdNxpQR
 ioxQZgv0HUr5ZakzEM1S9lA/FdNe0jhbX+xl+YrCviYo24ktRsXwfmqQDHViNWwwChbgLI2n1KM
 SajESGv2o3jkrZO/LqKFwvCEdA6MNu9YETzljzqfv9szIWxSfdAK7ZPA+I9c6r8j/UwayF/1cqG
 4ddsf+6pV7dfBFH2xueh7wVGTEKzlghixT5BgqmGb20TIr4s3Fc4Sj1e+a+vxSIakc0Yw8ORL8r
 fvAlPP4lZSRRGTip/uCQgDweHM8TtuSW1gY8/X7D7dWOelvCr9Svza6SzOaoA5unTtN4kYSNZ35
 bL7jh4dnR1o5jnUrXHRSegnMZUL3hxd0SqRUWsxR7g7Tb4bnzq/Y2IGult4UafC/+LZm4BAiz12
 UnyZoGcMCJVRSTf+5T54ZD25LLzLSEmSSjHRDs9NVck3gnmXINAIh4GnFRC5M5vGI83i8qqDUqg
 RXkzeo8m9Kb3fmCymS0pTBWfGTK90VGy3r1vEGKnsuCvZg+4KxgAbB4Z0Y2wqKSyR0OxEs92gOm
 wO+B9j1+C1zsTELPlgVqAARJ/Ls3LMcFtP23GuqWmccwKPqcVRtIrYJlsLMoeD4b7m+WZ6qMsDo
 3HHk5Wg22gQUnlQ==
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

