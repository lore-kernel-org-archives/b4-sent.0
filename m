From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:11:52 +0000
Subject: [PATCH 5/5] arm64: dts: rockchip: add the clock of the RK3588 PCIe
 SMMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-smmu-v3-pcie-pd-v1-5-628819ca44b9@gmail.com>
References: <20261110-smmu-v3-pcie-pd-v1-0-628819ca44b9@gmail.com>
In-Reply-To: <20261110-smmu-v3-pcie-pd-v1-0-628819ca44b9@gmail.com>
To: Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Niklas Cassel <cassel@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, iommu@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-rockchip@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294708; l=1149;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=bLcKcj+LRANwxoiMM46Cd89sIDqhd3QCt7Lj2mURtSQ=;
 b=z/amT++A9MqE0D1vOB9Z/nfaV7eqMvL0FbII2ljxfJoqQxQ3SwBJ94YvBvnKfIr81kZIptXkc
 /SnPZWdCfrxDT1hrAOLYlG9Pag59fuWPCU3SGV3HxnyEFzaypVbR4VF
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PCIe MMU-600 runs from ACLK_MMU_PCIE, which is also the parent of
the PCIe controllers' master clocks. When no PCIe controller is enabled,
nothing holds it and it gets gated as unused after boot, while
arm-smmu-v3 is still bound to the SMMU.

Describe the clock, so that the SMMU driver keeps it running.

Fixes: da92d3dfc871 ("arm64: dts: rockchip: enable the mmu600_pcie IOMMU on the rk3588 SoC")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
index bcd342c025c9..8eed22ca69ab 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
@@ -559,6 +559,7 @@ mmu600_pcie: iommu@fc900000 {
 			     <GIC_SPI 374 IRQ_TYPE_EDGE_RISING 0>,
 			     <GIC_SPI 367 IRQ_TYPE_EDGE_RISING 0>;
 		interrupt-names = "eventq", "gerror", "priq", "cmdq-sync";
+		clocks = <&cru ACLK_MMU_PCIE>;
 		#iommu-cells = <1>;
 		power-domains = <&power RK3588_PD_PCIE>;
 	};

-- 
2.55.0

