From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/5] iommu/arm-smmu-v3: power domain and clock of the
 RK3588 PCIe SMMU
Date: Tue, 10 Nov 2026 07:11:47 +0000
Message-Id: <20261110-smmu-v3-pcie-pd-v1-0-628819ca44b9@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDuQSUHFq5QuNJnoCLEhU0UQ7
 95Yl2/x/wHKWVihqw7IvInKZymgRwVu6peRUXwxWGNrIjKoMa64PTE5YUweexvINkNLvg1QqpQ
 5yP4/vt63dR1mdt9rA+f5A0Mz+z1zAAAA
X-Change-ID: 20261110-smmu-v3-pcie-pd-a2f127b81d8f
To: Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Niklas Cassel <cassel@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, iommu@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-rockchip@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294708; l=3396;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=YiFHdqWNwSB3JLobSnfZFcEq0DBZVx3dfBcT0SvTUnA=;
 b=vGVSbQIptB7q8Knk0YRw8Xy7JTTyVesyHrwcLDjVnBHlNDkoSbwifjktratUfAvNDDUMpG4+p
 v5zjYVT9qWFBXsurhLTIIauP1umEiJlnI1RR2u8dugIBvvQ5oXERsZW
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MMU-600 in front of the PCIe controllers of the Rockchip RK3588
(mmu600_pcie) is enabled for every RK3588 board, but its node describes
neither the power domain it lives in (RK3588_PD_PCIE) nor its clock
(ACLK_MMU_PCIE). Both are held by any enabled PCIe controller, which is
why nobody noticed: on a board that enables no PCIe controller in that
domain (an Orange Pi 5 with its M.2 slot in SATA mode, or any RK3588
board without PCIe), genpd powers the domain off and the clock framework
gates the clock as unused after boot, while arm-smmu-v3 stays bound.
At reboot, arm_smmu_device_shutdown() then writes CR0 and polls CR0ACK on
the dead block, the interconnect stalls, "reboot: Restarting system" is
never reached and the board only comes back ~90 s later when the
watchdog fires.

Patches 1 and 2 allow power-domains and clocks in the arm,smmu-v3
binding (arm,smmu.yaml already allows both for the earlier SMMUs).
Patch 3 makes the driver get and enable the clocks of its firmware node
before the first register access, for as long as it is bound; nodes
without clocks (and ACPI/IORT systems) are unaffected. Patches 4 and 5
describe the power domain and the clock in rk3588-base.dtsi. Both DT
patches are needed: with the power domain alone the clock is still
gated and the shutdown still hangs.

Related: Pranjal Shrivastava's "iommu/arm-smmu-v3: Add runtime PM
support" v11 (2026-09-29, 20260929034510.2023173-1-praan@google.com,
not merged) adds pm_domain-based runtime PM and resumes the SMMU around
shutdown, but has no clock handling. This series is compatible with it:
once it lands, the clocks from patch 3 should move into its runtime
suspend/resume callbacks.

Tested on an Orange Pi 5 (RK3588S) with the M.2 slot in SATA mode and
the root filesystem on the SATA SSD, where every reboot used to hang:
three consecutive reboots printed "reboot: Restarting system" and the
boot loader started 0.6 s later (previously ~89 s, from the watchdog);
clk_summary shows aclk_mmu_pcie enabled with iommu@fc900000 as consumer
and pm_genpd_summary shows PD_PCIE on; the SMMU probes as before and
SATA keeps running at 6.0 Gbps without errors. With patch 4 alone
(power domain, clock still gated) the reboot still hung at
"arm-smmu-v3 fc900000.iommu: shutdown" on the serial console. Boards
with PCIe enabled are already in the state these patches describe.

This series was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit messages, and I reviewed and tested
every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (5):
      dt-bindings: iommu: arm,smmu-v3: allow a power domain
      dt-bindings: iommu: arm,smmu-v3: allow clocks
      iommu/arm-smmu-v3: enable optional clocks
      arm64: dts: rockchip: add the PCIe power domain to the RK3588 PCIe SMMU
      arm64: dts: rockchip: add the clock of the RK3588 PCIe SMMU

 Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml | 10 ++++++++++
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi            |  2 ++
 drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c              |  7 +++++++
 3 files changed, 19 insertions(+)
---
base-commit: 2cf4be57b301ed2d7af82e70cff5dfd96894d8de
change-id: 20261110-smmu-v3-pcie-pd-a2f127b81d8f

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

