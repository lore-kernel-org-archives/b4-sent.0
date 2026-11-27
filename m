From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH v3 0/6] PCI: cortina: Add CS7542 PCIe host and PHY support
Date: Fri, 27 Nov 2026 07:35:18 +0300
Message-Id: <20261127-b4-cs7542-pcie-v3-0-b067875c56da@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32PQW7DIBBFr2KxLpUZwAaveo8qCxiGhKq2E+NYi
 SLfvcSJqmza5Zf++/PmxjJNiTLrqhubaEk5jUMJ8q1ieHDDnngKJTOooRECJPeKY261An7ERBx
 AkdQWTWMNK9Bxopgu2+Dn7pHz2X8RzveVZ2Oi07lcmh815l0mjmPfp7mrfONsdFIhKWFa9I0NE
 rUxTnkfI0qBpIM3kb0adtWv31MuXzOOA4dWBq00ti5Ctyh2VzqkPI/TdXt5EZvBX98tgtdcYSA
 NtQiqVh/73qXv9yK7TS3wPw4Fj9pYZzHUnuIrvq7rD33C+JB+AQAA
X-Change-ID: 20261123-b4-cs7542-pcie-224e359c8698
To: Manivannan Sadhasivam <mani@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Jingoo Han <jingoohan1@gmail.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 Krzysztof Wilczynski <kwilczynski@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Stephen Boyd <sboyd@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, linux-pci@vger.kernel.org, 
 linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795754119; l=6590;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=He1ygiNhn7MuHnxW34XgN+E9O0v4Q9fVoe3AiJDzQXE=;
 b=22W0Np/U1X6ZDmEhM0+PZPEuqLYYVK5u4JM70zQIU41+UKnLxLycjNOf9hEMorqC2tDIwwUcQ
 yt57bMiTG5FARb5lz6srAoimHiwce6pjLL7lWcnyBf/+f+3vQDBXCif
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a Snow Bush PCIe SerDes PHY and DesignWare host glue for CS7542.
The combined global-controls prerequisite supplies PCIe gates and resets;
this series contains no separate or duplicate global-control driver.

Prerequisite on Linux v7.4-rc4: the combined clock/reset/pinctrl v4,
posted on 25 November:
https://lore.kernel.org/all/20261125-cs7542-syscon-v4-0-3337bb0d3b48@gmail.com/
Brian's review places the early clock and separately probing reset
providers in that prerequisite. Local v5 error-path corrections are
included in the current integration tests; they keep its PCIe clock/reset
IDs and consumer interface unchanged. Binding review remains ongoing.
Board DTS enablement is separate. Ethernet is not a prerequisite.

The host protects its 512-byte root configuration limit, owns the
combined INTx/MSI lifecycle and reads link status from the application
wrapper. Unused SATA mode, hotplug and suspend remain outside this support.

Before the reset timing change, an Almond+ Linux v7.4-rc4 RAM run passed with
all three Root Ports/endpoints and Root Port MSI enabled after enumeration.
xHCI serviced MSI-X interrupts with three vectors, then forced legacy INTx
with no MSI vectors, then restored MSI-X. Complete host unload/reload,
repeated enumeration, real PCI OF nodes and factory calibration/MAC NVMEM
lookups all passed. Two NE load/unload cycles and external LAN1 traffic
ran alongside the live PCIe hosts without changing their reset bits.
The watchdog automatically returned to the installed firmware; no flash
writes were performed.

The updated host compiled for ARM with reset-controller support enabled
and disabled. Its framework-disabled object has no unresolved reset
symbols. The current reset sequence also passed the error-path tests.

Earlier independent ARM GCC14.2 W=1 vmlinux/modules with PHY/host=m and
COMPILE_TEST=n, full combined multi_v7 built-in/module builds, binding
examples and actual-source config/DBI/probe/Root-Port/MSI tests passed.
Two expected reset-core WARN/-EBUSY traces came from the fixture's
intentional duplicate-exclusive NE reset requests, not PCIe operations.
The fixture did not reset an active NE DMA consumer.

The lock serializes MMIO against the IRQ latch and teardown; it cannot
eliminate a physical link transition before IRQ delivery. Link-loss gating
remains conservative no-retrain policy, not a newly established silicon
requirement for upstream RC configuration. Non-identity MSI bus-window
arithmetic has host-test coverage; the hardware run used this board's
existing windows and unchanged comparator tokens.

