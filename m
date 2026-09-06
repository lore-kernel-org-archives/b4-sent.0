From: George Moussalem <george.moussalem@outlook.com>
Date: Sun, 06 Sep 2026 07:52:42 +0400
Subject: [PATCH v2 03/10] arm64: dts: qcom: ipq5018: Flatten usb controller
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-ipq-flatten-usb-v2-3-dab83120b10a@outlook.com>
References: <20260906-ipq-flatten-usb-v2-0-dab83120b10a@outlook.com>
In-Reply-To: <20260906-ipq-flatten-usb-v2-0-dab83120b10a@outlook.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 George Moussalem <george.moussalem@outlook.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788666763; l=3217;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=d4OUV1ubr3frsOV//1ALOKp4iIE5azs6C7X+EbQ6/2I=;
 b=gb7aWJMe5r6tJ8REzjiJM7mKtSIEt1xg0oUsNTDPCp98csv/pCQ/SD2VKO+R2/xrhItZv95z8
 4Ay+Zq0n3kiCZCI7eTnEmvf8AJMvX9QqFHlK5QPQOXVLA/SXUe2wB0N
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Flatten usb controller node and update to using latest bindings and
flattened driver approach.

In addition, set the right UTMI clock rate and override any clock
rate inherited from the bootloader.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts |  6 +--
 arch/arm64/boot/dts/qcom/ipq5018.dtsi          | 51 ++++++++++++--------------
 2 files changed, 25 insertions(+), 32 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts b/arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts
index 33eef92b19b1..8efb2b21ed9e 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts
+++ b/arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts
@@ -110,11 +110,9 @@ data-pins {
 };
 
 &usb {
-	status = "okay";
-};
-
-&usb_dwc {
 	dr_mode = "host";
+
+	status = "okay";
 };
 
 &usbphy0 {
diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 4fc627b47fe7..956d3217ec52 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -580,16 +580,9 @@ qpic_nand: spi@79b0000 {
 			status = "disabled";
 		};
 
-		usb: usb@8af8800 {
-			compatible = "qcom,ipq5018-dwc3", "qcom,dwc3";
-			reg = <0x08af8800 0x400>;
-
-			interrupts = <GIC_SPI 134 IRQ_TYPE_LEVEL_HIGH>,
-				     <GIC_SPI 121 IRQ_TYPE_LEVEL_HIGH>,
-				     <GIC_SPI 120 IRQ_TYPE_LEVEL_HIGH>;
-			interrupt-names = "pwr_event",
-					  "dp_hs_phy_irq",
-					  "dm_hs_phy_irq";
+		usb: usb@8a00000 {
+			compatible = "qcom,ipq5018-dwc3", "qcom,snps-dwc3";
+			reg = <0x08a00000 0xfc100>;
 
 			clocks = <&gcc GCC_USB0_MASTER_CLK>,
 				 <&gcc GCC_SYS_NOC_USB0_AXI_CLK>,
@@ -599,30 +592,32 @@ usb: usb@8af8800 {
 				      "iface",
 				      "sleep",
 				      "mock_utmi";
+			assigned-clocks = <&gcc GCC_USB0_MOCK_UTMI_CLK>;
+			assigned-clock-rates = <60000000>;
+
+			interrupts = <GIC_SPI 140 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 134 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 121 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 120 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "dwc_usb3",
+					  "pwr_event",
+					  "dp_hs_phy_irq",
+					  "dm_hs_phy_irq";
 
 			resets = <&gcc GCC_USB0_BCR>;
 
+			phys = <&usbphy0>;
+			phy-names = "usb2-phy";
+
 			qcom,select-utmi-as-pipe-clk;
-			#address-cells = <1>;
-			#size-cells = <1>;
-			ranges;
 
-			status = "disabled";
+			tx-fifo-resize;
+			snps,is-utmi-l1-suspend;
+			snps,hird-threshold = /bits/ 8 <0x0>;
+			snps,dis_u2_susphy_quirk;
+			snps,dis_u3_susphy_quirk;
 
-			usb_dwc: usb@8a00000 {
-				compatible = "snps,dwc3";
-				reg = <0x08a00000 0xe000>;
-				clocks = <&gcc GCC_USB0_MOCK_UTMI_CLK>;
-				clock-names = "ref";
-				interrupts = <GIC_SPI 140 IRQ_TYPE_LEVEL_HIGH>;
-				phy-names = "usb2-phy";
-				phys = <&usbphy0>;
-				tx-fifo-resize;
-				snps,is-utmi-l1-suspend;
-				snps,hird-threshold = /bits/ 8 <0x0>;
-				snps,dis_u2_susphy_quirk;
-				snps,dis_u3_susphy_quirk;
-			};
+			status = "disabled";
 		};
 
 		intc: interrupt-controller@b000000 {

-- 
2.53.0

