From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Wed, 22 Jul 2026 14:36:12 +0700
Subject: [PATCH v4 1/3] dt-bindings: arm: qcom: document the Ayaneo Pocket
 DS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-pocketds-v4-1-438704cd51f7@gmail.com>
References: <20260722-pocketds-v4-0-438704cd51f7@gmail.com>
In-Reply-To: <20260722-pocketds-v4-0-438704cd51f7@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784705771; l=906;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=oBrsCM7jjcemh5kkcBaIFnGWn5xiruOoVHMMuBw01l8=;
 b=CLaqMWFfaoDv+a2lcFiU6S6fVnvaTHWPdUWc2UzgnWq5U1vAmaVIoNJ9RUiZQA25ReinVPfbO
 wUuM+5+bCwZDHsOSt9NOMrWSrF4w0Es/LvTTeED/oTiH9YAFLfXUxgS
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Qualcomm QCS8550 based Ayaneo Pocket DS gaming console.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 2741c07e9f41..b5dad29a8606 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1107,6 +1107,12 @@ properties:
           - const: qcom,qcs8550
           - const: qcom,sm8550
 
+      - items:
+          - enum:
+              - ayaneo,pocket-ds
+          - const: qcom,qcs8550
+          - const: qcom,sm8550
+
       - items:
           - enum:
               - ayaneo,pocket-s2

-- 
2.55.0