Final self-review also exercised the actual MSI/GPIO policy helpers in
12 GCC and Clang ASan/UBSan cases each. The independent ARM build of
vmlinux and modules with host/PHY=m, COMPILE_TEST=n and no platform series
passed again after those fixes. Exact Linux 6.18 ARM W=1 Werror objects
and the combined personal image build pass. An actual normal-image RAM
boot enumerated the three Root Ports and endpoints and reached its root
filesystem with 432844 KiB available to Linux, then the watchdog returned
automatically to unchanged NAND OpenWrt. This boot is not hardware fault
injection or a new non-identity DMA-window test. The two Wi-Fi Root Ports
share one physical PERST# GPIO; independent hotplug is not qualified.

Changes in v3:
- Hold the host reset through PHY preparation. Wait 10 ms before
  deasserting it and 10 ms afterwards before accessing the host.
- Drop the PCIe consumer's Kconfig select of RESET_CONTROLLER.
- Balance the PHY reference clock if power-on and its cleanup both fail.
- Put PERST# on the Root Port child; retain three independent hosts and
  acquire the board's shared Wi-Fi reset GPIO only once.
- Assert the core before clock/PHY setup and release endpoint PERST#
  after Root Port setup, using the standard reset configuration wait.
- Describe MSI addresses as internal PCI bus match tokens, preserve their
  tested values and reject overlap with translated PCI memory windows.
- Keep v2 config/DBI/IRQ serialization; describe the no-retrain latch as
  conservative software policy, with no physical link-loss race claim.
- Preserve pci=nomsi in post-enumeration setup; an uninitialized receiver
  must not be enabled. Skip the optional PERST# lookup when the Root Port
  has no reset-gpios, including builds with GPIOLIB disabled.
- Address Kconfig/include ordering, bounded polling constants, error
  response helper, block comments, formatting and cleanup labels.
- Move the global binding, clock gates and reset provider into the
  independent shared-controls prerequisite; drop former patches 2 and 3.
- Keep only DWC export, PHY, host and their ownership in this series.
- Preserve existing PCIe reset IDs 0..2 and clock IDs 3..5.
- Link to v2: https://patch.msgid.link/20261123-b4-cs7542-pcie-v2-0-f589a9cd0bef@gmail.com

---
Fil Dunsky (6):
      PCI: dwc: Export the multiplexed MSI interrupt handler
      dt-bindings: phy: Describe CS7542 PCIe SerDes
      phy: Add CS7542 PCIe SerDes support
      dt-bindings: PCI: Describe the CS7542 host controller
      PCI: cs7542: Add CS7542 PCIe host support
      MAINTAINERS: Add CS7542 PCIe support

 .../bindings/pci/cortina,cs7542-pcie.yaml          | 157 +++++
 .../bindings/phy/cortina,cs7542-pcie-phy.yaml      |  67 +++
 MAINTAINERS                                        |   6 +-
 drivers/pci/controller/dwc/Kconfig                 |  12 +
 drivers/pci/controller/dwc/Makefile                |   1 +
 drivers/pci/controller/dwc/pcie-cs7542.c           | 658 +++++++++++++++++++++
 drivers/pci/controller/dwc/pcie-designware-host.c  |   1 +
 drivers/phy/Kconfig                                |  11 +
 drivers/phy/Makefile                               |   2 +
 drivers/phy/phy-cs7542-pcie.c                      | 236 ++++++++
 10 files changed, 1150 insertions(+), 1 deletion(-)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-pcie-224e359c8698
prerequisite-change-id: 20261123-cs7542-syscon-273d545c7af2:v4
prerequisite-patch-id: a9208276c628f8741a807d0e5c5945d4bf211c8a
prerequisite-patch-id: 65d46bb3caaa8518ee561f65d3f603ade396fff9
prerequisite-patch-id: a0ed5fbcfa308b16eaf265371a6697ad0aea6802
prerequisite-patch-id: bb8ffd99cb30e5a0b47881f6ba19a36329d5f4f2
prerequisite-patch-id: 7fbe9405265ef3d1ec62811415a46c0061afd7c8
prerequisite-patch-id: 01ece2c91e080d5cae6af81944159373776484ca

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

