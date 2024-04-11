From: Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
Date: Thu, 11 Apr 2024 18:51:30 +0200
Subject: [PATCH v6 1/2] dt-bindings: arm: qcom: Add Samsung Galaxy Z Fold5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240411-samsung-galaxy-zfold5-q5q-v6-1-8142297515aa@yahoo.com>
References: <20240411-samsung-galaxy-zfold5-q5q-v6-0-8142297515aa@yahoo.com>
In-Reply-To: <20240411-samsung-galaxy-zfold5-q5q-v6-0-8142297515aa@yahoo.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712854291; l=880;
 i=serdeliuk@yahoo.com; s=20240326; h=from:subject:message-id;
 bh=rbDG1dSELlka8CHOFtXAwuR4DJTaBLOcUGeig6bRpXg=;
 b=uZy1vrriVfkXbit7KGtAKdP07y4/PCTJ4Far8/gTqz02K8SZkn49X7gGbDj63CB6OG83XrmK8
 eNOU1PyY9TWCMEF1zg2KAPmNrLZkSrrLsvSQRqoWAly9nAZ+BEvNFGy
X-Developer-Key: i=serdeliuk@yahoo.com; a=ed25519;
 pk=aWyveUE11qfDOOlRIFayXukrNn39BvZ9k9uq94dAsgY=
X-Endpoint-Received: by B4 Relay for serdeliuk@yahoo.com/20240326 with auth_id=147
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This documents Samsung Galaxy Z Fold5 (samsung,q5q)
which is a foldable phone by Samsung based on the sm8550 SoC.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Acked-by: Rob Herring <robh@kernel.org>
Signed-off-by: Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 66beaac60e1d..dea2a23b8fc2 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1003,6 +1003,7 @@ properties:
               - qcom,sm8550-hdk
               - qcom,sm8550-mtp
               - qcom,sm8550-qrd
+              - samsung,q5q
           - const: qcom,sm8550
 
       - items:

-- 
2.34.1

