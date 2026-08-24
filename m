From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Mon, 24 Aug 2026 22:58:19 +0700
Subject: [PATCH v6 1/4] dt-bindings: arm: qcom: document the Ayaneo Pocket
 DS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-pocketds-v6-1-370161574ca2@gmail.com>
References: <20260824-pocketds-v6-0-370161574ca2@gmail.com>
In-Reply-To: <20260824-pocketds-v6-0-370161574ca2@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787587098; l=796;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=sQUubaNrrjR4wCxF7awG+2Xgfj1glKIe7/67WDA7+JI=;
 b=0Picst7MDOKab0rmMHXNXAJqA1VtgWh3pmTJ/c7ZOU1qlJViABDhIn7qy/XT1Fl6Lrrn+4j+5
 tCToc+scO5lAxlKqGDSLb9znM2fd3t29KLY2oP48Qa3YbY5zt07h9bP
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Qualcomm QCS8550 based Ayaneo Pocket DS gaming console.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index ff8a35df7862..6ff28b86bfe6 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1154,6 +1154,7 @@ properties:
 
       - items:
           - enum:
+              - ayaneo,pocket-ds
               - qcom,qcs8550-rb5gen2
           - const: qcom,qcs8550
           - const: qcom,sm8550

-- 
2.55.0

