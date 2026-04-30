From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 30 Apr 2026 13:43:37 -0500
Subject: [PATCH v7 2/6] dt-bindings: arm: qcom: Add AYN QCS8550 Devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260430-ayn-qcs8550-v7-2-591a96735fa3@gmail.com>
References: <20260430-ayn-qcs8550-v7-0-591a96735fa3@gmail.com>
In-Reply-To: <20260430-ayn-qcs8550-v7-0-591a96735fa3@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777574629; l=991;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=2rGqOlPqgBo2SVV0is/nScu9jSlRs3IsGD1uogdg7P8=;
 b=/lij3UsSBQRv/qHu/2g5276as2tHB5mceFtu5y/372FVjb6aizahdZ39zoJtWHfqMLlqGTzE1
 x7SJxOumCMOCruywycT/UKc0afTwdbKjz7fpikswos8v4p+QnbS50dC
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Namely:
* Odin 2
* Odin 2 Mini
* Odin 2 Portal
* Thor

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index b4943123d2e425..4a6733eaa8b14d 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1099,6 +1099,15 @@ properties:
           - const: qcom,qcs8550
           - const: qcom,sm8550
 
+      - items:
+          - enum:
+              - ayntec,odin2
+              - ayntec,odin2mini
+              - ayntec,odin2portal
+              - ayntec,thor
+          - const: qcom,qcs8550
+          - const: qcom,sm8550
+
       - items:
           - enum:
               - ayaneo,pocket-s2

-- 
2.53.0

