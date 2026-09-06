From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 20:36:43 +0200
Subject: [PATCH v2 20/22] arm64: dts: apple: t8103: Add USB4 ACIO and NHI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-apple-soc-tbt-v2-20-1f80085f93fb@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=10392; i=sven@kernel.org;
 h=from:subject:message-id; bh=+AIT3rGrnA1dnHtXc4jyApvNKaFqdKHWbR5KbldVPvw=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTWfm/ZV93LNvs0HqFM71LNvyntR8NjNWbJb7ukGuc
 WHnuxVSHaUsDGJcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJvFjPyHBq37QzaWve6jzT
 +rIt5MECSfvG5LiSCy/P3S22qBdjiuliZJgvvFw6ulL3dNkbjehWBk3+UqZN4RPUok8yrL77rZz
 lHB8A
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the ACIO host router, NHI, DART and M3 mailbox nodes for both Type-C
ports on t8103 and connect the host routers to the Type-C connectors.
Also describe the USB3 path from each host router to its DWC3 controller
so the NHI driver can create the required device link.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/t8103-jxxx.dtsi |  95 ++++++++++++++-
 arch/arm64/boot/dts/apple/t8103.dtsi      | 184 ++++++++++++++++++++++++++++++
 2 files changed, 277 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/apple/t8103-jxxx.dtsi b/arch/arm64/boot/dts/apple/t8103-jxxx.dtsi
index 686fb1dd215d..01c942b0a75b 100644
--- a/arch/arm64/boot/dts/apple/t8103-jxxx.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103-jxxx.dtsi
@@ -17,6 +17,10 @@ aliases {
 		wifi0 = &wifi0;
 		atcphy0 = &atcphy0;
 		atcphy1 = &atcphy1;
+		usb4-0-acio = &usb4_0_acio;
+		usb4-0-nhi = &usb4_0_nhi;
+		usb4-1-acio = &usb4_1_acio;
+		usb4-1-nhi = &usb4_1_nhi;
 	};
 
 	chosen {
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
 /*
  * Force the bus number assignments so that we can declare some of the
  * on-board devices and properties that are populated by the bootloader
diff --git a/arch/arm64/boot/dts/apple/t8103.dtsi b/arch/arm64/boot/dts/apple/t8103.dtsi
index 985dbd8e68ca..735591c72fde 100644
--- a/arch/arm64/boot/dts/apple/t8103.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103.dtsi
@@ -988,6 +988,14 @@ pinctrl_aop: pinctrl@24a820000 {
 				     <AIC_IRQ 272 IRQ_TYPE_LEVEL_HIGH>,
 				     <AIC_IRQ 273 IRQ_TYPE_LEVEL_HIGH>,
 				     <AIC_IRQ 274 IRQ_TYPE_LEVEL_HIGH>;
+
+			acio0_pins: acio0-pins {
+				pinmux = <APPLE_PINMUX(39, 1)>;
+			};
+
+			acio1_pins: acio1-pins {
+				pinmux = <APPLE_PINMUX(41, 1)>;
+			};
 		};
 
 		ans_mbox: mbox@277408000 {
@@ -1024,6 +1032,94 @@ nvme@27bcc0000 {
 			resets = <&ps_ans2>;
 		};
 
+		usb4_0_mbox: mailbox@381100000 {
+			compatible = "apple,t8103-m3-mailbox",
+				"apple,m3-mailbox-v2";
+			reg = <0x3 0x81100000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 812 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 813 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 814 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 815 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "send-empty", "send-not-empty",
+				"recv-empty", "recv-not-empty";
+			#mbox-cells = <0>;
+		};
+
+		usb4_0_acio: cio@381ac0000 {
+			compatible = "apple,t8103-usb4-acio";
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
+				compatible = "apple,t8103-dart";
+				reg = <0xa80000 0x4000>;
+				interrupt-parent = <&aic>;
+				interrupts = <AIC_IRQ 810 IRQ_TYPE_LEVEL_HIGH>;
+				#iommu-cells = <1>;
+			};
+
+			usb4_0_nhi: nhi@f00000 {
+				reg = <0xf00000 0x100000>,
+					<0xdb0000 0x30004>;
+				reg-names = "nhi", "pdf";
+				compatible = "apple,t8103-usb4-nhi";
+				interrupt-parent = <&aic>;
+				interrupts = <AIC_IRQ 783 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 784 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 785 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 786 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 787 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 788 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 789 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 790 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 791 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 792 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 793 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 794 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 795 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 796 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 797 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 798 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 799 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 800 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 801 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 802 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 803 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 804 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 805 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 806 IRQ_TYPE_LEVEL_HIGH>;
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
 			compatible = "apple,t8103-dwc3";
 			reg = <0x3 0x82280000 0x0 0xcd00>, <0x3 0x8228cd00 0x0 0x3200>;
@@ -1076,6 +1172,94 @@ atcphy0: phy@383000000 {
 			power-domains = <&ps_atc0_usb>;
 		};
 
+		usb4_1_mbox: mailbox@501100000 {
+			compatible = "apple,t8103-m3-mailbox",
+				"apple,m3-mailbox-v2";
+			reg = <0x5 0x01100000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 892 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 893 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 894 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ 895 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "send-empty", "send-not-empty",
+				"recv-empty", "recv-not-empty";
+			#mbox-cells = <0>;
+		};
+
+		usb4_1_acio: cio@501ac0000 {
+			compatible = "apple,t8103-usb4-acio";
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
+				compatible = "apple,t8103-dart";
+				reg = <0xa80000 0x4000>;
+				interrupt-parent = <&aic>;
+				interrupts = <AIC_IRQ 890 IRQ_TYPE_LEVEL_HIGH>;
+				#iommu-cells = <1>;
+			};
+
+			usb4_1_nhi: nhi@f00000 {
+				reg = <0xf00000 0x100000>,
+					<0xdb0000 0x30004>;
+				reg-names = "nhi", "pdf";
+				compatible = "apple,t8103-usb4-nhi";
+				interrupt-parent = <&aic>;
+				interrupts = <AIC_IRQ 863 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 864 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 865 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 866 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 867 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 868 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 869 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 870 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 871 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 872 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 873 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 874 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 875 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 876 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 877 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 878 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 879 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 880 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 881 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 882 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 883 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 884 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 885 IRQ_TYPE_LEVEL_HIGH>,
+					<AIC_IRQ 886 IRQ_TYPE_LEVEL_HIGH>;
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
 			compatible = "apple,t8103-dwc3";
 			reg = <0x5 0x02280000 0x0 0xcd00>, <0x5 0x0228cd00 0x0 0x3200>;

-- 
2.55.0

