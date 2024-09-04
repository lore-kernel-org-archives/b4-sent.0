From: Joel Granados <j.granados@samsung.com>
Date: Wed, 04 Sep 2024 15:17:14 +0200
Subject: [PATCH 3/6] iommu: kconfig: Move IOMMU_IOPF into INTEL_IOMMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240904-jag-iopfv8-v1-3-e3549920adf3@samsung.com>
References: <20240904-jag-iopfv8-v1-0-e3549920adf3@samsung.com>
In-Reply-To: <20240904-jag-iopfv8-v1-0-e3549920adf3@samsung.com>
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Kevin Tian <kevin.tian@intel.com>, 
 Klaus Jensen <its@irrelevant.dk>
Cc: linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=998; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=A1IcN/yt0t1BbWgqjM2qPuJqNqel/ygqpz+aUMrV/hQ=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGbYXhESVKYlERtao5dlV515lqqcRZZFHelXY
 IAhr15mwVk2UIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJm2F4RAAoJELqXzVK3
 lkFPD3wL/1YW2YIlo7fV0fDqWc+PvCSoS1xKWR2aLxKPa/kZBuc/SrFovAUFt9jr8hh4cxKSjNW
 fx4LcDnAKEEKx7dOM056DK9NypvbWuzHu4i7JAJV35O2Yew6c6OUWVyUEIe+VHHtj3Bj7Uy4imq
 /VQ8+h3WwXUNX+CwGpOocOf1olwaf+xxTbkVxKIJYZ4yIZndzLzYFnk2KXeMFT5+CfixqqvYuGf
 iEdCEpRYRw3A38/ONabQ/rkU/fiE6NmrlPkIX9MiPH7/vtyljjhEGflawkcfOug04hT497LTdJi
 JjJXAFmwZera9G9nPjwN5NC/qhrd6W4bGAHBmOg9gMgSq+Y6Ldjys6uzcMyhzAvwJzWQXGVT6dc
 2st5xWJmxllTfpocVqvn5rQbHULshC5FDOX9YehAmzw7i5sQGFE+SkoNrButwGq5CuO6XMBqcad
 du6YYUVoOGpA3LIslfWNxezI4PhA55bTdsLzfnTemHi0OZvtRNAPmzKTiB/yjH2Izro2Xi00Rd6
 kA=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move IOMMU_IOPF from under INTEL_IOMMU_SVM into INTEL_IOMMU. This
certifies that the core intel iommu utilizes the IOPF library
functions, independent of the INTEL_IOMMU_SVM config.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/iommu/intel/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iommu/intel/Kconfig b/drivers/iommu/intel/Kconfig
index f52fb39c968e..2888671c9278 100644
--- a/drivers/iommu/intel/Kconfig
+++ b/drivers/iommu/intel/Kconfig
@@ -15,6 +15,7 @@ config INTEL_IOMMU
 	select DMA_OPS
 	select IOMMU_API
 	select IOMMU_IOVA
+	select IOMMU_IOPF
 	select IOMMUFD_DRIVER if IOMMUFD
 	select NEED_DMA_MAP_STATE
 	select DMAR_TABLE
@@ -51,7 +52,6 @@ config INTEL_IOMMU_SVM
 	depends on X86_64
 	select MMU_NOTIFIER
 	select IOMMU_SVA
-	select IOMMU_IOPF
 	help
 	  Shared Virtual Memory (SVM) provides a facility for devices
 	  to access DMA resources through process address space by

-- 
2.43.0

