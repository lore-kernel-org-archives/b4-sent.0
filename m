From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 11 Mar 2026 01:46:04 -0500
Subject: [PATCH 1/5] dt-bindings: arm: qcom: Add AYN QCS8550 Devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260311-ayn-qcs8550-v1-1-fe8b2faad1ea@gmail.com>
References: <20260311-ayn-qcs8550-v1-0-fe8b2faad1ea@gmail.com>
In-Reply-To: <20260311-ayn-qcs8550-v1-0-fe8b2faad1ea@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773211585; l=1012;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=+Qzgj7Je2lOZICmiCh1V93HenVV6Sr8z3B2tW7C6ewE=;
 b=f/EKG8wcXT0/9ZKHoKGbbCxs00XOhxTt8e9V0+Wzarl5eUp9YHdLWIK1WSgX9uEJZDdZGmWAH
 1nGzjc1n6PwBqK0K+hDOvoboxQOK0tx2MBZPnaCoWxe3Rg7ws5IvKVg
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Namely:
* Odin 2
* Odin 2 Mini
* Odin 2 Portal
* Thor

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index d48c625d3fc42f1a90f76a020753ae4daec8c5ea..71ae7b0795c0df42e5a5afa5d18afa73202e02bf 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1055,6 +1055,16 @@ properties:
           - const: qcom,qcs8550
           - const: qcom,sm8550
 
+      - items:
+          - enum:
+              - ayntec,odin2
+              - ayntec,odin2mini
+              - ayntec,odin2portal
+              - ayntec,qcs8550-common
+              - ayntec,thor
+          - const: qcom,qcs8550
+          - const: qcom,sm8550
+
       - items:
           - enum:
               - qcom,sm8650-hdk

-- 
2.53.0

