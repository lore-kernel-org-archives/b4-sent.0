From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH v3 0/5] PCI: Add support for resetting the slots in a
 platform specific way
Date: Thu, 17 Apr 2025 22:46:26 +0530
Message-Id: <20250417-pcie-reset-slot-v3-0-59a10811c962@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGo3AWgC/3XNzQrDIAzA8VcpnudQ+2Hdae8xdrAutoFSSyyyU
 frusz1tjB3/IfllZREIIbJLsTKChBHDlKM8FcwNduqB4yM3U0LVohIVnx0CJ4iw8DiGhetSdN5
 qafMGy1czgcfnId7uuQeMS6DX8SDJffrfSpILblpTKyPbzhtxHXGyFM6BerZjSX0AsvkFVAbAg
 246pVsnv4Ft2977FJM68AAAAA==
X-Change-ID: 20250404-pcie-reset-slot-730bfa71a202
To: Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Oliver O'Halloran <oohall@gmail.com>, Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Zhou Wang <wangzhou1@hisilicon.com>, 
 Will Deacon <will@kernel.org>, Robert Richter <rric@kernel.org>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Marc Zyngier <maz@kernel.org>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Daire McNamara <daire.mcnamara@microchip.com>
Cc: dingwei@marvell.com, cassel@kernel.org, Lukas Wunner <lukas@wunner.de>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 linuxppc-dev@lists.ozlabs.org, linux-pci@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-riscv@lists.infradead.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4498;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=PvCdeV/T71+XdJMLiE0kUIteJDGjHav14JPcDUzEWbk=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBoATdtxd9VXuCzJQXALX9GONRBJRZvlq1rHHO2E
 vixk5tx8BOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaAE3bQAKCRBVnxHm/pHO
 9SGZB/9wO83g2WQiJXUe+pmJAGWUVZyOgslNdIVc+RJ1hJtslE2h7Sab5a93Ifm+nv6wpK569OR
 i1gjAn8JYIjUYRKqe549owUx0d61b6uUI9aqgk5KorUfpMWpCuCwZlALyUoR58nsedoG1u105el
 9BQX6K3r57OIC5YGIdFwZu+126TXcX02ygDt7e+aG1XmFJRjKOD3ir8NJRHge2Lweh1AkFMZ+by
 ApXkVlkdI1rqHa9ZDPwn/4UTjM2scyba3TkffP72FPsDzVQd7lhe65j6UpqS7AsaDkpkDAim/3z
 zqhI1xMxVGFaNU4cJ0tX3GrjjkOBQ8njtMdysDf6f6fkzXyf
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

Currently, in the event of AER/DPC, PCI core will try to reset the slot and its
subordinate devices by invoking bridge control reset and FLR. But in some
cases like AER Fatal error, it might be necessary to reset the slots using the
PCI host bridge drivers in a platform specific way (as indicated by the TODO in
the pcie_do_recovery() function in drivers/pci/pcie/err.c). Otherwise, the PCI
link won't be recovered successfully.

So this series adds a new callback 'pci_host_bridge::reset_slot' for the host
bridge drivers to reset the slot when a fatal error happens.

Also, this series allows the host bridge drivers to handle PCI link down event
by resetting the slots and recovering the bus. This is accomplished by the
help of a new API 'pci_host_handle_link_down()'. Host bridge drivers are
expected to call this API (preferrably from a threaded IRQ handler) when a link
down event is detected. The API will reuse the pcie_do_recovery() function to
recover the link if AER support is enabled, otherwise it will directly call the
reset_slot() callback of the host bridge driver (if exists).

For reference, I've modified the pcie-qcom driver to call
pci_host_handle_link_down() after receiving LINK_DOWN global_irq event and
populated the 'pci_host_bridge::reset_slot()' callback to reset the controller
(there by slots). Since the Qcom PCIe controllers support only a single root
port (slot) per controller instance, reset_slot() callback is going to be
invoked only once. For multi root port controllers, this callback is supposed to
identify the slots using the supplied 'pci_dev' pointer and reset them.

NOTE
====

This series is a reworked version of the earlier series [1] that I submitted for
handling PCI link down event. In this series, I've made use of the AER helpers
to recover the link as it allows notifying the device drivers and also
allows saving/restoring the config space.

Testing
=======

This series is tested on Qcom RB5 and SA8775p Ride boards by triggering the link
down event manually by writing to LTSSM register. For the error recovery to
succeed (if AER is enabled), all the drivers in the bridge hierarchy should have
the 'err_handlers' populated. Otherwise, the link recovery will fail.

[1] https://lore.kernel.org/linux-pci/20250221172309.120009-1-manivannan.sadhasivam@linaro.org

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Changes in v3:
- Made the pci-host-common driver as a common library for host controller
  drivers
- Moved the reset slot code to pci-host-common library
- Link to v2: https://lore.kernel.org/r/20250416-pcie-reset-slot-v2-0-efe76b278c10@linaro.org

Changes in v2:
- Moved calling reset_slot() callback from pcie_do_recovery() to pcibios_reset_secondary_bus()
- Link to v1: https://lore.kernel.org/r/20250404-pcie-reset-slot-v1-0-98952918bf90@linaro.org

---
Manivannan Sadhasivam (5):
      PCI/ERR: Remove misleading TODO regarding kernel panic
      PCI/ERR: Add support for resetting the slots in a platform specific way
      PCI: host-common: Make the driver as a common library for host controller drivers
      PCI: host-common: Add link down handling for host bridges
      PCI: qcom: Add support for resetting the slot due to link down event

 drivers/pci/controller/Kconfig                    |  8 +-
 drivers/pci/controller/dwc/Kconfig                |  1 +
 drivers/pci/controller/dwc/pcie-hisi.c            |  1 +
 drivers/pci/controller/dwc/pcie-qcom.c            | 90 ++++++++++++++++++++++-
 drivers/pci/controller/pci-host-common.c          | 64 +++++++++++++++-
 drivers/pci/controller/pci-host-common.h          | 17 +++++
 drivers/pci/controller/pci-host-generic.c         |  2 +
 drivers/pci/controller/pci-thunder-ecam.c         |  2 +
 drivers/pci/controller/pci-thunder-pem.c          |  1 +
 drivers/pci/controller/pcie-apple.c               |  2 +
 drivers/pci/controller/plda/pcie-microchip-host.c |  1 +
 drivers/pci/pci.c                                 | 13 ++++
 drivers/pci/pcie/err.c                            |  7 +-
 include/linux/pci-ecam.h                          |  6 --
 include/linux/pci.h                               |  1 +
 15 files changed, 196 insertions(+), 20 deletions(-)
---
base-commit: 08733088b566b58283f0f12fb73f5db6a9a9de30
change-id: 20250404-pcie-reset-slot-730bfa71a202

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

