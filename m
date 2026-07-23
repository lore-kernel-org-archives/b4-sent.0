From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Thu, 23 Jul 2026 20:23:59 +0700
Subject: [PATCH v5 1/3] dt-bindings: arm: qcom: document the Ayaneo Pocket
 DS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-pocketds-v5-1-74508388c716@gmail.com>
References: <20260723-pocketds-v5-0-74508388c716@gmail.com>
In-Reply-To: <20260723-pocketds-v5-0-74508388c716@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784813038; l=906;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=oBrsCM7jjcemh5kkcBaIFnGWn5xiruOoVHMMuBw01l8=;
 b=4pfB4cCyIBA36TYYi1iLeL51Kn2MxxgcIs9mcOrlLiIpJLSsjOx/ncv6psRSxhE8Sx5SOmOyj
 AJVpL+3LzZgDZca24kyR32bPVzZ6nZXuTY5MtTAGhjOftcifQxsgRLq
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

