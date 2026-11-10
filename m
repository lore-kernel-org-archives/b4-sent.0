From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:11:51 +0000
Subject: [PATCH 4/5] arm64: dts: rockchip: add the PCIe power domain to the
 RK3588 PCIe SMMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-smmu-v3-pcie-pd-v1-4-628819ca44b9@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294708; l=1589;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=XjCTjW7WX2P6Yil1lroIFdMhtw3N6JLNEl/nbTe3Rtc=;
 b=KT3JAHOImp1NNVgBlK1O+84HkPyq2khzDT/ZgpgGMhXk6Q8ZUnIvjXRkQhFMFSDOZHumy00Z7
 ROfIwWwGlmIC+fICCGyWRiAcj/Z0XCId4AlPvl96YptG5dDrNNRRMd9
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MMU-600 for the PCIe controllers (mmu600_pcie) is enabled for every
RK3588 board, but its node does not describe that it lives in
RK3588_PD_PCIE. It only works today because TF-A leaves the domain on at
boot and, on most boards, an enabled PCIe controller holds it on later.

On a board that disables all PCIe controllers using that domain (the
Orange Pi 5 with its M.2 slot in SATA mode is one), genpd powers
PD_PCIE off as unused after boot while arm-smmu-v3 is still bound. Then
at reboot arm_smmu_device_shutdown() writes CR0 and polls CR0ACK on the
unpowered block, which stalls the bus: the kernel never reaches
"reboot: Restarting system" and the board only comes back once the
watchdog fires.

Describe the power domain, so genpd keeps it on for as long as the SMMU
is bound.

Fixes: da92d3dfc871 ("arm64: dts: rockchip: enable the mmu600_pcie IOMMU on the rk3588 SoC")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
index aa69fd3793fd..bcd342c025c9 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588-base.dtsi
@@ -560,6 +560,7 @@ mmu600_pcie: iommu@fc900000 {
 			     <GIC_SPI 367 IRQ_TYPE_EDGE_RISING 0>;
 		interrupt-names = "eventq", "gerror", "priq", "cmdq-sync";
 		#iommu-cells = <1>;
+		power-domains = <&power RK3588_PD_PCIE>;
 	};
 
 	mmu600_php: iommu@fcb00000 {

-- 
2.55.0

