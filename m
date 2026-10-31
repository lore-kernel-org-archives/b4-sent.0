From: David Heidelberg <david@ixit.cz>
Date: Sat, 31 Oct 2026 16:05:00 +0100
Subject: [PATCH 03/11] dt-bindings: regulator: qcom,usb-vbus-regulator: Add
 pmi8998 and pm660
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-pmi8998-vbus-v1-3-4d805e5a0f27@ixit.cz>
References: <20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz>
In-Reply-To: <20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz>
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Robin Snyders <robin@snyders.xyz>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 linux-pm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1294; i=david@ixit.cz;
 h=from:subject:message-id; bh=8b76kVmv0SWaU2OFA005s+KLQA5vUoRMBd25Pd9muoU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq5gOvbY+oPG3hlXZA9XqKAk3Vrm8L+RMaCUlD3
 mLWP36ir4eJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCauYDrwAKCRBgAj/E00kg
 cq9cD/49B8I13OS7eo7LRQmzgDIyJRzRCkX+iJZxX+yUi87mXltY84FGkEMBuSSy7LOEhOezFhb
 MXLl8g4tUGflPLcBWoV2IdaVxV/ieR6x2kh1PYDrSoNqN28Q3qQRagDJx6Gt0ijfgBaEcAU0OmS
 EfAA6FU73aIassgW7RVWsjpWdNWcH7zkmIrpPCSWc+r8rSYzXxAo6Gtse1yPK+CWQTT/cQmDpHi
 V7I8X2EtDWoyOhbtRun8S8b7HlJcdi5sYBd7x2mXDoAIPekI0X1iCIloXk1AUqdd4j87O7nuLVX
 ewFcyKJkzz4dkc9ehH0HcicJh+JDICKR7/dyF66inlJUSrGMXKVYRrBFuVc7uDpRoB+0ec688a1
 6BQ782d6oS3611pQTC8bSC0WBot34NnaHW4u6H6nLDnbH2mEFYMa2PjjjzaLIlPFzwMIXhumAKG
 dmdX0+eGXHEseXY2CTABkYOK6t9fwOvF4R9ewLlSeTlsv9sZN9Rgj60BHrI2TYwgUApSYJC6uVI
 sAIRJgMH0Z5WF96R8MAIbfPxP2xrpZjegfJxEJT3c2DzHW1ZDjdQNCIx4g4Ncz345+38VaeddwK
 pNyqz+isUt5wvmaXZTOTyVYROs5tSyNbEZJqv06Z+2jwRTCA1eEj9gao5c9anvpSfPdShtXZW8e
 LWGJmBuf2z3yv0g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VBUS register block on the PMI8998 and PM660 PMIC shares the design
with the PM8150B one. Define corresponding compatible string, having the
qcom,pm8150b-vbus-reg as a fallback.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml          | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml b/Documentation/devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml
index 024b34d0eb1a6..3cdfb556662cb 100644
--- a/Documentation/devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml
+++ b/Documentation/devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml
@@ -24,19 +24,21 @@ description: |
 properties:
   compatible:
     oneOf:
       - enum:
           - qcom,pm8150b-vbus-reg
           - qcom,pm4125-vbus-reg
       - items:
           - enum:
+              - qcom,pm660-vbus-reg
               - qcom,pm6150-vbus-reg
               - qcom,pm7250b-vbus-reg
               - qcom,pmi632-vbus-reg
+              - qcom,pmi8998-vbus-reg
           - const: qcom,pm8150b-vbus-reg
 
   reg:
     maxItems: 1
     description: VBUS output base address
 
 allOf:
   - $ref: regulator.yaml#

-- 
2.55.0

