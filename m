From: David Wales <daviewales@disroot.org>
Date: Thu, 23 Apr 2026 23:24:50 +1000
Subject: [PATCH 1/2] dt-bindings: arm: qcom: Add Motorola Moto G2 (2014)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260423-device-motorola-titan-mainline-v1-1-e1813a028cc8@disroot.org>
References: <20260423-device-motorola-titan-mainline-v1-0-e1813a028cc8@disroot.org>
In-Reply-To: <20260423-device-motorola-titan-mainline-v1-0-e1813a028cc8@disroot.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Wales <daviewales@disroot.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=801; i=daviewales@disroot.org;
 h=from:subject:message-id; bh=oFKMnqsDC3T2vvql9PrtiyhX6OueJR2YWdPHmaYDyKw=;
 b=owEBbQGS/pANAwAKAW1jV4FG9KFmAcsmYgBp6h21+MI3k23WugEGLKIOeUacwyhuwOczLBd+k
 71Qy9HAYhGJATMEAAEKAB0WIQTXikd3yUPmOPWSLPJtY1eBRvShZgUCaeodtQAKCRBtY1eBRvSh
 Zql4B/40y3fcHWmF+Agq2WgZ/e4pDF9Yw7W4G/wM29JWSg8M+f5Xs/yq40Y9q3GJoMwZjBrBt15
 NsM0kVMz4tYoHE3FIxTg2FfShX4l9KUaRYxKRPAbSbQ7NsPKrO/eupQ41fjRrGCRWa5HzsVx+z8
 cISu/qB3fhmifzC0DKMcjHwbpEgE5yaBys4j3KCjIINeVFQVTnfK9crYBLZ4+4dWafNwtsFRN0y
 /rcWlMFa55M2UIxxGhvdhnv7965fJspIMBvSjNblei5TEpqX0Z6Rajc8t004bMjejSg+RU5Ejq5
 zc6l9NHIYmnK8PkhcX7zgwTi3pZUyJzUi0naKKgogo53h+7Q
X-Developer-Key: i=daviewales@disroot.org; a=openpgp;
 fpr=8F5BAFB15444A769DC3B61684022B817D275D037
X-Endpoint-Received: by B4 Relay for daviewales@disroot.org/default with auth_id=737
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Motorola Moto G2 (2014), which is a smartphone based on the
Qualcomm MSM8226 SoC.

Signed-off-by: David Wales <daviewales@disroot.org>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index d48c625d3fc4..3dec521bfd11 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -72,6 +72,7 @@ properties:
               - microsoft,makepeace
               - microsoft,moneypenny
               - motorola,falcon
+              - motorola,titan
               - samsung,ms013g
               - samsung,s3ve3g
           - const: qcom,msm8226

-- 
2.53.0

