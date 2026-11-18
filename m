From: David Heidelberg <david@ixit.cz>
Date: Wed, 18 Nov 2026 18:25:37 +0100
Subject: [PATCH v2 04/12] dt-bindings: regulator: qcom,usb-vbus-regulator:
 Add pmi8998 and pm660
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-pmi8998-vbus-v2-4-3c77a72b280a@ixit.cz>
References: <20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz>
In-Reply-To: <20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1376; i=david@ixit.cz;
 h=from:subject:message-id; bh=iOvaxT1G2XggGbeguNuBhCumUCCnVFoo/EJHZMzemjU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/d+XFuPrWspHz0miqC/yWOVsqMFXFIgZPsEzr
 ljLnGzKRAeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCav3flwAKCRBgAj/E00kg
 coz0EACAFvKPWMjZK+r8pF7ySaq6i5bl+/hHZqLw2+kVCr/AEwVpylT8fEjDTOy/OHRd4NHOUJ7
 hWaboAHTpc+okUIpvDJ78EdCXinzoasks3mKnUMicEdVjDD3JV2tmb4Wxgi7X6e+1bNONR4tkZk
 /dYUrC/1NwP2Go9bE9VeAbtuWOngNMIw+SrgJmjztAhW01saymfaWcrUjeV/C0XCeRMpGnL+S5/
 yQweeho95OuyO8isF7R13wENLfQ/79Jf45dzN/x87i7/g46DXLtUBD6EFfk4DVvdsuHlQIMD1/o
 /gqFXcD2fiZMXPReThwSQAdkP7IUwjNHu+S5tLXNn2DSqIFPpzb6K2/CiXSxF00wU7/Gg1XIL+c
 0IAv34gION47c3ka75ph+pKOnaoZPsgvZjqgB/7nTF7ATG/1ENLkPUhyzazowN3h37y+jdnpYmI
 EjDv06WI1w5Mlsg6jKZahoQN5bi9RrDgveaC1xDLJYJzsfBe1ZKDlrEBce9JSjp/foLEheniWO8
 BLh+1K8yKi9/jV9RmQiq+3a5ttHiv9pDfxCtrSSRvjenf2SX6zgK0uXx0x5nCIYf3HHPbtCRZ81
 cbMGev6iXiGRKfi1JpK5WWfjSQmhssmbjTvGnHhMJVyabbZxeHBrhJJCHezfYKWszOCndEUZ4RH
 9ABGTObMyUKmtcw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VBUS register block on the PMI8998 and PM660 PMIC shares the design.
Define corresponding compatible string, having the
qcom,pmi8998-vbus-reg as a fallback.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml       | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml b/Documentation/devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml
index 024b34d0eb1a6..96f984060ce4d 100644
--- a/Documentation/devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml
+++ b/Documentation/devicetree/bindings/regulator/qcom,usb-vbus-regulator.yaml
@@ -22,22 +22,27 @@ description: |
   and 5.0 V.
 
 properties:
   compatible:
     oneOf:
       - enum:
           - qcom,pm8150b-vbus-reg
           - qcom,pm4125-vbus-reg
+          - qcom,pmi8998-vbus-reg
       - items:
           - enum:
               - qcom,pm6150-vbus-reg
               - qcom,pm7250b-vbus-reg
               - qcom,pmi632-vbus-reg
           - const: qcom,pm8150b-vbus-reg
+      - items:
+          - enum:
+              - qcom,pm660-vbus-reg
+          - const: qcom,pm8998-vbus-reg
 
   reg:
     maxItems: 1
     description: VBUS output base address
 
 allOf:
   - $ref: regulator.yaml#
   - if:

-- 
2.55.0

