From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 08 Apr 2026 14:41:25 -0500
Subject: [PATCH v5 2/6] dt-bindings: arm: qcom: Add AYN QCS8550 Devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-ayn-qcs8550-v5-2-c90abeb7a152@gmail.com>
References: <20260408-ayn-qcs8550-v5-0-c90abeb7a152@gmail.com>
In-Reply-To: <20260408-ayn-qcs8550-v5-0-c90abeb7a152@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775677286; l=991;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=2rGqOlPqgBo2SVV0is/nScu9jSlRs3IsGD1uogdg7P8=;
 b=g6se97QCpIRoYUkdGjzmz1JQNjjx0AfUFPWNn8++ljYditgTD39ZVdQN+pfTEUgH9nvVuJn+o
 +BomwZLzIbnD7bC36KQg+/HRhmzik9s69Dm1M2BCXk9g10W0tQz2BbK
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

