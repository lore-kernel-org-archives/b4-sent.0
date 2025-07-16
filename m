From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH 0/6] PCI/ASPM: Fix pci_enable_link_state*() APIs behavior
Date: Wed, 16 Jul 2025 18:26:19 +0530
Message-Id: <20250716-ath-aspm-fix-v1-0-dd3e62c1b692@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHOhd2gC/x2MQQqAMAzAviI9W7BjMvQr4qFodT04ZRURxL87P
 CaQPGCSVQz66oEsl5ruqQDVFUyR0yqoc2FwjWubQIR8RmQ7Nlz0xomC945b7ligJEeWov/dML7
 vBxDLtA5eAAAA
X-Change-ID: 20250711-ath-aspm-fix-c17442a5a9ae
To: Jeff Johnson <jjohnson@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Nirmal Patel <nirmal.patel@linux.intel.com>, 
 Jonathan Derrick <jonathan.derrick@linux.dev>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 ath12k@lists.infradead.org, ath11k@lists.infradead.org, 
 ath10k@lists.infradead.org, Bjorn Helgaas <helgaas@kernel.org>, 
 ilpo.jarvinen@linux.intel.com, linux-arm-msm@vger.kernel.org, 
 linux-pci@vger.kernel.org, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Qiang Yu <qiang.yu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2631;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=XJHu0BU6B2oAYGh4zlJhKIwWPQugh47Z5AJ6yeiT7Z4=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBod6F2iDbObtlH1SjC+CqMAksFgzOriAQ1Avz7v
 IVgkpT7eMSJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaHehdgAKCRBVnxHm/pHO
 9YnKB/wIw+Evh74fkz1+e3zKFQWHQKJJSazZGHS5g4sICCMPZ/4M93vTf+iLF4Blp3veDJhLy1B
 BGe8V3AJq+xqMdOOWmaPj/fEy7ukevvMlLZHnS5yHIrebv9ehwe60fjePHZ+kkwke2JXgh5SMn2
 aoNSydN026Nm+C+XW0IVVbZqMpsq3pFyN5MLTUVKM9zREWmmg/RAd75jPZ0oWkNiqzEj2C4XoVV
 M3swsNxSU7uFYHGzLxGFSLk3zf3Sm1Tl48owufc1zv9xTnXYeobMvQIsx4hvQSBACG7gwFxjUmc
 4epgfpo4UEHaA5y6LDHB/oAZex/9Q6hTaG0SGH/st9KFUCxN
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes the behavior of the pci_enable_link_state() and
pci_enable_link_state_locked() APIs to be in symmetry with
pci_disable_link_state*() couterparts.

First 3 patches fixes and cleans up the ASPM code and the last 3 patches
modifies the atheros drivers to use the pci{enable/disable}_link_state() APIs
instead of modifying the LNKCTL register directly for enabling ASPM.

NOTE: The current callers of the pci_enable_link_state_locked() APIs (vmd and
pcie-qcom) drivers doesn't look like depending on the old behavior of the API. I
can atleast assure that for pcie-qcom. For VMD, it would be great if VMD folks
CCed could provide their review tags for patch 1/6.

Testing
=======

I've tested this series on Lenovo Thinkpad T14s with WCN7850 chipset (so that's
just ath12k driver). Rest of the drivers are compile tested only.

Merging Strategy
================

Even though there is no build dependency between PCI core and atheros patches,
there is a functional dependency. So I'd recommend creating an immutable branch
with PCI patches and merging that branch into both PCI and linux-wireless trees
and finally merging the atheros patches into linux-wireless tree.

If immutable branch seems like a hassle, then PCI core patches could get merged
for 6.17 and atheros patches can wait for 6.18.

- Mani

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (6):
      PCI/ASPM: Fix the behavior of pci_enable_link_state*() APIs
      PCI/ASPM: Transition the device to D0 (if required) inside pci_enable_link_state_locked() API
      PCI/ASPM: Improve the kernel-doc for pci_disable_link_state*() APIs
      wifi: ath12k: Use pci_{enable/disable}_link_state() APIs to enable/disable ASPM states
      wifi: ath11k: Use pci_{enable/disable}_link_state() APIs to enable/disable ASPM states
      wifi: ath10k: Use pci_{enable/disable}_link_state() APIs to enable/disable ASPM states

 drivers/net/wireless/ath/ath.h         | 14 ++++++
 drivers/net/wireless/ath/ath10k/pci.c  |  7 +--
 drivers/net/wireless/ath/ath11k/pci.c  | 10 ++---
 drivers/net/wireless/ath/ath12k/pci.c  | 10 ++---
 drivers/pci/controller/dwc/pcie-qcom.c |  5 ---
 drivers/pci/controller/vmd.c           |  5 ---
 drivers/pci/pcie/aspm.c                | 78 ++++++++++++++++++++++++----------
 7 files changed, 79 insertions(+), 50 deletions(-)
---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250711-ath-aspm-fix-c17442a5a9ae

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

