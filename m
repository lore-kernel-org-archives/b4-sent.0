From: George Moussalem <george.moussalem@outlook.com>
Date: Thu, 01 Oct 2026 11:53:46 +0400
Subject: [PATCH v4 3/8] arm64: dts: qcom: ipq5424: Flatten usb controller
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-ipq-flatten-usb-v4-3-486a4d5ede30@outlook.com>
References: <20261001-ipq-flatten-usb-v4-0-486a4d5ede30@outlook.com>
In-Reply-To: <20261001-ipq-flatten-usb-v4-0-486a4d5ede30@outlook.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Kathiravan Thirumoorthy <kathiravan.thirumoorthy@oss.qualcomm.com>, 
 George Moussalem <george.moussalem@outlook.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790841224; l=5279;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=2WbZjl88BsVpRDMHt1Ow+ORwp5yxlD+lDvmWEcY7aow=;
 b=GMUcklkAGAqAdZc9eG9WsIwoqTJMmjoPPtRbu1lCvJfua42X64RGMQKE92GL6PLGpPWnuedZ3
 XUFH4lUUXPJAko43U4QTlH2BYZXa+IXzZ1PHe5AbVwbqd8OkcmwGfA0
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Flatten usb controller nodes and update to using latest bindings and
flattened driver approach.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5424-rdp466.dts | 12 ++--
 arch/arm64/boot/dts/qcom/ipq5424.dtsi       | 86 +++++++++++++----------------
 2 files changed, 41 insertions(+), 57 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5424-rdp466.dts b/arch/arm64/boot/dts/qcom/ipq5424-rdp466.dts
index 793afc3ee82e..0c3370dba65b 100644
--- a/arch/arm64/boot/dts/qcom/ipq5424-rdp466.dts
+++ b/arch/arm64/boot/dts/qcom/ipq5424-rdp466.dts
@@ -74,14 +74,6 @@ vreg_misc_0p925: regulator-usb-0p925 {
 	};
 };
 
