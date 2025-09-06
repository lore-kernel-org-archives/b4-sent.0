From: Sven Peter <sven@kernel.org>
Date: Sat, 06 Sep 2025 15:43:35 +0000
Subject: [PATCH v2 22/22] arm64: dts: apple: t600x: Add Apple Type-C PHY
 and dwc3 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250906-atcphy-6-17-v2-22-52c348623ef6@kernel.org>
References: <20250906-atcphy-6-17-v2-0-52c348623ef6@kernel.org>
In-Reply-To: <20250906-atcphy-6-17-v2-0-52c348623ef6@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Frank Li <Frank.Li@nxp.com>, 
 Ran Wang <ran.wang_1@nxp.com>, Peter Chen <peter.chen@nxp.com>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, R <rqou@berkeley.edu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=25022; i=sven@kernel.org;
 h=from:subject:message-id; bh=Gz8VC2GdnmHU+sqgZZgFGx+yLwOX3aB1YhMwtYgCrWg=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8aesOV8orkmE2t2HE7M8xBvEu478k182/Knem5MGhkvr
 7rdbNnRUcrCIMbBICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZiIUhDDX/Fkh1sfTK6sumib
 eSKbJfRWxEPx2kNsjZwPZ0T5n95wxIGRYXNSbkvk+n39PX9z7v3c73swROyvxsN8xpd75Ew7xTf
 /YwMA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

Add all nodes and connections required to make USB3 work on M1 Pro, Max
and Ultra based Apple machines.

Co-developed-by: R <rqou@berkeley.edu>
Signed-off-by: R <rqou@berkeley.edu>
Signed-off-by: Janne Grunau <j@jannau.net>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/t6001.dtsi           |   1 +
 arch/arm64/boot/dts/apple/t6002-j375d.dts      | 197 +++++++++++++++++-
 arch/arm64/boot/dts/apple/t6002.dtsi           |   1 +
 arch/arm64/boot/dts/apple/t600x-dieX.dtsi      | 212 +++++++++++++++++++
 arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi | 236 +++++++++++++++++++++
 arch/arm64/boot/dts/apple/t600x-j375.dtsi      | 275 +++++++++++++++++++++++++
 6 files changed, 916 insertions(+), 6 deletions(-)

diff --git a/arch/arm64/boot/dts/apple/t6001.dtsi b/arch/arm64/boot/dts/apple/t6001.dtsi
index ffbe823b71bc8d9c0975524aa04efa9bf520a89e..6dcb71a1d65a8da82a512653a34ce6af3df8aee0 100644
--- a/arch/arm64/boot/dts/apple/t6001.dtsi
+++ b/arch/arm64/boot/dts/apple/t6001.dtsi
@@ -11,6 +11,7 @@
 #include <dt-bindings/interrupt-controller/apple-aic.h>
 #include <dt-bindings/interrupt-controller/irq.h>
 #include <dt-bindings/pinctrl/apple.h>
+#include <dt-bindings/phy/phy.h>
 #include <dt-bindings/spmi/spmi.h>
 
 #include "multi-die-cpp.h"
diff --git a/arch/arm64/boot/dts/apple/t6002-j375d.dts b/arch/arm64/boot/dts/apple/t6002-j375d.dts
index 3365429bdc8be90b63c8051822243d897854ab27..3b4715d5754c12848d418a71124b443c034af3e7 100644
--- a/arch/arm64/boot/dts/apple/t6002-j375d.dts
+++ b/arch/arm64/boot/dts/apple/t6002-j375d.dts
@@ -15,6 +15,11 @@
 / {
 	compatible = "apple,j375d", "apple,t6002", "apple,arm-platform";
 	model = "Apple Mac Studio (M1 Ultra, 2022)";
+
+	aliases {
+		atcphy4 = &atcphy0_die1;
+		atcphy5 = &atcphy1_die1;
+	};
 };
 
 /* USB Type C */
