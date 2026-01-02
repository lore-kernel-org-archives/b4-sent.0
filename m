From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v3 0/4] PCI: Fix ACS enablement for Root Ports in OF
 platforms
Date: Fri, 02 Jan 2026 21:04:46 +0530
Message-Id: <20260102-pci_acs-v3-0-72280b94d288@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJblV2kC/z3MQQrCMBCF4auUWZuSTBvSuPIeUiSm0Q7Ypma0K
 KV3NxZ0M/APj28BDokCw75YIIWZmOKYo9oV4Hs3XoOgLjegRK1QKjF5OjnP4qy0c5WtDTYW8np
 K4UKvTTq2uXviR0zvDZ7x+/0Z+DdmFFLoDo22zqi6sYfIXN6f7ubjMJT5QLuu6wdrODPxpQAAA
 A==
X-Change-ID: 20251201-pci_acs-b15aa3947289
To: Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 iommu@lists.linux.dev, Naresh Kamboju <naresh.kamboju@linaro.org>, 
 Pavankumar Kondeti <quic_pkondeti@quicinc.com>, 
 Xingang Wang <wangxingang5@huawei.com>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Robin Murphy <robin.murphy@arm.com>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5180;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=yKt9mXmVeWjVPM+Kk7KdqbalkLGUCWIr2ZFmKG8rePc=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpV+WlUVx/4bTP6BfZNlt9eRALRoMamvKIMXGrS
 rLG5CQHJE2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaVflpQAKCRBVnxHm/pHO
 9c1yB/9lxtQB67vgbAZABpKAdvNTS9M+n/dB9DGvBp36IZwncJeWKEh5UCXoElnzqv9GazqhCIy
 Ul9O3agybGYO1QOMFtOM5pW5eBM0VW9CUC/9tMK/RVWNRqLzen5WlQDUn7b4ITqBxd4bnfE1vor
 CY/F9/5lFDy8FprwqsRmORYkMAE+MgtayGr5XSKl369u88v8F0gMwYyhwk/sjatOFBQ+FhXxzTS
 i3hr+i5LPqGLVky0X4yeXrBLqXR7Sw22IlwpUR7zRG3MMgB0HUoX6Ob8eXEe6bfSFgqSIiZdSZP
 HBzAXzMoYgdtwKFgT+lrKI03d0GyB0M9X9y579vz/u0J07zk
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes the long standing issue with ACS in OF platforms. There are
two fixes in this series, both fixing independent issues on their own, but both
are needed to properly enable ACS on OF platforms.

Issue(s) background
===================

Back in 2021, Xingang Wang first noted a failure in attaching the HiSilicon SEC
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
of Naresh who got access to the Juno boards in LKFT. The Juno issue was with the
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

Solution
========

In September, I submitted a series [6] to fix both issues. For the IDT issue,
I reused the existing quirk in the PCI core which does a dummy config write
before issuing the first config read to the device. And for the ACS enablement
issue, I just resubmitted the original patch from Xingang which called
pci_request_acs() from devm_of_pci_bridge_init().

But during the review of the series, several comments were received and they
required the series to be reworked completely. Hence, in this version, I've
incorported the comments as below:

1. For the ACS enablement issue, I've moved the pci_enable_acs() call from
pci_acs_init() to pci_dma_configure().

2. For the IDT issue, I've cached the ACS capabilities (RO) in 'pci_dev',
and disabled the broken capability for the IDT switches in the cache. This also
allowed to get rid of the earlier workaround for the switch.

[1] https://lore.kernel.org/all/038397a6-57e2-b6fc-6e1c-7c03b7be9d96@huawei.com
[2] https://lore.kernel.org/all/1621566204-37456-1-git-send-email-wangxingang5@huawei.com
[3] https://lore.kernel.org/all/01314d70-41e6-70f9-e496-84091948701a@samsung.com
[4] https://lore.kernel.org/all/CADYN=9JWU3CMLzMEcD5MSQGnaLyDRSKc5SofBFHUax6YuTRaJA@mail.gmail.com
[5] https://lore.kernel.org/linux-pci/20241107-pci_acs_fix-v1-1-185a2462a571@quicinc.com
[6] https://lore.kernel.org/linux-pci/20250910-pci-acs-v1-0-fe9adb65ad7d@oss.qualcomm.com

Changes in v3:
- Dropped the 'acs_broken_cap' field and directly called the quirk from
  pci_acs_init()
- Collected tags. Since the delta between v2 and v3 is minimal, I've kept them.
- Rebased on top of v6.19-rc1 
- Link to v2: https://lore.kernel.org/r/20251202-pci_acs-v2-0-5d2759a71489@oss.qualcomm.com

Changes in v2:

* Reworked the patches completely as mentioned above.
* Rebased on top of v6.18-rc7

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (4):
      PCI: Enable ACS only after configuring IOMMU for OF platforms
      PCI: Cache ACS capabilities
      PCI: Disable ACS SV capability for the broken IDT switches
      PCI: Extend the pci_disable_broken_acs_cap() quirk for one more IDT switch

 drivers/pci/pci-driver.c |  8 +++++++
 drivers/pci/pci.c        | 33 ++++++++++++--------------
 drivers/pci/pci.h        |  4 +++-
 drivers/pci/probe.c      | 12 ----------
 drivers/pci/quirks.c     | 62 ++++++++++++------------------------------------
 include/linux/pci.h      |  1 +
 6 files changed, 42 insertions(+), 78 deletions(-)
---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251201-pci_acs-b15aa3947289

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

