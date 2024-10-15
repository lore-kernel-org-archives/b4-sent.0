From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 15 Oct 2024 23:08:13 +0200
Subject: [PATCH v4 3/5] iommu: kconfig: Move IOMMU_IOPF into INTEL_IOMMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241015-jag-iopfv8-v4-3-b696ca89ba29@kernel.org>
References: <20241015-jag-iopfv8-v4-0-b696ca89ba29@kernel.org>
In-Reply-To: <20241015-jag-iopfv8-v4-0-b696ca89ba29@kernel.org>
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Kevin Tian <kevin.tian@intel.com>, 
 Klaus Jensen <its@irrelevant.dk>
Cc: linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 Joel Granados <joel.granados@kernel.org>, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=1019;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=DFZ/f2G030ayl8RBGNPku2LZ2t8SBPpzPS8cPjwszTA=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGcO2cmuEQdDRIu0ztscVdErPio1hSdtYEEn7
 5j7xIBJ62+We4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnDtnJAAoJELqXzVK3
 lkFPTaYL/2kUhvQzC9gxlz5YFxpD/xouya4yX0Pi8XjQTh9x0JlkJiTFztVPqQIY8ilagv8lFzb
 Z7LYxN59eVgd3M0hgXn68Db3HN2t9Zph60JSHCaKWKFbQN+fx1y++gtuYgk/GACUNaEkZ14m9Ru
 KOyhd7EiF7wu/uoUTmeh0d+q1Xi0NXOmI0qcK3uI4M1IXniKN/xBKlEX2gw/eB/ymzIP6Wui5p9
 rIfQBwakxeNC2fWjIdcMeJcjKCCFYbLRPlo3bbRG93vniPhPEVRh5Lxe6LVpvhJX4DME/fDtpSt
 srXfrL28ionabr1esrXMEtNEChKCqEDc4xpyo19mfikyV86lqu8ixJLuiitT7NJMqvfxzUJsdEj
 yGE+jkz5KWuEEaKOa73/ApAZl8iZn1royYVFuFsMFWy0B0/OcBiCy4u6E205wLmSYBAY0tAbO6s
 95TG6607JFAfIJShO0lgociU5MpRIC1WPNXsbiu7s5re2QvaDXJ1rLp2MfDLNjiTzAvkhFIp/i6
 Ts=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move IOMMU_IOPF from under INTEL_IOMMU_SVM into INTEL_IOMMU. This
certifies that the core intel iommu utilizes the IOPF library
functions, independent of the INTEL_IOMMU_SVM config.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/iommu/intel/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iommu/intel/Kconfig b/drivers/iommu/intel/Kconfig
index 88fd32a9323c..f2f538c70650 100644
--- a/drivers/iommu/intel/Kconfig
+++ b/drivers/iommu/intel/Kconfig
@@ -14,6 +14,7 @@ config INTEL_IOMMU
 	depends on PCI_MSI && ACPI && X86
 	select IOMMU_API
 	select IOMMU_IOVA
+	select IOMMU_IOPF
 	select IOMMUFD_DRIVER if IOMMUFD
 	select NEED_DMA_MAP_STATE
 	select DMAR_TABLE
@@ -50,7 +51,6 @@ config INTEL_IOMMU_SVM
 	depends on X86_64
 	select MMU_NOTIFIER
 	select IOMMU_SVA
-	select IOMMU_IOPF
 	help
 	  Shared Virtual Memory (SVM) provides a facility for devices
 	  to access DMA resources through process address space by

-- 
2.43.0

