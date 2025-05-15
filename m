From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Thu, 15 May 2025 22:38:55 +0200
Subject: [PATCH 1/4] dt-bindings: arm: qcom: Add Lenovo Thinkbook 16
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250515-tb16-dt-v1-1-dc5846a25c48@oldschoolsolutions.biz>
References: <20250515-tb16-dt-v1-0-dc5846a25c48@oldschoolsolutions.biz>
In-Reply-To: <20250515-tb16-dt-v1-0-dc5846a25c48@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Johan Hovold <johan+linaro@kernel.org>, 
 Aleksandrs Vinarskis <alex.vinarskis@gmail.com>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747341542; l=979;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=TN9BFdQQ9DpzkCDMIeEV8p5iSAM7nvgIdQ75j09Yufw=;
 b=anN28te7ONtQoPfu7in0oDLURhFKKHzwKaBq2Yqy7y0k2rJqSoepiq4q+osZPQwlzCu9z2iQJ
 NNpj4IDLdX/DaXDGBIKndArqcg4NDEwfvMFJduz4fmsuCJygNNMMIsd
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the x1p-42-100/x1-26-100 variants of the Thinkbook 16 G7 QOY.

[1]: https://psref.lenovo.com/syspool/Sys/PDF/ThinkBook/ThinkBook_16_G7_QOY/ThinkBook_16_G7_QOY_Spec.pdf

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index a61c85a47e2e759c7c86f3bd49f8597fc5054929..42d22e2fb7817810742a15226807bd6a984e6acd 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1152,8 +1152,10 @@ properties:
       - items:
           - enum:
               - asus,zenbook-a14-ux3407qa
+              - lenovo,thinkbook-16
               - qcom,x1p42100-crd
           - const: qcom,x1p42100
+          - const: qcom,x1e80100
 
   # Board compatibles go above
 

-- 
2.48.1

