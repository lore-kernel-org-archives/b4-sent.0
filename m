From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 08 Oct 2025 19:32:55 +0400
Subject: [PATCH v17 3/9] dt-bindings: pwm: qcom,ipq6018-pwm: Add compatible
 for ipq5018
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251008-ipq-pwm-v17-3-9bd43edfc7f7@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759937623; l=1074;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=pFg/KpdU/D7prJHeba07a6q8ARK/xYrCZn9mJ+brTMI=;
 b=B9UjCLsvwGsiCRbH1bk3dRtzIfw6NogaWyqQb6a4MQMJOvq2c+pOM9dt5lblx8UOHQ+wZ7BMg
 ERmUKqUonifDEZ+t+VnwmN/UYuFMuGDUOugxYEs1irLC09wzff/yqXO
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IPQ5018 SoC contains a PWM block which is exactly the same as the
one found in IPQ6018. So let's add a compatible for IPQ5018 and use
IPQ6018 as the fallback.

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml b/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml
index 1172f0b53fadc140482f9384a36020260df372b7..acbdd952fcca53368e3b594544df8d3dae8a06b3 100644
--- a/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml
+++ b/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml
@@ -11,7 +11,12 @@ maintainers:
 
 properties:
   compatible:
-    const: qcom,ipq6018-pwm
+    oneOf:
+      - items:
+          - enum:
+              - qcom,ipq5018-pwm
+          - const: qcom,ipq6018-pwm
+      - const: qcom,ipq6018-pwm
 
   reg:
     maxItems: 1

-- 
2.51.0

