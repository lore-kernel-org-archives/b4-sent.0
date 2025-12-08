From: David Heidelberg <david@ixit.cz>
Date: Mon, 08 Dec 2025 10:41:55 +0100
Subject: [PATCH v6 2/8] dt-bindings: panel: sw43408: adjust to reflect the
 DDIC and panel used
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251208-pixel-3-v6-2-e9e559d6f412@ixit.cz>
References: <20251208-pixel-3-v6-0-e9e559d6f412@ixit.cz>
In-Reply-To: <20251208-pixel-3-v6-0-e9e559d6f412@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Dmitry Baryshkov <lumag@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Petr Hodina <phodina@protonmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, David Heidelberg <david@ixit.cz>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1948; i=david@ixit.cz;
 h=from:subject:message-id; bh=YFbMU07Wu5FnvTw9LCEYZ4TnpCBRf84TLv0leteBovM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpNp1/2va/mVnfDJFtJnUzeoVBNshAhSm3Ggl2r
 5QA/uM5P6qJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTadfwAKCRBgAj/E00kg
 chtGD/9BRz2pbgCA5jVXvzIkQFz5VPZK6MADTaowDuIVc05EFfw847eVJ5l7MmBDfALQXt3fY30
 IAHs8oeh/Q8omQjqwVB80tn631ArucHySGNes6wHnn4aky3/eJi4unvT/Hhzx6xJS4Bfd+dNdaD
 JvRBf03pfWnqLLsPFtnc7MmR4MKVizOS/+cHvsStCfd2THFCosCOVDryvzUlY4/njLkbtGfDDjT
 ozsLb5x192nR0ggJyAUaF4/qBnth52cFcCSibYWTyxVGx8iOjSl+UY+hBLlhCIfxUYyolJ4J2+u
 Vm24ODGYN9gk6blxMnjGkd9D/jTr1rNi3tMCUYInLVUAeKUHTm0K7ga01eHhluxR6T66v/SqIl3
 NNkDLeMdhkQHCW6l09HohEDXUSoDYjAWBxDkD7HeNrgOl+LxJBZWQ3c649297Gblzlm/C3pP4NS
 Wo4fwvs7P1l6bQiC1Nv+etV4MfCBOQRFVx6CkOHJrVaBTBbx5WsXKNhns756W+HdXYCqdvDRv1Y
 YUb/6LcZZjN7JuXdSpkgRoUzxf8oRMxg9xzsZNtO5Crazo4pGjNPzxPMEWNEzmSN6UX9E6iAuzb
 zj5yMgnssRXlNor1dn/IRZGPaDgrzqDBXm2ZrhSAD5QpOA3GxhHPYMbsyJKjAsie4Mu77DXgJ7p
 YWgsJB70FH5m5EA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible for used LG panel.
SW43408 is not panel, but DDIC. The panel itself is the
LG LH546WF1-ED01, so introduce combined compatible for it.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../devicetree/bindings/display/panel/lg,sw43408.yaml       | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/panel/lg,sw43408.yaml b/Documentation/devicetree/bindings/display/panel/lg,sw43408.yaml
index 2219d3d4ac43b..f641efaeb8b36 100644
--- a/Documentation/devicetree/bindings/display/panel/lg,sw43408.yaml
+++ b/Documentation/devicetree/bindings/display/panel/lg,sw43408.yaml
@@ -4,14 +4,16 @@
 $id: http://devicetree.org/schemas/display/panel/lg,sw43408.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
-title: LG SW43408 1080x2160 DSI panel
+title: LG SW43408 AMOLED DDIC
 
 maintainers:
   - Casey Connolly <casey.connolly@linaro.org>
 
 description:
-  This panel is used on the Pixel 3, it is a 60hz OLED panel which
-  required DSC (Display Stream Compression) and has rounded corners.
+  The SW43408 is display driver IC with connected panel.
+
+  LG LH546WF1-ED01 panel is used on the Pixel 3, it is a 60hz OLED panel
+  which required DSC (Display Stream Compression) and has rounded corners.
 
 allOf:
   - $ref: panel-common.yaml#
@@ -19,6 +21,9 @@ allOf:
 properties:
   compatible:
     items:
+      - enum:
+            # LG 5.46 inch, 1080x2160 pixels, 18:9 ratio
+          - lg,sw43408-lh546wf1-ed01
       - const: lg,sw43408
 
   reg:
@@ -46,7 +51,7 @@ examples:
         #size-cells = <0>;
 
         panel@0 {
-            compatible = "lg,sw43408";
+            compatible = "lg,sw43408-lh546wf1-ed01", "lg,sw43408";
             reg = <0>;
 
             vddi-supply = <&vreg_l14a_1p88>;

-- 
2.51.0

