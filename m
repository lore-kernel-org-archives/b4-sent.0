From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 01 Oct 2025 18:04:20 +0400
Subject: [PATCH v16 4/9] dt-bindings: pwm: qcom,ipq6018-pwm: Add compatible
 for ipq5332
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251001-ipq-pwm-v16-4-300f237e0e68@outlook.com>
References: <20251001-ipq-pwm-v16-0-300f237e0e68@outlook.com>
In-Reply-To: <20251001-ipq-pwm-v16-0-300f237e0e68@outlook.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Baruch Siach <baruch@tkos.co.il>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759327459; l=935;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=y8giwJKpFzWeiaRvUor0Eljp/p0jcgEG1QTHLcQUb/c=;
 b=cbOuQtetQFcdRwCz4KSHRK5SusXPEgOjS3eOsqWGIPHrIZhGq3M+OYdYqr+WgdT6Bipe37jmd
 OZ/TQIRAkdaBT0x38hr3KQK1P01kvvaWsVvuGEs3AGM4Z7O64QMTsjn
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IPQ5332 SoC contains a PWM block which is exactly the same as the
one found in IPQ6018. So let's add a compatible for IPQ5332 and use
IPQ6018 as the fallback.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml b/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml
index acbdd952fcca53368e3b594544df8d3dae8a06b3..e00b9e01f4f89dd0d08610772c984a0e2725d154 100644
--- a/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml
+++ b/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml
@@ -15,6 +15,7 @@ properties:
       - items:
           - enum:
               - qcom,ipq5018-pwm
+              - qcom,ipq5332-pwm
           - const: qcom,ipq6018-pwm
       - const: qcom,ipq6018-pwm
 

-- 
2.51.0

