From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v2 0/4] PCI: Introduce pci_suspend_retains_context() API
Date: Tue, 19 May 2026 13:41:19 +0530
Message-Id: <20260519-l1ss-fix-v2-0-b2c3a4bdeb15@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACcbDGoC/yXMUQ5AMBAE0KvIfmuizWpSVxEf1GJFkC4iEXdXf
 L7JzFwgFJgEiuSCQAcLL3OESRPwQz33pLiNBpMZm6FGNWkR1fGprHe+M5hrhwixvgaK8XdVVr9
 lb0by27uH+34A/GF7UGwAAAA=
X-Change-ID: 20260414-l1ss-fix-6c9cf2451944
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Keith Busch <kbusch@kernel.org>, 
 Jens Axboe <axboe@kernel.dk>, Christoph Hellwig <hch@lst.de>, 
 Sagi Grimberg <sagi@grimberg.me>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-nvme@lists.infradead.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2479;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=5xjo82f3ie4CuJPJXkiVNG3j7U7ZB0tOBqMF+qD1aFs=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqDBst/hoKrDTpdPRjYYJTCX+++TyvGSE6NanlW
 am4jXQ1szSJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagwbLQAKCRBVnxHm/pHO
 9eNGCACK2TWsgGvWcO0DSokv8etGLWLJwfMz66K1J0+8xc+cXK6Hfcx6lIBquWAnY2If3N3FtPj
 HUHTew/QYyZEZSKRV6PKMmVkYll6OGW2zbtFy+11qfr8ACFPQPF/bjtGoYwsTLtIR7CrIIFCfB4
 bexAzn9xOMAK9AsIdxrXNWKC3VR0/LsiIU8mXQxG+UqmVktjQv3LZZsd2zMBDuIsU2zVPdnxRbX
 5osUT2sxTvC1OVweFzzuQqRFIwol9Fs9htH2Uo7xxDM+duLEEXSjMZa0bnTFlPBl5dsFrH1oTAK
 gj7MNU/SHHucR5B6oNbyuZ8Yzlm+UwsMhpG5OfD4PbbdV7u2
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

This series introduces a new PCI API, pci_suspend_retains_context() to
let the client drivers know whether they can expect context retention across
suspend/resume or not and uses it in the NVMe PCI host driver.

This new API is targeted to abstract the PCI power management details away from
the client drivers. This is needed because client drivers like NVMe make use of
APIs such as pm_suspend_via_firmware() and decide to keep the device in low
power mode if this API returns 'false'. But some platforms may have other
limitations like in the case of Qcom, where if the RC driver removes the PCIe RC
resource vote to allow the SoC to enter low power mode, it cannot reliably exit
the L1ss state when the endpoint asserts CLKREQ#. So in this case also, the
client drivers cannot keep the device in low power state during suspend and
expect context retention.

And these limitations may just keep adding in the future. Without a unified
API, the client drivers have to implement their own logic which may cause code
duplication and may also lead to drivers missing some of the platform
limitations.

Once this series gets merged, we can extend this API usage to other client
drivers as well.

Testing
=======

This series is tested on Qualcomm Hamoa based Lenovo Thinkpad T14s latop with
NVMe drive.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Changes in v2:
- Renamed the API to pci_suspend_retains_context()
- Reworded the commit messages to include L10_REFCLK_ON + T_COMMONMODE as the
  L1ss exit latency
- Rebased on top of v7.1-rc1

---
Manivannan Sadhasivam (4):
      PCI: Introduce an API to check if RC/platform can retain device context during suspend
      PCI: Indicate context lost if L1ss exit is broken during resume from system suspend
      PCI: qcom: Indicate broken L1ss exit during resume from system suspend
      nvme-pci: Use pci_suspend_retains_context() API during suspend

 drivers/nvme/host/pci.c                |  3 ++-
 drivers/pci/controller/dwc/pcie-qcom.c | 12 ++++++++++++
 drivers/pci/pci.c                      | 34 ++++++++++++++++++++++++++++++++++
 include/linux/pci.h                    |  9 +++++++++
 4 files changed, 57 insertions(+), 1 deletion(-)
---
base-commit: 254f49634ee16a731174d2ae34bc50bd5f45e731
change-id: 20260414-l1ss-fix-6c9cf2451944

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

