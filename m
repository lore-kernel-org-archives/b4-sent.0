From: Asdlerto Korry <korryasdlerto@gmail.com>
Date: Wed, 04 Nov 2026 20:59:15 +0200
Subject: [PATCH 1/2] dt-bindings: arm: qcom: Add Samsung Galaxy M52 5G
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-m52xq-dts-v1-1-b198f02912ff@gmail.com>
References: <20261104-m52xq-dts-v1-0-b198f02912ff@gmail.com>
In-Reply-To: <20261104-m52xq-dts-v1-0-b198f02912ff@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Asdlerto Korry <korryasdlerto@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793818754; l=791;
 i=korryasdlerto@gmail.com; s=20261104; h=from:subject:message-id;
 bh=H56IcYVSNo0wgt3tuO8OiTWa9f7y69coL2KlUgR93oo=;
 b=7ne9EcWarSEtCO5jWlreL4Dpdj69yuj7pbG5P7iQ3DiaS27+sbIOb0sC+cEaKQd2TTJP4HMxQ
 eiLFnCUteAqDdCon8a6mtBDZQshWdqv1O0fcrCWrWBua9PYzlCISgii
X-Developer-Key: i=korryasdlerto@gmail.com; a=ed25519;
 pk=RqttIGkm2XZ8NhLQBzPgpXXawOdVa1uODGsk+sagbxs=
X-Endpoint-Received: by B4 Relay for korryasdlerto@gmail.com/20261104 with auth_id=1411
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Samsung Galaxy M52 5G (samsung,m52xq) smartphone, which is
based on the Qualcomm SM7325 SoC.

Signed-off-by: Asdlerto Korry <korryasdlerto@gmail.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 121ca557ce1e..fff2be0ecb47 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1124,6 +1124,7 @@ properties:
           - enum:
               - motorola,dubai
               - nothing,spacewar
+              - samsung,m52xq
               - xiaomi,lisa
               - xiaomi,taoyao
           - const: qcom,sm7325

-- 
2.25.1

