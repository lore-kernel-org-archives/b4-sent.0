From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH 0/2] PCI: Fix ACS enablement for Root Ports in DT platforms
Date: Wed, 10 Sep 2025 23:09:19 +0530
Message-Id: <20250910-pci-acs-v1-0-fe9adb65ad7d@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMe3wWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDS0MD3YLkTN3E5GLd5CSTtERjSwvjRKNkJaDqgqLUtMwKsEnRsbW1AP9
 n8A9ZAAAA
X-Change-ID: 20250910-pci-acs-cb4fa3983a2c
To: Bjorn Helgaas <bhelgaas@google.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joerg Roedel <jroedel@suse.de>, iommu@lists.linux.dev, 
 Anders Roxell <anders.roxell@linaro.org>, 
 Naresh Kamboju <naresh.kamboju@linaro.org>, 
 Pavankumar Kondeti <quic_pkondeti@quicinc.com>, 
 Xingang Wang <wangxingang5@huawei.com>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5832;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=D0MKaZD2Bc9mfUZsr9ayTEVMOhpnqSdYew565pJ4bks=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBowbfKaSSs6qB9cQXVcS7V+k7hyZRMibbBHAsW/
 ggxoOlb+U+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaMG3ygAKCRBVnxHm/pHO
 9Zq4CACmAWwLE/yoLMnF2wrmoe/PZCDW8qpAszZ0rM3Gwv6j1WNbP2N/mZoGBxYlt4rswVD2I8F
 xlDCmGidLBzFUgoRWDr9/IEQnT8MOoYSqO4Jc3dAtDk1WOKbwGw0DmCXe4YWGUGi/YTqlRzaxnt
 yYR5ZtcAh26QdL09N0sJPnUJG8bdBnpy/5hSHKoTBkEMCLx/Gun2CZslCPKxsAVsrHBQYhoU5Q1
 nPrCD0lAVj9mPErgbuUDeyaZ/ktxJuiChpNTlW2S6f7AnUVPAzWIE/WHP1pp2dJ2hEA19+xNZw9
 059ey1kADsNPqzfuai5tEUwwa7TiB9E4jU2xEm/76g9/buT9
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes the long standing issue with ACS in DT platforms. There are
two fixes in this series, both fixing independent issues on their own, but both
are needed to properly enable ACS on DT platforms (well, patch 1 is only needed
for Juno board, but that was a blocker for patch 2, more below...).

Issue(s) background
===================

Back in 2024, Xingang Wang first noted a failure in attaching the HiSilicon SEC
device to QEMU ARM64 pci-root-port device [1]. He then tracked down the issue to
ACS not being enabled for the QEMU Root Port device and he proposed a patch to
fix it [2].

Once the patch got applied, people reported PCIe issues with linux-next on the
ARM Juno Development boards, where they saw failure in enumerating the endpoint
devices [3][4]. So soon, the patch got dropped, but the actual issue with the
ARM Juno boards was left behind.

Fast forward to 2024, Pavan resubmitted the same fix [5] for his own usecase,
hoping that someone in the community would fix the issue with ARM Juno boards.
But the patch was rightly rejected, as a patch that was known to cause issues
should not be merged to the kernel. But again, no one investigated the Juno
issue and it was left behind again.

Now it ended up in my plate and I managed to track down the issue with the help
of Naresh who got access to the Juno boards in LKFT. The Juno issue is with the
PCIe switch from Microsemi/IDT, which triggers ACS Source Validation error on
Completions received for the Configuration Read Request from a device connected
to the downstream port that has not yet captured the PCIe bus number. As per the
PCIe spec r6.0 sec 2.2.6.2, "Functions must capture the Bus and Device Numbers
supplied with all Type 0 Configuration Write Requests completed by the Function
and supply these numbers in the Bus and Device Number fields of the Requester ID
for all Requests". So during the first Configuration Read Request issued by the
switch downstream port during enumeration (for reading Vendor ID), Bus and
Device numbers will be unknown to the device. So it responds to the Read Request
with Completion having Bus and Device number as 0. The switch interprets the
Completion as an ACS Source Validation error and drops the completion, leading
to the failure in detecting the endpoint device. Though the PCIe spec r6.0, sec
6.12.1.1, states that "Completions are never affected by ACS Source Validation".
This behavior is in violation of the spec.

This issue was already found and addressed with a quirk for a different device
from Microsemi with 'commit, aa667c6408d2 ("PCI: Workaround IDT switch ACS
Source Validation erratum")'. Apparently, this issue seems to be documented in
the erratum #36 of IDT 89H32H8G3-YC, which is not publicly available.

Solution for Juno issue
=======================

To fix this issue, I've extended the quirk to the Device ID of the switch
found in Juno R2 boards. I believe the same switch is also present in Juno R1
board as well.

With Patch 1, the Juno R2 boards can now detect the endpoints even with ACS
enabled for the Switch downstream ports. Finally, I added patch 2 that properly
enables ACS for all the PCI devices on DT platforms.

It should be noted that even without patch 2 which enables ACS for the Root
Port, the Juno boards were failing since 'commit, bcb81ac6ae3c ("iommu: Get
DT/ACPI parsing into the proper probe path")' as reported in LKFT [6]. I
believe, this commit made sure pci_request_acs() gets called before the
enumeration of the switch downstream ports. The LKFT team ended up disabling
ACS using cmdline param 'pci=config_acs=000000@pci:0:0'. So I added the above
mentioned commit as a Fixes tag for patch 1.

Also, to mitigate this issue, one could enumerate all the PCIe devices in
bootloader without enabling ACS (as also noted by Robin in the LKFT thread).
This will make sure that the endpoint device has a valid bus number when it
responds to the first Configuration Read Request from the switch downstream
port. So the ACS Source Validation error doesn't get triggered.

Solution for ACS issue
======================

To fix this issue, I've kept the patch from Xingang as is (with rewording of the
patch subject/description). This patch moves the pci_request_acs() call to
devm_of_pci_bridge_init(), which gets called during the host bridge
registration. This makes sure that the 'pci_acs_enable' flag set by
pci_request_acs() is getting set before the enumeration of the Root Port device.
So now, ACS will be enabled for all ACS capable devices of DT platforms.

[1] https://lore.kernel.org/all/038397a6-57e2-b6fc-6e1c-7c03b7be9d96@huawei.com
[2] https://lore.kernel.org/all/1621566204-37456-1-git-send-email-wangxingang5@huawei.com
[3] https://lore.kernel.org/all/01314d70-41e6-70f9-e496-84091948701a@samsung.com
[4] https://lore.kernel.org/all/CADYN=9JWU3CMLzMEcD5MSQGnaLyDRSKc5SofBFHUax6YuTRaJA@mail.gmail.com
[5] https://lore.kernel.org/linux-pci/20241107-pci_acs_fix-v1-1-185a2462a571@quicinc.com
[6] https://lists.linaro.org/archives/list/lkft-triage@lists.linaro.org/message/CBYO7V3C5TGYPKCMWEMNFFMRYALCUDTK

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (1):
      PCI: Extend pci_idt_bus_quirk() for IDT switch with Device ID 0x8090

Xingang Wang (1):
      iommu/of: Call pci_request_acs() before enumerating the Root Port device

 drivers/iommu/of_iommu.c | 1 -
 drivers/pci/of.c         | 8 +++++++-
 drivers/pci/probe.c      | 2 +-
 3 files changed, 8 insertions(+), 3 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250910-pci-acs-cb4fa3983a2c

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

