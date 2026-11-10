From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:20:09 +0000
Subject: [PATCH 4/4] arm64: dts: rockchip: Describe the USB3 Type-A
 connector on Orange Pi 5/5B
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-usb-port-pairing-v1-4-9307e29d2ed2@gmail.com>
References: <20261110-usb-port-pairing-v1-0-9307e29d2ed2@gmail.com>
In-Reply-To: <20261110-usb-port-pairing-v1-0-9307e29d2ed2@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295206; l=2457;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=IakzDRMMsFFpDM3Pul0+4jHnnMQtQ7ZuE6Fs1yH1Zm0=;
 b=OC5rK3ua1Qy61UygXep+9kHnO/LjV0yc7VK/6IzFLGy4eDROvGHeMgLZVAzetF4NpO4zIsFsu
 APSMfEOXhHYCanl/ineaEsILKjg1A+WWtbUbBnyJ14hejnch1PTuXCi
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The upper Type-A port of the Orange Pi 5 and 5B has its USB 2.0 lines
on USB 2.0 host 1 (EHCI/OHCI) and its SuperSpeed lanes on the
SuperSpeed-only USB 3.0 host 2 (xHCI). The lower Type-A port is USB 2.0
only, on host 0.

Describe the upper port as a usb-a-connector linked to both
controllers, so that the USB core pairs the EHCI root hub port with the
xHCI SuperSpeed port. Without that, a USB 3 device plugged in at boot
is enumerated by the EHCI before the xHCI is up and stays at high
speed.

VBUS of the port is not switched (the vendor DT has it on an always-on
5 V rail), so it is described as coming from vcc5v0_sys.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 .../boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi   | 60 ++++++++++++++++++++++
 1 file changed, 60 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
index 6e081bc06cfe..2049adc9be62 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi
@@ -56,6 +56,38 @@ led {
 		};
 	};
 
+	/*
+	 * The upper Type-A port: its USB 2.0 lines go to USB 2.0 host 1
+	 * (EHCI/OHCI), its SuperSpeed lanes to the SuperSpeed-only USB 3.0
+	 * host 2 (xHCI).
+	 */
+	usb3_con: connector-usb3 {
+		compatible = "usb-a-connector";
+		label = "USB3";
+		vbus-supply = <&vcc5v0_sys>;
+
+		ports {
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			port@0 {
+				reg = <0>;
+
+				usb3_con_hs: endpoint {
+					remote-endpoint = <&usb_host1_ehci_port1>;
+				};
+			};
+
+			port@1 {
+				reg = <1>;
+
+				usb3_con_ss: endpoint {
+					remote-endpoint = <&usb_host2_xhci_ss>;
+				};
+			};
+		};
+	};
+
 	vbus_typec: regulator-vbus-typec {
 		compatible = "regulator-fixed";
 		enable-active-high;
@@ -229,8 +261,36 @@ usb_host0_xhci_drd_sw: endpoint {
 	};
 };
 
+&usb_host1_ehci {
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@1 {
+			reg = <1>;
+
+			usb_host1_ehci_port1: endpoint {
+				remote-endpoint = <&usb3_con_hs>;
+			};
+		};
+	};
+};
+
 &usb_host2_xhci {
 	status = "okay";
+
+	ports {
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		port@1 {
+			reg = <1>;
+
+			usb_host2_xhci_ss: endpoint {
+				remote-endpoint = <&usb3_con_ss>;
+			};
+		};
+	};
 };
 
 &usbdp_phy0 {

-- 
2.55.0

