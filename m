From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 23 Mar 2026 11:27:44 -0500
Subject: [PATCH v4 2/6] dt-bindings: arm: qcom: Add AYN QCS8550 Devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260323-ayn-qcs8550-v4-2-33a8ac3d53fa@gmail.com>
References: <20260323-ayn-qcs8550-v4-0-33a8ac3d53fa@gmail.com>
In-Reply-To: <20260323-ayn-qcs8550-v4-0-33a8ac3d53fa@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774283267; l=969;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=ucre7b8YPLKnADDPwPA5ChGeyo0QfbGTENGUYfTNUj0=;
 b=i0xAfbVQu4xwVmOpdCTbqx12YAcG4ELGwuD04I+clxksLnkIh5ISQwS1+eeAkRUPAK/mWGcn9
 4RZQanEEe2QCMk6gN5AS8OO4kjh01/FKt3ltSLsdUfQzziFILEc0twm
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
 Documentation/devicetree/bindings/arm/qcom.yaml | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index b4c79f89b285491adcbae83017e08a5cd11da77d..179b850bdcb6715c4ffcdc6f88771c520670e8b9 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1090,6 +1090,15 @@ properties:
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
               - qcom,sm8650-hdk

-- 
2.53.0

