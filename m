From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v2 0/9] Fixes/improvements for the PCI M.2 power sequencing
 driver
Date: Thu, 07 May 2026 21:36:08 +0530
Message-Id: <20260507-pwrseq-m2-bt-v2-0-1740bd478539@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHC4/GkC/3WNwQ6CMBBEf4Xs2SVlUyB68j8MhxZWqRELXUAN4
 d8tePYyyUtm3iwgHBwLnJIFAs9OnH9GoEMCdWueN0bXRAZSVChNhP0rCA/YEdoRjW2MKTN11Gw
 hTvrAV/fedZfqxzLZO9fj5tgarZPRh8/+N2db7496zlBhSapRlOvcFPrsRdJhMo/ad10aA6p1X
 b+eodg8wQAAAA==
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
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2584;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=DI8D86bD8AE3e33QAsmWkuZyiSBpCR+NtFhwtZE0MFc=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp/Lh2l5qZXLrIeRH+CFId7hT2Ay1qhgWaR5qn5
 lX50UUrGe2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCafy4dgAKCRBVnxHm/pHO
 9YRkCACLd2DefFRxeOuA2LVlQF6kk8GAuQkBiUKQ5GCGiGNnm6p8Y7CaJaX9G+R0rUY7ertftpU
 n7xj4iPaax+MxIXtOsweskYcUqdoOapwOLylMi3bEhQ07roZV/45wLsPptFp4S5eZQKOe/nrpe/
 9s/Zb0jT2NCEFpk0QDba+JHLhkXHWXmJdRKALsLGwR3l6R4hOOWpZ1raPHvTF/h4X5lkRu0lkdG
 +iq3yzmbP72EUXgj5MymLkX4O8q6F9TX1YRYNmtyH5iJZ95JISwh8WaICJCiYHrrYBBcwK559S9
 QetE/nsuX87fG/YlBpsAKgwszANhjnsUF4I0CBDotIpAPs8S
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
Changes in v2:
- Dropped the pwrseq_is_fixed() change in favor or exporting pwrseq device's dev
  pointer and using it to check for the presence of W_DISABLE2# property
- Dropped the BT_EN fix for the Qcom WCN devices since it will be handled
  separately
- Collected tags
- Link to v1: https://patch.msgid.link/20260422-pwrseq-m2-bt-v1-0-720d02545a64@oss.qualcomm.com

---
Manivannan Sadhasivam (9):
      power: sequencing: pcie-m2: Fix inconsistent function prefixes
      power: sequencing: pcie-m2: Allow creating serdev for multiple PCI devices
      power: sequencing: pcie-m2: Improve PCI device ID check
      power: sequencing: pcie-m2: Create serdev for PCI devices present before probe
      power: sequencing: pcie-m2: Create BT node based on the pci_device_id[] table
      Bluetooth: hci_qca: Add M.2 Bluetooth device support using pwrseq
      Bluetooth: hci_qca: Rename 'power_ctrl_enabled' to 'bt_en_available'
      power: sequencing: Add an API to return the pwrseq device's 'dev' pointer
      Bluetooth: hci_qca: Set 'bt_en_available' based on W_DISABLE2# presence in M.2 connector

 drivers/bluetooth/hci_qca.c               |  28 +++-
 drivers/power/sequencing/core.c           |   9 ++
 drivers/power/sequencing/pwrseq-pcie-m2.c | 234 ++++++++++++++++++++++--------
 include/linux/pwrseq/consumer.h           |   7 +
 4 files changed, 217 insertions(+), 61 deletions(-)
---
base-commit: 254f49634ee16a731174d2ae34bc50bd5f45e731
change-id: 20260422-pwrseq-m2-bt-abdaa71094eb

Best regards,
--  
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

