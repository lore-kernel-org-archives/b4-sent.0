From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:20:25 +0000
Subject: [PATCH v2 4/4] arm64: dts: rockchip: Add the reset of the RK3588
 PCIe SMMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-smmu-v3-pcie-pd-v2-4-3a77bbb6b2c4@gmail.com>
References: <20261112-smmu-v3-pcie-pd-v2-0-3a77bbb6b2c4@gmail.com>
In-Reply-To: <20261112-smmu-v3-pcie-pd-v2-0-3a77bbb6b2c4@gmail.com>
To: Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Niklas Cassel <cassel@kernel.org>
Cc: Pranjal Shrivastava <praan@google.com>, 
 linux-arm-kernel@lists.infradead.org, iommu@lists.linux.dev, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-rockchip@lists.infradead.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>, Simon Xue <xxm@rock-chips.com>, 
 Finley Xiao <finley.xiao@rock-chips.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794471621; l=901;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=yMU3CRWnB+XjuBD0UcTK2F5C3aJnFDvPe+6GBdY2fjI=;
 b=y93n/EpF6PWfLsnsaGUaIrO2x+dm5s9ksej3O2HvYP5uoOYvsWIgrwvy3c1b9Y//j0fLwRh9p
 FrDhoOPM321Ah3I01Gz/9hNlI/hAe8q5/i9zBRk7U0Rw2yNf8aNV4Gk
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MMU-600 for the PCIe controllers (mmu600_pcie) has a reset line in
the CRU, SRST_A_MMU_PCIE, which its node does not describe. Add it, so
that the node describes both the clock and the reset of the MMU-600.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
index dfed34a8aa57..45c1bb335447 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
@@ -560,6 +560,7 @@ mmu600_pcie: iommu@fc900000 {
 			     <GIC_SPI 367 IRQ_TYPE_EDGE_RISING 0>;
 		interrupt-names = "eventq", "gerror", "priq", "cmdq-sync";
 		clocks = <&cru ACLK_MMU_PCIE>;
+		resets = <&cru SRST_A_MMU_PCIE>;
 		#iommu-cells = <1>;
 	};
 

-- 
2.55.0

