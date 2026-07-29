From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v9 0/5] PCI: Add support for resetting the Root Ports in a
 platform specific way
Date: Wed, 29 Jul 2026 10:22:26 +0530
Message-Id: <20260729-pci-port-reset-v9-0-53570b92064d@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAqHaWoC/33MQQ6CMBCF4auQri0ZCm2tK+9hXEA7SBOx2GKjI
 dzdQuJKcTPJP8n7JhLQWwzkkE3EY7TBulsKtcuI7urbBak1qQkDxkEWnA7a0sH5kXoMONLKKF4
 oLqFgJUmjwWNrnyt4OqfubBidf61+5Mt3k4qcAmWi5obJvWkqOLoQ8vujvmrX93k6ZBGj+K+Ip
 IhWaY2qQtk0G4r8KALKAr4UmRRlDIDWmvH6lzLP8xsJW1+4PwEAAA==
X-Change-ID: 20250715-pci-port-reset-4d9519570123
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Oliver O'Halloran <oohall@gmail.com>, Will Deacon <will@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Jingoo Han <jingoohan1@gmail.com>, Koichiro Den <den@valinux.co.jp>, 
 Kishon Vijay Abraham I <kishon@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 Niklas Cassel <cassel@kernel.org>, 
 Wilfred Mallawa <wilfred.mallawa@wdc.com>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 mani@kernel.org, Lukas Wunner <lukas@wunner.de>, 
 Richard Zhu <hongxing.zhu@nxp.com>, Brian Norris <briannorris@chromium.org>, 
 Wilson Ding <dingwei@marvell.com>, Frank Li <Frank.Li@nxp.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Manivannan Sadhasivam <mani@kernel.org>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=5143;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=RxdJGaG8GFXXVWdq8OfjftbgwE98nVk/da1gYGNjOHM=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqaYcbRHScUqhrvSL1gPNdjxKkFQUSQ6H8GOYBy
 Z7K9QlBJh+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCammHGwAKCRBVnxHm/pHO
 9fLuB/4llYSd0k/weqBqDRUKXH5ITPU4J1Nk5iQBsIqiy69jdfJC0n6jo1FUSkpDxsp38vQ+rfx
 PK4yq96lMHrbYsb9Efcm3gulzfCQ6MDFRyQU5rvPVihdKIbVdSCva/iu1NaE5ltidO2Eko6cHMg
 ujUjuQbdlpVUoZuCT3z2hsuO9VGJWlfwNcKY0kmEGcjfa/Hn2H6SyTeQb+jX1CK3FkY0ztQaQ1g
 CyeUUosmqUqz6dvXYXH9vEHMTCWhJp+iKGxu1ZesoyNXtKlMC4RHe8esmp0E+Zf7tX/O0EvoCLl
 GH1JLYqGto3siMdK8K3JuwiUvR4rXoFRbWcbhXd1VsDFfikg
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

Currently, in the event of AER/DPC, PCI core will try to reset the slot (Root
Port) and its subordinate devices by invoking bridge control reset and FLR. But
in some cases like AER Fatal error, it might be necessary to reset the Root
Ports using the PCI host bridge drivers in a platform specific way (as indicated
by the TODO in the pcie_do_recovery() function in drivers/pci/pcie/err.c).
Otherwise, the PCI link won't be recovered successfully.

So this series adds a new callback 'pci_host_bridge::reset_root_port' for the
host bridge drivers to reset the Root Port when a fatal error happens.

Also, this series allows the host bridge drivers to handle PCI link down event
by resetting the Root Ports and recovering the bus. This is accomplished by the
help of the new 'pci_host_handle_link_down()' API. Host bridge drivers are
expected to call this API (preferrably from a threaded IRQ handler) with
relevant Root Port 'pci_dev' when a link down event is detected for the port.
The API will reuse the pcie_do_recovery() function to recover the link if AER
support is enabled, otherwise it will directly call the reset_root_port()
callback of the host bridge driver (if exists).

