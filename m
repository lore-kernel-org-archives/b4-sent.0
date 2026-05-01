From: David Wales <daviewales@disroot.org>
Date: Sat, 02 May 2026 08:50:17 +1000
Subject: [PATCH v2 1/2] dt-bindings: arm: qcom: Add Motorola Moto G2 (2014)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-device-motorola-titan-mainline-v2-1-c791277c740a@disroot.org>
References: <20260502-device-motorola-titan-mainline-v2-0-c791277c740a@disroot.org>
In-Reply-To: <20260502-device-motorola-titan-mainline-v2-0-c791277c740a@disroot.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Wales <daviewales@disroot.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=801; i=daviewales@disroot.org;
 h=from:subject:message-id; bh=oFKMnqsDC3T2vvql9PrtiyhX6OueJR2YWdPHmaYDyKw=;
 b=owEBbQGS/pANAwAKAW1jV4FG9KFmAcsmYgBp9S5NSQdX2Kk5lmtIlf8pG45VGmpGZBDci7EZu
 ENP7CAm1HKJATMEAAEKAB0WIQTXikd3yUPmOPWSLPJtY1eBRvShZgUCafUuTQAKCRBtY1eBRvSh
 ZmaLB/9FKybEHHrH0cg2oqJYVxh7OS3p8nDTwoU/Zy52G6pb7yymlfWBy79dTnsILOy+AcrEC4d
 PTmwC8oRs1yFqmFMgYphY0I1LwIVa1ezK0oNeH+95dKs39Ph+fzVfqjvFVSuJtk0kPnAbgoF6ej
 qqtNiAlrp2gf5kgjpDRlThYrkmG9PQkacm/c5Jgt+bL7Wu0dceNZrcpDO9CzdrOAM1xPhobKHA0
 bdvpTl0W6JwBhWxks/yTjoETJD1CMF7OJ/1IgbLJIgetWJG/JO6ULa/fG2WzwuDEk9yVN/8/4Qn
 Y4bqPyBtg9tRt9/oz6YLw2QIYf8CRWbdrPlzL8FjlYMiXTnw
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

