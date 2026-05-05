From: David Wales <daviewales@disroot.org>
Date: Tue, 05 May 2026 23:51:41 +1000
Subject: [PATCH v3 1/2] dt-bindings: arm: qcom: Add Motorola Moto G2 (2014)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260505-device-motorola-titan-mainline-v3-1-8fcfa280e5d0@disroot.org>
References: <20260505-device-motorola-titan-mainline-v3-0-8fcfa280e5d0@disroot.org>
In-Reply-To: <20260505-device-motorola-titan-mainline-v3-0-8fcfa280e5d0@disroot.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Wales <daviewales@disroot.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=871; i=daviewales@disroot.org;
 h=from:subject:message-id; bh=jBv/WRLzVN0AQTAYpLJKebbhWke/WqhwJrSIev0LDSE=;
 b=owEBbQGS/pANAwAKAW1jV4FG9KFmAcsmYgBp+fYIdOiKbh3PMOHt2cCqRxlOYmuueZDP5adnV
 6q1AUPHu/CJATMEAAEKAB0WIQTXikd3yUPmOPWSLPJtY1eBRvShZgUCafn2CAAKCRBtY1eBRvSh
 Ztn+B/sGWFPHU6DrQGrMnFoOVjMtU03LoDDL2FMM4H9wKVH7pNrgJErMLRnt4e9am/k+iOAnLRw
 XjB8XXPN0S0erQaTAmEnRFGJymCM/yp1UPA5iQCQ7dT5+EoztFudzrhcxXYVoSzVk07JKwgadY3
 rCwR24wLysYHu4g+mdK4K1pGN+8keRO0xk7FemG9KYxDxnZr0UEpFKhVUGzw8gvu3UzZHes7sAJ
 kYRzYdt5elcs2HINxjn4hoc4V6YpMRXLHMR5YPa9xDnJssrLCjAv36l0H2iNo4skV79GwYqgxqM
 sg9ZppCOXQaneGimU57y1DtVaZZ6UX6de4gQZyqINSs+nFB6
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