@@ -26,6 +31,30 @@ hpm4: usb-pd@39 {
 		interrupt-parent = <&pinctrl_ap>;
 		interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
 		interrupt-names = "irq";
+
+		typec4: connector {
+			compatible = "usb-c-connector";
+			label = "USB-C Front Right";
+			power-role = "dual";
+			data-role = "dual";
+
+			ports {
+				#address-cells = <1>;
+				#size-cells = <0>;
+				port@0 {
+					reg = <0>;
+					typec4_connector_hs: endpoint {
+						remote-endpoint = <&dwc3_0_die1_hs>;
+					};
+				};
+				port@1 {
+					reg = <1>;
+					typec4_connector_ss: endpoint {
+						remote-endpoint = <&atcphy0_die1_typec_lanes>;
+					};
+				};
+			};
+		};
 	};
 
 	/* front-left */
@@ -35,16 +64,172 @@ hpm5: usb-pd@3a {
 		interrupt-parent = <&pinctrl_ap>;
 		interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
 		interrupt-names = "irq";
+
+		typec5: connector {
+			compatible = "usb-c-connector";
+			label = "USB-C Front Left";
+			power-role = "dual";
+			data-role = "dual";
+
+			ports {
+				#address-cells = <1>;
+				#size-cells = <0>;
+				port@0 {
+					reg = <0>;
+					typec5_connector_hs: endpoint {
+						remote-endpoint = <&dwc3_1_die1_hs>;
+					};
+				};
+				port@1 {
+					reg = <1>;
+					typec5_connector_ss: endpoint {
+						remote-endpoint = <&atcphy1_die1_typec_lanes>;
+					};
+				};
+			};
+		};
 	};
 };
 
+/* USB controllers on die 1 */
+&dwc3_0_die1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			dwc3_0_die1_hs: endpoint {
+				remote-endpoint = <&typec4_connector_hs>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			dwc3_0_die1_ss: endpoint {
+				remote-endpoint = <&atcphy0_die1_usb3>;
+			};
+		};
+	};
+};
+
+&dwc3_1_die1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			dwc3_1_die1_hs: endpoint {
+				remote-endpoint = <&typec5_connector_hs>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			dwc3_1_die1_ss: endpoint {
+				remote-endpoint = <&atcphy1_die1_usb3>;
+			};
+		};
+	};
+};
+
+/* Type-C PHYs */
+&atcphy0_die1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			atcphy0_die1_typec_lanes: endpoint {
+				remote-endpoint = <&typec4_connector_ss>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			atcphy0_die1_usb3: endpoint {
+				remote-endpoint = <&dwc3_0_die1_ss>;
+			};
+		};
+	};
+};
+
+&atcphy1_die1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			atcphy1_die1_typec_lanes: endpoint {
+				remote-endpoint = <&typec5_connector_ss>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			atcphy1_die1_usb3: endpoint {
+				remote-endpoint = <&dwc3_1_die1_ss>;
+			};
+		};
+	};
+};
+
+
+/* Disable unused dwc3 instandes on the second die. */
+&dwc3_2_dart_0_die1 {
+	status = "disabled";
+};
+
+&dwc3_2_dart_1_die1 {
+	status = "disabled";
+};
+
+&dwc3_2_die1 {
+	status = "disabled";
+};
+
+&dwc3_3_dart_0_die1 {
+	status = "disabled";
+};
+
+&dwc3_3_dart_1_die1 {
+	status = "disabled";
+};
+
+&dwc3_3_die1 {
+	status = "disabled";
+};
+
+/* Disable unused ATC phy instandes on the second die. */
+&atcphy2_die1 {
+	status = "disabled";
+};
+
+&atcphy3_die1 {
+	status = "disabled";
+};
+
+/* Disable unused USB power-domains on the second die. */
+&ps_atc2_usb_aon_die1 {
+	status = "disabled";
+};
+
+&ps_atc2_usb_die1 {
+	status = "disabled";
+};
+
+&ps_atc3_usb_aon_die1 {
+	status = "disabled";
+};
+
+&ps_atc3_usb_die1 {
+	status = "disabled";
+};
+
 /* delete unused always-on power-domains on die 1 */
 
