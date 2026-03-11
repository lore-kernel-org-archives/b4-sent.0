From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 11 Mar 2026 12:44:37 -0500
Subject: [PATCH v2 1/5] dt-bindings: arm: qcom: Add AYN QCS8550 Devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260311-ayn-qcs8550-v2-1-e66986e0f0cb@gmail.com>
References: <20260311-ayn-qcs8550-v2-0-e66986e0f0cb@gmail.com>
In-Reply-To: <20260311-ayn-qcs8550-v2-0-e66986e0f0cb@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773251087; l=1012;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=sRHd0dN8i64gurzG1B2rArWdm5nsNAgaI9zkt3MwCSQ=;
 b=Hw+Oa8VbSZjEnnzrS+gED0THGMG06iot60u25mqyQ2bKDpAIXmu0B5VWpFvRxODXuYbxzzQHu
 Lf30noOWd+nAsv+JClq5ONuN3CpHRwdp9EWxGuaAhZ0JJkcUPTKhgB8
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
index d054a8f5632d853509b7cd37f07f02473cf6bf71..d76c0b0a082e2ee1a2adaefdb4601048cb8e8a70 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1075,6 +1075,16 @@ properties:
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

