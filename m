From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 25 Aug 2026 16:37:25 +0400
Subject: [PATCH v3 08/12] arm64: dts: qcom: ipq5018: Add USB Super-Speed
 PHY node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-ipq5018-usb3-v3-8-39be0955a6aa@outlook.com>
References: <20260825-ipq5018-usb3-v3-0-39be0955a6aa@outlook.com>
In-Reply-To: <20260825-ipq5018-usb3-v3-0-39be0955a6aa@outlook.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Praveenkumar I <praveenkumar.i@oss.qualcomm.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Nitheesh Sekar <quic_nsekar@quicinc.com>, 
 Wesley Cheng <quic_wcheng@quicinc.com>, 
 Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787661450; l=1320;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=3gnMuvdkhkSVCiECSjDDLV0IaEe/Z6xvImu3EIsvXdQ=;
 b=Cknj3brONBxs/fkWzuFYk+noU2/5hU46dPVVx7B3IKjGcQqW/s4Vkd1ihFhRVK/WAOdVNL46K
 zO0iGzB9aGdDsirSHzKDD7mgIJjv3NzyIYU3YVMs5Nq49wCwyCE7gJI
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the USB3 PHY node and populate the USB DT clock on the GCC node for
the GCC to gate the PIPE clock supplied by the USB3 PHY.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 19 ++++++++++++++++++-
 1 file changed, 18 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 71834606535e..7638299671d8 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -179,6 +179,23 @@ usbphy0: phy@5b000 {
 			status = "disabled";
 		};
 
+		usbphy1: phy@5d000 {
+			compatible = "qcom,ipq5018-uniphy-usb3-phy";
+			reg = <0x0005d000 0x800>;
+
+			clocks = <&gcc GCC_USB0_PHY_CFG_AHB_CLK>,
+				 <&gcc GCC_USB0_PIPE_CLK>;
+
+			resets = <&gcc GCC_USB0_PHY_BCR>;
+
+			#clock-cells = <0>;
+			#phy-cells = <0>;
+
+			qcom,phy-usb-mux-sel = <&tcsr 0x10540>;
+
+			status = "disabled";
+		};
+
 		pcie1_phy: phy@7e000 {
 			compatible = "qcom,ipq5018-uniphy-pcie-phy";
 			reg = <0x0007e000 0x800>;
@@ -436,7 +453,7 @@ gcc: clock-controller@1800000 {
 				 <&sleep_clk>,
 				 <&pcie0_phy>,
 				 <&pcie1_phy>,
-				 <0>,
+				 <&usbphy1>,
 				 <&gephy_rx_clk>,
 				 <&gephy_tx_clk>,
 				 <0>,

-- 
2.53.0