-/delete-node/ &ps_atc2_usb_aon_die1;
-/delete-node/ &ps_atc2_usb_die1;
-
-/delete-node/ &ps_atc3_usb_aon_die1;
-/delete-node/ &ps_atc3_usb_die1;
-
 /delete-node/ &ps_disp0_cpu0_die1;
 /delete-node/ &ps_disp0_fe_die1;
diff --git a/arch/arm64/boot/dts/apple/t6002.dtsi b/arch/arm64/boot/dts/apple/t6002.dtsi
index 8fb648836b538bbd9efdccd6cec5d08d868a0d39..a532e5401c4ec430d8ff649a92459c80e9b6bb2b 100644
--- a/arch/arm64/boot/dts/apple/t6002.dtsi
+++ b/arch/arm64/boot/dts/apple/t6002.dtsi
@@ -11,6 +11,7 @@
 #include <dt-bindings/interrupt-controller/apple-aic.h>
 #include <dt-bindings/interrupt-controller/irq.h>
 #include <dt-bindings/pinctrl/apple.h>
+#include <dt-bindings/phy/phy.h>
 #include <dt-bindings/spmi/spmi.h>
 
 #include "multi-die-cpp.h"
diff --git a/arch/arm64/boot/dts/apple/t600x-dieX.dtsi b/arch/arm64/boot/dts/apple/t600x-dieX.dtsi
index a32ff0c9d7b0c2ec720e9d4cf8e769da6431fbba..a282029475af874db7bf760017e1345ca982d94e 100644
--- a/arch/arm64/boot/dts/apple/t600x-dieX.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-dieX.dtsi
@@ -119,3 +119,215 @@ DIE_NODE(pinctrl_ap): pinctrl@39b028000 {
 		interrupt-controller;
 		#interrupt-cells = <2>;
 	};
