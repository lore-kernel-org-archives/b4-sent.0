From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH v5 0/4] PCI: Allow D3Hot for PCI bridges in Devicetree
 based platforms
Date: Fri, 02 Aug 2024 11:24:59 +0530
Message-Id: <20240802-pci-bridge-d3-v5-0-2426dd9e8e27@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALN0rGYC/x2MywqAIBAAf0X23IKsBtWvRAcfW+3FRCGC8N+Tj
 sMw80LlIlxhUS8UvqXKlTqMg4JwunQwSuwMpMlqQxpzEPRFYjfRoJ6JybML1kzQm1x4l+f/rVt
 rH7oVnQtfAAAA
To: Bjorn Helgaas <bhelgaas@google.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-acpi@vger.kernel.org, lukas@wunner.de, 
 mika.westerberg@linux.intel.com, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Hsin-Yi Wang <hsinyi@chromium.org>, Bjorn Helgaas <helgaas@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=3410;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=ukMBOMVf5/SQqEc9ERVW/jAC++xbTeCq9CS0IIw4Y+w=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmrHTCfSo/mfFS/bxOe2eefyfjz9u0G2yanEM6y
 b7OClN0PvGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZqx0wgAKCRBVnxHm/pHO
 9TDeB/9/SM6+JeQrrSF8L7RpM5SG+czu6Nqa/lDyoya3UHWXfH3GoynxyrD804Qri4+v18lyLnj
 Ua5WXEN3k65ZEblnnDx1ozNT5xW6EX1GoZqdaHOteXknjvWyA1G7YZVhgBB4GzNHCDtAdCxS9sg
 F1a94OxCo4WAuk2QWBLNKlltoSNubuRCgGUqDIBmCriPN9ew/bfGJ8q+eZH4sVJbIB2zHLFfhnx
 8vTfcd3yMQCecOeWHPm/AAjlpVgM0yJ4E2joqlXZ/x8dqU3HCBYBdQpuxwEZl/UFQMrTHlf04Ld
 v0aJaiqwSNb2AGmKH8+XPcahfXEOycvtP4gh9uyNWmsrRmic
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series allows D3Hot for PCI bridges in Devicetree based platforms.
Even though most of the bridges in Devicetree platforms support D3Hot, PCI
core will allow D3Hot only when one of the following conditions are met:

1. Platform is ACPI based
2. Thunderbolt controller is used
3. pcie_port_pm=force passed in cmdline

While options 1 and 2 do not apply to most of the DT based platforms,
option 3 will make the life harder for distro maintainers.

Initially, I tried to fix this issue by using a Devicetree property [1], but
that was rejected by Bjorn and it was concluded that D3Hot should be allowed by
default for all the Devicetree based platforms.

During the review of v3 series, Bjorn noted several shortcomings of the
pci_bridge_d3_possible() API [2] and I tried to address them in this series as
well.

But please note that the patches 2 and 3 needs closer review from ACPI and x86
folks since I've splitted the D3Hot and D3Cold handling based on my little
understanding of the code.

Testing
=======

This series is tested on SM8450 based development board on top of [3].

- Mani

[1] https://lore.kernel.org/linux-pci/20240214-pcie-qcom-bridge-v3-1-3a713bbc1fd7@linaro.org/
[2] https://lore.kernel.org/linux-pci/20240305175107.GA539676@bhelgaas/
[3] https://lore.kernel.org/linux-arm-msm/20240321-pcie-qcom-bridge-dts-v2-0-1eb790c53e43@linaro.org/

Changes in v5:
- Rebased on top of v6.11-rc1
- Fixed the function name in Kdoc of patch 3/4
- Collected tags
- Link to v4: https://lore.kernel.org/linux-pci/20240326-pci-bridge-d3-v4-0-f1dce1d1f648@linaro.org

Changes in v4:
- Added pci_bridge_d3_possible() rework based on comments from Bjorn
- Got rid of the DT property and allowed D3Hot by default on all DT platforms

Changes in v3:
- Fixed kdoc, used of_property_present() and dev_of_node() (Lukas)
- Link to v2: https://lore.kernel.org/r/20240214-pcie-qcom-bridge-v2-1-9dd6dbb1b817@linaro.org

Changes in v2:
- Switched to DT based approach as suggested by Lukas.
- Link to v1: https://lore.kernel.org/r/20240202-pcie-qcom-bridge-v1-0-46d7789836c0@linaro.org

To: Bjorn Helgaas <bhelgaas@google.com>
To: Rafael J. Wysocki <rafael@kernel.org>
To: Len Brown <lenb@kernel.org>
Cc: linux-pci@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-acpi@vger.kernel.org
Cc: lukas@wunner.de
Cc: mika.westerberg@linux.intel.com

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Manivannan Sadhasivam (4):
      PCI/portdrv: Make use of pci_dev::bridge_d3 for checking the D3 possibility
      PCI: Rename pci_bridge_d3_possible() to pci_bridge_d3_allowed()
      PCI: Decouple D3Hot and D3Cold handling for bridges
      PCI: Allow PCI bridges to go to D3Hot on all Devicetree based platforms

 drivers/pci/bus.c          |  2 +-
 drivers/pci/pci-acpi.c     |  9 ++---
 drivers/pci/pci-sysfs.c    |  2 +-
 drivers/pci/pci.c          | 90 ++++++++++++++++++++++++++++++++--------------
 drivers/pci/pci.h          | 12 ++++---
 drivers/pci/pcie/portdrv.c | 16 ++++-----
 drivers/pci/remove.c       |  2 +-
 include/linux/pci.h        |  3 +-
 8 files changed, 89 insertions(+), 47 deletions(-)
---
base-commit: 705c1da8fa4816fb0159b5602fef1df5946a3ee2
change-id: 20240320-pci-bridge-d3-092e2beac438

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

