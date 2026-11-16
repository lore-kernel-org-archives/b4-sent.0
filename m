From: Matt Thompson <matt@boondocker.io>
Subject: [PATCH RFC v3 0/6] PCI: rockchip-host: Handle unavailable
 downstream config space
Date: Mon, 16 Nov 2026 02:35:42 -0700
Message-Id: <20261116-rfc-b4-v3-0-0bf052b68f2a@boondocker.io>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG7O+moC/22NzQrCMBAGX6Xs2Ug2bSLxJAg+gFfx0PzURqGRp
 Aal9N1N4614/JaZ2QmiDc5G2FcTBJtcdH7Io95UoPt2uFniTN7AKBOIWJPQaaIaItROcsVrYWQ
 LGX4G27l3CV3gfDrC9XeML3W3elwSC9a7OPrwKe8SFnhdTkgoURKNVpwyxulBeT8Yrx82bJ0v4
 cT+qyyrRihsOsk1GrFW53n+AqD9x87yAAAA
X-Change-ID: 20261113-rfc-b4-6b795b536d9a
To: Shawn Lin <shawn.lin@rock-chips.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>
Cc: Rob Herring <robh@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 linux-pci@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794821744; l=3925;
 i=matt@boondocker.io; s=rk3399-rfc-20261113; h=from:subject:message-id;
 bh=32ugxZ9YhRZmQLH1EfOQDSlBHTw79cq4a8bA5dFZ1lQ=;
 b=UODUueP6aJsGykruLNX++bgYLoLqRjAPAex3aYOzj24x9UodGmKQ8UXcyoxw5Mh6O/Yl2msMi
 /dH+q0SZmyqBqj1VV4NU71XxHOkZAw/HjjWqqymrT9IF6aa4iJvbc6t
X-Developer-Key: i=matt@boondocker.io; a=ed25519;
 pk=WMnh3kwFFRkrqamL/FbDcdl1/9rBF2uT03VdvGGP40k=
X-Endpoint-Received: by B4 Relay for matt@boondocker.io/rk3399-rfc-20261113 with auth_id=1517
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a RockPro64 v2.1 with a Kintex-7 FPGA endpoint, a downstream vendor
ID read during a PCI rescan raised a synchronous external abort
(ESR 0x96000210). The rescan task exited with IRQs disabled and the
watchdog reported a lockup.

Patches 1 through 3 retain the downstream link check, the guarded
arm64 read fixup, and the AXI link-down latch handling. The fixup
handles current-EL synchronous external read aborts at the annotated
instructions.

Testing repeated re-enable, retrain, and rescan exposed three further
failures:

- PCI runtime resume replayed a saved Link Disable bit after userspace
  cleared it. Patch 4 resumes the port before a sysfs write to Link
  Control while holding the configuration access runtime PM reference.
- The PHY could reach L0 while the data link stayed in initialization.
  Patch 5 retains an early retrain request and issues it once if a
  later downstream access finds initialization still pending.
- The Rockchip PCIe client correctable-error interrupt fired at about
  one million interrupts per second on CPU 0 and starved RCU. Patch 6
  masks that controller-local notification. The standard AER service
  remains on the root port's separate interrupt.

Validation used upstream commit 97d73c825122, these six patches, and
Igor Velkov's separately posted probe and resume retry patch [1]. The
combined source matches the audit branch [2]. The clean kernel
completed 600 disable, re-enable, retrain, and rescan cycles with
runtime PM set to auto. Each cycle found the FPGA without a driver
rebind or a second userspace retrain request. The board stayed on the
same boot, the client IRQ count remained zero, and the kernel logged
no stall or SError. This test did not reproduce the asynchronous SError
that Igor reported on Helios64 [3].

[1] https://lore.kernel.org/r/20261116-rockchip-pcie-resume-v2-1-a633e279be97@iav.lv
[2] https://github.com/boondocklabs/linux/commit/bb7c4f9ee7ed33fc32832060fdecb9115c8e9630
[3] https://lore.kernel.org/r/20261116-rockchip-host-rfc-v2-test-1@iav.lv

---
Changes in v3:
- Add the Fixes tag to the downstream link-state check.
- Resume a suspended downstream port before sysfs Link Control writes.
- Defer early retrain requests when the PHY is still training.
- Mask the Rockchip client correctable-error interrupt.
- Record the 600-cycle RockPro64 test with Igor's separate patch applied.
- Link to v2: https://lore.kernel.org/r/20261113-rfc-b4-v2-0-d6b14f95c1d6@boondocker.io

Changes in v2:
- Restrict the MMIO read fixup to the SEA path and exclude its
  exception-table type from user-access classification.
- Look up the guarded instruction once on the SEA path.
- Use the standard arm64 register-number encoding helpers in
  the exception-table macro (Sashiko review).
- Link to v1: https://lore.kernel.org/r/20261113-rfc-b4-v1-0-b91dcb502250@boondocker.io

---
Matt Thompson (6):
      PCI: rockchip-host: Skip downstream config access while link is down
      arm64: Allow synchronous abort fixups for guarded MMIO reads
      PCI: rockchip-host: Recover downstream configuration access
      PCI: Resume downstream ports before sysfs Link Control writes
      PCI: rockchip-host: Defer retraining during initial link training
      PCI: rockchip-host: Mask the client correctable error interrupt

 arch/arm64/include/asm/asm-extable.h        |  15 ++++
 arch/arm64/mm/extable.c                     |  20 +++++
 arch/arm64/mm/fault.c                       |   4 +
 drivers/pci/controller/pcie-rockchip-host.c | 119 +++++++++++++++++++++++++++-
 drivers/pci/controller/pcie-rockchip.h      |   4 +
 drivers/pci/pci-sysfs.c                     |  16 ++++
 6 files changed, 176 insertions(+), 2 deletions(-)
---
base-commit: 97d73c8251226cf27cc6656b4c542869bb8c69fa
change-id: 20261113-rfc-b4-6b795b536d9a

Best regards,
--  
Matt Thompson <matt@boondocker.io>

