From: Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
Date: Fri, 29 Mar 2024 00:08:35 +0100
Subject: [PATCH 2/2] v2 arm64: dts: qcom: Add support for Samsung Galaxy Z
 Fold5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240329-v2-dts-add-support-for-samsung-galaxy-zfold5-v1-2-9a91e635cacc@yahoo.com>
References: <20240329-v2-dts-add-support-for-samsung-galaxy-zfold5-v1-0-9a91e635cacc@yahoo.com>
In-Reply-To: <20240329-v2-dts-add-support-for-samsung-galaxy-zfold5-v1-0-9a91e635cacc@yahoo.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711667317; l=791;
 i=serdeliuk@yahoo.com; s=20240326; h=from:subject:message-id;
 bh=aP9dXZCNUEWuwg/1mNlC5AwvYPo1MGxaQ74pQNFY26I=;
 b=xmnoLEDkl6vJkXWr6FR5M8j03ap1+Mo4ohgcJr/BB8+OJVHOAxTAMBX8YR/oB/VWjWuHd0WtK
 aBTJB18F0ArC59xMy8TEOo07U7jqQZWPjIkaM8XjjnZt8GKDsbXzXpr
X-Developer-Key: i=serdeliuk@yahoo.com; a=ed25519;
 pk=aWyveUE11qfDOOlRIFayXukrNn39BvZ9k9uq94dAsgY=
X-Endpoint-Received: by B4 Relay for serdeliuk@yahoo.com/20240326 with auth_id=147
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Samsung Galaxy Z Fold5 (q5q) foldable phone

Currently working features:
- Framebuffer
- UFS
- i2c
- Buttons

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

