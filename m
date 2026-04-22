From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH 00/12] Fixes/improvements for the PCI M.2 power sequencing
 driver
Date: Wed, 22 Apr 2026 16:54:41 +0530
Message-Id: <20260422-pwrseq-m2-bt-v1-0-720d02545a64@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPqv6GkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDEyMj3YLyouLUQt1cI92kEt3EpJTERHNDA0uT1CQloJaCotS0zAqwcdG
 xEH5xaVJWanIJyAyl2loAycvp3XAAAAA=
X-Change-ID: 20260422-pwrseq-m2-bt-abdaa71094eb
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Shuai Zhang <quic_shuaz@quicinc.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-bluetooth@vger.kernel.org, Wei Deng <wei.deng@oss.qualcomm.com>, 
 Luiz Augusto von Dentz <luiz.von.dentz@intel.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 stable+noautosel@kernel.org
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2584;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=lqk3QdLBMm60ixEGqFx4KyHoJO7Nz6868LggAMS8LtY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp6K/+74ctGya8p8gkXaPiUCDCvw26R/1sf31k+
 3IL7DZbwWyJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaeiv/gAKCRBVnxHm/pHO
 9SONB/97M+ux5IjYybMtelgpS4I3KTrOMDXpTMpWH1ziA49OGXH8mUfyDlcDGatxmuRfF6dhz9m
 tr0qaHJZLNOJsSgjWrh4E5qFDkKvO0Ss0DDwQpQJ8LA883KMrjYaL3g1jU1Ifq5fbqp7CeC7wIG
 /cjfeBjOumzw/0bQ9QVRm3h/qBH6SVaymWRMuTCaSjROVI76j1e7hfuiqK1agIIe94TbEndP/6b
 cYtLXHRTkUcC6rNuR8Q8MvlosdrmXeEI+PH/Pc8/IWfMlIyFjWCTrb5PLnSXeqRIPRoIet2KwzR
 0dzB41l4ZPR2ByB8P4xYX01vga7PK58akyC/9i3rgBraM+hT
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series has several key improvements and fixes to the M.2 power sequencing
driver and also the BT HCI_QCA driver. Notably, this series allows the M.2 power
sequencing driver to work with more M.2 cards, not just WCN7850. It also allows
the BT HCI_QCA driver to detect whether it can control BT_EN (or W_DISABLE2#)
signal on the connector and set the HCI_QUIRK_NON_PERSISTENT_SETUP quirk.

Testing
=======

This series was tested on Lenovo Thinkpad T14s together with the below DTS
patches:
https://github.com/Mani-Sadhasivam/linux/commit/29534d15307551b2355eb254601dec511169f0aa
https://github.com/Mani-Sadhasivam/linux/commit/f4eaacfe647674be200847092b43cdef2194fc55

Merge Strategy
==============

Since the BT HCI_QCA changes depend on the pwrseq changes, it would be good to
merge the whole series through pwrseq tree or through an immutable branch.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (12):
      power: sequencing: Introduce an API to check whether the pwrseq is fixed or controllable
      power: sequencing: pcie-m2: Add support for 'is_fixed()' callback to 'uart' target
      power: sequencing: qcom-wcn: Add support for 'is_fixed()' callback to 'bluetooth' target
      power: sequencing: pcie-m2: Fix inconsistent function prefixes
      power: sequencing: pcie-m2: Allow creating serdev for multiple PCI devices
      power: sequencing: pcie-m2: Improve PCI device ID check
      power: sequencing: pcie-m2: Create serdev for PCI devices present before probe
      power: sequencing: pcie-m2: Create BT node based on the pci_device_id[] table
      Bluetooth: hci_qca: Add M.2 Bluetooth device support using pwrseq
      Bluetooth: hci_qca: Rename 'power_ctrl_enabled' to 'bt_en_available'
      Bluetooth: hci_qca: Check whether the M.2 UART interface is fixed or not
      Bluetooth: hci_qca: Fix the broken BT_EN GPIO detection for Qcom WCN devices

 drivers/bluetooth/hci_qca.c                |  40 +++--
 drivers/power/sequencing/core.c            |  33 ++++
 drivers/power/sequencing/pwrseq-pcie-m2.c  | 242 ++++++++++++++++++++++-------
 drivers/power/sequencing/pwrseq-qcom-wcn.c |   9 ++
 include/linux/pwrseq/consumer.h            |   6 +
 include/linux/pwrseq/provider.h            |   2 +
 6 files changed, 262 insertions(+), 70 deletions(-)
---
base-commit: 6596a02b207886e9e00bb0161c7fd59fea53c081
change-id: 20260422-pwrseq-m2-bt-abdaa71094eb

Best regards,
--  
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

