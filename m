From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:20:24 +0000
Subject: [PATCH v2 3/4] arm64: dts: rockchip: Add the clock of the RK3588
 PCIe SMMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-smmu-v3-pcie-pd-v2-3-3a77bbb6b2c4@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794471621; l=1677;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=bT4wW5fxE+lRE4iUQ2xEu2GNE9wpr1LdQatMTtwsJ4Y=;
 b=GhAq+MnnkgyIMxuNGov5TI+kHb/LxReTEmJLO905SXhtYgwWC85vQO5dIvKil11OUOwvvzYYG
 otr73P35N7oDWlqt2Qe+SGga2fJNEi74Q0coyoMuI4LBhq9vTEUKNEb
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MMU-600 for the PCIe controllers (mmu600_pcie) is enabled for every
RK3588 board, but its node does not describe its clock, ACLK_MMU_PCIE.
That gate is also the parent of the PCIe controllers' master clocks, so
on most boards an enabled PCIe controller keeps it running.

On a board that enables none of these PCIe controllers (the Orange Pi 5
with its M.2 slot in SATA mode is one), nothing holds the clock and it
is gated as unused late in boot, while arm-smmu-v3 is still bound to the
SMMU. The SMMU registers then stop responding: at reboot,
arm_smmu_device_shutdown() writes CR0 and polls CR0ACK, the kernel never
reaches "reboot: Restarting system" and the board only comes back once
the watchdog fires.

Describe the clock, so that the SMMU driver keeps it running for as long
as it is bound.

Fixes: da92d3dfc871 ("arm64: dts: rockchip: enable the mmu600_pcie IOMMU on the rk3588 SoC")
Reviewed-by: Sebastian Reichel <sebastian.reichel@collabora.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
index aa69fd3793fd..dfed34a8aa57 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
@@ -559,6 +559,7 @@ mmu600_pcie: iommu@fc900000 {
 			     <GIC_SPI 374 IRQ_TYPE_EDGE_RISING 0>,
 			     <GIC_SPI 367 IRQ_TYPE_EDGE_RISING 0>;
 		interrupt-names = "eventq", "gerror", "priq", "cmdq-sync";
+		clocks = <&cru ACLK_MMU_PCIE>;
 		#iommu-cells = <1>;
 	};
 

-- 
2.55.0

