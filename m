From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:26 +0200
Subject: [PATCH 28/28] arm64: dts: qcom: talos-evk: Fix swapped USB QMP PHY
 vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-28-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1127;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=z+Dr9mEJKAeC1o6t8aRa4QhX6vOTIK+pqWvTSI5WUL0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZqnBt1DwNxdiyYJgZrKfWtJVtUJHHhNldkL
 cMBjrT5vq2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2agAKCRBVnxHm/pHO
 9SqPCACYwM3BIyy9MF67qMTOrytLV8geZoq4OQRuFKNGh8fP63a/EQhPUYv+JOzjrePFkvC0z1T
 pp9s3vnvSMRZ3f2yDl1DWU84Bn8xS4s05z6H/uc2TxoWS+tN4GdQ+rloTiGQesLiskU7mf3vg15
 sHyKCe9NEOmdauq0V7QLGeIbu5XUjNsBhjIV//6ZaHteqwppXAsLkSYf1DNOQlkn2vyaAvgGnaR
 M7ZAgLPULtbprPCaDTH40I8FpvgggraBfK2XdPuv1lqUcsedUbeT+CTP1w773lSzv1pyAxBlZF3
 tuWHUtzbafQBLQhGiDpF1hlr82F43MFv6S3Ave4TPU54S2jm
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be around 0.88V and the
vdda-pll supply to be 1.2V. But these two supplies are swapped for the
USB QMP PHY on this board, feeding 1.2V to vdda-phy and 0.9V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 0f9e6db8a223 ("arm64: dts: qcom: talos-evk: Add support for QCS615 talos evk board")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/talos-evk-som.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/talos-evk-som.dtsi b/arch/arm64/boot/dts/qcom/talos-evk-som.dtsi
index 294354c034c3..6469c6fa9f63 100644
--- a/arch/arm64/boot/dts/qcom/talos-evk-som.dtsi
+++ b/arch/arm64/boot/dts/qcom/talos-evk-som.dtsi
@@ -589,8 +589,8 @@ &usb_qmpphy {
 };
 
 &usb_qmpphy_2 {
-	vdda-phy-supply = <&vreg_l11a>;
-	vdda-pll-supply = <&vreg_l5a>;
+	vdda-phy-supply = <&vreg_l5a>;
+	vdda-pll-supply = <&vreg_l11a>;
 
 	status = "okay";
 };

-- 
2.43.0

