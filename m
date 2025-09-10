From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 10 Sep 2025 23:09:20 +0530
Subject: [PATCH 1/2] PCI: Extend pci_idt_bus_quirk() for IDT switch with
 Device ID 0x8090
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250910-pci-acs-v1-1-fe9adb65ad7d@oss.qualcomm.com>
References: <20250910-pci-acs-v1-0-fe9adb65ad7d@oss.qualcomm.com>
In-Reply-To: <20250910-pci-acs-v1-0-fe9adb65ad7d@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1800;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=F1zn/e3u//vrD8NT+S3b2bYGHBAjod1HSL73CfBCa2s=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBowbfKIsbljvZZO1jxubZqxR2RwT326BD2EYLym
 lsxnouTuiOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaMG3ygAKCRBVnxHm/pHO
 9eecCACj8Q14c0+RcOMVe1jcVdN2q2XiQtNonvov3RaMAGPhIpkrpyRFgd+MK1H1V4sT1X8oHQd
 9X+4cBk2lJ+K9CtrvCGiJXyfVqtGLkle3/YdUJ33o1lfFKnfeTk9O70ZjI3TQ1zYSwxR/PigPo2
 mHD98aR+g84BbtKLKH0LjkI8MsuWenkanDA5rDO1zWC1Dlk04C7bsSjLIaGCt3s7l7EqS2dc3Um
 b6eE/h921Jt6pHaDR6/D/5FGmJC15PrR5RfD/8LBEF6v7cdBN0k062rXJRzUUkQ/O45nvePw/MS
 13BFh/hPSF/czp8yt+DAcde8+fAAqn/bqZNnQfZ1ckxPFGdk
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If ACS is enabled, the IDT switch with Device ID 0x8090 found in ARM Juno
R2 development board incorrectly raises an ACS Source Validation error on
Completions for Config Read Requests, even though PCIe r6.0, sec 6.12.1.1,
says that Completions are never affected by ACS Source Validation.

This behavior is documented in non-public erratum 89H32H8G3-YC and there is
already a quirk available to workaround this issue.

Hence, extend the quirk for Device ID 0x8090 to make the switch functional
if ACS is enabled.

Note: The commit mentioned in the Fixes tag causes ACS to be enabled before
the enumeration of the switch downstream port. So it ended up breaking PCIe
on ARM Juno R2 board, which used to work before this commit until someone
forcefully enabled ACS with cmdline.

Cc: stable@vger.kernel.org # 6.15
Fixes: bcb81ac6ae3c ("iommu: Get DT/ACPI parsing into the proper probe path")
Closes: https://lists.linaro.org/archives/list/lkft-triage@lists.linaro.org/message/CBYO7V3C5TGYPKCMWEMNFFMRYALCUDTK
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/probe.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/pci/probe.c b/drivers/pci/probe.c
index f41128f91ca76ab014ad669ae84a53032c7c6b6b..2320818bc8e58c61d9ada312dfbd8c0fbfbadc0c 100644
--- a/drivers/pci/probe.c
+++ b/drivers/pci/probe.c
@@ -2500,7 +2500,7 @@ bool pci_bus_read_dev_vendor_id(struct pci_bus *bus, int devfn, u32 *l,
 	 * ACS Source Validation errors on completions for config reads.
 	 */
 	if (bridge && bridge->vendor == PCI_VENDOR_ID_IDT &&
-	    bridge->device == 0x80b5)
+	    (bridge->device == 0x80b5 || bridge->device == 0x8090))
 		return pci_idt_bus_quirk(bus, devfn, l, timeout);
 #endif
 

-- 
2.45.2

