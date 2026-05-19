From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v3 0/9] Fixes/improvements for the PCI M.2 power sequencing
 driver
Date: Tue, 19 May 2026 14:25:55 +0530
Message-Id: <20260519-pwrseq-m2-bt-v3-0-b39dc2ae3966@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJslDGoC/3WNwQ6CMBBEf4Xs2ZKyFoie/A/DoYVVaoRCF1BD+
 u8WPHuZ5CUzb1Zg8pYYzskKnhbL1vURjocE6lb3dxK2iQwosZAKUQwvzzSKDoWZhDaN1mUmT4o
 MxMng6Wbfu+5a/Zhn86B62hxbo7U8Of/Z/5Zs6/1RL5mQokTZSMxVrgt1cczpOOtn7boujQFVC
 OEL1ssDmcEAAAA=
X-Change-ID: 20260422-pwrseq-m2-bt-abdaa71094eb
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-pci@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-bluetooth@vger.kernel.org, Wei Deng <wei.deng@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2779;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=DbW7cWokzs9SPWLbVR6F11pAkkmVjuF4uDahlgdHrFI=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqDCWd6uHVDNDSaoRPub149N10KV5kuzO24ifSD
 MySZ45yJ7mJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagwlnQAKCRBVnxHm/pHO
 9cIBB/9x3BxeHndl79hZqMzi6uMkzEEbeolEngfxNvIn2I6u7AbAxFP9ctfVhWHQ3cL+JRmwvsB
 P3n1xHSJMXEVLWmnNNmyFijsP5xfPTk9WkXKvHXvm3mG8WpzE4n0Hb2OwD6sMKaixHua/JjZl+Q
 H1wFeiX1DvMnEv/OT9U5X4FY8b5UZ98y6TS4IXkWeasMkA987IRbt54BYBqI65bDa+OY8PVjHjB
 JQVTnUxg/bZ0kUnnVtWC9yMQIt7ARoMdXCqk3Y7+VaFhXMYv3OqrQabgKhBywjqNgXUGj9+vSlj
 qM3G10Cz8Wbg7SELu9I/YGjAKFrPKdpV6HNc8FMBVNnUnFxq
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
Changes in v3:
- Renamed __pwrseq_pcie_m2_create_serdev() to pwrseq_pcie_m2_create_serdev_one()
- Moved the pwrseq patches together for creating the immutable pwrseq branch
- Collected tags

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
      power: sequencing: Add an API to return the pwrseq device's 'dev' pointer
      Bluetooth: hci_qca: Add M.2 Bluetooth device support using pwrseq
      Bluetooth: hci_qca: Rename 'power_ctrl_enabled' to 'bt_en_available'
      Bluetooth: hci_qca: Set 'bt_en_available' based on W_DISABLE2# presence in M.2 connector

 drivers/bluetooth/hci_qca.c               |  28 +++-
 drivers/power/sequencing/core.c           |   9 ++
 drivers/power/sequencing/pwrseq-pcie-m2.c | 232 ++++++++++++++++++++++--------
 include/linux/pwrseq/consumer.h           |   7 +
 4 files changed, 215 insertions(+), 61 deletions(-)
---
base-commit: 254f49634ee16a731174d2ae34bc50bd5f45e731
change-id: 20260422-pwrseq-m2-bt-abdaa71094eb

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