For reference, I've modified the pcie-qcom driver to call
pci_host_handle_link_down() API with Root Port 'pci_dev' after receiving the
LDn global_irq event and populated 'pci_host_bridge::reset_root_port()'
callback to reset the Root Ports.
 
Testing
-------

Tested on Qcom Lemans AU Ride platform with Host and EP SoCs connected over PCIe
link. Simulated the LDn by disabling LTSSM_EN on the EP and I could verify that
the link was getting recovered successfully.

Changes in v9:
- Rebased on top of v7.2-rc1
- Added Fixes tag to Patch 1
- Amended the commit message of Patch 3 to clarify that err_handlers are not
  triggered for RPs
- Fixed some misc issues in Patch 4 pointed by Sashiko

Changes in v8:
- Removed pci_save_state() for the Root Port during recovery as the PCI core 
- Link to v7: https://lore.kernel.org/r/20260310-pci-port-reset-v7-0-9dd00ccc25ab@oss.qualcomm.com

Changes in v7:
- Dropped Rockchip Root port reset patch due to reported issues. But the series
  works on other platforms as tested by others.
- Added pci_{lock/unlock}_rescan_remove() to guard pci_bus_error_reset() as the
  device could be removed in-between due to Native hotplug interrupt.
- Rebased on top of v7.0-rc1
- Link to v6: https://lore.kernel.org/r/20250715-pci-port-reset-v6-0-6f9cce94e7bb@oss.qualcomm.com

Changes in v6:
- Incorporated the patch: https://lore.kernel.org/all/20250524185304.26698-2-manivannan.sadhasivam@linaro.org/
- Link to v5: https://lore.kernel.org/r/20250715-pci-port-reset-v5-0-26a5d278db40@oss.qualcomm.com

Changes in v5:
* Reworked the pci_host_handle_link_down() to accept Root Port instead of
  resetting all Root Ports in the event of link down.
* Renamed 'reset_slot' to 'reset_root_port' to avoid confusion as both terms
  were used interchangibly and the series is intended to reset Root Port only.
* Added the Rockchip driver change to this series.
* Dropped the applied patches and review/tested tags due to rework.
* Rebased on top of v6.16-rc1.

Changes in v4:
- Handled link down first in the irq handler
- Updated ICC & OPP bandwidth after link up in reset_slot() callback
- Link to v3: https://lore.kernel.org/r/20250417-pcie-reset-slot-v3-0-59a10811c962@linaro.org

Changes in v3:
- Made the pci-host-common driver as a common library for host controller
  drivers
- Moved the reset slot code to pci-host-common library
- Link to v2: https://lore.kernel.org/r/20250416-pcie-reset-slot-v2-0-efe76b278c10@linaro.org

Changes in v2:
- Moved calling reset_slot() callback from pcie_do_recovery() to pcibios_reset_secondary_bus()
- Link to v1: https://lore.kernel.org/r/20250404-pcie-reset-slot-v1-0-98952918bf90@linaro.org

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (5):
      PCI: dwc: ep: Clear MSI iATU mapping in dw_pcie_ep_cleanup()
      PCI/ERR: Add support for resetting the Root Ports in a platform specific way
      PCI: host-common: Add link down handling for Root Ports
      PCI: qcom: Add support for resetting the Root Port due to link down event
      misc: pci_endpoint_test: Add AER error handlers

 drivers/misc/pci_endpoint_test.c                |  23 ++++
 drivers/pci/controller/dwc/pcie-designware-ep.c |   5 +
 drivers/pci/controller/dwc/pcie-qcom.c          | 140 +++++++++++++++++++++++-
 drivers/pci/controller/pci-host-common.c        |  35 ++++++
 drivers/pci/controller/pci-host-common.h        |   1 +
 drivers/pci/pci.c                               |  14 +++
 drivers/pci/pcie/err.c                          |   6 +-
 include/linux/pci.h                             |   1 +
 8 files changed, 219 insertions(+), 6 deletions(-)
---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20250715-pci-port-reset-4d9519570123

Best regards,
--  
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

