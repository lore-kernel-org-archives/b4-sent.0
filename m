From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Fri, 22 Aug 2025 08:44:10 +0200
Subject: [PATCH v12 1/3] dt-bindings: arm: qcom: Add Lenovo TB16 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250822-tb16-dt-v12-1-bab6c2986351@oldschoolsolutions.biz>
References: <20250822-tb16-dt-v12-0-bab6c2986351@oldschoolsolutions.biz>
In-Reply-To: <20250822-tb16-dt-v12-0-bab6c2986351@oldschoolsolutions.biz>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755845055; l=952;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=thk+MxsHNEPHwSzWHQ050lhc842Rldx6y6UuBNa55OY=;
 b=w7rhyqRsRcbSqaVGGnOzu2y2mlXLISTbu8/EOwiw0799z6rSsKvwwcVwBfiKYuEUNTogh66hW
 G4359EFhf/gB5tojAUfdVbOJ+/VMK5VMqAWcdGgiIUSrcqsD6et7z+W
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
index 55e5eb75af8905c93e6604d54d516585f70a8e29..55113096dde567dddec419e67b916a0bff8c318e 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1072,6 +1072,7 @@ properties:
       - items:
           - enum:
               - asus,zenbook-a14-ux3407qa
+              - lenovo,thinkbook-16
               - qcom,x1p42100-crd
           - const: qcom,x1p42100
 

-- 
2.48.1

