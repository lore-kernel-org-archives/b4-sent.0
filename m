From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 25 Aug 2026 14:42:31 +0400
Subject: [PATCH 6/9] arm64: dts: qcom: ipq5424: Flatten usb controller
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-ipq-flatten-usb-v1-6-5c1f3170bbe9@outlook.com>
References: <20260825-ipq-flatten-usb-v1-0-5c1f3170bbe9@outlook.com>
In-Reply-To: <20260825-ipq-flatten-usb-v1-0-5c1f3170bbe9@outlook.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787654580; l=5460;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=gdbpY1GROdrMhOSCYV276n/5Y7paNY112o8bpbwPIZY=;
 b=UKXdBccAqZoJwx+wuJcjfo3zeDOMwPbA3eWB+kereCt44wCBDC7sXOp+QIgsNmbV9C5WygWGU
 JaF3imUk7PnBnAP/GfFGT9ijYnThUnbtEshr4jyVaRA6kls034aL/Uq
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Flatten usb controller nodes and update to using latest bindings and
flattened driver approach.

Add property to both USB controller nodes to select UTMI as reference
clock for the DWC3 core to calculate the right values for the period and
frame length adjustment.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5424-rdp466.dts | 12 ++--
 arch/arm64/boot/dts/qcom/ipq5424.dtsi       | 89 +++++++++++++----------------
 2 files changed, 44 insertions(+), 57 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5424-rdp466.dts b/arch/arm64/boot/dts/qcom/ipq5424-rdp466.dts
index be8657239c46..dfd6a124686a 100644
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
@@ -282,10 +274,14 @@ &uart1 {
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
index 702061e16a58..648f95d70448 100644
--- a/arch/arm64/boot/dts/qcom/ipq5424.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5424.dtsi
@@ -639,12 +639,9 @@ qusb_phy_1: phy@71000 {
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
@@ -663,33 +660,32 @@ usb2: usb2@1ef8800 {
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
+			qcom,select-utmi-as-ref-clk;
 
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
@@ -730,13 +726,9 @@ ssphy_0: phy@7d000 {
 			status = "disabled";
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
@@ -755,34 +747,33 @@ usb3: usb3@8af8800 {
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
+			qcom,select-utmi-as-ref-clk;
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

