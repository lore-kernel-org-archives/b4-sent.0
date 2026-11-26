From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v4 0/3] iommu/arm-smmu-v3: Keep the clock of the RK3588
 PCIe SMMU running
Date: Thu, 26 Nov 2026 09:54:12 +0000
Message-Id: <20261126-smmu-v3-pcie-pd-v4-0-c340c2dbd1d2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XNTQ6CMBQE4KuQrq3hvVagrryHcdGWAjXyEwqNh
 nB3KW5Q4nKS+WYm4kxvjSPnaCK98dbZtlkCP0REV7IpDbX5kgnGmABATF1dj9Qz2mlraJdTiQV
 gqjLIs4IsqutNYZ/r4vX2yW5Ud6OHMBMalXVD27/WSw+h93/dA41pglkGQkvOlbiUtbSPo25rE
 tY9bj3uPS6eyTRVSiUKNf/1bOvZ3rPghVG8ECBO+PU/z/MbLIR2xEABAAA=
X-Change-ID: 20261110-smmu-v3-pcie-pd-a2f127b81d8f
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795686852; l=2915;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=OykbgClr+ZRK4+0ppCdomu1EHFQbW+fawWJaWWyDfFk=;
 b=4w4KGwCAjg+suLsY7Wb+HjUF+MXqiHM+K6VvQS1vu8dKFbs1s3X6LFFI9MENRlif9M9NxN7S1
 uwd52RE1j4wBnUqWqyH26/yNQulQKg1cKZ6csv8oSQrHEfUy1zQE0eT
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On RK3588 boards without an enabled PCIe controller, ACLK_MMU_PCIE is
gated as unused while arm-smmu-v3 is bound to the PCIe SMMU, and reboot
hangs in arm_smmu_device_shutdown() until the watchdog fires.

Patches 1-2 are for the iommu tree, patch 3 for the Rockchip tree. The
clock can move into the runtime PM callbacks of Pranjal Shrivastava's
pending SMMUv3 sleep ops series once it lands.

Tested as v2 (same code apart from comments) on an Orange Pi 5 with the
M.2 slot in SATA mode: reboot reaches the boot loader in 0.59 s (was
~89 s, via the watchdog). The resets property is unused by the driver
and untested.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v4:
- 1/3: Acked-by Rob Herring
- 2/3: kept dev_err_probe(): the clk getters do not print, and the
  message records the deferral reason (Sebastian Reichel)
- 2/3, 3/3: shorter commit messages; 2/3: shorter comment
- Rebased
- Link to v3: https://patch.msgid.link/20261113-smmu-v3-pcie-pd-v3-0-39eb4f919529@gmail.com

Changes in v3:
- Shortened the commit messages and the cover letter, and dropped the
  "on SoCs where ..." part of the binding's clock description
  (Sebastian Reichel).
- Squashed the DTS reset patch into the clock patch (Sebastian Reichel).
  His Reviewed-by of the clock patch is kept.
- Dropped the description of the binding's resets property.
- No code changes.
- Link to v2: https://patch.msgid.link/20261112-smmu-v3-pcie-pd-v2-0-3a77bbb6b2c4@gmail.com

Changes in v2:
- Moved the fix for the Tegra CMDQV reference leak on a bad
  #iommu-cells (Sashiko AI review) to a separate patch.
- Dropped the power-domain patches: the TRM puts MMU600_PCIE in PD_PHP,
  which Linux does not control (Sebastian Reichel, Shawn Lin).
- Binding: one clock instead of up to four (Sashiko, Sebastian Reichel).
- Driver: one optional clock, got before the firmware probe so a failure
  cannot leak the CMDQV reference (Sashiko); shorter comment (Sebastian
  Reichel).
- Added the reset to the binding and the DTS (Sebastian Reichel).
- Link to v1: https://patch.msgid.link/20261110-smmu-v3-pcie-pd-v1-0-628819ca44b9@gmail.com

---
Arun Iyengar (3):
      dt-bindings: iommu: arm,smmu-v3: Allow a clock and a reset
      iommu/arm-smmu-v3: Enable an optional clock
      arm64: dts: rockchip: Add the clock and reset of the RK3588 PCIe SMMU

 Documentation/devicetree/bindings/iommu/arm,smmu-v3.yaml | 8 ++++++++
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi            | 2 ++
 drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c              | 8 ++++++++
 3 files changed, 18 insertions(+)
---
base-commit: c9b82d9808c4af1734e6d08f06fd411c30438ae8
change-id: 20261110-smmu-v3-pcie-pd-a2f127b81d8f

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

