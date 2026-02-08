From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sun, 08 Feb 2026 22:25:38 +0100
Subject: [PATCH 1/4] dt-bindings: arm: qcom: Add ASUS Vivobook X1P42100
 variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260208-b4-vivobook-v1-1-3a9b5e153909@oldschoolsolutions.biz>
References: <20260208-b4-vivobook-v1-0-3a9b5e153909@oldschoolsolutions.biz>
In-Reply-To: <20260208-b4-vivobook-v1-0-3a9b5e153909@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770585945; l=1004;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=IBPKARxFia+6xnXTVvSKWy8Y0My2kh4kelOmQulvrgA=;
 b=O4QTAkI8VT1e9qSgk6yo+NuHGUmWb/iVwqJ1RTG1W4V1X3U4mHJJwFT7kvByhkCsTirTvtmeW
 hTlRAcNHkReDKl+Y/bDRSV/OA9nHXDMhbD0QhYNPT+BMnlfX2G0mw0C
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ASUS Vivobook S15 (S5507) [1] is available with Hamoa and Purwa SoC.
Add the Purwa-based variant:

asus,vivobook-s15-x1p4 compatible to Purwa SoC

[1]: https://www.asus.com/de/laptops/for-home/vivobook/asus-vivobook-s-15-s5507/techspec/

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index d48c625d3fc42f1a90f76a020753ae4daec8c5ea..5eaeda2c85bdc189d650bba82f173810854f5d1e 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1124,6 +1124,7 @@ properties:
 
       - items:
           - enum:
+              - asus,vivobook-s15-x1p4
               - asus,zenbook-a14-ux3407qa-lcd
               - asus,zenbook-a14-ux3407qa-oled
           - const: asus,zenbook-a14-ux3407qa

-- 
2.51.0

