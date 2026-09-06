From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 20:36:45 +0200
Subject: [PATCH v2 22/22] arm64: dts: apple: t60xx: Add USB4 ACIO and NHI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-apple-soc-tbt-v2-22-1f80085f93fb@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=53817; i=sven@kernel.org;
 h=from:subject:message-id; bh=X87Bo5nHz82LjOFPhHoCnms1F5YSIAAbuWhYyJ3Rjmg=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTeclTv6ZmN6fc6LP4qFKI4vHI0aT2ZeSGF3PdLYfv
 vzhmN/LjlIWBjEuBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBEYpkYGY60F+pc9OZc6fTD
 TPzw+1thipJvHvnezjMOsXY8PyH001GGf9o9e59nS9RskQpsnmkWsflXVkGeEceN1Kwy9XON653
 9uQA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the ACIO host router, NHI, DART and mailbox nodes for the four ATC
instances on each t600x and t602x die and connect the host routers to
the Type-C connectors on the MacBook Pro (j314/j316 and j414/j416), Mac
Studio (j375 and j475), Mac mini (j474) and Mac Pro (j180d) boards.

Also describe the USB3 path from each host router to its DWC3 controller
so the NHI driver can create the required device link.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/t6002-j375d.dts      | 101 ++++++-
 arch/arm64/boot/dts/apple/t600x-dieX.dtsi      | 376 +++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi | 158 ++++++++++-
 arch/arm64/boot/dts/apple/t600x-j375.dtsi      | 205 +++++++++++++-
 arch/arm64/boot/dts/apple/t6022-j180d.dts      | 304 +++++++++++++++++++-
 arch/arm64/boot/dts/apple/t6022-j475d.dts      |  10 +
 arch/arm64/boot/dts/apple/t6022-jxxxd.dtsi     |  91 +++++-
 arch/arm64/boot/dts/apple/t602x-dieX.dtsi      | 376 +++++++++++++++++++++++++
 8 files changed, 1604 insertions(+), 17 deletions(-)

diff --git a/arch/arm64/boot/dts/apple/t6002-j375d.dts b/arch/arm64/boot/dts/apple/t6002-j375d.dts
index e6eb6b6c386d..93f07df1c006 100644
--- a/arch/arm64/boot/dts/apple/t6002-j375d.dts
+++ b/arch/arm64/boot/dts/apple/t6002-j375d.dts
@@ -18,6 +18,10 @@ / {
 	aliases {
 		atcphy4 = &atcphy0_die1;
 		atcphy5 = &atcphy1_die1;
+		usb4-4-acio = &usb4_0_acio_die1;
+		usb4-4-nhi = &usb4_0_nhi_die1;
+		usb4-5-acio = &usb4_1_acio_die1;
+		usb4-5-nhi = &usb4_1_nhi_die1;
 	};
 };
 
@@ -52,6 +56,13 @@ typec4_connector_ss: endpoint {
 						remote-endpoint = <&atcphy4_typec_lanes>;
 					};
 				};
+
+				port@2 {
+					reg = <2>;
+					typec4_con_tbt: endpoint {
+						remote-endpoint = <&usb4_4_acio_tbt>;
+					};
+				};
 			};
 		};
 	};
@@ -85,6 +96,13 @@ typec5_connector_ss: endpoint {
 						remote-endpoint = <&atcphy5_typec_lanes>;
 					};
 				};
+
+				port@2 {
+					reg = <2>;
+					typec5_con_tbt: endpoint {
+						remote-endpoint = <&usb4_5_acio_tbt>;
+					};
+				};
 			};
 		};
 	};
@@ -112,10 +130,19 @@ dwc3_4_hs: endpoint {
 		};
 
 		port@1 {
+			#address-cells = <1>;
+			#size-cells = <0>;
 			reg = <1>;
-			dwc3_4_ss: endpoint {
+
+			dwc3_4_ss: endpoint@0 {
+				reg = <0>;
 				remote-endpoint = <&atcphy4_usb3>;
 			};
+
+			dwc3_4_usb4: endpoint@1 {
+				reg = <1>;
+				remote-endpoint = <&usb4_4_acio_usb3>;
+			};
 		};
 	};
 };
@@ -133,10 +160,19 @@ dwc3_5_hs: endpoint {
 		};
 
 		port@1 {
+			#address-cells = <1>;
+			#size-cells = <0>;
 			reg = <1>;
-			dwc3_5_ss: endpoint {
+
+			dwc3_5_ss: endpoint@0 {
+				reg = <0>;
 				remote-endpoint = <&atcphy5_usb3>;
 			};
+
+			dwc3_5_usb4: endpoint@1 {
+				reg = <1>;
+				remote-endpoint = <&usb4_5_acio_usb3>;
+			};
 		};
 	};
 };
@@ -186,8 +222,69 @@ atcphy5_usb3: endpoint {
 
 #include "hwmon-fan-dual.dtsi"
 
+/* USB4 on die 1 */
+&usb4_0_acio_die1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		/* 1: USB4 port */
+		port@1 {
+			reg = <1>;
+			usb4_4_acio_tbt: endpoint {
+				remote-endpoint = <&typec4_con_tbt>;
+			};
+		};
+
+		/* 2: USB4 lane 1 adapter */
+		/* 3: PCIe */
+		port@4 {
+			reg = <4>;
+			usb4_4_acio_usb3: endpoint {
+				remote-endpoint = <&dwc3_4_usb4>;
+			};
+		};
+
+		/* 5: DP0 */
+		/* 6: DP1 */
+	};
+};
+
+&usb4_1_acio_die1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		/* 1: USB4 port */
+		port@1 {
+			reg = <1>;
+			usb4_5_acio_tbt: endpoint {
+				remote-endpoint = <&typec5_con_tbt>;
+			};
+		};
+
+		/* 2: USB4 lane 1 adapter */
+		/* 3: PCIe */
+		port@4 {
+			reg = <4>;
+			usb4_5_acio_usb3: endpoint {
+				remote-endpoint = <&dwc3_5_usb4>;
+			};
+		};
+
+		/* 5: DP0 */
+		/* 6: DP1 */
+	};
+};
+
 /* delete unused USB nodes on die 1 */
 
+/delete-node/ &usb4_2_acio_die1;
+/delete-node/ &usb4_2_mbox_die1;
+
+/delete-node/ &usb4_3_acio_die1;
+/delete-node/ &usb4_3_mbox_die1;
+
 /delete-node/ &dwc3_2_dart_0_die1;
 /delete-node/ &dwc3_2_dart_1_die1;
 /delete-node/ &dwc3_2_die1;
