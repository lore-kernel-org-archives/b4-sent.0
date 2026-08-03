From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:00 +0200
Subject: [PATCH 02/28] arm64: dts: qcom: sc8280xp-blackrock: Fix swapped
 USB QMP PHY vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-2-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1429;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=CcvnhusAZmfI+yh1IIykSb8F96Q6pOG85doT5s1hKoU=;
 b=owGbwMvMwMUYOl/w2b+J574ynlZLYsgqMEtk4PkaZm/2p3335S0ML9/4ng1fWFmnOnX6voD71
 Wc8V/nUdDIaszAwcjHIiimypC911mr0OH1jSYT6dJhBrExgU7g4BWAiux9wMDSkXXvSre9tcjBs
 A3ev+5KVtWoOT/rn1CTGMIf2eZlfeGsxpbL2KMu6u6/0FHxDNjUb6KXbJdzhEY2fM/eo0d6zkg8
 eae0JajR5ZyT0RcC11uraqfxd55+o3E7NYF9y78QUP5Ginrj3vz+/WtOokGkyp3fdJovfhrKL9v
 HODnsZccRNSKn2aFNj/eXEbUvU1WvWb025n5Eo1r4suMjp33efqolr5mgf4JV30zGKeDSBcb3tv
 WuG9kVzXY/HZFyv7bT+xvt73uuqpglWTxmMdOXv3fmouKJL1D/pU2Ck37dbqgLddv5nBYM89I3K
 erkcwleH7RPMFHk4O+FeQwfL9Us+t/bom77gmHG85JgNAA==
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be around 0.88V and the
vdda-pll supply to be 1.2V. But these two supplies are swapped for the
USB QMP PHYs on this board, feeding 1.2V to vdda-phy and 0.9V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 16a7fed11714 ("arm64: dts: qcom: sc8280xp-blackrock: dt definition for WDK2023")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
index 125af356e24b..4e74eda7405f 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-blackrock.dts
@@ -1003,8 +1003,8 @@ &usb_0_hsphy {
 };
 
 &usb_0_qmpphy {
-	vdda-phy-supply = <&vreg_l4d>;
-	vdda-pll-supply = <&vreg_l9d>;
+	vdda-phy-supply = <&vreg_l9d>;
+	vdda-pll-supply = <&vreg_l4d>;
 
 	orientation-switch;
 
@@ -1040,8 +1040,8 @@ &usb_1_hsphy {
 };
 
 &usb_1_qmpphy {
-	vdda-phy-supply = <&vreg_l3b>;
-	vdda-pll-supply = <&vreg_l4b>;
+	vdda-phy-supply = <&vreg_l4b>;
+	vdda-pll-supply = <&vreg_l3b>;
 
 	orientation-switch;
 

-- 
2.43.0

