From: Ishu Brar <patches@brar.si>
Date: Fri, 16 Oct 2026 15:16:40 +0530
Subject: [PATCH 1/2] dt-bindings: arm-smmu: Document SM7250 SMMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-smmu-sm7250-v1-1-e11fc0384cfa@brar.si>
References: <20261016-smmu-sm7250-v1-0-e11fc0384cfa@brar.si>
In-Reply-To: <20261016-smmu-sm7250-v1-0-e11fc0384cfa@brar.si>
To: Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>
Cc: linux-arm-kernel@lists.infradead.org, iommu@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792144002; l=1541;
 i=patches@brar.si; h=from:subject:message-id;
 bh=eoLyOF9/wNBzZ+sKEN+DTeBqDSGPwVGLE9P0wgTznzA=;
 b=hmM4xz8ovVApQf2nZtu1RSpEqyjrLarY9UHJg8Uy3+Ds9pSE1KHQib13EAkqUuR7A7SxkzO2P
 Usj4sn67yNjC+IdMqKiatwsgMjc5ujgqOtirsGrrbke3rJWm7UcRR+W
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the SMMU found on the Qualcomm SM7250 SoC: the apps SMMU, which
is an MMU-500 implementation, and the GPU SMMU, which additionally
carries qcom,adreno-smmu.

Signed-off-by: Ishu Brar <patches@brar.si>
---
 Documentation/devicetree/bindings/iommu/arm,smmu.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/iommu/arm,smmu.yaml b/Documentation/devicetree/bindings/iommu/arm,smmu.yaml
index 6748351c7..86844cefa 100644
--- a/Documentation/devicetree/bindings/iommu/arm,smmu.yaml
+++ b/Documentation/devicetree/bindings/iommu/arm,smmu.yaml
@@ -64,6 +64,7 @@ properties:
               - qcom,sm6125-smmu-500
               - qcom,sm6350-smmu-500
               - qcom,sm6375-smmu-500
+              - qcom,sm7250-smmu-500
               - qcom,sm8150-smmu-500
               - qcom,sm8250-smmu-500
               - qcom,sm8350-smmu-500
@@ -116,6 +117,7 @@ properties:
               - qcom,shikra-smmu-500
               - qcom,sm6115-smmu-500
               - qcom,sm6125-smmu-500
+              - qcom,sm7250-smmu-500
               - qcom,sm8150-smmu-500
               - qcom,sm8250-smmu-500
               - qcom,sm8350-smmu-500
@@ -641,6 +643,7 @@ allOf:
                 - qcom,shikra-smmu-500
                 - qcom,sm6115-smmu-500
                 - qcom,sm6125-smmu-500
+                - qcom,sm7250-smmu-500
                 - qcom,sm8150-smmu-500
                 - qcom,sm8250-smmu-500
                 - qcom,sm8350-smmu-500

-- 
2.56.0