diff --git a/arch/arm64/boot/dts/apple/t600x-dieX.dtsi b/arch/arm64/boot/dts/apple/t600x-dieX.dtsi
index 5e163d756a7f..b7ef3321b57d 100644
--- a/arch/arm64/boot/dts/apple/t600x-dieX.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-dieX.dtsi
@@ -99,6 +99,22 @@ DIE_NODE(pinctrl_aop): pinctrl@293820000 {
 				<AIC_IRQ DIE_NO 571 IRQ_TYPE_LEVEL_HIGH>,
 				<AIC_IRQ DIE_NO 572 IRQ_TYPE_LEVEL_HIGH>,
 				<AIC_IRQ DIE_NO 573 IRQ_TYPE_LEVEL_HIGH>;
+
+		DIE_NODE(acio0_pins): acio0-pins {
+			pinmux = <APPLE_PINMUX(39, 1)>;
+		};
+
+		DIE_NODE(acio1_pins): acio1-pins {
+			pinmux = <APPLE_PINMUX(41, 1)>;
+		};
+
+		DIE_NODE(acio2_pins): acio2-pins {
+			pinmux = <APPLE_PINMUX(43, 1)>;
+		};
+
+		DIE_NODE(acio3_pins): acio3-pins {
+			pinmux = <APPLE_PINMUX(45, 1)>;
+		};
 	};
 
 	DIE_NODE(pinctrl_ap): pinctrl@39b028000 {
@@ -126,6 +142,96 @@ DIE_NODE(pinctrl_ap): pinctrl@39b028000 {
 		#interrupt-cells = <2>;
 	};
 
+	DIE_NODE(usb4_0_mbox): mailbox@701100000 {
+		compatible = "apple,t6000-m3-mailbox",
+			"apple,m3-mailbox-v2";
+		reg = <0x7 0x01100000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1311 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 1312 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 1313 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 1314 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "send-empty", "send-not-empty",
+			"recv-empty", "recv-not-empty";
+		#mbox-cells = <0>;
+	};
+
+	DIE_NODE(usb4_0_acio): cio@701ac0000 {
+		compatible = "apple,t6000-usb4-acio", "apple,t8103-usb4-acio";
+		reg = <0x7 0x01ac0000 0x0 0xc000>,
+			<0x7 0x01080000 0x0 0x20000>;
+		reg-names = "rc", "sram";
+
+		mboxes = <&DIE_NODE(usb4_0_mbox)>;
+		resets = <&DIE_NODE(cio_reset) 0>;
+
+		power-domains = <&DIE_NODE(ps_atc0_cio)>,
+				<&DIE_NODE(ps_atc0_cio_pcie)>,
+				<&DIE_NODE(ps_atc0_cio_usb)>;
+
+		pinctrl-0 = <&DIE_NODE(acio0_pins)>;
+		pinctrl-names = "default";
+
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges = <0x0 0x7 0x01000000 0x1000000>;
+		nonposted-mmio;
+
+		DIE_NODE(usb4_0_dart): iommu@a80000 {
+			compatible = "apple,t6000-dart";
+			reg = <0xa80000 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1309 IRQ_TYPE_LEVEL_HIGH>;
+			#iommu-cells = <1>;
+		};
+
+		DIE_NODE(usb4_0_nhi): nhi@f00000 {
+			reg = <0xf00000 0x100000>,
+				<0xdb0000 0x30004>;
+			reg-names = "nhi", "pdf";
+			compatible = "apple,t6000-usb4-nhi",
+				"apple,t8103-usb4-nhi";
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1282 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1283 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1284 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1285 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1286 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1287 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1288 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1289 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1290 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1291 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1292 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1293 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1294 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1295 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1296 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1297 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1298 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1299 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1300 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1301 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1302 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1303 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1304 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1305 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names =
+				"txring0", "txring1", "txring2",
+				"txring3", "txring4", "txring5",
+				"txring6", "txring7", "txring8",
+				"txring9", "txring10", "txring11",
+				"rxring0", "rxring1", "rxring2",
+				"rxring3", "rxring4", "rxring5",
+				"rxring6", "rxring7", "rxring8",
+				"rxring9", "rxring10", "rxring11";
+			iommus = <&DIE_NODE(usb4_0_dart) 1>,
+				 <&DIE_NODE(usb4_0_dart) 2>;
+			/* To be filled by the loader */
+			apple,thunderbolt-drom = [00];
+		};
+	};
+
 	DIE_NODE(dwc3_0): usb@702280000 {
 		compatible = "apple,t6000-dwc3", "apple,t8103-dwc3";
 		reg = <0x7 0x02280000 0x0 0xcd00>, <0x7 0x0228cd00 0x0 0x3200>;
@@ -179,6 +285,96 @@ DIE_NODE(atcphy0): phy@703000000 {
 		power-domains = <&DIE_NODE(ps_atc0_usb)>;
 	};
 
+	DIE_NODE(usb4_1_mbox): mailbox@b01100000 {
+		compatible = "apple,t6000-m3-mailbox",
+			"apple,m3-mailbox-v2";
+		reg = <0xb 0x01100000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1359 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 1360 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 1361 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 1362 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "send-empty", "send-not-empty",
+			"recv-empty", "recv-not-empty";
+		#mbox-cells = <0>;
+	};
+
+	DIE_NODE(usb4_1_acio): cio@b01ac0000 {
+		compatible = "apple,t6000-usb4-acio", "apple,t8103-usb4-acio";
+		reg = <0xb 0x01ac0000 0x0 0xc000>,
+			<0xb 0x01080000 0x0 0x20000>;
+		reg-names = "rc", "sram";
+
+		mboxes = <&DIE_NODE(usb4_1_mbox)>;
+		resets = <&DIE_NODE(cio_reset) 1>;
+
+		power-domains = <&DIE_NODE(ps_atc1_cio)>,
+				<&DIE_NODE(ps_atc1_cio_pcie)>,
+				<&DIE_NODE(ps_atc1_cio_usb)>;
+
+		pinctrl-0 = <&DIE_NODE(acio1_pins)>;
+		pinctrl-names = "default";
+
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges = <0x0 0xb 0x01000000 0x1000000>;
+		nonposted-mmio;
+
+		DIE_NODE(usb4_1_dart): iommu@a80000 {
+			compatible = "apple,t6000-dart";
+			reg = <0xa80000 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1357 IRQ_TYPE_LEVEL_HIGH>;
+			#iommu-cells = <1>;
+		};
+
+		DIE_NODE(usb4_1_nhi): nhi@f00000 {
+			reg = <0xf00000 0x100000>,
+				<0xdb0000 0x30004>;
+			reg-names = "nhi", "pdf";
+			compatible = "apple,t6000-usb4-nhi",
+				"apple,t8103-usb4-nhi";
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1330 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1331 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1332 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1333 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1334 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1335 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1336 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1337 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1338 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1339 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1340 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1341 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1342 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1343 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1344 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1345 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1346 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1347 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1348 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1349 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1350 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1351 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1352 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1353 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names =
+				"txring0", "txring1", "txring2",
+				"txring3", "txring4", "txring5",
+				"txring6", "txring7", "txring8",
+				"txring9", "txring10", "txring11",
+				"rxring0", "rxring1", "rxring2",
+				"rxring3", "rxring4", "rxring5",
+				"rxring6", "rxring7", "rxring8",
+				"rxring9", "rxring10", "rxring11";
+			iommus = <&DIE_NODE(usb4_1_dart) 1>,
+				 <&DIE_NODE(usb4_1_dart) 2>;
+			/* To be filled by the loader */
+			apple,thunderbolt-drom = [00];
+		};
+	};
+
 	DIE_NODE(dwc3_1): usb@b02280000 {
 		compatible = "apple,t6000-dwc3", "apple,t8103-dwc3";
 		reg = <0xb 0x02280000 0x0 0xcd00>, <0xb 0x0228cd00 0x0 0x3200>;
@@ -232,6 +428,96 @@ DIE_NODE(atcphy1): phy@b03000000 {
 		power-domains = <&DIE_NODE(ps_atc1_usb)>;
 	};
 
+	DIE_NODE(usb4_2_mbox): mailbox@f01100000 {
+		compatible = "apple,t6000-m3-mailbox",
+			"apple,m3-mailbox-v2";
+		reg = <0xf 0x01100000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1407 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 1408 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 1409 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 1410 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "send-empty", "send-not-empty",
+			"recv-empty", "recv-not-empty";
+		#mbox-cells = <0>;
+	};
+
+	DIE_NODE(usb4_2_acio): cio@f01ac0000 {
+		compatible = "apple,t6000-usb4-acio", "apple,t8103-usb4-acio";
+		reg = <0xf 0x01ac0000 0x0 0xc000>,
+			<0xf 0x01080000 0x0 0x20000>;
+		reg-names = "rc", "sram";
+
+		mboxes = <&DIE_NODE(usb4_2_mbox)>;
+		resets = <&DIE_NODE(cio_reset) 2>;
+
+		power-domains = <&DIE_NODE(ps_atc2_cio)>,
+				<&DIE_NODE(ps_atc2_cio_pcie)>,
+				<&DIE_NODE(ps_atc2_cio_usb)>;
+
+		pinctrl-0 = <&DIE_NODE(acio2_pins)>;
+		pinctrl-names = "default";
+
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges = <0x0 0xf 0x01000000 0x1000000>;
+		nonposted-mmio;
+
+		DIE_NODE(usb4_2_dart): iommu@a80000 {
+			compatible = "apple,t6000-dart";
+			reg = <0xa80000 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1405 IRQ_TYPE_LEVEL_HIGH>;
+			#iommu-cells = <1>;
+		};
+
+		DIE_NODE(usb4_2_nhi): nhi@f00000 {
+			reg = <0xf00000 0x100000>,
+				<0xdb0000 0x30004>;
+			reg-names = "nhi", "pdf";
+			compatible = "apple,t6000-usb4-nhi",
+				"apple,t8103-usb4-nhi";
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1378 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1379 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1380 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1381 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1382 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1383 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1384 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1385 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1386 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1387 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1388 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1389 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1390 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1391 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1392 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1393 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1394 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1395 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1396 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1397 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1398 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1399 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1400 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1401 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names =
+				"txring0", "txring1", "txring2",
+				"txring3", "txring4", "txring5",
+				"txring6", "txring7", "txring8",
+				"txring9", "txring10", "txring11",
+				"rxring0", "rxring1", "rxring2",
+				"rxring3", "rxring4", "rxring5",
+				"rxring6", "rxring7", "rxring8",
+				"rxring9", "rxring10", "rxring11";
+			iommus = <&DIE_NODE(usb4_2_dart) 1>,
+				 <&DIE_NODE(usb4_2_dart) 2>;
+			/* To be filled by the loader */
+			apple,thunderbolt-drom = [00];
+		};
+	};
+
 	DIE_NODE(dwc3_2): usb@f02280000 {
 		compatible = "apple,t6000-dwc3", "apple,t8103-dwc3";
 		reg = <0xf 0x02280000 0x0 0xcd00>, <0xf 0x0228cd00 0x0 0x3200>;
@@ -285,6 +571,96 @@ DIE_NODE(atcphy2): phy@f03000000 {
 		power-domains = <&DIE_NODE(ps_atc2_usb)>;
 	};
 
+	DIE_NODE(usb4_3_mbox): mailbox@1301100000 {
+		compatible = "apple,t6000-m3-mailbox",
+			"apple,m3-mailbox-v2";
+		reg = <0x13 0x01100000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 1455 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 1456 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 1457 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 1458 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "send-empty", "send-not-empty",
+			"recv-empty", "recv-not-empty";
+		#mbox-cells = <0>;
+	};
+
+	DIE_NODE(usb4_3_acio): cio@1301ac0000 {
+		compatible = "apple,t6000-usb4-acio", "apple,t8103-usb4-acio";
+		reg = <0x13 0x01ac0000 0x0 0xc000>,
+			<0x13 0x01080000 0x0 0x20000>;
+		reg-names = "rc", "sram";
+
+		mboxes = <&DIE_NODE(usb4_3_mbox)>;
+		resets = <&DIE_NODE(cio_reset) 3>;
+
+		power-domains = <&DIE_NODE(ps_atc3_cio)>,
+				<&DIE_NODE(ps_atc3_cio_pcie)>,
+				<&DIE_NODE(ps_atc3_cio_usb)>;
+
+		pinctrl-0 = <&DIE_NODE(acio3_pins)>;
+		pinctrl-names = "default";
+
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges = <0x0 0x13 0x01000000 0x1000000>;
+		nonposted-mmio;
+
+		DIE_NODE(usb4_3_dart): iommu@a80000 {
+			compatible = "apple,t6000-dart";
+			reg = <0xa80000 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1453 IRQ_TYPE_LEVEL_HIGH>;
+			#iommu-cells = <1>;
+		};
+
+		DIE_NODE(usb4_3_nhi): nhi@f00000 {
+			reg = <0xf00000 0x100000>,
+				<0xdb0000 0x30004>;
+			reg-names = "nhi", "pdf";
+			compatible = "apple,t6000-usb4-nhi",
+				"apple,t8103-usb4-nhi";
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1426 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1427 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1428 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1429 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1430 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1431 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1432 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1433 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1434 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1435 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1436 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1437 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1438 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1439 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1440 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1441 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1442 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1443 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1444 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1445 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1446 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1447 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1448 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1449 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names =
+				"txring0", "txring1", "txring2",
+				"txring3", "txring4", "txring5",
+				"txring6", "txring7", "txring8",
+				"txring9", "txring10", "txring11",
+				"rxring0", "rxring1", "rxring2",
+				"rxring3", "rxring4", "rxring5",
+				"rxring6", "rxring7", "rxring8",
+				"rxring9", "rxring10", "rxring11";
+			iommus = <&DIE_NODE(usb4_3_dart) 1>,
+				 <&DIE_NODE(usb4_3_dart) 2>;
+			/* To be filled by the loader */
+			apple,thunderbolt-drom = [00];
+		};
+	};
+
 	DIE_NODE(dwc3_3): usb@1302280000 {
 		compatible = "apple,t6000-dwc3", "apple,t8103-dwc3";
 		reg = <0x13 0x02280000 0x0 0xcd00>, <0x13 0x0228cd00 0x0 0x3200>;
diff --git a/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi b/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
index caded1636f3d..8287e2c0eb84 100644
--- a/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
@@ -21,6 +21,12 @@ aliases {
 		atcphy3 = &atcphy3;
 		bluetooth0 = &bluetooth0;
 		serial0 = &serial0;
+		usb4-0-acio = &usb4_0_acio;
+		usb4-0-nhi = &usb4_0_nhi;
+		usb4-1-acio = &usb4_1_acio;
+		usb4-1-nhi = &usb4_1_nhi;
+		usb4-2-acio = &usb4_2_acio;
+		usb4-2-nhi = &usb4_2_nhi;
 		wifi0 = &wifi0;
 	};
 
@@ -222,10 +228,19 @@ dwc3_0_hs: endpoint {
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
@@ -243,10 +258,19 @@ dwc3_1_hs: endpoint {
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
@@ -264,10 +288,19 @@ dwc3_2_hs: endpoint {
 		};
 
 		port@1 {
+			#address-cells = <1>;
+			#size-cells = <0>;
 			reg = <1>;
-			dwc3_2_ss: endpoint {
+
+			dwc3_2_ss: endpoint@0 {
+				reg = <0>;
 				remote-endpoint = <&atcphy2_usb3>;
 			};
+
+			dwc3_2_usb4: endpoint@1 {
+				reg = <1>;
+				remote-endpoint = <&usb4_2_acio_usb3>;
+			};
 		};
 	};
 };
@@ -366,6 +399,125 @@ &atcphy3 {
 	status = "disabled";
 };
 
+&typec0 {
+	ports {
+		port@2 {
+			reg = <2>;
+			typec0_con_tbt: endpoint {
+				remote-endpoint = <&usb4_0_acio_tbt>;
+			};
+		};
+	};
+};
+
+&typec1 {
+	ports {
+		port@2 {
+			reg = <2>;
+			typec1_con_tbt: endpoint {
+				remote-endpoint = <&usb4_1_acio_tbt>;
+			};
+		};
+	};
+};
+
+&typec2 {
+	ports {
+		port@2 {
+			reg = <2>;
+			typec2_con_tbt: endpoint {
+				remote-endpoint = <&usb4_2_acio_tbt>;
+			};
+		};
+	};
+};
+
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
+&usb4_2_acio {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		/* 1: USB4 port */
+		port@1 {
+			reg = <1>;
+			usb4_2_acio_tbt: endpoint {
+				remote-endpoint = <&typec2_con_tbt>;
+			};
+		};
+
+		/* 2: USB4 lane 1 adapter */
+		/* 3: PCIe */
+		port@4 {
+			reg = <4>;
+			usb4_2_acio_usb3: endpoint {
+				remote-endpoint = <&dwc3_2_usb4>;
+			};
+		};
+
+		/* 5: DP0 */
+		/* 6: DP1 */
+	};
+};
+
+/* ATC3 is used for DP-to-HDMI only and has no USB4 host router */
+/delete-node/ &usb4_3_acio;
+/delete-node/ &usb4_3_mbox;
+
 #include "spi1-nvram.dtsi"
 #include "hwmon-laptop.dtsi"
 #include "hwmon-fan-dual.dtsi"
diff --git a/arch/arm64/boot/dts/apple/t600x-j375.dtsi b/arch/arm64/boot/dts/apple/t600x-j375.dtsi
index 8a1494949e4c..18348192d143 100644
--- a/arch/arm64/boot/dts/apple/t600x-j375.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-j375.dtsi
@@ -20,6 +20,14 @@ aliases {
 		bluetooth0 = &bluetooth0;
 		ethernet0 = &ethernet0;
 		serial0 = &serial0;
+		usb4-0-acio = &usb4_0_acio;
+		usb4-0-nhi = &usb4_0_nhi;
+		usb4-1-acio = &usb4_1_acio;
+		usb4-1-nhi = &usb4_1_nhi;
+		usb4-2-acio = &usb4_2_acio;
+		usb4-2-nhi = &usb4_2_nhi;
+		usb4-3-acio = &usb4_3_acio;
+		usb4-3-nhi = &usb4_3_nhi;
 		wifi0 = &wifi0;
 	};
 
@@ -193,10 +201,19 @@ dwc3_0_hs: endpoint {
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
@@ -214,10 +231,19 @@ dwc3_1_hs: endpoint {
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
@@ -235,10 +261,19 @@ dwc3_2_hs: endpoint {
 		};
 
 		port@1 {
+			#address-cells = <1>;
+			#size-cells = <0>;
 			reg = <1>;
-			dwc3_2_ss: endpoint {
+
+			dwc3_2_ss: endpoint@0 {
+				reg = <0>;
 				remote-endpoint = <&atcphy2_usb3>;
 			};
+
+			dwc3_2_usb4: endpoint@1 {
+				reg = <1>;
+				remote-endpoint = <&usb4_2_acio_usb3>;
+			};
 		};
 	};
 };
@@ -256,10 +291,19 @@ dwc3_3_hs: endpoint {
 		};
 
 		port@1 {
+			#address-cells = <1>;
+			#size-cells = <0>;
 			reg = <1>;
-			dwc3_3_ss: endpoint {
+
+			dwc3_3_ss: endpoint@0 {
+				reg = <0>;
 				remote-endpoint = <&atcphy3_usb3>;
 			};
+
+			dwc3_3_usb4: endpoint@1 {
+				reg = <1>;
+				remote-endpoint = <&usb4_3_acio_usb3>;
+			};
 		};
 	};
 };
@@ -410,4 +454,157 @@ &pcie0_dart_3 {
 	status = "okay";
 };
 
+&typec0 {
+	ports {
+		port@2 {
+			reg = <2>;
+			typec0_con_tbt: endpoint {
+				remote-endpoint = <&usb4_0_acio_tbt>;
+			};
+		};
+	};
+};
+
+&typec1 {
+	ports {
+		port@2 {
+			reg = <2>;
+			typec1_con_tbt: endpoint {
+				remote-endpoint = <&usb4_1_acio_tbt>;
+			};
+		};
+	};
+};
+
+&typec2 {
+	ports {
+		port@2 {
+			reg = <2>;
+			typec2_con_tbt: endpoint {
+				remote-endpoint = <&usb4_2_acio_tbt>;
+			};
+		};
+	};
+};
+
+&typec3 {
+	ports {
+		port@2 {
+			reg = <2>;
+			typec3_con_tbt: endpoint {
+				remote-endpoint = <&usb4_3_acio_tbt>;
+			};
+		};
+	};
+};
+
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
+&usb4_2_acio {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		/* 1: USB4 port */
+		port@1 {
+			reg = <1>;
+			usb4_2_acio_tbt: endpoint {
+				remote-endpoint = <&typec2_con_tbt>;
+			};
+		};
+
+		/* 2: USB4 lane 1 adapter */
+		/* 3: PCIe */
+		port@4 {
+			reg = <4>;
+			usb4_2_acio_usb3: endpoint {
+				remote-endpoint = <&dwc3_2_usb4>;
+			};
+		};
+
+		/* 5: DP0 */
+		/* 6: DP1 */
+	};
+};
+
+&usb4_3_acio {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		/* 1: USB4 port */
+		port@1 {
+			reg = <1>;
+			usb4_3_acio_tbt: endpoint {
+				remote-endpoint = <&typec3_con_tbt>;
+			};
+		};
+
+		/* 2: USB4 lane 1 adapter */
+		/* 3: PCIe */
+		port@4 {
+			reg = <4>;
+			usb4_3_acio_usb3: endpoint {
+				remote-endpoint = <&dwc3_3_usb4>;
+			};
+		};
+
+		/* 5: DP0 */
+		/* 6: DP1 */
+	};
+};
+
 #include "spi1-nvram.dtsi"
diff --git a/arch/arm64/boot/dts/apple/t6022-j180d.dts b/arch/arm64/boot/dts/apple/t6022-j180d.dts
index f76b887429dd..1ddde77e00c0 100644
--- a/arch/arm64/boot/dts/apple/t6022-j180d.dts
+++ b/arch/arm64/boot/dts/apple/t6022-j180d.dts
@@ -26,6 +26,22 @@ aliases {
 		atcphy5 = &atcphy1_die1;
 		atcphy6 = &atcphy2_die1;
 		atcphy7 = &atcphy3_die1;
+		usb4-0-acio = &usb4_0_acio;
+		usb4-0-nhi = &usb4_0_nhi;
+		usb4-1-acio = &usb4_1_acio;
+		usb4-1-nhi = &usb4_1_nhi;
+		usb4-2-acio = &usb4_2_acio;
+		usb4-2-nhi = &usb4_2_nhi;
+		usb4-3-acio = &usb4_3_acio;
+		usb4-3-nhi = &usb4_3_nhi;
+		usb4-4-acio = &usb4_0_acio_die1;
+		usb4-4-nhi = &usb4_0_nhi_die1;
+		usb4-5-acio = &usb4_1_acio_die1;
+		usb4-5-nhi = &usb4_1_nhi_die1;
+		usb4-6-acio = &usb4_2_acio_die1;
+		usb4-6-nhi = &usb4_2_nhi_die1;
+		usb4-7-acio = &usb4_3_acio_die1;
+		usb4-7-nhi = &usb4_3_nhi_die1;
 		nvram = &nvram;
 		serial0 = &serial0;
 	};
@@ -152,6 +168,13 @@ typec6_connector_ss: endpoint {
 						remote-endpoint = <&atcphy6_typec_lanes>;
 					};
 				};
+
+				port@2 {
+					reg = <2>;
+					typec6_con_tbt: endpoint {
+						remote-endpoint = <&usb4_6_acio_tbt>;
+					};
+				};
 			};
 		};
 	};
