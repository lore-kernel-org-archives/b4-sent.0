From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Fri, 02 Jan 2026 21:04:50 +0530
Subject: [PATCH v3 4/4] PCI: Extend the pci_disable_broken_acs_cap() quirk
 for one more IDT switch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260102-pci_acs-v3-4-72280b94d288@oss.qualcomm.com>
References: <20260102-pci_acs-v3-0-72280b94d288@oss.qualcomm.com>
In-Reply-To: <20260102-pci_acs-v3-0-72280b94d288@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1308;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=GUu8Qg859a+VLOI/rgxng234DVNkgR6VO624aAuxydk=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpV+Wm74o/HwnJ04fTQcCSyQO4vFATpeTyjSpAk
 8/dpTmAVm2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaVflpgAKCRBVnxHm/pHO
 9RcLB/sEMvU90lbPoTRSvSEIII2sEIQZJK7DLRdmDPIZDhdb4/iHqsMWnXF4ZM/dwwFv5FJ8/HS
 K4Z710qqzXzZNXSQsXntZhoqwN9AmLhAwGMZbkA6vYX+VMdgNlAasGo5udyvHrn4QOOnbNbzBWn
 m99ZXef7u8oZXpybOnUctuyOQfBd5fRYxtshy5+1JdSDdir6S3pba9EGCm0nPXFPfQxvFjRTmF7
 YqcBYzDEFSwAozGsFlY42iwp01EEQUhrgoLr1qYaxbkfGUJI4UJzjSuR9ZU5YFjzKMHojrpk7oK
 PlermbNsTL+A9i4anveM1PyteOVhVAZ+oZ3QJyXXq0GsRxzI
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IDT switch with Device ID 0x8090 used in the ARM Juno R2 development
board incorrectly raises an ACS Source Validation error on Completions for
Config Read Requests, even though PCIe r6.0, sec 6.12.1.1, says that
Completions are never affected by ACS Source Validation.

This is already handled by the pci_disable_broken_acs_cap() quirk for one
of the IDT switch 0x80b5. Hence, extend the quirk for this device too.

Tested-by: Marek Szyprowski <m.szyprowski@samsung.com>
Tested-by: Naresh Kamboju <naresh.kamboju@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/quirks.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/pci/quirks.c b/drivers/pci/quirks.c
index 1571a2ef331e..11ecb9ba1594 100644
--- a/drivers/pci/quirks.c
+++ b/drivers/pci/quirks.c
@@ -5793,7 +5793,8 @@ DECLARE_PCI_FIXUP_CLASS_RESUME_EARLY(PCI_VENDOR_ID_NVIDIA, PCI_ANY_ID,
  */
 void pci_disable_broken_acs_cap(struct pci_dev *pdev)
 {
-	if (pdev->vendor == PCI_VENDOR_ID_IDT && pdev->device == 0x80b5) {
+	if (pdev->vendor == PCI_VENDOR_ID_IDT && (pdev->device == 0x80b5 ||
+	    pdev->device == 0x8090)) {
 		pci_info(pdev, "Disabling broken ACS SV\n");
 		pdev->acs_capabilities &= ~PCI_ACS_SV;
 	}

-- 
2.48.1

