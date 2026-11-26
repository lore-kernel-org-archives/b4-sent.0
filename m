From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 09:54:15 +0000
Subject: [PATCH v4 3/3] arm64: dts: rockchip: Add the clock and reset of
 the RK3588 PCIe SMMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-smmu-v3-pcie-pd-v4-3-c340c2dbd1d2@gmail.com>
References: <20261126-smmu-v3-pcie-pd-v4-0-c340c2dbd1d2@gmail.com>
In-Reply-To: <20261126-smmu-v3-pcie-pd-v4-0-c340c2dbd1d2@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795686852; l=1037;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=t/g+pNBiRoD0rdFZrx0NxcKY5w4/gVZZrK4FzRkJKzY=;
 b=dVSUoKZCcDEloFC8vGOhrfdcx4yBewn57BI5g7crGv4jL/SfdhTDB9uFGDppVN77KMuJ8kT0C
 Tfb0dv1eFSWA8V3LiU8bhh9Xp7cBBr4nPLuYxSxqs9HaP1F07VPhODm
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With no PCIe controller enabled (e.g. Orange Pi 5, M.2 in SATA mode),
ACLK_MMU_PCIE is gated as unused and reboot hangs in SMMU shutdown.

Fixes: da92d3dfc871 ("arm64: dts: rockchip: enable the mmu600_pcie IOMMU on the rk3588 SoC")
Reviewed-by: Sebastian Reichel <sebastian.reichel@collabora.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
index aa69fd3793fd..45c1bb335447 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
@@ -559,6 +559,8 @@ mmu600_pcie: iommu@fc900000 {
 			     <GIC_SPI 374 IRQ_TYPE_EDGE_RISING 0>,
 			     <GIC_SPI 367 IRQ_TYPE_EDGE_RISING 0>;
 		interrupt-names = "eventq", "gerror", "priq", "cmdq-sync";
+		clocks = <&cru ACLK_MMU_PCIE>;
+		resets = <&cru SRST_A_MMU_PCIE>;
 		#iommu-cells = <1>;
 	};
 

-- 
2.55.0

