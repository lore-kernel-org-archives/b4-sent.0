From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 10 Sep 2025 23:09:21 +0530
Subject: [PATCH 2/2] iommu/of: Call pci_request_acs() before enumerating
 the Root Port device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250910-pci-acs-v1-2-fe9adb65ad7d@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2676;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=s3IWPWrtmYAF1td5P6U9N7afV7EwajwvWtWy1fRfcR0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBowbfLBKMpPRmXeHjCf82JrGyQlLaBTrURN4KsN
 QgzqkNRMXCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaMG3ywAKCRBVnxHm/pHO
 9cuaB/9aEE0RS60+8mmPH7waGER7/F4s9uVWLBpZtCDkWRZyWUdJ7SMdDR50TXthG97BiOw0ZEl
 4e6l/R90xwaAnmLqpLJMEtBSGR9tGHIrcG+/CiSN5xNqV2SZBSFPxxdsp4DSywhRmXfHw1KShMd
 RC4g15WALpt1tcpI7nYLmC2Ice8R9lTycjTI23MvuU8H+F5CVsODjWbHUN+5xH1MGM0LoQnpdVd
 jH1+LY4a3TqtbeSVCGJPg8zBe/WRZzLLGB85PgXMKoINILTQu6Zxt/OlppSIEbwIL9KFB9nYhmW
 XWvmR+84jPDpHrO27Hyx7es3T68W6UA577cF56W8GUUtYQrl
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Xingang Wang <wangxingang5@huawei.com>

When booting with devicetree, ACS is enabled for all ACS capable PCI
devices except the first Root Port enumerated in the system. This is due to
calling pci_request_acs() after the enumeration and initialization of the
Root Port device. But afterwards, ACS is getting enabled for the rest of
the PCI devices, since pci_request_acs() sets the 'pci_acs_enable' flag and
the PCI core uses this flag to enable ACS for the rest of the ACS capable
devices.

Ideally, pci_request_acs() should only be called if the 'iommu-map' DT
property is set for the host bridge device. Hence, call pci_request_acs()
from devm_of_pci_bridge_init() if the 'iommu-map' property is present in
the host bridge DT node. This aligns with the implementation of the ARM64
ACPI driver (drivers/acpi/arm64/iort.c) as well.

With this change, ACS will be enabled for all the PCI devices including the
first Root Port device of the DT platforms.

Cc: stable@vger.kernel.org # 5.6
Fixes: 6bf6c24720d33 ("iommu/of: Request ACS from the PCI core when configuring IOMMU linkage")
Signed-off-by: Xingang Wang <wangxingang5@huawei.com>
Signed-off-by: Pavankumar Kondeti <quic_pkondeti@quicinc.com>
[mani: reworded subject, description and comment]
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/iommu/of_iommu.c | 1 -
 drivers/pci/of.c         | 8 +++++++-
 2 files changed, 7 insertions(+), 2 deletions(-)

diff --git a/drivers/iommu/of_iommu.c b/drivers/iommu/of_iommu.c
index 6b989a62def20ecafd833f00a3a92ce8dca192e0..c31369924944d36a3afd3d4ff08c86fc6daf55de 100644
--- a/drivers/iommu/of_iommu.c
+++ b/drivers/iommu/of_iommu.c
@@ -141,7 +141,6 @@ int of_iommu_configure(struct device *dev, struct device_node *master_np,
 			.np = master_np,
 		};
 
-		pci_request_acs();
 		err = pci_for_each_dma_alias(to_pci_dev(dev),
 					     of_pci_iommu_init, &info);
 		of_pci_check_device_ats(dev, master_np);
diff --git a/drivers/pci/of.c b/drivers/pci/of.c
index 3579265f119845637e163d9051437c89662762f8..98c2523f898667b1618c37451d1759959d523da1 100644
--- a/drivers/pci/of.c
+++ b/drivers/pci/of.c
@@ -638,9 +638,15 @@ static int pci_parse_request_of_pci_ranges(struct device *dev,
 
 int devm_of_pci_bridge_init(struct device *dev, struct pci_host_bridge *bridge)
 {
-	if (!dev->of_node)
+	struct device_node *node = dev->of_node;
+
+	if (!node)
 		return 0;
 
+	/* Enable ACS if IOMMU mapping is detected for the host bridge */
+	if (of_property_read_bool(node, "iommu-map"))
+		pci_request_acs();
+
 	bridge->swizzle_irq = pci_common_swizzle;
 	bridge->map_irq = of_irq_parse_and_map_pci;
 

-- 
2.45.2

