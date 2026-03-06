From: Michael Riesch <michael.riesch@collabora.com>
Date: Fri, 06 Mar 2026 15:09:50 +0100
Subject: [PATCH 3/4] arm64: dts: rockchip: add mipi csi-2 receiver nodes to
 rk3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260305-rk3588-csi2rx-v1-3-0cd8d2bf28c0@collabora.com>
References: <20260305-rk3588-csi2rx-v1-0-0cd8d2bf28c0@collabora.com>
In-Reply-To: <20260305-rk3588-csi2rx-v1-0-0cd8d2bf28c0@collabora.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Frank Li <Frank.li@nxp.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Collabora Kernel Team <kernel@collabora.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772806189; l=2445;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=Muw10Ob2mbGv5nQmZECuxfL28AD/N1oGV2Lsi4zIYF0=;
 b=LX+dHfueGExnbTDu2GSTbC3J+jUUEGHc97BFsIBTk37tt39CQpWqe10V7wXEZ7tg+9VadLH3Y
 Z97bCC5DfQKCXAlYdri8R7JygV3vsCwqB1YqHu14aCoHT0b0G4eGh40
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Rockchip RK3588 features six MIPI CSI-2 receiver units:
 - MIPI0: connected to MIPI DCPHY0 (not supported)
 - MIPI1: connected to MIPI DCPHY1 (not supported)
 - MIPI2: connected to MIPI DPHY0
 - MIPI3: connected to MIPI DPHY0-1 (not supported)
 - MIPI4: connected to MIPI DPHY1
 - MIPI5: connected to MIPI DPHY1-1 (not supported)
As the MIPI DCPHYs as well as the split DPHY mode of the DPHYs
are not yet supported, add only the device tree nodes for the
MIPI2 and MIPI4 units.

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi | 52 +++++++++++++++++++++++++++
 1 file changed, 52 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
index 7fe9593d8c19..3bbd057ca504 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
@@ -1430,6 +1430,58 @@ av1d: video-codec@fdc70000 {
 		resets = <&cru SRST_A_AV1>, <&cru SRST_P_AV1>, <&cru SRST_A_AV1_BIU>, <&cru SRST_P_AV1_BIU>;
 	};
 
+	csi2: csi@fdd30000 {
+		compatible = "rockchip,rk3588-mipi-csi2";
+		reg = <0x0 0xfdd30000 0x0 0x10000>;
+		interrupts = <GIC_SPI 147 IRQ_TYPE_LEVEL_HIGH 0>,
+			     <GIC_SPI 148 IRQ_TYPE_LEVEL_HIGH 0>;
+		interrupt-names = "err1", "err2";
+		clocks = <&cru PCLK_CSI_HOST_2>;
+		phys = <&csi_dphy0>;
+		power-domains = <&power RK3588_PD_VI>;
+		resets = <&cru SRST_P_CSI_HOST_2>;
+		status = "disabled";
+
+		ports {
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			csi2_in: port@0 {
+				reg = <0>;
+			};
+
+			csi2_out: port@1 {
+				reg = <1>;
+			};
+		};
+	};
+
+	csi4: csi@fdd50000 {
+		compatible = "rockchip,rk3588-mipi-csi2";
+		reg = <0x0 0xfdd50000 0x0 0x10000>;
+		interrupts = <GIC_SPI 151 IRQ_TYPE_LEVEL_HIGH 0>,
+			     <GIC_SPI 152 IRQ_TYPE_LEVEL_HIGH 0>;
+		interrupt-names = "err1", "err2";
+		clocks = <&cru PCLK_CSI_HOST_4>;
+		phys = <&csi_dphy1>;
+		power-domains = <&power RK3588_PD_VI>;
+		resets = <&cru SRST_P_CSI_HOST_4>;
+		status = "disabled";
+
+		ports {
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			csi4_in: port@0 {
+				reg = <0>;
+			};
+
+			csi4_out: port@1 {
+				reg = <1>;
+			};
+		};
+	};
+
 	vop: vop@fdd90000 {
 		compatible = "rockchip,rk3588-vop";
 		reg = <0x0 0xfdd90000 0x0 0x4200>, <0x0 0xfdd95000 0x0 0x1000>;

-- 
2.39.5