+
+	DIE_NODE(dwc3_0_dart_0): iommu@702f00000 {
+		compatible = "apple,t6000-dart";
+		reg = <0x7 0x02f00000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1194 IRQ_TYPE_LEVEL_HIGH>;
+		power-domains = <&DIE_NODE(ps_atc0_usb)>;
+		#iommu-cells = <1>;
+	};
+
+	DIE_NODE(dwc3_0_dart_1): iommu@702f80000 {
+		compatible = "apple,t6000-dart";
+		reg = <0x7 0x02f80000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1194 IRQ_TYPE_LEVEL_HIGH>;
+		power-domains = <&DIE_NODE(ps_atc0_usb)>;
+		#iommu-cells = <1>;
+	};
+
+	DIE_NODE(dwc3_0): usb@702280000 {
+		compatible = "apple,t6000-dwc3", "apple,t8103-dwc3";
+		reg = <0x7 0x02280000 0x0 0xcd00>, <0x7 0x0228cd00 0x0 0x3200>;
+		reg-names = "dwc3-core", "dwc3-apple";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1190 IRQ_TYPE_LEVEL_HIGH>;
+		dr_mode = "otg";
+		usb-role-switch;
+		role-switch-default-mode = "host";
+		iommus = <&DIE_NODE(dwc3_0_dart_0) 0>,
+			<&DIE_NODE(dwc3_0_dart_1) 1>;
+		power-domains = <&DIE_NODE(ps_atc0_usb)>;
+		resets = <&DIE_NODE(atcphy0)>;
+		phys = <&DIE_NODE(atcphy0) PHY_TYPE_USB2>, <&DIE_NODE(atcphy0) PHY_TYPE_USB3>;
+		phy-names = "usb2-phy", "usb3-phy";
+	};
+
+	DIE_NODE(atcphy0): phy@703000000 {
+		compatible = "apple,t6000-atcphy", "apple,t8103-atcphy";
+		reg = <0x7 0x03000000 0x0 0x4c000>,
+			<0x7 0x03050000 0x0 0x8000>,
+			<0x7 0x00000000 0x0 0x4000>,
+			<0x7 0x02a90000 0x0 0x4000>,
+			<0x7 0x02a84000 0x0 0x4000>;
+		reg-names = "core", "lpdptx", "axi2af", "usb2phy",
+			"pipehandler";
+
+		#phy-cells = <1>;
+		#reset-cells = <0>;
+
+		orientation-switch;
+		mode-switch;
+		power-domains = <&DIE_NODE(ps_atc0_usb)>;
+	};
+
+	DIE_NODE(dwc3_1_dart_0): iommu@b02f00000 {
+		compatible = "apple,t6000-dart";
+		reg = <0xb 0x02f00000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1211 IRQ_TYPE_LEVEL_HIGH>;
+		power-domains = <&DIE_NODE(ps_atc1_usb)>;
+		#iommu-cells = <1>;
+	};
+
+	DIE_NODE(dwc3_1_dart_1): iommu@b02f80000 {
+		compatible = "apple,t6000-dart";
+		reg = <0xb 0x02f80000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1211 IRQ_TYPE_LEVEL_HIGH>;
+		power-domains = <&DIE_NODE(ps_atc1_usb)>;
+		#iommu-cells = <1>;
+	};
+
+	DIE_NODE(dwc3_1): usb@b02280000 {
+		compatible = "apple,t6000-dwc3", "apple,t8103-dwc3";
+		reg = <0xb 0x02280000 0x0 0xcd00>, <0xb 0x0228cd00 0x0 0x3200>;
+		reg-names = "dwc3-core", "dwc3-apple";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1207 IRQ_TYPE_LEVEL_HIGH>;
+		dr_mode = "otg";
+		usb-role-switch;
+		role-switch-default-mode = "host";
+		iommus = <&DIE_NODE(dwc3_1_dart_0) 0>,
+			<&DIE_NODE(dwc3_1_dart_1) 1>;
+		power-domains = <&DIE_NODE(ps_atc1_usb)>;
+		resets = <&DIE_NODE(atcphy1)>;
+		phys = <&DIE_NODE(atcphy1) PHY_TYPE_USB2>, <&DIE_NODE(atcphy1) PHY_TYPE_USB3>;
+		phy-names = "usb2-phy", "usb3-phy";
+	};
+
+	DIE_NODE(atcphy1): phy@b03000000 {
+		compatible = "apple,t6000-atcphy", "apple,t8103-atcphy";
+		reg = <0xb 0x03000000 0x0 0x4c000>,
+			<0xb 0x03050000 0x0 0x8000>,
+			<0xb 0x00000000 0x0 0x4000>,
+			<0xb 0x02a90000 0x0 0x4000>,
+			<0xb 0x02a84000 0x0 0x4000>;
+		reg-names = "core", "lpdptx", "axi2af", "usb2phy",
+			"pipehandler";
+
+		#phy-cells = <1>;
+		#reset-cells = <0>;
+
+		orientation-switch;
+		mode-switch;
+		power-domains = <&DIE_NODE(ps_atc1_usb)>;
+	};
+
+	DIE_NODE(dwc3_2_dart_0): iommu@f02f00000 {
+		compatible = "apple,t6000-dart";
+		reg = <0xf 0x02f00000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1228 IRQ_TYPE_LEVEL_HIGH>;
+		power-domains = <&DIE_NODE(ps_atc2_usb)>;
+		#iommu-cells = <1>;
+	};
+
+	DIE_NODE(dwc3_2_dart_1): iommu@f02f80000 {
+		compatible = "apple,t6000-dart";
+		reg = <0xf 0x02f80000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1228 IRQ_TYPE_LEVEL_HIGH>;
+		power-domains = <&DIE_NODE(ps_atc2_usb)>;
+		#iommu-cells = <1>;
+	};
+
+	DIE_NODE(dwc3_2): usb@f02280000 {
+		compatible = "apple,t6000-dwc3", "apple,t8103-dwc3";
+		reg = <0xf 0x02280000 0x0 0xcd00>, <0xf 0x0228cd00 0x0 0x3c00>;
+		reg-names = "dwc3-core", "dwc3-apple";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1224 IRQ_TYPE_LEVEL_HIGH>;
+		dr_mode = "otg";
+		usb-role-switch;
+		role-switch-default-mode = "host";
+		iommus = <&DIE_NODE(dwc3_2_dart_0) 0>,
+			<&DIE_NODE(dwc3_2_dart_1) 1>;
+		power-domains = <&DIE_NODE(ps_atc2_usb)>;
+		resets = <&DIE_NODE(atcphy2)>;
+		phys = <&DIE_NODE(atcphy2) PHY_TYPE_USB2>, <&DIE_NODE(atcphy2) PHY_TYPE_USB3>;
+		phy-names = "usb2-phy", "usb3-phy";
+	};
+
+	DIE_NODE(atcphy2): phy@f03000000 {
+		compatible = "apple,t6000-atcphy", "apple,t8103-atcphy";
+		reg = <0xf 0x03000000 0x0 0x4c000>,
+			<0xf 0x03050000 0x0 0x8000>,
+			<0xf 0x00000000 0x0 0x4000>,
+			<0xf 0x02a90000 0x0 0x4000>,
+			<0xf 0x02a84000 0x0 0x4000>;
+		reg-names = "core", "lpdptx", "axi2af", "usb2phy",
+			"pipehandler";
+
+		#phy-cells = <1>;
+		#reset-cells = <0>;
+
+		orientation-switch;
+		mode-switch;
+		power-domains = <&DIE_NODE(ps_atc2_usb)>;
+	};
+
+	DIE_NODE(dwc3_3_dart_0): iommu@1302f00000 {
+		compatible = "apple,t6000-dart";
+		reg = <0x13 0x02f00000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1245 IRQ_TYPE_LEVEL_HIGH>;
+		power-domains = <&DIE_NODE(ps_atc3_usb)>;
+		#iommu-cells = <1>;
+	};
+
+	DIE_NODE(dwc3_3_dart_1): iommu@1302f80000 {
+		compatible = "apple,t6000-dart";
+		reg = <0x13 0x02f80000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1245 IRQ_TYPE_LEVEL_HIGH>;
+		power-domains = <&DIE_NODE(ps_atc3_usb)>;
+		#iommu-cells = <1>;
+	};
+
+	DIE_NODE(dwc3_3): usb@1302280000 {
+		compatible = "apple,t6000-dwc3", "apple,t8103-dwc3";
+		reg = <0x13 0x02280000 0x0 0xcd00>, <0x13 0x0228cd00 0x0 0x3200>;
+		reg-names = "dwc3-core", "dwc3-apple";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1241 IRQ_TYPE_LEVEL_HIGH>;
+		dr_mode = "otg";
+		usb-role-switch;
+		role-switch-default-mode = "host";
+		iommus = <&DIE_NODE(dwc3_3_dart_0) 0>,
+			<&DIE_NODE(dwc3_3_dart_1) 1>;
+		power-domains = <&DIE_NODE(ps_atc3_usb)>;
+		resets = <&DIE_NODE(atcphy3)>;
+		phys = <&DIE_NODE(atcphy3) PHY_TYPE_USB2>, <&DIE_NODE(atcphy3) PHY_TYPE_USB3>;
+		phy-names = "usb2-phy", "usb3-phy";
+	};
+
+	DIE_NODE(atcphy3): phy@1303000000 {
+		compatible = "apple,t6000-atcphy", "apple,t8103-atcphy";
+		reg = <0x13 0x03000000 0x0 0x4c000>,
+			<0x13 0x03050000 0x0 0x8000>,
+			<0x13 0x00000000 0x0 0x4000>,
+			<0x13 0x02a90000 0x0 0x4000>,
+			<0x13 0x02a84000 0x0 0x4000>;
+		reg-names = "core", "lpdptx", "axi2af", "usb2phy",
+			"pipehandler";
+
+		#phy-cells = <1>;
+		#reset-cells = <0>;
+
+		orientation-switch;
+		mode-switch;
+		power-domains = <&DIE_NODE(ps_atc3_usb)>;
+	};
diff --git a/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi b/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
index 22ebc78e120bf8f0f71fd532e9dce4dcd117bbc6..13e654849eb3d637ac21479a3def8f8ddd731dd6 100644
--- a/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
@@ -13,6 +13,10 @@
 
 / {
 	aliases {
+		atcphy0 = &atcphy0;
+		atcphy1 = &atcphy1;
+		atcphy2 = &atcphy2;
+		atcphy3 = &atcphy3;
 		serial0 = &serial0;
 		wifi0 = &wifi0;
 	};
@@ -62,6 +66,31 @@ hpm0: usb-pd@38 {
 		interrupt-parent = <&pinctrl_ap>;
 		interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
 		interrupt-names = "irq";
+
+		typec0: connector {
+			compatible = "usb-c-connector";
+			label = "USB-C Left Rear";
+			power-role = "dual";
+			data-role = "dual";
+
+			ports {
+				#address-cells = <1>;
+				#size-cells = <0>;
+
+				port@0 {
+					reg = <0>;
+					typec0_connector_hs: endpoint {
+						remote-endpoint = <&dwc3_0_hs>;
+					};
+				};
+				port@1 {
+					reg = <1>;
+					typec0_connector_ss: endpoint {
+						remote-endpoint = <&atcphy0_typec_lanes>;
+					};
+				};
+			};
+		};
 	};
 
 	hpm1: usb-pd@3f {
@@ -70,6 +99,31 @@ hpm1: usb-pd@3f {
 		interrupt-parent = <&pinctrl_ap>;
 		interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
 		interrupt-names = "irq";
+
+		typec1: connector {
+			compatible = "usb-c-connector";
+			label = "USB-C Left Front";
+			power-role = "dual";
+			data-role = "dual";
+
+			ports {
+				#address-cells = <1>;
+				#size-cells = <0>;
+
+				port@0 {
+					reg = <0>;
+					typec1_connector_hs: endpoint {
+						remote-endpoint = <&dwc3_1_hs>;
+					};
+				};
+				port@1 {
+					reg = <1>;
+					typec1_connector_ss: endpoint {
+						remote-endpoint = <&atcphy1_typec_lanes>;
+					};
+				};
+			};
+		};
 	};
 
 	hpm2: usb-pd@3b {
@@ -78,6 +132,31 @@ hpm2: usb-pd@3b {
 		interrupt-parent = <&pinctrl_ap>;
 		interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
 		interrupt-names = "irq";
+
+		typec2: connector {
+			compatible = "usb-c-connector";
+			label = "USB-C Right";
+			power-role = "dual";
+			data-role = "dual";
+
+			ports {
+				#address-cells = <1>;
+				#size-cells = <0>;
+
+				port@0 {
+					reg = <0>;
+					typec2_connector_hs: endpoint {
+						remote-endpoint = <&dwc3_2_hs>;
+					};
+				};
+				port@1 {
+					reg = <1>;
+					typec2_connector_ss: endpoint {
+						remote-endpoint = <&atcphy2_typec_lanes>;
+					};
+				};
+			};
+		};
 	};
 
 	/* MagSafe port */
@@ -90,6 +169,163 @@ hpm5: usb-pd@3a {
 	};
 };
 
+/* USB controllers */
+&dwc3_0 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			dwc3_0_hs: endpoint {
+				remote-endpoint = <&typec0_connector_hs>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			dwc3_0_ss: endpoint {
+				remote-endpoint = <&atcphy0_usb3>;
+			};
+		};
+	};
+};
+
+&dwc3_1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			dwc3_1_hs: endpoint {
+				remote-endpoint = <&typec1_connector_hs>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			dwc3_1_ss: endpoint {
+				remote-endpoint = <&atcphy1_usb3>;
+			};
+		};
+	};
+};
+
+/* USB controllers */
+&dwc3_2 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			dwc3_2_hs: endpoint {
+				remote-endpoint = <&typec2_connector_hs>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			dwc3_2_ss: endpoint {
+				remote-endpoint = <&atcphy2_usb3>;
+			};
+		};
+	};
+};
+
+/* The 4th ATC Phy is connected to an internal DP to HDMI converter. */
+&dwc3_3_dart_0 {
+	status = "disabled";
+};
+
+&dwc3_3_dart_1 {
+	status = "disabled";
+};
+
+&dwc3_3 {
+	status = "disabled";
+};
+
+/* Type-C PHYs */
+&atcphy0 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			atcphy0_typec_lanes: endpoint {
+				remote-endpoint = <&typec0_connector_ss>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			atcphy0_usb3: endpoint {
+				remote-endpoint = <&dwc3_0_ss>;
+			};
+		};
+	};
+};
+
+&atcphy1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			atcphy1_typec_lanes: endpoint {
+				remote-endpoint = <&typec1_connector_ss>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			atcphy1_usb3: endpoint {
+				remote-endpoint = <&dwc3_1_ss>;
+			};
+		};
+	};
+};
+
+&atcphy2 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			atcphy2_typec_lanes: endpoint {
+				remote-endpoint = <&typec2_connector_ss>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			atcphy2_usb3: endpoint {
+				remote-endpoint = <&dwc3_2_ss>;
+			};
+		};
+	};
+};
+
+&atcphy3 {
+	/* Disable atcphy3 as long as DisplayPort is not supported. */
+	status = "disabled";
+};
+
+/*
+ * The ps_atcN_usb_aon power-domains are always-on to avoid resetting dwc3
+ * which reverts initialisation done by firmware.
+ * atc3 is used exclusively for the DP-to-HDMI converter so this is not
+ * necessary.
+ */
+&ps_atc3_usb_aon {
+	/delete-property/ apple,always-on;
+};
+
 &nco_clkref {
 	clock-frequency = <1068000000>;
 };
