From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:23 +0200
Subject: [PATCH 25/28] arm64: dts: qcom: lemans: Fix swapped USB QMP PHY
 vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-25-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2105;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=8ZYH+tmfk8ioacGyz9vd+PWCd+d+CB3fr8hUQVuVSJU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZprPy1HXT6zaQO2OZYhfF8KqW2MU0MedvxG
 SN37XucapiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2aQAKCRBVnxHm/pHO
 9dRNCACqQDFGsWycHMV7Kv14p4EGCURPC5fKJynsAYqo8WQal3Bt/0/G/jPp/s6haKIyjNgYDRp
 MBIACg/WuKaNcW686rDBRmKdXMac8lvTmXfD2fu47Focp/Zx1Z9aHR/IZd02Yhl9aQ8JHqr2mri
 ZQ3l8ahQLcXPxHg2vrsPZAlx+q2fuHqaEkKFu1bYDjfP9LOTO1WscZ8hlLAuhUwNROchYSaljAT
 UqE8Rv07I/C1xz9T2SeP17HAccd5c4vdR4NkdycxHD7Z07N1kJpkD/OMWTnuJz35EyG0wdkS7l0
 LG/t/i0J7llwzUm82LhJylcwLeF+d0IYqdWKNmg8nClvKYml
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be the lower voltage (~0.8V)
and the vdda-pll supply to be the higher voltage (~1.2V), as used by the
PCIe and UFS QMP PHYs on this SoC. But these two supplies are swapped for
the USB QMP PHYs on these boards, feeding 1.14V to vdda-phy and 0.72V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 76326da895b8 ("arm64: dts: qcom: lemans: Refactor ride/ride-r3 boards based on daughter cards")
Fixes: 7bd68ef80661 ("arm64: dts: qcom: lemans-evk: Enable first USB controller in device mode")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/lemans-evk.dts          | 4 ++--
 arch/arm64/boot/dts/qcom/lemans-ride-common.dtsi | 8 ++++----
 2 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/lemans-evk.dts b/arch/arm64/boot/dts/qcom/lemans-evk.dts
index 34dfc8d22b6a..b835fce8b336 100644
--- a/arch/arm64/boot/dts/qcom/lemans-evk.dts
+++ b/arch/arm64/boot/dts/qcom/lemans-evk.dts
@@ -1008,8 +1008,8 @@ &usb_0_hsphy {
 };
 
 &usb_0_qmpphy {
-	vdda-phy-supply = <&vreg_l1c>;
-	vdda-pll-supply = <&vreg_l7a>;
+	vdda-phy-supply = <&vreg_l7a>;
+	vdda-pll-supply = <&vreg_l1c>;
 
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/qcom/lemans-ride-common.dtsi b/arch/arm64/boot/dts/qcom/lemans-ride-common.dtsi
index 40f88498999b..b2195fc03095 100644
--- a/arch/arm64/boot/dts/qcom/lemans-ride-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/lemans-ride-common.dtsi
@@ -1103,8 +1103,8 @@ &usb_0_hsphy {
 };
 
 &usb_0_qmpphy {
-	vdda-phy-supply = <&vreg_l1c>;
-	vdda-pll-supply = <&vreg_l7a>;
+	vdda-phy-supply = <&vreg_l7a>;
+	vdda-pll-supply = <&vreg_l1c>;
 
 	status = "okay";
 };
@@ -1126,8 +1126,8 @@ &usb_1_hsphy {
 };
 
 &usb_1_qmpphy {
-	vdda-phy-supply = <&vreg_l1c>;
-	vdda-pll-supply = <&vreg_l7a>;
+	vdda-phy-supply = <&vreg_l7a>;
+	vdda-pll-supply = <&vreg_l1c>;
 
 	status = "okay";
 };

-- 
2.43.0

