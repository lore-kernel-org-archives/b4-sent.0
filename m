From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v4 0/5] PCI: dwc: Rework the error handling of
 dw_pcie_wait_for_link() API
Date: Tue, 20 Jan 2026 23:17:39 +0530
Message-Id: <20260120-pci-dwc-suspend-rework-v4-0-2f32d5082549@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALu/b2kC/4XNwQ6CMAyA4VchO1uyTQbDk+9hPMxtyqIwXGVoC
 O/u4OJF46XJ36RfJ4I2OItkl00k2OjQ+S5FscmIblR3seBMasIpF4yxGnrtwIwacMDedgaCHX2
 4gjxRwYTayrKqSTrugz275wofjqkbhw8fXuufyJbtXzIyoKCUYbSQXIqS7z1ifh/UTfu2zdMgi
 xz5R+NM/tR40oSqqkrqktaF+qLN8/wGpZZfZhEBAAA=
X-Change-ID: 20251119-pci-dwc-suspend-rework-8b0515a38679
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 vincent.guittot@linaro.org, zhangsenchuan@eswincomputing.com, 
 Shawn Lin <shawn.lin@rock-chips.com>, Niklas Cassel <cassel@kernel.org>, 
 Richard Zhu <hongxing.zhu@nxp.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2551;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=LNIqiIz35Ow0dB+iP/L2EzA6wdMLWrPcxHXyLD9uLEk=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpb7+/u8cAJRCYx1de+zE2cF1PsPrS+sMLsbksX
 hOQ/ODi73iJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaW+/vwAKCRBVnxHm/pHO
 9U1wB/0cB6ghiIJDfjb0BWy2iBYwszcPE/QFkdSSrE6n0aCXH7jxx7hx8eH1CIP8+tPdwBTojqx
 HC06tBxQqZq9b17jfTqGSQwumQ38pMwkq4pHQWBw1ewWeXSiQqv363fmAeNIDQ7HqJGUMXvo0YE
 UTu7f34O0zN1WvOhWYjOLuictjdbuizs1/26VZCElbn8QY1dal8hoUcOdWbOmkCw9SIZLH9Ie5h
 pIzuRtiyZWgo862sJOubuUObeyeqlJJQIpyBlM6Zx0HlovVp0Qn9HhVBMdn6D9xSdEaC6tlX8pT
 g5ciMy2EPgQ6onLDGF5PUSeZY8exGh8IIs92FiZleiRS09Ve
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
is not detected on the bus, -EIO if the device is found but not active and
-ETIMEDOUT otherwise. This allows the callers to skip the failure as needed.

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
- Added a check for POLL state and returned -EIO from dw_pcie_wait_for_link()
- Collected tags
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
Manivannan Sadhasivam (5):
      PCI: dwc: Return -ENODEV from dw_pcie_wait_for_link() if device is not found
      PCI: dwc: Return -EIO from dw_pcie_wait_for_link() if device is not active
      PCI: dwc: Rename and move ltssm_status_string() to pcie-designware.c
      PCI: dwc: Rework the error print of dw_pcie_wait_for_link()
      PCI: dwc: Fail dw_pcie_host_init() if dw_pcie_wait_for_link() returns -ETIMEDOUT

 .../pci/controller/dwc/pcie-designware-debugfs.c   | 54 +-------------
 drivers/pci/controller/dwc/pcie-designware-host.c  |  9 ++-
 drivers/pci/controller/dwc/pcie-designware.c       | 86 +++++++++++++++++++++-
 drivers/pci/controller/dwc/pcie-designware.h       |  2 +
 4 files changed, 94 insertions(+), 57 deletions(-)
---
base-commit: 68ac85fb42cfeb081cf029acdd8aace55ed375a2
change-id: 20251119-pci-dwc-suspend-rework-8b0515a38679

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

