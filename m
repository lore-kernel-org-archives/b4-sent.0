From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH 0/4] riscv: Add PCIe support for UltraRISC DP1000 SoC
Date: Mon, 16 Mar 2026 15:06:56 +0800
Message-Id: <20260316-ultrarisc-pcie-v1-0-ef2946ede698@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABCst2kC/yXMQQqDQAxA0atI1gbGGVHTq0gXdho1UuyQaCmId
 ++0Xb7F/wcYq7DBpThA+SUmzzWjKguI87BOjHLPBu9840LlcH9sOqhYxBSFsaaaqGubEIggR0l
 5lPdv2F//tv22cNy+FzjPD2lTZsVyAAAA
X-Change-ID: 20260310-ultrarisc-pcie-494998763399
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, Jingoo Han <jingoohan1@gmail.com>, 
 Xincheng Zhang <zhangxincheng@ultrarisc.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773644922; l=1823;
 i=wangjia@ultrarisc.com; s=20260309; h=from:subject:message-id;
 bh=9A5OCwRLDHXQNfCDrDgLTuSWigTIaBNqYaY07aDVvXk=;
 b=rTFbbGwTCs1+w180BnpbPCUeQ48DDiDPysHMhe+dVo09dnr0HDi5YQ722b8CFO3rBZlb+4Mxj
 ApRZT3KEmc7CSeiRFYvzulaVAR4fW8CRujEIfp2OSn7/LlXmilFN+/I
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=XvYkrelqJIIzobY7j+nIg8rsfv5kzaOzuc1UPhd087U=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260309 with auth_id=682
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds PCIe controller support for the UltraRISC DP1000 SoC.
The DP1000 is an 8-core 64-bit RISC-V SoC based on UltraRISC C100 cores,
supporting RV64GCBHX ISA with Hardware Virtualization and RISC-V H(v1.0)
Extension.

The PCIe controller is based on Synopsys DesignWare PCIe IP.
This series adds:
- Patch 1 adds the basic SoC family Kconfig support for UltraRISC platforms.
- Patch 2 adds the MAINTAINERS entry for the new driver.
- Patch 3 adds the device tree bindings documentation for the PCIe controller.
- Patch 4 introduces the PCIe host controller driver.

The patches have been tested on UltraRISC DP1000 development board with
various PCIe devices including NVMe SSDs and network cards, verifying
link establishment, enumeration, and basic data transfer.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
Jia Wang (3):
      riscv: add UltraRISC SoC family Kconfig support
      MAINTAINERS: Add entry for the UltraRISC DP1000 PCIe controller driver and its DT binding
      dt-bindings: PCI: Add UltraRISC DP1000 PCIe controller

Xincheng Zhang (1):
      PCI: dwc: Add UltraRISC DP1000 PCIe rc driver

 .../bindings/pci/ultrarisc,dp1000-pcie.yaml        | 108 +++++++++++
 MAINTAINERS                                        |   8 +
 arch/riscv/Kconfig.socs                            |  10 +
 drivers/pci/controller/dwc/Kconfig                 |  15 ++
 drivers/pci/controller/dwc/Makefile                |   1 +
 drivers/pci/controller/dwc/pcie-designware.h       |  22 +++
 drivers/pci/controller/dwc/pcie-ultrarisc.c        | 202 +++++++++++++++++++++
 7 files changed, 366 insertions(+)
---
base-commit: f338e77383789c0cae23ca3d48adcc5e9e137e3c
change-id: 20260310-ultrarisc-pcie-494998763399

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

