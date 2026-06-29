From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH 0/2] PCI: ultrarisc: Add DP1000 PCIe clock support
Date: Mon, 29 Jun 2026 13:59:49 +0800
Message-Id: <20260629-ultrarisc-pci-clk-v1-0-5ea3308fdab3@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANUJQmoC/yXMQQqDQAxA0atI1gZmpCj1KuIiprFNKyqJUwri3
 Tu2y7f4fwcXU3Foix1M3uq6zBmxLIAfNN8F9ZYNVajqUMcG07QZmTrjyoo8vZA4XsOloTEKQe5
 Wk1E/v2fX/+1peApv5wiO4wsWHP8VdQAAAA==
X-Change-ID: 20260617-ultrarisc-pci-clk-ac19047af1ea
To: Xincheng Zhang <zhangxincheng@ultrarisc.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782712801; l=1358;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=I2rovNTFCnQGV7yVPJLdnI5nWXDV0HPkDuEeWfEqjY8=;
 b=eKf6kc1lr6911TENYLvqSzu6t+q65lQ4mXFQ+QSVohXQFtfJeRcTkYl6Mx2tCoCG4f064Atm0
 9dcuTnh39eoDLh3gbxQbQMDl+aSkKk7TYe46OsMybDrdvtZa/snonFV
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add clock handling for the UltraRISC DP1000 DesignWare PCIe host
controller.

The DP1000 PCIe controller depends on three input clocks: core, dbi, and
aux. The driver accesses DBI registers during host initialization, so the
clocks must be enabled before the controller registers are touched.

This series documents the required clocks in the device tree binding and
updates the driver to get and enable them during probe. The driver keeps
the clock data alongside struct dw_pcie, uses the bulk clock API to
acquire and enable the clocks, and registers a managed cleanup action to
disable them on failure or detach.

Testing:
- Build and module build tested with ARCH=riscv.
- Boot tested on UltraRISC DP1000.
- Validated the PCIe binding with dt_binding_check and dtbs_check.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
Jia Wang (2):
      dt-bindings: pci: ultrarisc: add required DP1000 PCIe clocks
      PCI: ultrarisc: get and enable DP1000 PCIe clocks

 .../bindings/pci/ultrarisc,dp1000-pcie.yaml        | 16 +++++
 drivers/pci/controller/dwc/pcie-ultrarisc.c        | 74 ++++++++++++++++++++--
 2 files changed, 83 insertions(+), 7 deletions(-)
---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260617-ultrarisc-pci-clk-ac19047af1ea

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

