From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 15 Oct 2024 23:08:14 +0200
Subject: [PATCH v4 4/5] iommufd: Enable PRI when doing the
 iommufd_hwpt_alloc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241015-jag-iopfv8-v4-4-b696ca89ba29@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1744;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=2Eaiy4QCkjWZY4GuW+pKOnCGB1W4epa8LRYF3JllTWE=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGcO2crQU+6G18bpdBSQ3b2okV5b1pnNy79N2
 GBUEOtjJWhlGYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnDtnKAAoJELqXzVK3
 lkFPSVAL/3rHF6ukiaXmkrOcXi5XsOXxKxc+dgVZpvgqNqmS96KCaUlqgm3b8Z/55GNDDtL8Owh
 BAQZGtjn23xsG84Dvdwxn23GB1Wn/UTUDDpgQZd4emeeYdz2HZ2TEBtSbxdQThWRYZNmHFcNRRp
 f5P1m53+tgK+RWNkWsY8uEr4QlWXiB5xCFCyoN/pt/tdLoYG0UdEulrguVtBsvMvK07XhhrIPmK
 OcW4a+NQkE02DJt417GFzTOT0qnfKluNb0WaOonpWQmacvWKsN8KIHckjfHCEvwWWt+s9SAFzu9
 t6qvDmAuiAdgHJcD8kbz4nRRwHp3NrgMvUHgpljZ6gOnMFKSx5Gm7odAg1Ce/xRROq9fcuakjRS
 kZNOGAgrUC/AibV67khE6HXC4lo1wWVFUijH5Jj9tbgHVRrz1A8ZNSiOC0qTOUcx8CQvxeih81P
 KGPdaVWKTGbQCsYlox2HFbuyxdVSEtqqkhHBxdk8sM9mXCaz9Dkarg9hVMt9x7Sd2bXZaMBKXo5
 ys=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add IOMMU_HWPT_FAULT_ID_VALID as part of the valid flags when doing an
iommufd_hwpt_alloc allowing the use of an iommu fault allocation
(iommu_fault_alloc) with the IOMMU_HWPT_ALLOC ioctl.

Reviewed-by: Kevin Tian <kevin.tian@intel.com>
Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/iommu/intel/iommu.c          | 3 ++-
 drivers/iommu/iommufd/hw_pagetable.c | 3 ++-
 2 files changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/iommu/intel/iommu.c b/drivers/iommu/intel/iommu.c
index 5d9c3333c92d..dd399ca09859 100644
--- a/drivers/iommu/intel/iommu.c
+++ b/drivers/iommu/intel/iommu.c
@@ -3535,7 +3535,8 @@ intel_iommu_domain_alloc_user(struct device *dev, u32 flags,
 	}
 
 	if (flags &
-	    (~(IOMMU_HWPT_ALLOC_NEST_PARENT | IOMMU_HWPT_ALLOC_DIRTY_TRACKING)))
+	    (~(IOMMU_HWPT_ALLOC_NEST_PARENT | IOMMU_HWPT_ALLOC_DIRTY_TRACKING
+	       | IOMMU_HWPT_FAULT_ID_VALID)))
 		return ERR_PTR(-EOPNOTSUPP);
 	if (nested_parent && !nested_supported(iommu))
 		return ERR_PTR(-EOPNOTSUPP);
diff --git a/drivers/iommu/iommufd/hw_pagetable.c b/drivers/iommu/iommufd/hw_pagetable.c
index d06bf6e6c19f..8f020bc0815f 100644
--- a/drivers/iommu/iommufd/hw_pagetable.c
+++ b/drivers/iommu/iommufd/hw_pagetable.c
@@ -107,7 +107,8 @@ iommufd_hwpt_paging_alloc(struct iommufd_ctx *ictx, struct iommufd_ioas *ioas,
 			  const struct iommu_user_data *user_data)
 {
 	const u32 valid_flags = IOMMU_HWPT_ALLOC_NEST_PARENT |
-				IOMMU_HWPT_ALLOC_DIRTY_TRACKING;
+				IOMMU_HWPT_ALLOC_DIRTY_TRACKING |
+				IOMMU_HWPT_FAULT_ID_VALID;
 	const struct iommu_ops *ops = dev_iommu_ops(idev->dev);
 	struct iommufd_hwpt_paging *hwpt_paging;
 	struct iommufd_hw_pagetable *hwpt;

-- 
2.43.0

