From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sun, 13 Oct 2024 13:54:03 +0200
Subject: [PATCH v3 1/3] dt-bindings: arm: qcom: Add Microsoft Windows Dev
 Kit 2023
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241013-jg-blackrock-for-upstream-v3-1-839d3483a8e7@oldschoolsolutions.biz>
References: <20241013-jg-blackrock-for-upstream-v3-0-839d3483a8e7@oldschoolsolutions.biz>
In-Reply-To: <20241013-jg-blackrock-for-upstream-v3-0-839d3483a8e7@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>, 
 Merck Hung <merckhung@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728820456; l=1029;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=IplL0shONZvDiTTnGoLL+Sj1NmoGENvTEN3itFDkMrA=;
 b=8fl/UPEy/W4r7SATjMMCoo/7ABk0fBShrNE0dZzD0e+zYzNztcO7Av+g/nd2GauFuhxvG8jGh
 v/XU062wlR/AQ2CXjNxhfyBwTopcKq30LzqrvCT0rJJx3dROaskJr+W
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible values for the Microsoft Windows Dev Kit (WDK2023)
with its codename "blackrock". The Dev kit is a small desktop box
based on the mainboard of the Surface pro 9 5G, intended for
developers to test/build arm64-based Windows software.
Link: https://learn.microsoft.com/en-us/windows/arm/dev-kit/

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 5de6290cd063a..8790c6ef768c7 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -822,6 +822,7 @@ properties:
           - enum:
               - lenovo,thinkpad-x13s
               - microsoft,arcata
+              - microsoft,blackrock
               - qcom,sc8280xp-crd
               - qcom,sc8280xp-qrd
           - const: qcom,sc8280xp

-- 
2.43.0

