From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v8 0/5] PCI: Add support for resetting the Root Ports in a
 platform specific way
Date: Mon, 18 May 2026 20:29:12 +0530
Message-Id: <20260518-pci-port-reset-v8-0-eb5a7d331dfc@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEEpC2oC/33MQQ6CMBCF4auQri0ZCm2pK+9hXEA7SBOh2CLRE
 O5uIXGluJnkn+R9MwnoLQZyTGbicbLBuj5GeUiIbqv+itSa2IQB4yAzTgdt6eD8SD0GHGlhFM8
 Ul5CxnMTR4LGxzw08X2K3NozOvzZ/4ut3l5o4BcpExQ2TpakLOLkQ0vujumnXdWk8ZBUn8V8RU
 RGN0hpVgbKudxT5UQTkGXwpMirKGACtNePVL2VZljfQ6RrYPwEAAA==
X-Change-ID: 20250715-pci-port-reset-4d9519570123
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Oliver O'Halloran <oohall@gmail.com>, Will Deacon <will@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 Niklas Cassel <cassel@kernel.org>, 
 Wilfred Mallawa <wilfred.mallawa@wdc.com>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 mani@kernel.org, Lukas Wunner <lukas@wunner.de>, 
 Richard Zhu <hongxing.zhu@nxp.com>, Brian Norris <briannorris@chromium.org>, 
 Wilson Ding <dingwei@marvell.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Frank Li <Frank.Li@nxp.com>, Manivannan Sadhasivam <mani@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5165;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=3AIauHZc5fsWKZZZAdpC8t1KoLS+876d+0DM89J+kl8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqCylTQOA4nC0mQALeCJgw1HmXmSTWcof5udtVK
 u/RdWjGSMmJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagspUwAKCRBVnxHm/pHO
 9W1hB/wKp6MDZshPsB3gTDX/NgNSiNPsUCxaAbf5fuBcPAUJYDV+CcTnwU4fOBmOf+m6p6kKolH
 qThFdeESTekTYQVvYlVdmnd3htGg9xw+Zb0aHZtu4KNdyKRoyakYJl6lhqE34sNRDHJ6fj2Vo4Y
 D9/0szP3hnxYPOw7Kyb00CBvdmVi5PZFbmKZVPK7ImSyt28ZokIMWa3U5k4SVDp2azNVnsV1tJK
 3LFamLyNKpMiCVnMHLzF24rywH/EgoOYw1240eFQoebK5SjxoZaWWZ4NnMqQsDMAsHXxwnqjLg/
 7MbJY0+wp4knK47XP/6y5tfKu09Qc0c7h+e7pJj7cJ2uQojA
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

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Changes in v8:
- Removed pci_save_state() for the Root Port during recovery as the PCI core now
  saves the config space during enumeration
- Added save/restore in pci_endpoint_test.c driver to save the config space
  after enabling BME and restoring it after reset
- Added a patch to unmap MSI address post LDn
- Rebased on top of v7.1-rc1
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

---
Manivannan Sadhasivam (5):
      PCI: dwc: ep: Clear MSI iATU mapping in dw_pcie_ep_cleanup()
      PCI/ERR: Add support for resetting the Root Ports in a platform specific way
      PCI: host-common: Add link down handling for Root Ports
      PCI: qcom: Add support for resetting the Root Port due to link down event
      misc: pci_endpoint_test: Add AER error handlers

 drivers/misc/pci_endpoint_test.c                |  23 ++++
 drivers/pci/controller/dwc/pcie-designware-ep.c |   5 +
 drivers/pci/controller/dwc/pcie-qcom.c          | 143 +++++++++++++++++++++++-
 drivers/pci/controller/pci-host-common.c        |  35 ++++++
 drivers/pci/controller/pci-host-common.h        |   1 +
 drivers/pci/pci.c                               |  14 +++
 drivers/pci/pcie/err.c                          |   6 +-
 include/linux/pci.h                             |   1 +
 8 files changed, 222 insertions(+), 6 deletions(-)
---
base-commit: 254f49634ee16a731174d2ae34bc50bd5f45e731
change-id: 20250715-pci-port-reset-4d9519570123

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

