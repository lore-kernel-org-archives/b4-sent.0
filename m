From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v3 0/4] PCI: dwc: Rework the error handling of
 dw_pcie_wait_for_link() API
Date: Tue, 30 Dec 2025 20:37:31 +0530
Message-Id: <20251230-pci-dwc-suspend-rework-v3-0-40cd485714f5@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALPqU2kC/4XNwQ6CMAyA4VchOzuyDgbDk+9hPMxtyqIyXGVoC
 O/u4OJF46XJ36RfJ4I2OItkm00k2OjQ+S5FscmIblV3ttSZ1IQzLgCgob121Iya4oC97QwNdvT
 hQuWRCRCqkFXdkHTcB3tyzxXeH1K3Dh8+vNY/EZbtXzICZVQpA6yUXIqK7zxifh/UVfvbLU+DL
 HLkH42D/KnxpAlV17XUFWtK9UWb5/kNjcbOkREBAAA=
X-Change-ID: 20251119-pci-dwc-suspend-rework-8b0515a38679
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 vincent.guittot@linaro.org, zhangsenchuan@eswincomputing.com, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2251;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=oDy+EPyaJnAnM/riqZPjUlFELI7OMCcdl4Yu+VC1JyY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpU+q6EaZRACdCf7yoRSVenZw+VK1paZd1LVQKl
 Pigd+ExmXKJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaVPqugAKCRBVnxHm/pHO
 9c3FB/98VgTT2qugab9NRzLkZCj/HRoVqpfmC7svAT31KZl4Ux9razZ+9uI6Ntgi6dM/9tDcUor
 wAN2CHZjEsOLXRciaRCUNjaC/BNyrecdIYwTasJnWKL/8YVqBysqNMjltIl/vu8mHwPudfSbq+S
 BSvJSGcIwfhW5RL7FT256w/G9t18rhVaKWtkQXrc3Fr2eorzZ8YLnrLgL7b1+HGS0CZr7LqmdIZ
 grCVbueLHsXC+zBl1hW1QPtwAfXNNcdzE7AVj1pCa8Q2xrk7ryeHLzsGBKwfEbogSW3hxJpxqBh
 wkwvLx7cLTO4WtdSIL3rWH1e4XtLBRX7SU5QfxbNcWTTlw+v
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
Changes in v3:
- Dropped patch 1 that got appplied
- Reworked the error handling of dw_pcie_wait_for_link() API further
- Link to v2: https://lore.kernel.org/r/20251218-pci-dwc-suspend-rework-v2-0-5a7778c6094a@oss.qualcomm.com

Changes in v2:
- Changed the logic to check for Detect.Quiet/Active states
- Collected tags and rebased on top of v6.19-rc1
- Link to v1: https://lore.kernel.org/r/20251119-pci-dwc-suspend-rework-v1-0-aad104828562@oss.qualcomm.com

---
Manivannan Sadhasivam (4):
      PCI: dwc: Return -ENODEV from dw_pcie_wait_for_link() if device is not found
      PCI: dwc: Rename and move ltssm_status_string() to pcie-designware.c
      PCI: dwc: Rework the error print of dw_pcie_wait_for_link()
      PCI: dwc: Only skip the dw_pcie_wait_for_link() failure if it returns -ENODEV

 .../pci/controller/dwc/pcie-designware-debugfs.c   | 54 +---------------
 drivers/pci/controller/dwc/pcie-designware-host.c  |  6 +-
 drivers/pci/controller/dwc/pcie-designware.c       | 75 +++++++++++++++++++++-
 drivers/pci/controller/dwc/pcie-designware.h       |  2 +
 4 files changed, 80 insertions(+), 57 deletions(-)
---
base-commit: 68ac85fb42cfeb081cf029acdd8aace55ed375a2
change-id: 20251119-pci-dwc-suspend-rework-8b0515a38679

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

