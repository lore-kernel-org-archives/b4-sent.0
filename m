From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:25 +0200
Subject: [PATCH 27/28] arm64: dts: qcom: sa8155p-adp: Fix swapped USB and
 UFS QMP PHY vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-27-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1474;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=pdJ0+3lX9UMfGKOEewe/tBmrR1874axt7eR/rE1rQKA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZqKHe223E6pEgdH/0XeGjVB6/RfA9bnBotd
 Rquzznvg+yJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2agAKCRBVnxHm/pHO
 9e8ZCACfrwAdlhREt3IKb/wQv6c7XAvzJVMM4RN25WXYTPUfhRl8hVUlmcwkLvAAM6QLqtN7mVX
 wStj7XURMI06AU8Nj5xqhX07IpRkjGlV3GkPDh1C1Cmzuk4ScrbDsqpcJJKgP+1Usd9886E/Izw
 pBV05q06fiwYyxVjG5tPksfwMaZrtA8/I5eD2DVaAHFKy+ukkkRxRaKD/CtP3SbNA66RoLzCfgl
 T3SJgchY+akReqbBi24lldIbNT2zTwUUNAYaF43/iy36vFFAqLxn2GHYbJion3k8e6m5QB5pCgU
 iqKVU9Ip2UuvI7l8iSq+cTrqa+wjzBursNr2G1M6/n2FlXFe
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be around 0.88V and the
vdda-pll supply to be 1.2V. But these two supplies are swapped for the
USB and UFS QMP PHYs on this board, feeding 1.2V to vdda-phy and 0.9V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 12dd4ebda47a ("arm64: dts: qcom: Fix usb entries for SA8155p adp board")
Fixes: 5b85e8f2225c ("arm64: dts: qcom: sa8155p-adp: Add base dts file")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sa8155p-adp.dts | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sa8155p-adp.dts b/arch/arm64/boot/dts/qcom/sa8155p-adp.dts
index 388d5ecee949..3e22ee8b5092 100644
--- a/arch/arm64/boot/dts/qcom/sa8155p-adp.dts
+++ b/arch/arm64/boot/dts/qcom/sa8155p-adp.dts
@@ -428,8 +428,8 @@ &ufs_mem_hc {
 &ufs_mem_phy {
 	status = "okay";
 
-	vdda-phy-supply = <&vreg_l8c_1p2>;
-	vdda-pll-supply = <&vreg_l5a_0p88>;
+	vdda-phy-supply = <&vreg_l5a_0p88>;
+	vdda-pll-supply = <&vreg_l8c_1p2>;
 };
 
 &usb_1 {
@@ -474,8 +474,8 @@ &usb_2_hsphy {
 
 &usb_2_qmpphy {
 	status = "okay";
-	vdda-phy-supply = <&vreg_l8c_1p2>;
-	vdda-pll-supply = <&vdda_usb_ss_dp_core_1>;
+	vdda-phy-supply = <&vdda_usb_ss_dp_core_1>;
+	vdda-pll-supply = <&vreg_l8c_1p2>;
 };
 
 &pcie0 {

-- 
2.43.0

