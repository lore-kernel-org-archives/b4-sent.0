From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 03 Aug 2026 08:34:24 +0200
Subject: [PATCH 26/28] arm64: dts: qcom: eliza-mtp: Fix swapped USB QMP PHY
 vdda-phy/vdda-pll supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-phy-supply-fix-v1-26-5880630cde3e@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1160;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=ANzRcaIcnxqMKC8C1vEn6VKb3Z6RSk0Mx0s2IxhfNQ8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqcDZqYHVMvEtvdZq/wH/mij3JpnHQAwdL5s7/5
 4JuNh8AHQ2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCanA2agAKCRBVnxHm/pHO
 9V7MB/9q1TWNFnwv+zOIdxNXpHDPD1eG90qECIoEQg1fDY+fSY9qpPLsH6dwOj55Xj7Pg9qtwEQ
 xZFgpFUvX+kKwLEcMTtWgTIJl8S6uLq7MRCnQuhNWKhKhz+Ga4KmoG5K7n//j3wWR615xI2vthU
 BWrsQzx6yax5wzanMlS2sJKzkUjgrETQlGaVRrqD3iSr5/dUG3omQ85eGR8rD4vET/YewrGleaz
 20VbtMDsB+OWj34jdoJA8AmQwBUgQztwMsm1Ns3WK+xq8AFi33iogNG9CCYx1BvGp7fsx3XfQqD
 uzPKx+FQvypjr8OBWpL0X9C7wmhoDE+KTF5MaHEqwdhbc1sl
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QMP PHY expects the vdda-phy supply to be the lower voltage (~0.8V)
and the vdda-pll supply to be the higher voltage (~1.2V), as used by the
UFS QMP PHY on this SoC. But these two supplies are swapped for the USB
QMP PHY on this board, feeding 1.15V to vdda-phy and 0.72V to vdda-pll.

Fix it by swapping the two supplies back.

Fixes: 49dab7311f57 ("arm64: dts: qcom: eliza-mtp: Enable USB and ADSP support")
Reported-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Assisted-by: Claude:opus-4-8
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/eliza-mtp.dts | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/eliza-mtp.dts b/arch/arm64/boot/dts/qcom/eliza-mtp.dts
index 1374afd9d14e..9d58ef20213a 100644
--- a/arch/arm64/boot/dts/qcom/eliza-mtp.dts
+++ b/arch/arm64/boot/dts/qcom/eliza-mtp.dts
@@ -535,8 +535,8 @@ &usb {
 };
 
 &usb_dp_qmpphy {
-	vdda-phy-supply = <&vreg_l3g>;
-	vdda-pll-supply = <&vreg_l7k>;
+	vdda-phy-supply = <&vreg_l7k>;
+	vdda-pll-supply = <&vreg_l3g>;
 
 	status = "okay";
 };

-- 
2.43.0

