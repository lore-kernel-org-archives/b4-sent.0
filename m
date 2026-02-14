From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 14 Feb 2026 09:32:53 +0100
Subject: [PATCH v3 1/4] dt-bindings: arm: qcom: Add ASUS Vivobook X1P42100
 variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260214-b4-vivobook-v3-1-3c88065bbf77@oldschoolsolutions.biz>
References: <20260214-b4-vivobook-v3-0-3c88065bbf77@oldschoolsolutions.biz>
In-Reply-To: <20260214-b4-vivobook-v3-0-3c88065bbf77@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>, 
 "Colin K. Williams" <colin@li-nk.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771057984; l=1042;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=Ob76MMVVgaNIRiTmQ4oMoqiJcv8/sZb/spbBVJA3R+s=;
 b=W+x2wkWBb8Z7jDGkMUd7S03dTgzDSVYeqUowV8TPF7CPaU+u3nRG1r7n0MBHrKoNUW/l5ZdfE
 D1QlkzJDNgFBD1WDRReiX9esJt2e1GNfBZMnvYK01f2akxmkcui/eth
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ASUS Vivobook S15 (S5507) [1] is available with Hamoa and Purwa SoC.
Add the Purwa-based variant:

asus,vivobook-s15-x1p4 compatible to Purwa SoC

[1]: https://www.asus.com/de/laptops/for-home/vivobook/asus-vivobook-s-15-s5507/techspec/

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index d48c625d3fc42f1a90f76a020753ae4daec8c5ea..8ca0b96c5221dff40be88b0d820671a8614da0b3 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1131,6 +1131,7 @@ properties:
 
       - items:
           - enum:
+              - asus,vivobook-s15-x1p4
               - hp,omnibook-x14-fe1
               - lenovo,thinkbook-16
               - qcom,x1p42100-crd

-- 
2.51.0

