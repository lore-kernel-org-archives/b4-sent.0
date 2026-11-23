From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH 0/8] soc: cortina: Add CS7542 PCIe control, SerDes and host
 support
Date: Mon, 23 Nov 2026 21:43:28 +0300
Message-Id: <20261123-b4-cs7542-pcie-v1-0-4cde5201d404@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/z2OzW7DIBCEX8Xi3K0CLAR86ntUOcB6SalqO/U6U
 aMo7x7yox5HmvnmuyjhpbKovruohU9V6jy1oN86RV9p2jPUoWVlNsZrbSxkBJKtQwMHqgzGIFs
 XKfgYVBsdFi717wH83D2zHPM303qnvBoL/x7b0/qsqZyEgeZxrGvfZZ9iSRaJUYctZR8HSy6Eh
 DmXQlYTuyGHckeNLJIein33L/iyk7PQPMFJwwYwBhfYW40YP/Zjqj/v7U7trtcbOhs3wAABAAA
 =
X-Change-ID: 20261123-b4-cs7542-pcie-224e359c8698
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Vinod Koul <vkoul@kernel.org>
Cc: Jingoo Han <jingoohan1@gmail.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 Krzysztof Wilczynski <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 linux-pci@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-clk@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459409; l=4046;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=+KcFkt6zaT2tLskeXzg7MF3C8vczJ1q0kPo5HltV7rw=;
 b=GnuNQHWYPkVabRpyNN2+KF3Y7yNbrHsQgfpZyeLrU2LLjENAKS96MYUxuLBhOL3HcUAM6syEF
 QCNXfcsW9N9A/On1z70S1EvDNdDZGqy9+hp92KdS8TkikNtK6iuzPht
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add PCIe support for the Cortina Systems CS7542, with the shared global
controls, Snow Bush SerDes and DesignWare host glue in separate drivers.
Each controller consumes a clock gate, reset line and generic PHY rather
than modifying the global registers directly.

This series depends on the CS7542 global clock/pinctrl v1 series:
https://lore.kernel.org/all/20261123-cs7542-syscon-v1-0-49858e631449@gmail.com/
Both series are based on Linux v7.4-rc4. Board DTS enablement is kept in
the integration test branch and is not part of these eight driver patches.

The host protects the hardware's 512-byte root configuration limit for
both PCI config operations and direct DBI callbacks, while preserving
access to the private DesignWare register bank and separate iATU base.
It reads live link/LTSSM state from the application wrapper and owns the
combined INTx/MSI interrupt lifecycle.
Clock rates for the controller gates are not inferred; only the SerDes
reference is required to be 24 MHz. SATA mode, hotplug and suspend/resume
are outside the support described by this first version.

Validation:
- Full ARM GCC 14.2 vmlinux+modules for all three new drivers built-in and
  as modules, COMPILE_TEST=n, without the Cortina platform series.
- DT schema/examples, strict source checkpatch, and 49298 UBSan cases
  executing actual config/DBI/link callbacks, including fatal-link guards.
- Almond+ RAM Linux 7.4-rc4: 73 checks / 0 failures; all three endpoints enumerate; xHCI No-op
  commands complete through real MSI-X and INTx interrupts. Module removal,
  injected CMU timeout on every lane, cleanup and subsequent recovery pass.
- With unused SATA gates disabled, the shared PHY status still works.
  Link loss blocks DBI/config until controller reprobe, which restores it;
  a held-reset endpoint safely leaves a root-only bus.
- Shared global register bits are preserved. The RAM program has no MTD
  support and performs no flash I/O. The installed firmware remains intact.

---
Fil Dunsky (8):
      PCI: dwc: Export the multiplexed MSI interrupt handler
      dt-bindings: clock: Describe CS7542 PCIe gates and resets
      clk: Add CS7542 PCIe gates and resets
      dt-bindings: phy: Describe CS7542 PCIe SerDes
      phy: Add CS7542 PCIe SerDes support
      dt-bindings: PCI: Describe the CS7542 host controller
      PCI: cs7542: Add CS7542 PCIe host support
      MAINTAINERS: Add CS7542 PCIe support

 .../clock/cortina,cs7542-pcie-control.yaml         |  47 ++
 .../bindings/pci/cortina,cs7542-pcie.yaml          | 127 ++++++
 .../bindings/phy/cortina,cs7542-pcie-phy.yaml      |  67 +++
 .../soc/cortina/cortina,cs7542-syscon.yaml         |   4 +
 MAINTAINERS                                        |   8 +-
 drivers/clk/Kconfig                                |  11 +
 drivers/clk/Makefile                               |   2 +
 drivers/clk/clk-cs7542-pcie.c                      | 168 +++++++
 drivers/pci/controller/dwc/Kconfig                 |  12 +
 drivers/pci/controller/dwc/Makefile                |   2 +
 drivers/pci/controller/dwc/pcie-cs7542.c           | 508 +++++++++++++++++++++
 drivers/pci/controller/dwc/pcie-designware-host.c  |   1 +
 drivers/phy/Kconfig                                |  11 +
 drivers/phy/Makefile                               |   2 +
 drivers/phy/phy-cs7542-pcie.c                      | 232 ++++++++++
 15 files changed, 1201 insertions(+), 1 deletion(-)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-pcie-224e359c8698
prerequisite-message-id: 20261123-cs7542-syscon-v1-0-49858e631449@gmail.com
prerequisite-patch-id: 4b568d742095f1a61312c911d2b6e81c8e754312
prerequisite-patch-id: a4bba26a3aac57e4e4229a727fdf94677373493a
prerequisite-patch-id: f8a2ba71717f71ca2bedda986f8b861995cdc586
prerequisite-patch-id: 7a2275c69dcde437fc8badf2bba06d451943a66f
prerequisite-patch-id: 25220835f5d2506a01ba652d86f9b9ac3ad5121a

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

