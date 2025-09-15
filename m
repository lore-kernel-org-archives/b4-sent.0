From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Mon, 15 Sep 2025 09:35:04 +0200
Subject: [PATCH v9 1/3] dt-bindings: arm: qcom: Add HP Omnibook X14 AI
 X1P4200 variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250915-hp-x14-x1p-v9-1-fa457ca30ffe@oldschoolsolutions.biz>
References: <20250915-hp-x14-x1p-v9-0-fa457ca30ffe@oldschoolsolutions.biz>
In-Reply-To: <20250915-hp-x14-x1p-v9-0-fa457ca30ffe@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Stephan Gerhold <stephan.gerhold@linaro.org>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757921715; l=1044;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=84BFla7oeqqiXUYREX3Zt9zgWs4ikNp5mg7FgtIK0VY=;
 b=fpYaAqiiPecPK8xFBhtiAEIc5qFTqEHnZOSLkcBAcg2x+HEjeAj490MaFXwBIWx0GWmgqK/Tv
 GIkHO4wTLoWDUIjDJVuvKybBnUsOZujQyOsVsRKO/Ncyi2as0hhTAys
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP Omnibook X14 AI PC is available in fe0 (Hamoa, x1e80100) and
fe1 (Purwa, x1p42100) SKUs. Since they are not completely dtb-compatible,
add another variant:

hp,omnibook-x14-fe1 compatible to cqom,x1p42100

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 0a3222d6f3686f1647b9e2ea192c175b0b96d48a..d205bc901f9251fdc162d6b060b0437aef3aef7e 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1077,6 +1077,7 @@ properties:
       - items:
           - enum:
               - asus,zenbook-a14-ux3407qa
+              - hp,omnibook-x14-fe1
               - lenovo,thinkbook-16
               - qcom,x1p42100-crd
           - const: qcom,x1p42100

-- 
2.48.1

