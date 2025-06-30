From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Mon, 30 Jun 2025 21:06:39 +0200
Subject: [PATCH v8 1/4] dt-bindings: arm: qcom: Add Lenovo TB16 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250630-tb16-dt-v8-1-cf42a396e736@oldschoolsolutions.biz>
References: <20250630-tb16-dt-v8-0-cf42a396e736@oldschoolsolutions.biz>
In-Reply-To: <20250630-tb16-dt-v8-0-cf42a396e736@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Matthias Kaehlcke <mka@chromium.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Aleksandrs Vinarskis <alex.vinarskis@gmail.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751310400; l=952;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=pTpFlr2JNOBM1+TcC8lKJt5CSizsc8tw4WUtA7IPpGs=;
 b=OUEDZiZBFZC1HZSi8siB5cra5E8pkekIVs90R/mWkQV2EzlW2nUfoU3FSw5qVLJDVN5wglBJ1
 CW0BWfu8e+nDZnA1tVewZUu12sg0YxrxRAdKBYoSykkNHj/cPwkWmjD
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the x1p-42-100/x1-26-100 variants of the Thinkbook 16 G7 QOY.

[1]: https://psref.lenovo.com/syspool/Sys/PDF/ThinkBook/ThinkBook_16_G7_QOY/ThinkBook_16_G7_QOY_Spec.pdf

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index ae43b35565808ed27cd8354b9a342545c4a98ed6..98f8ae80feccf23b79ba7e7b04d4f6a291e37a44 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1159,6 +1159,7 @@ properties:
       - items:
           - enum:
               - asus,zenbook-a14-ux3407qa
+              - lenovo,thinkbook-16
               - qcom,x1p42100-crd
           - const: qcom,x1p42100
 

-- 
2.48.1

