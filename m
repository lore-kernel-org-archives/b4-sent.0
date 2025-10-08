From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 08 Oct 2025 19:32:57 +0400
Subject: [PATCH v17 5/9] dt-bindings: pwm: qcom,ipq6018-pwm: Add compatible
 for ipq9574
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251008-ipq-pwm-v17-5-9bd43edfc7f7@outlook.com>
References: <20251008-ipq-pwm-v17-0-9bd43edfc7f7@outlook.com>
In-Reply-To: <20251008-ipq-pwm-v17-0-9bd43edfc7f7@outlook.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Baruch Siach <baruch@tkos.co.il>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759937623; l=1000;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=hrkECPGJIlhb4smP284sXv3tC5v7hT/ab5fvLg2W1dU=;
 b=36g7JgZ2r2cBC71ovyzzWLy1PdMUxHvB9NOgJRIBxR3UjaNYQ9HfsrwJY8Xl67WlSXM6Hdyaj
 XKuQmkVmiORAh27hDo0ap1Y92DwqWyHvgWauVndQzX69gFRSuP45uiT
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IPQ9574 SoC contains a PWM block which is exactly the same as the
one found in IPQ6018. So let's add a compatible for IPQ9574 and use
IPQ6018 as the fallback.

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml b/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml
index e00b9e01f4f89dd0d08610772c984a0e2725d154..48dd7d1b8f511b0dd2cbebc07f33cafc3655ce50 100644
--- a/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml
+++ b/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml
@@ -16,6 +16,7 @@ properties:
           - enum:
               - qcom,ipq5018-pwm
               - qcom,ipq5332-pwm
+              - qcom,ipq9574-pwm
           - const: qcom,ipq6018-pwm
       - const: qcom,ipq6018-pwm
 

-- 
2.51.0

