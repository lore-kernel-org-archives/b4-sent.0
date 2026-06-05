From: David Wales <daviewales@disroot.org>
Date: Fri, 05 Jun 2026 23:19:11 +1000
Subject: [PATCH v4 1/2] dt-bindings: arm: qcom: Add Motorola Moto G2 (2014)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-device-motorola-titan-mainline-v4-1-08a7be31f05c@disroot.org>
References: <20260605-device-motorola-titan-mainline-v4-0-08a7be31f05c@disroot.org>
In-Reply-To: <20260605-device-motorola-titan-mainline-v4-0-08a7be31f05c@disroot.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 David Wales <daviewales@disroot.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=871; i=daviewales@disroot.org;
 h=from:subject:message-id; bh=jBv/WRLzVN0AQTAYpLJKebbhWke/WqhwJrSIev0LDSE=;
 b=owEBbQGS/pANAwAKAW1jV4FG9KFmAcsmYgBqIszXdatheWB4D+GMsg3dy2VNNVFI9RNKhj8vE
 aao/Uf6bvuJATMEAAEKAB0WIQTXikd3yUPmOPWSLPJtY1eBRvShZgUCaiLM1wAKCRBtY1eBRvSh
 ZurpB/9crbf6RjfUb+3kGTIEenHrWZGD5rbK3BaKczpRvVbEO23nAEzycPVUh7bBslnamz1ev5a
 mnRCBOiV058RFyUFqdeiHYCMUE/nPOlEYMjI4eBl5fli1asnq2yxjC8Q5WjCdZv8qdsI1bWJdRO
 oRZgQf5s+z242yDy5DiKrk0dAmoY4LQsNxrlRi3GTRxpxFheHFHzDtdBYT4gegZqeky2VRGCYRx
 X1Ovgl5eFNv71T+hML+vDgSVsO7pGeFGbzKsbUAFIdhPBj5uD7YedCtGArBi6Tz4jQK2fRYbypL
 f8ZF3NEuDB0qbobe5BD+TpIDkY4e7aUHDspUMWNyqhlRxuKj
X-Developer-Key: i=daviewales@disroot.org; a=openpgp;
 fpr=8F5BAFB15444A769DC3B61684022B817D275D037
X-Endpoint-Received: by B4 Relay for daviewales@disroot.org/default with auth_id=737
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Motorola Moto G2 (2014), which is a smartphone based on the
Qualcomm MSM8226 SoC.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
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
2.54.0

