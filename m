From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 09 Oct 2024 09:28:11 +0200
Subject: [PATCH v3 3/5] iommu: kconfig: Move IOMMU_IOPF into INTEL_IOMMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241009-jag-iopfv8-v3-3-bd4271df5b2b@kernel.org>
References: <20241009-jag-iopfv8-v3-0-bd4271df5b2b@kernel.org>
In-Reply-To: <20241009-jag-iopfv8-v3-0-bd4271df5b2b@kernel.org>
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
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGcGMI1kWyEIegIoy25Zf+v70/MKy/yzg1Agm
 tJTDsxDdzpxdIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnBjCNAAoJELqXzVK3
 lkFPC+YL/13Haqx5UkfXPFFAidrjr4KLB2A9o4PHyHC87z6XdTYZtAq/2L62iwqUpfTOUyCdyha
 2dC4kAPf9r6KO2CDzjOFY9PXhFkyyYT5sIAis1kIOTLjZXqazbSULSgHody8BCs77ruwICE6VMJ
 udxkIENnXkKAkrvFs+/cksA9EVQoBpIXu1BvBj7YIkJqSeEMPCpPAvzIhflyGlw3BeDSuO87Wmz
 D66V8zgKJfMsWFMcmKPC+uJOQvb/HAHpFA3F2UXybawFRbN7D7a3fz4dVHhrRomFmFdcpOwWYJM
 8MXvLHok6zQ9KIxa7okSDuDuHvuU/J7Z9nDeb5c3SFDcxA2fnhxuuKUY5jajy/3/FoVaEVk5XB5
 LxHc1baHlhBoA6YqPpWlu+WCOxJxbcyNuGihrWj+rP1X9Jiph6n2KGsxnEGnsDXznoGeWUfx1br
 FYGlqcuB8dC/zYJJfIe5PWvD+jihbMqrIofClr7Zpr/vHnc8HhALnwGPgssBo3yT7xbyxzB64J5
 po=
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

