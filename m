From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:20 +0200
Subject: [PATCH 22/28] arm64: dts: qcom: sar2130p: Fix swapped USB QMP PHY
 vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-22-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1144;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=WKawKoYyiR4q4gN4qKPm1tu6RoVI63v74w4JT0Dpu6E=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZoAj5EwpuJnINd90aVcqskc7TdKE9B5mITI
 xW+7O6mGkiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2aAAKCRBVnxHm/pHO
 9RBNB/4nYm9dhYycWWaIwDgBqCKs7+KT7USw5oz2lsUzCetC1/3zrQpO94Lz+M+Fe7mTg/0qsVV
 qoghb7x5Y8pB3q99MzLUjxtc7SlWgcEyYiJIC/tr9RBM5BXVVHNXbV8I4ERJZ3oF9bED/Sfry4a
 RRwMh6fSoytqlFV+gOMDcclANoz3lKsU8k7DlkJRFlP3vqW9NdHp41L2jHfxQCmYU+pHdFbRJ5k
 UrS8+ghJy3vsqIOCL79ZF1g2GZrZfZF/nIFMhNRu+/P/vH4LgDzVcmifhdhm36Tox/DlIz66SwG
 4n+s1gcenfHdkW7w1UsWGZfyQq7TfuL7MzLe4q3ek+6SNrgp
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be around 0.88V and the
vdda-pll supply to be 1.2V. But these two supplies are swapped for the
USB QMP PHY on this board, feeding 1.2V to vdda-phy and 0.9V to
vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 6339e41fa39b ("arm64: dts: qcom: sar2130p: add QAR2130P board file")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/sar2130p-qar2130p.dts | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sar2130p-qar2130p.dts b/arch/arm64/boot/dts/qcom/sar2130p-qar2130p.dts
index 74778a5b19ba..80428c0b3b4e 100644
--- a/arch/arm64/boot/dts/qcom/sar2130p-qar2130p.dts
+++ b/arch/arm64/boot/dts/qcom/sar2130p-qar2130p.dts
@@ -551,8 +551,8 @@ &usb_1_hsphy {
 };
 
 &usb_dp_qmpphy {
-	vdda-phy-supply = <&vreg_l3a_1p2>;
-	vdda-pll-supply = <&vreg_l1a_0p91>;
+	vdda-phy-supply = <&vreg_l1a_0p91>;
+	vdda-pll-supply = <&vreg_l3a_1p2>;
 
 	status = "okay";
 };

-- 
2.43.0

