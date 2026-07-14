From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH v3 0/3] PCI: ultrarisc: Add DP1000 PCIe clock support
Date: Tue, 14 Jul 2026 09:11:01 +0800
Message-Id: <20260714-ultrarisc-pci-clk-v3-0-e72723fc0ef1@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAKWMVWoC/23Nyw6CMBQE0F8hXVvThxZx5X8YF225lesDSAuNh
 vDvFjSaGJaTzJwZSACPEMg+G4iHiAGbOgW5yoitdH0GimXKRDChmOI57W+d1x6Dpa1Fam9Xqi0
 v2CbXjoMmadd6cPiYzePpnUNvLmC7CZoaFYau8c/5NPKp9/FFseBHThndgpaS7VypjTx8O2vb3
 Mn0EcVPyZlaUkRShJPOKGe0UuZfGcfxBRQjU7UOAQAA
X-Change-ID: 20260617-ultrarisc-pci-clk-ac19047af1ea
To: Xincheng Zhang <zhangxincheng@ultrarisc.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783991481; l=2995;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=2okLRAGbVQqKklUYGWmJ7tyA+p3vyLm+/B5mkepvT5Y=;
 b=PMqfwG3L/HPPIM7FZXN8QLT8vF5qGlTEcsmO7O2+RjQAIHyJ7ZeLJpxQgTkzrkK7U3NqTCTXH
 nDKJzlPRWvxDi0rmUvbOf5DLuRDJjhg5buBapFyxEWWuIVl333CFIcQ
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add clock handling for the UltraRISC DP1000 DesignWare PCIe host
controller.

The DP1000 PCIe controller depends on three input clocks: core, dbi, and
aux. The driver accesses DBI registers during host initialization, so the
clocks must be enabled before the controller registers are touched.

This series documents the required clocks in the device tree binding,
enables the core, dbi, and aux clocks before DesignWare host
initialization, and keeps them managed across probe failure, detach, and
system suspend/resume. It also switches the driver to
module_platform_driver() so the existing tristate Kconfig option builds
correctly as a module.

Testing:
- Build and module build tested with ARCH=riscv.
- Boot tested on UltraRISC DP1000.
- Validated the PCIe binding with dt_binding_check and dtbs_check.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
Changes in v3:
- Track whether the PCIe clocks are enabled and make clock enable/disable
  helpers idempotent.
- Skip dw_pcie_suspend_noirq() when the controller is already suspended to
  avoid register access with clocks disabled after a failed resume.
- Disable clocks again if dw_pcie_resume_noirq() fails after clocks were
  re-enabled.
- Add a remove callback to deinitialize the DesignWare host when the module
  build support is added.
- Link to v2: https://patch.msgid.link/20260706-ultrarisc-pci-clk-v2-0-2f3fb6fba66b@ultrarisc.com

Changes in v2:
- Add Fixes and Acked-by tags to the binding patch.
- Add a Fixes tag to the driver clock handling patch.
- Fix the suspend/resume clock handling so clocks are disabled only after a
  successful suspend and kept enabled on resume failure.
- Add a module build fix by switching to module_platform_driver().
- Link to v1: https://patch.msgid.link/20260629-ultrarisc-pci-clk-v1-0-5ea3308fdab3@ultrarisc.com

To: Xincheng Zhang <zhangxincheng@ultrarisc.com>
To: Jia Wang <wangjia@ultrarisc.com>
To: Lorenzo Pieralisi <lpieralisi@kernel.org>
To: Krzysztof Wilczyński <kwilczynski@kernel.org>
To: Manivannan Sadhasivam <mani@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Bjorn Helgaas <bhelgaas@google.com>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Cc: linux-pci@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Jia Wang (3):
      dt-bindings: pci: ultrarisc: add required DP1000 PCIe clocks
      PCI: ultrarisc: get and enable DP1000 PCIe clocks
      PCI: ultrarisc: allow DP1000 driver to build as module

 .../bindings/pci/ultrarisc,dp1000-pcie.yaml        |  16 +++
 drivers/pci/controller/dwc/pcie-ultrarisc.c        | 112 +++++++++++++++++++--
 2 files changed, 120 insertions(+), 8 deletions(-)
---
base-commit: a13c140cc289c0b7b3770bce5b3ad42ab35074aa
change-id: 20260617-ultrarisc-pci-clk-ac19047af1ea

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