diff --git a/arch/arm64/boot/dts/apple/t600x-j375.dtsi b/arch/arm64/boot/dts/apple/t600x-j375.dtsi
index d5b985ad567936111ee5cccc9ca9fc23d01d9edf..ab49ad9e32f2798bd126d0794917c8f434f222de 100644
--- a/arch/arm64/boot/dts/apple/t600x-j375.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-j375.dtsi
@@ -11,6 +11,10 @@
 
 / {
 	aliases {
+		atcphy0 = &atcphy0;
+		atcphy1 = &atcphy1;
+		atcphy2 = &atcphy2;
+		atcphy3 = &atcphy3;
 		serial0 = &serial0;
 		wifi0 = &wifi0;
 	};
@@ -48,6 +52,31 @@ hpm0: usb-pd@38 {
 		interrupt-parent = <&pinctrl_ap>;
 		interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
 		interrupt-names = "irq";
+
+		typec0: connector {
+			compatible = "usb-c-connector";
+			label = "USB-C Back Left";
+			power-role = "dual";
+			data-role = "dual";
+
+			ports {
+				#address-cells = <1>;
+				#size-cells = <0>;
+
+				port@0 {
+					reg = <0>;
+					typec0_connector_hs: endpoint {
+						remote-endpoint = <&dwc3_0_hs>;
+					};
+				};
+				port@1 {
+					reg = <1>;
+					typec0_connector_ss: endpoint {
+						remote-endpoint = <&atcphy0_typec_lanes>;
+					};
+				};
+			};
+		};
 	};
 
 	hpm1: usb-pd@3f {
@@ -56,6 +85,31 @@ hpm1: usb-pd@3f {
 		interrupt-parent = <&pinctrl_ap>;
 		interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
 		interrupt-names = "irq";
+
+		typec1: connector {
+			compatible = "usb-c-connector";
+			label = "USB-C Back Left Middle";
+			power-role = "dual";
+			data-role = "dual";
+
+			ports {
+				#address-cells = <1>;
+				#size-cells = <0>;
+
+				port@0 {
+					reg = <0>;
+					typec1_connector_hs: endpoint {
+						remote-endpoint = <&dwc3_1_hs>;
+					};
+				};
+				port@1 {
+					reg = <1>;
+					typec1_connector_ss: endpoint {
+						remote-endpoint = <&atcphy1_typec_lanes>;
+					};
+				};
+			};
+		};
 	};
 
 	hpm2: usb-pd@3b {
@@ -64,6 +118,31 @@ hpm2: usb-pd@3b {
 		interrupt-parent = <&pinctrl_ap>;
 		interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
 		interrupt-names = "irq";
+
+		typec2: connector {
+			compatible = "usb-c-connector";
+			label = "USB-C Back Right Middle";
+			power-role = "dual";
+			data-role = "dual";
+
+			ports {
+				#address-cells = <1>;
+				#size-cells = <0>;
+
+				port@0 {
+					reg = <0>;
+					typec2_connector_hs: endpoint {
+						remote-endpoint = <&dwc3_2_hs>;
+					};
+				};
+				port@1 {
+					reg = <1>;
+					typec2_connector_ss: endpoint {
+						remote-endpoint = <&atcphy2_typec_lanes>;
+					};
+				};
+			};
+		};
 	};
 
 	hpm3: usb-pd@3c {
@@ -72,6 +151,202 @@ hpm3: usb-pd@3c {
 		interrupt-parent = <&pinctrl_ap>;
 		interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
 		interrupt-names = "irq";
+
+		typec3: connector {
+			compatible = "usb-c-connector";
+			label = "USB-C Back Right";
+			power-role = "dual";
+			data-role = "dual";
+
+			ports {
+				#address-cells = <1>;
+				#size-cells = <0>;
+
+				port@0 {
+					reg = <0>;
+					typec3_connector_hs: endpoint {
+						remote-endpoint = <&dwc3_3_hs>;
+					};
+				};
+				port@1 {
+					reg = <1>;
+					typec3_connector_ss: endpoint {
+						remote-endpoint = <&atcphy3_typec_lanes>;
+					};
+				};
+			};
+		};
+	};
+};
+
+/* USB controllers */
+&dwc3_0 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			dwc3_0_hs: endpoint {
+				remote-endpoint = <&typec0_connector_hs>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			dwc3_0_ss: endpoint {
+				remote-endpoint = <&atcphy0_usb3>;
+			};
+		};
+	};
+};
+
+&dwc3_1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			dwc3_1_hs: endpoint {
+				remote-endpoint = <&typec1_connector_hs>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			dwc3_1_ss: endpoint {
+				remote-endpoint = <&atcphy1_usb3>;
+			};
+		};
+	};
+};
+
+/* USB controllers */
+&dwc3_2 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			dwc3_2_hs: endpoint {
+				remote-endpoint = <&typec2_connector_hs>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			dwc3_2_ss: endpoint {
+				remote-endpoint = <&atcphy2_usb3>;
+			};
+		};
+	};
+};
+
+&dwc3_3 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			dwc3_3_hs: endpoint {
+				remote-endpoint = <&typec3_connector_hs>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			dwc3_3_ss: endpoint {
+				remote-endpoint = <&atcphy3_usb3>;
+			};
+		};
+	};
+};
+
+/* Type-C PHYs */
+&atcphy0 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			atcphy0_typec_lanes: endpoint {
+				remote-endpoint = <&typec0_connector_ss>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			atcphy0_usb3: endpoint {
+				remote-endpoint = <&dwc3_0_ss>;
+			};
+		};
+	};
+};
+
+&atcphy1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			atcphy1_typec_lanes: endpoint {
+				remote-endpoint = <&typec1_connector_ss>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			atcphy1_usb3: endpoint {
+				remote-endpoint = <&dwc3_1_ss>;
+			};
+		};
+	};
+};
+
+&atcphy2 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			atcphy2_typec_lanes: endpoint {
+				remote-endpoint = <&typec2_connector_ss>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			atcphy2_usb3: endpoint {
+				remote-endpoint = <&dwc3_2_ss>;
+			};
+		};
+	};
+};
+
+&atcphy3 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+			atcphy3_typec_lanes: endpoint {
+				remote-endpoint = <&typec3_connector_ss>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+			atcphy3_usb3: endpoint {
+				remote-endpoint = <&dwc3_3_ss>;
+			};
+		};
 	};
 };
 

-- 
2.34.1

