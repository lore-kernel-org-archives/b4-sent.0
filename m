From: Matt Thompson <matt@boondocker.io>
Subject: [PATCH RFC v2 0/3] PCI: rockchip-host: Handle unavailable
 downstream config space
Date: Fri, 13 Nov 2026 17:52:18 -0700
Message-Id: <20261113-rfc-b4-v2-0-d6b14f95c1d6@boondocker.io>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMOw92oC/12NQQrCMBBFr1JmbSRJTaWuBMEDuJUuOsnUjkIjS
 S1K6d1N487l+zzenyFSYIpwKGYINHFkPyTQmwJs3w43EuwSg5a6UkqVInRW4E5UuK8NmrJydQt
 Jfgbq+J1DV7icT9D8xvjCO9lxTaxaz3H04ZPvJpXl//KkhBRYK2fRSK2NPKL3g/P2QWHLHpplW
 b4RYmE+twAAAA==
X-Change-ID: 20261113-rfc-b4-6b795b536d9a
To: Shawn Lin <shawn.lin@rock-chips.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>
Cc: Rob Herring <robh@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 linux-pci@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794617540; l=2945;
 i=matt@boondocker.io; s=rk3399-rfc-20261113; h=from:subject:message-id;
 bh=u8NC1h2UFOo1v6PYckTyaAJW66VhB2jXXpyJT0WEzzE=;
 b=OwCULHv2DTo7iZm5pH4MrnKZdJGHc4Pm+X0UKcVZOeVooF2AHEUEMn0dyo3IqMpyHEB/nI9pb
 OIJlGYE7jVmDKXVtsSqLepnrFpddKUXdTrx7bzBJffKITc/dqVy1lzq
X-Developer-Key: i=matt@boondocker.io; a=ed25519;
 pk=WMnh3kwFFRkrqamL/FbDcdl1/9rBF2uT03VdvGGP40k=
X-Endpoint-Received: by B4 Relay for matt@boondocker.io/rk3399-rfc-20261113 with auth_id=1517
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a RockPro64 v2.1 with a Kintex-7 FPGA endpoint, a downstream
vendor-ID read during a PCI rescan raised a synchronous external
abort (ESR 0x96000210) in rockchip_pcie_rd_conf(). The rescan task
exited with IRQs disabled and a watchdog lockup followed.

The first patch skips downstream config accesses while the controller
reports the link unavailable. The remaining patches handle synchronous
external aborts on explicitly annotated arm64 config reads, including
when the link changes after the status check. The final patch also
clears the AXI link-down latch before downstream config accesses
once the controller reports the link ready.

The arm64 change is limited to marked load instructions. Asynchronous
SError, BAR accesses, and config writes that race a link change are
outside that recovery path. Feedback on the exception-table interface
and whether the controller can handle absent completions directly is
welcome.

A related discussion covers an RK3399 endpoint that trains but fails
to answer config requests:
https://lore.kernel.org/linux-pci/20261024-rockchip-pcie-resume-v1-0-58e54a5cf5f1@iav.lv/

Validation: applied these three RFC patches to upstream commit
97d73c8251226cf27cc6656b4c542869bb8c69fa and booted the resulting
7.4.0-rc2 kernel on a RockPro64 v2.1. The test config enabled Rust
and built in the required board drivers.

Three test cycles completed on the v2 kernel. Each removed the FPGA
from Linux, disabled the link and rescanned, then re-enabled the link,
requested retraining and rescanned. The FPGA stayed absent in each
disabled scan and returned at 01:00.0 after each retrain without a host
driver rebind. The log showed no synchronous external abort or
watchdog lockup. The test did not establish whether the arm64 fixup ran.

---
Changes in v2:
- Restrict the MMIO read fixup to the SEA path and exclude its
  exception-table type from user-access classification.
- Look up the guarded instruction once on the SEA path.
- Use the standard arm64 register-number encoding helpers in
  the exception-table macro (Sashiko review).
- Link to v1: https://patch.msgid.link/20261113-rfc-b4-v1-0-b91dcb502250@boondocker.io

---
Matt Thompson (3):
      PCI: rockchip-host: Skip downstream config access while link is down
      arm64: Allow synchronous abort fixups for guarded MMIO reads
      PCI: rockchip-host: Recover downstream configuration access

 arch/arm64/include/asm/asm-extable.h        | 15 +++++++
 arch/arm64/mm/extable.c                     | 20 +++++++++
 arch/arm64/mm/fault.c                       |  4 ++
 drivers/pci/controller/pcie-rockchip-host.c | 68 +++++++++++++++++++++++++++++
 drivers/pci/controller/pcie-rockchip.h      |  1 +
 5 files changed, 108 insertions(+)
---
base-commit: a72c40386d63746568fb027900faaa8ec0054127
change-id: 20261113-rfc-b4-6b795b536d9a

Best regards,
--  
Matt Thompson <matt@boondocker.io>

