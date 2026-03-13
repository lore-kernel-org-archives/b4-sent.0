From: Michael Riesch <michael.riesch@collabora.com>
Date: Fri, 13 Mar 2026 16:20:48 +0100
Subject: [PATCH 6/9] arm64: dts: rockchip: add vicap node to rk3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250430-rk3588-vicap-v1-6-b3bddf749914@collabora.com>
References: <20250430-rk3588-vicap-v1-0-b3bddf749914@collabora.com>
In-Reply-To: <20250430-rk3588-vicap-v1-0-b3bddf749914@collabora.com>
To: Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Jagan Teki <jagan@amarulasolutions.com>, 
 =?utf-8?q?=D0=9A=D1=83=D0=B7=D0=BD=D0=B5=D1=86=D0=BE=D0=B2_=D0=9C=D0=B8=D1=85=D0=B0=D0=B8=D0=BB?= <mai.kuznetsov.misha@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Collabora Kernel Team <kernel@collabora.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773415244; l=3136;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=lhhtStvU9KJ5KtPRq641jsKNo7Ekcu2JQR1zIWTa/rU=;
 b=Dj/JnQqIZbphAyL0wxDZunBFM3jouZROffHfMzlmQ9+dHFgVuiCwctfttMPwS63mqr7cDUsSy
 t0UKjSU4Zw2A0G0PVH2xZr4uYnbDQJBEf5g0ZbXIswPhtFpWtKA94Av
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the device tree node for the RK3588 Video Capture (VICAP) unit.

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi | 87 +++++++++++++++++++++++++++
 1 file changed, 87 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
index 6c593b0255c3..9019ce0968da 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
@@ -1430,6 +1430,85 @@ av1d: video-codec@fdc70000 {
 		resets = <&cru SRST_A_AV1>, <&cru SRST_P_AV1>, <&cru SRST_A_AV1_BIU>, <&cru SRST_P_AV1_BIU>;
 	};
 
+	vicap: video-capture@fdce0000 {
+		compatible = "rockchip,rk3588-vicap";
+		reg = <0x0 0xfdce0000 0x0 0x800>;
+		interrupts = <GIC_SPI 155 IRQ_TYPE_LEVEL_HIGH 0>;
+		clocks = <&cru ACLK_VICAP>, <&cru HCLK_VICAP>,
+			 <&cru DCLK_VICAP>, <&cru ICLK_CSIHOST0>,
+			 <&cru ICLK_CSIHOST1>;
+		clock-names = "aclk", "hclk", "dclk", "iclk_host0", "iclk_host1";
+		iommus = <&vicap_mmu>;
+		power-domains = <&power RK3588_PD_VI>;
+		resets = <&cru SRST_A_VICAP>, <&cru SRST_H_VICAP>,
+			 <&cru SRST_D_VICAP>, <&cru SRST_CSIHOST0_VICAP>,
+			 <&cru SRST_CSIHOST1_VICAP>, <&cru SRST_CSIHOST2_VICAP>,
+			 <&cru SRST_CSIHOST3_VICAP>, <&cru SRST_CSIHOST4_VICAP>,
+			 <&cru SRST_CSIHOST5_VICAP>;
+		status = "disabled";
+
+		ports {
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			vicap_dvp: port@0 {
+				reg = <0>;
+			};
+
+			vicap_mipi0: port@1 {
+				reg = <1>;
+			};
+
+			vicap_mipi1: port@2 {
+				reg = <2>;
+			};
+
+			vicap_mipi2: port@3 {
+				reg = <3>;
+
+				vicap_mipi2_input: endpoint {
+					remote-endpoint = <&csi2_output>;
+				};
+			};
+
+			vicap_mipi3: port@4 {
+				reg = <4>;
+			};
+
+			vicap_mipi4: port@5 {
+				reg = <5>;
+
+				vicap_mipi4_input: endpoint {
+					remote-endpoint = <&csi4_output>;
+				};
+			};
+
+			vicap_mipi5: port@6 {
+				reg = <6>;
+			};
+
+			vicap_toisp0: port@a {
+				reg = <10>;
+			};
+
+			vicap_toisp1: port@b {
+				reg = <11>;
+			};
+		};
+	};
+
+	vicap_mmu: iommu@fdce0800 {
+		compatible = "rockchip,rk3588-iommu", "rockchip,rk3568-iommu";
+		reg = <0x0 0xfdce0800 0x0 0x40>, <0x0 0xfdce0900 0x0 0x40>;
+		interrupts = <GIC_SPI 113 IRQ_TYPE_LEVEL_HIGH 0>;
+		clocks = <&cru ACLK_VICAP>, <&cru HCLK_VICAP>;
+		clock-names = "aclk", "iface";
+		#iommu-cells = <0>;
+		power-domains = <&power RK3588_PD_VI>;
+		rockchip,disable-mmu-reset;
+		status = "disabled";
+	};
+
 	csi2: csi@fdd30000 {
 		compatible = "rockchip,rk3588-mipi-csi2", "rockchip,rk3568-mipi-csi2";
 		reg = <0x0 0xfdd30000 0x0 0x10000>;
@@ -1452,6 +1531,10 @@ csi2_in: port@0 {
 
 			csi2_out: port@1 {
 				reg = <1>;
+
+				csi2_output: endpoint {
+					remote-endpoint = <&vicap_mipi2_input>;
+				};
 			};
 		};
 	};
@@ -1478,6 +1561,10 @@ csi4_in: port@0 {
 
 			csi4_out: port@1 {
 				reg = <1>;
+
+				csi4_output: endpoint {
+					remote-endpoint = <&vicap_mipi4_input>;
+				};
 			};
 		};
 	};

-- 
2.39.5

