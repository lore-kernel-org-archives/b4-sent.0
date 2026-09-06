From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 20:36:44 +0200
Subject: [PATCH v2 21/22] arm64: dts: apple: t8112: Add USB4 ACIO and NHI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-apple-soc-tbt-v2-21-1f80085f93fb@kernel.org>
References: <20260906-b4-apple-soc-tbt-v2-0-1f80085f93fb@kernel.org>
In-Reply-To: <20260906-b4-apple-soc-tbt-v2-0-1f80085f93fb@kernel.org>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=10505; i=sven@kernel.org;
 h=from:subject:message-id; bh=yCkOmBaR5nil6EWh+gg1vqFVc4hjJ7N+uufRHhr7jwc=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTWe3bLoX8SFp0buN0X4LP5nz/D1bqfjsfMH+XLGbz
 yyazky62VHKwiDGxSArpsiyfb+96ZOHbwSXbrr0HmYOKxPIEAYuTgGYiOImRoaHvAncd4/Jylc7
 6upKtG39u1z40oW+9TLHEqzO/34k872O4X+m2s6fe08dCsz9sGmrY3jhbbbeZdej4/++8ajNvh9
 fcYsXAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the ACIO host router, NHI, DART and mailbox nodes for both Type-C
ports on t8112 and connect the host routers to the Type-C connectors.
Also describe the USB3 path from each host router to its DWC3 controller
so the NHI driver can create the required device link.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/t8112-jxxx.dtsi |  95 ++++++++++++++-
 arch/arm64/boot/dts/apple/t8112.dtsi      | 186 ++++++++++++++++++++++++++++++
 2 files changed, 279 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/apple/t8112-jxxx.dtsi b/arch/arm64/boot/dts/apple/t8112-jxxx.dtsi
index 562e7a25a1e8..d0dc7eaaca35 100644
--- a/arch/arm64/boot/dts/apple/t8112-jxxx.dtsi
+++ b/arch/arm64/boot/dts/apple/t8112-jxxx.dtsi
@@ -13,6 +13,10 @@ / {
 	aliases {
 		atcphy0 = &atcphy0;
 		atcphy1 = &atcphy1;
+		usb4-0-acio = &usb4_0_acio;
+		usb4-0-nhi = &usb4_0_nhi;
+		usb4-1-acio = &usb4_1_acio;
+		usb4-1-nhi = &usb4_1_nhi;
 		serial0 = &serial0;
 		serial2 = &serial2;
 	};
@@ -76,6 +80,13 @@ typec0_connector_ss: endpoint {
 						remote-endpoint = <&atcphy0_typec_lanes>;
 					};
 				};
+
+				port@2 {
+					reg = <2>;
+					typec0_con_tbt: endpoint {
+						remote-endpoint = <&usb4_0_acio_tbt>;
+					};
+				};
 			};
 		};
 	};
@@ -107,6 +118,13 @@ typec1_connector_ss: endpoint {
 						remote-endpoint = <&atcphy1_typec_lanes>;
 					};
 				};
+
+				port@2 {
+					reg = <2>;
+					typec1_con_tbt: endpoint {
+						remote-endpoint = <&usb4_1_acio_tbt>;
+					};
+				};
 			};
 		};
 	};
@@ -126,10 +144,19 @@ dwc3_0_hs: endpoint {
 		};
 
 		port@1 {
+			#address-cells = <1>;
+			#size-cells = <0>;
 			reg = <1>;
-			dwc3_0_ss: endpoint {
+
+			dwc3_0_ss: endpoint@0 {
+				reg = <0>;
 				remote-endpoint = <&atcphy0_usb3>;
 			};
+
+			dwc3_0_usb4: endpoint@1 {
+				reg = <1>;
+				remote-endpoint = <&usb4_0_acio_usb3>;
+			};
 		};
 	};
 };
@@ -147,10 +174,19 @@ dwc3_1_hs: endpoint {
 		};
 
 		port@1 {
+			#address-cells = <1>;
+			#size-cells = <0>;
 			reg = <1>;
-			dwc3_1_ss: endpoint {
+
+			dwc3_1_ss: endpoint@0 {
+				reg = <0>;
 				remote-endpoint = <&atcphy1_usb3>;
 			};
+
+			dwc3_1_usb4: endpoint@1 {
+				reg = <1>;
+				remote-endpoint = <&usb4_1_acio_usb3>;
+			};
 		};
 	};
 };
