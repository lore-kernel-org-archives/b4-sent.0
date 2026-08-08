From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 08 Aug 2026 12:37:56 -0500
Subject: [PATCH 2/4] dt-bindings: arm: qcom: Add Retroid Pocket QCS8550
 Devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-rp-qcs8550-v1-2-a5a365ba3dc5@gmail.com>
References: <20260808-rp-qcs8550-v1-0-a5a365ba3dc5@gmail.com>
In-Reply-To: <20260808-rp-qcs8550-v1-0-a5a365ba3dc5@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786210675; l=835;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=R/24U57AVpzkrKRocX2qxeqPSy6EPsUVcphg05ZobrU=;
 b=AUlaNaKgI7z4KswfNYsMNIZPadpyIZBQjOKfcU/x+2uXSUBwIqIZvSsj7Nevi5hteYgkE5eI5
 +MxeOMKdj4SCUEqCr2ViralcJeTCBjMuZjWhMtd4TaWTLNwWjWAPcAt
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

    Namely:
    * Nova
    * RP6

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 954be28203017..52ef669d6fe9b 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1161,6 +1161,13 @@ properties:
           - const: qcom,qcs8550
           - const: qcom,sm8550
 
+      - items:
+          - enum:
+              - retroidpocket,nova
+              - retroidpocket,rp6
+          - const: qcom,qcs8550
+          - const: qcom,sm8550
+
       - items:
           - enum:
               - qcom,qcs8550-rb5gen2

-- 
2.54.0

