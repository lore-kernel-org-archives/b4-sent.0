From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Wed, 02 Jul 2025 20:59:07 +0200
Subject: [PATCH 1/3] dt-bindings: arm: qcom: Split HP Omnibook X14 AI in
 SoC variants
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250702-hp-x14-x1p-v1-1-219356e83207@oldschoolsolutions.biz>
References: <20250702-hp-x14-x1p-v1-0-219356e83207@oldschoolsolutions.biz>
In-Reply-To: <20250702-hp-x14-x1p-v1-0-219356e83207@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751482749; l=1368;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=Pol/dtLzZJ2i32WcUXC19GKh3aXInqtPj/XtwlKvYLI=;
 b=O/0tTVJf7pv48wPhAMLCcI3LiJIFevkD6HYUOF/RkA57CFax4wQYHhS7q/DMbkpz1l8ugar8p
 Hf/27Hzm0ZQAn/+XpiRbKZKa2ri90bfWqqbCEamNDNkV5mbpx3jz/Fx
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP Omnibook X14 AI PC is available in fe0 (Hamoa, x1e80100) and
fe1 (Purwa, x1p42100) SKUs. Since they are not completely dtb-compatible,
split the model strings in 2 variants:

hp,omnibook-x14-fe0 compatible to qcom, x1e80100
hp,omnibook-x14-fe1 compatible to cqom, x1p42100

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index ae43b35565808ed27cd8354b9a342545c4a98ed6..d114b7ae4fa7b162a83a152d9bf8d3fc2d74750a 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1148,7 +1148,7 @@ properties:
               - asus,zenbook-a14-ux3407ra
               - dell,xps13-9345
               - hp,elitebook-ultra-g1q
-              - hp,omnibook-x14
+              - hp,omnibook-x14-fe0
               - lenovo,yoga-slim7x
               - microsoft,romulus13
               - microsoft,romulus15
@@ -1159,6 +1159,7 @@ properties:
       - items:
           - enum:
               - asus,zenbook-a14-ux3407qa
+              - hp,omnibook-x14-fe1
               - qcom,x1p42100-crd
           - const: qcom,x1p42100
 

-- 
2.48.1

