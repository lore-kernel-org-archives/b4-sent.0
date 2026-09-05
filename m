From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 05 Sep 2026 11:28:56 +0200
Subject: [PATCH 1/7] dt-bindings: arm: qcom: Distinguish IdeaCentre Mini
 01Q8X10 SKUs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260905-x1-ideacentre-mini-prettify-v1-1-9a87882973bb@oldschoolsolutions.biz>
References: <20260905-x1-ideacentre-mini-prettify-v1-0-9a87882973bb@oldschoolsolutions.biz>
In-Reply-To: <20260905-x1-ideacentre-mini-prettify-v1-0-9a87882973bb@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788600555; l=1987;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=et/ZQ7VNffXkfxW74a3PzNDQBmP6roSPIOtf9Akxd2U=;
 b=i9RasyOfjLW5VQKkFUupfbfgBfqoDlYao0yl6JDn7ldeGqFEa4ttI1qO3wz+mnQ7s2eXejbaK
 B3yflsXLvZsDisRLDBJfF17MwSuaqGOmLD0eS+YJniM3QJfTKv7PePm
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Lenovo IdeaCentre Mini 01Q8X10 exists on both X1E80100 (Hamoa) and
X1P42100 (Purwa). A single two-entry compatible cannot tell those
device trees apart.

Move the board out of the generic X1E80100 enum and document two
three-entry lists:

  lenovo,hamoa-ideacentre-mini-01q8x10, lenovo,ideacentre-mini-01q8x10,
  qcom,x1e80100

  lenovo,purwa-ideacentre-mini-01q8x10, lenovo,ideacentre-mini-01q8x10,
  qcom,x1p42100

Assisted-by: Grok 4.5 (xAI)
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 5ccb571520d1d..4d6f561a8cac0 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1180,6 +1180,11 @@ properties:
           - const: qcom,x1e001de
           - const: qcom,x1e80100
 
+      - items:
+          - const: lenovo,hamoa-ideacentre-mini-01q8x10
+          - const: lenovo,ideacentre-mini-01q8x10
+          - const: qcom,x1e80100
+
       - items:
           - enum:
               - lenovo,thinkpad-t14s-lcd
@@ -1211,7 +1216,6 @@ properties:
               - honor,magicbook-art-14-snapdragon
               - hp,elitebook-ultra-g1q
               - hp,omnibook-x14
-              - lenovo,ideacentre-mini-01q8x10
               - lenovo,yoga-slim7x
               - microsoft,romulus13
               - microsoft,romulus15
@@ -1230,6 +1234,11 @@ properties:
           - const: microsoft,denali
           - const: qcom,x1e80100
 
+      - items:
+          - const: lenovo,purwa-ideacentre-mini-01q8x10
+          - const: lenovo,ideacentre-mini-01q8x10
+          - const: qcom,x1p42100
+
       - items:
           - const: microsoft,surface-pro-12in
           - const: qcom,x1p42100

-- 
2.53.0