@@ -184,6 +207,13 @@ typec7_connector_ss: endpoint {
 						remote-endpoint = <&atcphy7_typec_lanes>;
 					};
 				};
+
+				port@2 {
+					reg = <2>;
+					typec7_con_tbt: endpoint {
+						remote-endpoint = <&usb4_7_acio_tbt>;
+					};
+				};
 			};
 		};
 	};
@@ -280,10 +310,19 @@ dwc3_0_hs: endpoint {
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
@@ -301,10 +340,19 @@ dwc3_1_hs: endpoint {
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
@@ -322,10 +370,19 @@ dwc3_2_hs: endpoint {
 		};
 
 		port@1 {
+			#address-cells = <1>;
+			#size-cells = <0>;
 			reg = <1>;
-			dwc3_2_ss: endpoint {
+
+			dwc3_2_ss: endpoint@0 {
+				reg = <0>;
 				remote-endpoint = <&atcphy2_usb3>;
 			};
+
+			dwc3_2_usb4: endpoint@1 {
+				reg = <1>;
+				remote-endpoint = <&usb4_2_acio_usb3>;
+			};
 		};
 	};
 };
@@ -343,10 +400,19 @@ dwc3_3_hs: endpoint {
 		};
 
 		port@1 {
+			#address-cells = <1>;
+			#size-cells = <0>;
 			reg = <1>;
-			dwc3_3_ss: endpoint {
+
+			dwc3_3_ss: endpoint@0 {
+				reg = <0>;
 				remote-endpoint = <&atcphy3_usb3>;
 			};
+
+			dwc3_3_usb4: endpoint@1 {
+				reg = <1>;
+				remote-endpoint = <&usb4_3_acio_usb3>;
+			};
 		};
 	};
 };
