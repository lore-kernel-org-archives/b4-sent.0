From: Joel Granados <j.granados@samsung.com>
Date: Fri, 13 Sep 2024 13:44:50 +0200
Subject: [PATCH v2 4/5] iommufd: Enable PRI when doing the
 iommufd_hwpt_alloc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240913-jag-iopfv8-v2-4-dea01c2343bc@samsung.com>
References: <20240913-jag-iopfv8-v2-0-dea01c2343bc@samsung.com>
In-Reply-To: <20240913-jag-iopfv8-v2-0-dea01c2343bc@samsung.com>
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Kevin Tian <kevin.tian@intel.com>, 
 Klaus Jensen <its@irrelevant.dk>
Cc: linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=1694;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=DxEbBmnkeSWlQ/5MEXCH0l7yNP6fyq/9U3DrRBtODeQ=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGbkJdN3nIyQtewYxO5dzLpub6VBCQvASt1vP
 lOAMWJPVRuvTYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJm5CXTAAoJELqXzVK3
 lkFPctcL+QHiIJxPNK8u2+QZbImwSx9KtOG1MIiyOjy1prL1mFeCx3hv6fyrYsZCBYZnVFQCnC5
 OKY6Ot6kNutAzzaHvu+wFxeGddX25+OJL9VRjwSPv4hRHGdK+ojK2etw+3/V1jdURYxBRyf37ew
 mkpmo1QTBDb2e8dqWUXQa9dliujivt92tXPIdiSPMFJz1pPZD0guvljBA3JdLEpKERGubE6EIhb
 PuWihQnMVVcaNtPhsjy/9XbRnklRtaMVoM+CSnchCXq+BSTczuwvYIvTdyxKOOvtFMKEGBK8w0/
 o6azqmqwvHDVuk6/DirH/w1kDqsGhbLHcjJNtQAfWhxZls/qwkAxE1jZPFnDxtXu6ikOo/aJwdC
 rSf5p/ppZd0uaiO116XZ9pWvVBfq++VcpqL1Fwbh9X5eLN1qGtNRsgBoY2HMVNw5D5ho3SpGgHI
 i+2OUylhqVMFDlzJyCXkP1l6udZe1MR5z/ppRBWeHhXAzTHb3d8KpsCQz/26dkyjMV+iEfmX0D7
 x8=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add IOMMU_HWPT_FAULT_ID_VALID as part of the valid flags when doing an
iommufd_hwpt_alloc allowing the use of an iommu fault allocation
(iommu_fault_alloc) with the IOMMU_HWPT_ALLOC ioctl.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 drivers/iommu/intel/iommu.c          | 3 ++-
 drivers/iommu/iommufd/hw_pagetable.c | 3 ++-
 2 files changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/iommu/intel/iommu.c b/drivers/iommu/intel/iommu.c
index 5acc52c62e8c..3d1c971eb9e5 100644
--- a/drivers/iommu/intel/iommu.c
+++ b/drivers/iommu/intel/iommu.c
@@ -3718,7 +3718,8 @@ intel_iommu_domain_alloc_user(struct device *dev, u32 flags,
 	}
 
 	if (flags &
-	    (~(IOMMU_HWPT_ALLOC_NEST_PARENT | IOMMU_HWPT_ALLOC_DIRTY_TRACKING)))
+	    (~(IOMMU_HWPT_ALLOC_NEST_PARENT | IOMMU_HWPT_ALLOC_DIRTY_TRACKING
+	       | IOMMU_HWPT_FAULT_ID_VALID)))
 		return ERR_PTR(-EOPNOTSUPP);
 	if (nested_parent && !nested_supported(iommu))
 		return ERR_PTR(-EOPNOTSUPP);
diff --git a/drivers/iommu/iommufd/hw_pagetable.c b/drivers/iommu/iommufd/hw_pagetable.c
index aefde4443671..88074e459995 100644
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

