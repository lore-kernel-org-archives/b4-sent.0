From: George Moussalem <george.moussalem@outlook.com>
Date: Sun, 06 Sep 2026 08:46:46 +0400
Subject: [PATCH v3 07/10] arm64: dts: qcom: ipq6018: Flatten usb controller
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-ipq-flatten-usb-v3-7-13e4e0f63123@outlook.com>
References: <20260906-ipq-flatten-usb-v3-0-13e4e0f63123@outlook.com>
In-Reply-To: <20260906-ipq-flatten-usb-v3-0-13e4e0f63123@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788670018; l=5041;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=QMYZOel4Z7ohvK/v1QgPC715UMdbY7FAiCKD4hgbqKc=;
 b=1JmXJB/g03B3GX1/U7rJmh5iWYzqjYyFt/UUrB9VYljlqwhmNNP4iNhA0pD/vnlkGbTvYL8yR
 QyKuP1yzHHlDnUp76U2bejdaq1hxCAIQo9wzPZ/Nnv3xwDF8e3eDmih
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Flatten usb controller nodes and update to using latest bindings and
flattened driver approach.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq6018-cp01-c1.dts |  6 +-
 arch/arm64/boot/dts/qcom/ipq6018.dtsi        | 93 +++++++++++++---------------
 2 files changed, 44 insertions(+), 55 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq6018-cp01-c1.dts b/arch/arm64/boot/dts/qcom/ipq6018-cp01-c1.dts
index a366be17c251..dfc3aac955e8 100644
--- a/arch/arm64/boot/dts/qcom/ipq6018-cp01-c1.dts
+++ b/arch/arm64/boot/dts/qcom/ipq6018-cp01-c1.dts
@@ -48,10 +48,6 @@ flash@0 {
 	};
 };
 
