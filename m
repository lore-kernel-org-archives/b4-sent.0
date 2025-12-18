From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v2 0/2] PCI: dwc: Suspend/resume rework
Date: Thu, 18 Dec 2025 17:34:51 +0530
Message-Id: <20251218-pci-dwc-suspend-rework-v2-0-5a7778c6094a@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOPtQ2kC/4WNQQ6CMBBFr0Jm7ZC2Wi2uvIdhUdsqE4ViR0BDu
 LuVC7j5yfvJf38GDokCw7GYIYWRmGKXQW0KcI3tbgHJZwYllJZSVtg7Qj855IH70HlMYYrpjuY
 itNR2a/aHCvK4T+FK71V8rjM3xK+YPuvPKH/tX+UoUaC1XoqdUUbv1Skyl8/BPlxs2zIH1Muyf
 AHvgU/AwwAAAA==
X-Change-ID: 20251119-pci-dwc-suspend-rework-8b0515a38679
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 vincent.guittot@linaro.org, zhangsenchuan@eswincomputing.com, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Frank Li <Frank.Li@nxp.com>, Shawn Lin <shawn.lin@rock-chips.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1662;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=Un1QrMZoYgKUn6xmBehYxA0h/rJ2Hz8sTCOdXY7E7RA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpQ+3kzBf+R5T3XmBxJx1jwtjyxhR0q0MBrgOSq
 gQ2KZAsHT6JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaUPt5AAKCRBVnxHm/pHO
 9XQMB/9lQ8zjM+FyNsCcCwFroBXwObpbD0YykfOi+ewIXOuF5vKk15CUAnC3CVJawYn3d1aNcWL
 vdFowGdk+V6C8lxDBDg6dFVd6jpe6Hiip6cnh8sdshB3eb6dhpwE7zJ7W4G4yyAd3vhNd8jbKvo
 OT9TcRxksB24iFMnEeW5yr4em13jmgOJiWV09581OynprqXsOURthWdHWXaoWBbAa/QFf3R1A7I
 Dwyd1yX79v2K/roo5VZ381s8tfh0pVFUKXeUNQ8DZsZOv/1qvE0o+Yz5ppxBMlyHjLlhDfVq3HB
 AGq/xkVFuomqDR32qgHYVd9jFSuzWum3YSNrPBzdXh/IRoob
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series is a rework of [1] to allow DWC vendor glue drivers to use the
dw_pcie_suspend_noirq() and dw_pcie_resume_noirq() APIs without failures as
reported in [2][3].

Currently, both of these APIs will fail if there is no device connected to the
bus. This is not fair as suspend/resume should continue even if there is no
device. Hence, this series tries to address this limitation.

- Mani

[1] https://lore.kernel.org/linux-pci/20251107044319.8356-4-manivannan.sadhasivam@oss.qualcomm.com/
[2] https://lore.kernel.org/linux-pci/CAKfTPtCtHquxtK=Zx2WSNm15MmqeUXO8XXi8FkS4EpuP80PP7g@mail.gmail.com/
[3] https://lore.kernel.org/linux-pci/27516921.17f2.1997bb2a498.Coremail.zhangsenchuan@eswincomputing.com/

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Changes in v2:
- Changed the logic to check for Detect.Quiet/Active states
- Collected tags and rebased on top of v6.19-rc1
- Link to v1: https://lore.kernel.org/r/20251119-pci-dwc-suspend-rework-v1-0-aad104828562@oss.qualcomm.com

---
Manivannan Sadhasivam (2):
      PCI: dwc: Skip PME_Turn_Off broadcast and L2/L3 transition during suspend if link is not up
      PCI: dwc: Do not return failure if link is in Detect.Quiet/Active states

 drivers/pci/controller/dwc/pcie-designware-host.c | 12 +++++++++---
 drivers/pci/controller/dwc/pcie-designware.c      | 12 +++++++++++-
 2 files changed, 20 insertions(+), 4 deletions(-)
---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251119-pci-dwc-suspend-rework-8b0515a38679

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