@@ -365,10 +431,19 @@ dwc3_6_hs: endpoint {
 		};
 
 		port@1 {
+			#address-cells = <1>;
+			#size-cells = <0>;
 			reg = <1>;
-			dwc3_6_ss: endpoint {
+
+			dwc3_6_ss: endpoint@0 {
+				reg = <0>;
 				remote-endpoint = <&atcphy6_usb3>;
 			};
+
+			dwc3_6_usb4: endpoint@1 {
+				reg = <1>;
+				remote-endpoint = <&usb4_6_acio_usb3>;
+			};
 		};
 	};
 };
@@ -386,10 +461,19 @@ dwc3_7_hs: endpoint {
 		};
 
 		port@1 {
+			#address-cells = <1>;
+			#size-cells = <0>;
 			reg = <1>;
-			dwc3_7_ss: endpoint {
+
+			dwc3_7_ss: endpoint@0 {
+				reg = <0>;
 				remote-endpoint = <&atcphy7_usb3>;
 			};
+
+			dwc3_7_usb4: endpoint@1 {
+				reg = <1>;
+				remote-endpoint = <&usb4_7_acio_usb3>;
+			};
 		};
 	};
 };
@@ -535,4 +619,212 @@ &nco_clkref {
 	clock-frequency = <1068000000>;
 };
 