@@ -198,6 +234,61 @@ atcphy1_usb3: endpoint {
 	};
 };
 
+/* USB4 */
+&usb4_0_acio {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		/* 1: USB4 port */
+		port@1 {
+			reg = <1>;
+			usb4_0_acio_tbt: endpoint {
+				remote-endpoint = <&typec0_con_tbt>;
+			};
+		};
+
+		/* 2: USB4 lane 1 adapter */
+		/* 3: PCIe */
+		port@4 {
+			reg = <4>;
+			usb4_0_acio_usb3: endpoint {
+				remote-endpoint = <&dwc3_0_usb4>;
+			};
+		};
+
+		/* 5: DP0 */
+		/* 6: DP1 */
+	};
+};
+
+&usb4_1_acio {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		/* 1: USB4 port */
+		port@1 {
+			reg = <1>;
+			usb4_1_acio_tbt: endpoint {
+				remote-endpoint = <&typec1_con_tbt>;
+			};
+		};
+
+		/* 2: USB4 lane 1 adapter */
+		/* 3: PCIe */
+		port@4 {
+			reg = <4>;
+			usb4_1_acio_usb3: endpoint {
+				remote-endpoint = <&dwc3_1_usb4>;
+			};
+		};
+
+		/* 5: DP0 */
+		/* 6: DP1 */
+	};
+};
+
 &i2c1 {
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/apple/t8112.dtsi b/arch/arm64/boot/dts/apple/t8112.dtsi
index 2c3b59e05e01..e70ed4a470e1 100644
--- a/arch/arm64/boot/dts/apple/t8112.dtsi
+++ b/arch/arm64/boot/dts/apple/t8112.dtsi
@@ -991,6 +991,14 @@ pinctrl_aop: pinctrl@24a820000 {
 				     <AIC_IRQ 305 IRQ_TYPE_LEVEL_HIGH>,
 				     <AIC_IRQ 306 IRQ_TYPE_LEVEL_HIGH>,
 				     <AIC_IRQ 307 IRQ_TYPE_LEVEL_HIGH>;
+
+			acio0_pins: acio0-pins {
+				pinmux = <APPLE_PINMUX(28, 1)>;
+			};
+
+			acio1_pins: acio1-pins {
+				pinmux = <APPLE_PINMUX(30, 1)>;
+			};
 		};
 
 		ans_mbox: mbox@277408000 {
@@ -1027,6 +1035,95 @@ nvme@27bcc0000 {
 			resets = <&ps_ans>;
 		};
 
+		usb4_0_mbox: mailbox@381108000 {
+			compatible = "apple,t8112-asc-mailbox",
+				"apple,asc-mailbox-v4";
+			reg = <0x3 0x81108000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 1067 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 1068 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 1069 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 1070 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "send-empty", "send-not-empty",
+				"recv-empty", "recv-not-empty";
+			#mbox-cells = <0>;
+		};
+
+		usb4_0_acio: cio@381ac0000 {
+			compatible = "apple,t8112-usb4-acio", "apple,t8103-usb4-acio";
+			reg = <0x3 0x81ac0000 0x0 0xc000>,
+				<0x3 0x81080000 0x0 0x20000>;
+			reg-names = "rc", "sram";
+
+			mboxes = <&usb4_0_mbox>;
+			resets = <&cio_reset 0>;
+
+			power-domains = <&ps_atc0_cio>,
+					<&ps_atc0_cio_pcie>,
+					<&ps_atc0_cio_usb>;
+
+			pinctrl-0 = <&acio0_pins>;
+			pinctrl-names = "default";
+
+			#address-cells = <1>;
+			#size-cells = <1>;
+			ranges = <0x0 0x3 0x81000000 0x1000000>;
+			nonposted-mmio;
+
+			usb4_0_dart: iommu@a80000 {
+				compatible = "apple,t8110-dart";
+				reg = <0xa80000 0x4000>;
+				interrupt-parent = <&aic>;
+				interrupts = <AIC_IRQ 1065 IRQ_TYPE_LEVEL_HIGH>;
+				#iommu-cells = <1>;
+			};
+
+			usb4_0_nhi: nhi@f00000 {
+				reg = <0xf00000 0x100000>,
+					<0xdb0000 0x30004>;
+				reg-names = "nhi", "pdf";
+				compatible = "apple,t8112-usb4-nhi",
+					"apple,t8103-usb4-nhi";
+				interrupt-parent = <&aic>;
+				interrupts = <AIC_IRQ 1038 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1039 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1040 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1041 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1042 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1043 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1044 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1045 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1046 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1047 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1048 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1049 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1050 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1051 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1052 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1053 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1054 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1055 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1056 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1057 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1058 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1059 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1060 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1061 IRQ_TYPE_LEVEL_HIGH>;
+				interrupt-names =
+					"txring0", "txring1", "txring2",
+					"txring3", "txring4", "txring5",
+					"txring6", "txring7", "txring8",
+					"txring9", "txring10", "txring11",
+					"rxring0", "rxring1", "rxring2",
+					"rxring3", "rxring4", "rxring5",
+					"rxring6", "rxring7", "rxring8",
+					"rxring9", "rxring10", "rxring11";
+				iommus = <&usb4_0_dart 1>;
+				/* To be filled by the loader */
+				apple,thunderbolt-drom = [00];
+			};
+		};
+
 		dwc3_0: usb@382280000 {
 			compatible = "apple,t8112-dwc3", "apple,t8103-dwc3";
 			reg = <0x3 0x82280000 0x0 0xcd00>, <0x3 0x8228cd00 0x0 0x3200>;
@@ -1079,6 +1176,95 @@ atcphy0: phy@383000000 {
 			power-domains = <&ps_atc0_usb>;
 		};
 
+		usb4_1_mbox: mailbox@501108000 {
+			compatible = "apple,t8112-asc-mailbox",
+				"apple,asc-mailbox-v4";
+			reg = <0x5 0x01108000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 1148 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 1149 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 1150 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 1151 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "send-empty", "send-not-empty",
+				"recv-empty", "recv-not-empty";
+			#mbox-cells = <0>;
+		};
+
+		usb4_1_acio: cio@501ac0000 {
+			compatible = "apple,t8112-usb4-acio", "apple,t8103-usb4-acio";
+			reg = <0x5 0x01ac0000 0x0 0xc000>,
+				<0x5 0x01080000 0x0 0x20000>;
+			reg-names = "rc", "sram";
+
+			mboxes = <&usb4_1_mbox>;
+			resets = <&cio_reset 1>;
+
+			power-domains = <&ps_atc1_cio>,
+					<&ps_atc1_cio_pcie>,
+					<&ps_atc1_cio_usb>;
+
+			pinctrl-0 = <&acio1_pins>;
+			pinctrl-names = "default";
+
+			#address-cells = <1>;
+			#size-cells = <1>;
+			ranges = <0x0 0x5 0x01000000 0x1000000>;
+			nonposted-mmio;
+
+			usb4_1_dart: iommu@a80000 {
+				compatible = "apple,t8110-dart";
+				reg = <0xa80000 0x4000>;
+				interrupt-parent = <&aic>;
+				interrupts = <AIC_IRQ 1146 IRQ_TYPE_LEVEL_HIGH>;
+				#iommu-cells = <1>;
+			};
+
+			usb4_1_nhi: nhi@f00000 {
+				reg = <0xf00000 0x100000>,
+					<0xdb0000 0x30004>;
+				reg-names = "nhi", "pdf";
+				compatible = "apple,t8112-usb4-nhi",
+					"apple,t8103-usb4-nhi";
+				interrupt-parent = <&aic>;
+				interrupts = <AIC_IRQ 1119 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1120 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1121 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1122 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1123 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1124 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1125 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1126 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1127 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1128 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1129 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1130 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1131 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1132 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1133 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1134 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1135 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1136 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1137 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1138 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1139 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1140 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1141 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 1142 IRQ_TYPE_LEVEL_HIGH>;
+				interrupt-names =
+					"txring0", "txring1", "txring2",
+					"txring3", "txring4", "txring5",
+					"txring6", "txring7", "txring8",
+					"txring9", "txring10", "txring11",
+					"rxring0", "rxring1", "rxring2",
+					"rxring3", "rxring4", "rxring5",
+					"rxring6", "rxring7", "rxring8",
+					"rxring9", "rxring10", "rxring11";
+				iommus = <&usb4_1_dart 1>;
+				/* To be filled by the loader */
+				apple,thunderbolt-drom = [00];
+			};
+		};
+
 		dwc3_1: usb@502280000 {
 			compatible = "apple,t8112-dwc3", "apple,t8103-dwc3";
 			reg = <0x5 0x02280000 0x0 0xcd00>, <0x5 0x0228cd00 0x0 0x3200>;

-- 
2.55.0

