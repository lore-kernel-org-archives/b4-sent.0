From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH v6 0/4] PCI: qcom: Add 16.0 GT/s equalization and margining
 settings
Date: Wed, 04 Sep 2024 12:41:56 +0530
Message-Id: <20240904-pci-qcom-gen4-stability-v6-0-ec39f7ae3f62@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADwI2GYC/x3MQQqDMBBG4avIrDsQQoy0VykuYvy1A23UJIgiu
 buhy2/x3kUJUZDo1VwUsUuSJVTYR0P+48IMlrGatNJGPZXh1QtvfvnxjGA4ZTfIV/LJSsPb1nW
 wMFTrNWKS439+96Xccvbe6WkAAAA=
To: Richard Zhu <hongxing.zhu@nxp.com>, 
 Lucas Stach <l.stach@pengutronix.de>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Jingoo Han <jingoohan1@gmail.com>, 
 Chuanhua Lei <lchuanhua@maxlinear.com>, 
 Marek Vasut <marek.vasut+renesas@gmail.com>, 
 Yoshihiro Shimoda <yoshihiro.shimoda.uh@renesas.com>
Cc: linux-pci@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 imx@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-renesas-soc@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 abel.vesa@linaro.org, johan+linaro@kernel.org, 
 Shashank Babu Chinta Venkata <quic_schintav@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2406;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=cLb2NYLXwStX/LKCjvnBpOqyb4PG6V2tb9fd5zD3pBU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBm2Ag+yXw76QSloqji0A8dUGvbGecOjKDwzo19V
 gChmcyzYReJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZtgIPgAKCRBVnxHm/pHO
 9QBoB/40W7x6SSRfFEQvwB1+Lx05sntI/Ecem96LKwXC0adZ62tG7DZcnlrBOHu/Yv/gMxxLb4K
 hr2epksRdMTtqaQ0nDTXn+3oiwA0Q9WEzst3bydA7yMtYLRcJa0+BfLsc28z58fEHTA2Zojogcg
 kaCDyFsjo6vwzuD+eE7PWgFtMJGMAjXfb2XcMnolL9RJirnLZ1bZfZjW/5AJ2iwHPkCUsMvqaFP
 n6ibN4qXxgfXODKqbUrvqbDUDQWcbYJvfqQxMt8nn0QaaxmgmJrIKXBapriYTb4bY+xkQczG8Ih
 Rds1yh9PZCYFNVq++7Z/H/svXcvpMEk0K9hOzny43boAID1f
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds 16.0 GT/s specific equalization and RX lane margining settings
to the Qcom RC and EP drivers. This series is mandatory for the stable operation
of the PCIe link at 16.0 GT/s on the Qcom platforms.

NOTE:
=====

I've taken over the series from Shashank based on the discussion [1]. In order
to apply the equalization/margining settings properly in the Qcom driver, I
added the first 2 patches to the series which inevitably touches other vendor
drivers also.

- Mani

Changes in v6:

- Dropped the code refactoring patch as suggested by Johan
- Added 2 patches to fix the caching of maximum supported link speed value that
  is needed to apply the equalization/margining settings
- Updated the commit message of patch 3 as per Bjorn's suggestion

For previous changelogs, please refer [2]

[1] https://lore.kernel.org/linux-pci/af65b744-7538-4929-9ab4-8ee42e17b8d1@quicinc.com/
[2] https://lore.kernel.org/linux-pci/20240821170917.21018-1-quic_schintav@quicinc.com/

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Manivannan Sadhasivam (2):
      PCI: dwc: Rename 'dw_pcie::link_gen' to 'dw_pcie::max_link_speed'
      PCI: dwc: Always cache the maximum link speed value in dw_pcie::max_link_speed

Shashank Babu Chinta Venkata (2):
      PCI: qcom: Add equalization settings for 16.0 GT/s
      PCI: qcom: Add RX margining settings for 16.0 GT/s

 MAINTAINERS                                   |  4 +-
 drivers/pci/controller/dwc/Kconfig            |  5 ++
 drivers/pci/controller/dwc/Makefile           |  1 +
 drivers/pci/controller/dwc/pci-imx6.c         |  8 +--
 drivers/pci/controller/dwc/pcie-designware.c  | 22 +++++---
 drivers/pci/controller/dwc/pcie-designware.h  | 32 ++++++++++-
 drivers/pci/controller/dwc/pcie-intel-gw.c    |  4 +-
 drivers/pci/controller/dwc/pcie-qcom-common.c | 76 +++++++++++++++++++++++++++
 drivers/pci/controller/dwc/pcie-qcom-common.h |  9 ++++
 drivers/pci/controller/dwc/pcie-qcom-ep.c     |  6 +++
 drivers/pci/controller/dwc/pcie-qcom.c        |  6 +++
 drivers/pci/controller/dwc/pcie-rcar-gen4.c   |  6 +--
 12 files changed, 162 insertions(+), 17 deletions(-)
---
base-commit: 47ac09b91befbb6a235ab620c32af719f8208399
change-id: 20240904-pci-qcom-gen4-stability-02ec65a7e6e4

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