+/* USB4 on die 1 */
+&usb4_2_acio_die1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		/* 1: USB4 port */
+		port@1 {
+			reg = <1>;
+			usb4_6_acio_tbt: endpoint {
+				remote-endpoint = <&typec6_con_tbt>;
+			};
+		};
+
+		/* 2: USB4 lane 1 adapter */
+		/* 3: PCIe */
+		port@4 {
+			reg = <4>;
+			usb4_6_acio_usb3: endpoint {
+				remote-endpoint = <&dwc3_6_usb4>;
+			};
+		};
+
+		/* 5: DP0 */
+		/* 6: DP1 */
+	};
+};
+
+&usb4_3_acio_die1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		/* 1: USB4 port */
+		port@1 {
+			reg = <1>;
+			usb4_7_acio_tbt: endpoint {
+				remote-endpoint = <&typec7_con_tbt>;
+			};
+		};
+
+		/* 2: USB4 lane 1 adapter */
+		/* 3: PCIe */
+		port@4 {
+			reg = <4>;
+			usb4_7_acio_usb3: endpoint {
+				remote-endpoint = <&dwc3_7_usb4>;
+			};
+		};
+
+		/* 5: DP0 */
+		/* 6: DP1 */
+	};
+};
+
+&typec0 {
+	ports {
+		port@2 {
+			reg = <2>;
+			typec0_con_tbt: endpoint {
+				remote-endpoint = <&usb4_0_acio_tbt>;
+			};
+		};
+	};
+};
+
+&typec1 {
+	ports {
+		port@2 {
+			reg = <2>;
+			typec1_con_tbt: endpoint {
+				remote-endpoint = <&usb4_1_acio_tbt>;
+			};
+		};
+	};
+};
+
+&typec2 {
+	ports {
+		port@2 {
+			reg = <2>;
+			typec2_con_tbt: endpoint {
+				remote-endpoint = <&usb4_2_acio_tbt>;
+			};
+		};
+	};
+};
+
+&typec3 {
+	ports {
+		port@2 {
+			reg = <2>;
+			typec3_con_tbt: endpoint {
+				remote-endpoint = <&usb4_3_acio_tbt>;
+			};
+		};
+	};
+};
+
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
+&usb4_2_acio {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		/* 1: USB4 port */
+		port@1 {
+			reg = <1>;
+			usb4_2_acio_tbt: endpoint {
+				remote-endpoint = <&typec2_con_tbt>;
+			};
+		};
+
+		/* 2: USB4 lane 1 adapter */
+		/* 3: PCIe */
+		port@4 {
+			reg = <4>;
+			usb4_2_acio_usb3: endpoint {
+				remote-endpoint = <&dwc3_2_usb4>;
+			};
+		};
+
+		/* 5: DP0 */
+		/* 6: DP1 */
+	};
+};
+
+&usb4_3_acio {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		/* 1: USB4 port */
+		port@1 {
+			reg = <1>;
+			usb4_3_acio_tbt: endpoint {
+				remote-endpoint = <&typec3_con_tbt>;
+			};
+		};
+
+		/* 2: USB4 lane 1 adapter */
+		/* 3: PCIe */
+		port@4 {
+			reg = <4>;
+			usb4_3_acio_usb3: endpoint {
+				remote-endpoint = <&dwc3_3_usb4>;
+			};
+		};
+
+		/* 5: DP0 */
+		/* 6: DP1 */
+	};
+};
+
 #include "spi1-nvram.dtsi"