-&dwc_1 {
-	dr_mode = "host";
-};
-
 &tlmm {
 	i2c_1_pins: i2c-1-state {
 		pins = "gpio42", "gpio43";
@@ -88,5 +84,7 @@ &qusb_phy_1 {
 };
 
 &usb2 {
+	dr_mode = "host";
+
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/qcom/ipq6018.dtsi b/arch/arm64/boot/dts/qcom/ipq6018.dtsi
index c02110ad9cb0..4f5f8b628bf2 100644
--- a/arch/arm64/boot/dts/qcom/ipq6018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq6018.dtsi
@@ -423,12 +423,10 @@ pwm: pwm@1941010 {
 			status = "disabled";
 		};
 
-		usb2: usb@70f8800 {
-			compatible = "qcom,ipq6018-dwc3", "qcom,dwc3";
-			reg = <0x0 0x070f8800 0x0 0x400>;
-			#address-cells = <2>;
-			#size-cells = <2>;
-			ranges;
+		usb2: usb@7000000 {
+			compatible = "qcom,ipq6018-dwc3", "qcom,snps-dwc3";
+			reg = <0x0 0x07000000 0x0 0xfc100>;
+
 			clocks = <&gcc GCC_USB1_MASTER_CLK>,
 				 <&gcc GCC_USB1_SLEEP_CLK>,
 				 <&gcc GCC_USB1_MOCK_UTMI_CLK>;
@@ -441,26 +439,25 @@ usb2: usb@70f8800 {
 			assigned-clock-rates = <133330000>,
 					       <24000000>;
 
-			interrupts = <GIC_SPI 128 IRQ_TYPE_LEVEL_HIGH>,
+			interrupts = <GIC_SPI 99 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 128 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 130 IRQ_TYPE_LEVEL_HIGH>;
-			interrupt-names = "pwr_event",
+			interrupt-names = "dwc_usb3",
+					  "pwr_event",
 					  "qusb2_phy";
 
 			resets = <&gcc GCC_USB1_BCR>;
-			status = "disabled";
 
-			dwc_1: usb@7000000 {
-				compatible = "snps,dwc3";
-				reg = <0x0 0x07000000 0x0 0xcd00>;
-				interrupts = <GIC_SPI 99 IRQ_TYPE_LEVEL_HIGH>;
-				phys = <&qusb_phy_1>;
-				phy-names = "usb2-phy";
-				tx-fifo-resize;
-				snps,is-utmi-l1-suspend;
-				snps,hird-threshold = /bits/ 8 <0x0>;
-				snps,dis_u2_susphy_quirk;
-				snps,dis_u3_susphy_quirk;
-			};
+			phys = <&qusb_phy_1>;
+			phy-names = "usb2-phy";
+
+			tx-fifo-resize;
+			snps,is-utmi-l1-suspend;
+			snps,hird-threshold = /bits/ 8 <0x0>;
+			snps,dis_u2_susphy_quirk;
+			snps,dis_u3_susphy_quirk;
+
+			status = "disabled";
 		};
 
 		sdhc: mmc@7804000 {
@@ -668,21 +665,18 @@ qpic_nand: nand-controller@79b0000 {
 			status = "disabled";
 		};
 
-		usb3: usb@8af8800 {
-			compatible = "qcom,ipq6018-dwc3", "qcom,dwc3";
-			reg = <0x0 0x08af8800 0x0 0x400>;
-			#address-cells = <2>;
-			#size-cells = <2>;
-			ranges;
+		usb3: usb@8a00000 {
+			compatible = "qcom,ipq6018-dwc3", "qcom,snps-dwc3";
+			reg = <0x0 0x08a00000 0x0 0xfc100>;
 
 			clocks = <&gcc GCC_SYS_NOC_USB0_AXI_CLK>,
-				<&gcc GCC_USB0_MASTER_CLK>,
-				<&gcc GCC_USB0_SLEEP_CLK>,
-				<&gcc GCC_USB0_MOCK_UTMI_CLK>;
+				 <&gcc GCC_USB0_MASTER_CLK>,
+				 <&gcc GCC_USB0_SLEEP_CLK>,
+				 <&gcc GCC_USB0_MOCK_UTMI_CLK>;
 			clock-names = "cfg_noc",
-				"core",
-				"sleep",
-				"mock_utmi";
+				      "core",
+				      "sleep",
+				      "mock_utmi";
 
 			assigned-clocks = <&gcc GCC_SYS_NOC_USB0_AXI_CLK>,
 					  <&gcc GCC_USB0_MASTER_CLK>,
@@ -691,31 +685,28 @@ usb3: usb@8af8800 {
 					       <133330000>,
 					       <24000000>;
 
-			interrupts = <GIC_SPI 134 IRQ_TYPE_LEVEL_HIGH>,
+			interrupts = <GIC_SPI 140 IRQ_TYPE_LEVEL_HIGH>,
+				     <GIC_SPI 134 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 136 IRQ_TYPE_LEVEL_HIGH>,
 				     <GIC_SPI 220 IRQ_TYPE_LEVEL_HIGH>;
-			interrupt-names = "pwr_event",
+			interrupt-names = "dwc_usb3",
+					  "pwr_event",
 					  "qusb2_phy",
 					  "ss_phy_irq";
 
 			resets = <&gcc GCC_USB0_BCR>;
-			status = "disabled";
 
-			dwc_0: usb@8a00000 {
-				compatible = "snps,dwc3";
-				reg = <0x0 0x08a00000 0x0 0xcd00>;
-				interrupts = <GIC_SPI 140 IRQ_TYPE_LEVEL_HIGH>;
-				phys = <&qusb_phy_0>, <&ssphy_0>;
-				phy-names = "usb2-phy", "usb3-phy";
-				clocks = <&xo>;
-				clock-names = "ref";
-				tx-fifo-resize;
-				snps,parkmode-disable-ss-quirk;
-				snps,is-utmi-l1-suspend;
-				snps,hird-threshold = /bits/ 8 <0x0>;
-				snps,dis_u2_susphy_quirk;
-				snps,dis_u3_susphy_quirk;
-			};
+			phys = <&qusb_phy_0>, <&ssphy_0>;
+			phy-names = "usb2-phy", "usb3-phy";
+
+			tx-fifo-resize;
+			snps,parkmode-disable-ss-quirk;
+			snps,is-utmi-l1-suspend;
+			snps,hird-threshold = /bits/ 8 <0x0>;
+			snps,dis_u2_susphy_quirk;
+			snps,dis_u3_susphy_quirk;
+
+			status = "disabled";
 		};
 
 		intc: interrupt-controller@b000000 {

-- 
2.53.0

