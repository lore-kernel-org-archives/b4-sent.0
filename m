From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 05 Jul 2025 22:31:54 +0200
Subject: [PATCH v4 1/3] dt-bindings: arm: qcom: Split HP Omnibook X14 AI in
 SoC variants
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250705-hp-x14-x1p-v4-1-1c351dbeaf18@oldschoolsolutions.biz>
References: <20250705-hp-x14-x1p-v4-0-1c351dbeaf18@oldschoolsolutions.biz>
In-Reply-To: <20250705-hp-x14-x1p-v4-0-1c351dbeaf18@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751747534; l=1005;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=pkh4LkVh9hJDmVs2/Xz1A5/7QQZjQJLMn+aQFFKE45g=;
 b=AlaeodUILYz40xmxLjDilhfgnzlLL9KRwL82Gz/GlTwqySv4HHuRU31gZn+y2EehcmI2vhRfG
 xLLDjjmZ4IqDqM25PYpltHJeKZ134TuocVvDra+Z2kF/08vRnvKqU9c
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP Omnibook X14 AI PC is available in fe0 (Hamoa, x1e80100) and
fe1 (Purwa, x1p42100) SKUs. Since they are not completely dtb-compatible,
split the model strings in 2 variants:

hp,omnibook-x14	compatible to qcom,x1e80100
hp,omnibook-x14-fe1 compatible to cqom,x1p42100

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index ae43b35565808ed27cd8354b9a342545c4a98ed6..50b7b77dfe3e66f8fd57ccd5fd7e95a7e1ac2e35 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1159,6 +1159,7 @@ properties:
       - items:
           - enum:
               - asus,zenbook-a14-ux3407qa
+              - hp,omnibook-x14-fe1
               - qcom,x1p42100-crd
           - const: qcom,x1p42100
 

-- 
2.48.1

