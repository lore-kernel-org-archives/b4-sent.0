From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH 0/4] PCI: Add support for resetting the slots in a platform
 specific way
Date: Fri, 04 Apr 2025 13:52:20 +0530
Message-Id: <20250404-pcie-reset-slot-v1-0-98952918bf90@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL2W72cC/x2M0QpAQBAAf0X7bGudk/Ir8nBYbAndXlKXf7d5n
 JqZDMpRWKErMkS+ReU8DKqygGkLx8ooszE4cg158nhNwhhZOaHuZ8K2pnEJbRXMAKuuyIs8/7E
 f3vcD/+QHFmEAAAA=
X-Change-ID: 20250404-pcie-reset-slot-730bfa71a202
To: Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Oliver O'Halloran <oohall@gmail.com>, Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>
Cc: dingwei@marvell.com, cassel@kernel.org, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 linuxppc-dev@lists.ozlabs.org, linux-pci@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3286;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=8TBdxLAGrit6gBbaVtyDDpDQ2oJQC/gOB1crRUimuhM=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBn75bC/QhBJ2Lm7oDnkXSD3gojuMdbnoP6BwqvI
 wVLoiJ/YduJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ++WwgAKCRBVnxHm/pHO
 9WByCACcRzJZPgK72FjeRiCIUdQhXnSDM57XBK0IaJvyXV9ngfUmFVI62u7EK98Q5sduNhzryce
 w7WuocXfTiJFpqwtK9sdKJujil1YBy8DRqQBO0xzgMmUrRf5Fw1IqVxJpbyOVStroPAROeQTeE6
 W0HKbFgBVVnG+u1gOSjzJrdz8gaYImwQSPE3vztXZpHLV0qfWvHqxiQMlFQhhUfIoFKZ0Fr1dq3
 3XHgP9oqcRtIsLKdgZ5M2HRi57gDCD7bsDcLRLO/aMoyf7CZfzzDBmqzJEOMGEvLyS8arKig/1Y
 0ooTgcXOHgn5PRkopSUzf5lLj0iJMtB7nMyBAl+ghyx+Idpu
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
Manivannan Sadhasivam (4):
      PCI/ERR: Remove misleading TODO regarding kernel panic
      PCI/ERR: Add support for resetting the slot in a platforms specific way
      PCI: Add link down handling for host bridges
      PCI: qcom: Add support for resetting the slot due to link down event

 drivers/pci/controller/dwc/pcie-qcom.c | 89 +++++++++++++++++++++++++++++++++-
 drivers/pci/pci.h                      | 22 +++++++++
 drivers/pci/pcie/err.c                 | 29 ++++++++---
 drivers/pci/probe.c                    |  7 +++
 include/linux/pci.h                    |  2 +
 5 files changed, 140 insertions(+), 9 deletions(-)
---
base-commit: 08733088b566b58283f0f12fb73f5db6a9a9de30
change-id: 20250404-pcie-reset-slot-730bfa71a202

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