-&dwc_0 {
-	dr_mode = "host";
-};
-
-&dwc_1 {
-	dr_mode = "host";
-};
-
 &pcie2 {
 	pinctrl-0 = <&pcie2_default_state>;
 	pinctrl-names = "default";
@@ -284,10 +276,14 @@ &uart1 {
 };
 
 &usb2 {
+	dr_mode = "host";
+
 	status = "okay";
 };
 
 &usb3 {
+	dr_mode = "host";
+
 	status = "okay";
 };
 
diff --git a/arch/arm64/boot/dts/qcom/ipq5424.dtsi b/arch/arm64/boot/dts/qcom/ipq5424.dtsi
index 23f851e9241f..b1bfe31227e7 100644
--- a/arch/arm64/boot/dts/qcom/ipq5424.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5424.dtsi
@@ -640,12 +640,9 @@ qusb_phy_1: phy@71000 {
 			status = "disabled";
 		};
 
-		usb2: usb2@1ef8800 {
-			compatible = "qcom,ipq5424-dwc3", "qcom,dwc3";
-			reg = <0 0x01ef8800 0 0x400>;
-			#address-cells = <2>;
-			#size-cells = <2>;
-			ranges;
+		usb2: usb2@1e00000 {
+			compatible = "qcom,ipq5424-dwc3", "qcom,snps-dwc3";
+			reg = <0 0x01e00000 0 0xfc100>;
 
 			clocks = <&gcc GCC_USB1_MASTER_CLK>,
 				 <&gcc GCC_USB1_SLEEP_CLK>,
@@ -664,33 +661,31 @@ usb2: usb2@1ef8800 {
 			assigned-clock-rates = <200000000>,
 					       <24000000>;
 
-			interrupts-extended = <&intc GIC_SPI 395 IRQ_TYPE_LEVEL_HIGH>,
+			interrupts-extended = <&intc GIC_SPI 396 IRQ_TYPE_LEVEL_HIGH>,
+					      <&intc GIC_SPI 395 IRQ_TYPE_LEVEL_HIGH>,
 					      <&intc GIC_SPI 397 IRQ_TYPE_LEVEL_HIGH>,
 					      <&intc GIC_SPI 387 IRQ_TYPE_LEVEL_HIGH>,
 					      <&intc GIC_SPI 388 IRQ_TYPE_LEVEL_HIGH>;
-			interrupt-names = "pwr_event",
+			interrupt-names = "dwc_usb3",
+					  "pwr_event",
 					  "qusb2_phy",
 					  "dm_hs_phy_irq",
 					  "dp_hs_phy_irq";
 
 			resets = <&gcc GCC_USB1_BCR>;
+
+			phys = <&qusb_phy_1>;
+			phy-names = "usb2-phy";
+
 			qcom,select-utmi-as-pipe-clk;
-			status = "disabled";
 
-			dwc_1: usb@1e00000 {
-				compatible = "snps,dwc3";
-				reg = <0 0x01e00000 0 0xe000>;
-				clocks = <&gcc GCC_USB1_MOCK_UTMI_CLK>;
-				clock-names = "ref";
-				interrupts = <GIC_SPI 396 IRQ_TYPE_LEVEL_HIGH>;
-				phys = <&qusb_phy_1>;
-				phy-names = "usb2-phy";
-				tx-fifo-resize;
-				snps,is-utmi-l1-suspend;
-				snps,hird-threshold = /bits/ 8 <0x0>;
-				snps,dis_u2_susphy_quirk;
-				snps,dis_u3_susphy_quirk;
-			};
+			tx-fifo-resize;
+			snps,is-utmi-l1-suspend;
+			snps,hird-threshold = /bits/ 8 <0x0>;
+			snps,dis_u2_susphy_quirk;
+			snps,dis_u3_susphy_quirk;
+
+			status = "disabled";
 		};
 
 		qusb_phy_0: phy@7b000 {
@@ -746,13 +741,9 @@ restart_reason: restartreason-sram@7b0 {
 			};
 		};
 
-		usb3: usb3@8af8800 {
-			compatible = "qcom,ipq5424-dwc3", "qcom,dwc3";
-			reg = <0 0x08af8800 0 0x400>;
-
-			#address-cells = <2>;
-			#size-cells = <2>;
-			ranges;
+		usb3: usb3@8a00000 {
+			compatible = "qcom,ipq5424-dwc3", "qcom,snps-dwc3";
+			reg = <0 0x08a00000 0 0xfc100>;
 
 			clocks = <&gcc GCC_USB0_MASTER_CLK>,
 				 <&gcc GCC_USB0_SLEEP_CLK>,
@@ -771,34 +762,31 @@ usb3: usb3@8af8800 {
 			assigned-clock-rates = <200000000>,
 					       <24000000>;
 
-			interrupts-extended = <&intc GIC_SPI 412 IRQ_TYPE_LEVEL_HIGH>,
+			interrupts-extended = <&intc GIC_SPI 409 IRQ_TYPE_LEVEL_HIGH>,
+					      <&intc GIC_SPI 412 IRQ_TYPE_LEVEL_HIGH>,
 					      <&intc GIC_SPI 414 IRQ_TYPE_LEVEL_HIGH>,
 					      <&intc GIC_SPI 423 IRQ_TYPE_LEVEL_HIGH>,
 					      <&intc GIC_SPI 424 IRQ_TYPE_LEVEL_HIGH>;
-			interrupt-names = "pwr_event",
+			interrupt-names = "dwc_usb3",
+					  "pwr_event",
 					  "qusb2_phy",
 					  "dm_hs_phy_irq",
 					  "dp_hs_phy_irq";
 
 			resets = <&gcc GCC_USB_BCR>;
-			status = "disabled";
 
-			dwc_0: usb@8a00000 {
-				compatible = "snps,dwc3";
-				reg = <0 0x08a00000 0 0xcd00>;
-				clocks = <&gcc GCC_USB0_MOCK_UTMI_CLK>;
-				clock-names = "ref";
-				interrupts = <GIC_SPI 409 IRQ_TYPE_LEVEL_HIGH>;
-				phys = <&qusb_phy_0>, <&ssphy_0>;
-				phy-names = "usb2-phy", "usb3-phy";
-				tx-fifo-resize;
-				snps,is-utmi-l1-suspend;
-				snps,hird-threshold = /bits/ 8 <0x0>;
-				snps,dis_u2_susphy_quirk;
-				snps,dis_u3_susphy_quirk;
-				snps,dis-u1-entry-quirk;
-				snps,dis-u2-entry-quirk;
-			};
+			phys = <&qusb_phy_0>, <&ssphy_0>;
+			phy-names = "usb2-phy", "usb3-phy";
+
+			tx-fifo-resize;
+			snps,is-utmi-l1-suspend;
+			snps,hird-threshold = /bits/ 8 <0x0>;
+			snps,dis_u2_susphy_quirk;
+			snps,dis_u3_susphy_quirk;
+			snps,dis-u1-entry-quirk;
+			snps,dis-u2-entry-quirk;
+
+			status = "disabled";
 		};
 
 		timer@f420000 {

-- 
2.53.0

