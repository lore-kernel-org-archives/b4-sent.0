From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v4 0/6] PCI: dwc: Rework the error handling of
 dw_pcie_wait_for_link() API
Date: Wed, 07 Jan 2026 13:41:53 +0530
Message-Id: <20260107-pci-dwc-suspend-rework-v4-0-9b5f3c72df0a@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEkVXmkC/4XNSw7CIBCA4as0rMUwPAp15T2MCwRqibZUsFVje
 nepG13YuJnkn2S+eaLkoncJbYonim70yYcuB18VyDS6OzrsbW5ECRUAUOHeeGxvBqch9a6zOLp
 biCesDkSA0EyVskL5uI+u9vc3vNvnbny6hvh4/xlh3v4lR8AEa22BcEWVKOk2pLS+DPpsQtuu8
 0CzPNKPRkEtajRrQksplSlJxfWCxr40RhY1ljVOjOVKSOC1+KFN0/QCXt3C5F8BAAA=
X-Change-ID: 20251119-pci-dwc-suspend-rework-8b0515a38679
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 vincent.guittot@linaro.org, zhangsenchuan@eswincomputing.com, 
 Shawn Lin <shawn.lin@rock-chips.com>, Richard Zhu <hongxing.zhu@nxp.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2748;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=o9pWIvqMlzb/PHzIzRlxl4DrSd1mVj3lgO+vQNtuY74=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpXhVNnNFpj8UPDghdOiSSpSpX3YCWrYv2ZUBJ9
 cKkV/0gk7+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaV4VTQAKCRBVnxHm/pHO
 9a38B/4z5YcOBkBsZ7y1lk6E/lID3aXAxRJA/h1wexQej17UYQLmOifbj1FEXBlMkpEqmVogflS
 QO/FrQnb0GI5v+W6HnYllgISXCLRh+neQRh/zhiOKmaOvnH8Lk9Y3QqOAztKXD0piAk46tUtwUt
 6GsETJ1ST6znGPo1OdikleRYRowXxpd2nI0nyFeNonUPKcGJbVnojIQ7b156AzB4qMN7AP0UtRz
 PYOar6qI6R7mihXA0mwmpTcQIDizb2fIbPuNTlMK5ihZLkViYcwL3vBDy2NhbaEIu4U1/UN49kA
 WEsbjuR/hMNEBrn5dYrQkLBXy19sGauXYBipaKFmZFq+/yi7
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series reworks the dw_pcie_wait_for_link() API to allow the callers to
detect the absence of the device on the bus and skip the failure.

Compared to v2, I've reworked the patch 2 to improve the API further and
dropped the patch 1 that got applied (hence changed the subject). I've also
modified the error code based on the feedback in v2 to return -ENODEV if device
is not detected on the bus and -ETIMEDOUT otherwise. This allows the callers to
skip the failure if device is not detected and handle error for other failure.

Testing
=======

Tested this series on Rb3Gen2 board without powering on the PCIe switch. Now the
dw_pcie_wait_for_link() API prints:

	qcom-pcie 1c08000.pcie: Device not found

Instead of the previous log:

	qcom-pcie 1c08000.pcie: Phy link never came up

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Changes in v4:
- Skipped returning failure during resume as well if no device is found
- Link to v3: https://lore.kernel.org/r/20251230-pci-dwc-suspend-rework-v3-0-40cd485714f5@oss.qualcomm.com

Changes in v3:
- Dropped patch 1 that got appplied
- Reworked the error handling of dw_pcie_wait_for_link() API further
- Link to v2: https://lore.kernel.org/r/20251218-pci-dwc-suspend-rework-v2-0-5a7778c6094a@oss.qualcomm.com

Changes in v2:
- Changed the logic to check for Detect.Quiet/Active states
- Collected tags and rebased on top of v6.19-rc1
- Link to v1: https://lore.kernel.org/r/20251119-pci-dwc-suspend-rework-v1-0-aad104828562@oss.qualcomm.com

---
Manivannan Sadhasivam (6):
      PCI: dwc: Return -ENODEV from dw_pcie_wait_for_link() if device is not found
      PCI: dwc: Rename and move ltssm_status_string() to pcie-designware.c
      PCI: dwc: Rework the error print of dw_pcie_wait_for_link()
      PCI: dwc: Only skip the dw_pcie_wait_for_link() failure if it returns -ENODEV
      PCI: host-common: Add an API to check for any device under the Root Ports
      PCI: dwc: Skip failure during dw_pcie_resume_noirq() if no device is available

 .../pci/controller/dwc/pcie-designware-debugfs.c   | 54 +---------------
 drivers/pci/controller/dwc/pcie-designware-host.c  | 23 +++++--
 drivers/pci/controller/dwc/pcie-designware.c       | 75 +++++++++++++++++++++-
 drivers/pci/controller/dwc/pcie-designware.h       |  2 +
 drivers/pci/controller/pci-host-common.c           | 21 ++++++
 drivers/pci/controller/pci-host-common.h           |  2 +
 6 files changed, 115 insertions(+), 62 deletions(-)
---
base-commit: 68ac85fb42cfeb081cf029acdd8aace55ed375a2
change-id: 20251119-pci-dwc-suspend-rework-8b0515a38679

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

