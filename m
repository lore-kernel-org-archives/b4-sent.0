From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH 0/3] bus: mhi: ep: Implement flush_async() callback to
 flush async read/write
Date: Mon, 29 Jun 2026 10:45:14 +0200
Message-Id: <20260629-mhi-ep-flush-v1-0-714e0d56e87c@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAJswQmoC/yXMyw5AMBBA0V+RWZukmnj+ilgUQ0e80kEk4t8Vy
 7O49wIhxyRQBBc4Olh4mT2iMIDGmrkn5NYbtNKJSnSKk2WkFbtxF4t1rGKl0ygzeQs+WR11fH6
 7svotez1Qs70PuO8HKQlnIXAAAAA=
X-Change-ID: 20260627-mhi-ep-flush-b50502718a9d
To: Manivannan Sadhasivam <mani@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 mhi@lists.linux.dev, linux-arm-msm@vger.kernel.org, 
 linux-pci@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable+noautosel@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1442;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=EEIPKjIO+KkdnYvxCNUbUzbpbcAL4I2ToYQqaXxdMzs=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqQjCfKvW6Psv5ZdbX6f8IN9tWLJiESISCNI8EO
 nZipYdAgRSJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCakIwnwAKCRBVnxHm/pHO
 9c5TCACcWlPnEt0ry/oWcQcwS+qFP62S5Mi6pD4dZnXLl9IYtjq8BKAdA62o+iXBJ/CGnrKy4Mk
 K/sW0rELwp/WzvR5eOnWu4AhAS1vbmz2CSUNF2kZYtAIAbS9RUuT2+5VxmGj/GUbJRZCE9+Z2qY
 9HznTaila5F4c8DXd48m/b5dZiVm2Fmgd1D52lpuNKCi/0f1dN6QCRkM+irUEJLzKEb9mELKJ3f
 BlO0aeDK2ITO52VPLjVF6tVZRWABJh8glV+4ID+mNDc/yYmxIAzs8rpv+fEoPuhbj6W+iaO0z3H
 4I5G6rIXMN3VWx8Ys5VqgKJ1uhsWQcsAWogALjBKTer636K5
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series introduces a new mhi_cntrl->flush_async() callback to flush the
async read/write operations performed by the MHI controller using offload
mechanisms such as DMA.

The MHI EPF driver implements this callback by flushing the DMA wq. With this
series, the MHI EP stack can guarnatee that the channel specific xfer_cb() won't
be run after calling mhi_ep_remove().

Merge Strategy
==============

The dmaengine driver change can go separately as there is no build dependency.
But both MHI and PCI EP changes should go together. I'm planning to take both
MHI and PCI EP patches through MHI tree.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (3):
      dmaengine: dw-edma: Implement device_synchronize() callback
      bus: mhi: ep: Add mhi_cntrl->flush_async() callback to flush the async read/write
      PCI: epf-mhi: Implement mhi_cntrl->flush_async() to flush DMA read/write

 drivers/bus/mhi/ep/main.c                    |  7 +++++++
 drivers/dma/dw-edma/dw-edma-core.c           | 16 ++++++++++++++++
 drivers/pci/endpoint/functions/pci-epf-mhi.c | 10 ++++++++++
 include/linux/mhi_ep.h                       |  2 ++
 4 files changed, 35 insertions(+)
---
base-commit: 4549871118cf616eecdd2d939f78e3b9e1dddc48
change-id: 20260627-mhi-ep-flush-b50502718a9d

Best regards,
--  
மணிவண்ணன் சதாசிவம்

