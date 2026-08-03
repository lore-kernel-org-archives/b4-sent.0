From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:09 +0200
Subject: [PATCH 11/28] arm64: dts: qcom: qcs8550-aim300: Fix swapped USB
 QMP PHY vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-11-5880630cde3e@oss.qualcomm.com>
References: <20260803-phy-supply-fix-v1-0-5880630cde3e@oss.qualcomm.com>
In-Reply-To: <20260803-phy-supply-fix-v1-0-5880630cde3e@oss.qualcomm.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1116;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=sVIw/XA4Bl5xC2ztfAnRuiSiLBDt6b5+q7ceIieDwBs=;
 b=owGbwMvMwMUYOl/w2b+J574ynlZLYsgqMEuZXvuoIf7qm4IjLz+1n9eX/KGi4xen9exKy5ZF+
 RUtYhLSnYzGLAyMXAyyYoos6UudtRo9Tt9YEqE+HWYQKxPIFAYuTgGYCJ8gB8PCjH7Df/x5jhd0
 pr7Oiwj8d+G61r4NGzJqtXlDsgL5++Icz0msryq41RG+wEhUOGGxkNRclbdze2aXb2y4+9RuUkH
 /i8NVxRcO6+/LnKVjsyhUZxrv7/DwQLFHHa8/3K37yJ8mHt96JExBr6pcIcPDQf5xWuiTLSc6m1
 pCHuxfamTq93nSV74CHc5dwRuVhVa8yYot1034PuOJfz7rjQ2Roq0bt9W07EvcuGuzkuhx9ZDVv
 Nsr3/SmHJjx9ghHUWu4zdkjmt5f+Cpf/3KNeMgfKjXH2uCJr+1cb9as5WGOxw6Lrapq/yF28kBp
 7rdgr8alvB38DEU9X46Gdc7171YKW/3tqr74zRRLu9/LAA==
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be around 0.88V and the
vdda-pll supply to be 1.2V. But these two supplies are swapped for the
USB QMP PHY on this board, feeding 1.2V to vdda-phy and 0.88V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 0b12da4e28d8 ("arm64: dts: qcom: add base AIM300 dtsi")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/qcs8550-aim300.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/qcs8550-aim300.dtsi b/arch/arm64/boot/dts/qcom/qcs8550-aim300.dtsi
index e6ebb643203b..ae301d78e071 100644
--- a/arch/arm64/boot/dts/qcom/qcs8550-aim300.dtsi
+++ b/arch/arm64/boot/dts/qcom/qcs8550-aim300.dtsi
@@ -412,8 +412,8 @@ &usb_1_hsphy {
 };
 
 &usb_dp_qmpphy {
-	vdda-phy-supply = <&vreg_l3e_1p2>;
-	vdda-pll-supply = <&vreg_l3f_0p88>;
+	vdda-phy-supply = <&vreg_l3f_0p88>;
+	vdda-pll-supply = <&vreg_l3e_1p2>;
 };
 
 &xo_board {

-- 
2.43.0