diff --git a/arch/arm64/boot/dts/apple/t6022-j475d.dts b/arch/arm64/boot/dts/apple/t6022-j475d.dts
index 32938a3bf96a..d99633160beb 100644
--- a/arch/arm64/boot/dts/apple/t6022-j475d.dts
+++ b/arch/arm64/boot/dts/apple/t6022-j475d.dts
@@ -20,6 +20,10 @@ / {
 	aliases {
 		atcphy4 = &atcphy0_die1;
 		atcphy5 = &atcphy1_die1;
+		usb4-4-acio = &usb4_0_acio_die1;
+		usb4-4-nhi = &usb4_0_nhi_die1;
+		usb4-5-acio = &usb4_1_acio_die1;
+		usb4-5-nhi = &usb4_1_nhi_die1;
 	};
 };
 
@@ -57,6 +61,12 @@ &typec5 {
 /delete-node/ &dwc3_3_die1;
 /delete-node/ &atcphy3_die1;
 
+/delete-node/ &usb4_2_acio_die1;
+/delete-node/ &usb4_2_mbox_die1;
+
+/delete-node/ &usb4_3_acio_die1;
+/delete-node/ &usb4_3_mbox_die1;
+
 /* delete unused always-on power-domains on die 1 */
 /delete-node/ &ps_atc2_usb_aon_die1;
 /delete-node/ &ps_atc2_usb_die1;
diff --git a/arch/arm64/boot/dts/apple/t6022-jxxxd.dtsi b/arch/arm64/boot/dts/apple/t6022-jxxxd.dtsi
index dc877bd604f8..6a3e866f83be 100644
--- a/arch/arm64/boot/dts/apple/t6022-jxxxd.dtsi
+++ b/arch/arm64/boot/dts/apple/t6022-jxxxd.dtsi
@@ -46,6 +46,13 @@ typec4_connector_ss: endpoint {
 						remote-endpoint = <&atcphy4_typec_lanes>;
 					};
 				};
+
+				port@2 {
+					reg = <2>;
+					typec4_con_tbt: endpoint {
+						remote-endpoint = <&usb4_4_acio_tbt>;
+					};
+				};
 			};
 		};
 	};
@@ -78,6 +85,13 @@ typec5_connector_ss: endpoint {
 						remote-endpoint = <&atcphy5_typec_lanes>;
 					};
 				};
+
+				port@2 {
+					reg = <2>;
+					typec5_con_tbt: endpoint {
+						remote-endpoint = <&usb4_5_acio_tbt>;
+					};
+				};
 			};
 		};
 	};
@@ -98,10 +112,19 @@ dwc3_4_hs: endpoint {
 		};
 
 		port@1 {
+			#address-cells = <1>;
+			#size-cells = <0>;
 			reg = <1>;
-			dwc3_4_ss: endpoint {
+
+			dwc3_4_ss: endpoint@0 {
+				reg = <0>;
 				remote-endpoint = <&atcphy4_usb3>;
 			};
+
+			dwc3_4_usb4: endpoint@1 {
+				reg = <1>;
+				remote-endpoint = <&usb4_4_acio_usb3>;
+			};
 		};
 	};
 };
@@ -119,10 +142,19 @@ dwc3_5_hs: endpoint {
 		};
 
 		port@1 {
+			#address-cells = <1>;
+			#size-cells = <0>;
 			reg = <1>;
-			dwc3_5_ss: endpoint {
+
+			dwc3_5_ss: endpoint@0 {
+				reg = <0>;
 				remote-endpoint = <&atcphy5_usb3>;
 			};
+
+			dwc3_5_usb4: endpoint@1 {
+				reg = <1>;
+				remote-endpoint = <&usb4_5_acio_usb3>;
+			};
 		};
 	};
 };
@@ -169,3 +201,58 @@ atcphy5_usb3: endpoint {
 		};
 	};
 };
