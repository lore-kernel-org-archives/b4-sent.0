From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH 0/5] Rework M.2 Bluetooth instantiation using the auxiliary
 bus
Date: Tue, 15 Sep 2026 16:24:01 +0200
Message-Id: <20260915-pci-m2-bt-rework-v1-0-3c7d9cf9c010@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAJVqWoC/y2NyxKCMAxFf6XTtWFqQURW/ofDorRBq5ZCw8OR8
 d8t6CYzJ7k5d+GEwSLxki084GTJ+jbCfse4vqn2imBNZC6FzEUhcui0BSehHiDg7MMDjoXRUp9
 k3gjB41sXsLGvTXmpfkxjfUc9rJ5/ImA/xq7hF+MOidTWVbKt6SQycL59K5htwGc8w5SDAFPog
 8hknWJjzp4o6Uf11N65JI7VXStCWBd2KNl0TFIIes+rz+cLdgSQaeoAAAA=
X-Change-ID: 20260806-pci-m2-bt-rework-78dc2c926f00
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Amitkumar Karwar <amitkumar.karwar@nxp.com>, 
 Neeraj Kale <neeraj.sanjaykale@nxp.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-kernel@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-pci@vger.kernel.org, 
 linux-pm@vger.kernel.org, Rahul Samana <rahul.samana@oss.qualcomm.com>, 
 Wei Deng <wei.deng@oss.qualcomm.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3270;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=EzEipVhfzm1eKNikYmDIvFcSrVs4H5/sTMHoZJa+42U=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqqVURPnvp+NVOzzUOhYTE7PYDvNyZ8d6FiMJHq
 Cxi+0zYGm+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaqlVEQAKCRBVnxHm/pHO
 9Q7xCACaUoZfOItFE+qGdxY6A0KW2E50cIXF16Z1DnTqX0GAY3sUD63UVop5Z1l5IVoUO/RtW6D
 pwEsGGzNPx36w/iX8PZUg66bxzAS03dMJHV9PPsslkOFlo/oKFlMGXWrJTXzW8UEG00XjQNtvKC
 wzWYrG4rp9Y2oOyTzGokc/u4HwlJkELH6Dxa+VVgUD0pxaHbJ9FSmYDSpPxT7LT+MxrtuvXzIDR
 ytjVTroWxgrzA/FMfLFPuUpJWKKeVHGg/MPicsp3JkS5nbNKmKq57QTpDlWq7oQa9TJlPbnF6zl
 Esap6akr1qO7C3gtDbZLQAoyogv0RNr59I5BJ9IIJwL/DCgY
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series reworks the PCIe M.2 Bluetooth instantiation using the auxiliary
bus.

The Bluetooth interface of the QCA2066, WCN6855, WCN7850 and NXP 88W8987
M.2 modules is accessed over UART, but the modules show up at runtime over
PCIe and are not described in firmware like devicetree. To make the serdev
bus match the Bluetooth driver, the power sequencing driver was creating a
devicetree node at runtime using an of_changeset. But, creating a node just for
driver matching is not recommended as per Krzysztof [1].

So this series reworks the instantiation to use the auxiliary bus instead. The
power sequencing driver still allocates the UART serdev, but now hands it over
through an auxiliary device along with the power sequencing target. So this
series adds auxiliary driver support to hci_qca and btnxpuart drivers binding to
this device and brings up the controller over the existing UART transport.
Finally, it drops the serdev based M.2 code from both BT drivers.

Dependency
==========

This series depends on Monza series from Loic [2] and reuses its
pwrseq_is_controllable() API.

[1] https://lore.kernel.org/linux-pci/768142f0-2638-41f3-a34f-dc80bb99eb7f@kernel.org
[2] https://lore.kernel.org/all/20260904-monza-wireless-v6-0-d8c5042b3efd@oss.qualcomm.com

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (5):
      Bluetooth: hci_qca: Add auxiliary driver for PCIe M.2 modules
      Bluetooth: btnxpuart: Add auxiliary driver for PCIe M.2 modules
      power: sequencing: pcie-m2: Create auxiliary device for the M.2 BT interface
      Bluetooth: hci_qca: Drop serdev based M.2 power sequencing code
      Bluetooth: btnxpuart: Drop serdev based M.2 power sequencing code

 MAINTAINERS                               |   1 +
 drivers/bluetooth/Kconfig                 |   2 +
 drivers/bluetooth/btnxpuart.c             | 193 +++++++++++++++++++-----------
 drivers/bluetooth/hci_qca.c               | 138 +++++++++++++++------
 drivers/power/sequencing/Kconfig          |   2 +-
 drivers/power/sequencing/pwrseq-pcie-m2.c | 137 +++++++++++----------
 include/linux/pwrseq/pcie-m2-bt.h         |  38 ++++++
 7 files changed, 343 insertions(+), 168 deletions(-)
---
base-commit: e5e04726cdd043e309677071ab1b65a4b18f422b
change-id: 20260806-pci-m2-bt-rework-78dc2c926f00
prerequisite-message-id: 20260904-monza-wireless-v6-0-d8c5042b3efd@oss.qualcomm.com
prerequisite-patch-id: c4e777757ca9358cc4dd35e23738cd7dc1ead1a0
prerequisite-patch-id: 09600595c2e80b12eda3aae39af192847d0f03d0
prerequisite-patch-id: afe88432c4d459e9094c0e6dd31ebeab6c9f2f08
prerequisite-patch-id: 60fd7b13447ccad7546fa8e5b5609d8f133f788f
prerequisite-patch-id: 61dcbe55fdb6f33a3229c197f16a678785aa16d8
prerequisite-patch-id: 14099e5c573d7c41b899c3f9bb9126aa23f1553e
prerequisite-patch-id: 647ee15b77671054b4bb012afa9ba8694b6c86c5
prerequisite-patch-id: c3a774cae81a6fad287731a38f1b76c7e8babc4c
prerequisite-patch-id: 18b0fa62060a1a2c96e76051944d692699035572
prerequisite-patch-id: df02ab167976ac1f0d5a38c78e559a7372b16c1f
prerequisite-patch-id: 3f2dddd108677252a539cdb1eb661912836289ca

Best regards,
--  
மணிவண்ணன் சதாசிவம்

