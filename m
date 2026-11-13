From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:38:54 +0000
Subject: [PATCH 8/9] arm64: dts: rockchip: Attach the masters of the RK3588
 PHP SMMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-mmu600-php-v1-8-231196049a3b@gmail.com>
References: <20261113-mmu600-php-v1-0-231196049a3b@gmail.com>
In-Reply-To: <20261113-mmu600-php-v1-0-231196049a3b@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, Damien Le Moal <dlemoal@kernel.org>, 
 Niklas Cassel <cassel@kernel.org>, Serge Semin <fancer.lancer@gmail.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-ide@vger.kernel.org, 
 Pranjal Shrivastava <praan@google.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, iommu@lists.linux.dev, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794587927; l=3063;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Eywo1baNrJ1Su6epW6UvLlR5LbuALQF4wCpKeTucpp0=;
 b=nZdrYLxPkrM8t5kgc8zE46GmG7YiEe37zQU/0qimGODqdNWa1XU0hl4ibHEnRFGyNy0jrx5Wz
 AIpNMKWpha+CX4LhWo3q5qXrGXglhp81dgdSq7IpUmmNkhylyT/XD48
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

GMAC0/1, SATA0-2 and USB3OTG_2 are behind MMU600_PHP with StreamIDs
1-6. No effect until the SMMU is enabled.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi  | 4 ++++
 arch/arm64/boot/dts/rockchip/rk3588-extra.dtsi | 2 ++
 2 files changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
index 3bf8d0e4ff33..cb0a39f63788 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
@@ -534,6 +534,7 @@ usb_host2_xhci: usb@fcd00000 {
 		compatible = "rockchip,rk3588-dwc3", "snps,dwc3";
 		reg = <0x0 0xfcd00000 0x0 0x400000>;
 		interrupts = <GIC_SPI 222 IRQ_TYPE_LEVEL_HIGH 0>;
+		iommus = <&mmu600_php 6>;
 		clocks = <&cru REF_CLK_USB3OTG2>, <&cru SUSPEND_CLK_USB3OTG2>,
 			 <&cru ACLK_USB3OTG2>, <&cru CLK_UTMI_OTG2>,
 			 <&cru CLK_PIPEPHY2_PIPE_U3_G>;
@@ -2310,6 +2311,7 @@ gmac1: ethernet@fe1c0000 {
 		interrupts = <GIC_SPI 234 IRQ_TYPE_LEVEL_HIGH 0>,
 			     <GIC_SPI 233 IRQ_TYPE_LEVEL_HIGH 0>;
 		interrupt-names = "macirq", "eth_wake_irq";
+		iommus = <&mmu600_php 2>;
 		clocks = <&cru CLK_GMAC_125M>, <&cru CLK_GMAC_50M>,
 			 <&cru PCLK_GMAC1>, <&cru ACLK_GMAC1>,
 			 <&cru CLK_GMAC1_PTP_REF>;
@@ -2357,6 +2359,7 @@ sata0: sata@fe210000 {
 		compatible = "rockchip,rk3588-dwc-ahci", "snps,dwc-ahci";
 		reg = <0 0xfe210000 0 0x1000>;
 		interrupts = <GIC_SPI 273 IRQ_TYPE_LEVEL_HIGH 0>;
+		iommus = <&mmu600_php 3>;
 		clocks = <&cru ACLK_SATA0>, <&cru CLK_PMALIVE0>,
 			 <&cru CLK_RXOOB0>, <&cru CLK_PIPEPHY0_REF>,
 			 <&cru CLK_PIPEPHY0_PIPE_ASIC_G>;
@@ -2380,6 +2383,7 @@ sata2: sata@fe230000 {
 		compatible = "rockchip,rk3588-dwc-ahci", "snps,dwc-ahci";
 		reg = <0 0xfe230000 0 0x1000>;
 		interrupts = <GIC_SPI 275 IRQ_TYPE_LEVEL_HIGH 0>;
+		iommus = <&mmu600_php 5>;
 		clocks = <&cru ACLK_SATA2>, <&cru CLK_PMALIVE2>,
 			 <&cru CLK_RXOOB2>, <&cru CLK_PIPEPHY2_REF>,
 			 <&cru CLK_PIPEPHY2_PIPE_ASIC_G>;
diff --git a/arch/arm64/boot/dts/rockchip/rk3588-extra.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-extra.dtsi
index 2bcf30d8a338..425770a8ff61 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-extra.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-extra.dtsi
@@ -538,6 +538,7 @@ gmac0: ethernet@fe1b0000 {
 		interrupts = <GIC_SPI 227 IRQ_TYPE_LEVEL_HIGH 0>,
 			     <GIC_SPI 226 IRQ_TYPE_LEVEL_HIGH 0>;
 		interrupt-names = "macirq", "eth_wake_irq";
+		iommus = <&mmu600_php 1>;
 		clocks = <&cru CLK_GMAC_125M>, <&cru CLK_GMAC_50M>,
 			 <&cru PCLK_GMAC0>, <&cru ACLK_GMAC0>,
 			 <&cru CLK_GMAC0_PTP_REF>;
@@ -585,6 +586,7 @@ sata1: sata@fe220000 {
 		compatible = "rockchip,rk3588-dwc-ahci", "snps,dwc-ahci";
 		reg = <0 0xfe220000 0 0x1000>;
 		interrupts = <GIC_SPI 274 IRQ_TYPE_LEVEL_HIGH 0>;
+		iommus = <&mmu600_php 4>;
 		clocks = <&cru ACLK_SATA1>, <&cru CLK_PMALIVE1>,
 			 <&cru CLK_RXOOB1>, <&cru CLK_PIPEPHY1_REF>,
 			 <&cru CLK_PIPEPHY1_PIPE_ASIC_G>;

-- 
2.55.0

