From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:19:35 +0000
Subject: [PATCH 3/3] arm64: dts: rockchip: Add USB-C DP AltMode for Orange
 Pi 5/5B
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-opi5-dts-v1-3-582b63d074be@gmail.com>
References: <20261110-opi5-dts-v1-0-582b63d074be@gmail.com>
In-Reply-To: <20261110-opi5-dts-v1-0-582b63d074be@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295172; l=4241;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=+xmGbI4GlMgBmPGKtTKnBGXbYPlqe8bWAMPWV4cMo58=;
 b=3Jl0l/Hm3AzwagElH5K8zDZOTARddC/2ctTH7U2tgMLE8KpqBFi3pZrMhgnM4NH3zZJ1sbwJK
 z1g2+Rlm4cRA9des28Fu+HPG5hZFhvXc7gPwvnHrfUv50GMto/aWfzI
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The USB-C port of the Orange Pi 5 and 5B is connected to the RK3588S
USBDP PHY0, which can mux two (pin assignment D) or all four (pin
assignment C/E) of its SuperSpeed lanes to the DisplayPort controller
DP0. The SBU lines are wired to the PHY's DP AUX channel through the
sbu1/sbu2 DC control GPIOs that are already described.

Enable DP0, route it from VOP2 video port 2 and describe the full
USB-C graph using the USBDP PHY ports scheme:

  port@0: SuperSpeed lanes to the USB-C connector
  port@1: from the DWC3 controller (SuperSpeed)
  port@2: from the DP controller
  port@3: DP AUX to the connector's SBU port

and advertise DisplayPort AltMode (DFP_D, HBR3, receptacle, pin
assignments C/D/E) on the connector, so TCPM enters DP AltMode with
DP capable sinks/adapters.

VP2 is used as on the ROCK 5B family, leaving VP0 for HDMI0 and VP1
free.

Modelled on Sebastian Reichel's ROCK 5B family DP Alt Mode support in
the Collabora rockchip-3588 tree.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi   | 89 +++++++++++++++++++---
 1 file changed, 78 insertions(+), 11 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
index 7c1fd5905553..52f5005c738d 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
@@ -94,6 +94,22 @@ vcc_3v3_sd_s0: regulator-vcc-3v3-sd-s0 {
 	};
 };
 
+&dp0 {
+	status = "okay";
+};
+
+&dp0_in {
+	dp0_in_vp2: endpoint {
+		remote-endpoint = <&vp2_out_dp0>;
+	};
+};
+
+&dp0_out {
+	dp0_out_con: endpoint {
+		remote-endpoint = <&usbdp_phy0_dp_in>;
+	};
+};
+
 &gmac1 {
 	clock_in_out = "output";
 	phy-handle = <&rgmii_phy1>;
@@ -143,6 +159,13 @@ usb_con: connector {
 				<PDO_FIXED(5000, 3000, PDO_FIXED_USB_COMM)>;
 			try-power-role = "source";
 
+			altmodes {
+				displayport {
+					svid = /bits/ 16 <0xff01>;
+					vdo = <0x00001c46>;
+				};
+			};
+
 			ports {
 				#address-cells = <1>;
 				#size-cells = <0>;
@@ -150,21 +173,21 @@ ports {
 				port@0 {
 					reg = <0>;
 					usbc0_hs: endpoint {
-						remote-endpoint = <&usb_host0_xhci_drd_sw>;
+						remote-endpoint = <&usb_host0_xhci_hs>;
 					};
 				};
 
 				port@1 {
 					reg = <1>;
 					usbc0_ss: endpoint {
-						remote-endpoint = <&usbdp_phy0_typec_ss>;
+						remote-endpoint = <&usbdp_phy0_ss_out>;
 					};
 				};
 
 				port@2 {
 					reg = <2>;
 					usbc0_sbu: endpoint {
-						remote-endpoint = <&usbdp_phy0_typec_sbu>;
+						remote-endpoint = <&usbdp_phy0_dp_out>;
 					};
 				};
 			};
@@ -250,9 +273,24 @@ &usb_host0_xhci {
 	dr_mode = "otg";
 	usb-role-switch;
 
-	port {
-		usb_host0_xhci_drd_sw: endpoint {
-			remote-endpoint = <&usbc0_hs>;
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@0 {
+			reg = <0>;
+
+			usb_host0_xhci_hs: endpoint {
+				remote-endpoint = <&usbc0_hs>;
+			};
+		};
+
+		port@1 {
+			reg = <1>;
+
+			usb_host0_xhci_ss: endpoint {
+				remote-endpoint = <&usbdp_phy0_ss_in>;
+			};
 		};
 	};
 };
@@ -267,18 +305,47 @@ &usbdp_phy0 {
 	sbu1-dc-gpios = <&gpio4 RK_PA5 GPIO_ACTIVE_HIGH>;
 	sbu2-dc-gpios = <&gpio4 RK_PA7 GPIO_ACTIVE_HIGH>;
 
-	port {
+	ports {
 		#address-cells = <1>;
 		#size-cells = <0>;
 
-		usbdp_phy0_typec_ss: endpoint@0 {
+		port@0 {
 			reg = <0>;
-			remote-endpoint = <&usbc0_ss>;
+
+			usbdp_phy0_ss_out: endpoint {
+				remote-endpoint = <&usbc0_ss>;
+			};
 		};
 
-		usbdp_phy0_typec_sbu: endpoint@1 {
+		port@1 {
 			reg = <1>;
-			remote-endpoint = <&usbc0_sbu>;
+
+			usbdp_phy0_ss_in: endpoint {
+				remote-endpoint = <&usb_host0_xhci_ss>;
+			};
 		};
+
+		port@2 {
+			reg = <2>;
+
+			usbdp_phy0_dp_in: endpoint {
+				remote-endpoint = <&dp0_out_con>;
+			};
+		};
+
+		port@3 {
+			reg = <3>;
+
+			usbdp_phy0_dp_out: endpoint {
+				remote-endpoint = <&usbc0_sbu>;
+			};
+		};
+	};
+};
+
+&vp2 {
+	vp2_out_dp0: endpoint@a {
+		reg = <ROCKCHIP_VOP2_EP_DP0>;
+		remote-endpoint = <&dp0_in_vp2>;
 	};
 };

-- 
2.55.0

