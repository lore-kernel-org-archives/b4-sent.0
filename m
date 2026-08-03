From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:19 +0200
Subject: [PATCH 21/28] arm64: dts: qcom: sm8750: Fix swapped USB QMP PHY
 vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-21-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1734;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=Hvrjmn+BHOaL81Hl9ocL7I8WQhouCubTnWtvMsEB+cg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZogIROlkY2DpYxDpFpRT/e5SNCvMrAc1aSx
 mDH7/S6RY+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2aAAKCRBVnxHm/pHO
 9c/VB/sHsHGcfKENAiilCEN3nYvYAYJHFnViRxGlrcRO7nuM3KKEdh4ZbwMDKjEFlzmh5r0sUS3
 +tQiTiVPJw/R7uBACi6WG024oIuQbU1yTsY9JplUq4YlaDrwoi4f7hbTnpg9U0g+/9n11L9At0R
 WRXysIfuSqRWEMxmEUXbqkDdnHTP/7Czge8QWp7UWkLe6t1I3IFzhfclEJ98drNV+7Ues475ofP
 8Mwbgk/l/xefINwFDO2sXAzY4KWn9mBmWwVN79aBjP1gceZtlLW5CD0o/n1gKSbTISEvXgqYE4N
 LsHz6ovCzcV9OQk5h6cjYDMjtZhB8RUyNKJLs2Kg+/DE38VB
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be around 0.88V and the
vdda-pll supply to be 1.2V. But these two supplies are swapped for the
USB QMP PHYs on these boards, feeding 1.2V to vdda-phy and 0.88V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 2340f29e2b06 ("arm64: dts: qcom: sm8750: Add USB support for SM8750 MTP platform")
Fixes: 530f824a4e18 ("arm64: dts: qcom: sm8750: Add USB support for SM8750 QRD platform")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sm8750-mtp.dts | 4 ++--
 arch/arm64/boot/dts/qcom/sm8750-qrd.dts | 4 ++--
 2 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8750-mtp.dts b/arch/arm64/boot/dts/qcom/sm8750-mtp.dts
index 3837f6785320..9b5fbc004df4 100644
--- a/arch/arm64/boot/dts/qcom/sm8750-mtp.dts
+++ b/arch/arm64/boot/dts/qcom/sm8750-mtp.dts
@@ -1404,8 +1404,8 @@ &usb {
 };
 
 &usb_dp_qmpphy {
-	vdda-phy-supply = <&vreg_l3g_1p2>;
-	vdda-pll-supply = <&vreg_l2d_0p88>;
+	vdda-phy-supply = <&vreg_l2d_0p88>;
+	vdda-pll-supply = <&vreg_l3g_1p2>;
 
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/qcom/sm8750-qrd.dts b/arch/arm64/boot/dts/qcom/sm8750-qrd.dts
index 801c46d55602..b56317cfa9fc 100644
--- a/arch/arm64/boot/dts/qcom/sm8750-qrd.dts
+++ b/arch/arm64/boot/dts/qcom/sm8750-qrd.dts
@@ -1132,8 +1132,8 @@ &usb {
 };
 
 &usb_dp_qmpphy {
-	vdda-phy-supply = <&vreg_l3g_1p2>;
-	vdda-pll-supply = <&vreg_l2d_0p88>;
+	vdda-phy-supply = <&vreg_l2d_0p88>;
+	vdda-pll-supply = <&vreg_l3g_1p2>;
 
 	status = "okay";
 };

-- 
2.43.0