+
+/* USB4 on die 1 */
+&usb4_0_acio_die1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		/* 1: USB4 port */
+		port@1 {
+			reg = <1>;
+			usb4_4_acio_tbt: endpoint {
+				remote-endpoint = <&typec4_con_tbt>;
+			};
+		};
+
+		/* 2: USB4 lane 1 adapter */
+		/* 3: PCIe */
+		port@4 {
+			reg = <4>;
+			usb4_4_acio_usb3: endpoint {
+				remote-endpoint = <&dwc3_4_usb4>;
+			};
+		};
+
+		/* 5: DP0 */
+		/* 6: DP1 */
+	};
+};
+
+&usb4_1_acio_die1 {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		/* 1: USB4 port */
+		port@1 {
+			reg = <1>;
+			usb4_5_acio_tbt: endpoint {
+				remote-endpoint = <&typec5_con_tbt>;
+			};
+		};
+
+		/* 2: USB4 lane 1 adapter */
+		/* 3: PCIe */
+		port@4 {
+			reg = <4>;
+			usb4_5_acio_usb3: endpoint {
+				remote-endpoint = <&dwc3_5_usb4>;
+			};
+		};
+
+		/* 5: DP0 */
+		/* 6: DP1 */
+	};
+};
diff --git a/arch/arm64/boot/dts/apple/t602x-dieX.dtsi b/arch/arm64/boot/dts/apple/t602x-dieX.dtsi
index fd4d572a04e7..1fba52e38ad8 100644
--- a/arch/arm64/boot/dts/apple/t602x-dieX.dtsi
+++ b/arch/arm64/boot/dts/apple/t602x-dieX.dtsi
@@ -98,6 +98,22 @@ DIE_NODE(pinctrl_aop): pinctrl@2a6820000 {
 				<AIC_IRQ DIE_NO 602 IRQ_TYPE_LEVEL_HIGH>,
 				<AIC_IRQ DIE_NO 603 IRQ_TYPE_LEVEL_HIGH>,
 				<AIC_IRQ DIE_NO 604 IRQ_TYPE_LEVEL_HIGH>;
+
+		DIE_NODE(acio0_pins): acio0-pins {
+			pinmux = <APPLE_PINMUX(65, 1)>;
+		};
+
+		DIE_NODE(acio1_pins): acio1-pins {
+			pinmux = <APPLE_PINMUX(67, 1)>;
+		};
+
+		DIE_NODE(acio2_pins): acio2-pins {
+			pinmux = <APPLE_PINMUX(69, 1)>;
+		};
+
+		DIE_NODE(acio3_pins): acio3-pins {
+			pinmux = <APPLE_PINMUX(71, 1)>;
+		};
 	};
 
 	DIE_NODE(pinctrl_ap): pinctrl@39b028000 {
@@ -133,6 +149,96 @@ DIE_NODE(pmgr_gfx): power-management@404e80000 {
 		reg = <0x4 0x4e80000 0 0x4000>;
 	};
 
+	DIE_NODE(usb4_0_mbox): mailbox@701108000 {
+		compatible = "apple,t6020-asc-mailbox",
+			"apple,asc-mailbox-v4";
+		reg = <0x7 0x01108000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 822 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 823 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 824 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 825 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "send-empty", "send-not-empty",
+			"recv-empty", "recv-not-empty";
+		#mbox-cells = <0>;
+	};
+
+	DIE_NODE(usb4_0_acio): cio@701ac0000 {
+		compatible = "apple,t6020-usb4-acio", "apple,t8103-usb4-acio";
+		reg = <0x7 0x01ac0000 0x0 0xc000>,
+			<0x7 0x01080000 0x0 0x20000>;
+		reg-names = "rc", "sram";
+
+		mboxes = <&DIE_NODE(usb4_0_mbox)>;
+		resets = <&DIE_NODE(cio_reset) 0>;
+
+		power-domains = <&DIE_NODE(ps_atc0_cio)>,
+				<&DIE_NODE(ps_atc0_cio_pcie)>,
+				<&DIE_NODE(ps_atc0_cio_usb)>;
+
+		pinctrl-0 = <&DIE_NODE(acio0_pins)>;
+		pinctrl-names = "default";
+
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges = <0x0 0x7 0x01000000 0x1000000>;
+		nonposted-mmio;
+
+		DIE_NODE(usb4_0_dart): iommu@a80000 {
+			compatible = "apple,t6020-dart", "apple,t8110-dart";
+			reg = <0xa80000 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1387 IRQ_TYPE_LEVEL_HIGH>;
+			#iommu-cells = <5>;
+		};
+
+		DIE_NODE(usb4_0_nhi): nhi@f00000 {
+			reg = <0xf00000 0x100000>,
+				<0xdb0000 0x30004>;
+			reg-names = "nhi", "pdf";
+			compatible = "apple,t6020-usb4-nhi",
+				"apple,t8103-usb4-nhi";
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1360 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1361 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1362 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1363 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1364 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1365 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1366 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1367 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1368 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1369 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1370 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1371 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1372 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1373 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1374 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1375 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1376 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1377 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1378 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1379 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1380 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1381 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1382 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1383 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names =
+				"txring0", "txring1", "txring2",
+				"txring3", "txring4", "txring5",
+				"txring6", "txring7", "txring8",
+				"txring9", "txring10", "txring11",
+				"rxring0", "rxring1", "rxring2",
+				"rxring3", "rxring4", "rxring5",
+				"rxring6", "rxring7", "rxring8",
+				"rxring9", "rxring10", "rxring11";
+			iommus = <&DIE_NODE(usb4_0_dart) 1 0x100 0x0 0x10 0x0>,
+				 <&DIE_NODE(usb4_0_dart) 2 0x100 0x0 0x10 0x0>;
+			/* To be filled by the loader */
+			apple,thunderbolt-drom = [00];
+		};
+	};
+
 	DIE_NODE(dwc3_0): usb@702280000 {
 		compatible = "apple,t6020-dwc3", "apple,t8103-dwc3";
 		reg = <0x7 0x02280000 0x0 0xcd00>, <0x7 0x0228cd00 0x0 0x3200>;
@@ -186,6 +292,96 @@ DIE_NODE(atcphy0): phy@703000000 {
 		power-domains = <&DIE_NODE(ps_atc0_usb)>;
 	};
 
+	DIE_NODE(usb4_1_mbox): mailbox@b01108000 {
+		compatible = "apple,t6020-asc-mailbox",
+			"apple,asc-mailbox-v4";
+		reg = <0xb 0x01108000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 826 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 827 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 828 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 829 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "send-empty", "send-not-empty",
+			"recv-empty", "recv-not-empty";
+		#mbox-cells = <0>;
+	};
+
+	DIE_NODE(usb4_1_acio): cio@b01ac0000 {
+		compatible = "apple,t6020-usb4-acio", "apple,t8103-usb4-acio";
+		reg = <0xb 0x01ac0000 0x0 0xc000>,
+			<0xb 0x01080000 0x0 0x20000>;
+		reg-names = "rc", "sram";
+
+		mboxes = <&DIE_NODE(usb4_1_mbox)>;
+		resets = <&DIE_NODE(cio_reset) 1>;
+
+		power-domains = <&DIE_NODE(ps_atc1_cio)>,
+				<&DIE_NODE(ps_atc1_cio_pcie)>,
+				<&DIE_NODE(ps_atc1_cio_usb)>;
+
+		pinctrl-0 = <&DIE_NODE(acio1_pins)>;
+		pinctrl-names = "default";
+
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges = <0x0 0xb 0x01000000 0x1000000>;
+		nonposted-mmio;
+
+		DIE_NODE(usb4_1_dart): iommu@a80000 {
+			compatible = "apple,t6020-dart", "apple,t8110-dart";
+			reg = <0xa80000 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1435 IRQ_TYPE_LEVEL_HIGH>;
+			#iommu-cells = <5>;
+		};
+
+		DIE_NODE(usb4_1_nhi): nhi@f00000 {
+			reg = <0xf00000 0x100000>,
+				<0xdb0000 0x30004>;
+			reg-names = "nhi", "pdf";
+			compatible = "apple,t6020-usb4-nhi",
+				"apple,t8103-usb4-nhi";
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1408 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1409 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1410 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1411 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1412 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1413 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1414 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1415 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1416 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1417 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1418 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1419 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1420 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1421 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1422 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1423 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1424 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1425 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1426 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1427 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1428 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1429 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1430 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1431 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names =
+				"txring0", "txring1", "txring2",
+				"txring3", "txring4", "txring5",
+				"txring6", "txring7", "txring8",
+				"txring9", "txring10", "txring11",
+				"rxring0", "rxring1", "rxring2",
+				"rxring3", "rxring4", "rxring5",
+				"rxring6", "rxring7", "rxring8",
+				"rxring9", "rxring10", "rxring11";
+			iommus = <&DIE_NODE(usb4_1_dart) 1 0x100 0x0 0x10 0x0>,
+				 <&DIE_NODE(usb4_1_dart) 2 0x100 0x0 0x10 0x0>;
+			/* To be filled by the loader */
+			apple,thunderbolt-drom = [00];
+		};
+	};
+
 	DIE_NODE(dwc3_1): usb@b02280000 {
 		compatible = "apple,t6020-dwc3", "apple,t8103-dwc3";
 		reg = <0xb 0x02280000 0x0 0xcd00>, <0xb 0x0228cd00 0x0 0x3200>;
@@ -239,6 +435,96 @@ DIE_NODE(atcphy1): phy@b03000000 {
 		power-domains = <&DIE_NODE(ps_atc1_usb)>;
 	};
 
+	DIE_NODE(usb4_2_mbox): mailbox@f01108000 {
+		compatible = "apple,t6020-asc-mailbox",
+			"apple,asc-mailbox-v4";
+		reg = <0xf 0x01108000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 830 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 831 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 832 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 833 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "send-empty", "send-not-empty",
+			"recv-empty", "recv-not-empty";
+		#mbox-cells = <0>;
+	};
+
+	DIE_NODE(usb4_2_acio): cio@f01ac0000 {
+		compatible = "apple,t6020-usb4-acio", "apple,t8103-usb4-acio";
+		reg = <0xf 0x01ac0000 0x0 0xc000>,
+			<0xf 0x01080000 0x0 0x20000>;
+		reg-names = "rc", "sram";
+
+		mboxes = <&DIE_NODE(usb4_2_mbox)>;
+		resets = <&DIE_NODE(cio_reset) 2>;
+
+		power-domains = <&DIE_NODE(ps_atc2_cio)>,
+				<&DIE_NODE(ps_atc2_cio_pcie)>,
+				<&DIE_NODE(ps_atc2_cio_usb)>;
+
+		pinctrl-0 = <&DIE_NODE(acio2_pins)>;
+		pinctrl-names = "default";
+
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges = <0x0 0xf 0x01000000 0x1000000>;
+		nonposted-mmio;
+
+		DIE_NODE(usb4_2_dart): iommu@a80000 {
+			compatible = "apple,t6020-dart", "apple,t8110-dart";
+			reg = <0xa80000 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1483 IRQ_TYPE_LEVEL_HIGH>;
+			#iommu-cells = <5>;
+		};
+
+		DIE_NODE(usb4_2_nhi): nhi@f00000 {
+			reg = <0xf00000 0x100000>,
+				<0xdb0000 0x30004>;
+			reg-names = "nhi", "pdf";
+			compatible = "apple,t6020-usb4-nhi",
+				"apple,t8103-usb4-nhi";
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1456 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1457 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1458 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1459 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1460 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1461 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1462 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1463 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1464 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1465 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1466 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1467 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1468 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1469 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1470 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1471 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1472 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1473 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1474 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1475 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1476 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1477 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1478 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1479 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names =
+				"txring0", "txring1", "txring2",
+				"txring3", "txring4", "txring5",
+				"txring6", "txring7", "txring8",
+				"txring9", "txring10", "txring11",
+				"rxring0", "rxring1", "rxring2",
+				"rxring3", "rxring4", "rxring5",
+				"rxring6", "rxring7", "rxring8",
+				"rxring9", "rxring10", "rxring11";
+			iommus = <&DIE_NODE(usb4_2_dart) 1 0x100 0x0 0x10 0x0>,
+				 <&DIE_NODE(usb4_2_dart) 2 0x100 0x0 0x10 0x0>;
+			/* To be filled by the loader */
+			apple,thunderbolt-drom = [00];
+		};
+	};
+
 	DIE_NODE(dwc3_2): usb@f02280000 {
 		compatible = "apple,t6020-dwc3", "apple,t8103-dwc3";
 		reg = <0xf 0x02280000 0x0 0xcd00>, <0xf 0x0228cd00 0x0 0x3200>;
@@ -292,6 +578,96 @@ DIE_NODE(atcphy2): phy@f03000000 {
 		power-domains = <&DIE_NODE(ps_atc2_usb)>;
 	};
 
+	DIE_NODE(usb4_3_mbox): mailbox@1301108000 {
+		compatible = "apple,t6020-asc-mailbox",
+			"apple,asc-mailbox-v4";
+		reg = <0x13 0x01108000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ DIE_NO 834 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 835 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 836 IRQ_TYPE_LEVEL_HIGH>,
+			<AIC_IRQ DIE_NO 837 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "send-empty", "send-not-empty",
+			"recv-empty", "recv-not-empty";
+		#mbox-cells = <0>;
+	};
+
+	DIE_NODE(usb4_3_acio): cio@1301ac0000 {
+		compatible = "apple,t6020-usb4-acio", "apple,t8103-usb4-acio";
+		reg = <0x13 0x01ac0000 0x0 0xc000>,
+			<0x13 0x01080000 0x0 0x20000>;
+		reg-names = "rc", "sram";
+
+		mboxes = <&DIE_NODE(usb4_3_mbox)>;
+		resets = <&DIE_NODE(cio_reset) 3>;
+
+		power-domains = <&DIE_NODE(ps_atc3_cio)>,
+				<&DIE_NODE(ps_atc3_cio_pcie)>,
+				<&DIE_NODE(ps_atc3_cio_usb)>;
+
+		pinctrl-0 = <&DIE_NODE(acio3_pins)>;
+		pinctrl-names = "default";
+
+		#address-cells = <1>;
+		#size-cells = <1>;
+		ranges = <0x0 0x13 0x01000000 0x1000000>;
+		nonposted-mmio;
+
+		DIE_NODE(usb4_3_dart): iommu@a80000 {
+			compatible = "apple,t6020-dart", "apple,t8110-dart";
+			reg = <0xa80000 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1531 IRQ_TYPE_LEVEL_HIGH>;
+			#iommu-cells = <5>;
+		};
+
+		DIE_NODE(usb4_3_nhi): nhi@f00000 {
+			reg = <0xf00000 0x100000>,
+				<0xdb0000 0x30004>;
+			reg-names = "nhi", "pdf";
+			compatible = "apple,t6020-usb4-nhi",
+				"apple,t8103-usb4-nhi";
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ DIE_NO 1504 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1505 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1506 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1507 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1508 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1509 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1510 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1511 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1512 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1513 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1514 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1515 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1516 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1517 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1518 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1519 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1520 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1521 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1522 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1523 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1524 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1525 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1526 IRQ_TYPE_LEVEL_HIGH>,
+				<AIC_IRQ DIE_NO 1527 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names =
+				"txring0", "txring1", "txring2",
+				"txring3", "txring4", "txring5",
+				"txring6", "txring7", "txring8",
+				"txring9", "txring10", "txring11",
+				"rxring0", "rxring1", "rxring2",
+				"rxring3", "rxring4", "rxring5",
+				"rxring6", "rxring7", "rxring8",
+				"rxring9", "rxring10", "rxring11";
+			iommus = <&DIE_NODE(usb4_3_dart) 1 0x100 0x0 0x10 0x0>,
+				 <&DIE_NODE(usb4_3_dart) 2 0x100 0x0 0x10 0x0>;
+			/* To be filled by the loader */
+			apple,thunderbolt-drom = [00];
+		};
+	};
+
 	DIE_NODE(dwc3_3): usb@1302280000 {
 		compatible = "apple,t6020-dwc3", "apple,t8103-dwc3";
 		reg = <0x13 0x02280000 0x0 0xcd00>, <0x13 0x0228cd00 0x0 0x3200>;

-- 
2.55.0

