From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Wed, 11 Feb 2026 21:37:50 +0100
Subject: [PATCH v2 1/4] dt-bindings: arm: qcom: Add ASUS Vivobook X1P42100
 variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260211-b4-vivobook-v2-1-9f500415d2ed@oldschoolsolutions.biz>
References: <20260211-b4-vivobook-v2-0-9f500415d2ed@oldschoolsolutions.biz>
In-Reply-To: <20260211-b4-vivobook-v2-0-9f500415d2ed@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>, 
 "Colin K. Williams" <colin@li-nk.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770842282; l=1020;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=PIiPkqq6VcHG3ksDSsOKNpwFjbQlxSUzu0Mnzw3gWck=;
 b=Z8ZyLz2cUOpwlEZo6psPovsQy9dY6p1M1nRjossm85l0V3zL+L7Sd3I2u7Eu5yVip9r+yE8bh
 8h0UA9n2DFKDsC9JA9RiGsC+gA4VMIpv9LrA+bGvR6Uf3WzOHoL7eBs
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ASUS Vivobook S15 (S5507) [1] is available with Hamoa and Purwa SoC.
Add the Purwa-based variant:

asus,vivobook-s15-x1p4 compatible to Purwa SoC

[1]: https://www.asus.com/de/laptops/for-home/vivobook/asus-vivobook-s-15-s5507/techspec/

Tested-by: Colin K. Williams <colin@li-nk.org>
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

