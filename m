From: David Heidelberg <david@ixit.cz>
Date: Tue, 15 Sep 2026 16:32:24 +0200
Subject: [PATCH v2 1/2] dt-bindings: arm: qcom: Add Xiaomi Mi 8 family
 compatibles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-dipper-v2-1-cbade54919ee@ixit.cz>
References: <20260915-dipper-v2-0-cbade54919ee@ixit.cz>
In-Reply-To: <20260915-dipper-v2-0-cbade54919ee@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1258; i=david@ixit.cz;
 h=from:subject:message-id; bh=E/ElkcIutej9yrswGTSuy+VcChc1d40Fq6rbIpw9sXE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqqVb6lhA63Dif0jFEcWy4Ko7/7FSaU6eausaci
 73W7wdSAl6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqlW+gAKCRBgAj/E00kg
 ci5/EACrLyyDxMjkJowF5ja2c+QN5lBpUZlSjXM5NWO4wwBUVH15FuecCU9CKPluHP7CYrOGpJY
 Q5InBqEhcg7Hcfzuus9ke3e8YLVk/bOyUFZq7P5Jui4hPMyJzJYk60RHIqJ7ipr0i5HXKMqIL58
 tvgj25rYMnh3846YPDjuJ5Jl1zcJph/ddcB6+UXes6KoBt6oBhDArrw4Bx4N9aOFy3in8dVafkB
 m1AQR2NZJ6q04rlUpAymHW97FArIc59hYzegnRUQA71e2wBAyDRLMDght1fJ/QG+fUYP83sM90I
 u2z5RIH8WB4Cpg5+8cMp4FIRKY8aCJrT14cIIz+A+oakt0QzvfVyMHFvwuzbqT3nBu7gK3iStJ9
 +T0qexR2Z5h0H1A3fzmrOANiLpKFlvpf8+7MpEic8H5Wrh85Hm2GrtHnedDEhCqcvx+ALnm2YKa
 XExCR+52sXiiSoxTeffMs1zktpkYxar2/eEE1GbtAAsSrbLPlyTliKa+BBCkXXzDWv+j/eVoA7D
 HWUPPMY1Mald1Yi/mQ7j/0J4J+aBFKEhHlTLKpg/YwLCpthIXa7OPm/Fim1Zntsxh2E5zHyVKMn
 iZxmQSRfAiQDx88ytkXuBSXdMx+rVlnYoGBPQHoAjT/g8UVZLG71iTNTy9AamdxjjbVuy68ZMRs
 gIxAxrHGKCXCz/A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This smartphone codenamed dipper is now supported by this series,
variants such as ursa and equuleus just documented.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index ff8a35df7862d..c3491630e56d1 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -945,16 +945,25 @@ properties:
           - const: qcom,sdm670
 
       - items:
           - enum:
               - google,bonito-tianma
           - const: google,bonito
           - const: qcom,sdm670
 
+      - description: Xiaomi Mi 8 family
+        items:
+          - enum:
+              - xiaomi,dipper
+              - xiaomi,equuleus
+              - xiaomi,ursa
+          - const: xiaomi,dipper-common
+          - const: qcom,sdm845
+
       - description: Xiaomi Poco F1
         items:
           - enum:
               - xiaomi,beryllium-ebbg
               - xiaomi,beryllium-tianma
           - const: xiaomi,beryllium
           - const: qcom,sdm845
 

-- 
2.55.0

