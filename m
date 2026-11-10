From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 10:08:14 +0000
Subject: [PATCH RFC 12/12] arm64: dts: rockchip: Add the VEPU580 encoder
 cores to the RK3588
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-rkvenc-v1-12-ea8b47122d8c@gmail.com>
References: <20261110-rkvenc-v1-0-ea8b47122d8c@gmail.com>
In-Reply-To: <20261110-rkvenc-v1-0-ea8b47122d8c@gmail.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Paul Kocialkowski <paulk@sys-base.io>, 
 =?utf-8?q?Sven_P=C3=BCschel?= <s.pueschel@pengutronix.de>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Detlev Casanova <detlev.casanova@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Jiaxing Hu <gahing@gahingwoo.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794305283; l=3181;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=kagifa6Lmg0J/Xo2eD/GKAYer7IvTfvqdz6aGlCXzQU=;
 b=Z55zyJzLXjk5M0iOHQBuQmkiC3qqZVinOuzqIhqBgV9OAHTjmiFRh0C7Jcn5sf5tp6ip/f6hn
 dUnPCBOY7WSCOjYQ4VM4zLV2TEaEVljLIwKq9tLlNcHjTz+3XVBALkU
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the two VEPU580 (RKVENC) video encoder cores and their IOMMUs.

Interrupts, clocks, resets, power domains and the clock rates (500 MHz
AXI, 800 MHz core) are taken from the Rockchip BSP rk3588s.dtsi. Each
IOMMU has two register banks and two interrupts, and keeps the BSP's
rockchip,disable-mmu-reset.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi | 56 +++++++++++++++++++++++++++
 1 file changed, 56 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
index aa69fd3793fd..9c813e6475c5 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
@@ -1397,6 +1397,62 @@ vepu121_3_mmu: iommu@fdbac800 {
 		#iommu-cells = <0>;
 	};
 
+	vepu580_0: video-codec@fdbd0000 {
+		compatible = "rockchip,rk3588-vepu580";
+		reg = <0x0 0xfdbd0000 0x0 0x6000>;
+		interrupts = <GIC_SPI 101 IRQ_TYPE_LEVEL_HIGH 0>;
+		clocks = <&cru ACLK_RKVENC0>, <&cru HCLK_RKVENC0>,
+			 <&cru CLK_RKVENC0_CORE>;
+		clock-names = "aclk", "hclk", "core";
+		assigned-clocks = <&cru ACLK_RKVENC0>, <&cru CLK_RKVENC0_CORE>;
+		assigned-clock-rates = <500000000>, <800000000>;
+		resets = <&cru SRST_A_RKVENC0>, <&cru SRST_H_RKVENC0>,
+			 <&cru SRST_RKVENC0_CORE>;
+		reset-names = "aclk", "hclk", "core";
+		iommus = <&vepu580_0_mmu>;
+		power-domains = <&power RK3588_PD_VENC0>;
+	};
+
+	vepu580_0_mmu: iommu@fdbdf000 {
+		compatible = "rockchip,rk3588-iommu", "rockchip,rk3568-iommu";
+		reg = <0x0 0xfdbdf000 0x0 0x40>, <0x0 0xfdbdf040 0x0 0x40>;
+		interrupts = <GIC_SPI 99 IRQ_TYPE_LEVEL_HIGH 0>,
+			     <GIC_SPI 100 IRQ_TYPE_LEVEL_HIGH 0>;
+		clocks = <&cru ACLK_RKVENC0>, <&cru HCLK_RKVENC0>;
+		clock-names = "aclk", "iface";
+		power-domains = <&power RK3588_PD_VENC0>;
+		rockchip,disable-mmu-reset;
+		#iommu-cells = <0>;
+	};
+
+	vepu580_1: video-codec@fdbe0000 {
+		compatible = "rockchip,rk3588-vepu580";
+		reg = <0x0 0xfdbe0000 0x0 0x6000>;
+		interrupts = <GIC_SPI 104 IRQ_TYPE_LEVEL_HIGH 0>;
+		clocks = <&cru ACLK_RKVENC1>, <&cru HCLK_RKVENC1>,
+			 <&cru CLK_RKVENC1_CORE>;
+		clock-names = "aclk", "hclk", "core";
+		assigned-clocks = <&cru ACLK_RKVENC1>, <&cru CLK_RKVENC1_CORE>;
+		assigned-clock-rates = <500000000>, <800000000>;
+		resets = <&cru SRST_A_RKVENC1>, <&cru SRST_H_RKVENC1>,
+			 <&cru SRST_RKVENC1_CORE>;
+		reset-names = "aclk", "hclk", "core";
+		iommus = <&vepu580_1_mmu>;
+		power-domains = <&power RK3588_PD_VENC1>;
+	};
+
+	vepu580_1_mmu: iommu@fdbef000 {
+		compatible = "rockchip,rk3588-iommu", "rockchip,rk3568-iommu";
+		reg = <0x0 0xfdbef000 0x0 0x40>, <0x0 0xfdbef040 0x0 0x40>;
+		interrupts = <GIC_SPI 102 IRQ_TYPE_LEVEL_HIGH 0>,
+			     <GIC_SPI 103 IRQ_TYPE_LEVEL_HIGH 0>;
+		clocks = <&cru ACLK_RKVENC1>, <&cru HCLK_RKVENC1>;
+		clock-names = "aclk", "iface";
+		power-domains = <&power RK3588_PD_VENC1>;
+		rockchip,disable-mmu-reset;
+		#iommu-cells = <0>;
+	};
+
 	vdec0: video-codec@fdc38000 {
 		compatible = "rockchip,rk3588-vdec";
 		reg = <0x0 0xfdc38000 0x0 0x100>,

-- 
2.55.0

